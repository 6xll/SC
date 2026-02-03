# Email Security Scanner - Sistema de Segurança e Automação

Este projeto implementa um sistema automatizado de análise de segurança para anexos de email. O sistema extrai anexos de emails, analisa-os em busca de malware usando sandbox (Cuckoo Sandbox) ou métodos alternativos, e organiza os arquivos em pastas apropriadas.

## Funcionalidades

- ✅ **Processamento Automático de Emails**: Processa emails da caixa de entrada automaticamente
- ✅ **Extração de Anexos**: Extrai anexos de emails usando múltiplos métodos
- ✅ **Análise de Malware**: Suporta múltiplos métodos de análise:
  - Cuckoo Sandbox (recomendado)
  - ClamAV (antivírus)
  - Verificação de hash (comparação com malware conhecido)
  - Modo de simulação (para testes)
- ✅ **Organização Automática**: Move arquivos para pastas baseado no resultado:
  - `clean/` - Arquivos limpos e seguros
  - `infected/` - Arquivos infectados/maliciosos
  - `quarantine/` - Arquivos suspeitos/desconhecidos
- ✅ **Agendamento com Cron**: Execução automática em intervalos configuráveis
- ✅ **Logging Completo**: Registra todas as ações e resultados

## Estrutura do Projeto

```
SC/
├── config/
│   ├── email_scanner.conf    # Arquivo de configuração principal
│   └── cron_config.txt        # Exemplos de configuração cron
├── scripts/
│   ├── process_emails.sh      # Script principal de processamento
│   └── setup.sh               # Script de instalação/configuração
├── inbox/                     # Pasta para emails recebidos
├── clean/                     # Arquivos limpos
├── infected/                  # Arquivos infectados
├── quarantine/                # Arquivos suspeitos
├── logs/                      # Logs do sistema
├── processed/                 # Emails já processados
└── README.md                  # Este arquivo
```

## Requisitos

### Obrigatórios
- Bash 4.0 ou superior
- Sistema Linux/Unix
- `md5sum` (geralmente pré-instalado)
- `curl` (para integração com Cuckoo)

### Opcionais (mas recomendados)
- **ClamAV**: Para scanning antivírus
  ```bash
  sudo apt-get install clamav clamav-daemon
  sudo freshclam  # Atualizar definições de vírus
  ```

- **mpack**: Para melhor parsing de emails
  ```bash
  sudo apt-get install mpack
  ```

- **Cuckoo Sandbox**: Para análise avançada em sandbox
  - Instalação: https://cuckoosandbox.org/
  - Documentação: https://cuckoo.readthedocs.io/

## Instalação

### 1. Clone o Repositório
```bash
git clone https://github.com/6xll/SC.git
cd SC
```

### 2. Execute o Script de Setup
```bash
./scripts/setup.sh
```

Este script irá:
- Verificar dependências
- Criar estrutura de diretórios
- Configurar permissões

### 3. Configure o Sistema

Edite o arquivo de configuração:
```bash
nano config/email_scanner.conf
```

Principais configurações:
- `CUCKOO_ENABLED`: Habilitar/desabilitar Cuckoo Sandbox
- `CUCKOO_API_URL`: URL da API do Cuckoo
- `FALLBACK_MODE`: Método alternativo (clamav, hash, simulate)
- Ajuste os caminhos dos diretórios se necessário

### 4. Configure o Cron Job

Para executar automaticamente:
```bash
crontab -e
```

Adicione uma das linhas do arquivo `config/cron_config.txt`, por exemplo:
```bash
# Executar a cada 10 minutos
*/10 * * * * /caminho/para/SC/scripts/process_emails.sh >> /caminho/para/SC/logs/cron.log 2>&1
```

## Uso

### Execução Manual

Para processar emails manualmente:
```bash
./scripts/process_emails.sh
```

### Adicionar Emails para Processamento

1. Coloque arquivos de email (.eml) na pasta `inbox/`:
```bash
cp meu_email.eml inbox/
```

2. O sistema processará automaticamente (via cron) ou execute manualmente

### Visualizar Logs

```bash
# Log principal
tail -f logs/email_scanner.log

# Log do cron
tail -f logs/cron.log
```

## Métodos de Análise

### 1. Cuckoo Sandbox (Recomendado)
- Análise avançada em ambiente isolado
- Detecta comportamento malicioso
- Requer instalação e configuração do Cuckoo
- Configure `CUCKOO_ENABLED=true` no config

### 2. ClamAV
- Antivírus open-source
- Rápido e eficiente
- Requer instalação do ClamAV
- Configure `FALLBACK_MODE=clamav`

### 3. Verificação de Hash
- Compara MD5 do arquivo com lista de malware conhecido
- Muito rápido
- Limitado a malware conhecido
- Configure `FALLBACK_MODE=hash`

### 4. Modo Simulação
- Para testes e desenvolvimento
- Não requer ferramentas externas
- Baseado em nome de arquivo
- Configure `FALLBACK_MODE=simulate`

## Fontes de Malware para Testes

⚠️ **AVISO**: Use apenas em ambientes isolados e para fins educacionais!

- [EICAR Test File](https://www.eicar.org/download-anti-malware-testfile/)
- [Malware Sample Sources](https://zeltser.com/malware-sample-sources)
- [theZoo - Malware Database](https://github.com/ytisf/theZoo)
- [MalwareBazaar](https://bazaar.abuse.ch/)

## Exemplos de Email de Teste

O projeto inclui emails de teste na pasta `inbox/`:

1. `test_email_clean.eml` - Email com anexo limpo
2. `test_email_malware.eml` - Email com arquivo EICAR (teste de malware)

## Segurança

### Boas Práticas
- Execute o sistema em um ambiente isolado
- Use permissões apropriadas nos diretórios
- Revise regularmente os logs
- Mantenha as definições de vírus atualizadas
- Implemente backup dos arquivos importantes

### Pastas de Segurança
- `infected/`: Mantenha isolada, não execute arquivos desta pasta
- `quarantine/`: Revise manualmente antes de usar
- `clean/`: Arquivos considerados seguros

## Troubleshooting

### Problema: Script não executa
```bash
chmod +x scripts/process_emails.sh
```

### Problema: ClamAV não encontra vírus
```bash
sudo freshclam  # Atualizar definições
sudo systemctl start clamav-daemon
```

### Problema: Cuckoo não conecta
- Verifique se o Cuckoo está rodando
- Verifique a URL e token na configuração
- Teste com: `curl http://localhost:8090/cuckoo/status`

### Problema: Anexos não são extraídos
- Instale mpack: `sudo apt-get install mpack`
- Verifique formato do arquivo de email

## Logs e Monitoramento

### Estrutura dos Logs
```
[TIMESTAMP] [LEVEL] MESSAGE
```

Níveis de log:
- `INFO`: Operações normais
- `WARN`: Avisos e problemas menores
- `ERROR`: Erros críticos

### Exemplo de Log
```
[2026-02-03 10:00:00] [INFO] Email Security Scanner Started
[2026-02-03 10:00:01] [INFO] Processing email: inbox/test_email.eml
[2026-02-03 10:00:02] [INFO] Extracting attachments from: inbox/test_email.eml
[2026-02-03 10:00:03] [INFO] Scanning file: document.txt
[2026-02-03 10:00:04] [INFO] File hash (MD5): abc123...
[2026-02-03 10:00:05] [INFO] ClamAV scan clean: document.txt
[2026-02-03 10:00:06] [INFO] Moving clean file to: /path/to/clean
```

## Desenvolvimento

### Adicionar Novos Métodos de Análise

Edite `scripts/process_emails.sh` e adicione uma nova função:
```bash
scan_with_custom_method() {
    local file=$1
    # Seu código aqui
    return 0  # 0=clean, 1=infected, 2=unknown
}
```

### Adicionar Novos Hashes de Malware

Edite `config/email_scanner.conf`:
```bash
MALWARE_HASHES=(
    "hash1"
    "hash2"
    "hash3"
)
```

## Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## Licença

Este projeto é desenvolvido para fins educacionais no contexto de Segurança e Automação.

## Autores

- Desenvolvido como projeto acadêmico
- Repositório: https://github.com/6xll/SC

## Recursos Adicionais

- [Cuckoo Sandbox Documentation](https://cuckoo.readthedocs.io/)
- [ClamAV Documentation](https://docs.clamav.net/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)
- [Cron Job Tutorial](https://crontab.guru/)

## Changelog

### Versão 1.0.0 (2026-02-03)
- Implementação inicial
- Suporte para múltiplos métodos de análise
- Integração com Cuckoo Sandbox
- Suporte para ClamAV
- Sistema de logging
- Configuração via cron job
- Documentação completa
