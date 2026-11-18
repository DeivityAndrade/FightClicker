# Fase 6c2 — Mais longe que eu: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-18.
Li: `PROMPT.md`, `docs/direcao-narrativa.md`, `fase6c-escopo.md` (critérios 12–21), `fase6c2-design.md`, `fase6c2-api.md`, `fase6c2-textos.md`, `fase6c2-qa.md`, `docs/estado-atual.md`. Olhei as capturas `f6c2_tela_mural_9`, `f6c2_mural_academia` e o mockup do mural.

## Veredito: APROVADA, e a Fase 6c está FECHADA
Uma condição: a rodada de testes e do `ui_audit` que está rodando agora, depois da retirada do trio de adversários que tinha entrado por engano, tem que sair verde e com 0 problemas. Se algo falhar, volta para o Programador antes do PR. A revisão não precisa ser refeita.

## 1. Bate com a visão?
Sim. A sensação pedida era *"a escola é maior que qualquer lutador"*.
- **Mural:** os retratos lado a lado, o John primeiro e o símbolo no peito de quem veio depois contam a história da escola sem nenhuma fala. É a melhor tela da fase.
- **Honra:** só vem quando o lutador sai por vontade e com pelo menos uma vitória. Nunca é multiplicada e não aparece no HUD. Fica como recompensa por sair por cima, sem competir com o Legado.
- **Hall:** 6 nós pequenos e de "qualidade de vida" (caixa, treino inicial, luva, prévia). Não acelera o jogo: o teto medido foi de 3,4% a 7,7% do efeito da árvore de Legado.
- **Escolha real:** lutar vale mais que sair quando a chance de vencer passa de 20%. Sair cedo rende cerca de 1/6 do jeito padrão. Ninguém é premiado por desistir.
- **Anti-incremental:** nada. Com o hall vazio, o balanço é idêntico ao da 6c1 (diff do QA).
- **Identidade:** original. Os nomes do hall (FITA FROUXA, VAQUINHA, CADERNINHO…) são pé no chão e nossos. A retirada do "Leslie Chow" foi correta: nome de personagem de filme não entra.

## 2. Critérios de aceite da 6c2
| # | Critério | Situação |
|---|---|---|
| 12–13 | Honra: fórmula, só saída voluntária, nunca multiplicada, fora do HUD | **Cumprido** |
| 14 | Hall: 6 nós, compra entre campanhas, efeito na seguinte | **Cumprido** |
| 15 | Retrato com selo, teto | **Cumprido** |
| 16 | Falas dos mentores (revanche, recorde, "mais longe que eu") | **Cumprido** |
| 17 | Mural nas duas salas, sem cobrir alvo nem cabeças | **Cumprido** (B3 corrigido: o mural vazio agora tem aviso) |
| 18 | Símbolo desde o 1º cinturão, John nunca usa | **Cumprido** (B2 corrigido) |
| 19 | Balanço: hall vazio idêntico à 6c1; metas valem | **Cumprido** |
| 20 | Save v12→v13 com Honra retroativa, cópia do save real | **Cumprido** (B1 corrigido: "PAROU NUMA LUTA") |
| 21 | `ui_audit` 0 problemas, testes verdes | **Cumprido** (358 estados, 0 problemas). Falta só a confirmação da rodada atual |

## 3. Decisões que eram minhas (design §12)
- **§12.2 (Carreira 1 com o "hall cheio"):** vale o caso real. A Carreira 1 fica igual à 6b2 e o hall fecha por volta da 9ª carreira.
- **§12.3 (teto medido no tempo até o cinturão e o Kid):** aceito. É o que o jogador sente.
- **§12.4 (8 saídas no padrão, 13–14 só com cinturão):** aceito sem baixar para 180. O caso de 13–14 é de quem joga de um jeito específico, e o hall nunca bloqueia nada. Revejo se os testadores reclamarem.
- **O7 (Honra só aparece na confirmação):** fica assim.
- **O8 (cálculo em segundo plano sem espera ao fechar):** não trava. Programador acrescenta a espera na próxima vez que mexer no `game_state.gd`.

## 4. Perguntas para os testadores
1. Você abriu o quadro na parede sozinho? Entendeu o que ele é?
2. Quando viu "+HONRA" na tela de fim, entendeu por que ganhou (ou por que não ganhou)?
3. Alguma vez você parou um lutador de propósito para ganhar Honra? Ou preferiu lutar?
4. O que você comprou primeiro no mural, e por quê?
5. Você reparou no desenho no peito dos lutadores novos? O que achou que era?
6. Quando o lutador sentado no caixote falou depois de uma vitória, você leu? Achou bonito ou chato?
7. (Da 6c1, ainda valendo) Você percebeu quando o John foi embora? A frase dele no mural fez sentido?

## 5. Para o pixel artist humano
- Símbolo no peito na luta: hoje é só uma marca discreta. Desenhar à mão para ficar legível em todas as poses.
- O retrato 32x32 da luta (só o rosto) não mostra o símbolo. Avaliar se cabe.
- Ícones dos 6 nós do hall e o quadro do mural na parede (garagem e academia).
- Tudo o que ficou da 6c1: braço da bolsa, esteira, cabeça do Osmar, saco "na ponta da mão" e foto torta de 1 px.

## 6. Próxima fase: 7a — Lutas por arte
- Boxe e Jiu-jitsu passam a lutar de jeitos diferentes, com habilidades passivas, e entra a arena da academia (escopo §5).
- Fica de fora o que for de fases seguintes (8a: escada além do Kid e novos adversários). Os nomes de adversários novos são originais e passam pelo Roteirista.
- A 7a começa com o meu escopo (`fase7a-escopo.md`), em paralelo com os testadores da 6c.

## Resumo para o Produtor
- A 6c2 está **aprovada** e **a Fase 6c fecha aqui**. Só falta a rodada atual de testes e do `ui_audit` sair verde; aí abre o PR e integra.
- O mural com a Honra entrega a sensação de "a escola é maior que qualquer lutador", sem acelerar o jogo: o hall vazio dá o mesmo jogo da 6c1, e o hall cheio no máximo 7,7%.
- Aceitei a economia do Designer como está: o hall enche em 8 saídas no jeito padrão.
- Há 7 perguntas para os testadores, e o símbolo na luta vai para o pixel artist.
- Próximo passo: a 7a, com Boxe e Jiu-jitsu lutando diferente.
