# Fase 6b1 (Passar o posto): relatório do QA

Dono: QA. Data: 2026-11-14. Branch `fase-6b`, árvore de trabalho (6b1 sem commit). Critérios: `fase6b-escopo.md` §6, itens 1 a 12 e 18 a 20.
Nenhum código de `scripts/`, `scenes/`, `ui/` ou `data/` foi alterado pelo QA.

## Veredito
**Pronto para o Diretor revisar, com 4 bugs pequenos para corrigir antes do dono jogar (nenhum bloqueia a fase).** Os 15 pontos pedidos passam; os bugs são B1 (texto errado na tela de fim, já conhecido), B2 (toques do John somem se o jogador lutar antes do 1º clique), B3 (chegada curta 4 a 7 ms acima de 2,5 s) e B4 (colar nome grande).

## Como testei
| O quê | Comando / arquivo | Resultado |
|---|---|---|
| Bateria | `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1` | 24 grupos, **TODOS OS TESTES PASSARAM**, cena principal 120 quadros sem erro, guarda do save real OK |
| Cena principal | `--path . --position 1950,40 --quit-after 300 -- --save-dir=user://test/qa6b1_main/` | sem ERROR, sem vazamento |
| `ui_audit` | `--resolution 1280x720 --position 1950,40 --script res://tools/ui/ui_audit.gd -- --estados todos` | **ESTADOS 276 | PROBLEMAS 0** (capturas `f6b1_*` em `%APPDATA%\Godot\app_userdata\Fightclicker\ui_audit_saida\`) |
| Validador | `--headless --script res://tools/cenas/validar_cenas.gd` | 0 erros nas 2 cenas (2 pendências de arte, ver B6) |
| Lógica extra | `tests/qa_f6b1_logica.gd` (novo) | 105 de 106; a falha é o B2 |
| Tempos | `tests/qa_f6b1_tempos.gd` (novo) | 9 de 9 |
| Jogo real em janela | `tests/qa_f6b1_ui.gd` (novo; `-- arte` e `-- frames` rodam cenários soltos) | 54 checagens, 2 falhas (B3 e B4) |
| Balanço, GDScript | `tests/qa_f6a_sim.gd` na 6b1 e na 6a (`git archive fase-6a`) | saída **idêntica** (3 lutas, fim em 750 s, mesmos treino/ouro/dia) |
| Balanço, Python | `tools/sim/fase5_sim.py b23c f52` na 6b1 e na 6a | saída **idêntica** (47 linhas, `diff` vazio) |

Save real do dono: hash SHA-256 antes e depois `7CD2FD3A...A954`, igual (não precisou restaurar). Todos os scripts usam `user://test/`.

## Critérios de aceite
| # | Critério | Veredito | Evidência |
|---|---|---|---|
| 1 | Cena inteira: parte 1 <= 9,5 s, criação, parte 2 <= 6,5 s, soma <= 16 s | OK | Linha do tempo do player: parte 1 chega na tela em **9,36 s**, parte 2 devolve o controle em **5,74 s** (jogo real: 5,77 s), total 15,1 s. Validador: 15,13 s presos. Margem da parte 1: 0,14 s |
| 2 | Carreira 1 curta (perder a 1ª luta ou passar o posto sem lutar) | OK | `tests/test_fase6b1.gd` e `qa_f6b1_logica.gd` (`qa6b1_derrota`): derrota na 1ª luta e aposentadoria com 0 vitórias tocam a cena; comentário `cl_primeira_derrota` ainda sai depois da sucessão, mesmo fechando o jogo na criação |
| 3 | Pular: ESC/ESPAÇO 0,5 s e botão; criação não pula; reação toca mesmo pulando | OK | Jogo real: ESC 0,2 s e ESPAÇO 0,3 s não pulam; ESC segurado pula aos **0,53 s** para a criação; luvas já no saco; ESC (curto e 1,2 s) e ESPAÇO (1,2 s) na criação não fazem nada. Botão PULAR na parte 1 leva à criação; na parte 2 chega no estado do S10 em **< 1 quadro** (limite 0,3 s); depois de pular o 1º clique vale e o John senta |
| 4 | Toca uma vez só | OK | Marco gravado no RECEBER (`cena_primeira_sucessao`). 30 sucessões seguidas só dão `chegada_discipulo`. Fechar na parte 1, na criação, na parte 2 e depois do controle: a cena grande nunca volta. Chegada curta pulável (mesmo botão). Tempo da chegada: ver **B3** |
| 5 | Fechar o jogo no meio | OK | Jogo real, 4 etapas: parte 1 e criação reabrem na tela de criação sem a cena (relógio parado 2 s) e depois do CONFIRMAR toca a chegada curta; parte 2 reabre com `arriving`, aplica o final sem tocar, discípulo "Zeca Pontaria" preservado, `mentor_greeted` falso, 1º clique dá toques sem fala; depois do controle, jogo normal |
| 6 | Personalização (nome, pele, cabelo, calção) | OK | Garagem: textura do lutador igual à de `DiscVisual` com o visual escolhido e diferente da folha padrão. Luta: idem (`fight_player_*_disc`). 180 combinações geram 180 texturas distintas. Todas as folhas `*_disc` do manifest (garagem, luta, todas as luvas L1 a L4, retratos) têm a versão `_layered`. Fim de campanha e retrato usam o visual. John mantém o dele |
| 7 | Clique primeiro: 1º soco vale no mesmo quadro; John toca e "isso." | OK, com ressalva (B2) | `qa_f6b1_logica.gd` e jogo real: o soco vale no quadro do `return_control`, plano `cena=primeira_sucessao`, `com_fala`, guarda 0,5 s, toques a 0,22 s, balão "isso." nas capturas. Ressalva: B2 |
| 8 | Só o John faz o gesto | OK | `pedir_gesto` devolve `{}` para o discípulo; validador reprova `gesture`/`mentor_first_taps` em `current_player` |
| 9 | Save novo, fila sem duas janelas | OK | Fila medida em jogo real com artes liberadas: parte 2 termina, **depois** abre `JanelaArte` (5,67 s após o CONFIRMAR), cartão só depois da arte; nunca duas janelas ao mesmo tempo |
| 10 | Save antigo | OK | Ver "Migração" abaixo |
| 11 | Lista da escola | OK | `roster` ganha 1 entrada por campanha encerrada, no mesmo `salvar()`; sobrevive a RECEBER (30 sucessões, 30+ entradas); só "Apagar save" zera (testes da 6b1) |
| 12 | Cartão da luva "o par do John" | OK | Captura `f6b1_luva_hover`: "O PAR DO JOHN. AGORA É SEU. FECHA BEM." (discípulo); `glove_start_desc` para o John; nenhum número mudou |
| 18 | Balanço inalterado; relógio parado | OK | Simulações Python e GDScript idênticas às da 6a; arquivos de balanço de `data/` idênticos aos da 6a (só `ui_texts.json` mudou, e criou 3 arquivos novos). Em `scene_1`, `creating`, `scene_2` (300 s simulados cada, com autosave ligado): `segundos_campanha`, `tempo_jogo`, treino, ouro e `fight_day` não mudam; clique, compra e luta recusados |
| 19 | `ui_audit` 0 problemas | OK | 276 estados, 0 problemas. Capturas conferidas contra a prancha (S1 a S10, criação com nome de 14 letras e vazio, chegada, John sentado com balão, PULAR com anel e chip "SEGURE ESC: PULAR", fim, cartão, arte, HUD com nome). Chip corrigido, balão em modo de cena, nenhum balão cobre cabeça |
| 20 | Testes passando | OK | `run_tests` verde; testes com save de teste; validador sem erro |

### Itens extras pedidos
| Ponto | Resultado |
|---|---|
| Nome 14 letras, vazio, acentos, SORTEAR, cores | Digitando, nome corta em 14; 14 "M" cabe na caixa, no HUD, no cartão e no resumo. Vazio e só espaços não confirmam e voltam a um nome sorteado. Acentos `ÁÉÍÓÚ Ôzé Ção` passam; número, hífen, símbolo e emoji são cortados. 300 sorteios: todos válidos, só os 3 campos da 6b1 variam, 100 SORTEARs seguidos nunca repetem o nome. Colar texto grande: ver B4 |
| John mentor: toques | 1º clique: 1 toque; cliques dentro da guarda de 0,5 s não cancelam; depois, cada clique durante os toques cancela. Depois de vitória: toca com 1,0 s de sala ativa; clique antes dos 1,0 s cancela; janela aberta cancela; vitória a menos de 60 s do último toque é descartada e **não reaparece**; 20 vitórias seguidas: no máximo 1 toque; aposentadoria e derrota não tocam; só na garagem |
| Relógio parado, balanço igual | Ver 18 |
| Nome no lugar de "Carreira N" | HUD, cartão ("TATI GANCHO: O QUE VOCÊ TROUXE"), resumo, escolha da arte, botão do fim ("NOVO DISCÍPULO", plano B). Texto fora de `ui_texts.json` com "Carreira N" não está mais ligado a nenhuma tela. Resta só a linha de apoio da tela de fim (B1) |
| Console | Sem ERROR e sem vazamento na bateria, na cena principal, no `ui_audit` e no jogo real. Zero WARNING no jogo real (os "Save sem o discípulo" que aparecem no `ui_audit` vêm dos estados sintéticos dele) |

## Migração v11 para v12
**Atenção ao Produtor:** o save real do dono **já não está em v10.** Hoje ele é **v12, Carreira 4**, regravado em 14/11 às 19:19 (o `save.json.bak` também é v12). Ele tem `disciple` "Novato" padrão em andamento, John na lista com fim `defeat` e `wins -1` (desconhecido), `mentors: []`, marco da cena ausente. É o caso "v11 com discípulo padrão em andamento" do design §3.6: a cena grande toca quando ele apertar RECEBER NOVO DISCÍPULO no fim desta campanha. Não toquei no arquivo.
Como não há mais cópia v10, derivei um v10 "Carreira 3" do save real (somente leitura, em `user://test/`):
| Caso | Resultado |
|---|---|
| v10, Carreira 3 em andamento | `first_fighter_campaign 3`, lutador John, `disciple` vazio, `roster` vazio, sem handover; Legado, árvore, belts_won, treino e calendário **iguais**; regravado em v12; `aposentar()` põe o John na lista; RECEBER toca `primeira_sucessao` |
| v10, fim pendente do John | `first_fighter_campaign 4`; RECEBER começa a campanha do John sem cena (caso "começo do John") |
| v11 com Novato em andamento (N maior que F) | nome "Novato" no HUD (`NOVATO`), roster com John e Novato, Legado preservado |
| Save v12 corrompido (6 variantes: handover texto, campanha errada, visual lixo, sem rascunho, rascunho nulo, roster com lixo) | Nenhum erro de script; cai no padrão com aviso, descarta handover inválido, ida e volta do nome estável |
| Real v12 copiado | abre sem aviso, `Novato` e roster intactos |

## Bugs

### B1: tela de fim ainda mostra "A luva fica no gancho" (conhecido)
- **Gravidade:** média (texto errado, na tela mais vista; contradiz a cena em que as luvas ficam no saco).
- **Passos:** terminar qualquer campanha (derrota ou PASSAR O POSTO); ler a linha cinza logo abaixo do título.
- **Esperado:** `end_support_line_disc` ("O par fica no saco. O próximo vai pegar."), como diz `fase6b1-textos.md`.
- **Obtido:** "A luva fica no gancho. O próximo vai achar." (captura `f6b1_fim_botao.png`).
- **Arquivo provável:** `scripts/game_state.gd:2489` (`"support": texto_ui("end_support_line")`); a chave `end_support_line_disc` existe em `data/ui_texts.json:366` e nenhum código a lê.
- **Quem corrige:** programador.

### B2: toques do John somem se o jogador lutar (ou mudar de local) antes do 1º clique
- **Gravidade:** baixa a média (a cena toca perfeitamente, mas a reação "isso." + toques pode não aparecer nunca).
- **Passos:** primeira sucessão; no `return_control`, abrir a prévia e lutar (ou ir ao local novo) **antes** de dar o 1º soco; vencer e voltar à garagem; dar o 1º soco. Reproduz sem janela: `tests/qa_f6b1_logica.gd`, função `_reacao_orfa` (resultado `INFO reacao orfa: planos=1 cena='primeira_sucessao' com_fala=true`).
- **Esperado:** o John faz os dois toques (a UI cuida, sem fala), como no 1º clique de uma sucessão seguinte.
- **Obtido:** o jogo manda o plano com `cena = "primeira_sucessao"`; a UI não toca (`ui/sala.gd:2022`: "é da reação da cena") e o player já descartou as reações (`reacoes_descartadas` em `scripts/cena_player.gd:425`). Ninguém toca, e `mentor_greeted` e o intervalo de 60 s são gastos.
- **Arquivo provável:** `scripts/game_state.gd` (`_reacao_cena`, linhas 3915/4057/4075): zerar `_reacao_cena` quando começar luta ou mudar de local (ou quando o player descartar a reação).
- **Quem corrige:** programador.

### B3: chegada curta passa de 2,5 s por 4 a 7 ms no jogo real
- **Gravidade:** baixa (critério 4/11 diz "no máximo 2,5 s"; a linha do tempo tem 2,47 s e os quadros somam o resto).
- **Passos:** `godot ... --script res://tests/qa_f6b1_ui.gd` (cenário 4 de "fechar o jogo"): do CONFIRMAR até o `return_control` na 2ª sucessão.
- **Esperado:** <= 2,5 s. **Obtido:** 2,504 s e 2,507 s em duas execuções (o validador dá 2,47 s, "provisório").
- **Arquivo provável:** `data/cutscenes/chegada_discipulo.json` (tirar 0,1 s: `wait` de 0,2 s ou a `speed` 72 do `walk_bare`).
- **Quem corrige:** diretor-de-cutscenes. (A parte 1 também está justa: 9,36 s contra 9,5 s.)

### B4: colar texto grande no nome perde letras
- **Gravidade:** baixa.
- **Passos:** na tela de criação, colar (Ctrl+V) `A1B2C3D4E5F6G7H8I9J0`. Reproduzido definindo o texto do campo: `tests/qa_f6b1_ui.gd`.
- **Esperado:** `ABCDEFGHIJ` (letras filtradas, até 14). **Obtido:** `ABCDEFG`, porque o `LineEdit` corta em 14 caracteres **antes** do filtro tirar os números.
- **Arquivo provável:** `ui/tela_criar_discipulo.gd` (`_nome.max_length = max_letras()`): deixar `max_length` maior e confiar no `definir_rascunho`, que já corta em 14.
- **Quem corrige:** designer-ui-ux.

### B5 (observação, sem dono): `mentor_spot` fora da prancha
O manifest e o `design`/`api` dizem (254,252); o escopo e a prancha dizem (268,268). O Diretor de Arte/Artista moveu o ponto junto com o caixote (nota no manifest). Na captura o John fica bem sentado e fora da faixa do alvo; só o Diretor precisa confirmar que (254,252) é a decisão final. **Quem decide:** diretor-de-arte.

### B6 (observação): tempo da cena "provisório" no validador
O validador acusa pendência "animação sem arte: current_player/idle" e "first_fighter/punch" e marca o tempo como provisório, embora as folhas existam (o palco as acha por outro caminho: `ui/cena_sala.gd` `_nome_folha`). Não afeta o jogo (medi o tempo real). Para o tempo ficar "exato", registrar `manifest.scene_anims` para esses dois. **Quem corrige:** artista-personagens (manifest) ou programador (validador).

## Riscos
- **Cena e criação em toda campanha:** a tela de criação tem de continuar confirmável em 1 clique; está (abre preenchida, CONFIRMAR resolve). A parte 1 tem só 0,14 s de folga sobre o teto de 9,5 s: qualquer pose a mais estoura.
- **Save do dono em v12:** a primeira vez que ele vir a cena será no fim da Carreira 4, jogando o "Novato" padrão (nome e aparência padrão, sem tela retroativa), como o escopo manda. Vale avisar o Produtor para o dono não estranhar.
- **Reabrir na criação toca a chegada curta, não a parte 2** (decisão do design §1.4): quem fecha o jogo na criação da 1ª sucessão nunca vê a parte 2 com o John apontando a guarda e "vamos ver sua guarda.". Aceito pelo design; só registro.
- **Previa 6b2:** as folhas `_layered` já cobrem todas as folhas `_disc`; o gerador está pronto para receber cortes e roupas.

## Arquivos de teste novos (todos com save de teste)
`tests/qa_f6b1_logica.gd`, `tests/qa_f6b1_tempos.gd`, `tests/qa_f6b1_ui.gd`. Os dois primeiros rodam `--headless`; o terceiro abre janela e exige `--position 1950,40`. O `qa_f6b1_logica.gd` falha de propósito no B2 até ele ser corrigido.

## Resumo
Veredito: pronto para o Diretor revisar. Bugs: B1 média (programador), B2 baixa/média (programador), B3 baixa (diretor-de-cutscenes), B4 baixa (designer-ui-ux); observações B5 (diretor-de-arte) e B6 (artista-personagens).
