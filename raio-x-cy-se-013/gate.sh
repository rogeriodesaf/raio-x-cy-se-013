#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ $# != 1 ]]; then
    printf 'Uso: %s IMAGEM_LOCAL\n' "$0" >&2
    exit 2
fi

decisao=$(
    docker image inspect --format '{{json .Config.User}}' "$1" |
        jq '{user: .}' |
        opa eval --stdin-input --data policy/container.rego --format raw \
            'data.projeto.container.allow'
)
printf '%s\n' "$decisao"
case "$decisao" in
    true) exit 0 ;;
    false) exit 10 ;;
    *) exit 2 ;;
esac
