# Fase 7b2 — Textos das segundas passivas (Roteirista)

Chaves novas em `data/ui_texts.json` (nada apagado). Tela em maiúsculas; falas do Osmar em minúsculas, 2 linhas (`\n`).
Variáveis entre chaves são do código. Separador das linhas: ponto final, sem "·". Meta: **3** vitórias pela 1ª passiva (decisão do dono).

## Decisões
- **Nomes confirmados:** Boxe **Contragolpista**, Jiu-jitsu **Por cima**, Muay Thai **Clinch**. Curtos, dizem a ideia sem explicar.
- Ideia de tom: a 1ª passiva é "o que você faz"; a 2ª é "o que você aprende a esperar". Mentor fala em tom de "agora aprende...".
- Linhas da prévia **não repetem números fixos** (50%, 60%, 80%): dizem "com ele fraco / já machucado", para não mentir se o Designer mexer no dado.
  Exceção: os motivos de derrota `cp_never_hurt` (60%) e `tc_never_hurt` (50%) seguem a regra de hoje (igual à 7a1/7b1).
- Letreiros: **K.O. NO CONTRAGOLPE!**, **O JUIZ PAROU!**, **JOELHADA!** (mantidos). Pequenos: CARGA!, LEVANTOU, CLINCH!.
- Mentor: opcional, uma vez, só com o marco. Ficou em `ui_texts` (como `muay_thai_unlocked`), porque o gatilho `passive2_<art>_unlocked`
  ainda não existe em `dialogos.json` (não mexi em gatilho).

## arts.json (`passive_2`, campos de texto)
| Arte | `name` | `fight_text` |
|---|---|---|
| Boxe | Contragolpista | GUARDA ALTA: ESQUIVA CARREGA O CONTRAGOLPE. NO 3º ROUND, VEM O K.O. |
| Jiu-jitsu | Por cima | DERRUBA CEDO E CASTIGA NO CHÃO ATÉ O JUIZ PARAR |
| Muay Thai | Clinch | PRENDE NO CLINCH: ELE NÃO ESQUIVA E A JOELHADA ENTRA |

## ui_texts.json
| Chave | Texto | Variáveis |
|---|---|---|
| `passive_counter_punch_name` | CONTRAGOLPISTA | |
| `passive_counter_punch_line` | VOCÊ ESQUIVA {d}%. CADA ESQUIVA CARREGA (+{c}). NO 3º ROUND, K.O. ATÉ {k}% POR GOLPE | d, c, k |
| `passive_counter_punch_line_aggressive` | NO AGRESSIVO VOCÊ NÃO ESPERA (**sufixo**: acrescentar à linha, como `counter_warn`) | |
| `passive_share_counter_punch` | {n} EM 10 VITÓRIAS POR K.O. NO CONTRAGOLPE | n |
| `passive_top_control_name` | POR CIMA | |
| `passive_top_control_line` | DERRUBA {p}% POR ACERTO (NO {r}º ROUND). ELE LEVANTA {e}%. COM ELE FRACO, O JUIZ PARA ({s}%) | p, r, e, s |
| `passive_top_control_line_late` | SÓ DERRUBA EM {x} DE 10 LUTAS (substitui a linha inteira) | x |
| `passive_share_top_control` | {n} EM 10 VITÓRIAS COM O JUIZ PARANDO | n |
| `passive_thai_clinch_name` | CLINCH | |
| `passive_thai_clinch_line` | PRENDE {p}% POR ACERTO (NO {r}º ROUND). NO CLINCH: JOELHADA {k}% DE CRÍTICO. ELE SOLTA {e}% | p, r, k, e |
| `passive_thai_clinch_line_late` | SÓ PRENDE EM {x} DE 10 LUTAS (substitui a linha inteira) | x |
| `passive_share_thai_clinch` | {n} EM 10 VITÓRIAS POR JOELHADA | n |

### Letreiros e avisos na luta
| Chave | Texto |
|---|---|
| `fight_charge_full` | CARGA! |
| `fight_counter_ko` | K.O. NO CONTRAGOLPE! |
| `fight_stood_up` | LEVANTOU |
| `fight_ground_stop` | O JUIZ PAROU! |
| `fight_clinch` | CLINCH! |
| `fight_knee_ko` | JOELHADA! |

### Motivo da derrota (`reason_passive_*`) e dicas (`tip_passive_*`, 2 por id)
| Id | Texto | Dica 1 | Dica 2 |
|---|---|---|---|
| `cp_early` | VOCÊ CAIU ANTES DO 3º ROUND | RESISTÊNCIA PARA CHEGAR INTEIRO AO 3º | O CONTRAGOLPE SÓ MATA NO 3º ROUND. SEGURE ATÉ LÁ |
| `cp_held` ({n}) | ELE AGUENTOU {n} CONTRAGOLPES | NO CONTRA-ATAQUE, CADA ESQUIVA VALE 2 DE CARGA | RESISTÊNCIA PESA O K.O. DO CONTRAGOLPE |
| `cp_never_hurt` | ELE NUNCA BAIXOU DE 60% | MAIS FORÇA PARA CANSAR ELE | O K.O. SÓ ENTRA COM ELE JÁ MACHUCADO. TREINE FORÇA |
| `tc_no_takedown` | VOCÊ NÃO CONSEGUIU DERRUBAR | FORÇA DERRUBA. O AGRESSIVO DERRUBA MAIS | SEM QUEDA, NÃO TEM POR CIMA. TREINE FORÇA |
| `tc_stood_up` ({n}) | ELE LEVANTOU {n} VEZES | FORÇA SEGURA. O DEFENSIVO NÃO DEIXA ELE LEVANTAR | ÁGIL DEMAIS PARA SEGURAR? MAIS FORÇA NO SACO |
| `tc_never_hurt` | ELE NUNCA BAIXOU DE 50% | MAIS FORÇA PARA CASTIGAR | POR CIMA SEM DANO NÃO ASSUSTA O JUIZ. TREINE FORÇA |
| `cl_never` | VOCÊ NÃO PRENDEU NO CLINCH | FORÇA PRENDE. O DEFENSIVO PRENDE MAIS | O CLINCH SÓ ENTRA COM ELE JÁ MACHUCADO. ACERTE ANTES |
| `cl_released` ({n}) | ELE SOLTOU DO CLINCH {n} VEZES | RESISTÊNCIA SEGURA O CLINCH | O DEFENSIVO FAZ ELE SOLTAR MENOS |
| `cl_held` ({n}) | ELE AGUENTOU {n} JOELHADAS | NO AGRESSIVO A JOELHADA DERRUBA MAIS | MAIS FORÇA NA JOELHADA. O CRÍTICO DO CLINCH FAZ O RESTO |

Chaves: `reason_passive_<id>` e `tip_passive_<id>` (ex.: `reason_passive_cp_early`).

### Cartão da arte e meta
| Chave | Texto |
|---|---|
| `art_card_passive_locked` | TRAVADO |
| `art_card_passive_progress` | {n}/{m} {fim} (n = vitórias, m = 3) |
| `passive_finish_knockout` | K.O. DE EMBALO |
| `passive_finish_submission` | FINALIZAÇÕES |
| `passive_finish_spin_kick` | CHUTES RODADOS |
| `passive2_unlocked_line` | NOVO JEITO DE LUTAR: {nome}. ESCOLHA NA PRÓXIMA CARREIRA |

Exemplos na tela: "2/3 K.O. DE EMBALO", "1/3 FINALIZAÇÕES", "0/3 CHUTES RODADOS".

### Mentor (Osmar, opcional, uma vez; marco `passive2_<art>_unlocked`)
| Chave | Fala |
|---|---|
| `passive2_boxing_unlocked` | três nocautes de embalo? / agora aprende a esperar. |
| `passive2_bjj_unlocked` | três finalizações. agora / aprende a derrubar antes. |
| `passive2_muay_thai_unlocked` | três chutes rodados. / agora cola nele e joelha. |

### skill_tree.json
`effect_text_2` já existia e foi mantido: CONTRAGOLPISTA: K.O. +{pct}% / POR CIMA: DERRUBA {pct}% MAIS / CLINCH: PRENDE {pct}% MAIS.

## Para o Programador
- `passive_counter_punch_line_aggressive` é sufixo (não substitui a linha).
- Linhas do Por cima e do Clinch não têm o limiar (50% / 80%) no texto; não precisam de variável para isso.
- `art_card_passive_progress`: `{fim}` vem de `passive_finish_<finish>`, onde `finish` é `passive_2.unlock.finish`.
- `passive2_<art>_unlocked` (ids `boxing`, `bjj`, `muay_thai`) estão só em `ui_texts`; o gatilho em `dialogos.json` fica para o Programador.
