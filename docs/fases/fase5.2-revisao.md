# Fase 5.2 — Clique sem teto: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-12. Branch: `fase-5.2`.
Li: `fase5.2-escopo.md` (com as Decisões do Diretor), `fase5.2-design.md`, `fase5.2-api.md`, `fase5.2-qa.md`.

## Veredito: **APROVADO** para mostrar ao dono

- 12 de 12 critérios OK no QA (o 5 dentro do limite que eu aceitei, o 8 medido pelo controle, como decidido).
- Bateria inteira passando, `ui_audit` com 144 estados e 0 problemas, save real intacto.
- Nenhum bug funcional. A única pendência é visual e baixa (B1, abaixo).
- **Não disparo a condição do R1** (seção 1). Nenhum número muda antes de integrar.

## 1. Decisão sobre o R1 (cinturão antes de 20:00 com 2.000 jogadores)

**Decisão: NÃO disparo. A melhoria 3 fica em $250K.**

Por quê:
- **A condição foi escrita para o 23b com 400 jogadores**, que é o teste do critério 7. Com 400, o mais cedo é 20:20 e a taxa fica em 25,5% / 24,8%. A condição não acendeu.
- **Com 2.000, o caso é a cauda da cauda:** 1 jogador em 2.000, a 5/s, 12 s antes do limite, com sorte de FRENESI e de bolsa juntas. A taxa (26,6% / 26,2%) continua dentro da tolerância de 2 pontos (≤ 27%).
- **O remédio custa caro para quem clica pouco.** O tempo morto da carreira 1 a 3/s está exatamente no teto aceito (10:32, R4 do QA). A tabela 7.2 do design mostra que encarecer a melhoria 3 alonga essa parede. Trocar 12 s de um jogador raro a 5/s por um tempo morto pior para todo o perfil de 3/s vai contra o pedido do dono ("o clique sempre tem que dar prazer", "nunca ficar parado").
- **A 5.3 refaz essa conta de qualquer jeito.** O calendário muda o ritmo da carreira 1, e o 23b e o tempo morto vão ser remedidos lá. Ajustar $300K agora seria afinar algo que vai mudar daqui a uma fase.

O que muda daqui em diante (registro, não é retrabalho agora):
- **A partir da 5.3, o 23b roda com 2.000 jogadores.** A meta passa a ser: taxa ≤ 25% (±2), **nenhum cinturão antes de 19:30** e **p1 ≥ 20:00** (no máximo 1% dos jogadores antes de 20:00). Um "nunca" medido com amostra pequena dá falsa segurança, e com amostra grande ele sempre acaba furando por um jogador.
- Se na 5.3 o mais cedo com 2.000 cair abaixo de 19:30, a alavanca continua a mesma: melhoria 3 para $300K.

## 2. Outros pontos para registrar

### R2 — Jiu-jitsu × Boxe por jogador e a 5/s
- O critério 6 (obrigatório, a 3/s) fecha: mediana 1 × 1, média 1,31 (Jiu-jitsu) × 1,38 (Boxe).
- Por jogador, com a mesma semente, o Jiu-jitsu chega ao Kid depois do Boxe em 28 de 96 casos a 3/s. Isso é variação de sorte de cada jogador, e o critério sempre foi lido por perfil. Fica aceito.
- A 5/s o Boxe fica na frente (média 0,85 × 1,00). **Isso é coerente com a identidade:** o Boxe é a arte de quem clica muito. Não é defeito.
- **Para a 5.4:** junto do equilíbrio Boxe × Jiu-jitsu na sequência (que já é obrigatório lá), o Designer mede o Kid por perfil a 3, 4 e 5/s. Meta de observação: a 3/s o Jiu-jitsu não fica atrás, e a 5/s o Boxe não abre mais de 0,3 carreira de vantagem.

### B1 — Retrato da luta com luva vermelha na L4 (pendência conhecida)
- O retrato do jogador no topo da luta não segue o sufixo da luva: com a L4, a luva aparece vermelha.
- Não bloqueia. Mas contradiz um pouco a sensação da fase ("comprei a luva e vi na mão").
- **Entra na 5.3 como tarefa pequena** (Artista de Personagens, com o UI/UX ligando o sufixo da luva no retrato). Se não couber, fica para a 7a, quando a tela de luta for refeita.

### Observação de UI (não é bug)
- Na LOJA, o card do Grito da equipe fica abaixo da dobra até o jogador rolar (há seta amarela). É a compra que segura o clique no late game, e o dono pode não vê-la. Peço que ele confira no roteiro (passo 5). Se ele não achar sozinho, na 5.3 o Grito sobe na ordem da LOJA.

## 3. Entrega o pedido do dono?

| O que o dono disse | O que a 5.2 entregou | Avaliação |
|---|---|---|
| "O máximo das melhorias de clique está muito pouco" | L3 ($1.200) e L4 ($2.500), ×2 cada: a luva total vai de ×4 para **×16**. A L3 é comprada segundos depois de chegar à academia. O Grito da equipe soma 1 s da equipe a cada clique, **sem teto** | **Entrega.** O teto subiu 4 vezes e passou a crescer junto com a equipe |
| "Tô jogando só upando o farm" | Grito da equipe: a equipe agora alimenta o clique. No fim do conteúdo, **1 clique vale 52–72% da renda/s** (meta ≥ 25%). A bolsa da torcida dá algo para quem clica pouco, sem virar obrigatória (a ×7 vale 2 a 4 vezes mais para quem clica) | **Entrega.** Upar a equipe deixa de competir com o clique e passa a ajudar o clique |
| "Metrônomo/Shift fracos" | **Não mudou.** O Designer mediu: acelerar ou baratear o Metrônomo tira no máximo 30 s do tempo morto. O escopo mandava mexer só se os números pedissem | **Entrega parcial.** Os números dizem que não precisa, mas a queixa veio de quem joga. **A pergunta volta para o dono** (pergunta 1). Se ele confirmar, o ajuste é só número em `shop.json` (`interval`) e entra na 5.3 |
| "O clique sempre tem que dar prazer" | Cada luva dobra o número do clique na hora, as luvas chegam na caixa de 3 cliques, a bolsa e a ×7 têm visual diferente, o texto flutuante grande ficou menor sem perder o número de todo clique, e a medida de late game virou tabela fixa para toda fase | **Entrega.** Ainda falta som novo para a bolsa e para a caixa (isso é da fase 13) |

## 4. Passou do escopo?

- **Dinho ×1,4 e melhoria 3 dos aparelhos a $250K:** mudanças sem pedido, mas só número em `data/`, registradas na linha "mudei sem pedido" e aceitas por mim. Ficam dentro da regra 2.5.
- **Correção do robô do Dudu:** mexe só no simulador. Nenhum número do jogo mudou por causa disso.
- **Desvios de UI da 2.7:** entraram os 3 e eram opcionais. O QA confirma que ficaram limpos e baratos.
- **Nada de sistema de fase futura entrou:** não tem calendário, não tem nó novo de Legado, não tem fala nem luva com efeito de luta. O Grito ficou na LOJA, como pedido, e não na árvore.
- **Conclusão:** não houve inchaço. A fase ficou do tamanho combinado.

## 5. O que fica para a 5.3 e a 5.4

**5.3 (calendário):**
- Remedir o tempo morto da carreira 1 a 3/s (meta voltando a ≤ 10:00).
- 23b com 2.000 jogadores e a meta nova da seção 1 (mais cedo ≥ 19:30, p1 ≥ 20:00).
- B1: o retrato da luta passa a seguir a luva.
- Metrônomo/Shift, se o dono confirmar que estão fracos (só número).
- Grito mais acima na LOJA, se o dono não achar o card.

**5.4 (árvore):**
- **Obrigatório:** Boxe × Jiu-jitsu até o cinturão ≤ 10% na sequência, a 3, 4 e 5/s. As alavancas são `style_bjj` e `body_crew_2`.
- Árvore do Boxe a 5/s fechando na 5ª carreira ou depois.
- Kid por perfil e por arte (R2).
- "Clique com equipe" como nó da árvore, se fizer sentido junto do Grito.
- Refazer a tabela fixa de late game (seção 5.3 do design).

## 6. Roteiro de teste para o dono (~8 min)

Antes: abra o jogo pelo seu save de sempre. O save novo é convertido sozinho e você não perde nada. Se você ainda estiver na garagem, faça os passos 1 a 3 e deixe o resto para quando chegar à academia.

1. **(1 min) Luva dourada.** Fique na sala de treino. A cada 1 a 1,5 min aparece um brilho dourado. Às vezes é uma **luva** (FRENESI ×7), às vezes é um **saco de moedas** (a bolsa da torcida, que paga de uma vez vários segundos da sua equipe).
   - Dá para saber de longe qual é qual?
2. **(1 min) Bolsa.** Pare o mouse em cima do saco antes de clicar: ele mostra quanto vai pagar. Clique e veja o número subir.
   - O valor parece justo?
3. **(1 min) Metrônomo e Shift.** Deixe a mão parada por 30 s, primeiro só com o Shift (modo assistido) e depois com o Metrônomo.
   - Ainda parecem fracos?
4. **(1 min) Luva L3.** Ao chegar à academia, abra a LOJA e compre a L3 ($1.200). Ela chega numa caixa perto do lutador: são 3 cliques para abrir. Veja o número do clique na barra de baixo antes e depois.
   - Deu a sensação de que o clique dobrou?
5. **(1 min) Grito da equipe.** Na LOJA, **role até o fim** e procure o "Grito da equipe" ($1.500). Depois de comprar, o número do clique passa a subir sozinho toda vez que você contrata alguém para a equipe.
   - Você teria achado esse card sem eu avisar?
6. **(2 min) Tonhão e L4.** Lute com o Tonhão. Com o prêmio, compre a L4 ($2.500), abra a caixa e veja a luva azul na sala e na luta.
   - A arte da L4 está boa?
   - Obs.: o retratinho no topo da luta ainda mostra a luva vermelha. Já sabemos e vamos corrigir.
7. **(1 min) Kid.** Treine um pouco e tente o Kid.
   - Ficou fácil, justo ou difícil demais?
   - Com a equipe grande, clicar ainda dá prazer?

## 7. Perguntas para o dono

1. **Metrônomo e Shift:** depois de jogar esta versão, ainda estão fracos? Se sim, o que incomoda mais: a velocidade ou o preço? A resposta decide se a 5.3 mexe neles.
2. **Bolsa da torcida:** hoje ela aparece em metade das luvas douradas e paga 45 s da equipe. Prefere que ela apareça menos (para a ×7 ficar mais comum) ou está bom assim?
3. **Kid:** quem clica rápido vence o Kid na primeira tentativa em quase metade das vezes. Isso é bom ("comprei a L4 e mereci") ou ele precisa resistir mais?

## Resumo para o Produtor

A 5.2 está **aprovada**: 12 de 12 critérios OK, nenhum bug funcional, UI com 0 problemas. A luva vai até ×16, o Grito da equipe faz o clique crescer junto com a equipe, e a bolsa da torcida ajuda quem clica pouco.
**R1: não disparo a condição.** Com 400 jogadores (o teste combinado) ninguém chega antes de 20:00. O caso dos 19:48 é 1 em 2.000, e encarecer a melhoria 3 pioraria o tempo morto de quem clica 3/s, que já está no limite. A partir da 5.3, o 23b roda com 2.000 jogadores e uma meta nova.
Pendências: o retrato da luta com luva vermelha (5.3) e Metrônomo/Shift sem mudança. A última é a primeira pergunta ao dono, porque a queixa foi dele.
Mostre o roteiro de 8 min da seção 6 e as 3 perguntas da seção 7.
