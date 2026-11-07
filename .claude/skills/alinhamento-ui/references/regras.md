# Regras do verificador `tools/ui/ui_audit.gd`

Tudo medido na resolução base 640x360 (coordenadas globais do `Control` divididas pela escala). Tolerância padrão: **1 px**.

| Código | Regra | Como mede |
|---|---|---|
| `TXT_ALIGN` | Botão com texto deve ter `alignment = CENTER` (salvo `ui_align` left/right). Label com `ui_align=center` deve ter `horizontal_alignment` e `vertical_alignment = CENTER`. | Propriedades do nó. |
| `TXT_OFFCENTER` | O texto renderizado fica centralizado no retângulo útil (descontando o `content_margin` do stylebox). | `font.get_string_size(texto, font_size)`; centro do texto vs centro da área útil. |
| `ICON_GROUP` | Em botão com ícone, o grupo ícone+separação+texto fica centralizado. | Soma das larguras vs área útil. |
| `CHILD_OFFCENTER` | Nó com `ui_align=center` (ou `center_h`/`center_v`) tem o centro igual ao do pai no eixo pedido. | `get_global_rect()` do nó vs do pai. |
| `ROW_UNEVEN` | Irmãos visíveis do mesmo tipo dentro de `HBoxContainer`/`VBoxContainer`/`GridContainer` com mesma função (ex.: botões de foco, táticas) têm o mesmo tamanho e espaçamento. | Larguras/alturas e gaps; avisa se diferirem >1 px. Ignora se o pai tiver `ui_align_row="free"`. |
| `MARGIN_ASYM` | Painel/janela: margem esquerda = direita (e topo = base quando `ui_align=center`). | Distância do conteúdo às bordas do pai. |
| `CLIPPED` | Texto não cabe: largura mínima > largura do controle, ou `clip_text`/`text_overrun_behavior` cortando. | `get_minimum_size()` vs `size`. |
| `OFFSCREEN` | Controle visível total ou parcialmente fora de 640x360. | Retângulo global. |
| `OVERLAP` | Irmãos visíveis fora de container se sobrepõem (salvo `ui_align=ignore` ou camadas de propósito). | Interseção de retângulos. |
| `SUBPIXEL` | Posição ou tamanho global não inteiro na base. | `fposmod(x, 1.0) > 0.01`. |

## Estados que o verificador percorre (`--estados todos`)
Garagem (aba Treino e aba Loja), F12 aberto, prévia (com cada tática), luta (início com letreiro, meio, fim por K.O. e por pontos), vitória, cinturão, fim de carreira (derrota normal e por azar), confirmação de aposentar, tela "saiu por cima". Use save de teste em `user://test/ui_audit/`, nunca o save real.

## Saída
- Uma linha por problema: `CÓDIGO  caminho/do/nó  estado  detalhe (ex.: "centro x=318.5, esperado 320.0, Δ=1.5px")`.
- Resumo: `ESTADOS n | PROBLEMAS n`.
- Capturas PNG por estado na pasta de saída.
- Código de saída 0 sem problemas, 1 com problemas.
