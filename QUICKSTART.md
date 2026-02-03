# Guia Rápido de Instalação e Uso
# Quick Installation and Usage Guide

## Instalação Rápida / Quick Installation

### 1. Clone o Repositório / Clone the Repository
```bash
git clone https://github.com/6xll/SC.git
cd SC
```

### 2. Execute o Setup / Run Setup
```bash
./scripts/setup.sh
```

### 3. Configure (Opcional) / Configure (Optional)
```bash
nano config/email_scanner.conf
```

### 4. Teste o Sistema / Test the System
```bash
# Processar emails de exemplo / Process sample emails
./scripts/process_emails.sh

# Ver status / View status
./scripts/status.sh
```

## Uso Diário / Daily Usage

### Adicionar Emails para Processamento / Add Emails for Processing
```bash
# Copiar emails para a pasta inbox / Copy emails to inbox folder
cp meu_email.eml inbox/

# Ou mover / Or move
mv meu_email.eml inbox/
```

### Processar Manualmente / Process Manually
```bash
./scripts/process_emails.sh
```

### Ver Status do Sistema / View System Status
```bash
./scripts/status.sh
```

### Ver Logs / View Logs
```bash
# Ver últimas linhas / View last lines
tail -20 logs/email_scanner.log

# Monitorar em tempo real / Monitor in real-time
tail -f logs/email_scanner.log
```

### Verificar Arquivos / Check Files
```bash
# Arquivos limpos / Clean files
ls -lh clean/

# Arquivos infectados / Infected files
ls -lh infected/

# Arquivos em quarentena / Quarantined files
ls -lh quarantine/
```

## Configuração do Cron / Cron Setup

### Editar Crontab / Edit Crontab
```bash
crontab -e
```

### Adicionar Linha (Exemplo) / Add Line (Example)
```bash
# Executar a cada 10 minutos / Run every 10 minutes
*/10 * * * * /caminho/completo/para/SC/scripts/process_emails.sh >> /caminho/completo/para/SC/logs/cron.log 2>&1
```

### Verificar Cron Ativo / Verify Active Cron
```bash
crontab -l
```

## Modos de Análise / Analysis Modes

### 1. Cuckoo Sandbox
```bash
# Editar config / Edit config
nano config/email_scanner.conf

# Configurar / Configure
CUCKOO_ENABLED="true"
CUCKOO_API_URL="http://localhost:8090"
CUCKOO_API_TOKEN="seu_token_aqui"
```

### 2. ClamAV
```bash
# Instalar ClamAV / Install ClamAV
sudo apt-get install clamav clamav-daemon
sudo freshclam

# Configurar / Configure
FALLBACK_MODE="clamav"
```

### 3. Modo Hash (Verificação de Hash Conhecido) / Hash Mode
```bash
FALLBACK_MODE="hash"
```

### 4. Modo Simulação (Para Testes) / Simulation Mode
```bash
FALLBACK_MODE="simulate"
```

## Solução de Problemas / Troubleshooting

### Script não executa / Script doesn't run
```bash
chmod +x scripts/*.sh
```

### ClamAV não funciona / ClamAV doesn't work
```bash
sudo apt-get install clamav clamav-daemon
sudo freshclam
sudo systemctl start clamav-daemon
```

### Cuckoo não conecta / Cuckoo doesn't connect
```bash
# Verificar se Cuckoo está rodando / Check if Cuckoo is running
curl http://localhost:8090/cuckoo/status

# Verificar configuração / Check configuration
cat config/email_scanner.conf | grep CUCKOO
```

### Anexos não são extraídos / Attachments not extracted
```bash
# Instalar mpack / Install mpack
sudo apt-get install mpack
```

## Estrutura de Arquivos / File Structure
```
SC/
├── inbox/           ← Coloque emails aqui / Put emails here
├── clean/           ← Arquivos limpos / Clean files
├── infected/        ← Arquivos infectados / Infected files
├── quarantine/      ← Arquivos suspeitos / Suspicious files
├── processed/       ← Emails processados / Processed emails
├── logs/            ← Logs do sistema / System logs
├── config/          ← Configurações / Configuration
│   ├── email_scanner.conf
│   └── cron_config.txt
└── scripts/         ← Scripts
    ├── process_emails.sh
    ├── setup.sh
    └── status.sh
```

## Recursos Adicionais / Additional Resources

- README completo: `README.md`
- Configuração: `config/email_scanner.conf`
- Exemplos de Cron: `config/cron_config.txt`
- Cuckoo Sandbox: https://cuckoosandbox.org/
- ClamAV: https://www.clamav.net/
- EICAR Test File: https://www.eicar.org/

## Segurança / Security

⚠️ **IMPORTANTE / IMPORTANT:**
- Execute em ambiente isolado / Run in isolated environment
- Não execute arquivos da pasta `infected/` / Don't run files from `infected/`
- Revise arquivos em `quarantine/` antes de usar / Review files in `quarantine/` before using
- Mantenha backups / Keep backups
- Use senhas fortes para Cuckoo API / Use strong passwords for Cuckoo API

## Comandos Úteis / Useful Commands

```bash
# Status completo / Full status
./scripts/status.sh

# Processar emails / Process emails
./scripts/process_emails.sh

# Setup inicial / Initial setup
./scripts/setup.sh

# Limpar arquivos processados / Clean processed files
rm -rf processed/* clean/* infected/* quarantine/*

# Ver últimos logs / View recent logs
tail -50 logs/email_scanner.log

# Contar emails pendentes / Count pending emails
ls -1 inbox/ | wc -l

# Buscar nos logs / Search logs
grep "WARN" logs/email_scanner.log
grep "infected" logs/email_scanner.log
```

## Suporte / Support

Para questões e suporte:
- Repository: https://github.com/6xll/SC
- Issues: https://github.com/6xll/SC/issues
