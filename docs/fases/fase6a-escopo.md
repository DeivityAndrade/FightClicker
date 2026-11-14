# Fase 6a — Prólogo e voz: escopo

Dono: Diretor de Jogo. Data: 2026-11-13. Branch `fase-6a` (sobre 5.4, 5.3, 5.2 e 5.1, ainda fora da `main`).
Li: `PROMPT.md`, `docs/roadmap.md` (6a, 6b, 6c), `docs/direcao-narrativa.md` (manda), `docs/visao.md`, `docs/propostas/feedback-2026-11-11.md` (seções 4 e 5), `docs/narrativa.md`, `docs/cutscenes/` (`linguagem.md`, `gesto-assinatura.md`, `formato-dados.md`, `pedidos.md`, `ideia-do-dono.md` com as decisões do dono) e `docs/fases/fase5.4-escopo.md`.
**Status: aprovado pelo dono antes de ver o plano ("pode continuar").** O que ele valida quando jogar está na seção 8.

## 1. Objetivo e sensação
- É a primeira fase com história: **as pessoas da garagem ganham voz, nome e gesto**, e a escola passa a ter um passado e uma meta (salvar a garagem). O treino, a luta e a economia continuam iguais.
- A sensação que queremos: *"essa garagem é de alguém, esse cara é alguém, e eu estou lutando para não perder este lugar"*, sem que o jogador nunca precise parar de clicar para entender isso.
- A história **acompanha** o treino. Ela não pode atrasar o treino nem obrigar a ler.

## 2. Decisões do Diretor (o que estava em aberto)
1. **A abertura não é uma cutscene.** O player de cena é da 6b. A abertura é a **própria sala viva**, com o saco aceitando clique desde o começo, 2 a 4 balões e o gesto do 1º lutador. Isso também garante que ela devolve o controle rápido.
2. **Garagem salva = 1º cinturão amador da escola**, ganho por qualquer discípulo (decisão anterior, mantida). Em geral isso acontece entre a 2ª e a 4ª campanha, então quase nunca é o 1º lutador que ganha. Isso combina com a direção: a conquista é da escola.
   - **Na hora do cinturão:** a tela de vitória mostra o selo "garagem salva". A informação fica na interface e não depende de balão.
   - **Na próxima vez que alguém estiver na garagem** (normalmente o começo da campanha seguinte, porque o cinturão leva à academia), o aviso já saiu, a foto da equipe está na parede e o treinador comenta uma única vez.
3. **O 1º lutador é o lutador da Carreira 1**, com o sprite atual do jogador. Ele faz o gesto e tem nome. Da Carreira 2 em diante, até a personalização chegar na 6b, entra um **"discípulo padrão"**: troca de paleta fixa (cabelo e calção diferentes), sem nome próprio, sem gesto e sem tela nova. A regra "só ele faz o gesto" vale desde já.
4. **Saves antigos com várias campanhas** (o caso do dono). **Isto substitui o item 11 do feedback**, porque do jeito antigo o dono nunca veria o 1º lutador na 6a:
   - A **campanha em andamento** passa a ser a do 1º lutador. O número da carreira não muda e o Legado, a árvore e os atributos ficam iguais.
   - A abertura toca **uma vez**, no primeiro carregamento, e pode ser pulada.
   - O aviso de cobrança aparece, e a garagem é salva **no próximo cinturão amador ganho depois da 6a**. Cinturões ganhos antes não contam. Assim o dono vê o Arco 1 inteiro sem precisar ver a abertura de novo.
   - O recorte de jornal aparece na próxima vitória da escola.
5. **Marcos da escola** ficam no save, fora do reset (`school.milestones`). Cada marco é gravado **no momento em que acontece**. Pular, fechar o jogo ou perder logo depois não faz o marco se repetir.
6. **A luva inicial é "o par dele"** (decisão do dono). Na 6a isso aparece só na descrição da luva e numa fala do treinador, uma vez. Tirar a luva e passar para outro é da 6b.

## 3. O que entra

### 3.1 Sistema de fala (balão e voz)
- **Balão preso ao personagem** (decisão do dono), com os valores de `linguagem.md` §7.1: no máximo 2 linhas de 26 caracteres, em minúsculas, com a plaquinha de nome.
- Nesta fase só entra o **modo passivo**: o jogador continua no controle, o balão não recebe clique, some sozinho e **nunca cobre o alvo central**. O modo de cena (com a seta `▼`) fica pronto no componente, mas só é usado na 6b.
- **Texto letra a letra** (28 c/s por padrão, com pausas na pontuação) e **blip de voz a cada 2 letras**, com a nota mudando pela vogal. Cada personagem tem seu timbre e sua velocidade. O som é **sintetizado pelo nosso gerador**, sem amostra de fora. O volume fica cerca de 8 dB abaixo do soco.
- **Acelerar e pular:** clique **fora do alvo** ou ESPAÇO completa a fala. Segurar ESC por 0,5 s pula a abertura inteira. O clique no saco **nunca** é consumido pelo balão.
- **Nenhuma mecânica depende de ler.** Toda informação de jogo (garagem salva, luva nova, luta marcada) também aparece na interface.
- Todos os valores (velocidades, pausas, timbres, intervalos) ficam em `data/`.

### 3.2 O 1º lutador
- Nome (proposto pelo Roteirista), visual (o sprite atual com os rostos `bite` e `smile` novos) e **gesto A, "fecho e dois toques"**: ele puxa o fecho da luva com os dentes (`rrrip`) e dá dois toques de punho, sempre com 0,22 s entre eles.
- Onde o gesto aparece na 6a (tabela de `gesto-assinatura.md`):
  - na **abertura**, versão completa;
  - no **começo de toda luta da campanha dele**, versão completa, **dentro dos 1,5 s de entrada que já existem**;
  - na **vitória**, versão curta, dentro do tempo de saída;
  - ao **calçar luva nova**, versão completa, uma vez por luva;
  - com a **garagem parada** (20 s sem clique), versão curta, a cada 30–60 s.
- **Qualquer clique cancela o gesto no mesmo quadro.** O gesto não soma nenhum segundo à luta.

### 3.3 O treinador original
- Personagem fixo na garagem, num ponto próprio que não é de gerador e não cobre o alvo. Tem 3 folhas: parado, olhar para o lado e falar.
- **Comentários contextuais** sobre compra marcante, caixa aberta, vitória, derrota, luta marcada perto, luva nova e o treino parado. As falas são curtas e não explicam regra.
- **Controle de frequência** (o Designer fecha os números dentro destes limites):
  - no mínimo 60 s entre dois comentários; a meta é cerca de 1 a cada 90–120 s de sala;
  - nada de comentário na luta, com janela aberta, no dia de luta parado ou enquanto outro balão está na tela;
  - cada fala é **única da escola** (toca uma vez na vida do save) ou **repetível com descanso** (não volta na mesma campanha nem na seguinte);
  - quando duas falas disputam o mesmo momento, toca a mais importante e a outra é descartada, não guardada para depois.
- O treinador também fica nas campanhas seguintes, com falas que reconhecem o passado ("da outra vez...") em vez de repetir as da Carreira 1.

### 3.4 Abertura (prólogo)
- Toca **só no save novo**, ou uma vez no save antigo. **No máximo 20 s**, e o saco aceita clique em **até 3 s** depois que a sala aparece.
- Precisa passar 3 ideias: **a garagem está em dificuldade** (o aviso na parede), **o treinador tem um sonho** e **o 1º lutador foi humilhado e quer provar o valor dele**.
- **Forma da humilhação:** o Roteirista propõe 2 ou 3 opções e o dono escolhe jogando. Limites:
  - contada em até 3 balões mais 1 objeto na parede, sem cena de luta;
  - sincera e nunca cruel, sem humilhar o jogador;
  - sugestão do Diretor: ligar a humilhação ao **dono do cinturão amador** (Seu Muralha ou um adversário da escada). Assim o 1º cinturão salva a garagem e também fecha a revanche **da escola**.

### 3.5 Arco 1 — Salvar a garagem (narração pelo cenário)
| Objeto | Quando aparece | Quando sai |
|---|---|---|
| **Aviso de cobrança** na parede | desde o começo | quando a garagem é salva |
| **Foto antiga** (treinador jovem) | desde o começo, fica sempre | nunca (ir para a academia é da 6c) |
| **Recorte de jornal** | 1ª vitória da escola depois da 6a | fica |
| **Foto da equipe** e **símbolo da escola** pintado (proposta: a lâmpada, 5x5 px) | garagem salva | ficam |
- Os objetos **ficam entre campanhas** e são gravados nos marcos da escola.
- O símbolo aparece **só na parede**. Na roupa dos discípulos, fica para a 6c.

### 3.6 Diretor de Cutscenes (só documentos)
- Ajustar o storyboard da "Primeira sucessão" ao nome, à voz e à humilhação escolhidos.
- Fazer a **prancha de quadros-chave** (animatic) das duas cenas centrais, junto com o Diretor de Arte. O dono aprova a prancha antes da 6b.
- Afinar os timbres com o Programador e revisar se os comentários atrasam o treino.

## 4. O que fica de fora
| Item | Fase |
|---|---|
| Player de cena por dados, `data/cutscenes/`, botão PULAR com anel e modo de cena do balão em uso | 6b |
| Cena "Primeira sucessão", gesto ao contrário (tirar a luva) e 1º lutador como mentor na garagem | 6b |
| Personalização (nome, pele, cabelo, calção) e textos "passar o posto", "nova campanha" e "receber novo discípulo" | 6b |
| Porta de enrolar (sprite e sons) | 6b |
| Chegada à academia, foto antiga indo para a academia, saída do 1º mentor, mural/hall e Honra | 6c |
| Símbolo na roupa dos discípulos e comentários sobre a arte escolhida | 6c |
| Rival | 8a |
| Opção de desligar comentários ou blips e volume separado de voz | 13 |
| Qualquer mudança de economia, preço, luta ou calendário | — (não é desta fase) |

## 5. Critérios de aceite
1. **Save novo:** a sala aparece e o 1º soco no saco vale em ≤ 3 s. A abertura acaba em ≤ 20 s e segurar ESC 0,5 s pula tudo, com o mesmo estado final.
2. **Fechar o jogo no meio da abertura** (ou pular) e abrir de novo: a abertura não toca outra vez.
3. **Sem ler nada:** o QA joga a Carreira 1 inteira com os balões escondidos (opção de teste) e consegue treinar, comprar, abrir a caixa, lutar, ganhar o cinturão e entender que a garagem foi salva pelo selo na tela de vitória.
4. **Fala:** letra a letra a 28 c/s, um blip a cada 2 letras, sem blip na fala completada pelo clique. O 1º lutador e o treinador são reconhecíveis de olhos fechados (o dono valida). O clique no saco nunca é consumido por um balão.
5. **O balão nunca cobre o alvo central.** O `ui_audit` dá **0 problemas** nos 6 estados de `linguagem.md` §7.1, mais o balão do treinador e do 1º lutador na garagem e na academia.
6. **Gesto:** aparece no começo de toda luta da Carreira 1 e não aparece da Carreira 2 em diante. A **duração da luta é a mesma** de antes (medida igual à da 5.x). Qualquer clique cancela o gesto no mesmo quadro. Toca na vitória, ao calçar a luva e com a garagem parada.
7. **Treinador:** numa Carreira 1 de 10–15 min, toca entre 5 e 10 comentários. Nunca há dois em menos de 60 s, nenhum se repete na campanha e nenhum toca na luta, com janela aberta ou no dia de luta.
8. **Arco 1:** o aviso está na parede desde o início. O recorte aparece depois da 1ª vitória. No 1º cinturão amador (de qualquer carreira), o selo aparece; na volta à garagem, o aviso saiu, a foto da equipe e o símbolo estão lá e o treinador comenta uma vez. Nas campanhas seguintes, o aviso e a abertura **nunca voltam**.
9. **Save antigo com várias carreiras** (cópia de teste): a abertura toca uma vez, a campanha atual é a do 1º lutador e o Legado, a árvore, os atributos e o calendário ficam iguais. A garagem é salva no próximo cinturão.
10. **Nada mudou no balanço:** a simulação da 5.4 dá os mesmos números (23b, 1ª derrota em 10–15 min, cinturão entre a 2ª e a 4ª campanha, tempo morto). Nenhum segundo foi somado à luta ou ao calendário.
11. Os testes de marcos usam **save de teste**, nunca o save real. As janelas de teste abrem com `--position 1950,40`.

## 6. Riscos
- **A história atrasar o treino** (o maior risco). Proteção: a sala nunca sai de cena, o clique no saco sempre vale, o balão é passivo, a frequência é limitada e o gesto é cancelável. O critério 3 testa isso.
- **Repetição entre resets.** Proteção: os marcos da escola ficam no save, as falas são únicas ou têm descanso, o treinador tem falas de "já vimos isso" e o critério 8 cobre o resto. Ponto a vigiar: o dono faz muitas campanhas curtas, então o banco de falas repetíveis precisa ser maior do que parece. O Roteirista entrega pelo menos **3 variantes por gatilho repetível**.
- **Blip cansativo** num jogo de cliques rápidos. Proteção: volume baixo, nada de blip na fala completada e poucos balões. Se o dono reclamar, a opção de desligar sobe da 13 para a 6b.
- **Gesto demais.** São 15–25 vezes na Carreira 1. Com a garagem parada ele só usa a versão curta; se cansar, o primeiro corte é esse.
- **Garagem salva vista fora do momento:** o cinturão leva direto à academia. Por isso existe o selo na hora e a mudança na volta. Na 6b, a sucessão e esse comentário podem cair no mesmo começo de campanha; a fila da 6b resolve.
- **Save antigo estranho:** a "Carreira 7" seria a do 1º lutador. É aceitável até a 6b, e na 6b os textos de campanha podem esconder o número.
- **Fonte:** as minúsculas acentuadas da 5x7 precisam existir e ler bem. Se faltar alguma, isso trava o sistema de fala inteiro, então o Diretor de Arte confere primeiro.
- **Fase grande demais em arte.** Ordem de corte, se precisar: (1) o gesto ao calçar luva, (2) o símbolo na parede (vai para a 6c), (3) o gesto com a garagem parada. **Não se cortam** o sistema de fala, o gesto na luta, o treinador, a abertura e o Arco 1.

## 7. Papéis
| Papel | Entrega |
|---|---|
| **Roteirista** | Nomes do 1º lutador, do treinador e da escola, com 2–3 opções cada e uma recomendação. Uma linha descrevendo a voz de cada um. 2–3 formas da humilhação. Falas da abertura (até 4 balões). Banco de comentários do treinador (únicos e repetíveis, com 3 variantes por gatilho repetível) e falas de "já vimos isso" para as campanhas seguintes. Texto do selo "garagem salva" e da luva "o par dele". Atualizar `narrativa.md`, onde o protagonista ainda está "sem nome". Arquivo: `docs/fases/fase6a-textos.md`. |
| **Designer** | Gatilhos, prioridades e intervalos dos comentários, dentro dos limites da seção 3.3. Lista dos marcos da escola e o que cada um grava. Regras do save antigo (seção 2, item 4). Confirmar que o gesto cabe em `intro_seconds`/`outro_seconds` sem mudar a luta. Rodar a simulação de não-regressão. Arquivo: `docs/fases/fase6a-design.md`. |
| **Diretor de Cutscenes** (Fable) | Timbres finais junto com o Programador. Storyboard da sucessão ajustado. Prancha de quadros-chave junto com o Diretor de Arte. Revisar a abertura com a regra "o gesto antes da fala". |
| **Artista de Personagens** | Rostos `bite`/`smile`, fita do fecho, folhas `fighter_gesture(_short)` e `fight_player_gesture(_short)` com todos os sufixos de luva (até L4), `bite_frame`/`tap_frames` no manifest. Treinador com 3 folhas. Paleta do "discípulo padrão". Tudo pela skill `padrao-personagem`. |
| **Diretor de Arte** | Balão (9-slice, rabicho, plaquinha de nome). Conferir as minúsculas acentuadas da fonte 5x7 **antes de tudo**. Aviso de cobrança, foto antiga, recorte, foto da equipe e símbolo 5x5. Prancha de quadros-chave com o Artista e o DC. |
| **Programador** | Sistema de fala (letra a letra, pausas, blip por 2 letras com nota por vogal, timbre e velocidade por personagem, completar, guardas de clique), com tudo em `data/`. Sons no `make_sfx.gd`: `voice_<timbre>`, `strap_rip`, `tap_glove`. Gesto na luta, na vitória, ao calçar luva e com a garagem parada, sempre cancelável. Treinador com a fila de comentários. Abertura. Objetos do Arco 1. `school.milestones` fora do reset, migração do save antigo e testes em save de teste. Opção de teste para esconder balões (para o critério 3). |
| **UI/UX** | Layout do balão passivo nos 6 estados e na garagem e na academia, com a regra de nunca cobrir o alvo. Selo "garagem salva" na tela de vitória. `alinhamento-ui` com 0 problemas. |
| **QA** | Critérios 1–11, com atenção especial ao 3 (sem ler), ao 6 (luta com a mesma duração) e ao 9 (save antigo em cópia). |

## 8. O que o dono valida quando jogar
1. **Nomes** do 1º lutador, do treinador e da escola, escolhidos entre as opções do Roteirista.
2. **Forma da humilhação** e se a abertura passa a ideia em até 20 s sem tirar a vontade de clicar.
3. **Vozes:** se dá para reconhecer o 1º lutador e o treinador pelo blip, e se o blip incomoda.
4. **Gesto "fecho e dois toques":** se lê no boneco, se o som é marcante e se cansa ou não.
5. **Frequência do treinador:** se é pouco, bom ou demais.
6. **Garagem salva:** se o momento (selo mais a volta à garagem sem o aviso) emociona o suficiente, e se o símbolo da lâmpada serve.
7. **Discípulo padrão** da Carreira 2+ até a 6b: se a troca de paleta serve como ponte.
8. **Save dele:** se a campanha atual virar a do 1º lutador funciona para ele.
9. **Prancha de quadros-chave** da sucessão e do reencontro, que destrava a 6b.

## 9. Perguntas abertas (não travam o começo)
- Os comentários devem dar alguma dica leve de jogo (ex.: "fica verde, vai")? Recomendo **não**: as dicas continuam na interface e o treinador só reage.
- O treinador fala também na academia, ou só na garagem? Recomendo **os dois lugares, com menos falas na academia**. A presença dele ao longo da história é decidida na 6c.

## Resumo para o Produtor
- A 6a dá voz à garagem: balão preso ao personagem com blip original, o 1º lutador com nome e o gesto "fecho e dois toques", o treinador comentando de vez em quando e uma abertura de até 20 s em que o saco já aceita clique em 3 s.
- O Arco 1 é contado pela parede: aviso de cobrança, foto antiga, recorte, e no 1º cinturão amador da escola o selo "garagem salva", a foto da equipe e o símbolo. Nada disso se repete depois de um reset.
- No save do dono, a campanha atual passa a ser a do 1º lutador e a abertura toca uma vez. Economia e lutas não mudam.
- O dono valida jogando: os nomes, a humilhação, as vozes, o gesto, a frequência das falas, o momento da garagem salva e a prancha que destrava a 6b.

## Escolhas do dono (2026-11-13)
- 1º lutador: **John Bullet** (fixo; vira mentor e é o último adversário).
- Treinador: **Osmar Brandão**.
- Escola: **Raízes Fight Club** (o dono escreveu "Raizes"; usar "Raízes" com acento se a fonte 5x7 ler bem, senão "RAIZES").
- Humilhação: **A, "a ficha em branco"** (campo ESCOLA = "nenhuma", o Seu Muralha riu da ficha); a ficha amassada fica na parede e vira "ESCOLA: RAÍZES FIGHT CLUB" quando a garagem é salva.
