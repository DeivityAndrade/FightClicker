# Ronda 2a do Gato Preto: escopo

Diretor de Jogo, 2026-11-25. Base: `ronda2-ideias.md` (direção do dono, capítulos e prêmios), `ronda-escopo.md`, `ronda-design.md`,
`ronda-revisao.md` (ganchos, D2–D6), `identidade-revisao.md` (D2: placar de `ignore`), `roadmap.md`, PROMPT §3 (tom) e §5
(lutas resolvidas pelos números), `docs/codigo/mapa.md` e o motor `scripts/luta.gd` (`lutar(jog, adv, tatica, semente)` aceita
semente própria; passivas de adversário da 8a1 já existem). O jogo não foi rodado.

## 1. Objetivo e sensação
- **Objetivo:** o vulto para de só assustar. Em algumas noites ele **briga de verdade** num beco, com o motor de luta, contra bandidos
  do bairro e, no topo, contra o **1º supervilão**: um sujeito de bairro exagerado que se acha mais do que é. É a primeira vez que o
  lado fantasioso aparece no jogo.
- **Sensação:** "isso é difícil e é meu segredo. Demorei campanhas para chegar no chefe, e agora tem o capacete amassado dele na
  minha prateleira." Os prêmios são de colecionador: dá para ver o progresso, e ninguém fica mais forte por isso.

## 2. Regras fixas (não se discutem no design)
- **Opcional e com o relógio parado**, como na Ronda 1: a campanha e a equipe congelam, e ir não custa nem rende dia, treino ou
  dinheiro.
- **A briga da noite não é luta da carreira:**
  - perder nunca encerra a carreira e não mexe em Legado, FAMA, dias nem no AQUECIDO;
  - a luta usa os atributos crus do discípulo e a arte dele;
  - tem **sorteio próprio** (semente da Ronda), sem tocar no `rng` do jogo.
- **Sem código novo no motor:** os bandidos e o vilão são adversários com atributos e uma passiva de adversário que **já existem**,
  só com nome e visual novos. A prévia continua honesta, com a chance real.
- **Tom mais sujo, sem violência gráfica:**
  - cenário de beco à noite, com chuva, lixo, poste piscando e gíria;
  - o K.O. é "apagou" ou "saiu tonto e fugiu", sem sangue e sem ninguém machucado no chão depois.
- **O vulto continua insinuação:** sem rosto, sem nome do discípulo e sem texto que diga quem é, até a fase 11.

## 3. O que entra
### 3.1 Noites e adversários (fase pequena)
| Noite | Quantas | Como é |
|---|---|---|
| **Briga de beco** (`kind` novo nos `nights`) | 3 bandidos fixos, 1 por noite | **Aproximação curta:** 1 ocorrência da "Estátua no telhado", com a lógica da Ronda 1 reaproveitada. Depois vem a **luta no motor**, com escolha de tática. Ser visto **não** cancela a luta, só perde o desafio (§3.4) |
| **Noite do chefe** | 1 supervilão regional | Igual à briga de beco, com arena própria, entrada com letreiro e passiva mais forte |

- Os 3 bandidos reaproveitam os corpos dos 3 ladrões da Ronda 1 (gancho já pronto), agora com animações de luta.
- **Escolher a noite:** quando a briga abre, o capuz leva ao **Esconderijo** (§3.3), onde o jogador escolhe entre SUSTO (a Ronda
  1), um bandido ou o chefe. Antes de a briga abrir, o capuz continua levando direto ao SUSTO, como hoje.
- Continua valendo **1 capuz por vez**, no relógio da Ronda 1, e cada capuz dá 1 noite.
- **Duração:** até ~60 s por noite (aproximação, luta e prêmio). SAIR na aproximação devolve o capuz sem custo.

### 3.2 Como se destrava (difícil de alcançar)
- **Brigas de beco:** precisam de **lenda nível 3** e de a linhagem já ter **vencido o Kid** (ter entrado na liga regional).
  O Designer confirma qual marco usar.
- **Os bandidos vão em ordem:** o 2º só abre depois de vencer o 1º.
- **Chefe:** precisa de **lenda nível 5**, dos **3 bandidos vencidos** e de a linhagem ter o **cinturão regional** (o mesmo ponto
  da campanha, regra do dono).
- **Meta para o Designer (proposta):**
  - a 1ª briga fica vencível por volta da campanha 6–7 de quem joga a Ronda;
  - o chefe, com o discípulo que acabou de ganhar o cinturão regional, tem **30–50%** de chance na prévia;
  - a versão rara do prêmio do chefe fica com **≤ 20%** por tentativa.

### 3.3 Prêmios desta fase (só visual e lore; nada de poder)
| Dificuldade | Prêmio |
|---|---|
| Vencer um bandido | **Ficha no Dossiê:** desenho, apelido e manchete. Recorte novo na parede da sala |
| Desafio do bandido | **1 estilo de personalização** (3 no total: peças da noite como faixa, bandagem e calção escuro), sem efeito em número |
| Vencer o chefe | Ficha do chefe, **troféu no Esconderijo** (peça marcante dele), **título da imprensa** no Dossiê e cartaz no canto livre da parede do menu (reservado na ID4) |
| Desafio do chefe | **Versão rara** do troféu (dourado ou com detalhe próprio) e 1 **estilo raro** |

- **Esconderijo:** é **uma tela só**. Tem a parede do Dossiê, a prateleira de troféus e o quadro "ESTA NOITE" para escolher a noite.
  Ele é o progresso visível da lore.
- **Estilos na personalização:** entram como opções da tela de personalização que já existe (6b), marcadas com o gato. Não mudam
  nenhum número (a foto prova).
- **Semente da 8b (pequena, sem risco):** a ficha do chefe traz a frase de uma testemunha, "o vulto luta como gente de academia".
  Nada de fala do Osmar na sala, porque mexeria no sorteio de falas e na foto.

### 3.4 Desafios opcionais (1 por adversário)
- São verificáveis pelo resultado da noite, sem reflexo extra. Exemplos para o Designer:
  - **"sem ser visto"** na aproximação;
  - vencer antes do 3º round;
  - vencer com a vida acima de X%.
- Cada desafio aparece **antes** da luta, no quadro da noite, e o jogador escolhe tentar ou não.
- Vale a regra do dono: o prêmio raro custa mais.

### 3.5 Penalidade de perder (pequena, nunca anti-incremental)
- Perder a briga não dá prêmio: o vulto foge "mancando", o capuz é gasto e só volta no próximo relógio da Ronda (~4 min de sala).
- A lenda nunca cai, e o que já foi ganho no Dossiê nunca some. Fica a marca de **revanche** no quadro, como na liga.

### 3.6 Item técnico: D2 da identidade
- Baixar o placar de `ignore` para **≤ 15** no jogo e no menu, com as isenções por tipo da `identidade-revisao.md`.
- As telas novas (Esconderijo, beco, prêmio) nascem no tema C e **não somam `ignore`**.
- Junto disso entra o **D2 da Ronda**, a dica "SOLTE E CLIQUE!" para quem só segura, porque a aproximação reaproveita esse verbo.

## 4. Fica de fora
| Item | Fase |
|---|---|
| Ringue da Lua, o Osmar desconfiar, o James ligar as tramas, as falas do Osmar guardadas | 8b |
| Vilões nacionais | 8b |
| Vilões mundiais | 9 |
| Vilões absurdos e a arte marcial do Gato Preto | 10 |
| Qualquer prêmio de poder: golpe "da noite", nós novos na região, bônus de lenda | 8b, se o dono quiser (pergunta 3) |
| Aliado ou informante, páginas de quadrinho, música da noite, variações de capuz e capa | capítulos seguintes |
| Revelar quem é o vulto | 11 |
| Sons próprios e conquistas | 13 e 14 |

## 5. Divisão
- **2a1, brigas de beco.** Entram:
  - o `kind` de briga, o Esconderijo com Dossiê e quadro, os 3 bandidos, o beco, a penalidade e as fichas;
  - os desafios e os 3 estilos;
  - o D2 da identidade;
  - a medida do teto.
  - **Jogável sozinha.**
- **2a2, o chefe.** Entram:
  - o supervilão, com amostra de arte aprovada antes, e a arena dele;
  - o troféu, normal e raro, o estilo raro, o título e o cartaz no menu.
- **Arte primeiro:** a amostra do **vulto lutando** (traje como camada sobre a folha de luta, em 3 discípulos e nas 3 artes) vai ao
  dono antes do elenco. A amostra do vilão vai antes da 2a2.

## 6. Critérios de aceite
1. **Quem não joga = igual:** a foto (`foto.gd`) de uma campanha inteira com o capuz nunca usado é idêntica à da main 626c70a.
2. **Quem briga = quem só faz SUSTO:** uma campanha indo em todas as brigas tem a mesma foto de quem só faz a Ronda 1 (dias, treino,
   dinheiro, FAMA, Legado, lutas da liga e `rng`). Só diferem os campos novos do Gato Preto, apagados com linha comentada.
3. **Teto de 10% com tudo junto:**
   - medido no simulador, numa corrida só, com os minigames da 7a2, a Ronda 1 com a região GATO PRETO e a Ronda 2a;
   - nada de soma à mão;
   - nenhum trecho passa de 10%;
   - se passar, encolhe primeiro o ×1,4 da equipe da região (D3 da Ronda).
4. **Perder é pequeno:** derrota na noite não encerra carreira e não mexe em Legado, FAMA, dias nem AQUECIDO. O capuz volta no
   relógio seguinte, e a lenda e o Dossiê nunca caem.
5. **Destrave:**
   - abaixo da lenda 3 ou sem o marco, o capuz leva ao SUSTO como hoje;
   - o chefe só aparece com lenda 5, os 3 bandidos vencidos e o cinturão regional;
   - um save no ponto certo e um no ponto errado provam isso nos testes.
6. **Difícil e honesto:**
   - o simulador mostra as metas do §3.2;
   - a prévia mostra a chance real;
   - a noite usa só a semente própria.
7. **Curta:** cada noite dura até ~60 s, e SAIR na aproximação não custa o capuz.
8. **Juice e tom:**
   - o K.O. tem letreiro, tremida e queda;
   - busca por sangue/blood nos dados, textos e arte = 0;
   - o vulto nunca mostra o rosto.
9. **Original:**
   - busca por batman/morcego/gotham sem resultado;
   - o vilão não lembra nenhum personagem de quadrinho;
   - o dono aprova as amostras (vulto lutando e vilão).
10. **Prêmios:** cada ficha, estilo e troféu aparece no lugar certo e persiste entre discípulos. Os estilos não mudam nenhum número
    (critério 2).
11. **Save:**
    - continua v13, só com campos opcionais;
    - fechar no meio da noite não duplica nem perde prêmio;
    - save sujo carrega, e a cópia do save do dono abre sem erro.
12. `tools/run_tests.ps1` verde, com save de teste, janelas em `--position 1950,40` e um Godot por vez.
13. **Alinhamento:**
    - `ui_audit --estrito` com **0 problemas**, cobrindo o Esconderijo (vazio e cheio), o quadro da noite, o beco, a luta da noite,
      o prêmio normal e o raro, e a personalização com os estilos;
    - **placar de `ignore` ≤ 15** (D2 da identidade).

## 7. Riscos
- **Traje sobre a folha de luta:** o capuz e a capa precisam vestir todas as animações das 3 artes. Esse é o maior custo. Se apertar,
  a ordem de corte é:
  1. a capa vira só o capuz na luta;
  2. o beco perde detalhes.
  O traje e o K.O. sem sangue não se cortam.
- **Difícil demais e ninguém vê o chefe:** o Dossiê mostra a silhueta de quem falta e o que precisa ("PRECISA DA LENDA 5"). O
  jogador sabe o que perseguir.
- **Prêmio só visual não puxar:** a proteção é o Esconderijo cheio e o cartaz no menu. Se os testadores ignorarem, a conversa vira a
  pergunta 3.
- **Tom virar violento:** a regra do §2, revisada no texto e na arte.
- **Adiantar a 8b:** nada de Osmar desconfiando na sala. A semente fica só no papel do Dossiê.

## 8. Perguntas ao dono (gosto)
1. **Qual supervilão?**
   - **A (recomendo):** o "rei do ferro-velho", com armadura caseira de calotas e câmara de pneu, que jura que é robô. O troféu é o
     capacete de calota amassado.
   - **B:** o eletricista que apaga a luz do bairro e briga com lanterna de capacete.
   - **C:** o ex-mascote de time de várzea preso na fantasia gigante, que virou chefe de gangue.
   - O Roteirista dá o nome.
2. **Estilos:** ficam disponíveis só na personalização do **próximo discípulo**, na tela que já existe (**recomendo**: sem tela
   nova), ou dá para trocar já no Esconderijo?
3. **Prêmio de poder:** a 2a fica **só com visual e lore** (**recomendo**: o teto fica intocado e o poder entra na 8b), ou já entra
   1 nó pequeno novo na região GATO PRETO, medido no simulador?

## Resumo para o Produtor
- A Ronda 2a traz brigas de verdade no beco: 3 bandidos e 1 supervilão regional, no motor de luta, com o relógio parado e sem
  sangue. O vulto segue sem rosto.
- É difícil de propósito. As brigas pedem lenda 3 e ter passado do Kid. O chefe pede lenda 5, os 3 bandidos e o cinturão regional.
  Perder só gasta o capuz da noite.
- Os prêmios são visuais e de lore: Dossiê, estilos na personalização, troféu no Esconderijo, título e cartaz no menu. Cada
  adversário tem um desafio que dá a versão rara.
- São 2 subfases jogáveis (2a1 com os bandidos e o D2 do `ignore` ≤ 15; 2a2 com o chefe). Os aceites são a foto igual, o teto de
  10% medido com tudo junto e o `--estrito` em 0.
- São 3 perguntas de gosto: qual vilão (recomendo o do ferro-velho), onde escolher os estilos e se entra algum prêmio de poder
  (recomendo que não).

## Decisões do dono (2026-11-25)
- Supervilão: o dono quer ver **um mockup de cada** (A, B, C) antes de escolher.
- Estilos: aparecem **só na personalização do próximo discípulo**. Não há troca no Esconderijo.
- Poder: o dono deixou a decisão para o Produtor, que decidiu **só visual e lore** na 2a. Nenhum nó de poder novo.
- Menu (identidade D4): primeiro o dono pediu o CONTINUAR sempre vermelho. Depois de ver a captura, mudou: **só o botão em foco fica vermelho** e os outros, CONTINUAR inclusive, ficam em papel.
- **Supervilão da 2a: C, Capivarão** (escolha do dono em 2026-11-25). Antes da arte final, o focinho precisa ler como capivara em 1x.
- **O B, Apagão (eletricista), fica guardado para um capítulo futuro.** O dono gostou e quer melhorá-lo: dar mais exagero ao corpo. Pode ser o vilão do Ringue da Lua na 8b ou do capítulo mundial.
- O A, Rei Calota, fica de reserva.
- **Atualização (2026-11-25):** depois de ver as versões v2, o dono trocou o supervilão. **O da 2a passa a ser o B, Apagão (v2)**: bateria nas costas, coroa de cabos, choque e a pose de apagão. Passiva sugerida: `adv_slippery`. Troféu: o capacete com a lanterna quebrada. **O Capivarão (v2) fica guardado** para um capítulo futuro, e o Rei Calota continua de reserva.
