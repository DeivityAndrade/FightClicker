# Ronda Noturna do Gato Preto: revisão

Diretor de Jogo, 2026-11-25. Base: `ronda-escopo.md` (com as Decisões do dono), `ronda-design.md`, `ronda-textos.md`,
`ronda-qa.md` (1ª rodada, Respostas do Programador e Reteste). O jogo não foi rodado; usei os relatórios e as capturas do QA.

## Veredito: APROVADA COM RESSALVAS
Pode ir para o dono assim que o **N1** (vulto cortado na borda no VISTO) estiver corrigido e com captura nova.
Nenhuma ressalva abaixo bloqueia; elas viram tarefas (D1…).

## Critérios de aceite (§7)
| # | Critério | Situação |
|---|---|---|
| 1 | Quem não joga = foto da main | **OK.** Hashes idênticos; só diferem listas de leitura (nós `cat_*`). Aceito a explicação do BUG-4 |
| 2 | Quem joga = mesma foto (até o 1º nó da região, regra do dono) | **OK.** `ident` igual em 8 de 8 jogadores; sorteios e falas iguais depois do corte do BUG-2 |
| 3 | Abre na campanha seguinte ao boato; 1ª carreira nunca vê | **OK** (mais a rede da campanha 5) |
| 4 | Capuz: nunca em janela/luta/cena, nunca abre sozinho, máx. 1 | **OK.** "Testador sem dica acha em 2 aparições" **não foi medido com pessoa** → teste do dono (D4) |
| 5 | 25–40 s, SAIR a qualquer hora, piso > 0 | **OK** (23–32 s de ronda + contagem e prêmio; SAIR = +1, sem duplicar) |
| 6 | Legível com 1 linha, pelo menos 1 SUSTO | **OK no robô** (92/62/19% fazem 3 sustos). Pessoa real: teste do dono. Furo de quem só segura (D2) |
| 7 | SUSTO com juice | **OK** (letreiro, tremida, ladrão caindo, som reaproveitado) |
| 8 | Lenda: 5 níveis, recortes nos 3 locais, nome a partir do 1, nunca cai | **OK.** Nit: o centro não tem captura de recorte por nível (D6) |
| 9 | Original, amostra aprovada | **OK.** Busca limpa, capa reta, amostra aprovada pelo dono com a faixa vermelha; BUG-1 (vulto sem capuz) corrigido |
| 10 | Save | **OK** (8 saves sujos, fechar no meio, cópia do save do dono sem aviso) |
| 11 | `run_tests.ps1` verde, save isolado | **OK** |
| 12 | `ui_audit` 0 problemas | **OK** (23 estados), com **N1 pendente** |

## O que ficou bom
- **O tom acertou:** o que acontece é pequeno (ladrão cai de bunda), a manchete é que cresce até o absurdo. É o PROMPT §3 em miniatura.
- **Verbo próprio:** avançar/congelar/SUSTO é legível e não é cópia do Choque nem da Panfletagem.
- **Economia blindada:** a Ronda congela tudo, os sorteios não se cruzam e a região só ajuda conveniência, com valores fixos.
- **Decisões do dono cumpridas:** região GATO PRETO travada por lenda; campo `nights` pronto para outro tipo de noite.
- **Corte certo do BUG-2:** as falas do Osmar saíram (fora do escopo §8) e foram guardadas, sem perder o texto.
- **Vulto com identidade:** capuz, faixa e "R" vestem 4 discípulos diferentes, sem espelhar.

## O que desvia (pequeno)
- **Quem só segura nunca vê o aviso** (chega ao fim do muro antes do 1º olhar e fica parado). A graça do jogo é congelar a tempo;
  esse jogador sai com +1 e acha que "não tem nada ali".
- **Teto de 10% com margem de 0,4 ponto** (Kid 9,6%), somado à mão, sem medir Ronda + 7a2 juntas. Passa, mas abaixo do ruído do próprio simulador.

## Tarefas futuras
| # | Tarefa | Dono sugerido | Quando |
|---|---|---|---|
| D1 | Fechar o N1 (vulto não sai da tela no VISTO, `max(x, 0)` ou recuo menor) e refazer a captura `ronda_visto` | UI/UX | **antes de mostrar ao dono** |
| D2 | Tapar o furo de quem só segura: o 1º ladrão da 1ª ronda dá o 1º AVISO cedo (antes de ~2 s de muro) **ou** no fim do muro aparece "SOLTE E CLIQUE!". Escolher 1, só dados/texto | Designer (+ UI/UX) | ajuste rápido, pode entrar já ou na Ronda 2 |
| D3 | **Ronda 2 mede o teto de 10% com tudo junto** (Ronda + região GATO PRETO + minigames da 7a2 + o que a Ronda 2 trouxer), no simulador, nada de soma à mão. A 8b também remede se mexer em renda de equipe. Se passar de 10%, o primeiro a encolher é o ×1,4 da equipe da região | Designer | design da Ronda 2 e da 8b |
| D4 | Teste do dono com pessoa real: acha o capuz em ≤ 2 aparições? Entende a 1ª ronda só com a linha de instrução? | Produtor | ao apresentar a fase |
| D5 | Estabilizar o roteiro B do `qa_ronda_ui.gd` (flaky por tempo real; N2) | QA | quando sobrar tempo |
| D6 | Capturas do recorte por nível também no CENTRO no audit | UI/UX | próxima passada de audit |

## Ganchos que a Ronda atual deixa para a Ronda 2
Já existem (não mexer agora):
- campo `nights` no `ronda.json` com só `scare`: a briga entra como novo `kind`, sem tela nova de entrada;
- capuz no prego como porta única (a Ronda 2 decide como o jogador escolhe a noite, sem convite do Osmar);
- lenda da linhagem 0–5 e contador `scares`/`rounds`: o "Ringue da Lua" pode exigir lenda alta sem campo novo;
- falas do Osmar sobre a lenda guardadas em `ronda-textos.md` ("Guardado para a Ronda 2"): base da desconfiança dele;
- os 3 ladrões com corpo próprio: viram os primeiros bandidos.

Para a Ronda 2 já nascer certa (decidir no escopo dela):
- relógio parado e opcional, como agora; o tom mais sujo **sem violência gráfica** (apagar, derrubar, fugir; nada de sangue);
- se a briga der qualquer prêmio de economia, vale o D3 antes de aprovar;
- tensão de identidade (Osmar, James) só como insinuação: revelar quem é o vulto continua fora até a fase 11;
- as falas do Osmar mexem no sorteio de falas: a Ronda 2 precisa decidir isso de propósito e atualizar a prova de "foto igual".

## Resumo para o Produtor
- Ronda Noturna **aprovada com ressalvas**: todos os 12 critérios passam no que é automático; o vulto agora veste o capuz em qualquer discípulo.
- Só falta o **N1** (vulto cortado no VISTO) antes de mostrar ao dono; o resto vira tarefa (D2–D6).
- No teste, peça ao dono para ver se acha o capuz sozinho e entende a 1ª ronda (D4); avise que segurar direto não funciona (D2).
- A Ronda 2 tem de **medir o teto de 10% com tudo junto** no simulador (D3); os ganchos (`nights`, lenda, falas guardadas, ladrões) já estão no lugar.
