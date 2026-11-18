# Prancha de quadros-chave da 6c1: Primeira chegada à academia e Saída do John

Dono: Diretor de Cutscenes. Versão 2 (2026-11-15): dados ajustados à arte e aos sons finais (ver "Versão 2" no fim).
Base: `ideia-do-dono.md` e `docs/direcao-narrativa.md` (mandam), `cenas-curtas.md` §1 e §2, `linguagem.md`, `docs/fases/fase6c-escopo.md` (§3, §4.1, §4.3), `docs/fases/fase6c1-design.md` (§1, §4, §6), `docs/fases/fase6c1-textos.md`.
Nomes: John Bullet (1º lutador), Osmar Brandão (treinador), Raízes Fight Club, Academia Boa Esquina. O rival não aparece.

**As imagens são rascunho de composição, não arte final.** Mostram onde cada um fica, a luz, as silhuetas e o tempo. A arte final já está no manifest e os dados das cenas usam essa arte (ver "Versão 2").

## Imagens
| Arquivo (`docs/arte/mockups/`) | O que é |
|---|---|
| `prancha_6c1_chegada.png` | Folha com os 8 quadros A1 a A8, 640x360 cada, com legenda |
| `prancha_6c1_saida.png` | Folha com os 8 quadros J1 a J8 (J8 = variante da garagem) |
| `prancha_6c1_elenco.png` | Os 3 elencos da chegada no quadro A2, mesmo recorte em 2x |
| `prancha_6c1_chegada_A01..A08.png`, `prancha_6c1_saida_J01..J08.png` | Quadros soltos, 640x360 |

Gerador: `tools/art/make_prancha_6c1.gd`. Rodar de uma pasta temporária com `project.godot` vazio:
`Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_prancha_6c1.gd` (um argumento depois de `--` troca a pasta de saída).

Dados: `data/cutscenes/primeira_academia.json` e `data/cutscenes/saida_primeiro_mentor.json`. Os nomes seguem o escopo, o design e `data/escola.json` (o pedido inicial falava em `chegada_academia` e `saida_john`).

## A ideia visual das duas
- **A academia só vira casa quando o Osmar acerta a foto.** (Mudança do dono, 2026-11-16: antes ele entortava; agora a foto cai torta no prego e ele a desentorta. Casa nova, a gente chegou.) A sala começa com um tubo aceso e metade no escuro. O segundo tubo só acende depois do "agora sim.".
- **Quem traz o caixote senta nele.** A "caixa" da mudança é o caixote do mentor. O John carrega o lugar dele para a casa nova, pousa e senta. É de lá que ele assiste o Osmar pendurar a foto, e é de lá que ele levanta para ir embora na outra cena.
- **A chegada tem um corte; a saída não tem nenhum.** A chegada é a única cena da 6c1 com a interface apagada. A saída acontece atrás do treino, com tudo ligado.
- **Uma batida só.** O Osmar bate o prego uma vez e o John acena a cabeça uma vez. Dois toques ritmados continuam sendo só do gesto do John.
- **Os mesmos pontos da garagem.** Osmar, caixote e 2º mentor ficam na academia nas mesmas coordenadas da garagem (proposta, o Diretor de Arte confirma). A foto fica ao lado da cabeça do Osmar, como na garagem.

---

## Cena 1: Primeira chegada à academia
Gatilho: MUDAR para a academia com o marco `cena_primeira_academia` ausente (design §1.1). Controle preso: **12,9 s** previstos, teto 15 s. O validador mede 12,90 s com as folhas reais (marca "provisório" só porque ainda não resolve quem é o `mentor:seat`; o `put_crate` real tem 0,3 s e não está no caminho mais longo). Relógio da campanha parado. Depois da cena o jogo abre a escolha da arte, se pendente.

### Quadros
| # | Tempo | Câmera | Quem e como | Fala | Passa para o próximo |
|---|---|---|---|---|---|
| **A1** Casa vazia | 0,0–1,2 s | Sala 1x. A interface apaga em 2 quadros | Academia sem aparelho, sem equipe e sem foto. Tubo da esquerda aceso (pisca uma vez), tubo da direita apagado: a metade direita fica 1 passo mais escura. O Osmar já está no ponto dele (196,236), com a foto nas mãos, olhando a parede. Em 0,9 s a porta da rua abre e a luz do dia entra no chão | — | Sem corte: alguém aparece na porta |
| **A2** A mudança entra | 1,2–3,0 s | Sala 1x | Entra primeiro quem traz o **caixote** nos braços (elenco abaixo). 0,8 s depois, o **lutador da campanha** com o saco remendado no ombro. Andam a 48 px/s, da porta (428,224) para a esquerda | — | Sem corte: a porta fica livre e o ajudante tenta entrar |
| **A3** A esteira não passa | 3,0–5,8 s | Sala 1x | Ao fundo, o **vizinho com a esteira velha atravessada**: bate nos batentes (3,4 s, tremida de 1 px), recua, bate de novo (4,7 s) e fica parado. O lutador para em (352,262), saco no ombro, e olha o Osmar. Quem trouxe o caixote chega ao `gym_mentor_spot` (254,252), pousa o caixote (5,25 s) e fica em pé ao lado (o vizinho não senta) | — | Corte seco para 2x quando o Osmar ergue a foto |
| **A4** Pendura a foto | 5,8–6,8 s | **2x**, região (128,118,192,136) | O Osmar encosta a moldura na parede, bate o prego com a palma **uma vez**, solta e a foto escorrega um pouco: fica **torta**. O mentor sentado no caixote assiste, parado. O lutador e a porta ficam fora do quadro | — | Mesmo plano |
| **A5** Passo atrás | 6,8–8,2 s | 2x, mesmo plano | O Osmar recua 8 px até (188,240), inclina a cabeça (do jeito que a foto está) e olha. **0,9 s sem som novo**: é a pausa da cena | — | Mesmo plano |
| **A6** Desentorta | 8,2–10,4 s | 2x, mesmo plano | Ele volta ao ponto, acerta o canto da moldura com um dedo e a foto fica **reta**. Só então fala | **Osmar:** "agora sim." (`aca_agora_sim`) | Corte seco de volta ao 1x, junto com o estalo do tubo |
| **A7** O outro tubo acende | 10,4–12,9 s | Sala 1x | O tubo da direita pisca e acende, e a sala clareia inteira. O lutador anda até (303,272) e ergue o saco para o gancho (336,183), com poeira. O ajudante vira a esteira de lado, passa e encosta ela no lugar (445,267). 0,4 s de respiro com a academia inteira | — | A interface volta |
| **A8** A interface volta | 12,9 s | Sala 1x, interface ligada | A equipe, os aparelhos, as caixas e o 2º mentor (se houver) aparecem nos pontos do jogo. Os vizinhos que ajudaram somem junto com a entrada da equipe. A porta fecha sozinha. A escolha da arte abre por cima, se pendente | — | Fim |

### Elenco (uma cena só, `prancha_6c1_elenco.png`)
| Situação | Lutador (saco) | Caixote | Esteira |
|---|---|---|---|
| Carreira 1 | John | vizinho (`helper_2`). Pousa o caixote, fica em pé (`helper_stand`) e some no A8 | vizinho (`helper`) |
| Discípulo, com o John na escola | discípulo, com o `look` dele | **John**, que termina sentado como mentor | vizinho |
| Depois da saída do John | discípulo | o último que passou o posto, que termina sentado | vizinho |

O 2º mentor em pé (Carreira 3 em diante, com o John) fica **fora da cena** e aparece no ponto dele no A8, como o Designer propôs: a cena já tem 4 pessoas.

### Se pular
- Em qualquer quadro: em 0,3 s fica o estado do A8. Dois tubos acesos, Osmar no ponto, foto reta na parede, caixote no lugar com o mentor sentado (se houver), saco no gancho, equipe e aparelhos de volta, porta fechada. O jogo abre a escolha da arte, se pendente.
- O marco é gravado no MUDAR. Pular, fechar o jogo no meio ou chegar com outro lutador não repete a cena.
- Como pular: segurar ESC ou ESPAÇO por 0,5 s, ou clicar em PULAR.
- Nada do jogo depende da cena: a foto, o Osmar e os mentores na academia saem do marco.

### Se o tempo apertar (ordem de corte do escopo §8)
1. A segunda batida da esteira sai (a entrada do ajudante passa de 3,0 s para 3,9 s).
2. O tubo acende sem piscar.
3. A poeira do saco sai.
Não se corta: a foto torta no prego, o passo atrás, a foto acertada e "agora sim.".

### Arte por quadro
| # | Arte nova | Reaproveita |
|---|---|---|
| A1 | Osmar `hold_photo`. Cenário: `gym_half_dark` (máscara da metade escura), `gym_door` (fechada, abrindo, aberta com a rua no vão), `gym_daylight` (luz no chão) | `gym_bg`, `gym_tube` (quadro 1 = apagado, animação `flicker`), som `lamp_hum` |
| A2 | Lutador `carry_bag` (John e discípulo em camadas). Quem traz o caixote: `carry_crate` (John, discípulo em camadas, vizinho) | sons de passo |
| A3 | Lutador `carry_bag_idle`. Vizinho com a esteira: `treadmill_bump`, `treadmill_stuck`. Quem traz o caixote: `put_crate`; o vizinho fica em `helper_stand` (não senta) | `garage_crate_gym` |
| A4 | Osmar `hang_photo`. Objeto: `wall_photo_old_gym` (quadro 0 reta, quadro 1 torta) | a arte da `wall_photo_old` |
| A5 | Osmar `step_back` e `look_photo` (cabeça inclinada) | — |
| A6 | Osmar `nudge_photo` | balão, plaquinha `osmar`, voz `coach` |
| A7 | Lutador `hang_bag`. Vizinho `treadmill_turn`, `treadmill_carry`, `treadmill_put`, `stand` | `bag_lN_hit_gym`, `fx_arrive_dust_small`, `treadmill_l0_side_gym`, `coach_idle_gym`, som `tube_start` |
| A8 | nada | a sala do jogo e a janela da arte |

---

## Cena 2: Saída do John (ação no cenário)
Gatilho: `mentor_leave_due` (design §6): a saída fica devida depois da 1ª vitória de um discípulo na academia ou na campanha F+3, e toca no 1º momento calmo com o John desenhado. Momento aprovado pelo dono em 2026-11-15. **0 s presos.** Duração da ação: 13,9 s, mais 2,6 s do último mentor indo sentar.

Regras da cena inteira: interface ligada, o soco vale do primeiro ao último quadro, sem barras, sem corte, sem 2x, sem música, sem gesto dos dois toques, balões passivos que nunca cobrem o alvo. O lutador, a equipe e os aparelhos não são da cena: continuam vivos.

### Quadros (academia)
| # | Tempo | Câmera | Quem e como | Fala | Passa para o próximo |
|---|---|---|---|---|---|
| **J1** Levanta e pega a bolsa | 0,0–1,6 s | Sala 1x, interface ligada | O John levanta do caixote e pega uma bolsa de lona que estava atrás dele. A bolsa só existe a partir daqui | — | Ele começa a andar |
| **J2** Atravessa a sala | 1,6–4,8 s | igual | Anda a 48 px/s em 3 trechos: do caixote sobe até o fundo do piso (274,224), segue rente à parede até (364,224), **48 px atrás do lutador e atrás do saco**, e só desce até (380,246) depois do saco. Na faixa do lutador só as canelas dele passam atrás da cabeça do lutador (correção do C2 da 6d) | — | Ele para perto da porta |
| **J3** Olha a sala | 4,8–6,1 s | igual | Vira para a esquerda e olha a sala por 1,3 s, com a bolsa no ombro | — | O balão entra |
| **J4** "vou procurar meu rumo." | 6,1–10,5 s | igual | Parado. Dois balões passivos seguidos, empurrados para a direita do alvo | **John:** "vou procurar meu rumo." (`saida_rumo_1`) e "cuidem bem disso aqui." (`saida_rumo_2`) | O Osmar responde |
| **J5** "vê se manda notícia." | 10,5–12,9 s | igual | O Osmar responde do lugar dele, sem andar. O John acena com a cabeça, uma vez | **Osmar:** "vê se manda notícia." (`saida_resposta`) | O John vira para a porta |
| **J6** Sai pela porta da rua | 12,9–14,4 s | igual | Abre a porta, sai, a porta fecha. Ninguém se despede de novo | — | A sala segue |
| **J7** O caixote tem outro dono | 14,4–17,0 s | igual | O último que passou o posto anda do ponto de pé (150,262) até o caixote e senta. Na Carreira 2 não há ninguém: o caixote fica vazio | — | Fim. O treino nunca parou |
| **J8** Na garagem (reserva) | mesmos tempos | igual | Tudo igual até o J5. No J6 a porta de enrolar sobe, emperra, e ele passa por baixo, como sempre fez. A porta desce sozinha | as mesmas | Fim |

### Se o jogador interromper
- Abrir janela, começar luta, MUDAR, tela de fim ou RECEBER: a ação termina **na hora** no estado final. John fora, bolsa fora, portas fechadas, balões fechados, o último sentado no caixote (ou o caixote vazio), ponto de pé vazio.
- Não tem botão PULAR nem dica de tecla: a cena não prende nada. Clique e ESPAÇO só treinam.
- O marco `cena_saida_primeiro_mentor` e o `mentor_leaves` são gravados no começo. Fechar o jogo no meio abre a sala já no estado final. Nunca toca de novo.
- Nenhum objeto do John fica na sala.

### Arte por quadro
| # | Arte nova | Reaproveita |
|---|---|---|
| J1 | John `stand_up` (pode ser o `sit_down` de trás para frente) e `pick_duffel`. Objeto: `john_duffel` (bolsa no chão) | `john_sit_rest`, `garage_crate` |
| J2 | John `walk_duffel` (andar sem luvas, bolsa no ombro; virado para a direita) | sons de passo |
| J3 | John `look_room` (virado para a esquerda, bolsa no ombro) | — |
| J4 | nada | balão passivo, plaquinha `john`, voz `first` |
| J5 | John `nod` | `coach_talk`, `coach_idle`, voz `coach` |
| J6 | nada além da `gym_door` da chegada | `walk_duffel` |
| J7 | Discípulo em camadas `sit_down` e `sit_rest` (as mesmas da chegada) | `disciple_walk_bare`, `disciple_stand_bare` |
| J8 | John `duck_out` (passar por baixo saindo, com a bolsa) | `garage_door`, `garage_door_outside`, `garage_daylight`, sons `door_roll` e `door_jam` |

---

## O que a prancha mudou em relação à `cenas-curtas.md`
1. **A "caixa" virou o caixote do mentor.** Resolve onde a caixa fica depois da cena e dá ao John um lugar para assistir sem roubar o momento do Osmar.
2. **O Osmar já está na sala no começo.** Ele não entra pela porta: economiza 2 s e uma folha de andar, e abre a cena com a imagem dele sozinho com a foto.
3. **A foto fica no barrado verde, ao lado da cabeça do Osmar,** em (212,158), e não na parede creme: a parede creme fica acima do alcance do braço, e à direita do espelho o saco e a corrente passam na frente.
4. **O lutador espera fora do recorte do 2x** e só pendura o saco no A7. Com ele no lugar final, o saco no ombro entrava no canto do plano fechado.
5. **A esteira para de bater durante o plano 2x.** Um baque de metal em cima da pausa da foto disputaria a atenção. A piada fecha no A7.
6. **A equipe e os aparelhos voltam no A8,** junto com a interface, e os vizinhos que ajudaram somem aí: são a equipe da sala.
7. **Saída: uma parada só, perto da porta.** O John fala de onde vai sair. Os balões ficam longe do alvo e a cena não atravessa a faixa do clique.
8. **Saída em um arquivo só para os dois locais,** com passos condicionados ao local (formato §9, item 22).

## Decisões que fogem do escopo (cada uma com a minha recomendação)
1. **Caixote na academia no lugar do banco.** O design §4.1 prevê "caixote ou banco" e `seat_prop.gym = gym_mentor_bench`, visível desde a 1ª sucessão. A prancha usa o caixote, que chega na cena e fica visível com o marco `cena_primeira_academia`, inclusive na Carreira 1. *Recomendo o caixote:* reaproveita as folhas de sentar e é o que dá sentido à caixa. Decide o Designer, com o Diretor de Arte.
2. **Chegada sem esteira comprada.** A esteira custa $500 e a academia pede o cinturão, então é raro. Nesse caso o ator `helper` não entra (campo `requires.owned`) e a cena perde só a piada do fundo. *Recomendo assim;* a alternativa é uma folha a mais de vizinho com caixa grande. Decide o Diretor de Jogo.
3. **Pontos da academia iguais aos da garagem** (Osmar 196,236; caixote 254,252; 2º mentor 150,262) e foto em (212,158). São propostas minhas para a cena fechar; o Diretor de Arte confirma no mockup com a sala cheia. Se um ponto mudar, mudam três posições inteiras em `primeira_academia.json`.
4. **Nomes dos arquivos:** `primeira_academia.json` e `saida_primeiro_mentor.json`, como no escopo e em `data/escola.json`, e não `chegada_academia` / `saida_john`.
5. **Teste da 6b1 fica vermelho** até o Programador atualizar: `tests/test_fase6b1.gd` confere que `data/cutscenes/` tem exatamente 2 cenas, e a saída usa 3 coisas que o validador ainda não conhece (formato §9, itens 22 e 23).

## Versão 2: dados ajustados à arte e aos sons finais (2026-11-15)
O que mudou em `primeira_academia.json` e `saida_primeiro_mentor.json`:
1. **Sons próprios** (`tools/sfx/make_sfx.gd`) no lugar dos dublês: `gym_door_open`, `gym_door_close`, `metal_bump` (esteira na porta), `crate_down`, `nail_knock` (a batida única do prego), `frame_scrape` (foto escorrega no prego e foto acertada), `tube_start` (o tubo da direita no A7). O `ring_clink` do A7 ficou só para a argola do saco.
2. **O vizinho do caixote não senta** (corte 4 do pedido): `put_crate` e depois um passo só, `stand` em laço. Para o `helper_2` isso é o `helper_stand`. Limite: John e discípulo ainda não têm folha `stand` sem luva; eles ficam no último quadro do `put_crate` (em pé) até o A8, quando o jogo os desenha sentados. Se quisermos o mentor sentando de novo dentro da cena, falta um jeito de o passo valer só para um personagem (ver pedidos ao Programador).
3. **Nomes das poses = folhas reais.** Onde a folha só existe virada para a esquerda o nome leva `_left` (`carry_bag_left`, `carry_bag_idle_left`, `carry_crate_left`, `treadmill_*_left`, `stand_left` do vizinho da esteira, `look_room_left`, `nod_left`). Osmar na academia: `idle_gym` e `talk_gym` (na saída, por `if.location`).
4. **Porta da academia com 6 quadros.** A chegada começa em `closed_dark` e abre com `open_dark`; no A7 a porta vai do quadro 5 para o 2 no mesmo tique em que o `gym_half_dark` some; no fim fecha com `close` (claro). A luz do dia (`gym_daylight`, definida depois do `gym_half_dark`) entra no quadro 4 da porta (meia) e abre no 5, e fecha junto com a porta. A saída ganhou a mesma luz do dia na academia (`gym_light`). Porta em (401,116), luz em (330,220), caixote `garage_crate_gym`.
5. **Pisca dos tubos e foto torta quadro a quadro.** `gym_tube` e `wall_photo_old_gym` estão com `fps 0` no manifest: as animações `flicker` e `tilt` tocariam a 0,1 fps. A cena troca os quadros direto (pisca a ~12 fps; a foto entra no quadro 1 = torta e passa ao 0 = reta).
6. **Tempo preso da chegada: 12,90 s** (era 14,95 s). `look_photo` tem 0,3 s de folha + 0,6 s parado (a pausa continua 0,9 s); "agora sim." segura 1,05 s para o A7 começar em 10,4 s; o respiro final passou para 0,65 s porque o `hang_bag` real (0,8 s) termina antes.
7. **Saída:** `john_pick_duffel` real (6 quadros, 56x72, pivô 22,67); a bolsa do chão some em 0,4 s (`grab_frame` 4) e ele segura 0,6 s, então o J2 continua começando em 1,6 s.

## Versão 3: o Osmar desentorta a foto (decisão do dono, 2026-11-16)
O dono trocou o gesto do A6: em vez de entortar, o Osmar **desentorta**. Mensagem: casa nova, a gente chegou.
1. **A4:** a foto solta no `release_frame` do `hang_photo` já **torta** (`wall_photo_old_gym` quadro 1); o `frame_scrape` vira ela escorregando no prego.
2. **A5:** ele olha a foto torta com a cabeça inclinada (o `look_photo` serve como está: a cabeça inclina para o lado da foto).
3. **A6:** o dedo acerta a moldura e ela passa ao **quadro 0 (reta)**; "agora sim."; o tubo acende no A7.
4. **Depois da cena:** a foto fica **reta** na academia para sempre (`data/escola.json` `old_photo.gym.tilted = false`). Na garagem nada muda.
5. Tempo preso igual: **12,90 s** (teto 15). Nenhum passo mudou de duração.

Pendências de outros papéis:
- **Artista de Personagens** (`coach_nudge_photo`): hoje o quadro 2 empurra o canto de baixo à direita **1 px para baixo** (gesto de entortar). Na foto torta esse canto está 1 px mais baixo que na reta; para desentortar, o dedo precisa **erguer** o canto: quadro 1 encosta 1 px abaixo de onde encosta hoje (ponta perto de 229,178) e o quadro 2 sobe 1 px (de volta a ~229,177), com a foto trocando para reta nesse quadro. Basta trocar a altura do dedo dos quadros 1 e 2. Atualizar o `frames_note` ("a foto entorta NESTE quadro" → "a foto endireita NESTE quadro", `straight`). Sem a correção a cena funciona, mas o dedo desce enquanto a foto sobe (1 px, quase invisível no 2x). O `hang_photo` serve: a moldura nas mãos (quadros 1-4) é a reta e na soltura ela aparece torta, o que lê como escorregar no prego.
- **Diretor de Arte** (manifest): nota do `wall_photo_old_gym` ("No jogo, sempre o quadro 1" → quadro 0 na academia) e `by_data_id.gym_arrival_scene.props.photo.frames` ("0 reta (A4-A5)", "1 torta (no jogo, sempre)" → "1 torta (A4-A5)", "0 reta (A6 em diante, no jogo)").
- **Roteirista** (`data/dialogos.json`): `cl_ac_chegada_2` ("torta, como manda.") e o hover `objects.old_photo_gym`.
