# Fase 7a — Lutas por arte + treino fora de hora: escopo

Diretor de Jogo, 2026-11-19. Base: `PROMPT.md` §5.6–5.7, `docs/roadmap.md` (7a), decisões do dono na `fase6d-escopo.md`
(minigame em tela própria, sempre opcional) e no pedido de hoje (Muay Thai fora, James Blindado na 8a, campeão mundial na 9).

## 1. Objetivo e sensação
- **Objetivo:** a arte escolhida passa a aparecer na luta (golpes, ritmo e um jeito próprio de vencer) e ganha um treino
  especial opcional, numa tela própria, que o jogador aceita quando quer.
- **Sensação:** "meu lutador de Boxe luta diferente do meu de Jiu-jitsu, e eu vejo isso na hora". E, de vez em quando:
  "o seu Osmar me chamou para um treino extra; vou porque é gostoso, não porque preciso".

## 2. Divisão (a 7a ficaria grande)
| Parte | O que traz | Ordem |
|---|---|---|
| **7a1 — Cada arte luta do seu jeito** | golpes e ritmo por arte, 1 passiva por arte (na prévia), arena da liga da academia | **primeiro** |
| **7a2 — Treino fora de hora** | o minigame em tela própria, com convite opcional | depois da 7a1 aprovada |

Por que nessa ordem: o minigame é "o treino especial da arte"; ele só faz sentido depois que o jogador sente a arte na luta.
E o dono escolhe o minigame (§5) enquanto a 7a1 é feita.

## 3. 7a1 — O que muda na luta com cada arte
Hoje a arte na luta é só um número (Boxe +10% de dano; Jiu-jitsu -10% de dano recebido) e os dois usam os mesmos golpes de boxe.

| | **Boxe** | **Jiu-jitsu** | **Sem arte** (Carreira 1, John) |
|---|---|---|---|
| Golpes | os de hoje (jab, direto, gancho, uppercut, estômago) | novos: empurrão no clinch, queda (pega a perna), pressão no chão e a finalização | igual a hoje |
| Ritmo | **mais rápido**: mais golpes por round, troca franca | **mais lento**: menos golpes, cada um pesa mais; a luta vai para o chão | igual a hoje |
| Passiva (proposta) | **Mão rápida:** ataca com intervalo menor. Ganha cedo, por K.O. | **Finalização:** a partir de um round (Designer), com o adversário abaixo de X% de vida, cada acerto tem chance de finalizar. Ganha tarde, por finalização | nenhuma |
| O que o jogador vê | muitos golpes, K.O. no 1º/2º round, letreiro "K.O." | queda, os dois no chão, letreiro novo "FINALIZOU!" | igual |
| Na prévia | 1 linha: nome e efeito da passiva | 1 linha: nome e efeito da passiva | nada |

Regras:
- A passiva entra no **motor** (`scripts/luta.gd`), e a prévia e o risco usam a mesma conta. **A prévia continua honesta.**
- Os traços de hoje (+10% / -10%) ficam ou são trocados pela passiva: o Designer decide, desde que o total da arte não fique mais forte.
- A derrota explica a passiva quando ela pesou (ex.: "faltou aguentar até o 3º round para a finalização").
- Os nós ESTILO da árvore (Contragolpe / Base firme) continuam valendo; o Designer diz se passam a reforçar a passiva.
- A **arena da liga da academia** (Tonhão e Kid lutam nela; a borracharia fica para a liga amadora). Lugar original, um degrau acima
  da borracharia e ainda pé no chão (sugestão para o Diretor de Arte: quadra coberta de escola do bairro, sábado, arquibancada de concreto).
- Pendência antiga que entra aqui (5.4, B2): estado "fim depois de derrota, com a arena visível" no `ui_audit`.
- Opcional, primeiro a cortar: 1 fala do mentor do caixote sobre estilo, quando ele lutou numa arte e o discípulo vence com a outra (Arco 3).

## 4. 7a2 — O minigame
### Regras fixas (decisão do dono)
- **Tela própria**, fora da sala.
- **Sempre opcional.** É um convite: o jogador aceita ou ignora. **Ignorar não custa nada**: nenhuma perda, nenhuma fala de bronca,
  nenhum aviso insistente.
- **Ir nunca custa nada:** o relógio da campanha para fora da sala (regra da 5.3) e a equipe continua produzindo durante o minigame.
- Só existe com arte escolhida (é treino da arte).

### Lugar na história, convite, duração, frequência
- **Lugar:** depois do expediente, o seu Osmar leva o lutador para treinar "fora de hora" (praça do bairro ou fundos da academia, à noite,
  luz de poste). O Osmar está nos dois locais e sonha formar um campeão: é natural ele chamar.
- **Convite:** um balão pequeno do Osmar na sala, com um botão "IR" (ou clicar no Osmar). Nunca abre sozinho, nunca trava a sala,
  nunca aparece em cena, fala, janela aberta, luta ou no dia da luta.
- **Ignorar:** o balão some sozinho depois de um tempo (proposta: no fim do dia seguinte da campanha). Convites não acumulam.
- **Frequência:** proposta de 1 convite a cada ~3–4 min de sala (o Designer fixa em dias de campanha, em `data/`).
- **Duração:** 20 a 30 s, com SAIR a qualquer hora (sai com o que já ganhou).
- **Recompensa:** treino nos atributos da arte, igual a alguns segundos da produção atual (escala sozinha com o jogo). Piso garantido
  só de ir; jogar bem dá mais, com teto. Mostrada grande no fim ("+N FORÇA").
- **Peso:** fazer todos os convites de uma campanha com nota máxima acelera a campanha **no máximo 10%**. Mais que isso vira obrigação.

### Três ideias (o dono escolhe)
| | Ideia | Como é | Prós | Contras |
|---|---|---|---|---|
| **A (recomendo)** | **Manopla do seu Osmar** | **Boxe:** o Osmar levanta a manopla em lugares diferentes e chama "um-dois!"; clicar na manopla acesa antes de ela baixar; as sequências crescem. **Jiu-jitsu:** "pegada": segurar o botão para apertar a pegada e soltar quando o marcador estiver na faixa certa (raspagem/finalização), 4–5 vezes | tem a cara de cada arte; é clique com impacto (juice forte); reaproveita o Osmar | duas variantes de arte e de regra |
| B | **Corrida até a padaria** | de madrugada, clicar no ritmo dos passos; errar o ritmo só diminui o ganho | a mais simples de fazer; muito "pé no chão" | igual para as duas artes, não parece "treino da arte" |
| C | **Roda de sparring de sexta** | 3 trocas rápidas contra alunos, escolhendo golpe ou defesa no tempo | parece luta | confunde com a luta de verdade, que é decidida pelos números; só cabe na academia |

**Recomendo A.** Se a arte do Jiu-jitsu apertar, a variante dele usa a mesma tela e o mesmo Osmar, mudando só o objeto (faixa no lugar da manopla).

## 5. Fica de fora
| Item | Fase |
|---|---|
| Muay Thai (arte, golpes, chute rodado) | 7b |
| Passivas liberadas por meta (2ª passiva da arte) | 7b |
| Passiva própria de cada adversário na prévia | 8a, com os adversários novos (ver pergunta 2) |
| Rival James Blindado, liga regional, arena regional, local 3 | 8a |
| Campeão mundial, segunda arte / híbridos | 9 |
| Mais de um minigame, ranking ou recorde do minigame | — (só se os testadores pedirem) |
| Cliques durante a luta dando boost | 13, se pedirem |
| Mudança de preço, Legado, Honra, calendário ou escada | — |

## 6. Save
- **7a1:** sem versão nova. A arte já está no save; golpes e passivas vêm de `data/`. Continua v13.
- **7a2:** só o dia do último convite (e se ele está aberto). Entra na v13 como campo opcional com valor padrão, **sem migração**.
  Se o Designer precisar de mais que isso, vira v14 com migração simples. Fechar o jogo no meio do minigame = convite ignorado;
  a recompensa só entra no fim (ou no SAIR) e salva na hora.

## 7. Critérios de aceite
### 7a1
1. Com Boxe, o jogador vê golpes de boxe, ritmo rápido e "K.O."; com Jiu-jitsu, vê queda, luta no chão e "FINALIZOU!" em pelo menos
   1 de cada 3 vitórias contra o Tonhão. Um testador diz qual é a arte só olhando a luta.
2. A prévia mostra a passiva da arte em 1 linha. **Prévia honesta:** em 1.000 lutas simuladas por adversário e arte, a vitória real fica a
   ±5 pontos da chance mostrada.
3. Sem arte (Carreira 1), a luta e o balanço não mudam: `tools/refatoracao/foto.gd` igual à main até a escolha da arte.
4. Luta continua curta: 8 a 20 s, com ou sem finalização.
5. Tonhão e Kid lutam na arena nova; os 4 amadores continuam na borracharia.
6. **Balanço medido** (Designer, simulação em `tools/sim`): tempo até vencer o Kid com Boxe e com Jiu-jitsu, a 3 e a 4 cliques/s.
   Diferença entre as artes ≤ 15%; nenhuma é "a certa". Metas da visão mantidas (1ª carreira 10–15 min, cinturão amador entre a 2ª e a
   4ª carreira, tempo morto ≤ 10 min). Atacar a nota da 5.4: "Kid fácil a 4/s, Jiu-jitsu 1 campanha atrás".
### 7a2
7. O convite aparece na frequência dos dados, nunca em cena, fala, janela, luta ou dia da luta, e some sozinho se ignorado.
8. **Ignorar não custa nada:** uma campanha ignorando todos os convites dá exatamente o mesmo resultado que antes da 7a2 (foto igual).
9. **Ir nunca custa:** do clique em IR até a volta à sala, o relógio da campanha fica parado e a equipe produz.
10. O minigame dura 20–30 s, tem SAIR a qualquer hora, e o piso de recompensa é maior que 0.
11. **Teto:** campanha fazendo todos os convites com nota máxima é no máximo 10% mais rápida que a campanha ignorando todos (medido pelo Designer).
12. Fechar o jogo no meio do minigame não duplica nem perde recompensa; save antigo (cópia do save do dono) abre sem erro.
### As duas partes
13. `tools/run_tests.ps1` verde, com testes novos usando **save de teste** (APPDATA temporário); janelas com `--position 1950,40`.
14. `ui_audit` com **0 problemas**, incluindo: prévia com a passiva de cada arte; arena nova (luta e "fim depois de derrota com arena");
    letreiro "FINALIZOU!"; balão do convite nos dois locais; tela do minigame no começo, no meio e na tela de recompensa, nas duas variantes.

## 8. Quem faz
| Papel | 7a1 | 7a2 |
|---|---|---|
| **Designer** | passivas, ritmo, se o traço de hoje fica, nós ESTILO, motivo da derrota, simulação e balanço (§7.6) → `fase7a-design.md` | regras do minigame escolhido, recompensa, frequência, piso/teto, medida do §7.11 |
| **Roteirista** | nomes das passivas, "FINALIZOU!", nome da arena, fala de estilo (opcional) | falas do convite do Osmar (2–3), textos da tela, nome do treino |
| **Diretor de Arte** | arena da academia (mockup antes) | cenário do treino fora de hora, manopla/faixa, mockup da tela |
| **Artista de Personagens** | golpes do Jiu-jitsu (clinch, queda, chão, finalização) e reações do adversário, pela `padrao-personagem` | Osmar com manopla (e faixa); poses do lutador no minigame |
| **Programador** | passivas no motor e na prévia, golpes por estilo em `moves.json`, arena por liga, testes | estado do convite, recompensa, save, testes |
| **UI/UX** | linha da passiva na prévia, letreiro, arena; `alinhamento-ui` 0 problemas | balão do convite, tela do minigame, juice; `alinhamento-ui` 0 problemas |
| **QA** | critérios 1–6, 13, 14 | critérios 7–14 |

## 9. Riscos
- **Arte do Jiu-jitsu cara** (luta no chão com dois corpos). Ordem de corte: (1) pressão no chão vira uma pose só; (2) finalização sem
  animação própria, só o letreiro e a queda. Não se corta: a queda e o "FINALIZOU!".
- **Finalização parecer sorte** e quebrar a prévia honesta. Proteção: conta no motor, linha na prévia e no motivo da derrota.
- **Minigame virar obrigação.** Proteção: teto de 10%, convite que não acumula, nada de aviso insistente.
- **Minigame de reflexo contra "lutas decididas pelos números".** Proteção: ele é treino, nunca decide uma luta.

## 10. Perguntas para o dono
1. **Qual minigame?** A (manopla do Osmar, recomendo), B (corrida até a padaria) ou C (sparring de sexta).
2. **Passiva de cada adversário** (o roadmap pôs na 7a): recomendo deixar para a 8a, quando chegam adversários novos, para a 7a ficar
   pequena. Concorda?
3. As passivas propostas (Boxe "Mão rápida", Jiu-jitsu "Finalização") combinam com o que você imagina das artes?

## Resumo para o Produtor
- A 7a foi dividida em duas: **7a1** (cada arte luta do seu jeito: Boxe rápido que vence por K.O., Jiu-jitsu lento que leva ao chão e
  vence por finalização, arena nova da academia) e depois **7a2** (o minigame "treino fora de hora", chamado pelo seu Osmar).
- O minigame é sempre opcional: um balão com "IR"; ignorar não custa nada e ir também não (relógio parado, equipe produzindo); 20–30 s;
  ganho limitado a 10% da campanha.
- Três ideias de minigame; **recomendo a A, a manopla do seu Osmar** (Boxe acerta a manopla, Jiu-jitsu aperta e solta a pegada na hora certa).
- Save continua v13. Muay Thai (7b), rival (8a) e campeão mundial (9) ficam de fora.
- Três perguntas ao dono: qual minigame, se a passiva dos adversários fica para a 8a, e se as passivas das artes combinam com ele.

## 8. Decisões do dono (2026-11-19) — valem sobre o texto acima
1. **Passivas como "jeito de montar o lutador"**, não só número:
   - **Boxe — Mão rápida:** chance de K.O. cresce com AGILIDADE e com **embalo** (acertos seguidos na luta); depois do 2º round o
     boxeador **cansa**. Tática agressiva acaba cedo, mas arrisca contragolpe.
   - **Jiu-jitsu — Finalização:** cada round sobrevivido enche a **barra de pegada**; com ela cheia, a finalização fica possível.
     RESISTÊNCIA para chegar, FORÇA para fechar. Tática defensiva enche a pegada mais rápido.
   - Focos de treino passam a ter um "certo" diferente por arte; nós ESTILO reforçam a passiva; a prévia mostra a barra/embalo e a chance real.
2. **Passiva dos adversários fica para a 8a** (com estilos que neutralizam cada arte).
3. **Minigame (7a2) — trocado:** sai a "Manopla"; entram **dois**:
   - **Choque (sparring):** cabo de guerra numa barra; o adversário empurra com ritmo próprio (rajadas, pausas, fintas, com aviso).
     Camadas: **fôlego** (clicar rápido demais enfraquece), **ler o aviso** e segurar, **contragolpe** na pausa dele (clique vale 2x).
     Variante **Boxe** = troca franca por cliques; variante **Jiu-jitsu** = disputa de pegada (segurar para puxar, soltar quando ele puxa forte).
     Prêmio: treino nos atributos da arte; vencer dá **embalo** (bônus pequeno) na próxima luta oficial, mostrado na prévia.
   - **Panfletagem da escola** (do mundo): distribuir panfletos da Raízes, clicando em quem parece interessado (ler sinais); errar custa pouco.
     Prêmio: FAMA ou um discípulo um pouco melhor na próxima sucessão.
   - Regras gerais mantidas: convite do Osmar, ignorar não custa nada, 20–40 s, SAIR a qualquer hora, relógio parado, teto de 10% somando tudo.
     Cada minigame dá um tipo de prêmio diferente. "Bico na padaria" fica para depois.
4. **Gato Preto (vigilante do bairro):** personagem **original** (capuz preto com orelhas costuradas, faixa da escola como máscara,
   capa de lona), referência ao arquétipo do herói noturno **sem copiar o visual do Batman**. Na **7a2 só a semente** (recorte de jornal
   e boato do Osmar). A **Ronda Noturna** (minigame com fama própria do Gato Preto) fica para uma fase própria, perto da 8a.
