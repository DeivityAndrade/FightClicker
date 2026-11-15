# Fase 6b2: textos (Cara de lutador)

Dono: Roteirista. Data: 2026-11-15. Base: `fase6b2-design.md` (§3.3), `fase6b1-textos.md`, `data/disciples.json`.
Chaves acrescentadas ao fim de `data/ui_texts.json` (nada mais mudou). `scripts/`, `ui/`, `data/disciples.json` e `data/cutscenes/` intocados.

## 1. Rótulos das linhas (máx. 6 caracteres, como CABELO e CALÇÃO)
O design previa até 9 (COR FAIXA, EM CIMA). Encurtei para caber folgado: a cor fica logo abaixo da peça, então o contexto resolve.

| Linha | Chave | Texto | Obs. |
|---|---|---|---|
| NOME | `disc_label_name` | NOME | já existia |
| PELE | `disc_label_skin` | PELE | já existia |
| CORTE | `disc_label_style` | CORTE | |
| CABELO | `disc_label_hair` | CABELO | já existia |
| FAIXA | `disc_label_band` | FAIXA | |
| cor da faixa | `disc_label_band_color` | COR | em vez de "COR FAIXA" (9) |
| parte de cima | `disc_label_top` | CIMA | em vez de "EM CIMA" (7) |
| cor da cima | `disc_label_top_color` | COR | |
| CALÇÃO | `disc_label_shorts` | CALÇÃO | já existia |
| MEIÃO | `disc_label_socks` | MEIÃO | |

Se a UI/UX tiver folga de 7 a 9 caracteres, basta trocar só o texto: `COR FAIXA` e `EM CIMA` voltam sem mexer em mais nada.

## 2. Nome da opção (ao lado das setas)
| Chave | Texto |
|---|---|
| `disc_opt_hair_style_buzz` | RASPADO |
| `disc_opt_hair_style_short` | CURTO |
| `disc_opt_hair_style_volume` | VOLUME |
| `disc_opt_hair_style_bun` | COQUE |
| `disc_opt_top_none` | SEM |
| `disc_opt_top_tank` | REGATA |
| `disc_opt_top_tee` | CAMISETA |
| `disc_opt_headband_none` | SEM |
| `disc_opt_headband_band` | COM |
| `disc_opt_socks_none` | SEM |
| `disc_opt_socks_on` | COM |

A chave segue o padrão `disc_opt_<campo>_<id>` do design. O maior é CAMISETA (8). Se não couber ao lado das setas, o plano B é CAMISA (6); regata e camiseta continuam distinguíveis pela prévia.

## 3. Nome das cores (opcional)
O design diz que as cores ficam só em chips. Deixei os nomes prontos para dica ao passar o mouse ou para uso futuro; a UI não precisa ler.

| Cores de roupa, faixa e calção (`disc_color_<id>`) | Texto |
|---|---|
| `white` | BRANCO |
| `black` | PRETO |
| `gray` | CINZA |
| `blue` | AZUL |
| `green` | VERDE |
| `yellow` | AMARELO |
| `red` | VERMELHO |
| `purple` | ROXO |

| Cor de cabelo (`disc_hair_<id>`) | Texto |
|---|---|
| `black` | PRETO |
| `dark_brown` | CASTANHO |
| `brown` | MARROM |
| `copper` | RUIVO |
| `blond` | LOIRO |
| `platinum` | PLATINA |

## 4. Dica do 2º mentor (garagem, ao passar o mouse)
| Chave | Texto | Uso |
|---|---|---|
| `disc_mentor2_hint` | `{nome}: já passou o posto.` | `{nome}` vem do roster; a UI aplica `.to_upper()` se a dica for em maiúscula, como no HUD |

- Ele não fala: nada de balão nem fala. É só um rótulo opcional, sem exigir clique.
- Letras: só A-Z, `á ã ç ú í é` já usados na 6b1, mais `:` e `.`; nenhuma letra nova na 5x7. O nome do discípulo vem do banco que já respeita a fonte.

## 5. Conferência de letras
Acentos usados nos textos novos: `Ã` (MEIÃO), já usado em CINTURÃO e DISCÍPULO. Nenhum `Ô`, `Ê` ou trema.
