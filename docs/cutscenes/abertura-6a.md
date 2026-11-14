# Abertura da 6a — prólogo na sala viva (storyboard)

Dono: Diretor de Cutscenes. Versão 1 (2026-11-13). Fase 6a.
Base: `docs/fases/fase6a-escopo.md` (§2.1, §3.4, critérios 1, 2 e 9), `fase6a-design.md` §5 (estados, teto, calendário), `fase6a-textos.md` §3 (falas), `linguagem.md`, `gesto-assinatura.md`, `balao-e-voz.md`.
**Não é cutscene:** não existe player de cena na 6a. A interface fica ligada, o saco vale desde o primeiro quadro e ninguém prende o jogador.
**Decisão do dono (2026-11-13):** 1º lutador **John Bullet** (plaquinha `john`), treinador **Osmar Brandão** (plaquinha `osmar`), escola **Raízes Fight Club**, humilhação **A, "a ficha em branco"**. Os ids de voz continuam `first` e `coach`. As falas são as do Roteirista com o nome trocado; o texto final dele manda.

## 1. Gatilho e marco
- **Quando:** estado `pending` → `playing` no primeiro momento de sala calma de um save sem o marco `prologue_seen` (`fase6a-design.md` §5.1). No save novo é o primeiro quadro da sala.
- **Marco:** `prologue_seen`, gravado e salvo **em t = 0**, antes do gesto e de qualquer balão. Pular, fechar o jogo ou abrir janela no meio não repete nada.
- **Save antigo:** a mesma abertura, uma vez, com o que a campanha atual tiver na sala (aparelhos e equipe continuam se mexendo).
- **Campanha atual na academia** (possível no save antigo): toca igual. O aviso não está na tela, mas `open_1` ("chegou outro aviso") funciona sem ele. Osmar olha para a foto antiga se ela estiver lá; senão, para o John.
- O relógio do calendário **anda** durante a abertura (decisão do Designer, §5.3). Os comentários do treinador ficam fechados até o estado `over`.

## 2. Palco (garagem, base 640x360, personagens pelo ponto dos pés)

| Elemento | Posição | Observação |
|---|---|---|
| John (`first`) | **(303,272)**, `foco_saco`, virado para a direita | ponto e folha que o jogo já usa (`fighter_idle`). Ninguém anda na abertura |
| Saco | centro (336,183) | alvo `click_area` (312,182,48,90) |
| Osmar (`coach`) | **proposta (236,238)**, virado para a direita, encostado no para-lama do carro coberto | ponto próprio, fora dos geradores. Diretor de Arte confirma contra `neighbor_2` (220,258), a caixa da corda (258,244) e o ponto do mentor da 6b (268,266). Reserva: (160,252), no canto da parede esquerda |
| **Parede da memória** | parede do fundo, x 180..262, y 56..104 (acima da prateleira, junto do quadrinho que já existe em ~(245,74)) | aviso, foto antiga e ficha agora; depois recorte e foto da equipe. É para onde Osmar olha |
| Aviso de cobrança | proposta (200,62), ~18x24, torto, com fita e carimbo vermelho | tem que ler como "conta" sem texto |
| Ficha amassada (objeto da humilhação) | na mesma parede, ≤ 24x24, presa com um prego | opcional pelo Roteirista; **peço que entre**, porque é ela que faz o balão 4 ("um nome ali") ter para onde apontar |

Balões (regra de `balao-e-voz.md` §3): o de Osmar fica em cima dele, x 150..322, y 134..165; o do John é empurrado para a esquerda do alvo, x 136..308, y 168..199. Um por vez.

## 3. Batida a batida (≈ 14 s com as falas propostas)

`t` conta do primeiro quadro da sala. **O clique no saco vale em t = 0,0** (o critério pede ≤ 3 s; não há guarda de clique no alvo).

| # | t (s) | Quem | O que acontece | Folha / pose | Som |
|---|---|---|---|---|---|
| 0 | 0,0 | — | A sala aparece com a interface normal. John em guarda. **Osmar está de lado, olhando o aviso** na parede. A dica de primeira vez da barra de baixo pisca como hoje. | `fighter_idle`; `coach_look` parado | nenhum som novo |
| 1 | 0,30–1,19 | John | **Gesto A completo** (o gesto antes da fala): luva na boca, puxa o fecho, dois toques. | `fighter_gesture` (8 quadros, 9 fps) | `strap_rip` em 0,41; `tap_glove` em 0,86 e 1,08 |
| 2 | 1,2 | Osmar | Vira a cabeça para o John (reage aos toques). | `coach_look` → `coach_idle` | — |
| 3 | 1,5–4,15 | Osmar | **Balão 1 — a garagem em dificuldade.** `open_1`: "chegou outro aviso, john." (25) | `coach_talk` enquanto escreve; `coach_idle` depois | blip `coach`, 22 c/s |
| 4 | 4,45–7,1 | Osmar | **Balão 2 — o sonho.** Antes de falar ele **volta a olhar a parede** (agora a foto antiga); o balão entra 0,3 s depois do olhar. `open_2`: "ainda formo campeão aqui." (25) | `coach_look`, depois `coach_talk` | blip `coach` |
| 5 | 7,4–11,35 | John | **Balão 3 — a humilhação.** Osmar vira para ele. `open_3`: "o muralha riu da ficha: / escola: nenhuma." (39) | John em `fighter_idle` (sem folha de fala: quem fala é o balão); `coach_idle` | blip `first`, 28 c/s |
| 6 | 11,65–13,8 | John | **Balão 4 — a decisão.** `open_4`: "vou botar um nome ali." (22). **Osmar olha a ficha na parede** (é o olhar dele que mostra o "ali"). | `fighter_idle`, rosto `smile` se a folha permitir; `coach_look` | blip `first` |
| 7 | 14,1 | Osmar | Volta ao parado. Estado `over`. | `coach_idle` | — |

- Entre balões: 0,3 s. Tempo de leitura: `max(1,2 s; 0,06 s x letras)` (`typing.hold_*`).
- **Teto:** `opening.max_seconds` = 20 s. Se chegar lá com balão escrevendo, ele completa e some (Designer §5.2).
- Sem câmera, sem corte, sem barras, sem escurecer nada. **Um movimento por vez:** enquanto um fala, o outro só respira ou olha.
- **Ajuste sobre a tabela do Roteirista:** os tempos acima substituem os "t aprox." dele (o balão 3 começa em 7,4 s, o 4 em 11,65 s). A ordem e os textos são os dele.

As 3 ideias do escopo: dificuldade = aviso + olhar de Osmar + balão 1; sonho = foto antiga + balão 2; humilhação e vontade de provar = ficha + balões 3 e 4.
**Sem ler nada**, sobra: um velho olhando um aviso na parede, um lutador que morde o fecho e bate dois toques, e um saco esperando.

## 4. Quando o controle volta
**Ele nunca sai.** Desde t = 0 valem clique no saco, ESPAÇO, compras, abas e botões.
O fim da abertura (≈ 14 s; no máximo 20 s) só muda o estado para `over`, que libera:
- os comentários do treinador (o fim da abertura conta como um comentário: o 1º vem pelo menos 60 s depois);
- o gesto curto da sala parada (20 s sem clique).

## 5. Orçamento das falas
- Vale o do Designer: **≤ 140 letras somadas nos 4 balões**, com o validador somando o tempo e reprovando acima de 20 s. A proposta atual tem **111 letras** e dá ≈ 14 s: sobra folga para o dono ler devagar.
- Pedido ao Roteirista se reescrever: manter a ordem Osmar, Osmar, John, John; o balão 2 começa depois de um olhar (0,3 s); o balão 4 tem que fazer sentido com e sem a ficha na parede.
- Ids nos dados: `open_1` a `open_4` (o `fase6a-textos.md` chama de `ab_1` a `ab_4`; vale o nome do Designer).

## 6. Se o jogador clicar durante a abertura

| Ação | Efeito |
|---|---|
| **Clique no saco** | Treino normal, sempre. Se o gesto estiver tocando, **é cancelado no mesmo quadro** e vira o soco (o `strap_rip` é cortado; o 2º toque não toca). O gesto da abertura não é refeito. **Os balões seguem** no ritmo deles: o clique no alvo nunca é consumido, não completa nem fecha fala. |
| Clique em botão ou na sala **fora do alvo** | Cancela o gesto, se estiver tocando. Fora do alvo e fora de botão: completa a fala que está sendo escrita (sem blip); o tempo de leitura corre normal. Não pula o próximo balão. |
| **ESPAÇO** | Só treina, como hoje. Não completa fala na sala viva (decidido; `balao-e-voz.md` §5). |
| Comprar, trocar de aba | Funciona normal; a abertura segue. |
| **Abrir qualquer janela** (LUTAR, árvore, caixa) | O balão da vez fecha na hora e a abertura **espera**: os balões seguintes só entram com a sala calma de novo. O teto de 20 s continua contando; passou dele, vai para `over`. Nunca fica balão por baixo de janela. |
| **Segurar ESC 0,5 s** | Pula tudo: estado final em até 0,3 s. Soltar antes não faz nada. |
| Fechar o jogo | `prologue_seen` já foi gravado em t = 0: não toca de novo. |

O balão do John fica preso ao **ponto parado** da cabeça dele; não treme quando ele soca.

## 7. Estado final (igual pulando ou não)
- Nenhum balão. John em `fighter_idle` (ou socando, se o jogador estiver clicando). Osmar em `coach_idle` no ponto dele.
- Aviso de cobrança, foto antiga e ficha na parede: são do cenário e já estavam lá em t = 0.
- `prologue_seen` gravado, estado `over`. Nenhum recurso é tocado; nenhum segundo é somado.

## 8. Checagem (`linguagem.md` §8)
1. ≤ 20 s (≈ 14 s) e versão pulada com o mesmo estado final. OK.
2. Funciona sem ler. OK.
3. Save antigo e campanha na academia. OK.
4. Não repete depois de reset: marco da escola. OK.
5. Personagens nos pontos do jogo; ninguém anda. OK.
6. Posições inteiras. OK.
7. Balões: uma captura por balão para a `alinhamento-ui`, na garagem e na academia.

## 9. Pendências
- **Roteirista:** trocar os nomes em `fase6a-textos.md` (inclusive a ficha depois de salva: `ESCOLA: RAIZES FIGHT CLUB`) e conferir se o símbolo da lâmpada ainda combina com o nome novo da escola.
- **Diretor de Arte:** ponto de Osmar, parede da memória, aviso e ficha.
- ESPAÇO na sala viva: **decidido**, só treina (`balao-e-voz.md` §5).
- **Programador:** o ESC já é usado em `ui/fluxo.gd`; o "segurar 0,5 s" não pode fechar outra coisa no aperto.
