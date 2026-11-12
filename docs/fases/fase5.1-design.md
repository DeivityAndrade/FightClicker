# Fase 5.1 — Garagem clara + caixa: design

Dono: Designer de Jogo. Data: 2026-11-11. Branch: `fase-5.1`.
Base: `docs/fases/fase5.1-escopo.md` (aprovado), `docs/fases/fase5-design.md` (R8 vale), `docs/fases/fase5.1-textos.md` (Roteirista).
Nenhum número de balanço muda nesta fase. Tudo novo está na caixa (seção 1) e na hierarquia de tela (seções 2 e 3).

---

## 1. Caixa de equipamento

### 1.1 O que chega em caixa
| Compra | Moeda | Caixa? | Onde a caixa aparece |
|---|---|---|---|
| Esteira (`treadmill`, unlock) | Treino | **sim** | slot `treadmill` |
| Corda (`jump_rope`, unlock) | Treino | **sim** | slot `jump_rope` |
| Pera (`speed_bag`) / Boneco (`grappling_dummy`), aparelho da arte | Treino | **sim** | slot `art` (os dois usam o mesmo: só existe uma arte por carreira) |
| Luva de lona (`glove_l1`) e de couro (`glove_l2`) | Dinheiro | **sim** | slot `glove` |
| Melhorias de aparelho e técnicas | Treino | não, instantâneas | — |
| Equipe (geradores), Prof. Nelson, Metrônomo, MUDAR, nós da árvore | — | não | — |
| Saco (`punching_bag`) | — | não, vem montado em toda carreira | — |

**Caixas por carreira: no máximo 5** (esteira, corda, aparelho da arte, 2 luvas). Meta do escopo: ≤ 6. O simulador confirma (1.9).

### 1.2 Estados e cliques
| Estado | `hits` | Visual (Diretor de Arte) | Entra quando |
|---|---|---|---|
| Fechada | 0 | caixa inteira, etiqueta da escola; balança 1 px a cada 4 s | compra |
| 1 clique | 1 | tremida 1 px, 1ª rachadura | 1º clique |
| 2 cliques | 2 | tremida 2 px, rachadura maior, lasca solta | 2º clique |
| Aberta | — (sai da lista) | tremida 3 px, tampa voa, lascas, "tchan" (brilho), item no lugar | 3º clique |

- Fórmula: `abre quando hits == box.clicks_to_open` (3). Cada clique soma 1; não há limite de velocidade nem tempo entre cliques. Os cliques nunca "esfriam" (2 cliques hoje + 1 amanhã abre).
- **Abertura ≤ 1,5 s** do 3º clique ao item no lugar. Proposta: `open_seconds` = **1,2 s** (0,15 racha + 0,30 tampa voa + 0,45 item aparece com brilho + 0,30 assenta). O estado do jogo muda **no 3º clique** (aparelho montado / luva valendo); a animação é só visual e não bloqueia nada.
- Ao abrir um **aparelho**: entra em `apparatus_owned`, o **foco vai para ele** e salva na hora (o mesmo que a compra fazia até a Fase 5). Toast `box_arrived`.
- Ao abrir uma **luva**: o multiplicador passa a valer, o sprite da luva troca, o foco não muda. Toast `box_arrived`.
- Substitui a "chegada com poeira" da 4b (`unlock_arrived` deixa de ser usado; a poeira pode virar parte do "tchan").

### 1.3 Clique na caixa x clique de treino — **confirmado: clicar na caixa não treina**
- Motivo 1 (número): abrir uma caixa custa ~1 s de reação + 3 cliques (0,6–1 s) + até 1,2 s olhando = **~3 s de mão fora do alvo**. Com 5 caixas, **15,5–17,5 s por carreira, ~1,5% do tempo** de uma carreira típica (1.9). O Metrônomo e a equipe continuam rendendo nesse tempo. Não perde Treino que se sinta.
- Motivo 2 (clareza): se a caixa treinasse, o jogador ficaria em dúvida sobre "onde eu clico". O alvo é um só.
- Condição do Diretor cumprida: **a caixa fica fora do caminho do alvo central** (1.4). Um clique no retângulo de clique (`click_area`) só treina; um clique na caixa só conta para a caixa. **Espaço nunca abre caixa** (só o mouse abre). Teclas 1–4 não focam aparelho que ainda está na caixa.
- O clique na caixa **não** conta crítico, não gera número de treino, não conta como "estou clicando" para o assistido/Shift.

### 1.4 Onde a caixa aparece (nunca cobre o alvo)
Regra dura (vale para garagem e academia):
1. O retângulo da caixa fica a **≥ 8 px** do `click_area` (312,182,48,90) e do lutador em qualquer foco (x 281–362 no chão).
2. Duas caixas nunca se sobrepõem (até 3 juntas: corda, aparelho da arte e luva — ver 1.5).
3. A caixa fica **no chão**, na frente da marca de fita do aparelho (ou embaixo dela, se o aparelho é de parede).

Proposta de slots (ponto = centro-base da caixa; caixa até **24 × 22 px**; o Diretor de Arte fecha os pixels em `manifest.json → layout.box_slots`):
| Slot | Ponto | Ocupa (x) | Justificativa |
|---|---|---|---|
| `treadmill` | (445, 270) | 433–457 | em cima da fita da esteira (lado direito) |
| `jump_rope` | (262, 288) | 250–274 | chão embaixo do gancho, deslocada para a esquerda do lutador (281) |
| `art` | (228, 283) | 216–240 | canto do boneco (pera e boneco usam o mesmo: só uma arte por carreira) |
| `glove` | (382, 288) | 370–394 | entre o alvo (termina em 360) e a esteira de lado (começa em 402), "perto do lutador" |
A sala da academia usa os mesmos slots (as posições dos aparelhos não mudam no `_gym`). Se a corda descer (3.3 do escopo), o slot `jump_rope` continua no chão.

### 1.5 Várias caixas ao mesmo tempo
- **Lado a lado**, cada uma no seu slot, sem fila: o jogador abre a que quiser, na ordem que quiser.
- Para não virar pilha, duas regras de compra (simples para o Programador):
  - **Requisito pede o anterior MONTADO** (como hoje: `aparelho_montado(requires)`). Corda e aparelho da arte só ficam à venda com a **caixa da esteira aberta**. Na marca de fita, a dica diz `tape_locked_box` ("abra a caixa da esteira").
  - **A próxima luva só fica à venda com a caixa da luva anterior aberta.** Na loja, a linha da luva de couro mostra `shop_glove_boxed` (apagada, sem vermelho).
- Resultado: no máximo **1 caixa por slot** e **3 caixas juntas** (corda + arte + luva; a da esteira nunca convive com corda/arte).

### 1.6 O que acontece com...
| Situação | Regra |
|---|---|
| Trocar o foco | A caixa não muda. Aparelho em caixa não pode receber foco (botão de foco mostra o ícone da caixa, apagado; hover `focus_boxed`). |
| Luta (prévia, tela de luta, vitória/derrota) | A sala some; a caixa fica congelada com os `hits` que tinha. Volta igual. |
| Janelas (árvore, arte, aposentar, prévia) | Enquanto `acoes_bloqueadas()`, clique na caixa é ignorado (igual à loja). |
| MUDAR para a academia | As caixas fechadas vão junto, para os mesmos slots na sala da academia. |
| Salvar / fechar / reabrir | Caixas e `hits` vão no save (1.7). Salva na compra e na abertura; o 1º e 2º cliques vão no autosave (30 s). Perder um clique por fechar o jogo não é problema. |
| Tempo | Nunca abre sozinha, nunca some, sem prazo. |
| Fim da carreira (derrota/aposentar) | Caixas fechadas somem com a carreira (como o Treino e os aparelhos). Não devolve nada e não muda o Legado. |
| NOVA CARREIRA | `boxes = []`, só o saco montado, luva velha. Nenhuma exceção (nem com a árvore). |
| Luva dourada (FRENESI) | Independe da caixa. Clicar na caixa durante o FRENESI não treina (o jogador escolhe). |

### 1.7 Save v7
Novo campo na carreira:
```json
"career": { "...todos os campos da v6...": "",
            "boxes": [ { "item": "treadmill", "kind": "apparatus", "hits": 0 },
                       { "item": "glove_l1",  "kind": "glove",     "hits": 2 } ] }
```
| Campo | Tipo | Leitura (validação, com aviso, sem travar) |
|---|---|---|
| `career.boxes` | lista, ordem da compra | ausente/inválido → `[]` |
| `.item` | id de aparelho com `unlock` ou id de luva | inexistente → descarta a entrada |
| `.kind` | `"apparatus"` \| `"glove"` | não bate com o `item` → corrige pelo `item` |
| `.hits` | inteiro 0..2 | fora → `clamp(0, 2)` |
**Consistência:**
- aparelho em caixa **e** em `apparatus_owned` → fica montado, descarta a caixa;
- aparelho de outra arte (ou arte vazia) → descarta a caixa (Treino não volta; dado de save editado);
- caixa repetida (mesmo `item`) → fica a 1ª;
- luva: `glove_level` passa a contar **luvas compradas** (abertas + na caixa). A luva em caixa tem que ser exatamente `levels[glove_level − 1]`; senão descarta a caixa. Multiplicador do clique usa `luvas_abertas = glove_level − (1 se há caixa de luva)`.

**Momentos de salvar (novos):** comprar aparelho/luva (Treino ou Dinheiro + caixa nova, num único save); abrir caixa (caixa sai + `apparatus_owned`/foco, num único save).

### 1.8 Migração `_migrar_6_para_7`
```
v7.career    = v6.career + { boxes: [] }
v7.permanent = v6.permanent
v7.ending    = v6.ending
```
- **Save antigo não vira caixa:** tudo o que está em `apparatus_owned` e `glove_level` continua montado e valendo.
- `SaveStore.MIGRACOES[6] = "_migrar_6_para_7"`, `VERSAO_ATUAL = 7`. Cadeia v0 → v7. Teste em pasta própria.

### 1.9 Simulação (`tools/sim/fase5_sim.py`, seções `b23` e `caixa`)
Modelo: a compra põe o item numa caixa; o robô abre na hora (fila, uma por vez). Abrir custa `reação 1,0 s + 3 cliques / max(3, cps) + 1,5 s de animação` (pessimista: usa 1,5 s, não 1,2 s) **sem nenhum Treino da mão**; Metrônomo e equipe seguem. Aparelho só treina e luva só multiplica **depois** de aberta. Durante a luta o relógio da caixa para. Corda/arte só à venda com a esteira aberta; luva seguinte só com a anterior aberta. Variável `SIM_CAIXA="reacao,cliques,anim,espera"` (`SIM_CAIXA=0` = sem caixa).

**Resultados** (direto de `data/`, robô pega 80% das luvas douradas; "sem" = `SIM_CAIXA=0`, que reproduz exatamente o R8 da Fase 5):

| Meta (crit. 10) | Sem caixa | **Com caixa** | Com caixa, jogador deixa cada caixa 60 s fechada | Situação |
|---|---|---|---|---|
| 1ª derrota da carreira 1 (mediana, 400 jogadores) | 11:14 (5/s) / 12:44 (4/s) | **11:14 / 12:44** | 11:14 / 12:44 | **fecha** (10–15) |
| Cinturão mais cedo (23b) | 20:24 / 22:51 | **20:25 / 22:52** | 20:50 / 22:52 | **fecha** (≥ 20:00) |
| Cinturão na 1ª carreira (23b) | 26,2% / 25,2% | **26,0% / 22,0%** | 25,0% / 29,2% | igual ao R8 (no limite, ruído ±3) |
| Tempo morto carreira 1 (mediana / p90), 32 × 4 carreiras | Boxe 5/s 5:00 / 10:01; JJ 4/s 5:30 / 11:01; Boxe 3/s 6:30 / 13:02 | **5:00 / 10:01; 5:30 / 11:31; 6:30 / 13:32** | — | **fecha** (mediana ≤ 10); p90 +30 s a 3–4/s |
| Tempo morto carreiras 2–4 (p90) | ≤ 8:00 | **≤ 8:00** | — | **fecha** |

| Caixa (16 jogadores × 8 carreiras) | 5/s | 4/s | 3/s |
|---|---|---|---|
| Caixas por carreira (mediana; máximo) | 5; 5 | 5; 5 | 5; 5 |
| Mão na caixa por carreira | 15,5 s | 16,5 s | 17,5 s |
| % do tempo da carreira (mediana; pior) | 1,6–1,7%; 8,4% | 1,5–1,6%; 9,0% | 1,4–1,5%; 6,8% |
O "pior" é uma carreira que acaba aos ~3 min no Dudu: as caixas são as mesmas, a carreira é que é curta.

**O que mexe, sem enfeite:** derrotas do robô no **Dudu** (1ª luta, aos 3:00, chance ~98%) passam de 3 e 10 em 400 (sem caixa) para 10–13 e 26–29 (com caixa, reação de 0,5 s ou 1 s); deixando as caixas 60 s fechadas ficam 6 e 5. É o robô lutando no 1º olhar com ~98%: 3 s a menos de treino trocam o resultado de sementes que estavam no fio. É ruído de sementes (o "60 s fechada" treina menos e perde menos), a mediana da 1ª derrota não se move e o jogador real vê o selo verde. **Nenhum número de balanço muda.**

---

## 2. Três níveis de leitura (garagem e academia)

Níveis: **N1** sempre visível, grande (`txt_hero` / `txt_title`, cor cheia). **N2** visível, discreto (`txt_body`, `col_text_2` nos rótulos). **N3** sob demanda (hover ou 1 clique). "Hover" = dica do `painel_atributos` (caixa de info) ou tooltip; nunca texto fixo sobre a sala.

### 2.1 HUD (topo)
| Item hoje | Nível | Como fica / como achar |
|---|---|---|
| Treino (saldo) | **N1** | `txt_hero`, `col_treino` |
| +X/s (renda passiva total) | **N1** | ao lado do Treino, `txt_body`, `col_treino` |
| Dinheiro | **N2** | `txt_body`, `col_money` |
| Fama | **N3** | ícone pequeno + número em `txt_body`/`col_text_2` num grupo "ⓘ" à direita, ou só ícone; **hover** mostra `hint_fame` + valor |
| Legado em jogo | **N3** | junto da Fama, mesmo grupo; **hover** `hint_legacy` + valor |
| Carreira N | **N2** | `txt_body`, `col_text_2` |
| Nome do local | **N2** | `txt_body`, `col_text_2`; **hover** mostra `location_ambience` (a descrição sai da coluna esquerda) |

### 2.2 Coluna esquerda
| Item hoje | Nível | Como fica / como achar |
|---|---|---|
| 3 atributos (valor + barra) | **N2** | nome em `col_text_2`, valor em `txt_body` branco, barra na cor do atributo |
| Dica do atributo ("Força: quanto dói...") | **N3** | hover no atributo |
| "COMPRE A CORDA PARA TREINAR" (`attr_locked`) | **N3** | atributo sem aparelho mostra só a barra vazia apagada; hover dá o texto |
| PRÓXIMA: nome + selo de risco | **N2** | nome `txt_body`; selo na cor do risco (é o único destaque forte da coluna) |
| Prêmio da luta | **N3** | hover no bloco PRÓXIMA (`hint_prize` / `hint_prize_belt`); continua inteiro na prévia |
| Fita "VOCÊ PERDEU PRA ELE" | **N2** | fica (é a revanche; informação de decisão) |
| "ESPERE FICAR VERDE" | **N2** | fica, `col_text_2` |
| Cartão MUDAR (botão + preço) | **N1** quando existe | é a ação do momento depois do cinturão |
| "APOSENTAR AGORA LEVA {n}" | **N2** | fica |
| Caixa de info / descrição do local | **N3** | a caixa de info só aparece com algo sob o mouse; vazia, não mostra a ambientação |

### 2.3 Coluna direita (loja)
| Item hoje | Nível | Como fica / como achar |
|---|---|---|
| Abas TREINO / LOJA | **N2** | `txt_title` |
| Item comprável mais barato (todas as abas) | **N2 destacado** | brilha (contorno/realce); preço na cor da moeda |
| Outros itens compráveis | **N2** | normais |
| Item sem saldo | **N2 apagado** | texto e preço em `col_text_2`, **sem vermelho** |
| Item bloqueado ("CORDA — DEPOIS DA ESTEIRA") | **N3** | 1 linha só com o nome, apagada; hover `hint_locked_item` |
| Descrição do item, efeito, "AGORA: ..." do Metrônomo | **N3** | hover no item (caixa de info) |
| Custos das melhorias de itens bloqueados | **N3** | hover |

### 2.4 Barra de baixo
| Item hoje | Nível | Como fica / como achar |
|---|---|---|
| Valor por clique | **N1** | `txt_hero`, `col_treino` |
| Auto /s (Metrônomo) | **N2** | `txt_body` |
| Botões de foco (1–4) | **N2** | ícone + nome; o do foco atual realçado. Aparelho que falta: apagado, sem preço (preço no hover). Aparelho em caixa: ícone da caixa |
| Dica de primeira vez ("Clique no saco") | **N2 temporário** | só até o 1º clique da carreira 1 (como hoje) |
| "SEGURE SHIFT" / botão SEGURAR | **N3** | botão fica (é controle), sem texto fixo grande; `hint_assist_first` aparece nas **3 primeiras vezes** que o jogador fica 5 s sem clicar (some sozinha em 4 s); depois só no hover (`hint_assist`) |
| Teclas (1–4, Shift, F11, Espaço) | **N3** | hover num ícone "?" pequeno da barra (`hint_keys`) |
| LUTAR (cor do risco) | **N1** | maior botão da barra |
| APOSENTAR | **N2** | menor que LUTAR |

### 2.5 Sala
| Item hoje | Nível | Como fica / como achar |
|---|---|---|
| Lutador + aparelho em foco | **N1** | igual |
| Números do clique, crítico, FRENESI | **N1 efêmero** | igual (são juice, somem sozinhos) |
| Luva dourada | **N1 efêmero** | igual |
| Equipe (Vizinho, Tio) | **N2** | igual |
| Plaquinhas "X — DEPOIS DA Y" / "X — n TREINO" | **sai** → marca de fita sem texto (**N3**: hover na fita mostra `tape_*`; clique na fita abre a aba TREINO, como hoje) |
| "SEGURE SHIFT" / "SEGURAR" na sala | **sai** (ver 2.4) |
| Chip da arte na sala | **N3** | sai da sala; a arte aparece no hover do nome do local e no botão de foco do aparelho da arte |
| Caixas | **N1** enquanto fechadas | sem texto; hover `box_hover_*` |

**Toda informação continua a ≤ 1 hover ou 1 clique** (critério 4): Fama/Legado (hover no grupo do HUD), descrição do local (hover no nome do local), teclas (hover no "?"), preços e requisitos (hover na fita ou na loja), prêmio (hover no PRÓXIMA ou abrir a prévia).

---

## 3. Tokens de hierarquia
Nomes únicos para Diretor de Arte e UI/UX. O Diretor de Arte escolhe as cores na paleta (`ui_tema.gd`); a coluna "sugestão" é só ponto de partida. A fonte é 5×7 pixel com escala inteira, por isso tamanho = escala.

### 3.1 Tamanhos (no máximo 3)
| Token | Escala | Uso |
|---|---|---|
| `txt_hero` | ×2 | Treino (saldo), valor por clique, texto do botão LUTAR |
| `txt_title` | ×1, cor `col_text_1` + faixa/sublinhado do bloco | títulos de bloco (PRÓXIMA, ATRIBUTOS, abas da loja) |
| `txt_body` | ×1, cor `col_text_1` ou `col_text_2` | todo o resto (rótulos, valores N2, dicas) |
- Fonte pixel 5×7 só tem escala inteira: na garagem usam-se **2 escalas** (×1 e ×2). Se o UI/UX quiser o Treino ainda maior, ×3 vira o `txt_hero` e ×2 o `txt_title`; nunca uma 4ª escala (critério 3).
- Números flutuantes do clique/crítico/FRENESI na sala são efeito, não texto de interface (seguem como estão).

### 3.2 Cores
| Token | Uso | Sugestão (paleta atual) |
|---|---|---|
| `col_treino` | Treino, +/s, por clique, preços em Treino | `Y1` f5d26b |
| `col_money` | Dinheiro e preços em $ | `GR3` a6d86a |
| `col_fame` | Fama | `B3` 8fbbe0 |
| `col_legacy` | Legado (em jogo e permanente) | `P2` b07ad8 |
| `col_text_1` | texto principal N1/N2 | `WHITE` f2ece0 |
| `col_text_2` | texto secundário: rótulos, "CADA", descrições, item sem saldo | `G2` 8f8890 |
| `col_disabled` | item bloqueado (1 linha) | `G1` 6b6570 |
| `col_buyable` | realce do item comprável mais barato (contorno/brilho, não o texto) | `Y2` fff3c4 |
| `col_risk_green` / `col_risk_yellow` / `col_risk_red` | selo de risco e LUTAR | as que já existem |
Regras: a mesma cor da moeda no HUD, na loja e em todo preço. Preço sem saldo = `col_text_2` (nunca vermelho). Atributos mantêm as cores atuais; se uma cor de atributo coincidir com uma de moeda, **muda a moeda**, não o atributo (o Diretor de Arte confere Força vermelha × nada de moeda vermelha).

---

## 4. Contrato de dados

### 4.1 Proposta para `data/training.json` (bloco novo `box`; o Programador aplica)
```json
"box": {
  "clicks_to_open": 3,
  "open_seconds": 1.2,
  "shake_px": [1, 2, 3],
  "shake_seconds": 0.15,
  "idle_wobble_every_seconds": 4.0,
  "applies_to": { "apparatus_unlock": true, "glove": true },
  "focus_on_open": true
}
```
Padrões no código se o bloco faltar: os mesmos valores. `applies_to.*: false` volta ao comportamento da Fase 5 (instantâneo) — útil se o dono preferir a luva instantânea (pergunta 4 da seção 7 do escopo): **é só mudar `"glove": false`**.

Slots de posição: `assets/sprites/manifest.json → layout.box_slots` = `{ "treadmill": [445,270], "jump_rope": [262,288], "art": [228,283], "glove": [382,288] }` (Diretor de Arte confirma).

### 4.2 Funções/estado que a UI vai precisar (nomes sugeridos)
- `GameState.caixas() -> Array` (`[{item, kind, hits}]`), `GameState.bater_caixa(item) -> bool` (soma 1; no 3º abre), sinais `caixa_nova(item)`, `caixa_batida(item, hits)`, `caixa_aberta(item)`.
- `estado_aparelho()` ganha `"boxed"`. `luvas_abertas()`; `proxima_luva()` vazia enquanto há luva em caixa.
- Ids de caixa = id do aparelho (`treadmill`, `jump_rope`, `speed_bag`, `grappling_dummy`) ou da luva (`glove_l1`, `glove_l2`).

### 4.3 Textos (chaves para o Roteirista) — partindo de `fase5.1-textos.md`
Uso as chaves do Roteirista com estas mudanças:
| Chave | Mudança |
|---|---|
| `box_label` / `box_stamp` | sub-chaves pelos **ids reais**: `treadmill`, `jump_rope`, `speed_bag`, `grappling_dummy`, `glove_l1`, `glove_l2` (não `boxing`/`bjj`/`glove_canvas`/`glove_leather`) |
| `hint_keys` | **1 a 4 trocam o FOCO de treino**, não a tática: `ESPAÇO ou clique: treinar\nSHIFT: treino assistido\n1 a 4: foco   F11: tela cheia` |
| `box_hover_queue` | **sai** (não há fila; cada caixa no seu slot) |
| `tape_owned` | não usada (aparelho montado não mostra fita) — pode ficar |
| **novas** `tape_locked_box` | `{nome}\nAbra a caixa da {requisito}.` |
| **nova** `tape_boxed` | hover da fita com a caixa em cima: usa `box_hover_closed` |
| **nova** `focus_boxed` | botão de foco de aparelho em caixa: `Na caixa. Abra para treinar.` |
| **nova** `shop_glove_boxed` | linha da próxima luva: `Abra a caixa da luva antes.` |
| `unlock_arrived` | deixa de ser usada (vira `box_arrived`) |
| `floor_mark_price`, `floor_mark_after`, `assist_hint`, `assist_hint_short` | saem da sala; ficam no JSON só se outro lugar usar |
Ficam como estão: `box_sender`, `box_to`, `box_click`, `box_arrived`, `box_hover_closed`, `box_hover_left`, `tape_open`, `tape_locked`, `tape_short`, `hint_assist`, `hint_assist_first`, `hint_fame`, `hint_legacy`, `hint_locked_item`, `hint_prize`, `hint_prize_belt`.

---

## 5. Testes automáticos que este design pede
| Teste | Confere |
|---|---|
| Compra gera caixa | comprar esteira/corda/arte/luva → `caixas()` cresce; aparelho **não** montado; luva **não** multiplica; melhoria continua instantânea |
| 3 batidas abrem | `hits` 1, 2 → fechada; 3ª → montado, foco nele, salvo; luva → multiplicador vale |
| Clique de treino x caixa | `clicar()` com caixa fechada treina normal e não mexe em `hits`; `bater_caixa` não soma Treino |
| Bloqueios | corda/arte não compráveis com a esteira em caixa; luva 2 não comprável com a 1 em caixa; foco/tecla em aparelho em caixa recusado |
| Persistência | caixa com `hits` 2 sobrevive a salvar/ler, a lutar e a MUDAR |
| Nova carreira | `boxes == []`, só o saco, inclusive depois de aposentar na academia |
| Save v7 | v6 com aparelhos e luva 2 → v7 tudo montado, `boxes == []`; v0 → v7 em cadeia; validações de 1.7 |
| Testes nunca no save real | pasta própria, como hoje |

---

## Resumo
- **Caixa:** esteira, corda, aparelho da arte e as 2 luvas chegam numa caixa da escola (**máx. 5 por carreira**, meta ≤ 6). **3 cliques** abrem (tremida 1/2/3 px); estado muda no 3º clique; animação **1,2 s** (≤ 1,5). Abrir aparelho põe o foco nele e salva.
- **Clique na caixa não treina — confirmado:** custa ~3 s de mão por caixa (~16 s/carreira, ~1,5% do tempo). Caixas ficam em 4 slots no chão, a ≥ 8 px do alvo e do lutador; Espaço nunca abre caixa.
- **Várias caixas:** lado a lado, sem fila. Corda/arte só à venda com a **esteira aberta**; a próxima luva só com a anterior aberta (máx. 3 caixas juntas).
- **Nunca some:** fica com os cliques ao trocar foco, lutar, abrir janelas, MUDAR e salvar; some só com o fim da carreira. NOVA CARREIRA = só o saco.
- **Save v7:** `career.boxes = [{item, kind, hits}]`; `glove_level` passa a contar luvas compradas. Migração v6→v7 só acrescenta `boxes: []`; nada vira caixa.
- **Dados:** bloco `training.json → box` (`clicks_to_open` 3, `open_seconds` 1.2, `applies_to.glove` liga/desliga a luva em caixa); slots em `manifest.json → layout.box_slots`.
- **Tela:** 3 níveis (tabelas da seção 2), tokens `txt_hero`/`txt_title`/`txt_body`, `col_treino`/`col_money`/`col_fame`/`col_legacy`, `col_text_1`/`col_text_2`/`col_disabled`/`col_buyable`.
- **Simulação:** metas da Fase 5 seguem — 1ª derrota 11:14 / 12:44, cinturão mais cedo 20:25, tempo morto mediano 5:00–6:30. Única mexida: mais derrotas do robô no Dudu (ruído de sementes a ~98%).
