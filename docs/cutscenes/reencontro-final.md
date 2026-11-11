# Cena: Reencontro final (animatic por escrito)

Dono: Diretor de Cutscenes. Versão 1 (2026-11-11). Fase 11. Cena única.
Função (direção narrativa §6, Arco 6, e §9): **dar espaço para o jogador reconhecer** o 1º lutador pelo gesto, pela aparência e pelo nome. Ele não é vilão: é o último mestre a superar.
Par visual: `primeira-sucessao.md` (a tabela "Como as duas cenas conversam" está lá).
Linguagem: `linguagem.md` (registro **Simples**). Gesto: `gesto-assinatura.md` (opção A). Falas são rascunho para o Roteirista.

## Gatilho
- **Evento:** o jogador aperta LUTAR na prévia da última luta (topo dos torneios secretos) **pela primeira vez na história da escola**. A cena entra no lugar da entrada normal da luta.
- **Marco:** `cena_reencontro_final`, gravado no começo.
- **Antes da cena o jogo não revela quem é:** na prévia e no bloco PRÓXIMA LUTA, retrato em silhueta (como o `?` que já existe) e um título no lugar do nome. **Os números da prévia continuam honestos**: nada de mecânica depende da surpresa. (Pedido ao Designer e ao UI/UX.)
- **Depois do marco:** retrato e nome verdadeiros em todo lugar.
- **Tentativas seguintes** (perdeu e voltou com outro discípulo): versão curta, sem fala, que cabe na entrada normal de 1,5 s (ver "Versão curta").

## Palco
Tela de luta (640x360). A cena fecha a imagem na **janela (128,52,384,272)**, igual em tamanho à sala da garagem.

**Proposta de cenário (precisa do Diretor de Jogo e do dono):** a última arena é um lugar simples. Depois das arenas absurdas, a última porta dá numa sala de concreto com **uma lâmpada pendurada, um círculo de giz no chão e uma porta de enrolar à direita**. Ele montou no topo um lugar parecido com aquele onde começou. Sem torcida.
**Plano B**, se a arena for outra: qualquer arena com tudo apagado menos um foco de luz; ele entra pela direita e a borda da luz o mostra só do peito para baixo (máscara de sombra em dither). O resto da cena é igual.

| Elemento | Posição | Observação |
|---|---|---|
| Lâmpada | (320,66) | o mesmo sprite e o mesmo zumbido da garagem |
| Porta de enrolar | x 382..464, base y 254 | mesmo lugar e largura da porta da garagem dentro da janela; valores finais do Diretor de Arte |
| `discipulo` | (296,318), virado para a direita | ponto normal do jogador; com a aparência, a luva e o **símbolo da escola** dele |
| `primeiro` (mais velho) | atrás da porta em (423,256); termina em (346,318), virado para a esquerda | ponto normal do adversário |

## Quadros (≈ 21,5 s)

| # | Tempo | Plano | O que acontece | Pose / animação | Som |
|---|---|---|---|---|---|
| 1 | 0,0–2,5 | tela inteira → janela | Começa como mais uma apresentação exagerada: holofotes varrem a entrada, rufar de tambor. **Ninguém aparece.** Os holofotes apagam um a um. A imagem fecha na janela 384x272. Sobra a lâmpada e o discípulo sozinho, de guarda. | holofotes (3 feixes, os mesmos das vinhetas da fase 10); pilares e barras entram em 0,4 s; `fight_player_idle` | `intro_drums` que murcha; 3 estalos de luz; `lamp_hum` |
| 2 | 2,5–5,0 | janela 1x | Meio segundo de silêncio. **Passos** lentos fora de quadro e **couro raspando**. A porta treme, sobe e **emperra na altura do peito**. | 4 passos a cada 0,45 s; adereço `final_door` (fechada → 1/3 → emperrada, 0,8 s), tremida de 1 px | `step_1`/`step_2`, `glove_rub`, `door_shake`, `door_roll`, `door_jam` (os mesmos da sucessão) |
| 3 | 5,0–8,2 | **corte para 2x**, região (327,123,192,136): as luvas ficam no mesmo ponto do quadro que na sucessão (centro, 78 px abaixo do topo) | Vemos `primeiro` **do peito para baixo**, luvas caídas ao lado do corpo. A luva esquerda sobe e some atrás da borda da porta: **o fecho**. Ela desce. **Dois toques.** Depois, 0,6 s sem nada. | `fight_player_gesture` na versão lenta (1,4 s), com a cabeça coberta pela porta; 2 faíscas pequenas nos toques | `strap_rip`; `tap_glove`, `tap_glove` (intervalo de 0,22 s, igual ao do jogo inteiro) |
| 4 | 8,2–11,0 | **corte para 1x** | Ele **passa por baixo da porta** (a mesma pose do discípulo na sucessão), endireita o corpo e anda até debaixo da lâmpada. | `duck_under` em vista de luta (0,7 s); `walk` de (423,256) a (346,318), 2,1 s a 48 px/s | passos |
| 5 | 11,0–13,6 | janela 1x | A luz pega o rosto: **mais velho**. Aparece **só o nome**, pequeno, sem título. **2,6 s sem fala e sem som novo.** Só respiração e uma piscada da lâmpada. O discípulo levanta a cabeça 1 px. | `primeiro`: parado, braços baixos; cartão de nome simples (1x, `cream`, centrado 8 px abaixo dos pés dele) | `lamp_hum` |
| 6 | 13,6–15,8 | janela 1x | **`primeiro`:** "Então vocês chegaram." | balão de cena, 21 caracteres, 24 c/s; fica 1,3 s | blip dele, uma terça abaixo |
| 7 | 15,8–17,6 | janela 1x | Ele **olha o símbolo da escola** no discípulo: a cabeça baixa um pouco. O símbolo dá um brilho de 2 quadros. | nova `look_emblem` (segura 1,0 s); `fx` de brilho no símbolo | — |
| 8 | 17,6–20,4 | janela 1x | Ele **arma a guarda** e sorri de leve. **`primeiro`:** "Quero ver o que aprenderam." | guarda dele (`idle`), rosto `smile`; balão de 2 linhas (27 caracteres); fica 1,5 s | blip; couro |
| 9 | 20,4–21,6 | janela → tela inteira | A janela **abre** para os 640. As barras de vida entram, com o retrato e o nome dele. Sino. Luta. | pilares e barras saem em 0,4 s; HUD normal da luta | `bell_start` |

O cartão de nome do quadro 5 some quando o balão do quadro 6 entra.

## Versão curta (tentativas seguintes, ≤ 1,5 s)
A porta já está emperrada meio aberta e ele já está sob a lâmpada. Dois toques (gesto curto, 0,4 s), guarda, sino. Sem fala, sem janela, sem holofote.

## Se pular
- Em 0,3 s: `primeiro` em (346,318) de guarda, porta meio aberta ao fundo, tela inteira, HUD com retrato e nome dele, sino, luta.
- O marco já estava gravado: a prévia passa a mostrar quem ele é, e a cena completa não volta.
- Pular não muda nada da luta (mesmos números, mesma tática escolhida).

## O que fica depois
- A porta meio aberta e a lâmpada continuam durante a luta (é o cenário).
- Prévia, bloco PRÓXIMA LUTA e retrato mostram o 1º lutador mais velho.
- **Nada no mural ainda.** A foto dos dois é da cena "Vitória final" (storyboard próprio, depois deste).
- Se o discípulo perder: fim de campanha normal. Os comentários de quem ficou na escola são do Roteirista, fora desta cena.

## O 1º lutador mais velho (pedido ao Artista de Personagens)
- **O mesmo corpo**: mesmas medidas de braço e perna, mesma cabeça, mesmo calção. O jogador tem que reconhecer a silhueta antes do rosto.
- Mais velho em poucos pixels: têmpora e barba por fazer grisalhas (`g2`/`g3`), sobrancelha mais pesada, ombro um pouco mais largo.
- **Luva velha remendada**, a do começo do jogo, não uma luva de marca.
- Sem símbolo da escola na roupa: o símbolo nasceu depois dele. É por isso que ele olha.
- Retrato 32x32 novo e a silhueta para a prévia.

## Rascunho de falas (para o Roteirista)
| id | Quem | Rascunho | Intenção |
|---|---|---|---|
| `fim_chegaram` | `primeiro` | "Então vocês chegaram." | "Vocês" = a linhagem inteira. Sem surpresa, sem ameaça. |
| `fim_ver` | `primeiro` | "Quero ver o que aprenderam." | Ecoa "Vamos ver sua guarda." Manter o verbo **ver**. |

O discípulo não fala nesta cena. A resposta dele é a luta (e a troca da "Vitória final").

## Dependências que travam esta cena
1. Gesto escolhido e usado desde a 6a (`gesto-assinatura.md`).
2. Símbolo da escola existindo na roupa dos discípulos desde a 6b/6c.
3. Porta de enrolar que emperra, estabelecida na sucessão (6b).
4. Vinhetas exageradas na fase 10, para o silêncio daqui ter contraste.
5. Decisão sobre a última arena (proposta acima ou plano B).
