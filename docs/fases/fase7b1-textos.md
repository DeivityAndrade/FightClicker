# Fase 7b1 — Textos do Muay Thai (Roteirista)

Chaves novas em `data/ui_texts.json` (nada apagado). Tela em maiúsculas; falas do Osmar em minúsculas, 2 linhas (`\n`).
Variáveis entre chaves são do código. Separador das linhas: ponto final (". "), sem "·".

## Decisões
- **Passiva: Canela** (aprovada pelo dono). Nome do aparelho, da regra de treino e dos nós seguem o mesmo cheiro: canela, coxa, estalo.
- **Chute rodado:** o golpe continua se chamando **Chute rodado** (já está em `moves.json` e no `tech_mt_4`). Letreiro do especial: **CHUTE RODADO!** (final da luta). A perna cheia pisca **PERNA CHEIA!**.
- **Nós da árvore e aparelho:** os nomes e descrições gravados pelo Designer ficaram. Já têm a graça e cabem na largura. Nada mudou em `skill_tree.json`.
- **Contra-ataque** do Muay Thai: o texto avisa que o contragolpe "marca a perna".
- Fala do Osmar sem nome de lutador de verdade e sem citar outro jogo. Ele "guardou" o chute: tom de história exagerada dele.

## Onde cada texto entra
### `data/arts.json → arts[muay_thai]` (campos de texto, já gravados)
| Campo | Texto |
|---|---|
| `tagline` | Canela dura, paciência curta. Uma marca por chute. (igual ao provisório) |
| `rule_text` | CRÍTICO DO CLIQUE: {chance}% DE CHANCE, x{mult} (igual; mostra "20% DE CHANCE, x4,1") |
| `fight_text` (**trocado**, mais curto) | CANELA: CHUTE BAIXO MARCA A PERNA. CHEIA, VEM O CHUTE RODADO |

### `data/ui_texts.json` (gravado)
| Chave | Texto | Variáveis |
|---|---|---|
| `passive_muay_thai_name` | CANELA | |
| `passive_muay_thai_line` | PERNA CHEIA NO {r}º ROUND ({k} CHUTES). RODADO {p}% POR GOLPE. ELE {s}% MAIS LENTO | r, k, p, s |
| `passive_muay_thai_line_late` | A PERNA SÓ ENCHE EM {x} DE 10 LUTAS | x |
| `passive_muay_thai_counter_warn` | ELE CONTRAGOLPEIA (Agressivo, acrescentar à linha) | |
| `passive_muay_thai_counter_marks` | SEU CONTRAGOLPE MARCA A PERNA (Contra-ataque, acrescentar à linha) | |
| `passive_share_muay_thai` | {n} EM 10 VITÓRIAS POR CHUTE RODADO | n |
| `fight_marks_full`, `fight_spin_kick`, `fight_special_banner_muay_thai` | PERNA CHEIA! / CHUTE RODADO! / CHUTE RODADO! | |
| `reason_passive_mt_counter` | OS CONTRAGOLPES DELE TIRARAM {n}% DA SUA VIDA | n |
| `reason_passive_mt_marks_late` | A PERNA NÃO ENCHEU: SÓ {n} DE 3 MARCAS | n |
| `reason_passive_mt_held` | ELE AGUENTOU {n}X O CHUTE RODADO | n |
| `reason_passive_mt_never_hurt` | A PERNA ENCHEU, MAS ELE NUNCA BAIXOU DE 60% | |
| `tip_passive_mt_counter` / `_marks_late` / `_held` / `_never_hurt` | arrays de 2 dicas cada (padrão `tip_passive_*`) | |
| `art_card_muay_thai_fight` | mesmo texto do `fight_text` novo (o cartão pode ler um ou outro) | |
| `art_focus_muay_thai` | FORÇA MARCA A PERNA. AGILIDADE FAZ O CRÍTICO (dica de foco, cartão e mentor) | |
| `mentor_style_muay_thai` (2) | "canela se faz com paciência." / "força marca a perna. agilidade manda o resto." (opcionais, puxáveis) | |
| `muay_thai_unlocked` | "o kid caiu? então guardei um chute pra você." (Osmar, uma vez, marco `muay_thai_unlocked`) | |
| `spar_name_muay_thai` | CHOQUE: NO COMPASSO | |
| `spar_tip_muay_thai` | CLIQUE NA BATIDA. TRÊS NO TEMPO, CHUTE. SEGURE PARA GUARDAR. | |
| `spar_beat_on` / `spar_beat_off` / `spar_beat_kick` | NO TEMPO! / FORA DO TEMPO / CHUTE! | |
| `spar_combo` | COMBO {n} | n |
Choque do Muay Thai reaproveita o resto da 7a2 (RAJADA!, ELE ABRIU!, ENCOSTOU!, FÔLEGO, placar, recompensa, AQUECIDO).

### `data/training.json → kick_bag` (campo de texto, já gravado)
`crit_texts` (8, o Muay Thai vê 2x mais crítico): CANELA! / ESSE ESTALOU! / O SACO DOBROU! / TEP! / MARCOU! / ECOOU NO BAIRRO! / ESTALO SECO! / SOLTOU AREIA!
Nomes e descrições do aparelho e de `tech_mt_1..4` ficam como estão.

### `data/skill_tree.json` (sem mudança)
| Nó | Nome | Descrição | Efeito na tela |
|---|---|---|---|
| `style_muay_thai` | Canela de ferro | O saco comprido já tem a marca da sua perna. | MUAY THAI: CRÍTICO DO CLIQUE CRESCE {pct}% |
| `mt_shin` | Chute na coxa | Sempre no mesmo lugar. Até ele lembrar. | MUAY THAI: MARCA A PERNA {pct}% MAIS RÁPIDO |
| `mt_oil` | Óleo de massagem | Cheiro de cânfora. A canela agradece. | MUAY THAI: CRÍTICO DO CLIQUE CRESCE {pct}% |
| `mt_rope` | Pé de pluma | Pula leve. Chuta pesado. | +{pct}% TREINO POR CLIQUE |

## Para o Programador
- A fala `muay_thai_unlocked` está em `ui_texts` (como as da 7a1), porque o gatilho ainda não existe em `dialogos.json`. Speaker: Osmar (`coach`), uma vez só, na próxima vez que a sala estiver livre.
- `passive_muay_thai_line` tem ~80 caracteres: quebrar em 2 linhas na fonte 5x7 (o `ui_audit` decide). Dá para cortar em "{k} CHUTES)." se faltar espaço.
- `reason_passive_mt_held`: `{n}` é número de chutes rodados que ele aguentou ("1X" e "3X" funcionam; não precisa de plural).
- `passive_muay_thai_line_late` substitui a linha inteira quando `full_share < 0,5`.
