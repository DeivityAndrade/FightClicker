# QA da ID3: janelas e telas no tema C

Data: 2026-11-25. O agente de QA não podia gravar o relatório; o Produtor gravou o conteúdo dele aqui.

## Veredito: NÃO aprovado (2 bugs visuais médios; a mecânica está intacta)

| Item | Resultado |
|---|---|
| `ui_audit --estados todos --estrito` | 586 estados, 0 problemas e 0 achados estritos |
| `tools/run_tests.ps1` | todos passaram |
| `foto.gd` contra `origin/main~3` | idêntica (SHA-256 `20387E62…9110D2C`) |
| Olho nas capturas | B1 e B2 reais; B3 a B5 menores |
| Placar de `ignore` | 43, todos com motivo (meta: 15) |

## Bugs
- **B1 (média): janela "RONDA FEITA"** (`ronda_premio_*`)
  - O botão VOLTAR encosta na borda de baixo (0 px).
  - "NÍVEL 2" e "OCORRÊNCIAS" ficam a cerca de 2 px do botão.
  - "+3 LENDA" encosta no filete do cabeçalho.
  - Correção na tela: UI/UX.
- **B2 (média): mural "O QUE FICOU NA PAREDE"** (`f6c2_tela_mural_*`, `f6c2_hall_*`)
  - A 2ª linha da descrição é cortada pela tarja (COMPRADO, FALTAM N DE HONRA, COMPRA NO FIM DA CAMPANHA).
  - Correção: UI/UX.
- **B3 (baixa): peças escuras que sobraram**
  - A caixa do NOME na criação de discípulo.
  - A caixa preta alta e vazia no cinturão ("VOCÊ SE MUDA..."), e "GARAGEM SALVA" com as linhas coladas.
  - A barra preta vazia sob "DEFENSIVO" no HUD da luta.
  - Correção: UI/UX.
- **B4 (baixa): topo do mapa escuro**
  - Fica assim: é o "mundo noturno", e o texto se lê bem.
- **B5 (baixa): números de dano empilhados**
  - "CLINCH!" sobre números no estresse de MT (`f7b2_luta_mt_clinch`).
  - Correção: UI/UX.

## Lacunas do verificador (Programador)
- **Regra de folga:**
  - entre texto e botão ou irmão vizinho (ao menos 2 px);
  - entre botão e borda interna da janela (igual às outras janelas).
  - Essa regra teria pego B1 e B2.
- **Isenções por tipo, para o placar chegar à meta de 15:**
  - área de hover sem desenho;
  - `ReferenceRect`;
  - peça sem texto (`TextureRect`, `NinePatchRect` ou `ColorRect`) dentro de moldura;
  - raiz `Node2D` de mundo.
  - Estimativa: de 43 para cerca de 15.

## Para reconferir
Os estados `ronda_*` e `f6c2_*`, mais os do B3 e do B5. Não precisa de nova rodada completa.
