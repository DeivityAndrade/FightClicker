# Fase 6c2 — Mais longe que eu: design

Dono: Designer de Jogo. Data: 2026-11-16.
Base: `fase6c-escopo.md` (§3 itens 11–18, §4.5–4.9, §7, critérios 12–21), `fase6c1-design.md`, `fase6c1-api.md`, `fase6c1-revisao.md` (inclusive "Correção: carga e foto", OBS-C), `docs/visao.md` (metas e decisões de 2026-11-11), `docs/direcao-narrativa.md` (Arco 3), `data/disciples.json`, `data/escola.json`, `data/skill_tree.json`, `data/career.json`, `data/dialogos.json`, `scripts/game_state.gd` e `scripts/save_store.gd` (save v12, `school.roster`, Legado, árvore), `tools/sim/fase5_sim.py`.
Fase de **economia nova e tela**. Nenhum número de luta, calendário, preço, Legado ou árvore de Legado muda.

Quem manda em quê:
| Assunto | Documento que vale |
|---|---|
| Fórmula da Honra, bônus do retrato, nós do hall, regras do mural, gatilhos das falas de mentor, símbolo, save v13 | **este** + `data/hall.json` (novo) + `data/escola.json` (blocos `mural`, `mentor_lines`, `mentor_voice`, `school_symbol`) |
| Textos (nomes dos nós, "HONRA", linhas do retrato, falas dos mentores) | Roteirista (`fase6c2-textos.md`, `data/ui_texts.json`, `data/dialogos.json`). Os nomes em `hall.json` são provisórios |
| Desenho do símbolo, objeto do mural, moldura e selo | Diretor de Arte |
| Layout da janela do MURAL e do "+N HONRA" | UI/UX, com a skill `alinhamento-ui` |

---

## 1. A Honra em uma linha
**Vem** só de sair por vontade com pelo menos 1 vitória (inclusive passar o posto no dia da luta). **Vai** só para a árvore do hall, na janela do mural, entre campanhas. Nunca compra Legado, nunca é comprada com Legado, nunca é multiplicada por nó nenhum, e não aparece no HUD da sala.

```
fim por vontade (retire) com wins >= 1 ──► +Honra (tela de fim, retrato no mural)
                                          └► retrato ganha SELO ──► bônus do retrato (teto)
Honra ──► nós do hall (compra só com a tela de fim pendente) ──► efeitos da campanha seguinte
derrota ──► 0 Honra, retrato sem selo (com recorde e "parou em ...")
```

---

## 2. Fórmula da Honra

### 2.1 Regra
```
se fim == "retire" e wins >= min_wins:
    honra = soma(per_win[i] para i em 0..wins-1)  +  (belt_bonus se a campanha tem o cinturão)
senão:
    honra = 0
```
- `wins` = `indice_escada` no fim (as vitórias da campanha). Posição além da lista repete o último valor (para quando a escada crescer na 8a).
- `fim == "retire"` cobre o APOSENTAR entre lutas e o PASSAR O POSTO no dia da luta (os dois passam por `aposentar()`).
- Derrota: 0. Sair com 0 vitórias: 0 (não vira fazenda de "sair no primeiro dia").
- Inteiro, sem arredondamento. Nenhum nó (Legado ou hall) mexe na Honra: o "Caderno do velho" (+15% de Legado) não vale para ela.
- Gravada no **mesmo `salvar()`** do Legado, em `_encerrar_carreira`.

### 2.2 Números (`data/hall.json → honor`)
| Campo | Valor |
|---|---|
| `min_wins` | 1 |
| `per_win` (Dudu, Brutão, Dinho, Muralha, Tonhão, Kid) | 1, 2, 3, 4, 5, 7 |
| `belt_bonus` | 5 |
| `retro_unknown_wins` (migração, §8) | 1 |

| Sai por vontade com… | Honra | Legado da mesma saída (sem nós) |
|---|---|---|
| 0 vitórias | **0** | 0 |
| 1 (Dudu) | 1 | 20 |
| 2 (Brutão) | 3 | 80 |
| 3 (Dinho) | 6 | 200 |
| 4 + cinturão (Muralha) | **15** | 750 |
| 5 (Tonhão) | 20 | 1.110 |
| 6 (Kid, topo) | **27** | 1.710 |
| derrota (qualquer ponto) | 0 | 50% do pote |

Por que essa curva: o salto do cinturão (+5) premia o marco que a escola mais celebra; o valor por vitória cresce para que **sair cedo nunca renda mais Honra por minuto** do que ir longe (medido na §9.2). A razão 27/15 = 1,8 acompanha a razão de tempo Kid/cinturão das campanhas maduras (≈ 1,7 com a troca de campanha).

### 2.3 Onde aparece
| Lugar | O quê |
|---|---|
| Confirmação de APOSENTAR e botão PASSAR O POSTO da prévia do dia | "+N HONRA" ao lado do Legado (`previa_aposentar().honor`). Com 0 vitórias: o texto `retire_no_honor` ("HONRA SÓ COM 1 VITÓRIA", Roteirista) |
| Tela de fim (retire) | "+N HONRA" abaixo do Legado (`fim.honor_gained`), e o saldo "HONRA: N" ao lado do botão MURAL. Retire com 0 vitórias: a mesma linha `retire_no_honor`. Derrota: **nada** sobre Honra (não humilha) |
| Mural | saldo de Honra no topo; "+N" em cada retrato com selo |
| HUD da sala | **nunca** |

---

## 3. Bônus do retrato

### 3.1 Regra
- **Retrato com selo** = entrada do `roster` com `honor > 0` (saiu por cima com conquista). Inclui o John, se ele saiu assim.
- Cada retrato com selo dá **+2% de todo o treino**, **multiplicativo** (um fator só, sobre tudo): clique, Metrônomo, assistido e equipe. Na prática entra em `_base_soco()` e em `_fator_equipe()`, então o Grito da equipe e a bolsa da torcida herdam sozinhos.
- **Teto:** contam no máximo **5** retratos (+10%). O nó `hall_wall` soma **+3** ao teto (8 retratos, +16%).
- `mult_escola = 1 + per_portrait × min(retratos_com_selo, max_portraits + bônus_do_hall_wall)`.
- Vale da campanha seguinte em diante. Como o `roster` só ganha entrada no fim da campanha, o fator fica constante durante a campanha (não precisa de foto como `active_nodes`).
- Derrota e retire com 0 vitórias: retrato normal, sem selo, sem bônus.

### 3.2 Números (`data/hall.json → portrait`)
| Campo | Valor |
|---|---|
| `per_portrait` | 0,02 |
| `max_portraits` | 5 (8 com `hall_wall`) |
| Fator máximo | ×1,10 sem o nó; **×1,16** com o nó |

### 3.3 Visível
- Cartão de início da campanha: linha nova `start_card_mural` ("O MURAL: +{pct}% DE TREINO"), só com bônus > 0.
- Mural: no topo, "RETRATOS COM SELO: {n} (CONTAM {c} DE {teto}) · +{pct}% DE TREINO".

---

## 4. Árvore do hall

### 4.1 Regras
- **6 nós**, lista fixa dentro da janela do MURAL, na ordem da tabela. Sem mapa, sem névoa, **sem pré-requisito** entre eles.
- **Compra só entre campanhas:** com a tela de fim pendente (`fim` não vazio), igual à árvore de Legado (decisão da Fase 4). Fora disso, a lista aparece só para consulta (preço e efeito visíveis, botão apagado com "COMPRA NO FIM DA CAMPANHA").
- Paga com Honra, sem reembolso, um `salvar()` por compra.
- O efeito vale da **campanha seguinte** (a compra é sempre feita com a campanha encerrada).
- Proibido (escopo §3, item 14): nada que torne a derrota melhor que a saída, nada forte na luta e nenhuma moeda dentro da moeda. Nenhum nó abaixo toca luta, Legado, derrota ou Honra.

### 4.2 Os nós (`data/hall.json → hall.nodes`)
| # | id | Nome provisório | Custo (Honra) | Tipo | Efeito exato | Como fica visível na campanha seguinte |
|---|---|---|---|---|---|---|
| 1 | `hall_box` | Fita frouxa | 10 | conforto | `box_clicks_minus 1`: toda caixa (aparelho e luva) abre com `clicks_to_open − 1` cliques (3 → 2; mínimo 1) | a caixa abre no 2º clique |
| 2 | `hall_fund` | Vaquinha da escola | 20 | começo de campanha | `start_training 500`: a campanha começa com 500 de **saldo** de Treino (não soma em atributo) | o saldo começa em 500; dá para comprar a 1ª melhoria do saco (`bag_patch`, 300) no 1º segundo |
| 3 | `hall_notes` | Caderno de recordes | 30 | conforto (informação) | `preview_detail 1`: a prévia mostra o atributo que mais falta e quanto, pelo mesmo cálculo do motivo da derrota (`motor.motivo(jog, adv, tática)`), quando a cor não é verde. Não muda chance nem resultado | linha nova na prévia: "FALTA: ~{n} DE {atributo}" |
| 4 | `hall_crew` | Turma da escola | 35 | número pequeno | `crew_mult 0.10`: a equipe produz ×1,10 (multiplica `_fator_equipe()`) | Treino/s da equipe 10% maior |
| 5 | `hall_glove` | Luva do mural | 45 | começo de campanha | `start_glove 1`: a campanha começa com a Luva de lona (`glove_l1`) **já aberta**, sem caixa e sem custo. A loja passa a oferecer a de couro | o lutador já entra com a luva de lona |
| 6 | `hall_wall` | Parede maior | 50 | teto | `portrait_cap_plus 3`: o teto do bônus do retrato vai de 5 para 8 retratos (+10% → +16%) | o mural mostra "CONTAM {c} DE 8" |
| | | **Total** | **190** | | | |

Notas:
- `hall_glove` funciona como a "Corda montada" da árvore de Legado: a luva já está calçada desde o 1º quadro, sem caixa, sem gesto de calçar e sem a fala `glove_new` do Osmar. `nivel_luva` começa em 1 e o nível 1 entra em `gestured_gloves` no começo da campanha.
- `hall_notes` reaproveita o motivo que já existe. Se o cálculo for caro na prévia (até ~9.000 lutas), roda em segundo plano, como hoje no `motivo_da_luta`, e a linha aparece quando fica pronta.
- O robô do simulador compra o mais barato que cabe. Um jogador de verdade pode escolher a ordem; nenhuma ordem quebra o teto (§9.5).

### 4.3 Por que esses 6 e não outros
- Começo de campanha e conforto fazem a saída "deixar alguma coisa pra escola" sem mexer na luta.
- `hall_crew` e `hall_wall` são os únicos números, pequenos e com teto.
- Ficou de fora: dia a mais de preparo (o calendário está fora da 6c), bônus de dinheiro ou fama (viraria Legado disfarçado), qualquer coisa na derrota.

---

## 5. Mural da escola

### 5.1 O objeto
| Local | Ponto | Aparece |
|---|---|---|
| Garagem | `mural_spot` (novo, Diretor de Arte), ao lado da foto | sempre |
| Academia | `gym_mural_spot` (novo), ao lado da foto reta | com o marco `cena_primeira_academia` (igual à foto) |

- Hover e clique no padrão da ficha da 6a. Hover: `objects.mural` ("MURAL DA ESCOLA", Roteirista).
- Abre **a qualquer hora** em que a sala está ativa (consulta). Durante cena presa, luta ou janela aberta, não abre.
- Botão **MURAL** na tela de fim, ao lado da ÁRVORE. É o único lugar onde o hall compra.
- Regras de folga do ponto: as da `fase6c1-design.md` §4.3 (fora da faixa do alvo, da `no_cover`, da porta e dos `box_slots`).
- Dados: `escola.json → mural`. Nada do objeto vai para o save.

### 5.2 A janela "MURAL DA ESCOLA"
De cima para baixo (UI/UX decide o layout exato):
1. Título; saldo de Honra; linha do bônus do retrato (§3.3).
2. **Retratos**: um por entrada de `school.roster`, na ordem do roster (o John é sempre a 1ª entrada). Fileiras iguais; rolagem quando passar de uma página (sugestão: 5 colunas × 2 fileiras por página). Com 30 entradas, nada cortado.
3. **Hall**: os 6 nós (§4), com custo, efeito, estado (comprado / dá para comprar / falta N / "compra no fim da campanha").

A campanha em andamento **não** entra no mural (ela entra no fim, junto com o Legado).

### 5.3 Um retrato
| Campo | Fonte | Regra |
|---|---|---|
| Imagem | camadas da cabeça do `look` (2x) | discípulo: gerada das camadas (pele, cabelo, faixa); John: a cabeça dele. Com o símbolo se `simbolo_na_entrada(e)` (§7) — o retrato é de busto, então o símbolo do peito aparece só se o enquadramento pegar o peito (Diretor de Arte decide; sem parte de cima, não aparece no busto) |
| Nome | `name` | |
| Campanha | `campaign` | "CARREIRA {n}" (texto existente) |
| Arte | `art` | nome da arte; vazio → "—" |
| Recorde | `wins`, `belt` | "{n} VITÓRIAS" + ícone do cinturão se `belt`; `wins == -1` → `mural_wins_unknown` ("?") |
| Como terminou | `end`, `honor`, `opponent` | ver 5.4 |
| Selo | `honor > 0` | selo de "saiu por cima" (Diretor de Arte) + "+{honor} HONRA" |
| Linha extra do John | marco `cena_saida_primeiro_mentor` | `mural_first_left`: **"foi seguir o rumo dele" (PENDENTE, §5.5)** |

### 5.4 Texto do fim (chaves em `escola.json → mural.end_texts`)
| Fim | Chave | Texto provisório | Selo |
|---|---|---|---|
| `retire` com `honor > 0` | `mural_end_retire` | "SAIU POR CIMA" | sim |
| `retire` com 0 vitórias | `mural_end_passed` | "PASSOU O POSTO" | não |
| `defeat` | `mural_end_defeat` | "PAROU EM {adversario}" (nome do `opponent`), como recorde, nunca como vergonha | não |
| `unknown` (migrado) | `mural_end_passed` | "PASSOU O POSTO" | não |

### 5.5 O John no mural (pendente dos testadores)
- O John é o 1º retrato sempre, com o recorde e o fim da campanha dele, como qualquer outro.
- Depois do marco `cena_saida_primeiro_mentor`, ganha a linha extra `mural_first_left`, provisória: **"foi seguir o rumo dele"**.
- **Pendente:** o texto final espera a pergunta 3 dos testadores da 6c1 ("perceberam que o John foi embora?"), porque o mural é a 2ª proteção do risco §8 do escopo. Se não perceberam, a linha pode ficar mais clara; se perceberam e acharam triste, mais leve. O Roteirista fecha o texto depois da resposta; o Programador já lê a chave.

### 5.6 Estados para o `ui_audit` (inclui a OBS-C da correção 6c1)
1. Mural vazio (só o John), com 1, com 8 e com 30 retratos (rolagem).
2. Retratos de cada fim: selo, passou o posto, parou em, desconhecido (`?`), John com a linha extra.
3. Hall: nada, metade e tudo comprado; dentro e fora da tela de fim.
4. "+N HONRA" na tela de fim (N de 1 e de 2 dígitos) e a linha `retire_no_honor`.
5. Parede da academia: **foto reta + hover `old_photo_gym` com o texto novo + mural ao lado** (OBS-C). Garagem: foto + mural.
6. Discípulo com símbolo, com e sem parte de cima (§7).

---

## 6. Falas dos mentores

### 6.1 Quem fala
- Só o **mentor do caixote** (`mentores_na_sala()` com `role "seat"`), desenhado no local atual: o John enquanto estiver na escola, depois o último que passou o posto (regra da 6c1, §4.1).
- **Sem mentor sentado no local, nenhuma fala de mentor** (Carreira 1, Carreira 2 depois da saída do John, academia sem o marco da cena).
- Balão passivo preso ao mentor, sem cena e sem câmera.

### 6.2 Quando (gatilho `mentor_won`)
Avaliado em `concluir_luta()`, na **vitória**, com os dados reais do `roster` (a campanha atual ainda não está nele). Testa nesta ordem e pede **no máximo uma** fala por vitória:

| Ordem | Fala | Condição (dados reais) | Teto |
|---|---|---|---|
| 1 | **revanche** | existe entrada no `roster` com `end == "defeat"` e `opponent == id do adversário vencido` | 1 por campanha (grupo `revanche`) |
| 2 | **recorde** | `recorde_da_escola >= 1` e `indice_escada > recorde_da_escola`, onde `recorde_da_escola = max(wins)` das entradas com `wins >= 0` | 1 por campanha (grupo `marca`) |
| 3 | **mais longe que eu** | o mentor sentado tem `wins >= 0` e `indice_escada > wins` dele | 1 por campanha (grupo `marca`) |

- **recorde** e **mais longe que eu** dividem o teto `marca`: quem bate o recorde da escola também passou o mentor, e as duas falas diriam a mesma coisa. Com o recorde dito, "mais longe que eu" não sai naquela campanha.
- As condições são de **estado**, não de cruzamento: se a vaga se perder (intervalo de 60 s), a fala pode sair numa vitória seguinte da mesma campanha, enquanto a condição valer. A revanche só vale na vitória sobre aquele adversário.
- Mentor com `wins == -1` (migrado): "mais longe que eu" nunca sai para ele. Entradas com `wins == -1` não entram no `recorde_da_escola`.
- Na escada atual (6 vitórias), quando todos chegam ao Kid, recorde e "mais longe" param de sair. É esperado: voltam quando a escada crescer (8a).

### 6.3 Prioridade e espaçamento
- Trigger novo em `dialogos.json → triggers.mentor_won`: `priority 7`, `defer true`, sem `campaign_cap` próprio (o teto é por grupo, em `escola.json → mentor_lines`).
- Mesmo espaçamento das falas do Osmar: uma vaga só, 60 s desde o último comentário, espera de até 15 s (`comments`).
- **Quando uma fala de mentor é pedida, a `fight_won` do Osmar não sai nessa vitória** (`suppress_coach_fight_won`). Assim não há dois balões sobre o mesmo fato e o Osmar continua falando de recorde/revanche nas campanhas sem mentor.
- O teto do grupo só é gasto quando a fala **toca**.

### 6.4 Para o Roteirista (`dialogos.json`)
- 2–3 variações de cada, `speaker: "mentor"`, `trigger: "mentor_won"`, `conditions: {mentor_line: "revanche"|"recorde"|"mais_longe"}`, `repeat: "rest"`.
- Condição opcional `mentor_kind: "first"|"disciple"`, para o John ter falas dele.
- Revanche com condição opcional `own: true` quando o mentor derrubado é o próprio que está falando ("esse aí me derrubou").
- Marcadores: `{adversario}` (nome do vencido), `{mentor}` (nome de quem ele derrubou, na revanche).
- O recorde pode usar a frase da direção narrativa: "Daqui pra frente, você vai ter que contar pra gente como é."

### 6.5 Voz
- O John mantém a voz `first`.
- Discípulos mentores: `escola.json → mentor_voice`: `base_hz 200`, passo de 14 Hz, deslocamento pela campanha do mentor (`steps[campaign % 5]` = −2, 0, 2, −1, 1 → 172 a 228 Hz), `cps 26`. Original e determinístico (o mesmo mentor soa igual sempre).

---

## 7. Símbolo da escola
- **Regra:** um lutador mostra o símbolo se é **discípulo** (nunca o John) e a campanha dele é ≥ `campanha_do_simbolo()`.
- `campanha_do_simbolo()` = o menor entre:
  - `garage_saved.campaign` (marco da 6a, gravado na vitória ao vivo sobre o Muralha, de qualquer lutador da escola);
  - `campaign` das entradas do `roster` com `belt == true`;
  - a campanha atual, se `cinturao` agora.
  - Nenhum dos três → sem símbolo para ninguém.
- Vale para a pose do lutador em todas as folhas (garagem, academia, luta, cenas), para o mentor sentado e em pé e para o retrato. O discípulo que ganha o 1º cinturão passa a mostrar o símbolo **na volta da vitória**.
- Discípulos de campanhas anteriores ao 1º cinturão continuam sem símbolo (no mural e sentados no caixote): o retrato conta a história como foi.
- **Nada vai para o save**: tudo é derivado do marco e do roster.
- Lugar: peito liso de `tank`/`tee` e peito nu (`top none`); se o Diretor de Arte achar que o peito nu não funciona, perna do calção (`escola.json → school_symbol.place_without_top`, hoje `shorts_leg`, ele confirma).
- Save antigo com cinturão só de antes da 6a (sem o marco e sem entrada com `belt`): o símbolo chega no próximo cinturão. É a mesma regra da garagem salva (6a: nunca por `belts_won`).

---

## 8. Save v12 → v13

### 8.1 Campos novos
| Campo | Onde | Tipo | Padrão |
|---|---|---|---|
| `honor` | `school` | int ≥ 0 (saldo) | 0 |
| `honor_total` | `school` | int ≥ 0 (ganha na vida, nunca desce) | 0 |
| `hall_nodes` | `school` | lista de ids de `hall.json` | [] |
| `honor` | cada entrada de `school.roster` | int ≥ 0 | 0 |
| `honor_gained` | `ending` | int ≥ 0 | 0 |

Validação na carga: id de nó desconhecido ou repetido é ignorado (com aviso, como `_validar_nos`); números inválidos viram 0; `honor` nunca maior que `honor_total` (se for, `honor_total = honor`).

### 8.2 Migração `_migrar_12_para_13` (formato congelado, não lê `data/`)
1. Para cada entrada do `roster`: `honor = honra_v13(wins, belt)` se `end == "retire"`, senão 0.
   - `wins >= 1`: a fórmula da §2 com as constantes congeladas `HONRA_POR_VITORIA_V13 = [1, 2, 3, 4, 5, 7]`, `HONRA_CINTURAO_V13 = 5`.
   - `wins == -1` (desconhecido): o mínimo de uma saída com 1 vitória = **1**.
   - `wins == 0`: 0.
2. `school.honor_total = school.honor = soma das entradas`. `school.hall_nodes = []`.
3. Fim pendente: `ending.honor_gained = honor` da entrada da campanha pendente se `ending.kind == "retire"`; senão 0.
4. Nada mais muda: Legado, árvore, atributos, calendário, marcos, falas vistas e o resto do `roster`.

- As constantes congeladas são cópia de `hall.json` no fechamento da 6c2. Um teste confere que elas batem com `hall.json` enquanto a 6c2 estiver aberta; depois disso, mudar `hall.json` não muda quem já foi migrado (como o `NOME_PADRAO_V12`).
- `VERSAO_ATUAL = 13`. Save v13 aberto num build v12: bloqueado como "versão mais nova" (comportamento atual do `SaveStore`).

### 8.3 Fim de campanha (código novo)
No `_encerrar_carreira`, no mesmo `salvar()`: calcula a Honra (§2), soma em `school.honor` e `school.honor_total`, grava `honor` na entrada nova do roster e `honor_gained` no `fim`.

---

## 9. Balanço (medido)
Simulador novo: `tools/sim/fase6c2_sim.py` (usa o `fase5_sim.py`; valores de `data/hall.json`). Python: `"C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" -I`.

### 9.1 Base sem mudança (critério 11 da 6c1 e 19 da 6c2, "Honra 0")
`fase5_sim.py b23c f52` rodado nesta máquina: **idêntico** à saída da 6b2 (`b23c`: 5/s 26,4% de cinturão na 1ª, mais cedo 20:44; 1ª derrota 13:39 / 14:09 / 4:14; `f52`: mesmas tabelas). Seção `ident` do sim novo: com o hall desligado, as sequências são idênticas às do `fase5_sim.sequencia`.

### 9.2 Honra por minuto em 3 jeitos de jogar (+ o robô padrão)
`fase6c2_sim.py honra`: 96 jogadores × 20 campanhas por perfil, 90 s entre campanhas (fim, árvore, mural, criação, chegada). O robô compra a árvore de Legado e depois o hall, sempre o mais barato. (Rodada com o hall a 210; a rodada final a 190 deu as mesmas Honras por minuto, ±0,02.)

| Perfil | Sai depois da 1ª vitória | Sai com o cinturão | Vai até perder | Padrão (passa o posto no vermelho do dia, sai no topo) |
|---|---|---|---|---|
| Boxe 5/s | 0,29 | 1,56 | 2,37 | 2,44 |
| Boxe 3/s | 0,24 | 1,36 | 1,94 | 2,00 |
| Jiu-jitsu 5/s | 0,29 | 1,56 | 2,26 | 2,42 |
| Jiu-jitsu 3/s | 0,24 | 1,36 | 1,68 | 2,00 |

Honra por minuto, todas as campanhas. Na metade final (árvore de Legado cheia), padrão 2,7–3,3 / cinturão 1,9–2,1 / 1ª vitória 0,26–0,30.
- **Sair cedo nunca rende mais por minuto:** sair depois da 1ª vitória rende ~1/8 do padrão e ~1/5 de sair com o cinturão. A Honra cresce mais rápido que o tempo.
- "Ir até perder" só ganha Honra no topo: depois do Kid não há luta, e sair é a única saída. Fica igual ao padrão para quem vence, e cai para quem perde muito (Jiu-jitsu 3/s, 377 derrotas em 1.920 campanhas: 1,68).
- Minuto de cada vitória nas campanhas com a árvore de Legado cheia (padrão, mediana): Boxe 5/s Dudu 0:43, Muralha 3:13, Kid 6:23; Boxe 3/s Muralha 4:14, Kid 8:19. Com 1,5 min de troca: cinturão 15/(3,2+1,5) = 3,2 por minuto; Kid 27/(6,4+1,5) = 3,4 por minuto. Ir até o Kid rende um pouco mais que parar no cinturão, como pede a curva.

### 9.3 Quantas saídas compram o hall inteiro (alvo 10 ± 3)
Hall = 190 de Honra. Rodada com os preços finais (64 jogadores × 20 campanhas):
| Perfil | Padrão: saídas com Honra até o hall cheio (med; p10–p90) | Padrão: campanha do hall cheio (med) | Só com o cinturão: saídas (med; p10–p90) | Só com o cinturão: campanha (med) |
|---|---|---|---|---|
| Boxe 5/s | 8 (8–8) | 9 | 13 (13–14) | 15 |
| Boxe 3/s | 8 (8–8) | 8 | 14 (14–14) | 15 |
| Jiu-jitsu 5/s | 8 (8–8) | 9 | 13 (13–14) | 15 |
| Jiu-jitsu 3/s | 8 (8–9) | 9 | 14 (14–14) | 15 |

- O robô padrão fecha o hall com **8 saídas**, quase todas no topo (27 cada), por volta da campanha 9. A árvore de Legado fecha antes, na campanha 6–7 (`f52`), então o hall vira a "próxima coisa" depois dela, como queríamos.
- Quem só sai com o cinturão precisa de **13–14** (15 cada; a 3/s às vezes passa o posto antes do cinturão e ganha menos): a borda de cima da faixa. É o preço de não ir à academia, e vem da regra "ir longe nunca rende menos por minuto" (§9.2), que obriga o topo a valer ~1,8× o cinturão.
- Quem só sai depois da 1ª vitória nunca fecha nas 20 campanhas (1 de Honra por saída: 190 saídas).

### 9.4 Metas da visão com o hall vazio, normal e cheio
`fase6c2_sim.py metas`: 120 jogadores × 10 campanhas por perfil. Três modos: hall vazio (= 6b2), hall comprado ao longo do jogo (o caso real) e hall cheio com o retrato no teto **desde a Carreira 1** (caso extremo, impossível no jogo: a Honra começa em 0 e a Carreira 1 é a do John).

| Perfil | Modo | Fim da Carreira 1 (med) | Cinturão na Carreira 1 | Cinturão amador: campanha (med; p10–p90) | Cinturão até a 4ª | Morto Carreira 1 (p90) | Morto academia (p90) |
|---|---|---|---|---|---|---|---|
| Boxe 5/s | vazio | 13:39 | 22,5% | 2 (1–2) | 100% | 7:43 | 4:30 |
| Boxe 5/s | real | 13:39 | 22,5% | 2 (1–2) | 100% | 7:43 | 4:01 |
| Boxe 5/s | extremo | 9:39 | 63,3% | 1 (1–2) | 100% | 7:48 | 4:30 |
| Boxe 4/s | vazio | 13:56 | 0,8% | 2 (2–3) | 100% | 5:30 | 5:00 |
| Boxe 4/s | real | 13:56 | 0,8% | 2 (2–3) | 99% | 5:30 | 5:00 |
| Boxe 4/s | extremo | 10:09 | 52,5% | 1 (1–2) | 100% | 7:45 | 4:30 |
| Boxe 3/s | vazio | 15:26 | 0,0% | 2 (2–3) | 99% | 6:00 | 6:01 |
| Boxe 3/s | real | 15:26 | 0,0% | 2 (2–3) | 100% | 6:00 | 6:00 |
| Boxe 3/s | extremo | 11:09 | 25,0% | 2 (1–2) | 100% | 8:32 | 5:01 |
| Jiu-jitsu 5/s | vazio | 13:39 | 22,5% | 2 (1–2) | 100% | 9:02 | 5:31 |
| Jiu-jitsu 5/s | real | 13:39 | 22,5% | 2 (1–2) | 100% | 9:02 | 5:30 |
| Jiu-jitsu 5/s | extremo | 9:39 | 63,3% | 1 (1–2) | 100% | 7:49 | 7:00 |
| Jiu-jitsu 3/s | vazio | 15:26 | 0,0% | 2 (2–3) | 99% | 6:00 | 7:27 |
| Jiu-jitsu 3/s | real | 15:26 | 0,0% | 2 (2–3) | 100% | 6:00 | 7:20 |
| Jiu-jitsu 3/s | extremo | 11:09 | 25,0% | 2 (1–2) | 100% | 10:02 | 7:27 |

(O cinturão na Carreira 1 de 22,5% é a mesma medida do `b23c`, 26,4% com 2.000 jogadores; aqui são 120.)

- **Hall vazio = 6b2.** A Carreira 1 não muda (Honra 0), e o cinturão sai na 2ª campanha (p90 na 3ª).
- **Caso real:** o hall fecha na campanha 9 (mediana, todos os perfis), muito depois das metas. A Carreira 1 é idêntica e o cinturão continua na 2ª–3ª. O maior tempo morto (p90) continua 9:02 (Jiu-jitsu 5/s, Carreira 1, igual à 6b2), ≤ 10 min.
- **Caso extremo** (só para saber o tamanho): o hall cheio na Carreira 1 encurtaria a 1ª carreira para 9:39–11:09 e daria o cinturão nela para 25–63% dos jogadores. Não acontece no jogo, porque a Carreira 1 começa com Honra 0 e o hall só fecha por volta da 9ª. O mais cedo possível é: Carreira 2 com 1 retrato (+2%) e até 27 de Honra (o John sai no topo), ou seja, no máximo a caixa (10) ou o Treino inicial (20). Esse caso está dentro do modo "real".

### 9.5 O teto de 10% (a conta)
**Medida:** o tempo que o jogador sente. Uma campanha sem calendário, com o robô lutando só no VERDE e a derrota não encerrando (assim só a força do treino conta). Mede-se o minuto do cinturão e do Kid em 4 condições: árvore de Legado vazia, árvore cheia (só os nós da arte jogada), árvore cheia + hall cheio + retrato no teto (8 retratos, ×1,16), e o mesmo hall sobre a árvore vazia.
- Efeito da árvore de Legado: `E_L = T(vazia) − T(cheia)`.
- Efeito do hall **no mesmo ponto do jogo** (o hall só fecha depois da árvore): `E_H = T(cheia) − T(cheia + hall)`.
- Regra: `E_H ≤ 10% × E_L`.

`fase6c2_sim.py teto`, 32 jogadores por linha:
| Perfil | Marco | Árvore vazia | Árvore cheia | Cheia + hall | E_L | E_H | **E_H / E_L** | só retrato / só nós |
|---|---|---|---|---|---|---|---|---|
| Boxe 5/s | cinturão | 18:21 | 4:19 | 3:13 | 14:02 | 1:05 | **7,7%** | 3,8% / 3,8% |
| Boxe 5/s | Kid | 39:58 | 7:47 | 6:19 | 32:11 | 1:28 | **4,6%** | 2,9% / 1,6% |
| Boxe 3/s | cinturão | 24:26 | 5:14 | 4:14 | 19:12 | 1:00 | **5,2%** | 2,6% / 5,1% |
| Boxe 3/s | Kid | 56:31 | 10:19 | 7:54 | 46:12 | 2:25 | **5,2%** | 3,2% / 3,2% |
| Jiu-jitsu 5/s | cinturão | 17:55 | 4:14 | 3:13 | 13:41 | 1:00 | **7,3%** | 6,0% / 7,3% |
| Jiu-jitsu 5/s | Kid | 45:30 | 7:55 | 6:21 | 37:36 | 1:33 | **4,1%** | 2,7% / 2,7% |
| Jiu-jitsu 3/s | cinturão | 21:25 | 4:15 | 3:17 | 17:10 | 0:58 | **5,7%** | 0,1% / 3,0% |
| Jiu-jitsu 3/s | Kid | 68:01 | 9:23 | 7:25 | 58:38 | 1:58 | **3,4%** | 0,8% / 2,5% |

- **Pior caso: 7,7%** (cinturão, Boxe 5/s). Todos ≤ 10%. O robô olha a prévia a cada 30 s, então os tempos andam de 30 em 30 s; a folga de 2,3 pontos cobre esse ruído.
- Para o jogador, o hall cheio deixa a campanha madura ~1 a 2,5 min mais curta (de 6–10 min para 5–8 min até o Kid). Sente-se, mas não muda o jogo.
- O mesmo hall sobre a árvore **vazia** valeria 28–41% do efeito dela. Isso nunca acontece: com 1 de Honra por saída curta e 27 no topo, o hall só fecha por volta da campanha 10, e a árvore de Legado fecha na 6–7. É por isso que os primeiros nós são de conforto e começo, e os números (equipe, parede) são os mais caros.
- **Multiplicador puro** (para referência): a árvore de Legado cheia dá ×4 no clique, ×3,25 na equipe, ×3 no dinheiro, ×2 na fama, Metrônomo no nível 2, 5 vizinhos, corda montada, +1 dia e os bônus de arte; o hall cheio dá ×1,16 em todo o treino e ×1,10 na equipe, e nada em dinheiro, fama, Legado ou luta. Comparar só os multiplicadores de treino superestima o hall, porque a árvore também acelera pelo dinheiro e pelo começo; por isso o teto é medido no tempo.

### 9.6 Sair continua melhor que perder, sem dominar
Conta no dia da 2ª luta (Brutão), com 1 vitória. A Honra entra em "Legado equivalente" pela taxa **máxima** que o teto permite: 1 de Honra ≤ 10% × 16.810 (custo da árvore de Legado) / 190 = **8,8 de Legado**.
| Escolha | Legado | Honra | Total (Legado equivalente) |
|---|---|---|---|
| Sair no dia da 2ª luta | 20 | 1 | **28,8** |
| Lutar e vencer (e sair logo depois) | 80 | 3 | **106,5** |
| Lutar e perder | 10 | 0 | **10** |

- **Sair é melhor que perder:** 28,8 contra 10 (2,9×). Com o cinturão: 750 + 15 de Honra contra 250 e 0.
- **Sair não domina:** lutar vale mais que sair sempre que a chance for maior que **20%** (sem a Honra, 14%). A prévia só fica vermelha abaixo de 40%; no verde (≥ 90%), lutar vale 3,4× sair. Com a fama da árvore (×2 e ×3), o ponto fica em 17% e 16%.
- O robô chega à 2ª luta com chance mediana de 100% (p10 96%): na prática, ninguém tem motivo para sair ali.
- A Honra empurra o ponto de virada só 6 pontos (14% → 20%). É a "recompensa por sair por cima": deixa a saída no vermelho um pouco mais digna, sem tornar sair a única escolha boa.

---

## 10. Dados e contrato

### 10.1 Arquivos
| Arquivo | Dono | O que entra na 6c2 |
|---|---|---|
| `data/hall.json` (**novo, criado por mim**) | Designer (valores); Roteirista (nomes e `effect_text`) | `honor`, `portrait`, `hall.nodes` |
| `data/escola.json` (blocos novos, criados por mim) | Designer | `mural`, `mentor_lines`, `mentor_voice`, `school_symbol` |
| `data/dialogos.json` | Roteirista (o gatilho e as condições são meus) | `triggers.mentor_won` (`priority 7, defer true`), falas `ml_revanche_*`, `ml_recorde_*`, `ml_mais_longe_*` (§6.4), `objects.mural` |
| `data/ui_texts.json` | Roteirista | `honor_label` ("HONRA"), `end_honor_gain` ("+{n} HONRA"), `retire_no_honor`, `mural_button`, `mural_title`, `mural_honor_balance`, `mural_bonus_line`, `mural_end_retire`, `mural_end_passed`, `mural_end_defeat`, `mural_first_left` (pendente), `mural_wins_unknown`, `hall_buy_only_end`, `hall_owned`, `hall_missing`, `start_card_mural`, `preview_missing_line` |
| manifest | Diretor de Arte | `mural_spot` (garagem), `gym_mural_spot` (academia), sprites do mural, moldura, selo, símbolo (3/4 e perfil) |
| `tools/sim/fase6c2_sim.py` (**novo**) | Designer | seções `ident`, `honra`, `escolha`, `metas`, `teto` |

### 10.2 Números
| Decisão | Valor | Onde |
|---|---|---|
| Honra por vitória (Dudu → Kid) | 1, 2, 3, 4, 5, 7 | `hall.json → honor.per_win` |
| Bônus do cinturão | +5 | `honor.belt_bonus` |
| Mínimo de vitórias | 1 | `honor.min_wins` |
| Honra de entrada migrada com `wins -1` | a de 1 vitória (1) | `honor.retro_unknown_wins` + constante congelada |
| Retrato com selo | +2% de todo o treino, até 5 (8 com `hall_wall`) | `portrait` |
| Hall | 10 / 20 / 30 / 35 / 45 / 50 = 190 | `hall.nodes[].cost` |
| Caixa | −1 clique (3 → 2) | `hall_box` |
| Treino inicial | 500 | `hall_fund` |
| Equipe | ×1,10 | `hall_crew` |
| Voz dos mentores | 200 Hz ± 14 Hz × passo, 26 letras/s | `escola.json → mentor_voice` |
| Mural | 5 × 2 por página (sugestão) | `escola.json → mural` |

### 10.3 Contrato para o Programador (nomes sugeridos)
| Onde | Item |
|---|---|
| `GameState` (leitura) | `honra() -> int` (saldo); `honra_total() -> int`; `honra_da_saida(wins, belt) -> int` (a fórmula, só dados); `previa_aposentar()` ganha `honor`; `fim.honor_gained`; `mult_escola() -> float`; `retratos_com_selo() -> int`; `teto_retratos() -> int`; `mural() -> {entries, honor, sealed, counted, cap, bonus_pct}` com `entries[] = {campaign, kind, name, look, art, wins, belt, end, end_key, opponent_name, sealed, honor, symbol, extra_key}`; `hall_lista() -> [{id, name, cost, effect_text, state "owned"\|"buyable"\|"missing"\|"closed", missing}]`; `pode_comprar_hall(id)`; `mural_na_sala() -> {spot, object_text}` ou `{}`; `campanha_do_simbolo() -> int` (0 = nenhuma); `simbolo_no_lutador() -> bool`; `simbolo_na_entrada(e) -> bool` |
| `GameState` (ações) | `comprar_hall(id) -> bool`: só com `fim` pendente; desconta a Honra exata, grava o nó e salva (um save só) |
| Efeitos | `_base_soco()` × `mult_escola()`; `_fator_equipe()` × `mult_escola()` × (1 + `crew_mult`); no começo da campanha: saldo + `start_training`, Luva de lona aberta (`start_glove`), cliques da caixa − `box_clicks_minus` (mín. 1); `previa()` ganha `missing_line` com `hall_notes` (fora do verde) |
| `_encerrar_carreira` | Honra (§2) no mesmo `salvar()`: `school.honor`, `school.honor_total`, `honor` na entrada nova do roster, `fim.honor_gained` |
| `concluir_luta()` | na vitória, `_fala_do_mentor(opp)` (§6.2): pede `mentor_won` com `{line, adversario, mentor, own, mentor_kind}` e, se pediu, não dispara a `fight_won` do Osmar. Teto por grupo = alguma fala do grupo com `lines_seen[id] == campanha atual` |
| Falas | `speaker "mentor"` resolve para o mentor sentado (`mentores_na_sala()` role `seat`); sem ele, a fala não é candidata. Condições novas: `mentor_line`, `mentor_kind`, `own` |
| Sinais | `honra_mudou(honor)`, `hall_mudou()` |
| Save | v13 (§8): `school.honor`, `school.honor_total`, `school.hall_nodes`, `roster[].honor`, `ending.honor_gained`; `_migrar_12_para_13` com as constantes congeladas |
| Testes (save de teste) | Honra: 0 vitórias = 0, derrota = 0, passar o posto no dia = saída, cada linha da tabela §2.2; teto do retrato (5 e 8); compra do hall só com `fim` pendente, sem reembolso, saldo exato; cada efeito na campanha seguinte (caixa 2 cliques, saldo 500, luva de lona aberta, equipe ×1,10, linha da prévia); Honra e Legado nunca se misturam (comprar nó de Legado não mexe na Honra e vice-versa); falas de mentor nos casos da §6.2 e sem mentor; símbolo (antes/depois do 1º cinturão, John nunca, retrato antigo sem); migração v12 → v13 com cópia do save do dono (Honra retroativa, nada mais muda); constantes congeladas = `hall.json` |

---

## 11. Fora da 6c2 (não adiantar)
- Mais nós no hall, regiões novas, moeda dentro da Honra.
- Falas de mentor sobre diferença de estilo (Arco 3, quando as artes lutarem diferente, 7a).
- Botão "igual ao anterior" na criação (só se os testadores da 6b2 pedirem).
- Foto do reencontro no mural (fase 11).
- Qualquer mudança de Legado, preço, luta, calendário ou árvore de Legado.

---

## 12. Pontos em aberto
| # | Ponto | Recomendação | Quem decide |
|---|---|---|---|
| 1 | Texto do John no mural ("foi seguir o rumo dele") | Fica provisório; a chave `mural_first_left` já existe. Fecha depois da pergunta 3 dos testadores da 6c1 | Roteirista, depois dos testadores |
| 2 | Critério 19 fala de "hall cheio" e "1ª carreira 10–15 min" juntos, mas o hall nunca está cheio na Carreira 1 | Valer o caso real (§9.4): Carreira 1 igual à 6b2 e hall fechando na ~9ª. O caso extremo fica registrado só como tamanho | Diretor |
| 3 | O teto de 10% foi medido no tempo até o cinturão e o Kid (pior caso 7,7%), e não no multiplicador puro de treino (§9.5) | Manter a medida no tempo: é o efeito que o jogador sente e a única que inclui dinheiro, começo e aparelhos | Diretor |
| 4 | Quem só sai com o cinturão precisa de 13–14 saídas (a borda de cima da faixa 10 ± 3, a 3/s passa 1); o padrão, 8 | Aceitar: a razão entre os dois vem da regra "ir longe nunca rende menos por minuto". Baixar o hall para 180 põe o cinturão em 12–13 e o padrão em 7 | Diretor |
| 5 | Lugar do símbolo sem parte de cima (peito nu ou perna do calção) e se o retrato em busto mostra o símbolo | Peito, se ler bem no peito nu; senão perna. No retrato, só se o enquadramento pegar o peito | Diretor de Arte |
| 6 | Custo do cálculo da linha "FALTA" do `hall_notes` na prévia | Calcular em segundo plano, como o motivo da derrota; se pesar, mostrar só o atributo, sem o número | Programador |

---

## Resumo
- **Honra:** só sai por vontade com ≥ 1 vitória (inclusive passar o posto no dia). `honra = soma(1, 2, 3, 4, 5, 7 até as vitórias) + 5 com o cinturão` → 1 / 3 / 6 / **15** (cinturão) / 20 / **27** (Kid). Derrota e 0 vitórias dão 0. Nada multiplica a Honra. Aparece na tela de fim, na confirmação de sair e no mural; nunca no HUD.
- **Retrato com selo:** +2% de todo o treino cada, multiplicativo, até 5 retratos (+10%); o nó `hall_wall` sobe o teto para 8 (+16%).
- **Hall (190 de Honra, 6 nós, só entre campanhas):** caixa com 1 clique a menos (10), 500 de Treino inicial (20), prévia com o que mais falta (30), equipe ×1,10 (35), começa com a Luva de lona (45), +3 retratos no teto (50).
- **Medido:** Honra por minuto 0,24–0,29 saindo na 1ª vitória, 1,36–1,56 com o cinturão e 2,0–2,4 no padrão (sair cedo nunca compensa). O hall fecha em 8 saídas no padrão (campanha ~9) e 13–14 só com cinturões (alvo 10 ± 3). Hall cheio + retrato no teto = **3,4% a 7,7%** do efeito da árvore de Legado (teto 10%). Lutar vale mais que sair a partir de 20% de chance; sair vale 2,9× perder.
- **Metas:** com Honra 0, tudo igual à 6b2 (simulação idêntica). No jogo real o hall fecha na campanha ~9: Carreira 1 igual (13:39–15:26), cinturão na 2ª–3ª, tempo morto p90 ≤ 9:02. Só no caso impossível de ter o hall cheio na Carreira 1 ela cairia para 9:39–11:09.
- **Mural, falas e símbolo:** um retrato por entrada do roster (o John primeiro, com "foi seguir o rumo dele" **pendente** dos testadores); falas de revanche, recorde e "mais longe que eu" pelo mentor do caixote, uma por vitória, no máximo 1 de cada grupo por campanha; símbolo derivado do 1º cinturão (marco `garage_saved` ou roster), nunca no John, sem campo no save.
- **Save v13:** Honra, nós do hall e `honor` por entrada; Honra retroativa para quem saiu por vontade (`wins -1` = 1).
