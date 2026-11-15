# Fase 5.3 — Calendário da campanha: revisão do Diretor

Data: 2026-11-13. Branch `fase-5.3`. Base: `fase5.3-escopo.md` (com as Decisões do Diretor), `fase5.3-design.md`, `fase5.3-qa.md`, `fase5.3-api.md` e as capturas `f53_dia_previa_revanche_arte`, `f53_hud_hoje`, `f53_aviso_1_dia_a` e `f53_hud_completa`.

## Veredito
**Aprovado com 1 ajuste pequeno antes de mostrar ao dono (A1).** O calendário faz o que o dono pediu e os 15 critérios passam (B1 a B4 corrigidos, `ui_audit` com 172 estados e 0 problemas, todos os testes passando). O A1 é só uma frase que aparece no lugar errado. Não precisa de nova rodada de QA: basta conferir a captura do dia.

## 1. A visão do dono: cumprida
O dono pediu "passagem de tempo, a cada X dias uma luta", com a luta obrigatória no dia e "passar o posto".
- **Passagem de tempo:** o dia da campanha anda na sala e a data da próxima luta fica sempre à vista no painel da esquerda ("FALTA 1 DIA / DUDU ALONGADO" com a folhinha "29" e o risco embaixo). Dá para ver sem procurar.
- **A cada X dias uma luta:** as 6 lutas têm data (folgas 12, 13, 10, 16, 24 e 16 dias). Lutar antes é livre e a próxima data conta do dia da luta.
- **Obrigatória no dia:** no dia tudo para (relógio, clique, equipe, Metrônomo, luva dourada) e a janela "DIA DA LUTA" abre sem jeito de voltar a treinar. As únicas saídas são **LUTAR!** e **PASSAR O POSTO**. O QA deixou parado e nenhuma luta começou sozinha. O dia manda, mas quem aperta é sempre o jogador.
- **Passar o posto:** dá 100% do Legado, pede confirmação, e a janela do dia mostra o custo de perder ("PERDER ENCERRA A CAMPANHA (METADE DO LEGADO)"). A escolha fica clara.
- **Avisos:** a faixa de 1 dia ("AMANHÃ É DUDU ALONGADO. GASTE O QUE TIVER.") está no tom pé no chão, bem lida e não cobre nada importante.
- **Depois do Kid:** "CAMPANHA COMPLETA" com a folhinha de estrela e o relógio some. Certo.
- **Balanço:** 23b em 26,4% (5/s), ninguém antes de 20:44; tempo morto da carreira 1 a 3/s em 6:00 (melhor que antes); 96 a 97% das lutas acontecem antes da data. O calendário pressiona sem virar "relógio que mata".

## 2. O que ficou bom
- **Regra anti-abuso redonda:** uma condição só (`sala_ativa`) liga relógio e equipe juntos. Não existe "abro uma janela e treino de graça".
- **B3 resolvido do jeito certo:** com a luta em outro local (Tonhão com o jogador na garagem), o relógio não conta, e a folga cheia começa quando ele chega na academia. Ninguém cai direto no dia depois de mudar.
- **Save:** a migração dá folga cheia e não perde nada. Testes com save isolado; o save real do dono ficou intacto.
- **Textos:** "Passar o posto", "Campanha encerrada" e "Nova campanha" sem nenhum "aposentar" sobrando.
- **Pendências da 5.2 fechadas:** o retrato segue a luva (L0 a L4) e o Grito aparece sem rolar na LOJA.

## 3. O que desvia da visão (corrigir antes de mostrar)
- **A1 (obrigatório): "ESPERE FICAR VERDE" aparece no dia da luta.** Aparece na janela do dia (`f53_dia_previa_revanche_arte`, à direita do risco) e no bloco da próxima luta, no HUD. No dia não dá para esperar: o treino está parado. Para o jogador, a frase diz que ele pode esperar, mas a única escolha é lutar ou passar o posto. Correção: no dia, esconder essa frase nos dois lugares (`ui/janela_previa.gd`, por volta da linha 315, e `ui/bloco_proxima.gd`, `_verde`). Se sobrar espaço, a dica de passar o posto já cobre. Dono: UI/UX. Depois, rodar `ui_audit` de novo (0 problemas).
- **A2 (só documento): `fase5.3-api.md`, seção "Observações", 1º item,** ainda descreve o comportamento antigo do Tonhão ("o relógio NÃO trava... até mudar para a academia, quando o dia chega"). Isso contradiz a seção nova "Luta em outro local (B3)". Apagar ou reescrever. Dono: Programador.
- **Nota visual (aceita, sem ação):** o selo "HOJE 30" agora fica pendurado acima do canto da janela, por cima da barra de cima (que está escurecida). Não toca o retrato e o verificador aprova. Parece uma folhinha presa na janela, e isso combina com a ideia.

## 4. O que passou do escopo
Nada que mude o jogo. A única regra nova fora do texto do escopo é que **a equipe também para na luta e nas janelas**. Ela é consequência direta da regra anti-abuso e já foi aceita (Decisão 5). Nenhum sistema de fase futura foi adiantado: não entraram diálogo, cena, nó de "+1 dia", offline nem som novo.

## 5. O que fica para a 5.4 (pendências obrigatórias)
1. **Árvore fecha só da 5ª à 8ª carreira.** Hoje fecha na 4ª, por causa dos 100% do Legado ao passar o posto (Decisão 2). A remedição da 5.4 tem que voltar para 5ª a 8ª.
2. **Jiu-jitsu x Boxe ≤ 10% de diferença.** Hoje está dentro do ruído (3 de 48), mas tem que ser medido com amostra maior e ficar no limite.
3. **O Kid fica fácil para quem espera o verde** (79 a 98% de vitória na chegada; Decisão 1). A alavanca é F/A/R do Kid. A data não muda.
4. **Ramo "CARREIRA" da árvore** muda de nome para combinar com "campanha" (Roteirista, `skill_tree.json`).
5. Já previstos para a 5.4: árvore grande e o nó "+1 dia de preparo".
- Fase 13 (offline): nunca pular o dia da luta e mostrar os avisos que ficaram no caminho (B2 já deixou o salto emitindo o aviso de 1 dia).
- Só se o dono pedir: Metrônomo/Shift.

## 6. Roteiro de teste para o dono (cerca de 8 min)
Use o seu save normal. O jogo abre com folga cheia, então você não cai direto no dia da luta.
1. **(1 min) Olhe o painel da esquerda.** Embaixo dos atributos tem uma folhinha com "Faltam X dias", o nome do próximo adversário e a cor do risco. *Valide:* dá para ver sem procurar?
2. **(2 min) Treine normal e olhe o dia passar.** Abra a prévia (LUTAR!) e feche. O dia não anda com a prévia aberta. *Valide:* o tamanho do dia parece certo?
3. **(2 min) Não lute. Deixe a data chegar.** A 3 dias aparece uma faixa no alto e a 1 dia aparece outra, com som. *Valide:* os avisos chegam a tempo e não irritam?
4. **(1 min) No dia:** a janela "DIA DA LUTA" abre sozinha e o treino para (clique e equipe). Tente clicar no saco e abrir a LOJA. Nada acontece. *Valide:* ficou claro que é "lutar ou passar o posto"? Em algum momento pareceu que o jogo decidiu por você?
5. **(30 s) Aperte PASSAR O POSTO e depois cancele.** Tem confirmação e o Legado fica à vista. Volte e aperte **LUTAR!**.
6. **(30 s) Lute antes da data** na próxima luta, a qualquer hora. *Valide:* a nova data aparece contada a partir de hoje?
7. **(1 min) Deixe o jogo aberto em outra janela** (ou minimizado) até chegar uma data. Ao voltar, ele está parado esperando você. *Valide:* isso incomoda ou faz sentido?
8. **De passagem:** veja se o retrato no topo da luta usa a luva que você tem e se o Grito da equipe aparece na LOJA sem rolar. *Valide também:* "campanha" e "passar o posto" soam bem para você?

## 7. Perguntas para o dono
1. **O tamanho do dia e a folga entre as lutas estão bons?** A 3 e 4 cliques/s, a 1ª campanha quase sempre termina no Dinho, porque o jogador passa o posto. Isso foi de propósito, como a "parede" da carreira 1. Se achar curto, a alavanca é a folga em `data/`.
2. **O jogo parado no dia para quem saiu de perto: tudo bem?** Quem deixa o jogo 10 min sozinho perde quase metade da renda da equipe nesse tempo. Se incomodar, a saída é dar mais folga. Luta automática nunca.
3. **Metrônomo e Shift continuam fracos para você?** Está em aberto desde a 5.2. Se sim, é só mexer em número numa fase seguinte.

## Resumo para o Produtor
A 5.3 está **aprovada**, com 1 ajuste de texto antes de mostrar: no dia da luta, sumir com "ESPERE FICAR VERDE" (janela do dia e HUD), porque no dia não dá para esperar. Também tem 1 linha antiga para corrigir no `fase5.3-api.md`.
O calendário cumpre o pedido do dono: tempo passando, uma luta a cada X dias, o dia obrigatório com "lutar ou passar o posto" e nenhuma luta começando sozinha. As metas de balanço estão de pé.
Para a 5.4 ficam, obrigatórios: árvore fechando da 5ª à 8ª carreira, Jiu-jitsu x Boxe ≤ 10%, Kid menos fácil (F/A/R, nunca a data) e trocar o nome do ramo "CARREIRA".
O dono testa em cerca de 8 min pelo roteiro da seção 6 e responde às 3 perguntas da seção 7.
