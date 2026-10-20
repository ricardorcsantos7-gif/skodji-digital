
#!/bin/bash

# SKODJI DIGITAL - Laboratorio 7
# Backup comprimido, cifrado e automatizado

set -o pipefail
umask 077

ORIGEM="$HOME/empresa"
DESTINO="$HOME/backups"
PASS_FILE="$HOME/.backup_pass"
LOG="$DESTINO/backup.log"
DATA=$(date +%Y-%m-%d_%H%M%S)
NOME="backup_empresa_$DATA"

mkdir -p "$DESTINO" || exit 1

if [ ! -d "$ORIGEM" ]; then
    echo "ERRO: pasta de origem nao encontrada: $ORIGEM" |
        tee -a "$LOG"
    exit 1
fi

if [ ! -f "$PASS_FILE" ]; then
    echo "ERRO: ficheiro de password nao encontrado." |
        tee -a "$LOG"
    exit 1
fi

if [ ! -s "$PASS_FILE" ]; then
    echo "ERRO: ficheiro de password vazio." |
        tee -a "$LOG"
    exit 1
fi

TEMP="$DESTINO/$NOME.tar.gz"
CIFRADO="$DESTINO/$NOME.tar.gz.enc"

if tar -czf "$TEMP" -C "$HOME" empresa; then
    if openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$TEMP" \
        -out "$CIFRADO" \
        -pass "file:$PASS_FILE"; then

        rm -f "$TEMP"
        chmod 600 "$CIFRADO"
        echo "[$(date '+%F %T')] SUCESSO: $CIFRADO" |
            tee -a "$LOG"
    else
        rm -f "$CIFRADO"
        echo "[$(date '+%F %T')] ERRO: falha na cifragem." |
            tee -a "$LOG"
        rm -f "$TEMP"
        exit 1
    fi
else
    rm -f "$TEMP"
    echo "[$(date '+%F %T')] ERRO: falha na compressao." |
        tee -a "$LOG"
    exit 1
fi

