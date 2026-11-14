# Cena: Primeira sucessão (animatic por escrito)

Dono: Diretor de Cutscenes. Versão 1 (2026-11-11). Fase 6b. Cena única.
> **Nomes (decisão do dono, 2026-11-13):** `primeiro` = **John Bullet** (plaquinha `john`, voz `first`); `treinador` = **Osmar Brandão** (plaquinha `osmar`, voz `coach`); escola = **Raízes Fight Club**; humilhação A, "a ficha em branco". Nas tabelas abaixo, `primeiro` é o John e `treinador` é o Osmar.
Função (direção narrativa §9): mostrar a passagem de responsabilidade e apresentar o novo discípulo. **Sem despedida triste:** é a descoberta de que o anterior continua conosco.
Par visual: `reencontro-final.md` (ver "Como as duas cenas conversam", no fim).
Linguagem: `linguagem.md`. Gesto: `gesto-assinatura.md` (opção A). Falas são rascunho para o Roteirista.

## Gatilho
- **Evento:** o jogador aperta "receber novo discípulo" depois do fim da Carreira 1 (derrota ou saída), já passada a tela de fim e a árvore. A cena toca **na garagem da nova campanha** (já zerada: só o saco, sem corda, esteira nem equipe).
- **Marco:** `cena_primeira_sucessao`, gravado no começo da cena.
- **Funciona com 1ª carreira curta:** não depende de vitória, cinturão, compra nem tempo de jogo.
- **Save antigo** (já com várias carreiras quando a 6b chegar): toca no próximo fim de campanha, com o 1º lutador no lugar de quem treina. Nenhuma fala diz "segundo" ou "primeiro" discípulo.
- **Sucessões seguintes:** não repetem esta cena. Só a tela de criar o discípulo e uma chegada curta (porta sobe, discípulo passa por baixo, 2 s, sem fala).

## Palco
Garagem, janela de cena = a própria sala (128,18,384,272). Coordenadas de tela na base 640x360; personagens pelo ponto dos pés.

| Elemento | Posição | Observação |
|---|---|---|
| Saco (`bag_l0_idle`) | centro (336,183) | o único aparelho |
| Lâmpada (`lamp`) | onde já está | única luz; zumbido baixo |
| Porta de enrolar | x 382..464, base y 220 | fresta de luz do dia embaixo (já existe no fundo) |
| `primeiro` | (303,272), virado para a direita | começa socando, com a luva velha |
| `discipulo` | fora, atrás da porta, em (423,221) | só aparece na parte 2 |
| Ponto do mentor | **(268,266)**, a confirmar pelo Diretor de Arte | caixote para sentar |
| `treinador` | no ponto que a 6a der a ele | não fala; só acompanha com a cabeça |

## Parte 1 — antes de criar o discípulo (≈ 9 s)

| # | Tempo | Plano | O que acontece | Pose / animação | Som |
|---|---|---|---|---|---|
| 1 | 0,0–1,8 | sala 1x | A interface apaga. `primeiro` solta os três últimos socos no saco. O saco balança forte. | `fighter_punch` x3 (0,33 s cada, 0,2 s entre eles); `bag_l0_hit` | `punch_1`, `punch_2`, `hit_heavy`; corrente rangendo |
| 2 | 1,8–3,6 | sala 1x | Ele **segura o saco com as duas luvas** e o saco para. O rangido para junto. Fica um silêncio com o zumbido da lâmpada. Ele respira. | nova `hold_bag` (3 quadros, segura 1,5 s); saco travado no quadro parado; rosto `tired` | `bag_catch`; `chain_creak` some; `lamp_hum` |
| 3 | 3,6–6,6 | **corte para 2x**, região (222,154,192,136) | Ele leva a luva esquerda à boca, **abre o fecho com os dentes** e tira as duas luvas. Pendura o par na argola do saco. Abre e fecha a mão nua uma vez. | nova `gloves_off` (8 quadros, 2,0 s: mesma pose-chave do gesto, ao contrário); nova `hang_gloves` (0,6 s); mão abre e fecha (0,4 s) | `strap_open`; couro saindo; argola tilinta |
| 4 | 6,6–9,0 | **corte para 1x** | Na fresta de luz embaixo da porta aparece a **sombra de dois pés**. A porta treme uma vez. Ele vira a cabeça para a entrada e fica olhando. | adereço `door_gap_shadow`; porta treme 1 px; nova `look_door` (segura 1,2 s) | `door_shake` (chapa) |

**Passagem para a tela "Receber novo discípulo"** (personalização): a sala escurece com o dither de janela que o jogo já usa; `primeiro` continua olhando a porta por trás da janela. A cena fica parada aqui até o jogador confirmar.

Luvas penduradas: `art_hung_glove_old` em (336,186), pontas até y ≈ 197.

## Parte 2 — o discípulo entra (≈ 6 s)

| # | Tempo | Plano | O que acontece | Pose / animação | Som |
|---|---|---|---|---|---|
| 5 | 0,0–2,6 | sala 1x | A porta sobe e **emperra na altura do peito**. Luz do dia no chão. Vemos o discípulo **do peito para baixo** (calção e pele já são os escolhidos). Meio segundo parado. Ele **passa por baixo da porta**, endireita o corpo e para em (392,258). `primeiro` sorri de leve. | adereço `garage_door` (fechada → 1/3 → emperrada, 0,8 s) + luz no chão; discípulo: nova `duck_under` (0,7 s) de (423,221) a (410,236), depois `walk` até (392,258); `primeiro`: rosto `smile` | `door_roll`, `door_jam` (tranco, tremida de 1 px); `step_1`, `step_2` |
| 6 | 2,6–4,6 | sala 1x | `primeiro` **se afasta do saco**: anda até (268,268), vira para a direita e aponta com a mão aberta o lugar em frente ao saco. Fala. Enquanto isso o discípulo anda até (303,272). | `primeiro`: nova `walk` sem luvas (0,7 s) + nova `point_spot` (segura); discípulo: `walk` (1,9 s) | passos; voz `primeiro` |
| | | | **`primeiro`:** "Vamos ver sua guarda." | balão de cena, 21 caracteres | blip |
| 7 | 4,6–6,2 | sala 1x | O discípulo estica o braço, **pega as luvas** na argola, calça e arma a guarda. A interface volta. | nova `take_gloves` (0,8 s) → `fighter_idle` com a luva velha; somem as luvas penduradas | couro; `strap_rip` curto (sem os dois toques: o gesto é só do `primeiro`) |

**Controle devolvido aos 6,2 s.** Tempo preso total: ≈ 15 s (9 + 6), fora a tela de criação.

## Depois do controle (sem prender o jogador)

| Quando | O que acontece |
|---|---|
| Logo ao devolver | A porta destrava e desce sozinha com um tranco (`door_roll` ao contrário). |
| **No primeiro clique** do jogador | `primeiro` acena com a cabeça e bate **dois toques de punho** (`mentor_first_taps`, sem luvas). Balão passivo: **"Isso."** |
| 1,5 s depois do primeiro clique (ou 6 s sem clique) | Ele anda até o ponto do mentor e **senta no caixote** (nova `sit_rest`): é a primeira vez que o vemos descansar enquanto outro treina. Esta pose vira a pose parada dele como mentor. |

## Variação
- Se a Carreira 1 terminou em **derrota**: `primeiro` usa um esparadrapo na sobrancelha (o mesmo X da marca de revanche), 2 px. Nenhuma fala muda. Opcional; se custar caro, sai.

## Se pular
- **Na parte 1:** vai direto para a tela de criar o discípulo. As luvas já aparecem penduradas no saco.
- **Na parte 2:** em 0,3 s o discípulo está em (303,272) de guarda com a luva velha, `primeiro` está **sentado** no ponto do mentor, a porta fechada, a interface de volta.
- A reação do primeiro clique continua armada mesmo pulando (ele reage sentado: aceno + dois toques).
- O marco e o mentor na sala já estavam gravados desde o começo.

## O que fica no cenário
- **`primeiro` sentado no caixote**, no ponto do mentor, até o afastamento (6c). O caixote fica mesmo depois, para os mentores seguintes.
- **A luva velha é o par dele.** Todo discípulo começa com a luva velha: é o mesmo par passado adiante. Não é mecânica nova, só o sentido de uma regra que já existe.
- A porta de enrolar que emperra na altura do peito passa a ser "coisa da casa": toda chegada de discípulo novo usa.

## Rascunho de falas (para o Roteirista)
| id | Quem | Rascunho | Intenção |
|---|---|---|---|
| `suc_guarda` | `primeiro` | "vamos ver sua guarda." (polida pelo Roteirista) | Convite, não ordem. Manter o verbo **ver** (ecoa no reencontro). |
| `suc_isso` | `primeiro` | "isso." | Aprovação mínima no 1º clique. Pode ficar sem texto. |

## Como as duas cenas conversam

| | Primeira sucessão (garagem) | Reencontro final (última arena) |
|---|---|---|
| **Janela** | a sala, 384x272 | a mesma janela 384x272, dentro da arena |
| **Luz** | uma lâmpada quente, cantos escuros | a mesma lâmpada, o resto apagado |
| **Porta** | porta de enrolar à direita (x 382..464), sobe e **emperra no peito** | porta de enrolar no mesmo lugar do quadro, sobe e emperra no peito |
| **Quem chega** | o discípulo, visto do peito para baixo, **passa por baixo** | `primeiro`, visto do peito para baixo, passa por baixo **com a mesma pose** |
| **Quem espera** | `primeiro`, à esquerda, virado para a direita | o discípulo, à esquerda, virado para a direita: no lugar que era dele |
| **Gesto** | **abre** o fecho com os dentes e tira as luvas | **aperta** o fecho com os dentes e bate dois toques |
| **Plano 2x** | um corte, no gesto | um corte, no gesto, com as mãos na mesma altura do quadro |
| **Som** | o saco para; silêncio; `strap_open`; `door_roll` + `door_jam` | silêncio; `door_roll` + `door_jam`; `strap_rip`; `toc, toc` |
| **Olhar** | ele olha para a entrada | ele olha o símbolo da escola no discípulo |
| **Fala** | "Vamos **ver** sua guarda." | "Quero **ver** o que aprenderam." e é ele quem arma a guarda |
| **Depois** | o controle volta e ele senta para assistir | a janela abre, as barras de vida entram e ele luta |
