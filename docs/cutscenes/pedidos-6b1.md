# Pedidos da 6b1: o que falta para a cena da sucessão

Dono: Diretor de Cutscenes. Versão 1.1 (2026-11-14): `mentor_spot` em (254,252), caixote em (238,232) e porta 84x68, valores do Diretor de Arte.
Cenas: `data/cutscenes/primeira_sucessao.json` e `data/cutscenes/chegada_discipulo.json`. Storyboard: `primeira-sucessao.md` (v2). Formato: `formato-dados.md` (v1.1, §9).
Tudo em 1x na base 640x360, pixel inteiro. "Ponto na sala" = ponto dos pés (personagem) ou canto de cima à esquerda (cenário), em coordenadas de tela.
As cenas usam **nomes lógicos de animação** (coluna "Na cena"); o manifest liga cada nome ao sprite.

## 1. Artista de Personagens (skill `padrao-personagem`)

Regras para todas as folhas abaixo:
- Quadro **48x72, pivô (22,67)**, igual às folhas da garagem. Vista 3/4.
- A cena acontece sempre na garagem zerada: **só a luva velha**. Nenhuma folha precisa dos sufixos `_glove_l1..l4`.
- `head_anchor` no manifest para cada folha (o balão e a regra de "não cobrir cabeça" usam).
- Comprimento de braço e perna constante, pés de apoio fixos, luva girando com o antebraço.
- Luz da lâmpada aplicada para o ponto da coluna "Ponto na sala".

### 1.1 John (folhas próprias, sem camadas)

| Sprite | Na cena | Quadros | fps | Duração | Laço | Ponto na sala | O que é, quadro a quadro |
|---|---|---|---|---|---|---|---|
| `john_hold_bag` | `hold_bag` | 3 | 10 | 0,3 s e segura | não | (303,272), direita | **Com luvas.** 0 = braço do soco ainda esticado (igual ao quadro 2 do `fighter_punch`); 1 = a outra luva sobe para o saco; 2 = as duas luvas no saco, cabeça 2 px mais baixa. Marcar `catch_frame: 2` |
| `john_gloves_off` | `gloves_off` | 8 | 4 | 2,0 s | não | (303,272), direita | **O avesso do gesto.** Cada quadro é uma pose segurada 0,25 s. 0 = solta o saco, guarda baixa; 1 = luva da frente na boca, rosto `bite` (mesma pose-chave do quadro 1 do `fighter_gesture`); 2 = puxa o fecho, cabeça recua 1 px, fita esticada; 3 = prende a luva debaixo do outro braço e tira a mão: **1ª mão nua**; 4 = mão nua abre o fecho da outra luva; 5 = a 2ª luva sai; 6 = as duas luvas seguras pelo cadarço na mão da frente; 7 = amarra os cadarços, mãos juntas na altura do peito. Marcar `bite_frame: 1` |
| `john_hang_gloves` | `hang_gloves` | 8 | 8 | 1,0 s | não | (303,272), direita | 0 = baixa o par; 1 = balança o braço para cima, calcanhar sobe; 2 = **solta o par** em direção à argola (a partir daqui o par é o adereço `garage_hung_gloves_old`); 3 = braço desce; 4 = mãos nuas ao lado do corpo; 5 = olha a mão da frente aberta; 6 = fecha o punho; 7 = abre e relaxa. Marcar `release_frame: 2` |
| `john_look_door` | `look_door` | 4 | 10 | 0,3 s e segura | não | (303,272), direita | **Sem luvas**, braços soltos. 0 = olhando a mão; 1 = cabeça vira para a porta; 2 = olhando a porta, queixo um pouco erguido (**quadro parado atrás da tela de criação**); 3 = igual ao 2 com o rosto `smile` |
| `john_step_back` | `step_back` | 4 | 8 | laço | sim | de (303,272) a (254,252), **virado para a direita** | Passo de boxeador para trás, sem luvas, rosto `smile`. Anda 53 px em 1,1 s (48 px/s, cerca de 4 passos curtos). Substitui o "`walk` sem luvas" da prancha: ele recua sem dar as costas a quem chegou e não precisa de espelho. Marcar `step_frames: [1, 3]` |
| `john_point_spot` | `point_spot` | 3 | 10 | 0,3 s e segura | não | (254,252), direita | 0 = braço da frente começa a subir; 1 = antecipação; 2 = **mão aberta apontando o chão em frente ao saco** (mão em torno de (274,216)), rosto `smile`. Fica nessa pose enquanto fala (cerca de 2,2 s) |
| `john_sit_down` | `sit_down` | 4 | 10 | 0,4 s | não | (254,252), direita | 0 = baixa o braço; 1 = dobra os joelhos; 2 = quadril encosta no caixote; 3 = sentado (igual ao quadro 0 do `john_sit_rest`) |
| `john_sit_rest` | `sit_rest` | 4 | 3 | laço | sim | (254,252), direita | **A pose parada dele como mentor.** Sentado no caixote (assento a 17 px do chão), antebraços nos joelhos, mãos nuas, olhando o saco, rosto `smile` leve. Respiração de 1 px nos ombros. Rascunho na prancha: quadril (0,-18), cabeça (5,-43). `head_anchor` perto de (5,-51) |
| `mentor_first_taps` | `mentor_first_taps` | 4 | 9 | 0,44 s | não | (254,252), direita | **Sentado**, sem luvas: os dois toques de punho. 0 = punho de trás recua; 1 = **1º toque**; 2 = separa 2 px; 3 = **2º toque**. Mesmos tempos do `fighter_gesture_short`. Marcar `tap_frames: [1, 3]` e `tap_points`. Termina encaixando no quadro 0 do `john_sit_rest`. É a mesma folha que o jogo usa nos toques do mentor |

Notas:
- **Alcance:** a argola do saco fica em (335,186), acima do alcance da mão dele (pelas medidas da prancha, a mão chega perto de (327,204) na ponta do pé). Por isso o `hang_gloves` é um arremesso curto do par pelo cadarço. Confira no `personagem_lib.gd`; se o braço alcançar, pode virar "ergue e engancha", com os mesmos 8 quadros.
- O caixote **não** entra nas folhas: é adereço do Diretor de Arte, desenhado atrás dele (base em y 266).
- Reaproveita sem mudar: `fighter_idle`, `fighter_punch` (luva velha), rostos `bite` e `smile`.
- John não precisa de `walk` sem luvas na 6b1 (vai precisar na saída dele, 6c).

### 1.2 Discípulo (em camadas, com paleta trocável)

Todas pelo sistema de camadas do escopo §4.4 (corpo + cabeça, âncoras de cabeça e tronco por quadro, paleta de pele, cabelo e calção). Na 6b1 só existe o corte atual.

| Sprite | Na cena | Quadros | fps | Duração | Laço | Ponto na sala | O que é, quadro a quadro |
|---|---|---|---|---|---|---|---|
| `disciple_stand_bare` | `stand_bare` | 4 | 4 | laço | sim | (423,221), **esquerda**, atrás da porta | Parado, sem luvas, braços soltos, respiração de 1 px. Na cena só aparece do ombro para baixo (a porta cobre de y 171 para cima). É a base da pose de mentor da 6b2 |
| `disciple_duck_under` | `duck_under` | 7 | 10 | 0,7 s | não | de (423,221) a (410,236), esquerda | **Entrar por baixo da porta.** 0 = dobra os joelhos; 1 = tronco inclina, a mão de trás sobe para a borda; 2–3 = cabeça passa embaixo da borda (**topo da cabeça abaixo de y 171 na tela**), mão na borda perto de (431,172); 4 = solta a borda, passo à frente; 5 = endireita o tronco; 6 = de pé, encaixa no `walk_bare`. Marcar `step_frames: [3, 6]`. **É a pose que o John repete no reencontro**: silhueta clara e simples |
| `disciple_walk_bare` | `walk_bare` | 6 | 10 | laço | sim | de (410,236) a (303,272), esquerda | Andar sem luvas. Passada de 14 px (48 px/s na cena grande, 72 px/s na chegada curta). Marcar `step_frames: [1, 4]` |
| `disciple_take_gloves` | `take_gloves` | 8 | 10 | 0,8 s | não | (303,272), termina virado para a **direita** | **Pegar as luvas e armar a guarda.** 0 = vira o corpo para o saco; 1 = estica o braço da frente (mão em torno de (322,212)); 2 = **pega o par** (o adereço some neste quadro); 3 = par na altura do peito; 4 = calça a mão de trás; 5 = calça a mão da frente; 6 = aperta o fecho contra a outra luva, **sem dentes e sem toque**; 7 = guarda (igual ao quadro 0 do `fighter_idle`). Luva velha a partir do quadro 4. Marcar `grab_frame: 2` |

Notas:
- **Quem entra anda para a esquerda.** `stand_bare`, `duck_under` e `walk_bare` são usadas viradas para a esquerda. Você decide se o espelho serve (luz e detalhes do rosto) ou se desenha viradas. Na cena está `facing: "left"`; se desenhar viradas, avise para o manifest marcar a folha como `facing: "esquerda"`.
- A guarda final usa a folha parada do discípulo que já existe, agora em camadas.
- O validador reprova `gesture` e `mentor_first_taps` em discípulo: nenhuma destas folhas pode ter os dois toques.

## 2. Diretor de Arte

Ordem de desenho pedida ao Programador: fundo → camada `wall` → camada `floor` → sprites por y dos pés (`sorted`).

| Sprite | Tamanho do quadro | Quadros | fps | Ponto na sala (canto sup. esq.) | Camada | O que é |
|---|---|---|---|---|---|---|
| `garage_door` | 84x68, pivô (0,12) | 9 | 10 nas animações | (381,166) | `sorted`, `sort_y` 222 | **A porta em 3 estados** (fechada, 1/3, emperrada) com os quadros de passagem. Cada quadro desenha as lâminas até a borda de baixo, a barra (3 px, `st0`) e a linha `ink`; **abaixo da borda é transparente**. Borda (linha `ink`) em y: quadro 0 = fechada (igual ao fundo); 1 = **216** (fresta de 3 px); 2 = 209; 3 = 201; 4 = **193** (1/3); 5 = 185; 6 = 178; 7 = 172; 8 = **171** (emperrada, altura do ombro). A barra passa 1 px de cada lado do miolo (x 381..464) |
| `garage_door_outside` | 82x52 | 1 | 0 | (382,168) | `wall` | **O lado de fora**, visto pelo vão: luz do dia **branca** em cima, passando a `y2` em dither para baixo, calçada `cream` de 7 px na base (y 213..219). Cobre a porta pintada no `garage_bg`. Fica atrás de quem está na soleira |
| `garage_daylight` | 170x70 | 3 | 10 nas animações | (308,220) | `floor` | **Luz do dia no chão**: o próprio chão 1 passo mais claro na rampa, em trapézio que abre para a esquerda e para a frente, borda em dither de 5–7 px (sem transparência parcial). 0 = fresta (y 220..236); 1 = meio (y 220..262); 2 = cheia (y 220..289, de x 308 a 477 na base). Gerar a partir do `garage_bg`, para as marcas de giz continuarem lá |
| `garage_door_shadow` | 64x32 | 4 | 0 | (374,214) | `floor` | **Sombra de pés** e sombra comprida, em dither `-1` na rampa. 0 = dois pés contra a luz na fresta (2 blocos `d1` de 7x4 em x 412..418 e 425..431, y 216..219) com as sombras esticadas **14 px** no chão; 1 = sombra comprida de quem está na soleira, **34 px** a partir de (423,221), para a esquerda e para a frente; 2 = 30 px a partir de (414,228); 3 = 16 px a partir de (410,236) |
| `garage_crate` | 26x19 | 1 | 0 | (238,232), valor do Diretor de Arte | `sorted`, atrás do John sentado | **Caixote** de madeira (ripas `br0`/`br1`/`br2`, contorno `ink`), assento a 17 px do chão. Luz aplicada para o ponto. Fica na garagem para sempre a partir da cena. Tem que ser diferente das caixas de papelão da escola (não é clicável) |
| `garage_hung_gloves_old` | 20x34, pivô (17,1) na argola | 4 | 10 nas animações | pivô em (335,186) | `sorted`, `sort_y` 254 | **O par do John pendurado**: cadarço `cream` da argola até as luvas, luvas velhas (mesma arte do `glove_old`, 12x13) centradas perto de **(325,206) e (331,211)**, encostadas no ombro esquerdo do saco. 0 = chegando (par 4 px acima e à esquerda); 1 = balança para a esquerda; 2 = balança para a direita; 3 = parado |

Animações (mapa `anim` de cada sprite no manifest, com `fps` 10):
| Sprite | Nome | Quadros | Duração |
|---|---|---|---|
| `garage_door` | `closed` / `ajar` / `jammed` | [0] / [1] / [8] | parado |
| | `shake_ajar` | [0,1,0,1] | 0,4 s |
| | `open_jam` | [1,2,3,4,5,6,7,8] | 0,8 s |
| | `open_jam_fast` | [1,4,8] | 0,3 s |
| | `close` | [8,6,4,2,1,0] | 0,6 s |
| `garage_daylight` | `sliver` | [0] | parado |
| | `open` | [0,0,0,1,1,1,2,2] | 0,8 s |
| | `open_fast` | [0,1,2] | 0,3 s |
| | `close` | [2,1,1,0,0,0] | 0,6 s |
| `garage_hung_gloves_old` | `land` | [0,1,2,1,3] | 0,5 s |
| | `rest` | [3] | parado |

Pontos e conferências no manifest:
| Item | Valor | Observação |
|---|---|---|
| `mentor_spot` | (254,252) | ponto nomeado; as cenas usam o nome |
| Conflito a conferir | caixa da corda em `box_slots.jump_rope` (258,244) | com o ponto novo, John sentado ocupa mais ou menos x 241..271, y 202..252 e fica na frente de quase toda essa caixa (clique em x 242..274, y 217..246). Confirmar no mockup se a caixa da corda mudou de lugar junto; se não mudou, ela precisa mudar. A cena não muda |
| Mockup de conferência | quadros S4, S6, S7 e S10 | com as peças finais, mais um com a equipe cheia e as 4 caixas (escopo §4.5) |
| Balão do John no `mentor_spot` | cabeça do Osmar em (197,173) | a regra "não cobre cabeça" (§22.2) empurra o balão para a direita; conferir com UI/UX nos dois casos: de pé (S8) e sentado (S10) |

Se a arte apertar (ordem de corte do escopo §7): a luz do dia vira só a fresta (`garage_daylight` com 1 quadro) e a `garage_door_shadow` fica só com o quadro 0.

## 3. Sons novos (Programador, no gerador `tools/sfx/make_sfx.gd`; som 100% sintetizado)

| Id | Duração | Como soa | Quando toca | Volume |
|---|---|---|---|---|
| `bag_catch` | 0,25 s | baque abafado de couro, grave, sem estalo: duas mãos parando o saco | S2, em 1,92 s | igual ao `punch_1` |
| `chain_creak` | laço de 0,9 s | rangido de corrente, metálico e irregular | S1, do 1º soco até ele segurar o saco; some em 0,15 s | 0,6 |
| `lamp_hum` | laço de 1,0 s, sem emenda audível | zumbido elétrico baixo (cerca de 100 Hz com um harmônico) | do S2 até 0,5 s depois de o controle voltar | 0,5; tem que sumir embaixo de qualquer outro som |
| `strap_open` | 0,35 s | o `strap_rip` ao contrário: fecho abrindo devagar, mais longo e mais grave | S3, em 3,87 s | igual ao `strap_rip` |
| `glove_leather` | 0,3 s | couro deslizando, ruído filtrado curto | S3 (2 vezes), S9 e chegada curta | 0,8 |
| `ring_clink` | 0,15 s | um tilintar de argola, agudo e seco | S3, em 5,97 s | 0,6 |
| `door_shake` | 0,4 s | chapa de aço tremendo: 2 batidas rápidas com chocalho | S4, em 6,62 s; começo da chegada curta | 0,9 |
| `door_roll` | 0,8 s | porta de enrolar subindo: chocalho metálico contínuo que sobe de tom | S6; a descida depois do controle usa o mesmo, a 0,8 | 1,0 |
| `door_jam` | 0,2 s | tranco seco de metal travando, com um resto de vibração | S6, em 0,70 s da parte 2; fim da descida, a 0,7 | 1,0 |
| `strap_close` | 0,12 s | fecho colando, um toque curto de velcro. **Não pode parecer o `strap_rip`**, que é do John | S9, quando o discípulo aperta a luva | 0,7 |
| `tap_fist` | 0,075 s | o `tap_glove` mais seco e mais agudo: osso em osso, sem couro | S10 e toques do mentor; 2 vezes com **0,22 s** de intervalo, por temporizador | igual ao `tap_glove` |

- `door_shake`, `door_roll` e `door_jam` voltam iguais no reencontro final (fase 11): o ouvido tem que reconhecer.
- Extras meus, fora da lista do escopo: `glove_leather`, `ring_clink` e `strap_close`. Se precisar cortar, saem nessa ordem (as cenas continuam funcionando sem eles).
- Reaproveitados: `punch_1`, `punch_2`, `hit_heavy`, `step_1`, `step_2`.
- Gerar depois dos sons antigos (o ruído tem semente fixa, regra da 6a).

## 4. Programador (player de cena)
- Os 15 acréscimos de `formato-dados.md` §9. Os que mais pesam: `open_screen.state` e começar do checkpoint (#10 e #11), objeto da sala como adereço (#5), camada `sorted` com `sort_y` (#6) e `pose.frames` (#8).
- Com a cena ativa, os comentários do Osmar e os gestos automáticos da sala não tocam.
- Se uma janela, luta ou troca de local chegar antes do 1º clique, a reação é descartada e a sala fica no `end_state`.
- Manifest: ligar os nomes lógicos (`hold_bag`, `gloves_off`, `hang_gloves`, `look_door`, `step_back`, `point_spot`, `sit_down`, `sit_rest`, `mentor_first_taps`, `stand_bare`, `duck_under`, `walk_bare`, `take_gloves`) aos sprites por personagem.

## 5. UI/UX
- Balão em modo de cena com John em (254,252) de pé e balão passivo com ele sentado, os dois sem cobrir a cabeça do Osmar: entram no `ui_audit`.
- A tela de criação abre sobre o estado do S5. As luvas no saco e a fresta de luz ficam à direita do centro: vale conferir o que sobra visível em volta da janela.

## 6. Pendente comigo
- Conferir as duas cenas nas capturas quando o player e as folhas existirem, e ajustar tempos só nos arquivos de dados.
- `reencontro_final.json` como rascunho validável (escopo §7): ainda não escrevi. Ele cita sprites da fase 11 que não existem, então reprovaria o critério 20 ("validador sem erro em todo `data/cutscenes/`"). Preciso que o Programador diga onde rascunho pode morar (pasta `_rascunhos/` ou campo `draft: true`).
