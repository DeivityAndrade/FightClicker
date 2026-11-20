# Fase 7a2 — Treino fora de hora: revisão do Diretor

Diretor de Jogo, 2026-11-20. Branch `fase-7a2`, sem commit. Base: `fase7a-escopo.md` (§4, §7 e **§8, decisões do dono**),
`fase7a2-design.md`, `fase7a2-textos.md`, `fase7a2-qa.md`, capturas `docs/arte/mockups/fase7a2_*.png` e o código do prêmio
(`scripts/estado/treino_fora.gd`, `ui/tela_panfleto.gd`).

## Veredito
**Aprovado com 2 ajustes pequenos**, a fazer antes de mostrar ao dono. Nenhum deles mexe em tela nem em save:
1. **Designer:** rodar mais uma política no simulador, "luta mais cedo com o AQUECIDO" (detalhe abaixo, ponto 2). Se passar de 10% em dias, baixar `spar.warm.attr_bonus` para 0,02 e rodar de novo.
2. **Roteirista:** duas falas de quem aceita o panfleto não servem em todos os casos (ver "Desvios").

B1 e B2 do QA estão corrigidos. Conferi o B1 no código: em `_tick_fora` a equipe só produz enquanto o jogo do minigame não chegou ao fim.

## O que bate com o pedido do dono
- **Os dois minigames da §8.3:** o Choque (cabo de guerra com fôlego, aviso, contragolpe ×2 e finta; Boxe por cliques, Jiu-jitsu segurando e soltando) e a Panfletagem (clicar em quem dá sinal de interesse; errar tira meio panfleto). Cada um dá um prêmio diferente: treino da arte com AQUECIDO no Choque, FAMA na Panfletagem.
- **Ignorar não custa nada:** a foto da 7a2 é idêntica à da main e o simulador dá 80/80 sequências idênticas. O convite não usa sorteio do jogo nem mexe nas falas.
- **Ir nunca custa dia:** o relógio da campanha fica parado e a equipe produz, mas só enquanto o jogo roda.
- **Duração:** ~35 s no total (contagem, jogo e prêmio). Dá para SAIR a qualquer hora e sempre há piso.
- **Habilidade conta de verdade:** quem clica afobado perde para quem mantém o ritmo; quem lê os sinais vence. Na Panfletagem, clicar em todo mundo rende zero. O enfeite das pessoas não entrega quem está interessado (o QA mediu). É o "ler sinais" que o dono pediu.
- **Tutorial intocado:** na 1ª carreira não há convite antes do cinturão, e os tempos do cinturão e da 1ª carreira são iguais em todas as políticas.
- **Save:** continua v13, com 1 campo opcional e 1 marco novo. O save sujo e o save antigo abrem sem erro.
- **Visual:** as capturas têm cara própria. Fundos da academia à noite, rua com padaria, "Lanches da Nena" e o cartaz da Raízes com o "R de raiz". As poses ficam frente a frente, sem espelhar.
- **Prévia honesta:** o AQUECIDO entra na mesma conta nos quatro lugares. O QA mediu +41 na prévia e +43,3 em 1.500 lutas reais.

## Nada adiantado
- **Gato Preto:** só a semente. São o recorte "VULTO MASCARADO" (silhueta de gato com a lua, nada de morcego nem de Batman) e um boato de uma vez só, dentro da Panfletagem. O nome não aparece. Não há minigame, fama própria nem peças do traje. **A Ronda Noturna continua inteira para a fase dela.**
- Nada da 7b (Muay Thai, 2ª passiva) nem da 8a (passiva dos adversários, rival, liga regional).
- O "discípulo melhor" como prêmio da Panfletagem ficou de fora de propósito: pediria save v14 e um conceito novo. O "bico na padaria" também ficou de fora. As duas decisões estão certas.

## Os três pontos para julgar

### 1. Teto de 10%: em dias ou em tempo real?
**Minha opinião: em dias de campanha, como o Designer fez.**
- O teto existe para o minigame não virar obrigação. A obrigação viria da **data da luta**, que é medida em dias. Em dias, quem vai em tudo com nota máxima chega 3,7–5,7% antes ao Kid, e o pior trecho fica em 9,2%. Isso cumpre a regra.
- Em tempo real, ir **custa** de 3% a 13% a mais. Um custo não pode virar obrigação: quem quer correr ignora o convite, e quem está apertado com a data vai. É exatamente a escolha que queríamos.
- **Ressalva:** a margem é pequena (9,2% contra 10%). Os números de `data/minigames.json` ficam travados. Qualquer mudança em `max_seconds`, `attr_bonus`, `interval_s` ou `first_after_s` obriga a rodar o simulador de novo.
- **Pergunta ao dono (1 linha):** "acelerar no máximo 10%" é em dias da campanha? Se ele quiser em tempo real, a regra já está cumprida com folga, porque ir sempre deixa a campanha mais longa no relógio.

### 2. AQUECIDO forte demais?
**Minha opinião: manter +3%, mas medir o teto num caso que ficou de fora.**
- O +41 não é defeito do AQUECIDO. A luta é íngreme perto dos 50% de chance (motor da 7a1), e em qualquer lugar da curva +3% nos atributos vale pouco. A prévia mostra o número verdadeiro. Ver "+41 NA CHANCE" depois de vencer um sparring é um bom momento: o clique de treino pesa na luta, e isso é juice.
- **O furo está na medida, não no bônus:** o robô do teto (`forca`) só luta no verde, onde o AQUECIDO vale +0,6. Mas um jogador esperto pode **guardar o AQUECIDO e lutar mais cedo**, aos ~50% sem o bônus, que viram ~90% com ele. Isso poupa dias, e a §8 não mediu esse caso.
- **Ajuste:** o Designer roda uma política "todos_max + luta assim que a prévia **com** o AQUECIDO fica verde" e confere se o pior trecho continua abaixo de 10% em dias. Se passar, basta baixar `attr_bonus` para 0,02. O mesmo vale para a variante sem regra nova: ninguém mexe no motor nem na prévia.
- Também não quero teto de pontos na chance ("no máximo +15"). Ele quebraria a regra de "mesma conta nos quatro lugares", que é o que mantém a prévia honesta.

### 3. Gato Preto
**Aprovado.** É semente pura e cumpre a §8.4: personagem original, sem cara de Batman e sem nome. O boato fica na rua, à noite, e não disputa vaga com as falas da sala. O recorte fica na parede, ao lado dos outros papéis, legível no hover e sem roubar a atenção. Deixar o nome para depois foi a escolha certa: a lenda cresce antes do herói.

## Desvios e pendências
| # | O quê | Peso | Quem |
|---|---|---|---|
| D1 | Medir o teto com "lutar cedo guardando o AQUECIDO" (ponto 2). Baixar para 0,02 só se passar de 10% | **antes de mostrar** | Designer |
| D2 | As falas de `flyers_took` saem sorteadas sem olhar o contexto: "HUM, BOXE? DEIXA VER" aparece para o aluno de Jiu-jitsu e "RAÍZES? FICA NA GARAGEM, NÉ?" aparece com a escola na academia. Trocar por falas neutras (sem arte e sem local) é o mais simples | **antes de mostrar** | Roteirista |
| D3 | A Panfletagem aparece na 1ª carreira depois do cinturão, **sem arte**. O escopo antigo dizia "só existe com arte", mas a §8 do dono criou um minigame "do mundo", então está coerente. Só avisar o dono | informar | Produtor |
| D4 | O QA não rodou a seção `campanha` do simulador (tempo real com calendário). Rodar junto com o D1 | junto do D1 | Designer |
| D5 | Perder o foco da janela com o botão apertado foi conferido só lendo o código. O dono pode testar no jogo (ver abaixo) | baixo | QA, se o dono achar algo |

## O que o dono deve testar com as próprias mãos
Use uma campanha 2 ou mais, já com arte.
1. **Ignorar:** jogue uns 10 min sem clicar no balão. Ele deve aparecer perto do Osmar, sumir sozinho, sem bronca, e nunca cobrir uma fala.
2. **Choque com a sua arte:** jogue um clicando o mais rápido que conseguir e outro no ritmo, guardando na RAJADA (ou soltando na PUXADA) e batendo no "ELE ABRIU!". O segundo deve render claramente mais. Tente cair numa finta.
3. **AQUECIDO:** vença um Choque e abra a prévia da próxima luta. A linha "+N NA CHANCE" deve fazer sentido para você: o bônus parece justo ou forte demais?
4. **Panfletagem:** jogue uma lendo os sinais e outra clicando em todo mundo. A segunda tem de render quase nada.
5. **SAIR e prêmio:** saia no meio e veja o prêmio mínimo. Depois, deixe a tela de prêmio parada: o Treino não pode subir.
6. **Fechar o jogo no meio do minigame:** ao reabrir, você volta para a sala, sem prêmio e sem convite repetido.
7. **Recorte de jornal:** passe o mouse sobre ele, na garagem e na academia. Na 1ª Panfletagem com o recorte na parede, o Osmar fala do vulto.
8. **Sensação geral:** o convite é um passeio que dá vontade de fazer, ou parece obrigação?

## Resumo para o Produtor
- A 7a2 está **aprovada com 2 ajustes pequenos**: o Designer mede o teto no caso "guardar o AQUECIDO e lutar mais cedo" (só baixa para +2% se passar de 10%), e o Roteirista troca duas falas da Panfletagem que citam o Boxe e a garagem fora de hora.
- Teto: recomendo medir **em dias de campanha**. Em tempo real, ir sempre custa mais, então não vira obrigação. Falta só o dono confirmar.
- O AQUECIDO de +3% fica: o +41 vem da luta íngreme, e a prévia é honesta.
- O Gato Preto é só semente (recorte e boato, sem nome nem traje de Batman). Nada da Ronda Noturna, da 7b ou da 8a foi adiantado.
- Avisar o dono que a Panfletagem já aparece na 1ª carreira depois do cinturão (sem arte), o que está coerente com a decisão dele.
