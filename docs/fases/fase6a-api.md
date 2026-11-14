# Fase 6a: API para a UI (prólogo e voz)

Dono: Programador. Base: `fase6a-design.md` (contrato) e `docs/cutscenes/balao-e-voz.md`. Só lógica: nenhum arquivo de `ui/` ou `scenes/` foi tocado.
Tudo vive no autoload `GameState`. Dados em `data/dialogos.json`, lidos por `scripts/dialogos_data.gd` (`GameState.dialogos`).

## 1. Sinais (a UI só escuta)
| Sinal | Quando | O que a UI faz |
|---|---|---|
| `fala_pedida(speaker, text, id)` | um comentário ou fala da abertura começou | mostra o balão. `speaker` = `"first"` ou `"coach"`; `text` já vem em minúsculas, com `\n` e os apelidos trocados (`john`, `osmar`) |
| `fala_cancelada(id)` | janela abriu, luta começou, abertura pulada, carga | fecha o balão **na hora** |
| `comentario(line_id)` | comentário começou (mesmo com balões escondidos) | testes e telemetria |
| `gesto_pedido(plano)` | o 1º lutador deve fazer o gesto | ver §3 |
| `gesto_cancelado()` | clique, janela ou abertura pulada | parar o gesto e cortar o `strap_rip`; o 2º toque não toca |
| `abertura_mudou(estado)` | `"pending"`, `"playing"`, `"over"` | mostrar/esconder a dica `esc: pular` |
| `marco_gravado(id)` | marco da escola gravado | redesenhar a parede (ver §4) |

Quem fala: `GameState.dialogos.personagem(speaker)` devolve `{name, short, color, voice}` (plaquinha `short`, cor `color`, voz `voice`).

## 2. Chamadas
| Função | Para quê |
|---|---|
| `fala_terminada(id)` | a UI avisa que o balão sumiu (leitura acabou). Se não chamar, o jogo libera sozinho depois do tempo previsto + 1 s |
| `fala_recusada(id)` | a UI **recusou** o balão (sem espaço): chamar dentro do tratador de `fala_pedida`. A fala não vira vista, `comentario` não sai e a única fica pendente (volta no próximo espaço calmo). Não chamar `fala_terminada` nesse caso |
| `pular_abertura()` | ESC segurado `opening.skip_hold_seconds` (0,5 s). A UI conta o tempo; não prende outra coisa no ESC |
| `registrar_clique()` | **qualquer** clique que não passou por `clicar()` (botão, fora do alvo): cancela o gesto e zera a "sala parada". `clicar()` já chama |
| `pedir_gesto("fight_intro")` | no começo da animação da luta (também ao reabrir com luta pendente). Devolve o plano ou `{}` |
| `pedir_gesto("victory")` | quando começa o `outro` da vitória. Na derrota não chama |
| `fala_terminada`, `cancelar_gesto()` | opcionais |
| `lutador_atual()` | `"first"` (John Bullet) ou `"disciple"` (discípulo padrão): escolhe sprite (`_disc` = discípulo), nome, luva |
| `marco(id)` / `dados_marco(id)` | leitura dos marcos |
| `abertura_estado()` | `"pending"`, `"playing"`, `"over"` (ao montar a tela) |
| `segundos_ocioso()` | segundos de sala ativa sem clique (começa em 0 ao abrir) |
| `tem_balao()` | há balão na tela |
| `descricao_luva_inicial()` | "O par do John. Velha, mas fecha direito." no John, descrição padrão no discípulo |
| `dialogos.texto_objeto(chave, campo="text")` | texto de objeto da parede (tooltip): `debt_notice` (`title`, `text`), `old_photo`, `entry_form_before`, `entry_form_after` (`text_alt` = RAIZES), `clipping` (`title`, `text`, `footer`), `team_photo`, `garage_saved_seal` (`title`, `text`), `starter_glove_desc` |
| `baloes_escondidos` (var) | opção de teste (aceite 3): sem balão, marcos e `lines_seen` iguais |

Toda a lógica de intervalo, vaga, teto e "sala calma" é do `GameState`: a UI só mostra o que `fala_pedida` manda.

## 3. Gesto (só o John)
`pedir_gesto(momento)` e o sinal `gesto_pedido` entregam o mesmo plano:
`{momento, version ("full"|"short"), start, duration, rip_at, taps [t1, t2], rip_sound, tap_sound, pose_at}`.
- Tempos relativos ao pedido (`start` já é o atraso): abertura 0,30 s; luta 0,30 s; vitória 0,15 s (e `pose_at` 0,60 s); luva nova 0,30 s; sala parada 0 s.
- `version`: `full` = folha `*_gesture` (8 quadros, 0,89 s); `short` = `*_gesture_short` (4 quadros, 0,44 s).
- Sons: `rip_at` (só no completo) toca `strap_rip`; `taps` tocam `tap_glove` (t2 − t1 = 0,22 s exatos, temporizador, não quadro).
- O `GameState` chama sozinho: abertura, luva nova (`caixa_aberta` de luva, 1 vez por nível, `career.gestured_gloves`) e sala parada (aos 20 s, depois 30–60 s, máx. 3 por parada). A UI chama `fight_intro` e `victory`.
- Discípulo: `pedir_gesto` devolve `{}` (nunca faz).
- O gesto é só visual. O comentário que cairia durante ele espera o fim ou o cancelamento.

## 4. Marcos e parede da garagem
`marco(id)`: `prologue_seen`, `first_school_win`, `garage_saved`, `garage_saved_seen` (+ `dados_marco("garage_saved")` = `{campaign, version, opponent, by_first}`).
- Aviso de cobrança: visível se **não** `marco("garage_saved_seen")`. Ficha "antes" idem; "depois" quando há `garage_saved_seen`.
- Recorte de jornal: `marco("first_school_win")`. Foto da equipe e símbolo: `marco("garage_saved_seen")`. Foto antiga: sempre.
- `resumo` de `luta_resolvida` / `concluir_luta()` (vitória) ganhou `garage_saved` (selo "GARAGEM SALVA", só na vez que o marco nasce), `first_school_win` e `record` (bool).
- `garage_saved_seen` nasce no 1º tick com sala ativa na garagem depois de `garage_saved` (ao fechar a vitória, ou no começo da campanha seguinte); o sinal `marco_gravado("garage_saved_seen")` é a hora de trocar a parede.

## 5. Abertura
`pending` -> `playing` no 1º tick com `sala_ativa()`; em t = 0 grava `prologue_seen` (e salva), pede o gesto (0,30 s) e a 1,5 s entra o 1º balão (`open_1`..`open_4`, 0,3 s entre eles). Termina quando a última acaba, em 20 s ou por `pular_abertura()`. O relógio da campanha anda; o saco vale desde t = 0; ESPAÇO só treina.
Prevista com as falas atuais: 111 letras, 13,9 s.

## 6. Voz (arquivos prontos em `assets/sfx/`)
`voice_<timbre>_<vogal>.wav` com timbre `first`, `coach`, `disciple` (sem uso na 6a) e vogal `u,o,a,e,i`; `strap_rip.wav`, `tap_glove.wav`. Escala por vogal e variações (±3%, `?`, MAIÚSCULA) em `balao-e-voz.md` §6.1; números em `data/dialogos.json` (`voices`, `typing`). Um blip a cada 2 letras (`typing.blip_every_letters`), -8 dB (`typing.blip_volume_db`), um tocador só.

## 7. Save v11
`state.school = {first_fighter_campaign, milestones, lines_seen, last_end}` e `career.gestured_gloves`. Migração v10 -> v11 em `SaveStore._migrar_10_para_11` (a campanha atual vira a do John; com fim pendente, a seguinte; nenhum marco é criado). `school` nunca é zerado por NOVA CAMPANHA, derrota ou aposentadoria; só "Apagar save".

## 8. Para os testes de UI
`GameState.disparar_gatilho(id, params)` empurra um gatilho (resolvido no próximo `tick`); `GameState.pular_abertura()` deixa o save de teste sem a abertura.

## 9. Correções do QA (B1-B3)
- **Osmar só na garagem**: toda fala do treinador (fora da abertura) tem `conditions.location = "garage"`; na academia nada toca e a única `cl_primeira_academia` não é gasta (a cena da academia vem na 6c). A abertura só começa na garagem (`pending` espera) e as falas do Osmar da abertura esperam a garagem.
- **1ª derrota rearmada na carga**: se `school.last_end` é derrota da campanha anterior e `cl_primeira_derrota` não foi dita, o `after_defeat` é redisparado no 1º tick com a sala ativa na garagem.
- **`lines_seen` só depois do aceite**: `fala_pedida` é emitido antes de gravar; se a UI chamar `fala_recusada(id)`, nada é gravado/salvo (a única entra na vaga e tenta de novo após 2 s de calma). `ui/garagem.gd` usa isso quando `Balao.mostrar` recusa.
