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

## Cuidados
- Os itens 2 e 3 são visuais: a "foto igual" (`foto.gd`) não pode mudar.
- Os itens 1 e 4 mexem na economia: entram com simulador, mediana por arte e o teto de 10% dos minigames medido de novo.
- O dono pode mandar mais coisas. Elas entram aqui antes do escopo.
