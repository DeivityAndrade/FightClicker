# Fase 4b: contrato da lógica para a UI

Dono: Programador. Tudo no autoload `GameState` (`scripts/game_state.gd`). Dados em `data/training.json` (`unlock`, `assist`) e `data/ui_texts.json`.

## Aparelhos que chegam
Ordem de compra: saco (já montado) -> esteira (500) -> corda (1.500, pede a esteira). Zera na NOVA CARREIRA.

| API | Faz |
|---|---|
| `aparelho_montado(id) -> bool`, `aparelhos_montados() -> Array` | consulta (ordem da compra) |
| `estado_aparelho(id) -> String` | `"owned"`, `"buyable"`, `"missing"`, `"locked"` |
| `desbloqueio(id) -> Dictionary` | `{id, cost, requires, name, description, arrives_as}` ou `{}` (saco) |
| `nome_curto_aparelho(id) -> String` | "Esteira", "Corda" (para frases; use `.to_upper()`) |
| `textos_trancado(id) -> Dictionary` | para não montado: `price`, `after` (vazio se não `locked`), `floor_mark` (plaquinha), `focus_locked` (botão de foco), `attr_locked`. `{}` se montado |
| `pode_comprar_aparelho(id)`, `comprar_aparelho(id) -> bool` | compra: desconta Treino, foco vai para o aparelho, salva na hora. Recusa sem Treino, sem o anterior, em luta ou tela de fim |
| `signal aparelho_comprado(aparelho)` | para a chegada com juice (emitido junto com `foco_mudou` e `economia_mudou`) |
| `definir_foco(id)` | agora devolve false e não troca se o aparelho não está montado |
| `proxima_melhoria(id)` / `pode_comprar_melhoria(id)` | `{}` / false para aparelho não montado |

- `GameState.clicar()` sempre treina o aparelho em foco, que é sempre montado. Clique na marca do chão ou no botão de foco trancado: a UI não chama `clicar()` nem `definir_foco()` (só abre a aba TREINO). Espaço e as teclas 1/2/3: usar `definir_foco`, que já recusa trancado.
- A ordem em `dados.aparelhos` (= `data/training.json`) agora é saco, esteira, corda: a mesma da ordem de compra. A UI depende disso: botões de foco, cartões da aba TREINO e as teclas 1/2/3 seguem esse array.
- Textos novos em `ui_texts.json`: `unlock_buy`, `unlock_price`, `unlock_after`, `floor_mark_*`, `focus_locked_*`, `attr_locked`, `unlock_arrived` (use `GameState.preencher(modelo, {"nome": ...})`), `tip_unlock*`.

## Modo assistido (só com Shift pressionado)
A UI captura a tecla; o jogo não guarda nada no save.

| API | Faz |
|---|---|
| `definir_assistido(segurando: bool)` | chamar com true no Shift pressionado (sem eco) ou botão SEGURAR pressionado, e false ao soltar. Perder o foco da janela já solta sozinho (o autoload trata `NOTIFICATION_APPLICATION_FOCUS_OUT`) |
| `assistido_estado() -> String` | `"off"`, `"waiting"` (segurando, mão ainda mexendo), `"active"` (socando), `"metronome"` (Metrônomo >= 1: some a dica e o botão; mostrar `assist_metronome`) |
| `signal assistido_mudou(estado)` | só quando o estado muda |
| `assistido_segurando()`, `assistido_disponivel()`, `assistido_intervalo()` | consultas (intervalo para `shop_metronome_now`, `{s}`) |
| `assist_socos_total` | contador para o QA (também conta em `auto_socos_total`) |

- Cada soco do assistido emite `auto_socou` (igual ao Metrônomo: número menor, sem tremida). Para "pulsar a cada soco", escute `auto_socou` enquanto `assistido_estado() == "active"`.
- Regras: 1 soco a cada 3,0 s, só com a mão parada há 1,0 s (`clicar()` zera), 1º soco 1,0 s depois de ativar. Nada em luta, janelas (`definir_modal(true)`), tela de fim. Com Metrônomo >= 1 não faz nada. Dica fixa: `assist_hint` (ou `assist_hint_short`), botão `assist_button`, esperando `assist_waiting`, socando `assist_active`.
- Aplicar o `definir_assistido(true)` com o botão SEGURAR: ligar no `button_down` e desligar no `button_up`.

## Dica de derrota
`fim.reason.unlock_tip` = id do aparelho que falta ("" se não). `textos_fim().tip` já devolve a dica `tip_unlock_<aparelho>` nesse caso.

## Save v5
`career.apparatus_owned` (lista). Migração v4 -> v5 dá os 3 aparelhos à carreira em andamento. Nada novo em `permanent`.

## O que existe na UI hoje
A UI está implementada. Quem usa o quê:

| Arquivo | Integração |
|---|---|
| `ui/sala.gd` | Marcas de fita (`fita` + `fantasma`) e plaquinha de papelão (`textos_trancado().floor_mark`) para cada aparelho com `unlock`; visíveis enquanto `estado_aparelho(id) != "owned"`, atualizadas em `economia_mudou`. Esteira/corda só aparecem se `aparelho_montado`. Escuta `aparelho_comprado` para a animação de chegada (esteira cai, corda é pendurada; poeira/brilho; texto `unlock_arrived`); clique ou auto-soco durante a queda encerra a chegada na hora; `carreira_mudou` cancela. Clique no alvo central chama `clicar()`; clique em aparelho lateral montado chama `definir_foco()`. |
| `ui/sala.gd` (sinal `marca_clicada(aparelho)`) | Emitido ao clicar na marca de fita/plaquinha de aparelho não montado. Não chama `clicar()` nem `definir_foco()`; só toca o som de foco. O `garagem.gd` liga o sinal a `PainelLoja.destacar_compra(id)`. |
| `ui/barra_baixo.gd` | Botões de foco na ordem de `dados.aparelhos`. Aparelho não montado vira botão trancado (cadeado, nome curto, preço via `textos_trancado().focus_locked`, ou "DEPOIS DA ESTEIRA" se `locked`); `buyable` pulsa a borda a 3 fps. Sem número de tecla nos trancados. Clique no trancado emite `compra_pedida(aparelho)` (não troca foco); montado chama `definir_foco()`. Reage a `estado_aparelho` a cada `atualizar()`. |
| `ui/painel_loja.gd` | Aba TREINO: no lugar do cartão de melhorias, um cartão de compra por aparelho com `unlock` (`_unl`), enquanto não `owned`. Botão COMPRAR chama `comprar_aparelho(id)`; estado `buyable`/`missing` define preço e cor, `locked` mostra `textos_trancado().after` num botão apagado. Hover usa `desbloqueio().description` e `arrives_as` na caixa de informação. Ao comprar, o cartão de melhorias do aparelho pisca. `destacar_compra(id)` abre a aba TREINO e pisca a borda do cartão 3 vezes. Melhorias só aparecem para aparelho montado. |
| `ui/painel_atributos.gd` | Atributo de aparelho não montado: nome apagado e, ao passar o mouse, o aviso `textos_trancado().attr_locked` na linha extra. |
| `ui/garagem.gd` | Liga `Sala.marca_clicada` e `BarraBaixo.compra_pedida` ao mesmo `_apontar_compra` (abre TREINO e pisca o cartão). Teclas 1/2/3 usam `definir_foco(dados.aparelhos[i].id)`, que recusa aparelho trancado (a tecla então não faz nada, sem som). Espaço chama `Sala.treinar_pelo_teclado()` (= `clicar()`), bloqueado em luta, janela, tela de fim e depuração. |
| `ui/faixa_assistido.gd` | Faixa abaixo dos pés do lutador: chip de estado (`assistido_estado()`: off/waiting/active/metronome) e botão SEGURAR. Captura Shift (só aperto sem eco e soltura) e `button_down`/`button_up`; chama `definir_assistido(true)` se Shift OU mouse estiver pressionado e `false` quando ambos soltam. Perda de foco da janela solta tudo (também tratada no GameState). Pulsa o chip a cada `auto_socou` quando o estado é `active`. Com `metronome` esconde o botão. Texto longo `assist_hint` cede a `assist_hint_short` se não couber. Reage a `assistido_mudou`, `carreira_mudou` e `metronomo_mudou`. |

Compras de aparelho pelo cartão (aba TREINO) são o único caminho de compra; marca da sala e botão de foco trancado só apontam para ele.
