# Fase 6b — Primeira sucessão: escopo

Dono: Diretor de Jogo. Data: 2026-11-14. Branch `fase-6b` (sobre a 6a).
Li: `PROMPT.md`, `docs/roadmap.md` (6b e 6c), `docs/visao.md`, `docs/direcao-narrativa.md` (manda), `docs/cutscenes/ideia-do-dono.md` (com a "Prancha da 6b: escolhas do dono", **todas as opções A**), `docs/cutscenes/prancha-6b.md` (aprovada; suas correções valem sobre os storyboards), `primeira-sucessao.md`, `formato-dados.md`, `gesto-assinatura.md`, `fase6a-escopo.md`, `fase6a-revisao.md`, `fase6a-api.md` e os pontos da garagem em `assets/sprites/manifest.json`.
**Versão 2 (2026-11-14):** ajustada às respostas do dono (seção "Escolhas do dono", no fim). Com cortes de cabelo, roupas e o segundo mentor na sala, a fase ficou grande demais para uma entrega só e foi **dividida em 6b1 e 6b2**, cada uma jogável.

## 1. Objetivo e sensação
- A Carreira 1 acaba e o John **passa o posto de verdade**: tira as luvas, pendura no saco, e um discípulo criado pelo jogador entra pela porta e calça o par dele. O John fica na garagem como mentor e, a cada sucessão, quem acabou de passar o posto fica ali também.
- Sensação: *"ele não foi embora, está sentado ali me olhando treinar, esse lutador agora é meu, e a garagem lembra de quem passou por ela"*. Sem despedida triste.
- A cena é o primeiro uso do **player de cena por dados**, feito de um jeito que a 6c (academia) e a fase 11 (reencontro) só acrescentem passos, sem mudar o formato.

## 2. A divisão
| Parte | Nome | O que o dono joga no fim dela |
|---|---|---|
| **6b1** | Passar o posto | A cena completa da sucessão, a tela de criação com **nome, pele, cor do cabelo e cor do calção**, o John sentado como mentor, a chegada curta nas campanhas seguintes e a luva "o par do John". |
| **6b2** | Cara de lutador | A mesma tela ganha **cortes de cabelo, parte de cima (regata/camiseta), faixa de cabeça e meião**, e a garagem passa a mostrar **o John e o último que passou o posto**. |

Por que essa ordem: a 6b1 entrega a história inteira (a cena é a prioridade da direção narrativa) e já monta o discípulo **em camadas**, com uma opção só por camada. A 6b2 só acrescenta conteúdo nas camadas e um ponto novo na garagem, sem mexer na cena nem no player. O dono aprova a 6b1 jogando antes de a 6b2 começar.

## 3. Decisões do Diretor
1. **A prancha manda.** Quadros S1–S10 de `prancha-6b.md`, com as escolhas A do dono: tela de criação no meio (S5), luvas penduradas no saco, luz do dia branca, Osmar presente e calado, corte 2x no gesto (S3). Onde `primeira-sucessao.md` diverge, vale a prancha (luvas na argola perto de (325,206)/(331,211), porta emperrada no ombro, borda em y 171).
2. **Player de cena: formato completo, execução só do que a 6b usa.** O validador conhece todos os tipos de `formato-dados.md` (inclusive `view: fight`, `frame`, `name_card`, `light`, `start_fight`, `photo`, `versions`). O player executa só os passos da vista `room` desta fase. Os outros entram com quem precisa deles (6c, 11).
3. **Personalização em camadas, nunca folha por combinação** (detalhe na §4.4). Cada opção é desenhada uma vez por vista (3/4 da garagem e perfil da luta), e o gerador de personagens aplica a opção em todas as poses usando as âncoras de cabeça e tronco de cada quadro. A cor é troca de paleta. Só visual: nenhuma escolha muda número.
4. **A tela de criação aparece em toda campanha nova**, mas abre já preenchida (nome e aparência sorteados). CONFIRMAR resolve em 1 clique.
5. **Sucessões seguintes:** sem a cena grande. Tela de criação e uma **chegada curta** (porta sobe, discípulo passa por baixo, sem fala, ≤ 2,5 s, pulável), como segunda cena de dados.
6. **Quem fica na garagem** (regra do dono): enquanto o John está na história, o John e o último que passou o posto. Depois da saída do John (6c), só o último que passou o posto.
   - "Passou o posto" vale para **qualquer fim de campanha** (derrota ou saída por vontade): pela direção narrativa, todo lutador que encerra vira mentor. A diferença entre os dois (Honra, bônus no mural) é da 6c.
   - Na 6b: Carreira 2 tem só o John; da Carreira 3 em diante, o John e o discípulo anterior.
   - Os mentores na garagem **não falam** na 6b. Só o John faz os dois toques sem luva. As falas de mentor ficam para a 6c.
7. **Mural/hall fica na 6c.** Ele vem junto com a Honra e a árvore do hall, que mexem em economia, e a 6b tem o critério de balanço inalterado. A 6b grava a lista de discípulos da escola (fora do reset), então ninguém se perde até lá.
8. **Símbolo da escola na roupa:** continua **6c**. A parte de cima da 6b2 já deixa o lugar do símbolo no peito livre, para ele entrar depois sem redesenhar.
9. **Ordem no começo da campanha nova** (uma fila só, nada por cima de nada): cena parte 1 → tela de criação → cena parte 2 → escolha da arte (se pendente) → cartão de início → reação do 1º clique → comentários do Osmar no próximo momento calmo.
10. **O relógio da campanha não anda** durante a parte presa da cena nem com a tela de criação aberta.
11. **Save antigo (o do dono):** a cena toca no **próximo** "receber novo discípulo". Se o dono já começou uma Carreira 2 com o discípulo padrão, esse discípulo ganha nome padrão e aparência padrão, e a cena toca no fim dessa campanha. Não há tela retroativa.
12. **Esparadrapo depois de derrota:** fica de fora (fase 13).

## 4. O que entra

### 4.1 Player de cena por dados (6b1)
- `data/cutscenes/<id>.json`, um player só, uma fila só (`formato-dados.md` §1–§6).
- Passos usados: `wait`, `say` (cena e passivo), `move`, `pose`, `face`, `show`/`hide`, `sound`, `camera` (1x e 2x com corte seco), `ui`, `prop`, `shake`, `open_screen`, `return_control`, `parallel`, `sequence`, `reactions` (`first_click`, `idle_seconds`) e `end_state`.
- Marco gravado **no começo**, com salvamento imediato, junto com os `grants` (`mentor_in_room`).
- **Pular:** segurar ESC ou ESPAÇO 0,5 s, ou o botão PULAR com anel (`linguagem.md` §5). Leva ao próximo `open_screen` ou aplica o `end_state` em ≤ 0,3 s. As `reactions` continuam armadas.
- **Validador** em `tools/` (§7 do formato) e **captura de cena** com save de teste.
- O modo de cena do balão (com `▼`), pronto desde a 6a, passa a ser usado.

### 4.2 Cena "Primeira sucessão" (6b1)
- S1–S10 da prancha. Parte 1 ≈ 9 s, parte 2 ≈ 6,2 s, `max_seconds` 16.
- O avesso do gesto (`gloves_off`) com corte 2x na região (222,154,192,136). Os toques do John no S10 são **sem luvas** (`mentor_first_taps`, som `tap_fist`), com o mesmo intervalo de 0,22 s.
- O discípulo **não faz o gesto** (no `take_gloves`, no máximo um `strap_rip` curto, sem toques).
- Falas: `suc_guarda` ("vamos ver sua guarda.") e `suc_isso` ("isso.", passivo). Osmar sem fala.
- Funciona com Carreira 1 curta.

### 4.3 Tela "receber novo discípulo" (6b1, ampliada na 6b2)
- Por cima da garagem escurecida, janela no meio, cena congelada atrás. Não pode ser pulada nem fechada com ESC. Abre preenchida.
- Prévia grande do discípulo com a luva velha, atualizada a cada troca. Botão **sortear** para tudo e **CONFIRMAR**.
- Nome: tamanho máximo e caracteres limitados ao que a fonte 5x7 desenha. Vazio não confirma (volta ao sorteado).
- **6b1:** nome, pele, cor do cabelo, cor do calção.
- **6b2:** corte de cabelo, parte de cima (com cor), faixa de cabeça (com cor) e meião. A janela é desenhada na 6b1 já com espaço para essas linhas, para a 6b2 não refazer o layout.

### 4.4 Personalização em camadas
**Como montar o discípulo (vale nas duas partes):**
| Camada (de trás para a frente) | O que é | Como varia |
|---|---|---|
| Corpo | pele, calção, meião, sapato e luvas (as folhas que já existem, com sufixo de luva) | paleta: pele, calção; meião é cor-chave que some (vira pele) quando "sem meião" |
| Parte de cima | regata ou camiseta | folha de camada por opção, cor por paleta |
| Cabeça | corte de cabelo e faixa | folha de camada por corte, cor por paleta; faixa é uma cor-chave dentro da camada |
| Frente | quadros em que a luva passa na frente do rosto | máscara por quadro gerada pelo gerador, para a luva não ficar atrás do cabelo |

- O Artista de Personagens desenha cada corte e cada parte de cima **uma vez por vista** (3/4 e perfil). O `personagem_lib.gd` gera a camada para todas as poses do discípulo pela âncora da cabeça e do tronco de cada quadro. Nenhuma combinação vira folha inteira.
- Todas as camadas usam o mesmo quadro e o mesmo pivô da folha do corpo. O jogo empilha as camadas em tempo real e aplica as paletas.
- Valem em **todas** as folhas do discípulo: garagem, luta, poses da cena e poses de mentor.
- O John não usa o sistema: ele mantém as folhas dele.

**Opções iniciais:**
| Campo | 6b1 | 6b2 |
|---|---|---|
| Nome | digitado ou sorteado | — |
| Pele | 5 tons | — |
| Cor do cabelo | 6 | — |
| Corte de cabelo | 1 (o atual) | **4**: raspado, curto, volume, rabo/coque |
| Calção (cor) | 6 | — |
| Parte de cima | nenhuma | **3**: sem, regata, camiseta; 6 cores |
| Faixa de cabeça | nenhuma | **2**: sem, com; 6 cores |
| Meião | nenhum | **2**: sem, com (cor acompanha o calção) |

- São 4 cortes e 2 partes de cima desenhados em 2 vistas: **12 desenhos-base** para a 6b2, contra milhares de folhas se fosse por combinação.
- O save grava o visual com **todos os campos desde a 6b1** (os da 6b2 com o valor padrão). A 6b2 não precisa de migração.
- Mais opções (outros cortes, roupas, tipo de corpo) ficam para a fase 13, se o dono pedir.

### 4.5 Mentores na garagem
- **John (6b1):** sentado no caixote no ponto `mentor_spot` (268,268), pose `sit_rest`. Dois toques sem luva no 1º clique de cada campanha nova e na volta à garagem depois de uma vitória, no máximo 1 por minuto. Qualquer clique cancela. Fica até a saída (6c).
- **Último que passou o posto (6b2):** a partir da Carreira 3, no ponto novo `mentor_2_spot`, parado e sem luvas, com o visual que tinha e uma pose viva simples (respira e de vez em quando olha o saco). Não fala, não faz gesto e não reage a clique.
- Só na garagem. Na academia, os mentores entram com a 6c.

**Pontos que a arte precisa (Diretor de Arte confere no mockup com a equipe cheia, as 4 caixas e a porta aberta):**
| Ponto | Uso | Posição | Regras |
|---|---|---|---|
| `mentor_spot` | John no caixote (6b1). Na 6c, quando o John sair, o último que passou o posto passa a ocupar este ponto | (268,268), da prancha | já aprovado na prancha |
| `mentor_2_spot` | último que passou o posto, enquanto o John está (6b2) | **proposta: lado esquerdo do fundo, perto de (150,258)**, encostado na parede; alternativa: canto direito perto de (490,250). O Diretor de Arte escolhe | fora da faixa do alvo (x 281..362) com 8 px de folga; fora da `no_cover` (310,180,52,94); fora do caminho da porta (de (423,221) a (303,272)); sem cobrir os pontos da equipe (176,284), (220,258), (488,286), (455,236), (398,230), o Osmar (196,236) e as caixas |
| `head_anchor` das poses de mentor | onde o rabicho de um balão apontaria e o retângulo de cabeça que nenhum balão pode cobrir | um por pose; no discípulo, medido com o **corte mais alto** | entra no `ui_audit` |

### 4.6 A luva velha (6b1)
- O cartão da luva inicial mostra a descrição **"o par do John"** (pendência da 6a), com uma variante para o discípulo.
- Nenhuma mudança de número.

### 4.7 Textos de campanha (6b1)
- O botão do fim de campanha passa a ser **"RECEBER NOVO DISCÍPULO"** (o Roteirista confirma a forma).
- Onde hoje aparece "Carreira N", aparece o **nome do discípulo** (o número pode ficar pequeno, se o Designer achar útil).

### 4.8 Porta de enrolar (6b1)
- `garage_door` em 3 estados, luz do dia no chão (dither), sombra de pés, sons `door_shake`, `door_roll`, `door_jam`. No resto do jogo, fechada como hoje.

### 4.9 Correções herdadas da 6a (6b1)
- Chip "ESC esc: pular" corrigido junto com o botão PULAR.
- Regra nova do balão: **não cobre a cabeça de nenhum personagem** (`direcao-visual.md` §22.2): Osmar, John e, na 6b2, o segundo mentor.

## 5. O que fica de fora
| Item | Fase |
|---|---|
| Cortes de cabelo, parte de cima, faixa, meião e o 2º mentor na sala | **6b2** (não entram na 6b1) |
| Mural/hall, retratos, Honra e árvore do hall | 6c |
| Falas dos mentores (recorde, revanche, "mais longe que eu") | 6c |
| Saída discreta do John; o último que passou o posto passa para o caixote | 6c |
| Mentores e Osmar na academia; cena da chegada à academia | 6c |
| Símbolo da escola na roupa | 6c |
| Passos de luta do player em execução (`view: fight`, `frame`, `name_card`, `light`, `start_fight`) | 11 (e vinhetas da 10) |
| Reencontro final, John mais velho, última arena | 11 |
| Mais cortes e roupas, tipo de corpo, esparadrapo depois de derrota | 13, se o dono pedir |
| Opção de desligar blips | 13 (sobe só se o dono pedir) |
| Qualquer mudança de economia, preço, luta, calendário ou Legado | — |

## 6. Critérios de aceite

### 6b1 — Passar o posto
1. **Cena inteira:** depois da Carreira 1, ao apertar "receber novo discípulo", a parte 1 dura ≤ 9,5 s, a tela de criação abre, e a parte 2 devolve o controle em ≤ 6,5 s depois do CONFIRMAR. O validador soma ≤ 16 s presos.
2. **Carreira 1 curta:** perdendo a 1ª luta (ou passando o posto antes de lutar), a cena toca igual.
3. **Pular:** na parte 1, segurar ESC/ESPAÇO 0,5 s ou clicar em PULAR leva à tela de criação com as luvas já no saco. Na parte 2, em ≤ 0,3 s fica o estado do S10. A tela de criação não pode ser pulada. A reação do 1º clique toca mesmo pulando.
4. **Toca uma vez só:** o marco `cena_primeira_sucessao` é gravado no começo. Pular, perder, passar o posto ou fechar o jogo em qualquer ponto não faz a cena tocar de novo. Da Carreira 3 em diante só aparecem a tela de criação e a chegada curta (≤ 2,5 s, pulável).
5. **Fechar o jogo no meio:** fechando antes de CONFIRMAR, ao abrir de novo a tela de criação aparece (sem a cena) e a campanha só começa depois dela. Fechando depois, o discípulo está lá com o nome e a aparência escolhidos.
6. **Personalização:** nome, pele, cor do cabelo e cor do calção aparecem na garagem, na academia, na luta (todas as luvas) e no fim de campanha. O John mantém a aparência dele. Nenhuma escolha muda número.
7. **Clique primeiro:** depois de `return_control`, o 1º soco vale no mesmo quadro. O John reage (dois toques sem luva e "isso.") e senta. Os toques do mentor nunca passam de 1 por minuto e qualquer clique os cancela.
8. **Só o John faz o gesto:** nenhum discípulo faz os dois toques, nem na cena, nem na luta.
9. **Save novo:** abertura da 6a → Carreira 1 com o John → fim → cena → discípulo criado. Tudo em ordem, sem duas janelas ao mesmo tempo (§3, item 9).
10. **Save antigo (cópia de teste do save do dono):** a migração preserva Legado, árvore, atributos, calendário e marcos da 6a. A cena toca no próximo "receber novo discípulo". Um discípulo padrão em andamento ganha nome padrão e continua normal.
11. **Lista da escola:** cada discípulo que passa o posto fica gravado em `school` (nome, visual completo, como terminou, recorde) e sobrevive a qualquer reset que não seja "Apagar save".
12. **Cartão da luva** mostra "o par do John" (e a variante do discípulo).

### 6b2 — Cara de lutador
13. **Opções novas:** os 4 cortes, as 3 partes de cima, a faixa e o meião aparecem certos em **todas** as poses do discípulo (garagem, luta com todas as luvas, cena e chegada curta). A luva que passa na frente do rosto fica na frente do cabelo.
14. **Sem folha por combinação:** o número de arquivos novos cresce com o número de opções, não com as combinações (o QA confere a contagem no manifest).
15. **Dois mentores:** na Carreira 2 só o John está na garagem. Da Carreira 3 em diante, o John no caixote e o último que passou o posto (derrota ou saída) no `mentor_2_spot`, com o visual que tinha. A cada sucessão o segundo mentor é trocado pelo novo último.
16. **Nada cobre o jogo:** com a equipe cheia, as 4 caixas, a porta aberta e os dois mentores, ninguém cobre a faixa do alvo nem a `no_cover`, e a chegada curta passa sem atravessar um mentor.
17. **Save da 6b1 abre na 6b2 sem migração:** discípulos criados na 6b1 aparecem com os valores padrão nos campos novos.

### As duas partes
18. **Balanço inalterado:** a simulação da 5.4/6a dá os mesmos números. O relógio fica parado na parte presa da cena e com a tela de criação aberta. Nenhum segundo entra em luta ou calendário.
19. **`ui_audit` com 0 problemas** (skill `alinhamento-ui`), incluindo:
    - tela de criação: nome vazio, nome no tamanho máximo, cada campo (e, na 6b2, todas as linhas novas);
    - botão PULAR com anel, chip de pular corrigido e balão em modo de cena;
    - John sentado com balão do Osmar e, na 6b2, os dois mentores com balão do Osmar e do John: **nenhum balão cobre cabeça**;
    - nome do discípulo onde antes estava "Carreira N".
20. **Testes passando:** `run_tests` verde, testes novos com **save de teste** e validador sem erro em todo `data/cutscenes/`. Janelas de teste abrem com `--position 1950,40`.

## 7. Riscos
- **A cena prender demais.** 15 s numa fase de jogo rápido. Proteção: pular em 0,5 s, controle volta com o 1º clique valendo, toca uma vez na vida do save.
- **Tela de criação cansar** quem faz muitas campanhas curtas. Proteção: abre preenchida e confirma em 1 clique. Se ainda cansar, o ajuste é um botão "igual ao anterior".
- **Camadas não encaixarem em todas as poses** (o maior risco técnico, agora maior com cortes e roupas). Proteção: a 6b1 já roda o sistema de camadas com uma opção, então o encaixe é testado antes de multiplicar opções. Na 6b2, o corte "volume" é o primeiro a sair se não ler no perfil.
- **Garagem lotada** com Osmar, equipe, caixas, dois mentores e o discípulo. Proteção: o critério 16 e o mockup de conferência do Diretor de Arte. Se não couber, o segundo mentor fica de pé encostado na parede, ocupando menos espaço.
- **Arte demais na 6b1.** Ordem de corte: (1) chegada curta das sucessões seguintes (vira só a tela e um corte seco), (2) toques do mentor depois de vitória, (3) luz do dia em dither (vira só a fresta). **Não se cortam:** player, cena S1–S10, tela de criação, camadas em todas as folhas, John como mentor, luva "o par do John".
- **Formato que não serve ao reencontro.** Proteção: o validador já conhece todos os tipos de passo, e o Diretor de Cutscenes escreve o `reencontro_final.json` só como rascunho validável.

## 8. Papéis
| Papel | 6b1 | 6b2 |
|---|---|---|
| **Diretor de Cutscenes** (Fable) | Monta `primeira_sucessao.json` e `chegada_discipulo.json` pela prancha e confere pela captura. Rascunho de `reencontro_final.json` só para o validador | Confere a chegada curta com os cortes e roupas novos |
| **Artista de Personagens** | Poses do John: `hold_bag`, `gloves_off`, `hang_gloves`, `look_door`, `walk` sem luvas, `point_spot`, `sit_rest`, `mentor_first_taps`. Poses do discípulo: parado sem luvas, `duck_under`, `walk`, `take_gloves`. **Separar o discípulo em camadas** (corpo e cabeça) no `personagem_lib.gd`, com âncoras de cabeça e tronco e máscara de luva por quadro, em todas as folhas. Decidir se o espelho serve para quem entra andando para a esquerda. Tudo pela `padrao-personagem` | 4 cortes, regata e camiseta, faixa e meião, cada um em 3/4 e perfil, aplicados pelo gerador. Pose de mentor do discípulo (parado sem luvas, respira, olha o saco) com todas as camadas |
| **Diretor de Arte** | `garage_door` (3 estados), luz do dia, sombra de pés, caixote e `mentor_spot`, luvas na argola. Paletas de pele (5), cabelo (6) e calção (6), legíveis na garagem, na academia e na luta. Caracteres da fonte 5x7 aceitos no nome | Paletas de parte de cima e faixa (6 cada). Escolher o `mentor_2_spot` no mockup com a equipe cheia, caixas e porta aberta. Lugar livre no peito da parte de cima para o símbolo da 6c |
| **Roteirista** | Polir `suc_guarda` e `suc_isso`. Botão "receber novo discípulo" e textos da tela. **Lista de nomes para sortear** (≥ 30, originais, tom de bairro). Nome padrão do discípulo migrado. "O par do John" e a variante. Textos onde "Carreira N" vira nome. Arquivo `docs/fases/fase6b-textos.md` | Rótulos das opções novas (cortes, roupas) |
| **Designer** | Fila do começo da campanha. Regras do nome. Formato do visual (já com os campos da 6b2), discípulo atual, lista da escola e migração. Frequência dos toques. Relógio parado. Simulação de não-regressão. Arquivo `docs/fases/fase6b-design.md` | Regra do segundo mentor (quem entra, quando troca). Sorteio que evita combinações feias |
| **Programador** | Player de cena, validador e captura. Composição em camadas com paleta em tempo real. Save novo com migração e testes em save de teste. Sons `bag_catch`, `chain_creak`, `lamp_hum`, `strap_open`, `door_shake`, `door_roll`, `door_jam`, `tap_fist`. John na sala. API para a UI (`fase6b-api.md`) | Camadas novas nos dados. Segundo mentor na sala, trocado a cada sucessão. Teste de que o save da 6b1 abre sem migração |
| **UI/UX** | Tela "receber novo discípulo" com prévia e espaço para as linhas da 6b2. PULAR com anel e chip corrigido. Balão em modo de cena. Regra do balão que não cobre cabeça. Nome no HUD e no fim de campanha. `alinhamento-ui` com 0 problemas | Linhas novas da tela. Estados de dois mentores no `ui_audit`. `alinhamento-ui` com 0 problemas |
| **QA** | Critérios 1–12, 18–20, com atenção a 3, 4, 5, 10 e 18 | Critérios 13–20, com atenção a 13 (todas as poses), 15 e 16 |

## 9. O que o dono valida quando jogar
**6b1:**
1. Se a cena emociona e se 15 s parece muito ou na medida.
2. Se o S3 (o John tirando as luvas, de perto) lê bem.
3. Se a tela de criação é rápida o bastante para fazer toda campanha.
4. Se o John sentado assistindo funciona e se os toques cansam.
5. Se a chegada curta das campanhas seguintes agrada ou atrapalha.

**6b2:**
6. Se os cortes e as roupas bastam para o discípulo ficar "dele".
7. Se o segundo mentor na garagem dá a sensação de linhagem sem poluir a sala.

## 10. Perguntas para o dono
Nenhuma trava o começo. Uma decisão minha para ele confirmar quando jogar:
- **"O último que aposentou" inclui quem perdeu?** Decidi que **sim**: na direção narrativa, todo lutador que encerra a campanha (perdendo ou saindo) vira mentor. Se ele quiser só quem saiu por vontade, muda uma regra nos dados, sem mexer na arte.

## Escolhas do dono (2026-11-14)
1. **Personalização**, nas palavras dele: *"O cabelo tem que mudar a cor e também temos que deixar o player escolher entre alguns cortes diferentes, além de roupas etc"*.
   - Entram nome, pele, cor do cabelo, cortes de cabelo e roupas (calção, parte de cima, faixa de cabeça e meião), em camadas (§4.4). A fase foi dividida em 6b1 e 6b2.
2. **Quem fica na garagem**, nas palavras dele: *"Até o arco onde o john não aparece mais deve ser ele e o ultimo que aposentou, depois apenas o que aposentou"*.
   - Na 6b: o John e, a partir da Carreira 3, o último que passou o posto (§4.5, 6b2). Depois da saída do John (6c), só o último, no caixote.

## Resumo para o Produtor
- Com as respostas do dono, a 6b foi dividida em duas partes jogáveis. A **6b1 (Passar o posto)** traz a cena da sucessão no player por dados, a tela de criação com nome, pele, cor do cabelo e calção, o John sentado como mentor e "o par do John".
- A **6b2 (Cara de lutador)** acrescenta 4 cortes de cabelo, regata/camiseta, faixa e meião, e o último que passou o posto na garagem, ao lado do John.
- Para a arte não explodir, o discípulo é montado em camadas desde a 6b1: cada corte ou roupa é desenhado uma vez por vista e o gerador aplica em todas as poses. São 12 desenhos-base na 6b2, sem folhas por combinação.
- Mural, Honra, falas de mentor e saída do John continuam na 6c. O balanço não muda em nenhuma das duas partes.
- Uma decisão para o dono confirmar jogando: quem perdeu também conta como "o último que aposentou" (decidi que sim).
