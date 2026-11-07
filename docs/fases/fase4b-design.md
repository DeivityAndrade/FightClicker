# Fase 4b — Aparelhos que chegam + modo assistido no Shift: design

Dono: Designer de Jogo. Versão 1 (2026-11-06).
Base: `docs/fases/fase4b-escopo.md` (inclusive **"Respostas do dono"**, que prevalecem), `fase4-design.md` (metas, tempo morto, revanche, árvore, Metrônomo, D1 e D2), `fase3-design.md`, `fase2-design.md`, `data/*.json` e `scripts/` (contrato atual: `game_state.gd`, `save_store.gd`, `training_data.gd`).
Simulação: `tools/sim/fase4b_sim.py` (novo; importa `fase4_sim.py`, `fase3_sim.py` e `fase2_sim.py`). Os valores deste documento estão no bloco `PROPOSTA_4B` do simulador. Quando o Programador puser os campos em `data/training.json`, o simulador passa a ler de lá.
O Designer **não alterou** nada em `data/` nem em `scripts/`. A seção 7 lista exatamente o que muda nos JSON.

**Decisões do dono aplicadas aqui**
1. Ordem: **saco → esteira → corda**.
2. Os aparelhos **zeram a cada carreira**. Só a árvore é permanente.
3. Modo assistido **só enquanto o Shift estiver pressionado**. Não liga nem desliga, não existe preferência salva em `permanent` e não existe indicador de "ligado". Há uma dica fixa ("SEGURE SHIFT: TREINO ASSISTIDO"), um indicador **enquanto ele está socando** e, para quem só usa mouse, um botão de **segurar**.

**O que não muda:** adversários, limiares de risco, motor da luta, motivo da derrota, árvore, Metrônomo, preços da garagem, Prof. Nelson, luvas e Legado. Nada da Fase 5 ou posterior entra.

---

## 1. Recursos: de onde vem, para onde vai (o que muda)

| Recurso | Bloco do save | Entra por | Sai por | Na tela |
|---|---|---|---|---|
| **Aparelhos montados** (`apparatus_owned`) | `career` | compra com Treino na aba TREINO (o saco já vem montado) | zera em NOVA CARREIRA (volta a ser só o saco) | sala (aparelho ou marca de fita), botões de foco, aba TREINO |
| Treino (saldo) | `career` | clique, geradores, auto-soco (Metrônomo **ou** assistido) | garagem: geradores, melhorias e **agora os 2 aparelhos** | como antes |
| **Assistido** (Shift pressionado) | nenhum (não vai para o save) | tecla Shift ou botão de segurar | soltar, Metrônomo ≥ 1, luta, janela aberta | indicador perto do foco enquanto soca |

O tempo morto (Fase 4 §9.2) **não muda**: ele olha os preços da LOJA, e os aparelhos custam Treino.

## 2. Aparelhos que chegam

### 2.1 Tabela
| Aparelho | id do aparelho | id do desbloqueio | Preço (Treino) | Pede | Atributo | Plaquinha (exemplo) |
|---|---|---|---|---|---|---|
| Saco remendado | `punching_bag` | — (já vem montado) | — | — | Força | — |
| Esteira enferrujada | `treadmill` | **`unlock_treadmill`** | **500** | — | Resistência | "ESTEIRA — 500 TREINO" |
| Corda de varal | `jump_rope` | **`unlock_jump_rope`** | **1.500** (tela: 1.5K) | `treadmill` | Agilidade | "CORDA — 1.5K TREINO" |

Total por carreira: **2.000 de Treino**. Na 2ª carreira (com o Jab), isso é ~1 min de clique.

**Por que 500 e 1.500** (testei 500/1.500, 500/1.800, 500/2.000, 600/1.500, 750/1.500, 750/2.000, 750/3.000 e 1.000/2.500; ver 9.2):
- A **esteira a 500** sai entre a fita (300) e o Dudu: 1:19 (5/s), 1:37 (4/s) e 2:06 (3/s). Com 600 ou 750, o Dudu do 5/s atrasa uma janela de 30 s (3:13 → 3:44) sem ganho nenhum.
- A **corda a 1.500** sai logo depois da areia: 4:36 (5/s), 5:34 (4/s) e 6:26 (3/s). Fica sempre antes do Brutão e custa a metade do tio (2.500). Com 2.000, o Dinho do 5/s atrasa mais 30 s.
- O atraso da curva fica **≤ 1 min** em todos os perfis (9.2).

### 2.2 Regras (para o Programador)
```
montado(ap)       = ap em career.apparatus_owned  (aparelho sem "unlock" está sempre montado)
desbloqueio(ap)   = training.json → apparatus[ap].unlock   ({} se não tem)
pedido_ok(ap)     = unlock.requires == "" ou montado(unlock.requires)
pode_comprar(ap)  = não montado(ap) e pedido_ok(ap) e treino ≥ unlock.cost e não acoes_bloqueadas()
comprar(ap):        treino −= unlock.cost ; apparatus_owned.append(ap) ; foco = ap ; salvar() na hora
```
- **Estado de cada aparelho** (para a sala, o botão de foco e a linha da aba):

| estado | condição | botão de foco / linha da aba |
|---|---|---|
| `owned` | montado | normal; a linha da aba mostra as melhorias dele |
| `buyable` | não montado, `pedido_ok`, Treino suficiente | silhueta + cadeado + preço em destaque; COMPRAR aceso |
| `missing` | não montado, `pedido_ok`, Treino insuficiente | silhueta + cadeado + preço apagado; COMPRAR apagado (sem aviso de erro) |
| `locked` | não montado e falta o aparelho pedido | silhueta + cadeado + "DEPOIS DA ESTEIRA" no lugar do preço; sem COMPRAR |

- **A compra:** 1 clique em COMPRAR na seção MELHORIAS da aba TREINO. Desconta o preço exato, nunca deixa o saldo negativo e **não mexe em atributo nenhum** (`_gastar` só tira do saldo). Recusa sem Treino, sem o anterior, durante a luta ou com a tela de fim. Quando recusa, não muda nada.
- **Depois da compra:** foco no aparelho novo (`foco_mudou`), sinal novo `aparelho_comprado(aparelho_id)` para a UI fazer a chegada, `economia_mudou` e **save imediato** (critério 14).
- **Foco:** `definir_foco(ap)` **recusa** aparelho não montado (retorna false). O teclado e os atalhos pulam os trancados.
- **Melhorias:** `proxima_melhoria(ap)` devolve `{}` e `pode_comprar_melhoria(ap)` devolve false para aparelho não montado. A linha da aba só mostra as melhorias depois da compra.
- **Clique na marca do chão ou no botão de foco trancado:** não chama `clicar()` nem `definir_foco()`. Só abre a aba TREINO e pisca a linha (trabalho da UI).
- **Atributo de aparelho trancado:** continua valendo na luta pelos 10% gerais (`general_share`). Isso não muda.
- **NOVA CARREIRA:** `apparatus_owned` = aparelhos sem `unlock` (hoje só `["punching_bag"]`) e `foco = default_focus`.

### 2.3 Ordem na tela
A ordem de compra vem do campo `requires`, não da posição na lista. **Na implementação, `training.json` passou para a ordem saco, esteira, corda** (a mesma da compra), e a fileira de foco e as teclas 1/2/3 seguem esse array (ver `fase4b-api.md`). Isso não mexe em lógica nem em número.

## 3. Sala, foco e aba (o que a UI recebe)
- **Marca no chão:** para todo aparelho com estado ≠ `owned`, a sala mostra a marca de fita crepe no lugar dele, com a plaquinha `floor_mark_price` ("{nome} — {n} TREINO"). Para o `locked`, a plaquinha usa `floor_mark_after` ("{nome} — DEPOIS DA {anterior}").
- **Botão de foco trancado:** mesma fileira e mesmo tamanho dos outros. Mostra a silhueta, o cadeado e o preço (`focus_locked_price`) ou "DEPOIS DA {anterior}" (`focus_locked_after`).
- **Linha da aba:** ícone em silhueta, nome, preço e COMPRAR. Depois da compra, ela vira a linha normal de melhorias do aparelho.
- **Painel de atributos:** abaixo do atributo de aparelho trancado, a linha `attr_locked` ("COMPRE A {nome} PARA TREINAR").
- Tudo passa pela skill `alinhamento-ui` com 1, 2 e 3 aparelhos comprados (critério 17).

## 4. Modo assistido (Shift pressionado)

### 4.1 Números
| Campo (`data/training.json` → `assist`) | Valor | O que é |
|---|---|---|
| `interval` | **3.0 s** | 1 auto-soco a cada 3 s (0,33 soco/s). O Metrônomo 1 é 2.0 s. |
| `still_seconds` | **1.0 s** | "mão parada": só soca se o último clique ou Espaço foi há ≥ 1 s |
| `first_delay` | **1.0 s** | o 1º soco sai 1 s depois que o modo fica ativo (resposta rápida a quem segura o Shift) |

Eficiência (critério 24): no mesmo aparelho, com a mesma luva e os mesmos nós, o clique rende `cps × interval` vezes o assistido, ou seja, **12× a 4/s, 13,5× a 4,5/s e 15× a 5/s** (9× a 3/s). Na simulação "misto", 1 min de descanso com Shift dá 20 auto-socos, contra 240 cliques no mesmo minuto a 4/s (12×).

### 4.2 Regras (para o Programador)
```
segurando   = Shift pressionado (tecla, sem eco) OU botão de segurar pressionado com o mouse
ocioso      = segundos desde o último clicar() do jogador (mouse no alvo ou Espaço); auto-soco não zera
disponivel  = nivel_metronomo == 0
ativo       = segurando e disponivel e not modal_aberto and not acoes_bloqueadas() e ocioso ≥ still_seconds

a cada tick(delta):
    ocioso += delta
    se ativo:   acc += delta
                enquanto acc ≥ interval (máx. 3 por quadro):  acc −= interval ; auto_socar()   ← mesmo caminho do Metrônomo
    senão:      acc = interval − first_delay            (zera: ao voltar a ficar ativo, o 1º soco sai em first_delay)
clicar():   ocioso = 0   (antes de qualquer outra coisa, mesmo se a ação for recusada)
```
- **Caminho do soco:** `auto_socar()` da Fase 4, sem mudança: aparelho em foco × melhorias × luva × árvore, mesmo sorteio de crítico, treino no saldo e no atributo do foco, sinal `auto_socou`. A UI trata igual ao Metrônomo: número menor, sem tremida, som mais baixo e o jab do rig.
- **Contador de QA:** `assist_socos_total` (além do `auto_socos_total`, que conta os dois).
- **Mão parada:** quem clica 4–5/s tem intervalos de 0,2–0,25 s, então `ocioso` nunca chega a 1 s e o assistido **nunca soca**. Ao parar de clicar, o 1º auto-soco sai **2 s** depois do último clique (1 s de mão parada + 1 s de `first_delay`), o que cumpre o critério 21 (≥ 1 s).
- **Shift batido rápido não vira clique:** cada soltura zera o `acc`, e o 1º soco só vem 1 s depois. Bater no Shift mais rápido que 1 vez por segundo não rende nada.
- **Onde não funciona:** na luta e com a tela de fim (`acoes_bloqueadas`), com a prévia, a confirmação, a vitória ou o cartão de início abertos (`modal_aberto`), e na árvore (ela só abre com a tela de fim). Em todos esses casos, 0 soco e o `acc` não acumula para depois.
- **Some com o Metrônomo:** com `nivel_metronomo ≥ 1` (comprado ou pela Memória muscular), `disponivel = false`. O Shift não faz nada, e a dica e o botão de segurar dão lugar a "METRÔNOMO TOCANDO" (`assist_metronome`). Comprar o Metrônomo com o Shift pressionado corta o assistido no mesmo quadro.
- **Perder o foco da janela** (alt-tab, `NOTIFICATION_APPLICATION_FOCUS_OUT`) conta como soltar o Shift. Assim a tecla nunca fica "presa".
- **Shift + clique e Shift + Espaço:** o clique treina normalmente e zera `ocioso`. Nada mais muda (R9).
- **Offline:** nada (Fase 9). `acc` e `ocioso` não vão para o save.
- **Validação:** `interval` em [0.5, 60]. Se `interval ≤ intervalo do metronome_l1`, ele vira `intervalo_l1 + 1.0`, com aviso (nunca fica igual ou mais rápido que o nível 1). `still_seconds` em [0, 10], padrão 1.0. `first_delay` em [0, interval], padrão 1.0. Bloco ausente: os padrões acima.

### 4.3 Indicador e textos
| Situação | O que aparece perto do foco | chave |
|---|---|---|
| Metrônomo 0, não está segurando | dica fixa "SEGURE SHIFT: TREINO ASSISTIDO" + botão de segurar | `assist_hint`, `assist_button` |
| segurando, mão ainda mexendo (< 1 s) | "MÃO PARADA = ASSISTIDO" (indica que está esperando) | `assist_waiting` |
| ativo (socando) | "ASSISTIDO" aceso, pulsando a cada soco | `assist_active` |
| Metrônomo ≥ 1 | "METRÔNOMO TOCANDO" (sem botão) | `assist_metronome` |
| LOJA, item Metrônomo, nível 0 | "AGORA: 1 SOCO A CADA {s} S, SÓ SEGURANDO SHIFT" | `shop_metronome_now` |

Sinal novo: `assistido_mudou(estado: String)` com `"off" | "waiting" | "active" | "metronome"`, emitido só quando o estado muda.

## 5. Dica da tela de fim com aparelho não comprado
- O cálculo do motivo **não muda**.
- Em `_encerrar_carreira` (derrota): se `reason.kind != "luck"` e o aparelho que treina `reason.attribute` (o 1º aparelho em `training.json` com esse atributo) **não está montado**, grava `ending.reason.unlock_tip = <id do aparelho>`. Senão, `""`. Um `ending` antigo sem o campo vale `""`.
- Em `textos_fim`: com `unlock_tip != ""`, a dica sai de `tip_unlock_<aparelho>` (lista, mesmo índice `tip` de hoje) **no lugar** de `tip_<atributo>`. Se a lista não existir, usa `tip_unlock` com `{nome}`. A frase do motivo ("FALTARAM 29,5K DE AGILIDADE"), a dica de tática e a `tip_wait_green` continuam iguais.
- A revanche não muda. Na próxima carreira o jogador compra o aparelho normalmente.
- Frequência medida: o aparelho da dica não estava comprado em **2 de 89** derrotas (5/s) e **0 de 93** (4/s). Na variante "compra só quando a prévia pedir", foram 3 de 84–90. É raro, mas o critério 12 pede o texto certo.

## 6. Save v5

### 6.1 Formato (o que muda em relação à v4)
```json
{ "version": 5, "saved_at_unix": 1730000000,
  "state": {
    "career":    { "...todos os campos da v4...": "", "apparatus_owned": ["punching_bag", "treadmill"] },
    "permanent": { "...igual à v4 (nada novo)...": "" },
    "ending":    { "...igual...", "reason": { "...": "", "unlock_tip": "" } } } }
```
- `career.apparatus_owned`: lista de ids, na ordem da compra. **Nada novo em `permanent`** (decisão do dono 3).

### 6.2 Leitura (validação)
- Ignora id inexistente ou repetido (com aviso). Sempre acrescenta os aparelhos sem `unlock`.
- Aparelho montado cujo `requires` não está montado: **mantém** (com aviso). É dado editado, e o jogo não tira o que o jogador tem.
- Campo ausente ou que não é lista: só os aparelhos sem `unlock` (com aviso).
- `focus` num aparelho não montado volta para `default_focus` (com aviso).
- Nível de melhoria > 0 num aparelho não montado vira 0 (com aviso). O Treino não é devolvido.

### 6.3 Migração `_migrar_4_para_5`
```
v5.career = v4.career + { apparatus_owned: ["punching_bag", "jump_rope", "treadmill"] }
v5.permanent = v4.permanent            (sem campo novo)
v5.ending    = v4.ending               (sem "unlock_tip": vale "")
```
- Os 3 ids são **constantes da migração** (são ids estáveis). A migração não lê `data/`.
- A carreira em andamento continua com tudo: foco, melhorias, Treino e luta pendente. Com a tela de fim pendente também vale, e a próxima NOVA CARREIRA começa só com o saco.
- `SaveStore.MIGRACOES[4] = "_migrar_4_para_5"` e `VERSAO_ATUAL = 5`. A cadeia v0 → v5 funciona, e o guarda do save real continua cobrindo tudo.

### 6.4 Momentos de salvar (novos)
| Ação | Num único save |
|---|---|
| Comprar aparelho | `training −= custo`, `apparatus_owned += id`, `focus = id` |
| NOVA CARREIRA | como na Fase 4 + `apparatus_owned = aparelhos sem unlock` |
| Derrota | como na Fase 4 + `ending.reason.unlock_tip` |

## 7. Contrato de dados

### 7.1 `data/training.json`
Duas mudanças: um bloco `unlock` nos aparelhos que chegam e um bloco `assist` novo. Os ids e os campos de hoje não mudam.
```json
{
  "click": { "...": "igual" },
  "assist": { "interval": 3.0, "still_seconds": 1.0, "first_delay": 1.0 },
  "default_focus": "punching_bag",
  "apparatus": [
    { "id": "punching_bag", "...": "igual, SEM unlock (sempre montado)" },
    { "id": "jump_rope", "...": "igual",
      "unlock": { "id": "unlock_jump_rope", "cost": 1500, "requires": "treadmill",
                  "name": "Corda de varal", "description": "...", "arrives_as": "..." } },
    { "id": "treadmill", "...": "igual",
      "unlock": { "id": "unlock_treadmill", "cost": 500, "requires": "",
                  "name": "Esteira enferrujada", "description": "...", "arrives_as": "..." } }
  ]
}
```
| Campo | Tipo / faixa | Padrão | Validação |
|---|---|---|---|
| `unlock` | objeto ou ausente | ausente = sempre montado | outro tipo: ignorado, com aviso |
| `unlock.id` | texto, único | `"unlock_" + id do aparelho` | repetido: usa o padrão, com aviso |
| `unlock.cost` | número ≥ 1 | — | faltando, inválido ou < 1: o aparelho fica **sem trancar**, com aviso (dado ruim não tranca o jogador) |
| `unlock.requires` | id de outro aparelho ou `""` | `""` | inexistente, ele mesmo ou ciclo: vira `""`, com aviso |
| `unlock.name` / `description` / `arrives_as` | texto | nome do aparelho / "" | textos do Roteirista |
| `default_focus` | aparelho **sem** `unlock` | `punching_bag` | se apontar para um aparelho com `unlock`, o `unlock` dele é ignorado, com aviso (o foco inicial nunca fica trancado) |
| `assist.*` | ver 4.2 | ver 4.1 | ver 4.2 |

Mudar `unlock.cost`, `assist.interval` ou `assist.still_seconds` muda o jogo sem mexer em código (critérios 15 e 27).

### 7.2 `data/ui_texts.json` (chaves novas; o texto final é do Roteirista)
| chave | placeholders | rascunho / intenção |
|---|---|---|
| `unlock_buy` | — | "COMPRAR" (linha da aba) |
| `unlock_price` | `{n}` | "{n} TREINO" |
| `unlock_after` | `{nome}` | "DEPOIS DA {nome}" |
| `floor_mark_price` | `{nome}`, `{n}` | "{nome} — {n} TREINO" (plaquinha) |
| `floor_mark_after` | `{nome}`, `{anterior}` | "{nome} — DEPOIS DA {anterior}" |
| `focus_locked_price` | `{n}` | "{n}" (cabe no botão de foco) |
| `focus_locked_after` | `{nome}` | "DEPOIS DA {nome}" |
| `attr_locked` | `{nome}` | "COMPRE A {nome} PARA TREINAR" |
| `unlock_arrived` | `{nome}` | "{nome} CHEGOU!" (opcional, na chegada) |
| `tip_unlock_treadmill` | — | lista: "COMPRE A ESTEIRA CEDO NA PRÓXIMA CARREIRA", ... |
| `tip_unlock_jump_rope` | — | lista: "COMPRE A CORDA CEDO NA PRÓXIMA CARREIRA", ... |
| `tip_unlock` | `{nome}` | reserva: "COMPRE A {nome} CEDO NA PRÓXIMA CARREIRA" |
| `assist_hint` | — | "SEGURE SHIFT: TREINO ASSISTIDO" |
| `assist_button` | — | "SEGURAR" (botão para quem só usa mouse) |
| `assist_waiting` | — | "MÃO PARADA = ASSISTIDO" |
| `assist_active` | — | "ASSISTIDO" |
| `assist_metronome` | — | "METRÔNOMO TOCANDO" |
| `shop_metronome_now` | `{s}` | "AGORA: 1 SOCO A CADA {s} S, SÓ SEGURANDO SHIFT" |

Os nomes dos aparelhos nas frases ("A ESTEIRA", "A CORDA") ficam com o Roteirista (gênero e artigo).

## 8. API sugerida (nomes livres para o Programador)
| Função / sinal | Faz |
|---|---|
| `aparelho_montado(id) -> bool`, `aparelhos_montados() -> Array` | consulta |
| `desbloqueio(id) -> Dictionary` | `{id, cost, requires, name, ...}` ou `{}` |
| `estado_aparelho(id) -> String` | `owned` / `buyable` / `missing` / `locked` |
| `pode_comprar_aparelho(id)`, `comprar_aparelho(id) -> bool` | 2.2 |
| `signal aparelho_comprado(aparelho: String)` | chegada com juice |
| `definir_foco(id)` | passa a recusar aparelho não montado |
| `definir_assistido(segurando: bool)` | chamado pela UI (Shift, botão, perda de foco) |
| `assistido_estado() -> String`, `signal assistido_mudou(estado)` | 4.3 |
| `assist_socos_total` | contador para o QA |

## 9. Simulação e balanço

### 9.1 O robô (regras declaradas)
`tools/sim/fase4b_sim.py` (seções `precos curvas inicio assistido revanche carreiras`). Luta, prévia, motivo, árvore, Metrônomo, LOJA e tempo morto vêm do `fase4_sim.py` sem mudança.
- **Compra dos aparelhos (regra principal, `asap`):**
  - 1ª carreira: a esteira vira prioridade **depois da fita** (o robô junta para ela e não compra mais nada até ter), e a corda vira prioridade **depois da areia peneirada**.
  - Da 2ª carreira em diante, o jogador já sabe: as duas viram prioridade logo depois da fita.
- **Variante `previa`:** só compra quando a prévia (o "ELE É MUITO MAIS ...") ou a dica da tela de fim pede um aparelho que ele não tem. Aí junta para ele (e para a esteira antes, se o pedido for a corda).
- **Depois de comprar,** o foco vai para o aparelho novo e o robô clica nele por 10 s ("testa a compra"). Depois volta à regra de foco da Fase 4.
- **O robô "lê a prévia"** só alterna para um aparelho já montado. Se a regra pede um aparelho que falta, ele fica no saco.
- **Assistido:** só soca com o perfil sem clicar (ritmo 0) e com o Shift; regras da seção 4 a cada 0,1 s. Com o Metrônomo ≥ 1, para.
- **Perfis:** típico 5/s e 4/s, lento 3/s; "Shift sempre" (típico 5/s segurando o Shift a carreira inteira); **misto** (4/s em blocos de 2 min e 1 min de descanso, com e sem Shift); **só assistido** (não clica nunca e segura o Shift); "não clica nem usa Shift". A base de comparação é o "Fase 4" (os 3 aparelhos no minuto 0, mesmo robô).
- Números: 64 jogadores no início da carreira, 32 × 8 carreiras na sequência, 120 × 2 carreiras na revanche e 400 × 1 carreira para o 23b.

Rodar:
```
"C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase4b_sim.py tudo
SIM_N=32 SIM_CARREIRAS=8 SIM_N_REV=120 SIM_N_INI=64 ... tudo     (números deste documento)
SIM_UNLOCK="500,1500"  SIM_ASSIST="3.0"                           (testar outros preços / ritmo)
```

### 9.2 Começo da 1ª carreira (robô típico, sem nós; o começo é determinístico até a 1ª luta)
| perfil | 1º vizinho | 1ª melhoria | tio | **esteira** | **corda** | vence Dudu | luta Brutão | luta Dinho | 2 aparelhos antes do Brutão | antes do Dinho |
|---|---|---|---|---|---|---|---|---|---|---|
| Fase 4, 5/s | 0:10 | 0:53 | 4:39 | — | — | 3:13 | 8:31 | 11:31 | — | — |
| **4b, 5/s** | 0:10 | 0:53 | 5:23 | **1:19** | **4:36** | 3:13 | 9:01 | 12:01 | **58 de 58** | 58 de 58 |
| Fase 4, 4/s | 0:12 | 1:04 | 5:27 | — | — | 3:44 | 10:01 | 13:31 | — | — |
| **4b, 4/s** | 0:12 | 1:04 | 6:15 | **1:37** | **5:34** | 4:14 | 10:31 | 14:01 | **64 de 64** | 64 de 64 |
| Fase 4, 3/s | 0:17 | 1:27 | 6:12 | — | — | 4:14 | 11:01 | 15:01 | — | — |
| **4b, 3/s** | 0:17 | 1:27 | 7:01 | **2:06** | **6:26** | 4:44 | 12:01 | 16:01 | 55 de 55 | **55 de 55** |
| 4b `previa`, 5/s | 0:10 | 0:53 | 5:34 | 3:31 | 3:41 | 3:13 | 9:01 | 12:31 | 58 de 58 | 57 de 57 |
| 4b `previa`, 4/s | 0:12 | 1:04 | 6:06 | 5:00 | 5:11 | 3:44 | 10:01 | 13:31 | 59 de 59 | 59 de 59 |
| 4b `previa`, 3/s | 0:17 | 1:27 | 6:53 | 5:00 | 5:10 | 4:14 | 11:31 | 15:31 | 50 de 50 | 50 de 50 |

- **Atraso na curva** (o robô olha a prévia a cada 30 s, então os tempos andam em degraus de 30 s): Dudu +0:00 / +0:30 / +0:30, Brutão +0:30 / +0:30 / +1:00, Dinho +0:30 / +0:30 / +1:00 (5 / 4 / 3 cliques/s). **≤ 1 min** em todos.
- Na variante `previa`, o robô só compra quando a prévia do Brutão grita ("ELE É MUITO MAIS ..."), logo depois do Dudu, e leva os dois aparelhos em sequência. Também chega antes do Brutão em 100%.
- Outros preços testados (5/s; esteira, corda, Dudu, Brutão): 600/1.500 → 1:24, 4:53, **3:44**, 9:31. 750/2.000 → 1:32, 5:02, **3:44**, 9:31. 1.000/2.500 → 1:46, 5:12, 3:44, 9:31 (tio do 3/s 8:01, fora da faixa).

### 9.3 Carreiras em sequência (32 jogadores, 8 carreiras; árvore pela regra "dica")
| perfil | 1ª derrota (mediana) | como a 1ª carreira acaba (de 32) | cinturão: carreira (med; p10–p90) | árvore fecha | aparelhos nas carreiras 2+ (mediana; p90; pior) | dica aponta aparelho não comprado |
|---|---|---|---|---|---|---|
| Fase 4, típico 5/s | 11:44 | Dinho 19, Muralha 5, Dudu 3, cinturão 5 | 2 (1–4) | 6 (5–7) | — | — |
| **4b, típico 5/s** | **12:14** | Dinho 19, Muralha 5, Dudu 2, cinturão 6 | **2 (1–3)** | **6 (6–7)** | **1:05; 1:20; 2:45** | 2 de 89 |
| Fase 4, típico 4/s | 13:44 | Dinho 19, Muralha 6, Dudu 2, cinturão 5 | 2 (1–3) | 6 (5–8) | — | — |
| **4b, típico 4/s** | **14:14** | Dinho 18, Muralha 7, cinturão 7 | **2 (1–3)** | **6 (5–8)** | **1:18; 1:36; 1:47** | 0 de 93 |
| Fase 4, lento 3/s | 15:14 | Dinho 16, Muralha 6, Dudu 7, cinturão 3 | 3 (2–3) | 6 (6–8) | — | — |
| 4b, lento 3/s | 16:14 | Dinho 17, Muralha 6, Dudu 5, cinturão 4 | 3 (1–3) | 7 (6–8) | 1:39; 2:21; 4:42 | 0 de 99 |
| 4b, típico 5/s, **Shift sempre** | 12:14 | **idêntico ao 4b típico 5/s** | 2 (1–3) | 6 (6–7) | 1:05; 1:20; 2:45 | 2 de 89 |
| 4b `previa`, típico 5/s | 12:44 | Dinho 18, Muralha 6, Dudu 3, cinturão 5 | 2 (1–3) | 6 (5–7) | 3:00; 3:01; 5:01 | 3 de 84 |
| 4b `previa`, típico 4/s | 13:44 | Dinho 19, Muralha 6, Dudu 2, cinturão 5 | 2 (1–4) | 6 (6–8) | 3:01; 3:31; 5:31 | 3 de 90 |
| 4b, **misto** 4/s, com Shift | 16:44 | Dinho 18, Muralha 7, Dudu 2, cinturão 5 | 2 (1–3) | 6 (5–8) | 1:18; 1:36; 4:57 | 0 de 97 |
| 4b, misto 4/s, sem Shift | 17:14 | Dinho 15, Muralha 9, Dudu 6, cinturão 2 | 2 (2–3) | 7 (6–8) | 1:18; 1:47; 5:32 | 0 de 100 |

- O pior caso de "aparelhos nas carreiras 2+" (2:45 a 5/s) é a carreira que vem depois de uma derrota no Dudu, sem Legado e sem nós: ela é igual à 1ª.
- **"Shift sempre" dá resultado idêntico, semente a semente** (critério 25): a regra da mão parada zera o efeito em quem clica sem parar.

**Tempo morto (maior trecho seguido; mediana / p90 / pior; carreiras acima de 10 min, de 32)**
| perfil | carreira 1 | carreira 2 | carreira 3 | carreira 4 |
|---|---|---|---|---|
| Fase 4, típico 5/s | 5:00 / 11:01 / 11:01 (10) | 6:00 / 6:00 / 11:01 (2) | 5:00 / 6:00 / 6:00 (0) | 5:00 / 5:30 / 6:00 (0) |
| **4b, típico 5/s** | **5:30 / 11:01** / 11:01 (11) | 6:00 / **6:00** / 11:01 (1) | 5:30 / **6:00** / 6:00 (0) | 4:30 / **5:30** / 5:30 (0) |
| Fase 4, típico 4/s | 6:00 / 12:32 / 12:32 (11) | 7:00 / 7:00 / 7:30 (0) | 6:00 / 7:00 / 7:00 (0) | 5:30 / 6:30 / 7:00 (0) |
| **4b, típico 4/s** | **6:00 / 12:32** / 12:32 (14) | 7:00 / **7:30** / 7:30 (0) | 5:30 / **7:00** / 7:00 (0) | 5:30 / **6:00** / 7:00 (0) |
| 4b, lento 3/s | 7:00 / 14:33 / 14:33 (10) | 8:01 / 8:31 / 14:33 (2) | 7:01 / 8:01 / 9:01 (0) | 6:00 / 7:00 / 8:01 (0) |
| 4b, misto 4/s com Shift | 7:30 / 15:03 / 15:03 (12) | 8:31 / 9:01 / 15:03 (1) | 7:00 / 8:31 / 8:31 (0) | 6:30 / 7:30 / 8:31 (0) |

### 9.4 Revanche (120 jogadores, 2 carreiras, **com a alavanca L1**, que é o jogo aprovado)
| perfil | algoz | casos | venceu o algoz | quando | protótipo (mediana) |
|---|---|---|---|---|---|
| Fase 4, típico 5/s | Dinho / Muralha | 65 / 18 | 95% / 89% | 8:14 / 18:17 | 20:58 |
| **4b, típico 5/s** | Dinho / Muralha | 67 / 18 | **93% / 94%** | 8:18 / 18:47 | **21:31** |
| Fase 4, típico 4/s | Dinho / Muralha | 64 / 19 | 94% / 79% | 9:14 / 20:17 | 23:58 |
| **4b, típico 4/s** | Dinho / Muralha | 71 / 23 | **93% / 87%** | 9:14 / 20:47 | **24:28** |
| 4b, lento 3/s | Dinho / Muralha | 65 / 17 | 95% / 88% | 11:44 / 24:48 | 28:58 |
| 4b `previa`, típico 4/s | Dinho / Muralha | 61 / 19 | 97% / 63% | 10:14 / 22:47 | 24:58 |

(O Dudu e o Brutão como algoz: 85–100%, poucos casos.) O protótipo é o caminho "perde no Dinho → jab + bolsa → vence o Dinho no verde" (~55% das 1ªs carreiras).

### 9.5 Cinturão na 1ª carreira (23b), 400 jogadores × 1 carreira
| perfil | cinturão na 1ª | mais cedo | derrotas no Dudu (de 400) |
|---|---|---|---|
| Fase 4, típico 5/s | 16,8% | 23:19 | 36 |
| **4b, típico 5/s** | **17,0%** | 23:51 | 45 |
| Fase 4, típico 4/s | 20,8% | 26:50 | 34 |
| **4b, típico 4/s** | **24,2%** | 27:20 | **4** |

### 9.6 Perfil "só assistido" (não clica nunca, segura o Shift; 16 jogadores, limite de 180 min)
| carreira | 1º vizinho | fita | esteira | vence Dudu | vence Brutão | corda | vence Dinho | Metrônomo 1 | como acaba (de 16) | maior tempo morto (med; p90) |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2:28 | 8:13 | 9:01 | **10:44 (16 de 16)** | 20:44 (14 de 16) | 20:09 | 27:46 (7 de 16) | 27:46 | cinturão 2, Dinho 7, Muralha 5, Brutão 2 | 10:31 / 24:05 |
| 2 (com o que a 1ª comprou) | 1:13 | 4:46 | 5:46 | 9:14 (15 de 16) | 19:44 (13 de 16) | 8:46 | 25:15 (11 de 16) | 19:44 | cinturão 7, Muralha 4, Brutão 2, Dinho 2, Dudu 1 | 17:03 / 18:04 |

- **Vence o Dudu sem clicar em 16 de 16, aos 10:44** (critério 24). O típico vence aos 3:13–4:14.
- O assistido inteiro rende só ~2,4K de Treino na 1ª carreira: ele é o **arranque**. Sem ele, quem não clica fica com 0 de Treino para sempre (perfil "não clica nem usa Shift": parado em 16 de 16). O resto vem dos geradores e do Prof. Nelson, que já existiam.
- O ritmo é 2,5–3,3× mais lento que o do típico até o Dudu e ~2× até o Dinho. O tempo morto da 1ª carreira é longo (p90 24 min), e o dono deve saber disso (R8).
- **Misto (4/s, 2 min clicando e 1 min descansando):** o descanso de 1/3 do tempo empurra a 1ª derrota de 14:14 para 17:14. O Shift no descanso devolve 0:30 dela (16:44) e reduz as derrotas no Dudu (2 contra 6, de 32). No tempo morto quase não muda (carreira 1, p90 de 15:03 com Shift e 14:33 sem; carreira 2, 9:01 nos dois). Um minuto de descanso com Shift = 20 auto-socos.

### 9.7 Metas: antes e depois (honesto)
| Meta | Fase 4 (antes) | **4b (depois)** | Situação |
|---|---|---|---|
| F2: 1º gerador ≤ 1:00 | 0:10–0:17 | 0:10–0:17 | **fecha** |
| F2: 1ª melhoria ≤ 3:00 | 0:53–1:27 | 0:53–1:27 | **fecha** |
| F2: tio em 5–8 min | 4:39 / 5:27 / 6:12 | **5:23 / 6:15 / 7:01** | **fecha** (o 5/s, que estava em 4:39, entra na faixa) |
| F3: 1ª vitória em 2–5 min (4–5/s) | 3:13 / 3:44 | 3:13 / 4:14 | **fecha** |
| F4 22: 1ª derrota em 10–15 min (mediana) | 11:44 / 13:44 | **12:14 / 14:14** | **fecha** (lento: 16:14) |
| F4 23a: cinturão entre a 2ª e a 4ª carreira | 2 (1–4) / 2 (1–3) | 2 (1–3) / 2 (1–3) | **fecha** |
| F4 23b (meta nova do Diretor): cinturão na 1ª ≤ 20% a 5/s, ≤ 25% a 4/s, nunca antes de 20:00 | 16,8% / 20,8%; 23:19 | **17,0% / 24,2%**; 23:51 | **fecha** (4/s com margem curta: 24,25% contra 25%; ver "Decisão do Diretor") |
| F4 24: tempo morto, carreira 1 mediana ≤ 10 e p90 ≤ 13 | 5:00–6:00; 11:01 / 12:32 | 5:30–6:00; **11:01 / 12:32** | **fecha** |
| F4 24: carreiras 2–4 p90 ≤ 10 | ≤ 7:30 | **≤ 7:30** | **fecha** |
| F4 25: revanche Dinho ≥ 80%, Muralha ≥ 60% (com L1) | 94–95% / 79–89% | **93% / 87–94%** | **fecha** |
| F4 26: protótipo ~20 min (até 25) | 20:58 / 23:58 | **21:31 / 24:28** | **fecha** (o 4/s fica a 0:32 do teto) |
| F4 8: árvore entre a 5ª e a 8ª carreira | 6 / 6 | 6 / 6 (lento 7) | **fecha** |
| 4b 8: 2º aparelho ≤ 3 min; 3º antes do Brutão em ≥ 90% (mediana ≤ 8) | — | 1:19 / 1:37; 3º em 100%, 4:36 / 5:34 | **fecha** (o 5/s compra a esteira um pouco antes do "~1:30" e a corda antes de "~5 min") |
| 4b 9: lento com os dois antes do Dinho em ≥ 90% | — | 100% (corda 6:26) | **fecha** |
| 4b 10 (texto revisto, B4): carreiras 2+ ≤ 2 min na mediana e no p90 a 4–5/s; 3/s p90 ≤ 2:30; sem nós, no máximo o tempo da 1ª | — | mediana 1:05 / 1:18; p90 1:20 / 1:36; 3/s p90 2:21; pior 2:45 (5/s) e 4:42 (3/s), ambos abaixo da 1ª carreira | **fecha** |
| 4b 24: só assistido vence o Dudu sem clicar | — | 16 de 16, aos 10:44 | **fecha** |
| 4b 24: típico rende ≥ 8× o assistido | — | 12× (4/s), 15× (5/s) | **fecha** |
| 4b 25: típico igual com e sem Shift | — | idêntico, semente a semente | **fecha** |

**Tudo fecha.** O único caso que chegou a não fechar foi o 23b a 4 cliques/s (24,2% contra o limite antigo de 20%). O Diretor aceitou e reescreveu a meta (≤ 20% a 5/s, ≤ 25% a 4/s, nunca antes de 20:00; ver "Decisão do Diretor (23b)" no fim). Com a meta nova, fecha, com margem curta a 4/s (24,25% contra 25%). O histórico da análise fica abaixo:
- **Não vem dos aparelhos em si.** A base da Fase 4 já estava no limite: 20,8% com 400 jogadores (os 16% da tabela da Fase 4 eram 32 jogadores). O que muda é que **quase ninguém perde mais no Dudu** a 4/s (34 → 4 de 400). A compra da esteira empurra a 1ª olhada no Dudu de 3:44 para 4:14, e o robô chega 30 s mais forte. Esses jogadores seguem na escada, e parte deles faz o cinturão na 1ª, sempre depois de 27 min e numa luta de ~45% no amarelo.
- **O preço dos aparelhos não corrige isso:** com 400 jogadores, a 4/s, 300/1.000 deu 22,0%, 500/1.500 deu 24,2%, 1.000/3.000 deu 27,5% e 500/4.000 deu 31,0%. É ruído em volta do degrau de 30 s, sem tendência que se possa usar.
- **Mexer no Muralha também não fecha** (não posso mexer nele, só testei): `opp_tank.endurance` 530K dá 22,5% a 4/s e p90 do tempo morto de 13:02; 560K dá 21,2% e p90 de 13:32. Isso quebra o critério 24.
- Pela regra D1 da Fase 4, o caso foi ao Diretor, que **aceitou** com a meta "≤ 25% a 4/s" (o mais cedo continua 23:51, o 5/s fica em 17%). Trava: 4/s > 25%, 5/s > 20% ou cinturão antes de 20:00 volta ao Diretor. Rerodar o 23b com 400 jogadores sempre que mexer em `data/`.

## 10. Testes automáticos que este design pede
| Teste | Confere |
|---|---|
| Começo | save novo e NOVA CARREIRA (após derrota e após aposentadoria): `apparatus_owned == ["punching_bag"]`, foco no saco |
| Compra | desconta o custo exato do JSON; atributos iguais antes e depois; recusa sem saldo, sem o anterior (corda antes da esteira), com luta e com fim; saldo nunca negativo; foco vai para o novo; salva na hora (reabrir: comprado e descontado uma vez só) |
| Foco e melhorias | `definir_foco` recusa trancado; `proxima_melhoria` vazia e `comprar_melhoria` false em trancado |
| Dados | mudar `unlock.cost` num JSON de teste muda o preço; `cost` inválido deixa o aparelho montado com aviso; `requires` em ciclo vira `""`; `default_focus` com unlock tem o unlock ignorado |
| Dica de fim | derrota com atributo decisivo de aparelho não montado → `unlock_tip` = id e dica de `tip_unlock_*`; montado → dica normal; `luck` → nada muda |
| Save v5 | v4 com carreira (e com fim pendente) → v5 com os 3 aparelhos, foco, melhorias e Treino intactos; próxima NOVA CARREIRA só com o saco; v0 → v5 em cadeia; foco/melhoria em aparelho não montado corrigidos com aviso |
| Assistido, ritmo | segurando, sem clicar, 60 s de jogo: 20 auto-socos (1º em 1 s, depois a cada 3 s); soltar zera; Shift batido a cada 0,5 s por 10 s: 0 auto-soco |
| Assistido, caminho do clique | 1.000 auto-socos: crítico na taxa do clique (±3 pontos); com a lona o treino dobra; vai para o atributo do foco |
| Mão parada | `clicar()` a cada 0,25 s por 30 s segurando: 0 auto-soco do assistido; ao parar, o 1º sai 2 s depois do último clique |
| Fora da garagem | segurando, 5 lutas, prévia, tela de fim e cartão: 0 auto-soco |
| Metrônomo | com `nivel_metronomo ≥ 1` (comprado ou pela Memória muscular), segurando: só os socos do Metrônomo, no ritmo dele; `assist_socos_total` não anda |
| Validação | `assist.interval` = 1.0 no JSON de teste → vira 3.0 (L1 + 1), com aviso; mudar `interval` e `still_seconds` muda o jogo |
| Foco da janela | perder o foco com o Shift pressionado → assistido para |
| Guarda do save real | continua passando; tudo em pasta de teste |

## 11. Ids e nomes para o Roteirista
- Desbloqueios: **`unlock_treadmill`** (Esteira enferrujada, 500) e **`unlock_jump_rope`** (Corda de varal, 1.500, pede a esteira). Campos de texto: `unlock.name`, `unlock.description` e `unlock.arrives_as` (de onde o aparelho vem: casa do vizinho, ferro-velho...).
- Chaves de `ui_texts.json`: as da tabela 7.2 (`unlock_*`, `floor_mark_*`, `focus_locked_*`, `attr_locked`, `unlock_arrived`, `tip_unlock_treadmill`, `tip_unlock_jump_rope`, `tip_unlock`, `assist_hint`, `assist_button`, `assist_waiting`, `assist_active`, `assist_metronome` e `shop_metronome_now`).
- Tom: pé no chão, coisa de bairro. "SEGURE SHIFT" precisa caber na largura do botão de foco (passa pela `alinhamento-ui`).

## 12. Lista de arte (Diretor de Arte; placeholder do estúdio vale)
| Item | Quantos | Observação |
|---|---|---|
| Marca de fita crepe no chão | 2 (esteira e corda) | contorno no tamanho e no lugar exato do aparelho; some na chegada |
| Plaquinha de papelão escrita à mão | 1 base, com o texto por cima | o texto vem de `floor_mark_*` (preço ou "DEPOIS DA ESTEIRA"); precisa caber "CORDA — 1.5K TREINO" |
| Silhueta com cadeado | 2 (esteira e corda) | para o botão de foco trancado e a linha da aba TREINO, no mesmo tamanho dos ícones de hoje |
| Botão de foco trancado | estados `buyable`, `missing` e `locked` | mesma moldura dos outros botões; preço em destaque, apagado ou "DEPOIS DA ..." |
| Efeito de chegada | 1 | poeira e queda ou deslizada; reaproveita partículas que já existem |
| Indicador do assistido | 4 estados (dica, esperando, socando, Metrônomo) | pequeno, perto do foco; "socando" pulsa a cada auto-soco; o botão SEGURAR fica no mesmo lugar |
| Nada de personagem novo | — | o Artista de Personagens não entra |

## 13. Pedido extra (Diretor, via Produtor): rótulo da revanche no `fase4_sim.py`
A tabela "Resumo por perfil" do `tools/sim/fase4_sim.py carreiras` agora diz no cabeçalho que as colunas de revanche são **"sem L1 — referência"**. Antes da tabela sai um aviso: o jogo aprovado (D2) usa a L1, e a revanche que vale para o critério 25 está na seção `revanche`, nos perfis com a alavanca L1. Não mudei nenhuma conta. No `fase4b_sim.py`, a revanche só é medida com a L1 (seção 9.4).

## Resumo
- **Aparelhos:** toda carreira começa só com o saco. A esteira (`unlock_treadmill`, **500 de Treino**) pode ser comprada desde o minuto 0. A corda (`unlock_jump_rope`, **1.500**) pede a esteira. A compra é feita na aba TREINO, com 1 clique, salva na hora, leva o foco para o aparelho novo e zera na NOVA CARREIRA. Os preços ficam no bloco `unlock` do aparelho em `data/training.json`.
- **Modo assistido:** só com o Shift pressionado (ou o botão SEGURAR). Dá 1 auto-soco a cada **3.0 s** pelo caminho do clique, só com a mão parada há **1.0 s**, e o 1º soco sai 1.0 s depois de ativar. Não funciona na luta, nas janelas, no fim nem na árvore, e some com o Metrônomo ≥ 1. Nada vai para o save. O bloco é `assist` em `data/training.json`.
- **Save v5:** `career.apparatus_owned`. A migração v4 → v5 dá os 3 aparelhos à carreira em andamento. Nada novo em `permanent`. A tela de fim ganha `reason.unlock_tip` para a dica "compre a esteira/corda".
- **Números-chave:** esteira aos 1:19 / 1:37 / 2:06 e corda aos 4:36 / 5:34 / 6:26 (5 / 4 / 3 cliques/s), sempre antes do Brutão. A curva atrasa ≤ 1 min. 1ª derrota aos 12:14 / 14:14. Cinturão na 2ª carreira (mediana). Tempo morto da carreira 1 com p90 de 11:01 / 12:32, carreiras 2–4 ≤ 7:30. Revanche: Dinho 93%, Muralha 87–94% com a L1. Protótipo aos 21:31 / 24:28. O só-assistido vence o Dudu aos 10:44 sem clicar, e o clique rende 12–15× o assistido. O típico dá o mesmo resultado com e sem Shift.
- **Metas:** todas fecham. O 23b a 4/s (24,2%) fecha pela meta nova do Diretor (≤ 25% a 4/s, ≤ 20% a 5/s, nunca antes de 20:00), com margem curta. O critério 10 fecha pelo texto revisto (B4). A revanche usa Dinho ≥ 80% e Muralha ≥ 60% (B5).

---

## Decisão do Diretor (23b) — 2026-11-06
**Aceito; a meta muda.** Nada de número muda neste design (preços 500/1.500 e Muralha como estão).
- Nova meta 23b: cinturão na 1ª carreira **≤ 20% a 5/s**, **≤ 25% a 4/s**, **nunca antes de 20:00**; 23a (mediana na 2ª carreira) sem mudança.
- Situação na 4b: 17,0% / 24,2%, mais cedo 23:51 → **fecha**. Atualizar a linha "F4 23b" da tabela 9.7 com essa meta ao rodar a próxima vez.
- Motivo: a 1ª carreira continua terminando em derrota para 3 de cada 4 jogadores; a alta vem de menos derrota boba no Dudu (coisa boa); a vitória precoce é tardia e apertada. Mexer no Muralha quebraria o critério 24, que vale mais.
- Trava: 4/s > 25%, 5/s > 20% ou cinturão antes de 20:00 em fase futura volta ao Diretor (D1). O QA usa esta meta no critério 11.

## Nota do Designer para o Diretor (critério 10, B4 do QA) — 2026-11-06
Rodada `SIM_N=32 SIM_CARREIRAS=8 fase4b_sim.py carreiras`, coluna "aparelhos nas carreiras 2+" (mediana; p90; pior):
5/s **1:05; 1:20; 2:45**. 4/s **1:18; 1:36; 1:47**. Lento 3/s **1:39; 2:21; 4:42**.
- O pior caso a 5/s (2:45) é quem perdeu no Dudu sem ganhar nós: a carreira 2 dele é igual à 1ª (esteira 1:19 + corda). O de 4:42 a 3/s é o mesmo caso, no ritmo lento (na 1ª carreira, a corda a 3/s sai aos 6:26).
- **Recomendo mudar o texto, não os números:** "Carreiras 2+ com os nós da derrota típica: os dois aparelhos em **≤ 2 min na mediana e no p90, a 4–5/s**. Lento (3/s): p90 ≤ 2:30. Quem não ganhou nós leva no máximo o tempo da 1ª carreira." Com esse texto, tudo **fecha** (3/s p90 2:21).
- Por que não mexer em número: para levar o p90 de 3/s para ≤ 2:00, seria preciso baratear a corda (estimativa: ~1.100 em vez de 1.500; não simulei). Isso adianta a corda também na 1ª carreira, mexe nos critérios 8 e 9 e mexe no 23b, que a 4/s está com margem curta (24,25% contra 25%; ruído de ±2 pontos). Dar nós a quem perdeu no Dudu mexe na árvore (F4 8). O ganho é pequeno e o risco é alto.
- `data/` não foi alterado. Se o Diretor preferir o número, eu rodo a corda a 1.100 com 400 jogadores antes de propor.

**Decisão do Diretor (B4 e B5) — 2026-11-06:** texto aceito, nenhum número muda. O critério 10 do escopo foi reescrito com o texto acima. Trava: p90 de 4–5/s acima de 2:00 ou de 3/s acima de 2:30 volta ao Diretor. B5: a revanche da 4b é Dinho ≥ 80% e Muralha ≥ 60% (critério 25 da Fase 4); a seção 8 do escopo foi corrigida.
