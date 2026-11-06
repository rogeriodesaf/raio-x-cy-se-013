#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export LC_ALL=C

: "${REPO:?Informe o repositório de teste no registry (sem tag).}"
: "${IDENTIDADE:?Informe a identidade exata do certificado Sigstore.}"
: "${EMISSOR:?Informe o emissor OIDC, por exemplo https://accounts.google.com.}"

if [[ ! -s resultados/local/id-original.txt ]] ||
   [[ $(docker image inspect --format '{{.Id}}' raio-x:original) != "$(cat resultados/local/id-original.txt)" ]]; then
    echo 'Execute ./demonstrar.sh para vincular a imagem original à análise local.' >&2
    exit 1
fi

./gate.sh raio-x:original
./gate.sh raio-x:alterada
mkdir -p resultados
saida=$(mktemp -d "resultados/keyless-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")
execucao=${saida##*/}
echo "Evidências desta execução: $saida"

publicar() {
    local variante=$1 tag digest
    tag="$REPO:$execucao-$variante"
    docker tag "raio-x:$variante" "$tag"
    docker push "$tag" | tee "$saida/push-$variante.txt" >&2
    digest=$(awk '$2 == "digest:" && $3 ~ /^sha256:/ {print $3}' "$saida/push-$variante.txt")
    [[ $digest =~ ^sha256:[0-9a-f]{64}$ ]] || return 1
    printf '%s@%s\n' "$REPO" "$digest"
}

original=$(publicar original)
alterada=$(publicar alterada)
[[ $original != "$alterada" ]]

{
    date -u +%FT%TZ
    cosign version
    printf 'Identidade esperada: %s\nEmissor OIDC: %s\n' "$IDENTIDADE" "$EMISSOR"
    printf 'Original: %s\nAlterada: %s\n' "$original" "$alterada"
    docker image inspect --format '{{join .RepoTags ","}} {{.Id}}' raio-x:original raio-x:alterada
} > "$saida/referencias.txt"

# A autorização interativa via OIDC é feita pela pessoa que executa o teste.
cosign sign --oidc-disable-ambient-providers --bundle "$saida/assinatura.sigstore.json" "$original"

verificar() {
    cosign verify --certificate-identity "$IDENTIDADE" \
        --certificate-oidc-issuer "$EMISSOR" "$1"
}

verificar "$original" > "$saida/verificacao-original.json" 2> "$saida/verificacao-original.log"

if verificar "$alterada" > "$saida/verificacao-alterada.json" 2> "$saida/verificacao-alterada.log"; then
    echo 'A variante foi aceita. A demonstração falhou.' >&2
    exit 1
else
    codigo=$?
fi

printf 'Verificação da original: 0\nVerificação da alterada: %s\n' "$codigo" |
    tee "$saida/status.txt"
cat "$saida/verificacao-alterada.log"
if ! grep -Eiq 'no signatures found|no matching signatures|no bundles found|no valid signatures|no valid attestations|no matching attestations|no referrers found|no acceptable attestations' "$saida/verificacao-alterada.log"; then
    echo 'A causa da falha precisa ser verificada no log antes de concluir.' >&2
    exit 1
fi
