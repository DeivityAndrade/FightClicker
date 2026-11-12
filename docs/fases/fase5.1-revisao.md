# Fase 5.1 — Garagem clara + caixa: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-12. Branch: `fase-5.1`.
Base: `fase5.1-escopo.md`, `fase5.1-design.md`, `fase5.1-api.md`, `fase5.1-qa.md` (12/12 critérios OK, 4 bugs baixos), capturas `f51_garagem`, `f51_caixas_varias`, `f51_caixa_abrindo`, `f51_previa`, `f51_anim_esteira` em `%APPDATA%\Godot\app_userdata\Fightclicker\ui_audit_saida\`.

## Veredito: APROVADO — pode ir para o dono

Os 4 bugs do QA foram corrigidos depois do relatório:
- B1: caixa da arte foi para (204,283) e não encosta mais na da corda.
- B2: caixa da luva subiu para (386,280) e ganhou folga do rodapé.
- B3: textos da abertura saem um embaixo do outro (na captura só aparece "ABRIU!", limpo).
- B4: botão do assistido foi para o canto esquerdo do chão e não cobre mais a esteira.
- `ui_audit`: 126 estados, 0 problemas. `run_tests.ps1` passa inteiro, sem tocar o save real.

Não sobra nada que impeça mostrar a fase. Os ajustes da seção 4 são pequenos e podem esperar a resposta do dono.

## 1. Entregou o que o dono pediu?
| Pedido do dono | Resultado | Onde se vê |
|---|---|---|
| "A garagem é bonita demais pra ser ofuscada por tanta informação" | **Sim.** Sumiram as plaquinhas, o "SEGURE SHIFT" e o chip da arte. Na sala só ficam pessoas, aparelhos, marcas de fita sem texto e caixas. A arte da garagem finalmente aparece. | `f51_garagem` |
| "Tudo com a mesma cara" | **Sim.** Só 2 tamanhos de texto (x2 para Treino, por clique e LUTAR; x1 para o resto). Cada moeda tem uma cor só: Treino verde, Dinheiro dourado, Fama rosa e Legado roxo. Rótulos e o que não dá para comprar ficam apagados, e nenhum preço fica vermelho. O olho vai primeiro no Treino, depois no lutador e no LUTAR. | `f51_garagem`, `f51_caixas_varias` |
| Prévia apertada | **Sim.** Os blocos estão separados: quem luta, atributos, risco, tática, prêmio e aviso, botões. O aviso "perder encerra a carreira" continua visível e o LUTAR é o maior botão. | `f51_previa` |
| Corda | **Sim.** Agora fica num gancho na parede (296,166), nas 2 salas, e os 6 quadros do giro saíram sem quadro torto. | QA, critério 6 |
| Caixa com 3 cliques | **Sim.** Racha, racha e abre, com a tremida crescendo. A abertura leva 1,2 s e o foco vai para o aparelho. A caixa nunca some, não fica no caminho do alvo e clicar nela não treina. São 5 caixas por carreira, e abri-las toma cerca de 1,5% do tempo. | `f51_caixa_abrindo`, `f51_caixas_varias`, QA |
| Top 3 animações | **Entregue** a escolha do Diretor: saco, esteira e equipe (gifs em `docs/arte/mockups/fase51_animacoes_*`). Falta o dono confirmar se eram essas. | `f51_anim_esteira` |

## 2. O que ficou bom
- A sala voltou a ser o jogo: num olhar de 5 s você vê o Treino grande, o lutador no meio e o LUTAR vermelho (que é a cor do risco "PERIGOSO").
- A caixa é a identidade da fase: tem etiqueta da escola, abre com 3 cliques e conta a história sem nenhuma fala. É 100% nossa.
- Toda informação continua a 1 hover de distância (Fama, Legado, local, prêmio, teclas e bloqueados). Nada sumiu do jogo, só mudou de nível.
- O balanço ficou intacto: 1ª derrota em 11–13 min e cinturão nunca antes de 20:25.
- Se o dono preferir a luva instantânea, basta trocar uma linha de dado (`applies_to.glove = false`), sem mexer em código.

## 3. Passou do escopo?
**Não.** Nada da 5.2 em diante entrou: luvas L3/L4, teto do clique, Metrônomo e Shift novos, Kid, calendário e falas ficaram de fora. O som do "tchan" ficou como já estava no projeto.
Três decisões de UI foram além da letra do escopo, mas dentro do espírito dele. O dono confirma as três (seção 6):
- O chip da arte foi para a dica do nome do local, no HUD.
- O chip "METRÔNOMO TOCANDO" foi tirado da sala. O número "AUTO +X/S" continua na barra de baixo.
- A dica do Shift conta as 3 primeiras vezes **por sessão**, sem gravar no save.

## 4. Desvios pequenos (não bloqueiam; resolver depois que o dono jogar)
- **Dois destaques na loja ao mesmo tempo:** o mais barato tem contorno amarelo e o aparelho novo tem contorno laranja. O escopo pedia um destaque só. Ver se o dono estranha.
- **"0/4" das melhorias** está apertado embaixo do ícone (`f51_garagem`). É legível, mas está colado.
- **Texto flutuante grande** ("+3 RESISTÊNCIA!" e "A ESTEIRA GEMEU!") cobre metade da sala por um instante. É juice e some sozinho, mas se o dono disser "ainda tem texto demais", começa por aqui.
- **Coluna esquerda vazia** abaixo de PRÓXIMA. É respiro e não é defeito; não preencher sem motivo.
- **Pôster "SOCO"** é arte de cenário e não conta como texto fixo. Fica.

## 5. O que fica para a 5.2
- Já previsto: luvas L3/L4, teto do clique, luva que paga a equipe, Metrônomo e Shift, Jiu-jitsu no Kid.
- Vigiar o tempo morto da carreira 1 para quem clica 3–4 vezes por segundo: a mediana fecha, mas os 10% mais lentos chegam a 11:31–13:32, e a caixa somou cerca de 30 s. A 5.2 mexe no Metrônomo e no teto do clique, então é a hora certa de corrigir.
- O robô do simulador perde mais para o Dudu (são 3 s a menos de treino aos 3:00). Conferir junto.
- Aplicar o que o dono responder no roteiro abaixo (luva instantânea, próximas 3 animações, contador do Shift, chips).

## 6. Perguntas de UI para o dono
1. **Chip da arte:** a arte escolhida (Boxe ou Jiu-jitsu) agora aparece no hover do nome do local e no botão de foco do aparelho da arte. Dá para achar quando você quer?
2. **"METRÔNOMO TOCANDO" saiu da sala:** sentiu falta de ver que o Metrônomo está ligado, ou o "AUTO +X/S" na barra de baixo basta?
3. **Dica do Shift por sessão:** ela aparece nas 3 primeiras vezes cada vez que o jogo é aberto. Incomoda ver de novo, ou ajuda? (Se incomodar, passa a contar no save.)

## 7. Roteiro de teste para o dono (~8 min)
Antes de começar: a caixa só aparece quando você **compra** algo novo. Aparelho que já estava comprado no save antigo continua montado. Se a sua carreira já tem tudo, use a próxima carreira para ver as caixas (toda carreira começa só com o saco).

**Minuto 0–1: a tela (pontos 1 e 2)**
- Abra o jogo e olhe a garagem por 5 segundos, sem ler nada. Você sabe onde clicar, quanto Treino tem e onde lutar?
- Passe o mouse no nome do local, no grupo da Fama e do Legado (topo à direita), no PRÓXIMA, no "?" da barra de baixo e numa marca de fita no chão.
- **Pergunta 1:** a tela ficou clara? **Pergunta 2:** faltou alguma informação que você usava?

**Minuto 1–4: a caixa (pontos 3 e 4)**
- Compre a esteira e clique 3 vezes na caixa que aparece. Repare na tremida e no "tchan".
- Compre uma luva na LOJA e abra a caixa dela, que fica perto do lutador.
- Para testar: deixe uma caixa com 1 ou 2 cliques, vá lutar e volte, feche e reabra o jogo. Ela continua lá, com os mesmos cliques.
- **Pergunta 3:** os 3 cliques dão vontade de abrir ou cansam? **Pergunta 4:** a luva na caixa ficou boa, ou você prefere que ela chegue na hora?

**Minuto 4–6: as animações e a corda (pontos 5 e 6)**
- Treine no saco, troque o foco para a esteira (tecla 2) e repare no Vizinho e no Tio treinando ao fundo.
- Compre a corda, abra a caixa e treine nela. Olhe a altura do gancho e o giro.
- **Pergunta 5:** saco, esteira e equipe eram as animações que você achava mais fracas? Se não eram, quais são as próximas 3? **Pergunta 6:** a corda está na altura certa?

**Minuto 6–8: a prévia (ponto 7)**
- Clique em LUTAR para abrir a prévia. Leia de cima para baixo: quem é ele, atributos, risco, tática, prêmio e aviso.
- **Pergunta 7:** dá para ler com conforto, ou ainda parece apertado?
- Por fim, responda as 3 perguntas de UI da seção 6: chip da arte, Metrônomo e dica do Shift.

## Resumo para o Produtor
A Fase 5.1 está **aprovada**: a garagem voltou a ser o jogo, com 2 tamanhos de texto, uma cor por moeda e nada escrito sobre a cena. A prévia ganhou respiro e a corda desceu para o gancho.
A caixa da escola funciona: abre com 3 cliques, nunca some e não atrapalha o treino nem o balanço. Os 4 bugs do QA estão corrigidos e o audit dá 0 problemas.
Nada passou do escopo. Para a 5.2 ficam o que já estava previsto e a vigilância do tempo morto de quem clica devagar.
Peça ao dono o roteiro de ~8 min (seção 7), as 7 respostas e as 3 perguntas de UI. A luva instantânea, se ele quiser, é uma troca de dado.
