# FightClicker — Direção narrativa

**Versão:** 1.0  
**Data:** 10 de novembro de 2026  
**Finalidade:** registrar as decisões narrativas desta conversa e orientar o desenvolvimento futuro.  
**Status:** direção criativa validada; roteiro e implementação ainda em desenvolvimento.

Este documento descreve a direção desejada para a história. Não afirma que os sistemas narrativos já estejam implementados. Falas de exemplo são rascunhos, não texto final.

## 1. Princípio central

O gameplay é o foco: treinar, melhorar atributos, enfrentar adversários, encerrar uma campanha, investir Legado e começar com um novo discípulo.

A narrativa acompanha esse ciclo e dá significado ao progresso. Na maioria dos casos, será contada passivamente por comentários curtos, mudanças no cenário, objetos, fotografias e reações aos acontecimentos reais do jogo.

**Ideia central:** a escola guarda o que aprendeu; cada discípulo precisa construir a própria trajetória.

## 2. Decisões validadas

- Cada nova campanha acompanha um novo discípulo. O lutador anterior torna-se mentor.
- O primeiro personagem terá nome e aparência definidos pela equipe.
- A personalização de nome e aparência começa no segundo discípulo. Os personagens preservam sua identidade quando viram mentores.
- A origem envolve salvar a garagem, realizar o sonho do antigo treinador e provar o valor do primeiro lutador depois de uma humilhação.
- Cada carreira representa uma campanha como representante da escola. Ao perder ou decidir sair, o personagem passa o posto ao próximo discípulo.
- O primeiro lutador atua como mentor e depois se afasta para seguir sua própria vida.
- Ele continua evoluindo fora de cena e reaparece como o último adversário da história.
- Ele não é um vilão: representa o último mestre a superar e o início da linhagem encontrando seu resultado.
- O mundo começa simples e torna-se cômico e progressivamente absurdo.
- As relações entre treinador, mentores e discípulos permanecem sinceras.
- A história termina, mas o jogador poderá continuar em um modo infinito e terá acesso a um modo de sequência de combates inspirado em torres.

## 3. Premissa e origem

A garagem é um pequeno lugar de treinamento em dificuldade. Seu treinador sonha em formar um grande campeão. O primeiro lutador quer ajudar a preservar esse espaço e provar seu valor depois de ter sido humilhado.

A forma exata da humilhação, a origem das dificuldades financeiras e os nomes dos personagens ainda não estão definidos. A abertura deve comunicar o necessário rapidamente e permitir que o jogador comece a treinar.

Salvar a garagem é um marco permanente da história. A dificuldade inicial não deve reaparecer como se nada tivesse acontecido em cada campanha.

## 4. Relação com o ciclo de gameplay

### 4.1 Campanha, derrota e passagem do posto

Uma carreira é uma campanha pelo circuito como representante da escola. A derrota encerra essa tentativa; a saída voluntária permite passar o posto antes disso. O lutador assume a formação de um sucessor, mas não fica impedido de treinar ou competir por conta própria.

Essa interpretação explica como o primeiro personagem pode encerrar sua campanha pela escola e posteriormente chegar ao topo por outro caminho.

Termos como **“passar o posto”**, **“nova campanha”** e **“receber novo discípulo”** são candidatos para a interface. A substituição dos textos atuais ainda precisa ser decidida.

### 4.2 O que recomeça e o que permanece

| Elemento | Tratamento narrativo |
|---|---|
| Atributos, dinheiro e conquistas da campanha | Pertencem ao discípulo atual e recomeçam conforme as regras do jogo. |
| Equipamentos e melhorias da campanha | Seguem o reset atual; a justificativa visual da recompra precisa ser refinada. |
| Legado e habilidades permanentes | Representam conhecimento transmitido pela linhagem. |
| Garagem salva e acontecimentos da história | Permanecem concluídos. |
| Fotos, troféus e recordações | Registram a história da escola entre campanhas. |
| Entrada na academia | É uma etapa alcançada pelo discípulo, não o abandono definitivo da garagem. |

Todo discípulo começa sua formação na garagem. O avanço até a academia é individual. Assim, voltar ao espaço inicial não significa que a escola perdeu tudo.

**Pendência importante:** a compra repetida de aparelhos é a parte menos natural dessa interpretação. Uma proposta é apresentar o gasto como preparar ou liberar uma estação de treino para aquela campanha. Essa solução ainda não está validada e não deve ser tratada como mudança aprovada de mecânica.

### 4.3 Progresso narrativo permanente

Salvar a garagem, conhecer personagens, acompanhar o afastamento do primeiro mentor e chegar pela primeira vez a novos patamares são acontecimentos únicos da escola.

As campanhas posteriores podem repetir a subida competitiva, mas os comentários reconhecem o passado. Não repetir a mesma abertura, despedida ou conquista narrativa como se fosse a primeira vez.

Esse acompanhamento permanente precisará ser implementado; este documento não define formato de save ou arquitetura técnica.

## 5. Personagens e funções

### Primeiro lutador

Protagonista inicial fixo, primeiro mentor e último adversário. Deve possuir identidade reconhecível: nome, aparência e um gesto característico. Esses detalhes ainda serão criados.

Sua ajuda à garagem e aos primeiros discípulos é sincera. Seu afastamento deve parecer uma conclusão natural daquela etapa da vida, sem enquadramento ameaçador ou promessa explícita de retorno.

Proposta de gatilho: sair depois de conviver com ao menos um sucessor e de a escola atingir um marco relevante. O momento exato ainda precisa ser definido e deve funcionar mesmo quando a primeira campanha for curta.

### Treinador original

Origem afetiva da escola e ligação com a garagem. Seus comentários podem reconhecer compras, derrotas e conquistas, além de antecipar o mundo extraordinário por meio de histórias que parecem exageradas.

Sua permanência durante toda a história, aparência e relação específica com o primeiro lutador ainda precisam ser detalhadas.

### Discípulos e mentores

Os personagens criados pelo jogador dão identidade à linhagem. Os mentores podem comentar seus próprios resultados e reconhecer quando um sucessor supera sua marca ou vence quem os derrotou.

O número de mentores simultaneamente presentes no cenário e a forma de consultar o histórico completo permanecem em aberto.

### Rival recorrente

Arco proposto e aprovado em direção: um lutador de academia tradicional começa menosprezando a escola, aprende a respeitá-la e pode terminar como parceiro de treino.

Sua rivalidade é com a escola, permitindo continuidade entre diferentes discípulos. As reações devem depender dos resultados reais; não presumir vitórias ou derrotas que não aconteceram.

Nome, visual, adversário correspondente no elenco atual e eventual função mecânica ainda precisam ser definidos.

## 6. Estrutura dos arcos

### Arco 1 — Salvar a garagem

**Função:** estabelecer a origem afetiva, o sonho do treinador e a motivação inicial.

A sala começa improvisada, com equipamentos remendados e sinais de dificuldade. Compras trazem pessoas e movimento. Vitórias deixam registros nas paredes. Um marco posterior confirma que o lugar foi preservado.

Exemplos de narrativa ambiental: aviso de cobrança, fotografia antiga, primeiro recorte de jornal, retirada do aviso e foto da equipe.

A conquista pertence à escola. Não exigir que o primeiro lutador pessoalmente vença o cinturão para a história avançar.

### Arco 2 — Um lugar nosso

**Função:** apresentar a academia e a escolha de um caminho próprio nas artes marciais.

O primeiro acesso à academia recebe um tratamento especial, com referências visuais à garagem. Nas campanhas seguintes, chegar ali representa o avanço do novo discípulo.

A escolha da arte reforça que o sucessor pode aprender com o mentor e lutar de outra maneira. Os comentários não devem apresentar uma arte como a escolha moralmente correta.

Esse arco oferece uma janela para o afastamento discreto do primeiro lutador. O gatilho definitivo permanece em aberto.

### Arco 3 — Mais longe que eu

**Função:** dar significado à repetição das campanhas e às superações entre gerações.

Mentores reconhecem adversários que os venceram, diferenças de estilo e novos recordes. O cenário acumula memórias dos feitos da escola.

Exemplo de fala ao superar o melhor resultado anterior:

> “Daqui pra frente, você vai ter que contar pra gente como é.”

Proposta de apresentação: um mural com marcos selecionados e histórico opcional. Sua forma final ainda será definida.

### Arco 4 — Nosso nome no circuito

**Função:** mostrar reconhecimento externo e desenvolver o rival recorrente.

Cartazes, recortes e comentários revelam que a escola deixou de ser desconhecida. O rival começa arrogante e passa a se preparar especificamente para enfrentar seus discípulos.

O arco se encerra com respeito e possível aproximação. A transformação em parceiro de treino depende de encaixe futuro no gameplay.

### Arco 5 — As histórias do velho

**Função:** levar o mundo ao absurdo de forma gradual.

Histórias antigas do treinador começam a ser confirmadas por arenas e adversários. Surgem métodos impossíveis de treino, ciborgues, animais competidores e mestres lendários.

A academia também reage à escala: equipamentos reforçados, rachaduras, reparos e comentários cômicos. Os vínculos cotidianos preservam a familiaridade do lugar.

O arco culmina no acesso ao último patamar de competição. Lugares, quantidade de circuitos e adversários ainda serão definidos conforme o gameplay crescer.

### Arco 6 — Até onde chegamos

**Função:** concluir a história da linhagem com o reencontro entre o primeiro lutador e um sucessor distante.

A existência do último desafio deve ser estabelecida antes da chegada, sem transformar a identidade de seu adversário numa investigação constante.

Na apresentação da última luta, o jogador reconhece nome, aparência e gesto do primeiro personagem. Ele continuou treinando durante a ausência e chegou ao topo.

A luta é séria, mas não representa vingança ou confronto com um criminoso. O primeiro mestre testa aquilo que as gerações posteriores aprenderam.

Falas de rascunho:

> “Então vocês chegaram.”
>
> “Quero ver o que aprenderam.”

Possível troca após a vitória:

> Mestre: “Essa eu não te ensinei.”  
> Discípulo: “Você ensinou quem me ensinou.”

O encerramento pode ser uma fotografia do reencontro no mural, próxima à imagem da garagem. Falas, coreografia e desfecho visual ainda não são definitivos.

## 7. Tom, humor e adversários

O mundo começa com humor de bairro e escala para situações extraordinárias tratadas com crescente naturalidade. As relações da escola conservam afeto e sinceridade.

Direções de elenco discutidas:

- Adversários locais caricatos.
- Veteranos e astros de luta com personalidade exagerada.
- Um ciborgue de estética cyberpunk.
- Um urso competidor.
- Mestres de técnicas e métodos impossíveis.
- Personagens originais que parodiam convenções de filmes de luta, incluindo o arquétipo de herói do boxe associado a Rocky.

Esses exemplos não constituem elenco fechado. A direção é criar personagens próprios; não foi definido incluir Rocky Balboa literalmente.

Recomendação de design: cada adversário combinar uma ideia cômica reconhecível com um perfil de combate legível. O humor também pode aparecer em fichas, regulamentos, objetos e comentários após a luta.

## 8. Narração passiva

### Canais principais

1. **Comentários contextuais:** compras, derrotas, vitórias, escolha da arte e superação de marcas.
2. **Cenário:** fotografias, reparos, objetos e lembranças permanentes.
3. **Comportamento:** chegadas, saídas, gestos e pequenas ações dos personagens.
4. **Adversários:** apresentações curtas e reações que reconhecem encontros anteriores.
5. **Conteúdo opcional:** possibilidade de consultar fotos, objetos ou histórico, ainda a definir.

### Regras de apresentação

- Evitar falas a cada compra ou clique. Usar espaçamento e controle de repetição.
- Fazer comentários coerentes com o que realmente aconteceu naquela campanha ou na escola.
- Manter informações necessárias ao gameplay explícitas; as pistas narrativas podem ser sutis.
- Não exigir leitura de diálogos para compreender uma mecânica.
- A história deve avançar por marcos, não exigir um número fixo de derrotas.
- Não repetir cenas únicas após cada reset.
- Dar histórias e relações próprias aos personagens presentes, sem centrar a narrativa no primeiro lutador ausente.

## 9. Cutscenes

A direção aceita poucas cenas curtas, puláveis, preferencialmente feitas com os próprios cenários e personagens. A seleção abaixo é a proposta de trabalho; durações são estimativas.

| Momento | Função | Duração sugerida |
|---|---|---|
| Primeira sucessão | Mostrar a passagem de responsabilidade e introduzir o novo discípulo. | 10–15 segundos |
| Primeira chegada à academia | Valorizar a conquista e preservar a conexão com a garagem. | 10–15 segundos |
| Reencontro final | Dar espaço ao reconhecimento do primeiro personagem. | 15–25 segundos |
| Vitória final | Encerrar o arco da linhagem e deixar uma lembrança no cenário. | 15–20 segundos |

Prioridades narrativas: primeira sucessão e reencontro final.

A saída do primeiro mentor deve ser discreta. Uma despedida excessivamente dramática anteciparia sua importância futura. Chegada do rival e colocação de objetos no mural podem acontecer sem retirar o controle do jogador.

## 10. Pós-jogo

### Direção validada

Depois de concluir a história, o jogador pode continuar num modo infinito e desbloqueia um modo de sequência de combates inspirado nas torres de Mortal Kombat.

### Hipóteses ainda não validadas

- Inimigos do infinito gerados por combinações de aparências, nomes, atributos e traços preparados à mão.
- Recorde do infinito pertencente à escola.
- Torre curta, inicialmente com cinco adversários.
- Entrada com os atributos atuais, sem treino ou compras entre andares e com ajuste de tática permitido.
- Derrota na torre encerrando apenas a tentativa, preservando a campanha.
- Recompensas cosméticas, troféus e decorações; bônus de poder exigem avaliação de balanceamento.

O procedural precisa ser testado quanto a variedade, legibilidade e equilíbrio. O infinito precisa preservar a utilidade do prestígio: formar outro discípulo deve continuar sendo uma decisão interessante.

Não implementar essas hipóteses como requisitos aprovados sem validação adicional.

## 11. Ideias substituídas

As seguintes propostas anteriores não fazem mais parte da direção atual:

- Primeiro lutador como vilão secreto, controlador do circuito ou responsável por crimes.
- Destruição da garagem e morte do treinador como motivação para o final.
- Investigação central sobre a identidade do primeiro lutador.
- Personalização do primeiro personagem.
- Mudança definitiva da escola que elimine a função da garagem nas campanhas seguintes.

O primeiro lutador é o adversário final e antigo mentor. A surpresa é o reencontro e a dimensão de sua evolução.

## 12. Pendências e próximos passos

### Decisões criativas

- Nome, visual, personalidade e gesto característico do primeiro lutador.
- Identidade do treinador original e sua presença ao longo do tempo.
- Forma da humilhação inicial e marco que confirma a garagem salva.
- Passagem de tempo entre campanhas e envelhecimento visual dos personagens.
- Explicação e apresentação da recompra dos aparelhos.
- Gatilho exato para o afastamento do primeiro mentor.
- Nomes, estilos e integração do rival e dos demais adversários.
- Roteiro definitivo das cenas e do encerramento.

### Trabalho de design e implementação

1. Mapear os arcos aos marcos e sistemas que já existem no jogo.
2. Separar acontecimentos únicos da escola de reações repetíveis por campanha.
3. Especificar os gatilhos, prioridades e intervalos dos comentários.
4. Definir quais lembranças visuais persistem após cada reset.
5. Projetar a personalização a partir do segundo discípulo e a continuidade visual dos mentores.
6. Prototipar a primeira sucessão e um pequeno conjunto de comentários contextuais.
7. Testar se a narrativa permanece compreensível sem atrasar o treino.
8. Desenvolver e validar o pós-jogo separadamente.

### Critérios de coerência

- A história funciona mesmo se a primeira campanha terminar cedo.
- O jogador que vence rapidamente não precisa perder de propósito para avançar a narrativa.
- O reset não apaga acontecimentos ou vínculos já estabelecidos.
- O primeiro lutador é lembrado sem dominar a história durante sua ausência.
- A revelação final funciona pelo reconhecimento, sem exigir longas explicações.
- As sugestões em aberto continuam identificadas como propostas até serem aprovadas.

