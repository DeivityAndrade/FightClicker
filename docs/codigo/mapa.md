# Mapa do GameState (scripts/game_state.gd + scripts/estado/)

Estado central do jogo (autoload `GameState`, `class_name EstadoJogo`). A refatoração dividiu um arquivo de ~4.900 linhas em
um núcleo (~1.000 linhas) e 15 módulos em `scripts/estado/`. **Nada mudou para quem usa**: telas e testes continuam chamando
`GameState.mural()`, `gs.comprar_hall(...)` etc.; as variáveis (`treino`, `fama`, `permanente`, `luta`...) e os sinais
continuam em GameState com os mesmos nomes.

## Como funciona
- `game_state.gd` guarda: sinais, constantes, **todas as variáveis de estado**, `_ready/_process/_notification`,
  `inicializar`, `tick` (a orquestração), os pequenos auxiliares de saldo (`_ganhar`, `_gastar`, `_gastar_dinheiro`,
  `_definir_treino`, `_numero_valido`, `_numero_ou`, `_inteiro_valido`, `_avisar`) e `preencher` (static).
- Cada função pública virou um repasse de uma linha: `func mural() -> Array: return _honra.mural()` (com um `##` em cima).
- Cada módulo é `extends RefCounted`, tem `var gs: EstadoJogo` e lê/grava as variáveis em `gs.x`. Dentro do módulo,
  funções do próprio módulo são chamadas direto; as dos outros assuntos passam por `gs.` (públicas) ou `gs._outro._f()` (privadas).
- Os módulos são criados em GameState (`var _honra := _HonraMural.new(self)`). O tipo `EstadoJogo` deixa o `:=` funcionar nos módulos.
- Privadas que testes ou telas chamam (`gs._gravar_marco`, `gs._atributos_array`...) também têm repasse em GameState.
- Cuidado ao mexer: nunca declare variável local chamada `gs` num módulo; a ordem das chamadas ao `rng` não pode mudar.

## Módulos (arquivo: o que faz; principais repasses)
| Módulo (var em GameState) | O que faz | Principais funções públicas |
|---|---|---|
| `depuracao.gd` (`_depur`) | tempo morto (QA), atalhos debug | `tempo_morto`, `menor_preco_loja`, `debug_*` |
| `textos.gd` (`_textos`) | textos montados; não muda estado | `texto_ui`, `texto_efeito_*`, `texto_stake_*`, `texto_hud_*`, `texto_passiva`, `textos_fim` (com `passive_note*`), `lista_ui`, `dica_aposentar` |
| `loja_geradores.gd` (`_loja`) | produção, cliques, geradores, melhorias, evento dourado, luvas, loja de dinheiro, Metrônomo | `clicar`, `auto_socar`, `por_clique`, `producao_total`, `comprar_gerador`, `comprar_melhoria`, `pegar_evento_dourado`, `comprar_luva`, `comprar_gerador_pago`, `comprar_metronomo`, `definir_modal` |
| `aparelhos.gd` (`_aparelhos`) | aparelhos (4b), modo assistido, caixas de equipamento (5.1) | `comprar_aparelho`, `estado_aparelho`, `definir_assistido`, `bater_caixa`, `abrir_caixa`, `caixas` |
| `calendario.gd` (`_calendario`) | relógio da campanha, dias, data da luta, avisos | `sala_ativa`, `dia_campanha`, `dias_para_luta`, `no_dia_da_luta` |
| `luta.gd` (`_luta`) | táticas, prévia (com a linha da passiva da arte), risco do HUD, revanche, a luta, golpes e fases visuais por arte, arena por local, motivo da derrota em segundo plano | `definir_tatica`, `previa`, `info_proxima`, `risco_proxima`, `lutar`, `concluir_luta`, `luta_atual`, `arena_da_luta`, `motivo_da_luta`, `aguardar_motivo` |
| `carreira.gd` (`_carreira`) | escada, fim de carreira, Legado, nova carreira | `pode_lutar`, `proximo_adversario`, `aposentar`, `nova_carreira`, `legado_em_jogo`, `resumo_legado`, `cartao_inicio` |
| `arvore.gd` (`_arvore`) | árvore do Legado: bônus, nós, mapa | `bonus_de`, `comprar_no`, `estado_no`, `arvore_mapa`, `nos_compraveis` |
| `academia_artes.gd` (`_academia`) | garagem x academia, mudança, artes marciais, passiva de luta (`_atualizar_passiva`: põe a passiva e o extra dos nós no motor) | `mudar`, `local_atual`, `escolher_arte`, `bonus_arte_clique`, `tatica_efetiva` |
| `save_validacao.gd` (`_save`) | save e validações da carga, avisos, emissão de tudo | `salvar`, `carregar_save`, `apagar_save`, `para_save`, `aplicar_save` |
| `escola_falas.gd` (`_escola`) | 6a: marcos, abertura, falas com balão, gesto de calçar | `marco`, `pular_abertura`, `disparar_gatilho`, `fala_terminada`, `pedir_gesto`, `registrar_clique` |
| `sucessao.gd` (`_sucessao`) | 6b: passar o posto, discípulo, rascunho, mentores, toques do John | `receber_discipulo`, `sucessao_tela_aberta`, `confirmar_discipulo`, `sucessao_terminou`, `sortear_rascunho`, `nome_lutador`, `visual_lutador` |
| `casa_nova.gd` (`_casa`) | 6c1: cena de chegada à academia, elenco da sala, saída do John | `cena_sala_terminou`, `elenco_primeira_academia`, `papel_da_sala`, `ponto_do_coach`, `saida_devida`, `saida_terminou` |
| `honra_mural.gd` (`_honra`) | 6c2: Honra, hall, mural, vozes dos mentores, linha "FALTA" da prévia (segundo plano) | `honra`, `hall_lista`, `comprar_hall`, `mural`, `mural_na_sala`, `voz_do_mentor`, `aguardar_falta` |
| `treino_fora.gd` (`_treino`) | 7a2: convite do Osmar, estado "treino fora", prêmios, AQUECIDO, Gato Preto | `convite_visivel`, `convite_ir`, `treino_jogo`, `treino_concluir`, `treino_voltar`, `aquecido`, `mult_aquecido`, `recorte_gato_preto` |

## Variáveis de estado mais usadas (todas em GameState)
- Carreira: `treino`, `atributos`, `foco`, `geradores`, `niveis_melhoria`, `geradores_pagos`, `nivel_luva`, `dinheiro`, `fama`,
  `indice_escada`, `cinturao`, `tatica`, `luta` (luta decidida e ainda não aplicada), `nivel_metronomo`, `local_id`, `arte_id`,
  `segundos_campanha`, `fight_day`, `caixas_lista`, `aparelhos_montados_ids`, `nos_ativos_ids`.
- Entre carreiras: `permanente` (Legado, nós, carreira nº), `fim` (tela de fim pendente), `escola` (marcos, falas vistas, Honra, hall, roster).
- Sucessão: `discipulo`, `sucessao`, `cena_sala`, `mentor_cumprimentou`.
- Dados carregados: `dados` (TrainingData), `lutas` (FightData), `academia` (GymData), `dialogos`, `disciples`, `motor` (Luta), `golpes`, `config`, `escola_cfg`, `hall_cfg`.
- Aleatório (a ordem das chamadas não pode mudar): `rng` (crítico e luta), `_rng_evento`, `_rng_fala`, `_rng_sucessao`.
- Internas dos módulos mas guardadas aqui: `_bonus`, `_gatilhos_quadro`, `_vaga`, `_balao`, `_toques`, `_falta_*`, `_motivo_*`, `_t_real`.

## Verificação da refatoração
`tools/refatoracao/foto.gd` (headless) grava um texto determinístico (simulação, robô de 3.000 passos com hash do save a cada 100
passos e partida roteirizada com leituras e o JSON do save). Rode antes e depois de mexer e compare com `diff`/`fc`:
`godot --headless --path . --script res://tools/refatoracao/foto.gd -- --out=C:\caminho\foto.txt`.

## Fase 7a1: cada arte luta do seu jeito (motor em `scripts/luta.gd`)
Referência de contas: `tools/sim/fase7a1_sim.py`; design: `docs/fases/fase7a1-design.md`. Dados: `data/arts.json -> passive`, `data/moves.json`, `data/locations.json -> fight_arena`.
- **Motor (`Luta`)**: `passiva` (vazia = sem arte, laço de sempre com 3 sorteios; com passiva `_rodar_arte`, 4 sorteios: esquiva, crítico, variação, arte) e `extra_passiva` (nós Contragolpe/Base firme). `estado_passiva()`, `chance_detalhada()` ({chance, wins, wins_passive, n}), `nota_passiva()`, `aplicar_passiva()` (no lugar do traço, que saiu). Quem põe a passiva no motor é `_academia._atualizar_passiva()` (o nome antigo `_atualizar_traco` ainda repassa).
- **Resultado do motor (só com arte)**: `finish` ("damage"|"knockout"|"submission"|"points"), `streak_peak`, `attempts`, `opp_counter_damage`, `grip_full_at` (-1 sem JJ), `tired_at` (-1 sem Boxe). Eventos: `streak`, `grip` (0-1), `tired`, `finish`.
- **O que a UI lê em `previa()` (só com arte; sem arte as chaves não existem)**: `passive_name`, `passive_line`, `passive_state` (Boxe: `streak_max, ko_max, interval, tired_at, tired_round, tired, opp_counter`; JJ: `grip_full_at, grip_round, grip_in_time, sub_chance`), `passive_share`, `passive_share_n`, `passive_tactics` ({tática: o mesmo bloco, para trocar de tática sem recalcular}); `art_fight_text` agora é o texto do cartão da arte.
- **O que a UI lê em `luta_atual()`**: `arena` ("arena" | "arena_league"), `passive` ("" | "fast_hands" | "submission"), `result.finish` (sempre preenchido na cópia da UI), `streak_peak`, `attempts`, `grip_full_at`, `tired_at`; por evento: `streak`, `grip`, `tired`, `finish`, `phase` ("standing"|"ground"), `phase_after`, `kind` pode ser `takedown` ou `submission`, `move`/`move_anim`/`defender_move_anim` já pelo estilo (JJ: `bjj` e `ground_bottom` no chão; reação `tap_out` na finalização).
- **Motivo da derrota**: `motivo.passive_note` = {id, n, r} (só com arte); `textos_fim()` traz `passive_note`, `passive_note_tip`, `passive_note_id` (textos de `reason_passive_*` e `tip_passive_*`).
- **Save**: continua v13; `career.fight.result.finish` é opcional (só lutas com arte).
- **Golpes**: `MovesData.KINDS` ganhou `takedown` e `submission`; golpe tem `phase`; `escolher(..., fase)` filtra pela fase.
- **Arena**: `GameState.arena_da_luta(adversario_id)`; vale a do local do adversário (`location`).
- **Testes**: `tests/test_fase7a1.gd` (casos exatos em `tests/data/fase7a1_casos.json`, gerado por `tools/sim/exportar_casos.py`).

## Fase 7a2: Treino fora de hora (convite do Osmar, Choque, Panfletagem, AQUECIDO)
Design: `docs/fases/fase7a2-design.md`; referência de contas: `tools/sim/fase7a2_sim.py`; números: `data/minigames.json` (lido por `MinigamesData`, `scripts/minigames_data.gd`; arquivo ausente = sem convites).
- **Arquivos**: `scripts/estado/treino_fora.gd` (estado, convite, prêmios, AQUECIDO), `scripts/minigame_choque.gd` (`ChoqueLogica`) e `scripts/minigame_panfleto.gd` (`PanfletoLogica`): lógica pura, sem tela, sorteio só na criação (rng recebido). Teste: `tests/test_fase7a2.gd`.
- **Variáveis em GameState**: `minigames`, `convite` ({room_s, next_at, open, open_since, last, warm}), `treino_fora` ("" | "spar" | "flyers"), `_treino_jogo`, `_rng_treino` (não vai para o save; o minigame e o convite nunca usam `rng`, `_rng_evento`, `_rng_fala`, `_rng_sucessao`).
- **Sinais**: `convite_mudou(tipo)` ("" = balão sumiu/escondeu), `treino_fora_mudou(estado)`, `aquecido_mudou(ativo)`.
- **Relógio**: `convite.room_s` anda com sala ativa + Osmar desenhado (`coach_presente`). Balão de fala, abertura, gesto de calçar, toques e saída do John escondem o balão e param o tempo dele. Dia da luta e MUDAR (local diferente) fecham em silêncio. `sala_ativa()` é falso com `treino_fora != ""`; nesse estado o `tick` só soma `producao_total() x delta` (foco atual) e passa o tempo do minigame (**a UI não chama `passo`**).
- **O que a UI chama**:
  1. Balão: escutar `convite_mudou(tipo)` (ou ler `convite_visivel()`; `convite_info()` traz `restante_s`). Clique em IR (ou no Osmar com o balão): `convite_ir()` -> `{kind, art, level, variant, rumor_text, countdown_s, duration_s}`; `rumor_text` não vazio = mostrar o balão do boato antes da contagem (o marco já foi gravado).
  2. Minigame: `treino_jogo()` devolve o objeto. **Choque** (`ChoqueLogica`): `apertar()` / `soltar()` (Boxe: apertar = clique, segurar 0,2 s = guarda; JJ: segurar = puxar), `estado()` ({fase "contagem"|"jogando"|"fim", contagem, restante, barra -1..1, folego, forca, pontos, pontos_dele, meta, congelado, padrao "burst"|"pause"|"feint"|"", momento "aviso"|"ativo"|"", sinal "red"|"white"|"", aviso_frac, x2, guarda, segurando}), `pegar_eventos()` ("clique", "contragolpe", "ponto_jogador", "ponto_dele", "aviso_burst|pause|feint", "finta_virou", "inicio_burst|pause|feint", "fim"). **Panfletagem** (`PanfletoLogica`): `pessoas()` ([{id, x 0..1, faixa 0..1, tipo 0..4, sinal "interesse"|"falso"|"fechada"|"", resolvida, aceitou}]), `clicar(id)` (id -1 = vazio; devolve "aceitou"|"erro"|"ocupado"|"ignorado"), `estado()` ({fase, contagem, restante, aceitos, erros, liquidos, meta, mao_ocupada}), `pegar_eventos()` ("aceitou", "erro", "fim").
  3. Fim (`estado().fase == "fim"`) ou SAIR: `treino_concluir()` aplica e salva o prêmio e o devolve: Choque `{kind, pontos, pontos_dele, nota, venceu, saiu, treino, atributos {id: n}, aquecido (novo), aquecido_ja, sem_luta}`; Panfletagem `{kind, aceitos, erros, liquidos, nota, fama, saiu}`. VOLTAR: `treino_voltar()` (devolve a sala; o próximo convite espera 60 s de sala). Trava de segurança: 120 s na tela de prêmio sem VOLTAR devolvem a sala.
  4. AQUECIDO: `aquecido()` (ícone na sala, sinal `aquecido_mudou`). Em `previa()` ganham-se chaves SÓ com AQUECIDO: `warm`, `warm_pct` (3), `warm_gain` (+N na chance da tática escolhida), `warm_gains` (por tática), `warm_line` (texto `warm_preview_line`). `previa().you` continua com os atributos reais; `risks[t].chance` já vem com x1,03.
  5. Gato Preto: `recorte_gato_preto()` -> `{spot [x, y], object_text}` ou `{}` (campanha >= 2, marco `garage_saved`, na academia o marco da cena; precisa do ponto `clipping_spot` / `gym_clipping_spot` no manifest, ainda não existe).
- **AQUECIDO no motor**: `_luta._atributos_array()` multiplica por `mult_aquecido()` (1,03); é a única entrada de prévia, risco do HUD, `risco_tatica` e `lutar()`. `lutar()` gasta o AQUECIDO. `_atributos_cru()` = sem bônus. `gs.luta.player` guarda os atributos já x1,03.
- **Save**: continua v13. `career.training_invite` (opcional, sempre gravado); validado em `treino_fora.validar` (número ruim = padrão; `open`/`last` fora da lista ou `open` sem elegibilidade = ""; `warm` só com arte e luta pela frente). `_zerar_carreira` zera (convite, AQUECIDO, minigame). Marco novo `black_cat_rumor_heard` (grava no IR da 1ª Panfletagem com o recorte devido).
- **Foto**: `tools/refatoracao/foto.gd` apaga `career.training_invite` antes de cada hash/JSON (`_save_sem_convite`).
- **Conhecido (aceito)**: o motivo da derrota (`motivo_da_luta`) parte de `gs.luta.player`, que já vem x1,03 com AQUECIDO; só o texto "faltaram X" muda. Só o gesto de calçar esconde o balão do convite (gestos ociosos e fala na vaga de espera não).
