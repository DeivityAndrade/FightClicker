# Fase 8b — Nacional (com o Ringue da Lua): escopo

Diretor de Jogo, 2026-11-26. Base: `PROMPT.md` §3, §5.4, §5.6 e §5.9; `docs/roadmap.md` (8b, Arco 4); `docs/direcao-narrativa.md`
(Arco 4); `docs/estado-atual.md`; `ronda2-ideias.md`; `fase8a-escopo.md`; as revisões `fase8a1`, `fase8a2` (E4: Legado que sobra),
`ronda2a1` (D5, D6) e `ronda2a2` ("Fica para depois"). O jogo não foi rodado.

## 1. Objetivo e sensação
- **Objetivo:** a Raízes vira nome do país. Do centro sai a **liga nacional**, numa arena grande. O **James** sobe junto, agora
  **estudando a escola**, e termina em respeito. O cinturão nacional libera o **complexo de elite** (local 4). À noite, para quem
  tem lenda alta, abre o **Ringue da Lua**, um torneio clandestino com supervilões de nível nacional.
- **Sensação de dia:** "o Blindado assistiu às minhas lutas e veio pronto pro meu jeito. Vou mudar e passar por cima dele."
- **Sensação de noite:** "isso é ridículo e é meu: um ringue no telhado, sob a lua, contra um sujeito que se acha lenda nacional.
  Demorei, mas o troféu dele está na prateleira. E o Osmar está olhando torto pra mim."
- **Tom:** de dia, o topo do circuito (TV, estádio), ainda pé no chão. De noite, o fantasioso sobe um degrau.

## 2. Divisão em subfases (ordem fixa)
| Parte | O que traz | Depende de |
|---|---|---|
| **8b0 — Item técnico** | placar de `ignore` ≤ 15 na rodada completa e estados instáveis (BUG-3). **Feito à parte, antes da 8b1** | — |
| **8b1 — Liga nacional** | liga saindo do centro, arena nacional, adversários nacionais, James preparado, campeão nacional, cinturão | 8b0 |
| **8b2 — Complexo de elite** | local 4, gerador novo, região da árvore (destino do Legado), respeito do James (fim do Arco 4) | 8b1 aprovada |
| **8b3 — Ringue da Lua: a chave** | destrave, arena do Ringue, 2 lutadores do Ringue, desafios, estilos, o Osmar desconfia | 8b1 (cinturão nacional) |
| **8b4 — Ringue da Lua: o campeão** | supervilão nacional, troféu normal e raro, título, marco no menu, o James liga as tramas | 8b2 e 8b3 |

**Por quê:** o cinturão nacional é a porta de tudo (local 4 e Ringue, regra "a lore anda com a campanha"). A 8b1 muda o jogo, a 8b2 é
prêmio e cenário, como na 8a. O Ringue repete o par 2a1/2a2 (elenco barato primeiro, chefe caro depois). O James só liga as tramas
depois de respeitar a escola, por isso a 8b4 vem por último. Os artistas não se atropelam: arena e elenco de dia (8b1), cenário
(8b2), elenco da noite (8b3/8b4).

## 3. O que entra
### 3.0 8b0 — já feito antes (só registro)
- Rodada completa do verificador com `ignore` ≤ 15 e os estados `f6b1_s8` e `f8a1_luta_guarda_clink` determinísticos.
- Tocado à parte pelo UI/UX e pelo Programador. A 8b1 só começa telas novas com isso fechado.

### 3.1 8b1 — Liga nacional
- **Onde abre:** ao chegar no centro com o Cinturão do Vale, abre a liga nacional, com data no calendário (regra da 5.3). Some o
  "SEM LUTA NOVA POR ENQUANTO" do centro. **Nada muda até a mudança para o centro.**
- **Tamanho (proposta):** **4 lutas**: 2 nacionais com passiva, o **James preparado** e o **campeão nacional** (personagem próprio,
  com passiva própria, como o Blindado). O Designer fecha números, prêmios e dias.
- **James estuda a escola (o novo da fase):** a passiva dele no nacional é escolhida pelo **jeito com que a escola o venceu da última
  vez** (dentre as passivas que já existem). A prévia diz isso em 1 linha ("ELE ESTUDOU O SEU CONTRAGOLPE"). Sem conta nova no motor;
  a prévia segue honesta. Ele continua arrogante na 8b1, mas agora "levando a sério".
- **Arena nacional:** degrau acima da regional: ginásio grande ou estádio coberto, TV nacional, telão, luzes. Nome com o Roteirista.
- **Fim:** cinturão nacional com "COMPLEXO DE ELITE LIBERADO" (a mudança chega na 8b2).
- **Pendências que entram aqui:**
  - **BUG-2 do Dossiê** (texto do bandido aberto e não vencido), primeira tarefa do UI/UX;
  - **refazer `ronda2a_sim.py chefe`** e **cronometrar 1 noite animada** (D6 da 2a1), Designer + QA;
  - **`ronda2a_sim.py teto`** de novo, porque a fama nacional mexe no Legado;
  - **passe de arte nas poses do meio do Apagão** (K.O. primeiro, depois cotovelo e bateria), em paralelo, **assim que o dono testar
    a 2a2**. Se o teste atrasar, vira condição de abertura da 8b3.

### 3.2 8b2 — Complexo de elite (local 4)
- **Mudança:** cinturão nacional + dinheiro levam ao MUDAR, no padrão do centro (dados em arquivo próprio). Cenário, multiplicador,
  aparelhos em versão nova e **1 gerador novo** que só existe ali (nome e números com Designer e Roteirista).
- **Destino do Legado que sobra (E4 da 8a2):** região **ELITE** na árvore (3–4 nós), só depois da 1ª mudança. Nenhum nó antigo muda.
- **Fim do Arco 4:** na 1ª vitória da escola sobre o **James preparado** com o complexo já no jogo, ele reconhece a escola.
  Caixa de diálogo pulável, ≤ 20 s, sem cena nova. Depois disso, as falas dele mudam de tom (respeito, sem virar parceiro). O
  cartaz dele aparece no complexo, assinado.
- **Chegada:** 1 fala do Osmar, sem cena. No complexo não há luta nova (a liga mundial é a 9).

### 3.3 8b3 — Ringue da Lua: a chave
- **O que é:** torneio clandestino num lugar alto à noite (telhado, caixa-d'água, lua enorme). Uma **chave de 3 degraus**: 2
  **lutadores do Ringue** nesta subfase e o campeão na 8b4 (aparece como "???").
- **Regras da Ronda 2a, todas mantidas:** opcional, relógio parado, 1 capuz = 1 noite, sorteio próprio, atributos crus, passivas
  que já existem, perder só gasta o capuz e marca REVANCHE, a lenda e o Dossiê nunca caem, sem sangue, vulto sem rosto.
- **Progresso na chave:** vencer um degrau fica salvo entre noites e entre discípulos. Perder não volta degrau.
- **Destrave (difícil):** **lenda nível 6** (nível novo, limiar com o Designer), **Apagão vencido** e **cinturão nacional** na
  linhagem. Antes disso, o Esconderijo mostra o que falta, uma coisa por vez (padrão da 2a2).
- **Prêmios (só visual e lore):** ficha no Dossiê por lutador; desafio de cada um dá 1 **estilo de personalização** (aparece no
  próximo discípulo, marcado com o gato).
- **O Osmar desconfia:** as falas `cl_lenda` guardadas, revistas pelo Roteirista, saem como 1 balão na sala quando a lenda sobe de
  nível. Ele estranha, nunca conclui. Só acontece para quem usa o capuz e **não usa o `rng` do jogo**.
- **Vilões:** os 2 lutadores do Ringue são supervilões menores no rig comum (cabeça, roupa, paleta e 1 pose de assinatura). Candidato
  natural a um deles: o **Rei Calota** (reserva do dono), ou 2 novos do Roteirista.

### 3.4 8b4 — Ringue da Lua: o campeão
- **Campeão do Ringue:** o supervilão nacional, com folha completa, entrada com letreiro, passiva mais forte e um "momento" visual
  que não mexe na luta (como o apagão). **Amostra de arte ao dono antes do elenco.** Candidato: o **Capivarão**, escalado para nível
  nacional (pergunta 3). Nome real escondido até vencer.
- **Prêmios:** troféu normal e raro na prateleira, título da imprensa, marco na parede do menu e, no desafio, uma **variação do
  capuz ou da capa** (prêmio raro, só visual). Quanto mais difícil, melhor.
- **O James liga as tramas:** só para quem venceu o campeão do Ringue e já teve o respeito do James: 1 fala dele na liga nacional
  ("Vi um sujeito de capuz no Ringue. Luta igual a vocês.") e 1 recorte no Dossiê. Ninguém diz quem é o vulto.

## 4. Fica de fora
| Item | Fase |
|---|---|
| Liga mundial, campeão mundial, templo (local 5), segunda arte e híbridos | 9 |
| Vilões mundiais, aliado/informante, páginas de quadrinho, música da noite | 9 (capítulo mundial) |
| Arte marcial do Gato Preto, golpe "da noite" | 10 |
| Revelar quem é o vulto | 11 |
| Prêmio de poder do Gato Preto (nó novo, bônus de lenda) | — (só se o dono pedir; pergunta 4) |
| James como parceiro de treino | — (direção narrativa: só se o dono pedir) |
| Cena nova (cutscene) para o James ou para a chegada ao complexo | — |
| Rede de academias, vários patrocinadores | a decidir com a gestão (13 se pedirem) |
| Mudança nos 6 adversários antigos, nos regionais e nos números do teto | — |
| Offline, sons novos, conquistas | 13 |

## 5. Save
- Tudo em **campos opcionais**, na v13 se couber: degrau da liga nacional, placar e "jeito da última vitória" contra o James,
  respeito visto, local `elite`, região ELITE, degrau do Ringue, prêmios e falas vistas.
- Save antigo no centro abre com a liga nacional aberta e **folga cheia** até a 1ª luta. A cópia do save do dono abre sem erro.

## 6. Critérios de aceite
### 8b1
1. **Nada muda antes:** com cada combinação, a foto (`foto.gd`) é igual à da main até a chegada ao centro.
2. **A liga abre:** chegar ao centro com o Cinturão do Vale mostra a data da 1ª luta nacional. O fim só volta depois do campeão.
3. **James estudou:** a passiva dele no nacional é a que trava o jeito da última vitória da escola, e a prévia diz qual em 1 linha.
   Sem vitória anterior, ele usa a padrão (Designer).
4. **Nunca imbatível e honesto:** para cada adversário nacional e cada uma das 6 combinações, existe 1 tática com ≥ 50% no treino
   mediano do degrau; em 1.000 lutas por adversário, a vitória real fica a ±5 pontos da prévia.
5. **Ritmo:** o 1º cinturão nacional vem **2–4 campanhas depois do 1º Cinturão do Vale** (mediana); as 6 combinações ficam a ≤ 15%
   entre si; tempo morto ≤ 10 min contando a liga nacional; lutas de 8 a 20 s; 1 clique ≥ 25% da renda/s no fim.
6. **Pendências:** BUG-2 fechado; `ronda2a_sim.py chefe` refeito e 1 noite animada cronometrada (≤ ~60 s); `teto` ≤ 10%.
### 8b2
7. Com o cinturão nacional e o dinheiro, MUDAR leva ao complexo, com multiplicador, aparelhos e gerador novo visíveis. Sem o cinturão,
   o botão não aparece. Tempo morto no complexo ≤ 10 min.
8. **Legado:** a região ELITE só aparece depois da 1ª mudança, nenhum nó antigo muda, e o Designer mostra que o Legado que sobrava
   passa a ter destino sem a árvore acabar de uma vez.
9. **Respeito:** toca uma vez na 1ª vitória sobre o James preparado, é pulável e dura ≤ 20 s; as falas seguintes dele são de respeito.
10. `teto` ≤ 10% de novo, com a região ELITE e o gerador novo.
### 8b3 e 8b4 (Ringue)
11. **Quem não usa o capuz = igual:** a foto de uma campanha inteira sem capuz é idêntica à da main antes da 8b3 (e da 8b4).
12. **Quem vai ao Ringue = quem só faz SUSTO:** mesma foto (dias, treino, dinheiro, FAMA, Legado, liga, `rng`). Só mudam os campos
    do Gato Preto, as falas do Osmar e a do James, que não mexem em número.
13. **Teto:** `ronda2a_sim.py teto`, numa corrida só com tudo junto (minigames, Ronda 1, 2a, Ringue, região GATO PRETO e ELITE),
    fica ≤ 10% em todo trecho.
14. **Destrave e dificuldade:** o Ringue só abre com lenda 6, Apagão vencido e cinturão nacional (testes com save no ponto certo e no
    errado). O campeão tem 30–50% na prévia para quem acabou de chegar, e o raro ≤ 20% por tentativa.
15. **Perder é pequeno:** não encerra carreira, não mexe em Legado, FAMA, dias nem AQUECIDO, não volta degrau da chave.
16. **Osmar e James:** as falas nunca dizem quem é o vulto (revisão do Diretor) e só aparecem para quem chegou no ponto. O vulto não
    mostra o rosto.
17. **Tom e originalidade:** sem sangue; busca por batman/morcego/gotham = 0; o dono aprova a amostra do campeão do Ringue.
18. **Prêmios:** fichas, estilos, troféus, título, marco no menu e variação do capuz aparecem no lugar certo, persistem e não mudam
    número.
### Todas
19. `tools/run_tests.ps1` verde, com save de teste, janelas em `--position 1950,40`, um Godot por vez, `--headless` sempre que der.
20. `ui_audit --estrito` com **0 problemas** nos estados novos de cada subfase, e o placar de `ignore` da rodada completa segue ≤ 15.

## 7. Riscos
- **James repetido:** ele aparece no regional e no nacional da mesma campanha. Proteção: no máximo 1 fala antes e 1 depois por luta,
  e falas diferentes nos dois degraus. Se cansar, o Designer põe o nacional dele só depois de vencê-lo no regional.
- **"Estudou a escola" virar muro:** a escola muda de jeito e passa. O critério 4 garante a saída; a prévia diz o que ele estudou.
- **Teto em 8,8%:** cada subfase mexe em Legado, região ou noite. Se passar de 10%, encolhe primeiro o ×1,4 da equipe da região GATO
  PRETO (regra da 2a).
- **Ringue inalcançável:** o Esconderijo mostra o que falta. Se ninguém chegar nos testes, baixa-se o limiar da lenda 6, não o prêmio.
- **Osmar entregar o segredo:** regra fixa de "estranha, nunca conclui". O Diretor revisa cada fala.
- **Custo de arte:** 8b1 (arena + 3 personagens, James reaproveitado) e 8b4 (chefe completo) são caras. Ordem de corte: pose de
  assinatura vira quadro parado; lutadores do Ringue no rig comum; público reaproveitado com paleta nova. Não se corta: arena
  nacional, rosto do campeão do Ringue e o "momento" dele.
- **Adiantar a 9:** nada de liga mundial, templo ou vilão mundial. O complexo fica com a campanha completa.

## 8. Perguntas ao dono (máximo 5)
1. **Divisão:** 8b1 liga → 8b2 complexo e respeito do James → 8b3 Ringue (chave) → 8b4 Ringue (campeão)? **Recomendo sim.**
2. **Cinturão nacional:** fica com um **campeão próprio**, e o James é a 3ª luta, estudando a escola (**recomendo**), ou o James é o
   dono do cinturão de novo?
3. **Campeão do Ringue da Lua:** o **Capivarão** escalado para nível nacional (**recomendo**: o senhor já gostou e estava guardado),
   o Rei Calota, ou um vilão novo do Roteirista? O Rei Calota pode ser um dos 2 lutadores da chave.
   - **Decisão do dono e do Produtor (2026-11-26):**
     - Fica para a 8b4: o dono escolhe pela amostra de arte, como fez com o Apagão.
     - Candidatos: o Capivarão, o Rei Calota e **O Roçador**.
     - O Roçador é uma ideia do dono no clima de terror de lenda urbana, original, sem nada de personagem de filme:
       - caseiro calado de um terreno baldio, de máscara de solda rachada com uma luz fraca, macacão de terra e um facão de roçar enorme;
       - o facão é só cena (ele crava no chão na entrada e luta de mão limpa; nada corta, sem sangue);
       - nunca corre nem fala;
       - passiva "NÃO CORRE": lento, mas aguenta e quase não cansa;
       - mote: "duas lendas no mesmo telhado".
     - O Sinaleiro, o Coronel Pipa e a Dona Marreta ficam de reserva.
4. **Prêmio de poder no Ringue:** continua **só visual e lore** (**recomendo**: o teto está em 8,8%), ou entra 1 nó pequeno medido?
5. **O Osmar desconfia:** só **balões curtos na sala quando a lenda sobe** (**recomendo**), ou também uma conversa pulável depois
   do campeão do Ringue?

## Resumo para o Produtor
- A 8b vira 4 subfases jogáveis, depois do item técnico 8b0 (`ignore` ≤ 15 e BUG-3, já tocado à parte).
- **8b1** abre a liga nacional saindo do centro: arena nova, 2 nacionais, o **James estudando a escola** e um campeão nacional próprio.
  Leva junto o BUG-2, o simulador do chefe, o `teto` e, depois do teste do dono, o passe de arte do Apagão.
- **8b2** traz o complexo de elite, a região ELITE (destino do Legado) e o respeito do James (fim do Arco 4).
- **8b3/8b4** trazem o **Ringue da Lua** (lenda 6, Apagão e cinturão nacional), com o Osmar desconfiando e o James ligando as tramas,
  tudo opcional, com o relógio parado, foto igual e teto ≤ 10%.
- 5 perguntas ao dono: divisão, quem segura o cinturão, campeão do Ringue (recomendo o Capivarão), poder (recomendo não) e Osmar.
