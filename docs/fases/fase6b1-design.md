# Fase 6b1 — Passar o posto: design

Dono: Designer de Jogo. Data: 2026-11-14.
Base: `fase6b-escopo.md` (v2, com "Escolhas do dono"), `docs/cutscenes/prancha-6b.md` (aprovada, todas as opções A), `ideia-do-dono.md`, `formato-dados.md`, `fase6a-design.md`, `fase6a-api.md`, `fase6b1-textos.md` (Roteirista), `scripts/game_state.gd` e `scripts/save_store.gd` (save v11).
Fase de **sistemas e regras**. Nenhum número de economia, luta, calendário ou Legado muda (§9).

Quem manda em quê:
| Assunto | Documento que vale |
|---|---|
| Fluxo da sucessão, estados, save v12, migração, regras do mentor, sorteio, paletas (alvo) | **este** + `data/disciples.json` |
| Passos, tempos e poses das cenas | `data/cutscenes/primeira_sucessao.json` e `chegada_discipulo.json` (Diretor de Cutscenes) |
| Textos, banco de nomes, nome padrão | `fase6b1-textos.md`, `data/ui_texts.json`, `data/nomes_discipulos.json` (Roteirista) |
| Hex final das paletas | Diretor de Arte (parte dos alvos da §6.3) |

---

## 1. O fluxo da sucessão

### 1.1 Quando há sucessão
"Receber novo discípulo" é o antigo NOVA CAMPANHA, apertado na tela de fim (`fim` pendente). Chame de **campanha nova** = `career_number + 1`.

| Caso | Condição | O que acontece |
|---|---|---|
| **Primeira sucessão** | campanha nova `> first_fighter_campaign` **e** marco `cena_primeira_sucessao` ausente | parte 1 da cena → tela de criação → parte 2 |
| **Sucessão seguinte** | campanha nova `> first_fighter_campaign` **e** marco presente | tela de criação → chegada curta |
| **Começo do John** (só save antigo, §5.3) | campanha nova `== first_fighter_campaign` | NOVA CAMPANHA de hoje, sem tela e sem cena |

A cena grande toca **uma vez na vida do save**, na primeira sucessão, seja quem for que encerrou (John ou discípulo padrão de save antigo). Não depende de vitórias: Carreira 1 com 0 vitórias (perdeu a 1ª luta ou passou o posto antes de lutar) toca igual.

### 1.2 Estados
Estado em memória `sucessao` (o Programador escolhe o nome):

| Estado | Entra | Sai | Vai para o save? |
|---|---|---|---|
| `none` | jogo normal | RECEBER | — |
| `scene_1` | RECEBER com primeira sucessão (passo 1 da §1.3 já aplicado) | `open_screen` da cena, ou PULAR | grava como `creating` |
| `creating` | `open_screen`; RECEBER em sucessão seguinte; carga com `handover.stage == "creating"` | CONFIRMAR | sim: `creating` |
| `scene_2` | CONFIRMAR na primeira sucessão (com a cena em andamento) | `return_control` (ou PULAR → `end_state` + `return_control`) | grava como `arriving` |
| `arriving` | CONFIRMAR nas seguintes, ou depois de fechar o jogo na criação | fim da chegada curta (ou PULAR) | sim: `arriving` |
| `none` | `return_control` | — | `handover = null` |

Regra: **com `sucessao != none` a carreira fica congelada igual à tela de fim**. Isso já resolve o relógio (§2).

### 1.3 Passo a passo (primeira sucessão)
1. **RECEBER** (um único `salvar()` no fim deste passo):
   1. tira a foto dos nós (`nos_ativos_ids`), zera a carreira, `career_number += 1`, `fim = {}` (exatamente o `nova_carreira()` de hoje);
   2. **não emite** `nova_carreira_iniciada`, `escolha_arte_pedida` nem o gatilho `after_defeat` (ficam para o passo 4);
   3. sorteia o rascunho (§6.1) e grava `school.handover = {stage: "creating", campaign, scene: "primeira_sucessao", draft}`;
   4. grava o marco `cena_primeira_sucessao = {campaign, version: 1}` e aplica os `grants` (`mentor_in_room` → `school.mentors = ["first"]`);
   5. `salvar()`; emite `marco_gravado("cena_primeira_sucessao")`.
2. **Parte 1** toca (S1–S4). PULAR leva ao `open_screen`.
3. **Tela de criação** (S5). Não fecha com ESC, não pula. Cada troca atualiza `handover.draft` (vai no autosave, sem salvar a cada troca). **CONFIRMAR**:
   1. valida o nome (§6.2); vazio → volta ao sorteado e não confirma;
   2. grava `career.disciple` (§3.2), `handover.stage = "arriving"`, `salvar()`.
4. **Parte 2** (S6–S9) e `return_control`. No `return_control` (ou ao aplicar o `end_state`):
   1. `handover = null`, `salvar()`;
   2. emite, nesta ordem, o começo da campanha: `nova_carreira_iniciada(cartao_inicio())`, `escolha_arte_pedida` (se pendente) e o gatilho `after_defeat` (se a regra da 6a pedir). A UI já trata a ordem "arte antes do cartão";
   3. arma as `reactions` da cena (`first_click`).
5. **1º clique** (S10): vale no mesmo quadro do `return_control`. John faz os toques sem luva + "isso." (reação da cena) e `career.mentor_greeted = true`.

**Sucessões seguintes:** passo 1 sem os itens 4 e 5 (marco já existe) e com `scene: "chegada_discipulo"`; abre direto a tela de criação; CONFIRMAR toca a chegada curta (`arriving`); o fim dela é o passo 4. O 1º clique da campanha dá os toques pela regra do mentor (§4), sem fala.

Fila do começo da campanha (escopo §3 item 9), sem nada por cima de nada:
`parte 1 → criação → parte 2 (ou chegada curta) → escolha da arte (se pendente) → cartão de início → toques do 1º clique → comentários do Osmar no próximo momento calmo`.

### 1.4 Fechar o jogo no meio
| Fechou durante | Save tem | Ao abrir |
|---|---|---|
| Parte 1 | marco gravado, `handover.stage = "creating"` | tela de criação **sem a cena**, sobre a garagem escurecida, John já sentado no `mentor_spot`, luvas no saco. O rascunho é o último gravado |
| Tela de criação | idem | idem. Depois de CONFIRMAR toca a **chegada curta** (a parte 2 não toca: depende do estado da parte 1) |
| Parte 2 ou chegada curta | `career.disciple` gravado, `handover.stage = "arriving"` | aplica o `end_state` sem tocar nada e faz o passo 4 (arte, cartão, `after_defeat`). `mentor_greeted` continua `false`: o 1º clique dá os toques, sem "isso." |
| Depois do `return_control` | `handover = null` | jogo normal |

Nenhum caso repete a cena grande (o marco nasce no passo 1). Nenhum caso deixa a campanha começar antes do CONFIRMAR.

---

## 2. Relógio parado (balanço inalterado)
- Com `sucessao != none`, o `tick` trata a carreira como com a tela de fim: **não somam** `tempo_jogo`, `_ocioso`, `segundos_campanha`, produção, arte, Metrônomo, assistido, ouro, risco. Continuam só `_tick_falas` (que não terá fala, por não haver sala calma) e o autosave.
- `sala_ativa()` ganha a condição `sucessao == none`. Como `clicar()` exige `sala_ativa`, nenhum soco vale antes do `return_control`; no quadro do `return_control` vale.
- A carreira nova nasce com `segundos_campanha = 0`, dia 1, `fight_day` = dia 1 + folga do 1º adversário (igual a hoje). Ela só começa a contar no `return_control`.
- Os passos da cena **depois** do `return_control` (porta descendo, reações) tocam com o relógio andando, igual a qualquer animação da sala.
- Os toques do mentor são só visuais: não mexem em `sala_ativa`, `_ocioso` nem no relógio.

---

## 3. Save v12

### 3.1 Visual (`look`), com os campos da 6b2 desde já
```json
"look": { "skin": "skin_3", "hair_color": "brown", "hair_style": "short", "shorts_color": "green",
          "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none" }
```
| Campo | Valores (ids de `data/disciples.json` → `fields`) | 6b1 | Padrão |
|---|---|---|---|
| `skin` | `skin_1`..`skin_5` | escolhe | `skin_3` (o tom atual) |
| `hair_color` | `black`, `dark_brown`, `brown`, `copper`, `blond`, `platinum` | escolhe | `brown` |
| `hair_style` | `short` (6b1); `buzz`, `volume`, `bun` (6b2) | fixo | `short` (o corte atual do discípulo) |
| `shorts_color` | `green`, `blue`, `black`, `white`, `purple`, `yellow` | escolhe | `green` |
| `top` | `none`; `tank`, `tee` (6b2) | fixo | `none` |
| `top_color` | 6 ids (6b2) | fixo | `white` |
| `headband` | `none`; `band` (6b2) | fixo | `none` |
| `headband_color` | 6 ids (6b2) | fixo | `red` |
| `socks` | `none`; `on` (6b2, cor do calção) | fixo | `none` |

- Valores são **ids (texto)**, nunca índices: reordenar a lista não muda ninguém.
- Leitura tolerante: campo ausente ou id desconhecido → valor de `default_look`, com aviso. Um id com `enabled: false` **é aceito** no save (a 6b2 só liga as opções; o save da 6b1 abre sem migração, critério 17).
- O visual é só aparência: nenhum campo é lido por economia, luta ou calendário.

### 3.2 Discípulo atual: `career.disciple`
```json
"disciple": { "name": "Tati Gancho", "look": { ... }, "campaign": 2 }
```
| Campo | Regra |
|---|---|
| `career.disciple` | `null` na campanha do John (`lutador_atual() == "first"`). Nas outras, obrigatório; se faltar ou vier inválido → `{name: nome_padrao, look: default_look}`, com aviso |
| `name` | texto já validado (§6.2), guardado como digitado. Nunca é chave de texto: trocar o banco de nomes não renomeia ninguém |
| `campaign` | `career_number` em que ele entrou (identifica o discípulo; é único) |

Nome mostrado (`nome_lutador()`): John → `cast.first.name` ("John Bullet"); discípulo → `career.disciple.name`. A interface aplica `.to_upper()`.

### 3.3 Outros campos novos
| Onde | Campo | Tipo | Regra |
|---|---|---|---|
| `career` | `mentor_greeted` | bool | `false` ao zerar a carreira; `true` depois dos toques do 1º clique (ou da reação da cena). Evita repetir os toques do 1º clique ao recarregar |
| `school` | `handover` | `null` ou `{stage, campaign, scene, draft}` | §1. `stage` ∈ `creating`, `arriving`; `scene` ∈ `primeira_sucessao`, `chegada_discipulo`; `draft = {name, look}` |
| `school` | `mentors` | Array[String] | quem está sentado na garagem. 6b1: `["first"]` depois do grant. 6c tira o `first` (`mentor_leaves`) |
| `school` | `roster` | Array (§3.4) | lista de quem passou o posto, fora do reset |

`school` continua fora do reset: NOVA CAMPANHA/RECEBER, derrota, aposentadoria e `_zerar_carreira()` não tocam nele (exceto `handover`, que é escrito pelo próprio fluxo). Só "Apagar save" zera.

### 3.4 Lista da escola: `school.roster`
Uma entrada por campanha encerrada desde o John, em ordem. Gravada em `_encerrar_carreira()`, **no mesmo `salvar()`** do Legado.
```json
{ "campaign": 2, "kind": "disciple", "name": "Tati Gancho", "look": { ... },
  "end": "defeat", "wins": 4, "belt": true, "art": "boxing", "opponent": "muralha", "legacy_gained": 38 }
```
| Campo | Regra |
|---|---|
| `campaign` | `career_number` da campanha encerrada |
| `kind` | `"first"` (John) ou `"disciple"` |
| `name`, `look` | do `career.disciple`; John: `cast.first.name` e `look: null` (ele usa as folhas dele) |
| `end` | `"defeat"`, `"retire"` ou `"unknown"` (só migração) |
| `wins` | `indice_escada` no fim (o recorde dele); `-1` = desconhecido (só migração) |
| `belt`, `art`, `opponent`, `legacy_gained` | do `fim`; `opponent` = quem venceu (vazio na aposentadoria) |

- "Passou o posto" = **toda** entrada da lista (derrota ou saída), `room_mentors.defeat_counts_as_passed = true` (escopo §3 item 6). A 6b2 lê "o último que passou o posto" como a última entrada `kind == "disciple"`; a 6c usa a lista para o mural. Na 6b1 nada lê a lista além dos testes.
- Campanhas anteriores ao John (saves de antes da 6a) não entram.
- Sem teto de tamanho: cada entrada tem ~300 bytes; 1.000 campanhas = 0,3 MB.

### 3.5 Migração v11 → v12 (`SaveStore._migrar_11_para_12`)
Sejam `N = permanent.career_number`, `F = school.first_fighter_campaign`, `P = ending pendente (defeat/retire)`, `U = N se P, senão N − 1` (última campanha encerrada).

1. `career.mentor_greeted = true` (não dispara toques no meio de uma campanha antiga).
2. `school.handover = null`, `school.mentors = []` (John só senta depois da cena).
3. `career.disciple`:
   - `N > F` → `{name: nome_padrao ("Novato"), look: default_look, campaign: N}` (caso do discípulo padrão em andamento ou com fim pendente);
   - `N <= F` → `null`.
4. `school.roster`: uma entrada para cada campanha `c` de `F` até `U` (nenhuma se `U < F`):
   - `c == F` → `kind "first"`, nome do John, `look null`;
   - `c > F` → `kind "disciple"`, `name "Novato"`, `default_look`;
   - `end` = `last_end.kind` se `last_end.campaign == c`, senão `"unknown"`;
   - se `P` e `c == N`: `wins`, `belt`, `art`, `opponent`, `legacy_gained` vêm do `ending`; senão `wins = -1`, `belt = false`, `art = ""`, `opponent = ""`, `legacy_gained = 0`.
5. **Não mexe em mais nada:** Legado, árvore, atributos, treino, geradores, caixas, luva, calendário, `career_number`, `first_fighter_campaign`, marcos e `lines_seen` da 6a.

Save v12 com campo ausente ou inválido: mesmo padrão da migração, com aviso. `VERSAO_ATUAL = 12`.

### 3.6 Casos do save do dono
| Save | Depois da migração | O que ele vê |
|---|---|---|
| v10 (o save atual do dono está em **v10, Carreira 3 em andamento**) | v10→v11 faz da Carreira 3 a do John (`F = 3`); v11→v12: `disciple = null`, `roster = []` | joga o John até o fim; no RECEBER toca a cena grande e cria o discípulo da Carreira 4 |
| v11 com John em andamento (`N == F`, sem fim) | igual acima | igual acima |
| v11 com discípulo padrão em andamento (`N > F`) | `disciple = Novato` padrão; `roster` com John (e Novatos anteriores, se houver) | joga o "NOVATO" normalmente (HUD com o nome); no RECEBER toca a cena grande. Sem tela retroativa |
| v11 com fim pendente do John (`N == F`, `P`) | `roster = [John com os números do ending]` | RECEBER → cena grande |
| v11 com fim pendente antes do John (`N < F`, `P`, vindo de v10) | nada no roster | RECEBER começa a campanha do John como hoje (§1.1, "começo do John") |

---

## 4. John mentor: os toques
John fica sentado no `mentor_spot` (268,268), pose `sit_rest`, quando: `"first" in school.mentors` **e** `lutador_atual() == "disciple"` **e** `local_id == "garage"`. Não fala fora da cena (falas de mentor são 6c). Não reage a clique.

Os **toques** (`mentor_first_taps`, dois toques de punho sem luva, som `tap_fist`, `tap_interval` 0,22 s) acontecem em dois momentos:

| Momento | Quando começa | Proteção contra clique |
|---|---|---|
| **1º clique da campanha** | no `clicar()` que acha `career.mentor_greeted == false`; grava `mentor_greeted = true` na hora (vai no autosave) | os cliques nos primeiros `first_click_guard_seconds` (0,5 s) **não cancelam**: o próprio clique que chamou a reação e o seguinte do jogador rápido deixariam os toques sem nunca aparecer. Depois de 0,5 s (os dois toques já soaram em 0 e 0,22 s), qualquer clique cancela o resto da pose |
| **Volta à garagem depois de vitória** | `win_return_delay_seconds` (1,0 s) de sala ativa na garagem depois de fechar a janela de vitória (`luta_resolvida` com `win`, sem `retire`) | qualquer clique cancela, inclusive antes de começar (aí não toca) |

Regras comuns:
- **No máximo 1 por minuto:** `cooldown_seconds` = 60 s, de início a início, em tempo real (conta luta e janela). Bloqueado pelo intervalo → **descartado**, nunca guardado.
- A reação `first_click` da cena grande **é** o toque do 1º clique dessa campanha: conta no intervalo e grava `mentor_greeted`.
- Só com sala ativa. Abrir janela, lutar ou mudar de local cancela.
- Cancelar = parar a pose, cortar o som pendente (o 2º toque não toca) e voltar ao `sit_rest`.
- Como o gesto da 6a: o comentário que cairia durante os toques espera o fim ou o cancelamento ("o gesto antes da fala"). Toques não contam como comentário.
- **Só o John faz.** Discípulo nenhum faz os dois toques (nem `pedir_gesto`, nem toques de mentor): `pedir_gesto` continua devolvendo `{}` para o discípulo, e o validador de cena reprova `gesture`/`mentor_first_taps` em ator `current_player`.

Conta: numa campanha de ~13 min com 3–6 vitórias, o John toca no máximo 1 + 6 = 7 vezes, cada uma ≤ 0,7 s; com o intervalo de 60 s e as lutas no meio, o esperado é 4–6. Alavanca sem código: `on_win_return: false` (corte nº 2 do escopo §7) ou `cooldown_seconds` maior.

---

## 5. Garagem e textos

### 5.1 Quem aparece
| Campanha | Garagem |
|---|---|
| a do John | John lutando (como hoje), ninguém no caixote |
| a primeira depois do John (Carreira 2 do save novo) | discípulo lutando, John no caixote |
| as seguintes | **6b1:** igual (só o John). O 2º mentor é da 6b2 (`room_mentors.second_mentor_from_campaign = 3`, desligado na 6b1) |
| academia | nenhum mentor (6c) |

### 5.2 Nome no lugar de "Carreira N"
- HUD: só o nome (`hud_disciple`, `{nome}` em maiúsculas; John → "JOHN BULLET"). **Sem o número:** o número da campanha não decide nada para o jogador, e o nome cabe melhor. `hud_disciple_career` fica sem uso.
- Fim de campanha, cartão e escolha da arte: `sum_title_named`, `career_card_title_named`, `art_sub_career_named`.
- Botão do fim: `new_disciple_button` ("RECEBER NOVO DISCÍPULO", plano B `new_disciple_button_short`). No caso "começo do John" (§1.1) o botão diz o mesmo; é só save antigo e acontece uma vez.

### 5.3 Luva inicial
`descricao_luva_inicial()`: John → `glove_start_desc`; discípulo → `glove_start_desc_disc`. Nenhum número da luva muda.

---

## 6. Sorteios e paletas

### 6.1 Sorteio
- **Ao abrir a criação**, o rascunho já vem sorteado (escopo §3 item 4). O botão SORTEAR sorteia **tudo** de novo.
- **Nome:** sorteio uniforme em `nomes_discipulos.json` → `nomes`, sem os nomes das últimas `avoid_recent` (5) entradas do `roster` nem o nome do rascunho atual. Se sobrar nenhum, sorteia na lista inteira.
- **Campos visuais:** cada campo de `random.fields` sorteia uniforme entre as opções `enabled`. Na 6b1 só `skin`, `hair_color` e `shorts_color` variam (os outros têm uma opção ligada).
- `avoid_same_shorts_as_last = true`: o calção não repete o do último discípulo do `roster` (1 novo sorteio). Prepara a 6b2, quando os dois estarão lado a lado na garagem.
- Combinações "feias" não são filtradas na 6b1: são só 5 × 6 × 6 = 180 e o Diretor de Arte confere as paletas uma contra a outra (§6.3). O filtro de combinações é tarefa da 6b2.
- O sorteio não usa a semente da luta nem nada da economia.

### 6.2 Regras do nome
| Regra | Valor |
|---|---|
| Tamanho máximo | `name.max_chars` = **14** (igual ao maior nome do banco) |
| Caracteres | letras A–Z/a–z, `á à â ã é ê í ó ô õ ú ç` e as maiúsculas (todas desenhadas na fonte 5x7), espaço. Sem número, pontuação nem hífen. A UI recusa o resto já na digitação |
| Limpeza ao confirmar | tira espaços das pontas e junta espaços repetidos |
| Mínimo | `min_letters` = 1 letra. Vazio (ou só espaços) → o campo volta ao nome sorteado e o CONFIRMAR não passa |
| Repetido | permitido (é só um nome) |
| Guardado | como digitado; a interface mostra em maiúsculas |

### 6.3 Paletas (alvo para o Diretor de Arte)
Troca de paleta em tempo real (escopo §4.4). As cores-chave da folha do discípulo (pele 3 tons, cabelo 2 tons + sobrancelha, calção 3 tons + cós) são trocadas pelas da opção. Valores em `data/disciples.json` → `fields.<campo>.options[].colors`; quando a cor já existe na paleta de 45, o token vai em `tokens`.

**Pele (5)** — `[sombra, base, luz]`. Só o `skin_3` já existe (`sk0/sk1/sk2`); as outras quatro são as "rampas extras de pele" previstas em `direcao-visual.md` §3.
| Id | Alvo | Sombra | Base | Luz |
|---|---|---|---|---|
| `skin_1` | clara | `#a8684e` | `#e0a888` | `#f4d0b4` |
| `skin_2` | média clara | `#8f5238` | `#cc8c62` | `#eebd94` |
| `skin_3` | média (atual, padrão) | `#7a4632` sk0 | `#b9744f` sk1 | `#e3a275` sk2 |
| `skin_4` | morena | `#5c3224` | `#8e5536` | `#b97c52` |
| `skin_5` | escura | `#4a281d` | `#6b3e2c` | `#94603f` |

**Cabelo (6)** — `[escuro, claro, sobrancelha]`, todos da paleta atual.
| Id | Alvo | Tokens |
|---|---|---|
| `black` | preto | `d1`, `g0`, `ink` |
| `dark_brown` | castanho escuro | `br0`, `br1`, `ink` |
| `brown` | castanho (padrão, o do discípulo atual) | `br1`, `br2`, `br0` |
| `copper` | acobreado/ruivo | `br2`, `br3`, `br1` |
| `blond` | loiro | `y0`, `y1`, `br2` |
| `platinum` | descolorido | `g3`, `cream`, `g1` |

**Calção (6)** — `[escuro, médio, claro, cós]`, todos da paleta atual.
| Id | Alvo | Tokens |
|---|---|---|
| `green` | verde (padrão) | `gr0`, `gr1`, `gr2`, `gr3` |
| `blue` | azul | `b0`, `b1`, `b2`, `b3` |
| `black` | preto | `d1`, `d2`, `g0`, `g2` |
| `white` | branco | `g2`, `g3`, `cream`, `white` |
| `purple` | roxo | `p0`, `p1`, `p2`, `cream` |
| `yellow` | amarelo | `br2`, `y0`, `y1`, `y2` |

O que o Diretor de Arte confere (e pode trocar hex, mantendo ids e quantidade):
- cada pele separa do contorno `ink`, do `br0` da sobrancelha e do vermelho da luva (`r1/r2`); `skin_5` é a mais arriscada;
- cabelo `dark_brown`/`black` sobre `skin_5` ainda mostra o desenho do corte (o contorno ajuda);
- `copper` × `blond` e `brown` × `copper` se distinguem lado a lado na tela de criação;
- calção legível na garagem (luz quente), na academia e na luta, e diferente do calção dos adversários da luta; nenhum calção vermelho (fica com a luva e a Força), e o roxo não confunde com o Legado porque está no corpo;
- `blue` é o calção do John: deixei disponível (o discípulo pode "vestir as cores do mestre"); se a leitura da cena ficar confusa, troca-se por outra cor só no JSON.

---

## 7. Dados novos

| Arquivo | Dono | O quê |
|---|---|---|
| `data/disciples.json` (**novo, criado por mim**) | Designer | `name` (regras), `default_look`, `fields` (opções, `enabled`, `colors`, `tokens`), `random`, `handover` (ids de tela/cenas/marco, teto da chegada 2,5 s), `mentor_taps`, `room_mentors` |
| `data/nomes_discipulos.json` | Roteirista | `nomes` (42), `nome_padrao` ("Novato"), `max_caracteres` (14). Referenciado por `disciples.json → names_file` |
| `data/ui_texts.json` | Roteirista | chaves de `fase6b1-textos.md` (`disc_*`, `new_disciple_button*`, `glove_start_desc_disc`, `hud_disciple`, `*_named`, `skip_*`, `suc_*`) |
| `data/cutscenes/primeira_sucessao.json`, `chegada_discipulo.json` | Diretor de Cutscenes | cenas. `primeira_sucessao`: `milestone: "cena_primeira_sucessao"`, `grants: [mentor_in_room first_fighter]`, `open_screen: "customize_disciple"`, `max_seconds` 16. `chegada_discipulo`: `once: false`, sem marco, `max_seconds` 2.5 |

Gatilho das cenas: o `formato-dados.md` usa `campaign_started`; nesta fase o evento é **"RECEBER apertado"** (antes do cartão). Sugiro o nome `handover_started` com `requires.milestone_missing` para a grande e `milestone_present` para a chegada; o Programador e o Diretor de Cutscenes fecham o nome.

### 7.1 Decisões numéricas
| Decisão | Valor | Onde |
|---|---|---|
| Nome: máximo / mínimo | 14 caracteres / 1 letra | `disciples.json → name` |
| Nomes recentes evitados | 5 | `name.avoid_recent` |
| Opções 6b1 | pele 5, cabelo 6, calção 6 (180 combinações) | `fields` |
| Toques: intervalo mínimo | 60 s, tempo real | `mentor_taps.cooldown_seconds` |
| Toques: clique não cancela no começo do 1º clique | 0,5 s | `first_click_guard_seconds` |
| Toques depois de vitória | 1,0 s de sala ativa na garagem | `win_return_delay_seconds` |
| Intervalo entre os dois toques | 0,22 s (o mesmo do gesto) | `tap_interval` |
| Chegada curta | ≤ 2,5 s presos | `handover.short_scene_max_seconds` (o validador soma) |
| Cena grande | ≤ 16 s presos (9 + 6,2) | `max_seconds` da cena |
| Relógio durante a sucessão | parado (0 s somados) | regra §2 |

### 7.2 Contrato para o Programador (nomes sugeridos)
| Onde | Item |
|---|---|
| `SaveStore` | `VERSAO_ATUAL = 12`, `_migrar_11_para_12` (§3.5) |
| save `career` | `disciple`, `mentor_greeted` |
| save `school` | `handover`, `mentors`, `roster` |
| `GameState` (ações) | `receber_discipulo()` (substitui a chamada da UI a `nova_carreira()`), `sortear_rascunho()`, `definir_rascunho(campo, valor)`, `confirmar_discipulo() -> bool`, `sucessao_terminou()` (o player chama no `return_control`/`end_state`) |
| `GameState` (leitura) | `sucessao_estado()`, `rascunho()`, `limpar_nome(texto) -> String`, `discipulo_atual()`, `nome_lutador()`, `visual_lutador() -> look`, `cores_visual(look)`, `mentores_na_sala()`, `escola_lista()` |
| sinais | `sucessao_mudou(estado)`, `toques_mentor_pedidos(plano)`, `toques_mentor_cancelados()`; `nova_carreira_iniciada` passa a sair em `sucessao_terminou()` |
| testes | save de teste: fluxo completo; fechar em cada estado (§1.4); migração dos 5 casos da §3.6; nenhum segundo de `segundos_campanha` durante a sucessão; cooldown e guarda dos toques; discípulo nunca faz gesto; `roster` sobrevive a RECEBER e é zerado só por "Apagar save" |

---

## 8. Fora da 6b1 (não adiantar)
Cortes, parte de cima, faixa, meião, 2º mentor na sala e filtro de combinações (6b2). Mural, Honra, falas de mentor, saída do John, símbolo da escola (6c).

## 9. Balanço: nada muda
| Ponto | Por que não muda |
|---|---|
| Reset da campanha | é o mesmo `nova_carreira()`; só a emissão dos sinais de começo foi adiada |
| Relógio e produção | congelados durante a sucessão (§2); a campanha começa com 0 s no `return_control`, como hoje começa no clique do NOVA CAMPANHA |
| Toques e cenas | só visuais |
| Visual e nome | não são lidos por nenhuma conta |
| `data/` de balanço | nenhum arquivo muda (`training`, `generators`, `fights`, `opponents`, `shop`, `skill_tree`, `career`, `locations` intactos) |

Simulação: o `tools/sim/fase5_sim.py` não tem parâmetro que esta fase toque, então o resultado é idêntico ao da 6a por construção (23b 26,4% / 0,2%; cinturão mais cedo 20:44; 1ª derrota da campanha 1 13:39 / 14:09). **Não rodei nesta máquina** (sem Python instalado); o QA confirma com `fase5_sim.py b23c` e `f52` e com o teste de `segundos_campanha` parado.

---

## Resumo
- **Fluxo:** RECEBER zera a campanha (igual a hoje) mas segura cartão, arte e comentário. 1ª sucessão: marco no começo → parte 1 → criação → parte 2 → começo da campanha. Seguintes: criação → chegada curta (≤ 2,5 s). A carreira fica congelada durante tudo (relógio parado, 0 s somados).
- **Fechar no meio:** antes do CONFIRMAR volta na tela de criação (depois, chegada curta); depois do CONFIRMAR aplica o estado final e segue. A cena grande nunca repete.
- **Save v12:** `career.disciple {name, look, campaign}`, `career.mentor_greeted`, `school.handover`, `school.mentors`, `school.roster` (lista da escola fora do reset). `look` já tem os 9 campos (6b2 com padrão). Migração cria o "Novato" padrão para discípulo em andamento e preenche o roster desde o John.
- **John mentor:** toques no 1º clique da campanha e 1 s depois de voltar de vitória na garagem; máximo 1 por 60 s; clique cancela (com 0,5 s de proteção no toque do 1º clique).
- **Sorteio e paletas:** nome do banco do Roteirista (evita os 5 últimos), máx. 14 caracteres; pele 5, cabelo 6, calção 6 com cores-alvo em `data/disciples.json`.
