# Fase 6b2 — Cara de lutador: design

Dono: Designer de Jogo. Data: 2026-11-15. Branch `fase-6b2` (sobre a 6b1 aprovada).
Base: `fase6b-escopo.md` (v2: §4.3–§4.5, critérios 13–20, "Escolhas do dono (2026-11-14)"), `fase6b1-design.md`, `fase6b1-api.md`, `fase6b1-revisao.md`, `data/disciples.json`, `docs/arte/paletas-6b1.md`, `direcao-visual.md` §3 e §23, `ui/tela_criar_discipulo.gd` (só leitura) e `scripts/game_state.gd` (roster e `mentores_na_sala`).
Fase de **conteúdo visual e uma regra de sala**. Nenhum número de economia, luta, calendário ou Legado muda (§6).

Decisões do Produtor que este design aplica (o dono passou o feedback aos testadores):
- Quem **perdeu** também conta como "o último que passou o posto" e fica na garagem.
- **Sem** botão "igual ao anterior" na tela de criação.

Quem manda em quê:
| Assunto | Documento que vale |
|---|---|
| Opções, ids, pesos, pares evitados, ordem da tela, regra do 2º mentor | **este** + `data/disciples.json` |
| Hex final das paletas novas (parte de cima, faixa) | Diretor de Arte (parte dos tokens da §1; pode trocar token, nunca id nem quantidade) |
| `mentor_2_spot` (posição), `head_anchor` das poses | Diretor de Arte / Artista de Personagens, no `manifest.json` |
| Rótulos das linhas e nomes das opções | Roteirista (`data/ui_texts.json`, chaves da §3.3) |

---

## 1. As opções e os ids

O formato e os ids já existem em `data/disciples.json` desde a 6b1 (o save v12 grava os 9 campos). A 6b2 **liga** as opções. Todas as cores são **tokens da paleta de 45** (`direcao-visual.md` §3); nenhuma cor nova.

### 1.1 Corte de cabelo (`hair_style`, 4)
| Id | Nome (provisório) | Peso no sorteio | Nota para a arte |
|---|---|---|---|
| `buzz` | raspado | 1 | quase rente, mostra o desenho do crânio; usa o tom escuro do cabelo |
| `short` | curto | 1 | o corte da 6b1 (padrão) |
| `volume` | volume | 1 | o mais alto junto com o `bun`; **primeiro a sair** se não ler no perfil (escopo §7) |
| `bun` | rabo/coque | 1 | coque alto atrás; no perfil é o que mais muda a silhueta |

A ordem do arquivo é a ordem da seta (do mais baixo ao mais alto). O `short` deixou de ser o primeiro, mas o padrão continua `short` (o save guarda id, não posição).

### 1.2 Parte de cima (`top` + `top_color`)
| `top` | Nome | Peso |
|---|---|---|
| `none` | sem (peito nu, como na 6b1) | 4 |
| `tank` | regata | 3 |
| `tee` | camiseta | 3 |

`top_color` — slots `[escuro, médio, claro]`:
| Id | Tokens | Por quê |
|---|---|---|
| `white` | `g3`, `cream`, `white` | padrão (vale só com `top` ligado) |
| `black` | `d1`, `d2`, `g0` | sem `ink` no corpo da peça: o contorno continua separando |
| `gray` | `g1`, `g2`, `g3` | camiseta de treino cinza. **Substitui o `red` da 6b1** |
| `blue` | `b0`, `b1`, `b2` | |
| `green` | `gr0`, `gr1`, `gr2` | |
| `yellow` | `br2`, `y0`, `y1` | |

- **Sem vermelho na parte de cima:** na guarda as luvas (`r1`/`r2`) ficam na frente do peito e sumiriam numa camisa vermelha. Mesmo motivo de não haver calção vermelho.
- Trocar `red` por `gray` não precisa de migração: o campo estava desligado, nenhum sorteio podia gravar `red` e o padrão é `white`. Um save com `top_color: "red"` (só se editado à mão) cai no padrão pela leitura tolerante.
- Regata e camiseta deixam **o peito liso** (sem estampa nem costura no meio), para o símbolo da escola da 6c entrar sem redesenho.

### 1.3 Faixa de cabeça (`headband` + `headband_color`)
| `headband` | Nome | Peso |
|---|---|---|
| `none` | sem | 3 |
| `band` | com faixa | 2 |

`headband_color` — slots `[escuro, claro]` (é uma tira de 2–3 px):
| Id | Tokens |
|---|---|
| `red` | `r1`, `r2` (padrão) |
| `white` | `cream`, `white` |
| `black` | `d1`, `g0` |
| `blue` | `b1`, `b2` |
| `green` | `gr1`, `gr2` |
| `yellow` | `y0`, `y1` |

O vermelho fica na faixa (é pequena, está na testa, e é a faixa clássica de quem treina). O Diretor de Arte confere os quadros em que a luva passa na frente da testa (ponto em aberto 3).

### 1.4 Meião (`socks`)
| Id | Nome | Peso | Cores |
|---|---|---|---|
| `none` | sem | 1 | as 3 cores-chave do meião viram pele `[shadow, base, base]`: some |
| `on` | com | 1 | cor do calção: `[dark, mid, band]` do `shorts_color` (a listra no alto do meião usa o tom do cós) |

O meião **não tem cor própria**. No JSON cada opção traz `source` (campo de onde vêm as cores) e `source_slots`. Trocar o calção troca o meião junto, na prévia e na sala.

### 1.5 Conta
Pele 5 × cor do cabelo 6 × corte 4 × calção 6 × parte de cima (1 + 2×6 = 13) × faixa (1 + 6 = 7) × meião 2 = **131.040 visuais**. Na arte são 4 cortes + 2 partes de cima desenhados em 2 vistas (**12 desenhos-base**) mais a faixa e o meião. Nenhuma combinação vira folha (critério 14).

---

## 2. Sorteio

O rascunho continua vindo sorteado ao abrir a tela, e o SORTEAR sorteia tudo de novo (6b1 §6.1). O que muda:

1. **Pesos.** Cada campo de `random.fields` sorteia entre as opções `enabled`, com probabilidade `weight / soma dos weights` (ausente = 1). Resultado: 40% sem parte de cima, 30% regata, 30% camiseta; 40% com faixa; 50% com meião; cortes e cores uniformes.
2. **Ordem:** sorteia os 9 campos, depois aplica as regras 3, 4 e 5, nesta ordem.
3. **Calção diferente do último** (`avoid_same_shorts_as_last`, já existe): igual ao último discípulo do `roster` → novo sorteio do calção **excluindo** o do último (0% de repetição; só repete se for a única opção ligada). *(Corrigido no B1 do QA.)*
4. **Cabeça diferente do último** (`avoid_same_hair_as_last`, novo): `hair_style` **e** `hair_color` iguais aos do último discípulo do `roster` → novo sorteio do `hair_style` **excluindo** o do último (0% de repetição; só repete se for a única opção ligada). *(Corrigido no B1 do QA.)* Motivo: na 6b2 o último fica do lado do novo na garagem, e a cabeça é o que mais identifica no tamanho da sala.
5. **Pares evitados** (`avoid_pairs`, novo; o "filtro de combinações feias" do escopo). Para cada par, na ordem do arquivo: se o look tem o valor de `if` **e** o de `and`, sorteia de novo o campo `reroll` (com peso). Repete a lista inteira até nenhum par bater ou até `max_rerolls` = 8 rodadas; se ainda bater, fica (nunca trava).

| Se | E | Sorteia de novo | Por quê |
|---|---|---|---|
| cabelo `black` | faixa `black` | `headband_color` | faixa some no cabelo (mesmos tokens) |
| cabelo `dark_brown` | faixa `black` | `headband_color` | `br0` × `d1` quase iguais em 1 px |
| cabelo `blond` | faixa `yellow` | `headband_color` | mesmos tokens |
| cabelo `copper` | faixa `yellow` | `headband_color` | `br3` × `y0` encostam |
| cabelo `platinum` | faixa `white` | `headband_color` | `cream` dos dois |
| pele `skin_5` | parte de cima `black` | `top_color` | tronco vira mancha escura na garagem |
| calção `white` | parte de cima `white` | `top_color` | lutador "todo branco" lava na luz quente |
| calção `yellow` | parte de cima `yellow` | `top_color` | idem, todo amarelo |

- Os pares valem **mesmo com a peça desligada** (ex.: faixa `none` com cor `black`): o valor escondido muda sem efeito visível, e a conta fica mais simples. Assim, ligar a faixa na tela já mostra uma cor boa.
- Os pares valem **só no sorteio**. Na tela o jogador escolhe qualquer combinação, inclusive as da tabela.
- O Diretor de Arte pode acrescentar ou tirar pares só no JSON.
- O sorteio continua sem usar a semente da luta nem nada da economia.

---

## 3. Tela de criação

### 3.1 Ordem dos campos
Com 10 linhas, a tela abre a 2ª coluna (`rows_per_column` = 6, a regra que a UI já tem). **Coluna 1 = cabeça, coluna 2 = corpo**, de cima para baixo como o corpo:

| # | Coluna | Linha | Campo | Mostra |
|---|---|---|---|---|
| 1 | 1 | NOME | `name` | caixa de texto (6b1) |
| 2 | 1 | PELE | `skin` | 3 chips |
| 3 | 1 | CORTE | `hair_style` | nome da opção |
| 4 | 1 | CABELO | `hair_color` | 2 chips |
| 5 | 1 | FAIXA | `headband` | nome (SEM / COM) |
| 6 | 1 | COR FAIXA | `headband_color` | 2 chips, depende de FAIXA |
| 7 | 2 | EM CIMA | `top` | nome (SEM / REGATA / CAMISETA) |
| 8 | 2 | COR | `top_color` | 3 chips, depende de EM CIMA |
| 9 | 2 | CALÇÃO | `shorts_color` | 3 chips |
| 10 | 2 | MEIÃO | `socks` | nome (SEM / COM) |

- A ordem está em `data/disciples.json → screen.rows` (dados, não código). Hoje a ordem vive na constante `CAMPOS` de `ui/tela_criar_discipulo.gd`; a UI/UX pode ler do JSON ou copiar a ordem, desde que fique igual.
- **Linhas que dependem de outra** (`depends_on`): com o pai em `none`, a linha de cor fica **apagada** (rótulo e chips em tom −2), a seta não faz nada e o valor fica guardado. Ligando o pai, a cor guardada volta. A linha não some (a janela não muda de tamanho a cada clique).
- O meião não tem linha de cor: a linha MEIÃO mostra SEM/COM, e a prévia mostra a cor do calção.
- Linha de texto: a seta passa pelas opções na ordem do JSON, em volta (depois da última vem a primeira), como as de cor.
- Sem botão "igual ao anterior" (decisão do Produtor). CONFIRMAR continua resolvendo em 1 clique.
- Rótulos com no máximo 9 caracteres na fonte 5x7 (a coluna do rótulo tem 56 px). Os textos finais são do Roteirista.

### 3.2 Prévia
A prévia grande mostra **todas as camadas** e a luva velha, atualizada a cada troca (como na 6b1). Com a parte de cima ligada e a luva na guarda, a prévia é o primeiro lugar em que o jogador vê o problema da camisa escura com pele escura; os pares do sorteio só evitam que ele receba isso pronto.

### 3.3 Textos novos (Roteirista)
| Chave | Sugestão | Observação |
|---|---|---|
| `disc_label_style` | CORTE | |
| `disc_label_band` | FAIXA | |
| `disc_label_band_color` | COR FAIXA | 9 caracteres, no limite |
| `disc_label_top` | EM CIMA | "CAMISA" mente quando é regata |
| `disc_label_top_color` | COR | fica logo abaixo de EM CIMA |
| `disc_label_socks` | MEIÃO | |
| `disc_opt_hair_style_<id>` | RASPADO, CURTO, VOLUME, COQUE | ≤ 9 caracteres |
| `disc_opt_top_<id>` | SEM, REGATA, CAMISETA | |
| `disc_opt_headband_<id>` | SEM, COM | |
| `disc_opt_socks_<id>` | SEM, COM | |

As cores continuam sem nome na tela (só chips), como na 6b1.

---

## 4. O segundo mentor (`mentor_2_spot`)

### 4.1 Quem é
**O segundo mentor é a última entrada do `school.roster` com `kind == "disciple"` e `end` em `room_mentors.passed_ends`.**
- `passed_ends` = `["defeat", "retire", "unknown"]`: derrota conta (decisão do Produtor), saída por vontade conta, e entradas vindas da migração (`unknown`) contam.
- O John (`kind == "first"`) nunca é o segundo mentor: ele já está no caixote.
- Não depende do número da campanha. Num save novo isso dá "da Carreira 3 em diante" (C1 John, C2 discípulo A sem 2º mentor, C3 com A). No save do dono, em que o John foi a Carreira 3, o Novato da Carreira 4 já é o 2º mentor da Carreira 5. Por isso a chave `second_mentor_from_campaign` saiu do JSON.

### 4.2 Quando aparece
Aparece no `mentor_2_spot` quando **todas** valem:
| Condição | Valor |
|---|---|
| Local | `garage` (academia é 6c) |
| John na sala | `"first" in school.mentors` (`requires_mentor`). Antes da cena grande de um save antigo, o John não está sentado, e o 2º mentor também não aparece |
| Lutador atual | discípulo (na campanha do John o roster está vazio de discípulos, então já não haveria ninguém) |
| Cena | **não** está tocando nem com a criação aberta da `primeira_sucessao` (`hidden_during_scenes`). A cena grande é do John. Num save novo isso não muda nada (o roster só tem o John nessa hora); serve para o save antigo, em que o Novato já estaria no roster. Ele aparece no `return_control`, sem animação |
| Existe alguém | há entrada que satisfaz a §4.1 |

**Troca a cada sucessão:** a entrada nova do roster é gravada no fim da campanha (`_encerrar_carreira`), então no RECEBER o 2º mentor **já é quem acabou de passar o posto**. A troca acontece com a garagem escurecida, atrás da tela de criação, sem pop visível. Na **chegada curta**, o novo entra pela porta e quem acabou de sair já está parado no canto, olhando: é o "passar o posto" das sucessões seguintes, sem uma linha de cena a mais.

**Se não houver ninguém:** o ponto fica vazio. Nada é desenhado, sem marca no chão, sem cadeira vazia. As regras de balão e de cobertura continuam só com quem está na sala.

### 4.3 Visual que o mentor guarda
- **O `look` gravado na entrada do roster**, os 9 campos, exatamente como estava no fim da campanha dele (critério 15: "com o visual que tinha"). Inclui parte de cima, faixa e meião. Nenhum campo novo no save.
- Entradas da 6b1 (sem os campos novos preenchidos de verdade) e as da migração (`Novato`) aparecem com o `default_look`: corte curto, sem parte de cima, sem faixa, sem meião (critério 17).
- `look` ausente ou inválido → `default_look`, com aviso (regra que já existe).
- O nome não aparece (não há texto na sala). Fica disponível em `mentores_na_sala()` para a 6c.

### 4.4 Pose: parado e **sem luvas**
| Item | Valor | Por quê |
|---|---|---|
| Pose | `stand_bare` (folha `disciple_stand_bare` da 6b1, 4 quadros, 4 fps, respiração de 1 px, em laço) | já existe e o manifest a chama de "base da pose de mentor da 6b2". Parado, sem gesto. De pé ocupa menos chão que sentado (o plano B do escopo para garagem lotada vira o plano A) |
| Luvas | **nenhuma** (`glove: "none"`) | o par do John fica com o discípulo atual; o mentor está de mãos nuas |
| Lado | `toward_bag`: virado para o saco. Ponto à esquerda de x 320 → folha virada à direita (`disciple_stand_bare`); à direita → `disciple_stand_bare_left` | sem espelho (regra da 6b1) |
| Camadas | todas (corte, cor, faixa, parte de cima, meião) e paletas do `look` dele | é a mesma composição do discípulo atual |
| Fala | nenhuma | falas de mentor são 6c |
| Gesto / toques | nenhum. `pedir_gesto` e `toques_mentor_*` continuam só do John | critério 8 |
| Clique / hover | não reage, não é alvo de clique | |
| Ordem de desenho | `sorted` pelo y dos pés, como as pessoas | |
| Balão | tem `head_anchor` próprio (medido com o corte mais alto, `volume`/`bun`); nenhum balão do Osmar ou do John cobre a cabeça dele | escopo §4.5 e critério 19 |

O "olha o saco de vez em quando" do escopo §4.5 **não entra**: o Produtor fechou "parado, sem gesto". Se o dono pedir vida a mais, é uma pose nova no mesmo ponto, sem mudar regra.

### 4.5 O ponto
`mentor_2_spot` vai em `manifest.json → layout.mentor_2_spot` (como o `mentor_spot`), escolhido pelo Diretor de Arte no mockup com equipe cheia, 4 caixas, porta aberta, John em (254,252) e a caixa da corda **na posição nova (424,287)**. Proposta do escopo: perto de (150,258), lado esquerdo do fundo (encaixa com a folha virada à direita). Regras do escopo §4.5 valem (fora da faixa do alvo x 281..362 com 8 px, fora da `no_cover`, fora do caminho da porta (423,221)→(303,272), sem cobrir Osmar, equipe nem caixas). `data/cena_player.json → points` ganha o mesmo ponto só como reserva.

---

## 5. Save: continua v12, sem migração

| Pergunta | Resposta |
|---|---|
| Os campos novos já estão no save? | Sim. `career.disciple.look`, `school.roster[].look` e `school.handover.draft.look` gravam os 9 campos desde a 6b1 |
| Precisa de campo novo? | **Não.** O 2º mentor é derivado do `roster` (nada gravado: nem quem é, nem onde está). A ordem da tela e os pesos são dados |
| Versão | `VERSAO_ATUAL` continua **12** |
| Save da 6b1 abre? | Sim, sem migração (critério 17). Os discípulos da 6b1 têm `short`/`none`/`white`/`none`/`red`/`none`, que são exatamente o visual da 6b1 |
| Ids aceitos | a leitura tolerante já aceitava ids com `enabled: false`; agora eles estão ligados. Id desconhecido (ex.: `top_color: "red"` editado à mão) → padrão do campo, com aviso |
| `room_mentors` | `defeat_counts_as_passed`, `second_mentor_from_campaign` e `second_mentor_phase` saíram (nenhum código lia). Entraram `passed_ends` e `second_mentor` |

Teste pedido: abrir um save v12 gerado na 6b1 com discípulo em andamento, 2 entradas `disciple` no roster e `handover` em `creating` → nada muda no arquivo além do autosave normal; o 2º mentor é o último do roster; o rascunho aberto mantém seus valores e o SORTEAR passa a variar os campos novos.

---

## 6. Balanço: nada muda

| Ponto | Por que não muda |
|---|---|
| Visual (corte, roupa, faixa, meião) | não é lido por economia, luta nem calendário |
| 2º mentor | só desenho; não toca `sala_ativa`, `_ocioso`, relógio, cliques nem comentários do Osmar |
| Tela com mais linhas | a carreira já está congelada com a criação aberta (6b1 §2): tempo de escolha não entra em `segundos_campanha` |
| Chegada curta | mesmo arquivo e mesmo teto de 2,5 s; o 2º mentor não é ator da cena |
| `data/` de balanço | nenhum arquivo muda (`training`, `generators`, `fights`, `opponents`, `shop`, `skill_tree`, `career`, `locations`) |

Simulação: nenhum parâmetro do `tools/sim/fase5_sim.py` muda, então o resultado é o da 6a/6b1 por construção. O QA confirma com `fase5_sim.py b23c` e `f52` e com o teste de `segundos_campanha` parado (critério 18).

---

## 7. Dados e contrato

### 7.1 `data/disciples.json` (já editado, `version` 2)
| Bloco | O que mudou |
|---|---|
| `fields.hair_style` | ordem `buzz, short, volume, bun`, `weight` |
| `fields.top` / `top_color` | `weight`; cores com `slots` `[dark, mid, light]` e tokens; `red` → `gray` |
| `fields.headband` / `headband_color` | `weight`; cores com `slots` `[dark, light]` e tokens |
| `fields.socks` | `slots` `[shadow, base, stripe]`; `source` e `source_slots` por opção |
| `random` | `avoid_same_hair_as_last`, `max_rerolls`, `avoid_pairs` (`if`, `and`, `reroll`) |
| `screen` (novo) | `rows_per_column`, `rows` (`field`, `label`, `kind`, `chips`, `depends_on`) |
| `room_mentors` | `passed_ends`, `second_mentor` (`enabled`, `requires_mentor`, `location`, `spot`, `pose`, `glove`, `facing`, `bag_x`, `hidden_during_scenes`) |

**As opções novas estão com `enabled: false`** para o build da 6b1 seguir verde até as camadas existirem (rodei `tools/run_tests.ps1` depois da edição: tudo passa). **O Programador liga cada campo quando as camadas dele estiverem no manifest.** Os demais valores (pesos, tokens, pares, ordem) são os finais. Na entrega, o teste `test_fase6b1.gd` linha 108 ("campos da 6b2 com uma opção só") tem de virar o teste da 6b2.

### 7.2 Para o Programador (nomes sugeridos)
| Onde | Item |
|---|---|
| `DiscipulosData` | sorteio com `weight`; regras 3–5 da §2; `cores(look)` resolve `source`/`source_slots` do meião (devolve as cores do meião já copiadas da pele ou do calção); leitura de `screen` e `room_mentors` |
| `GameState.mentores_na_sala()` | passa a devolver até 2 entradas: `{id: "first", spot: "mentor_spot", pose: "sit_rest"}` e `{id: "second", spot: "mentor_2_spot", pose: "stand_bare", glove: "none", facing: "right"\|"left", campaign, name, look}`. Regras da §4.2 |
| `GameState.segundo_mentor() -> Dictionary` | a entrada do roster (§4.1) ou `{}`, sem as condições de sala (para testes e para a 6c) |
| testes (save de teste) | pesos aproximados em 10.000 sorteios (±2 pontos percentuais); nenhum par da tabela sai em 10.000 sorteios (a chance de esgotar as 8 rodadas é de cerca de 1 em 1,7 milhão por sorteio); cabeça e calção diferentes do último; 2º mentor: roster vazio, só John, John + 1, John + 3 (pega o último), última entrada `retire` e `defeat`, campanha do John, academia, `mentors == []`, durante `primeira_sucessao`, durante `chegada_discipulo` (já é o novo último); save da 6b1 abre sem migração |
| `mentor_2_spot` | lido do manifest (`layout.mentor_2_spot`), reserva em `cena_player.json` |

### 7.3 Para a arte
- **Artista de Personagens:** 4 cortes, regata e camiseta, faixa e meião, em 3/4 e perfil, aplicados pelo gerador em todas as poses (inclusive `stand_bare` e `stand_bare_left`); máscara da luva na frente do cabelo; `head_anchor` medido com o corte mais alto. Cores-chave novas da folha (parte de cima 3, faixa 2, meião 3) não podem repetir nenhuma cor usada em outra coisa da folha (regra de `paletas-6b1.md`).
- **Diretor de Arte:** confere os tokens da §1 (pode trocar, mantendo ids e quantidade), os pares da §2, o lugar liso no peito e escolhe o `mentor_2_spot`.

---

## 8. Fora da 6b2 (não adiantar)
Falas dos mentores, saída do John e o último indo para o caixote, mentores na academia, mural, Honra, símbolo da escola na roupa (6c). Mais cortes e roupas, tipo de corpo, esparadrapo (13, se o dono pedir). Botão "igual ao anterior" (cortado pelo Produtor).

---

## Resumo
- **Opções:** 4 cortes (`buzz`, `short`, `volume`, `bun`); parte de cima `none`/`tank`/`tee` em 6 cores (`white`, `black`, `gray`, `blue`, `green`, `yellow`, sem vermelho); faixa `none`/`band` em 6 cores (`red`, `white`, `black`, `blue`, `green`, `yellow`); meião `none`/`on` copiando a cor do calção. Tudo com tokens da paleta de 45. 131.040 visuais, 12 desenhos-base.
- **Sorteio:** pesos (40% sem camisa, 40% com faixa, 50% com meião), calção e cabeça diferentes do último discípulo, 8 pares feios evitados (faixa que some no cabelo, camisa preta em pele escura, lutador de uma cor só). A escolha manual é livre.
- **Tela:** 10 linhas em 2 colunas: cabeça (NOME, PELE, CORTE, CABELO, FAIXA, COR FAIXA) e corpo (EM CIMA, COR, CALÇÃO, MEIÃO). A cor fica apagada com a peça em "sem". Ordem em `screen.rows`.
- **2º mentor:** a última entrada `disciple` do roster (derrota conta), na garagem, só com o John sentado, fora da cena grande. Visual = `look` do roster. Pose `stand_bare`, sem luvas, virado para o saco, sem fala, gesto ou clique. Troca no RECEBER, atrás da tela de criação. Sem ninguém, o ponto fica vazio.
- **Save:** continua v12, sem migração e sem campo novo. **Balanço:** inalterado.

## Pontos em aberto
1. **`mentor_2_spot`:** o Diretor de Arte escolhe (proposta (150,258), virado para a direita), conferindo com a caixa da corda em (424,287) e o caminho da chegada curta.
2. **"Olha o saco de vez em quando"** (escopo §4.5) ficou de fora por ordem do Produtor ("parado"). A pose é `stand_bare`, com a respiração de 1 px que a folha já tem. Se o Produtor quiser 100% estático, basta segurar o quadro 0. Isso só muda nos dados.
3. **Faixa vermelha × luva vermelha:** com `r1`/`r2` a faixa sumia na luva quando ela passa na frente da testa. **Resolvido:** a faixa `red` usa `[r2, r3]` (`#d4473a`/`#f07a5a`, deep `#9c2a2a`), aprovado pelo Produtor (comparação em `docs/arte/mockups/fase6b2_faixa_luva_x3.png`).
4. **Ligar as opções:** estão com `enabled: false` até as camadas existirem. O Programador liga, e o teste da 6b1 que exige "uma opção só" precisa ser trocado.
5. **Pesos e pares precisam de código novo** (`weight`, `avoid_same_hair_as_last`, `avoid_pairs`, `source` do meião): o `DiscipulosData` de hoje sorteia uniforme e não lê esses campos.
6. **Save antigo do dono:** o Novato migrado vira 2º mentor com o visual padrão. Isso está certo pela regra, mas o Produtor pode avisar o dono.
