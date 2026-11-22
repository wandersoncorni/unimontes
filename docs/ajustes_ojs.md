# Configuração do portal

Estas são configurações recomendadas pelo PKP/OJS para segurança da instalação OJS.

## 1. Hardening e Segurança no `config.inc.php` (OJS 3.5)

O OJS 3.5 utiliza componentes do ecossistema Laravel que exigem parâmetros específicos de criptografia e restrição de host:

```ini
[general]
app_key = "base64:GERE_UMA_CHAVE_ALEATORIA_DE_32_BYTES"
allowed_hosts = '["periodicos.sua-instituicao.edu.br"]'

[security]
force_ssl = On
cipher = "AES-256-CBC"
cookie_encryption = On
salt = "sua-string-aleatoria-longa-aqui"
api_key_secret = "outra-string-aleatoria-longa-aqui"
session_check_ip = On
session_lifetime = 30

[debug]
show_stacktrace = Off
display_errors = Off
deprecation_warnings = Off
```

### Checklist Adicional de Segurança na Interface e Servidor
* **Diretório `files_dir` fora da raiz web:** Nunca mapeie `/var/www/files` dentro de `/var/www/html`.
* **Permissões restritas:** `.env` e `config.inc.php` devem ter permissão `600` ou `640` e serem montados como somente leitura (`:ro`) no contêiner.
* **Novo Sistema de Convites (OJS 3.5):** Mantenha ativo o fluxo nativo de convite com aceite para novos editores/avaliadores e restrinja o auto-registro aberto onde não for necessário.
* **Limpeza de Plugins:** Desinstale completamente plugins de terceiros não homologados para o OJS 3.5.