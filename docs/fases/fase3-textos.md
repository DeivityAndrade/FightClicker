# Fase 3 — Textos das lutas e do fim de carreira

Dono: Roteirista. Versão 1 (2026-11-05). Só texto: números e fórmulas ficam com o Designer.
Limites: nome até 16 caracteres, descrição/frase até 44, tudo exibido em MAIÚSCULAS (aqui em caixa normal para leitura).
Acentos mantidos. `{n}`, `{nome}`, `{k}` são variáveis que o código preenche. Ids em inglês são propostas de chave para `data/ui_texts.json`.
Voz: dinheiro curto, bairro, humor seco. Ninguém grita. Nada de humilhar o jogador.

Convenção das falas: **entrada** = prévia da luta; **ele ganha** = aparece quando o jogador perde para ele; **ele perde** = aparece quando o jogador vence.

## 1. Adversários (escada amadora)

### 1.1 `opp_warmup` — Dudu Alongado (perfil: equilibrado, fraco)
| Campo | Texto |
|---|---|
| Nome (13) | Dudu Alongado |
| Descrição (41) | Alonga mais do que luta. Bom pra começar. |
| Entrada | Tô só esquentando. Pode vir. |
| Ele ganha | Foi aquecimento pra mim. Foi mal. |
| Ele perde | Eu ainda nem tinha alongado o ombro. |
| Perfil na prévia | EQUILIBRADO |

Aparência (Arte): magro, médio, regata branca e calção de futebol sem escudo. Detalhe marcante: meiões brancos até o joelho e faixa de cabeça mole. Paleta neutra (branco, cinza, verde-musgo), nada que grite. Postura de quem se alonga entre os golpes.

### 1.2 `opp_strong` — Brutão do Posto (perfil: muita Força)
| Campo | Texto |
|---|---|
| Nome (15) | Brutão do Posto |
| Descrição (41) | Carrega botijão no braço. Derruba parede. |
| Entrada | Carrego botijão. Você é mais leve. |
| Ele ganha | Foi só um empurrãozinho. |
| Ele perde | Alguém anota a placa desse soco. |
| Perfil na prévia | FORTE |

Aparência (Arte): o maior e mais largo da escada, ombros enormes, pescoço curto. Regata cinza manchada de graxa, macacão azul amarrado na cintura, boné do posto de gasolina. Detalhe marcante: luvas remendadas com fita isolante vermelha. Dominante vermelho-queimado.

### 1.3 `opp_fast` — Dinho Pulga (perfil: muita Agilidade)
| Campo | Texto |
|---|---|
| Nome (11) | Dinho Pulga |
| Descrição (38) | Você pisca e ele já bateu. Duas vezes. |
| Entrada | Se piscar, perde. Já perdeu. |
| Ele ganha | Nem vi você cair. Sério. |
| Ele perde | Tropecei. Conta como tropeço. |
| Perfil na prévia | RÁPIDO |

Aparência (Arte): baixo e magro, sempre na ponta do pé. Moletom azul com capuz para trás, bandana na testa, tênis laranja gasto. Detalhe marcante: o cadarço desamarrado que balança a cada passo. Dominante azul. Silhueta mais leve que a dos outros, pose de quem pula.

### 1.4 `opp_tank` — Seu Muralha (perfil: muita vida, luta do cinturão)
| Campo | Texto |
|---|---|
| Nome (11) | Seu Muralha |
| Descrição (36) | Dono do cinturão. Não cai, só cansa. |
| Entrada | O cinturão é meu há onze anos. |
| Ele ganha | O cinturão fica. Eu também. |
| Ele perde | Onze anos. Pode levar. Pesa. |
| Perfil na prévia | RESISTENTE |

Aparência (Arte): alto, largo e parado, barriga firme, bigode grisalho. Camiseta amarela de um time de várzea que já acabou. Detalhe marcante: o cinturão amador de pano e fivela torta, sempre na cintura (é o mesmo que o jogador ganha). Dominante amarelo. Anda devagar, bate devagar, não cai.

## 2. Táticas

| id | Botão (≤16) | Dica (≤44) |
|---|---|---|
| `aggressive` | AGRESSIVO | Bate mais forte. Defende pior. |
| `defensive` | DEFENSIVO | Fecha a guarda. O crítico dele não entra. |
| `counter` | CONTRA-ATAQUE | Esquiva mais e responde com golpe extra. |

Rótulo da seção: `tactic_label` TÁTICA.

## 3. Prévia da luta

| chave | Texto |
|---|---|
| `preview_title` | PRÓXIMA LUTA |
| `preview_him` | ELE |
| `preview_you` | VOCÊ |
| `risk_easy` | FÁCIL |
| `risk_even` | EQUILIBRADO |
| `risk_hard` | PERIGOSO |
| `risk_label` | RISCO |
| `fight_button` | LUTAR! |
| `back_button` | VOLTAR A TREINAR |
| `lead_strength` | ELE É MUITO MAIS FORTE |
| `lead_agility` | ELE É MUITO MAIS RÁPIDO |
| `lead_endurance` | ELE AGUENTA MUITO MAIS |
| `stake_win` | SE VENCER: ${n} + {n} FAMA |
| `stake_belt` | SE VENCER: O CINTURÃO AMADOR |
| `stake_lose` | PERDER ENCERRA A CARREIRA (METADE DO LEGADO) |
| `time_rule` | SEM K.O. NO TEMPO: VENCE QUEM TEM MAIS VIDA |

Nomes dos atributos na prévia: FORÇA, AGILIDADE, RESISTÊNCIA (os mesmos da garagem).
| `time_rule_tie` | EMPATE EXATO: FICA COM ELE |

(`time_rule_tie` é a linha de regra do empate exato no limite de tempo: o empate fica com o adversário. 26 caracteres.)

## 4. Durante a luta (arena)

| chave | Texto |
|---|---|
| `fight_dodge` | ESQUIVOU |
| `fight_crit` | {n}! (crítico, número maior) |
| `fight_ko` | K.O.! |
| `fight_points` | POR PONTOS |
| `fight_round` | {n}º ROUND |
| `fight_time` | TEMPO! |

## 5. Vitória e cinturão

| chave | Texto |
|---|---|
| `victory_title` | VENCEU! |
| `victory_gain` | +${n}   +{n} FAMA   +{n} LEGADO |
| `victory_next` | PRÓXIMO: {nome} |
| `belt_title` | CINTURÃO AMADOR |
| `belt_line` | O bairro viu. Uns quinze. |
| `belt_unlock` | ACADEMIA DE BAIRRO LIBERADA (EM BREVE) |
| `belt_hint` | NÃO HÁ MAIS LUTAS NESTA VERSÃO. APOSENTAR VALE MAIS. |
| `no_more_fights` | SEM MAIS ADVERSÁRIOS POR ENQUANTO |

## 6. Tela de fim de carreira (derrota)

Título: `end_defeat_title` **FIM DE CARREIRA**

Quem e quando (uma das duas linhas):
- `end_who_ko`: {nome} VENCEU NO {n}º ROUND
- `end_who_points`: {nome} VENCEU POR PONTOS

Motivo principal com número. O código escolhe o atributo decisivo e sorteia/usa o modelo (os `{n}` vêm da simulação; porcentagens inteiras).

Revisão (v2): o motivo agora é "quanto treino a mais faltou" no atributo decisivo. O formato novo é **FALTARAM {n} DE …** (modelos 1 e 2, `{n}` = treino que faltou, formato da prévia). Os modelos antigos (estatística da luta) viram **alternativa** (modelos 3 e 4), para a segunda linha da tela ou para o caso em que `faltaram` não existe. Tamanhos contados com `{n}` = 3 caracteres.

| atributo | id | Modelo 1 (faltaram) | Modelo 2 (faltaram, outra voz) | Modelo 3 (antigo) | Modelo 4 (antigo) |
|---|---|---|---|---|---|
| Força | `reason_strength` | FALTARAM {n} DE FORÇA PARA ABRIR A GUARDA (41) | FALTARAM {n} DE FORÇA PRA ELE SENTIR O SOCO (43) | ELE BATIA {n}% MAIS FORTE | — |
| Agilidade | `reason_agility` | FALTARAM {n} DE AGILIDADE PARA ALCANÇÁ-LO (40) | FALTARAM {n} DE AGILIDADE PRA ACOMPANHÁ-LO (42) | ELE ESQUIVOU {n}% DOS SEUS GOLPES | ELE ACERTOU {n} CRÍTICOS. VOCÊ, {k} |
| Resistência | `reason_endurance` | FALTARAM {n} DE RESISTÊNCIA PARA FICAR EM PÉ (44) | FALTARAM {n} DE RESISTÊNCIA PRA AGUENTAR (40) | ELE TIROU {n}% DA SUA VIDA EM {k} GOLPES | — |

Dicas de ação (3 variações por atributo; o código usa a do atributo decisivo e pode alternar):

| id | Variação 1 | Variação 2 | Variação 3 |
|---|---|---|---|
| `tip_strength` | TREINE NO SACO ANTES DA PRÓXIMA | MAIS SOCO NO SACO. ELE ACEITA | FORÇA PRIMEIRO. DEPOIS A LUTA |
| `tip_agility` | PULE CORDA ATÉ O ARRASTÃO | MAIS CORDA. FICAR PARADO SAI CARO | AGILIDADE PRIMEIRO. DEPOIS A LUTA |
| `tip_endurance` | TREINE NA ESTEIRA ANTES DA PRÓXIMA | MAIS ESTEIRA. FÔLEGO TAMBÉM LUTA | RESISTÊNCIA PRIMEIRO. DEPOIS A LUTA |
| `tip_tactic` (se a tática errada decidiu) | TENTE OUTRA TÁTICA NA PRÓXIMA | A TÁTICA CERTA MUDA O RISCO. OLHE A PRÉVIA | TÁTICA TAMBÉM É TREINO |

### 6.1 Correção pós-QA (v3): azar, estatísticas e segurança

Chaves novas em `data/ui_texts.json`. Listas em array, como `reason_*`/`tip_*`. Todas até 44 caracteres (com `{n}` de 2–3 dígitos).

| chave | tipo | Texto |
|---|---|---|
| `reason_luck` | lista (3) | ERA PRA SER SUA. DEU AZAR. / A PRÉVIA DIZIA FÁCIL. A LUTA NÃO LEU. / TUDO CERTO, MENOS O ACASO. |
| `tip_luck` | lista (3) | O TREINO ESTAVA CERTO. REPITA O CAMINHO / LUTE DE NOVO. O TREINO NÃO TEM CULPA / AZAR PASSA. LUVA E TREINO FICAM |
| `stat_stronger_x` (`{n}` 2–9) | texto | UM SOCO DELE VALIA {n} DOS SEUS |
| `stat_stronger_cap` (`{n}` = 10) | texto | UM SOCO DELE VALIA MAIS DE {n} DOS SEUS |
| `stat_points` (`{n}`, `{k}` em %) | texto | NO GONGO: VOCÊ {n}% DA VIDA, ELE {k}% |
| `stat_luck_odds` (`{n}` 1–10) | texto | ISSO ACONTECE EM {n} DE CADA 100 LUTAS |
| `stat_luck_rare` | texto | ISSO QUASE NUNCA ACONTECE |
| `reason_far` (`{n}` ≥ 2) | texto | ELE TINHA {n}X O SEU TREINO |
| `reason_far_plain` | texto | TREINE MUITO MAIS ANTES DE ENCARAR ELE |

Notas: `stat_points` foi encurtado em relação ao rascunho (45 caracteres no pior caso, 100% / 100%) para caber em 44. `tip_luck` não culpa atributo nem treino.

Resumo da carreira (rótulos):

| chave | Texto |
|---|---|
| `sum_title` | RESUMO DA CARREIRA {n} |
| `sum_wins` | VITÓRIAS |
| `sum_belts` | CINTURÕES |
| `sum_fame` | FAMA |
| `sum_money` | DINHEIRO GANHO |
| `sum_time` | TEMPO DE JOGO |
| `sum_legacy_gain` | LEGADO GANHO |
| `sum_legacy_total` | LEGADO TOTAL |
| `legacy_note` | O LEGADO FICA GUARDADO. VAI SERVIR NA PRÓXIMA VERSÃO. |
| `new_career_button` | NOVA CARREIRA |

Nota: `tip_tactic` (acima) é para quando a tática errada decidiu. A dica do botão DEFENSIVO (seção 2) é outra coisa e já diz que o crítico dele não entra.

Texto de apoio opcional sob o título (uma linha, vira "mentor" na Fase 8): "A luva fica no gancho. O próximo vai achar."

## 7. Aposentar

| chave | Texto |
|---|---|
| `retire_button` | APOSENTAR |
| `retire_confirm_title` | PENDURAR AS LUVAS? |
| `retire_confirm_take` | VOCÊ LEVA {n} DE LEGADO |
| `retire_confirm_bonus` | INCLUI +{n} POR SAIR COM O CINTURÃO |
| `retire_confirm_zero` | VOCÊ LEVA 0 DE LEGADO |
| `retire_confirm_lose` | TUDO DESTA CARREIRA SE PERDE |
| `retire_yes` | APOSENTAR |
| `retire_no` | CONTINUAR |
| `retire_title` | SAIU POR CIMA |
| `retire_line` | O saco fica pro próximo. |
| `retire_line_belt` | Cinturão na parede. Joelho no gelo. |

A tela de aposentadoria reaproveita os rótulos do resumo (seção 6) e o botão NOVA CARREIRA.

## 8. Loja em dinheiro

| chave | Texto |
|---|---|
| `shop_title` | LOJA |
| `shop_sub` | Dinheiro de luta, só aqui. |
| `shop_buy` | COMPRAR |
| `shop_hire` | CONTRATAR |
| `shop_no_money` | Falta dinheiro |

### Gerador pago
| id | Nome | Descrição | Aparece na sala como |
|---|---|---|---|
| `gen_paid_1` | Prof. Nelson | Cobra por hora e confere o relógio. | Homem de moletom do clube do bairro, apito no pescoço e prancheta, no aparelho em foco |

### Luvas de loja (`glove_shop`)
A luva de início segue como **Luva velha** (nome já existente, não muda).

| id | Nível | Nome | Descrição |
|---|---|---|---|
| `glove_l1` | 1 | Luva de lona | Comprada na feira. Ainda cheira a novo. |
| `glove_l2` | 2 | Luva de couro | Costura dupla. Os dedos agradecem. |
| `glove_l3` | 3 (opcional) | Luva de marca | Etiqueta quase original. Pega bem. |

Aparência (Arte): lona = bege com fita branca no pulso; couro = marrom-avermelhado com costura clara; marca = preta com listra amarela torta (a "marca" é inventada, sem logo reconhecível).

## 9. Rótulos novos de HUD

| chave | Texto |
|---|---|
| `hud_money` | DINHEIRO (símbolo `$`, ex.: `$ 120`) |
| `hud_fame` | FAMA |
| `hud_legacy_run` | LEGADO EM JOGO |
| `hud_career` | CARREIRA {n} |
| `hud_next_fight` | PRÓXIMA: {nome} |

Rótulo auxiliar: `hud_legacy_total` LEGADO (para a tela de fim).
