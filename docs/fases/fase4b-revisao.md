# Fase 4b — Revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-06.
Li: `fase4b-escopo.md` (as respostas do dono prevalecem), `fase4b-design.md`, `fase4b-qa.md`, `fase4b-api.md`, `fase4b-textos.md` e as capturas `b4_inicio_marcas`, `b4_assist_socando`, `b4_chegada_esteira_poeira` e `b4_fim_dica_esteira`.
Corrigido depois do QA (informado pelo Produtor): B1 (o aviso do atributo trancado aparece sem passar o mouse, como "COMPRE A ESTEIRA"), B2 (api atualizada), B3 (os dois Shifts separados) e B6 (simulador). Verificador: 63 estados, 0 problemas. Todos os testes passam.

## Veredito
**Aprovado para mostrar ao dono.** Nada bloqueia. B4 e B5 foram resolvidos no texto (abaixo), sem mexer em número.

## A fase entrega a visão do dono?
| Pedido do dono | Entregue? | Como |
|---|---|---|
| Começa só com o saco | Sim | Save novo e toda NOVA CARREIRA: só o saco, duas marcas de fita com plaquinha (critério 1, captura `b4_inicio_marcas`) |
| Compra esteira e depois corda (resposta 1) | Sim | Esteira 500, corda 1.500 e "DEPOIS DA ESTEIRA" até lá. Compra com Treino, no ícone da aba TREINO |
| Zera a cada carreira (resposta 2) | Sim | Depois de derrota e de aposentadoria (critério 7). Da 2ª carreira em diante, os dois chegam em ~1:05–1:18 |
| Assistido só com o Shift segurado (resposta 3) | Sim | Soca enquanto segura e para ao soltar. Não existe liga/desliga nem preferência salva. Botão SEGURAR para quem só usa o mouse |
| Bem mais fraco que clicar | Sim | Clicar rende **12–15×** o assistido (4–5/s). Quem clica sem parar e segura o Shift tem resultado **idêntico** a quem não segura (critério 25): ele não soma com o clique |
| Não "quebrar" o jogo | Sim | Some com o Metrônomo, não funciona em luta nem nas janelas, Shift batido rápido não rende nada. As metas da Fase 4 continuam na faixa |

O que ficou bom:
- **A chegada tem festa:** queda, poeira, "CHEGOU: ESTEIRA!", e o foco vai direto para o aparelho novo. A sala fica mais cheia na frente do jogador.
- **As marcas de fita com plaquinha de papelão** contam a história sem precisar de tutorial. Combinam com o tom de bairro (ferro-velho, varal da vizinha).
- **A dica do fim fecha o ciclo:** "FALTARAM 126K DE RESISTÊNCIA" seguido de "COMPRE A ESTEIRA CEDO NA PRÓXIMA CARREIRA".
- **A ordem esteira → corda acertou:** quase ninguém perde mais à toa no Dudu (a 4/s, 34 → 4 de 400 jogadores).
- **A curva atrasa ≤ 1 min.** O tio, que a 5/s chegava cedo demais (4:39), agora entra na faixa (5:23).

## O que desvia da visão ou do escopo
- **Nada passou do escopo.** Não entrou nó de "começar com a esteira", nem opção de tecla, nem assistido offline. O personagem também não mudou.
- Pequenas diferenças de texto, todas aceitas:
  - o aviso do atributo trancado ficou "COMPRE A ESTEIRA" em vez de "COMPRE A ESTEIRA PARA TREINAR" (cabe no painel e diz o mesmo);
  - a corda mostra a marca na parede, onde ela fica pendurada, e não no chão. Faz sentido para uma corda.
- O preço aparece como "1.50K" (decisão do Produtor, igual ao resto do jogo).

## Decisões desta revisão (gravadas no escopo e no design)
- **B4 (critério 10): aceito o texto do Designer, sem mudar número.** O critério passa a ser: carreiras 2+ com os nós da derrota típica, os dois aparelhos em **≤ 2 min na mediana e no p90, a 4–5/s**. Lento (3/s): **p90 ≤ 2:30**. Quem não ganhou nós leva **no máximo o tempo da 1ª carreira**.
  - Medido: 1:05 / 1:20 (5/s), 1:18 / 1:36 (4/s), 3/s p90 2:21 → **fecha**.
  - Os piores casos (2:45 e 4:42) são de quem perdeu no Dudu sem nós. A carreira 2 dessa pessoa é igual à 1ª, e isso é justo.
  - Baratear a corda mexeria nos critérios 8 e 9 e no 23b, que está com margem curta. Trava: p90 acima desses limites volta ao Diretor.
- **B5 (revanche): o erro estava no texto da seção 8 do escopo.** A meta é a da Fase 4: **Dinho ≥ 80% e Muralha ≥ 60%**, com a L1. A 4b dá Dinho 92–93% e Muralha 79–94%, melhor que a Fase 4.
- **Design:** o parágrafo "O que não fecha" abaixo da tabela 9.7 e o item "Não fecha" do Resumo agora dizem que **tudo fecha** com a meta 23b nova. A linha do critério 10 foi atualizada, e o §2.3 passou a registrar a ordem real do array (saco, esteira, corda).

## Placeholders e pendências
- **Arte:** as marcas de fita, as silhuetas com cadeado, a poeira e a corda pendurada são placeholder do estúdio. Funcionam e estão alinhados, mas podem ganhar acabamento quando houver passe de arte.
- **Critério 18 (sessão de 30 min):** o QA cobriu 16:52 de jogo em 2 carreiras completas, sem erro. Faltam os 30 min corridos. O teste do dono ajuda a cobrir isso.
- **Teclado físico:** o QA usou entrada simulada. Segurar o Shift de verdade numa janela real só o dono vai testar (está no roteiro).
- **23b a 4/s com margem curta** (24,25% contra 25%). Rerodar com 400 jogadores sempre que mexer em `data/`.
- **Só assistido é lento:** vence o Dudu aos 10:44, mas só 7 de 16 vencem o Dinho na 1ª carreira, e o tempo morto chega a 24 min (p90). Foi aceito pelo pedido "bem menos eficiente" (R8), e o dono precisa saber disso.
- **Fica para a Fase 9:** trocar a tecla, opção de acessibilidade no menu e o assistido no progresso offline.
- `tests/qa_f4b_*.gd` são do QA e não entram no runner (estão documentados no relatório do QA).

## Roteiro de teste para o dono (~10 min)

**Antes de começar:** o seu save atual vira v5 e a carreira em andamento fica com os 3 aparelhos (ninguém perde nada). Para ver o começo novo, você vai aposentar essa carreira. Se quiser guardar o save como está, peça ao Produtor uma cópia antes.

### Parte A — sem F12 (~7 min)
1. **Abra o jogo.** A carreira em andamento continua com saco, esteira e corda, e com o mesmo foco e as mesmas melhorias.
2. **Clique em APOSENTAR e depois em NOVA CARREIRA.** Só o saco fica montado. No lugar da esteira há uma marca de fita no chão com a plaquinha "ESTEIRA 500 TREINO". A corda mostra "DEPOIS DA ESTEIRA". No painel da esquerda, Agilidade e Resistência dizem "COMPRE A ...".
3. **Clique na marca de fita da esteira.** Não ganha treino e o foco não muda. A aba TREINO abre e a linha da esteira pisca. Faça o mesmo no botão de foco trancado, embaixo: o resultado é igual.
4. **Clique no saco até juntar 500 de Treino** (menos de 2 min). Aperte COMPRAR na linha da esteira. Ela cai na sala com poeira e "CHEGOU: ESTEIRA!", e o foco vai para ela. O próximo clique já treina Resistência.
5. **Tente comprar a corda antes de juntar 1.500.** O botão fica apagado. Junte o Treino, compre e veja a corda chegar.
6. **Modo assistido.** Pare de clicar e segure o Shift. Depois de ~2 s aparece "ASSISTIDO" e sai 1 soco a cada 3 s, com número pequeno. Solte e ele para.
   - Segure o Shift e clique ao mesmo tempo: o assistido espera ("ESPERANDO A MÃO PARAR") e não soma nada.
   - Segure o botão SEGURAR com o mouse: faz o mesmo que o Shift.
   - Compare: 10 s clicando contra 10 s só segurando. A diferença tem de ser grande.
7. **Feche o jogo logo depois de uma compra e abra de novo.** O aparelho continua lá, e o Treino foi descontado uma vez só.
8. **Lute com o Shift segurado.** Na luta, na prévia e na tela de fim não sai nenhum soco assistido.

### Parte B — com F12, se quiser ver o resto (~3 min)
Aviso: o F12 mexe no seu save de verdade (multiplica o saldo). Use só no fim.
1. **Antes de usar o F12, abra a LOJA e passe o mouse no Metrônomo.** A caixa diz "AGORA: 1 SOCO A CADA 3.0 S COM SHIFT".
2. **F12 → SALDO x1000 → compre o Metrônomo.** O indicador vira "METRÔNOMO TOCANDO", o botão SEGURAR some e o Shift não muda mais nada. O Metrônomo soca sozinho e soma com o clique.
3. **Perca uma luta** (ou aposente) e comece uma NOVA CARREIRA. Volta a ser só o saco, e os dois aparelhos são comprados de novo, agora bem mais rápido. Se você perder por falta de Resistência sem a esteira, a dica do fim diz "COMPRE A ESTEIRA CEDO NA PRÓXIMA CARREIRA".

## Perguntas para o dono
1. **Segurar o Shift é confortável para quem tem tendinite?** Segurar uma tecla também cansa. Se incomodar, a Fase 9 (opções) pode trazer a escolha "tocar para ligar". Por enquanto ficou como você pediu.
2. **O ritmo do assistido (1 soco a cada 3 s) está pesado demais?** Quem só usa o assistido vence o Dudu aos 11 min e fica até 24 min sem novidade. É um número em `data/` e muda em segundos.
3. **Comprar os dois aparelhos a cada carreira ficou um ritual gostoso ou burocracia?** Se cansar, a correção é baixar o preço agora, ou um nó de árvore na Fase 7.

## Resumo para o Produtor
A Fase 4b está **aprovada para mostrar ao dono**. Toda carreira começa só com o saco, a esteira e a corda chegam com festa em poucos minutos, e tudo zera na NOVA CARREIRA. O modo assistido só soca com o Shift segurado, rende 12–15× menos que clicar e não soma com o clique, então não quebra o jogo.
Decidi o B4 aceitando o texto do Designer para o critério 10 e esclareci o B5 (Muralha ≥ 60%, como na Fase 4). Nenhum número mudou. Pendências: arte placeholder, os 30 min corridos e o Shift num teclado físico, que o roteiro do dono cobre.
Mostre ao dono o roteiro de ~10 min e as 3 perguntas (conforto do Shift, ritmo do assistido e se o ritual cansa).
