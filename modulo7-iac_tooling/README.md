# Jewelry App - AWS Deployment

Aplicação Vue.js para exibição de joias com deploy automatizado na AWS usando Terraform.

## 🚀 Características

- ✅ Infraestrutura como Código (Terraform)
- ✅ Deploy automatizado com Makefile
- ✅ Container Docker otimizado
- ✅ Instância EC2 t2.micro (Free Tier)
- ✅ Segurança com IAM Roles e Security Groups
- ✅ IP estático com Elastic IP
- ✅ CI/CD com GitHub Actions

## 📋 Pré-requisitos

- **Node.js 18+**
- **Docker**
- **Terraform 1.5+**
- **AWS CLI** configurado
- **Credenciais AWS** (Access Key e Secret Key)

## 🔧 Configuração Inicial

### 1. Configurar AWS CLI

```bash
# Instalar AWS CLI (Windows)
# Baixe de: https://aws.amazon.com/cli/

# Configurar credenciais
aws configure
# AWS Access Key ID: [sua-access-key]
# AWS Secret Access Key: [sua-secret-key]
# Default region: us-east-1
# Default output format: json
```

### 2. Clonar o Repositório

```bash
git clone https://github.com/dartanghan/proway-docker.git
cd proway-docker/modulo7-iac_tooling
```

> 💡 **Quer fazer deploy em seu próprio repositório?** Veja o [Guia de Migração](./MIGRATION_GUIDE.md)

### 3. Gerar Chave SSH

```bash
make ssh-keygen
```

## 🚀 Deploy na AWS

### Deploy Automatizado (Recomendado)

```bash
make aws-deploy
```

Este comando irá:
1. ✅ Gerar chave SSH (se não existir)
2. ✅ Inicializar o Terraform
3. ✅ Validar configurações
4. ✅ Criar infraestrutura na AWS
5. ✅ Configurar a aplicação automaticamente

### Deploy Manual (Passo a Passo)

```bash
# 1. Gerar chave SSH
make ssh-keygen

# 2. Inicializar Terraform
make init

# 3. Validar configuração
make validate

# 4. Planejar mudanças
make plan

# 5. Aplicar infraestrutura
make apply
```

Após 2-3 minutos, a aplicação estará disponível na URL exibida no output.

## 💻 Desenvolvimento Local

### Modo Desenvolvimento

```bash
# Instalar dependências
npm install

# Executar em modo desenvolvimento
npm run dev
```

Acesse: http://localhost:5173

### Docker Local

```bash
# Build e execução com Makefile
make docker-run

# Ou manualmente
docker build -t jewelry-app .
docker run -d -p 8080:80 jewelry-app
```

Acesse: http://localhost:8080

## 🧪 Comandos Úteis

```bash
# Ver todos os comandos disponíveis
make help

# Validar Terraform
make validate

# Planejar mudanças
make plan

# Aplicar mudanças
make apply

# Destruir infraestrutura
make aws-destroy

# Limpar arquivos temporários
make clean

# Build da aplicação
make build
```

## 🏗️ Arquitetura AWS

### Recursos Provisionados

- **VPC** (10.0.0.0/16)
  - Subnet Pública (10.0.1.0/24)
  - Internet Gateway
  - Route Table
  
- **EC2 Instance**
  - Tipo: t2.micro (Free Tier)
  - AMI: Ubuntu 22.04 LTS
  - Volume: 8GB GP3 (criptografado)
  - Docker pré-instalado
  
- **Security Group**
  - Porta 22 (SSH)
  - Porta 8080 (HTTP)
  
- **Elastic IP**
  - IP público fixo
  
- **IAM Role**
  - Permissões para CloudWatch Logs
  - Instance Profile

### Diagrama de Arquitetura

```
┌─────────────────────────────────────────┐
│         AWS Cloud (us-east-1)           │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                │  │
│  │                                   │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Subnet Pública             │  │  │
│  │  │  (10.0.1.0/24)              │  │  │
│  │  │                             │  │  │
│  │  │  ┌────────────────────┐     │  │  │
│  │  │  │  EC2 t2.micro      │     │  │  │
│  │  │  │  Ubuntu 22.04      │     │  │  │
│  │  │  │                    │     │  │  │
│  │  │  │  Docker Container  │     │  │  │
│  │  │  │  (Jewelry App)     │     │  │  │
│  │  │  │  Port: 8080        │     │  │  │
│  │  │  └────────────────────┘     │  │  │
│  │  │           │                 │  │  │
│  │  │    [Elastic IP]             │  │  │
│  │  └─────────────────────────────┘  │  │
│  │               │                   │  │
│  │    [Internet Gateway]             │  │
│  └───────────────────────────────────┘  │
│                 │                       │
└─────────────────┼───────────────────────┘
                  │
            [Internet]
```

## 🔒 Segurança

### Implementações de Segurança

✅ **Security Group** com regras restritivas
✅ **IAM Roles** com princípio do menor privilégio
✅ **Volume EBS criptografado**
✅ **Chaves SSH** para acesso seguro
✅ **VPC isolada** com subnet pública

### Melhorias Recomendadas

- Restringir SSH apenas para IPs específicos
- Implementar AWS Systems Manager (Session Manager)
- Adicionar WAF (Web Application Firewall)
- Configurar CloudWatch Alarms
- Implementar backup automático
- Adicionar HTTPS com Certificate Manager

## 📊 Custos Estimados

### Free Tier (Primeiro Ano)

- EC2 t2.micro: **Gratuito** (750 horas/mês)
- EBS GP3 8GB: **Gratuito** (30GB/mês)
- Elastic IP: **Gratuito** (quando associado)
- Data Transfer: **Gratuito** (até 100GB/mês)

### Após Free Tier

- EC2 t2.micro: ~$8.50/mês
- EBS GP3 8GB: ~$0.64/mês
- Elastic IP: Gratuito (quando associado)
- **Total estimado: ~$9.14/mês**

## 🔄 CI/CD com GitHub Actions

O projeto inclui pipeline automatizado que:

1. ✅ Valida código Terraform
2. ✅ Executa testes de segurança
3. ✅ Aplica infraestrutura automaticamente
4. ✅ Notifica sobre deploy

### Configurar Secrets no GitHub

```
AWS_ACCESS_KEY_ID: [sua-access-key]
AWS_SECRET_ACCESS_KEY: [sua-secret-key]
```

## 📁 Estrutura do Projeto

```
modulo7-iac_tooling/
├── src/                    # Código Vue.js
│   ├── App.vue
│   └── main.js
├── .github/
│   └── workflows/
│       └── deploy.yml      # Pipeline CI/CD
├── .ssh/                   # Chaves SSH (geradas)
│   ├── id_rsa
│   └── id_rsa.pub
├── main.tf                 # Configuração Terraform
├── Dockerfile              # Container da aplicação
├── Makefile               # Comandos automatizados
├── package.json           # Dependências Node.js
├── vite.config.js         # Config Vite
└── README.md              # Este arquivo
```

## 🐛 Troubleshooting

### Erro: "SSH key not found"

```bash
make ssh-keygen
```

### Erro: "AWS credentials not configured"

```bash
aws configure
```

### Erro: "Terraform state locked"

Vários engenheiros trabalhando na mesma conta podem causar conflitos. O projeto usa DynamoDB para lock de estado.

```bash
# Forçar unlock (use com cuidado)
terraform force-unlock [LOCK_ID]
```

### Aplicação não está acessível

Aguarde 2-3 minutos após o deploy. O user-data precisa instalar Docker e buildar a aplicação.

```bash
# Verificar logs da instância
aws ec2 get-console-output --instance-id [ID_INSTANCIA]

# Conectar via SSH e verificar
make ssh
docker ps
docker logs jewelry-app
```

## 📞 Suporte

Para problemas ou dúvidas:
1. Verifique os logs: `terraform output ssh_command`
2. Conecte via SSH e verifique: `docker ps`
3. Verifique logs do container: `docker logs jewelry-app`

## 🧹 Limpeza

Para remover toda a infraestrutura:

```bash
make aws-destroy
```

**⚠️ ATENÇÃO:** Este comando irá destruir todos os recursos criados na AWS!

## 📝 Licença

Este projeto é para fins educacionais.

---

**🎯 Desenvolvido para migração Azure → AWS com foco em custo-benefício e segurança**
