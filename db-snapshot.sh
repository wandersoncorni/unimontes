cat << 'EOF' > db-snapshot.sh
#!/bin/bash

# --- CONFIGURAÇÕES (Ajuste os nomes se necessário) ---
SERVICO_MYSQL="mysql"
PASTA_DADOS="./data/mysql"
PASTA_MOLDE="./data/mysql-copy"

# Verifica se o rsync está instalado
if ! command -v rsync &> /dev/null; then
    echo "Erro: O 'rsync' não está instalado. Instale com: sudo apt install rsync"
    exit 1
fi

case "$1" in
    criar)
        if [ ! -d "$PASTA_DADOS" ]; then
            echo "Erro: A pasta '$PASTA_DADOS' não foi encontrada."
            exit 1
        fi

        echo "1/3 Parando o serviço '$SERVICO_MYSQL'..."
        docker compose stop "$SERVICO_MYSQL"

        echo "2/3 Criando snapshot (molde) em '$PASTA_MOLDE'..."
        sudo rsync -a --delete --info=progress2 "$PASTA_DADOS/" "$PASTA_MOLDE/"

        echo "3/3 Iniciando o serviço '$SERVICO_MYSQL'..."
        docker compose start "$SERVICO_MYSQL"
        echo "✅ Snapshot criado com sucesso!"
        ;;

    restaurar)
        if [ ! -d "$PASTA_MOLDE" ]; then
            echo "Erro: Nenhum snapshot encontrado em '$PASTA_MOLDE'. Rode './db-snapshot.sh criar' primeiro."
            exit 1
        fi

        echo "1/3 Parando o serviço '$SERVICO_MYSQL'..."
        docker compose stop "$SERVICO_MYSQL"

        echo "2/3 Restaurando apenas os arquivos alterados (isso será rápido)..."
        sudo rsync -a --delete --info=progress2 "$PASTA_MOLDE/" "$PASTA_DADOS/"

        echo "3/3 Iniciando o serviço '$SERVICO_MYSQL'..."
        docker compose start "$SERVICO_MYSQL"
        echo "✅ Banco restaurado para o estado do snapshot!"
        ;;

    *)
        echo "Uso: ./db-snapshot.sh [opcao]"
        echo ""
        echo "Opções disponíveis:"
        echo "  criar      Cria ou atualiza o snapshot a partir do banco atual"
        echo "  restaurar  Restaura o banco para o estado salvo no snapshot"
        exit 1
        ;;
esac
EOF

chmod +x db-snapshot.sh
