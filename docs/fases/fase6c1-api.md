# Fase 6c1 (Casa nova): contrato para a interface

Lógica em `scripts/game_state.gd` (autoload `GameState`), `scripts/cena_player.gd` e `scripts/cena_dados.gd`. Dados: `data/escola.json`, `data/disciples.json` (blocos `_6c1`), `data/cutscenes/primeira_academia.json` e `saida_primeiro_mentor.json`. Save continua v12, sem migração (só marcos novos em `escola.milestones`).

## 1. Cena da 1ª chegada à academia
- `GameState.mudar()` para `gym` com o marco `cena_primeira_academia` ausente: grava o marco no mesmo `salvar()`, põe `cena_sala = "primeira_academia"` e emite `cena_sala_pedida(id)`. A UI toca a cena com `CenaPlayer.iniciar(id)`.
- Com `cena_sala != ""`: relógio, produção, arte e cliques parados; `sala_ativa()` e `escolha_arte_pendente()` são falsos; `acoes_bloqueadas()` verdadeiro; `escolha_arte_pedida` NÃO é emitido.
- O fim é automático: o `return_control` da cena (ou PULAR) chama `GameState.cena_sala_terminou()`, que solta o relógio e emite `escolha_arte_pedida` se a arte estiver pendente. Trava de segurança: sem aviso, solta sozinha após 30 s.
- A carga do save NÃO toca a cena (o marco já existe ou a academia fica como na 6b2).
- `elenco_primeira_academia() -> {fighter: "first"|"disciple", box: "first"|"last_passed"|"neighbor", box_look}`. O player já resolve os atores por papel: `mundo.atores[id]` ganhou `existe`, `personagem`, `look`, `nome`. Ator ausente (ex.: `helper` sem esteira) tem `visible: false` e todos os passos dele são pulados. `current_player` na campanha do John vem como `first_fighter`. Disciplinas (último que passou o posto) vêm como `personagem = "current_player"` com `look` e `nome`.
- O caixote fica na academia depois do marco (`assento_visivel()`).

## 2. A escola na academia (depois do marco)
| Leitura | Retorno |
|---|---|
| `coach_presente()` | Osmar desenhado no local atual (garagem: sempre; academia: com o marco). Só fala quem está desenhado |
| `ponto_do_coach()` | `[x, y]` ou `[]` |
| `foto_antiga()` | `{spot, object_text, tilted}` ou `{}` (garagem: reta, texto `old_photo`; academia: torta, texto `old_photo_gym`) |
| `assento_visivel()` | caixote desenhado no local, com ou sem gente sentada |
| `mentores_na_sala()` | lista de `{id "first"\|"last", role "seat"\|"stand", spot, point [x,y], pose, glove, facing, campaign, name, look}`; vale na garagem e na academia (com o marco) |
| `mentor_sentado()` | só o John sentado (toques valem; garagem e academia) |
| `segundo_mentor()` | o em pé (`stand`), como antes; escondido na cena da academia e na 1ª sucessão |

Pontos: `gym_coach_spot`, `gym_mentor_spot`, `gym_mentor_2_spot`, `gym_photo_spot`. Lidos do `manifest.layout`, com reserva em `data/cena_player.json > points` (196,236 / 254,252 / 150,262 / 212,158).
Mudança de id: o mentor em pé agora tem `id "last"` (era `"second"`); o `ui/sala.gd` precisa trocar a leitura e usar `role`/`point`.

## 3. Saída do John
- `saida_devida()`: John em `school.mentors`, discípulo jogando, marco `cena_saida_primeiro_mentor` ausente e (marco `disciple_gym_win` OU campanha >= campanha do John + 3).
- `disciple_gym_win`: gravado em `concluir_luta()` na 1ª vitória de discípulo na academia com o John ainda na escola.
- No 1º momento calmo (sala ativa, 2 s de calma, sem balão/gesto/toques, John desenhado) o jogo grava o marco, remove o John de `mentors`, salva e emite `saida_mentor_pedida()`. A UI chama `CenaPlayer.iniciar("saida_primeiro_mentor")` (cena `blocking: false`, 0 s presos, jogador no controle).
- A cena termina sozinha (`CenaPlayer` chama `GameState.cena_livre_terminou`) ou é interrompida: janela, luta, MUDAR, tela de fim, RECEBER ou dia da luta. Interrupção emite `saida_mentor_interrompida`; o `CenaPlayer` (conectado) aplica o `end_state` e emite `baloes_cancelados`, para a UI fechar os balões da cena.
- Durante a saída, `papel_da_sala("seat"|"stand"|"coach")` devolve o que a sala desenhava antes dela; a UI deve esconder os mentores/Osmar da sala (`stage.hide`) enquanto a cena roda e redesenhar por `mentores_na_sala()` no `end_state` (`hand_to_game`).
- `saida_tocando()` é verdadeiro durante a cena. Depois: ninguém faz os toques; o último que passou o posto está sentado (`role "seat"`, `sit_rest`), ou o caixote fica vazio; o `stand` fica vazio.
- Trava de segurança: sem aviso, a saída se encerra sozinha em `max_seconds + 3` s.

## 4. Formato de cena (v1.2, ver `docs/cutscenes/formato-dados.md` §9 itens 16 a 24)
Elenco por papel (`mentor:seat`, `mentor:last`, `fallback`, `optional`, `requires.owned`), `helper_2`, `from_room`, `stage.location: "any"`, `stage.hide` com `apparatus|boxes|wall_objects`, `if.location`, adereço com `location`, `seat_spot|stand_spot|coach_spot`, evento `mentor_leave_due`, passo `fx` executado (evento `fx` no player; a UI desenha ou ignora).

## 5. Sons novos (placeholders sintetizados)
`gym_door_open`, `gym_door_close`, `metal_bump`, `crate_down`, `nail_knock`, `frame_scrape`, `tube_start`. As cenas ainda usam dublês nos passos marcados `_som_final`; o Diretor de Cutscenes troca os ids.

## 6. Comentário da arte
`art_choice` sai uma vez por campanha, quando `arte_segundos` passa de 60 (`escola.json > art_comment`). Nunca na carga.
