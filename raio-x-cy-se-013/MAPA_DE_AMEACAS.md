# Mapa de ameaças e evidências | CY-SE-013

| Entrada do atacante | Controle | Evidência |
| --- | --- | --- |
| Alguém muda o usuário padrão da imagem para root durante o build. | O gate OPA libera apenas UID numérico positivo. | Configuração da imagem, versão da política e decisão registrada. |
| Um componente vulnerável entra no build. O laboratório inclui Log4j 2.14.1. | O SBOM do Syft localiza a versão. O Trivy associa o componente à CVE-2021-44228. | SBOM e relatório Trivy vinculados ao arquivo da imagem analisada. |
| Alguém publica uma imagem diferente e tenta apresentá-la como a versão aprovada. | O Cosign verifica o digest da imagem candidata. No fluxo keyless, também exige a identidade e o emissor OIDC autorizados. | Digests, bundle de assinatura e resultados das duas verificações. |

Se a cadeia fosse atacada amanhã, eu começaria pelo digest que chegou ao ambiente. Compararia esse digest com o release aprovado e com a identidade registrada no bundle keyless. Usaria o SBOM e o relatório do Trivy daquele artefato para dizer quais componentes estavam presentes e quais alertas existiam na data da análise. Se o gate tivesse bloqueado a entrega, guardaria a configuração inspecionada, a versão da regra e o resultado. Para investigar **quem substituiu a imagem** ou **se ela chegou a rodar**, precisaria também dos logs de escrita do registry e dos registros de implantação ou execução, com horários correlacionáveis.

Em 2024, código malicioso foi inserido nos arquivos de distribuição do xz-utils 5.6.0 e 5.6.1. A ligação com o exercício é a confiança no artefato distribuído. A verificação por digest detecta uma substituição posterior à assinatura. Se o conteúdo malicioso entrar antes de uma assinatura legítima, a assinatura continua válida. O inventário ajuda a localizar a versão afetada quando o incidente é conhecido. [Análise da Red Hat](https://access.redhat.com/security/cve/cve-2024-3094)
