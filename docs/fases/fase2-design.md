# Fase 2 — Treino na garagem: design

Dono: Designer de Jogo. Versão 1 (2026-11-05).
Base: `docs/fases/fase2-escopo.md` (24 critérios), `docs/visao.md`, `docs/roadmap.md`, `docs/arte/direcao-visual.md`, código da Fase 1 (`scripts/*.gd`, `data/config.json`).
Nomes e textos: `docs/fases/fase2-textos.md` (Roteirista). Os ids daqui são os mesmos de lá.
Simulação: `tools/sim/fase2_sim.py`.

Regra da fase (decisão do Diretor): **tudo na garagem custa Treino**. Cada ponto de treino ganho, por clique ou passivo, soma **ao mesmo tempo** no saldo de Treino e no atributo do aparelho em foco. Gastar saldo **nunca** reduz atributo.

---

## 1. Recursos: de onde vem, para onde vai

| Recurso | Tipo | Entra por | Sai por | Pode diminuir? |
|---|---|---|---|---|
| **Treino (saldo)** | float ≥ 0 | clique no alvo; renda passiva dos geradores | compra de gerador; compra de melhoria | sim, só ao comprar |
| **Força** (`strength`) | float ≥ 0 | todo treino ganho com foco no saco | nada | **nunca** |
| **Agilidade** (`agility`) | float ≥ 0 | todo treino ganho com foco na corda | nada | **nunca** |
| **Resistência** (`endurance`) | float ≥ 0 | todo treino ganho com foco na esteira | nada | **nunca** |

Invariante que o teste confere: `soma dos 3 atributos == treino total ganho` e `saldo == treino total ganho − total gasto`.
Na Fase 2 os atributos **não têm efeito** (o efeito é da Fase 3). Cada um mostra uma linha dizendo para que vai servir na luta (texto do Roteirista).

## 2. Foco

- Foco = **id do aparelho no centro**: `punching_bag`, `jump_rope` ou `treadmill`. Cada aparelho aponta para 1 atributo (tabela da seção 7).
- Começo da carreira: `punching_bag`.
- Trocar o foco: instantâneo, grátis, sem limite. O próximo clique e o próximo tick de passivo já vão para o novo atributo.
- O foco é guardado como **id do aparelho** (não do atributo) porque o aparelho da arte marcial da Fase 5 será um 4º foco que não é um atributo único. Só guardamos o id agora; nada da Fase 5 entra.

## 3. Clique

### Fórmula
```
mult_aparelho(a)  = produto de "multiplier" das melhorias já compradas do aparelho a   (1 se nenhuma)
por_clique        = base_training × mult_aparelho(foco)                                 (o "POR CLIQUE" da barra)
critico           = randf() < crit_chance                                               (um sorteio por clique)
ganho_do_clique   = por_clique × (crit_multiplier se critico, senão 1)
saldo            += ganho_do_clique
atributo[foco]   += ganho_do_clique
```

| Campo | Valor | Por quê |
|---|---|---|
| `base_training` | **1** | Começa pequeno; as melhorias levam a 3 e 15 por clique. Tudo inteiro: o número na tela é exatamente o que entra (critério 9). |
| `crit_chance` | **0.10** (10%) | 1 a cada ~10 cliques: aparece toda hora, dá ritmo. Em 200 cliques o QA espera ~20 (faixa aceitável 9–31, 99% de confiança). |
| `crit_multiplier` | **3** | Crítico que se nota (+12 vira +36), sem dominar a economia: o clique médio vale **1.2×** o normal. |

- O crítico **não depende de Agilidade** nesta fase (Agilidade dá crítico na luta, Fase 3).
- Valores possíveis por clique na Fase 2: normal **1 / 3 / 15**, crítico **3 / 9 / 45**. Sempre inteiros.
- Número flutuante: mostra `ganho_do_clique` (com o mesmo formatador do HUD) e o nome do atributo do foco. Crítico: 2x, `r3`, "!" e o texto do Roteirista (`crit_texts`).
- Só conta clique dentro da área do alvo central (48x90 px da base, saco em x≈336). Clique em aparelho lateral troca o foco e **não** gera treino.
- Sem limite de cliques por segundo e sem "clique automático" nesta fase.

## 4. Geradores (renda passiva)

### Fórmulas
```
custo(g, n)    = teto3( base_cost × growth^n )        n = quantas unidades de g o jogador já tem
producao_total = Σ  production(g) × quantidade(g)      (Treino/s; o "AUTO +x/s" e o "+x/S" do HUD)
a cada tick:   ganho = producao_total × delta
               saldo += ganho ;  atributo[foco] += ganho
```
- `teto3(x)`: arredonda **para cima** mantendo 3 dígitos significativos (abaixo de 1000: para cima no inteiro). Detalhe e motivo na seção 6.
- Produção é linear em `delta`: 1 tick de 1 s ou 144 ticks de 1/144 s dão o mesmo total (critério de 30 e 144 FPS). Não arredondar o ganho por tick.
- Não existe "treino/s de teste" na Fase 2: a renda passiva vem **só** dos geradores (com 0 geradores, o passivo é 0).
- Comprar **nunca** é bloqueado por espaço. Quantidade sem teto (o float aguenta: 200 vizinhos custam 1.45e21).

### Tabela
| id | Nome provisório (Roteirista) | `base_cost` | `growth` | `production` (Treino/s por unidade) | Pessoas desenhadas (`draw_thresholds`) |
|---|---|---|---|---|---|
| `neighbor_kid` | Vizinho da casa 12 | **60** | **1.25** | **1** | 1ª pessoa com 1, 2ª com 10, 3ª com 25 → máx. 3 |
| `retired_uncle` | Tio aposentado | **2500** | **1.25** | **8** | 1ª pessoa com 1, 2ª com 10 → máx. 2 |

`pessoas_desenhadas(g) = quantos valores de draw_thresholds são ≤ quantidade(g)`. A partir do último, o número continua subindo e a sala não muda (critério 17). Onde cada pessoa fica e como se move é com UI/Arte.

### Custos por unidade (já com `teto3`)
| n (já tem) | 0 | 1 | 2 | 3 | 4 | 5 | 9 | 10 | 14 | 19 | 20 | 50 | 100 | 200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Vizinho | 60 | 75 | 94 | 118 | 147 | 184 | 448 | 559 | 1.37K | 4.17K | 5.21K | 4.21M | 295B | 1.45e21 |
| Tio | 2.50K | 3.13K | 3.91K | 4.89K | 6.11K | 7.63K | 18.7K | 23.3K | 56.9K | 174K | 217K | 176M | 12.3T | 6.03e22 |

### Por que crescimento 1.25 e não 1.15
O escopo diz "~1.15, ajustável". Com 1.15 a simulação deu renda passiva **maior que o clique** antes dos 10 min (o jogador empilha 20+ vizinhos baratos) e o jogador impulsivo nunca juntava para o Tio. Com **1.25** o vizinho satura por volta de 12–17 unidades, o clique continua valendo mais aos 10 min e a curva fica mais apertada, como pede o pilar "não tão fácil". Continua ajustável em `data/`.

### Leitura dos números
- **Vizinho:** 60 de treino = ~10 s a 5 cliques/s. Primeira pessoa na sala quase na hora (o começo é generoso).
- **Tio:** 2500 é o "primeiro objetivo de verdade": ~40× o vizinho, produz 8×. Pior por treino gasto que o 1º vizinho, mas melhor que o 10º (custo 559 por +1/s contra 2500 por +8/s = 312 por +1/s). É aí que a escolha aparece.

## 5. Melhorias de aparelho

Uma linha por aparelho, com **2 níveis**, comprados em ordem (nível 2 só depois do 1). Cada nível **multiplica o treino por clique daquele aparelho**. Os multiplicadores do mesmo aparelho se **multiplicam** entre si (×3 depois ×5 = ×15).

**Não** afetam a renda passiva e **não** afetam os outros aparelhos. Motivo: o clique fica com um caminho de crescimento próprio, que o passivo não come, e quem quer treinar Agilidade com força total precisa investir também na corda.

| id | Aparelho | Nível | Nome provisório (Roteirista) | `cost` | `multiplier` | Por clique depois (normal / crítico) | `visual_level` |
|---|---|---|---|---|---|---|---|
| `bag_patch` | `punching_bag` | 1 | Fita nova no saco | **300** | **3** | 3 / 9 | **1** (saco remendado → saco novo) |
| `bag_sand` | `punching_bag` | 2 | Areia peneirada | **5000** | **5** | 15 / 45 | 1 (sem sprite novo) |
| `rope_laundry` | `jump_rope` | 1 | Corda sem nó | **300** | **3** | 3 / 9 | **1** (corda de varal → corda de verdade) |
| `rope_handles` | `jump_rope` | 2 | Cabos de cabo de vassoura | **5000** | **5** | 15 / 45 | 1 |
| `treadmill_oil` | `treadmill` | 1 | Óleo de cozinha na esteira | **300** | **3** | 3 / 9 | **1** (enferrujada → lubrificada) |
| `treadmill_belt` | `treadmill` | 2 | Correia emendada | **5000** | **5** | 15 / 45 | 1 |

- `sprite_do_aparelho = maior visual_level entre as melhorias compradas` (0 se nenhuma). São os 2 níveis visuais do escopo (0 e 1). O nível 2 é só numérico, como o escopo permite.
- Os 3 aparelhos custam igual: nenhum atributo é "o barato". A diferença de preço do mockup ($30/$45/$60) não vale.
- Antes de comprar, o item mostra o efeito, ex.: **"x3 POR CLIQUE NO SACO"**. Aviso ao Roteirista/UI: o "+25% FORÇA no saco" do `fase2-textos.md` era só exemplo; o número real é ×3 e ×5, vindo do campo `multiplier`.
- Linha completa: o item mostra "MÁXIMO" (texto do Roteirista) e não pode mais ser comprado.
- Por que ×3 e ×5: o escopo pede compras que se sintam, e sem elas o clique fica abaixo do passivo aos 10 min. ×2 e ×4 foram testados e deixaram o passivo maior que o clique aos 10 min.

## 6. Compra, saldo e formatação (resposta ao Programador)

### Regra de compra
```
EPS = 1e-9
pode_pagar(custo) = saldo >= custo × (1 − EPS)
comprar: se pode_pagar → saldo = max(0, saldo − custo); quantidade += 1 (ou nível += 1)
         senão → recusa, nada muda
```
O `EPS` evita o caso "saldo 59.9999999 não compra o item de 60" por erro de float. O `max(0, …)` garante que o saldo nunca fica negativo. Atributo nunca é tocado na compra.

### Custos sempre com 3 dígitos significativos (`teto3`)
```
teto3(x):
  se x <= 0: 0
  x = x × (1 − EPS)                       # 60.0000000001 vira 60, não 61
  se x < 1000: ceil(x)
  e = floor(log10(x)) − 2 ;  f = 10^e
  ceil(x / f) × f                          # 1364.24 → 1370 ; 4163.3 → 4170
```
- Vale para **custo de gerador**. Os custos de melhoria já são valores fixos com 3 dígitos em `data/`.
- O custo cobrado é o mesmo número que aparece na tela. A diferença para `base × growth^n` é no máximo +1% (e menos de 1 unidade abaixo de 1000).
- O teste automático do critério 18 confere `custo(n) == teto3(base × growth^n)` e, com folga de 1%, `custo(n) ≈ base × growth^n`.

### Decisão do formatador: **truncar** o que o jogador tem, nunca arredondar para cima
Pergunta do Programador: arredondar ou truncar? Mostrar "1.00M" sem ter 1M?
**Decisão: o saldo e os atributos são truncados (para baixo) a 3 dígitos. Nunca mostrar "1.00M" sem ter 1M.**

| Valor | Modo | Exemplo |
|---|---|---|
| Saldo de Treino, atributos | **TRUNCAR** | 999,600 → `999K` (não `1.00M`); 59.7 → `59`; 1,149.99 → `1.14K` |
| Custos (gerador e melhoria) | já são exatos com 3 dígitos (`teto3`) | 1370 → `1.37K` em qualquer modo |
| Treino/s, por clique, número flutuante | ARREDONDAR (o padrão atual) | na Fase 2 são inteiros, então ficam exatos |

Por que funciona: como o custo já é exato em 3 dígitos e o saldo é mostrado truncado, **"saldo na tela ≥ preço na tela" é exatamente "pode comprar"**. O jogador nunca vê "60" de saldo e um preço "60" em vermelho, nem o contrário. É a regra que pinta o preço de `r2`.

Implementação sugerida (o como é do Programador): `NumberFormat.fmt(valor, modo := ARREDONDAR)` com `modo = TRUNCAR` usando `floor(m × 10^casas + 1e-9)` (o `+1e-9` evita `1.15 × 100 = 114.999…` virar `1.14`). O resto do formatador (sufixos, científico ≥ 1e15, NaN, infinito) não muda. No modo TRUNCAR não existe o "subir de faixa" (999.99K fica `999K`).

### O que a tela mostra
| Lugar | Valor | Formato |
|---|---|---|
| HUD "TREINO" | saldo | TRUNCAR |
| HUD "+x/S" e barra "AUTO +x/S" | `producao_total` | ARREDONDAR |
| Barra "POR CLIQUE" | `por_clique` (sem crítico) | ARREDONDAR |
| Painel esquerdo | os 3 atributos | TRUNCAR |
| Painel direito | custo da próxima unidade/nível, quantidade, produção por unidade, efeito | custo exato; quantidade inteira |
| Número flutuante | `ganho_do_clique` | ARREDONDAR (inteiro) |

## 7. Contrato de dados (`data/`, JSON)

O Programador define o carregador. Eu sou dono dos **valores**. Regras gerais:
- Campo que falta, tem tipo errado ou fica fora da faixa: usa o **padrão desta tabela** e dá `push_warning` (igual ao `GameConfig` da Fase 1). Campo desconhecido: ignorado sem erro.
- Item com `id` vazio ou repetido: ignorado, com aviso.
- **Ordem das listas = ordem na tela** (painel de geradores, ordem dos níveis de melhoria).
- Ids são estáveis e em inglês. Nomes e textos vêm do Roteirista, nunca daqui.

### `data/training.json` (novo)
```json
{
	"click": {
		"base_training": 1,
		"crit_chance": 0.10,
		"crit_multiplier": 3
	},
	"default_focus": "punching_bag",
	"apparatus": [
		{
			"id": "punching_bag",
			"attribute": "strength",
			"upgrades": [
				{ "id": "bag_patch", "cost": 300, "multiplier": 3, "visual_level": 1 },
				{ "id": "bag_sand", "cost": 5000, "multiplier": 5, "visual_level": 1 }
			]
		},
		{
			"id": "jump_rope",
			"attribute": "agility",
			"upgrades": [
				{ "id": "rope_laundry", "cost": 300, "multiplier": 3, "visual_level": 1 },
				{ "id": "rope_handles", "cost": 5000, "multiplier": 5, "visual_level": 1 }
			]
		},
		{
			"id": "treadmill",
			"attribute": "endurance",
			"upgrades": [
				{ "id": "treadmill_oil", "cost": 300, "multiplier": 3, "visual_level": 1 },
				{ "id": "treadmill_belt", "cost": 5000, "multiplier": 5, "visual_level": 1 }
			]
		}
	]
}
```

| Campo | Tipo | Faixa válida | Padrão |
|---|---|---|---|
| `click.base_training` | número | > 0 e finito | 1 |
| `click.crit_chance` | número | 0 a 1 | 0.10 |
| `click.crit_multiplier` | número | ≥ 1 | 3 |
| `default_focus` | id de aparelho | um dos `apparatus[].id` | `punching_bag` |
| `apparatus[].id` | texto | não vazio, único | — |
| `apparatus[].attribute` | texto | `strength`, `agility` ou `endurance` | — (aparelho sem atributo válido é ignorado) |
| `upgrades[].id` | texto | não vazio, único no arquivo todo | — |
| `upgrades[].cost` | número | > 0 e finito | o da tabela da seção 5 |
| `upgrades[].multiplier` | número | ≥ 1 | o da tabela da seção 5 |
| `upgrades[].visual_level` | inteiro | 0 ou 1 (só existem 2 sprites por aparelho) | 0 |

Os 3 atributos são fixos nesta fase (`strength`, `agility`, `endurance`). As cores são da direção visual e ficam na UI.

### `data/generators.json` (novo)
```json
{
	"generators": [
		{ "id": "neighbor_kid", "base_cost": 60, "growth": 1.25, "production": 1, "draw_thresholds": [1, 10, 25] },
		{ "id": "retired_uncle", "base_cost": 2500, "growth": 1.25, "production": 8, "draw_thresholds": [1, 10] }
	]
}
```

| Campo | Tipo | Faixa válida | Padrão |
|---|---|---|---|
| `id` | texto | não vazio, único | — |
| `base_cost` | número | > 0 e finito | o da tabela da seção 4 |
| `growth` | número | 1.0 a 10 | 1.25 |
| `production` | número | ≥ 0 e finito | o da tabela da seção 4 |
| `draw_thresholds` | lista de inteiros | crescente, cada ≥ 1 | `[1]` |

Critério 20: mudar `base_cost` aqui e reabrir muda o preço, sem mexer em código.

### `data/config.json` (muda)
| Chave | Fase 1 | Fase 2 |
|---|---|---|
| `autosave_intervalo_segundos` | 30 | **30** (fica) |
| `ui_atualizacoes_por_segundo` | 10 | **10** (fica) |
| `multiplicador_debug` | 1000 | **1000** (fica; agora multiplica só o **saldo**, nunca atributo) |
| `treino_por_segundo_teste` | 1.0 | **sai** (o passivo vem só dos geradores) |
| `treino_botao_teste` | 1 | **sai** (o clique de verdade substitui) |
| `debug_unidades_gerador` | — | **10** (novo: o botão de depuração soma 10 unidades de cada gerador, de graça, para o critério 17 chegar a 200) |

Chave que saiu e ainda estiver no arquivo: ignorada sem erro.

## 8. Save v1 → v2

### Formato v2
```json
{
	"version": 2,
	"saved_at_unix": 1730000000,
	"state": {
		"career": {
			"training": 1234.5,
			"attributes": { "strength": 900.0, "agility": 200.0, "endurance": 134.5 },
			"focus": "punching_bag",
			"generators": { "neighbor_kid": 12, "retired_uncle": 3 },
			"upgrades": { "punching_bag": 2, "jump_rope": 0, "treadmill": 1 }
		}
	}
}
```
- Tudo da Fase 2 fica dentro de `career`, como o Diretor recomendou: na Fase 3 a carreira se perde e o que for permanente ficará fora dela. Aqui é **só agrupamento**, nenhum sistema de carreira.
- `upgrades` guarda o **nível comprado por aparelho** (0, 1 ou 2), não a lista de ids. Assim a ordem do `data/` manda e não existe save com "nível 2 sem nível 1".
- Produção total e custos **não** são salvos: são recalculados do `data/` ao carregar (por isso o critério 20 funciona).

### Leitura (validação de cada campo)
| Campo | Se faltar ou for inválido |
|---|---|
| `training` | 0. Negativo vira 0. NaN é ignorado (fica 0). |
| `attributes.<id>` | 0. Negativo vira 0. Id desconhecido é ignorado. |
| `focus` | `default_focus` do `data/`, se não for um aparelho existente |
| `generators.<id>` | 0. Não inteiro: `floor`. Negativo: 0. Id que não existe mais no `data/`: ignorado (e some no próximo save). |
| `upgrades.<id>` | 0. Recortado para `0..quantidade de níveis do aparelho`. |

### Migração `_migrar_1_para_2`
```
v1: { "version": 1, "saved_at_unix": T, "state": { "treino": X } }
v2: { "version": 2, "saved_at_unix": T, "state": { "career": {
        "training": X (validado: número finito ≥ 0, senão 0),
        "attributes": { "strength": 0, "agility": 0, "endurance": 0 },
        "focus": "punching_bag",
        "generators": {}, "upgrades": {} } } }
```
- O treino da v1 vira **saldo** (é o "Treino" que o jogador via na Fase 1). Os atributos começam em 0: na Fase 1 não havia foco, então nenhum atributo treinou.
- A cadeia continua: save v0 → v1 → v2 passa pelas duas migrações.
- Migrações em `SaveStore.MIGRACOES` (`1: "_migrar_1_para_2"`), `VERSAO_ATUAL = 2`.

## 9. Curva esperada (simulação)

`tools/sim/fase2_sim.py` lê `data/training.json` e `data/generators.json` quando existirem; senão usa os valores deste documento. Passo de 0,05 s, clique em valor esperado (crítico pela média 1.2×) e 30 rodadas com sorteio para ver a variação.

Jogadores simulados:
- **3, 5 e 8 cliques/s** o tempo todo.
- **Compra "melhor"**: escolhe a opção de menor `tempo até pagar + custo ÷ ganho em treino/s` e junta para ela.
- **Foco fixo**: sempre no saco. **Rodízio**: troca de aparelho a cada 60 s (cada melhoria vale 1/3 do tempo).
- **Compra "barato"** (jogador impulsivo): sempre o item mais barato. É o pior caso.

### Jogador principal: foco fixo, compra "melhor"
"clique/s" = treino por segundo vindo do clique (com crítico médio). "passivo/clique" = critério 19.

**5 cliques/s** — vizinho 0:10, fita no saco 0:53, areia 4:51, **tio 5:20**
| min | clique/s | passivo/s | passivo/clique | vizinhos | tios | níveis saco | treino total ganho |
|---|---|---|---|---|---|---|---|
| 1 | 18 | 2 | 11% | 2 | 0 | 1 | 499 |
| 3 | 18 | 7 | 39% | 7 | 0 | 1 | 3.42K |
| 5 | 90 | 8 | 9% | 8 | 0 | 2 | 7.05K |
| 8 | 90 | 44 | 49% | 12 | 4 | 2 | 28.4K |
| **10** | **90** | **62** | **69%** | 14 | 6 | 2 | 46.0K |
| 15 | 90 | 89 | 99% | 17 | 9 | 2 | 97.0K |

**3 cliques/s** — vizinho 0:17, fita 1:27, areia 7:05, **tio 7:45**
| min | clique/s | passivo/s | passivo/clique | vizinhos | tios | níveis saco | treino total |
|---|---|---|---|---|---|---|---|
| 1 | 3 | 2 | 56% | 2 | 0 | 0 | 286 |
| 3 | 10 | 9 | 83% | 9 | 0 | 1 | 1.99K |
| 5 | 10 | 9 | 83% | 9 | 0 | 1 | 4.37K |
| 8 | 54 | 17 | 31% | 9 | 1 | 2 | 10.4K |
| **10** | **54** | **35** | **65%** | 11 | 3 | 2 | 20.0K |
| 15 | 54 | 71 | 131% | 15 | 7 | 2 | 52.4K |

**8 cliques/s** — fita 0:31, vizinho 0:33, areia 3:16, **tio 3:36**
| min | clique/s | passivo/s | passivo/clique | vizinhos | tios | níveis saco | treino total |
|---|---|---|---|---|---|---|---|
| 1 | 28 | 6 | 21% | 6 | 0 | 1 | 1.23K |
| 3 | 28 | 6 | 21% | 6 | 0 | 1 | 5.41K |
| 5 | 144 | 44 | 31% | 12 | 4 | 2 | 23.4K |
| 8 | 144 | 71 | 49% | 15 | 7 | 2 | 60.0K |
| **10** | **144** | **89** | **62%** | 17 | 9 | 2 | 87.1K |
| 15 | 144 | 115 | 80% | 19 | 12 | 2 | 160K |

Variação com sorteio de crítico (30 rodadas, foco fixo): os marcos mudam no máximo ±15 s. A 4 cliques/s: vizinho 0:11–0:14, fita 0:58–1:06, tio **6:10–6:24**.

### Todos os casos contra as metas
| Jogador | 1º gerador (≤ 1:00) | 1ª melhoria (≤ 3:00) | Tio (5:00–8:00) | Passivo/clique aos 10 min (≥ ~30% e < 100%) |
|---|---|---|---|---|
| 3/s fixo melhor | 0:17 ok | 1:27 ok | 7:45 ok | 65% ok |
| **4/s fixo melhor** | 0:13 ok | 1:04 ok | **6:18 ok** | 74% ok |
| **5/s fixo melhor** | 0:10 ok | 0:53 ok | **5:20 ok** | 69% ok |
| 8/s fixo melhor | 0:33 ok | 0:31 ok | 3:36 **cedo** | 62% ok |
| 3/s rodízio melhor | 0:17 ok | 1:47 ok | 6:20 ok | 241% **passivo > clique** |
| 5/s rodízio melhor | 0:10 ok | 1:06 ok | 8:05 **no limite** | 48% ok |
| 8/s rodízio melhor | 0:06 ok | 0:35 ok | 6:33 ok | 43% ok |
| 3/s fixo barato | 0:17 ok | 3:05 **no limite** | 11:02 **tarde** | 157% **passivo > clique** |
| 5/s fixo barato | 0:10 ok | 2:20 ok | 8:28 **tarde** | 144% **passivo > clique** |
| 8/s fixo barato | 0:06 ok | 1:43 ok | 6:18 ok | 149% **passivo > clique** |

### "Clicar ainda rende mais que não clicar" (critério 19)
- Sem clicar nada começa: com 0 geradores o passivo é 0. O primeiro vizinho exige ~60 cliques.
- Aos 10 min, o jogador principal (5/s, fixo) ganha 90/s clicando e 62/s parado. **Se parar de clicar, perde 59% da renda.** A 3/s perde 61%; a 8/s, 62%.
- Aos 15 min o passivo empata com o clique (99% a 5/s). É o "clique perde relevância aos poucos" do PROMPT, e as melhorias da Fase 3 em diante retomam isso. Nesta fase o clique não tem mais nível depois do 2º.

### Onde a meta não fecha (honesto)
1. **8 cliques/s acha o tio aos 3:36**, antes dos 5 min. Não dá para o mesmo preço servir 3/s e 8/s: a renda do clique difere 2,7×. Calibrei para o "clique normal" do critério 13 (4–5/s). Quem clica muito rápido é premiado, e acho isso certo num jogo ativo.
2. **Jogador impulsivo** (compra sempre o mais barato): nunca junta para a "Areia peneirada" (5000) nem para o tio antes dos 8:28. Por isso o passivo dele passa o clique aos 10 min (144%). Ainda assim, clicar rende 41% da renda dele. Mitigações sem mexer em número: a UI mostra o tio e a areia com preço desde o começo (meta visível), e o "/s" do tio (+8/s) aparece antes da compra. Se o QA jogando cair nesse caso, o ajuste é subir `growth` do vizinho para 1.3.
3. **Rodízio a 3 cliques/s**: quem troca de foco o tempo todo e clica devagar demora a comprar as 3 areias (15 mil de treino) e fica com passivo > clique aos 10 min. É o custo de treinar os 3 atributos, e a Fase 3 é que vai pedir isso. Não corrijo agora para não deixar o foco fixo fácil demais.
4. A simulação é um modelo: clica sem parar e compra no instante certo. Gente de verdade para, lê e hesita, então os tempos reais tendem a ser **um pouco mais lentos** (bom para o tio, ruim para a 1ª melhoria, que tem folga de sobra: 0:53 contra 3:00).

## 10. Requisitos técnicos herdados da Fase 1 (Produtor, revisão aprovada em `docs/fases/fase1-revisao.md`)
1. **Stretch mode muda de `canvas_items` para `viewport`**, com escala inteira (`scale_mode = integer`, `aspect = keep`), como pede `docs/arte/direcao-visual.md` §1. Texto em **fonte pixel 5x7**. Conferir a legibilidade em 1280x720 (critério 2).
2. **F11 alterna tela cheia.** Janela maximizada em 1080p dá escala 2x com faixas; tela cheia dá 3x.
3. **Save v1 → v2 com teste automático** provando que um save da Fase 1 abre sem perder o treino (vira o saldo; seção 8). Critério 21.
4. **Botões de depuração escondidos** atrás de uma tecla e ativos **só em build de debug** (`OS.is_debug_build()`). Sugestão: F12 (não usar F11, que é tela cheia). A tecla vai no README (critério 1). Ações: ×`multiplicador_debug` no saldo, +`debug_unidades_gerador` de cada gerador, salvar, recarregar, apagar save.

## 11. Testes automáticos que este design pede (soma aos da Fase 1)
| Teste | Confere |
|---|---|
| Custo de gerador | `custo(n) == teto3(base × growth^n)` para n = 0, 1, 5, 20, 200; valores da tabela da seção 4 (60, 75, 94, 4.17K…) |
| `teto3` | 60 → 60; 93.75 → 94; 1364.24 → 1370; 60.0000000001 → 60; 999.2 → 1000 |
| Compra | desconta o custo exato; saldo nunca negativo; sem saldo, recusa e nada muda |
| Gasto não mexe em atributo | atributos iguais antes e depois de 10 compras |
| Clique | sem crítico (chance 0): ganho = `base × mult`; com chance 1: ganho = `base × mult × 3`; o valor emitido = o que entrou no saldo e no atributo |
| Multiplicadores | 0 → 1, `bag_patch` → 3, + `bag_sand` → 15; melhoria do saco não muda o clique da corda |
| Crítico estatístico | com RNG de semente fixa, 10.000 cliques a 10% → entre 9% e 11% |
| Passivo vai para o foco | só o atributo do foco sobe; trocar o foco desvia o próximo tick |
| FPS | 30 ticks de 1/30 s e 144 ticks de 1/144 s dão o mesmo total (tolerância 1e-9 relativa) |
| Formatador TRUNCAR | 999,600 → `999K`; 59.7 → `59`; 1150 → `1.15K`; 1149.99 → `1.14K`; ARREDONDAR continua igual à Fase 1 |
| Save v2 | salvar e carregar devolve saldo, atributos, foco, geradores e níveis |
| Migração | v1 `{"treino": 42}` → saldo 42, atributos 0, foco `punching_bag`; v0 também chega na v2 |
| Dados | `base_cost` alterado num `generators.json` de teste muda o custo; campo inválido usa o padrão com aviso |

---

## Resumo
- **Clique:** `1 × mult do aparelho em foco`; crítico **10%** com **×3**. Por clique vai de 1 → 3 → 15 (crítico 45). Tudo inteiro.
- **Geradores:** Vizinho da casa 12 (`neighbor_kid`) **60**, ×1.25, **+1/s**; Tio aposentado (`retired_uncle`) **2500**, ×1.25, **+8/s**. Custo `teto3(base × 1.25^n)`.
- **Melhorias:** por aparelho, nível 1 **300 → ×3** (troca o sprite) e nível 2 **5000 → ×5**. Valem só para o clique daquele aparelho e se multiplicam.
- **Formatador:** saldo e atributos **truncam** (nunca "1.00M" sem ter 1M); custos já são exatos em 3 dígitos. Assim "saldo na tela ≥ preço" é o mesmo que "pode comprar".
- **Save v2:** tudo em `state.career` (saldo, atributos, foco, geradores, nível por aparelho). O `treino` da v1 vira o saldo.
- **Simulação (5 cliques/s, foco fixo):** vizinho 0:10, 1ª melhoria 0:53, tio 5:20; aos 10 min clique 90/s e passivo 62/s (69%). As metas fecham para 3–5 cliques/s. Não fecham: 8 cliques/s acha o tio cedo (3:36), e o jogador impulsivo e o de rodízio lento ficam com passivo maior que o clique aos 10 min.
