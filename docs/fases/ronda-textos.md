# Ronda Noturna do Gato Preto: textos (Roteirista)

Tudo abaixo já está gravado em `data/ui_texts.json` (chaves novas no fim) e `data/ronda.json` (só campos de texto: descrições dos 3 nós, referência `name` nas ocorrências). Tela em MAIÚSCULAS. Nenhum número foi tocado. Nada de `scripts/` ou `ui/`.

## Decisões de tom
- O **nome GATO PRETO só aparece do nível 1 em diante**: o hover do capuz, a instrução, a contagem e o prêmio dos níveis 0 não dizem o nome. Quem diz primeiro é o jornal (manchete 1).
- O vulto é o discípulo da vez e **o jogo nunca diz isso**. Ninguém (nem o Osmar) sabe quem é. Nenhum texto usa "você" para o vulto, só para a ação ("SEGURE", "CLIQUE").
- Cada manchete parte de algo pequeno e verdadeiro (o estepe, a bicicleta, o portão) e escala até o absurdo. Ninguém apanha: só se assusta.
- Busca por batman/morcego/gotham: sem resultado. Texto 100% original.

## 1. Tela e HUD
| Chave | Texto |
|---|---|
| `hood_hover` (capuz no prego) | SAIR DE NOITE? |
| `night_scare_name` (título da tela, nível 0) | RONDA NOTURNA |
| `night_scare_name_cat` (opcional, nível ≥ 1) | RONDA DO GATO PRETO |
| `night_scare_tip` (instrução na contagem) | SEGURE PARA ANDAR. SOLTE QUANDO ELE OLHAR. PERTO, CLIQUE! |
| `ronda_occ_tire` / `ronda_occ_bike` / `ronda_occ_gate` | LADRÃO DE ESTEPE / MOLEQUE NA BICICLETA / SUJEITO NO PORTÃO |
| `ronda_occ_count` | {n} DE 3 |
| `legend_label` / `ronda_level_label` | LENDA / NÍVEL {n} |
| SAIR / VOLTAR / VAI! | reaproveita `mini_exit`, `mini_back`, `mini_go` (7a2) |

## 2. Avisos e letreiros
| Chave | Texto | Quando |
|---|---|---|
| `ronda_warn_mark` | ? | AVISO do ladrão (o "?" pequeno) |
| `ronda_warn_text` | SOLTE! | opcional, no AVISO |
| `ronda_looking_text` | ELE OLHOU! | opcional, no OLHANDO |
| `ronda_still_hint` | ESTÁTUA | opcional, ao soltar |
| `near_hint` | PERTO! | sinal do HUD (distância ≥ 0,8) |
| `scare_banner` | SUSTO! | letreiro grande, com a tremida |
| `seen_banner` | ESCAPOU! | falha leve, letreiro menor e cinza |

## 3. Prêmio (resumo da noite)
| Chave | Texto |
|---|---|
| `ronda_reward_title` | RONDA FEITA |
| `ronda_reward_legend` | +{n} LENDA |
| `ronda_reward_clean` | RONDA LIMPA (os 3 SUSTOS) |
| `ronda_reward_scares` | SUSTOS: {a} DE 3 |
| `ronda_reward_line` (array, índice = nº de SUSTOS 0..3) | A NOITE PASSOU EM SILÊNCIO. A LENDA ANOTOU. / UM LADRÃO ASSUSTADO. BOM COMEÇO. / DOIS LADRÕES ASSUSTADOS. O BAIRRO RONCA. / TRÊS SUSTOS. O BAIRRO DORME EM PAZ. |
| `ronda_left_line` (saiu pelo SAIR) | VOLTOU CEDO. O CAPUZ VOLTA PARA O PREGO. |
| `ronda_dawn_line` (acabou o tempo, `fim_tempo`) | AMANHECEU. O RESTO FICA PARA OUTRA NOITE. |
| `ronda_count` (depois do nível 5) | OCORRÊNCIAS: {n} |
| `ronda_level_up` | A LENDA CRESCEU |
| `ronda_level_up_line` (array, índice = nível novo − 1) | O JORNAL BATIZOU O VULTO. / O BAIRRO JÁ CONTA A HISTÓRIA. / TEM FAIXA NA RUA. NINGUÉM ASSUME. / CRIANÇA DE ORELHINHA NA JANELA. / O BAIRRO INTEIRO TEM O GATO NA PAREDE. |
| `ronda_banner_text` (faixa da rua, nível 3+) | VALEU, GATO PRETO |

## 4. As 5 manchetes (hover do recorte e "jornal do dia seguinte")
| Nível | Chave | Manchete |
|---|---|---|
| 0 (já existia) | `black_cat_clipping` | VULTO MASCARADO ASSUSTA LADRÃO PERTO DA BORRACHARIA |
| 1 | `black_cat_clipping_1` | É O GATO PRETO! VULTO DA BORRACHARIA GANHA NOME |
| 2 | `black_cat_clipping_2` | GATO PRETO ASSUSTA LADRÕES DE ESTEPE, BICICLETA E PORTÃO |
| 3 | `black_cat_clipping_3` | GATO PRETO SALTA MURO DE 3 METROS. TESTEMUNHA JURA: 8 |
| 4 | `black_cat_clipping_4` | LADRÕES EVITAM O BAIRRO. ESTEPES VOLTAM SOZINHOS |
| 5 | `black_cat_clipping_5` | GATO PRETO PARA ÔNIBUS COM UMA MÃO. MOTORISTA AGRADECE |
Comprimento: a maior tem 56 caracteres (a de hoje, 51). O `ui_audit` decide se quebra em 2 linhas; se a arte pedir, cortar "MOTORISTA AGRADECE" / "TESTEMUNHA JURA: 8" é seguro, mas perde a piada.

## 5. Região GATO PRETO e nós
| Item | Texto |
|---|---|
| `region_black_cat` / `map_region_black_cat` / `region.name` | GATO PRETO |
| `node_sealed` | PRECISA DA LENDA NÍVEL {n} |
| `node_sealed_name` (nome na silhueta lacrada) | ??? |

| Nó | Nome | Descrição | `effect_text` (já estava) |
|---|---|---|---|
| `cat_rooftop` | Atalho pelos telhados | Quem conhece o bairro de cima chega antes. | COMEÇA A CAMPANHA COM {n} TIOS NA EQUIPE |
| `cat_watch` | O bairro de olho | Ninguém mexe na garagem enquanto a gente treina. | +{n} DIAS DE PREPARO NAS LUTAS DA LIGA |
| `cat_thanks` | O bairro agradece | Tem estepe que voltou para o dono. O dono veio treinar. | +{pct}% TREINO/S DA EQUIPE |
Alterei só as `description` (tirei o "[ROT]"; "você" virou "a gente" no `cat_watch`, para casar com o jeito da Raízes). Os `effect_text` ficaram como o Designer escreveu.

## 6. Osmar e falas (proposta, NÃO gravada)
O design não nomeia nenhuma fala nem gatilho. Para o Osmar não saber quem é, sugiro 1 balão na volta da sala quando a lenda sobe de nível (gatilho novo `legend_level_up`, prioridade 5, adiado, uma vez por nível). Não gravei em `dialogos.json` porque exige uma condição nova (`legend_level`) e eu não quero deixar linhas elegíveis sem o código; o Programador decide se vale. Falas prontas (2 linhas, ≤ 26 caracteres):
| Nível | Fala (coach) |
|---|---|
| 1 | jornal diz: gato preto.\nserá o gato do vizinho? |
| 2 | estepe, bicicleta, portão.\no bairro tá animado. |
| 3 | tem faixa pintada na rua.\nnem a nossa tem faixa. |
| 4 | tem criança de orelhinha.\nnão olha pra mim, não. |
| 5 | parou ônibus com uma mão.\ndevia treinar aqui. |
(Todas com linhas de até 26 caracteres, sem º nem à. Ids sugeridos: `cl_lenda_1..5`, `speaker: "coach"`, `repeat: "once"`.)

## Para o Programador ligar
- `ronda.json → nights.scare.occurrences[].name` é campo novo de texto (chave de `ui_texts`). Se o `RondaData` rejeitar campo desconhecido, ignore-o e leia por `ronda_occ_<id>`.
- Título da tela: `night_scare_name` no nível 0; `night_scare_name_cat` a partir do nível 1 (opcional, pode usar sempre a primeira).
- Prêmio: linha por SUSTOS em `ronda_reward_line[sustos]`; no SAIR use `ronda_left_line`; no `fim_tempo` use `ronda_dawn_line`. Subiu de nível: `ronda_level_up` + `ronda_level_up_line[level − 1]` + a manchete do nível (`clipping_text_by_level[level]`) em grande. `ronda_count` só com o nível 5 já atingido.
- Arrays (`ronda_reward_line`, `ronda_level_up_line`) vêm como em `flyers_took`; índice por valor, nunca sorteio.
- `ronda_warn_text`, `ronda_looking_text`, `ronda_still_hint` são opcionais (a UI/UX decide se cabem no HUD).
- Nó lacrado: título `node_sealed_name`, subtítulo `node_sealed` com `{n}` = nível da trava; só para travas `black_cat:N`.
- As falas do Osmar (§6) dependem de decisão e de gatilho novo.
