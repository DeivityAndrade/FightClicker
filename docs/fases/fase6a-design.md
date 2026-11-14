# Fase 6a — Prólogo e voz: design

Dono: Designer de Jogo. Data: 2026-11-13 (v2, alinhada com as escolhas do dono e com o Diretor de Cutscenes).
Base: `fase6a-escopo.md` (aprovado), `fase6a-textos.md` (Roteirista), `docs/cutscenes/abertura-6a.md` e `balao-e-voz.md` (Diretor de Cutscenes), `fase5.4-api.md`, `gesto-assinatura.md`, `formato-dados.md` §6.
Fase de **sistemas e regras**, não de balanço. Nenhum número de economia, luta ou calendário muda (§7).

**Escolhas do dono (2026-11-13):** 1º lutador **John Bullet**, treinador **Osmar Brandão**, escola **Raízes Fight Club**, humilhação **A ("a ficha em branco")**.

Quem manda em quê:
| Assunto | Documento que vale |
|---|---|
| Formato de `data/dialogos.json`, gatilhos, prioridades, intervalos, marcos, save | **este** |
| Texto das falas e dos objetos | `fase6a-textos.md` (convertido para o formato da §1) |
| Balão, voz, timbres, pausas de digitação, ESPAÇO | `balao-e-voz.md` (valores em `voices` e `typing`) |
| Linha do tempo da abertura | `abertura-6a.md` |

---

## 1. `data/dialogos.json`

### 1.1 Estrutura
```json
{
  "version": 1,
  "cast": {
    "first": { "name": "John Bullet", "short": "john", "color": "r2", "voice": "first" },
    "coach": { "name": "Osmar Brandão", "short": "osmar", "color": "y0", "voice": "coach" }
  },
  "school_name": "Raízes Fight Club",
  "voices": {
    "first": { "base_hz": 180, "cps": 28, "vowel_order": "uoaei", "vowel_steps": [0, 2, 4, 5, 7] },
    "coach": { "base_hz": 110, "cps": 22, "vowel_order": "uoaei", "vowel_steps": [0, 2, 4, 5, 7] }
  },
  "typing": {
    "pause_comma": 0.12, "pause_stop": 0.28, "pause_ellipsis_dot": 0.13,
    "hold_min": 1.2, "hold_per_char": 0.06, "click_guard": 0.15,
    "blip_every_letters": 2, "blip_pitch_jitter": 0.03, "blip_volume_db": -8,
    "space_completes_passive": false
  },
  "comments": {
    "gap_min_seconds": 60, "gap_filler_seconds": 120, "filler_max_priority": 4,
    "settle_seconds": 2.0, "defer_max_seconds": 15.0, "after_gesture": true,
    "idle_comment_seconds": 45
  },
  "gesture": {
    "fight_intro_start": 0.30, "victory_short_start": 0.15, "victory_pose_at": 0.60,
    "idle_first_seconds": 20, "idle_repeat_min": 30, "idle_repeat_max": 60, "idle_max_per_stop": 3,
    "tap_interval": 0.22
  },
  "triggers": { "<id>": { "priority": 3, "defer": false, "campaign_cap": 1 } },
  "opening": { "max_seconds": 20, "skip_hold_seconds": 0.5, "gap_between": 0.3,
               "lines": ["open_1", "open_2", "open_3", "open_4"] },
  "lines": [ { "...": "ver 1.2" } ],
  "objects": { "...": "textos de objeto da parede (fase6a-textos.md §5), chaves em inglês" }
}
```
- Chaves em inglês `snake_case`; textos em português (padrão de `data/`). Os valores de `voices` e `typing` são os de `balao-e-voz.md` (o timbre completo, as 5 frequências e as curvas ficam lá; o Programador copia).
- `vowel_steps` é lido na ordem de `vowel_order` (**u, o, a, e, i**: da mais grave à mais aguda).
- `typing.space_completes_passive = false` (decisão do Produtor): no modo passivo o ESPAÇO **só treina**. Completa a fala: clique fora do alvo e fora de botão.
- Placeholders no texto: `{first}`, `{coach}`, `{school}`. No **balão** viram o `short` (minúsculo: `john`, `osmar`); em **objeto/interface**, o `name`. O validador mede o texto já trocado.

### 1.2 Campos de cada fala (`lines[]`)
| Campo | Tipo | Obrig. | Regra |
|---|---|---|---|
| `id` | String | sim | único. Abertura `open_1..4`; comentários `cl_*` (ids do Roteirista mantidos) |
| `speaker` | `"first"` \| `"coach"` | sim | chave de `cast` (o `primeiro`/`treinador` do Roteirista vira `first`/`coach`) |
| `text` | String | sim | minúsculas; `\n` = quebra; até 2 linhas de 26 caracteres |
| `trigger` | String | sim | id da §1.4, ou `opening` |
| `repeat` | `"once"` \| `"rest"` | sim | `once` = uma vez na vida do save (`unica`); `rest` = repetível com descanso (`repetivel`) |
| `rest_campaigns` | int | não (1) | tocou na campanha N → volta só na N + 1 + `rest_campaigns` (padrão N+2) |
| `priority` | int 1–10 | não | padrão = prioridade do gatilho |
| `conditions` | Dictionary | não | todas valem (E lógico), §1.5 |
| `enabled` | bool | não (true) | `false` = desligada até a fase certa (`passar_posto` 6b, `arte` 6c) |
| `group` | String | não | só documentação (o Roteirista usa para agrupar variantes); o jogo ignora |

Conversão do bloco JSON de `fase6a-textos.md` §7: `frequency: unica → repeat: once`; `repetivel → rest`; `campaign: c2mais → conditions.after_line` ou `first_fighter_done` (ver §1.4); `campaign: qualquer` some; `order` só na abertura (vira a ordem de `opening.lines`). Os nomes `téo`/`cleto`/`lâmpada acesa` dos textos são trocados pelo Roteirista pelos escolhidos (ou por placeholder).

Validador do carregador (aviso, nunca trava): id repetido, `speaker`/`trigger` desconhecido, texto que não cabe, maiúscula acentuada em balão, condição desconhecida → **a fala é desligada** e o resto carrega.

### 1.3 Escolha da fala
Quando um gatilho chega:
1. **Sala calma?** (§1.6). Se não: descarta; se o gatilho é `defer`, guarda na vaga única.
2. **Candidatas:** falas `enabled` do gatilho com `conditions` verdadeiras e disponíveis: `once` nunca tocada; `rest` nunca tocada ou com `campanha_atual − lines_seen[id] > rest_campaigns`.
3. **Teto do gatilho:** se o gatilho já tocou `campaign_cap` falas `rest` nesta campanha, saem as `rest`. Falas `once` não contam nem são barradas.
4. **Intervalo:** melhor candidata com prioridade ≤ `filler_max_priority` (4) precisa de `gap_filler_seconds` (120 s) desde o último comentário; acima de 4, `gap_min_seconds` (60 s). Sem intervalo: descarta.
5. **Escolha:** maior `priority`; empate: nunca tocadas primeiro; depois, sorteio.
6. **Grava** `school.lines_seen[id] = campanha_atual` quando o balão começa. `once` salva na hora; `rest` vai no autosave.
7. Dois gatilhos no mesmo quadro (ex.: luva aberta = `glove_new` + `box_opened`): toca a melhor fala dos dois; o resto é **descartado**, nunca guardado.

O teto por campanha sai de `lines_seen` (conta falas do gatilho com valor = campanha atual). Sem campo novo.

### 1.4 Gatilhos (alinhados com `fase6a-textos.md` §4.1)
"Campanha atual" = `permanente.career_number`. Prioridades na escala 1–10 do Roteirista.

| `trigger` | Gatilho(s) do Roteirista | Sinal do `GameState` / origem | Quando toca | Prior. | `defer` | Teto `rest` | Condições extras das falas |
|---|---|---|---|---|---|---|---|
| `opening` | `abertura` | §5 | abertura | — | — | — | — |
| `garage_saved_return` | `garagem_salva` | marco `garage_saved` sem `garage_saved_seen`, ao desenhar a sala na garagem (§2.3) | 1ª volta à garagem | 10 | sim | — | — |
| `after_defeat` | `primeira_derrota`, `derrota`, `derrota_recall` | `fim_de_carreira(fim)` com `kind == "defeat"` grava `school.last_end`; toca no 1º momento calmo da campanha seguinte (`nova_carreira_iniciada` + cartão e arte fechados) | começo da campanha seguinte | 9 (única) / 5 | sim | 1 | — |
| `glove_new` | `luva_par` | `caixa_aberta(item, "glove")` | luva calçada | 8 | não | — (só única) | — |
| `fight_won` | `revanche`, `recorde` | `luta_resolvida(resumo)` com `resumo.win` | volta à sala | 7 / 6 | sim | 1 | `revenge`, `record` |
| `gym_arrival` | `primeira_academia`, `academia_volta` | `local_mudou("gym")` vindo do MUDAR (não da carga nem do NOVA CAMPANHA) | chegada à academia | 6 | sim | 1 | `after_line` |
| `fight_near` | `luta_marcada` | `aviso_data(dias)` com `dias == calendar.warn_days` (3) | faixa de aviso | 4 | não | 1 | — |
| `big_purchase` | `primeira_compra`, `compra` | `caixa_criada(item, tipo)` (aparelho ou luva comprados); `melhoria_comprada` no último nível; `metronomo_mudou` de 0 para 1; `crew_click_mudou(true)` vindo de false | compra marcante | 3 | não | 1 | `what`, `item` |
| `box_opened` | `primeira_caixa`, `caixa` | `caixa_aberta(item, tipo)` | 3º clique na caixa | 3 | não | 1 | `kind`, `item` |
| `idle` | `parado` | `_ocioso >= idle_comment_seconds` (45 s) com sala ativa (depois do 1º gesto curto, que vem aos 20 s) | treino parado | 1 | não | 1 | — |
| `retire` | (sem falas na 6a) | — | reservado | — | — | — | — |

Regras de dado pedidas pelo Roteirista:
- **`revenge`** = `resumo.revenge` (vitória sobre o algoz gravado em `permanente.revenge_opponent`, que vem da derrota da campanha **anterior**). "Quem te derrotou nesta campanha" não existe: a derrota encerra a campanha.
- **`record`** = vitória em que `indice_escada` (já somado) passou `permanente.best_wins` **e** `best_wins > 0` (havia marca). Com o teto 1, toca no máximo uma vez por campanha.
- **`after_line: "<id>"`** = aquela fala já tocou numa campanha anterior. `academia_volta` usa `after_line: "cl_primeira_academia"`.
- `metronomo_mudou` e `crew_click_mudou` também saem na carga e no NOVA CAMPANHA: só vale a **transição por compra** (a fila guarda o valor anterior).

**Ajuste pedido ao Roteirista (`derrota` c1):** o 1º lutador perde **uma vez só** (a derrota encerra a campanha dele), e essa vez é a `primeira_derrota`. As 3 variantes `derrota` marcadas `c1` nunca tocariam. Regra nova: `derrota` e `derrota_recall` ficam **as 6 no mesmo pool** do `after_defeat`, sem condição de campanha (descanso normal). Assim o banco de derrota fica com 6 variantes, o que ajuda quem faz muitas campanhas curtas (risco do escopo §6).

### 1.5 Condições (`conditions`)
| Chave | Valor | Verdadeira quando |
|---|---|---|
| `fighter` | `"first"` / `"disciple"` | `lutador_atual()` (§3) |
| `first_fighter_done` | bool | `career_number > school.first_fighter_campaign` |
| `location` | `"garage"` / `"gym"` | `local_id` |
| `milestone_present` / `milestone_missing` | Array | marcos §2.2 |
| `after_line` | id | `lines_seen[id]` existe e é < campanha atual |
| `revenge`, `record` | bool | §1.4 |
| `opponent` | id | adversário da luta (ou o próximo, em `fight_near`) |
| `item`, `kind`, `what` | id | parâmetros do sinal (`what`: `apparatus`, `glove`, `upgrade_max`, `metronome`, `crew_click`) |
| `campaign_min` | int | `career_number >= n` |

### 1.6 Sala calma e espaçamento
**Sala calma** = todas:
- `GameState.sala_ativa()` (já exclui luta, janela/`modal_aberto`, escolha da arte, tela de fim e dia da luta parado);
- abertura em `over`;
- nenhum balão na tela;
- `settle_seconds` (2 s) desde que a sala voltou a ficar ativa.

| Regra | Valor |
|---|---|
| Intervalo mínimo entre comentários (início a início), tempo real (`tempo_jogo`, conta luta e janela) | **60 s** |
| Intervalo dos "enchimentos" (prioridade ≤ 4: luta marcada, compra, caixa, parado) | **120 s** |
| Fim da abertura | conta como comentário (zera o intervalo) |
| Gatilho `defer` sem sala calma | **1 vaga** (a de maior prioridade substitui a menor); toca no 1º momento calmo; some após 15 s de sala ativa sem conseguir; não vai para o save |
| Gesto tocando | o balão espera o gesto acabar ou ser cancelado ("o gesto antes da fala") |
| Abrir janela com balão na tela | o balão fecha na hora (nunca fica balão por baixo de janela) |
| Balão | **passivo**: não marca `modal_aberto`, não mexe em `sala_ativa`, não consome clique nem ESPAÇO |

O intervalo conta em tempo real porque o aceite 7 é percepção ("nunca dois em menos de 60 s") e porque a fala da vitória precisa poder vir logo depois da luta.

### 1.7 Conta da frequência
**Carreira 1 (John, ~13 min):**
| Gatilho | Disparos | Comentários prováveis |
|---|---|---|
| `big_purchase` (`primeira_compra` única + 1 `compra`) | 5–8 caixas compradas, 1–3 melhorias no topo | 2 |
| `box_opened` (`primeira_caixa` única + 1 `caixa`) | 5–8 | 1–2 |
| `glove_new` (`luva_par`, única) | 1–3 | 1 |
| `fight_near` | 3 | 1 |
| `idle` | 0–2 | 0–1 |
| `fight_won` (sem algoz nem marca na Carreira 1) | 3 | 0 |
| **Total** | | **≈ 5–7** (meta 5–10; ~1 a cada 110–150 s) |

**Campanhas seguintes:** `after_defeat` 1, `big_purchase` 1, `box_opened` 1, `fight_near` 1, `idle` 0–1, `fight_won` (revanche/recorde) 0–2, `gym_arrival` 0–1 → **≈ 4–7**.

Alavancas sem código, se o QA medir fora de 5–10: `campaign_cap` de `big_purchase`/`box_opened` (1 → 2) e `filler_max_priority` (4 → 3 deixa compra/caixa no intervalo de 60 s).
Banco: com teto 1 e descanso de 1 campanha, 3 variantes nunca esgotam (a da campanha N volta na N+2).

---

## 2. Marcos da escola (fora do reset)

### 2.1 Bloco `school` no save
```json
"school": {
  "first_fighter_campaign": 1,
  "milestones": { "prologue_seen": { "campaign": 1, "version": 1 } },
  "lines_seen": { "cl_primeira_compra": 1, "cl_caixa_2": 3 },
  "last_end": { "kind": "defeat", "campaign": 1 }
}
```
| Campo | Tipo | Regra |
|---|---|---|
| `first_fighter_campaign` | int ≥ 1 | campanha do 1º lutador (§3) |
| `milestones` | `{id: {campaign, version, ...}}` | gravado **no momento** do evento, com `salvar()` imediato. Id desconhecido: mantido |
| `lines_seen` | `{line_id: campanha}` | última campanha em que a fala tocou. Id que sumiu do JSON: mantido, sem efeito |
| `last_end` | `{kind, campaign}` ou `null` | gravado quando a tela de fim é criada (`defeat` / `retire`); usado pelo `after_defeat` |

- Mora em `state.school`, ao lado de `permanent`. NOVA CAMPANHA, derrota, aposentadoria e `_zerar_carreira()` **não tocam** nele. Só "Apagar save" zera.
- Campo novo da carreira: `career.gestured_gloves: Array[int]` (níveis de luva que já tiveram o gesto de calçar; zera com a carreira).

### 2.2 Marcos
| Id | Gravado quando | Efeito |
|---|---|---|
| `prologue_seen` | **t = 0** da abertura (antes do gesto e dos balões) | a abertura nunca mais toca |
| `first_school_win` | `concluir_luta()` com vitória, se ausente (mesmo `salvar()` do prêmio) | recorte de jornal na parede |
| `garage_saved` | `concluir_luta()` com vitória sobre adversário `belt: true` (o Muralha), se ausente. Grava também `opponent` e `by_first: bool` | selo "GARAGEM SALVA" na vitória (`resumo.garage_saved = true`) |
| `garage_saved_seen` | 1ª vez que a sala é desenhada com `local_id == "garage"` depois de `garage_saved` | parede muda; dispara `garage_saved_return` |

Objetos da parede (derivados dos marcos; nada a mais no save):
| Objeto | Visível se | Texto (tooltip) |
|---|---|---|
| Aviso de cobrança | `garage_saved_seen` ausente | `objects.debt_notice` |
| Foto antiga | sempre | `objects.old_photo` |
| Ficha amassada (humilhação A) | sempre: versão "antes" sem `garage_saved_seen`; versão "depois" (nome da escola escrito à mão) com ele | `objects.entry_form_before` / `entry_form_after` |
| Recorte de jornal | `first_school_win` | `objects.clipping` |
| Foto da equipe e símbolo | `garage_saved_seen` | `objects.team_photo` |

A ficha é o objeto-resposta da humilhação A: o cinturão do Muralha (quem riu) salva a garagem e escreve o nome na ficha no mesmo marco.

### 2.3 Regras da garagem salva
- Conta **qualquer** lutador da escola que vença o adversário `belt: true`.
- **Só cinturões ganhos depois da 6a:** o marco nasce só do evento ao vivo em `concluir_luta()`. A migração **nunca** lê `belts_won` nem o `cinturao` da campanha em andamento. Se a campanha atual do save antigo já tem o cinturão, a garagem só é salva num cinturão de campanha seguinte.
- O selo vem na hora (a UI lê `resumo.garage_saved`). A parede muda na próxima vez que a garagem aparece: ao fechar a tela de vitória (se o jogador fica na garagem) ou no começo da campanha seguinte (se ele mudou para a academia). Mesmo marco, uma vez só.
- "Desenhar a sala na garagem" = carga do jogo, volta da luta, NOVA CAMPANHA ou MUDAR para a garagem, sempre com sala calma.

---

## 3. 1º lutador e discípulo padrão

### 3.1 Quem está jogando
`lutador_atual()` (derivada, sem campo na carreira):
- `"first"` se `permanente.career_number == school.first_fighter_campaign`;
- `"disciple"` se maior.

| | John Bullet (`first`) | Discípulo padrão (até a 6b) |
|---|---|---|
| Visual | sprite atual + rostos `bite`/`smile` | paleta fixa `disciple_default` (cabelo e calção; plaquinha `b3` reservada) |
| Nome | `cast.first` | nenhum; não fala na 6a |
| Gesto | sim | **nunca** |
| Luva inicial | descrição "o par dele" (`objects.starter_glove_desc`) | descrição padrão |

A paleta fica nos dados de arte (manifest do Artista). Save novo: `first_fighter_campaign = 1`.

### 3.2 Gesto — regra "só ele faz"
Todo gancho de gesto checa `lutador_atual() == "first"`. Nenhum outro ator tem as folhas `*_gesture*` ligadas; o validador reprova uso por outro ator.

| Momento | Versão | Tempo | Limite |
|---|---|---|---|
| Abertura | completa (0,9 s) | 0,30–1,19 s (`abertura-6a.md`) | 1 vez |
| Entrada de toda luta | completa | 0,30–1,20 s dentro de `intro_seconds` = 1,5 s | toda luta da campanha dele |
| Vitória | curta (0,4 s) | 0,15–0,55 s do `outro_seconds` (1,5 s); a pose de braços erguidos entra em **0,60 s** | toda vitória |
| Calçar luva nova | completa | logo após `caixa_aberta(item, "glove")` | 1 vez por nível (`career.gestured_gloves`) |
| Sala parada | curta | 1ª aos 20 s sem clique; depois a cada 30–60 s (sorteado) | **no máximo 3 por parada** (zera no próximo clique); só com sala ativa e sem balão |

Qualquer clique (saco, botão, fora do alvo) cancela o gesto no mesmo quadro. O gesto é só visual: não tem tempo de jogo, não mexe em `sala_ativa` nem em `_ocioso`.

---

## 4. Save antigo (escopo, item 4)

### 4.1 Versão e migração
Save **v11**. Migração **v10 → v11** (uma função em `SaveStore.MIGRACOES`):
- cria `state.school`:
  - `first_fighter_campaign` = `permanent.career_number`; **se há tela de fim pendente** (`ending != null`), `career_number + 1` (o número só sobe no NOVA CAMPANHA, e é essa a campanha que ele vai jogar);
  - `milestones = {}`, `lines_seen = {}`, `last_end = null` (ou `{kind: ending.kind, campaign: career_number}` se pendente);
- cria `career.gestured_gloves = []`;
- **não mexe em mais nada:** Legado, árvore (`skill_nodes`, `active_nodes`, `tree_last_node`), atributos, treino, geradores, caixas, luva, `campaign_seconds`, `fight_day`, `career_number`, `belts_won`, `best_wins`, `revenge_opponent`.

Save v11 sem `school` ou com campo inválido: mesmo padrão da migração, com aviso.

### 4.2 O que o dono vê
1. Abre o jogo: sem `prologue_seen` → a abertura toca no 1º momento calmo (carregou no dia da luta ou com luta pendente: espera a sala voltar). Na academia ela toca igual (`abertura-6a.md` §1).
2. A campanha atual é do John: gesto nas lutas, nome, luva "o par dele".
3. Aviso e ficha na parede da garagem. Recorte na próxima vitória. Garagem salva no próximo cinturão amador (§2.3).
4. Da campanha seguinte em diante: discípulo padrão.

Aceite 9 (QA, em cópia): comparar `permanent`, `career` (menos `gestured_gloves`) e calendário antes e depois: idênticos.

---

## 5. Abertura

### 5.1 Estados
| Estado | Entra quando | Sai quando |
|---|---|---|
| `pending` | save sem `prologue_seen` | 1º momento de sala calma (sem as regras de balão e intervalo) |
| `playing` | grava `prologue_seen` + `salvar()` em t = 0 | última fala acabou, ESC segurado 0,5 s, ou 20 s |
| `over` | — | — (libera comentários e o gesto de sala parada) |

"Pulável" não é estado à parte: a abertura toda é pulável desde o quadro 0 e não tem trecho preso. Pular = mesmo estado final de terminar. Fechar o jogo no meio: `prologue_seen` já foi gravado (aceite 2).
Abrir janela durante `playing`: o balão da vez fecha e os seguintes esperam a sala calma; o teto de 20 s continua contando (passou, vai para `over`).

### 5.2 Tempo
Linha do tempo em `abertura-6a.md` §3 (gesto 0,30–1,19 s; balões de 1,5 s a ~13,8 s; `over` ≈ 14,1 s).
- Tempo de um balão de n letras: `n/cps + pausas + max(1,2; 0,06·n) + 0,3`.
- Orçamento: **≤ 140 letras somadas nos 4 balões**; o validador soma e reprova acima de 20 s. Proposta atual: 110 letras ≈ 14 s.
- Teto: chegou a 20 s com balão escrevendo, ele completa e some.
- **O saco vale em t = 0** (aceite 1 pede ≤ 3 s). Clique no saco: treina e cancela o gesto; os balões seguem. Clique fora do alvo e fora de botão: completa o balão (sem blip). **ESPAÇO: só treina.** Nada disso pula a abertura.

### 5.3 Calendário durante a abertura
**O relógio anda normalmente.** Motivos:
1. Desde a 5.3 há **uma condição só** (`sala_ativa`) para relógio, produção, clique e equipe. Parar só o relógio criaria a 1ª exceção; parar a sala bloquearia o clique (`clicar()` exige `sala_ativa`) e quebraria o aceite 1.
2. A abertura é a sala viva: o jogador treina durante ela.
3. Custo máximo: ~14 s (teto 20 s) = 0,5–0,7 dia dos 12 de preparo do Dudu, e só para quem não clicar. No save novo a produção é 0 nesses segundos. Nenhum segundo é somado (aceite 10); no pior caso o jogador chega um pouco mais fraco, o que não adianta o 23b.

---

## 6. Contrato de dados (resumo para o Programador)
| Onde | Campo | Tipo |
|---|---|---|
| `data/dialogos.json` | `cast`, `school_name`, `voices`, `typing`, `comments`, `gesture`, `triggers`, `opening`, `lines`, `objects` | §1.1–1.2 |
| save `state.school` | `first_fighter_campaign`, `milestones`, `lines_seen`, `last_end` | §2.1 |
| save `career` | `gestured_gloves` | Array[int] |
| `resumo` de `concluir_luta()` | `garage_saved`, `first_school_win`, `record` (bool) | novos (`revenge` já existe) |
| `GameState` (leitura) | `lutador_atual()`, `marco(id) -> bool`, `abertura_estado()`, `segundos_ocioso()` | derivados |
| sinais novos sugeridos | `marco_gravado(id)`, `comentario(line_id)` | para UI e testes |
| `SaveStore` | `VERSAO_ATUAL = 11`, migração v10→v11 | §4.1 |

Ids de `triggers`: `opening`, `garage_saved_return`, `after_defeat`, `glove_new`, `fight_won`, `gym_arrival`, `fight_near`, `big_purchase`, `box_opened`, `idle`.
Ids de `objects`: `debt_notice`, `old_photo`, `entry_form_before`, `entry_form_after`, `clipping`, `team_photo`, `garage_saved_seal`, `starter_glove_desc`.
Opção de teste "esconder balões" (aceite 3): é do Programador; marcos e `lines_seen` funcionam igual com os balões escondidos.

---

## 7. Balanço: nada muda em relação à 5.4
| Ponto | Por que não muda |
|---|---|
| Duração da luta | `screen_seconds = intro_seconds + t_end + outro_seconds`. Gesto completo (0,9 s) em 0,30–1,20 s da entrada de 1,5 s; curto (0,4 s) em 0,15–0,55 s da saída de 1,5 s, antes da pose em 0,60 s. `data/fights.json` não muda |
| Treino com comentário | balão passivo: não marca `modal_aberto`, não muda `sala_ativa`, não consome clique nem ESPAÇO. Produção, equipe, Metrônomo e relógio seguem |
| Gesto de sala parada | só visual; não zera nem soma `_ocioso` |
| Abertura | ≤ 20 s (≈ 14 s) com sala ativa e clique valendo; nenhum segundo somado (§5.3) |
| Economia, preços, calendário | nenhum arquivo de balanço de `data/` muda |

Regressão (`tools/sim/fase5_sim.py b23c` e `f52`, branch `fase-6a`, 2026-11-13): **idêntica à 5.4**.
| Medida | 5.4 | 6a |
|---|---|---|
| 23b (5/s; 4/s), 2.000 jogadores | 26,4% / 0,2% | 26,4% / 0,2% |
| Cinturão mais cedo; antes de 20:00 | 20:44; 0 | 20:44; 0 |
| 1ª derrota da campanha 1 (5/s; 4/s) | 13:39 / 14:09 | 13:39 / 14:09 |
| Cinturão amador: campanha (med) | 2 | 2 |

(O texto da 5.4 cita "14:39" para 4/s; a tabela dela e a da 5.3 dizem 14:09, que é o valor certo.) O simulador não ganhou alavanca nova, porque nada de tempo de jogo mudou.

---

## Resumo
- `data/dialogos.json`: elenco (John Bullet, Osmar Brandão, Raízes Fight Club), vozes e digitação de `balao-e-voz.md`, 10 gatilhos ligados a sinais que já existem, falas `once`/`rest` com descanso de 1 campanha, prioridade 1–10 e teto de 1 fala repetível por gatilho por campanha.
- Intervalos: 60 s entre comentários (120 s para os de prioridade ≤ 4), nada fora da sala calma, 1 vaga de espera para vitória/derrota/academia/garagem salva. Conta: 5–7 comentários na Carreira 1.
- `school` no save (v11): campanha do 1º lutador, marcos (`prologue_seen`, `first_school_win`, `garage_saved`, `garage_saved_seen`), falas vistas e o último fim. A garagem é salva pelo 1º cinturão amador ganho depois da 6a, por qualquer lutador; a parede muda na volta à garagem.
- Gesto só do John: luta 0,30–1,20 s, vitória 0,15–0,55 s, até 3 por parada. Abertura: saco em t = 0, ≈ 14 s, relógio andando. Balanço da 5.4 intacto.
