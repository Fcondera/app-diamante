# 🚀 Guia de Deployment - Jewelry App

## Índice
1. [Pré-requisitos](#pré-requisitos)
2. [Configuração Inicial](#configuração-inicial)
3. [Deploy Manual](#deploy-manual)
4. [Deploy Automatizado](#deploy-automatizado)
5. [CI/CD com GitHub Actions](#cicd-com-github-actions)
6. [Troubleshooting](#troubleshooting)
7. [Rollback](#rollback)

## Pré-requisitos

### Software Necessário

| Software | Versão Mínima | Instalação |
|----------|---------------|------------|
| Node.js | 18+ | https://nodejs.org/ |
| Docker | 20+ | https://docker.com/get-started |
| Terraform | 1.5+ | https://terraform.io/downloads |
| AWS CLI | 2.0+ | https://aws.amazon.com/cli/ |
| Git | 2.0+ | https://git-scm.com/ |
| Make | - | Incluído no Windows 10+ |

### Credenciais AWS

1. Acesse o AWS Console
2. Vá para IAM → Users → Seu usuário
3. Security Credentials → Create Access Key
4. Salve o Access Key ID e Secret Access Key

### Permissões Necessárias

O usuário AWS precisa das seguintes permissões:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "iam:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Configuração Inicial

### 1. Clonar o Repositório

```bash
git clone https://github.com/dartanghan/proway-docker.git
cd proway-docker/modulo7-iac_tooling
```

### 2. Configurar AWS CLI

```bash
aws configure
# AWS Access Key ID: [sua-access-key]
# AWS Secret Access Key: [sua-secret-key]
# Default region: us-east-1
# Default output format: json
```

Verificar configuração:

```bash
aws sts get-caller-identity
```

### 3. Gerar Chaves SSH

```bash
make ssh-keygen
```

Este comando cria:
- `.ssh/id_rsa` (chave privada)
- `.ssh/id_rsa.pub` (chave pública)

⚠️ **IMPORTANTE:** Nunca commite a chave privada!

## Deploy Manual

### Passo 1: Validar Configuração

```bash
make validate
```

Este comando:
- Inicializa o Terraform
- Valida sintaxe
- Verifica formatação

### Passo 2: Planejar Mudanças

```bash
make plan
```

Revise o output:
- Recursos a serem criados (+)
- Recursos a serem modificados (~)
- Recursos a serem destruídos (-)

### Passo 3: Aplicar Infraestrutura

```bash
make apply
```

Tempo estimado: **3-5 minutos**

### Passo 4: Aguardar Aplicação

Após o Terraform concluir, aguarde **2-3 minutos** para:
- User data executar
- Docker instalar
- Aplicação buildar
- Container iniciar

### Passo 5: Verificar Deploy

```bash
# Obter URL da aplicação
terraform output app_url

# Testar acesso
curl -I $(terraform output -raw app_url)
```

## Deploy Automatizado

### Usando Makefile (Recomendado)

```bash
make aws-deploy
```

Este comando executa:
1. ✅ Gera chave SSH (se necessário)
2. ✅ Inicializa Terraform
3. ✅ Valida configuração
4. ✅ Aplica infraestrutura
5. ✅ Exibe URL da aplicação

### Output Esperado

```
======================================
Deploy concluído!
Aguarde 2-3 minutos para a aplicação inicializar...
======================================
http://3.80.123.456:8080
======================================
Para conectar via SSH:
ssh -i .ssh/id_rsa ubuntu@3.80.123.456
======================================
```

## CI/CD com GitHub Actions

### Configuração

#### 1. Fork do Repositório

```bash
# No GitHub, clique em "Fork"
git clone https://github.com/SEU_USUARIO/proway-docker.git
cd proway-docker/modulo7-iac_tooling
```

#### 2. Configurar Secrets

Vá para: `Settings → Secrets and variables → Actions → New repository secret`

Adicione:

| Name | Value |
|------|-------|
| AWS_ACCESS_KEY_ID | Sua Access Key |
| AWS_SECRET_ACCESS_KEY | Sua Secret Key |

#### 3. Ativar Actions

1. Vá para a aba "Actions"
2. Clique em "I understand my workflows, go ahead and enable them"

#### 4. Fazer Push

```bash
git add .
git commit -m "feat: enable AWS deployment"
git push origin main
```

### Pipeline Automático

O pipeline executa automaticamente em:
- ✅ Push para branch `main`
- ✅ Pull Requests
- ✅ Manual (workflow_dispatch)

#### Stages do Pipeline

1. **Validate** (30s)
   - Terraform format check
   - Terraform validate

2. **Security Scan** (1-2 min)
   - Trivy vulnerability scan
   - tfsec security scan

3. **Deploy** (5-7 min)
   - Terraform plan
   - Terraform apply
   - Health check

4. **Notify** (10s)
   - Success/failure notification

## Troubleshooting

### Erro: "SSH key not found"

**Solução:**
```bash
make ssh-keygen
```

### Erro: "AWS credentials not configured"

**Solução:**
```bash
aws configure
```

### Erro: "Terraform state locked"

**Causa:** Outro engenheiro está executando Terraform simultaneamente

**Solução 1 (Aguardar):**
```bash
# Aguarde 5-10 minutos e tente novamente
```

**Solução 2 (Forçar unlock):**
```bash
terraform force-unlock [LOCK_ID]
```

⚠️ **CUIDADO:** Só faça force-unlock se tiver certeza que ninguém está executando!

### Erro: "Instance already exists"

**Causa:** Recursos com nomes conflitantes

**Solução:**
```bash
# Destruir infraestrutura antiga
make aws-destroy

# Recriar
make aws-deploy
```

### Aplicação não responde

**Verificação 1: Aguardar**
```bash
# Aguarde 3-5 minutos após o deploy
```

**Verificação 2: Logs da instância**
```bash
aws ec2 get-console-output --instance-id $(terraform output -raw instance_id)
```

**Verificação 3: Conectar via SSH**
```bash
ssh -i .ssh/id_rsa ubuntu@$(terraform output -raw instance_public_ip)
docker ps
docker logs jewelry-app
```

**Verificação 4: Security Group**
```bash
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)
```

### Erro: "t2.micro not available"

**Causa:** Free tier esgotado ou região sem disponibilidade

**Solução:**
```bash
# Editar main.tf
instance_type = "t3.micro"  # Ligeiramente mais caro
```

## Rollback

### Rollback Completo

```bash
# Destruir toda infraestrutura
make aws-destroy

# Checkout da versão anterior
git checkout <commit-anterior>

# Recriar infraestrutura
make aws-deploy
```

### Rollback de Aplicação

```bash
# Conectar à instância
ssh -i .ssh/id_rsa ubuntu@$(terraform output -raw instance_public_ip)

# Parar container atual
docker stop jewelry-app
docker rm jewelry-app

# Fazer checkout da versão anterior
cd /home/ubuntu/proway-docker/modulo7-iac_tooling
git fetch --all
git checkout <commit-anterior>

# Rebuildar e executar
docker build -t jewelry-app .
docker run -d --name jewelry-app --restart unless-stopped -p 8080:80 jewelry-app
```

## Ambientes Múltiplos

### Desenvolvimento

```bash
# Criar workspace dev
terraform workspace new dev
terraform workspace select dev

# Deploy
make apply
```

### Produção

```bash
# Criar workspace prod
terraform workspace new prod
terraform workspace select prod

# Deploy
make apply
```

## Monitoramento

### Health Check Manual

```bash
# Script de health check
curl -f $(terraform output -raw app_url) && echo "✅ OK" || echo "❌ FAIL"
```

### Logs

```bash
# Conectar via SSH
ssh -i .ssh/id_rsa ubuntu@$(terraform output -raw instance_public_ip)

# Ver logs do Docker
docker logs -f jewelry-app

# Ver logs do sistema
tail -f /var/log/user-data.log
```

## Custos

### Estimativa Mensal

| Recurso | Free Tier | Custo Pós Free Tier |
|---------|-----------|---------------------|
| EC2 t2.micro | 750h/mês | $8.50/mês |
| EBS GP3 8GB | 30GB/mês | $0.64/mês |
| Elastic IP | Gratuito* | Gratuito* |
| Data Transfer | 100GB/mês | $0.09/GB |

*Gratuito quando associado a instância em execução

**Total: ~$9.14/mês** (após Free Tier)

### Otimização de Custos

1. **Use t2.micro** (Free Tier)
2. **Desligue em dev**: Fora do horário comercial
3. **Auto Scaling**: Apenas se necessário
4. **Reserved Instances**: Para produção de longo prazo

## Limpeza

### Destruir Infraestrutura

```bash
make aws-destroy
```

⚠️ **ATENÇÃO:** Este comando remove TODOS os recursos!

### Verificar Recursos Órfãos

```bash
# Listar instâncias EC2
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,Tags[?Key==`Project`].Value|[0]]' --output table

# Listar EIPs não associados
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].[PublicIp]' --output table

# Listar volumes não anexados
aws ec2 describe-volumes --query 'Volumes[?State==`available`].[VolumeId]' --output table
```

## Contatos e Suporte

- **Documentação:** [README.md](./README.md)
- **Segurança:** [SECURITY.md](./SECURITY.md)
- **Issues:** https://github.com/dartanghan/proway-docker/issues

---

**Última atualização:** Novembro 2025  
**Versão:** 1.0.0
