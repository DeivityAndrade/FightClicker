# Fase 5 — Textos: academia de bairro, Boxe e Jiu-jitsu

Dono: Roteirista. Versão 1 (2026-11-06). Só texto; números, preços e ids ficam com o Designer.
Base: `fase5-escopo.md` (respostas do dono), `fase5-design.md` (§13.1), `data/proposta_fase5/*.json`, `narrativa.md`, `fase4b-textos.md`.
Limites: nome até 16 caracteres, descrição até 44, tudo em maiúsculas na tela. Fonte 5x7: **sem travessão (—), sem sinal de menos (−), sem ponto mediano (·)**. Uso só hífen, vírgula, dois-pontos, barra e `x`.

## Decisões de texto
- **A academia tem nome: Boa Esquina.** "Academia Boa Esquina": fica na esquina do bairro, mensalidade atrasada, pôster desbotado, espelho trincado. Calor humano, nada de luxo. O termo genérico "academia de bairro" continua no glossário.
- **Tonhão do Tatame e Kid Navalha ficam** (originais, cabem em 16 e 11 caracteres). Mudei só descrição e falas para caberem nos limites e deixarem o Tonhão mais caloroso e o Kid mais seco.
- **Tonhão** é o veterano da casa: acolhe e cobra. **Kid Navalha** é o campeão que treina sozinho: seco, sem crueldade. Nenhum humilha o jogador.
- **Pêndulo trocado por "Esquiva e volta".** "Pêndulo" já é o nome dos níveis do Metrônomo na LOJA (`metronome_l1` a `l3`). Dois itens com o mesmo nome confundiriam. O id `tech_boxing_2` não muda.
- **"Peso do tempo" no lugar de "Pressão de quem tem tempo"** (25 caracteres, estourava 16).
- **Gênero dos aparelhos.** `unlock.name` curto: **Pera** (feminino) e **Boneco** (masculino). As dicas de fim usam listas próprias por aparelho (`tip_unlock_speed_bag`, `tip_unlock_grappling_dummy`), igual a esteira e a corda, então "A PERA" e "O BONECO" saem certos. **Não usar o `tip_unlock` genérico ("COMPRE A {nome}") com o Boneco.** `unlock_after` e `focus_locked_after` falam da esteira (o que ele pede), então não quebram.
- Sem travessão: onde a 4b usava " — " (plaquinha) já existe no código; isso não muda. Nos textos novos, nada.

## 1. Academia (`locations[gym]`)
| campo | texto |
|---|---|
| `name` | Academia Boa Esquina |
| `ambience` | Pôster desbotado, mensalidade atrasada e um espelho que trinca onde você bate. |
| `move_button` | MUDAR |
| `move_description` | Sai da garagem. Mais treino e 2 lutas novas. (44) |

## 2. Adversários
| id | name | description (≤44) | entry | wins_line | loses_line |
|---|---|---|---|---|---|
| `opp_gym_1` | Tonhão do Tatame (16) | Faixa roxa de cor duvidosa. Pesa e não sai. (43) | Aqui o tatame é meu. Fica à vontade. | Bem-vindo à academia. Paga a mensalidade. | Tá bom, pode ficar. Cuidado com o espelho. |
| `opp_gym_2` | Kid Navalha (11) | Campeão da casa. Corta o ar e a conversa. (41) | Eu vi você chegar de chinelo. | Volta quando a garagem te soltar. | Amanhã cedo. Você e eu. De novo. |

Perfis (do Designer): Tonhão RESISTENTE, Kid RÁPIDO. Arte: Tonhão pesado, quimono velho de faixa roxa; Kid magro, boxeador.

## 3. Aparelhos das artes
| id | `name` (≤16) | `unlock.name` | `unlock.description` (≤44) | `unlock.arrives_as` (≤44) |
|---|---|---|---|---|
| `speed_bag` | Pera veloz (10) | Pera | Pequena, veloz e sem perdão pra distraído. (42) | Presa na parede. Alguém jurou que aguenta. (42) |
| `grappling_dummy` | Boneco de tatame (16) | Boneco | Não reclama, não bate, não desiste. (35) | Veio num tatame velho. Cheira a vestiário. (42) |

- `focus_label`: `["BOXE", "PERA"]` e `["JIU-JITSU", "BONECO"]`.
- `first_hint`: "Clique na pera: força e agilidade juntas" (40) e "Clique no boneco: resistência e força juntas" (44).
- `crit_texts` Pera: TRA-TRA-TRA! / RITMO DE SINO! / A PERA SUMIU! / MÃO DE RELÓGIO! / NEM VIU VOLTAR! (todos ≤16).
- `crit_texts` Boneco: ENCAIXOU! / GUARDA PASSADA! / PEGOU AS COSTAS! / PEDIU TAPA! / O TATAME GEMEU! (todos ≤16; "BATEU, BATEU!" virou "PEDIU TAPA!").

## 4. Técnicas
| id | name (≤16) | description (≤44) |
|---|---|---|
| `tech_boxing_1` | Jab duplo (9) | Um pra medir, outro pra doer. (29) |
| `tech_boxing_2` | Esquiva e volta (15) | A cabeça sai da frente. A mão, não. (34) |
| `tech_bjj_1` | Guarda fechada (14) | Entrou, não sai. Nem pra tomar água. (36) |
| `tech_bjj_2` | Raspagem (9) | Embaixo é só o começo. (22) |

## 5. Artes (`arts.json`) e janela de escolha
Cada cartão mostra: ícone, nome, `tagline`, `rule_text`, `fight_text`, botão ESCOLHER.

| id | name | tagline (≤44) | rule_text | fight_text |
|---|---|---|---|---|
| `boxing` | Boxe | Mão rápida, cabeça fria. Quem clica, manda. (43) | +{pct}% TREINO NO CLIQUE DA SUA MÃO | BOXE: +{pct}% DE DANO |
| `bjj` | Jiu-jitsu | Sem pressa. Quanto mais tempo, mais aperta. (43) | EQUIPE +{pct}% (SOBE {rate}% POR MINUTO ATÉ {cap}%) | JIU-JITSU: -{pct}% DE DANO RECEBIDO |

Mudança no `rule_text` do Boxe: "NO CLIQUE DA SUA MÃO" deixa claro, sem número, que Metrônomo e assistido ficam de fora.

## 6. Aba ESTILO (`skill_tree`)
| id | name (≤16) | description (≤44) | effect_text |
|---|---|---|---|
| `style_boxing` | Mão de sino (11) | A pera aprendeu seu nome. E seu ritmo. (38) | BOXE: BÔNUS DO CLIQUE CRESCE {pct}% |
| `style_bjj` | Peso do tempo (13) | O tatame ensina: quem espera, aperta. (37) | JIU-JITSU: BÔNUS DA EQUIPE CRESCE {pct}% |

Ramo `style`: nome "ESTILO". O `effect_text` usa só `{pct}` (50), então o texto acompanha o JSON. Os números finais (+50% para +75%, teto +150%) aparecem em `tree_short_style_*`.

## 7. Textos de mudança, chegada e recusa na LOJA
| momento | chave | texto |
|---|---|---|
| Aviso do cinturão | `belt_unlock` | ACADEMIA BOA ESQUINA LIBERADA |
| Dica do cinturão | `belt_hint` | MUDE PARA A ACADEMIA OU APOSENTE COM O CINTURÃO. |
| Janela/bloco do MUDAR | `move_title` | ACADEMIA BOA ESQUINA |
| Chegada (toast) | `move_arrived` | BEM-VINDO À BOA ESQUINA! |
| Recusa na LOJA | `move_reserve` | GUARDE ${n} PARA A MUDANÇA |

## 8. Dicas de fim de carreira
As `tip_unlock_*` por aparelho seguem o padrão da 4b. As demais são **chaves novas fora da lista do design**; só entram se o Designer/Programador aprovarem (ver "Pedidos"). Todas até 42 caracteres.

| chave | quando | textos |
|---|---|---|
| `tip_unlock_speed_bag` | morreu sem a pera (Boxe) | COMPRE A PERA CEDO NA PRÓXIMA CARREIRA / PERA CEDO. MÃO RÁPIDA NÃO SE IMPROVISA / A PLATAFORMA ESTÁ VAZIA. PEGUE A PERA |
| `tip_unlock_grappling_dummy` | morreu sem o boneco (Jiu-jitsu) | COMPRE O BONECO CEDO NA PRÓXIMA CARREIRA / BONECO CEDO. ELE NUNCA RECLAMA / O TATAME ESTÁ LIVRE. PEGUE O BONECO |
| `tip_gym_loss` | derrota na academia | A CASA COBRA CARO. ESPERE O VERDE / NA ACADEMIA, AMARELO JÁ É APOSTA ALTA / APOSENTAR TAMBÉM É UMA BOA LUTA |
| `tip_art_boxing` | derrota jogando de Boxe | BOXE GOSTA DE MÃO. CLIQUE VOCÊ MESMO / O METRÔNOMO NÃO TEM O BÔNUS DO BOXE / COMPRE A PERA CEDO. ELA TREINA POR TRÊS |
| `tip_art_bjj` | derrota jogando de Jiu-jitsu | JIU-JITSU PREMIA O TEMPO. NÃO CORRA / MONTE EQUIPE: O JIU-JITSU MULTIPLICA / COMPRE O BONECO CEDO. ELE TREINA POR TRÊS |
| `tip_move_belt` | aposentou com o cinturão sem mudar | NA PRÓXIMA, MUDE PARA A ACADEMIA / GUARDE O DINHEIRO. A BOA ESQUINA ESPERA / TREINO EM DOBRO SÓ DEPOIS DO CINTURÃO |
| `hint_retire_gym` | dica do Designer (10.7, depende do Diretor) | APOSENTAR AGORA LEVA {n} DE LEGADO |

Nota: "TREINO EM DOBRO" fixa o ×2 no texto; se o Designer mudar `training_mult`, trocar por "MAIS TREINO".

## 9. Bloco JSON de `data/ui_texts.json` (chaves do design)
```json
{
	"belt_unlock": "ACADEMIA BOA ESQUINA LIBERADA",
	"belt_hint": "MUDE PARA A ACADEMIA OU APOSENTE COM O CINTURÃO.",
	"move_title": "ACADEMIA BOA ESQUINA",
	"move_button": "MUDAR",
	"move_price": "${n}",
	"move_effect": "TREINO x{mult} / 2 LUTAS DA CASA",
	"move_keeps": "TUDO O QUE VOCÊ COMPROU VAI JUNTO",
	"move_no_money": "Falta dinheiro",
	"move_reserve": "GUARDE ${n} PARA A MUDANÇA",
	"move_arrived": "BEM-VINDO À BOA ESQUINA!",
	"move_per_career": "VALE ATÉ O FIM DESTA CARREIRA",
	"hud_next_move": "PRÓXIMA: MUDE PARA A ACADEMIA",
	"hud_location_mult": "ACADEMIA: TREINO x{mult}",
	"no_more_fights_gym": "VOCÊ VENCEU A ACADEMIA. APOSENTAR VALE MAIS.",
	"art_title": "QUE TIPO DE LUTADOR VOCÊ QUER SER?",
	"art_sub_first": "AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE",
	"art_sub_career": "CARREIRA {n}: ESCOLHA A ARTE",
	"art_choose": "ESCOLHER",
	"art_whole_career": "VALE A CARREIRA INTEIRA",
	"art_last": "ÚLTIMA: {nome}",
	"hud_art_boxing": "BOXE: +{pct}% NO SEU CLIQUE",
	"hud_art_bjj": "JIU-JITSU: EQUIPE +{pct}%",
	"hud_art_bjj_max": "JIU-JITSU: EQUIPE +{pct}% (MÁX.)",
	"focus_split": "FOR {f}% / AGI {a}% / RES {r}%",
	"career_card_art": "ARTE: {nome}",
	"sum_art": "ARTE",
	"tree_branch_style": "ESTILO",
	"tree_short_style_boxing": "BOXE +{pct}%",
	"tree_short_style_bjj": "JIU-JITSU +{pct}%",
	"tree_style_art_only": "SÓ VALE JOGANDO DE {nome}",
	"tip_unlock_speed_bag": [
		"COMPRE A PERA CEDO NA PRÓXIMA CARREIRA",
		"PERA CEDO. MÃO RÁPIDA NÃO SE IMPROVISA",
		"A PLATAFORMA ESTÁ VAZIA. PEGUE A PERA"
	],
	"tip_unlock_grappling_dummy": [
		"COMPRE O BONECO CEDO NA PRÓXIMA CARREIRA",
		"BONECO CEDO. ELE NUNCA RECLAMA",
		"O TATAME ESTÁ LIVRE. PEGUE O BONECO"
	]
}
```
Mudanças em relação ao rascunho do Designer: `·` virou `/` em `move_effect` e `focus_split` (a fonte 5x7 pode não ter); `move_title`, `move_arrived` e `belt_unlock` usam o nome da academia; `belt_hint` sem alteração.

Bloco opcional (só com aprovação das chaves novas e do `hint_retire_gym`):
```json
{
	"move_reserve_short": "GUARDE ${n}",
	"tip_gym_loss": [
		"A CASA COBRA CARO. ESPERE O VERDE",
		"NA ACADEMIA, AMARELO JÁ É APOSTA ALTA",
		"APOSENTAR TAMBÉM É UMA BOA LUTA"
	],
	"tip_art_boxing": [
		"BOXE GOSTA DE MÃO. CLIQUE VOCÊ MESMO",
		"O METRÔNOMO NÃO TEM O BÔNUS DO BOXE",
		"COMPRE A PERA CEDO. ELA TREINA POR TRÊS"
	],
	"tip_art_bjj": [
		"JIU-JITSU PREMIA O TEMPO. NÃO CORRA",
		"MONTE EQUIPE: O JIU-JITSU MULTIPLICA",
		"COMPRE O BONECO CEDO. ELE TREINA POR TRÊS"
	],
	"tip_move_belt": [
		"NA PRÓXIMA, MUDE PARA A ACADEMIA",
		"GUARDE O DINHEIRO. A BOA ESQUINA ESPERA",
		"TREINO EM DOBRO SÓ DEPOIS DO CINTURÃO"
	],
	"hint_retire_gym": "APOSENTAR AGORA LEVA {n} DE LEGADO"
}
```

## 10. Blocos JSON dos outros arquivos (só campos de texto)
```json
// data/locations.json, locations[gym]
"name": "Academia Boa Esquina",
"ambience": "Pôster desbotado, mensalidade atrasada e um espelho que trinca onde você bate.",
"move_button": "MUDAR",
"move_description": "Sai da garagem. Mais treino e 2 lutas novas."

// data/arts.json
"boxing": { "name": "Boxe", "tagline": "Mão rápida, cabeça fria. Quem clica, manda.",
            "rule_text": "+{pct}% TREINO NO CLIQUE DA SUA MÃO", "fight_text": "BOXE: +{pct}% DE DANO" },
"bjj":    { "name": "Jiu-jitsu", "tagline": "Sem pressa. Quanto mais tempo, mais aperta.",
            "rule_text": "EQUIPE +{pct}% (SOBE {rate}% POR MINUTO ATÉ {cap}%)", "fight_text": "JIU-JITSU: -{pct}% DE DANO RECEBIDO" }

// data/training.json, speed_bag
"name": "Pera veloz",
"unlock": { "name": "Pera", "description": "Pequena, veloz e sem perdão pra distraído.", "arrives_as": "Presa na parede. Alguém jurou que aguenta." },
"focus_label": ["BOXE", "PERA"], "first_hint": "Clique na pera: força e agilidade juntas",
"crit_texts": ["TRA-TRA-TRA!", "RITMO DE SINO!", "A PERA SUMIU!", "MÃO DE RELÓGIO!", "NEM VIU VOLTAR!"],
"upgrades": [ { "id": "tech_boxing_1", "name": "Jab duplo", "description": "Um pra medir, outro pra doer." },
              { "id": "tech_boxing_2", "name": "Esquiva e volta", "description": "A cabeça sai da frente. A mão, não." } ]

// data/training.json, grappling_dummy
"name": "Boneco de tatame",
"unlock": { "name": "Boneco", "description": "Não reclama, não bate, não desiste.", "arrives_as": "Veio num tatame velho. Cheira a vestiário." },
"focus_label": ["JIU-JITSU", "BONECO"], "first_hint": "Clique no boneco: resistência e força juntas",
"crit_texts": ["ENCAIXOU!", "GUARDA PASSADA!", "PEGOU AS COSTAS!", "PEDIU TAPA!", "O TATAME GEMEU!"],
"upgrades": [ { "id": "tech_bjj_1", "name": "Guarda fechada", "description": "Entrou, não sai. Nem pra tomar água." },
              { "id": "tech_bjj_2", "name": "Raspagem", "description": "Embaixo é só o começo." } ]

// data/skill_tree.json
"style_boxing": { "name": "Mão de sino", "description": "A pera aprendeu seu nome. E seu ritmo.", "effect_text": "BOXE: BÔNUS DO CLIQUE CRESCE {pct}%" },
"style_bjj":    { "name": "Peso do tempo", "description": "O tatame ensina: quem espera, aperta.", "effect_text": "JIU-JITSU: BÔNUS DA EQUIPE CRESCE {pct}%" }

// data/opponents.json
"opp_gym_1": { "name": "Tonhão do Tatame", "description": "Faixa roxa de cor duvidosa. Pesa e não sai.",
               "entry": "Aqui o tatame é meu. Fica à vontade.", "wins_line": "Bem-vindo à academia. Paga a mensalidade.", "loses_line": "Tá bom, pode ficar. Cuidado com o espelho." },
"opp_gym_2": { "name": "Kid Navalha", "description": "Campeão da casa. Corta o ar e a conversa.",
               "entry": "Eu vi você chegar de chinelo.", "wins_line": "Volta quando a garagem te soltar.", "loses_line": "Amanhã cedo. Você e eu. De novo." }
```
(Os comentários `//` acima são só explicação; não colar nos JSON.)

## Pedidos e avisos
1. **Larguras para a `alinhamento-ui`:** "GUARDE $1.000 PARA A MUDANÇA" (28) no botão da LOJA (se não couber, usar `move_reserve_short`: "GUARDE $1.000"); "JIU-JITSU: EQUIPE +150% (MÁX.)" (30) perto do foco; o `rule_text` do Jiu-jitsu (~42) no cartão da janela de arte.
2. **Chaves novas (seção 8, bloco opcional)** pedem o aceite do Designer/Programador. Sem elas, o jogo funciona com `tip_unlock_*` e as dicas já existentes.
3. **Aparelhos do Boneco:** o plaquinha da fita no chão sai "BONECO - 2.5K TREINO" se a plaquinha usar `unlock.name`; se usar `name`, "BONECO DE TATAME" não cabe (16). Usar `unlock.name`.
4. `docs/narrativa.md` atualizado com a academia, os 2 adversários e as artes.
