# Raio-X da Cadeia de Suprimentos | CY-SE-013

Projeto final do módulo. A aplicação é um binário pequeno que lê uma frase e informa o UID do processo. O cenário de ataque troca apenas a frase da imagem. Um JAR vulnerável é incluído para o exercício de inventário. O binário em C jamais carrega esse JAR.

## O contraste

| Imagem | UID padrão | Frase | Resultado esperado do OPA |
| --- | --- | --- | --- |
| `raio-x:antes` | 0 | Original | Bloqueia |
| `raio-x:original` | 65532 | Original | Aprova |
| `raio-x:alterada` | 65532 | Substituída | Aprova |

O gate avalia o usuário padrão da imagem. Ele deve rodar antes da promoção da imagem e não cobre uma substituição de usuário feita na execução, como `docker run --user 0`. A variante passa no OPA porque mantém o UID permitido. A verificação do Cosign é que distingue a versão assinada da substituta.

## 1. Build, OPA, Syft e Trivy

Use Linux x86_64 ou WSL 2 x86_64 com Docker, compilador C com libc estática (por exemplo, `build-essential` no Ubuntu), Bash, curl, jq, OPA 1.x, Syft e Trivy. A primeira execução do Trivy pode demorar pelo download das bases de vulnerabilidades e de Java.

```bash
./demonstrar.sh
```

O script constrói as três imagens pelo mesmo Dockerfile, testa o gate, executa duas versões com a rede desabilitada e salva os resultados em `resultados/local/`. O gate aprova com código 0 e bloqueia com código 10. O JAR tem SHA-256 fixado no script de preparação. Para o inventário, procure por `log4j-core` 2.14.1 e `CVE-2021-44228`. A CVE é real e está presente no componente incluído. O exercício evidencia presença e exposição potencial em sistemas que carreguem o JAR.

Referências [Syft](https://oss.anchore.com/docs/reference/syft/cli/) · [Trivy](https://trivy.dev/docs/latest/target/container_image/) · [Advisory do Log4j](https://github.com/advisories/GHSA-jfh8-c2jp-5v3q)

## 2. Cosign keyless

Use Cosign 3.x e um repositório de teste com permissão de escrita e suporte a assinaturas OCI. O script publica as duas imagens em tags exclusivas da execução. Use um registry autorizado para este exercício. A assinatura com o Sigstore público registra dados da assinatura e do certificado no serviço de transparência.

Depois de fazer login no registry, defina o repositório, a identidade exata que deve aparecer no certificado e o emissor. O exemplo é para um login Google. Troque os dois valores de exemplo antes de executar.

```bash
export REPO='ghcr.io/SEU_USUARIO/raio-x-cy-se-013'
export IDENTIDADE='voce@example.com'
export EMISSOR='https://accounts.google.com'
./assinar.sh
```

Conclua o login interativo do Cosign com a identidade escolhida. O script assina a original pelo digest, guarda o bundle e exige que a verificação da original passe. Depois consulta a imagem alterada, também por digest, e exige que a verificação falhe por falta de assinatura aceitável. Os digests, os logs e os códigos de saída ficam em `resultados/keyless-*/`. O resultado negativo esperado é **no signatures found**. Uma falha de rede ou autenticação requer revisão e não conta como evidência.

Referências [Assinatura de containers](https://docs.sigstore.dev/cosign/signing/signing_with_containers/) · [Verificação por identidade](https://docs.sigstore.dev/cosign/verifying/verify/)

## Evidências incluídas

| Arquivo | Resultado obtido |
| --- | --- |
| `evidencias/opa.txt` | OPA real retornou `false` para UID 0 e `true` para os dois UIDs 65532. |
| `evidencias/sbom.cdx.json` | SBOM CycloneDX gerado pelo Syft para a imagem original. |
| `evidencias/trivy.png` e `evidencias/trivy.txt` | Imagem da saída capturada e relatório do Trivy. |
| `evidencias/cosign-local/` | Teste real com chave descartável no registry local. A original retornou 0. A variante retornou 10, sem assinatura. |
| `MAPA_DE_AMEACAS.md` | Mapa, evidências de incidente e conexão com xz-utils. |

O ambiente da coleta não tinha daemon Docker. Para os resultados incluídos, as três imagens foram empacotadas como arquivos compatíveis com `docker save`, com o mesmo conteúdo, usuário e entrypoint declarados no Dockerfile. O Dockerfile e os scripts de execução com Docker foram revisados, mas a execução por esse caminho ainda precisa ser feita. Os digests de manifesto do registry constam separadamente dos IDs locais de configuração.

O teste local do Cosign usou uma chave de laboratório e dispensou o log de transparência. **A execução keyless permanece pendente.** Use `assinar.sh` para obter as evidências com a sua identidade e o seu registry.

## Apresentação de 5 minutos

1. **Antes · 1 min** — Mostre o Dockerfile e o UID 0 da imagem inicial. Aponte para o JAR no SBOM e para o alerta no Trivy.
2. **Ataque · 1 min** — Compare `mensagem.txt` e `mensagem-alterada.txt`. Explique que a troca da frase representa a substituição da imagem no canal de distribuição. Mostre que o UID permanece 65532.
3. **Depois · 2 min** — Mostre o OPA rejeitando a imagem root e aprovando as duas imagens sem root. Mostre a original aceita pelo Cosign e a variante sem assinatura rejeitada. Para apresentar o critério keyless, use os arquivos gerados após o login OIDC. Identifique o teste com chave caso mostre a evidência local.
4. **Por que importa · 1 min** — Use o caso xz-utils para explicar onde a alteração entrou e o que o digest, a assinatura e o SBOM permitem investigar.

A imagem analisada está em `evidencias/imagem-original.tar.gz`. O SHA-256 em `evidencias/sha256-imagens.txt` se refere ao TAR descompactado. Para reanalisar o mesmo artefato, descompacte com `gzip -dc evidencias/imagem-original.tar.gz > original.tar` e passe esse TAR ao Syft ou ao Trivy.
