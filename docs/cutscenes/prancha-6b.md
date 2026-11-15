# Prancha de quadros-chave da 6b: Primeira sucessão e Reencontro final

Dono: Diretor de Cutscenes. Versão 1 (2026-11-14). Pedida em `docs/fases/fase6a-revisao.md` §4: o dono aprova antes do escopo da 6b.
Base: `ideia-do-dono.md` e `docs/direcao-narrativa.md` (mandam), `primeira-sucessao.md`, `reencontro-final.md`, `linguagem.md`, `gesto-assinatura.md`.
Nomes: John Bullet (1º lutador), Osmar Brandão (treinador), Raízes Fight Club. **O rival não aparece em nenhuma das duas cenas**; onde for preciso citá-lo, o marcador é `[RIVAL]`.

**É rascunho de composição, não arte final.** As imagens mostram onde cada um fica, a luz, as silhuetas e o tempo. As poses novas são um quadro só, feitas por código, e não entraram em `assets/` nem no manifest.

## Imagens
| Arquivo (`docs/arte/mockups/`) | O que é |
|---|---|
| `prancha_6b_sucessao.png` | Folha com os 10 quadros S1 a S10, 640x360 cada, com legenda |
| `prancha_6b_reencontro.png` | Folha com os 10 quadros R1 a R10 |
| `prancha_6b_pares.png` | Os 3 pares que ligam as duas cenas (porta, gesto, passar por baixo), no mesmo recorte |
| `prancha_6b_sucessao_S01..S10.png`, `prancha_6b_reencontro_R01..R10.png` | Quadros soltos, 640x360 |

Gerador: `tools/art/make_prancha_6b.gd`. Rodar de uma pasta temporária com `project.godot` vazio:
`Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_prancha_6b.gd` (um argumento depois de `--` troca a pasta de saída).

## A ideia visual das duas cenas
- **Uma lâmpada, uma porta, um lugar à esquerda.** As duas cenas usam a mesma janela de 384x272, a mesma lâmpada e a porta de enrolar no mesmo ponto do quadro. Quem espera fica à esquerda, virado para a direita.
- **Na sucessão, quem chega vem da luz.** A porta sobe e a luz do dia corta o chão da garagem pela primeira vez no jogo. Na garagem só existia a lâmpada.
- **No reencontro, quem chega vem do escuro.** A porta abre para o preto e ele anda até a lâmpada. O discípulo está no lugar que era dele.
- **O gesto dele ao contrário.** Na garagem ele abre o fecho com os dentes e tira as luvas. Na arena ele aperta o fecho e bate os dois toques, com o rosto escondido pela porta.
- **A câmera não se mexe.** Cada cena tem um único corte de perto (2x), no gesto.

---

## Cena 1: Primeira sucessão (garagem, fase 6b)
Gatilho: o jogador aperta "receber novo discípulo" depois do fim da Carreira 1. Controle preso: 9 s (parte 1) + 6,2 s (parte 2). A tela de criar o discípulo fica no meio.

### Quadros
| # | Tempo | Câmera | Quem e como | Fala | Passa para o próximo |
|---|---|---|---|---|---|
| **S1** Últimos socos | 0,0–1,8 s | Sala 1x. A interface apaga em 2 quadros | John solta os 3 últimos socos. O saco balança forte e a lâmpada balança junto. Osmar assiste encostado no carro | — | Sem corte: no 3º soco ele não recolhe o braço |
| **S2** Segura o saco | 1,8–3,6 s | Sala 1x | John segura o saco com as duas luvas, cabeça um pouco baixa. O saco e a lâmpada param juntos. Fica só o zumbido | — | Corte seco para 2x quando a luva sobe |
| **S3** Abre o fecho | 3,6–6,6 s | **2x**, região (222,154,192,136) | Luva na boca, ele puxa o fecho com os dentes, tira as duas luvas e amarra o par na argola do saco. Abre e fecha a mão nua uma vez | — | Corte seco de volta ao 1x, junto com o som da porta |
| **S4** Alguém na porta | 6,6–9,0 s | Sala 1x | A porta treme e sobe 3 px. Na fresta aparecem dois pés, e a sombra deles estica no chão. John e Osmar viram a cabeça para a porta | — | A sala escurece em dither e a tela de criação abre |
| **S5** Tela de criação | espera o jogador | Sala 1x escurecida, janela no meio | A cena fica parada atrás da janela: John olhando a porta, luvas no saco | — | Ao confirmar, a janela fecha e a sala clareia |
| **S6** A porta emperra | parte 2: 0,0–1,3 s | Sala 1x | A porta sobe e trava com um tranco de 1 px. Luz do dia no chão. O discípulo aparece do ombro para baixo, já com a pele e o calção escolhidos, com a sombra comprida entrando na sala | — | Sem corte: meio segundo parado e ele se abaixa |
| **S7** Passa por baixo | 1,3–2,6 s | Sala 1x | O discípulo passa por baixo da porta com uma mão na borda. John sorri de leve | — | Sem corte: John começa a andar |
| **S8** "vamos ver sua guarda." | 2,6–4,6 s | Sala 1x | John sai do lugar dele, vai até (268,268) e aponta com a mão aberta o chão em frente ao saco. O discípulo vem andando | **John:** "vamos ver sua guarda." | O balão some sozinho. O discípulo chega ao lugar |
| **S9** Pega o par dele | 4,6–6,2 s | Sala 1x | O discípulo estica o braço, pega as luvas no saco, calça e arma a guarda. John observa de mãos nuas | — | A interface volta. O clique já vale |
| **S10** 1º clique | jogador no controle | Sala 1x, interface ligada | No primeiro soco do jogador, John senta no caixote e bate dois toques de punho. A porta desce sozinha | **John:** "isso." (balão passivo) | Fim. John fica sentado ali como mentor |

Fala do Osmar: nenhuma na proposta (ver decisão 4).

### Se pular
- **De S1 a S4:** vai direto para a tela de criação (S5), com as luvas já no saco. A tela não pode ser pulada.
- **De S6 a S9:** em 0,3 s fica o estado do S10: discípulo de guarda com a luva velha, John sentado no caixote, porta fechada, interface de volta.
- A reação do S10 continua armada mesmo pulando.
- O marco `cena_primeira_sucessao` é gravado no começo. Pular ou fechar o jogo não repete a cena.
- Como pular: segurar ESC ou ESPAÇO por 0,5 s, ou clicar em PULAR (`linguagem.md` §5).

### Arte por quadro
| # | Arte nova | Reaproveita da 6a |
|---|---|---|
| S1 | nada | `fighter_punch`, `bag_l0_hit`, `lamp` (quadro de balanço), `coach_idle`, parede da memória |
| S2 | John: pose `hold_bag` (3 quadros) | `bag_l0_idle`, `lamp` |
| S3 | John: `gloves_off` (o gesto ao contrário, 8 quadros) e `hang_gloves`. Objeto: par de luvas amarrado na argola | Poses-chave de `fighter_gesture` e o rosto `bite` |
| S4 | John sem luvas: `look_door`. Cenário: porta que sobe 3 px e sombra de pés (`door_gap_shadow`) | `coach_look` |
| S5 | Tela "receber novo discípulo" (UI/UX) | Dither de janela que o jogo já usa |
| S6 | Cenário: `garage_door` em 3 estados (fechada, 1/3, emperrada), luz do dia no chão (máscara em dither), sombra comprida. Discípulo: parado sem luvas, com paleta trocável | `garage_bg` |
| S7 | Discípulo: `duck_under`. John: rosto `smile` na pose sem luvas | rosto `smile` da 6a |
| S8 | John: `walk` sem luvas e `point_spot`. Discípulo: `walk` | balão e plaquinha `john`, voz `first` |
| S9 | Discípulo: `take_gloves` | `fighter_idle_disc` (guarda com a luva velha) |
| S10 | John: `sit_rest` (vira a pose parada de mentor) e `mentor_first_taps`. Objeto: caixote | balão passivo, `fighter_punch_disc` |

---

## Cena 2: Reencontro final (última arena, fase 11)
Gatilho: o jogador aperta LUTAR na última luta pela primeira vez na história da escola. Duração: 21,6 s. Não entra na 6b; está aqui porque a sucessão planta o que ela colhe.

### Quadros
| # | Tempo | Câmera | Quem e como | Fala | Passa para o próximo |
|---|---|---|---|---|---|
| **R1** Entrada exagerada? | 0,0–1,6 s | Tela inteira | Três holofotes varrem a porta, tambor, letreiro de apresentação. Não entra ninguém. O discípulo espera de guarda | — | Os holofotes apagam um a um, com 3 estalos |
| **R2** Sobra uma lâmpada | 1,6–3,0 s | A imagem fecha na janela 384x272 | Só a lâmpada acesa. O discípulo sozinho, à esquerda | — | Sem corte: meio segundo de silêncio |
| **R3** A porta emperra | 3,0–5,0 s | Janela 1x | Passos e couro raspando fora de quadro. A porta sobe e trava no mesmo ponto do quadro da garagem. Vemos John do ombro para baixo, luvas caídas | — | Corte seco para 2x |
| **R4** O fecho, sem rosto | 5,0–6,6 s | **2x**, região (327,123,192,136) | A luva sobe e some atrás da porta. Ouve-se o fecho | — | Mesmo plano |
| **R5** Dois toques | 6,6–8,2 s | 2x, mesmo plano | A luva desce e bate duas vezes na outra, com 2 faíscas. Depois, 0,6 s sem nada | — | Corte seco de volta ao 1x |
| **R6** Passa por baixo | 8,2–11,0 s | Janela 1x | Ele passa por baixo da porta com a mesma pose do discípulo na garagem, endireita o corpo e anda até a luz | — | Sem corte: ele para sob a lâmpada |
| **R7** O rosto e o nome | 11,0–13,6 s | Janela 1x | A luz pega o rosto, mais velho. Braços baixos. O nome aparece pequeno na faixa preta. **2,6 s sem fala e sem som novo** | — (só o nome "John Bullet") | O nome some quando o balão entra |
| **R8** "então vocês chegaram." | 13,6–17,6 s | Janela 1x | Ele fala. Depois baixa os olhos para o símbolo da escola no peito do discípulo, que brilha por 2 quadros | **John:** "então vocês chegaram." | Sem corte: ele levanta as luvas |
| **R9** "quero ver o que aprenderam." | 17,6–20,4 s | Janela 1x | Ele arma a guarda e sorri de leve | **John:** "quero ver o que aprenderam." | A janela abre para a tela inteira |
| **R10** Luta | 20,4–21,6 s | Tela inteira | Barras de vida com o retrato e o nome dele. Sino | — | Luta normal |

O discípulo não fala. A resposta dele é a luta.

### Se pular
- Em qualquer quadro: em 0,3 s fica o estado do R10 (John de guarda sob a lâmpada, porta meio aberta ao fundo, tela inteira, barras de vida), toca o sino e a luta começa.
- O marco `cena_reencontro_final` é gravado no começo. Depois dele, a prévia já mostra quem ele é.
- Nas tentativas seguintes toca a versão curta de 1,5 s: porta já emperrada, dois toques, guarda, sino.
- Pular não muda nenhum número da luta.

### Arte por quadro
| # | Arte nova | Reaproveita |
|---|---|---|
| R1 | Fundo da última arena (concreto, círculo de giz, porta de enrolar). 3 holofotes e letreiro (os mesmos das vinhetas da fase 10) | `fight_player_idle` do discípulo |
| R2 | Pilares e faixas pretas da janela. Símbolo da escola no peito do discípulo | sprite `lamp` da garagem, mesmo zumbido |
| R3 | `final_door` em 3 estados. John mais velho: parado de braços baixos | sons `door_roll` e `door_jam` da 6b |
| R4, R5 | `fight_player_gesture` com o corpo do John mais velho, na versão lenta (1,4 s) | Os mesmos 8 quadros e tempos do gesto da 6a |
| R6 | John mais velho: `duck_under` em vista de luta e `walk` | A pose-chave do `duck_under` da 6b |
| R7 | Retrato 32x32 do John mais velho e a silhueta para a prévia. Texto do nome | fonte 5x7 com minúsculas |
| R8 | John mais velho: `look_emblem`. Brilho do símbolo | balão, plaquinha `john`, voz `first` uma terça abaixo |
| R9 | John mais velho: guarda com rosto `smile` | rosto `smile` |
| R10 | nada | HUD normal da luta, `bell_start` |

---

## O que a prancha corrigiu nos storyboards
1. **As luvas penduradas não alcançavam.** Em (336,186) ficam acima da cabeça do discípulo. Na prancha o par fica amarrado na argola e cai no ombro esquerdo do saco, perto de (325,206) e (331,211), ao alcance do braço.
2. **O nome do John saía da janela.** "8 px abaixo dos pés" dá y 326 e a janela termina em y 323. O nome foi para a faixa preta de baixo (y 331), centrado nele.
3. **A porta emperra na altura do ombro, não do peito.** Assim a cabeça fica toda escondida e os dois toques aparecem inteiros. Garagem: borda em y 171. Arena: borda em y 194.
4. **A sombra de pés em 2 px não se lê.** A porta sobe 3 px quando treme e as sombras esticam 14 px no chão.
5. **Quem entra na garagem anda para a esquerda.** A prancha espelha as poses do discípulo. O Artista de Personagens decide se o espelho serve ou se desenha as poses viradas.
6. **O balão do John no ponto do mentor cobria a cabeça do Osmar.** Precisa da regra extra já proposta em `direcao-visual.md` §22.2 (o balão não cobre a cabeça de outro personagem).
7. **O R1 antigo foi dividido em dois** (holofotes e janela fechando), para o apagar das luzes ter tempo próprio. A duração total não mudou.

## Decisões que ficam com o dono
Cada uma tem a opção da prancha marcada como recomendada.

**1. Quando aparece a tela de criar o discípulo?**
- A. No meio da cena, depois que John olha a porta (prancha). *Recomendo:* é a sua ideia original e a pessoa que entra já é a que você criou.
- B. Antes da cena. A cena roda inteira, sem parar, mas perde o momento de "quem será que vem?".

**2. Como as luvas passam para o discípulo?**
- A. John pendura o par no saco e o discípulo pega sozinho (prancha). *Recomendo:* não vira despedida e funciona igual se a cena for pulada.
- B. John entrega as luvas na mão do discípulo. É mais emotivo, mas pede uma pose a mais de cada um e pesa para o lado da despedida.

**3. Que luz entra quando a porta sobe?**
- A. Dia claro, branco (prancha). *Recomendo:* contrasta com a lâmpada amarela e com o escuro de onde John vem no reencontro.
- B. Fim de tarde, dourado. Bonito, mas se mistura com a cor da lâmpada.
- C. Noite, com luz de poste. A cena fica mais triste do que deve.

**4. O Osmar participa da sucessão?**
- A. Está lá, calado, e só vira a cabeça para a porta (prancha). *Recomendo:* a cena é do John.
- B. Diz uma fala curta quando a sombra aparece na porta. Dá calor, mas soma uns 2 s.
- C. Fica fora de quadro.

**5. O corte de perto no gesto fica?**
- A. Nas duas cenas (prancha). *Recomendo:* é o que faz as duas conversarem.
- B. Só no reencontro. A garagem fica toda em plano aberto.
- C. Em nenhuma. O gesto tem poucos pixels de longe e o momento perde força.

**6. Como começa o reencontro?**
- A. Com uma falsa entrada exagerada: holofotes procuram, ninguém entra, tudo apaga (prancha). *Recomendo:* o silêncio só é sentido depois do barulho.
- B. Direto no silêncio, com a lâmpada. Mais curto, 1,6 s a menos.

**7. O nome dele aparece na tela?**
- A. Só "John Bullet", pequeno, na faixa preta (prancha). *Recomendo.*
- B. Sem nome na cena. Ele só aparece na barra de vida quando a luta começa.
- C. Nome e uma frase embaixo. Fica com cara de apresentação de adversário, que é o que esta cena evita.

**8. Quanto o John envelheceu?**
- A. Cabelo grisalho e barba por fazer, com o mesmo corpo e a mesma luva velha (prancha). *Recomendo:* reconhece-se pela silhueta.
- B. Bem mais velho: cabelo branco, mais pesado. Mais dramático, mas pode parecer outra pessoa.
- C. Quase igual, só a barba. Arrisca o jogador não perceber o tempo que passou.

## Pedidos por papel (depois do "sim" do dono)
| Papel | Pedido |
|---|---|
| **Artista de Personagens** | 6b: John `hold_bag`, `gloves_off`, `hang_gloves`, `look_door`, `walk` sem luvas, `point_spot`, `sit_rest`, `mentor_first_taps`; discípulo `duck_under`, `walk`, `take_gloves` e parado sem luvas, todas com paleta trocável. Fase 11: John mais velho (parado, `duck_under`, `walk`, `look_emblem`, guarda com `smile`, gesto lento, retrato e silhueta) |
| **Diretor de Arte** | 6b: `garage_door` em 3 estados, luz do dia no chão, sombra de pés, caixote e ponto do mentor (268,268), luvas amarradas na argola. Fase 11: fundo da última arena, `final_door`, janela na luta, brilho do símbolo |
| **Roteirista** | Polir `suc_guarda`, `suc_isso`, `fim_chegaram` e `fim_ver`, mantendo o verbo "ver" nas duas cenas |
| **Programador** | Player de cena por dados (`formato-dados.md`), com tela obrigatória no meio, estado final ao pular e reação armada. Sons `bag_catch`, `chain_creak`, `lamp_hum`, `strap_open`, `door_shake`, `door_roll`, `door_jam`, `tap_fist` |
| **UI/UX** | Tela "receber novo discípulo" por cima da garagem escurecida, botão PULAR, regra do balão que não cobre a cabeça de outro personagem. Tudo pela `alinhamento-ui` |
| **Diretor de Jogo / Designer** | Confirmar que o símbolo da escola vai na roupa dos discípulos a partir da 6b/6c: o R8 depende disso |

Fora da prancha: animação, sons, folhas completas e `data/cutscenes/`. A cena montada em dados vem quando o player existir.
