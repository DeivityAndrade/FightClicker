# Fase 5.4 — Árvore grande: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-13. Branch `fase-5.4`.
Li: `fase5.4-escopo.md` (com as decisões D1–D3), `fase5.4-design.md`, `fase5.4-api.md`, `fase5.4-qa.md` e as capturas `f54_mapa_inicio`, `f54_mapa_meio`, `f54_cartao_grito_sem_loja` e `f54_botao_hover`.
Depois do QA, o Produtor corrigiu o **B1** (o botão ÁRVORE do fim não abria depois de uma derrota, em `ui/fluxo.gd`; a reprodução do QA agora dá 23/0) e o **B3** (travessão em `career_card_title`). Os testes passam e o audit dá 183 estados com 0 problemas.

## 1. Veredito
**Aprovado.** A fase pode ir para o dono.
- Os 13 critérios de aceite passam. O único que tinha falhado (critério 1, na tela de fim depois de uma derrota) foi corrigido e tem uma reprodução automática.
- O balanço fecha com as metas novas das decisões D1 e D2. O QA rodou o simulador por conta própria e os números batem com o design.

## 2. A visão do dono foi entregue?
| Pedido do dono | Entregue? | Como |
|---|---|---|
| "Árvore estilo Fortune Mill" (mapa grande que se revela) | **Sim** | 39 nós, a maioria pequenos e baratos, com marcos. Comprar acende o nó e mostra os vizinhos na hora. Há regiões com nome e 4 ligações. Visual, nomes e formato são nossos: moldura de madeira, regiões com chão de textura (tijolo, terra, tatame, lona) e ícones próprios |
| "Escondida, clica para abrir" | **Sim** | Um botão pequeno no canto da garagem, fora do saco. A dica mostra "ÁRVORE / 2 NÓS PARA COMPRAR". O botão brilha só quando dá para comprar, e o mapa fecha com o X ou com Esc |
| Substitui as 3 abas | **Sim** | Não há mais abas na sala. CORPO, CAMPANHA e ESTILO ficaram no centro do mapa com os mesmos ids. O save antigo abre com tudo aceso |
| "Corda montada" | **Sim** | O nó `gar_rope` faz a campanha começar com a corda no lugar, sem caixa. A esteira e o aparelho da arte continuam chegando na caixa |
| Também pedido: +1 dia e Grito com a equipe | **Sim** | As 6 lutas ganham +1 dia. O Grito continua na LOJA, e o nó "Grito mais alto" avisa no cartão "PEDE O GRITO DA EQUIPE (LOJA)" |
| Kid menos fácil para quem espera o verde | **Em parte, como decidido (D1)** | Média de 79% na 1ª tentativa, e nenhum perfil abaixo de 50%. A 4/s ele continua fácil (92–96%). Quem decide se ficou justo é o dono, jogando |

### O que ficou bom
- **O mapa do meio da partida passa a sensação certa.** As regiões têm cor e chão diferentes, as linhas roxas mostram o caminho comprado e cada nó à vista tem preço. Dá vontade de ir para o próximo.
- **O cartão é claro.** Nome, frase de tom pé no chão ("A garagem inteira grita junto."), efeito em verde, aviso em laranja, preço e a faixa "VALE NA PRÓXIMA CAMPANHA". Nada fica cortado.
- **A regra "vale na próxima campanha"** está aplicada de forma limpa (foto da campanha em `active_nodes`) e não mexe no 23b.
- **O save** passou por 14 casos de save corrompido e pela migração v9 para v10 sem perder nada.
- **O balanço**: a árvore fecha na 6ª–7ª campanha (mediana), Boxe x Jiu-jitsu ≤ 10%, e nenhuma meta que "não pode piorar" piorou.

### Pontos de atenção (não bloqueiam)
- **A 1ª abertura do mapa é vazia demais.** São só 2 nós num campo escuro, com linhas tracejadas que somem no nada (`f54_mapa_inicio`). As linhas funcionam como pista de "tem mais", mas a 1ª impressão é pobre. Fica para o dono julgar (pergunta 1). Se ele estranhar, a solução barata é deixar os vizinhos de 1º grau como silhueta, sem nome nem preço. Isso pede um ajuste pequeno de regra numa fase futura, não agora.
- **O brilho do botão é sutil** (o QA também viu). Isso é de propósito, para não puxar o olho do saco. O dono decide.
- **Nomes diferentes para a mesma coisa.** A dica do botão diz "ÁRVORE" e o título do mapa diz "O QUE O VELHO TE ENSINOU". Eu aceito: o título dá tom e a dica dá função. Só anoto, caso o dono confunda.
- **A região AGENDA usa roxo, a mesma cor do Legado** nas etiquetas de preço. Não chega a confundir nas capturas. Fica de olho para o Diretor de Arte na fase 13.
- **O decimal "+0.5 S" usa ponto.** Já foi decidido. Fica igual ao resto do jogo.

## 3. Algo passou do escopo?
**Não.** Tudo o que veio a mais estava liberado pelo escopo ou foi aceito por mim na D3:
- `body_crew_2` 900 → 800, `career_good_loser` 800 → 700, a regra "nó de arte só vale na arte", as entradas dos ramos de arte como raiz, e os nós de fama e Legado (`camp_diary` é o **único** multiplicador de Legado da fase).
- **Efeitos novos dos marcos**: `start_generator` (5 Vizinhos), `gym_training_bonus` (Academia x2,5), `art_fight_bonus` e `legacy_bonus`. Isso é o "efeito novo e visível" que o escopo pediu para os marcos. Nenhum adianta Honra, personalização, história ou Muay Thai.
- `gar_metro` (Metrônomo começa no nível 2) usa um efeito que **já existia** (`metronome_start`). Não é o "Metrônomo/Shift" que ficou de fora.
- As travas `gym` e `art:*` ficaram separadas por id, para a 7b e a 8a. É preparo de dado, sem sistema adiantado. Está ok.

## 4. Pendências
### B2: o audit não cobre a tela de fim depois de uma derrota com a arena visível
**Não bloqueia. Vai para a lista.**
- O defeito real (B1) foi corrigido e tem uma reprodução automática (`tests/qa_f54_diag.gd`, 23/0). O B2 é um buraco de cobertura e não deixa o jogador sem ação hoje.
- **Condição para o merge na `main`:** a reprodução do B1 tem que rodar dentro do `tools/run_tests.ps1`, para não voltar sem ninguém ver. O estado novo do `ui_audit` ("fim depois de derrota, com arena") entra na **1ª tarefa da próxima fase que mexer na tela de fim ou na arena**.

### Tabela `f54dia` (corda + 1 dia)
**Aceita.** No relatório, o QA diz que o `f54dia` (96 x 10) terminou depois da entrega e bate com a tabela 5.8 do design:
- com o nó, a corda chega na mão aos 0:00; sem ele, aos 0:29–0:46;
- com +1 dia, 100% das campanhas ficam antes da data.

Os efeitos também estão cobertos por teste. Não peço mais nada.

### B4: os scripts `tests/qa_f54_*.gd` ainda não estão no repositório
O Produtor decide se eles entram no commit. Recomendo que entrem, porque são eles que guardam o B1.

## 5. O que fica para as próximas fases
| Item | Fase |
|---|---|
| História, diálogo, voz e cenas (mentor e rival) | **6a+** |
| Personalização e "receber novo discípulo" | **6b** |
| Honra, mural/hall e árvore do hall | **6c** |
| Kid a 4/s ainda fácil (92–96%) e Jiu-jitsu 3/s às vezes 1 campanha atrás. A alavanca é a força das artes, não a data do Kid | primeira fase que mexer nas artes (**7b**, Muay Thai, ou antes, se o dono pedir) |
| Região e nós do Muay Thai (a trava `art:*` já existe) | **7b** |
| Regiões do centro de treinamento em diante | **8a+** |
| Segunda arte (híbridos) | **9** |
| Zoom, mapa animado, som novo, revisão de cor (AGENDA x Legado) e silhuetas dos vizinhos na 1ª abertura (se o dono pedir) | **13** (Polimento) |
| "Vale na hora" em vez de "na próxima campanha" | só se o dono estranhar, com nova medição |
| Estado "fim depois de derrota" no `ui_audit` (B2) | 1ª fase que mexer na tela de fim ou na arena |

## 6. Roteiro de teste do dono (cerca de 8 min)
Use o save de sempre. O jogo já abre com o que você comprou antes.

1. **Save antigo (1 min).** Abra o jogo. Procure o botão pequeno com moldura no **canto de cima, à esquerda da garagem**. Passe o mouse: aparece "ÁRVORE" e quantos nós dá para comprar. Clique.
   - Valide: os nós que você já tinha estão acesos no meio, os vizinhos aparecem com preço e o Legado (no alto, à direita) está igual.
2. **Andar pelo mapa (1 min).** Arraste com o mouse e use a roda.
   - Valide: é confortável sem zoom? Dá para achar as regiões GARAGEM, AGENDA, ACADEMIA, BOXE e JIU-JITSU?
3. **Comprar (1 min).** Passe o mouse num nó. Leia o cartão e clique uma vez.
   - Valide: o nó acende e aparecem vizinhos novos na hora. Dá a sensação de "apareceu mais coisa"? O aviso "VALE NA PRÓXIMA CAMPANHA" incomoda ou faz sentido?
4. **Corda montada e Grito (1 min).** Ache "Grito mais alto" (entre a garagem e o boxe) e o nó da corda na GARAGEM. Compre a corda, se o Legado der.
   - Valide: o cartão do Grito avisa que ele precisa do Grito da LOJA?
5. **Fechar e voltar ao saco (30 s).** Feche com o X ou com Esc.
   - Valide: o relógio ficou parado enquanto o mapa estava aberto? Com tudo comprado, o botão para de brilhar? O brilho chama sem incomodar?
6. **Nova campanha (2 min).** Jogue até o fim da campanha (pode perder de propósito). Na tela "CAMPANHA ENCERRADA", clique **ÁRVORE**. O mapa tem que abrir (era o bug corrigido). Compre algo, feche e clique NOVA CAMPANHA.
   - Valide: se comprou a corda, ela já está montada na garagem, sem caixa? As datas das lutas parecem folgadas demais com o +1 dia (se comprou)?
7. **Kid (1–2 min, se chegar lá).** Na academia, lute com o Kid quando o indicador ficar verde.
   - Valide: foi uma luta de verdade ou fácil demais?

## 7. Perguntas para o dono
1. **O botão da árvore é fácil de achar** quando você tem Legado para gastar? O brilho chama o suficiente? E a 1ª vez que o mapa abre, com só 2 nós, pareceu vazio demais?
2. **AGENDA é um bom nome** para a região de Legado, dinheiro e +1 dia? O centro continua CAMPANHA. Se preferir, a alternativa é "EMPRESÁRIO".
3. **O Kid ficou justo?** Ficou mais difícil para quem espera o verde, mas quem clica rápido ainda passa fácil. Você quer que isso mude agora ou quando mexermos nas artes?

## Resumo para o Produtor
- **Aprovado.** A 5.4 entrega o que o dono pediu: um mapa grande e escondido que se revela a cada compra, no lugar das 3 abas, com corda montada, +1 dia e Grito mais alto. Nada passou do escopo.
- O B1 foi corrigido. O B2 (audit sem o fim depois de derrota) não bloqueia. Condição para o merge na `main`: a reprodução do B1 tem que rodar no `run_tests.ps1`. O `f54dia` foi conferido pelo QA (bate com o design).
- Para o teste do dono: 7 passos (cerca de 8 min) e 3 perguntas (botão fácil de achar, nome AGENDA, Kid justo).
- Ficam anotados: a 1ª abertura do mapa vazia, o brilho sutil e o Kid fácil a 4/s (para a fase das artes).
