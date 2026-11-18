# Fase 6d + 6d2: revisão do Diretor

Diretor de Jogo, 2026-11-18. Branch `fase-6d` (sem commit). Base: `fase6d-escopo.md`, `fase6d-qa.md`, as correções de B1 a B4
feitas depois do QA, as decisões O1 e O2 do Produtor, o código de `ui/garagem.gd`, `ui/painel_loja.gd` e `ui/barra_baixo.gd` e as capturas
`fase6d2_qa_*` e `fase6d_qa2_*`.

## Veredito

**APROVADA COM RESSALVAS.** Tudo o que o dono pediu está entregue e os critérios de aceite passam. As ressalvas são pequenas e
nenhuma bloqueia: duas dicas ainda não recebem o item apontado e a luz das pessoas que mudaram de lugar não foi refeita. Falta
também o dono confirmar com o mouse dele (veja abaixo).

## Pedido do dono x entregue

| Pedido | Situação |
|---|---|
| Opção C (HUD de hoje, atributos em miniatura, faixa fina com focos e LUTAR, painel pela direita com FIXAR, L/E/H) | Entregue. Testada pelo QA ao vivo (`qa_f6d2_tela.gd`, 0 falhas) |
| Sala larga repensada (não só esticada) | Entregue. Três fileiras (fundo, alvo, frente), alvo no centro, mentores à esquerda, porta livre. Na academia, a parede ganhou armários, porta, espaldar e o painel de horário. Já não parece só "mais chão" |
| Equipamento não comprado invisível | Entregue. Sem pontilhado nem silhueta: aparece a caixa e, depois de aberta, o aparelho |
| Sem textos inúteis | Entregue. Saíram legendas e rótulos; custo, falta de dinheiro, perigo e dias para a luta ficaram |
| Pop-up perto do cursor | Entregue. Aparece em 1 quadro, nunca sai da tela. Loja, mapa e hall não cobrem o item. A faixa, o HUD e a aba já recebem o item apontado (B2) |
| Números por atributo | Entregue. Um número por atributo, tamanho que acompanha o ganho, no máximo 3. Aparelho de um atributo continua igual |
| Cenas com o lutador criado | Entregue. 7 visuais, todas as cenas, 0 falhas. A passada por baixo da porta e a saída do John estão corrigidas |

## Correções depois do QA (conferidas)
- **B1:** o chip do assistido foi para x 146 e já não fica em cima do vizinho 2 (veja `fase6d2_qa_tela_fixado.png`).
- **B2:** os focos, o "?", PASSAR O POSTO, o HUD, os atributos, o mapa e o assistido passam o item apontado para `Dica.pedir`.
- **B3:** com 4 focos a dica "CLIQUE NO SACO" some (veja `fase6d2_qa_tela_academia.png`). Com 3 focos, ela cabe entre os focos e o "?".
- **B4:** a quebra no "/" agora é feita na hora de exibir.
- **O1 e O2:** o código bate com a decisão.
  - Durante o modo "só a sala", L e E saem desse modo e abrem o painel.
  - Na mesma aba, L ou E fecha o painel e solta o FIXAR. Na outra aba, só troca e o painel continua fixado.

## Nada da 7a foi adiantado
- Não há minigame nem convite em `scripts/`, `ui/`, `data/` ou `scenes/`. A única ocorrência de "convite" é um comentário sobre a animação do LUTAR.
- A economia não mudou: a foto de balanço é igual à da main, sem nenhuma diferença numérica. Também não entrou conteúdo nem Muay Thai.

## O que fica de pendência (não bloqueia)
1. **Duas dicas ainda sem o item apontado.** São o cartão recolhido da loja (`ui/painel_loja.gd:534`) e as dicas da sala, como a da
   caixa e a do mentor 2 (`ui/sala.gd:1172`). Hoje o balão evita só a ponta do cursor. O teste do QA não achou cobertura, mas o
   certo é passar o alvo. Fica para o UI/UX numa próxima passada.
2. **Luz das pessoas.** O vizinho da frente à esquerda e o Nelson ficaram um pouco claros ou escuros demais, porque a luz foi
   pintada para os pontos antigos. Fica para o Diretor de Arte, junto da 7a ou num polimento.
3. **Personagens atrás do painel fixado.** Com o painel fixado, o Nelson, o vizinho 3 e a ponta da esteira ficam escondidos. Foi
   aceito, mas vale ouvir o dono: se incomodar, o painel fixado pode encolher a sala em vez de cobrir.
4. **"/CLIQUE" ao lado do +N.** Desvia do texto do Roteirista, que pedia só "+1". Eu mantenho, porque ajuda a ler o número, mas é
   uma escolha do dono.
5. **Mouse real.** O balão foi testado com uma âncora fixa, não com o mouse real. Só o dono confirma a sensação.

## O que o dono deve testar com as próprias mãos (uns 10 minutos)
1. **Tela C.** Jogue 2 a 3 minutos na garagem.
   - Abra e feche a loja com L e a equipe com E.
   - Fixe o painel, clique no saco e veja que ele continua aberto.
   - Aperte H e depois L: deve sair do "só a sala" e abrir a loja.
   - Com o painel fixado na loja, aperte E: troca de aba e continua fixado. Aperte E de novo: fecha.
2. **Sala larga.** Contrate até a equipe ficar cheia e veja se as pessoas e os aparelhos parecem bem distribuídos e se nada da
   interface fica em cima de alguém. Faça o mesmo depois da mudança para a academia.
3. **Aparelho invisível.** Compre a esteira: deve aparecer só a caixa. Abra a caixa: aparece o aparelho.
4. **Balão.** Passe o mouse em cartões da loja, nos focos de baixo, no mapa e no hall. Veja se o balão gruda no cursor e não
   esconde o que você está apontando.
5. **Números.** Treine no boneco do Jiu-jitsu (ou em outro aparelho de vários atributos) e veja os 2 ou 3 números de tamanhos diferentes.
6. **Cenas.** Crie um discípulo bem diferente do padrão, por exemplo pele clara, coque, regata e faixa. Passe o posto e veja a
   chegada dele e a saída do John.

## Resumo para o Produtor repassar ao dono
- A 6d + 6d2 está **aprovada com ressalvas**: tela C, sala larga redistribuída, aparelho invisível até a caixa, menos texto,
  balão no cursor, números por atributo e cenas com o lutador criado.
- Os bugs do QA (B1 a B4) foram corrigidos. L/E/H e o FIXAR seguem as decisões O1 e O2. O balanço não mudou e nada da 7a entrou.
- Ficam pequenas pendências: duas dicas sem o item apontado, a luz de duas pessoas, gente atrás do painel fixado e o "/CLIQUE".
- O dono deve testar com o mouse: o painel, os atalhos, o balão e as cenas com um lutador bem diferente (uns 10 minutos).
