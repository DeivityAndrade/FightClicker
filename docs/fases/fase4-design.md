# Fase 4 — Árvore de habilidades (inicial) + Metrônomo: design

Dono: Designer de Jogo. Versão 1 (2026-11-06).
Base: `docs/fases/fase4-escopo.md` (33 critérios), `docs/visao.md`, `docs/roadmap.md`, `docs/propostas/auto-clique.md` (aprovada, opção A nas três perguntas), `fase2-design.md`, `fase3-design.md` (inclusive §16), `fase3-revisao.md`, `data/*.json` e `scripts/` (contrato atual: `game_state.gd`, `save_store.gd`, `fight_data.gd`).
Simulação: `tools/sim/fase4_sim.py` (importa `fase3_sim.py` e `fase2_sim.py`). Os valores deste documento estão no bloco `PROPOSTA` do simulador; quando o Programador criar os JSON novos, o simulador passa a ler de `data/`.
Nada em `data/` nem em `scripts/` foi alterado pelo Designer. A seção 10 lista exatamente o que muda nos JSON.

Regras que não mudam: limiares de risco (`risk.easy_min` 0.90, `even_min` 0.40), motor da luta, motivo da derrota, preços da garagem, Prof. Nelson e luvas. Nada da Fase 5+ entra (sem Linhagem, sem começar com gerador/dinheiro/luva/local, sem arte nova de personagem).

---

## 1. Recursos: de onde vem, para onde vai (o que muda)

| Recurso | Bloco do save | Entra por | Sai por | Na tela |
|---|---|---|---|---|
| **Legado total** (`legacy_total`) | `permanent` | fim de carreira (derrota 50%, aposentadoria 100% + bônus), **agora na escala ×10** | **compra de nós da árvore** (entre carreiras) | inteiro, árvore e HUD "LEGADO" |
| **Nós comprados** (`skill_nodes`) | `permanent` | compra na árvore | nunca (sem reembolso nesta fase) | árvore, cartão de início, resumo da garagem |
| **Algoz** (`revenge_opponent`) | `permanent` | derrota (id de quem venceu) | aposentadoria (vira vazio), vitória sobre ele (vira vazio) | marca "VOCÊ PERDEU PRA ELE" |
| **Nível do Metrônomo** (`metronome_level`) | `career` | compra na LOJA (dinheiro); `1` no início se tiver a Memória muscular | zera em NOVA CARREIRA | prateleira da garagem, LOJA |
| Dinheiro | `career` | prêmio de vitória **× bônus de dinheiro** | LOJA (agora também o Metrônomo) | como na Fase 3 |
| Fama | `career` | prêmio de vitória **× bônus de fama** | nada | como na Fase 3 |

O pote (Legado em jogo) continua **derivado**: `floor(fama × legacy_per_fame) + belt_legacy_bonus se cinturão`.

## 2. Reescala do Legado (×10)

Com rendas de 1, 4, 10 e 75 não dá para ter 10 nós com preço crescente, o 1º custando "uma derrota no Brutão" e o cinturão comprando no máximo metade. **Tudo ×10**, mesmas proporções:

| Campo (`data/career.json`) | Fase 3 | **Fase 4** |
|---|---|---|
| `legacy_per_fame` | 0.2 | **2.0** |
| `belt_legacy_bonus` | 10 | **100** |
| `defeat_share` / `retire_share` / `retire_belt_bonus_share` | 0.5 / 1.0 / 0.5 | sem mudança |

| Vitórias na carreira | Fama | Pote | Perde a próxima | Aposenta |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |
| 1 (Dudu) | 10 | 20 | **10** (derrota no Brutão) | 20 |
| 2 (+ Brutão) | 40 | 80 | **40** (derrota no Dinho, o caso típico) | 80 |
| 3 (+ Dinho) | 100 | 200 | **100** (derrota no Seu Muralha) | 200 |
| 4 (cinturão) | 200 | 400 + 100 = 500 | — | **750** (500 + 250) |

Com o nó `career_crowd` (+50% de fama): 15 / 45 / 90 / 150 de fama por vitória → derrota no Dinho 60, no Muralha 150, cinturão + aposentar **1.050**.
Migração: o Legado guardado de um save v3 é multiplicado por 10 (seção 8.3). Quem tinha 14 passa a ter 140, e a proporção com os preços é a mesma.

## 3. A árvore

### 3.1 Estrutura
Dois ramos, **Corpo** (`body`) e **Carreira** (`career`), com 5 nós cada (10 no total). Cada ramo tem uma linha principal e **uma bifurcação, logo no 1º nó**: o 1º nó do ramo abre dois caminhos de 2 nós. Um nó só pede o anterior do mesmo ramo (`requires`, um id só ou vazio).

```
CORPO                                        CARREIRA
body_jab (10)                                career_purse (10)
 ├─ body_muscle_memory (30)                   ├─ career_scouting (25)
 │   └─ body_heavy_hands (500)                │   └─ career_purse_2 (500)
 └─ body_crew (150)                           └─ career_crowd (250)
     └─ body_crew_2 (900)                         └─ career_good_loser (800)
```
Preço sempre crescente dentro de cada caminho. **Custo total: 3.175.**

### 3.2 Lista final de nós
Nomes provisórios (o Roteirista refina no tom do mentor). Efeitos **aditivos** entre nós do mesmo tipo (R2): dois nós de +50% de passivo dão +100%, nunca ×2,25.

| id (estável) | Ramo | Nome provisório | Custo | Requer | Efeito exato (`effect`) | Onde aparece na tela (critério 10) |
|---|---|---|---|---|---|---|
| `body_jab` | Corpo | Jab de base | **10** | — | `click_bonus` **+1.0** (treino por clique ×2, vale para o Metrônomo) | número flutuante do 1º clique sai **2** em vez de 1 (crítico 6 em vez de 3); painel "POR CLIQUE" mostra 2 |
| `body_muscle_memory` | Corpo | Memória muscular | **30** | `body_jab` | `metronome_start` **1** (a carreira começa com o Metrônomo no nível 1) | Metrônomo na prateleira oscilando e socando no minuto 0; LOJA oferece o nível 2 |
| `body_heavy_hands` | Corpo | Mão pesada | **500** | `body_muscle_memory` | `click_bonus` **+0.5** (somado: clique ×2,5) | número do clique e "POR CLIQUE" (1 → 3 arredondado; com a fita, 7.5 → 8) |
| `body_crew` | Corpo | Garagem animada | **150** | `body_jab` | `passive_bonus` **+0.5** (todos os geradores, inclusive o Prof. Nelson, ×1,5) | "AUTO" (treino/s) do painel; efeito de cada gerador na garagem e na LOJA ("+38/S" no Nelson) |
| `body_crew_2` | Corpo | Garagem lotada | **900** | `body_crew` | `passive_bonus` **+0.5** (somado: passivo ×2) | idem ("+50/S" no Nelson) |
| `career_purse` | Carreira | Bolsa negociada | **10** | — | `money_bonus` **+0.5** (prêmio em dinheiro ×1,5) | prêmio da prévia: "SE VENCER: $75 (+50%) + 10 FAMA"; tela de vitória "+$75" |
| `career_scouting` | Carreira | Olho de treinador (prévia detalhada) | **25** | `career_purse` | `preview_percent` **1** (a prévia mostra a porcentagem de vitória) | prévia: "EQUILIBRADO 62%" ao lado do rótulo da tática selecionada |
| `career_purse_2` | Carreira | Empresário de bairro | **500** | `career_scouting` | `money_bonus` **+0.5** (somado: dinheiro ×2) | prêmio da prévia "$100 (+100%)" |
| `career_crowd` | Carreira | Torcida da rua | **250** | `career_purse` | `fame_bonus` **+0.5** (fama por vitória ×1,5, arredondada) | prévia "+15 FAMA (+50%)"; HUD "LEGADO EM JOGO" sobe mais rápido |
| `career_good_loser` | Carreira | Saber cair | **800** | `career_crowd` | `defeat_share_bonus` **+0.25** (a derrota leva 75% do pote, não 50%) | prévia `stake_lose` "PERDER ENCERRA A CARREIRA (75% DO LEGADO)"; tela de fim |

Por que estes:
- **Os dois primeiros (10 e 10)** são a escolha da 1ª derrota: clique (sente no 1º clique) ou dinheiro (sente na 1ª vitória). Quem perde no Brutão (10) escolhe um; quem perde no Dinho (40) leva os dois e sobra 20 (falta pouco para a Memória muscular ou a prévia detalhada: meta visível).
- **+100% no clique** (e não +25%): o número na tela sai de 1 para 2. Com +25% a tela mostraria "1" (o número flutuante é arredondado), e o critério 10 falharia.
- **Memória muscular custa 30**: barata, chega na 2ª ou 3ª carreira, como a proposta pede (o jogador já sabe que clicar importa, R4).
- **Prévia detalhada custa 25**: é informação, não força. Fica logo atrás da bolsa.
- **Os nós de 500 a 900** são o "fim de jogo" da árvore: cada um pede uma aposentadoria com cinturão inteira (critério 8, R3).
- `career_good_loser` não muda a regra "aposentar rende mais": 75% < 100%. Validação no código: `defeat_share + soma dos defeat_share_bonus` < `retire_share`, senão recorta em `retire_share − 0.05` com aviso.

### 3.3 Preços contra as rendas (critérios 6 e 7)
| Renda | Legado | O que compra (regra "mais barato" e regra "dica", iguais aqui) | Sobra |
|---|---|---|---|
| derrota no Brutão | 10 | `body_jab` **ou** `career_purse` | 0 |
| derrota no Dinho (típica) | 40 | `body_jab` + `career_purse` | 20 |
| derrota no Seu Muralha | 100 | + `body_muscle_memory` + `career_scouting` | 25 |
| cinturão + aposentar | 750 | + `body_crew` + `career_crowd` (6 nós) | 275 |

- Critério 6: há nó de preço ≤ 10 (dois, em ramos diferentes) e 2 nós em ramos diferentes ≤ 40. **Fecha.**
- Critério 7: 750 / 3.175 = **24%** do custo total (com a torcida, 1.050 = 33%). **Fecha** (≤ ~50%).

### 3.4 Regras de compra
1. A árvore **só abre pela tela de fim** (derrota ou aposentadoria): botão próprio ao lado de NOVA CARREIRA. Na garagem, na prévia e na luta não há caminho até ela (critério 4).
2. Comprar = **1 clique** no nó comprável. Comprável = não comprado, `requires` vazio ou comprado, e `custo ≤ legacy_total`.
3. Compra: `legacy_total -= custo`, `skill_nodes.append(id)`, **salva na hora** (um save só). Recusa sem saldo ou sem o anterior (não muda nada, sem aviso de erro: o nó já aparece como "falta Legado" ou "trancado"). Nunca deixa o Legado negativo.
4. **Sem reembolso** nesta fase.
5. Os bônus valem **a partir da próxima NOVA CARREIRA**. Como a árvore só abre com a tela de fim pendente (carreira congelada), "os bônus da carreira atual" = `bonus_de(permanent.skill_nodes)` em qualquer momento em que a carreira está viva. Não é preciso guardar uma cópia por carreira. Ao carregar, os bônus são recalculados a partir de `skill_nodes` (nunca somados de novo).
6. Estados do nó na tela: **comprado** (aceso), **comprável** (borda viva, preço em destaque), **falta Legado** (preço em vermelho, "FALTAM {n}"), **trancado** (apagado, "PEDE: {nome do anterior}").
7. Cliques: tela de fim → NOVA CARREIRA continua 1 clique (≤ 2, critério 5). Tela de fim → ÁRVORE (1) → compras → NOVA CARREIRA na árvore (1): 2 cliques além das compras (≤ 3).

### 3.5 Como cada efeito é calculado (fórmulas)
```
B = soma, por tipo, dos `effect.value` dos nós em permanent.skill_nodes
mult_clique    = 1 + B.click_bonus                              (0 → 1;  body_jab → 2;  + heavy_hands → 2,5)
por_clique     = base_training × mult_aparelho(foco) × mult_luva × mult_clique
mult_passivo   = 1 + B.passive_bonus
producao_total = (Σ geradores da garagem + Σ geradores pagos) × mult_passivo
premio_dinheiro= prize_money × (1 + B.money_bonus)
premio_fama    = floor(prize_fama × (1 + B.fame_bonus) + 0.5)     (inteiro)
defeat_share_ef= defeat_share + B.defeat_share_bonus               (< retire_share)
metronome_start= max dos `metronome_start`                         (0 ou 1)
preview_percent= true se algum nó tem `preview_percent`
```
- O crítico do clique continua `crit_multiplier` × `por_clique`.
- Os custos da garagem e da LOJA **não** mudam com a árvore.
- O cartão de início e o resumo da garagem mostram cada nó com o seu `effect_text` (ex.: "+100% TREINO POR CLIQUE").

## 4. Metrônomo (LOJA, dinheiro)

### 4.1 Níveis
| id | Custo ($) | Intervalo | Socos/s | Texto do item (`shop_metronome_effect`) |
|---|---|---|---|---|
| `metronome_l1` | **80** | **2.0 s** | 0,50 | "1 SOCO A CADA 2.0 S" |
| `metronome_l2` | **150** | **1.0 s** | 1,00 | "1 SOCO A CADA 1.0 S" |
| `metronome_l3` | **300** | **0.7 s** | 1,43 | "1 SOCO A CADA 0.7 S" |

- Comprado em ordem, um item com níveis (como a linha de luvas). Total $530.
- **1º nível ($80) cabe no prêmio de 2 vitórias** (Dudu $50 + Brutão $150; com a bolsa, já no Dudu $75 + sobra). Critério 12 **fecha**.
- **Ritmo máximo 1,43 soco/s** (≤ 1,5, critério 15).
- Decisão "luva, treinador ou ritmo?": com a luva de lona e o jab da árvore, um soco vale ~54 de treino. O nível 1 dá ~27/s por $80; o 2º Prof. Nelson dá 25/s por $80 (37/s com `body_crew`). Com a luva de couro (~108 por soco), o nível 2 dá +54/s por $150 e passa o Nelson. No simulador o robô compra o Metrônomo **depois** das luvas, com o dinheiro do Dinho (ver 9.4): ele é a compra "para quando o soco já vale muito".

### 4.2 Como funciona (regras para o Programador)
```
intervalo = levels[metronome_level − 1].interval        (sem Metrônomo se metronome_level = 0)
a cada frame, se o alvo aceita clique:  acc += delta
enquanto acc ≥ intervalo (no máximo 3 por frame):  acc −= intervalo ; auto_soco()
se o alvo não aceita clique: acc não anda (não acumula socos para depois)
```
- **"O alvo aceita clique"** = garagem na tela, sem luta, sem tela de fim, sem janela modal aberta (prévia, confirmação de aposentar, cartão de início). O painel da LOJA não bloqueia (é painel lateral). Na luta e com a tela de fim: **0 socos, 0 treino** (critério 16).
- `acc` não vai para o save. Fechar e abrir recomeça do zero (meio soco perdido no máximo). **Offline: nada** (Fase 9).
- `auto_soco()` é **o mesmo caminho do `clicar()`**: mesmo aparelho em foco, mesmo `por_clique()` (aparelho × luva × `mult_clique` da árvore), **mesmo sorteio de crítico** (`crit_chance`, mesmo `rng`), treino no saldo e no atributo do foco. Difere só no sinal: emite `auto_socou(ganho, critico, aparelho, atributo, texto_critico)` (ou `clicou` com `auto = true`), para a UI tratar diferente.
- O que o auto-soco **não faz** (UI/UX): não treme a tela; número flutuante **menor** (ex.: 70% do tamanho) e com menos opacidade; som mais baixo (ex.: −8 dB); o lutador anima o `jab` do rig com a **mesma luva** do cursor (`sufixo_luva()`). O soco do jogador continua sendo o mais pesado.
- Soma, não substitui: os cliques do jogador continuam normais, ao mesmo tempo. O auto-soco não bloqueia nem pausa o alvo.
- Nada de desgaste. Zera em NOVA CARREIRA (`metronome_level = 0`), ou volta para **1** com `body_muscle_memory`. Nesse caso a LOJA oferece o `metronome_l2`.

### 4.3 Critério 15 (clicar rende ≥ 2,5× mais)
Mesmo aparelho, mesma luva, mesmos nós: treino de clique por segundo = `(cliques/s + socos/s do Metrônomo) × por_clique × média do crítico`.
| Jogador | Com o Metrônomo no máximo | Só o Metrônomo (não clica) | Razão |
|---|---|---|---|
| lento, 3 cliques/s | 4,43 socos/s | 1,43 | **3,1×** |
| típico, 4 cliques/s | 5,43 | 1,43 | **3,8×** |
| típico, 5 cliques/s | 6,43 | 1,43 | **4,5×** |

Na curva (seção 9.4), aos 15 min da 1ª carreira a 5/s o clique do jogador dá 360/s e o Metrônomo (nível 2) 72/s: a mão continua sendo 5× o ajudante.

## 5. Revanche

- **Gatilho de marca:** ao encerrar uma carreira por **derrota**, `permanent.revenge_opponent = id do adversário que venceu` (no mesmo save que soma o Legado). Ao encerrar por **aposentadoria**, `revenge_opponent = ""`.
- **Onde aparece:** na carreira seguinte, sempre que o próximo adversário (`proximo_adversario().id`) for igual a `revenge_opponent`: HUD "PRÓXIMA: nome" ganha a linha `revenge_mark` ("VOCÊ PERDEU PRA ELE"), e a prévia mostra a mesma marca no topo. Contra outros adversários, nada.
- **Vencer ele:** ao aplicar a vitória (`concluir_luta`, no mesmo save do prêmio), se o adversário vencido == `revenge_opponent`: `revenge_opponent = ""` e o resumo devolvido ganha `revenge: true`. A tela de vitória mostra o momento `victory_revenge` ("REVANCHE!") **uma vez**. Reabrir com a luta pendente aplica a vitória uma vez só (regra da Fase 3) e mostra a revanche uma vez.
- Não é preciso campo novo em `career`: a marca está em `permanent` e some na vitória.
- Só a última derrota conta. Não há histórico.

## 6. Dica "lute quando ficar verde"

- **Tela de fim:** se `ending.reason.kind != "luck"` (ou seja, `missing`, `far` ou `far_plain`), depois da dica do atributo aparece a linha `tip_wait_green` ("VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE"). Se `kind == "luck"`, só a dica de azar (como hoje). Critério 20.
- **Prévia contra o algoz:** se `adversario.id == revenge_opponent` **e** o rótulo da tática selecionada não é FÁCIL (chance < `risk.easy_min`), aparece `preview_wait_green` ("ESPERE FICAR VERDE"). Recalcula junto com o rótulo quando a tática muda. Critério 21.
- Limiares e rótulos da Fase 3 **não mudam**. O teste de risco honesto continua valendo.

## 7. Bônus visíveis

- **Cartão de início** (`career_card_*`): em NOVA CARREIRA, se `skill_nodes` não está vazio, janela pequena "CARREIRA {n} — O QUE VOCÊ TROUXE:" com uma linha por nó comprado (ícone + `effect_text`). Some sozinho em **1,8 s** ou com 1 clique. Enquanto aberto, o alvo não aceita clique (≤ 1,8 s). Não reabre ao carregar o save.
- **Resumo na garagem:** rótulo pequeno `legacy_nodes_label` ("LEGADO: {n} NÓS") perto do HUD do Legado; ao passar o mouse, a mesma lista do cartão. Não cobre o alvo. Com 0 nós, não aparece.
- **Prêmio com bônus:** `stake_win` passa a mostrar o valor com o bônus e o bônus entre parênteses quando > 0: "SE VENCER: $75 (+50%) + 15 FAMA (+50%)" (`stake_bonus` = "(+{n}%)").
- **Tela de vitória:** `victory_gain` vira "+${n}   +{n} FAMA   +{n} LEGADO EM JOGO" (ajuste pedido na revisão da Fase 3).
- Sai da tela de fim a frase `legacy_note` ("VAI SERVIR NA PRÓXIMA VERSÃO").
- A garagem mostra o Legado total, e a árvore mostra o Legado disponível no topo.

## 8. Save v4

### 8.1 Formato (o que muda em relação à v3)
```json
{
  "version": 4,
  "saved_at_unix": 1730000000,
  "state": {
    "career": {
      "...todos os campos da v3...": "",
      "metronome_level": 1
    },
    "permanent": {
      "legacy_total": 140,
      "career_number": 3,
      "careers_finished": 2,
      "best_wins": 3,
      "belts_won": 0,
      "skill_nodes": ["body_jab", "career_purse"],
      "revenge_opponent": "opp_fast"
    },
    "ending": null
  }
}
```
- `career.metronome_level`: inteiro 0..nº de níveis (recorta).
- `permanent.skill_nodes`: lista de ids, ordem da compra. Na leitura: ignora id inexistente ou repetido (com aviso) e ignora nó cujo `requires` não está na lista (com aviso). **O Legado gasto não é devolvido** por esse descarte (é dado ruim de save editado, não de jogo).
- `permanent.revenge_opponent`: id de adversário existente ou `""` (inválido → `""`).
- `ending` não muda de formato (o `legacy_gained` e o `legacy_total` já estão na escala nova).

### 8.2 Momentos de salvar (novos)
| Ação | Num único save |
|---|---|
| Comprar nó | `legacy_total −= custo`, `skill_nodes += id` |
| Comprar nível do Metrônomo | `money −= custo`, `metronome_level += 1` |
| Derrota (fim da animação ou reabrir) | como na Fase 3 + `revenge_opponent = adversário` |
| Confirmar aposentadoria | como na Fase 3 + `revenge_opponent = ""` |
| Vitória (fim da animação ou reabrir) | como na Fase 3 + se era o algoz, `revenge_opponent = ""` |
| NOVA CARREIRA | como na Fase 3 + `metronome_level = metronome_start` (0 ou 1) |

Fechar e abrir com a árvore aberta: volta à tela de fim (o `ending` continua pendente), com o Legado e os nós do último save. Logo depois de comprar: o nó já está salvo. Cartão de início: não reaparece. Nada duplica (critério 29).

### 8.3 Migração `_migrar_3_para_4`
```
v3: { version 3, saved_at_unix T, state: { career: {...}, permanent: {...}, ending: E } }
v4: { version 4, saved_at_unix T, state: {
        career:    { ...v3 copiado..., metronome_level: 0 },
        permanent: { ...v3 copiado..., legacy_total: 10 × v3.legacy_total, skill_nodes: [], revenge_opponent: "" },
        ending:    E com legacy_gained × 10 e legacy_total × 10 (se E não é null) } }
```
- O fator **10** é uma constante da migração (`ESCALA_LEGADO_V4 := 10`), não um dado balanceável: é conversão de formato.
- Carreira em andamento intacta (inclusive `fight` pendente). Sem marca de revanche, nenhum nó.
- `SaveStore.MIGRACOES[3] = "_migrar_3_para_4"`, `VERSAO_ATUAL = 4`. A cadeia v0 → v4 continua.

## 9. Simulação e balanço

### 9.1 O robô
`tools/sim/fase4_sim.py` (seções `precos metronomo curvas revanche carreiras`). Luta, prévia (200 sementes fixas no jogo, 100 no robô), motivo e garagem são os da Fase 3. Clique em valor esperado (crítico pela média). Olha a prévia a cada 30 s.

- **Robô típico ("lê a prévia")**, usado nas tabelas principais:
  - Treina no saco. Depois da 1ª vitória da carreira, se o próximo está PERIGOSO e a prévia mostra "ELE É MUITO MAIS ..." (razão ≥ 2) num atributo que não é Força, alterna saco e esse aparelho a cada 60 s (é o que a prévia e a revisão da Fase 3 dizem que gente de verdade faz).
  - Contra o **algoz** da carreira anterior: alterna saco e o aparelho da dica da tela de fim, e **só luta quando estiver VERDE** (a dica nova). Contra quem já o derrotou alguma vez, também espera o verde (memória). Contra os outros, luta no amarelo (≥ 40%), como o típico da Fase 3.
  - LOJA: compra o item de maior ganho por dinheiro (Nelson, luva, Metrônomo); **no vermelho não fica juntando**: compra o melhor que cabe.
  - Cinturão: aposenta na hora (não há mais lutas). 60 min sem fim: aposenta.
  - Entre carreiras compra nós pela regra **"dica"** (ordem do Designer: `body_jab`, `career_purse`, `body_muscle_memory`, `career_scouting`, `body_crew`, `career_crowd`, `body_heavy_hands`, `career_purse_2`, `body_crew_2`, `career_good_loser`) ou **"mais barato"**.
- **Cauteloso:** igual, mas da 2ª carreira em diante espera o verde contra **todos**. É o jogador que aprendeu a lição "volte quando ficar verde".
- **Robô da Fase 3** (não lê a prévia): só saco, para comparar com a Fase 3.
- **Aposenta no vermelho:** típico que, depois de 10 min seguidos no vermelho, aposenta em vez de esperar.
- Perfis: típico 5 e 4 cliques/s, lento 3/s, com e sem Metrônomo. 32 jogadores por perfil, 8 carreiras cada (revanche: 120 jogadores, 2 carreiras).

### 9.2 Tempo morto (definição operacional)
Para cada 0,1 s de simulação (ou de jogo):
```
morto = (garagem na tela, sem luta, sem tela de fim)
        e existe próximo adversário (escada não acabou)
        e o rótulo de risco do próximo adversário é PERIGOSO na MELHOR das 3 táticas (chance < even_min)
        e dinheiro < menor preço da LOJA (próximo Prof. Nelson, próxima luva, próximo nível do Metrônomo)
trecho = tempo seguido com morto = verdadeiro (qualquer instante falso fecha o trecho)
reporta o maior trecho de cada carreira
```
- O rótulo é o da última olhada na prévia (robô: a cada 30 s; jogo: o HUD, 1 vez por segundo).
- **"Vermelho"** (R7): o mesmo trecho sem a condição da LOJA. Como o robô não junta dinheiro no vermelho, os dois saem quase iguais; a tabela mostra os dois.
- Depois do cinturão não há próximo adversário: não é tempo morto (o robô aposenta).

### 9.3 Mudança da Fase 3 que o balanço pede
| Arquivo / campo | De | Para | Por quê |
|---|---|---|---|
| `opponents.json` `opp_fast.prize_money` | 400 | **800** | É o único dinheiro entre o Dinho e o Seu Muralha. Com $800 (ou $1.200 com a bolsa) o jogador compra luva de couro **e** Metrônomo (ou mais Nelsons) e encurta a espera diante do Muralha: o maior trecho no vermelho da 1ª carreira cai de **17:02 para 11:01** (p90, 5/s). Também responde à decisão 4 da Fase 3 ("o dinheiro compra pouco"). |
| `career.json` | ver seção 2 | ×10 | reescala |

**O Seu Muralha não muda** (decisão A da revisão da Fase 3). Com a árvore, as carreiras 2 a 4 fecham o tempo morto sem mexer nele (9.5). Mexer nele não resolve a 1ª carreira sem quebrar o critério 23 (9.7).

### 9.4 Curvas (uma semente, robô típico)
Rodar: `fase4_sim.py curvas`. "Clique" = só a mão do jogador; "Metrônomo" = só os auto-socos.

**1ª carreira, sem nós, 5 cliques/s**
| min | clique/s | Metrônomo/s | passivo/s | treino total | vitórias | Nelson | luva | Metrônomo |
|---|---|---|---|---|---|---|---|---|
| 1 | 18 | 0 | 2 | 498 | 0 | 0 | 0 | 0 |
| 3 | 18 | 0 | 7 | 3.42K | 0 | 0 | 0 | 0 |
| 5 | 82 | 0 | 42 | 12.0K | 1 | 1 | 0 | 0 |
| 10 | 180 | 0 | 95 | 59.1K | 2 | 1 | lona | 0 |
| 15 | 360 | 72 | 166 | 200K | 3 | 2 | couro | 2 |
| 20 | 360 | 72 | 193 | 385K | 3 | 2 | couro | 2 |

Marcos: fita 0:53, Dudu 3:13, Nelson 3:13, areia 4:14, Brutão 8:44, lona 8:44, **Dinho 11:44 → couro + Metrônomo 1 e 2 com os $800** (nesta semente venceu; 59% das carreiras perdem aqui), Seu Muralha 23:24.

**2ª carreira com `body_jab` + `career_purse` (o que a derrota no Dinho compra), 5 cliques/s**
| min | clique/s | Metrônomo/s | passivo/s | treino total | vitórias |
|---|---|---|---|---|---|
| 1 | 36 | 0 | 5 | 1.70K | 0 |
| 3 | 180 | 0 | 42 | 10.8K | 1 |
| 5 | 174 | 0 | 69 | 31.2K | 1 |
| 10 | 720 | 205 | 182 | 160K | 3 |
| 15 | 720 | 205 | 235 | 501K | 3 |

Dudu 2:13, Brutão 6:14, Metrônomo 1 aos 6:31, **Dinho 9:44** (antes: perdeu aos 11:44), Metrônomo no máximo 9:44, cinturão 16:50. A 2ª carreira é visivelmente mais forte: no 1º minuto já tem 3,4× o treino.

**Árvore completa, 5 cliques/s:** Dudu 1:43, Brutão 4:14, Dinho 6:14, cinturão 10:53. É a "carreira de quem já sabe": curta, e é o fim do protótipo (R3).
**Lento (3/s), 1ª carreira:** Dudu 4:14, Brutão 11:14, perde no Dinho 15:14. Com o jab + bolsa: Dudu 3:13, Dinho 12:44, cinturão 21:52.

- O clique continua o centro: aos 15 min da 2ª carreira, a mão dá 720/s, o Metrônomo 205/s e o passivo 235/s. Com a árvore completa aos 10 min: 900 / 257 / 572.
- O Metrônomo entra **depois das luvas**: o robô compra o nível 1 entre o Brutão e o Dinho e os níveis 2 e 3 com o prêmio do Dinho.

### 9.5 Carreiras em sequência (32 jogadores por perfil, 8 carreiras)
Rodar: `SIM_N=32 SIM_CARREIRAS=8 fase4_sim.py carreiras`. Cinturão = carreira em que sai o 1º cinturão. Árvore = carreira ao fim da qual os 10 nós estão comprados. "Revanche" = 2ª carreira, vitória sobre quem encerrou a 1ª.

| perfil | 1ª derrota (mediana) | como a 1ª carreira acaba (de 32) | cinturão: carreira (mediana; p10–p90) | cinturão na 1ª antes de 40 min | revanche Dinho | revanche Muralha | árvore fecha (mediana; p10–p90) |
|---|---|---|---|---|---|---|---|
| **típico 5/s** | **11:44** | Dinho 19, Muralha 5, Dudu 3, cinturão 5 | **2** (1–4) | 5 (23:22) | 18 de 19 | 1 de 5 | **6** (5–7) |
| **típico 4/s** | **13:44** | Dinho 19, Muralha 6, Dudu 2, cinturão 5 | **2** (1–3) | 5 (26:55) | 17 de 19 | 3 de 6 | **6** (5–8) |
| lento 3/s | 15:14 | Dinho 16, Muralha 6, Dudu 7, cinturão 3 | 3 (2–3) | 3 (30:26) | 14 de 16 | 4 de 6 | 6 (6–8) |
| típico 5/s, nós "mais barato" | 11:44 | igual | 2 (1–4) | 5 | 18 de 19 | 1 de 5 | 6 (6–7) |
| típico 4/s, nós "mais barato" | 13:44 | igual | 2 (1–3) | 5 | 17 de 19 | 3 de 6 | 6 (5–8) |
| típico 5/s, **sem Metrônomo** | 11:44 | igual | 2 (1–3) | 5 (24:23) | 18 de 19 | 3 de 5 | 6 (5–7) |
| típico 4/s, sem Metrônomo | 13:44 | Dinho 19, Muralha 7, Dudu 2, cinturão 4 | 2 (1–3) | 4 (27:55) | 17 de 19 | 4 de 7 | 7 (6–7) |
| lento 3/s, sem Metrônomo | 15:14 | igual ao lento | 3 (2–4) | 3 (31:56) | 14 de 16 | 2 de 6 | 7 (6–8) |
| cauteloso 5/s | 11:44 | igual ao típico | 2 (1–2) | 5 | 18 de 19 | **5 de 5** | 5 (4–6) |
| cauteloso 4/s | 13:44 | igual ao típico | 2 (1–2) | 5 | 19 de 19 | **6 de 6** | 5 (5–6) |
| cauteloso 3/s | 15:14 | igual ao lento | 2 (2–3) | 3 | 15 de 16 | 6 de 6 | 5 (5–6) |
| robô da Fase 3 (só saco), 5/s | 12:44 | Dinho 11, Muralha 10, Brutão 2, Dudu 3, cinturão 6 | 3 (1–4) | 6 (33:19) | 9 de 11 | 5 de 10 | 7 (6–8) |
| típico 5/s, aposenta após 10 min no vermelho | 11:44 | Dinho 19, Dudu 3, **aposentou 10** | 3 (2–4) | 0 | 18 de 19 | — | 6 (6–7) |

Legado típico por carreira (5/s): 1ª derrota no Dinho = 40 → jab + bolsa; a 2ª carreira sai com o cinturão em ~47% (15 de 32) = 750 → mais 4 nós; as derrotas da 3ª e 4ª no Muralha rendem 150 (com a torcida). A árvore fecha com o 3º ou 4º cinturão.

**Tempo morto (maior trecho seguido; mediana / p90 / pior; nº de carreiras acima de 10 min, de 32)**
| perfil | carreira 1 | carreira 2 | carreira 3 | carreira 4 |
|---|---|---|---|---|
| **típico 5/s** | 5:00 / **11:01** / 11:01 (10) | 6:00 / 6:00 / 11:01 (2) | 5:00 / 6:00 / 6:00 (0) | 5:00 / 5:30 / 6:00 (0) |
| **típico 4/s** | 6:00 / **12:32** / 12:32 (11) | 7:00 / 7:00 / 7:30 (0) | 6:00 / 7:00 / 7:00 (0) | 5:30 / 6:30 / 7:00 (0) |
| lento 3/s | 6:30 / 14:33 / 14:33 (9) | 8:00 / 9:00 / 14:33 (3) | 7:01 / 8:01 / 9:00 (0) | 6:00 / 7:00 / 8:01 (0) |
| típico 5/s, sem Metrônomo | 5:00 / 12:01 / 12:01 (10) | 7:00 / 7:30 / 12:02 (2) | 6:00 / 7:00 / 7:00 (0) | 5:30 / 6:00 / 7:00 (0) |
| típico 4/s, sem Metrônomo | 6:00 / 13:32 / 13:32 (11) | 8:30 / 9:00 / 9:00 (0) | 6:00 / 8:00 / 8:30 (0) | 6:00 / 7:00 / 8:30 (0) |
| lento 3/s, sem Metrônomo | 6:30 / 16:03 / 16:03 (9) | 10:01 / 11:01 / 16:03 (19) | 10:01 / 10:01 / 11:01 (16) | 7:00 / 8:31 / 10:01 (3) |
| cauteloso 4/s | 6:00 / 12:32 / 12:32 (11) | 7:00 / 7:00 / 11:02 (2) | 5:30 / 5:30 / 5:30 (0) | 4:30 / 4:30 / 6:30 (0) |
| robô da Fase 3, 5/s | 20:03 / 20:03 / 20:03 (16) | 6:30 / 10:00 / 19:33 (6) | 5:30 / 9:30 / 10:01 (3) | 8:00 / 10:00 / 10:31 (4) |
| aposenta após 10 min no vermelho, 5/s | 5:00 / 10:00 / 10:00 | 6:00 / 6:00 / 10:00 | 5:00 / 6:00 / 6:00 | 5:00 / 5:30 / 6:00 |

- "Vermelho" (R7, só perigoso, sem olhar a loja) deu **igual** ao tempo morto em todas as linhas: o robô não guarda dinheiro no vermelho, e o dinheiro só chega com vitória.
- O trecho de ~5–6 min presente em quase toda carreira é o **Brutão** (do Dudu até o Brutão ficar amarelo). O trecho acima de 10 min é sempre o **Seu Muralha na 1ª carreira**, para quem venceu o Dinho.
- O Metrônomo ajuda pouco no típico (−0:30 a −1:30 no p90) e muito no lento (carreiras 2–3: mediana 10:01 → 8:00, carreiras acima de 10 min 19 → 3).

### 9.6 Revanche (critério 25): 120 jogadores por perfil, 2 carreiras
Rodar: `SIM_N_REV=120 fase4_sim.py revanche`.
| perfil | algoz | casos | venceu o algoz | quando (mediana) | o que deu errado |
|---|---|---|---|---|---|
| típico 5/s | Dinho | 65 | **62 (95%)** | 8:14 | 1 Dinho, 1 Brutão, 1 Dudu |
| típico 5/s | Seu Muralha | 18 | 4 (22%) | 17:16 | **perdeu para o Dinho 11** (no amarelo, antes de chegar ao Muralha), 2 Dudu, 1 Muralha |
| típico 4/s | Dinho | 64 | **53 (83%)** | 8:44 | 7 Dudu, 3 Dinho, 1 Brutão |
| típico 4/s | Seu Muralha | 19 | 6 (32%) | 19:17 | perdeu para o Dinho 10, 2 Muralha, 1 Dudu |
| **típico 5/s com a alavanca L1** | Seu Muralha | 18 | **16 (89%)** | 18:17 | 1 Dinho, 1 Muralha |
| **típico 4/s com a alavanca L1** | Seu Muralha | 19 | **15 (79%)** | 20:17 | 1 Dinho, 2 Muralha, 1 Dudu |
| cauteloso 5/s | Dinho / Muralha | 65 / 18 | 62 (95%) / 16 (89%) | 8:14 / 18:17 | |
| cauteloso 4/s | Dinho / Muralha | 64 / 19 | 60 (94%) / 15 (79%) | 9:14 / 20:17 | |
| lento 3/s | Dinho / Muralha | 60 / 18 | 49 (82%) / 8 (44%) | 10:14 / 22:48 | Muralha: perdeu para o Dinho 8 |
| cauteloso 3/s | Dinho / Muralha | 60 / 18 | 55 (92%) / 16 (89%) | 10:44 / 23:18 | |
| (Dudu e Brutão como algoz) | | 14 / 1 | 100% | 3:16 / 5:44 | |

- **Contra o algoz, esperar o verde funciona:** quando o robô chega ao algoz, vence 89–100% (o verde é ≥ 90% por construção).
- **O que derruba a revanche contra o Seu Muralha é o Dinho no caminho.** O robô típico enfrenta o Dinho no amarelo (40–60%) e perde ~55% das vezes antes de chegar ao Muralha. Por isso proponho a **alavanca L1** (seção 11.1): na carreira da revanche, a linha "ESPERE FICAR VERDE" aparece também contra quem vem **antes** do algoz na escada. Com ela, a revanche contra o Muralha sobe para **79–89%** (de 5 de 17 na Fase 3).

### 9.7 Metas: o que fecha e o que não fecha (honesto)
| Critério | Resultado | Situação |
|---|---|---|
| 6. 1ª derrota típica compra algo | nós de 10 nos dois ramos; a derrota no Dinho (40) compra os dois | **fecha** |
| 7. Cinturão compra ≤ ~50% | 750 / 3.175 = 24% (33% com a torcida) | **fecha** |
| 8. Árvore entre a 5ª e a 8ª carreira | típico 6 (5–7 / 5–8), lento 6–7, cauteloso 5 | **fecha** |
| 12. Metrônomo 1 ≤ 2 vitórias | $80 ≤ $200 | **fecha** |
| 15. ≤ 1,5/s e clicar ≥ 2,5× | 1,43/s; 3,8× (4/s), 4,5× (5/s); lento 3,1× | **fecha** |
| 22. 1ª carreira termina em derrota em 10–15 min | mediana 11:44 (5/s), 13:44 (4/s); lento 15:14 | **fecha** (59% perdem no Dinho; 16% fazem cinturão; 16% perdem no Muralha; 9% no Dudu) |
| 23a. Cinturão entre a 2ª e a 4ª carreira (mediana) | típico **2** (p90 3–4); lento 3 | **fecha** |
| 23b. Nunca cinturão na 1ª carreira do típico antes de 40 min | **5 de 32 (16%)** fazem cinturão na 1ª, aos 23–27 min | **não fecha** (ver abaixo) |
| 24. Tempo morto ≤ 10 min nas carreiras 1–4 | carreiras 2–4: p90 ≤ 7:30 (4–5/s). Carreira 1: mediana 5–6 min, mas **p90 11:01 (5/s) e 12:32 (4/s)**: ~1/3 das 1ªs carreiras passam de 10 min | **fecha nas carreiras 2–4; não fecha na 1ª para quem vence o Dinho** |
| 25. Revanche ≥ 80%; Muralha ≥ 60% | Dinho 95% (5/s), 83% (4/s). Muralha: 22–32% sem L1; **79–89% com L1** | **fecha com a alavanca L1**; sem ela, só o Dinho |
| 26. Protótipo em ~20 min (até 25) | 20:58 (5/s) e 23:28 (4/s) na mediana; ver 9.8 | **fecha no caminho típico (derrota no Dinho)** |

**Por que 23b e 24 não fecham juntos na 1ª carreira (é aritmética, não ajuste fino):** quem vence o Dinho aos ~12 min só sai do vermelho do Muralha quando ele fica amarelo, e o robô luta no 1º amarelo e vence ~45% das vezes. Se o vermelho dura no máximo 10 min, o cinturão pode sair aos 12 + 10 = ~22 min. Para "nunca antes de 40 min", o vermelho teria de durar ~28 min. As duas metas pedem coisas opostas para o mesmo jogador (o ~1/3 que vence o Dinho na 1ª carreira). A Fase 3 media só o robô que não lê a prévia (0 cinturão antes de 40 min, mas 30–35 min no vermelho).

Escolhas possíveis (1ª carreira, robô típico; 48 jogadores, só a 1ª carreira):
| opção | vermelho p90 5/s | 4/s | cinturão na 1ª antes de 40 min (lê a prévia) | idem, robô da Fase 3 |
|---|---|---|---|---|
| Fase 3 como está (Dinho $400) | 17:02 | 18:33 | 12% (29–33 min) | 0% |
| Dinho $600 | 12:32 | 14:32 | 12% (25–29 min) | 12% (35 min) |
| **Dinho $800 (proposta)** | **11:01** | **12:32** | 12% (23–27 min) | 15% (33 min) |
| Dinho $800 + `opp_tank.endurance` 430K | 10:01 | 11:02 | 12% (22–25 min) | 12% (31 min) |
| Dinho $1.000 + `opp_tank.endurance` 420K | 9:31 | 10:32 | 21% (22–25 min) | 25% (30 min) |
| Dinho $800 + jogador aposenta após 10 min no vermelho | 10:00 | 10:00 | 0% | — |

Recomendação do Designer: **Dinho $800 e o Muralha como está**. O tempo morto da 1ª carreira cai de 17 para 11 min (p90) com uma mudança só, de dinheiro, e as carreiras 2–4 fecham. O cinturão "cedo" na 1ª carreira é sempre uma luta de ~45% ganha no amarelo (a prévia avisou), em 1 de cada 8 jogadores. A **aposentadoria** passa a ser a saída honesta para quem empaca: com o Dinho vencido, aposentar rende 200 de Legado (4 nós e sobra 125), contra 100 se perder no Muralha. Quem decide é o Diretor (decisão 3 da seção 13).

### 9.8 Protótipo (critério 26)
Tempo somado = 1ª carreira até a derrota + 1 min (tela de fim, árvore, cartão) + 2ª carreira até vencer o algoz.
| caminho | quanto acontece | 5 cliques/s | 4 cliques/s | 3 cliques/s |
|---|---|---|---|---|
| perde no Dinho → jab + bolsa → vence o Dinho no verde | ~59% das 1ªs carreiras | **20:58** | **23:28–23:58** | 26:30–26:58 |
| perde no Dudu → vence o Dudu | ~9% | 7:29 | 8:29 | 9:28 |
| perde no Muralha → 4 nós → vence o Muralha (com L1) | ~16% | 42:42 | 48:13 | 54:45 |
| faz o cinturão na 1ª (não há algoz) | ~16% | — (itens 3 a 5 ficam para a carreira seguinte) | | |

Itens 1 e 2 (número em todo clique, gerador comprado) acontecem no 1º minuto. Item 3 (perde e a tela aponta o atributo e o verde): 11:44 / 13:44. Item 4 (nó): na tela de fim. Item 5: 2ª carreira. Item 6 (próxima meta): ao fim da 2ª carreira há sempre nó comprável ou a ≤ 1 carreira (Memória muscular 30 / prévia detalhada 25 com o Legado que sobra + o da 2ª carreira).
O QA a 4–5 cliques/s deve cair no caminho do Dinho (o mais provável). Se cair no do Muralha, o protótipo passa de 25 min; isso é dito no relatório ao dono.

## 10. Contrato de dados (`data/`, JSON)

Regras da Fase 2/3 valem (campo faltando ou fora da faixa → padrão + `push_warning`; id vazio ou repetido ignorado; ordem das listas = ordem na tela).

### `data/skill_tree.json` (novo)
```json
{
  "branches": [
    { "id": "body",   "name": "CORPO" },
    { "id": "career", "name": "CARREIRA" }
  ],
  "nodes": [
    { "id": "body_jab", "branch": "body", "requires": "", "cost": 10,
      "effect": { "type": "click_bonus", "value": 1.0 },
      "name": "Jab de base", "description": "...", "effect_text": "+{pct}% TREINO POR CLIQUE", "icon": "skill_body_jab" },
    { "id": "body_muscle_memory", "branch": "body", "requires": "body_jab", "cost": 30,
      "effect": { "type": "metronome_start", "value": 1 },
      "name": "Memória muscular", "description": "...", "effect_text": "COMEÇA COM O METRÔNOMO NO NÍVEL {n}", "icon": "skill_body_muscle_memory" },
    { "id": "body_heavy_hands", "branch": "body", "requires": "body_muscle_memory", "cost": 500,
      "effect": { "type": "click_bonus", "value": 0.5 }, "...": "" },
    { "id": "body_crew", "branch": "body", "requires": "body_jab", "cost": 150,
      "effect": { "type": "passive_bonus", "value": 0.5 }, "effect_text": "+{pct}% TREINO/S DA EQUIPE" },
    { "id": "body_crew_2", "branch": "body", "requires": "body_crew", "cost": 900,
      "effect": { "type": "passive_bonus", "value": 0.5 } },
    { "id": "career_purse", "branch": "career", "requires": "", "cost": 10,
      "effect": { "type": "money_bonus", "value": 0.5 }, "effect_text": "+{pct}% DINHEIRO POR VITÓRIA" },
    { "id": "career_scouting", "branch": "career", "requires": "career_purse", "cost": 25,
      "effect": { "type": "preview_percent", "value": 1 }, "effect_text": "A PRÉVIA MOSTRA A CHANCE EM %" },
    { "id": "career_purse_2", "branch": "career", "requires": "career_scouting", "cost": 500,
      "effect": { "type": "money_bonus", "value": 0.5 } },
    { "id": "career_crowd", "branch": "career", "requires": "career_purse", "cost": 250,
      "effect": { "type": "fame_bonus", "value": 0.5 }, "effect_text": "+{pct}% FAMA POR VITÓRIA" },
    { "id": "career_good_loser", "branch": "career", "requires": "career_crowd", "cost": 800,
      "effect": { "type": "defeat_share_bonus", "value": 0.25 }, "effect_text": "A DERROTA LEVA +{pct}% DO LEGADO EM JOGO" }
  ]
}
```
| Campo | Tipo / faixa | Padrão | Validação |
|---|---|---|---|
| `id` | texto, único | — | vazio ou repetido: nó ignorado |
| `branch` | `body` ou `career` | — | outro: nó ignorado |
| `requires` | id de nó **do mesmo ramo** ou `""` | `""` | inexistente, de outro ramo ou ciclo: vira `""` com aviso |
| `cost` | inteiro ≥ 1 | — | < 1: nó ignorado |
| `effect.type` | `click_bonus`, `passive_bonus`, `money_bonus`, `fame_bonus`, `defeat_share_bonus`, `metronome_start`, `preview_percent` | — | desconhecido: nó ignorado |
| `effect.value` | número ≥ 0 (bônus em fração: 0.5 = +50%) | — | `metronome_start` recortado em 0..nº de níveis; `defeat_share_bonus` total recortado para manter `< retire_share` |
| `name`, `description`, `effect_text`, `icon` | texto | id / "" | `{pct}` = `round(100 × value)`, `{n}` = `value` |

### `data/shop.json` → bloco novo `metronome`
```json
"metronome": {
  "id": "metronome",
  "name": "Metrônomo", "description": "...", "appears_as": "Metrônomo de feira na prateleira, pêndulo no andamento",
  "levels": [
    { "id": "metronome_l1", "cost": 80,  "interval": 2.0 },
    { "id": "metronome_l2", "cost": 150, "interval": 1.0 },
    { "id": "metronome_l3", "cost": 300, "interval": 0.7 }
  ]
}
```
Validação: `cost` > 0; `interval` em [0.667, 60] (o mínimo garante ≤ 1,5 soco/s mesmo com dado errado); níveis com intervalo **decrescente** (senão, nível ignorado com aviso). Lista vazia ou bloco ausente: sem Metrônomo na LOJA (e `metronome_start` não faz nada).

### `data/career.json`
`{ "legacy_per_fame": 2.0, "belt_legacy_bonus": 100, "defeat_share": 0.5, "retire_share": 1.0, "retire_belt_bonus_share": 0.5 }`

### `data/opponents.json`
Só `opp_fast.prize_money`: 400 → **800**. Nada mais.

### `data/ui_texts.json` (chaves novas, textos finais do Roteirista)
| chave | placeholders | rascunho / intenção |
|---|---|---|
| `tree_button` | — | "ÁRVORE" (botão da tela de fim) |
| `tree_title` | — | "O QUE O VELHO TE ENSINOU" |
| `tree_legacy` | `{n}` | "LEGADO: {n}" |
| `tree_branch_body` / `tree_branch_career` | — | "CORPO" / "CARREIRA" |
| `tree_buy` | `{n}` | "{n} DE LEGADO" (no nó comprável) |
| `tree_owned` | — | "APRENDIDO" |
| `tree_missing` | `{n}` | "FALTAM {n}" |
| `tree_locked` | `{nome}` | "PEDE: {nome}" |
| `tree_new_career` | — | "NOVA CARREIRA" (na árvore) |
| `career_card_title` | `{n}` | "CARREIRA {n} — O QUE VOCÊ TROUXE:" |
| `legacy_nodes_label` | `{n}` | "LEGADO: {n} NÓS" |
| `revenge_mark` | — | "VOCÊ PERDEU PRA ELE" |
| `victory_revenge` | `{nome}` | "REVANCHE!" (+ linha opcional com o nome) |
| `tip_wait_green` | — | "VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE" |
| `preview_wait_green` | — | "ESPERE FICAR VERDE" |
| `preview_percent` | `{n}` | "{n}%" (ao lado do rótulo) |
| `stake_bonus` | `{n}` | "(+{n}%)" |
| `stake_lose_pct` | `{n}` | "PERDER ENCERRA A CARREIRA ({n}% DO LEGADO)" (usado quando o efetivo ≠ 50%) |
| `shop_metronome_effect` | `{s}` | "1 SOCO A CADA {s} S" (`{s}` com 1 casa, ponto decimal como o NumberFormat) |
| `victory_gain` (muda) | | "+${n}   +{n} FAMA   +{n} LEGADO EM JOGO" |
| `legacy_note` | | **sai da tela de fim** (a chave pode ficar sem uso) |

## 11. Pedidos e alavancas

### 11.1 Alavanca L1 (proposta, precisa do "sim" do Diretor)
Na carreira em que existe `revenge_opponent`, `preview_wait_green` aparece também contra **todo adversário antes do algoz na escada** enquanto não estiver verde (mesma regra: rótulo da tática selecionada < FÁCIL). Só texto na prévia: o jogador pode lutar do mesmo jeito. Efeito medido: revanche contra o Muralha **22–32% → 79–89%**; contra o Dinho não muda (ele já é o 1º depois do Dudu e do Brutão, que ficam verdes rápido). Custo: uma condição a mais na prévia. Sem ela, o critério 25 fecha só para o Dinho.

### 11.2 Alavancas que restam (todas em `data/`)
| alavanca | campo | efeito |
|---|---|---|
| Prêmio do Dinho | `opp_fast.prize_money` (800) | mais = menos tempo morto na 1ª carreira, cinturão mais cedo para quem passa do Dinho (tabela 9.7) |
| Resistência do Muralha | `opp_tank.endurance` (490K) | menos = vermelho mais curto em todas as carreiras e cinturão mais cedo; mais = o contrário |
| Preço dos nós de 500–900 | `skill_tree.json` `cost` | sobe/desce a carreira em que a árvore fecha (hoje 6) sem mexer nas primeiras |
| `career_crowd` | `effect.value` (0.5) | é o nó que acelera o Legado (R2); 0.25 empurra a árvore ~1 carreira |
| Ritmo/custo do Metrônomo | `metronome.levels` | o lento é quem mais sente (9.5) |
| `body_jab` | `effect.value` (1.0) | é o que faz a 2ª carreira ser ~20% mais rápida até o Dinho (protótipo) |

### 11.3 Para o UI/UX
Árvore no padrão das janelas (prévia/fim): duas colunas, a bifurcação desenhada como "Y" logo abaixo do 1º nó. Auto-soco: número menor, sem tremida, som mais baixo, jab do rig com a luva atual. Metrônomo como prop na prateleira da garagem (oscila no andamento; parado no nível 0, sem prop). Revanche e "ESPERE FICAR VERDE" na prévia e no bloco "PRÓXIMA". Cartão de início ≤ 1,8 s. Tudo passa pela skill `alinhamento-ui`.

## 12. Testes automáticos que este design pede
| Teste | Confere |
|---|---|
| Compra de nó | desconta o custo exato; recusa sem saldo e sem o anterior; Legado nunca negativo; salva na hora |
| Árvore fechada na carreira | `comprar_no` recusa sem `ending` pendente |
| Efeito de cada nó (critério 11) | para cada nó, num save isolado: comprar → NOVA CARREIRA → o valor prometido muda (por_clique ×2; produção ×1,5; prêmio ×1,5; fama ×1,5 arredondada; derrota 75%; `metronome_level` 1; prévia com %); **antes** do NOVA CARREIRA nada muda; salvar/recarregar não duplica |
| Aditivo | `body_jab` + `body_heavy_hands` = ×2,5 (não ×3); `body_crew` + `body_crew_2` = ×2 |
| Metrônomo, caminho do clique (13) | 1.000 auto-socos: taxa de crítico = `crit_chance` (±3 pontos); com a lona o treino por soco dobra; vai para o atributo do foco |
| Metrônomo fora da luta (16) | 10 lutas e a tela de fim: 0 auto-socos, 0 treino |
| Metrônomo na carreira (17) | zera em NOVA CARREIRA; com a Memória muscular começa em 1 e a LOJA oferece o 2 |
| Ritmo | com dado de intervalo 0.1 no JSON de teste, recorta para ≤ 1,5/s |
| Revanche (18, 19) | derrota marca o algoz; aposentadoria limpa; vencer o algoz limpa e devolve `revenge: true` uma vez; reabrir com a luta pendente não mostra duas vezes |
| Dica do verde (20, 21) | derrota `missing` → `tip_wait_green`; `luck` → não; prévia contra o algoz não verde → `preview_wait_green`; verde → não |
| Migração (28) | v3 → v4: Legado ×10, `ending` ×10, `skill_nodes` [], `revenge_opponent` "", `metronome_level` 0, carreira igual; v0 → v4 em cadeia |
| Dados (30) | mudar `cost`, `effect.value`, `interval` num JSON de teste muda o jogo; tipo desconhecido ignora o nó com aviso |
| Risco honesto e guarda do save real | continuam passando |

## 13. Decisões para o Diretor / dono
1. **Reescala do Legado ×10** com migração (seção 2). Proporções iguais às da Fase 3.
2. **Dinho paga $800** (era $400). Única mudança de número da Fase 3.
3. **Critérios 23b e 24 na 1ª carreira não fecham juntos** (9.7). Recomendo aceitar o vermelho de ~11–12,5 min (p90) para o ~1/3 que vence o Dinho na 1ª carreira, com a aposentadoria como saída. Alternativas na tabela de 9.7.
4. **Alavanca L1** (11.1): "ESPERE FICAR VERDE" também antes do algoz. Sem ela, a revanche contra o Seu Muralha fica em 22–32%.
5. O robô típico desta fase **lê o destaque da prévia** (a revisão da Fase 3 pediu um típico mais humano). O robô da Fase 3 continua nas tabelas para comparar.

## 14. Ids novos (contrato)
- Nós: `body_jab`, `body_muscle_memory`, `body_heavy_hands`, `body_crew`, `body_crew_2`, `career_purse`, `career_scouting`, `career_purse_2`, `career_crowd`, `career_good_loser`. Ramos: `body`, `career`.
- Metrônomo: `metronome` com `metronome_l1`, `metronome_l2`, `metronome_l3`.
- Tipos de efeito: `click_bonus`, `passive_bonus`, `money_bonus`, `fame_bonus`, `defeat_share_bonus`, `metronome_start`, `preview_percent`.
- Save: `permanent.skill_nodes`, `permanent.revenge_opponent`, `career.metronome_level`; versão 4, `_migrar_3_para_4`.
- Sinal: `auto_socou` (ou `clicou` com `auto = true`).
- Arquivo novo: `data/skill_tree.json`.

## Resumo
- **Árvore:** 10 nós, Corpo e Carreira, uma bifurcação logo no 1º nó de cada ramo. Preços 10 / 30 / 150 / 500 / 900 (Corpo) e 10 / 25 / 250 / 500 / 800 (Carreira), total 3.175 em Legado reescalado ×10. Efeitos aditivos: clique +100% (+50%), passivo +50% (+50%), dinheiro +50% (+50%), fama +50%, derrota 75%, Memória muscular (Metrônomo 1 no minuto 0) e prévia com %. Compra só pela tela de fim, 1 clique, sem reembolso, vale na carreira seguinte.
- **Metrônomo:** $80 / $150 / $300, um soco a cada 2.0 / 1.0 / 0.7 s (máx. 1,43/s), pelo caminho do clique (aparelho em foco × luva × árvore, mesmo crítico), sem tremida, só com o alvo livre, zera a cada carreira. Clicar rende 3,8–4,5× mais.
- **Revanche e verde:** algoz em `permanent.revenge_opponent`; "VOCÊ PERDEU PRA ELE" no HUD e na prévia; "REVANCHE!" uma vez; dica do verde em toda derrota que não é azar; "ESPERE FICAR VERDE" contra o algoz (e, com L1, antes dele).
- **Save v4:** `skill_nodes`, `revenge_opponent`, `metronome_level`; migração v3 → v4 multiplica o Legado (e o `ending`) por 10.
- **Fase 3 muda só:** `legacy_per_fame` 2.0, `belt_legacy_bonus` 100, Dinho $800.
- **Números-chave (típico 4–5/s):** 1ª derrota 11:44–13:44; cinturão na 2ª carreira (mediana); árvore fecha na 6ª; revanche Dinho 83–95%, Muralha 79–89% com L1 (22–32% sem); tempo morto ≤ 7:30 nas carreiras 2–4, **11–12,5 min (p90) na 1ª** para quem vence o Dinho; protótipo em 21–24 min. Não fecham: 23b (16% fazem cinturão na 1ª, aos 23–27 min) e o tempo morto da 1ª carreira para ~1/3 dos jogadores. São opostos por construção (9.7).

## Decisões do Diretor (2026-11-06)
**D1. 23b x tempo morto: a recomendação do Designer foi aceita, e os critérios foram revistos no escopo.**
- `data/opponents.json`: `opp_fast.prize_money` = **800** (era 400). Nenhum outro número de adversário muda: `opp_tank.endurance` continua **490K**.
- Critério 23b novo: cinturão na 1ª carreira do típico 4–5/s em **≤ 20%** dos casos e **nunca antes de 20:00**. Medido: 12–16%, aos 22–27 min. **Fecha.**
- Critério 24 novo: carreiras 2–4 com **p90 ≤ 10:00**; carreira 1 com **mediana ≤ 10:00** e **p90 ≤ 13:00**. Medido: carreira 1 com mediana de 5:00/6:00 e p90 de 11:01/12:32; carreiras 2–4 com p90 ≤ 7:30. **Fecha.**
- Nenhum texto ou regra nova de aposentadoria nesta fase.
- Se um ajuste futuro de `data/` puser a carreira 1 com p90 acima de 13:00 ou o cinturão na 1ª acima de 20%, o caso volta para o Diretor.

**D2. Alavanca L1: aprovada.** Regra para o Programador:
- Só vale quando `permanent.revenge_opponent` não está vazio **e** o algoz ainda não foi vencido nesta carreira.
- Mostra `preview_wait_green` na prévia (e no bloco "PRÓXIMA") contra o algoz **e** contra todo adversário com índice na escada **menor** que o do algoz, enquanto o rótulo da tática selecionada estiver abaixo de FÁCIL (chance < `risk.easy_min`).
- Contra quem vem depois do algoz, sem algoz, ou depois de vencer o algoz: a linha não aparece.
- É só texto: não bloqueia o LUTAR!, não muda cor, rótulo nem limiares.
- Teste novo (junto com o da dica do verde): algoz = `opp_tank`, prévia de `opp_fast` não verde → mostra; `opp_fast` verde → não mostra; sem algoz → não mostra.
- Meta (critério 25): revanche contra o Muralha **≥ 60%**, medida hoje em 79% (4/s) e 89% (5/s); contra o Dinho, 83–95%.
