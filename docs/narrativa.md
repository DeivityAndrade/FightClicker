# Narrativa — bíblia curta

Dono: Roteirista. Versão 1 (2026-11-05). Base: `PROMPT.md` §3, `docs/visao.md`.
Identidade 100% original. Nada de nomes, personagens ou falas de outros jogos.

## Regras de texto
- Português do Brasil, natural, curto: o jogador lê em 2 segundos.
- Nomes de item até ~16 caracteres; descrição até ~44.
- Humor seco: a piada vem do detalhe, não do grito. Ninguém explica a graça.
- Texto nunca trava o loop. Diálogo só em marcos e sempre pulável.
- Nada de humilhar o jogador. A derrota dói, mas explica e deixa algo.

## Protagonista e elenco da origem (Fase 6a, nomes escolhidos pelo dono em 2026-11-13)
- **John Bullet** é o 1º lutador: fixo, com nome, rosto e gesto ("fecho e dois toques"). Plaquinha "John". Fala pouco e seco, com um sorriso no fim. Vira o primeiro mentor e, mais tarde, o adversário final.
- **Osmar Brandão** é o treinador original ("seu Osmar"). Voz rouca e lenta; conta histórias que parecem exagero. Sonha em formar um campeão.
- **Raízes Fight Club** é a escola. O nome nasce na ficha do torneio do bairro, onde John ficou com "ESCOLA: NENHUMA" e o Seu Muralha riu. O 1º cinturão amador salva a garagem e a ficha passa a dizer "ESCOLA: RAÍZES FIGHT CLUB".
- A partir da Carreira 2, os discípulos têm nome e aparência próprios (personalização na 6b). Até lá, "discípulo padrão" sem nome.
- A UI ainda usa "Carreira N" para a campanha. O jogador não nomeia John.
- A garagem guarda marcas da linhagem: aviso de cobrança, foto antiga, ficha, recorte, foto da equipe. Detalhe, não sistema.
- Textos completos em `docs/fases/fase6a-textos.md`.

## Tom por local

| # | Local | Tom | Como o texto soa | Exemplo |
|---|---|---|---|---|
| 1 | Fundo de garagem | Pé no chão, melancólico | Gambiarra, esforço, vizinhos. Ninguém é pago. | "Mais fita, menos areia no chão." |
| 2 | Academia de bairro | Realista, calor humano | Rotina, mensalidade atrasada, pôster desbotado. | "O espelho trinca onde você sempre bate." |
| 3 | Centro de treinamento | Profissional, meio frio | Logos, metas, planilha. A graça é o jargão. | "Meta do trimestre: 40 socos por hora." |
| 4 | Complexo de elite | Luxo caricato | Exagero de marca, câmera em tudo. | "Sua toalha tem assessor de imprensa." |
| 5 | Templo na montanha | Lendário, calmo, absurdo sério | Frases curtas, proverbial, um urso comum. | "O urso não julga. Só te ganha." |
| 6 | Dojo no fim da realidade | Absurdo total, quase poético | Regras do mundo dobradas, sem explicar. | "O soco chegou antes de você sair." |

Escala: cada local sobe um degrau do absurdo, sem quebrar o anterior. A garagem tem que continuar
engraçada e triste quando o jogador voltar a ela em outra carreira.

## Elenco (reservado, entra na Fase 8)
- **Mentor:** John Bullet (o 1º lutador) e, depois, os lutadores das carreiras anteriores. Falas curtas, voz de quem já apanhou. Marcos de progresso.
- **Rival recorrente:** aparece em cada camada; humilha no começo, é o chefe do título mundial. Caricato, nunca cruel.
- **Gente do bairro** (Fase 2): Vizinho da casa 12, Tio aposentado. Nomes e piadas em `docs/fases/fase2-textos.md`.

## Escada amadora (Fase 3)
Luta clandestina de bairro, valendo pouco. Todos têm cara de gente que você já viu na rua. Textos completos em `docs/fases/fase3-textos.md`.

| id | Nome | Perfil | Em uma linha |
|---|---|---|---|
| `opp_warmup` | Dudu Alongado | equilibrado, fraco | Alonga mais do que luta. |
| `opp_strong` | Brutão do Posto | Força | Carrega botijão no braço. |
| `opp_fast` | Dinho Pulga | Agilidade | Você pisca e ele já bateu. |
| `opp_tank` | Seu Muralha | vida, dono do cinturão | Não cai, só cansa. |

## Academia Boa Esquina (Fase 5)
Local 2. A academia de bairro tem nome: **Academia Boa Esquina** (pôster desbotado, mensalidade atrasada, espelho trincado). Textos em `docs/fases/fase5-textos.md`.

| id | Nome | Perfil | Em uma linha |
|---|---|---|---|
| `opp_gym_1` | Tonhão do Tatame | resistente | Faixa roxa de cor duvidosa. Pesa e não sai. |
| `opp_gym_2` | Kid Navalha | rápido | Campeão da casa. Corta o ar e a conversa. |

Artes: **Boxe** (aparelho: Pera veloz; técnicas Jab duplo, Esquiva e volta; nó Mão de sino) e **Jiu-jitsu** (aparelho: Boneco de tatame; técnicas Guarda fechada, Raspagem; nó Peso do tempo). "Pêndulo" é só do Metrônomo.

Loja do bairro: Prof. Nelson (cobra por hora) e luvas de lona, couro e "de marca". Derrota explica com número e dica; aposentar é "sair por cima".

## Glossário

| Termo | Significa | Observação |
|---|---|---|
| Carreira | uma run do lutador, da garagem à derrota ou à aposentadoria | UI: "Carreira 1" |
| Treino | moeda e progresso gerado por clique e por gente treinando | verde; gasta-se, atributo não cai |
| Atributo | Força, Agilidade, Resistência | cores: vermelho, azul, amarelo |
| Foco | aparelho no centro que recebe o treino | "FOCO DE TREINO" |
| Aparelho | onde se clica (saco, corda, esteira) | não é gerador |
| Gerador | gente que treina sozinha | na Fase 2 só "gente do bairro" |
| Melhoria | gambiarra que melhora um aparelho | troca o sprite |
| Legado | moeda permanente entre carreiras | só a partir da Fase 3 |
| Aposentar | encerrar a carreira por cima | Fase 3 |
| Linhagem | a sequência de lutadores, cada um mentor do seguinte | tema central |
| Mentor | o lutador anterior | Fase 8 |
| Rival | adversário recorrente | Fase 8 |

## Pendências
- Nome oficial do jogo (Fightclicker é nome de trabalho).
- Nome do rival (Fase 8). O 1º mentor já tem nome: John Bullet.
- Vozes dos locais 3 a 6 (escritos quando entrarem).
