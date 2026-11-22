services:
  # 1. Proxy Reverso HTTP/HTTPS (Nginx)
  nginx:
    image: nginx:alpine
    container_name: ojs_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
      - type: bind
        source: ./data/public
        target: /var/www/html/public
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

  # 2. Aplicação OJS 3.5 Endurecida (Read-Only + tmpfs + Secrets + cgroups)
  ojs:
    build:
      context: ./ojs
      dockerfile: Dockerfile
    container_name: ojs_app
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

    # Bind mounts isolados (rprivate) + Secret para o config.inc.php
    volumes:
      - type: bind
        source: ./data/files
        target: /var/www/files
        bind:
          propagation: rprivate
      - type: bind
        source: ./data/public
        target: /var/www/html/public
        bind:
          propagation: rprivate
    secrets:
      - source: ojs_config_php
        target: /var/www/html/config.inc.php
        uid: "100"
        gid: "101"
        mode: 0440
    environment:
      OJS_CLI_INSTALL: "0"
      SERVERNAME: "periodicos.sua-instituicao.edu.br"
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

  # 3. Banco de Dados MariaDB (Isolado + Secrets + Limites)
  db:
    image: mariadb:10.11
    container_name: ojs_db
    restart: unless-stopped
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - SETUID
      - SETGID
    security_opt:
      - no-new-privileges:true
    deploy:
      resources:
        limits:
          cpus: "2.0"
          memory: 2G
          pids: 200
    secrets:
      - db_root_password
      - db_password
    environment:
      MARIADB_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MARIADB_DATABASE: ${DB_NAME}
      MARIADB_USER: ${DB_USER}
      MARIADB_PASSWORD_FILE: /run/secrets/db_password
    command: >
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb-buffer-pool-size=1G
      --max-allowed-packet=64M
    volumes:
      - type: bind
        source: ./data/db
        target: /var/lib/mysql
        bind:
          propagation: rprivate
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ojs_backend

secrets:
  ojs_config_php:
    file: ./secrets/config.inc.php
  db_root_password:
    file: ./secrets/db_root_password.txt
  db_password:
    file: ./secrets/db_password.txt

networks:
  ojs_frontend:
    driver: bridge
  ojs_backend:
    driver: bridge
    internal: true
