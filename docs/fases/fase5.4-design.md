# Fase 5.4 — Árvore grande: design

Dono: Designer de Jogo. Data: 2026-11-13. Branch: `fase-5.4`.
Base: `docs/fases/fase5.4-escopo.md` (aprovado pelo dono), `fase5.3-design.md`, `fase5.3-revisao.md` (seção 5), `fase5.2-revisao.md` (seção 5).
Simulador: `tools/sim/fase5_sim.py`, seções novas `f54`, `f54x` e `f54dia`. Tudo é lido de `data/`. Para rodar:
```
"C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" tools/sim/fase5_sim.py f54x b23c f54dia
```
- `SIM_N54`: jogadores por perfil (padrão 400). `SIM_K54`: campanhas (padrão 10). `SIM_N_23B`: padrão 2.000.
- Outras alavancas: `SIM_ARVORE=antiga` (árvore da 5.3), `SIM_SEM="id,id"` (tira nós do mapa), `SIM_CUSTO="id=c;id=c"` (troca preços), `SIM_G2="F,A,R"` (Kid) e `SIM_ARTE_LUTA="dano_boxe,recebido_jj"`.

**Os números deste documento já estão em `data/`** (lista na seção 7.5).

---

## 1. Regras do mapa

### 1.1 Estados de um nó
| Estado | Regra | O que mostra |
|---|---|---|
| **Comprado** | `id` está em `permanent.skill_nodes` | aceso, com nome e efeito |
| **À vista** | não comprado, trava aberta (1.2) e (`root` **ou** algum vizinho comprado) | nome, efeito, preço; pode comprar |
| **Escondido** | o resto | nada (nem a linha até ele) |

- A linha entre dois nós só aparece quando os dois estão **comprados ou à vista**.
- **Nome da região** aparece quando o 1º nó dela fica à vista ou é comprado. Os nós de ligação não têm nome de região.
- **Pode comprar** = à vista, `Legado ≥ cost`, mapa aberto. **1 clique, sem confirmação.** O Legado cai na hora, o nó acende e os vizinhos novos aparecem na mesma hora (critério 4).
- O estado **não é gravado** no save. Ele é calculado de `skill_nodes` + travas. Por isso a migração não precisa abrir os vizinhos à mão (seção 6).

### 1.2 Travas (`lock`)
| `lock` | Abre quando | Regiões |
|---|---|---|
| `""` | sempre | CORPO, CAMPANHA, ESTILO*, Garagem, Campanha, ligações |
| `"gym"` | `permanent.arts_unlocked` não está vazio (algum discípulo já chegou à academia) | Academia |
| `"art:boxing"` / `"art:bjj"` | a arte está em `permanent.arts_unlocked` | Boxe / Jiu-jitsu (e o nó ESTILO da arte) |
- \* Os nós ESTILO são raiz com trava de arte, como hoje.
- Hoje as três travas abrem juntas (a 1ª chegada libera as duas artes). Os ids continuam separados para a 7b (Muay Thai) e a 8a.
- Um nó de ligação não tem trava própria. Ele pode aparecer antes da região do outro lado, se o vizinho do lado aberto for comprado. É de propósito: a ligação é a "porta lateral" e dá uma pista do que vem. **Os nós da região travada nunca aparecem antes da hora** (critério 4).

### 1.3 Raízes (à vista sem vizinho comprado)
`body_jab`, `career_purse` (sempre); `style_boxing`, `style_bjj`, `box_counter`, `bjj_guard` (com a arte); `gym_membership` (com a academia).
- **O 1º nó de cada região é barato e aparece cedo:** Garagem `gar_tape` 15 e Campanha `camp_poster` 20 (vizinhos de 10). Academia `gym_membership` 150 e as artes `box_counter`/`bjj_guard` 200 são raiz e aparecem no instante em que a trava abre.

### 1.4 "Vale na próxima campanha"
- A árvore abre a qualquer hora (decisão 1 do Diretor). A compra entra em `permanent.skill_nodes` na hora, mas **os bônus da campanha vêm de uma foto**: `career.active_nodes`, tirada ao começar a campanha (NOVA CAMPANHA e 1ª campanha).
- Todo efeito lê `active_nodes`, nunca `skill_nodes`. Um nó comprado no meio da campanha aparece aceso no mapa, com a etiqueta "VALE NA PRÓXIMA CAMPANHA" no cartão, até a campanha acabar.
- A campanha 1 começa sem nós (23b intacto).

### 1.5 Botão e centro
- **Brilho do botão:** `existe nó à vista com cost ≤ Legado`. É a mesma função de "pode comprar", sem olhar se o mapa está aberto (critério 2).
- **Ao abrir:** centraliza no último nó comprado (`permanent.tree_last_node`, gravado a cada compra). Sem compra, centraliza em (0, 0), entre `body_jab` e `career_purse`.
- Mapa aberto = modal: `sala_ativa()` falso. Relógio, equipe, Metrônomo, clique e luva param (critério 8; é a regra das janelas da 5.3).

---

## 2. O mapa: 39 nós

### 2.1 Desenho (grade; x para a direita, y para baixo; 1 unidade = `map.unit_px` = **40 px** na base 640x360 do Diretor de Arte)
Com 40 px, o par mais perto fica a 57 px (diagonal), acima do mínimo do Diretor de Arte (40 px entre nós pequenos, 52 px com marco; conferido por script em todos os pares). O mundo tem 21 × 17 unidades = **840 × 680 px**, contra uma janela de 630 × 329: dá umas 2 telas de largura e 2 de altura para arrastar.
Legenda: C = CORPO, K = CAMPANHA do centro, E = ESTILO, G = Garagem, P = Campanha, A = Academia, B = Boxe, J = Jiu-jitsu, L = ligação. `*` = marco, `+` = ligação.
```
y\x     -9    -8    -7    -6    -5    -4    -3    -2    -1     0     1     2     3     4     5     6     7     8     9    10    11
 -8      .     .     .     .     .     .     .     .     .B:bell     .     .     .     .     .     .     .     .A:part     .     .
 -7      .     .     .     .     .     .     .     .     .     .     .     .     .L+:mir     .     .     .     .     .     .     .
 -6      .     .     .     .     .     .     .B:wrap     .     .     .B:foot     .     .     .     .     .A*:fan     .     .     .
 -5      .     .     .     .     .     .     .     .     .B*:cou     .     .     .     .     .A:mirr     .     .     .     .     .
 -4      .     .     .     .     .L+:sho     .     .     .     .     .     .     .     .     .     .     .     .A:leag     .     .
 -3      .     .     .     .     .     .     .     .     .E*:box     .     .     .     .     .     .A:memb     .     .     .     .
 -2      .     .     .     .C:heav     .C*:mus     .     .     .     .     .K*:sco     .K:purs     .     .     .     .     .     .
 -1      .G*:met     .G*:rop     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .L+:rin     .
  0 G:shoe     .     .     .     .G:tape     . C:jab     .     .     .K:purs     .P:post     .     .P:spon     .     .     .     .
  1      .G*:cre     .G:radi     .     .     .     .     .     .     .     .     .     .     .     .     .     .P*:dia     .     .
  2      .     .     .     .C:crew     .C:crew     .     .     .     .     .K:crow     .K:good     .     .     .     .     .     .
  3      .     .     .     .     .     .     .     .     .E*:bjj     .     .     .     .     .     .     .     .     .     .P*:ext
  4      .     .     .     .     .L+:mat     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .
  5      .     .     .     .     .     .     .     .     .J*:gua     .     .     .     .     .     .     .     .     .     .     .
  6      .     .     .     .     .     .     .J:brea     .     .     .J:knot     .     .     .     .     .     .     .     .     .
  7      .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .     .
  8      .     .     .     .     .     .     .     .     .J:pati     .     .     .     .     .     .     .     .     .     .     .
```
- **Centro** (x −5..5, y −3..3): os 12 nós de hoje, com o mesmo id, o mesmo efeito e as mesmas ligações de antes (`requires` vira vizinho).
- **Garagem** a oeste, **Campanha** a leste, **Boxe** ao norte, **Jiu-jitsu** ao sul e **Academia** a nordeste. As 4 ligações ficam nas diagonais: Garagem–Boxe (Grito), Garagem–Jiu-jitsu (equipe), Academia–Boxe (clique) e Academia–Campanha (dinheiro).
- **"+1 dia"** fica no canto mais longe (11, 3), a 4 compras do centro: `career_purse` → `camp_poster` → `camp_sponsor` → `camp_diary` → `camp_extra_day`.

### 2.2 Tabela
`requires_art`: o efeito só vale **jogando aquela arte** (como o ESTILO hoje), inclusive os efeitos genéricos dos ramos de arte (`box_footwork`, `bjj_breath`).

| id | região | tipo | pos | vizinhos | Legado | efeito | revela quando |
|---|---|---|---|---|---|---|---|
| `body_jab` | CORPO | pequeno | -2,0 | career_purse, body_muscle_memory, body_crew, gar_tape | 10 | `click_bonus` +100% | sempre (raiz) |
| `body_muscle_memory` | CORPO | **marco** | -3,-2 | body_jab, body_heavy_hands | 30 | `metronome_start` 1 | vizinho comprado |
| `body_crew` | CORPO | pequeno | -3,2 | body_jab, body_crew_2 | 150 | `passive_bonus` +50% | vizinho comprado |
| `body_heavy_hands` | CORPO | pequeno | -5,-2 | body_muscle_memory | 500 | `click_bonus` +50% | vizinho comprado |
| `body_crew_2` | CORPO | pequeno | -5,2 | body_crew | 800 | `passive_bonus` +50% | vizinho comprado |
| `career_purse` | CAMPANHA (centro) | pequeno | 2,0 | body_jab, career_scouting, career_crowd, camp_poster | 10 | `money_bonus` +50% | sempre (raiz) |
| `career_scouting` | CAMPANHA (centro) | **marco** | 3,-2 | career_purse, career_purse_2 | 25 | `preview_percent` 1 | vizinho comprado |
| `career_crowd` | CAMPANHA (centro) | pequeno | 3,2 | career_purse, career_good_loser | 250 | `fame_bonus` +50% | vizinho comprado |
| `career_purse_2` | CAMPANHA (centro) | pequeno | 5,-2 | career_scouting, gym_membership | 500 | `money_bonus` +50% | vizinho comprado |
| `career_good_loser` | CAMPANHA (centro) | pequeno | 5,2 | career_crowd | 700 | `defeat_share_bonus` +25% | vizinho comprado |
| `style_boxing` | ESTILO | **marco** | 0,-3 | box_counter | 1200 | `art_rule_bonus` +50% (só jogando Boxe) | sempre (raiz) + Boxe liberado |
| `style_bjj` | ESTILO | **marco** | 0,3 | bjj_guard | 1200 | `art_rule_bonus` +50% (só jogando Jiu-jitsu) | sempre (raiz) + Jiu-jitsu liberado |
| `gar_tape` | Garagem | pequeno | -4,0 | body_jab, gar_rope, gar_radio | 15 | `click_bonus` +25% | vizinho comprado |
| `gar_radio` | Garagem | pequeno | -6,1 | gar_tape, gar_crew_start, link_mat | 100 | `passive_bonus` +25% | vizinho comprado |
| `gar_rope` | Garagem | **marco** | -6,-1 | gar_tape, gar_metro, link_shout | 300 | `rope_installed` 1 | vizinho comprado |
| `gar_shoes` | Garagem | pequeno | -9,0 | gar_metro, gar_crew_start | 300 | `click_bonus` +25% | vizinho comprado |
| `gar_metro` | Garagem | **marco** | -8,-1 | gar_rope, gar_shoes | 400 | `metronome_start` 2 | vizinho comprado |
| `gar_crew_start` | Garagem | **marco** | -8,1 | gar_radio, gar_shoes | 600 | `start_generator` 5 × neighbor_kid | vizinho comprado |
| `camp_poster` | Campanha | pequeno | 4,0 | career_purse, camp_sponsor | 20 | `money_bonus` +25% | vizinho comprado |
| `camp_sponsor` | Campanha | pequeno | 7,0 | camp_poster, camp_diary | 300 | `fame_bonus` +25% | vizinho comprado |
| `camp_diary` | Campanha | **marco** | 9,1 | camp_sponsor, camp_extra_day, link_ring | 700 | `legacy_bonus` +15% | vizinho comprado |
| `camp_extra_day` | Campanha | **marco** | 11,3 | camp_diary | 1800 | `prep_days_bonus` 1 | vizinho comprado |
| `gym_membership` | Academia | pequeno | 7,-3 | career_purse_2, gym_mirror, gym_league | 150 | `money_bonus` +25% | sempre (raiz) + academia |
| `gym_mirror` | Academia | pequeno | 6,-5 | gym_membership, gym_fan, link_mirror | 250 | `click_bonus` +25% | vizinho comprado + academia |
| `gym_league` | Academia | pequeno | 9,-4 | gym_membership, gym_fan, link_ring | 300 | `fame_bonus` +25% | vizinho comprado + academia |
| `gym_partner` | Academia | pequeno | 9,-8 | gym_fan | 500 | `passive_bonus` +25% | vizinho comprado + academia |
| `gym_fan` | Academia | **marco** | 8,-6 | gym_mirror, gym_league, gym_partner | 700 | `gym_training_bonus` +25% | vizinho comprado + academia |
| `box_counter` | Boxe | **marco** | 0,-5 | style_boxing, box_wraps, box_footwork | 200 | `art_fight_bonus` +10% (só jogando Boxe) | sempre (raiz) + Boxe liberado |
| `box_footwork` | Boxe | pequeno | 2,-6 | box_counter, box_bell, link_mirror | 300 | `click_bonus` +25% (só jogando Boxe) | vizinho comprado + Boxe liberado |
| `box_wraps` | Boxe | pequeno | -2,-6 | box_counter, box_bell, link_shout | 400 | `art_rule_bonus` +25% (só jogando Boxe) | vizinho comprado + Boxe liberado |
| `box_bell` | Boxe | pequeno | 0,-8 | box_wraps, box_footwork | 800 | `art_rule_bonus` +25% (só jogando Boxe) | vizinho comprado + Boxe liberado |
| `bjj_guard` | Jiu-jitsu | **marco** | 0,5 | style_bjj, bjj_knot, bjj_breath | 200 | `art_fight_bonus` +10% (só jogando Jiu-jitsu) | sempre (raiz) + Jiu-jitsu liberado |
| `bjj_breath` | Jiu-jitsu | pequeno | -2,6 | bjj_guard, bjj_patience, link_mat | 300 | `passive_bonus` +25% (só jogando Jiu-jitsu) | vizinho comprado + Jiu-jitsu liberado |
| `bjj_knot` | Jiu-jitsu | pequeno | 2,6 | bjj_guard, bjj_patience | 400 | `art_rule_bonus` +25% (só jogando Jiu-jitsu) | vizinho comprado + Jiu-jitsu liberado |
| `bjj_patience` | Jiu-jitsu | pequeno | 0,8 | bjj_knot, bjj_breath | 800 | `art_rule_bonus` +25% (só jogando Jiu-jitsu) | vizinho comprado + Jiu-jitsu liberado |
| `link_ring` | Ligação | ligação | 10,-1 | gym_league, camp_diary | 300 | `money_bonus` +50% | vizinho comprado |
| `link_mat` | Ligação | ligação | -4,4 | gar_radio, bjj_breath | 400 | `passive_bonus` +50% | vizinho comprado |
| `link_mirror` | Ligação | ligação | 4,-7 | box_footwork, gym_mirror | 400 | `click_bonus` +50% | vizinho comprado |
| `link_shout` | Ligação | ligação | -4,-4 | gar_rope, box_wraps | 500 | `crew_click_bonus` +0.5 s | vizinho comprado |

**Totais por região (Legado):** CORPO 1490, CAMPANHA (centro) 1485, ESTILO 2400, Garagem 1715, Campanha 2820, Academia 1900, Boxe 1700, Jiu-jitsu 1700, Ligação 1600 | tudo 16810
**Útil para quem joga só Boxe: 13910 ; só Jiu-jitsu: 13910**

### 2.3 Marcos e ritmo (anti-planilha)
| Região | Caminho típico (robô) | Marco no caminho |
|---|---|---|
| Garagem | fita → rádio → **corda montada** → **pêndulo** → tênis → **turma** | 3 marcos em 6 nós |
| Campanha | cartaz → rádio do bairro → **caderno (+15% Legado)** → **+1 dia** | 2 em 4 |
| Academia | carteirinha → espelho → liga → **ventilador (+25% na academia)** → parceiro | 1 em 5 (a academia já tem o marco "lugar novo") |
| Boxe / Jiu-jitsu | **contragolpe / base firme** (raiz) → 2 pequenos → sino / paciência | o marco é a porta de entrada |
| Ligações | **Grito mais alto** é marco; as outras são "+50%" (o dobro de um nó pequeno) | — |
- Nenhum nó novo é menor que +25% (ou +15% no Legado, que soma em todo o fim de campanha). Os "+%" pequenos usam **1 ícone por tipo de efeito** (seção 9).

### 2.4 Por que esses preços
- **Orçamento:** quem joga uma arte só tem 34 nós úteis (os 39 menos os 4 do ramo da outra arte e o ESTILO dela), que somam **13.910 de Legado**. O Legado por campanha é ~80 (campanha 1), ~1.700 (chegada), ~2.500 e depois ~3.300–3.800 (com fama e caderno). A soma passa de 13.910 entre a 6ª e a 7ª campanha (seção 5).
- **Os 12 do centro não mudaram de efeito.** Mudaram dois preços: `body_crew_2` 900 → **800** e `career_good_loser` 800 → **700** (o escopo deixa mexer nesses preços; ver o topo da seção 5). `style_bjj` e `style_boxing` ficam em **1.200**.
- O robô compra o **mais barato à vista** (seção 5.2). Os nós caros (ESTILO 1.200, +1 dia 1.800) ficam para o fim, como para um jogador que gasta o que tem.

---

## 3. Efeitos novos (fórmulas)

| `effect.type` | Onde age | Fórmula | Texto do cartão |
|---|---|---|---|
| `rope_installed` (value 1) | início da campanha | `jump_rope` entra montada: sem compra em Treino, **sem caixa**, sem "chegou equipamento". A esteira continua na caixa. As melhorias da corda continuam à venda. A regra "a corda pede a esteira" não vale para a corda montada | COMEÇA A CAMPANHA COM A CORDA NO LUGAR |
| `start_generator` (value n, `target`) | início da campanha | `qtd[target] = n` (já contratados). O preço do próximo segue `base × growth^qtd`. Valor: **5 Vizinhos** | COMEÇA COM {n} VIZINHOS NA GARAGEM |
| `metronome_start` (já existe) | início da campanha | `nível = max(valores)`. `gar_metro` = **2** (`body_muscle_memory` continua 1) | COMEÇA COM O METRÔNOMO NO NÍVEL {n} |
| `prep_days_bonus` (value 1) | calendário | `fight_day = dia_da_última_luta + prep_days(próximo) + Σ bônus`, nas **6** lutas (Dudu conta do Dia 1) | +{n} DIA DE PREPARO ANTES DE CADA LUTA |
| `crew_click_bonus` (value 0,5) | clique da mão | `crew_share_efetivo = crew_click.crew_share + Σ bônus` (**1,0 → 1,5 s** da equipe por clique). Só com o Grito comprado na LOJA. Sem o Grito, o cartão diz "PEDE O GRITO DA EQUIPE (LOJA)" | GRITO DA EQUIPE: CADA CLIQUE VALE +{n} S |
| `gym_training_bonus` (value 0,25) | multiplicador do local | academia: `training_mult × (1 + Σ)` = **×2,0 → ×2,5**. Garagem: igual | TREINO NA ACADEMIA +{pct}% |
| `art_fight_bonus` (value 0,10, `requires_art`) | traço de luta da arte | Boxe: `damage_mult × (1 + Σ)` (1,10 → 1,21). Jiu-jitsu: `taken_mult × (1 − Σ)` (0,90 → 0,81). Entra no cálculo da prévia | BOXE: +{pct}% DE DANO NA LUTA / JIU-JITSU: -{pct}% DE DANO RECEBIDO |
| `legacy_bonus` (value 0,15) | fim da campanha | `Legado ganho = floor(Legado_base × (1 + Σ))`, em qualquer fim (derrota, passar o posto, aposentar). A tela de fim mostra a linha "+15% caderno" | +{pct}% DE LEGADO NO FIM DA CAMPANHA |
- `{pct}` = `round(100 × value)`. `{n}` = `value` (inteiro, ou com 1 casa no Grito: "+0,5 S").
- Os tipos que já existem (`click_bonus`, `passive_bonus`, `money_bonus`, `fame_bonus`, `defeat_share_bonus`, `metronome_start`, `preview_percent`, `art_rule_bonus`) **somam como hoje**.
- Regra geral: **um nó com `requires_art` só vale jogando aquela arte**, qualquer que seja o tipo.

---

## 4. Kid

| | Força | Agilidade | Resistência | Data |
|---|---|---|---|---|
| Antes (5.3) | 4.600.000 | 8.050.000 | 20.700.000 | 16 dias (não muda) |
| **Agora** | **6.900.000** | **12.075.000** | **31.050.000** | 16 dias |
- **Kid ×1,5 nos três atributos.** Ele continua "RÁPIDO" (a proporção não muda), e o prêmio e a fama também ficam iguais.
- O resto da seção (por que ×1,5, o que testei e por que a meta de 70% não fecha) está na **seção 5.4**.

---

## 5. Simulação

**Mudei sem pedido (5 itens, aceitos pelo Diretor):** (a) `body_crew_2` 900→800; (b) `career_good_loser` 800→700; (c) nó de arte só vale jogando a arte; (d) entrada de cada ramo de arte vira raiz; (e) nós novos de fama e Legado. Detalhes: Os preços do centro que mudaram (`body_crew_2`, `career_good_loser`) são de nós que o escopo deixa mexer ("e outros, se precisar"). Fora do texto do escopo, decidi três regras: (1) **um nó com `requires_art` só vale jogando aquela arte**, também nos efeitos genéricos (é a regra do ESTILO, estendida); (2) a **entrada de cada ramo de arte** (`box_counter`, `bjj_guard`) é raiz e aparece quando a arte é liberada, como o ESTILO; (3) a fama e o Legado ganharam nós novos (`camp_sponsor`, `gym_league`, `camp_diary`). Por isso o Legado por campanha sobe de ~2.500 para ~3.300–3.800 depois da 4ª campanha. Isso entrou no orçamento da árvore.

### 5.1 O que mudou no simulador
- **Mapa:** lê `skill_tree.json` v2 (vizinhos, raízes e travas). A trava `gym` abre depois da 1ª campanha que chega à academia, e as artes abrem junto.
- **Robô da árvore:** entre uma campanha e outra, compra o **nó mais barato à vista** que o Legado paga (empate: id) e repete até não caber nada. Ele nunca compra o ramo da arte que não joga. Tudo vale na campanha seguinte (1.4).
  - "Fechar" = comprou os **34 nós úteis** do perfil (os 39 menos os 5 da outra arte).
  - O robô "dica" da 5.3 (ordem fixa) não serve para um mapa que se revela. O mais barato primeiro é o jeito de quem gasta o que tem.
- **Efeitos novos** (seção 3): corda montada, Vizinhos de saída, +1 dia, Grito +0,5, academia ×2,5, traço de luta da arte e +15% de Legado.
- O resto é o simulador da 5.3: calendário, robô paciente (antes da data só luta no verde; no dia luta no amarelo e passa o posto no vermelho), caixas, luvas e bolsa.
- **Rodada final:** `f54x` com **400 jogadores por perfil e arte × 10 campanhas**, `b23c` com 2.000 e `f54dia` com 96 × 10 (mais a variante sem +1 dia e sem corda).

### 5.2 Critérios (400 jogadores por perfil e arte, 10 campanhas)
| Critério | Meta | **Agora** | Situação |
|---|---|---|---|
| Árvore fecha (34 nós úteis) | 5ª–8ª campanha | mediana **6** (Boxe 3/4/5 e JJ 5/s) e **7** (JJ 3/4/s); p10–p90 **6–7 / 6–8**; 100% fecham até a 10ª | **fecha** |
| Boxe × JJ até o Kid (tempo na campanha com arte) | ≤ 10% | **6,9% / 9,4% / 9,4%** (5/4/3 por s; Boxe na frente a 5/s, JJ a 3–4/s) | **fecha** (no limite a 3–4/s) |
| Boxe × JJ até o 1º Kid (tempo de jogo acumulado) | (leitura) | 8,0% / 3,1% / **21,5%** | a 3/s o JJ chega depois (5.4) |
| Kid: campanhas até o Kid, contando a da chegada (mediana) | 1–2 | **1** nos 6 perfis (p90: 1–4) | **fecha** |
| Kid a 3/s: JJ não fica atrás | JJ ≤ Boxe | mediana 1 × 1; **média 2,07 × 1,17** | **fecha na mediana, não na média** (5.4) |
| Kid a 5/s: Boxe à frente ≤ 0,3 campanha | ≤ 0,3 | média 1,34 × 1,53: **0,19** | **fecha** |
| Kid na 1ª tentativa (robô que espera o verde) | ≤ 70% | **72,5 / 69,2 / 95,5 / 91,8 / 89,0 / 56,2%** (B5/J5/B4/J4/B3/J3); média 79% (5.3: 79–98%) | **não fecha**: só o JJ 5/s e o JJ 3/s ficam em ≤ 70% (5.4) |
| 1ª derrota compra ≥ 1 nó | todos | **100%** das campanhas 1 com Legado > 0 (derrota ou passar o posto). Quem perde para o Dudu (2–4%) sai com Legado 0, como na 5.3 | **fecha** (exceção herdada) |
| 23b (2.000 jogadores) | ≤ 25% ±2; ninguém antes de 19:30; ≤ 1% antes de 20:00 | **26,4% / 0,2%** (5/s / 4/s); mais cedo **20:44**; p1 21:00; **0** antes de 20:00 | **fecha**, igual à 5.3 (a campanha 1 não tem árvore) |
| 1ª derrota da campanha 1 | 10–15 min | **13:39 / 14:39** (5/s / 4/s); a 3/s quase todos passam o posto (fim da campanha 1 ~15 min, igual à 5.3) | **fecha** |
| Cinturão amador | 2ª–4ª campanha | mediana **2** (p10–p90: 1–2 a 5/s; 2–3 a 3–4/s) | **fecha** (o "1" é o 23b) |
| Tempo morto, campanha 1, 3/s (p90) | ≤ 10:32 | **6:00** (4/s 6:00; 5/s 7:43–9:02) | **fecha** |
| Tempo morto, academia (p90) | ≤ 10:00 | **4:30–7:27** | **fecha** |
| "Próxima coisa", academia (p90) | ≤ 10:00 | 3:56–5:39 | **fecha** |
| Clique no fim do conteúdo, árvore cheia | ≥ 25% da renda | **66–85%** (5.9) | **fecha** |

### 5.3 Kid por perfil e arte (`f54`, 400 × 10)
| Perfil | Campanhas até o Kid, contando a da chegada (med; p10–p90; média) | Kid na 1ª tentativa | 1ª tentativa sem vitória | Tempo de jogo até o 1º Kid (med) | Kid nas campanhas com arte (min na campanha, med) |
|---|---|---|---|---|---|
| Boxe 5/s | 1 (1–2); 1,34 | 72,5% | passou o posto 101, derrota 9 | 38:53 | 7:52 |
| Jiu-jitsu 5/s | 1 (1–3); 1,53 | 69,2% | passou 105, derrota 18 | 42:00 | 8:25 |
| Boxe 4/s | 1 (1–1); 1,07 | 95,5% | derrota 15, passou 3 | 40:21 | 9:45 |
| Jiu-jitsu 4/s | 1 (1–1); 1,21 | 91,8% | derrota 25, passou 8 | 41:35 | 8:55 |
| Boxe 3/s | 1 (1–2); 1,17 | 89,0% | derrota 43, passou 1 | 45:37 | 10:50 |
| Jiu-jitsu 3/s | 1 (1–4); 2,07 | 56,2% | derrota 95, passou 80 | 55:26 | 9:55 |
- "1ª tentativa" = a 1ª campanha em que o Kid é o próximo adversário (o jogador venceu o Tonhão). Vencer = vencer o Kid nessa campanha. Passar o posto no vermelho conta como não vencer.
- **Contagem:** "campanhas até o Kid" conta a da chegada (1 = venceu na chegada). Na 5.2 a conta era "depois da chegada" (0 = na chegada). As duas metas dizem a mesma coisa: Kid na campanha da chegada ou na seguinte.
- A 5/s, 26% dos jogadores pegam o cinturão na campanha 1 (23b) e chegam ao Kid **sem nenhum nó**. São eles que passam o posto ("passou 101"). A 3–4/s, a chegada é na campanha 2, já com 5 nós.

### 5.4 Kid: por que ×1,5 e por que os 70% não fecham
Teste com 48 jogadores × 4–5 campanhas, Kid na 1ª tentativa (B5 / J5 / B4 / J4 / B3 / J3) e média de campanhas do JJ 3/s:
| Kid (F × A × R) | 1ª tentativa | JJ 3/s: mediana; média |
|---|---|---|
| ×1,0 (5.3) | 88 / 75 / 100 / 100 / 94 / 100 (16 jogadores) | 1; 1,00 |
| ×1,4 | 83 / 83 / 98 / 94 / 96 / 75 | 1; 1,81 |
| **×1,5 (escolhido)** | 83 / 79 / 96 / 94 / 88 / 63 (com 400: 73 / 69 / 96 / 92 / 89 / 56) | **1; 2,07** |
| ×1,6 | 81 / 79 / 94 / 85 / 85 / **35** | **3**; 3,31 |
| ×1,8 | 83 / 79 / 85 / 58 / 54 / **2** | **4**; 4,81 |
| só Força ×2,5 | 81 / 81 / 94 / 90 / 90 / 73 | 1; 2,04 |
| só Força ×3,5 (32 jog.) | 69 / 75 / 91 / 72 / 66 / — | — (JJ 4/s: p90 "nunca") |
| "canhão de vidro" F ×5, R ×0,7 | 71 / 63 / 73 / 44 / 29 / **2** | **3**; 4,69 |
| só Agilidade ×1,5 / só Resistência ×1,6 / só Força ×1,6 | quase igual ao ×1,0 | 1 |
| ×1,6 com JJ recebendo −20% ou −25% de dano (traço da arte) | J3 44% | 3 |
- **A causa:** a data do Kid é fixa (16 dias = 8 min de sala depois do Tonhão). O tempo até o verde é quase fixo para cada velocidade de clique. Por isso a chance de vencer na 1ª tentativa é quase um degrau por perfil: 100% até um certo Kid e 0% logo depois. O degrau do 5/s fica muito acima do degrau do 3/s (cerca de 1,7× mais treino por minuto).
- **O Jiu-jitsu a 3/s é o 1º a cair.** Na campanha da chegada ele treina mais devagar que o Boxe depois do Tonhão: a regra dele multiplica a equipe, que no Kid é ~4% do treino. É o mesmo motivo que fez a 5.3 calibrar a data do Kid pelo JJ 3/s.
- **Nenhum formato de Kid** (mais Força, mais Agilidade, canhão de vidro) leva o 4/s a ≤ 70% sem levar o JJ 3/s a 3 campanhas ou mais. Isso fura a trava "mediana 1–2" do escopo. Reforçar o traço de luta do JJ também não resolve (−25% de dano: 44%).
- **Escolhi ×1,5**, o maior Kid em que o JJ 3/s ainda vence na mediana na 1ª campanha da academia (56% na 1ª tentativa). O Kid ficou um pouco menos fácil: média de 79% (era 79–98% por perfil), com 5/s ~70%, JJ 3/s 56% e 4/s 92–96%.
- **Meta que proponho no lugar de "≤ 70% em todo perfil":** "Kid na 1ª tentativa ≤ 80% na **média** dos 6 perfis (robô que espera o verde), com a mediana de 1–2 campanhas em todos". Motivo: o robô por perfil é um degrau, e o jogador de verdade fica entre os perfis (clica mais rápido ou mais devagar, espera ou não espera o verde). Com ×1,5, a média dá **79%**. Para o 4/s chegar a 70%, só com outra alavanca: data do Kid (proibida), JJ mais forte na academia (fora do escopo) ou uma arte que não dependa da equipe.

### 5.5 Boxe × Jiu-jitsu
| Medida (mediana) | 5/s | 4/s | 3/s |
|---|---|---|---|
| **Até o Kid, na campanha com arte desde o minuto 0** (o critério) | 7:52 × 8:25 → **6,9%** | 9:45 × 8:55 → **9,4%** | 10:50 × 9:55 → **9,4%** |
| Até o 1º Kid, tempo de jogo acumulado | 8,0% | 3,1% | **21,5%** (JJ depois) |
| Campanhas até o Kid (média) | 1,34 × 1,53 | 1,07 × 1,21 | 1,17 × **2,07** |
| Cinturão amador nas campanhas com arte (medida da 5.2, só leitura) | 2,6% | 22,6% (JJ na frente) | 20,4% (JJ na frente) |
- **O critério fecha** na medida da 5.2, agora no Kid: tempo até o Kid numa campanha que já começa com a arte. Fica no limite a 3–4/s (o JJ na frente). Alavancas se precisar: `style_bjj` mais caro ou `bjj_knot`/`bjj_patience` (regra do JJ) mais fracos.
- A distância no tempo acumulado a 3/s é a 1ª tentativa no Kid (5.4), não a árvore.
- O cinturão amador continua com o JJ ~20% na frente a 3–4/s, como na 5.2/5.3 (a garagem é onde a equipe pesa). O escopo da 5.4 mede até o Kid. Deixo o número para o Diretor ver.

### 5.6 A árvore fecha na 6ª–7ª campanha
| Perfil | Fecha (med; p10–p90) | Legado por campanha (1..6) |
|---|---|---|
| Boxe 5/s, JJ 5/s | 6 (6–7) | 80 / 1.710 / 2.490 / 3.270 / 3.760 / 3.760 |
| Boxe 4/s | 6 (6–8) | igual |
| Jiu-jitsu 4/s | 7 (6–8) | 80 / 1.710 / 2.490 / 3.270 / 3.270 / 3.760 |
| Boxe 3/s | 6 (6–8) | igual ao 5/s |
| Jiu-jitsu 3/s | 7 (6–8) | 80 / 1.110 / 1.590 / 2.883 / 3.270 / 3.760 |
- Era a 4ª na 5.3 (12 nós, 4.375 de Legado). Agora são 34 nós úteis e 13.910 de Legado.
- **Ordem real (Boxe 4/s, campanha da compra, mediana):** depois da campanha 1, `body_jab`, `career_purse`, `gar_tape`, `camp_poster` e `career_scouting` (5 nós com 80 de Legado). Depois da 2: `body_crew`, `body_muscle_memory`, `box_counter`, `box_footwork`, `career_crowd`, `gar_radio`, `gym_membership` e `gym_mirror` (8 nós). Depois da 3: corda montada, pêndulo, tênis, cartaz da liga, colchão... Depois da 4: Grito mais alto, caderno, turma. Depois da 5: ventilador, sino, Garagem lotada, Saber cair e parceiro. Depois da 6: **+1 dia** e `style_boxing` (os dois mais caros).
- **Sempre tem um pedacinho novo:** depois de cada campanha, de 2 a 3, o robô compra **5 a 8 nós**. Na 6ª–7ª compra os últimos 2 a 4.
- **Tempo:** a árvore fecha com **~1h40 a 2h** de jogo (6–7 campanhas de 13–17 min).

### 5.7 O que não podia piorar (`b23c`, 2.000 jogadores, campanha 1)
| Perfil | Cinturão na 1ª | Mais cedo | p1 | Antes de 20:00 | Fim da campanha 1 (med; p10–p90) | 1ª derrota (med) | Passou o posto na campanha 1 |
|---|---|---|---|---|---|---|---|
| 5/s | 26,4% | 20:44 | 21:00 | 0 | 13:39 (12:26–21:39) | 13:39 | 933 |
| 4/s | 0,2% | 22:58 | — | 0 | 14:09 (13:26–14:56) | 14:09 | 1.718 |
| 3/s | 0% | — | — | 0 | 15:26 (14:26–15:56) | (só Dudu) | 1.891 |
- **Idêntico à 5.3** número a número: a campanha 1 começa sem nós, e o Kid não aparece na campanha 1 antes do cinturão.
- Tempo morto (maior trecho; mediana / p90 / pior), 400 × 10: campanha 1 a 3/s **5:30 / 6:00 / 6:12**; a 4/s 5:00 / 6:00; a 5/s 5:00 / 7:43–9:02. Academia, todas as campanhas: p90 **4:30–7:27**, pior 11:02 (JJ 4/s, 1 caso). "Próxima coisa" na academia: p90 3:56–5:39.
- Cinturão amador: campanha **2** de mediana em todos os perfis (p10–p90: 1–2 a 5/s, 2–3 a 3–4/s).

### 5.8 +1 dia e corda montada na tabela "luta no dia × antes" (`f54dia`, 96 × 10, campanhas 2+)
| Grupo | Campanhas | Antes da data | No dia | Vermelho no dia | Dias da campanha (med; p90) | Corda na mão aos (med) |
|---|---|---|---|---|---|---|
| Boxe 5/s, mapa completo | 864 | 99,9% | 0,1% | 0,1% | 12; 31 | 0:00 |
| ↳ só campanhas com **+1 dia** | 351 | 100% | 0% | 0% | 12; 12 | 0:00 |
| ↳ só campanhas com **corda montada** | 672 | 100% | 0% | 0% | 12; 20 | **0:00** |
| Boxe 5/s, mapa **sem** +1 dia e **sem** corda | 864 | 99,9% | 0,1% | 0,1% | 12; 31 | **0:29** |
| Jiu-jitsu 3/s, mapa completo | 864 | 95,9% | 4,1% | 1,9% | 18; 53 | 0:00 |
| ↳ só com +1 dia | 263 | 100% | 0% | 0% | 14; 16 | 0:00 |
| ↳ só com corda montada | 622 | 99,9% | 0,1% | 0,1% | 16; 29 | 0:00 |
| Jiu-jitsu 3/s, **sem** os dois | 864 | 95,9% | 4,1% | 1,9% | 20; 53 | **0:46** |
(Boxe 3/s e Jiu-jitsu 5/s ficam entre os dois: a corda sem o nó chega aos 0:35–0:40.)
- **Corda montada:** a corda está na mão no segundo 0, em vez de **0:29–0:46** (compra de 1.500 de Treino + caixa). É a 1ª compra grande da Garagem (campanha 3, mediana) e vale em 72–78% das campanhas 2+. O "chegou equipamento" continua na esteira, no aparelho da arte e nas luvas.
- **+1 dia:** é o último nó que o robô compra (campanha 7–8). Nessa altura ele já vence tudo antes da data, então **não muda nada para o robô**: 0% de luta no dia, contra 0,1–4% sem o nó. Cada campanha ganha 6 dias de folga (3 min de sala). Para o 3/s, o +1 dia cai bem no Kid: hoje 25% das lutas do JJ 3/s com o Kid são no dia, e 11% no vermelho. Mas o nó chega tarde demais para essa 1ª tentativa.
- **O calendário não afrouxa:** o nó fica longe do centro e é o mais caro. Por isso o efeito só aparece quando a campanha já está resolvida, que é o que o escopo pediu. Para o jogador lento ou AFK, ele é um respiro: a data chega 30 s depois em cada luta.

### 5.9 Late game com a árvore cheia (tabela fixa, refeita)
Kid vencido em campanhas **depois** de a árvore fechar. 1 clique sem crítico e sem FRENESI, com o Grito (1,5 s). Renda sem a mão = equipe + Metrônomo.
| Perfil | Kids | 1 clique / renda sem a mão (med; pior) | Mão / equipe / Metrônomo por s (med) | Kid: min na campanha |
|---|---|---|---|---|
| Boxe 5/s | 1.386 | **85%; 85%** | 296K / 4,2K / 54K | 7:47 |
| Jiu-jitsu 5/s | 1.347 | **83%; 66%** | 213K / 16,4K / 25K | 7:55 |
| Boxe 4/s | 1.254 | **85%; 85%** | 236K / 4,1K / 54K | 8:19 |
| Jiu-jitsu 4/s | 1.214 | **66%; 66%** | 212K / 16,0K / 51K | 8:25 |
| Boxe 3/s | 1.260 | **85%; 85%** | 177K / 4,1K / 54K | 10:19 |
| Jiu-jitsu 3/s | 1.046 | **67%; 66%** | 158K / 16,2K / 51K | 8:55 |
| Meta | | **≥ 25%** | | |
- Subiu em relação à 5.2/5.3 (58–72%), por causa do **Grito mais alto** (1,0 → 1,5 s da equipe por clique) e dos nós de clique. O clique segue sendo a maior fonte nos dois estilos. O JJ tem a equipe ~4× maior que a do Boxe, como deve.
- Todas as campanhas (com árvore parcial): 44–76% (pior 44%, JJ na chegada, ainda sem os nós). Continua acima de 25%.



---

## 6. Save v10 (migração)

### 6.1 Campos
| Campo | Tipo | Padrão / inválido | O que é |
|---|---|---|---|
| `permanent.skill_nodes` | Array[String] | `[]` | **igual a hoje** (ids comprados, na ordem da compra) |
| `career.active_nodes` | Array[String] | cópia de `skill_nodes` | foto dos nós que valem nesta campanha (1.4) |
| `permanent.tree_last_node` | String | último de `skill_nodes`, ou `""` | onde o mapa centraliza ao abrir |
- Ids de `skill_nodes` que não existem mais em `data/` ficam no save e não fazem nada. Eles **não são apagados**, para o caso de um nó voltar. Ids repetidos: fica 1.

### 6.2 Migração `_migrar_9_para_10`
| Save v9 | Resultado |
|---|---|
| Qualquer um | `skill_nodes` igual. **Legado igual** (sem reembolso, sem cobrança). `active_nodes = skill_nodes` (hoje tudo o que foi comprado já vale). `tree_last_node = skill_nodes[-1]` ou `""` |
| Com nós comprados | Os nós ficam acesos no **centro** (mesmos ids, mesmas posições do mapa). Os vizinhos ficam **à vista** sozinhos, pela regra 1.1 (nada a gravar). Ex.: com `body_jab` comprado, `gar_tape` aparece à vista |
| Com `body_crew_2` ou `career_good_loser` comprados (preço caiu 100) | continuam comprados; **nada é devolvido** |
| Com arte liberada | `style_*`, `box_counter`, `bjj_guard` e `gym_membership` aparecem à vista (são raiz com a trava aberta) |
| Tela de fim pendente | igual. A próxima NOVA CAMPANHA tira a foto `active_nodes` normalmente |
- Nada mais muda: calendário, caixas, luvas, Grito, Metrônomo, arte, local e atributos.
- **Testes de migração só na pasta de save de teste**, nunca no save real (critério 13). Casos: save v9 sem nós; com os 12; com `style_bjj` e arte liberada; com tela de fim pendente; com id desconhecido em `skill_nodes`.

---

## 7. Contrato de dados (para o Programador)

### 7.1 `data/skill_tree.json`, versão 2
```json
{
  "version": 2,
  "map": { "unit_px": 40, "origin": [0, 0], "start_visible": "root" },
  "branches": [ ... ],                       // SÓ para o carregador antigo (3 abas); o novo ignora
  "regions": [ { "id": "garage", "name": "GARAGEM", "lock": "", "icon": "region_garage" }, ... ],
  "nodes": [
    { "id": "gar_rope", "region": "garage", "kind": "milestone", "pos": [-6, -1], "root": false,
      "neighbors": ["gar_tape", "gar_metro", "link_shout"], "cost": 300,
      "effect": { "type": "rope_installed", "value": 1 },
      "name": "Corda montada", "description": "...", "effect_text": "COMEÇA A CAMPANHA COM A CORDA NO LUGAR",
      "icon": "skill_m_rope" }
  ]
}
```
| Campo do nó | Tipo | Regra / padrão se faltar |
|---|---|---|
| `id` | String | único; repetido → ignora o 2º com aviso |
| `region` | String | id de `regions`; desconhecido → nó ignorado com aviso |
| `kind` | `small` \| `milestone` \| `link` | padrão `small` (só muda a moldura) |
| `pos` | [float, float] | unidades da grade; faltando → nó ignorado com aviso; posição repetida → só aviso |
| `root` | bool | padrão `false` |
| `neighbors` | Array[String] | **simétrico**: o carregador soma a volta se faltar (com aviso); id desconhecido → removido com aviso |
| `lock` | String | padrão = `lock` da região; valores: `""`, `"gym"`, `"art:<id>"` |
| `requires_art` | String | padrão `""`; efeito só vale com essa arte |
| `cost` | int ≥ 1 | inválido → nó ignorado |
| `effect` | `{type, value, target?}` | tipo desconhecido → nó ignorado; `value` ≥ 0; `start_generator` sem `target` válido → ignorado |
| `name`, `description`, `effect_text`, `icon` | String | textos do Roteirista; ícone da seção 9 |
| `branch`, `requires` | String | **só nos 12 antigos**, para o carregador antigo. O novo ignora |
- Um nó sem `root` e sem vizinho válido fica inalcançável: aviso no carregamento (o teste de dados falha).
- **Compatibilidade:** os 27 nós novos não têm `branch`. O carregador antigo (`fight_data.gd`, 3 abas) ignora esses nós com aviso e continua vendo **exatamente os 12** (`test_fase4.gd` "12 nós" continua passando até o Programador trocar o carregador). Depois da troca, o teste passa a esperar 39 e `branches` pode sair do arquivo.
- `regions[].name` é o que aparece no mapa. O ramo `career` aparece como **CAMPANHA** (critério 9). Também troquei `ui_texts.json → tree_branch_career` para "CAMPANHA". Os ids `career_*` **não mudam**.

### 7.2 Estado e funções (`GameState`)
- `estado_no(id) -> "owned" | "visible" | "hidden"` (regra 1.1); `pode_comprar_no(id)`; `comprar_no(id)` (aceita a qualquer hora em que o mapa abre, não só na tela de fim).
- `arvore_tem_compra() -> bool`: o brilho do botão (critério 2; teste automático).
- `bonus_ativos()` passa a ler `career.active_nodes`. `_recalcular_bonus()` roda **só** ao começar uma campanha e ao carregar o save.
- Sinais: `arvore_mudou()` (já existe), mais `no_revelado(ids: Array)` para a animação dos vizinhos novos.
- Onde o mapa **não** abre: luta, dia da luta, escolha da arte e caixa no meio da abertura (decisão 1).

### 7.3 Efeitos novos no código
| Tipo | Onde ler | Teste |
|---|---|---|
| `rope_installed` | `nova_campanha()`: põe `jump_rope` em aparelhos montados, sem caixa | campanha seguinte começa com a corda; a esteira ainda chega na caixa |
| `start_generator` | `nova_campanha()`: `qtd[target] = value` | 5 Vizinhos no Dia 1; preço do 6º = 60 × 1,25^5 |
| `prep_days_bonus` | onde calcula `fight_day` | todas as datas +1 (Dudu: 13 em vez de 12...) |
| `crew_click_bonus` | `extra_grito()` | Grito comprado: 1 clique = 1,5 × equipe/s; sem Grito: 0 |
| `gym_training_bonus` | `mult_local()` | academia ×2,5; garagem ×1 |
| `art_fight_bonus` | traço de luta da arte (luta e prévia) | Boxe dano ×1,21; Jiu-jitsu recebido ×0,81 |
| `legacy_bonus` | cálculo do Legado no fim | Legado × 1,15 (arredonda para baixo) |

### 7.4 Testes (pasta de save de teste)
- Revelação: com `body_jab` comprado, `gar_tape`, `body_muscle_memory`, `body_crew` e `career_purse` estão à vista; `gar_rope` está escondido.
- Travas: sem arte liberada, nenhum nó de `gym`, `boxing` ou `bjj` fica à vista, nem por ligação (`link_shout` à vista não revela `box_wraps`).
- Brilho: Legado 9 com só raízes de 10 → sem brilho; Legado 10 → brilho.
- "Vale na próxima": comprar `body_heavy_hands` no meio da campanha não muda `por_clique()`; depois de NOVA CAMPANHA, muda.
- Os 6 efeitos novos (tabela 7.3) e a migração (6.2).
- Mudar `cost` ou `value` no JSON muda o jogo sem código (critério 5).
- **Testes antigos que mudam:** `tests/test_fase5.gd` linha 115 confere o F/A/R do Kid (4,6M / 8,05M / 20,7M). Ela passa a esperar **6,9M / 12,075M / 31,05M**. `test_fase4.gd` ("12 nós") passa a esperar 39 quando o carregador novo entrar.

### 7.5 Tudo o que mudou em `data/` nesta fase
| Arquivo | Campo | Antes | Agora | Motivo |
|---|---|---|---|---|
| `skill_tree.json` | formato | v1 (12 nós, 3 ramos) | **v2** (39 nós, mapa, `regions`) | escopo 3.1 |
| `skill_tree.json` | `branches[career].name` | CARREIRA | **CAMPANHA** | decisão 7 |
| `skill_tree.json` | `body_crew_2.cost` | 900 | **800** | fechar a árvore na 5ª–8ª (seção 5) |
| `skill_tree.json` | `career_good_loser.cost` | 800 | **700** | idem |
| `opponents.json` | Kid (`opp_gym_2`) F/A/R | 4,6M / 8,05M / 20,7M | **6,9M / 12,075M / 31,05M** | escopo 3.3 (Kid menos fácil) |
| `ui_texts.json` | `tree_branch_career` | CARREIRA | **CAMPANHA** | decisão 7 |

---

## 8. Para o Roteirista
- **Nome do ramo:** CAMPANHA (já aplicado; troque se achar melhor). Como a região leste também se chama Campanha, sugiro dar outro nome a uma das duas. Por exemplo: centro "CAMPANHA" e região leste "EMPRESÁRIO" ou "AGENDA".
- **Regiões:** GARAGEM, ACADEMIA, BOXE, JIU-JITSU, CAMPANHA (leste). As ligações não têm nome de região.
- **Cartão:** "VALE NA PRÓXIMA CAMPANHA", "PEDE O GRITO DA EQUIPE (LOJA)" (no Grito mais alto sem o Grito) e "SÓ VALE JOGANDO DE {arte}" (já existe).
- **Nomes dos 27 nós novos (provisórios, ≤ 16 caracteres, tom pé no chão):** a tabela abaixo. A frase (`description`) também é provisória, com ≤ 45 caracteres.

| id | região | tipo | nome provisório | car. | frase provisória | texto do efeito |
|---|---|---|---|---|---|---|
| `gar_tape` | Garagem | pequeno | Fita no punho | 13 | Esparadrapo da farmácia. Segura tudo. | +{pct}% TREINO POR CLIQUE |
| `gar_radio` | Garagem | pequeno | Rádio no muro | 13 | Pagode baixinho. A turma treina no ritmo. | +{pct}% TREINO/S DA EQUIPE |
| `gar_rope` | Garagem | marco | Corda montada | 13 | O varal agora é seu. A vizinha desistiu. | COMEÇA A CAMPANHA COM A CORDA NO LUGAR |
| `gar_metro` | Garagem | marco | Pêndulo de casa | 15 | O tique-taque já mora na garagem. | COMEÇA COM O METRÔNOMO NO NÍVEL {n} |
| `gar_crew_start` | Garagem | marco | Turma de sempre | 15 | O vizinho já chega de luva. | COMEÇA COM {n} VIZINHOS NA GARAGEM |
| `gar_shoes` | Garagem | pequeno | Tênis de sola | 13 | Sola nova, pé firme, soco sentado. | +{pct}% TREINO POR CLIQUE |
| `camp_poster` | Campanha | pequeno | Cartaz na venda | 15 | Seu nome do lado do pão de queijo. | +{pct}% DINHEIRO POR VITÓRIA |
| `camp_sponsor` | Campanha | pequeno | Rádio do bairro | 15 | O locutor erra seu nome. Mas fala. | +{pct}% FAMA POR VITÓRIA |
| `camp_diary` | Campanha | marco | Caderno do velho | 16 | Cada luta anotada. Cada erro também. | +{pct}% DE LEGADO NO FIM DA CAMPANHA |
| `camp_extra_day` | Campanha | marco | Um dia a mais | 13 | O empresário empurra a data. Você agradece. | +{n} DIA DE PREPARO ANTES DE CADA LUTA |
| `gym_membership` | Academia | pequeno | Carteirinha | 11 | Sócio da academia. Tem até foto 3x4. | +{pct}% DINHEIRO POR VITÓRIA |
| `gym_mirror` | Academia | pequeno | Espelho grande | 14 | Você se vê errando. Erra menos. | +{pct}% TREINO POR CLIQUE |
| `gym_league` | Academia | pequeno | Liga do bairro | 14 | Tabela na parede, seu nome a lápis. | +{pct}% FAMA POR VITÓRIA |
| `gym_fan` | Academia | marco | Ventilador novo | 15 | Ninguém desmaia. Todo mundo treina. | TREINO NA ACADEMIA +{pct}% |
| `gym_partner` | Academia | pequeno | Parceiro fixo | 13 | Segura o saco e não reclama. | +{pct}% TREINO/S DA EQUIPE |
| `box_wraps` | Boxe | pequeno | Faixa nas mãos | 14 | Enrolada do jeito que o velho mandou. | BOXE: BÔNUS DO CLIQUE CRESCE {pct}% |
| `box_counter` | Boxe | marco | Contragolpe | 11 | Ele erra, você não perdoa. | BOXE: +{pct}% DE DANO NA LUTA |
| `box_footwork` | Boxe | pequeno | Jogo de pernas | 14 | Dança na ponta do pé. Bate parado. | +{pct}% TREINO POR CLIQUE |
| `box_bell` | Boxe | pequeno | Ouvido de sino | 14 | Você ouve a pera até dormindo. | BOXE: BÔNUS DO CLIQUE CRESCE {pct}% |
| `bjj_knot` | Jiu-jitsu | pequeno | Nó da faixa | 11 | Apertado. Não solta nem no banho. | JIU-JITSU: BÔNUS DA EQUIPE CRESCE {pct}% |
| `bjj_guard` | Jiu-jitsu | marco | Base firme | 10 | Empurra, puxa. Você não sai do lugar. | JIU-JITSU: -{pct}% DE DANO RECEBIDO |
| `bjj_breath` | Jiu-jitsu | pequeno | Respirar fundo | 14 | Embaixo dele, você conta até dez. | +{pct}% TREINO/S DA EQUIPE |
| `bjj_patience` | Jiu-jitsu | pequeno | Paciência | 9 | Quem tem pressa bate no chão. | JIU-JITSU: BÔNUS DA EQUIPE CRESCE {pct}% |
| `link_shout` | Ligação | ligação | Grito mais alto | 15 | A garagem inteira grita junto. | GRITO DA EQUIPE: CADA CLIQUE VALE +{n} S |
| `link_mat` | Ligação | ligação | Colchão no chão | 15 | Dois colchões velhos e muita vontade. | +{pct}% TREINO/S DA EQUIPE |
| `link_mirror` | Ligação | ligação | Pera emprestada | 15 | A academia empresta. Você devolve suado. | +{pct}% TREINO POR CLIQUE |
| `link_ring` | Ligação | ligação | Cartaz da liga | 14 | Seu nome impresso. Com acento e tudo. | +{pct}% DINHEIRO POR VITÓRIA |

---

## 9. Para o Diretor de Arte (compatível com `direcao-visual.md` §21 e o `manifest.json → skill_map`)
Li a §21, que foi feita em paralelo. **Ajustei os dados a ela; não pedi peça nova de tela.**
| Pedido da §21 | Como ficou nos dados |
|---|---|
| Distância mínima entre centros: 40 px (pequeno) / 52 px (marco) | `map.unit_px` = **40**. O par mais perto fica a 57 px. Conferido por script em todos os 741 pares |
| 3 formas: pequeno 24, marco 38, ligação 28x24 | `kind` = `small` / `milestone` / `link` (39 nós: 23 pequenos, 12 marcos, 4 ligações) |
| Tom do anel por ramo/região | `region` = `body`, `career`, `style`, `garage`, `gym`, `boxing`, `bjj`, `campaign`, `link`. A ligação comprada usa o par `<a>_<b>` dos vizinhos: `link_shout` garage_boxing, `link_mat` garage_bjj, `link_mirror` gym_boxing, `link_ring` gym_campaign |
| Pintura das regiões (célula mais perto até 44 px) | as regiões ficam em blocos separados (2.1). Centro x −5..5; Garagem x ≤ −4; Campanha x ≥ 4, y ≥ −1; Academia x ≥ 6, y ≤ −3; Boxe y ≤ −5; Jiu-jitsu y ≥ 5 |
| Nó pequeno usa o ícone do **tipo** (`icon_by_effect`) | o campo `icon` dos nós novos já aponta para esses ícones: `skill_body_jab` (clique), `skill_body_crew` (equipe), `skill_career_purse` (dinheiro), `skill_career_crowd` (fama), `skill_style_boxing`/`skill_style_bjj` (regra da arte), `icon_legacy_16` (Legado) |
| Ícones novos `skill_rope_ready`, `skill_prep_day`, `skill_shout_loud` | usados em `gar_rope`, `camp_extra_day` e `link_shout` |
| Nomes dos tipos novos ("sugestão") | os tipos ficaram `rope_installed` e `prep_days_bonus` (a §21 sugeria `rope_start` e `prep_day`). Basta trocar as 2 chaves em `icon_by_effect`. Também entram `start_generator`, `gym_training_bonus`, `art_fight_bonus` e `legacy_bonus` (seção 3) |
| Marcos sem ícone próprio usam `icon_region_<região>` até a 2ª passada | é o que está no JSON: `gar_metro`, `gar_crew_start` (garage), `gym_fan` (gym), `box_counter` (boxing), `bjj_guard` (bjj) |

**2ª passada de ícones (a lista que a §21.9 pedia):** **6 ícones de marco**, 16x16.
| Nó | Ideia (pé no chão) |
|---|---|
| `gar_metro` "Pêndulo de casa" | metrônomo de madeira em cima de um tijolo |
| `gar_crew_start` "Turma de sempre" | três chinelos na porta da garagem |
| `camp_diary` "Caderno do velho" | caderno de capa dura com elástico (hoje usa `icon_legacy_16`) |
| `gym_fan` "Ventilador novo" | ventilador de coluna |
| `box_counter` "Contragolpe" | luva vermelha com seta curva |
| `bjj_guard` "Base firme" | dois pés firmes no tatame |
- As 3 ligações reusam o ícone do tipo dentro da peça de ligação. Não precisam de ícone próprio.
- Os 12 do centro reusam os `skill_body_*`, `skill_career_*` e `skill_style_*` de hoje.
- O botão da sala, o cartão, a faixa "VALE NA PRÓXIMA CAMPANHA", as linhas, a neblina e as plaquinhas de região já estão na §21. Não mudo nada nelas.

---

## Resumo
- **Mapa de 39 nós:** os 12 de hoje no centro, com os mesmos ids e efeitos. Em volta: Garagem 6, Campanha 4, Academia 5, Boxe 4, Jiu-jitsu 4 e 4 ligações. São 12 marcos com efeito novo: corda montada, pêndulo nível 2, 5 Vizinhos de saída, caderno +15% de Legado, +1 dia, academia ×2,5, contragolpe/base firme e Grito mais alto (1,0 → 1,5 s). Ficam à vista as raízes e os vizinhos do que foi comprado. Academia e artes só abrem com a trava. Tudo vale na próxima campanha (`career.active_nodes`).
- **Preços:** 1º nó de cada região 15–200. Marcos de 200 a 1.800 (+1 dia, o mais longe e o mais caro). São 13.910 de Legado para os 34 nós úteis de cada arte. No centro, só `body_crew_2` (800) e `career_good_loser` (700) mudaram.
- **Kid ×1,5** (6,9M / 12,075M / 31,05M), com a data igual.
- **Fecha:**
  - árvore na **6ª–7ª** campanha (p90 8);
  - Boxe × JJ até o Kid **6,9 / 9,4 / 9,4%**;
  - Kid em **1** campanha de mediana em todos os perfis;
  - a 5/s o Boxe abre só **0,19** campanha;
  - 23b igual à 5.3 (**26,4%**, mais cedo 20:44);
  - 1ª derrota 13:39 / 14:39;
  - cinturão na campanha 2;
  - morto p90 ≤ 9:02;
  - clique no fim do conteúdo **66–85%**.
- **Não fecha:**
  - **Kid na 1ª tentativa ≤ 70%:** fica em 56–96% por perfil (média 79%). A data fixa transforma a 1ª tentativa num degrau por velocidade de clique, e o Jiu-jitsu 3/s cai primeiro. Proponho a meta "≤ 80% na média dos perfis, com mediana 1–2" (5.4).
  - **JJ 3/s:** empata com o Boxe na mediana, mas fica atrás na média (2,07 × 1,17 campanhas).
  - **Cinturão amador nas campanhas com arte:** o JJ segue ~20% na frente a 3–4/s, como na 5.3 (só leitura).
- **Save v10:** `active_nodes` e `tree_last_node` novos. O resto fica igual, sem reembolso, e os vizinhos abrem sozinhos pela regra de revelação.

---

## Decisões do Diretor (design 5.4)
Data: 2026-11-13. O texto completo está em `fase5.4-escopo.md`, na seção de mesmo nome. Estas decisões valem no lugar da 3.3 e do critério 11 do escopo.
1. **Kid na 1ª tentativa:** fica o **Kid ×1,5**. A meta passa a ser **média dos 6 perfis ≤ 80%**, **nenhum perfil < 50%**, mediana 1–2 campanhas e **p90 ≤ 4** em todos. Hoje fecha (79%; menor JJ 3/s 56%; p90 1–4). O 4/s a 92–96% fica registrado para uma fase que mexer nas artes.
2. **JJ 3/s atrás do Boxe:** aceito. "Não fica atrás" vale **na mediana** (1 × 1). Tetos: média do JJ 3/s **≤ 2,2** campanhas (hoje 2,07) e tempo acumulado até o 1º Kid **≤ 25%** depois do Boxe 3/s (hoje 21,5%). Não volta para ×1,4.
3. **Mudanças sem pedido: todas aceitas.**
   - `body_crew_2` 800 e `career_good_loser` 700.
   - `requires_art` só vale jogando a arte, em qualquer efeito. Condição: o cartão de **todo** nó dos ramos de arte mostra "SÓ VALE JOGANDO DE {arte}".
   - `box_counter` e `bjj_guard` são raiz e aparecem com a arte.
   - `camp_sponsor`, `gym_league` e `camp_diary`. Condição: `camp_diary` é o **único** multiplicador de Legado da 5.4.
4. **Correção pedida:** reescrever a linha "Mudei sem pedido" (topo da seção 5) listando essas 5 mudanças, em vez de "nenhum".
5. **Nenhum número de `data/` muda** por causa destas decisões. O QA confere as metas novas (itens 1 e 2) rodando o simulador.
