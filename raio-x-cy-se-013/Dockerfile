FROM scratch
ARG UID_APP=65532
ARG MENSAGEM=mensagem.txt
COPY build/app /app
COPY ${MENSAGEM} /mensagem.txt
# Versão vulnerável mantida apenas para o exercício de inventário.
COPY build/log4j-core-2.14.1.jar /componentes/log4j-core-2.14.1.jar
USER ${UID_APP}
ENTRYPOINT ["/app"]
