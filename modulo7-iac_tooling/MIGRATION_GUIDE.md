# 🚀 Guia de Migração para Novo Repositório

Este guia explica como fazer o deploy deste projeto em um novo repositório GitHub.

## 📋 Pré-requisitos

- Conta no GitHub
- Git instalado
- Credenciais AWS configuradas
- Terraform instalado

## 🔄 Passo a Passo

### 1. Criar Novo Repositório no GitHub

1. Acesse https://github.com/new
2. Preencha os dados:
   - **Nome:** `jewelry-app-aws` (ou nome de sua preferência)
   - **Descrição:** `Aplicação de joias com deploy automatizado na AWS`
   - **Visibilidade:** Privado (recomendado) ou Público
   - **NÃO** marque "Add a README file"
   - **NÃO** adicione .gitignore ou licença

3. Clique em "Create repository"

### 2. Preparar o Projeto Local

```powershell
# Navegue até o diretório do projeto
cd c:\Users\moc\proway-docker\modulo7-iac_tooling

# Inicializar novo repositório Git (se necessário)
git init

# Adicionar todos os arquivos
git add .

# Fazer commit inicial
git commit -m "feat: initial commit - jewelry app AWS deployment"
```

### 3. Conectar ao Novo Repositório

```powershell
# Adicionar remote (substitua SEU_USUARIO e NOME_REPO)
git remote add origin https://github.com/SEU_USUARIO/NOME_REPO.git

# Ou se preferir SSH:
git remote add origin git@github.com:SEU_USUARIO/NOME_REPO.git

# Verificar remote
git remote -v

# Push para o GitHub
git branch -M main
git push -u origin main
```

### 4. Configurar Secrets no GitHub

#### 4.1. Acessar Configurações

1. Vá para seu repositório no GitHub
2. Clique em `Settings` (⚙️)
3. No menu lateral, clique em `Secrets and variables` → `Actions`
4. Clique em `New repository secret`

#### 4.2. Adicionar AWS_ACCESS_KEY_ID

- **Name:** `AWS_ACCESS_KEY_ID`
- **Secret:** Cole sua AWS Access Key ID
- Clique em `Add secret`

#### 4.3. Adicionar AWS_SECRET_ACCESS_KEY

- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Secret:** Cole sua AWS Secret Access Key
- Clique em `Add secret`

### 5. Habilitar GitHub Actions

1. Vá para a aba `Actions` no seu repositório
2. Se solicitado, clique em "I understand my workflows, go ahead and enable them"

### 6. Ajustar Configurações (Opcional)

#### 6.1. Atualizar URLs no README.md

Edite o arquivo `README.md` e substitua as URLs do repositório original pelas do seu novo repositório.

#### 6.2. Configurar Backend do Terraform

O projeto usa S3 + DynamoDB para state remoto. Se quiser usar seu próprio bucket:

```powershell
# Edite o main.tf e ajuste o backend:
# backend "s3" {
#   bucket         = "seu-bucket-terraform-state"
#   key            = "jewelry-app/terraform.tfstate"
#   region         = "us-east-1"
#   dynamodb_table = "seu-terraform-locks"
#   encrypt        = true
# }
```

Ou comente o bloco `backend "s3"` para usar state local (não recomendado para produção).

### 7. Testar o Deploy

#### 7.1. Deploy Local

```powershell
# Instalar dependências
npm install

# Gerar chave SSH
make ssh-keygen

# Configurar AWS CLI (se ainda não configurou)
aws configure

# Fazer deploy
make aws-deploy
```

#### 7.2. Deploy via GitHub Actions

```powershell
# Fazer qualquer alteração
echo "# Test" >> README.md

# Commit e push
git add .
git commit -m "test: trigger GitHub Actions"
git push origin main
```

Acompanhe o deploy na aba `Actions` do GitHub.

## 🔧 Ajustes para Diferentes Cenários

### Cenário 1: Múltiplos Ambientes

Crie branches para cada ambiente:

```powershell
# Criar branch de desenvolvimento
git checkout -b development
git push -u origin development

# Criar branch de staging
git checkout -b staging
git push -u origin staging

# Branch main = production
```

Ajuste o workflow `.github/workflows/deploy.yml` para deploy condicional:

```yaml
on:
  push:
    branches:
      - main        # Production
      - staging     # Staging
      - development # Development
```

### Cenário 2: Terraform Workspaces

Use workspaces para isolar ambientes:

```powershell
# Development
terraform workspace new dev
terraform workspace select dev
make apply

# Production
terraform workspace new prod
terraform workspace select prod
make apply
```

### Cenário 3: Repositório Privado vs Público

#### Repositório Privado (Recomendado)
- ✅ Maior segurança
- ✅ Controle de acesso
- ✅ Ideal para projetos comerciais

#### Repositório Público
- ⚠️ Nunca commite secrets ou chaves
- ⚠️ Use apenas GitHub Secrets
- ⚠️ Revise código antes de publicar

## 🔒 Checklist de Segurança

Antes de fazer push:

- [ ] Arquivo `.gitignore` está configurado
- [ ] Chaves SSH NÃO estão no repositório
- [ ] Credenciais AWS NÃO estão no código
- [ ] Arquivo `.terraform/` está no .gitignore
- [ ] Arquivos `.tfstate` estão no .gitignore
- [ ] Secrets configurados no GitHub
- [ ] README.md atualizado com suas informações

## 📂 Estrutura de Branches (Sugestão)

```
main (production)
├── staging
│   └── development
│       └── feature/nova-funcionalidade
```

### Workflow Sugerido

```powershell
# Criar feature
git checkout -b feature/minha-feature development

# Desenvolver e testar
git add .
git commit -m "feat: adiciona nova funcionalidade"

# Push e criar Pull Request
git push -u origin feature/minha-feature
```

## 🚨 Troubleshooting

### Erro: "remote origin already exists"

```powershell
# Remover remote antigo
git remote remove origin

# Adicionar novo remote
git remote add origin https://github.com/SEU_USUARIO/NOME_REPO.git
```

### Erro: "failed to push some refs"

```powershell
# Pull das mudanças remotas primeiro
git pull origin main --rebase

# Depois push
git push origin main
```

### Erro: "GitHub Actions not running"

1. Verifique se Actions está habilitado em Settings → Actions
2. Verifique se os secrets estão configurados corretamente
3. Verifique os logs em Actions → Workflow run

### Erro: "AWS credentials invalid"

```powershell
# Verificar credenciais locais
aws sts get-caller-identity

# Reconfigurar
aws configure
```

## 📊 Monitoramento Pós-Deploy

### Verificar Status da Aplicação

```powershell
# Via Terraform
terraform output app_url

# Testar acesso
curl -I $(terraform output -raw app_url)
```

### Verificar Logs

```powershell
# Conectar via SSH
ssh -i .ssh/id_rsa ubuntu@$(terraform output -raw instance_public_ip)

# Ver logs da aplicação
docker logs jewelry-app

# Ver logs do sistema
tail -f /var/log/user-data.log
```

## 🎯 Próximos Passos

Após migração bem-sucedida:

1. ✅ Configurar branch protection rules
2. ✅ Adicionar colaboradores (se necessário)
3. ✅ Configurar notificações
4. ✅ Documentar processos específicos do seu time
5. ✅ Configurar ambientes no GitHub (opcional)
6. ✅ Adicionar status badges ao README

## 📝 Exemplo de README Badge

Adicione badges ao seu README.md:

```markdown
![Deploy Status](https://github.com/SEU_USUARIO/NOME_REPO/workflows/Deploy%20to%20AWS/badge.svg)
![Terraform](https://img.shields.io/badge/terraform-v1.5+-blue.svg)
![AWS](https://img.shields.io/badge/AWS-us--east--1-orange.svg)
```

## 🆘 Suporte

Se encontrar problemas durante a migração:

1. Verifique este guia completo
2. Consulte [DEPLOYMENT.md](./DEPLOYMENT.md) para troubleshooting
3. Revise [SECURITY.md](./SECURITY.md) para questões de segurança
4. Abra uma issue no repositório original (se público)

## ✅ Checklist Final

Após completar a migração:

- [ ] Repositório criado no GitHub
- [ ] Código enviado (git push)
- [ ] Secrets configurados
- [ ] GitHub Actions habilitado
- [ ] Deploy local testado
- [ ] Deploy via Actions testado
- [ ] Aplicação acessível
- [ ] Documentação atualizada
- [ ] Team notificado

---

**Boa sorte com seu novo repositório! 🚀**

**Data da criação deste guia:** 4 de novembro de 2025
