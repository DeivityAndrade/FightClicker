# Cena: Primeira sucessão (storyboard)

Dono: Diretor de Cutscenes. **Versão 2.1 (2026-11-14, ponto do mentor novo).** Fase 6b1. Cena única.
Esta versão junta a prancha aprovada (`prancha-6b.md`, todas as opções A, registro em `ideia-do-dono.md`) e o fluxo do Designer (`docs/fases/fase6b1-design.md`). **Os tempos e posições daqui são os mesmos de `data/cutscenes/primeira_sucessao.json`; se divergirem, vale o arquivo de dados.**
Nomes: John Bullet (ator `first`, plaquinha `john`, voz `first`), Osmar Brandão (ator `coach`), o discípulo criado pelo jogador (ator `disciple`).
Função (direção narrativa §9): mostrar a passagem de responsabilidade e apresentar o novo discípulo. **Sem despedida triste:** o anterior continua conosco.
Par visual: `reencontro-final.md`. Linguagem: `linguagem.md`. Gesto: `gesto-assinatura.md`. Pedidos de arte e som: `pedidos-6b1.md`.

## Escolhas do dono que esta versão aplica
| # | Escolha (A) | Onde aparece |
|---|---|---|
| 1 | Tela de criar o discípulo no meio da cena | S5, entre a parte 1 e a parte 2 |
| 2 | John pendura o par no saco; o discípulo pega sozinho | S3 e S9 |
| 3 | Luz do dia clara e branca | S4 (fresta) e S6 em diante |
| 4 | Osmar presente e calado | só vira a cabeça em S4; volta ao normal no fim |
| 5 | Corte de perto (2x) no gesto | S3, o único corte da cena |

## Gatilho
- **Evento:** `handover_started`, o RECEBER NOVO DISCÍPULO apertado na tela de fim, na **primeira sucessão** do save (marco `cena_primeira_sucessao` ausente). A cena toca na garagem já zerada da campanha nova: só o saco, sem corda, esteira, caixas nem equipe.
- **Marco:** `cena_primeira_sucessao`, gravado pelo jogo antes do primeiro passo, junto com `mentor_in_room` (John) e o caixote permanente.
- **Carreira 1 curta:** não depende de vitória, cinturão, compra nem tempo.
- **Save antigo:** toca no próximo RECEBER, com o John no lugar de quem treina. Nenhuma fala diz "primeiro" ou "segundo".
- **Sucessões seguintes:** só a tela de criação e a chegada curta (última seção).
- O relógio da campanha fica parado até o `return_control` (design §2).

## Palco
Garagem, janela de cena = a sala (128,18,384,272). Base 640x360, personagens pelo ponto dos pés.

| Elemento | Posição | Observação |
|---|---|---|
| Saco (`bag_l0`) | argola em (336,183) | objeto da sala, controlado pela cena até o `return_control` |
| Lâmpada (`lamp`) | (300,32) | idem; balança no 3º soco e para junto com o saco |
| Porta de enrolar | miolo x 382..463, y 100..219 | **emperra com a borda em y 171** (altura do ombro) |
| John | começa em (303,272), virado para a direita | luva velha |
| Osmar | (196,236) | não fala |
| Discípulo | atrás da porta em (423,221) | só aparece na parte 2 |
| Ponto do mentor (`mentor_spot`) | **(254,252)** (Diretor de Arte) | caixote em (238,232), lá desde o começo da cena |
| Par de luvas pendurado | cadarço na argola (335,186); luvas perto de **(325,206) e (331,211)** | no ombro esquerdo do saco, ao alcance do braço |

## Parte 1: antes de criar o discípulo (9,0 s)

| # | Tempo | Plano | O que acontece | Pose / animação | Som |
|---|---|---|---|---|---|
| **S1** Últimos socos | 0,00–1,72 | sala 1x | A interface apaga em 0,3 s. John solta 3 socos (começam em 0,40 / 0,93 / 1,47). No 3º ele **não recolhe o braço**. O saco balança e, no 3º, a lâmpada balança junto. | `punch` x2 e o 3º só até o quadro do golpe; saco `hit`; lâmpada `swing` | `punch_1`, `punch_2`, `hit_heavy`; `chain_creak` em laço desde o 1º soco |
| **S2** Segura o saco | 1,72–3,62 | sala 1x | Ele segura o saco com as duas luvas, cabeça um pouco baixa. Saco e lâmpada param juntos. Fica só o zumbido. | `hold_bag` (0,3 s e segura 1,6 s); saco e lâmpada parados | `bag_catch` em 1,92; `chain_creak` some; `lamp_hum` entra |
| **S3** Abre o fecho | 3,62–6,62 | **corte seco para 2x**, região (222,154,192,136) | Luva na boca, puxa o fecho com os dentes, tira as duas luvas (2,0 s). Joga o par pelo cadarço na argola do saco e olha a mão nua abrir e fechar (1,0 s). | `gloves_off` (o gesto ao contrário); `hang_gloves`; o par aparece no saco em 5,87 | `strap_open` em 3,87; `glove_leather` em 4,37 e 4,87; `ring_clink` em 5,97 |
| **S4** Alguém na porta | 6,62–9,00 | **corte seco para 1x** | A porta treme e sobe 3 px. Na fresta, dois pés contra a luz e a sombra deles esticada 14 px no chão. John vira a cabeça (7,12), depois o Osmar (7,27). Os dois ficam olhando. | porta `shake_ajar`; luz `sliver`; sombra de pés; `look_door`; `coach_look` | `door_shake` |

**S5 Tela de criação.** A sala escurece em dither e a janela "receber novo discípulo" abre no meio. A cena fica parada atrás: John olhando a porta, luvas no saco, fresta de luz. Não pode ser pulada nem fechada. Sem tempo: espera o CONFIRMAR.

## Parte 2: o discípulo entra (6,0 s)

| # | Tempo | Plano | O que acontece | Pose / animação | Som |
|---|---|---|---|---|---|
| **S6** A porta emperra | 0,00–1,30 | sala 1x | A porta sobe em 0,8 s e trava com um tranco de 1 px. Luz do dia branca no chão, pela primeira vez no jogo. O discípulo aparece **do ombro para baixo**, com a pele e o calção escolhidos, e a sombra comprida entra na sala. Meio segundo parado. | porta `open_jam`; luz `open`; discípulo `stand_bare` atrás da porta | `door_roll`; `door_jam` em 0,70 |
| **S7** Passa por baixo | 1,30–2,00 | sala 1x | Ele passa por baixo com uma mão na borda, de (423,221) a (410,236), e endireita o corpo. John sorri de leve (em 1,70). | `duck_under` (0,7 s); `walk_bare` | 2 passos |
| **S8** "vamos ver sua guarda." | 2,00–4,47 | sala 1x | Assim que o discípulo fica de pé, John recua de frente para ele, com passo de boxeador, até o `mentor_spot` (254,252): 53 px em 1,1 s. Aponta com a mão aberta o chão em frente ao saco e fala em 3,40. O discípulo vem andando por (392,258) até (303,272). | `step_back` (1,1 s); `point_spot`; discípulo `walk_bare` (2,47 s) | passos; voz `first` |
| | | | **John:** `suc_guarda` ("vamos ver sua guarda.") | balão de cena, some sozinho por volta de 5,6 | blip |
| **S9** Pega o par dele | 4,47–5,99 | sala 1x | O discípulo se vira para o saco, estica o braço, pega as luvas, calça e arma a guarda (pronto em 5,27). Quando o balão some, John **senta no caixote** (5,59–5,99). A interface volta. | `take_gloves` (0,8 s) → guarda com a luva velha; John `sit_down` → `sit_rest` | `glove_leather`; `strap_close` (sem os dois toques: o gesto é só do John) |

**Controle devolvido em 6,0 s.** Tempo preso: 9,0 + 6,0 = **15,0 s** (teto 16), fora a tela de criação. Com uma fala de 26 caracteres a parte 2 vai a 6,3 s (teto 6,5).

O recuo do John ficou mais longo com o ponto novo (53 px em vez de 35). Para não estourar o teto, ele começa a recuar em 2,00, enquanto o discípulo dá os primeiros passos dentro da sala, e não mais em 2,59.

## Depois do controle (sem prender o jogador)

| Quando | O que acontece |
|---|---|
| 0,6 s depois | A porta destrava e desce sozinha, com o mesmo tranco. A luz do dia some. O Osmar volta a olhar o treino. |
| **S10: no primeiro clique** | John, já sentado, bate **dois toques de punho** sem luva (`mentor_first_taps`, `tap_fist`, intervalo de 0,22 s) e diz `suc_isso` ("isso.") em balão passivo. Conta como o toque do 1º clique da campanha (design §4). |

**Mudança em relação à prancha:** nela, John sentava *no* primeiro clique. Aqui ele senta no fim do S9, antes de o controle voltar. Motivo: o Designer protege os toques dos cliques só nos primeiros 0,5 s; se ele ainda tivesse que sentar, o jogador rápido cancelaria os toques sem ver. A imagem do S10 é a mesma.

## Se pular
- **S1 a S4:** vai direto para a tela de criação, com o estado do S5 (John sem luvas olhando a porta, par no saco, fresta de luz). É o bloco `state` do passo `open_screen`.
- **S6 a S9:** em 0,3 s fica o estado final: discípulo de guarda com a luva velha em (303,272), John sentado no caixote, porta fechada, interface de volta.
- A reação do 1º clique continua armada.
- **Fechar o jogo** (design §1.4): antes do CONFIRMAR, ao abrir aparece a tela de criação sobre a garagem com John já sentado e o par no saco, e depois toca a **chegada curta**. Depois do CONFIRMAR, aplica o estado final. A cena grande nunca repete.

## O que fica no cenário
- **John sentado no caixote**, no `mentor_spot`, até a saída dele (6c). O caixote fica.
- **A luva velha é o par dele**, passada a cada discípulo. O par espera no saco no começo de toda campanha nova.
- A porta que emperra no ombro vira "coisa da casa": toda chegada usa.

## Falas
| Chave (`data/ui_texts.json`) | Quem | Texto | Modo |
|---|---|---|---|
| `suc_guarda` | John | "vamos ver sua guarda." | cena, S8 |
| `suc_isso` | John | "isso." | passivo, S10 |

Osmar e o discípulo não falam. Texto final e polimento: `docs/fases/fase6b1-textos.md`.

## Fora desta fase
- Esparadrapo no John depois de derrota: fase 13 (escopo §3, item 12).
- O discípulo nunca faz o gesto nem os dois toques.

## Chegada curta (`data/cutscenes/chegada_discipulo.json`)
Para toda sucessão depois da primeira. Sem fala, sem marco, pulável, **2,37 s presos** (teto 2,5; medido no jogo fica uns 0,04 s acima da conta).

| Tempo | O que acontece | Som |
|---|---|---|
| antes da tela (0 s) | Interface apagada. A porta treme e sobe 3 px, dois pés na fresta. O par de luvas já está no saco. A tela de criação abre por cima. | `door_shake` |
| 0,00–0,30 | CONFIRMAR. A porta sobe rápido e emperra. Luz do dia. | `door_roll`, `door_jam` |
| 0,10–0,80 | O discípulo passa por baixo, de (423,221) a (410,236). | 2 passos |
| 0,80–2,37 | Anda apressado (72 px/s) até (303,272). | passos |
| 2,37 | Guarda com a luva velha; o par some do saco. A interface volta. | `glove_leather` |
| depois | A porta desce sozinha. | `door_roll`, `door_jam` |

- A troca para a guarda com luvas é **seca** (não cabe o `take_gloves` em 2,5 s). Ela acontece junto com a volta da interface.
- Os mentores sentados não são tocados pela cena. O caminho da porta ao saco não passa pelo `mentor_spot`.
- Se pular: estado final em 0,3 s.

## Como as duas cenas conversam

| | Primeira sucessão (garagem) | Reencontro final (última arena) |
|---|---|---|
| **Janela** | a sala, 384x272 | a mesma janela 384x272, dentro da arena |
| **Luz** | uma lâmpada quente; quem chega vem da **luz do dia** | a mesma lâmpada; quem chega vem do **escuro** |
| **Porta** | de enrolar, x 382..463, emperra **no ombro** (borda em y 171) | no mesmo lugar do quadro, emperra no ombro (borda em y 194) |
| **Quem chega** | o discípulo, do ombro para baixo, **passa por baixo** | John, do ombro para baixo, passa por baixo **com a mesma pose** |
| **Quem espera** | John, à esquerda, virado para a direita | o discípulo, à esquerda, virado para a direita: no lugar que era dele |
| **Gesto** | **abre** o fecho com os dentes e tira as luvas | **aperta** o fecho com os dentes e bate dois toques |
| **Plano 2x** | um corte, no gesto | um corte, no gesto, com as mãos na mesma altura do quadro |
| **Som** | o saco para; zumbido; `strap_open`; `door_roll` + `door_jam` | silêncio; `door_roll` + `door_jam`; `strap_rip`; dois toques |
| **Fala** | "vamos **ver** sua guarda." | "quero **ver** o que aprenderam." e é ele quem arma a guarda |
| **Depois** | o controle volta e ele senta para assistir | a janela abre, as barras de vida entram e ele luta |
