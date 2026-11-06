#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ $(uname -s)/$(uname -m) != Linux/x86_64 ]]; then
    echo 'Use Linux x86_64 ou WSL 2 x86_64 com integração Docker.' >&2
    exit 2
fi

mkdir -p build
cc -static -Os -s -o build/app app.c
curl --fail --silent --show-error --location \
    https://repo.maven.apache.org/maven2/org/apache/logging/log4j/log4j-core/2.14.1/log4j-core-2.14.1.jar \
    -o build/log4j-core-2.14.1.jar
sha256sum --check <<'CHECKSUM'
ade7402a70667a727635d5c4c29495f4ff96f061f12539763f6f123973b465b0  build/log4j-core-2.14.1.jar
CHECKSUM
