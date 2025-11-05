terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "jewelry-app"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "jewelry-app-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "jewelry-app-igw"
  }
}

# Subnet Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "jewelry-app-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "jewelry-app-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "main" {
  name_prefix = "jewelry-app-sg-"
  description = "Security group for jewelry app"
  vpc_id      = aws_vpc.main.id

  # SSH (apenas para administração)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # RECOMENDADO: Restringir ao seu IP
  }

  # HTTP na porta 8080
  ingress {
    description = "Application HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress - permitir todo tráfego de saída
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jewelry-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Key Pair (SSH)
resource "aws_key_pair" "main" {
  key_name   = "jewelry-app-key-${data.aws_caller_identity.current.account_id}"
  public_key = file("${path.module}/.ssh/id_rsa.pub")

  tags = {
    Name = "jewelry-app-ssh-key"
  }
}

# IAM Role para EC2 (boas práticas de segurança)
resource "aws_iam_role" "ec2_role" {
  name_prefix = "jewelry-app-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "jewelry-app-ec2-role"
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "jewelry-app-ec2-profile-"
  role        = aws_iam_role.ec2_role.name

  lifecycle {
    create_before_destroy = true
  }
}

# Política IAM para logs do CloudWatch (opcional, mas recomendado)
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name_prefix = "cloudwatch-logs-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# AMI mais recente do Ubuntu 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro" # Free tier elegível
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Log de execução
    exec > >(tee /var/log/user-data.log)
    exec 2>&1
    
    echo "=== Iniciando configuração da instância ==="
    
    # Atualizar sistema
    apt-get update
    apt-get upgrade -y
    
    # Instalar Docker
    apt-get install -y docker.io git curl
    systemctl start docker
    systemctl enable docker
    
    # Adicionar usuário ubuntu ao grupo docker
    usermod -aG docker ubuntu
    
    # Instalar Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Aguardar o Docker estar totalmente operacional
    sleep 5
    
    # Parar container existente (se houver)
    docker container stop jewelry-app 2> /dev/null || true
    docker container rm jewelry-app 2> /dev/null || true
    
    # Clonar repositório atualizado
    cd /home/ubuntu
    rm -rf app-diamante/
    git clone https://github.com/Fcondera/app-diamante.git
    cd app-diamante/modulo7-iac_tooling
    
    # Build e execução do container
    docker build -t jewelry-app .
    docker run -d --name jewelry-app --restart unless-stopped -p 8080:80 jewelry-app
    
    # Verificar status
    docker ps
    
    echo "=== Configuração concluída ==="
  EOF
  )

  tags = {
    Name = "jewelry-app-instance"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP (para IP fixo)
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "jewelry-app-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# Outputs
output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "IP público da instância"
  value       = aws_eip.main.public_ip
}

output "app_url" {
  description = "URL da aplicação"
  value       = "http://${aws_eip.main.public_ip}:8080"
}

output "ssh_command" {
  description = "Comando para conectar via SSH"
  value       = "ssh -i .ssh/id_rsa ubuntu@${aws_eip.main.public_ip}"
}

output "security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.main.id
}
