# Arquitetura OJS 3.5 em Produção com Docker Compose, Segurança, Backup e Observabilidade

Este guia consolida a arquitetura completa para rodar o **Open Journal Systems (OJS) 3.5** em produção de forma segura, imutável e resiliente, separando Proxy Reverso (Nginx), Aplicação (OJS), Banco de Dados (MariaDB), Backup Off-site e Observabilidade.

---

## 1. Estrutura de Diretórios no Servidor

```text
/opt/ojs-portal/
├── .env                        # Senhas e variáveis sensíveis (permissão 600)
├── docker-compose.yml          # Orquestração dos serviços principais
├── docker-compose.monitoring.yml # Stack de observabilidade (Uptime Kuma, Prometheus, Grafana)
├── backup-ojs.sh               # Script automatizado de backup completo e imutável
├── ojs/
│   ├── Dockerfile              # Personalização leve sobre a imagem oficial do PKP
│   ├── php-custom.ini          # Ajustes de limite de upload, memória e hardening PHP
│   └── config.inc.php.example  # Modelo de configuração de segurança do OJS 3.5
├── nginx/
│   ├── nginx.conf              # Regras de segurança, SSL, headers e rate limiting
│   └── certs/                  # Certificados SSL (fullchain.pem / privkey.pem)
├── monitoring/
│   └── prometheus.yml          # Configuração de coleta de métricas (cAdvisor)
└── data/                       # Volumes persistentes (fora da raiz web)
    ├── files/                  # files_dir (manuscritos privados)
    ├── public/                 # Capas, logos e CSS das revistas
    └── monitoring/             # Dados do Uptime Kuma, Prometheus e Grafana
```
---

## 2. Criando a estrutura de diretórios e arquivos

Cria toda a árvore de diretórios e arquivos base com as permissões adequadas para produção e segurança do OJS.

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/opt/ojs-portal"

# Garante que o script seja executado como root (necessário para criar em /opt e ajustar donos)
if [[ $EUID -ne 0 ]]; then
   echo "Erro: Execute este script como root ou via sudo." >&2
   exit 1
fi

echo "Criando estrutura de diretórios em ${BASE_DIR}..."

# 1. Criação de todos os diretórios
mkdir -p "${BASE_DIR}"/{ojs,nginx/certs,monitoring,data/{files,public,db,monitoring}}

# 2. Criação dos arquivos base (caso ainda não existam)
touch "${BASE_DIR}/.env"
touch "${BASE_DIR}/docker-compose.yml"
touch "${BASE_DIR}/docker-compose.monitoring.yml"
touch "${BASE_DIR}/backup-ojs.sh"

touch "${BASE_DIR}/ojs/Dockerfile"
touch "${BASE_DIR}/ojs/php-custom.ini"
touch "${BASE_DIR}/ojs/config.inc.php.example"

touch "${BASE_DIR}/nginx/nginx.conf"
touch "${BASE_DIR}/monitoring/prometheus.yml"

# 3. Ajuste de propriedade (Owner/Group)
# Define o usuário que executou o sudo (ou root) como dono da estrutura de configuração
OWNER_USER="${SUDO_USER:-root}"
chown -R "${OWNER_USER}:${OWNER_USER}" "${BASE_DIR}"

# 4. Permissões de Diretórios e Arquivos de Configuração
# Diretórios principais com acesso padrão (755)
find "${BASE_DIR}" -maxdepth 2 -type d -exec chmod 755 {} +

# Arquivos de configuração e YAML (644)
chmod 644 "${BASE_DIR}/docker-compose.yml" \
          "${BASE_DIR}/docker-compose.monitoring.yml" \
          "${BASE_DIR}/ojs/Dockerfile" \
          "${BASE_DIR}/ojs/php-custom.ini" \
          "${BASE_DIR}/ojs/config.inc.php.example" \
          "${BASE_DIR}/nginx/nginx.conf" \
          "${BASE_DIR}/monitoring/prometheus.yml"

# 5. Permissões Críticas de Segurança
# .env acessível apenas pelo dono (leitura e escrita)
chmod 600 "${BASE_DIR}/.env"

# Script de backup executável apenas pelo dono/grupo autorizado
chmod 750 "${BASE_DIR}/backup-ojs.sh"

# Diretório de certificados SSL restrito
chmod 700 "${BASE_DIR}/nginx/certs"

# 6. Permissões dos Volumes Persistentes (data/)
# O contêiner oficial do PKP/OJS roda o servidor web (Apache/PHP) sob o UID/GID 33 (www-data) ou 100 (apache)
# Ajuste o UID abaixo caso sua imagem PKP utilize UID 100 (Alpine) em vez de 33 (Debian/Ubuntu)
WEB_UID=33
WEB_GID=33

chown -R "${WEB_UID}:${WEB_GID}" "${BASE_DIR}/data/files" "${BASE_DIR}/data/public"
chmod 750 "${BASE_DIR}/data/files"   # Restrito: manuscritos privados fora da web
chmod 755 "${BASE_DIR}/data/public"  # Público: capas, logos e CSS

# Monitoramento (Grafana usa 472, Prometheus 65534; 775 ou subpastas específicas evitam conflito inicial)
chmod 775 "${BASE_DIR}/data/monitoring"

echo "Estrutura criada e permissões aplicadas com sucesso!"


```

Execução:
```bash
chmod +x setup-ojs-dirs.sh
sudo ./setup-ojs-dirs.sh
```
### Resumo das Permissões Aplicadas

| Caminho | Permissão | Dono (UID:GID) | Motivo |
| :--- | :--- | :--- | :--- |
| `.env` | `600` | `root` / usuário | Protege senhas do banco e chaves de API contra leitura por outros usuários. |
| `backup-ojs.sh` | `750` | `root` / usuário | Permite execução apenas por administradores. |
| `nginx/certs/` | `700` | `root` / usuário | Protege a chave privada (`privkey.pem`). |
| `data/files/` | `750` | `33:33` (`www-data`) | Isola submissões e manuscritos privados. |
| `data/public/` | `755` | `33:33` (`www-data`) | Permite leitura pública dos assets das revistas. |
| `data/db/` | `700` | `999:999` (`mysql`) | Padrão exigido pela imagem oficial do MariaDB. |

---

## 3. Configuração dos Contêineres (Docker)

### 3.1. `ojs/Dockerfile`
```dockerfile
FROM pkpojs/ojs:3_5_0-0

COPY php-custom.ini /etc/php82/conf.d/99-ojs-custom.ini

RUN chown -R apache:apache /var/www/html /var/www/files
```

### 3.2. `ojs/php-custom.ini`
```ini
upload_max_filesize = 100M
post_max_size = 105M
memory_limit = 512M
max_execution_time = 300
expose_php = Off
allow_url_include = Off
```

### 3.3. `docker-compose.yml`
```yaml
services:
  nginx:
    image: nginx:alpine
    container_name: ojs_proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
      - type: bind
        source: /srv/portal/journals
        target: /var/www/html/public/journals
        read_only: true
        bind:
          propagation: rprivate
    depends_on:
      - ojs
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
    networks:
      - ojs_frontend

  ojs:
    build:
      context: ./ojs
      dockerfile: Dockerfile
    container_name: ojs_portal
    restart: unless-stopped

    # Sistema de arquivos somente leitura + tmpfs para diretórios voláteis do Alpine/Apache/OJS
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=256m
      - /run/apache2:rw,noexec,nosuid,size=16m
      - /var/run:rw,noexec,nosuid,size=16m
      - /var/log/apache2:rw,noexec,nosuid,size=64m
      - /var/log/supervisor:rw,noexec,nosuid,size=32m
      - /var/www/html/cache:rw,noexec,nosuid,uid=100,gid=101,size=256m

    # Princípio do menor privilégio (apenas o necessário para iniciar Apache/Supervisor na imagem PKP)
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - FOWNER
      - SETUID
      - SETGID
      - NET_BIND_SERVICE

    # Impede escalonamento de privilégios
    security_opt:
      - no-new-privileges:true

    # Limites de recursos (cgroups) contra OOM e fork bombs
    deploy:
      resources:
        limits:
          cpus: "2.0"
          memory: 1536M
          pids: 250
    ulimits:
      nofile:
        soft: 2048
        hard: 4096
    
    # Bind mounts isolados (rprivate): apenas files_dir e public/journals
    volumes:
      - type: bind
        source: ./data/files
        target: /var/www/files
        bind:
          propagation: rprivate
      - type: bind
        source: ./data/journals
        target: /var/www/html/public/journals
        bind:
          propagation: rprivate

    secrets:
      - source: /opt/portal_ojs/config
        target: /var/www/html/config.inc.php
        uid: "100"
        gid: "101"
        mode: 0440

    environment:
      - OJS_DB_HOST=db
      - OJS_DB_USER=${DB_USER}
      - OJS_DB_PASSWORD=${DB_PASSWORD}
      - OJS_DB_NAME=${DB_NAME}
      - OJS_WEB_CONF=/var/www/html/config.inc.php
    volumes:
      - ./ojs/config.inc.php:/var/www/html/config.inc.php:ro
      - ./data/files:/var/www/files
      - ./data/public:/var/www/html/public
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost/index.php/index/about || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - ojs_frontend
      - ojs_backend

  db:
    image: mariadb:10.11
    container_name: ojs_db
    restart: unless-stopped
    environment:
      - MARIADB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MARIADB_DATABASE=${DB_NAME}
      - MARIADB_USER=${DB_USER}
      - MARIADB_PASSWORD=${DB_PASSWORD}
    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb-buffer-pool-size=1G
      --max-allowed-packet=64M
    volumes:
      - ojs_db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ojs_backend

networks:
  ojs_frontend:
    driver: bridge
  ojs_backend:
    driver: bridge
    internal: true
```

---

## 4. Hardening do Proxy Reverso (`nginx/nginx.conf`)

```nginx
limit_req_zone $binary_remote_addr zone=ojs_login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=ojs_geral:10m rate=10r/s;

server {
    listen 80;
    server_name periodicos.sua-instituicao.edu.br;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name periodicos.sua-instituicao.edu.br;

    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 105M;

    # Cabeçalhos de Segurança HTTP
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Bloqueia acesso direto a arquivos sensíveis
    location ~* (config\.inc\.php|\.git|\.env|composer\.(json|lock)) {
        deny all;
        return 403;
    }

    # Impede execução de scripts PHP na pasta de uploads públicos
    location ~* ^/public/.*\.php$ {
        deny all;
        return 403;
    }

    # Proteção contra força bruta na tela de login
    location ~* /login/signIn {
        limit_req zone=ojs_login burst=3 nodelay;
        proxy_pass http://ojs:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    # Proteção contra bots/scrapers e proxy geral
    location / {
        limit_req zone=ojs_geral burst=20 nodelay;
        proxy_pass http://ojs:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 300s;
    }
}
```

---

## 5. Backup Completo e Recuperação de Desastres (Disaster Recovery)

### 5.1. Script de Backup (`backup-ojs.sh`)
```bash
#!/bin/bash
set -e

PORTAL_DIR="/opt/ojs-portal"
BACKUP_ROOT="/var/backups/ojs-portal"
DATA_ATUAL=$(date +"%Y-%m-%d_%H-%M")
DESTINO="$BACKUP_ROOT/$DATA_ATUAL"

source "$PORTAL_DIR/.env"
mkdir -p "$DESTINO"

echo "[1/4] Gerando dump consistente do MariaDB..."
docker compose -f "$PORTAL_DIR/docker-compose.yml" exec -T db   mariadb-dump -u root -p"$DB_ROOT_PASSWORD"   --single-transaction --routines --triggers --events "$DB_NAME"   | gzip > "$DESTINO/banco_ojs.sql.gz"

echo "[2/4] Compactando volumes de arquivos (files e public)..."
tar -czf "$DESTINO/arquivos_dados.tar.gz" -C "$PORTAL_DIR/data" files public

echo "[3/4] Salvando arquivos de configuração da stack..."
tar -czf "$DESTINO/infra_config.tar.gz" -C "$PORTAL_DIR"   docker-compose.yml docker-compose.monitoring.yml .env ojs/ nginx/ monitoring/

echo "[4/4] Exportando imagem Docker personalizada (Snapshot imutável)..."
docker save ojs-portal-ojs:latest | gzip > "$DESTINO/imagem_ojs.tar.gz"

# Remove backups locais com mais de 7 dias
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} +

echo "Backup concluído com sucesso em: $DESTINO"
```

### 5.2. Procedimento de Restauração em Caso de Falha ou Invasão
```bash
# 1. Extrair configurações da stack
mkdir -p /opt/ojs-portal/data/db
tar -xzf infra_config.tar.gz -C /opt/ojs-portal/

# 2. Restaurar volumes de submissões e arquivos públicos
tar -xzf arquivos_dados.tar.gz -C /opt/ojs-portal/data/

# 3. Carregar imagem Docker imutável
docker load < imagem_ojs.tar.gz

# 4. Subir banco primeiro e restaurar o dump SQL
cd /opt/ojs-portal
source .env
docker compose up -d db
sleep 15
gunzip < banco_ojs.sql.gz | docker compose exec -T db mariadb -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME"

# 5. Subir restante da stack sem rebuild
docker compose up -d --no-build
```

---

## 6. Observabilidade e Monitoramento (`docker-compose.monitoring.yml`)

Os painéis ficam vinculados apenas a `127.0.0.1` e devem ser acessados via **túnel SSH** (`ssh -L 3000:localhost:3000 -L 3001:localhost:3001 usuario@servidor`) ou VPN:

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: ojs_uptime
    restart: unless-stopped
    volumes:
      - ./data/monitoring/uptime:/app/data
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "127.0.0.1:3001:3001"
    networks:
      - ojs_frontend

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: ojs_cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks:
      - ojs_monitoring

  prometheus:
    image: prom/prometheus:latest
    container_name: ojs_prometheus
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./data/monitoring/prometheus:/prometheus
    networks:
      - ojs_monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: ojs_grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - ./data/monitoring/grafana:/var/lib/grafana
    ports:
      - "127.0.0.1:3000:3000"
    networks:
      - ojs_monitoring

networks:
  ojs_frontend:
    external: true
  ojs_monitoring:
    driver: bridge
    internal: true
```

### Auditoria Diária de Integridade (FIM)
Como o contêiner `ojs_portal` é imutável, agende via cron a verificação de alterações internas:
```bash
docker diff ojs_portal
```
Qualquer arquivo `.php` novo listado nesse comando indica alteração não autorizada dentro do contêiner.
