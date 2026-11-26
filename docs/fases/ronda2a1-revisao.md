# Ronda 2a1 (brigas de beco do Gato Preto): revisão do Diretor

Diretor de Jogo, 2026-11-26. Base: `ronda2a-escopo.md` (com as decisões do dono), `ronda2a-design.md`, `ronda2a-textos.md`,
`ronda2a-contrato.md`, `ronda2a-qa.md` (com o Reteste), as capturas `caps_r2a/r2a_*` e as pranchas `docs/arte/mockups/ronda2a_*.png`.
O jogo não foi rodado.

## Veredito
**Aprovada, com 3 condições** antes de mostrar ao dono. As 3 já estão com o Programador:
- **T1:** o estado `r2a_aprox_dica` do verificador fica estável (8 de 8 execuções passando).
- **T2:** o `--estados` falha quando recebe um nome que não existe.
- **Retrato do HUD:** o retrato do bandido na luta vira silhueta enquanto o nome está escondido, como na prévia. Depois da
  correção, uma captura nova de `r2a_luta_beco` precisa provar isso.

Nenhuma das 3 mexe em número nem em save. Basta o QA repetir o `--estrito` dos 22 estados `r2a_*`.

| # | Critério do escopo (§6) | Resultado |
|---|---|---|
| 1 | Quem não joga = igual | **OK.** A foto só difere no `cat_thanks` +20%, o corte que o dono aprovou |
| 2 | Quem briga = quem só faz SUSTO | **OK.** Passou nos testes do dev e no roteiro B do QA, com os 5 sorteios intactos |
| 3 | Teto de 10% com tudo junto | **OK, 8,8%.** Medido numa corrida só. A margem é curta (D5) |
| 4 | Perder é pequeno | **OK.** O capuz volta em 240 s, aparece a REVANCHE e o Dossiê fica intacto |
| 5 | Destrave | **OK.** Lenda 3 + `regional_league_opened`, bandidos em ordem e a ficha do chefe trancada em "LENDA 5" |
| 6 | Difícil e honesto | **OK.** Prévia = motor (até 3 pontos de diferença em 1000 sementes). A luta só usa `_rng_ronda` |
| 7 | Curta | **OK no papel.** A aproximação dura 10 s e SAIR não grava. A noite inteira com a luta animada não foi cronometrada (D6) |
| 8 | Juice e tom | **OK.** K.O. com letreiro e queda, sem sangue. O vulto aparece só com capuz e faixa nos olhos e se chama "???" |
| 9 | Original | **OK no texto** (busca = 0). **Falta o dono olhar** a capa nova do vulto (D1) |
| 10 | Prêmios | **OK.** Ficha, recorte nos 3 locais e estilo aparecem no lugar certo e persistem. Os estilos não mudam número |
| 11 | Save | **OK.** Continua v13, fechar no meio não duplica, 20 saves sujos carregam e o save real não foi tocado |
| 12 | `run_tests` | **OK.** Tudo verde, com save de teste e janela em 1950,40 |
| 13 | Alinhamento | **OK.** 22 estados com 0 problemas e placar de `ignore` em **7** (meta ≤ 15). Falta o T1 ficar estável |

## O que ficou bom
- **A sensação de "segredo difícil" funciona.** O Dossiê cheio, com retrato, apelido, "VENCIDO NA 5ª CAMPANHA" e a silhueta
  "??? LENDA 5", é exatamente o progresso de colecionador que o escopo pedia. Mostra o que já foi feito e o que falta.
- **O beco tem o tom certo.** Tem chuva, poça, poste, lixeira "07" e o pichado "VILA". Fica mais sujo que a liga e sem violência
  nenhuma.
- **A noite é disciplinada:** relógio parado, sorteio próprio, tudo gravado no LUTAR e a prévia honesta. É a fase mais segura até
  agora para quem não joga a Ronda.
- **Nome escondido até vencer.** "LADRÃO DO ESTEPE" vira "O CHAVE DE RODA" depois da vitória. É pequeno e dá vontade de descobrir
  quem é.
- **O B5 foi bem resolvido.** A capa virou lona cinza curta com remendo, e na silhueta chapada sumiram a capa pontuda e as orelhas
  em ponta. Hoje o vulto lê como "moleque de touca de gato", não como herói de capa preta.
- **O D2 da identidade passou da meta:** o placar de `ignore` foi de >15 para 7, e as telas novas não usam `ignore` nenhum.

## Tarefas futuras
| # | Tarefa | Responsável |
|---|---|---|
| D1 | **O dono valida o vulto novo** (prancha `ronda2a_vulto_antes_depois.png` e luta no beco). Se ainda lembrar o morcego, a saída combinada é tirar a capa e deixar só a touca. A touca e a faixa não se cortam | Produtor → dono; Diretor de Arte |
| D2 | A capa ainda é um placeholder feito por código (prega e atraso). Antes da 2a2, ela precisa ser desenhada à mão com peso de lona, nas 3 artes | Artista de Personagens |
| D3 | Os pontinhos do prêmio ("○○○●●" sob "LENDA 3") leem ao contrário à primeira vista. Basta conferir a direção (é o mesmo padrão da Ronda 1) e decidir se vale uma legenda | Designer UI/UX |
| D4 | Na prévia aparece "LADRÃO DO ESTEPE" e no HUD aparece "O LADRÃO DO ESTEPE". Escolher um dos dois e usar nos dois lugares | Roteirista |
| D5 | O teto está em 8,8% contra 10%. **Toda fase que mexer em equipe, Legado ou região (2a2, 8b) roda o `ronda2a_sim.py teto` de novo** | Designer |
| D6 | Cronometrar 1 noite inteira (aproximação, luta animada e prêmio) e confirmar que fica em ~60 s ou menos | QA |
| D7 | **A 2a2 (Apagão) herda o seguinte:** | |
| | a) A ficha "??? LENDA 5" do Dossiê vira o Apagão, com cadeado nos 3 requisitos: lenda 5, os 3 bandidos e o cinturão regional | Programador / UI/UX |
| | b) O cartão "O BECO ESTÁ QUIETO. POR ENQUANTO." passa a mostrar a noite do chefe | UI/UX / Roteirista |
| | c) Os 4 lugares vazios da prateleira de TROFÉUS recebem o capacete de lanterna quebrada e a versão rara com a lâmpada acesa | Diretor de Arte |
| | d) Passiva `adv_slippery`, atributos de partida ~110M/220M/325M, a calibrar para 30–50%, e o desafio "ANTES DO APAGÃO" com raro ≤ 20%. Medir no simulador | Designer |
| | e) O apagão é **só apresentação** (~1 s de escuro). A chance não muda, e a prévia continua honesta | Designer / Programador |
| | f) Mostrar ao dono a amostra de arte do Apagão (corpo exagerado, v2) e da arena antes do elenco | Diretor de Arte / Artista de Personagens |
| | g) O retrato do chefe já nasce com a regra corrigida agora: silhueta enquanto ele não foi vencido, em todo lugar | UI/UX |
| | h) Entram ainda o letreiro de entrada, o título da imprensa, o cartaz no canto do menu (ID4) e o estilo raro. O `--estrito` cobre os estados novos | UI/UX / Roteirista |
| | i) A testemunha do chefe diz "o vulto luta como gente de academia", só no papel. Nada de fala do Osmar | Roteirista |

## Resumo para o dono (o que testar)
- Com **lenda 3** e já tendo entrado na liga regional, o capuz leva ao **Esconderijo**. Lá dá para escolher SUSTO ou o próximo
  bandido e ver o Dossiê.
- **Teste 1:** fazer uma noite de briga, ver o nome escondido até vencer, ganhar a ficha e conferir o recorte na parede da sala.
- **Teste 2:** perder de propósito. Nada da carreira deve mudar, e o capuz volta em ~4 min com a marca REVANCHE.
- **Teste 3:** olhar a nova capa do vulto (lona cinza) e dizer se ainda lembra o morcego.
- **Teste 4:** com um desafio cumprido, criar o próximo discípulo e achar o estilo marcado com o gato na personalização.
