# Fase 6b1 — Passar o posto: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-15. Branch `fase-6b`.
Li: `fase6b-escopo.md` (critérios 1–12 e 18–20, com as "Escolhas do dono (2026-11-14)"), `fase6b1-design.md`, `fase6b1-textos.md`, `fase6b1-api.md`, `fase6b1-qa.md`, `docs/cutscenes/prancha-6b.md` (aprovada, todas as A), `ideia-do-dono.md`, `docs/direcao-narrativa.md` e `data/cutscenes/primeira_sucessao.json`.
Capturas conferidas: `f6b1_s3`, `f6b1_s5` (criação), `f6b1_s7`, `f6b1_s8`, `f6b1_s10`, `f6b1_mentor_sentado`, `f6b1_fim_botao` e o mockup `docs/arte/mockups/fase6b1_andar_esquerda_x4.png`.

Depois do QA, o Produtor e a equipe corrigiram:
- **B1:** a tela de fim diz "O par fica no saco. O próximo vai pegar." (conferido na captura).
- **B2:** a reação do 1º clique é zerada ao lutar ou mudar de local, e os toques não se perdem mais.
- **B3:** a chegada curta caiu para 2,37 s (o teto é 2,5).
- **B4:** o nome colado é filtrado antes de ser cortado em 14.
- **B6:** todas as poses da cena estão ligadas, o validador dá 0 pendências e a cena grande tem 14,75 s presos (o teto é 16).
- **Braço "ao contrário"** (reclamação do dono): os braços foram redesenhados e o andar para a esquerda ganhou folhas próprias (`_left`), sem espelho.
- **Tela de criação em posição fracionada** na entrada: a animação anda só em pixels inteiros.

O `run_tests` passa, o `ui_audit` dá 276 estados com 0 problemas e o balanço é idêntico ao da 6a.

## 1. Veredito
**Aprovado.** A fase está pronta para o dono testar.
- Os 15 critérios da 6b1 (1–12 e 18–20) passam. Os bugs B1–B4 e a observação B6 foram corrigidos.
- A reclamação do dono sobre o braço foi atendida do jeito certo, com desenho próprio em vez de remendo no espelho. No mockup, a versão "depois" lê como alguém andando para a esquerda, com o braço da frente balançando do lado certo, nos dois tons de pele.
- O balanço não mudou: a simulação em Python (b23c/f52) e a simulação determinística dão a mesma saída da 6a, e o relógio fica parado durante a cena e a criação.

## 2. A visão foi entregue?
| Pedido (escopo / prancha / direção) | Entregue? | Como |
|---|---|---|
| O John passa o posto de verdade, sem despedida triste | **Sim** | S3 de perto (corte 2x), luvas penduradas no saco, discípulo calça o par, "vamos ver sua guarda." e "isso." |
| Ele não foi embora, está ali olhando | **Sim** | John sentado no caixote ao lado do Osmar (`f6b1_mentor_sentado`), toques sem luva no 1º clique e na volta de vitória, no máximo 1 por minuto |
| "Esse lutador agora é meu" | **Sim, na medida da 6b1** | Nome, pele, cabelo e calção, com prévia na hora. O nome aparece no HUD, no cartão e no fim. Cortes e roupas são da 6b2 |
| Prancha S1–S10 com as escolhas A | **Sim** | Criação no meio (S5), luvas no saco, luz do dia branca na porta (S7), Osmar presente e calado, corte 2x no S3 |
| A história não atrasa o clique | **Sim** | 14,75 s presos, pular em 0,5 s, o 1º soco vale no quadro do `return_control` e a criação confirma em 1 clique |
| Só o John faz o gesto | **Sim** | `pedir_gesto` vazio para o discípulo, e o validador reprova o gesto em `current_player` |
| A escola guarda quem passou | **Sim** | `school.roster` fora do reset, uma entrada por campanha encerrada |
| Player por dados que serve à 6c e à 11 | **Sim** | O validador conhece todos os tipos de passo, e a chegada curta é a segunda cena feita no mesmo formato |

### O que ficou bom
- **O S7 é a imagem da fase.** Ele mostra a porta aberta com a luz branca, o discípulo novo no vão, as luvas penduradas no saco e o John esperando. Tudo isso lê sem nenhuma palavra.
- **"vamos ver sua guarda." no S8** é o tom certo, pé no chão e de treinador. O balão não cobre a cabeça de ninguém.
- **O John sentado não polui a sala.** Ele fica fora da faixa do alvo, ao lado do Osmar, e a garagem ganha uma "plateia" que conta a linhagem sem texto.
- **A tela de criação é rápida.** Ela abre preenchida, tem 4 linhas e o botão CONFIRMAR grande, e já deixa espaço vazio para as linhas da 6b2. "LUVA: O PAR DO JOHN" na própria tela amarra a criação com a cena.
- **A correção do braço foi feita com desenho e não com espelho.** É o padrão que quero daqui para a frente: se a direção importa para a leitura, ganha folha própria.

### Pontos de atenção (não bloqueiam)
- **O `mentor_spot` passou de (268,268) para (254,252), e a caixa da corda foi para (424,287).** Aceito, é decisão do Diretor de Arte e lê bem na captura. O escopo e a prancha ainda citam (268,268), então valem os dados (`manifest.json`). Na 6b2, o `mentor_2_spot` tem que ser conferido contra a **nova** posição da caixa da corda.
- **A parte 1 está justa.** O QA mediu 9,36 s com teto de 9,5 s. Os braços novos não mudam o tempo, mas qualquer pose a mais na parte 1 estoura. Regra para a 6c: se uma pose entrar ali, outra sai.
- **O botão do fim usa o plano B, "NOVO DISCÍPULO".** O texto cheio não coube. Lê bem e mantém a ideia, então aceito.
- **Quem fecha o jogo na criação da 1ª sucessão perde a parte 2** e vê a chegada curta no lugar. A decisão é do design e é um caso raro, então aceito.
- **No save do dono, a cena mostra o John no saco, mas quem acabou de jogar foi o "Novato".** É a regra do escopo (§3, item 11) para saves antigos: a cerimônia que ficou devendo toca agora. O Produtor precisa avisar o dono antes, para ele não achar que é bug (ver §6 e a pergunta 6).

## 3. Algo passou do escopo?
**Não.**
- Não entrou corte de cabelo, roupa, segundo mentor nem filtro de combinações. Os campos da 6b2 só existem no save, com o valor padrão.
- Os mentores não falam fora da cena.
- Não há mural, Honra nem símbolo na roupa.
- O player só executa os passos da vista `room`.
- Nenhum arquivo de balanço em `data/` mudou.

## 4. Pendências
| Pendência | Decisão |
|---|---|
| O escopo e a prancha citam `mentor_spot` (268,268) | **Aceita.** Atualizo a referência no escopo da 6b2. Valem os dados |
| A margem da parte 1 é de 0,14 s | **Aceita**, com a regra de "uma entra, uma sai" |
| Criação reaberta toca a chegada curta, e não a parte 2 | **Aceita** (design §1.4) |
| Testes do QA (`qa_f6b1_*.gd`) | Ficam no repositório. O `qa_f6b1_logica.gd` agora deve passar inteiro, porque o B2 foi corrigido. **Confirmar antes do merge** |
| Timbre e frequência dos toques | **É do dono.** Só dá para validar jogando |

## 5. O que fica para as próximas fases
| Item | Fase |
|---|---|
| 4 cortes, regata/camiseta, faixa, meião, segundo mentor (`mentor_2_spot`) e filtro de combinações feias | **6b2** |
| Botão "igual ao anterior" na criação | **6b2**, só se o dono achar a tela cansativa |
| Mural, Honra, falas de mentor, saída do John, mentores na academia e símbolo na roupa | **6c** |
| Passos de luta do player e reencontro | **11** |
| Opção de desligar o blip | **13**, ou antes se o dono pedir |

## 6. Roteiro de teste do dono (cerca de 10 min)
Use o save de sempre. Ele já está na Carreira 4, com o "NOVATO".

**Aviso antes de começar:** o Novato tem nome e aparência padrão, e não há tela para mudar isso agora. No fim desta campanha toca a cena do John passando o posto. Ela aparece agora porque o seu save começou antes dela existir. É a cerimônia do John, que ficou "devendo".

1. **Termine a Carreira 4 (o tempo que quiser).** Perca uma luta ou aperte PASSAR O POSTO.
   - Valide: a tela de fim diz "o par fica no saco" e o botão diz NOVO DISCÍPULO.
2. **A cena (15 s).** Aperte NOVO DISCÍPULO e assista sem pular.
   - Valide: dá para ver o John tirando as luvas, de perto? As luvas ficam no saco? A cena emociona, ou 15 s parece muito?
3. **Criação (30 s).** Troque pele, cabelo e calção e digite um nome. Depois aperte SORTEAR e CONFIRMAR.
   - Valide: a prévia muda na hora? Daria para fazer isso em toda campanha?
4. **A entrada.** O discípulo entra pela porta e anda até o saco.
   - Valide: o braço agora está certo no andar para a esquerda?
5. **1º clique.** Soque assim que o controle voltar.
   - Valide: o soco vale na hora? O John faz os dois toques, diz "isso." e senta?
6. **Campanha normal (5 min).** Ganhe uma luta e volte à garagem.
   - Valide: o seu nome aparece no alto. A luva diz "o par do John". O John sentado incomoda ou faz companhia? Os toques cansam?
7. **Carreira seguinte.** Termine e receba outro discípulo.
   - Valide: agora vem só a criação e uma chegada curta (2 s), sem a cena grande. Isso agrada ou atrapalha?
8. **(Opcional) Pular.** Numa cópia do save, ou se quiser rever, segure ESC durante a cena.
   - Valide: vai direto à criação, que não dá para pular.

## 7. Perguntas para o dono
1. **A cena** emociona? 15 s parece muito ou na medida?
2. **O close do John tirando as luvas** (o quadro de perto) dá para entender?
3. **A tela de criação** é rápida o bastante para aparecer em toda campanha? Se cansar, sugiro um botão "igual ao anterior".
4. **O John sentado no caixote**: faz companhia ou distrai? Os dois toques cansam?
5. **A chegada curta** das campanhas seguintes agrada ou atrapalha?
6. **No seu save**, foi estranho ver o John passar o posto logo depois de jogar com o Novato? Isso só acontece em save antigo. Num jogo novo, quem passa o posto é sempre o John.
7. **O braço no andar para a esquerda** ficou certo agora?
8. **Pergunta que vem do escopo:** quem **perdeu** também conta como "o último que passou o posto" e vai sentar na garagem na 6b2? Eu decidi que sim.

## 8. O que confirmar antes da 6b2
- **A resposta da pergunta 8**: ela decide quem é o segundo mentor.
- **A resposta da pergunta 3**: ela decide se o botão "igual ao anterior" entra junto com as linhas novas.
- **Se as cores de pele, cabelo e calção bastam.** A 6b2 só acrescenta cortes e roupas e não mexe nas paletas.
- **O Diretor de Arte escolhe o `mentor_2_spot`** num mockup com a equipe cheia, as 4 caixas (com a corda já em (424,287)), a porta aberta e o John em (254,252).
- **O `qa_f6b1_logica.gd` passa inteiro** e a 6b1 está commitada antes de a 6b2 abrir.

## Resumo para o Produtor
- **Aprovado para o dono testar.** A 6b1 entrega a sucessão completa: a cena de 15 s com o John pendurando as luvas no saco, a tela de criação (nome, pele, cabelo e calção), o John sentado como mentor com os toques e "o par do John" na luva. O balanço é idêntico ao da 6a.
- B1–B4 e B6 foram corrigidos. O braço do andar para a esquerda foi redesenhado com folhas próprias, e o audit dá 0 problemas em 276 estados.
- **Avise o dono antes:** no save dele, a cena toca no fim da Carreira 4. O Novato sai e é o John quem passa o posto. Isso é esperado em save antigo.
- O dono responde 8 perguntas (cerca de 10 min). A mais importante para a 6b2 é se quem perdeu também senta na garagem.
