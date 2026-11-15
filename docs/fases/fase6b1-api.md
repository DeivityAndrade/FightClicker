# Fase 6b1: API para a UI (passar o posto)

Dono: Programador. Base: `fase6b1-design.md` (contrato), `docs/cutscenes/formato-dados.md` v1.1 (§9). Só lógica: nada de `ui/` nem `scenes/` foi tocado.
Arquivos novos: `scripts/disciples_data.gd` (`DiscipulosData`), `scripts/cena_dados.gd` (`CenaDados`), `scripts/cena_player.gd` (`CenaPlayer`), `scripts/cena_validador.gd` (`CenaValidador`), `data/cena_player.json`, `tools/cenas/validar_cenas.gd`.
Mudou: `GameState` (`GameState.disciples` = `DiscipulosData`), `SaveStore` (v12), `tools/sfx/make_sfx.gd` (+11 sons).

## 1. A UI troca uma chamada
`GameState.nova_carreira()` (botão do fim) vira **`GameState.receber_discipulo()`**. Texto do botão: `new_disciple_button` ("RECEBER NOVO DISCÍPULO"), plano B `new_disciple_button_short`. `nova_carreira()` continua existindo (caminho direto, usado pelo "começo do John" e por testes) e dá ao discípulo o nome padrão.

## 2. Estados da sucessão
`GameState.sucessao_estado()` e sinal `sucessao_mudou(estado)`:

| Estado | Quando | O que a UI mostra |
|---|---|---|
| `none` | jogo normal | tudo normal |
| `scene_1` | RECEBER apertado (1ª sucessão) | a cena (player) |
| `creating` | o player chegou no `open_screen`; ou save aberto na criação | **tela de criação** |
| `scene_2` | CONFIRMAR na 1ª sucessão | a cena (player continua sozinho) |
| `arriving` | CONFIRMAR nas seguintes; ou save aberto depois do CONFIRMAR | chegada curta |

- Com estado != `none` a carreira está congelada: `sala_ativa()` false, `clicar()` devolve `{}`, nenhum segundo anda, nada se compra. A escolha da arte (`escolha_arte_pendente()`) só aparece depois.
- `nova_carreira_iniciada(cartao)`, `escolha_arte_pedida` e o gatilho `after_defeat` saem **no fim da sucessão** (`sucessao_terminou()`), nessa ordem. A UI já trata "arte antes do cartão".
- `sucessao_cena()` = id da cena a tocar (`primeira_sucessao` ou `chegada_discipulo`). `sucessao_retomada` = true se o estado veio de um save aberto no meio.

### Ao montar a tela (abrir o jogo)
| `sucessao_estado()` | Fazer |
|---|---|
| `creating` | `player.estado_da_tela(sucessao_cena())` devolve `{tela, estado, palco, atores}`: monte o palco no `estado` (garagem escurecida, John sentado, luvas no saco) e abra a tela de criação. **Não toque a cena.** Ao CONFIRMAR (`confirmar_discipulo()`), estado vira `arriving`: `player.iniciar("chegada_discipulo", "depois_criar")` |
| `arriving` | `player.aplicar_final_sem_tocar(sucessao_cena())`: aplica o `end_state` sem tocar e chama `sucessao_terminou()` |
| `none` | normal |

Fluxo vivo (RECEBER): `receber_discipulo()` -> `player.iniciar(sucessao_cena())` (a cena grande, ou a chegada que abre direto na tela) -> `tela_pedida` -> a UI abre a tela de criação -> o jogador usa as ações da §3 -> `confirmar_discipulo()` -> o player **continua sozinho** (escuta `sucessao_mudou`) -> `return_control` -> `sucessao_terminou()` chamado pelo player.

## 3. Tela de criação: ações e consultas (GameState)
| Chamada | Para quê |
|---|---|
| `rascunho()` | `{name, look}` atual (já vem sorteado ao abrir). Sinal `rascunho_mudou` a cada mudança |
| `definir_rascunho("name", texto)` | a cada tecla; filtra o que a fonte não desenha e corta em 14. Devolve false fora da criação |
| `definir_rascunho("skin"/"hair_color"/"shorts_color", id)` | só ids ligados (`disciples.opcoes_ativas(campo)`); false para o resto |
| `sortear_rascunho()` | botão SORTEAR (tudo de novo) |
| `confirmar_discipulo() -> bool` | CONFIRMAR. Nome vazio: o campo volta a um nome sorteado (`rascunho_mudou`) e devolve **false** |
| `limpar_nome(texto)` | o que seria gravado ("" se vazio) |
| `disciples.opcoes_ativas(campo)`, `disciples.cores(look)` | listas e cores dos campos (6b2 só liga mais opções) |
| `disciples.max_letras()` | 14 |

Não pode fechar com ESC nem pular: a tela só sai por `confirmar_discipulo()`.

## 4. Quem é o lutador (substitui "Carreira N")
| Chamada | Devolve |
|---|---|
| `nome_lutador()` | "John Bullet" ou o nome do discípulo (aplique `.to_upper()`) |
| `texto_hud_lutador()` | `hud_disciple` já em maiúsculas |
| `titulo_resumo()` | `sum_title_named` ("RESUMO DE {NOME}") |
| `cartao_inicio().title` | agora é `career_card_title_named`; `cartao_inicio().name` |
| `subtitulo_escolha_arte()` | usa `art_sub_career_named` |
| `descricao_luva_inicial()` | `glove_start_desc` (John) / `glove_start_desc_disc` |
| `discipulo_atual()` | `{name, look, campaign}` ({} no John) |
| `visual_lutador()` | `look` (9 campos, ids em texto; {} no John) |
| `cores_visual(look = {})` | `{campo: {id, slots, colors (hex), tokens}}` para a troca de paleta em tempo real |
| `escola_lista()` | quem passou o posto, em ordem (a 6c usa; a 6b2 lê o último `kind == "disciple"`) |

## 5. John mentor
- `mentores_na_sala()` -> `[{id: "first", spot: "mentor_spot", pose: "sit_rest"}]` ou `[]` (só garagem, só com discípulo jogando). O John fica no `mentor_spot` do manifest (hoje (254,252)); o caixote é o `prop_permanent` do manifest.
- Sinal `toques_mentor_pedidos(plano)`: `{momento ("first_click"|"win_return"), version "short", start 0, duration 0.44, taps [0.11, 0.33], tap_sound "tap_fist", anim "mentor_first_taps", guard, cena, com_fala}`.
  - Se `plano.cena != ""` (1º clique logo depois da cena grande) **quem toca é o player de cena** (reação `first_click`, com o "isso."): a UI **não** repete os toques.
  - Senão a UI toca a folha `mentor_first_taps` e `tap_fist` em 0,11 s e 0,33 s (temporizador, não quadro) e volta ao `sit_rest`.
- Sinal `toques_mentor_cancelados()`: parar a pose, cortar o 2º toque, voltar ao `sit_rest`. Vem de clique (com a guarda de 0,5 s no 1º clique), janela, luta e mudança de local. Cliques que não passam por `clicar()` precisam chamar `registrar_clique()` (como na 6a).
- Regras (tudo nos dados `data/disciples.json > mentor_taps`): máx. 1 por 60 s em tempo real; descartado, nunca guardado; vitória: 1,0 s de sala ativa na garagem depois de fechar a janela; só o John (`pedir_gesto` continua `{}` no discípulo).
- O comentário do Osmar que cairia durante os toques espera o fim ou o cancelamento.

## 6. CenaPlayer (`scripts/cena_player.gd`, `class_name CenaPlayer`, extends Node)
Não desenha nada: só avisa.
```
var p := CenaPlayer.new(GameState)      # gs; usa gs.dialogos e gs.dados.ui
add_child(p)                            # _process avança e lê ESC/ESPAÇO segurados
p.iniciar(id, desde_checkpoint = "")    # false se a cena ou o checkpoint não existe
```
Em testes: `p.automatico = false; p.ler_teclado = false; p.avancar(delta)`.

### Sinais
| Sinal | Quando |
|---|---|
| `evento(ev)` | **um passo para a UI executar** (abaixo) |
| `estado_aplicado(estado, origem)` | um estado inteiro aplicado de uma vez: `"inicio"` (palco inicial), `"tela"` (pulou até a criação), `"final"` (`end_state`), `"checkpoint"`. Formato do `state`/`end_state` do `formato-dados.md` (§9 itens 10 e 12) |
| `tela_pedida(tela, estado)` | abrir `customize_disciple`. A cena fica parada até o jogo sair de `creating` |
| `controle_devolvido()` | `return_control`: barras saem, interface volta, soltar objetos da sala e atores `hand_to_game` (ver `mundo().liberados`). O player já chamou `sucessao_terminou()` |
| `cena_iniciada(id)`, `cena_terminada(pulada)` | começo e fim da linha do tempo (as reações continuam armadas depois) |
| `pular_progresso(0..1)` | anel do botão PULAR enquanto ESC/ESPAÇO é segurado; 0 ao soltar |
| `reacao_iniciada/terminada/cancelada(quando)` | reação `first_click` (toques do 1º clique) |
| `reacoes_descartadas()` | luta ou troca de local antes do 1º clique: a sala fica no `end_state` |
| `passo_ignorado(tipo)` | passo só validado (frame, fx, light, name_card, photo, start_fight) |

### `evento(ev)`: campos por `ev.tipo` (todos têm `t`)
| tipo | Campos |
|---|---|
| `pose` | `ator, anim, loop, times, gap, hold, face, facing, frames [a,b], glove, slow, seconds` |
| `move` | `ator, to [x,y], seconds, anim, facing` (a UI anima do ponto atual até `to`) |
| `face` / `show` / `hide` | `ator`, `facing`/`face`; `show/hide` com `ator` ou `adereco` |
| `sound` | `id, volume, loop, stop, fade`. `origem_estado: true` quando veio de um estado (laços que param ou voltam) |
| `camera` | `scale (1\|2), rect, pan_to, seconds` (corte seco) |
| `ui` | `hide`/`show` (`"all"` ou lista), `seconds` |
| `prop` | `id, visible, anim, frame, pos, layer, seconds` (anim = nome do mapa `anim` do manifest) |
| `shake` | `px, frames, seconds` |
| `say` | `line, ator, mode ("scene"\|"passive"), text, voice, cps, cut_after, seconds`; texto já resolvido (`text_key` de `ui_texts.json`), minúsculo, com `\n` |

Nomes lógicos de animação: `ator.character` + `anim` viram o sprite por `<prefixo>_<anim>` (prefixos em `data/cena_player.json`: `john`, `disciple`, `coach`) ou, melhor, por `manifest.scene_anims.<character>.<anim>` (a arte pode escrever). `actors.<id>.glove`, `pose.glove` = `glove_old` / `none`.

### Consultas
- `mundo()` -> `{atores {id: {pos, facing, anim, glove, visible}}, adereços {id: {visible, anim, frame}}, camera, ui, sons_em_laco, liberados}`: espelho do que está em cena (monte os nós a partir daqui; `liberados` = quem foi entregue ao jogo).
- `estado_da_tela(id)`, `aplicar_final_sem_tocar(id)`: ver §2.
- `desenho_da_garagem()`: `manifest.by_data_id.garage_door_scene` (pivô da porta (0,12), quadro 84x68, camadas, `draw_order`: fundo, `wall` (fora), `floor` (luz do dia e **depois** a sombra de pés), `sorted` por y dos pés: porta 222, caixote, luvas 254, gente).
- `pode_pular()`, `pular()`, `segurar_pular(segurando, delta)`.
- Pontos nomeados (`mentor_spot`) vêm do manifest (`layout.mentor_spot`); `data/cena_player.json > points` é só o reserva.

### Pular
- Segurar ESC **ou** ESPAÇO por `data/cena_player.json > skip.hold_seconds` (0,5 s) -> `pular()`. O botão PULAR chama `pular()` direto.
- Antes da tela: aplica o `open_screen.state` e abre a tela (luvas já no saco). **Na tela de criação não pula.** Depois dela: aplica o `end_state`, devolve o controle e termina (≤ 0,3 s: é um estado, não animação). As reações continuam armadas (o 1º clique toca a reação mesmo pulando).
- O chip de dica é `skip_chip` ("SEGURE ESC: PULAR"); botão `skip_button`.

### Reação do 1º clique
Armada no `return_control`. Dispara quando `GameState` emite `toques_mentor_pedidos` com `plano.cena == id da cena`. Descartada se começar luta ou mudar o local antes. Cancelada por `toques_mentor_cancelados` (executa só a pose de descanso em laço).

## 7. Validador
`CenaValidador.novo().validar_tudo()` ou `godot --headless --path . --script res://tools/cenas/validar_cenas.gd` (`-- --rascunhos` inclui `data/cutscenes/_rascunhos/`). Cada relatório: `{id, erros, avisos, pendencias, tempo_preso, tempo_exato}`.
- Conhece **todos** os tipos do formato (inclusive `frame`, `fx`, `light`, `name_card`, `photo`, `start_fight`, `versions`), posições inteiras, `rect` 192x136, falas (2 linhas de 26, `text_key` existente), sons (`assets/sfx/<id>.wav`), `gesture`/`mentor_first_taps` proibidos em `current_player`, `end_state`, `return_control` ou `start_fight`, soma ≤ `max_seconds`.
- **Arte que falta não é erro:** vira `pendencias` (animação de personagem, sprite, ponto nomeado) e, enquanto a duração depender dela, o teste do tempo vira `avisos` (`tempo_exato = false`). Pendências hoje: as 11 poses do John e do discípulo ainda sem folha no manifest.
- Chaves que começam com `_` são comentário. A pasta `data/cutscenes/_rascunhos/` não é lida pelo jogo nem por `validar_tudo()`.

## 8. Save v12 e migração
`career.disciple` (`{name, look, campaign}` ou null), `career.mentor_greeted`, `school.handover` (`null` ou `{stage, campaign, scene, draft}`), `school.mentors`, `school.roster`. Migração v11 -> v12 em `SaveStore._migrar_11_para_12` (os 5 casos do design §3.6, testados). `mentor_greeted` fica `false` quando se fecha o jogo na parte 2 (os toques vêm no 1º clique, sem fala).

## 9. Sons novos (`tools/sfx/make_sfx.gd`, gerados e importados)
`bag_catch, chain_creak (laço), lamp_hum (laço sem emenda), strap_open, glove_leather, ring_clink, door_shake, door_roll, door_jam, strap_close, tap_fist`. Gerados depois dos antigos: os 38 sons anteriores ficam byte a byte iguais.

## 10. Decisões e dúvidas
- Gatilho: `handover_started` (já nas duas cenas). `GameState` escolhe a cena lendo os `trigger.requires` dos arquivos.
- `grants`: só `mentor_in_room` / `mentor_leaves` têm efeito. `prop_permanent` (caixote) é derivado de `school.mentors` (sem estado extra).
- Passos não executados na 6b1 (`frame`, `fx`, `light`, `name_card`, `photo`, `start_fight`) saem em `passo_ignorado`.
- Dúvida: durações das poses vêm do manifest (`frames / fps`); sem a folha, a pose conta 0,5 s e o tempo vira "provisório". Quando o Artista de Personagens registrar as folhas (ou `scene_anims`), rode o validador de novo: o tempo preso da cena grande (hoje 14,4 s provisório) passa a ser exato.
- Chip e botão: o QA/ui_audit é da UI/UX.
