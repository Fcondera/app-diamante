.PHONY: help init plan apply destroy build deploy clean docker-build docker-run aws-deploy aws-destroy ssh-keygen validate

default: help

help:
	@echo "Comandos disponíveis:"
	@echo "  make ssh-keygen    - Gerar chave SSH (necessário antes do deploy)"
	@echo "  make init          - Inicializar Terraform"
	@echo "  make validate      - Validar configuração Terraform"
	@echo "  make plan          - Planejar mudanças na infraestrutura"
	@echo "  make apply         - Aplicar infraestrutura na AWS"
	@echo "  make aws-deploy    - Deploy completo (build + infraestrutura)"
	@echo "  make destroy       - Destruir infraestrutura AWS"
	@echo "  make docker-build  - Build local da imagem Docker"
	@echo "  make docker-run    - Executar aplicação localmente"
	@echo "  make clean         - Limpar arquivos temporários"

ssh-keygen:
	@if not exist .ssh mkdir .ssh
	@if not exist .ssh\id_rsa (ssh-keygen -t rsa -b 4096 -f .ssh/id_rsa -N "" -C "jewelry-app-aws") else (echo Chave SSH já existe)

init:
	terraform init

validate: init
	terraform validate
	terraform fmt -check

plan: validate
	terraform plan

apply: validate
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

build:
	npm install
	npm run build

deploy: build apply
	@echo "Aguarde alguns minutos para a aplicação inicializar..."
	@timeout /t 60 /nobreak
	@terraform output -raw app_url

docker-build:
	docker build -t jewelry-app .

docker-run: docker-build
	docker run -d -p 8080:80 --name jewelry-app jewelry-app
	@echo "Aplicação rodando em http://localhost:8080"

clean:
	@if exist node_modules rmdir /s /q node_modules
	@if exist dist rmdir /s /q dist
	@if exist .terraform rmdir /s /q .terraform
	@if exist terraform.tfstate del terraform.tfstate*
	@if exist .terraform.lock.hcl del .terraform.lock.hcl

aws-deploy: ssh-keygen apply
	@echo "======================================"
	@echo "Deploy concluído!"
	@echo "Aguarde 2-3 minutos para a aplicação inicializar..."
	@echo "======================================"
	@terraform output app_url
	@echo "======================================"
	@echo "Para conectar via SSH:"
	@terraform output ssh_command
	@echo "======================================"

aws-destroy:
	terraform destroy -auto-approve
	@echo "Infraestrutura destruída com sucesso!"
