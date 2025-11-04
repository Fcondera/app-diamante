# 🔒 Política de Segurança

## Visão Geral

Este documento descreve as práticas de segurança implementadas no projeto Jewelry App e recomendações para manter a segurança da aplicação na AWS.

## 🛡️ Implementações de Segurança

### 1. Infraestrutura (IaC)

#### VPC e Network Security
- ✅ VPC isolada com CIDR dedicado (10.0.0.0/16)
- ✅ Subnet pública com controle de acesso
- ✅ Internet Gateway configurado corretamente
- ✅ Route Tables com rotas específicas

#### Security Groups
- ✅ Regras de entrada (Ingress) restritas:
  - SSH (22): Acesso administrativo
  - HTTP (8080): Aplicação web
- ✅ Regras de saída (Egress) controladas
- ✅ Princípio do menor privilégio aplicado

#### IAM (Identity and Access Management)
- ✅ IAM Role específica para EC2
- ✅ Instance Profile configurado
- ✅ Políticas com permissões mínimas necessárias
- ✅ CloudWatch Logs habilitado para auditoria

#### Criptografia
- ✅ Volume EBS criptografado
- ✅ Terraform State com criptografia (S3)
- ✅ Chaves SSH com 4096 bits RSA

### 2. Gerenciamento de Credenciais

#### ⚠️ NUNCA COMMITE:
- Chaves SSH privadas
- Credenciais AWS
- Arquivos .tfvars com dados sensíveis
- Tokens ou passwords

#### ✅ Boas Práticas:
- Use AWS Secrets Manager para credenciais
- Use GitHub Secrets para CI/CD
- Rotacione credenciais regularmente
- Use AWS IAM Roles sempre que possível

### 3. Acesso SSH

```bash
# Gerar chave SSH segura
ssh-keygen -t rsa -b 4096 -f .ssh/id_rsa -C "jewelry-app"

# Permissões corretas
chmod 600 .ssh/id_rsa
chmod 644 .ssh/id_rsa.pub
```

## 🚨 Melhorias Recomendadas

### Alta Prioridade

1. **Restringir SSH por IP**
   ```hcl
   # No main.tf, alterar:
   cidr_blocks = ["SEU_IP/32"]  # Em vez de 0.0.0.0/0
   ```

2. **Implementar AWS Systems Manager (SSM)**
   - Elimina necessidade de SSH direto
   - Auditoria completa de sessões
   - Sem necessidade de chaves

3. **Adicionar HTTPS**
   ```bash
   # Usar AWS Certificate Manager + Application Load Balancer
   ```

4. **Implementar WAF (Web Application Firewall)**
   - Proteção contra OWASP Top 10
   - Rate limiting
   - Proteção DDoS

### Média Prioridade

5. **CloudWatch Alarms**
   - CPU > 80%
   - Disk usage > 80%
   - Failed login attempts
   - Network anomalies

6. **AWS Config**
   - Compliance monitoring
   - Configuration history
   - Automatic remediation

7. **VPC Flow Logs**
   - Auditoria de tráfego de rede
   - Detecção de anomalias
   - Troubleshooting

8. **Backup Automatizado**
   - AWS Backup ou snapshots automáticos
   - Retention policy definida
   - Testes de restore regulares

### Baixa Prioridade

9. **Multi-AZ Deployment**
   - Alta disponibilidade
   - Disaster recovery

10. **AWS GuardDuty**
    - Threat detection
    - Intelligent security monitoring

## 🔍 Auditoria e Compliance

### Logs Habilitados
- ✅ CloudWatch Logs (aplicação)
- ✅ User Data execution logs
- ✅ Docker container logs
- ⚠️ VPC Flow Logs (recomendado)
- ⚠️ CloudTrail (recomendado)

### Verificação de Segurança

```bash
# Scan de vulnerabilidades (local)
trivy config .

# Scan de IaC
tfsec .

# Scan de container
trivy image jewelry-app
```

## 📋 Checklist de Segurança

Antes de ir para produção:

- [ ] SSH restrito a IPs específicos
- [ ] Credenciais AWS configuradas via IAM Role
- [ ] HTTPS configurado com certificado válido
- [ ] WAF ativado
- [ ] CloudWatch Alarms configurados
- [ ] Backup automatizado configurado
- [ ] VPC Flow Logs habilitado
- [ ] CloudTrail habilitado
- [ ] Testes de penetração realizados
- [ ] Política de rotação de credenciais definida
- [ ] Plano de resposta a incidentes documentado

## 🚨 Resposta a Incidentes

### Em caso de comprometimento:

1. **Isolar a instância**
   ```bash
   aws ec2 modify-instance-attribute --instance-id <ID> \
     --groups sg-isolated
   ```

2. **Criar snapshot para análise forense**
   ```bash
   aws ec2 create-snapshot --volume-id <ID> \
     --description "Forensic analysis"
   ```

3. **Rotacionar todas as credenciais**
   - AWS Access Keys
   - SSH Keys
   - Database passwords

4. **Revisar logs**
   - CloudWatch Logs
   - VPC Flow Logs
   - CloudTrail

5. **Notificar stakeholders**

## 📞 Reportar Vulnerabilidades

Se você encontrar uma vulnerabilidade de segurança:

1. **NÃO** abra uma issue pública
2. Envie um email para: security@jewelry-app.com
3. Inclua:
   - Descrição detalhada
   - Passos para reproduzir
   - Impacto potencial
   - Sugestões de correção (se houver)

## 🔄 Revisão de Segurança

Este documento deve ser revisado:
- ✅ Mensalmente
- ✅ Após cada incidente
- ✅ Após mudanças significativas na infraestrutura
- ✅ Anualmente (auditoria completa)

## 📚 Recursos Adicionais

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Terraform Security](https://www.terraform.io/docs/language/state/sensitive-data.html)

---

**Última atualização:** Novembro 2025  
**Responsável:** DevOps Team
