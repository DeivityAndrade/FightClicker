# Fase 7b2 — Segundo caminho (a 2ª passiva): revisão do Diretor

Diretor de Jogo, 2026-11-21. Worktree `continue-agents-config-722700`, sem commit. Base: `fase7b-escopo.md` (§4, §7 critérios 9–14
e decisões do dono), `fase7b2-design.md` (com as **decisões do dono de 2026-11-21**: N = 3 e equilíbrio pela mediana, sem
fortalecer o Por cima), `fase7b2-textos.md`, `fase7b2-qa.md`, `docs/arte/fase7b2-manifest.md`. Também olhei as capturas novas dos
letreiros (`capfull4\f7b2_luta_cp_ko_liga.png` e `f7b2_luta_mt_joelhada.png`).

## Veredito
**Aprovada com ressalvas.** Nada volta para Designer, Programador ou Arte. Os dois bugs do QA estão corrigidos:
- **B1:** os letreiros ficam em z 3000 e limpam os números de dano da área. Conferi duas capturas: "K.O. NO CONTRAGOLPE!" e
  "JOELHADA!" estão limpos, e os números ficam abaixo, perto dos lutadores.
- **B2:** o selo "ÚLTIMA: BOXE" subiu 3 px.

O `ui_audit` dá 470 estados com 0 problemas, e os testes `test_fase7b1` (270/270) e `test_fase7b2` (320/320) passam.

**Uma condição antes do merge (QA ou Produtor):** rodar o `tools/run_tests.ps1` **inteiro** uma vez, headless. A correção do B1 mexeu
na `tela_luta.gd`, e depois dela só os dois arquivos da 7b foram rodados. O teste da cena principal (120 quadros) também passa pela
luta. Se ficar verde, pode integrar. Se falhar, o problema volta para o **UI/UX**.

## O que bate com a visão
- **É escolha, não soma.** A 2ª passiva substitui a 1ª, vale para a carreira inteira e só aparece depois da meta. Nenhuma arte ficou
  mais forte do que era. Isso era a proteção principal contra o power creep (§9 do escopo).
- **Cada 2ª é outro jeito de lutar:**
  - O **Contragolpista** espera e vira a luta no 3º round. Pede o Contra-ataque e RESISTÊNCIA.
  - O **Por cima** leva a luta para o chão já no 1º round. Pede FORÇA e o Agressivo.
  - O **Clinch** luta colado, sem mancar e sem marcas. É a única passiva do jogo que ataca no Defensivo.
  - Cada uma é pior que a sua 1ª em pelo menos 1 adversário. Nenhuma é "a 1ª melhorada".
- **Quem lê a luta vê os sinais:** a carga aparece em 100% das vitórias do Contragolpista, o chão em 88–98% das do Por cima e o
  clinch em 50–86% das do Clinch. Com a 1ª passiva, esses sinais aparecem em 0%.
- **A meta ensina a 1ª passiva antes de dar a 2ª.** O progresso aparece no cartão ("2/3 K.O. DE EMBALO"), e o aviso sai uma vez só.
  Isso combina com a ideia de que a linhagem conta a história.
- **Quase nenhuma arte nova:** só reaproveitamento de animações, 3 ícones, a carga, o cadeado e 3 letreiros. Era o custo prometido no
  escopo.
- **Nada mudou para quem não usa a 2ª:** a foto sem arte é igual à da main, e o simulador deu 3.000 de 3.000 lutas idênticas na 1ª
  passiva. O save continua v13 e aguentou 16 casos de save sujo. A cópia do save do dono abre sem erro.
- **O tom está certo.** "Três chutes rodados. Agora cola nele e joelha." é pé no chão, na voz do Osmar.

## As observações do QA (R1–R5)

### R3: prévia honesta. **Passa.**
- O critério 12 vale como na 7b1 (critério 2): **média por adversário em 1.000 lutas, ±5**. Medido: de −3,3 a +2,2.
- O pior estado isolado (10,3 pontos) vem das 200 sementes fixas da própria prévia. É o mesmo padrão da 7b1. Exigir que **todo**
  estado fique a ±5 custaria CPU na tela de prévia, e o ganho não aparece para o jogador.
- **Tarefa futura (Designer, na próxima vez que mexer em balanço):** contra o Brutão e o Dudu, a prévia sai **otimista** em 2 a 3
  pontos nas três artes. É pouco, mas o desvio vai sempre para o mesmo lado. Vale conferir se o "fator de amador" do motor ainda está
  bem ajustado. Não bloqueia a fase.

### R4: a meta de 3 leva cerca de 3 campanhas no robô padrão. **Aceito, com registro.**
- O robô padrão só olha a chance e quase nunca escolhe a tática da passiva. O jogador vê "2/3 CHUTES RODADOS" no cartão e "N EM 10"
  na prévia, então busca a meta de propósito. Com N = 5, o robô que **busca a meta** já precisava de 3–4 campanhas. Com N = 3, a
  conta dá cerca de 2, que é o que o escopo pediu.
- O caso que preocupa é o **Muay Thai a 3 cliques/s**: 13 de cada 100 robôs padrão não liberam a meta em 6 campanhas. A causa é que o
  chute rodado sai pouco para quem fica no Defensivo (ver a revisão da 7b1, ponto 1). A prévia avisa.
- **Tarefa futura (Designer):** medir com N = 3 o robô que **busca a meta** (a tabela da §9.3 foi feita com N = 5). Se o Muay Thai
  passar de 3 campanhas na mediana, levar ao dono uma meta por arte (dá para mudar só no dado, `unlock.count`). Não mudo agora: o N
  foi decisão do dono, e o teste dele vai dizer se a espera incomoda.

### R1: o Clinch aparece em 50–65% das vitórias contra o Tonhão. **Passa.**
- Na 7b1, a régua do reconhecimento foi aparecer em **1 de cada 3** vitórias. O Clinch fica bem acima disso.
- Além do clinch, o Muay Thai do Clinch tem outro sinal: o adversário **não manca** e não ganha marcas. A diferença para a Canela se
  vê mesmo na luta em que ele não prende.
- A prévia já avisa quando o clinch é raro ("SÓ PRENDE EM n DE 10 LUTAS"). O teste do dono é feito no Defensivo, que é a tática da
  passiva.

### R2: os fins especiais são raros para quem está muito forte. **Passa, é o desenho.**
- A pista principal de cada passiva é o **meio** da luta: a carga, o chão e o clinch. O letreiro do fim é a recompensa de quem luta
  apertado, contra o Kid ou um degrau acima, na tática da passiva. Nesses casos, os fins especiais saem em 3 a 6 de cada 10 vitórias.
- Isso ainda conversa com o incremental: quem treinou demais ganha por pontos. A prévia mostra "N EM 10", então ninguém é enganado.

### R5: a média a 3 cliques/s fica 19,5% acima da combinação mais rápida. **Aceito, pela decisão do dono.**
- O dono decidiu medir pela **mediana**, e a mediana dá 1,8% a 3/s e 2,6% a 4/s. A média alta vem de 1 em cada 10 jogadores do Por
  cima, que leva campanhas a mais. O dono também decidiu não fortalecer o Por cima.
- **Registro:** se os testadores reclamarem que o Por cima "empaca", as alavancas já estão anotadas no design (§14.4). Até lá,
  ninguém mexe.

## Ressalvas que viram tarefa futura
| # | O quê | Peso | Quem |
|---|---|---|---|
| D1 | Rodar o `run_tests.ps1` inteiro depois da correção do B1 | **antes do merge** | QA ou Produtor (UI/UX, se falhar) |
| D2 | Ninguém viu na janela o balão da fala do Osmar, as animações em movimento nem o teste de reconhecimento por uma pessoa. Tudo isso entra no roteiro do dono | dono testa | Produtor |
| D3 | Prévia otimista em 2–3 pontos contra o Brutão e o Dudu (R3) | próxima rodada de balanço | Designer |
| D4 | Medir o tempo da meta com N = 3 para o robô que busca a meta; olhar o Muay Thai a 3/s (R4) | próxima rodada de balanço | Designer |
| D5 | O `fase7b2-design.md` ainda fala em "5" em alguns trechos (§9.1, §13 "{n}/5", §16.1 `count: 5`, §17 testes "4/5"). O dado e os textos já usam 3. Só o documento precisa de limpeza | documento | Designer |
| D6 | Cauda do Por cima a 3/s (R5): só mexer se os testadores reclamarem | observação | Designer |
| D7 | Ícones, cadeado e letreiros são provisórios feitos por código (§33). Ficam para a rodada de arte à mão | futuro | Diretor de Arte |

## Nada adiantado
Esta fase não trouxe rival, liga, arena nova, passiva de adversário, 3ª passiva, troca de passiva no meio da carreira nem escolha de
passiva luta a luta. Preço, Legado, Honra, calendário, escada, Panfletagem e os números travados do minigame ficaram iguais. A única
arte nova são peças de interface.

## Como o dono testa a 7b2 (~25 min, mais o tempo para bater a meta)
A 2ª passiva só aparece depois de 3 vitórias pela 1ª. Com o save que você já tem, o cartão começa em 0/3. Se quiser ir direto à
parte nova, peça ao Produtor um **save de teste separado**, com 2/3 em cada arte. Seu save fica guardado antes.

1. **Cartão da arte:** na escolha da arte, cada cartão tem duas opções. A 2ª vem com **cadeado** e uma barrinha, por exemplo
   "0/3 K.O. DE EMBALO". Confira se o texto está inteiro e se o selo "ÚLTIMA" não encosta no nome.
2. **Bater a meta:** jogue com Boxe na tática **Agressivo** e vença por **K.O.** As vitórias por pontos não contam. A barra sobe a
   cada K.O. Na 3ª, a tela de fim mostra "NOVO JEITO DE LUTAR: CONTRAGOLPISTA..." **uma vez só**, e o Osmar solta uma fala curta.
   Confira se o balão fica inteiro e não cobre nada.
3. **Escolher a 2ª:** na próxima carreira, o cadeado sumiu. Escolha o **Contragolpista**.
4. **Ver o Contragolpista:** lute no **Contra-ataque**, de preferência contra alguém do seu nível ou acima. Você deve ver a **guarda
   alta**, muitas esquivas seguidas de contragolpe e **3 losangos de carga** acendendo ao lado da sua vida. No 3º round pode vir o
   letreiro **K.O. NO CONTRAGOLPE!**, limpo, sem número por cima.
5. **Por cima (Jiu-jitsu):** lute no **Agressivo**. A queda vem já no 1º round, e a luta fica quase toda no chão. Quando ele levanta,
   aparece "LEVANTOU". O fim pode ser **O JUIZ PAROU!**, sem o adversário bater no chão.
6. **Clinch (Muay Thai):** lute no **Defensivo**. Os dois ficam **colados** por alguns segundos, com joelhadas. O adversário **não
   manca**, e essa é a diferença para a Canela. O fim pode ser **JOELHADA!**
7. **Prévia:** com cada 2ª passiva, troque de tática e veja a linha mudar, junto com o "N EM 10".
8. **O teste principal:** peça para alguém ver duas lutas da mesma arte, uma com cada passiva, sem ler o HUD. A pessoa tem que dizer
   qual é qual.
9. **Sensação:** ao liberar, deu vontade de "testar o outro jeito na próxima carreira"? Alguma das 6 combinações pareceu a escolha
   certa ou parou de evoluir?

## Resumo para o Produtor
- A 7b2 está **aprovada com ressalvas**. Antes do merge falta só rodar o `run_tests.ps1` inteiro uma vez, porque a correção do B1
  mexeu na tela da luta. Se falhar, volta para o UI/UX.
- B1 e B2 estão corrigidos. Os letreiros leem limpos nas capturas, e o audit dá 470 estados com 0 problemas.
- R1, R2, R3 e R5 passam. A prévia é honesta pela média por adversário, os sinais de cada passiva aparecem no meio da luta, e a
  média alta a 3/s foi aceita pela decisão do dono de medir pela mediana.
- R4 fica registrado: a meta de 3 leva cerca de 3 campanhas para quem não busca a meta, e no Muay Thai a 3/s às vezes mais. O
  Designer mede de novo para quem busca a meta. O teste do dono diz se a espera incomoda.
- O dono testa com o roteiro acima. Se quiser ir direto à 2ª passiva, o Produtor prepara um save de teste separado.
