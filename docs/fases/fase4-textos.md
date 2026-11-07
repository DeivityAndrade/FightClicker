# Fase 4 — Árvore de habilidades: textos

Dono: Roteirista. Versão 1 (2026-11-06). Base: `fase4-design.md` (seções 3, 4, 10, 14), `narrativa.md`, `data/ui_texts.json`.
Limites: nome ≤ 16 caracteres, descrição ≤ 44, tudo exibido em maiúsculas pela UI. Só texto: números e ids são do Designer.

Tom: a árvore é o que o lutador anterior ensinou ao próximo. Pé no chão, nada de magia. O "velho" é o mentor ainda sem rosto (Fase 8).

## 1. Ramos
| id | nome |
|---|---|
| `body` | CORPO |
| `career` | CARREIRA |

## 2. Nós
`effect_text` usa `{pct}` = `round(100 × value)` e `{n}` = `value`, como o design define. A coluna "Aparece como" é o texto já preenchido.

| id | name | description | effect_text | Aparece como |
|---|---|---|---|---|
| `body_jab` | Jab de base | O velho te ensinou a fechar a guarda. | `+{pct}% TREINO POR CLIQUE` | +100% TREINO POR CLIQUE (x2) |
| `body_muscle_memory` | Memória muscular | A mão lembra o ritmo. Você só assiste. | `COMEÇA COM O METRÔNOMO NO NÍVEL {n}` | COMEÇA COM O METRÔNOMO NO NÍVEL 1 |
| `body_heavy_hands` | Mão pesada | Soco com o peso de quem já caiu. | `+{pct}% TREINO POR CLIQUE` | +50% TREINO POR CLIQUE |
| `body_crew` | Garagem animada | A turma do bairro treina com mais vontade. | `+{pct}% TREINO/S DA EQUIPE` | +50% TREINO/S DA EQUIPE |
| `body_crew_2` | Garagem lotada | Já tem fila pro saco. Ninguém reclama. | `+{pct}% TREINO/S DA EQUIPE` | +50% TREINO/S DA EQUIPE |
| `career_purse` | Bolsa negociada | Você aprendeu a pedir mais antes do gongo. | `+{pct}% DINHEIRO POR VITÓRIA` | +50% DINHEIRO POR VITÓRIA |
| `career_scouting` | Olho clínico | Lê o rival como quem já apanhou dele. | `A PRÉVIA MOSTRA A CHANCE EM %` | (fixo) |
| `career_purse_2` | Empresário local | Um primo cuida da agenda. E do seu caixa. | `+{pct}% DINHEIRO POR VITÓRIA` | +50% DINHEIRO POR VITÓRIA |
| `career_crowd` | Torcida da rua | Uns quinze já sabem seu nome. É um começo. | `+{pct}% FAMA POR VITÓRIA` | +50% FAMA POR VITÓRIA |
| `career_good_loser` | Saber cair | Cair direito sai mais barato. | `+{pct}% DO LEGADO NA DERROTA` | +25% DO LEGADO NA DERROTA |

Notas:
- "Olho de treinador" (provisório) passou a **Olho clínico** por estourar 16 caracteres.
- `body_jab` foi pedido como "TREINO POR CLIQUE x2". Se o Programador preferir texto fixo em vez de `{pct}`, use `TREINO POR CLIQUE x2` neste nó (`click_bonus` 1.0 = dobra) e `+50% TREINO POR CLIQUE` no `body_heavy_hands`. Com `{pct}` o texto acompanha o JSON se o Designer mudar o valor.
- `career_good_loser`: o `+25%` é a soma ao 50% base (derrota passa a levar 75%). A prévia mostra o total real via `stake_lose_pct`.

## 3. Metrônomo (`data/shop.json`, bloco `metronome`)
| id | name | description | appears_as (prateleira) |
|---|---|---|---|
| `metronome` | Metrônomo | Marca o ritmo. Seu lutador acompanha. | Metrônomo de feira na prateleira, pêndulo no andamento |
| `metronome_l1` | Pêndulo lento | Preguiçoso, mas não perde a hora. | Metrônomo de feira, pêndulo preguiçoso |
| `metronome_l2` | Pêndulo firme | Agora o saco sente o compasso. | Metrônomo de madeira, pêndulo firme |
| `metronome_l3` | Pêndulo afinado | Quase tão rápido quanto a sua mão. Quase. | Metrônomo de palco, pêndulo veloz |

O efeito em número ("1 SOCO A CADA 2.0 S") vem de `shop_metronome_effect`, então as descrições não repetem número.

## 4. Chaves de `data/ui_texts.json` (novas e alteradas)
| chave | placeholders | texto |
|---|---|---|
| `tree_button` | — | ÁRVORE |
| `tree_title` | — | O QUE O VELHO TE ENSINOU |
| `tree_legacy` | `{n}` | LEGADO: {n} |
| `tree_branch_body` | — | CORPO |
| `tree_branch_career` | — | CARREIRA |
| `tree_buy` | `{n}` | {n} DE LEGADO |
| `tree_owned` | — | APRENDIDO |
| `tree_missing` | `{n}` | FALTAM {n} |
| `tree_locked` | `{nome}` | PEDE: {nome} |
| `tree_new_career` | — | NOVA CARREIRA |
| `career_card_title` | `{n}` | CARREIRA {n} — O QUE VOCÊ TROUXE: |
| `legacy_nodes_label` | `{n}` | LEGADO: {n} NÓS |
| `revenge_mark` | — | VOCÊ PERDEU PRA ELE |
| `victory_revenge` | — | REVANCHE! |
| `tip_wait_green` | — | VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE |
| `preview_wait_green` | — | ESPERE FICAR VERDE |
| `preview_percent` | `{n}` | {n}% |
| `stake_bonus` | `{n}` | (+{n}%) |
| `stake_lose_pct` | `{n}` | PERDER ENCERRA A CARREIRA ({n}% DO LEGADO) |
| `shop_metronome_effect` | `{s}` | 1 SOCO A CADA {s} S |
| `victory_gain` (alterada) | `{n}` x3 | +${n}   +{n} FAMA   +{n} LEGADO EM JOGO |

Observações para o Programador:
- `victory_revenge` fica sem `{nome}`: o design admite uma linha extra com o nome, e se quiserem uma, use `victory_next`/`end_who_*` já existentes. Se quiserem a linha, sugestão de chave nova: `victory_revenge_line` = "{nome} NÃO ESPERAVA ESSA." (humor seco, sem placeholders extras além de `{nome}`).
- `stake_win` hoje tem dois `{n}` e `stake_bonus` entra depois de cada valor: "SE VENCER: $75 (+50%) + 15 FAMA (+50%)". Quem monta a string decide a ordem; `stake_win` pode ficar como está.
- `legacy_note` sai da tela de fim (a chave pode ficar sem uso).
- `tree_title` é de tom (o "velho" é o mentor); se a janela for estreita, a variante curta é "O QUE O VELHO ENSINOU".

## 6. Textos curtos da árvore

Limite da tela: 16 caracteres por linha (fonte 5x7, ~104 px úteis). Contagem com placeholders no pior caso (`{pct}` com 3 dígitos, `{n}` com 1 a 2 dígitos). Maiúsculas aplicadas pela UI.

| id | `effect_short` | Pior caso | Chars |
|---|---|---|---|
| `body_jab` | `+{pct}% CLIQUE` | +100% CLIQUE | 12 |
| `body_muscle_memory` | `METRÔNOMO NÍV {n}` | METRÔNOMO NÍV 10 | 16 |
| `body_heavy_hands` | `+{pct}% CLIQUE` | +100% CLIQUE | 12 |
| `body_crew` | `+{pct}% EQUIPE` | +100% EQUIPE | 12 |
| `body_crew_2` | `+{pct}% EQUIPE` | +100% EQUIPE | 12 |
| `career_purse` | `+{pct}% DINHEIRO` | +100% DINHEIRO | 14 |
| `career_scouting` | `PRÉVIA COM %` | (fixo) | 12 |
| `career_purse_2` | `+{pct}% DINHEIRO` | +100% DINHEIRO | 14 |
| `career_crowd` | `+{pct}% FAMA` | +100% FAMA | 10 |
| `career_good_loser` | `+{pct}% LEGADO` | +100% LEGADO | 12 |

Estado trancado (nome do nó não aparece na linha curta):
| chave | placeholders | texto | Chars |
|---|---|---|---|
| `tree_requires_short` | — | PEDE O DE CIMA | 14 |
| `tree_requires` (tooltip) | `{nome}` | PRIMEIRO APRENDA: {nome} | tooltip, sem limite de 16 |

`name_short`: **não precisa**. Nomes mais longos: "Memória muscular" (16) e "Empresário local" (16); todos os outros têm 14 ou 15. Nenhum passa de 16.

Notas:
- `tree_locked` (`PEDE: {nome}`) fica só para o tooltip/painel largo; no nó use `tree_requires_short`.
- `body_muscle_memory` perde a palavra "COMEÇA" por espaço; a descrição do nó ("A mão lembra o ritmo...") e o tooltip carregam o sentido, e o tooltip pode usar o `effect_text` longo da tabela 2.
- Os `effect_text` longos da tabela 2 continuam valendo para tooltip e tela larga.

Snippet JSON (chaves novas; `effect_short` vai por nó em `data/`):
```json
"tree_requires_short": "PEDE O DE CIMA",
"tree_requires": "PRIMEIRO APRENDA: {nome}"
```

## 5. Snippet pronto para colar (JSON)
```json
"tree_button": "ÁRVORE",
"tree_title": "O QUE O VELHO TE ENSINOU",
"tree_legacy": "LEGADO: {n}",
"tree_branch_body": "CORPO",
"tree_branch_career": "CARREIRA",
"tree_buy": "{n} DE LEGADO",
"tree_owned": "APRENDIDO",
"tree_missing": "FALTAM {n}",
"tree_locked": "PEDE: {nome}",
"tree_new_career": "NOVA CARREIRA",
"career_card_title": "CARREIRA {n} — O QUE VOCÊ TROUXE:",
"legacy_nodes_label": "LEGADO: {n} NÓS",
"revenge_mark": "VOCÊ PERDEU PRA ELE",
"victory_revenge": "REVANCHE!",
"tip_wait_green": "VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE",
"preview_wait_green": "ESPERE FICAR VERDE",
"preview_percent": "{n}%",
"stake_bonus": "(+{n}%)",
"stake_lose_pct": "PERDER ENCERRA A CARREIRA ({n}% DO LEGADO)",
"shop_metronome_effect": "1 SOCO A CADA {s} S",
"victory_gain": "+${n}   +{n} FAMA   +{n} LEGADO EM JOGO"
```
