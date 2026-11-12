# Fase 5.1: API para a UI (caixa de equipamento, save v7)

Contrato do Programador para o UI/UX. Tudo em `GameState` (autoload). Nada de `ui/` ou `scenes/` foi mexido.

## 1. Regras que a lógica já garante (a UI não precisa reimplementar)
- Comprar aparelho com `unlock` (esteira, corda, pera, boneco) ou luva (lona, couro) **não monta nada**: cria uma caixa em `caixas()`.
- 3 batidas (`box.clicks_to_open`) abrem. No 3º clique o estado já mudou (aparelho montado e com foco, ou luva valendo) e já salvou; a animação de 1,2 s é só visual.
- Corda e aparelho da arte só ficam à venda com a **esteira aberta** (`estado_aparelho` devolve `"locked"` enquanto ela está na caixa).
- A próxima luva só fica à venda com a anterior **aberta** (`pode_comprar_luva()` false; `luva_em_caixa()` true: mostrar `shop_glove_boxed`).
- `definir_foco()` recusa aparelho na caixa. As teclas 1 a 4 devem usar `definir_foco`/`estado_aparelho == "owned"`.
- `clicar()` e a tecla Espaço **nunca** tocam em caixa; `bater_caixa()` não treina, não dá crítico e não emite `clicou`. Só o mouse chama `bater_caixa`.
- `bater_caixa` é ignorado com `acoes_bloqueadas()` (luta, tela de fim, janela de escolha de arte). Janelas da UI (árvore, aposentar, prévia): chamar `GameState.definir_modal(true)` não basta, a UI deve simplesmente não chamar `bater_caixa` com janela aberta.
- Caixas sobrevivem a foco, luta, janelas, MUDAR, salvar e reabrir. Somem em NOVA CARREIRA, sem reembolso.

## 2. Consultas
| Função | Devolve |
|---|---|
| `caixas() -> Array` | cópia de `[{item, kind, hits}]`, na ordem da compra. `kind` = `"apparatus"` \| `"glove"`; `item` = id do aparelho (`treadmill`, `jump_rope`, `speed_bag`, `grappling_dummy`) ou da luva (`glove_l1`, `glove_l2`); `hits` 0..2 |
| `tem_caixa(item) -> bool` | o item está numa caixa fechada |
| `caixa(item) -> Dictionary` | a caixa do item ou `{}` |
| `cliques_faltando(item) -> int` | para `box_hover_left` (`{n}`); 0 se não há caixa |
| `luva_em_caixa() -> bool` | há luva esperando |
| `luvas_abertas() -> int` | luvas que valem (`nivel_luva` menos a da caixa) |
| `estado_aparelho(id)` | agora também `"boxed"` (comprado, na caixa). Demais: `owned`, `buyable`, `missing`, `locked`, `absent` |
| `nivel_luva` | **luvas compradas** (abertas + a da caixa). Para o que vale/aparece equipado, usar `luvas_abertas()`, `luva_equipada()`, `sufixo_luva()`, `multiplicador_luva()` (já usam as abertas) |
| `proxima_luva()` | próxima da linha (`{}` só se a linha acabou). Com luva em caixa ela **não** está à venda: olhar `luva_em_caixa()`/`pode_comprar_luva()` |
| `menor_preco_loja()` | já ignora a luva enquanto a anterior está na caixa |

## 3. Ações
| Função | O que faz |
|---|---|
| `comprar_aparelho(id)` | gasta Treino, cria a caixa, salva, emite `caixa_criada` |
| `comprar_luva()` | gasta Dinheiro, `nivel_luva += 1`, cria a caixa, salva, emite `caixa_criada` |
| `bater_caixa(item) -> bool` | soma 1 batida e emite `caixa_batida(item, n)` (n = 1, 2, 3); na 3ª chama `abrir_caixa`. false se não há caixa ou `acoes_bloqueadas()` |
| `abrir_caixa(item) -> bool` | abre já (usada pela 3ª batida; pública para teste/debug). Não checa bloqueio |

## 4. Sinais (novos)
| Sinal | Quando |
|---|---|
| `caixa_criada(item, tipo)` | compra: a UI põe a caixa no slot e toca a chegada |
| `caixa_batida(item, batidas)` | cada clique (1, 2 e 3); tremida de 1, 2, 3 px. A 3ª vem logo seguida de `caixa_aberta` |
| `caixa_aberta(item, tipo)` | item já aplicado e **já salvo**. A UI roda a animação de 1,2 s (`box.open_seconds`) |
| `caixas_mudaram()` | lista trocada de uma vez (carga do save, NOVA CARREIRA, reabrir): recriar todas as caixas dos slots |

Na abertura saem, nesta ordem: `caixa_aberta`; para aparelho `aparelho_comprado(id)` e `foco_mudou(foco)` (a UI pode usar `aparelho_comprado` como "montou" e **não** deve tocar a chegada com poeira antiga: a chegada agora é o "tchan" da caixa); para luva `luva_mudou(luvas_abertas, sufixo)`; no fim `economia_mudou`.
`luva_mudou` **não** dispara na compra da luva (ela ainda está na caixa), só ao abrir. Com `applies_to.glove = false` dispara na compra, como na Fase 5.
Se o `applies_to.apparatus_unlock = false`, `comprar_aparelho` volta ao comportamento da Fase 5 (monta na hora, foco, `aparelho_comprado`).

## 5. Dados
`data/training.json -> box` (lido por `TrainingData`; `GameState.dados.*`):
```
box_clicks_to_open (3)   box_open_seconds (1.2)   box_shake_px ([1,2,3])   box_shake_seconds (0.15)
box_idle_wobble_every (4.0)   box_apparatus (applies_to.apparatus_unlock)   box_glove (applies_to.glove)   box_focus_on_open
```
Para o dono voltar a luva ao instantâneo: `"glove": false` no bloco `applies_to`. Bloco ausente = os mesmos padrões.

### Textos (`GameState.dados.ui[chave]`, ou `GameState.texto_ui(chave)` para os de texto simples)
| Chave | Uso |
|---|---|
| `box_label[item]`, `box_stamp[item]` | etiqueta e carimbo (dicionários por id real: `treadmill`, `jump_rope`, `speed_bag`, `grappling_dummy`, `glove_l1`, `glove_l2`). Ler com `GameState.dados.ui.box_label.get(item, "")` (`texto_ui` só devolve string) |
| `box_sender`, `box_to` | "DA ESCOLA" / "PARA O NOVATO" |
| `box_click` | lista `["TOC!", "RACHOU!", "ABRIU!"]` (use `lista_ui("box_click")`) |
| `box_arrived` | toast ao abrir, `{item}` = `box_label[item]` |
| `box_hover_closed` / `box_hover_left` (`{n}`) | hover da caixa (use `cliques_faltando`) |
| `tape_open` (`{nome}`, `{preco}`), `tape_locked` (`{nome}`, `{requisito}`), `tape_locked_box` (`{nome}`, `{requisito}`: quando o requisito está na caixa), `tape_boxed`, `tape_owned`, `tape_short` (`{nome}`, `{n}`) | hover da marca de fita. Escolha: `owned` -> `tape_owned`; `boxed` -> `tape_boxed`; `locked` com o requisito em caixa (`tem_caixa(requires)`) -> `tape_locked_box`; `locked` -> `tape_locked`; `missing` -> `tape_short`; `buyable` -> `tape_open` |
| `focus_boxed` | hover do botão de foco do aparelho na caixa |
| `shop_glove_boxed` | linha da próxima luva enquanto `luva_em_caixa()` |
| `hint_assist`, `hint_assist_first`, `hint_fame`, `hint_legacy`, `hint_keys`, `hint_locked_item` (`{requisito}`), `hint_prize` (`{dinheiro}`, `{fama}`), `hint_prize_belt` | níveis 3 de leitura |
Mudanças em relação ao texto do Roteirista: `hint_keys` diz "1 a 4: foco" (é foco, não tática); `hint_prize` usa `{dinheiro}` e `{fama}` (o original repetia `{n}` e preencheria os dois com o mesmo valor); `box_hover_queue` não existe (sem fila); `unlock_arrived` e `floor_mark_*`, `assist_hint*` continuam no JSON mas saem da sala.
Substituição de `{...}`: `GameState.preencher(modelo, {...})`.

### Cores e tamanhos (tokens)
Fonte única: `assets/sprites/manifest.json -> ui_tokens`. Já existe `UiTema.manifest()`:
```gdscript
var tokens: Dictionary = UiTema.manifest().get("ui_tokens", {})
var hex: String = tokens.colors.col_treino[1]            # "a6d86a"  (índice 0 = nome na paleta, 1 = hex)
var cor := Color.html("#" + hex)
var tam: Dictionary = tokens.sizes.txt_hero              # {font, scale: 2, font_size: 22}
```
Valores finais do Diretor de Arte (prevalecem sobre o design): Treino `gr3` a6d86a, Dinheiro `y1` f5d26b, Fama `f2` f59ac0 (rampa nova f0/f1/f2), Legado `p2` b07ad8, texto 1 `white`, texto 2 `g2`, desabilitado `g1`, comprável `y2` (só contorno), Resistência `y0` e0a040. Preço sem saldo = `col_text_2`, nunca vermelho. 3 tamanhos: `txt_hero` (2x, font_size 22), `txt_title`/`txt_body` (1x, 11).

### Posições
`manifest.layout.box_slots` = `{treadmill, jump_rope, art, glove}` (pivô = meio da base, no chão). `manifest.by_data_id.box`: `sprite_by_item`, `slot_by_item`, `frame_by_hits` (quadro 0, 1, 2; o 3 é a abertura), `clicks`, `idle`, `open_timeline_s`. Os 4 slots valem para garagem e academia. O `by_data_id.unlock_*.box` traz o sprite e a posição por aparelho.

## 6. Save v7
```json
"career": { "...campos da v6...": "", "boxes": [ {"item": "treadmill", "kind": "apparatus", "hits": 0},
                                               {"item": "glove_l1", "kind": "glove", "hits": 2} ] }
```
- `VERSAO_ATUAL = 7`. `MIGRACOES[6] = _migrar_6_para_7`: só acrescenta `boxes: []`. Save antigo **não** vira caixa (tudo em `apparatus_owned`/`glove_level` continua montado e valendo).
- `glove_level` passa a contar luvas **compradas** (abertas + a da caixa). A luva em caixa é sempre `lutas.luvas[glove_level - 1]`.
- Leitura (`_validar_caixas`, com aviso, sem travar): `boxes` ausente/inválido -> `[]`; item desconhecido, repetido (fica a 1ª), aparelho já montado, aparelho de outra arte/sem `unlock`, luva que não é a última comprada -> descarta a entrada; `kind` corrige-se pelo `item`; `hits` -> inteiro `0..clicks_to_open-1`.
- Salva na compra, na abertura (num único save) e no autosave (hits 1 e 2 vão no autosave de 30 s).

## 7. Testes
`tests/test_fase51.gd` (118 checagens): dados e textos, compra gera caixa, 3 batidas abrem, clique de treino x caixa, bloqueios de compra e foco, luva em caixa, persistência (salvar/reabrir/foco), luta e janelas, NOVA CARREIRA, validações do save v7, migração v6 -> v7 e v0 -> v7, `applies_to` desligado. Os testes antigos de compra instantânea (`test_apparatus_ui`, `test_fase4b`, `test_fase5`, `test_fight_game`) desligam a caixa com `gs.dados.box_apparatus = false` / `box_glove = false`.
`tools/sim/fase5_sim.py` lê `box.clicks_to_open` e `open_seconds` de `data/training.json` (`SIM_CAIXA` ainda sobrescreve; `SIM_CAIXA=0` = sem caixa).
