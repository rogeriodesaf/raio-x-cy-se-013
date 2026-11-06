#include <stdio.h>
#include <unistd.h>

int main(void) {
    char mensagem[128];
    FILE *arquivo = fopen("/mensagem.txt", "r");
    if (!arquivo) {
        perror("/mensagem.txt");
        return 1;
    }
    if (!fgets(mensagem, sizeof mensagem, arquivo)) {
        fputs("Não foi possível ler a mensagem.\n", stderr);
        fclose(arquivo);
        return 1;
    }
    fclose(arquivo);
    printf("UID %lu | %s", (unsigned long)getuid(), mensagem);
    return 0;
}
