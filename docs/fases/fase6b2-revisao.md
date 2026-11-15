# Fase 6b2 — Cara de lutador: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-15. Branch `fase-6b2`.
Li: `fase6b-escopo.md` (critérios 13–20 e "Escolhas do dono (2026-11-14)"), `fase6b2-design.md`, `fase6b2-api.md`, `fase6b2-textos.md`, `fase6b2-qa.md`, `fase6b1-revisao.md`, `docs/roadmap.md` e `docs/narrativa.md`.
Capturas conferidas: `f6b2_criar_cheio`, `f6b2_mentor2`, `f6b2_mentor2_dica` (depois da correção) e `f6b2_luta_cheio`.

Depois do QA, a equipe corrigiu:
- **B1:** o SORTEAR agora tira da lista o calção e a cabeça do último discípulo. O teste exige 0 repetições.
- **B2:** a dica do 2º mentor foi para a parede, acima da cabeça dele. Na captura, ela não cobre mais o lutador, a equipe nem o saco.
- **Faixa vermelha:** passou a usar `r2`/`r3` para não se confundir com a luva (era o ponto em aberto 3 do design).

Decisões do Produtor, porque o dono disse que o feedback agora vem dos testadores:
- quem perdeu também senta na garagem;
- não há botão "igual ao anterior".

Estado atual:
- `ui_audit`: 305 estados com 0 problemas, em duas rodadas;
- `run_tests`: passa, com 3.063 verificações numa pasta isolada;
- balanço: os dados de balanço são idênticos aos da 6b1, e a simulação f6a deu igual.

## 1. Veredito
**Aprovado. A 6b2 fecha a Fase 6b.**
- Os critérios 13–20 passam, e os dois bugs baixos foram corrigidos.
- A 6b1 já estava aprovada (`fase6b1-revisao.md`). Somadas, as duas entregam o que o dono pediu em 2026-11-14:
  - cortes, cor do cabelo e roupas;
  - o John e o último que passou o posto juntos na garagem.
- O que falta é a opinião dos testadores (§7). Ela calibra a 6c, mas não reabre a 6b. A exceção seria um problema de leitura grave, como ninguém perceber quem é o 2º mentor.

## 2. A visão foi entregue?
| Pedido (dono / escopo) | Entregue? | Como |
|---|---|---|
| *"cortes diferentes, além de roupas etc"* | **Sim** | 4 cortes (raspado, curto, volume, coque), regata/camiseta em 6 cores, faixa em 6 cores e meião na cor do calção. Dá 131.040 visuais |
| A cor do cabelo muda | **Sim** (já desde a 6b1) | 6 cores, agora em todos os cortes |
| *"ele e o último que aposentou"* enquanto o John estiver | **Sim** | O John fica no caixote e o último discípulo fica no `mentor_2_spot` (150,262), com o visual que tinha. Na Carreira 2 aparece só o John |
| Cada opção aparece em todas as poses | **Sim** | 132 folhas e 6.336 composições sem erro. A luva passa na frente do cabelo. Na captura da luta, o coque, a faixa e a camiseta leem no perfil, inclusive no retrato do HUD |
| Sem folha por combinação | **Sim** | Foram 224 PNG novos (32 poses x 7 camadas), que crescem com as opções e não com as combinações |
| "Esse lutador agora é meu" | **Sim** | A prévia muda na hora, a tela confirma em 1 clique e o visual escolhido acompanha o lutador até a luta |
| Sem mudar números | **Sim** | Nenhum `data/` de balanço mudou e o relógio fica parado com a criação aberta |

### O que ficou bom
- **A tela de criação não pesou.** Ela tem 10 linhas em duas colunas, com a cabeça à esquerda e o corpo à direita, na ordem do corpo. A janela continua do mesmo tamanho e CONFIRMAR resolve em 1 clique. A cor apagada quando a peça está em "SEM" é a escolha certa, porque a janela não pula.
- **O sorteio tem bom gosto.** Os pares feios (faixa que some no cabelo, camisa preta em pele escura, lutador de uma cor só) não saem, e o novo nunca vem igual ao anterior. A escolha manual continua livre.
- **A troca do 2º mentor acontece atrás da tela escura.** Na chegada curta, quem acabou de sair já está no canto olhando o novo entrar. É o "passar o posto" das sucessões seguintes sem nenhuma cena a mais, como eu queria.
- **A luta ganhou identidade.** O retrato do HUD mostra o corte e a camiseta do discípulo. O lutador do jogador deixou de ser genérico.
- **O peito liso na regata e na camiseta** deixa o símbolo da escola entrar na 6c sem redesenho.

### Pontos de atenção (não bloqueiam)
- **O 2º mentor pode se misturar com a equipe.** Na `f6b2_mentor2`, ele está de pé ao lado dos vizinhos, sem luva e com o mesmo porte. Só a dica do mouse diz quem ele é. É o maior risco de leitura da fase e vai como pergunta para os testadores (§7, pergunta 4). Se ninguém perceber, o ajuste da 6c é barato: uma pose própria (braços cruzados, ou encostado olhando o saco, que estava no escopo e foi cortada) ou ele ocupar o caixote quando o John sair.
- **A pose "olha o saco de vez em quando" saiu** por ordem do Produtor. Aceito, porque é só dado e a pose entra no mesmo ponto se pedirem.
- **Os rótulos ficaram curtos: "CIMA" e duas linhas "COR".** Pela posição, cada "COR" fica logo abaixo da sua peça e lê bem na captura. Mesmo assim, "CIMA" sozinho soa estranho em português, e a coluna 2 tem espaço (CALÇÃO cabe). **Recomendo trocar para "EM CIMA" antes de mandar aos testadores.** É uma troca só de texto (`disc_label_top`) e depois precisa rodar o `ui_audit`. Não bloqueia.
- **R1 do QA (faixa branca em cabelo platina, com a luva creme):** quase some, mas só na escolha manual. Aceito, porque escolher é direito do jogador.
- **No modo luta, o adversário também pode usar faixa branca.** Na `f6b2_luta_cheio`, os dois lutadores estão de faixa branca. As cores do calção e da camiseta separam bem os dois, e por isso não bloqueia. Só fica registrado para quando o Designer de UI olhar a leitura da luta.

## 3. Algo passou do escopo?
**Não.**
- Os mentores não falam, não fazem gesto e não reagem a clique. Só o John faz os toques.
- Não entrou mural, Honra, saída do John, mentores na academia nem símbolo na roupa.
- O save continua na v12, sem campo novo e sem migração.
- O botão "igual ao anterior" e a pose de olhar o saco ficaram de fora, o que é menos escopo, e não mais.

## 4. Pendências antes do merge
| Pendência | Decisão |
|---|---|
| Há sprites do discípulo e `.import` modificados que não foram commitados (`git status`) | **Commitar tudo** na `fase-6b2` antes do merge e rodar o `run_tests` de novo no commit final |
| O design §2 ainda diz "1 novo sorteio" (o B1 mudou para "excluir o último") e o §1.3 cita `r1`/`r2` na faixa | O Designer **atualiza o texto** do design. É só documento |
| "CIMA" → "EM CIMA" | Recomendado (§2). Roteirista e UI/UX, com o `ui_audit` em seguida |
| `fase5_sim.py` comparado byte a byte com a 6b1 | **Aceito sem a comparação.** Os dados e o `tools/sim` são idênticos, e a f6a deu igual |
| `docs/narrativa.md` diz que James Blindado "é o chefe do título mundial", mas o `roadmap.md` (linhas 151 e 217) diz que o campeão mundial é **outro** personagem e que o rival termina em respeito | **Contradição de visão.** O Roteirista alinha `narrativa.md` ao roadmap antes da 8a, ou o Produtor pergunta ao dono qual vale. Não afeta a 6b nem a 6c |

## 5. O que fica para a 6c (e depois)
| Item | Fase |
|---|---|
| Saída discreta do John. O último que passou o posto vai para o caixote e o `mentor_2_spot` esvazia | **6c** |
| Falas dos mentores (recorde, revanche, "mais longe que eu") | **6c** |
| Mural/hall com retratos, Honra e árvore do hall. É aqui que entra a diferença entre derrota e saída por vontade | **6c** |
| Mentores e Osmar na academia, cena da chegada à academia | **6c** |
| Símbolo da escola no peito (o lugar já está liso) | **6c** |
| Pose própria do 2º mentor (olhar o saco ou braços cruzados) | **6c**, se os testadores não o distinguirem da equipe |
| Botão "igual ao anterior" | **6c**, só se os testadores acharem a criação cansativa |
| Rival James Blindado em jogo | **8a** (Arco 4), conforme o roadmap |
| Mais cortes e roupas, tipo de corpo, esparadrapo | **13**, se pedirem |

Lembrete para a 6c, que vem da 6b1: a parte 1 da cena grande está a 0,14 s do teto. Se uma pose entrar ali, outra sai.

## 6. Roteiro de teste (cerca de 10 min, para os testadores)
Use um **jogo novo** ou um save de teste já na Carreira 2 ou depois.
1. **Termine uma campanha** (perca uma luta ou aperte PASSAR O POSTO) e aperte NOVO DISCÍPULO.
2. **Criação (1 min).** Aperte SORTEAR umas 5 vezes. Depois monte um lutador do seu jeito, com corte, faixa, camiseta e meião, e CONFIRME.
3. **Garagem.** Treine 1 minuto. Olhe a sala.
4. **Luta.** Lute uma vez e repare no seu lutador e no retrato no alto.
5. **Mais uma sucessão.** Termine a campanha, crie outro lutador e veja a entrada pela porta.

## 7. Perguntas para os testadores (linguagem simples)
1. Você conseguiu deixar o lutador **com a sua cara**? Sentiu falta de algum corte ou roupa?
2. Apertando **SORTEAR**, saiu algum lutador feio ou estranho? Qual?
3. A tela de criar lutador ficou **rápida** ou **chata** de passar em toda campanha? Você queria um botão "igual ao anterior"?
4. Na garagem, **você percebeu quem era o lutador de pé no canto esquerdo**, sem luvas? Ou achou que era alguém da equipe?
5. Ver o lutador anterior ali **fez você sentir que a garagem tem história**, ou deixou a sala cheia demais?
6. Na luta, você **reconheceu o seu lutador** de longe (corte, faixa, roupa)?
7. Alguma palavra da tela de criação **não ficou clara** (por exemplo "CIMA" ou "COR")?
8. Alguma combinação de cores **sumiu** (faixa que some no cabelo, camisa que some na pele)?

## Resumo para o Produtor
- **Aprovado. A 6b2 fecha a Fase 6b.** Os critérios 13–20 passam e B1/B2 foram corrigidos. O audit dá 305 estados com 0 problemas, os testes passam e o balanço não mudou. O pedido do dono está atendido: cortes, cor do cabelo, roupas e o John junto do último que passou o posto na garagem.
- Antes do merge: commitar os sprites pendentes e rodar o `run_tests` no commit final. Recomendo trocar "CIMA" por "EM CIMA".
- **Maior risco:** o 2º mentor pode parecer alguém da equipe. A pergunta 4 dos testadores decide se ele ganha uma pose própria na 6c.
- **Para o dono:** `narrativa.md` diz que James Blindado é o chefe do mundial, mas o roadmap diz que não. Alguém precisa decidir antes da 8a.
- **A 6c recebe:** a saída do John com o último indo para o caixote, as falas dos mentores, o mural/Honra, a academia e o símbolo no peito.
