# Cena: Reencontro final (storyboard)

Dono: Diretor de Cutscenes. **Versão 2 (2026-11-14).** Fase 11. Cena única. **Não entra na 6b**: está atualizada agora porque a sucessão planta o que ela colhe.
Esta versão junta a prancha aprovada (`prancha-6b.md`, quadros R1–R10, todas as opções A, registro em `ideia-do-dono.md`). Onde a versão 1 dizia outra coisa, vale esta.
Nomes: John Bullet (plaquinha `john`, voz `first`), o discípulo da campanha atual, Raízes Fight Club. O rival não aparece.
Função (direção narrativa §6, Arco 6, e §9): **dar espaço para o jogador reconhecer** o John pelo gesto, pela aparência e pelo nome. Ele não é vilão: é o último mestre a superar.
Par visual: `primeira-sucessao.md` (a tabela "Como as duas cenas conversam" está lá).
Linguagem: `linguagem.md` (registro **Simples**). Gesto: `gesto-assinatura.md`.

## Escolhas do dono que esta versão aplica
| # | Escolha (A) | Onde aparece |
|---|---|---|
| 5 | Corte de perto (2x) no gesto, como na sucessão | R4 e R5 |
| 6 | Começa com a falsa entrada exagerada, que apaga | R1 e R2 |
| 7 | Só "John Bullet", pequeno, na faixa preta | R7 |
| 8 | John grisalho, barba por fazer, mesmo corpo e a mesma luva velha | seção "O John mais velho" |

Última arena simples (concreto, uma lâmpada, porta de enrolar): aprovada pelo dono em 2026-11-11.

## Gatilho
- **Evento:** o jogador aperta LUTAR na prévia da última luta (topo dos torneios secretos) **pela primeira vez na história da escola**. A cena entra no lugar da entrada normal da luta.
- **Marco:** `cena_reencontro_final`, gravado no começo.
- **Antes da cena o jogo não revela quem é:** na prévia e no bloco PRÓXIMA LUTA, retrato em silhueta e um título no lugar do nome. **Os números da prévia continuam honestos.** (Pedido ao Designer e ao UI/UX.)
- **Depois do marco:** retrato e nome verdadeiros em todo lugar.
- **Tentativas seguintes:** versão curta, sem fala, dentro da entrada normal de 1,5 s.

## Palco
Tela de luta (640x360). A cena fecha a imagem na **janela (128,52,384,272)**, do tamanho da sala da garagem.
Sala de concreto, **uma lâmpada pendurada, um círculo de giz no chão e uma porta de enrolar à direita**. Sem torcida.

| Elemento | Posição | Observação |
|---|---|---|
| Lâmpada | (320,62) | o mesmo sprite e o mesmo zumbido da garagem |
| Porta de enrolar (`final_door`) | miolo x 382..463, y 154..253 | mesmo x da porta da garagem. **Emperra com a borda em y 194** (altura do ombro): a cabeça fica toda escondida e os dois toques aparecem inteiros |
| Discípulo | (296,318), virado para a direita | ponto normal do jogador; aparência, luva e **símbolo da escola** dele |
| John (mais velho) | atrás da porta em (423,256); termina em (346,318), virado para a esquerda | ponto normal do adversário |
| Nome | **faixa preta de baixo, y 331**, centrado no x dele (346) | fora da janela, que termina em y 323 |

## Quadros (21,6 s)

| # | Tempo | Plano | O que acontece | Pose / animação | Som |
|---|---|---|---|---|---|
| **R1** Entrada exagerada? | 0,0–1,6 | tela inteira | Três holofotes varrem a porta, tambor, letreiro de apresentação. **Não entra ninguém.** O discípulo espera de guarda. Os holofotes apagam um a um. | 3 feixes e letreiro (os das vinhetas da fase 10); `fight_player_idle` | `intro_drums` que murcha; 3 estalos |
| **R2** Sobra uma lâmpada | 1,6–3,0 | a imagem fecha na janela 384x272 | Só a lâmpada acesa. O discípulo sozinho, à esquerda. Meio segundo de silêncio. | pilares e barras entram em 0,4 s | `lamp_hum` |
| **R3** A porta emperra | 3,0–5,0 | janela 1x | Passos lentos e couro raspando fora de quadro. A porta treme, sobe e trava no mesmo ponto do quadro da garagem. Vemos John **do ombro para baixo**, luvas caídas. | 4 passos a cada 0,45 s; `final_door` (fechada → 1/3 → emperrada, 0,8 s), tranco de 1 px; John parado de braços baixos | `step_1`/`step_2`, `glove_rub`, `door_shake`, `door_roll`, `door_jam` (os da sucessão) |
| **R4** O fecho, sem rosto | 5,0–6,6 | **corte seco para 2x**, região (327,123,192,136) | A luva sobe e some atrás da borda da porta. Ouve-se o fecho. | `fight_player_gesture` lento (1,4 s no total), cabeça coberta pela porta | `strap_rip` |
| **R5** Dois toques | 6,6–8,2 | 2x, mesmo plano | A luva desce e bate duas vezes na outra, com 2 faíscas. Depois, 0,6 s sem nada. | quadros 5 a 7 do gesto, no tempo normal | `tap_glove` x2, intervalo de 0,22 s |
| **R6** Passa por baixo | 8,2–11,0 | **corte seco para 1x** | Ele passa por baixo da porta com a mesma pose do discípulo na garagem, endireita o corpo e anda até a luz. | `duck_under` em vista de luta (0,7 s); `walk` de (423,256) a (346,318), 2,1 s a 48 px/s | passos |
| **R7** O rosto e o nome | 11,0–13,6 | janela 1x | A luz pega o rosto, mais velho. Braços baixos. Aparece **só "John Bullet"**, pequeno, na faixa preta. **2,6 s sem fala e sem som novo.** Uma piscada da lâmpada. O discípulo levanta a cabeça 1 px. | John parado; nome em 1x, `cream`, sem título nem moldura | `lamp_hum` |
| **R8** "então vocês chegaram." | 13,6–17,6 | janela 1x | Ele fala; o nome some quando o balão entra. Depois baixa os olhos para o **símbolo da escola** no peito do discípulo, que brilha por 2 quadros. | balão de cena (21 caracteres, 24 c/s); `look_emblem` (segura 1,0 s); `fx` de brilho | blip dele, uma terça abaixo |
| **R9** "quero ver o que aprenderam." | 17,6–20,4 | janela 1x | Ele arma a guarda e sorri de leve. | guarda com rosto `smile`; balão de 2 linhas (27 caracteres) | blip; couro |
| **R10** Luta | 20,4–21,6 | a janela abre para a tela inteira | Barras de vida com o retrato e o nome dele. Sino. | pilares e barras saem em 0,4 s; HUD normal | `bell_start` |

O discípulo não fala. A resposta dele é a luta.

## Versão curta (tentativas seguintes, ≤ 1,5 s)
A porta já está emperrada e ele já está sob a lâmpada. Dois toques (gesto curto, 0,44 s), guarda, sino. Sem fala, sem janela, sem holofote.

## Se pular
- Em 0,3 s fica o estado do R10: John em (346,318) de guarda, porta meio aberta ao fundo, tela inteira, HUD com retrato e nome, sino, luta.
- O marco já estava gravado: a prévia passa a mostrar quem ele é e a cena completa não volta.
- Pular não muda nenhum número da luta.

## O que fica depois
- A porta meio aberta e a lâmpada continuam durante a luta (é o cenário).
- Prévia, bloco PRÓXIMA LUTA e retrato mostram o John mais velho.
- **Nada no mural ainda.** A foto dos dois é da cena "Vitória final".
- Se o discípulo perder: fim de campanha normal.

## O John mais velho (pedido ao Artista de Personagens, fase 11)
- **O mesmo corpo**: mesmas medidas de braço e perna, mesma cabeça, mesmo calção. O jogador reconhece a silhueta antes do rosto.
- **Grisalho e com barba por fazer** (`g2`/`g3`), sobrancelha mais pesada. Não fica mais pesado nem de cabelo branco.
- **A mesma luva velha remendada**, a do começo do jogo.
- Sem símbolo da escola na roupa: o símbolo nasceu depois dele. É por isso que ele olha.
- Poses: parado de braços baixos, `duck_under` e `walk` em vista de luta, `look_emblem`, guarda com `smile`, gesto lento. Retrato 32x32 e silhueta para a prévia.

## Falas (rascunho; o Roteirista pole na fase 11)
| id | Quem | Rascunho | Intenção |
|---|---|---|---|
| `fim_chegaram` | John | "então vocês chegaram." | "Vocês" = a linhagem inteira. Sem surpresa, sem ameaça. |
| `fim_ver` | John | "quero ver o que aprenderam." | Ecoa "vamos ver sua guarda." Manter o verbo **ver**. |

## Dependências que travam esta cena
1. Gesto usado desde a 6a (`gesto-assinatura.md`): feito.
2. Porta de enrolar que emperra no ombro e `duck_under`, estabelecidos na sucessão (6b1).
3. Símbolo da escola na roupa dos discípulos (6c): o R8 depende disso.
4. Vinhetas exageradas na fase 10, para o silêncio daqui ter contraste.
5. Passos de luta do player de cena (`view: fight`, `frame`, `name_card`, `light`, `start_fight`): fase 11.
