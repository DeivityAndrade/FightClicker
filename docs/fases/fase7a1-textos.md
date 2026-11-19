# Fase 7a1 — Textos (Roteirista)

Chaves novas em `data/ui_texts.json` (nada apagado). Na tela tudo sai em maiúsculas; acentos como no resto do arquivo.

## Decisões
- **Nomes das passivas:** ficam **Mão rápida** (Boxe) e **Finalização** (Jiu-jitsu), como o dono aprovou.
- **Arena da liga da academia:** **Ginásio Alvorada** (`arena_league_name`). Nome de ginásio de bairro, de dia, sem pompa.
- **Conflito "embalo":** `embalo` fica **só** do Boxe na luta (`fight_streak`). O bônus que o Choque (7a2) dá para a próxima luta
  se chama **AQUECIDO** (`bonus_warm_name`). Na 7a2 use "AQUECIDO" em prévia, convite e tela de recompensa; nunca "embalo".
- Separador das linhas da passiva: ponto final (". "), sem "·" (fonte 5x7 não garante o glifo).

## Chaves (variáveis em chaves são do código)
| Chave | Texto | Variáveis |
|---|---|---|
| `passive_boxing_name` / `passive_bjj_name` | MÃO RÁPIDA / FINALIZAÇÃO | |
| `passive_boxing_line` | SOCO A CADA {s} S. K.O. ATÉ {ko}% POR GOLPE. CANSA NO 3º ROUND | s, ko |
| `passive_boxing_line_defensive` | idem, termina em NÃO CANSA | s, ko |
| `passive_boxing_counter_warn` | ELE CONTRAGOLPEIA (acrescentar no Agressivo) | |
| `passive_bjj_line` | PEGADA CHEIA NO {r}º ROUND ({t} S). {p}% POR GOLPE PARA FINALIZAR | r, t, p |
| `passive_bjj_line_late` | A PEGADA NÃO ENCHE ANTES DO GONGO | |
| `passive_share_boxing` / `_bjj` | {n} EM 10 VITÓRIAS POR K.O. / POR FINALIZAÇÃO | n |
| `fight_streak`, `fight_tired`, `fight_grip_full`, `fight_submission` | EMBALO {n}, CANSADO, PEGADA!, FINALIZOU! | n |
| `reason_passive_*` (6) | as seis notas da §9 do design, texto igual ao provisório | n, r |
| `tip_passive_*` (6) | arrays de 2 dicas por nota (padrão `tip_*`) | |
| `art_card_boxing_fight` / `art_card_bjj_fight` | texto do cartão da janela da arte (substitui `fight_text` com `{pct}`; ver abaixo) | |
| `art_focus_boxing` / `_bjj` / `_none` | dica de foco de treino por arte (cartão e mentor) | |
| `mentor_style_boxing` / `_bjj` | 2 falas opcionais do mentor (ver abaixo) | |
| `arena_league_name` | GINÁSIO ALVORADA | |
| `bonus_warm_name` | AQUECIDO (7a2) | |

## Para o Programador (os dois pontos que não posso gravar)
- `data/arts.json → fight_text` (hoje com `{pct}`, que a passiva não usa mais) deve passar a apontar para `art_card_boxing_fight` /
  `art_card_bjj_fight`, ou receber o mesmo texto. Os textos antigos ("+{pct}% DE DANO", "-{pct}% DE DANO RECEBIDO") ficam
  falsos quando o traço sair.
- **Fala do mentor** (opcional, puxável, nunca trava o loop): as falas estão em `ui_texts` por não poder tocar em `dialogos.json`.
  Quem ligar o gatilho pode copiá-las para lá (speaker `mentor`, gatilho `art_choice`, 1 por campanha, só com arte escolhida).
  Texto do mentor em minúsculas, 2 linhas no máximo, como as de hoje.
- Textos de HUD e linha de prévia usam a fonte 5x7; a mais comprida é `passive_bjj_line` (cerca de 60 caracteres): quebrar em 2 linhas se
  o `ui_audit` acusar corte.
