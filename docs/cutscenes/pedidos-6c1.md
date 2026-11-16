# Pedidos da 6c1: o que falta para a chegada à academia e a saída do John

Dono: Diretor de Cutscenes. Versão 1 (2026-11-15).
Cenas: `data/cutscenes/primeira_academia.json` e `data/cutscenes/saida_primeiro_mentor.json`. Prancha: `prancha-6c1.md`. Formato: `formato-dados.md` (v1.2, §9 itens 16 a 24). Regras de jogo: `docs/fases/fase6c1-design.md`.
Tudo em 1x na base 640x360, pixel inteiro. "Ponto na sala" = ponto dos pés (personagem) ou canto de cima à esquerda (cenário), em coordenadas de tela.
As cenas usam **nomes lógicos de animação** (coluna "Na cena"); o manifest liga cada nome ao sprite (`scene_anims.<personagem>.<nome>`).

## 1. Artista de Personagens (skill `padrao-personagem`)

Regras para todas as folhas:
- Quadro **48x72, pivô (22,67)**, vista 3/4, como as folhas da garagem. As folhas com carga grande (saco, esteira) podem usar quadro maior; nesse caso informe o pivô no manifest.
- **Sem luvas** em todas (mãos nuas). `head_anchor` no manifest para cada folha.
- Luz da academia: tubos frios, sem a luz da lâmpada pintada. As folhas do John usadas na garagem (saída pela reserva) seguem a regra das folhas dele da 6b1.
- Nenhuma folha nova pode ter dois toques ritmados (punho, prego, cabeça): isso é só do gesto do John.

### 1.1 Osmar (chegada)
| Na cena | Quadros | fps | Duração | Laço | Ponto na sala | O que é |
|---|---|---|---|---|---|---|
| `hold_photo` | 4 | 4 | laço | sim | (196,236), direita | Parado, a moldura nas duas mãos na altura do peito, olhando a parede à frente. Respiração de 1 px |
| `hang_photo` | 8 | 8 | 1,0 s | não | (196,236), direita | 0–2 = ergue a moldura até a parede (mãos perto de (221,168)); 3 = encosta; 4 = **bate o prego com a palma, uma vez** (`knock_frame: 4`); 5 = solta a moldura (**a foto vira adereço neste quadro**, `release_frame: 5`); 6–7 = baixa os braços |
| `step_back` | 4 | 8 | laço | sim | de (196,236) a (188,240), **virado para a direita** | Passo curto para trás sem dar as costas à foto. A cena usa a mesma folha para voltar os 8 px |
| `look_photo` | 3 | 10 | 0,3 s e segura | não | (188,240), direita | 0 = braços soltos; 1 = mão no queixo; 2 = **cabeça inclinada**, olhando a foto. Segura 0,9 s |
| `nudge_photo` | 4 | 10 | 0,4 s | não | (196,236), direita | 0 = braço da frente sobe; 1 = dedo no canto de baixo da moldura (perto de (229,177)); 2 = **empurra** (a foto entorta neste quadro, `nudge_frame: 2`); 3 = recolhe o braço, satisfeito |

Reaproveita sem mudar: `coach_idle`, `coach_talk` (fala "agora sim." e responde na saída). **Conferir:** as folhas atuais do Osmar têm a luz da lâmpada da garagem pintada; para ele ficar parado na academia é preciso a versão com a luz dos tubos (o escopo já pede "parado na academia").

### 1.2 Lutador da campanha (chegada): John **e** discípulo em camadas
| Na cena | Quadros | fps | Duração | Laço | Ponto na sala | O que é |
|---|---|---|---|---|---|---|
| `carry_bag` | 6 | 10 | laço | sim | da porta (428,224) a (352,262) e depois a (303,272), **esquerda** | Andar com o saco remendado deitado no ombro de trás, uma mão segurando por cima. O saco fica **atrás da cabeça** (a cabeça aparece inteira). Passada de 14 px a 48 px/s. `step_frames: [1, 4]` |
| `carry_bag_idle` | 2 | 3 | laço | sim | (352,262), esquerda | Parado com o saco no ombro, cabeça virada para o Osmar. Ajeita o peso 1 px |
| `hang_bag` | 8 | 10 | 0,8 s | não | (303,272), termina virado para a **direita** | 0–1 = vira para o gancho e tira o saco do ombro; 2–3 = ergue o saco com os dois braços; 4 = **engancha** (o saco vira o objeto da sala neste quadro, `release_frame: 4`); 5–6 = solta e baixa os braços; 7 = encaixa na pose parada dele |

O saco carregado é sempre o **saco remendado** (o `bag_l0`), qualquer que seja o nível comprado: é o saco da garagem. A troca para o saco do nível atual acontece no quadro do gancho, com a poeira.

### 1.3 Quem traz o caixote (chegada): John, discípulo em camadas e vizinho
| Na cena | Quadros | fps | Duração | Laço | Ponto na sala | O que é |
|---|---|---|---|---|---|---|
| `carry_crate` | 6 | 10 | laço | sim | da porta (428,224) a (254,252), **esquerda** | Andar com o caixote nos dois braços, à frente do peito, tronco um pouco para trás. `step_frames: [1, 4]` |
| `put_crate` | 3 | 10 | 0,3 s | não | (254,252), termina virado para a **direita** | 0 = gira o corpo; 1 = dobra os joelhos e pousa o caixote atrás de si; 2 = solta (**o caixote vira adereço neste quadro**) |
| `sit_down`, `sit_rest` | 4 / 4 | 10 / 3 | 0,4 s / laço | não / sim | (254,252), direita | John: já existem. **Discípulo em camadas:** novas, com todas as camadas e paletas do `look` (é a pose de mentor sentado que o escopo já pede). Vizinho: ver o corte abaixo |

Corte possível: o vizinho (`helper_2`, Carreira 1) não senta. Ele pousa o caixote e fica em pé ao lado (`stand`). Nesse caso me avise: eu troco os dois passos dele na cena por um.

### 1.4 Vizinho com a esteira (chegada)
A esteira velha faz parte das folhas dele (quadro largo). Um vizinho da equipe, com a roupa do `neighbor_1`; o `helper_2` é a mesma folha com outra paleta (design §1.4).
| Na cena | Quadros | fps | Duração | Laço | Ponto na sala | O que é |
|---|---|---|---|---|---|---|
| `treadmill_bump` | 6 | 10 | 0,6 s | não | (430,222), esquerda, na soleira | Esteira **atravessada** (86 px de largura para um vão de 48). 0–2 = avança; 3 = **bate nos dois batentes** (`bump_frame: 3`, em 0,4 s com o som); 4–5 = recua 3 px |
| `treadmill_stuck` | 4 | 4 | laço | sim | (430,222) | Parado atrás da esteira, olha um batente, olha o outro. Quase sem movimento: é o que fica durante o plano 2x (fora do recorte) |
| `treadmill_turn` | 4 | 10 | 0,4 s | não | (430,222) | Gira a esteira para **de lado** (em pé, estreita) |
| `treadmill_carry` | 6 | 10 | laço | sim | de (430,222) a (440,250), esquerda | Passa pela porta com a esteira de lado |
| `treadmill_put` | 3 | 10 | 0,3 s | não | (440,250) | Deita a esteira no lugar dela (pivô 445,267). **A esteira vira adereço no último quadro** |
| `stand` | 4 | 4 | laço | sim | (440,250) | Parado, mãos na cintura, respirando |

### 1.5 John (saída)
| Na cena | Quadros | fps | Duração | Laço | Ponto na sala | O que é |
|---|---|---|---|---|---|---|
| `stand_up` | 4 | 10 | 0,4 s | não | ponto de sentar, direita | Levanta do caixote. Pode ser o `john_sit_down` de trás para frente |
| `pick_duffel` | 6 | 10 | 0,6 s e segura 0,4 | não | ponto de sentar, direita | 0–1 = vira e dobra o tronco; 2–3 = pega a alça da bolsa atrás do caixote (o adereço some em 0,5 s, `grab_frame: 4`); 4–5 = bolsa no ombro de trás |
| `walk_duffel` | 6 | 10 | laço | sim | de (254,252) a (380,246) e até a porta, **direita** | Andar sem luvas com a bolsa no ombro de trás. 48 px/s. `step_frames: [1, 4]`. É o "`walk` sem luvas" que a 6b1 deixou para a 6c |
| `look_room` | 3 | 10 | 0,3 s e segura | não | (380,246), **esquerda** | 0 = vira o corpo; 1 = cabeça percorre a sala; 2 = parado olhando a sala, rosto `smile` leve. Fica nesta pose durante as falas (cerca de 6,5 s) |
| `nod` | 4 | 10 | 0,4 s | não | (380,246), esquerda | **Um** aceno de cabeça: desce 2 px, volta. Sem mexer os punhos |
| `duck_out` | 7 | 10 | 0,7 s | não | de (410,236) a (423,221), direita, só na garagem | Passar por baixo da porta de enrolar **saindo**, com a bolsa. Mesma silhueta do `disciple_duck_under`, sem mão na borda (a mão segura a alça) |

`look_room` e `nod` são usadas viradas para a esquerda: você decide se o espelho serve ou se desenha viradas (como na 6b1).

### 1.6 Último que passou o posto (saída e chegada)
Só `sit_down` e `sit_rest` em camadas (§1.3). Andar e ficar em pé já existem (`disciple_walk_bare`, `disciple_stand_bare`).

### Ordem de corte, se a arte apertar
1. `treadmill_stuck` vira o último quadro do `treadmill_bump` parado.
2. `carry_bag_idle` vira o quadro 0 do `carry_bag` parado.
3. `stand_up` = `sit_down` invertido.
4. O vizinho do caixote não senta.
Não se corta: as 5 folhas do Osmar, `hang_bag`, `walk_duffel`, `look_room`, `nod`.

## 2. Diretor de Arte

| Sprite | Tamanho | Quadros | Ponto na sala | Camada | O que é |
|---|---|---|---|---|---|
| `gym_half_dark` | 384x272 | 1 | (128,18) | `floor` | **Metade direita da academia 1 passo mais escura** (tubo apagado): o próprio `gym_bg` escurecido de x 340 em diante, com borda em dither de x 300 a 340. Sem transparência parcial. Não cobre gente (fica abaixo dos personagens) |
| `gym_door` | cobre a porta pintada no `gym_bg` (miolo x 404..451, y 120..219) | 3 | (401,117) | `wall` | **Porta da rua**: 0 = fechada (igual ao fundo); 1 = meio aberta; 2 = aberta para dentro, folha de perfil à direita e **a rua clara no vão** (luz do dia branca, calçada `cream`), a mesma rua da `garage_door_outside`. Animações: `closed` [0], `open` [0,1,2], `close` [2,1,0], fps 10 |
| `gym_daylight` | livre | 1 | perto de (330,221) | `floor` | Luz do dia no piso de borracha, em trapézio que abre para a esquerda e para a frente, borda em dither. Gerada do `gym_bg` |
| `wall_photo_old_gym` | 18x21 (como a `wall_photo_old`) | 2 | `gym_photo_spot`, proposto (212,158) | `wall` | **A foto antiga na academia**: 0 = **reta** (só existe por 2 s na cena); 1 = **torta**, igual à da garagem. Animações: `straight` [0], `tilt` [0,1], `crooked` [1]. O quadro 1 é o que o jogo desenha depois (design §2) |
| `john_duffel` | cerca de 18x11 | 1 | (268,242), atrás do caixote | `sorted`, `sort_y` 251 | Bolsa de lona do John, no chão. Só aparece no 1º quadro da saída. **Nunca fica na sala depois** |
| `garage_crate` na academia | o mesmo | 1 | (238,232) | `sorted`, `sort_y` 250 | O caixote com a luz dos tubos, se a diferença aparecer |
| "esteira velha" e "saco remendado" | — | — | — | — | Não são sprites soltos: vão dentro das folhas de quem carrega (§1.2 e §1.4). Para o Artista de Personagens: a esteira é a `treadmill_l0` da garagem e o saco é o `bag_l0` |

Pontos novos no manifest (`layout`), com as regras de folga do design §4.3:
| Ponto | Proposta | Observação |
|---|---|---|
| `gym_coach_spot` | (196,236), o mesmo da garagem | Em frente ao banco pintado. A foto fica à direita da cabeça dele (197,173) |
| `gym_mentor_spot` | (254,252), o mesmo da garagem, com o caixote em (238,232) | Com o saco de lado (258,160) o saco passa atrás da cabeça dele, como na garagem |
| `gym_mentor_2_spot` | (150,262), o mesmo da garagem | Sobre o tatame. O caminho até o caixote (104 px) não cruza a faixa do alvo |
| `gym_photo_spot` | (212,158) | No barrado verde, acima do banco, entre a toalha e a mochila pintadas. Fora do saco de lado (x 238..278) e da corrente. O `neighbor_2` (220,258) de braços erguidos chega a y 185: não cobre |

Mockup de conferência pedido: a sala cheia (Osmar, John sentado, último em pé, equipe máxima, 4 caixas, foto) e os quadros A1, A3, A6 e A7 com as peças finais. A prancha (`prancha_6c1_saida.png`, quadro J1) já mostra a sala cheia com as minhas propostas: o lado esquerdo fica apertado (2º mentor, 2 vizinhos, Osmar e John em 130 px).

## 3. Sons novos (Programador, no gerador `tools/sfx/make_sfx.gd`; som 100% sintetizado)
As cenas já tocam com **dublês que existem** (para o validador passar). Quando o som próprio existir, eu troco o `id` no passo marcado com `_som_final`.
| Id | Duração | Como soa | Quando toca | Dublê hoje |
|---|---|---|---|---|
| `gym_door_open` / `gym_door_close` | 0,3 s | porta de madeira com mola: rangido curto e batida macia | A1, A8; J6 | `door_shake` |
| `metal_bump` | 0,25 s | ferro oco batendo em madeira, com chocalho de correia | A3, duas vezes (3,4 s e 4,7 s), a segunda mais fraca | `door_jam` |
| `crate_down` | 0,15 s | madeira pousando no piso de borracha | A3 (5,25 s) | `block` |
| `nail_knock` | 0,1 s | uma batida seca de palma em madeira. **Uma só** | A4 (6,3 s) | `block` |
| `frame_scrape` | 0,25 s | moldura raspando na parede | A4 (6,5 s) e A6 (8,7 s) | `glove_leather` |
| `tube_start` | 0,5 s | reator de lâmpada: estalos irregulares e zumbido subindo. Não pode soar como dois toques ritmados | A7 (10,4 s) | `ring_clink` |

Reaproveitados: `lamp_hum` (zumbido do tubo, a 0,4), `ring_clink`, `bag_catch`, `glove_leather`, `door_roll`, `door_jam`, `step_1`, `step_2`. Ordem de corte dos novos: `crate_down`, `frame_scrape`, `tube_start`.

## 4. Programador (player de cena, validador e jogo)
- Os acréscimos de `formato-dados.md` §9, itens 16 a 24. Os que mais pesam: elenco por papel com `fallback` e `optional` (16), cena sem controle preso (19), condição e pontos por local (22), gatilho `mentor_leave_due` (23).
- `data/cena_player.json`: evento `mentor_leave_due`, personagem `helper_2`, objeto da sala `treadmill`, `hide` novos.
- Validador: aceitar `if.location`; em cena `blocking: false`, reprovar `ui`, `camera`, `shake`, `open_screen` e `say` que não seja passivo; `actors.<id>.pos` e `stage.location: "any"` como descrito.
- **`tests/test_fase6b1.gd` (linha 166)** confere que `data/cutscenes/` tem exatamente `chegada_discipulo` e `primeira_sucessao`. Com as duas cenas novas esse teste fica vermelho até ser atualizado.
- Estado de hoje no validador: `primeira_academia` 0 erros, 26 pendências (arte e pontos), 13,85 s provisórios. `saida_primeiro_mentor` 3 erros esperados (evento novo e duas condições `if`).
- Fim da chegada: `return_control` chama `cena_sala_terminou()`, que abre a escolha da arte se pendente (design §1.2).
- Captura das duas cenas a cada 0,5 s e do estado pulado, com save de teste, nos 3 elencos da chegada e nos 2 locais da saída, para eu conferir.
- Manifest: ligar os nomes lógicos novos aos sprites (`scene_anims`), inclusive para `mentor:seat` e `mentor:last`.

## 5. Designer de Jogo
- **Caixote na academia.** A cena traz o caixote na mudança e ele fica. Peço `seat_prop.gym = mentor_crate` (ou o id que o Programador der) com `requires_milestone: cena_primeira_academia`, no lugar de `gym_mentor_bench` desde a 1ª sucessão. Assim o caixote existe na academia também na Carreira 1, depois da cena.
- **Chegada sem esteira comprada** (item 6).
- A saída termina com o `saida_terminou()` do design: na cena, o fim é o último passo do último mentor sentando, ou a interrupção.

## 6. Diretor de Jogo
- **Sem esteira comprada na chegada:** o ajudante da esteira não entra e a cena perde só a piada do fundo. Recomendo assim; a alternativa custa uma folha a mais.
- **Caixote no lugar do banco** (item 5): muda um detalhe do design §4.1.

## 7. UI/UX (skill `alinhamento-ui`)
- Balão de cena do Osmar no plano 2x (A6): cabeça dele perto de (266,124) na tela; o balão não pode cobrir a foto, que fica à direita (x 296..331, y 98..139 na tela).
- Balões passivos do John parado em (380,246): cabeça em (378,176). Ficam à direita do alvo e não cobrem a cabeça do `uncle_2` (398,230) nem a plataforma da pera na parede. Dois estados: 1 linha de 22 caracteres, nas duas falas.
- Balão passivo do Osmar na academia (`saida_resposta`), com o John em pé e o último mentor em pé na sala.
- Botão PULAR e chip na chegada. Na saída **não aparecem**.
- Estados para o `ui_audit`: A6, J4 (as duas falas), J5, na academia e na garagem.

## 8. Roteirista
- Chaves usadas, sem mudança: `aca_agora_sim`, `saida_rumo_1`, `saida_rumo_2`, `saida_resposta`. Fiquei com os **dois balões** de uma linha para a fala do John.
- Nenhuma chave nova pedida. A dica da foto (`objects.old_photo_gym`) combina com a cena: a foto termina torta de propósito.

## 9. Pendente comigo
- Trocar os sons dublês pelos próprios e acertar os tempos quando as folhas existirem (o tempo preso tem que ficar em 12,9 s, com teto de 15 s).
- Conferir as duas cenas nas capturas, nos 3 elencos e nos 2 locais.
- Atualizar as três posições inteiras da chegada se o Diretor de Arte mudar os pontos `gym_*`.
