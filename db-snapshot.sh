#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SERVICO_MYSQL="mysql"
PASTA_DADOS="$SCRIPT_DIR/data/mysql"
PASTA_MOLDE="$SCRIPT_DIR/data/mysql-copy"
STOP_TIMEOUT=300
START_TIMEOUT=180
COMPOSE=(docker compose --project-directory "$SCRIPT_DIR" -f "$SCRIPT_DIR/docker-compose.yaml")

SERVICE_STOPPED=0
RESTART_ON_EXIT=0
SNAPSHOT_STAGING=""

erro() {
    printf 'Erro: %s\n' "$*" >&2
}

tem_arquivos() {
    [[ -d "$1" ]] && [[ -n "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit)" ]]
}

aguardar_mysql() {
    local container_id status deadline

    container_id="$("${COMPOSE[@]}" ps -q "$SERVICO_MYSQL")"
    if [[ -z "$container_id" ]]; then
        erro "o container do serviço '$SERVICO_MYSQL' não foi encontrado."
        return 1
    fi

    deadline=$((SECONDS + START_TIMEOUT))
    while (( SECONDS < deadline )); do
        if ! status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null)"; then
            erro "não foi possível verificar o estado do container MySQL."
            return 1
        fi

        case "$status" in
            healthy|running)
                return 0
                ;;
            unhealthy|exited|dead)
                erro "o MySQL iniciou, mas seu estado é '$status'."
                return 1
                ;;
        esac

        sleep 2
    done

    erro "o MySQL não ficou saudável em até ${START_TIMEOUT}s."
    return 1
}

iniciar_mysql() {
    printf "Iniciando o serviço '%s'...\n" "$SERVICO_MYSQL"
    "${COMPOSE[@]}" start "$SERVICO_MYSQL" || return 1
    aguardar_mysql
}

finalizar() {
    local status=$?
    trap - EXIT

    if (( SERVICE_STOPPED && RESTART_ON_EXIT )); then
        printf "A operação falhou; tentando iniciar o MySQL sem alterar os dados originais...\n" >&2
        if iniciar_mysql; then
            SERVICE_STOPPED=0
        else
            erro "não foi possível iniciar o MySQL automaticamente."
        fi
    fi

    if [[ -n "$SNAPSHOT_STAGING" && -d "$SNAPSHOT_STAGING" ]]; then
        if ! rm -rf -- "$SNAPSHOT_STAGING"; then
            erro "não foi possível remover a pasta temporária '$SNAPSHOT_STAGING'."
        fi
    fi

    exit "$status"
}

uso() {
    cat <<EOF
Uso: $0 [criar|restaurar]

  criar      Cria ou atualiza o snapshot em data/mysql-copy
  restaurar  Restaura data/mysql a partir do snapshot (sobrescreve arquivos)
EOF
}

case "${1:-}" in
    criar|restaurar)
        ACAO="$1"
        ;;
    *)
        uso
        exit 1
        ;;
esac

if (($# != 1)); then
    uso
    exit 1
fi

for comando in rsync find sudo docker mktemp mv rm date; do
    if ! command -v "$comando" >/dev/null 2>&1; then
        erro "'$comando' não está instalado ou não está no PATH."
        exit 1
    fi
done

if [[ ! -f "$SCRIPT_DIR/docker-compose.yaml" ]]; then
    erro "arquivo docker-compose.yaml não encontrado em '$SCRIPT_DIR'."
    exit 1
fi

if ! "${COMPOSE[@]}" version >/dev/null 2>&1; then
    erro "Docker Compose não está disponível."
    exit 1
fi

if [[ ! -d "$PASTA_DADOS" || -L "$PASTA_DADOS" ]]; then
    erro "o diretório de dados '$PASTA_DADOS' não existe ou é um link simbólico."
    exit 1
fi

if [[ -L "$PASTA_MOLDE" ]]; then
    erro "o diretório do snapshot '$PASTA_MOLDE' não pode ser um link simbólico."
    exit 1
fi

if [[ "$ACAO" == "criar" ]]; then
    if ! tem_arquivos "$PASTA_DADOS"; then
        erro "o diretório de dados está vazio; snapshot não criado."
        exit 1
    fi
else
    if ! tem_arquivos "$PASTA_MOLDE"; then
        erro "snapshot inexistente ou vazio em '$PASTA_MOLDE'."
        exit 1
    fi

    printf "ATENÇÃO: isto substituirá os arquivos em:\n  %s\npelos arquivos do snapshot:\n  %s\n" \
        "$PASTA_DADOS" "$PASTA_MOLDE"
    read -r -p "Para continuar, digite RESTAURAR: " confirmacao
    if [[ "$confirmacao" != "RESTAURAR" ]]; then
        printf "Restauração cancelada; nenhum arquivo do banco foi alterado.\n"
        exit 1
    fi
fi

if ! sudo -v; then
    erro "não foi possível obter privilégios para preservar proprietário e permissões."
    exit 1
fi

if [[ "$ACAO" == "criar" ]]; then
    RESTART_ON_EXIT=1
fi
trap finalizar EXIT

printf "Parando o serviço '%s' (limite de %ss)...\n" "$SERVICO_MYSQL" "$STOP_TIMEOUT"
SERVICE_STOPPED=1
if ! "${COMPOSE[@]}" stop --timeout "$STOP_TIMEOUT" "$SERVICO_MYSQL"; then
    erro "não foi possível parar o MySQL; a cópia não será executada."
    exit 1
fi

if [[ "$ACAO" == "criar" ]]; then
    SNAPSHOT_STAGING="$(mktemp -d "$SCRIPT_DIR/data/.mysql-copy.tmp.XXXXXX")"
    printf "Criando snapshot temporário em '%s'...\n" "$SNAPSHOT_STAGING"

    if [[ -d "$PASTA_MOLDE" ]]; then
        if ! sudo rsync -aHAXS --numeric-ids --delete-delay --info=progress2 \
            --link-dest="$PASTA_MOLDE" "$PASTA_DADOS/" "$SNAPSHOT_STAGING/"; then
            erro "falha ao criar o snapshot temporário; o snapshot anterior foi mantido."
            exit 1
        fi
    elif ! sudo rsync -aHAXS --numeric-ids --delete-delay --info=progress2 \
        "$PASTA_DADOS/" "$SNAPSHOT_STAGING/"; then
        erro "falha ao criar o snapshot. O MySQL será reiniciado; verifique a cópia antes de restaurá-la."
        exit 1
    fi

    if ! tem_arquivos "$SNAPSHOT_STAGING"; then
        erro "o snapshot temporário ficou vazio; o snapshot anterior foi mantido."
        exit 1
    fi

    if [[ -d "$PASTA_MOLDE" ]]; then
        SNAPSHOT_ANTERIOR="$SCRIPT_DIR/data/mysql-copy.previous.$(date +%Y%m%d%H%M%S).$$"
        if ! mv -- "$PASTA_MOLDE" "$SNAPSHOT_ANTERIOR"; then
            erro "não foi possível preservar o snapshot anterior; a publicação foi cancelada."
            exit 1
        fi
        if ! mv -- "$SNAPSHOT_STAGING" "$PASTA_MOLDE"; then
            if ! mv -- "$SNAPSHOT_ANTERIOR" "$PASTA_MOLDE"; then
                erro "não foi possível publicar o novo snapshot nem restaurar o caminho do anterior ('$SNAPSHOT_ANTERIOR')."
            else
                erro "não foi possível publicar o novo snapshot; o anterior foi restaurado."
            fi
            exit 1
        fi
    elif ! mv -- "$SNAPSHOT_STAGING" "$PASTA_MOLDE"; then
        erro "não foi possível publicar o novo snapshot."
        exit 1
    fi
    SNAPSHOT_STAGING=""
    printf "Snapshot criado com sucesso.\n"
else
    printf "Restaurando arquivos do snapshot em '%s'...\n" "$PASTA_DADOS"
    if ! sudo rsync -aHAXS --numeric-ids --delete-delay --info=progress2 \
        "$PASTA_MOLDE/" "$PASTA_DADOS/"; then
        erro "falha na restauração. O MySQL permanecerá parado; execute a restauração novamente antes de iniciá-lo."
        exit 1
    fi
    printf "Arquivos restaurados com sucesso.\n"
fi

if ! iniciar_mysql; then
    erro "a cópia terminou, mas o MySQL não ficou saudável; verifique o serviço antes de continuar."
    exit 1
fi

SERVICE_STOPPED=0
RESTART_ON_EXIT=0
printf "Serviço MySQL iniciado e saudável.\n"
