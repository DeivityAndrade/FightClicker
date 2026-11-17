# Fase 6c2 — Mais longe que eu: design

Dono: Designer de Jogo. Data: 2026-11-16.
Base: `PROMPT.md`, `docs/fases/fase6c2-escopo.md` (decisões do dono incluídas), `fase6c1-design.md`, `fase6c1-api.md`, `data/escola.json`, `data/ui_texts.json`, `data/dialogos.json`, `data/skill_tree.json`, `docs/estado-atual.md`.
Fase de **identidade e progressão intra-campanha**. Nenhum número de economia, luta, calendário ou Legado muda (§9).

Decisões do dono que este design segue:
- **Texto do mural:** explícito — "foi seguir o rumo dele".
- **Árvore do hall:** já ramificada por arte; ramos sem conteúdo futuro usam placeholder "em breve".
- **Símbolo da escola:** nasce pronto e fixo na 6c2; sem evolução visual.

---

## 1. Sistema de Honra (raciocínio alto)

### 1.1 O que é e o que não é
| | Honra | Legado |
|---|---|---|
| Escopo | intra-campanha | entre campanhas |
| Reset | zera no RECEBER / nova campanha | permanente |
| Fonte | feitos verificáveis (vitória, recorde, marco) | progresso acumulado + cinturão |
| Gasto | árvore do hall (nós diegéticos) | árvore de Legado (`skill_tree.json`) |
| Sensação | "a escola me respeita hoje" | "a linhagem carrega meu nome" |

Honra **não** compra bônus de luta/economia diretos. Ela compra *reconhecimento* que se traduz em modificadores leves de treino e de presença, sempre dentro da campanha atual. O Legado continua sendo a alavanca de prestígio; a Honra é a textura do dia a dia na academia.

### 1.2 Fontes de Honra
Cada fonte tem um gatilho verificável e um valor fixo. Valores pensados para uma campanha média de ~45 min até o cinturão amador e ~90 min até a aposentadoria:

| Fonte | Gatilho | Valor | Justificativa |
|---|---|---|---|
| Vitória em luta | `fight_won` | 3 | Recompensa o loop principal sem inflar. 3 vitórias = 1 nó barato. |
| Revanche vencida | `fight_won` + `revenge: true` | 5 | Momento narrativo forte; vale mais que vitória comum. |
| Recorde pessoal (força/agilidade/resistência) | `personal_record_*` | 2 | Marca crescimento silencioso; acontece ~8–12x por campanha. |
| Marco de narrativa | `milestone_reached` (lista abaixo) | 4 | Fecha arcos da escola; poucos por campanha. |
| Chegada à academia (1ª vez) | `cena_primeira_academia` | 5 | Rito de passagem; só uma vez por save. |
| Saída do John presenciada | `cena_saida_primeiro_mentor` | 6 | Clímax emocional da 6c2; só uma vez por save. |
| Cinturão amador conquistado | `belt_amateur` | 8 | Primeiro título; pico de Honra no meio da campanha. |

**Marcos que dão Honra:** `cena_primeira_academia`, `cena_saida_primeiro_mentor`, `disciple_gym_win`, `belt_amateur`, `move_to_gym`. Outros marcos futuros podem entrar na mesma lista sem mudar a fórmula.

**Total esperado por campanha (estimativa):**
- Campanha 1 (John, garagem → academia): ~35–40 Honra.
- Campanha 2–3 (discípulo, academia cheia): ~50–60 Honra.
- Campanhas tardias (com mais recordes e revanches): ~70–80 Honra.

Isso permite comprar 4–6 nós baratos ou 1–2 caros por campanha, mantendo escolhas significativas.

### 1.3 Fórmula de ganho
```
honra_ganha = soma(fonte.valor para cada gatilho disparado na campanha)
```
Sem multiplicadores, sem decadência, sem teto. A linearidade intencional evita que a Honra vire moeda inflacionária; ela cresce junto com a narrativa, não com a exponencial dos números de luta.

### 1.4 Custos da árvore do hall
Custos escalonados para criar escolhas reais:

| Tier | Custo | Quantidade de nós | Exemplo de efeito |
|---|---|---|---|
| T1 | 8 | 4 | Reconhecimento básico (presença, texto) |
| T2 | 18 | 4 | Respeito do bairro (modificador leve de treino) |
| T3 | 35 | 3 | Voz na escola (fala de mentor nova, símbolo) |
| T4 | 60 | 2 | Nome na parede (mural atualiza, bônus de retrato) |

**Justificativa dos custos:**
- T1 (8): acessível com ~3 vitórias. Abre a árvore cedo, dá sensação de progresso imediato.
- T2 (18): exige ~6 vitórias ou combinação vitória+recorde. Meio da campanha.
- T3 (35): exige planejamento; só alcançável no terço final ou em campanhas longas.
- T4 (60): pico da campanha; só os jogadores ativos e eficientes chegam aqui antes de aposentar.

Crescimento entre tiers: ~2.2x. Maior que o 1.15x dos geradores porque a Honra é finita e narrativa, não econômica. Cada tier deve parecer um salto, não um incremento.

### 1.5 Bônus da árvore (intra-campanha, não persistem)
Nenhum bônus altera fórmulas de luta, custo de geradores, prêmio de dinheiro ou Legado. Todos são *modificadores de treino* ou *conteúdo diegético*:

| Tipo | Limite | Exemplo |
|---|---|---|
| Treino por clique | +5% por nó, máx +15% total | "Seu soco ecoa no salão" |
| Treino passivo (equipe) | +5% por nó, máx +10% total | "A turma treina quando você chega" |
| Conteúdo diegético | sem limite numérico | Fala nova de mentor, texto de mural, símbolo |
| Bônus de retrato | desbloqueia variação | Texto novo no hover da foto |

**Por que esses limites?**
- +15% clique e +10% passivo somados ao máximo da árvore de Legado (~+50% clique, ~+30% passivo) não quebram a curva da fase 5. São tempero, não prato principal.
- Conteúdo diegético é o verdadeiro prêmio da Honra. O jogador compra *história*, não número.
- Nenhum bônus afeta adversários, cintos, dias de preparo ou Legado. O balanço da luta e da economia permanece intacto.

### 1.6 Distinção clara vs. Legado (para o jogador)
- **Honra:** ganha e gasta *dentro* da campanha. Zera ao passar o posto. Compra respeito na academia.
- **Legado:** ganha ao passar o posto. Permanece. Compra lições do velho (`skill_tree.json`).
- As duas árvores ficam em abas separadas. A aba da Honra tem o título "HALL DA ESCOLA" e mostra o saldo atual + reset no fim da campanha.

---

## 2. Árvore do hall

### 2.1 Estrutura
Arquivo novo: `data/skill_tree_hall.json`. Formato espelha `skill_tree.json` para reutilizar o renderer, mas com campos próprios:

```json
{
  "version": 1,
  "currency": "honor",
  "reset_on": "campaign_end",
  "branches": [
    {"id": "hall_roots", "name": "RAÍZES"},
    {"id": "hall_boxing", "name": "BOXE", "requires_art": "boxing"},
    {"id": "hall_bjj", "name": "JIU-JITSU", "requires_art": "bjj"},
    {"id": "hall_future", "name": "EM BREVE", "placeholder": true}
  ],
  "nodes": [...]
}
```

### 2.2 Nós (JSON-ready)

| id | branch | tier | cost | requires | name | description | effect | effect_text |
|---|---|---|---|---|---|---|---|---|
| `hall_echo` | hall_roots | T1 | 8 | "" | Eco do salão | Seu soco volta antes de terminar. | `{type: "click_bonus", value: 0.05}` | "+{pct}% TREINO POR CLIQUE" |
| `hall_floor_creak` | hall_roots | T1 | 8 | "" | Piso conhecido | O chão range no seu passo. A turma sabe. | `{type: "passive_bonus", value: 0.05}` | "+{pct}% TREINO/S DA EQUIPE" |
| `hall_name_wall` | hall_roots | T1 | 8 | "" | Nome na parede | Alguém escreveu seu nome a lápis. | `{type: "portrait_variant", value: "name_wall"}` | "HOVER DA FOTO: VARIAÇÃO 'NOME'" |
| `hall_mentor_nod` | hall_roots | T1 | 8 | "" | Aceno do mentor | Ele te vê. Não precisa falar. | `{type: "mentor_line_unlock", value: "hall_nod"}` | "MENTOR: ACENO SILENCIOSO" |
| `hall_respect_street` | hall_roots | T2 | 18 | "hall_echo" | Respeito do bairro | Seus socos ecoam fora da academia. | `{type: "click_bonus", value: 0.05}` | "+{pct}% TREINO POR CLIQUE" |
| `hall_crew_rhythm` | hall_roots | T2 | 18 | "hall_floor_creak" | Ritmo da turma | A equipe treina no seu tempo. | `{type: "passive_bonus", value: 0.05}` | "+{pct}% TREINO/S DA EQUIPE" |
| `hall_photo_story` | hall_roots | T2 | 18 | "hall_name_wall" | História na foto | A foto antiga conta sua passagem. | `{type: "portrait_variant", value: "story"}` | "HOVER DA FOTO: VARIAÇÃO 'HISTÓRIA'" |
| `hall_mentor_praise` | hall_roots | T2 | 18 | "hall_mentor_nod" | Elogio raro | O mentor falou bem. Uma vez só. | `{type: "mentor_line_unlock", value: "hall_praise"}` | "MENTOR: ELOGIO RARO" |
| `hall_voice_school` | hall_roots | T3 | 35 | "hall_respect_street" | Voz na escola | Sua opinião pesa nas decisões. | `{type: "click_bonus", value: 0.05}` | "+{pct}% TREINO POR CLIQUE" |
| `hall_symbol_chest` | hall_roots | T3 | 35 | "hall_crew_rhythm" | Símbolo no peito | A escola veste você. | `{type: "symbol_unlock", value: "school"}` | "SÍMBOLO DA ESCOLA NO PEITO" |
| `hall_mural_update` | hall_roots | T4 | 60 | "hall_voice_school" | Mural atualizado | Seu nome fica ao lado do John. | `{type: "mural_upgrade", value: "disciple"}` | "MURAL: SEU NOME AO LADO DO JOHN" |
| `hall_legacy_whisper` | hall_roots | T4 | 60 | "hall_symbol_chest" | Sussurro do legado | A próxima campanha já te conhece. | `{type: "portrait_variant", value: "legacy"}` | "HOVER DA FOTO: VARIAÇÃO 'LEGADO'" |
| `hall_box_glove_echo` | hall_boxing | T2 | 18 | "hall_echo" | Luva que responde | A pera devolve o ritmo certo. | `{type: "art_click_bonus", art: "boxing", value: 0.05}` | "BOXE: +{pct}% CLIQUE NA ACADEMIA" |
| `hall_box_corner_respect` | hall_boxing | T3 | 35 | "hall_box_glove_echo" | Canto te reconhece | O ringue sabe seu nome. | `{type: "mentor_line_unlock", value: "hall_box_corner"}` | "MENTOR: CANTO DO RINGUE" |
| `hall_box_em_soon_1` | hall_boxing | T4 | 60 | "hall_box_corner_respect" | Em breve | Técnicas de campainha e corda. | `{type: "placeholder", text: "EM BREVE: TÉCNICAS DE CAMPAINHA"}` | "EM BREVE" |
| `hall_bjj_mat_memory` | hall_bjj | T2 | 18 | "hall_floor_creak" | Memória do tatame | O chão lembra seu peso. | `{type: "art_passive_bonus", art: "bjj", value: 0.05}` | "JIU-JITSU: +{pct}% EQUIPE NA ACADEMIA" |
| `hall_bjj_guard_whisper` | hall_bjj | T3 | 35 | "hall_bjj_mat_memory" | Guarda sussurrada | A defesa vem antes do golpe. | `{type: "mentor_line_unlock", value: "hall_bjj_guard"}` | "MENTOR: GUARDA SUSSURRADA" |
| `hall_bjj_em_soon_1` | hall_bjj | T4 | 60 | "hall_bjj_guard_whisper" | Em breve | Passagens e raspagens da escola. | `{type: "placeholder", text: "EM BREVE: PASSAGENS DA ESCOLA"}` | "EM BREVE" |
| `hall_future_muay_thai` | hall_future | T1 | 8 | "" | Muay Thai | Em breve. | `{type: "placeholder", text: "EM BREVE: MUAY THAI"}` | "EM BREVE" |
| `hall_future_judo` | hall_future | T1 | 8 | "" | Judô | Em breve. | `{type: "placeholder", text: "EM BREVE: JUDÔ"}` | "EM BREVE" |

**Notas de design:**
- Ramos `hall_boxing` e `hall_bjj` só aparecem se a arte estiver desbloqueada (campo `requires_art`). Na campanha atual, só a arte escolhida mostra nós compráveis; a outra aparece como placeholder.
- `hall_future` é sempre visível, sempre placeholder. Prepara a UI para artes futuras sem prometer mecânica.
- Nós `placeholder` têm `cost: 8` (T1) para manter a estrutura visual, mas `effect.type: "placeholder"` não aplica bônus. O texto diz "EM BREVE".
- Efeitos `art_click_bonus` e `art_passive_bonus` só valem na academia e só com a arte correspondente ativa. Fora da academia ou com outra arte, o bônus é 0. Isso mantém a distinção entre Honra (local, contextual) e Legado (global).

### 2.3 Pré-requisitos e fluxo
```
hall_echo ──→ hall_respect_street ──→ hall_voice_school ──→ hall_mural_update
hall_floor_creak ──→ hall_crew_rhythm ──→ hall_symbol_chest ──→ hall_legacy_whisper
hall_name_wall ──→ hall_photo_story
hall_mentor_nod ──→ hall_mentor_praise

hall_echo ──→ hall_box_glove_echo ──→ hall_box_corner_respect ──→ hall_box_em_soon_1
hall_floor_creak ──→ hall_bjj_mat_memory ──→ hall_bjj_guard_whisper ──→ hall_bjj_em_soon_1
```

Dois caminhos principais (clique e passivo) + dois laterais (retrato e mentor). O jogador escolhe identidade: "sou quem bate" ou "sou quem faz a turma crescer". Os dois se encontram nos tiers altos.

---

## 3. Mural

### 3.1 Estados
| Estado | Condição | Visual | Texto do mural |
|---|---|---|---|
| `empty` | Sem marco `cena_primeira_academia` | Parede vazia, pregos visíveis | (sem hover) |
| `john_only` | Marco `cena_primeira_academia` presente, `cena_saida_primeiro_mentor` ausente | Foto do John + placa "JOHN BULLET" | "foi seguir o rumo dele" |
| `john_left` | Ambos os marcos presentes, sem entrada de discípulo no roster | Foto do John + placa + espaço vazio ao lado | "foi seguir o rumo dele\no próximo ainda não chegou" |
| `with_disciple` | Ambos os marcos + entrada de discípulo no roster | Foto do John + placa + placa do último mentor | "foi seguir o rumo dele\n{nome_do_último} seguiu o nosso" |
| `symbol_unlocked` | Nó `hall_symbol_chest` comprado | Adiciona símbolo da escola abaixo das placas | (símbolo visual, sem texto extra) |
| `mural_upgraded` | Nó `hall_mural_update` comprado | Placa do discípulo ao lado da do John, mesma altura | "{nome_do_discípulo}\nao lado de John Bullet" |

**Transições:** automáticas, baseadas apenas em marcos e nós da árvore. Sem ação do jogador além de comprar o nó.

### 3.2 Gatilhos de atualização
| Evento | Ação no mural |
|---|---|
| Cena da academia termina | Transiciona de `empty` → `john_only` |
| Saída do John termina | Transiciona para `john_left` ou `with_disciple` (depende do roster) |
| Compra de `hall_symbol_chest` | Adiciona camada do símbolo |
| Compra de `hall_mural_update` | Atualiza placa do discípulo |
| Nova campanha (RECEBER) | Mantém estado (mural é da escola, não da campanha) |

### 3.3 Integração com `ui_audit` (OBS-C da revisão 6c1)
Estados auditáveis novos:
| Estado `ui_audit` | Descrição |
|---|---|
| `mural_empty` | Parede vazia, sem hover |
| `mural_john` | Com John, hover ativo |
| `mural_disciple` | Com discípulo, hover ativo |
| `mural_symbol` | Símbolo visível |
| `photo_tilted` | Foto torta na academia (já existe na 6c1, agora coberta pelo audit) |
| `photo_straight` | Foto reta na garagem |
| `hover_old_photo_gym` | Hover na academia exibe `objects.old_photo_gym` |
| `hover_old_photo_garage` | Hover na garagem exibe `objects.old_photo` |

Todos devem passar com 0 problemas no `tools/ui/ui_audit.gd`.

### 3.4 Texto "foi seguir o rumo dele"
Fixo, conforme decisão do dono. Aparece em todos os estados exceto `empty`. Não varia por campanha nem por testador. A pergunta sobre a saída discreta foi respondida pela escolha explícita.

---

## 4. Bônus de retrato

Hover na foto antiga exibe texto contextual. Variações desbloqueadas por nós da árvore do hall ou por marcos.

| Variação | Desbloqueio | Texto (chave em `ui_texts.json`) |
|---|---|---|
| `default_garage` | Sempre (garagem) | `objects.old_photo` → "Osmar, bem antes das histórias." |
| `default_gym` | Marco `cena_primeira_academia` | `objects.old_photo_gym` → "A foto veio da garagem.\nEra torta. Aqui ficou reta." |
| `name_wall` | Nó `hall_name_wall` | `objects.old_photo_name` → "Alguém escreveu seu nome atrás.\nA tinta ainda tá fresca." |
| `story` | Nó `hall_photo_story` | `objects.old_photo_story` → "Essa foto já viu três campeões.\nVocê é o quarto." |
| `legacy` | Nó `hall_legacy_whisper` | `objects.old_photo_legacy` → "A próxima campanha já te conhece.\nA foto lembra." |
| `john_left` | Marco `cena_saida_primeiro_mentor` | `objects.old_photo_john` → "O John saiu. A foto ficou.\nEle pediu pra cuidar." |

**Prioridade:** se múltiplas variações estão desbloqueadas, usa a mais específica (ordem da tabela, de baixo para cima). `john_left` tem prioridade sobre `default_gym` mas não sobre `legacy` (que é pós-campanha).

---

## 5. Falas de mentor (recorde e revanche)

### 5.1 Gatilhos exatos
| Gatilho | Condição | Intervalo mínimo | Mentor fala? |
|---|---|---|---|
| `personal_record_strength` | Atributo força supera máximo anterior da campanha | 120 s | Sim, se desenhado |
| `personal_record_agility` | Idem agilidade | 120 s | Sim, se desenhado |
| `personal_record_endurance` | Idem resistência | 120 s | Sim, se desenhado |
| `revenge_win_vs_X` | Vitória contra adversário que já venceu o jogador nesta campanha | 60 s | Sim, se desenhado |

**Condições comuns:**
- Mentor deve estar desenhado no local atual (`mentor_presente()` estendido para mentores, não só coach).
- Sala calma (`sala_ativa()`, 2 s de calma, sem balão/gesto/toques).
- Respeita intervalo global de comentários (`gap_min_seconds: 60`).
- Prioridade 6 (mesma de `cl_recorde_*` e `cl_revanche_*` existentes).
- `defer: true`, `campaign_cap: 3` (máximo 3 falas de recorde/revanche por campanha, compartilhado entre mentores).

### 5.2 Tabela de falas (pedir ao Roteirista)
As falas abaixo são **placeholders de design**. O Roteirista deve escrever versões finais no tom da escola, respeitando o limite de caracteres do balão (~40 chars/linha, 2 linhas).

| id | speaker | trigger | group | conditions | text (placeholder) |
|---|---|---|---|---|---|
| `mentor_rec_str_1` | mentor:last | personal_record_strength | mentor_rec | `{location: "gym"}` | "mais forte que ontem." |
| `mentor_rec_str_2` | mentor:last | personal_record_strength | mentor_rec | `{location: "gym"}` | "o saco sentiu." |
| `mentor_rec_agi_1` | mentor:last | personal_record_agility | mentor_rec | `{location: "gym"}` | "mais rápido. vi." |
| `mentor_rec_agi_2` | mentor:last | personal_record_agility | mentor_rec | `{location: "gym"}` | "não consegui acompanhar." |
| `mentor_rec_end_1` | mentor:last | personal_record_endurance | mentor_rec | `{location: "gym"}` | "aguenta mais. bom." |
| `mentor_rec_end_2` | mentor:last | personal_record_endurance | mentor_rec | `{location: "gym"}` | "fôlego de quem fica." |
| `mentor_rev_1` | mentor:last | revenge_win | mentor_rev | `{location: "gym"}` | "conta quitada." |
| `mentor_rev_2` | mentor:last | revenge_win | mentor_rev | `{location: "gym"}` | "ele não esperava." |
| `mentor_rev_3` | mentor:last | revenge_win | mentor_rev | `{location: "gym"}` | "agora ele lembra." |

**Nota:** estas falas são do **mentor sentado/em pé** (`mentor:last`), não do Osmar. O Osmar já tem `cl_recorde_*` e `cl_revanche_*` próprias. As novas falas só tocam se o mentor estiver desenhado; se não estiver, o Osmar pode tocar as dele normalmente.

### 5.3 Conflito com falas do Osmar
Se ambos (mentor e Osmar) têm fala candidata no mesmo momento calmo:
1. Prioridade decide (ambas são 6, então empata).
2. Empate: mentor tem precedência sobre coach neste gatilho específico (recorde/revanche), porque a fala do mentor é mais rara (`campaign_cap: 3` vs. `rest` do Osmar).
3. A fala perdedora vai para a vaga e pode tocar no próximo momento calmo, respeitando intervalos.

---

## 6. Símbolo da escola

### 6.1 Especificação visual (para o Diretor de Arte)
| Campo | Valor |
|---|---|
| Forma | Raiz estilizada: três linhas curvas convergindo para um ponto central, formando um triângulo invertido aberto. Minimalista, reconhecível em 16x16 px. |
| Paleta | Cor primária: `r2` (vermelho escuro da paleta do John). Cor secundária: `y0` (amarelo do Osmar). Fundo: transparente. |
| Tamanho no sprite | 12x12 px no peito esquerdo do lutador (escala 1:1 com o sprite de 64x64). |
| Posição | Fixa: `(x+18, y+22)` relativo ao centro do sprite do lutador. Não muda por pose, arte ou campanha. |
| Visibilidade | Apenas na academia (`local_id == "gym"`). Na garagem, em lutas, em cutscenes externas: invisível. |
| Evolução | Nenhuma. Nasce pronto na 6c2, fixo para sempre. Identidade definida de uma vez. |
| Camada | Sobre a roupa, sob a luva. Z-index entre `body` e `glove`. |

### 6.2 Desbloqueio
Nó `hall_symbol_chest` (T3, custo 35). Uma vez comprado, o símbolo aparece em todas as campanhas futuras daquela escola (não reseta com a campanha, diferente dos bônus de treino da Honra). **Exceção à regra de reset:** o símbolo é identidade, não bônus. Persiste como o mural.

### 6.3 Efeito mecânico
Nenhum. Puramente visual e diegético. Marca pertencimento.

---

## 7. Save

### 7.1 Onde cabem os dados novos
| Item | Local no save | Cabe na v12? |
|---|---|---|
| Saldo de Honra | `school.honor_balance` (campo novo) | Não: adiciona campo. Migração automática: se ausente, inicia em 0. |
| Nós comprados da árvore do hall | `school.hall_nodes` (array de ids) | Não: adiciona campo. Migração: se ausente, inicia `[]`. |
| Variações de retrato desbloqueadas | Derivado de `school.hall_nodes` (nós `portrait_variant`) | Sim: sem campo novo. |
| Símbolo desbloqueado | Derivado de `school.hall_nodes` (nó `hall_symbol_chest`) | Sim: sem campo novo. |
| Estado do mural | Derivado de marcos + `school.hall_nodes` | Sim: sem campo novo. |
| Marcos novos (`belt_amateur`, etc.) | `school.milestones` | Sim: estrutura existente aceita qualquer id. |

**Versão do save:** sobe para **v13**. Migração trivial: dois campos novos com default. Saves v12 abrem sem erro; campos ausentes são inicializados em `_validar_escola`.

### 7.2 Reset de Honra
No `receber_discipulo()` (RECEBER / nova campanha):
- `school.honor_balance = 0`
- `school.hall_nodes = []` (todos os nós são perdidos)
- Exceção: nó `hall_symbol_chest` **não** é removido (persiste como identidade)
- Mural mantém estado (é da escola, não da campanha)

### 7.3 Sem migração complexa
Apenas defaults em `_validar_escola`. Nenhum script de conversão, nenhum mapeamento de dados antigos. Campos novos são opcionais na leitura; se faltam, o jogo assume o estado inicial.

---

## 8. Contrato para o Programador

### 8.1 Arquivos novos/atualizados
| Arquivo | Dono | O que entra na 6c2 |
|---|---|---|
| `data/skill_tree_hall.json` (**novo**) | Designer | Nós, branches, custos, efeitos da árvore do hall |
| `data/escola.json` (bloco `_6c2`) | Designer | `honor_sources`, `mural_states`, `symbol_spec`, `portrait_variants` |
| `data/dialogos.json` (bloco `_6c2`) | Roteirista | Falas de mentor (recorde/revanche), textos de mural |
| `data/ui_texts.json` (chaves novas) | Roteirista | `objects.old_photo_name/story/legacy/john`, textos de mural, títulos da árvore do hall |

### 8.2 Leitura no GameState
| Método/propriedade | Retorno | Notas |
|---|---|---|
| `honor_balance() -> float` | Saldo atual de Honra | Zera no RECEBER |
| `hall_nodes_comprados() -> Array[String]` | Ids dos nós comprados na campanha | Perde tudo exceto `hall_symbol_chest` no RECEBER |
| `simbolo_desbloqueado() -> bool` | Verdadeiro se `hall_symbol_chest` foi comprado alguma vez | Persiste entre campanhas |
| `mural_estado() -> String` | `"empty"\|"john_only"\|"john_left"\|"with_disciple"\|"symbol_unlocked"\|"mural_upgraded"` | Derivado de marcos + nós |
| `mural_texto() -> String` | Texto atual do mural | Conforme §3.1 |
| `portrait_variant() -> String` | Variação ativa do hover da foto | Conforme §4 (prioridade) |
| `honor_gain(source: String, value: float)` | Adiciona Honra e dispara sinal | Chamado em `concluir_luta`, `_tick_recordes`, etc. |
| `hall_buy(node_id: String) -> bool` | Compra nó se saldo suficiente; retorna sucesso | Verifica pré-requisitos e tier |
| `hall_reset()` | Zera saldo e nós (exceto símbolo) | Chamado em `receber_discipulo` |

### 8.3 Sinais novos
| Sinal | Parâmetros | Quando |
|---|---|---|
| `honor_changed` | `(balance: float)` | Qualquer ganho ou gasto de Honra |
| `hall_node_bought` | `(node_id: String)` | Compra bem-sucedida |
| `mural_updated` | `(state: String)` | Mudança de estado do mural |
| `symbol_unlocked` | — | Primeira vez que `hall_symbol_chest` é comprado |

### 8.4 Testes (save de teste, janela no 2º monitor)
| Cenário | Esperado |
|---|---|
| Ganhar Honra por vitória | Saldo sobe 3; sinal `honor_changed` dispara |
| Comprar nó T1 | Saldo desce 8; nó entra em `hall_nodes_comprados`; bônus aplica imediatamente |
| Tentar comprar nó T2 sem T1 | Falha; saldo inalterado |
| Reset no RECEBER | Saldo = 0; `hall_nodes_comprados` = `[]`; `simbolo_desbloqueado` mantém |
| Mural transiciona após cena da academia | Estado muda para `john_only`; texto correto |
| Símbolo aparece na academia após compra | Visível no peito; invisível na garagem |
| Fala de mentor toca em recorde | Balão do mentor aparece; respeita intervalo |
| `ui_audit` com estados novos | 0 problemas |
| `fase5_sim.py` | Resultado idêntico à 6c1 (§9) |

---

## 9. Balanço: nada muda

| Ponto | Por que não muda |
|---|---|
| Honra e árvore do hall | Bônus máximos (+15% clique, +10% passivo) são intra-campanha e não afetam fórmulas de luta, geradores, prêmios ou Legado. Somados aos bônus de Legado, ficam dentro da margem já testada na fase 5. |
| Mural, retrato, símbolo | Puramente visuais/diegéticos. Nenhuma conta lê esses dados. |
| Falas de mentor | Balões passivos; não alteram produção, luta ou economia. |
| `data/` de balanço | Nenhum arquivo de balanço muda (`training`, `generators`, `fights`, `opponents`, `shop`, `skill_tree`, `career`, `locations`, `arts`). Só entram `skill_tree_hall.json` (novo, isolado) e blocos `_6c2` em `escola.json`/`dialogos.json`/`ui_texts.json` (nenhuma conta lê). |

**Simulação:** `tools/sim/fase5_sim.py` não tem parâmetro que a 6c2 toque. O resultado é idêntico ao da 6c1 por construção. O QA confirma com `fase5_sim.py b23c` e `f52`, mais teste comparativo no Godot (duas campanhas iguais, uma com Honra ativa e outra sem, dão relógio, treino, ouro, dia e luta idênticos).

---

## Resumo

- **Honra:** moeda intra-campanha ganha por feitos (vitória 3, revanche 5, recorde 2, marco 4–6). Custos da árvore: T1=8, T2=18, T3=35, T4=60. Bônus máximos +15% clique e +10% passivo, não persistem. Distinta de Legado (permanente, entre campanhas).
- **Árvore do hall:** 20 nós em 4 branches (raízes, boxe, jiu-jitsu, em breve). Dois caminhos principais (clique/passivo) + laterais (retrato/mentor). Ramos de arte ramificados agora; placeholders onde não há conteúdo. Arquivo novo `data/skill_tree_hall.json`.
- **Mural:** 6 estados baseados em marcos e nós. Texto fixo "foi seguir o rumo dele". Integra estados de `ui_audit` da foto e hover.
- **Bônus de retrato:** 6 variações de texto, desbloqueadas por nós ou marcos. Prioridade definida.
- **Falas de mentor:** gatilhos `personal_record_*` e `revenge_win`, intervalo 120/60 s, prioridade 6, `campaign_cap: 3`. Placeholders para o Roteirista.
- **Símbolo da escola:** raiz estilizada 12x12 px, cores `r2`/`y0`, peito esquerdo, só na academia. Fixo, sem evolução. Desbloqueado por nó T3, persiste entre campanhas (exceção à regra de reset).
- **Save v13:** dois campos novos (`honor_balance`, `hall_nodes`) com migração trivial. Símbolo persiste; resto reseta no RECEBER.
- **Balanço inalterado:** nenhum arquivo de economia/luta muda. Simulação idêntica à 6c1 por construção.