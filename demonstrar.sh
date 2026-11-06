#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export LC_ALL=C

./preparar.sh
mkdir -p resultados/local
saida=resultados/local

docker build --platform linux/amd64 --build-arg UID_APP=0 -t raio-x:antes .
docker build --platform linux/amd64 -t raio-x:original .
docker build --platform linux/amd64 --build-arg MENSAGEM=mensagem-alterada.txt -t raio-x:alterada .

{
    date -u +%FT%TZ
    opa version
    for tag in antes original alterada; do
        imagem="raio-x:$tag"
        printf '\n%s\n' "$imagem"
        docker image inspect --format 'ID={{.Id}} USER={{.Config.User}}' "$imagem"
        if ./gate.sh "$imagem"; then
            [[ $tag != antes ]]
            echo 'Gate: aprovado.'
        else
            codigo=$?
            [[ $tag == antes && $codigo == 10 ]]
            echo 'Gate: bloqueado.'
        fi
    done
} | tee "$saida/opa.txt"

docker run --rm --network none raio-x:antes
docker run --rm --network none raio-x:original
docker image inspect --format '{{.Id}}' raio-x:original > "$saida/id-original.txt"
docker save -o build/original.tar raio-x:original
syft scan docker-archive:build/original.tar -o "cyclonedx-json=$saida/sbom.cdx.json"
trivy --version > "$saida/trivy-versao.txt"
trivy image --no-progress --input build/original.tar --scanners vuln --severity CRITICAL \
    --format table | tee "$saida/trivy.txt"
grep -q 'CVE-2021-44228' "$saida/trivy.txt"
sha256sum build/original.tar "$saida/sbom.cdx.json" "$saida/trivy.txt" > "$saida/sha256.txt"
