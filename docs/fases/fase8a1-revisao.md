# Fase 8a1 — Liga regional: revisão do Diretor

Diretor de Jogo, 2026-11-22. Worktree `continue-agents-config-722700`, sem commit. Base: `fase8a-escopo.md` (§3, §7 critérios 1–10,
17, 18 e "Decisões do dono"), `fase8a1-design.md` (com as **decisões do dono**: 16,3% a 4/s aceito; Queixo de ferro ×0),
`fase8a1-textos.md`, `fase8a1-cutscene-james.md` (com a decisão do Produtor: a fala de depois toca no fim da tela de luta, antes da
janela de fim), `fase8a1-qa.md`, `docs/arte/fase8a1-manifest.md` e `fase8a1-personagens-manifest.md`. Olhei as capturas finais
`ui_audit_final\f8a1_luta_cinturao_erguido.png` e `f8a1_james_depois_pontos.png`.

## Veredito
**Aprovada com ressalvas.** Nada volta para Designer, Arte ou Roteirista. Os bugs do QA estão resolvidos:
- **B1 (cinturão erguido):** a peça nova (40x22) fica presa nas luvas, acima da cabeça, e o rosto fica livre. Na captura dá para ler
  "ergueu o cinturão", e não "placa flutuando". Era uma das 3 animações que o dono pediu, então era o bug que importava.
- **B2:** o James que perde por pontos agora fica de ombros caídos e guarda baixa. A diferença para a guarda normal é discreta, mas dá
  para ver, e a fala ("sorte de principiante.") segura a leitura.
- **B3, B4 e B5:** a linha "0%" some, o HUD não repete o número, e a 1ª apresentação caiu para 13,2 s (antes 14,2 a 15,2 s, com limite
  de 15 s).
- O audit dá 524 estados com 0 problemas, `test_fase8a1` dá 101/101 e `test_fase6a` dá 239/239 sozinho.

**Duas condições antes do merge (Produtor ou QA, nada volta para a equipe se der verde):**
1. **Rodar o `tools/run_tests.ps1` inteiro uma vez**, headless e sem outra tarefa pesada na máquina. As correções depois do QA
   mexeram em `tela_luta.gd`, no HUD, no texto da liga e na arte, e depois disso só os testes da 8a1 e da 6a rodaram. Se ficar verde,
   pode integrar. Se falhar, o problema volta para quem mexeu no arquivo (UI/UX para a tela de luta e o HUD, Programador para a liga).
2. **Explicar 102 → 101 no `test_fase8a1`.** O QA contou 102 testes e agora são 101. Se o teste que saiu é o do número repetido do
   HUD (B4), está certo. Se for outra coisa, o Programador devolve o teste.

## O que bate com a visão
- **Agora é circuito.** Depois do Kid a escada segue com 4 lutas, a data aparece no HUD e o "CAMPANHA COMPLETA" só volta depois do
  James. A arena tem ringue, faixa do patrocinador, TV VALE, mesa e público grande, e ainda é pé no chão (clube ferroviário à noite).
  É o degrau acima do Ginásio Alvorada que o escopo pediu.
- **A passiva trava um jeito, não uma arte.** Contra cada regional, a combinação travada perde 15, 40 e 44 pontos, e as outras 5 perdem
  0. Com isso, a 2ª passiva da 7b2 virou resposta, e a escolha do começo da carreira passou a pesar, como o dono aprovou.
- **Nunca imbatível.** Nas 24 células (6 combinações × 4 regionais), a melhor tática fica entre 80% e 98% com o treino da própria
  combinação.
- **A prévia continua honesta.** Ela usa a mesma conta do motor (diferença 0,000000). Em 1,2 milhão de lutas no jogo real, a média por
  adversário ficou entre −0,6 e +0,3 ponto.
- **Nada mudou até o Kid.** A foto é idêntica, e o motor deu 37.800 lutas idênticas, incluindo o Kid.
- **O James está do jeito certo.** Ele é arrogante com a escola e nunca cruel com o discípulo. Fala 1 vez antes e 1 depois por
  campanha, a fala bate com o resultado real, ele não aparece fora da liga e o respeito ficou para a 8b. O gesto de desprezo sai 1 vez
  por apresentação.
- **A passiva se vê na luta.** AGUENTOU!, NÃO CAIU, ESCAPOU!, GUARDA FECHADA e A GUARDA ABRIU, mais o número cinza com faísca na
  guarda. O motivo da derrota explica em linguagem de treinador ("O QUEIXO DELE NÃO ACEITA EMBALO. ACEITA PACIÊNCIA").
- **O incremental está de pé.** O tempo morto p90 fica em até 9:47, 1 clique vale de 52% a 88% da renda/s, e as lutas duram de 8 a 19 s.
- **Save:** continua opcional, aguentou 17 casos de save sujo e 400 lutas seguidas contra o James, e a cópia do save do dono abre sem
  erro.

## Riscos do QA
### R1: a 3 cliques/s, 6 a 14 de cada 72 jogadores nunca chegam ao James em 8 campanhas; a Canela leva 5 campanhas. **Aceito, com registro.**
- A meta do escopo (2–4 campanhas depois do 1º Kid) passa a 4/s e passa na mediana em 5 das 6 combinações a 3/s. A Canela fica 1
  campanha acima.
- O que preocupa é a **cauda**: 1 em cada 5 jogadores de Canela a 3/s nunca chega lá. Por enquanto é número de robô. Ninguém fica preso:
  passar o posto continua dando Legado, e o Legado continua subindo.
- Não mexo agora. O 16,3% a 4/s foi decisão do dono, e as alavancas são só dado. **O teste do dono decide.** Se ele ou um testador
  sentir "muro" no Sabão ou na Estaca, o Designer mexe no `league_regional.json`, e a regra é de sempre: prévia dos amadores e do Kid
  intocada.

### R2: a foto não chega ao Kid. **Passa.**
- O teste de 37.800 lutas do QA (com o Kid) e o `ident` do simulador (21.000 de 21.000) provam o critério 1 melhor que a foto.
- **Tarefa:** o Programador guarda o `tests/qa_f8a1_ident.gd` na suíte (ou estende a foto até o Kid). A 8a2 e a 8b vão mexer perto
  dessa escada, e essa é a rede de proteção.

### R3: ninguém ouviu a voz do James nem fez o teste de reconhecimento por uma pessoa. **Vai para o roteiro do dono.**
- Os arquivos existem e têm o mesmo formato dos outros timbres. Só o ouvido do dono diz se o serrilhado e nasal ficou bom.
- O critério 3 (dizer o que a passiva faz sem ler o HUD) tem medida forte: a Estaca e o Sabão mostram o sinal em 70–83% das lutas
  travadas. O Bigorna fica mais baixo (36–54%), e é o mais provável de não ser reconhecido. Se o dono não perceber o Bigorna, a
  correção é de leitura (UI/UX: o AGUENTOU! mais forte ou mais demorado), e não de regra.

## As 3 decisões do Programador
1. **A Panfletagem paga a fama do Kid durante a liga. Fica.** O escopo §5 diz que a Panfletagem não muda. Pagar a fama regional
   (até 500) inflaria um minigame opcional. Fica registrado que é de propósito.
2. **O convite do Osmar e o AQUECIDO seguem valendo na liga. Fica.** Está certo: a liga agora faz parte da campanha, e esses bônus
   existem para a campanha que ainda está viva. Cortar seria uma perda que o jogador sentiria como regra anti-incremental.
3. **`tip_gym_loss` nos regionais. Fica.** As lutas saem da academia, então a dica vale. Quando a passiva dele pesou, a linha dela vem
   primeiro, e é a que ensina mais.

## B6 (o rabicho do balão no James caído). **Não bloqueia.**
- O balão lê bem, e fica claro quem fala (o nome aparece no balão). A tarefa fica para o UI/UX como pequena, junto com o próximo ajuste
  na tela de luta.

## `test_fase6a` frágil sob carga (B7). **Não bloqueia, mas vira tarefa.**
- Ele falha quando a máquina está ocupada porque depende do relógio real. Sozinho passa 239/239. Não é da 8a1.
- **Tarefa (Programador):** tirar a dependência do relógio (avançar o tempo por código, como os outros testes). Até lá, a regra é rodar a
  suíte sem outra tarefa pesada ao mesmo tempo.

## Personagens regionais "sem personalidade" (observação do dono)
- O dono achou o Bigorna, a Estaca e o Sabão "padrão, sem personalidade". Também reprovou como "bizarro" o conceito com corpos
  exagerados e mandou manter como está. **A fase não reprova por isso:** os personagens cumprem o escopo (cabeça, roupa e paleta
  próprias, mais a pose de assinatura no rig comum).
- **Tarefa futura (Artista de Personagens com o Diretor de Arte, rodada de arte à parte):** dar personalidade **sem mudar o corpo**,
  no rig comum, com:
  - **rosto:** sobrancelha, cicatriz, bigode, nariz quebrado, expressão própria no `idle`;
  - **roupa e acessório:** um item que conte quem ele é (faixa, protetor velho, calção com remendo, cor que ninguém mais usa);
  - **pose de assinatura:** um tique próprio no `idle` ou na entrada (bater a luva no queixo para o Bigorna, por exemplo).
  Antes de fazer, mostrar ao dono um mockup lado a lado. Um personagem primeiro, os outros só com o "sim" dele. A regra que ele deu
  fica valendo: **corpo e proporções não mudam.**

## Ressalvas que viram tarefa futura
| # | O quê | Peso | Quem |
|---|---|---|---|
| E1 | `run_tests.ps1` inteiro, uma vez, sem carga | **antes do merge** | Produtor ou QA |
| E2 | Explicar 102 → 101 no `test_fase8a1` | **antes do merge** | Programador (só responde) |
| E3 | Save de teste da 8a1 (ver roteiro), no padrão do `tools/teste/criar_save_7b2.gd` | antes do dono testar | Programador |
| E4 | Voz do James, teste de reconhecimento e sensação da liga | dono testa | Produtor |
| E5 | Cauda a 3/s (Canela, Clinch, Finalização): só mexer se o dono ou um testador sentir muro | observação | Designer |
| E6 | Guardar `qa_f8a1_ident.gd` na suíte ou estender a foto até o Kid | próxima vez que mexer na escada | Programador |
| E7 | `test_fase6a` sem depender do relógio real | pequena | Programador |
| E8 | Rabicho do balão do James caído (B6) | pequena | UI/UX |
| E9 | Personalidade dos regionais por rosto, roupa e pose, no rig comum, com mockup antes | rodada de arte | Artista + Diretor de Arte |
| E10 | Folga de 5 px entre o cinturão e o balão: uma fala nova mais larga encosta. Conferir no audit sempre que entrar fala do James | regra | Roteirista / UI/UX |
| E11 | Ícones das passivas provisórios por código (junto com o D7 da 7b2) | rodada de arte | Diretor de Arte |

## Nada adiantado
Não entrou centro de treinamento, mudança de local, patrocínio, região nova na árvore, recorte de jornal nem cartaz rasgado (é a
8a2). Também não entrou o James estudando a escola, o respeito dele, a liga nacional (8b) nem a Ronda Noturna. Os 6 adversários de
hoje continuam sem passiva, e a Panfletagem, o Choque, o AQUECIDO e o teto de 10% ficaram iguais.

## Como o dono testa a 8a1 (~30 min)
A liga só abre depois do Kid. Com o save atual isso leva algumas campanhas. Para ir direto, peça ao Produtor um **save de teste
separado**, como na 7b2. O seu save fica guardado antes. Sugestão de save: academia, Boxe na Mão rápida, a **2 dias do Kid**, com
treino para vencê-lo e para encarar o Bigorna. Um 2º save, com o Contragolpista, serve para comparar.

1. **Abrir a liga:** vença o Kid. A janela de fim mostra o convite da liga. Na sala, o HUD mostra a data da 1ª luta regional, o
   Osmar fala uma vez, e na parede aparece o **cartaz da liga** com a cara do James.
2. **Prévia do Bigorna:** antes da luta, abaixo da sua passiva, aparece a passiva dele (QUEIXO DE FERRO) com "ATRAPALHA: ...". Troque
   de tática e veja a chance mudar.
3. **Arena nova:** entre na luta. Confira a entrada no ringue, a faixa do patrocinador, a câmera da TV e o público. Veja se o
   K.O./letreiro lê bem no fundo novo.
4. **Sinal da passiva:** lute na Mão rápida no Agressivo e repare no **AGUENTOU!**. O teste principal é este: peça para alguém ver
   as lutas do Bigorna, da Estaca e do Sabão **sem ler o HUD** e dizer o que cada um faz de diferente. Bastam 2 de 3.
5. **Perder de propósito (opcional):** a tela de fim explica com a passiva dele ("ELE NÃO CAIU NO EMBALO...").
6. **James:** na 1ª luta contra ele, veja a apresentação (3 falas e o **gesto de desprezo**). **Ouça a voz.** Teste o PULAR, o clique
   e segurar ESC. No 1º round a guarda dele fecha (GUARDA FECHADA) e depois abre.
7. **Depois da luta:** se ele vencer, zomba de braços erguidos. Se perder, continua arrogante (de ombros caídos por pontos, no chão por
   K.O.). A fala vem **antes** da janela de fim.
8. **Cinturão:** ao vencer o James, o discípulo **ergue o cinturão** com as luvas. A tela de fim mostra "CENTRO DE TREINAMENTO
   LIBERADO" (a mudança chega na próxima versão), e o HUD volta para "CAMPANHA COMPLETA".
9. **Reencontro:** passe o posto e chegue ao James com outro discípulo. A fala de antes tem que ser outra.
10. **Sensação:** deu vontade de "nesta campanha vou de outro jeito"? Algum regional pareceu muro? O James irritou do jeito bom
    (rival caricato) ou do jeito ruim?

## Resumo para o Produtor
- A 8a1 está **aprovada com ressalvas**. Antes do merge falta rodar o `run_tests.ps1` inteiro uma vez, sem carga, e explicar por que
  o `test_fase8a1` passou de 102 para 101. Se tudo estiver verde, pode integrar.
- B1 a B5 estão corrigidos. O cinturão erguido agora lê como "segurado". O B6 e o `test_fase6a` frágil viram tarefas pequenas.
- Os riscos do QA ficam registrados (cauda a 3/s, foto, voz). As 3 decisões do Programador ficam como estão.
- A observação do dono sobre os regionais "sem personalidade" vira tarefa de arte futura: rosto, roupa e pose de assinatura no rig
  comum, sem mudar o corpo, com mockup antes.
- Para o dono testar, o Programador prepara um save de teste da 8a1 (a 2 dias do Kid), no padrão da 7b2.
