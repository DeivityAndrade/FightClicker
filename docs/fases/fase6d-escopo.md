# Fase 6d — O que os testadores pediram: escopo

Produtor, 2026-11-18. Feedback dos testadores depois da 6c, triado com o dono (aprovado: "aprovo e podemos seguir").
Fase curta de polimento antes da 7a. Não muda economia, luta, save nem calendário.

## Entra
1. **Cutscenes com o lutador criado** (QA primeiro): o discípulo montado na tela de criação (pele, corte, cabelo,
   faixa, parte de cima, calção, meião, símbolo da escola) aparece certo em todas as cenas: primeira sucessão,
   chegada curta, chegada à academia, saída do John (garagem e academia), mentores sentados/em pé, mural.
   Bugs voltam para quem fez.
2. **Pop-up de descrição perto do cursor**: hoje a descrição das melhorias aparece longe, do outro lado da tela.
   Passa a ser um balão colado ao mouse (efeito, custo, o que muda), dentro da tela, sem cobrir o alvo nem o botão
   apontado. Vale para loja/melhorias, árvore (mapa) e hall.
3. **Números do treino por atributo, do tamanho do ganho**: nos aparelhos que treinam mais de um atributo (boneco do
   Jiu-jitsu e similares) hoje só pipoca um atributo. Cada clique mostra um número por atributo que subiu, na cor do
   atributo (`ui_tokens`), com o tamanho proporcional ao ganho (o maior grande, os outros menores), sem poluir:
   no máximo 3 números por clique.
4. **Tela principal maior (só com validação do dono)**: a sala ocupa quase a tela; painéis (loja, equipe, atributos)
   deixam de ser abas próprias e aparecem por cima da sala (gavetas que abrem e fecham, ou outro formato).
   **Primeiro mockup com 2–3 opções**; o dono escolhe; só então implementa (pode virar 6d2 se ficar grande).

## 6d2 — escolhas do dono (2026-11-18)
O dono viu os mockups (`docs/arte/fase6d-tela-opcoes.md`) e decidiu:
1. **Implementar a opção C (híbrido)**: HUD de hoje, atributos em miniatura, faixa fina embaixo com focos e LUTAR,
   loja/equipe num painel que entra pela direita com "FIXAR ABERTO"; atalhos L/E e tecla "só a sala".
2. **Repensar a sala larga, não só esticar**: "no fim você só aumentou o chão e as paredes". Com o espaço novo,
   reposicionar pessoas, equipamentos e elementos para ficar mais espaçado e bem distribuído — principalmente na academia
   (e a garagem também), mantendo o alvo central.
3. **Equipamento não comprado fica invisível**: nada de pontilhado/silhueta do aparelho que ainda não foi comprado.
   Ele só aparece depois de abrir a caixa.
4. **Tirar os textos inúteis ("bloat texts")** do jogo: legendas, linhas de ajuda e rótulos que não ajudam a decidir
   nada. Ficam só os que informam uma escolha ou um estado importante.

## Fica de fora
- **Minigame** → Fase 7a (treino especial da arte, de tempos em tempos). **Decisão do dono (2026-11-18): o minigame
  abre em uma tela própria**, não dentro da sala, num lugar que faça sentido na história. **É sempre opcional**: o
  jogador escolhe se quer ir (convite que ele aceita ou ignora); nunca obrigatório e sem punição por recusar.
- Mudanças de balanço, conteúdo novo, Muay Thai.

## Critérios de aceite
1. QA toca todas as cenas com pelo menos 6 visuais diferentes (todos os cortes, partes de cima, faixa, meião, símbolo,
   peles extremas) e não acha camada faltando, cor errada ou peça atravessando.
2. O pop-up aparece em até 0,15 s ao lado do cursor, nunca sai da tela, nunca cobre o item apontado, some ao tirar o mouse.
3. Num aparelho de vários atributos, cada clique mostra um número por atributo que subiu, com tamanho que acompanha o
   ganho; aparelho de um atributo fica igual ao de hoje.
4. Mockup da tela nova com 2–3 opções entregue ao dono antes de qualquer código da tela.
5. `tools/run_tests.ps1` verde (APPDATA temporário); `ui_audit` com 0 problemas; balanço idêntico
   (`tools/refatoracao/foto.gd` igual à main, porque nada de regra muda).

## Quem faz
- QA: item 1. Designer UI/UX: itens 2 e 3 (e a implementação do 4, depois da escolha). Diretor de Arte + UI/UX: mockup do 4.
- Programador: só se o item 3 precisar de dado novo do GameState (ganho por atributo por clique) — ver `docs/codigo/mapa.md`.
