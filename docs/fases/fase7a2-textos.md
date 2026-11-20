# Fase 7a2 — Textos (Roteirista)

Chaves novas em `data/ui_texts.json` (nada apagado). Tela em maiúsculas; falas do Osmar em minúsculas, 2 linhas (`\n`).
Variáveis entre chaves são do código. "AQUECIDO" é a palavra do bônus (nunca "embalo").

## Decisões
- Nome do treino: **Treino fora de hora**. Minigames: **Choque** (variantes "troca franca" no Boxe e "disputa de pegada" no Jiu-jitsu) e **Panfletagem**.
- **Gato Preto:** o nome **não aparece** nesta fase. O recorte fala em "vulto mascarado" e o Osmar em "vulto de capuz": a lenda
  ganha nome depois. As peças originais (orelhas costuradas, faixa da escola, capa de lona) ficam para a arte e a fase própria.
- O boato do Osmar sai só dentro da Panfletagem (`black_cat_rumor`), como o design manda.

## Chaves
| Chave | Texto |
|---|---|
| `treino_name`, `spar_name`, `spar_name_boxing`, `spar_name_bjj`, `flyers_name` | TREINO FORA DE HORA / CHOQUE / CHOQUE: TROCA FRANCA / CHOQUE: DISPUTA DE PEGADA / PANFLETAGEM |
| `invite_go` | IR |
| `invite_spar` (3, sorteio de fala a cargo do código; não usar `rng` do jogo) | "depois do expediente tem sparring. vem?" / "o saco tá frio. bora esquentar?" / "um choquezinho antes de fechar?" |
| `invite_flyers` (3) | "tem panfleto sobrando. vamos pra rua?" / "a escola precisa de cara nova. bora?" / "vinte minutinhos na calçada. vem?" |
| `mini_exit`, `mini_back`, `mini_ready`, `mini_go`, `mini_time` | SAIR / VOLTAR / PREPARAR / VAI! / {n} S |
| `spar_tip_boxing`, `spar_tip_bjj` | CLIQUE PARA EMPURRAR. SEGURE NA RAJADA. / SEGURE PARA PUXAR. SOLTE QUANDO ELE PUXAR. |
| `spar_warn_burst`, `spar_warn_pull`, `spar_warn_pause` | RAJADA! / PUXADA! / ELE ABRIU! (finta usa o aviso da rajada/puxada) |
| `spar_counter_x2`, `spar_point_you`, `spar_point_him`, `spar_breath` | X2 / ENCOSTOU! / ELE ENCOSTOU / FÔLEGO |
| `spar_score` | VOCÊ {a} X {b} ELE |
| `spar_won`, `spar_lost`, `spar_draw`, `spar_result_line` | VENCEU! / NÃO DEU / EMPATE / {n} PONTOS |
| `spar_reward_title`, `spar_reward_attr` | TREINO FEITO / +{n} {atributo} |
| `spar_warm_gain`, `spar_warm_none` | AQUECIDO PARA A PRÓXIMA LUTA / SEM LUTA MARCADA |
| `warm_preview_line` | AQUECIDO: +{pct}% NOS ATRIBUTOS (+{n} NA CHANCE) |
| `flyers_tip`, `flyers_accepted`, `flyers_refused`, `flyers_count` | ENTREGUE PARA QUEM OLHAR O CARTAZ. / ACEITOU! / NÃO, VALEU / {n} DE {goal} |
| `flyers_reward_title`, `flyers_reward_fame` | RUA CUMPRIDA / +{n} FAMA |
| `flyers_took` (5) | falas de quem aceita (balãozinho na rua): HUM, DEIXA EU VER / MEU PRIMO GOSTA DE LUTA / TEM AULA EXPERIMENTAL? / QUANTO É A MENSALIDADE? / VOU PASSAR LÁ (neutras: valem para qualquer arte e local; sem citar Boxe, garagem ou academia) |
| `flyers_ignored` (5) | falas de quem recusa (erro): NÃO, OBRIGADO / TÔ ATRASADO / OUTRA HORA / DEPOIS EU VEJO / SÓ ESPERANDO O ÔNIBUS |
| `black_cat_clipping` | VULTO MASCARADO ASSUSTA LADRÃO PERTO DA BORRACHARIA (hover do recorte) |
| `black_cat_rumor` | "dizem que um vulto de capuz / ronda o bairro de noite." (Osmar, 1 balão na rua) |

## Para o Programador
- `flyers_ignored` / `flyers_took` e as falas do convite são arrays; escolha por índice da rodada ou `_rng_treino`, nunca `rng`/`_rng_fala`.
- `spar_warn_pause` ("ELE ABRIU!") aparece na pausa; a finta mostra primeiro o aviso da rajada e vira branco na metade (arte, sem texto novo).
- Fonte 5x7: o mais comprido é `warm_preview_line` (~48 caracteres); `ui_audit` decide se quebra em 2 linhas.
- Fala do Osmar com `\n` fixo, como as `mentor_style_*`.
