# Ronda Noturna do Gato Preto: escopo

Diretor de Jogo, 2026-11-22. Base: `PROMPT.md` §3, §5.10 e §6; `fase7a-escopo.md` §4 e §8.4 (Gato Preto original, Ronda em fase
própria); `fase7a2-design.md` §1, §2, §8, §9 e §10 (convite, teto de 9,2%, "ignorar = foto igual", semente); `fase7a2-textos.md`;
`fase7a2-revisao.md` ("a lenda cresce antes do herói"); `fase7b-escopo.md` §5; `fase8a-escopo.md` (decisão 7 do dono: depois da 8a e
antes da 8b); `fase8a2-design.md` D10 (o recorte do Vale e o do Gato Preto são peças separadas); `direcao-visual.md` §31.5;
`docs/estado-atual.md`; correção do dono sobre o corpo dos personagens, de 2026-11-22.

## 1. Objetivo e sensação
- **Objetivo:** o vulto do recorte vira coisa que o jogador faz. De vez em quando, à noite, o discípulo veste o capuz e sai numa
  **ronda curta pelo bairro**: assusta um ladrão e volta. Cada ronda aumenta a **lenda do Gato Preto**, que o bairro conta cada vez
  maior: no jornal da parede, no muro e na rua.
- **Sensação:** "ninguém sabe que sou eu. O jornal agora diz que o Gato Preto parou um ônibus com uma mão, e eu só fiz um ladrão
  de estepe cair de bunda." O que acontece de verdade é pequeno e pé no chão. A **lenda** é que vai ficando absurda: é o tom do
  PROMPT §3 em miniatura.
- **Por que agora:** a semente está na parede desde a 7a2, e a 8a mostrou a escola crescendo fora do bairro. A Ronda é o lado
  secreto do bairro, antes de a 8b levar a escola para o país.

## 2. Onde entra e quando abre
- **Na ordem das fases:** depois da 8a2 e antes da 8b (decisão do dono).
- **No jogo (proposta, pergunta 4):** abre **na campanha seguinte** à que ouviu o boato do Osmar (marco `black_cat_rumor_heard`, da
  1ª Panfletagem com o recorte na parede). O boato vem numa campanha, e o capuz aparece para o discípulo seguinte.
- Save antigo que já tem o marco: abre na próxima campanha. Se o save não guarda em que campanha o boato saiu, o Programador trata
  como antigo e abre já na campanha atual.
- **A 1ª carreira (John) nunca vê a Ronda:** o recorte só aparece da campanha 2 em diante, então o tutorial fica intocado.
- Vale nos 3 locais (garagem, academia e centro). A ronda é **sempre no bairro de origem**: é lá que a lenda mora.

## 3. O minigame
### 3.1 Regras fixas (do dono e da 7a2)
- **Tela própria**, fora da sala. **Sempre opcional:** o jogador escolhe ir. Nunca abre sozinho e nunca trava nada.
- **Entrada:** quando há ronda disponível, aparece um **capuz preto pendurado num prego** na parede da sala, com as orelhas
  costuradas para fora. É um objeto parado, sem fala e sem balão. No hover aparece "SAIR DE NOITE?", e o clique abre a Ronda.
  O Osmar **não convida**, porque ele não sabe quem é o vulto (pergunta 5).
- **Quando o capuz pode aparecer:** a regra é a do convite da 7a2. Nunca durante janela, luta, cena, fala ou dia da luta. Ele
  **não some**: fica no prego até o jogador usar, e existe **no máximo 1** de cada vez, sem acumular. Como a Ronda não mexe na
  economia (§4), o capuz parado não pressiona ninguém.
- **Frequência (proposta, o Designer fixa em `data/`):** 1 ronda a cada ~4 min de sala (8 dias de campanha). O relógio é próprio e
  não mexe no relógio do convite do Osmar.
- **Duração:** 25 a 40 s no total (contagem, ronda de ~30 s e prêmio). **SAIR a qualquer hora** leva a lenda que já ganhou, e só ir
  já garante um piso maior que 0.
- **Congela o jogo (proposta, pergunta 2):** durante a Ronda o relógio da campanha **e a equipe** param, como numa pausa. Ir não
  custa nenhum dia nem treino, e também não rende nada a mais. É isso que deixa a economia igual (§4).
- **Sorteio próprio:** a Ronda nunca usa os sorteios do jogo (`rng`, falas, eventos, sucessão) nem o do Choque e da Panfletagem.

### 3.2 Três ideias (o dono escolhe, pergunta 1)
| | Ideia | Como é | Prós | Contras |
|---|---|---|---|---|
| **A (recomendo)** | **Estátua no telhado** | 3 ocorrências por ronda (ladrão de estepe na borracharia, moleque mexendo numa bicicleta, sujeito forçando um portão). O ladrão trabalha de costas e, de tempos em tempos, **olha para trás, com aviso antes**. **Segurar** faz o vulto avançar agachado pelo muro, e **soltar** faz ele congelar. Quando chega perto, um **clique** dá o **SUSTO!**: o ladrão larga tudo, cai de bunda e foge. Se o ladrão vê o vulto, foge antes e a ocorrência acaba sem castigo | verbo novo (avançar e congelar), legível em 1 linha, susto com juice forte; o cenário é um só, com 3 pontos; ninguém apanha | o segurar e soltar lembra o Choque do Jiu-jitsu (mas aqui o contexto e o ritmo são outros) |
| B | **Corrida pelos telhados** | o vulto corre sozinho, e o clique faz ele pular de telhado em telhado e cair em cima da ocorrência | muito "herói noturno", rápida de entender | a mais cara de arte (cenário que rola, salto, queda) e a mais perto do "jogo de reflexo genérico" |
| C | **Vigia da caixa d'água** | tela parada com a rua vista de cima; sombras aparecem, e o jogador clica nas suspeitas e deixa passar os inocentes (a vó com o lixo, o padeiro de madrugada) | barata, só 1 cenário | é quase a Panfletagem (ler sinais e clicar em quem) |

**Recomendo A.** É a única com cara própria, cabe num cenário só e mantém o tom: o Gato Preto **assusta, não bate**. É vigia de
bairro, não justiceiro.

### 3.3 Tom e identidade
- Cômico e pé no chão. Ninguém sangra e ninguém apanha: o ladrão cai, foge e esquece a bolsa. O vulto nunca é cruel.
- **Original, sem Batman:** capuz com orelhas largas e baixas, faixa da escola nos olhos com as pontas voando, capa de lona caindo
  reta (nunca aberta em asa), nada de símbolo no peito, cinto de utilidades ou sinal no céu (`direcao-visual.md` §31.5).
- **Quem é o vulto (proposta, pergunta 3):** é o **discípulo da vez**, e o jogo nunca diz isso em voz alta. O capuz e a lenda
  **passam de discípulo para discípulo**, como a escola. A lenda é da máscara, não da pessoa. O Osmar desconfia, mas não pergunta.
  O mistério fica aberto e não se cruza com o Arco 5 (histórias do Osmar, fase 9) nem com o Arco 6 (o 1º lutador, fase 11).

## 4. A lenda do Gato Preto ("fama do Gato Preto")
- **É um contador próprio, a LENDA**, separado da FAMA da carreira (para não confundir com a fama que dá Legado e patrocínio).
  Ela vale para a **linhagem**: o próximo discípulo continua do mesmo ponto. Só cresce e nunca cai (PROMPT §5.10).
- **Níveis (proposta: 5; o Designer fixa os números e o Roteirista os textos).** Cada nível troca o recorte da parede (o mesmo objeto
  da 7a2, nos 3 locais) e acrescenta uma camada **dentro da tela da Ronda**:

| Nível | Recorte na parede (hover) | Na rua da Ronda |
|---|---|---|
| 0 (hoje) | VULTO MASCARADO... (o de hoje) | rua normal |
| 1 | o jornal **dá o nome: GATO PRETO** (1ª vez que o nome aparece) | — |
| 2 | manchete já exagerada | pichação do gato no muro da borracharia |
| 3 | mais exagerada | faixa "VALEU, GATO PRETO" na borracharia |
| 4 | mais exagerada | criança com orelhinhas de gato na janela |
| 5 | manchete absurda (ex.: "GATO PRETO PARA ÔNIBUS COM UMA MÃO") | o bairro inteiro com o gato desenhado |

- **Ritmo (proposta):** o nível máximo chega com ~2 a 3 campanhas indo em todas as rondas. Depois do máximo a Ronda continua como
  passeio, com um contador honesto ("OCORRÊNCIAS: N"), sem prêmio novo.
- **O recorte do Gato Preto continua separado do recorte do Vale** (D10 da 8a2). A lenda só troca o do Gato Preto.

### 4.1 A lenda não mexe na economia (e como provar)
- **Nada da lenda vira dinheiro, treino, FAMA, AQUECIDO, Legado, Honra, chance de luta, preço ou patrocínio.** Ela só muda textos de
  hover e camadas da tela da Ronda.
- **A Ronda congela o jogo** (§3.1): o relógio fica parado e a equipe não produz. Ir em todas as rondas dá **os mesmos dias, o mesmo
  treino e o mesmo Legado** que não ir.
- **Nada na sala muda de comportamento:** o capuz e o recorte são objetos de hover. Não falam, não contam como ocioso, não
  disputam vaga com as falas e não usam sorteio.
- **Choque, Panfletagem, AQUECIDO e o teto de 10% ficam iguais.** Ficam iguais também a Panfletagem e a rua dela: a lenda não entra
  ali, porque mexeria no sorteio da Panfletagem.
- **Prova:** (1) quem **não joga** a Ronda tem a foto (`foto.gd`) igual à da main. (2) Quem **joga todas** as rondas tem a mesma foto
  de quem não joga, com o `foto.gd` apagando **só** os campos novos do Gato Preto (§6). (3) O teto da 7a2 continua em 9,2%, sem
  medir de novo, porque a Ronda soma 0.

## 5. Divisão
**Uma parte só.** São 1 minigame, 1 contador e objetos de hover, com regras que já existem (convite, relógio parado, save opcional).
O mais caro é a arte (§9), e ela tem ordem de corte. Se a folha do vulto atrasar, o Programador e o UI/UX fazem a tela com
silhuetas provisórias e trocam depois.

## 6. Save
- Continua **v13**, só com campos opcionais e valor padrão, **sem migração**:
  - no `permanente`: lenda, nível já mostrado, ocorrências e a campanha em que a Ronda abriu;
  - na carreira: o relógio da próxima ronda e se o capuz está no prego.
- A lenda só entra no fim da Ronda ou no SAIR, e salva na hora. **Fechar o jogo no meio:** não ganha lenda, o capuz volta para o
  prego e nada sai em dobro.
- O `foto.gd` apaga os campos novos antes do hash, com uma linha comentada, como fez com `training_invite`.
- Save sujo (tipos trocados, negativos, gigantes) carrega com valores válidos. A cópia do save do dono abre sem erro.

## 7. Critérios de aceite
1. **Quem não joga:** sem arte e com cada combinação, a foto é igual à da main numa campanha inteira com o capuz no prego e nunca
   usado.
2. **Quem joga:** uma campanha indo em **todas** as rondas dá a mesma foto que a mesma campanha sem ir (mesmos dias, treino,
   dinheiro, FAMA, Legado e lutas), tirando só os campos do Gato Preto.
3. **Abertura:** o capuz só aparece na campanha seguinte ao boato (ou na regra que o dono escolher). A 1ª carreira nunca o vê.
4. **Entrada:** o capuz nunca aparece em janela, luta, cena, fala ou dia da luta, nunca abre a Ronda sozinho e nunca acumula mais de 1.
   Um testador sem dica acha e usa o capuz em até 2 aparições.
5. **Curta e livre:** a Ronda dura 25–40 s, tem SAIR a qualquer hora, e só ir já dá lenda maior que 0.
6. **Legível:** um testador entende o que fazer na 1ª ronda só com 1 linha de instrução, e consegue pelo menos 1 SUSTO.
7. **Juice:** o SUSTO tem impacto: letreiro, tremida, o ladrão caindo e som (reaproveitado).
8. **Lenda:** cada nível troca o recorte nos 3 locais e a camada da rua. O nome "GATO PRETO" só aparece a partir do nível 1. A lenda
   nunca cai e o próximo discípulo vê o mesmo nível.
9. **Original:** busca por batman/morcego/gotham sem resultado; capa nunca aberta em asa. A folha do vulto foi aprovada pelo dono
   antes do minigame (§9).
10. **Save (§6):** fechar no meio da Ronda não duplica nem perde nada; save sujo carrega; a cópia do save do dono abre sem erro.
11. `tools/run_tests.ps1` verde, com save de teste (APPDATA temporário), janelas com `--position 1950,40` e um Godot por vez.
12. `ui_audit` com **0 problemas**, incluindo: o capuz no prego nos 3 locais (sala vazia e com equipe máxima), a tela da Ronda no
    começo, no meio, no SUSTO e no prêmio (com e sem subida de nível), e o recorte de cada nível no hover.

## 8. Fica de fora
| Item | Fase |
|---|---|
| Lenda dando qualquer bônus de economia (FAMA, dinheiro, treino, luta) | — (só com decisão do dono; o teto de 10% está em 9,2%) |
| Gato Preto lutando na liga, chefe noturno, vilão próprio | — (não planejado) |
| Revelar quem é o vulto, cena própria | — (o mistério fica aberto; só se o dono pedir, nunca antes da 11) |
| Lenda na Panfletagem, falas do Osmar na sala sobre a lenda | — (mexeria em sorteio e em falas; só se o dono pedir) |
| Traje do Gato Preto como roupa do lutador de dia | — |
| Mais ocorrências, mais bairros, ranking e recorde | — (só se os testadores pedirem) |
| Sons próprios da Ronda, conquistas ("Lenda viva") | 13 e 14 |
| Liga nacional, local 4, respeito do James | 8b |

## 9. Custo de arte
**Regra do dono para o corpo (2026-11-22):** inventar no corpo é permitido, inclusive com proporção diferente. O que o dono reprovou
na 8a1 foi o **acabamento**: ficou estranho, sem cuidado e fora do padrão do jogo. Valem, portanto:
- todo personagem segue a linguagem atual (sombreamento, encaixes, paleta, leitura em 1x e a skill `padrao-personagem`), com
  capricho;
- **amostra antes do elenco:** o vulto vai **primeiro**, numa folha com 1 pose e 1 animação, para o dono aprovar. Só depois vêm o resto
  dele e os ladrões. Se um ladrão tiver corpo diferente (o magrelo comprido, o baixinho largo), ele também passa por amostra.

| Peça | Quem | Pode cortar? |
|---|---|---|
| **Vulto:** traje vestido no discípulo da vez (capuz com orelhas, faixa com pontas voando, capa de lona), que tem de funcionar em qualquer discípulo | Artista | **não** (é a identidade) |
| Vulto: espreitar parado, avançar agachado (ciclo), congelar, **SUSTO** (salto do muro com a capa), pose no telhado com a lua | Artista | a pose no telhado vira 1 quadro |
| **Ladrão genérico:** trabalhar de costas, **olhar para trás com aviso**, cair de bunda e fugir; 2–3 paletas e cabeças | Artista | 1 só ladrão com paletas |
| **Cenário da Ronda:** rua da borracharia à noite, vista do muro, com 3 pontos de ocorrência | Diretor de Arte | não (mockup antes) |
| Camadas da lenda na rua (pichação, faixa, criança na janela) | Diretor de Arte | sim: viram só recortes |
| 5 recortes novos (pequeno para a parede e grande para o hover) | Diretor de Arte | o grande do hover é o primeiro a sair |
| Capuz no prego nos 3 locais (ponto conferido com equipe máxima), ícone da LENDA, HUD da tela | Diretor de Arte | não |

São cerca de **9 animações** (vulto ~5, ladrão ~4) e 1 cenário. **Ordem de corte:** (1) as camadas da rua viram só recortes;
(2) 1 ladrão com paletas; (3) a pose no telhado vira quadro parado. **Não se corta:** o traje original, o aviso do ladrão olhando
(é a regra do jogo) e o SUSTO com juice. A silhueta do recorte de hoje (7x8 px) é ajustada para bater com a folha nova.

## 10. Quem faz
| Papel | Faz |
|---|---|
| **Designer** | regra da ideia escolhida, aviso e janelas de tempo, piso da lenda, níveis e ritmo, frequência, prova do §4.1 → `ronda-design.md` |
| **Roteirista** | manchetes dos 5 níveis (escalando para o absurdo), linha de instrução, letreiros (SUSTO!), hover do capuz, textos do prêmio |
| **Diretor de Arte** | cenário (mockup antes), camadas, recortes, capuz no prego, ícone e HUD |
| **Artista de Personagens** | **amostra do vulto para o dono**, depois a folha completa dele e os ladrões, pela `padrao-personagem` |
| **Programador** | módulo novo em `scripts/estado/` com repasse no `game_state.gd`, capuz, relógio, lenda, save, `foto.gd`, testes; `mapa.md` atualizado |
| **UI/UX** | tela da Ronda, juice do SUSTO, tela de prêmio, hover; `alinhamento-ui` com 0 problemas |
| **QA** | critérios 1–12 |

## 11. Riscos
- **"Não dá nada, ninguém joga":** a lenda precisa ser vista e ter graça. Proteção: o recorte muda na parede de todo local, as
  manchetes são engraçadas e o nome só chega jogando. Se os testadores ignorarem, a conversa com o dono é sobre um bônus pequeno, e
  isso pede uma nova medida do teto.
- **Virar obrigação:** não vira, porque não há ganho, o capuz não some e ir não custa dia.
- **Tom errado (justiceiro violento):** o vulto só assusta, ninguém apanha, e o ladrão é cômico.
- **Parecer Batman:** a regra do §3.3 e o critério 9.
- **Acabamento da arte:** é o que o dono reprovou na 8a1. Proteção: a amostra de 1 personagem aprovada antes do elenco e a mesma
  linguagem visual do jogo. Um corpo diferente só entra se estiver caprichado.
- **Traje em qualquer discípulo:** o capuz e a capa têm de vestir todos os corpos e cabelos. O Artista prova isso em 3 discípulos.
- **Capuz atrapalhando a sala:** com a equipe máxima, gente cobre a parede. O ponto vem do Diretor de Arte, conferido no `ui_audit`.
- **Adiantar fases:** lenda com bônus, Gato Preto na liga ou revelar quem é ficam de fora (§8).

## 12. Perguntas ao dono
1. **Qual minigame?** A, "Estátua no telhado" (avança segurando, congela quando o ladrão olha, clica para o SUSTO; **recomendo**);
   B, corrida pelos telhados; ou C, vigia da caixa d'água.
2. **A Ronda congela o jogo** (relógio e equipe parados: não custa nem rende nada, e a economia fica provadamente igual;
   **recomendo**), ou a equipe produz como nos outros minigames? Nesse caso a Ronda passa a mexer no teto de 10% e as frequências
   têm de ser medidas de novo.
3. **Quem é o vulto:** o discípulo da vez, sem o jogo dizer, com o capuz passando pela linhagem (**recomendo**), ou um mistério total
   em que o jogador controla o vulto mas nunca fica claro que é ele?
4. **Quando abre:** na campanha seguinte ao boato do Osmar (**recomendo**), logo depois do boato, ou só depois do Cinturão do Vale?
5. **Entrada:** pelo capuz no prego, sem fala (**recomendo**: o Osmar não sabe), ou por um convite do Osmar como nos outros minigames?
6. **A lenda fica sem nenhum efeito na economia, só no bairro e no jornal** (**recomendo**)?
7. **Top 3 animações:** **recomendo** o SUSTO (salto do muro com a capa), o ladrão caindo de bunda e a pose no telhado com a lua.

## Resumo para o Produtor
- A Ronda Noturna é um minigame curto (~30 s), opcional e em tela própria. O discípulo veste o capuz, que aparece num prego na sala,
  e assusta ladrões no bairro. Ninguém apanha, e o tom é cômico e pé no chão.
- Cada ronda aumenta a **LENDA do Gato Preto**, que é da linhagem e só cresce. O jornal da parede dá o nome e as manchetes ficam
  cada vez mais absurdas.
- A lenda **não mexe na economia**, e a Ronda congela o jogo. Quem joga e quem não joga têm a mesma foto do jogo, e o teto de 10%
  fica igual. Save v13, uma parte só.
- O custo de arte é de ~9 animações e 1 cenário. O vulto sai primeiro, como amostra para o dono aprovar o acabamento, e só depois vêm
  o resto e os ladrões.
- São 7 perguntas ao dono, cada uma com a minha recomendação.

## Decisões do dono (2026-11-22)
"eu gostei de tudo" — as 7 perguntas seguem a recomendação do Diretor (minigame A "Estátua no telhado"; a Ronda congela o jogo; o vulto
é o discípulo da vez sem o jogo dizer; abre na campanha seguinte ao boato; entra pelo capuz no prego; top 3 animações: SUSTO, ladrão
caindo, pose no telhado com a lua), com **duas mudanças pedidas pelo dono**:

1. **A lenda ajuda a campanha, sem quebrar o jogo** (muda a pergunta 6). Em vez de "nenhum efeito", a lenda abre uma **região pequena
   na árvore** (sugestão: GATO PRETO), comprada com Legado como as outras, com efeitos modestos e com teto. Bônus: dá destino ao Legado
   que volta a sobrar depois da região CENTRO (R1 da 8a2). Regras: quem não joga a Ronda nunca fica travado nem atrás no essencial
   (escada, cinturões e tempo até o James medidos com e sem a região); a região só aparece depois da lenda nível 1; o Designer mede e
   prova que não quebra a economia (tempo até o Kid e até o James, clique vs renda, teto de 10%).
   Com isso, o critério "mesma foto para quem joga todas as rondas" passa a valer só ATÉ a compra do 1º nó da região nova.
2. **Futuro: lutas do Gato Preto contra bandidos.** O dono gostou da ideia de, mais para frente, a Ronda ganhar minigames de luta
   contra bandidos ("começa agora e depois vai aprimorando"). Nesta fase fica só a Ronda do SUSTO; o design deve deixar a tela da
   Ronda preparada para receber outro tipo de noite depois (ex.: um campo "tipo de noite" nos dados), sem implementar a luta agora.
