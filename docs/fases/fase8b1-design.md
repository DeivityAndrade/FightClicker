# Fase 8b1 — Liga nacional: design

Designer de Jogo, 2026-11-27. Base: `fase8b-escopo.md` (§3.1, §5, critérios 1–6, 19, 20) com as decisões do Produtor (perguntas 1, 2,
4 e 5 pela recomendação do Diretor: divisão 8b1→8b4; o cinturão nacional fica com um **campeão nacional próprio** e o James preparado é a
**3ª luta**; nenhum prêmio de poder no Ringue; o Osmar só em balões). Padrão seguido: `fase8a1-design.md` (liga regional, passivas de
adversário, James Blindado) e `fase8a2-design.md` (centro).
Simulador: `tools/sim/fase8b1_sim.py` (roda em cima do `fase8a2_sim.py`; **só acrescenta**). Dados gravados: `data/league_national.json`
(novo). Casos exatos: `tests/data/fase8b1_casos.json` (192). **[ROT]** = nome ou texto provisório (Roteirista).

## 0. A ideia em uma frase
Quem vence o James regional (Cinturão do Vale) muda para o centro, e **do centro sai a liga nacional**: 4 lutas na arena nacional. Os 2
nacionais travam os 2 jeitos que a liga regional deixou livres (Contragolpista e Canela); o **James preparado** volta estudando o jeito com
que a escola o venceu da última vez; o **campeão nacional** "lê todo mundo" um pouco. Vencer o campeão dá o **cinturão nacional** e
"COMPLEXO DE ELITE LIBERADO".

| Ordem | id | Nome [ROT] | Perfil | F / A / R | Total | Passiva (id) | O que faz |
|---|---|---|---|---|---|---|---|
| 11 | `opp_nac_1` | Nacional 1 | RESISTENTE | 300M / 250M / 700M | 1,25B | `adv_cold_read` [ROT] | **Contragolpista**: o K.O. de contragolpe ×0,25 |
| 12 | `opp_nac_2` | Nacional 2 | FORTE | 900M / 500M / 1,2B | 2,6B | `adv_oak_leg` [ROT] | **Canela**: o chute rodado derruba ×0,25 |
| 13 | `opp_james_nac` | James Blindado (preparado) | RESISTENTE | 500M / 1,6B / 2,3B | 4,4B | `adv_blindado_study` | guarda do 1º round (×0,6) **+ a trava do jeito que ele estudou** |
| 14 | `opp_nac_champ` | Campeão nacional | EQUILIBRADO | 1,95B / 1,95B / 3,5B | 7,4B | `adv_champion` [ROT] | **todos os 6 jeitos ×0,5** no golpe que decide |
Para comparar: James regional 560M; Apagão 2,5B. Ao chegar no centro o robô tem ~0,5B de atributos, e cresce ~0,2–0,3B por minuto (Boxe e
Muay Thai) ou ~0,6–0,9B por minuto (Jiu-jitsu) (§8).

## 1. Como a liga abre
- A escada passa a ser `opponents.json` (6) + `league_regional.json` (4) + **`league_national.json` (4)**, nessa ordem. O índice só cresce:
  10 = Nacional 1, 13 = campeão, 14 = escada completa. Arquivo ausente = jogo da 8a2.
- Os nacionais têm `location: "center"` e `league: "national"`. **Não precisa de regra nova de abertura:** depois do James, o próximo
  adversário pede o centro, e o jogo já faz o resto (`estado_escada() == "move"`): o HUD mostra a mudança, o relógio da campanha **não
  conta** enquanto o jogador não muda (regra B3 da 5.3), e a data da 1ª luta nacional sai na chegada.
- **Some o "SEM LUTA NOVA POR ENQUANTO"** do centro (8a2): ele só aparecia porque a escada acabava no James. Agora o centro mostra
  `PRÓXIMA LUTA NACIONAL: {d} DIAS` [ROT] (chave `league_national_next`). "CAMPANHA COMPLETA" só volta depois do campeão.
- A janela de vitória do James ganha o convite (`league_national_invite_*` [ROT]), no lugar do `belt_regional_soon` quando a liga existe.
- **Fala do Osmar:** marco `national_league_opened` na 1ª chegada ao centro com a liga (1 vez na linhagem), 1 balão [ROT]. Save antigo
  parado no centro: ao carregar (padrão `liga_regional.ao_carregar`).
- **Dias de preparo** (regra da 5.3, contados da luta anterior; o nó `prep_days_bonus` e o `league_prep_days_bonus` da Ronda valem):
  Nacional 1 **16**, Nacional 2 **16**, James **18**, campeão **18** (8, 8, 9 e 9 min de sala; a liga cabe em ~34 min de centro).
- **Nada muda até a chegada ao centro:** tudo depende de o jogador ter passado do James. Perder um nacional encerra a carreira como hoje
  (Legado ×0,5); passar o posto no vermelho do dia também.
- **Convite do Osmar e AQUECIDO** seguem na liga nacional (o jogo já os corta só com a escada completa). A fama da Panfletagem continua
  limitada ao Kid (`indice_do_kid`), sem mudança.
- **Patrocínio (8a2):** vale nas vitórias nacionais como em qualquer vitória (+50% do prêmio base). Nenhum número novo.

## 2. Arena nacional
`league_national.json → fight_arena: "arena_nacional"`. A regra da 8a1 já cobre: `arena_da_luta(opp)` = a arena da liga do adversário.
Como agora há 2 ligas, `FightData` guarda a arena **por liga** (`ligas[id].fight_arena`), não uma só (`liga` vira lista; ver §11).
Direção (Diretor de Arte, mockup antes): degrau acima da regional — ginásio grande/estádio coberto, **telão** com o rosto dos lutadores,
**câmera de TV nacional** na lateral, luzes de cima em cruz, público em arquibancada alta (pode reaproveitar o público com paleta nova).
Nome [ROT] (`arena_nacional_name`).

## 3. As passivas dos nacionais (só dado; mesmo motor da 8a1)
Todas usam `locks` (multiplicador num campo da **sua** passiva, por tipo) e/ou `guard`, as duas contas que o motor já tem. **Nenhum
sorteio novo, nenhuma conta nova.** A prévia, o risco do HUD, o motivo e a luta usam a mesma função: a prévia continua honesta.

| Passiva | Campo | Valor | Efeito | Escapa quem |
|---|---|---|---|---|
| `adv_cold_read` (Nacional 1) | `locks.counter_punch.ko_per_charge`, `ko_cap` | ×0,25 / ×0,25 | o K.O. de contragolpe quase não sai; a carga e o contragolpe ainda batem | Mão rápida e as 4 de JJ/MT |
| `adv_oak_leg` (Nacional 2) | `locks.shin.spin_ko` | ×0,25 | o chute rodado quase não derruba; as marcas e o crítico ainda valem | Clinch e as 4 de Boxe/JJ |
| `adv_blindado_study` (James) | `guard` + `study[tipo]` | guarda 1 round ×0,6; trava do tipo estudado (§4) | — | quem **mudou de jeito** só pega a guarda |
| `adv_champion` (campeão) | `locks.<os 6>` | ×0,5 nos campos de K.O./queda/pegada/rodado/clinch de cada jeito (tabela abaixo) | todo jeito decide pior; ninguém fica sem saída | ninguém trava inteiro |

Travas do campeão (×0,5): `fast_hands {ko_per_streak, ko_cap}`, `counter_punch {ko_per_charge, ko_cap}`, `submission {sub_base, sub_cap}`,
`top_control {td_base, td_cap}`, `shin {spin_ko}`, `thai_clinch {clinch_base, clinch_cap}`.

**Por que estes jeitos:** a liga regional travou Mão rápida, Por cima e Clinch. A nacional trava os outros dois que ainda estavam livres de
uma arte para outra (Contragolpista e Canela). A **Finalização** fica sem trava de lutador nacional de propósito: era a mais lenta até o
Cinturão do Vale (8a1 §10.1). Cada jeito continua travado no máximo uma vez por um lutador fixo; o James e o campeão travam "de passagem".

### 3.1 Sinal na luta (só visual, o mesmo sorteio)
Os 3 sinais da 8a1 ficam. Os novos seguem a mesma regra exata ("sem a trava este `r_arte` teria dado certo, com ela não deu"), marcando
`opp_block` no evento:
| Trava | Quando marca | O que se vê [arte/ROT] |
|---|---|---|
| Contragolpe (Nac 1, campeão, James) | tentativa de K.O. de contragolpe com `ko_com ≤ r_arte < ko_sem` | ele recebe o contragolpe e não cai: "LEU O CONTRA" |
| Canela (Nac 2, campeão, James) | chute com a perna cheia e `spin_com ≤ r_arte < spin_sem` | o rodado acerta e ele fica de pé: "PERNA DE PAU" |
| Finalização (campeão, James) | tentativa de finalização com `sub_com ≤ r_arte < sub_sem` | ele escapa da chave: "SAIU DA CHAVE" |
| Queixo, base larga, ensaboado (campeão, James) | a regra da 8a1 | os sinais da 8a1 |
`*_sem` = o estado da passiva calculado sem `passiva_adv` (o motor já calcula duas vezes no preparo). Programador: 3 casos novos em
`_bloqueio`, só comparação, sem sorteio.

### 3.2 Prévia e motivo
`previa()` contra os nacionais traz as chaves da 8a1 (`opp_passive_id|name|line|hits|hits_text|icon`). O campeão sempre "atrapalha"
(`ATRAPALHA: {jeito} (METADE)` [ROT]). O motivo (`motivo.opp_note`) segue a 8a1: perdeu e `opp_blocks ≥ 1` (Nac 1, Nac 2, campeão) ou
sempre (James, pela guarda, como hoje). Textos `reason_opp_<id>` e `tip_opp_<id>` [ROT].

## 4. James preparado: ele estuda a escola
### 4.1 A regra (sem conta nova no motor)
- O jogo guarda, na linhagem, **o tipo da sua passiva** (`fast_hands`, `counter_punch`, `submission`, `top_control`, `shin`,
  `thai_clinch`) em **toda vitória da escola sobre o James** (regional ou nacional): `escola.rival.last_win_type` e
  `last_win_campaign`. Quando a vitória é de uma campanha nova, o valor anterior passa para `prev_win_type`.
- **Tipo estudado** = o jeito da última vitória da escola **numa campanha anterior**:
  `estudado = last_win_type se last_win_campaign < campanha atual; senão prev_win_type` ("" = nunca).
- A passiva efetiva dele na luta = `guard` + `locks: {estudado: study[estudado]}`. Com `estudado == ""` (a 1ª vez de toda linhagem, e
  save antigo sem o campo), ele usa **só a guarda** — a padrão, o Blindado da 8a1.
- `study` = a trava que já existe para aquele jeito: **Mão rápida** = queixo de ferro (×0), **Por cima** = base larga (×0,25), **Clinch** =
  ensaboado (×0,3 / solta ×2), **Contragolpista** = a do Nacional 1, **Canela** = a do Nacional 2. A única trava que só ele tem é a da
  **Finalização** (`sub_base` ×0,3, `sub_cap` ×0,3).
- É o mesmo caminho da 8a1 (`_passiva_ef(adv)` com `locks`): a passiva dele é montada **antes** da prévia, e prévia, risco, motivo e luta
  usam a mesma. **A prévia continua honesta por construção** (medida na §9.4).

**Por que "numa campanha anterior"** (e não a vitória sobre ele no regional, 15 min antes): o discípulo não troca de passiva no meio da
campanha (`passiva_carreira` é por carreira). Se o James estudasse a vitória da mesma campanha, ele travaria **sempre** o seu jeito e não
haveria escolha: viraria só um James mais forte. Assim, a escolha está no **próximo discípulo**: quem repete o jeito encontra o James pronto
para ele ("O BLINDADO ASSISTIU ÀS MINHAS LUTAS"); quem muda passa só pela guarda ("VOU MUDAR E PASSAR POR CIMA DELE"). Na 1ª campanha
nacional da linhagem ele ainda não estudou nada.

### 4.2 A prévia em 1 linha
| Situação | `opp_passive_hits` | `opp_passive_hits_text` [ROT] |
|---|---|---|
| Estudou o **seu** jeito | true | `ELE ESTUDOU O SEU {JEITO}` (ex.: "ELE ESTUDOU O SEU CONTRAGOLPE") |
| Estudou **outro** jeito | true (a guarda) | `ELE ESTUDOU O {JEITO}. VOCÊ MUDOU: SÓ A GUARDA` |
| Não estudou nada | true (a guarda) | `ATRAPALHA: TODOS NO 1º ROUND` (a da 8a1) |
`{JEITO}` = o nome do jeito (`passive_finish_*` / nome da passiva da 7b2). Chave nova na prévia: `opp_studied` (tipo, "" se nada).

### 4.3 Falas (caixa de diálogo, pulável; no máximo 1 antes e 1 depois por luta)
Ele **não** repete as falas do regional (risco do escopo §7). Grupos novos, escolhidos pelo `estudado` e pelo placar nacional:
| Momento | Quando | Grupos [ROT] |
|---|---|---|
| Antes | ao apertar LUTAR contra ele, 1 vez por campanha (`career.rival_spoke.before_nac`) | `rival_jn_intro_first` (estudado ""), `rival_jn_intro_studied` (estudou o seu), `rival_jn_intro_changed` (estudou outro) |
| Depois | fim da luta, 1 vez por campanha (`after_nac`) | `rival_jn_after_win_*` / `rival_jn_after_lose_*` × `first` (1ª luta nacional dele) / `many` |
Tom (escopo): continua arrogante, agora "levando a sério". O respeito é da 8b2 (não entra aqui).

## 5. O cinturão nacional
- **Cinturão nacional** = a escada passou do campeão (`national_belt: true` no dado). `cinturao_nacional()` = `indice_escada >
  índice(opp_nac_champ)` (não é salvo, como o regional).
- Tela de vitória: `belt_national_title` "CINTURÃO NACIONAL" [ROT], `belt_national_line` [ROT] e **"COMPLEXO DE ELITE LIBERADO"**
  (`belt_national_unlock`), com `belt_national_soon` "A MUDANÇA CHEGA NA PRÓXIMA VERSÃO" [ROT] (a mudança é da 8b2). Tela de fim da
  carreira: mostra os 3 cinturões; `summary.belts` conta os 3.
- Linhagem: `permanent.national_belts` (quantos) e `permanent.first_national_belt_campaign`. `escola.roster[].national_belt`. Marco
  `national_belt_first` (fala do Osmar 1 vez [ROT]).
- **Legado:** o pote continua `fama × 2 + 100 se cinturão amador`. Sem bônus pelo nacional. A fama nacional (600/700/800/1.000 = 3.100
  por campanha, antes dos nós) entra no pote normalmente; esse Legado sobra até a região ELITE da 8b2 (registrado, §9.6).
- **Honra:** a lista `per_win` repete o último valor (7): +7 por vitória nacional. Nada muda no hall.
- **Prêmios em dinheiro:** $45.000 / $60.000 / $80.000 / $120.000. Só compram LOJA no centro (não há mais mudança nesta fase).

## 6. Save (continua **v13**; só campos opcionais, sem migração)
| Onde | Campo | Valor | Validação |
|---|---|---|---|
| `career` | `ladder_index` (já existe) | agora até 14 | 0..tamanho da escada. Save no centro com 10 (o "fim" da 8a2) abre com o Nacional 1 e **folga cheia** (`fight_day` −1 vira data nova, regra da 5.3) |
| `career` | `rival_spoke` (já existe) | ganha `before_nac`, `after_nac` (bool) | ausente = falso; zera em `_zerar_carreira` |
| `career.fight.result` | `opp_blocks` (já existe) | conta também os sinais novos | — |
| `escola.rival` (já existe) | `last_win_type`, `prev_win_type` (string, um dos 6 tipos ou ""), `last_win_campaign` (int ≥ 0), `nac_met`, `nac_school_wins` (int ≥ 0) | ausente = "" / 0; tipo desconhecido = "" (aviso); `last_win_campaign` > campanha atual = campanha atual. **Campos planos** (a foto apaga `rival` por regex sem chaves internas) |
| `permanent` | `national_belts`, `first_national_belt_campaign` | int ≥ 0 | ausente = 0 |
| `escola.roster[]` | `national_belt` | bool | só gravado quando verdadeiro |
| marcos | `national_league_opened`, `national_belt_first` | marcos novos | falas saem 1 vez |
- **Save antigo da 8a2 parado na academia depois do James** (sem mudar): abre com o MUDAR do centro e a liga esperando; o relógio não conta.
- A cópia do save do dono abre sem erro (ele não tem o Cinturão do Vale: nada aparece).
- `tools/refatoracao/foto.gd`: tira `national_belts`, `first_national_belt_campaign` (lista do `permanent`) e o `national_belt` do roster.
  Os campos novos do `rival` já saem com o `rival` inteiro.

## 7. Nada muda antes da chegada ao centro (critério 1)
- **Por construção:** os nacionais estão depois do James na escada, e nada da 8b1 é lido antes de `indice_escada ≥ 10`. O único dado lido
  antes é o `last_win_type` gravado na vitória sobre o James regional, que fica dentro de `escola.rival` (a foto já o apaga) e não mexe em
  número nenhum.
- **Simulador (`fase8b1_sim.py ident`):** o mesmo jogador com e sem a liga nacional, 11 jogadores × 6 combinações × 4 e 3/s, até 7
  campanhas: todas as campanhas antes da do 1º Cinturão do Vale **e** a do Vale até a vitória sobre o James são iguais (fim, vitórias,
  lutas, calendário, Legado, Honra, arte). Resultado na §9.7.
- **No jogo:** `foto.gd` igual à main com cada combinação até a vitória sobre o James; `qa_f8a1_ident.gd` passa com o
  `league_national.json` presente.

## 8. Números de referência (curva)
Robô padrão da 8a2 (calendário, Legado, hall, centro; antes da data só luta no VERDE, no dia luta no AMARELO e passa o posto no VERMELHO),
agora mudando para o centro **na hora** em que vence o James e seguindo o calendário nacional.
Ao chegar no centro (todas as combinações): ~0,5B de atributos. Crescimento medido (`sonda`, mediana, 4/s, campanha do 1º Vale → 2 depois):
| Minutos no centro | 0 | 8 | 16 | 25 | 34 |
|---|---|---|---|---|---|
| Boxe Mão rápida | 0,55B | 1,9 → 2,4B | 3,8 → 5,2B | 6,0 → 8,2B | 8,5 → 11,6B |
| Jiu-jitsu Por cima | 0,52B | 4,4 → 6,1B | 9,4 → 13,2B | 15,3 → 22,0B | 21,7 → 31,5B |
| Muay Thai Clinch | 0,50B | 1,5 → 2,1B | 3,0 → 4,6B | 4,8 → 7,7B | 6,9 → 10,8B |
O Jiu-jitsu cresce **~2,5× mais** no centro: o bônus da equipe da arte multiplica os Alunos da Raízes (8a2 §7.1, "×11–12 aos 10 min"). A
diferença entre a campanha do 1º Vale e as seguintes (+30–40%) é a região CENTRO comprada depois da 1ª mudança. Depois dela, a linhagem
não cresce mais entre campanhas (a árvore está cheia até a 8b2).

## 9. Medidas (simulador)
Comandos (Python do Blender com `-I`): `fase8b1_sim.py campanha` (16 jogadores × 12 campanhas por linha, `SIM_CACHE8B` guarda os
estados das lutas), depois `trava saida honesta exportar` com o mesmo cache, `ident` (`SIM_NI=11 SIM_K8B=7`), `teto` e `chefe` (§10).
**Robô e o James:** o robô nunca troca de combinação. Então, da 2ª campanha nacional em diante, o James **sempre** estudou o jeito dele
(o pior caso: quem não muda). Na 1ª, só a guarda (16 de 16 linhagens em todas as linhas).

### 9.1 Como cheguei aos números
| Versão | Nac 1 / Nac 2 / James / campeão (total) | Dias | O que deu |
|---|---|---|---|
| 1ª | 1,6B / 3,2B / 5,2B / 11,5B | 16/16/18/22 | campeão **nunca** vencido por Boxe e Muay Thai; JJ em 0–1 campanha; tempo morto 11:48 |
| 2ª | 1,25B / 2,6B / 4,4B / 8,4B | 16/16/18/22 | Boxe 1, MT 2, JJ 0 campanhas depois do Vale (4/s); tempo morto 10:32–10:55 (passa de 10) |
| 3ª | idem / **8,0B** | **16/16/18/18** | tempo morto ≤ 9:47; mas MT 3/s quase murado (14 de 16 nunca; melhor tática no treino mediano 8–37% para MT e Contragolpista) |
| **final** | **1,25B / 2,6B / 4,4B / 7,4B** | **16/16/18/18** | tabelas abaixo |
A forma do adversário (mais força, agilidade ou resistência) e as travas mudam o limiar de 50% em só ±10% (sonda `probe`). O que separa
as combinações no centro é a **economia** (§8): nenhum adversário da liga consegue igualar um Jiu-jitsu que cresce 2,5× mais rápido.

### 9.2 Ritmo e equilíbrio (critério 5; `campanha`)
| Combinação | cps | 1º Vale (campanha) | **1º cinturão nacional: mediana** / média / p90 | **Campanhas do 1º Vale ao 1º nacional** (med; p90; distribuição 0/1/2/3/4/5/6+) | Nunca em 12 | Prévia na luta contra o campeão (med) | Fins no centro (os 3 mais comuns) |
|---|---|---|---|---|---|---|---|
| Boxe Mão rápida | 4 | 6 | **231:28** / 227:42 / 297:06 | **1**; 2; 8/6/2/0/0/0/0 | 0 | 91% | campeão 82, perdeu p/ campeão 8, perdeu p/ Nac 2 5 |
| Boxe Contragolpista | 4 | 5 | **272:00** / 265:04 / 331:49 | **1**; 4; 5/4/4/1/1/0/0 | 1 | 90% | campeão 59, perdeu p/ campeão 16, Nac 2 6 |
| JJ Finalização | 4 | 6 | **219:50** / 217:58 / 258:28 | **0**; 2; 12/2/1/1/0/0/0 | 0 | 93% | campeão 68, perdeu p/ campeão 9, James 4 |
| JJ Por cima | 4 | 6 | **204:25** / 193:59 / 236:14 | **0**; 2; 13/1/1/1/0/0/0 | 0 | 94% | campeão 88, Nac 2 4, campeão 4 |
| MT Canela | 4 | 6 | **288:33** / 285:36 / 353:55 | **2**; 7; 0/7/6/0/1/0/1 | 1 | 91% | campeão 47, passou no campeão 12, James 9 |
| MT Clinch | 4 | 7 | **302:52** / 292:03 / 333:26 | **1**; 3; 0/12/1/2/0/0/0 | 1 | 91% | campeão 47, passou no campeão 16, James 5 |
| Boxe Mão rápida | 3 | 6 | **309:25** / 306:30 / 370:11 | **2**; 3; 2/6/5/3/0/0/0 | 0 | 90% | campeão 62, Nac 2 10, campeão 10 |
| Boxe Contragolpista | 3 | 7 | **350:37** / 353:54 / 414:11 | **2**; 5; 0/6/4/3/0/3/0 | 0 | 81% | campeão 35, perdeu p/ campeão 21, passou 13 |
| JJ Finalização | 3 | 7 | **241:32** / 250:50 / 311:43 | **0**; 1; 11/4/1/0/0/0/0 | 0 | 93% | campeão 62, James 6, campeão 5 |
| JJ Por cima | 3 | 7 | **234:39** / 237:26 / 308:14 | **0**; 2; 13/1/1/0/1/0/0 | 0 | 93% | campeão 69, James 6, campeão 4 |
| MT Canela | 3 | 7 | **395:42** / 381:15 / 441:41 | **4**; nunca; 0/2/1/4/2/0/0 | 7 | 68% | campeão 19, passou 16, perdeu p/ campeão 13 |
| MT Clinch | 3 | 8 | **349:58** / 363:32 / 498:27 | **3**; nunca; 0/2/2/5/1/0/0 | 6 | 72% | passou 17, campeão 17, perdeu p/ campeão 14 |
| **Diferença entre as 6** | | | **4/s: 204–303 (48%) · 3/s: 235–396 (69%)** | **4/s: 0 a 2 · 3/s: 0 a 4** | | | |
("Nunca em 12" do Muay Thai a 3/s: o 1º Vale dele sai na campanha 7–8, então sobram só 4–5 campanhas no simulador; 6–7 de 16 não
fecharam até a 12ª.)
- **Campanhas depois do 1º Vale (meta 2–4):** cumprida no **Muay Thai** (2–4) e no **Boxe a 3/s** (2). O **Boxe a 4/s** e o **Muay Thai
  Clinch a 4/s** dão 1. O **Jiu-jitsu dá 0** em todas as linhas: ele vence o campeão já na campanha do 1º Vale.
- **Equilíbrio (meta ≤ 15%):** **não cumpre** (48% a 4/s, 69% a 3/s). É a economia do centro (§8), não a liga: o Jiu-jitsu chega ao
  campeão com ~2,5× os atributos do Muay Thai. Ver a decisão **D1**.
- **Quando cada luta vira vencível** (1ª campanha, contada a partir da do 1º Vale = 1, em que o robô lutou com ≥ 50% na prévia; mediana):
  Nacional 1, Nacional 2 e James = **1** em todas as linhas (p75 1–3). Campeão: **JJ 1** (todas), **Boxe 4/s 1–2**, **Boxe 3/s 2–3**, **MT 4/s
  2–3**, **MT 3/s 4**. O robô chega no campeão aos **15 min** de centro no JJ e aos **26–32 min** no Boxe e no Muay Thai.
- **Onde cada um empaca:** o Contragolpista no **campeão** (perde 16–21 vezes: a trava ×0,5 no contragolpe pesa mais nele, que já tinha
  passado pelo Nacional 1); o Muay Thai no **campeão** (passa o posto no vermelho) e no James estudado; o Jiu-jitsu quase não empaca.
### 9.3 Nunca imbatível (critério 4; `saida`)
Treino de referência = mediana dos atributos que os robôs daquela combinação tinham **ao lutar** com aquele adversário (quem passou o posto
fica fora, como na 8a1). James com o **seu** jeito estudado. Melhor tática (e, entre parênteses, no treino mediano de todos os robôs):
| | Mão rápida | Contragolpista | Finalização | Por cima | Canela | Clinch |
|---|---|---|---|---|---|---|
| Nacional 1 | 98% A (94%) | 96% A (72%) | 100% A (80%) | 98% A (98%) | 93% A (88%) | 87% D (72%) |
| Nacional 2 | 94% A (78%) | 92% C (62%) | 99% A (72%) | 98% A (90%) | 87% A (71%) | 76% D (65%) |
| James preparado | 99% D (54%) | 100% A (68%) | 95% A (88%) | 96% A (82%) | 93% A (78%) | 91% A (52%) |
| Campeão | 91% A (76%) | 81% A (69%) | 93% A (82%) | 93% A (91%) | 88% A (91%) | 72% D (58%) |
**Todas ≥ 72%** (meta ≥ 50%). Contra o James que estudou a Mão rápida, a melhor tática vira o **Defensivo** (99%): a trava fecha o K.O. de
embalo, e a saída é mudar de tática — o "vou mudar e passar por cima dele" dentro da mesma luta.

### 9.4 Quanto cada passiva tira (`trava`, no treino mediano × 0,85, melhor tática com / sem)
| Adversário | Mão rápida | Contragolpista | Finalização | Por cima | Canela | Clinch |
|---|---|---|---|---|---|---|
| Nacional 1 (contragolpe) | 0 | **−7** | 0 | 0 | 0 | 0 |
| Nacional 2 (rodado) | 0 | 0 | 0 | 0 | **−10** | 0 |
| James: **estudou o seu** / só a guarda / sem passiva | 16 / 24 / 57% (**−41**) | 26 / 33 / 46% (**−20**) | 55 / 67 / 80% (**−25**) | 50 / 70 / 82% (**−31**) | 42 / 48 / 58% (**−16**) | 23 / 67 / 80% (**−57**) |
| Campeão (todos ×0,5) | −6 | −9 | −9 | −24 | −6 | −14 |
- Os 2 nacionais tiram pouco (−7, −10): o K.O. de contragolpe e o rodado são uma parte menor das vitórias, e quem chega neles já está
  forte. O sinal na tela (§3.1) é o que faz a trava "aparecer". Alavanca, se o dono quiser mais: ×0 (só dado).
- **O James estudado é o degrau que se sente:** tira 16–57 pontos de quem repete o jeito; quem mudou de jeito ganha **6–44 pontos** de
  volta (a coluna "só a guarda"). Isso é a escolha do escopo, e a prévia diz qual é.
- O campeão tira um pouco de todos (−6 a −24): ninguém tem o seu jeito livre contra ele.

### 9.5 Prévia honesta (critério 4; `honesta`, 1.000 lutas por adversário e combinação, atributos reais × 0,6..1,4, tática sorteada)
| Adversário | Mostrada (média das 6) | Real | Diferença | Pior combinação |
|---|---|---|---|---|
| Nacional 1 | 64,3% | 64,4% | +0,1 | Contragolpista +1,9 |
| Nacional 2 | 62,7% | 63,3% | +0,6 | Contragolpista +1,9 |
| James preparado (estudou o seu jeito) | 59,5% | 59,0% | −0,5 | Finalização −1,4 |
| Campeão | 56,5% | 56,6% | +0,1 | Contragolpista +2,1 |
**Pior combinação isolada: 2,1 pontos** (meta ±5). Tela **8,0–19,0 s** em todas.

### 9.6 Metas de pé
| Meta | Medido |
|---|---|
| Tempo morto no centro ≤ 10 min | p90 **4:01–9:24** (máximo 9:54, MT Clinch 3/s); antes do centro p90 5:31–8:02 (igual à 8a2) |
| Luta 8–20 s | 8,0–19,0 s |
| 1 clique ≥ 25% da renda/s no cinturão nacional | **97–122%** (mediana), mínimo 95% |
| Tempo no centro por campanha | 11–14 min (JJ) a 22–29 min (Boxe e MT), mediana; p90 ≤ 34 min |
| Legado por campanha com a liga (mediana, campanhas depois do 1º nacional) | ~14–35 mil (sem destino até a região ELITE da 8b2) |
| 1ª carreira, cinturão amador, Kid, Cinturão do Vale | iguais (§9.7) |

### 9.7 Nada muda até a chegada ao centro (`ident`)
Sem e com a liga nacional, 11 jogadores × 6 combinações × 4 e 3/s (até a campanha 7): **132 de 132 jogadores iguais**, **5.412 lutas
comparadas** (todas as campanhas antes da do 1º Vale e, nela, todas as lutas até a vitória sobre o James, inclusive). Depois da chegada
ao centro, todas as campanhas mudam (é a liga agindo).

## 10. Pendências da 2a2 que entram aqui
### 10.1 `ronda2a_sim.py chefe` refeito, com a liga nacional (D6 da 2a1; "Fica para depois" da 2a2)
Rodado por `fase8b1_sim.py chefe` (importa o `ronda2a_sim` **depois** dos remendos da liga: a Ronda roda em cima da liga nacional), com o
Apagão dos dados (0,8× = 420M/840M/1,24B), 11 jogadores × 14 campanhas por linha, robô médio na Ronda, briga com ≥ 50%.
| Medida (132 linhagens) | 2a2 (sem a liga, 144 linhagens) | **8b1 (com a liga)** |
|---|---|---|
| Chefe abre (campanha, mediana; p25–p75) | 8 (7–10) | **8 (7–10)** |
| 1ª vitória (campanha) | 8 (7–10) | **8 (7–10)** |
| Noites abertas até vencer (mediana; p25–p75) | 2 (1–9) | **2 (1–3)** |
| Vence na 1ª noite aberta (meta ≤ 35%) | 34% | **32%** |
| Linha mais lenta (1ª vitória, mediana; meta ≤ 11) | 11 (MT Clinch 3/s) | **9** (Boxe Contragolpista, JJ Por cima 3/s, MT Canela 4/s, MT Clinch 3/s) |
| Nunca até a 14ª (meta ≤ 10%) | 4% | **0%** |
| Prévia na noite em que abre (mediana; p25–p75) | 4% (0–98) | 2% (0–96) |
| Desafio "ANTES DO APAGÃO" por tentativa (meta ≤ 20%) | 13% | **14%** (672 tentativas) |
| Raro feito até a 14ª | 70 de 138 | 95 de 132 (campanha 10, 4ª tentativa) |
- **Os critérios do Produtor seguem como na 2a2:** (b) 32% ≤ 35%, (c) todas as linhas até a campanha 9, (d) 0% nunca; o (a) continua
  falhando como aprovado (vence na mesma campanha em que abre, na 2ª noite). O desafio fica em 14% ≤ 20%.
- **O chefe ficou um pouco mais fácil para quem demora:** a campanha com a liga nacional é mais longa (mais capuzes) e o discípulo cresce
  muito no centro, então as noites depois do James pegam um vulto mais forte. O cartão do chefe abre na mesma campanha (é a lenda que manda),
  mas as últimas linhas vencem 2 campanhas antes e ninguém fica sem vencer. **Recomendo não mexer** no Apagão: a revisão da 2a2 já
  aceitou a curva "mais fácil que o (a)"; reavaliar só se os testadores acharem o chefe de graça.
A **noite animada cronometrada** (≤ ~60 s) é do QA, no jogo (não há como medir no Python).

### 10.2 Teto de 10% com tudo junto (`ronda2a_sim.py teto`, critério 6)
Rodado por `fase8b1_sim.py teto` (o mesmo `_forca_um` da 2a2, agora até o campeão nacional, com a mudança para o centro na vitória sobre o
James e o James estudando o jeito da combinação, `SIM_STUDY=own`), 12 jogadores, variantes `so_regiao` e `tudo_max` (+20%, o valor do
dono), CENTRO cheio e vazio, 6 combinações × 4 e 3/s, numa corrida só:
| Combinação | 4/s `so_regiao` / `tudo_max` | 3/s `so_regiao` / `tudo_max` |
|---|---|---|
| Boxe Mão rápida | 5,2 / 8,7% | 2,6 / 6,7% |
| Boxe Contragolpista | **9,4** / **9,4%** (Muralha) | 6,2 / 7,4% |
| JJ Finalização | 6,4 / 8,0% | 8,2 / **9,2%** (Nacional 2) |
| JJ Por cima | 4,5 / 8,1% | 7,4 / 9,0% |
| MT Canela | 5,0 / 6,5% | 6,8 / 6,8% |
| MT Clinch | 4,2 / 5,5% | 3,5 / 7,6% |
- **Pior trecho: 9,4% ≤ 10%** (Boxe Contragolpista 4/s, CENTRO cheio, no **Muralha** — um trecho antigo; a 2a2 mediu 8,8% ali com 24
  jogadores, então é ruído de 12 jogadores). **Pior trecho nacional: 9,2%** (JJ Finalização 3/s, Nacional 2). Os outros trechos nacionais
  ficam em 2–8%.
- **A liga nacional não abre margem nova:** ela não traz nó, região nem gerador; só mais lutas no fim da campanha. A fama nacional mexe no
  Legado, mas a forca já usa a árvore cheia. A margem segue curta (9,2–9,4%): se a 8b2 (região ELITE, gerador novo) passar de 10%, a regra
  da 2a vale — encolhe primeiro o ×1,2 da equipe do `cat_thanks`.

## 11. Contrato de dados
### 11.1 `data/league_national.json` (gravado)
| Campo | Onde | O que é |
|---|---|---|
| `id`, `after`, `location`, `fight_arena` | topo | liga `national`, abre depois de `opp_james`, luta do `center`, arena `arena_nacional` |
| `opponents[]` | lista | mesmos campos de `league_regional.json → opponents` + `national_belt` (só o campeão) e `rival: "james"` (só o James preparado) |
| `passive.locks` / `passive.guard` | adversário | as regras da 8a1 (tipos válidos = os 6; mult 0–5; guard rounds 1–3, taken_mult 0–1) |
| `passive.study` | só o James | `{tipo: {campo: mult}}`, mesma validação de `locks`. Na luta: `locks = {estudado: study[estudado]}` |
Validação (`FightData`): arquivo ausente = sem liga nacional. `_ler_liga` passa a aceitar **várias ligas** (uma por arquivo, na ordem
regional → nacional), cada uma com a sua `fight_arena`. O "Kid" continua sendo o último adversário sem `league`.
### 11.2 O que generaliza no código (Programador)
- `_e_james(opp)` hoje é `regional_belt`; passa a ser `regional_belt` **ou** `rival == "james"`. As falas do regional e do nacional são
  grupos diferentes (§4.3). `registrar_luta` grava também `last_win_type`/`prev_win_type`/`last_win_campaign` e o placar `nac_*`.
- `cinturao_nacional()`, `indice_cinturao_nacional()`, `ao_vencer` com `national_belt` / `first_national_belt` no resumo da vitória.
- `estado_mudanca()` depois do James: o botão MUDAR do centro já aparece (requisito `regional_belt`); nada novo.
### 11.3 Chaves de texto novas (`ui_texts.json` / `dialogos.json`; todas **[ROT]**)
- Nomes e falas: `opp_nac_1`, `opp_nac_2`, `opp_nac_champ` → `name`, apelido (`description`), `entry`, `wins_line`, `loses_line`; a
  `description`/`entry`/linhas do `opp_james_nac` (diferentes das do regional).
- Liga e arena: `league_national_next`, `league_national_invite_title`, `league_national_invite_line`, `arena_nacional_name`.
- Passivas: `opp_passive_adv_cold_read_name|line`, `opp_passive_adv_oak_leg_name|line`, `opp_passive_adv_champion_name|line`,
  `opp_passive_adv_blindado_study_name|line`, `opp_passive_studied` ("ELE ESTUDOU O SEU {jeito}"), `opp_passive_studied_other`,
  `opp_passive_half` ("ATRAPALHA: {jeito} (METADE)").
- Sinais: `fight_opp_block_counter` ("LEU O CONTRA"), `fight_opp_block_spin` ("PERNA DE PAU"), `fight_opp_block_sub` ("SAIU DA CHAVE").
- Motivo: `reason_opp_<id>`, `tip_opp_<id>` para os 4.
- Cinturão: `belt_national_title`, `belt_national_line`, `belt_national_unlock` (**"COMPLEXO DE ELITE LIBERADO"**), `belt_national_soon`,
  `belt_national_lost`, `belt_national_label`.
- Falas: `rival_jn_intro_first_1..2`, `rival_jn_intro_studied_1..2`, `rival_jn_intro_changed_1..2`, `rival_jn_after_win_first_1`,
  `rival_jn_after_win_many_1`, `rival_jn_after_lose_first_1`, `rival_jn_after_lose_many_1`; Osmar `cl_liga_nacional` e
  `cl_cinturao_nacional`.
- **Originalidade:** os nomes dos 2 nacionais e do campeão são novos (não reaproveitar Capivarão, Rei Calota nem Roçador, que estão
  guardados para o Ringue), e nada de nomes de lutadores reais ou de outras obras.

## 12. Critérios de aceite da 8b1
1. **Nada muda antes:** com cada uma das 6 combinações (e sem arte), `foto.gd` igual à da main até a vitória sobre o James; `fase8b1_sim.py
   ident` com 100% dos jogadores iguais; `qa_f8a1_ident.gd` passa com o `league_national.json`.
2. **A liga abre:** depois do James, o HUD pede a mudança e o relógio não anda; ao chegar no centro aparece `PRÓXIMA LUTA NACIONAL: 16
   DIAS` (16 dias; mais os nós). "SEM LUTA NOVA" não aparece; "CAMPANHA COMPLETA" só depois do campeão. Save antigo no centro com
   `ladder_index` 10 abre com a folga cheia.
3. **James estudou:** com `last_win_type` de campanha anterior igual ao seu tipo, a prévia diz "ELE ESTUDOU O SEU {JEITO}" e a chance bate
   com a de `tests/data/fase8b1_casos.json` (`studied`); com outro tipo, só a guarda e a linha "VOCÊ MUDOU"; sem vitória anterior, só a
   guarda. Vitória na mesma campanha não muda o estudo daquela campanha.
4. **Nunca imbatível e honesto:** para cada nacional e cada combinação, a melhor tática tem ≥ 50% no treino mediano de quem luta com ele
   (§9.3); em 1.000 lutas por adversário e combinação, a vitória real fica a ±5 pontos da prévia (§9.4).
5. **Ritmo:** tempo morto no centro p90 ≤ 10 min; lutas 8–20 s; 1 clique ≥ 25% da renda/s no cinturão nacional; campanhas do 1º Vale ao
   1º nacional e diferença entre as 6 combinações como na §9.2 (ver a decisão D1).
6. **Casos exatos:** `tests/data/fase8b1_casos.json` (sem arte + 6 combinações × 4 nacionais, James com e sem estudo): `draws`, eventos, fim,
   `chance_200` iguais no Godot; os casos 7a1/7b1/7b2/8a1/8a2/Ronda continuam passando.
7. **Cinturão:** vencer o campeão mostra "CINTURÃO NACIONAL" e "COMPLEXO DE ELITE LIBERADO"; `permanent.national_belts` +1,
   `first_national_belt_campaign` na 1ª vez, `summary.belts` conta 3, roster com `national_belt`.
8. **Sinais:** contra os nacionais, os sinais da §3.1 aparecem só quando a trava segurou (mesmo sorteio), e o ícone da passiva dele fica ao
   lado da vida.
9. **Pendências:** BUG-2 do Dossiê fechado; `ronda2a_sim.py chefe` refeito com a liga (§10.1) e 1 noite animada cronometrada (≤ ~60 s,
   QA); `teto` ≤ 10% com a liga (§10.2).
10. `tools/run_tests.ps1` verde (save de teste, `--position 1950,40`, um Godot por vez, `--headless` sempre que der); `ui_audit --estrito`
    com 0 problemas nos estados novos (HUD da data nacional, prévia dos 4 com a linha da passiva e as 3 versões do James, arena nacional,
    sinais novos, vitória com o cinturão nacional, fim de carreira com 3 cinturões) e o placar de `ignore` ≤ 15.

## 13. Quem faz o quê
### Programador
1. `FightData`: várias ligas (§11.1), `national_belt`, `rival`, `passive.study`; `arena_da_luta` por liga.
2. Estado (módulo novo sugerido `scripts/estado/liga_nacional.gd`, repasses em GameState, mapa atualizado): `cinturao_nacional()`, data e
   HUD, marcos e falas do Osmar, `ao_carregar` para save antigo; o estudo do James (§4.1) montado antes da prévia; falas do James nacional
   (§4.3, `rival_spoke.before_nac/after_nac`); campos de linhagem (§5).
3. `scripts/luta.gd`: só os 3 casos novos de `_bloqueio` (§3.1). **Nenhuma conta nova.** Referência: `tools/sim/fase8b1_sim.py` (a passiva
   do James = `PV[estudado]`).
4. Save §6 e foto §6. Prévia (`opp_studied`, textos da §4.2) e motivo.
5. Testes (APPDATA temporário, save de teste): (a) foto igual até o James; (b) casos `fase8b1_casos.json`; (c) estudo: 3 saves (sem
   vitória, vitória de campanha anterior com o mesmo tipo, com outro tipo) e 1 com vitória na mesma campanha; (d) save antigo no centro
   com índice 10 e na academia depois do James; (e) a escada termina no campeão; (f) cinturão nacional e campos.
### UI/UX
Primeira tarefa: **BUG-2 do Dossiê** (texto do bandido aberto e não vencido). Depois: HUD da data nacional, prévia (linha da passiva dos
4, as 3 linhas do James), sinais novos, ícones, vitória e fim de carreira com o cinturão nacional, cartaz/convite da liga no centro.
`alinhamento-ui` até 0 problemas.
### Roteirista
Chaves da §11.3: nomes, apelidos e falas dos 2 nacionais e do campeão (originais), James preparado (arrogante, "levando a sério"), Osmar
(2 balões), arena, cinturão. Rascunho em `docs/fases/fase8b1-textos.md`.
### Diretor de Arte
Arena nacional (mockup antes), cinturão nacional, cartaz da liga no centro, 3 ícones de passiva novos (podem sair por código).
### Artista de Personagens
Os 2 nacionais e o campeão no rig comum com 1 pose de assinatura cada (Nac 1: lê o contragolpe e sorri; Nac 2: rodado na canela e ele
nem se mexe; campeão: postura de quem já viu tudo). O campeão pode ter acabamento de "folha completa" se o custo couber (corte do
escopo §7: pose vira quadro parado). James reaproveitado, com um detalhe novo (caderno/fita de vídeo na entrada, "estudou").
### QA
Critérios 1–10. Rodar `fase8b1_sim.py ident campanha trava saida honesta` e o `teto`/`chefe` da §10. Cronometrar 1 noite animada.

## Decisões do Designer (revisar com o dono)
| # | Decisão | Por quê | Alternativa |
|---|---|---|---|
| D1 | **Aceitar** que o Jiu-jitsu leva o cinturão nacional antes (0 campanhas depois do 1º Vale; Boxe 1–2; Muay Thai 2–4) e que as 6 combinações ficam a **48% (4/s) / 69% (3/s)**, fora dos 15% do escopo | o Jiu-jitsu cresce ~2,5× mais no centro (bônus da equipe da arte × Alunos, da 8a2) e era o **mais lento** até o Cinturão do Vale; nenhuma forma ou trava de adversário muda o limiar em mais de ±10%. Um campeão forte o bastante para segurar o JJ mura o Muay Thai (versão 1: nunca) | (a) mexer na economia do centro, fora desta fase (ex.: o bônus da equipe do JJ não vale para os Alunos), que muda a 8a2, o teto e o chefe; (b) um campeão mais forte (8,0–8,4B): Boxe e MT a 1–2 campanhas, mas o MT a 3/s fica quase murado |
| D2 | O James estuda o jeito da última vitória **numa campanha anterior** (não a vitória sobre ele no regional, da mesma campanha) | a passiva do discípulo não muda no meio da campanha; estudar a da mesma campanha travaria sempre o seu jeito, sem escolha. Assim a escolha é do próximo discípulo, e a 1ª campanha nacional usa a guarda (a "padrão" do critério 3) | estudar a vitória da mesma campanha (sempre o seu jeito: James mais forte para todos, sem "vou mudar") |
| D3 | As travas que o James estuda são as que **já existem** (Bigorna, Estaca, Sabão, Nacional 1, Nacional 2); só a da Finalização é nova (×0,3) | "dentre as passivas que já existem"; o jogador reconhece cada trava de um lutador que já enfrentou | travas próprias do James para os 6 |
| D4 | Os 2 nacionais travam **Contragolpista** e **Canela**; a Finalização fica sem trava de lutador | os jeitos que a liga regional deixou livres; a Finalização foi a mais lenta da 8a1 | trocar o Nacional 2 para a Finalização |
| D5 | O campeão trava **todos os jeitos ×0,5**, sem guarda | é o "lê todo mundo": diferente do Blindado (guarda), justo com as 6, e sem conta nova | guarda de 2 rounds (repete o James) |
| D6 | Prêmios $45/60/80/120 mil e fama 600/700/800/1.000; o Legado não ganha bônus pelo nacional | o dinheiro só compra LOJA no centro; a fama já leva o Legado a ~14–35 mil por campanha, sem destino até a 8b2 | bônus de Legado pelo cinturão (piora a sobra) |
| D7 | Dias 16/16/18/18 | o campeão com 22 dias deixava o tempo morto em 10:32–10:55 | mais dias (mais crescimento, mais espera) |

## Resumo
- **Liga nacional** depois do James: 4 lutas do centro, na arena nacional, com 16/16/18/18 dias. Escada = 6 + 4 regionais + **4 nacionais**
  (`data/league_national.json`, arquivo novo). Abre sozinha pela regra de local (o HUD pede a mudança e o relógio espera); "CAMPANHA COMPLETA"
  só depois do campeão. Save **v13** com campos opcionais.
- **Adversários:** Nacional 1 **1,25B** (trava o contragolpe ×0,25), Nacional 2 **2,6B** (trava o chute rodado ×0,25), **James preparado
  4,4B** (guarda do 1º round + a trava do jeito que ele estudou), **campeão nacional 7,4B** (todos os jeitos ×0,5). Prêmios $45k/60k/80k/120k,
  fama 600/700/800/1.000.
- **James estuda a escola:** a passiva dele trava o jeito da última vitória da escola sobre ele numa campanha anterior; a prévia diz qual
  em 1 linha. Tira 16–57 pontos de quem repete o jeito; quem muda passa só pela guarda. Sem conta nova no motor.
- **Medidas:** melhor tática ≥ 72% no treino mediano de cada combinação; prévia honesta a 0,6 ponto por adversário (pior 2,1); tela 8–19 s;
  tempo morto no centro p90 ≤ 9:24; 1 clique 97–122% da renda/s. Nada muda até o James (132 de 132 jogadores iguais).
- **Ritmo:** cinturão nacional 0 (JJ), 1–2 (Boxe) e 2–4 (Muay Thai) campanhas depois do 1º Vale; as 6 ficam a 48–69% (D1).
- **Pendências:** teto **9,4% ≤ 10%** (pior trecho nacional 9,2%); `chefe` refeito com a liga (§10.1): abre e é vencido na campanha 8, 32% na 1ª noite, todas as linhas até a 9,
ninguém fica sem vencer, desafio 14% por tentativa. A noite animada cronometrada fica com o QA.
