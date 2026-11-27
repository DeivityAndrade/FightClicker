# Polimento 1: o que o dono sentiu jogando (antes do escopo)

Anotado pelo Produtor em 2026-11-27, depois de o dono jogar um pouco. Serve de base para o Diretor escrever o escopo da mini fase
de polimento. Ela entra antes da implementação da 8b1, porque mexe no que o jogador sente toda hora.

## O que o dono pediu
1. **Os aparelhos próprios das artes não dão vontade de usar.** Os aparelhos do Boxe, do Jiu-jitsu e do Muay Thai "não estão
   satisfatórios o suficiente para eu querer usar eles".
   - O Designer descobre por quê: pode ser o ganho, o custo, o que cada um faz de diferente ou o retorno na tela.
   - O Designer propõe o que faz o jogador querer cada um.
2. **Números pipocando: grandes só no crítico.** Hoje todos os números saem grandes e a tela vira uma sopa ("não consegue entender
   o que tem na tela, fica muito feio").
   - Regra: número normal pequeno e número grande só quando é crítico.
   - Os aparelhos das artes seguem o mesmo padrão dos outros aparelhos.
   - Vale para todos: sala, aparelhos das artes e luta.
3. **O Jiu-jitsu precisa de animação própria no chão.** Ele não deve ficar dando soco no boneco caído. Deve mostrar o jogo de chão
   do Jiu-jitsu (raspar, passar a guarda, montar, finalizar), no estilo da arte do jogo.
4. **O jogo está enxuto: mais coisa para comprar.**
   - Mais nós na árvore.
   - Mais itens na loja.
   - Mais coisas na aba de equipe.
   - O Designer mede tudo com o simulador, porque mais compra muda a curva.
5. **Bug: caixote invisível.** Numa campanha nova (a partir da 2ª ou 3ª), o ajudante que fica em cima do caixote aparece em pé num
   caixote que sumiu.
   - É bug: corrigir logo, sem esperar a fase.

6. **Zoom na árvore incremental.** O jogador aproxima e afasta quando quiser, com a roda do mouse e/ou botões + e −, e arrasta para
   andar pela árvore. O verificador de telas precisa cobrir o zoom mínimo e o máximo.
7. **Árvore maior e mais funda.** Mais níveis e ramos mais compridos, não só mais nós soltos. Isso se junta ao item 4.
8. **Comprar na árvore no meio da campanha.** Hoje o Legado só é gasto na troca de discípulo. O dono quer poder abrir a árvore
   durante a campanha, comprar, e o nó já valer na campanha atual. Não precisa começar outra.
   - **Decisão do dono (2026-11-27):** só o Legado **já guardado** pode ser gasto a qualquer hora. O Legado que a campanha atual
     vai render para o próximo discípulo entra só na sucessão, como hoje ("senão quebra o jogo").
   - Tudo passa pelo simulador, porque comprar mais cedo acelera a curva.
   - Os testes de "foto igual" não valem aqui, porque a regra muda de propósito.

9. **Auto-clique na árvore (2026-11-27).** Nós que dão um auto-clique, com o golpe saindo sozinho num ritmo que sobe aos poucos.
   - Só a partir de uma fase mais adiantada do jogo. Bem mais à frente, quem quiser quase não precisa clicar.
   - Opcional: clicar na mão continua ajudando.
   - O dono pediu cuidado. O Designer escolhe quando começa e o ritmo, mede com o simulador e garante que o auto-clique não toma o
     lugar da equipe nem fura o teto.
10. **Ressalva D1 da 8b1 (Designer).** No centro, o Jiu-jitsu cresce cerca de 2,5× mais rápido que Boxe e Muay Thai, porque o bônus
    da equipe da arte multiplica os Alunos. Por isso o campeão nacional fica bem mais fácil para o Jiu-jitsu. Rever isso junto com
    os aparelhos das artes (item 1).

## Cuidados
- Os itens 2 e 3 são visuais: a "foto igual" (`foto.gd`) não pode mudar.
- Os itens 1 e 4 mexem na economia: entram com simulador, mediana por arte e o teto de 10% dos minigames medido de novo.
- O dono pode mandar mais coisas. Elas entram aqui antes do escopo.
