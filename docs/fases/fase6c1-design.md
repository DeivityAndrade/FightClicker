# Fase 6c1 — Casa nova: design

Dono: Designer de Jogo. Data: 2026-11-15.
Base: `fase6c-escopo.md` (§3, §4.1–4.4, §4.9, critérios 1–11), `cenas-curtas.md` §1 e §2, `formato-dados.md`, `fase6a-design.md` (§1.4–1.6, §2) e o B1 da `fase6a-revisao.md`, `fase6b1-design.md`, `fase6b1-api.md`, `fase6b2-api.md`, `data/dialogos.json` (com o rascunho do Roteirista em andamento), `fase6c1-textos.md`, `data/disciples.json`, `data/cutscenes/`, `scripts/game_state.gd` (save v12).
Fase de **regras e cena**. Nenhum número de economia, luta, calendário ou Legado muda (§8).

Decisões do Produtor que este design segue:
- **Gatilho da saída do John:** a recomendação do Diretor, enquanto o dono não responde. O John sai no 1º momento calmo depois da 1ª vitória de um discípulo na academia, ou no começo da Carreira 4. Vale o que vier primeiro.
- **Mentores na sala:** o John e o último que passou o posto enquanto o John estiver; depois, só o último.

Quem manda em quê:
| Assunto | Documento que vale |
|---|---|
| Gatilhos, estados, ordem da fila, marcos, quem aparece onde, regras de fala por local, save | **este** + `data/escola.json` + `data/disciples.json` (blocos `_6c1`) |
| Passos, tempos e poses das cenas | `data/cutscenes/primeira_academia.json` e `saida_primeiro_mentor.json` (Diretor de Cutscenes) |
| Textos | `fase6c1-textos.md`, `data/dialogos.json`, `data/ui_texts.json` (Roteirista) |
| Posição dos pontos `gym_*` | manifest (Diretor de Arte), com as regras de folga da §4.3 |

---

## 1. A cena da 1ª chegada à academia

### 1.1 Gatilho
A chegada à academia sempre passa pelo `mudar()`. Toda campanha começa na garagem (`_zerar_carreira` põe `local_padrao`), então **toda chegada é um MUDAR**. A carga do save e o RECEBER nunca levam à academia.

| Condição no `mudar()` para `gym` | O que acontece |
|---|---|
| marco `cena_primeira_academia` **ausente** | a cena toca (§1.2) |
| marco presente | chegada de hoje: sem cena, `gym_arrival` normal |

- Vale para qualquer lutador. Inclui o John na Carreira 1, se ele ganhar o cinturão nela.
- **Save que já esteve na academia** (todo save anterior à 6c1): o marco não existe, então a cena toca no **próximo MUDAR**. As artes já estão liberadas, então em geral a arte já foi escolhida na garagem e a janela da arte não abre depois da cena (ela só abre "se pendente").
- **Save aberto já dentro da academia sem o marco:** a cena **não** toca na carga (o escopo pede "na próxima chegada"). Até lá, a academia fica como na 6b2: sem Osmar, sem mentores e sem foto. Isso evita balão sem personagem (B1 da 6a). A cena toca no MUDAR da próxima campanha que chegar lá.

### 1.2 Fila da chegada (escopo §3, item 20)
`vitória → MUDAR → cena da academia → escolha da arte (se pendente) → cl_primeira_academia no 1º momento calmo`.

Passo a passo, em um único `salvar()` no MUDAR:
1. `mudar()` faz o de hoje: desconta o preço, `local_id = "gym"`, ajusta `fight_day` se estava parado, libera as artes na 1ª vez.
2. Se o marco está ausente:
   1. grava `cena_primeira_academia = {campaign, version: 1}`, com `_gravar_marco(..., salvar_agora = false)`. O `salvar()` do próprio `mudar()` grava junto;
   2. entra no estado `cena_sala = "primeira_academia"` (§1.3);
   3. **não emite** `escolha_arte_pedida`, que fica para o fim da cena;
   4. dispara `gym_arrival` como hoje. A sala não está calma, então a fala vai para a vaga. Como a `cl_primeira_academia` é `once`, a vaga dela persiste e não envelhece com a sala inativa (já é assim no código).
3. `salvar()`, `local_mudou("gym")` e o sinal novo `cena_sala_pedida("primeira_academia")`, para a UI tocar o player.
4. Quadros 1–4 da `cenas-curtas.md` §1.
5. **Fim da cena** (`return_control`, ou PULAR → `end_state`): `cena_sala_terminou()` faz `cena_sala = ""` e `_checar_sala()`, e emite `escolha_arte_pedida(primeira)` se a escolha estiver pendente.
6. A pessoa escolhe a arte. A sala fica ativa e, depois de 2 s de calma, a `cl_primeira_academia` toca (§5.2).

### 1.3 Relógio parado
- Com `cena_sala != ""`, o `tick` trata a carreira como na sucessão. Não somam `tempo_jogo`, `_ocioso`, `segundos_campanha`, produção, arte, Metrônomo, assistido, ouro, risco nem tempo morto.
- `sala_ativa()` e `escolha_arte_pendente()` ganham a condição `cena_sala == ""`. Nenhum soco vale durante a cena. A janela da arte não abre por cima dela.
- `cena_sala` **não vai para o save**: o marco já diz tudo (§1.5).

### 1.4 Quem está na cena (escopo §3, item 2)
| Papel | Regra (nesta ordem) | Ator no formato |
|---|---|---|
| Lutador, com o saco remendado | quem joga a campanha: o John (Carreira 1) ou o discípulo, com o `look` dele | `current_player`, que na campanha do John resolve para `first_fighter` |
| Quem carrega a caixa | 1) o **John**, se `"first" in school.mentors` e há discípulo jogando; 2) **o último que passou o posto**, se o marco `cena_saida_primeiro_mentor` existe e `segundo_mentor_entrada()` não é vazio; 3) **um vizinho** | `first_fighter` / `mentor:last` / `helper` |
| Ajudante com a esteira | sempre um ajudante do bairro | `helper` (2º) |
| Osmar | sempre | `coach` |
| 2º mentor em pé (Carreira 3+, com o John) | **fora da cena**: escondido durante ela e já no `gym_mentor_2_spot` no `end_state`. O corte de 2x para 1x do quadro 4 esconde a entrada dele | — |

- A ordem está em `data/escola.json → gym_arrival.box_carrier_order`.
- `GameState` oferece `elenco_primeira_academia() -> {fighter: "first"|"disciple", box: "first"|"last_passed"|"neighbor", box_look}` (nome sugerido). O Diretor de Cutscenes monta os atores condicionais com isso, numa cena só.
- Com caixa carregada pelo vizinho e esteira pelo ajudante, há **dois** `helper` na cena. O Artista de Personagens diferencia os dois por paleta, sem folha nova.

### 1.5 Pular, fechar no meio, tocar uma vez só
| Situação | Resultado |
|---|---|
| PULAR (segurar ESC/ESPAÇO 0,5 s ou o botão) | `end_state`: academia montada, foto torta no `gym_photo_spot`, Osmar no `gym_coach_spot`, mentores nos pontos, os dois tubos acesos. Depois, o passo 5 da §1.2. Tudo em ≤ 0,3 s |
| Fechar o jogo no meio | o save tem o marco e `local_id = "gym"`. Ao abrir, a academia aparece no estado final, sem a cena. Se a arte estava pendente, a janela abre como hoje na carga. A `cl_primeira_academia` volta pelo rearme (§5.2) |
| Perder, chegar com outro discípulo, campanha nova | o marco existe: sem cena |
| Chegadas seguintes | sem cena e sem tempo preso. `gym_arrival` toca a fala de chegada (§5.3) |

Teto: `max_seconds` 15 (escopo, critério 1), em `escola.json → gym_arrival.max_locked_seconds`. O alvo continua ≈ 13 s.

---

## 2. A foto antiga acompanha a escola
| Local | Visível | Ponto | Texto do hover |
|---|---|---|---|
| Garagem | sempre (como na 6a) | `garage_story_wall.objects.photo_old` (237,67) | `objects.old_photo` |
| Academia | com o marco `cena_primeira_academia` | `gym_photo_spot` (novo, Diretor de Arte) | `objects.old_photo_gym` (Roteirista) |

- É **uma foto só**, desenhada no local onde o lutador está treinando. Como só uma sala aparece por vez, as duas regras nunca entram em conflito, e a garagem não fica "abandonada".
- Na academia, ela fica **torta** (sprite próprio ou rotação em passo inteiro, a cargo do Diretor de Arte).
- O mural da 6c2 fica ao lado, no `mural_spot`. Esse ponto **não** entra na 6c1.
- Nada vai para o save: tudo sai do marco. Dados em `escola.json → old_photo`.

---

## 3. O Osmar na academia

### 3.1 Onde ele aparece
| Local | Aparece | Ponto |
|---|---|---|
| Garagem | sempre (como hoje) | `by_data_id.original_trainer.pos` (196,236) |
| Academia | só com o marco `cena_primeira_academia` | `gym_coach_spot` (novo) |

### 3.2 Regra única de fala: "só fala quem está desenhado"
- Substitui a trava de local fala por fala como proteção. Uma fala do `coach` só é candidata se o Osmar estiver desenhado no local atual (`coach_presente()`).
- O mesmo vale para a abertura (`_tick_abertura`, que hoje compara com `"garage"`) e para o balão de resposta da saída (§6).
- Se faltar o ponto no manifest, o Osmar não aparece e não fala naquele local. Nunca há balão sem personagem.
- A condição `location` das falas continua existindo, mas só para o **conteúdo**: falas que citam a lâmpada, o aviso etc. Dados em `escola.json → coach_presence`.

---

## 4. Mentores na academia e depois da saída

### 4.1 Quem aparece (garagem e academia, mesma regra)
"Último que passou o posto" = `segundo_mentor_entrada()`, a última entrada `kind == "disciple"` do `roster` com `end` em `passed_ends`.

| Momento | Sentado (`seat`) | Em pé (`stand`) | Toques do 1º clique e da volta da vitória |
|---|---|---|---|
| Campanha do John | ninguém | ninguém | — |
| Discípulo, John na escola, sem entrada de discípulo no roster (Carreira 2) | John, `sit_rest` | vazio | John |
| Discípulo, John na escola, com entrada (Carreira 3+) | John | último, `stand_bare`, virado para o saco | John |
| Depois da saída, sem entrada de discípulo (a saída aconteceu na Carreira 2) | **vazio** até o fim da campanha | vazio | ninguém |
| Depois da saída, com entrada | **último**, `sit_rest`, `glove none` | **vazio** | ninguém |
| Save migrado com Novato antes da 1ª sucessão (`mentors = []`, sem o marco da saída) | ninguém | ninguém | — |

Pontos por local (`disciples.json → room_mentors.spots_by_location`):
| Local | `seat` | `stand` | Condição extra |
|---|---|---|---|
| Garagem | `mentor_spot` | `mentor_2_spot` | — |
| Academia | `gym_mentor_spot` (caixote ou banco) | `gym_mentor_2_spot` | marco `cena_primeira_academia` |

- O caixote da garagem e o banco da academia aparecem desde a `cena_primeira_sucessao` (`seat_prop`), com gente sentada ou não. Hoje o caixote é derivado de `school.mentors`; depois da saída essa lista fica vazia e o caixote sumiria. O critério 9 pede o caixote vazio.
- O "último" muda sozinho a cada RECEBER, porque o roster ganha uma entrada no fim da campanha. **Ninguém é gravado como "mentor"**: depois da saída, `school.mentors` fica `[]` e o sentado sai do roster.
- O discípulo sentado usa a pose `sit_rest` com todas as camadas e paletas do `look` (pedido ao Artista de Personagens).

### 4.2 Ponto ocupado
- **Cada ponto tem no máximo um dono, pela regra.** O `seat` é do John enquanto ele estiver; depois, do último. O `stand` é do último só enquanto o John senta. Mentores anteriores ao último não aparecem. Não existe fila de espera por ponto.
- **Durante a saída** (§6), o John levanta do `seat` no quadro 1. O último só anda até o `seat` depois que o John passou pela porta. Os dois nunca disputam o ponto.
- **Durante a cena da academia**, os mentores ficam escondidos (`hide: mentors`) e entram pelo `end_state` nos pontos deles.
- **Pessoas da equipe, caixas de aparelho e o lutador nunca usam esses pontos.** Os pontos novos ficam fora das zonas proibidas (§4.3). Se o manifest não tiver um ponto, o personagem daquele ponto não aparece naquele local, sem erro e sem balão.
- **Dois balões ao mesmo tempo** (Osmar e mentor) não acontecem: as falas têm uma vaga só. Na 6c1, os mentores não falam fora da cena da saída.

### 4.3 Folga dos pontos novos (para o Diretor de Arte)
`gym_coach_spot`, `gym_mentor_spot`, `gym_mentor_2_spot` e `gym_photo_spot` seguem as regras da garagem:
- fora da faixa do lutador e do alvo (x 281..362);
- fora da `no_cover`, do caminho da porta da rua (x ≈ 404..454) e dos `box_slots` (`treadmill` 445,268 · `jump_rope` 424,287 · `art` 204,283 · `glove` 386,280);
- o balão do Osmar não cobre cabeça nenhuma, nem a do mentor em pé;
- o caminho do `stand` até o `seat` (fim da saída) não cruza a faixa do alvo;
- mockup de conferência com a sala cheia: Osmar, John sentado, último em pé, equipe máxima, 4 caixas e foto.

### 4.4 Toques do John
- Valem onde o John estiver sentado: `mentor_taps.locations = ["garage", "gym"]`. Na academia, só com o marco da cena, que é quando ele aparece lá. Regras e números da 6b1 sem mudança: 60 s, 0,5 s de guarda e 1,0 s depois da vitória.
- `only_first: true`: depois da saída, ninguém toca, nem o último sentado.

---

## 5. Falas do Osmar na academia

### 5.1 Fala por fala
"Os dois" = sem `location`; a fala vale onde o Osmar estiver (§3.2). Conferi o rascunho do Roteirista em `data/dialogos.json`. O que bate fica marcado com "ok"; o que precisa de ajuste vem com **pedido**.

| Id(s) | Local | Situação |
|---|---|---|
| `cl_primeira_compra`, `cl_primeira_caixa`, `cl_luva_par` | garagem | ok (`once`, já tocaram na Carreira 1 em quase todo save) |
| `cl_primeira_derrota` | garagem | ok (o começo da campanha é sempre na garagem) |
| `cl_garagem_salva` | garagem | ok (fala do aviso) |
| `cl_primeira_academia` | **academia** | ok no `location`. **Pedido:** acrescentar `milestone_present: ["cena_primeira_academia"]` (§5.2) |
| `cl_compra_1,2`, `cl_caixa_1,2`, `cl_revanche_*`, `cl_recorde_*`, `cl_luta_marcada_*`, `cl_parado_1,2` | os dois | ok |
| `cl_compra_3`, `cl_caixa_3`, `cl_parado_3` (lâmpada) | garagem | ok |
| `cl_ac_compra_*`, `cl_ac_caixa_1`, `cl_ac_luta_marcada_1`, `cl_ac_parado_*` | academia | ok |
| `cl_derrota_*`, `cl_derrota_recall_*` | — | ok, mas na prática só a garagem: o `after_defeat` sai no começo da campanha, que é sempre na garagem |
| `cl_ac_derrota_1,2` | academia | **nunca tocam**, pelo mesmo motivo. **Pedido ao Roteirista:** tirar, ou trocar o local para os dois |
| `cl_academia_volta_1..3` | hoje `garage` | **nunca tocam**: o `gym_arrival` só sai na academia (já era assim na 6a). **Pedido:** trocar para `location: gym`. Os textos ("já sabe o caminho", "cheiro de tatame", "o espelho é maior") são de quem chega. Com isso, entram no mesmo sorteio das `cl_ac_chegada_*` (6 variantes, teto 1 por campanha) |
| `cl_ac_chegada_1..3` | academia, `after_line: cl_primeira_academia` | ok |
| `cl_arte_1..4` | os dois, ligadas | ok no texto. **Pedido:** gatilho com as regras da §5.4 |
| `cl_passar_posto` | — | continua desligada (não é da 6c1) |

### 5.2 `cl_primeira_academia` (B1 da 6a resolvido)
- Gatilho `gym_arrival`, `once`, prioridade 6, `defer`. Condições: `location: gym` + `milestone_present: ["cena_primeira_academia"]`.
- Momento: o 1º momento calmo depois da cena e da escolha da arte (§1.2). A vaga `once` não se perde.
- Intervalo: prioridade 6 precisa de 60 s desde o último comentário. Se algum comentário tocou menos de 60 s antes do MUDAR, ela espera na vaga. Na prática, a cena e a escolha da arte já gastam ≥ 15 s.
- **Rearme** (como `garage_saved_return` e a 1ª derrota): uma vez por sessão, com sala calma na academia, marco presente e `cl_primeira_academia` fora de `lines_seen`, dispara `gym_arrival`. Cobre "fechou o jogo antes da fala" e o save antigo (critério 5).
- As `cl_academia_volta_*` e `cl_ac_chegada_*` usam `after_line`, então só falam a partir da campanha **seguinte** à da `cl_primeira_academia`. Na mesma chegada nunca tocam as duas.

### 5.3 Chegadas seguintes
`gym_arrival` (teto 1 `rest` por campanha) escolhe entre `cl_ac_chegada_*` e `cl_academia_volta_*` (depois do pedido da §5.1), com o descanso de 1 campanha.

### 5.4 Comentário da arte (`cl_arte_*`)
- **Problema:** o gatilho `art_choice` existe nos dados, mas nada o dispara. Se ele saísse no momento da escolha, perderia quase sempre:
  - no começo de toda campanha depois de derrota, para a `after_defeat` (prioridade 5 ou 9, no mesmo momento calmo; o resto é descartado);
  - na 1ª chegada, para a `cl_primeira_academia`.
- **Regra:** `art_choice` sai **uma vez por campanha**, quando `art_seconds` (tempo de sala ativa com a arte) cruza `after_art_seconds = 60` (`escola.json → art_comment`). Ou seja, o Osmar comenta depois de 1 minuto de treino com a arte. O cruzamento não sai na carga.
- **Pedido para `dialogos.json → triggers.art_choice`:** `priority 5, defer true, campaign_cap 1`, no lugar de `3, false, 1`. Com prioridade 5, ela usa o intervalo de 60 s, e não o de 120 s dos enchimentos. Assim ela cai entre a fala do começo e as compras.
- A conta de uma campanha com derrota antes: `after_defeat` em ~2 s, arte em ~62 s. Se o intervalo não deixar, ela espera até 15 s na vaga. A frequência total sobe no máximo +1 por campanha, dentro da meta de 5–10 da 6a.
- Opcional, para o Roteirista: a condição nova `art: "<id>"` (arte da campanha) permite falas por arte. As 4 atuais servem para qualquer arte, e nenhuma chama uma arte de "a certa".

---

## 6. A saída do John

### 6.1 Quando fica devida
`saida_devida()` é verdadeira quando **tudo** vale:
1. `"first" in school.mentors` (o John está na escola; um Novato migrado antes da 1ª sucessão não conta);
2. `lutador_atual() == "disciple"`;
3. marco `cena_saida_primeiro_mentor` ausente;
4. **e uma das duas:**
   - **(A)** marco `disciple_gym_win` presente;
   - **(B)** `career_number >= first_fighter_campaign + 3` (reserva).

Marco novo `disciple_gym_win`:
- é gravado em `concluir_luta()` na vitória, **no mesmo `salvar()` do prêmio**, se: `lutador_atual() == "disciple"`, `local_id == "gym"`, `"first" in school.mentors` e o marco está ausente;
- extra: `{opponent}`;
- com a regra 1, uma vitória de Novato migrado sem o John sentado não deixa a saída "armada" para logo depois da cena da 1ª sucessão.

Por que **F + 3**, e não "Carreira 4": num save novo, F = 1 e a reserva é a Carreira 4, o 3º discípulo, como o Diretor pediu. No save do dono, F = 3 (a Carreira 3 foi a do John). Com F + 3, ele recebe a mesma folga de dois discípulos, e não uma saída logo na 1ª campanha de discípulo. O offset fica em `escola.json → mentor_leave.reserve_campaign_offset`.

### 6.2 O momento exato
Devida a saída, ela começa no **1º quadro em que**:
- a sala está calma: `sala_ativa()`, abertura `over`, `sucessao == "none"`, `cena_sala == ""`, sem balão, 2 s de calma (`settle_seconds`);
- não há gesto nem toques tocando (ela espera os 0,44 s dos toques do 1º clique);
- o John está **desenhado** no local: garagem, ou academia com o marco `cena_primeira_academia`. Na academia sem o marco ela espera a garagem.

Na prática:
- **(A)**: ~2 s depois de fechar a janela da vitória, de volta à academia. Se a campanha acabar antes (aposentar na hora), sai no começo da campanha seguinte, na garagem, logo depois da chegada do novo discípulo.
- **(B)**: ~2 s depois da chegada do discípulo da campanha F+3 (e da arte, se pendente), na garagem.

**Precedência:** a saída vem antes de qualquer comentário no mesmo quadro. Os comentários que chegarem durante ela vão para a vaga, que **não envelhece** enquanto a saída toca. Ao terminar, a saída conta como comentário (`_ultimo_comentario`). Com isso:
- falas `once` e de prioridade ≥ 9 tocam logo depois;
- uma fala de vitória (revanche/recorde, `rest`, prioridade 6–7) em geral se perde pelo intervalo de 60 s. É aceitável: ela volta em outras campanhas, e o Osmar já falou na saída.

### 6.3 Como acontece (`cenas-curtas.md` §2)
- **Começo:** grava o marco `cena_saida_primeiro_mentor` e aplica `grants: [mentor_leaves first_fighter]`: `school.mentors.erase("first")`, `salvar()` imediato. A partir daqui a regra dos mentores (§4.1) já é a "depois da saída". Só o desenho espera a cena.
- **Ação** (passos passivos `move`, `pose`, `say` passivo, `sound`, `prop`; sem `ui hide`, sem `camera`, sem gesto), com ≈ 12 s + ≈ 2 s:
  1. o John levanta do `seat`, pega a bolsa e anda até perto da saída;
  2. olha a sala e diz `saida_rumo_1` e `saida_rumo_2`;
  3. o Osmar diz `saida_resposta` sem parar o que faz, e o John acena com a cabeça;
  4. ele sai: na garagem, por baixo da porta de enrolar; na academia, pela porta da rua;
  5. se houver o último em pé, ele anda do `stand` até o `seat` e senta (`sit_rest`). Sem último, o caixote fica vazio.
- **Jogador no controle o tempo todo:** a sala continua ativa e o relógio anda (0 s presos). O 1º soco vale, o clique não interrompe, e o ESPAÇO só treina.
- `max_seconds` 14 (em `escola.json → mentor_leave.max_seconds`), só como teto do validador: não prende nada.

### 6.4 Interrupção
Termina **na hora**, aplicando o `end_state`, quando acontece qualquer um destes: abrir janela (loja, árvore, mapa, prévia do dia da luta), começar luta, mudar de local, tela de fim ou RECEBER.

No `end_state`:
- o John some;
- o último fica sentado no `seat`, ou o caixote fica vazio;
- o `stand` fica vazio;
- os balões da cena fecham (`fala_cancelada`).

### 6.5 Fechar o jogo no meio
O marco e o `mentor_leaves` foram salvos no começo. Ao abrir, a sala já está no estado final: sem John, o último sentado (ou o caixote vazio) e o `stand` vazio. A ação **nunca toca de novo** e não há estado da saída no save.

### 6.6 Depois
- O John não aparece em sala nenhuma: `"first"` saiu de `school.mentors`, e os toques, o `mentor_sentado()` e a cena da academia dependem disso.
- Não fica nenhum objeto dele na sala.
- A cena da academia, se ainda não tocou (saída pela reserva antes de qualquer cinturão), usa o último para carregar a caixa (§1.4).
- O roster não muda: a entrada `kind: first` continua lá para o mural da 6c2.

### 6.7 Casos
| Save | O que acontece |
|---|---|
| Novo, 1ª vitória na academia na Carreira 2 | sai na academia depois dessa vitória. O seat fica vazio até a Carreira 3, quando o discípulo da Carreira 2 senta |
| Novo, sem academia nas Carreiras 2 e 3 | sai no começo da Carreira 4, na garagem. O discípulo da Carreira 3 vai do stand para o caixote |
| Novo, 1ª vitória na academia na Carreira 3 | sai na academia, e o discípulo da Carreira 2 senta |
| Do dono (F = 3) | igual, com a reserva na Carreira 6 |
| Novo, cinturão na Carreira 1 (o John chega à academia) | toca a cena da academia (John com o saco, vizinho com a caixa). A vitória do John não arma a saída |
| v11 migrado com Novato antes da 1ª sucessão | nada até a 1ª sucessão sentar o John. A partir daí, as regras acima |

---

## 7. Save: continua v12, sem migração
| Item novo | Onde | Cabe na v12? |
|---|---|---|
| `cena_primeira_academia` | `school.milestones` | sim: `_validar_escola` guarda qualquer id com `{campaign, version, ...}` |
| `cena_saida_primeiro_mentor` | `school.milestones` | sim |
| `disciple_gym_win` (`{opponent}`) | `school.milestones` | sim |
| John fora | `school.mentors` (já existe; vira `[]`) | sim |
| Falas novas | `school.lines_seen` (ids livres) | sim |
| `cena_sala`, saída tocando, vaga | memória | não vão para o save |

**Confirmado: nenhum campo novo e nenhuma migração.** `VERSAO_ATUAL` continua 12. Um save da 6c1 aberto num build da 6b2 também funciona: os marcos desconhecidos são mantidos e não têm efeito. O teste com a cópia do save do dono (critério 5) só precisa ver a cena no próximo MUDAR e a `cl_primeira_academia` uma vez.

---

## 8. Balanço: nada muda
| Ponto | Por que não muda |
|---|---|
| Cena da academia | relógio e produção congelados (§1.3). 0 s de campanha somados. Custa ~13 s de tempo real, uma vez na vida do save |
| Saída do John | 0 s presos, sala ativa e clique valendo. Só visual |
| Mentores, Osmar, foto, toques | só visuais. Nenhuma conta lê nada disso |
| Comentário da arte | balão passivo (regras da 6a) |
| `data/` de balanço | nenhum arquivo muda (`training`, `generators`, `fights`, `opponents`, `shop`, `skill_tree`, `career`, `locations`, `arts`). Mudaram só `disciples.json` (blocos de sala) e o novo `escola.json`, que nenhuma conta lê |

Simulação: o `tools/sim/fase5_sim.py` não tem parâmetro que a 6c1 toque, então o resultado é idêntico ao da 6b2 por construção: 23b 26,4% / 0,2%; cinturão mais cedo 20:44; 1ª derrota da campanha 1 13:39 / 14:09.
- **Não rodei nesta máquina:** o Python não está instalado.
- O QA confirma com `fase5_sim.py b23c` e `f52`, mais dois testes no Godot:
  1. `segundos_campanha`, `tempo_jogo`, treino e dinheiro iguais antes e depois da cena da academia, tocada e pulada;
  2. duas campanhas iguais, uma com a saída no meio e outra sem, dão relógio, treino, ouro, dia e luta idênticos.

---

## 9. Dados e contrato

### 9.1 Arquivos
| Arquivo | Dono | O que entra na 6c1 |
|---|---|---|
| `data/escola.json` (**novo, criado por mim**) | Designer | `gym_arrival`, `coach_presence`, `old_photo`, `mentor_leave`, `art_comment` |
| `data/disciples.json` (blocos `_6c1`, criados por mim) | Designer | `mentor_taps.locations`, `only_first`; `room_mentors.spots_by_location`, `seat_prop`, `after_first_leaves`; `second_mentor.locations`, `hidden_during_scenes_6c1`. As chaves antigas (`location`, `spot`, `hidden_during_scenes`) ficaram para o build atual seguir verde. O Programador troca a leitura e depois apaga as antigas |
| `data/dialogos.json` | Roteirista (os pedidos da §5 são meus) | `cl_primeira_academia` + `milestone_present`; `cl_academia_volta_*` → `gym`; `cl_ac_derrota_*` tirar ou soltar; `triggers.art_choice` 5/defer/1; `objects.old_photo_gym` |
| `data/cutscenes/primeira_academia.json` | Diretor de Cutscenes | `milestone: cena_primeira_academia`, `trigger: {event: location_reached, requires: {location: gym, milestone_missing: [cena_primeira_academia]}}`, `blocking: true`, `max_seconds: 15`, `stage.hide: [player, crew, mentors, coach]`, elenco da §1.4 |
| `data/cutscenes/saida_primeiro_mentor.json` | Diretor de Cutscenes | `milestone: cena_saida_primeiro_mentor`, `grants: [{type: mentor_leaves, character: first_fighter}]`, `blocking: false`, gatilho `mentor_leave_due` (novo; o `GameState` decide pela §6.1–6.2), versões ou pontos para garagem e academia |

### 9.2 Números
| Decisão | Valor | Onde |
|---|---|---|
| Cena da academia: tempo preso | ≈ 13 s, teto 15 s | `escola.json → gym_arrival.max_locked_seconds` |
| Relógio na cena da academia | parado (0 s) | §1.3 |
| Saída: tempo preso / teto do validador | 0 s / 14 s | `mentor_leave.locked_seconds`, `max_seconds` |
| Saída: calma antes de começar | 2 s (o mesmo das falas) | `mentor_leave.settle_seconds` |
| Reserva da saída | campanha ≥ F + 3 | `mentor_leave.reserve_campaign_offset` |
| Comentário da arte | 60 s de arte, prioridade 5, defer, teto 1 | `art_comment.after_art_seconds`; `triggers.art_choice` |
| Toques do John | 60 s / 0,5 s / 1,0 s (sem mudança), garagem e academia | `mentor_taps` |

### 9.3 Contrato para o Programador (nomes sugeridos)
| Onde | Item |
|---|---|
| `GameState` (estado) | `cena_sala` ("" \| "primeira_academia"), fora do save. Entra em `tick`, `sala_ativa()` e `escolha_arte_pendente()` |
| `GameState` (ações) | `cena_sala_terminou()` (o player chama no `return_control`/`end_state`); `saida_terminou()` (fim ou interrupção da saída: zera o "tocando" e marca o comentário) |
| `GameState` (leitura) | `coach_presente() -> bool`; `foto_antiga() -> {spot, object_text, tilted}` ou {}; `elenco_primeira_academia()`; `saida_devida() -> bool`; `mentores_na_sala()` passa a valer nos dois locais e depois da saída (`{id "first"\|"last", spot, pose, glove, facing, campaign, name, look}`); `assento_visivel() -> bool` |
| sinais | `cena_sala_pedida(id)`, `saida_mentor_pedida()`, `saida_mentor_interrompida()` |
| `mudar()` | §1.2 (marco, sem `escolha_arte_pedida`, `cena_sala_pedida`) |
| `concluir_luta()` | marco `disciple_gym_win` (§6.1) |
| `_tick_falas` | rearme da `cl_primeira_academia` (§5.2); `art_choice` no cruzamento de 60 s (§5.4); saída devida → pede no momento calmo (§6.2); `_tick_abertura` usa `coach_presente()` |
| Falas | candidata do `coach` só com `coach_presente()`; condição nova opcional `art` |
| testes (save de teste) | cena da academia: tocar, pular e fechar no meio (marco, estado final, arte depois, relógio parado); save sem marco que já esteve na academia: cena no próximo MUDAR e `cl_primeira_academia` 1x; elenco nos 3 casos; Osmar e foto na academia só com o marco; saída por (A) e por (B), interrompida por janela, luta e MUDAR, fechar no meio, nunca 2x; mentores antes e depois nos dois locais; nenhum toque depois da saída; caixote visível e vazio na Carreira 2 depois da saída; balanço igual (§8) |

---

## 10. Fora da 6c1 (não adiantar)
- Mural, `mural_spot`, Honra, árvore do hall, bônus do retrato.
- Falas dos mentores (recorde, revanche, "mais longe que eu").
- Símbolo da escola no peito.
- Voz dos mentores.
- "Igual ao anterior" na criação.
- Comentário do Osmar sobre a saída na volta à garagem: é o ajuste do risco §8 do escopo, só se os testadores não perceberem a saída.

---

## Resumo
- **Cena da academia:** toca no MUDAR para a academia com o marco `cena_primeira_academia` ausente, inclusive em save antigo, que a vê no próximo MUDAR. O marco vai no mesmo `salvar()` da mudança. O relógio fica parado (`cena_sala`), a escolha da arte vem depois e a `cl_primeira_academia` vem no 1º momento calmo. Quem carrega a caixa: o John, senão o último que passou o posto, senão um vizinho.
- **Academia como casa:** depois do marco, o Osmar aparece no `gym_coach_spot`, a foto antiga fica torta no `gym_photo_spot` e os mentores ficam no `gym_mentor_spot`/`gym_mentor_2_spot` com a mesma regra da garagem. Regra única: só fala quem está desenhado.
- **Saída do John:** fica devida pela 1ª vitória de discípulo na academia (marco `disciple_gym_win`) ou pela campanha F + 3. Toca no 1º momento calmo com o John desenhado, com 0 s presos. Marco e `mentor_leaves` gravados no começo. Janela, luta ou MUDAR terminam a ação na hora. Depois dela, o último senta e o `stand` fica vazio; na Carreira 2, o caixote fica vazio.
- **Save v12 sem migração** (só marcos novos). **Balanço inalterado** (nenhum arquivo de balanço mudou; simulação idêntica por construção, o QA confirma).
