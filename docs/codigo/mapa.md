# Mapa do GameState (scripts/game_state.gd + scripts/estado/)

Estado central do jogo (autoload `GameState`, `class_name EstadoJogo`). A refatoração dividiu um arquivo de ~4.900 linhas em
um núcleo (~1.000 linhas) e 14 módulos em `scripts/estado/`. **Nada mudou para quem usa**: telas e testes continuam chamando
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
| `textos.gd` (`_textos`) | textos montados; não muda estado | `texto_ui`, `texto_efeito_*`, `texto_stake_*`, `texto_hud_*`, `textos_fim`, `lista_ui`, `dica_aposentar` |
| `loja_geradores.gd` (`_loja`) | produção, cliques, geradores, melhorias, evento dourado, luvas, loja de dinheiro, Metrônomo | `clicar`, `auto_socar`, `por_clique`, `producao_total`, `comprar_gerador`, `comprar_melhoria`, `pegar_evento_dourado`, `comprar_luva`, `comprar_gerador_pago`, `comprar_metronomo`, `definir_modal` |
| `aparelhos.gd` (`_aparelhos`) | aparelhos (4b), modo assistido, caixas de equipamento (5.1) | `comprar_aparelho`, `estado_aparelho`, `definir_assistido`, `bater_caixa`, `abrir_caixa`, `caixas` |
| `calendario.gd` (`_calendario`) | relógio da campanha, dias, data da luta, avisos | `sala_ativa`, `dia_campanha`, `dias_para_luta`, `no_dia_da_luta` |
| `luta.gd` (`_luta`) | táticas, prévia, risco do HUD, revanche, a luta, motivo da derrota em segundo plano | `definir_tatica`, `previa`, `info_proxima`, `risco_proxima`, `lutar`, `concluir_luta`, `luta_atual`, `motivo_da_luta`, `aguardar_motivo` |
| `carreira.gd` (`_carreira`) | escada, fim de carreira, Legado, nova carreira | `pode_lutar`, `proximo_adversario`, `aposentar`, `nova_carreira`, `legado_em_jogo`, `resumo_legado`, `cartao_inicio` |
| `arvore.gd` (`_arvore`) | árvore do Legado: bônus, nós, mapa | `bonus_de`, `comprar_no`, `estado_no`, `arvore_mapa`, `nos_compraveis` |
| `academia_artes.gd` (`_academia`) | garagem x academia, mudança, artes marciais, traço de luta | `mudar`, `local_atual`, `escolher_arte`, `bonus_arte_clique`, `tatica_efetiva` |
| `save_validacao.gd` (`_save`) | save e validações da carga, avisos, emissão de tudo | `salvar`, `carregar_save`, `apagar_save`, `para_save`, `aplicar_save` |
| `escola_falas.gd` (`_escola`) | 6a: marcos, abertura, falas com balão, gesto de calçar | `marco`, `pular_abertura`, `disparar_gatilho`, `fala_terminada`, `pedir_gesto`, `registrar_clique` |
| `sucessao.gd` (`_sucessao`) | 6b: passar o posto, discípulo, rascunho, mentores, toques do John | `receber_discipulo`, `sucessao_tela_aberta`, `confirmar_discipulo`, `sucessao_terminou`, `sortear_rascunho`, `nome_lutador`, `visual_lutador` |
| `casa_nova.gd` (`_casa`) | 6c1: cena de chegada à academia, elenco da sala, saída do John | `cena_sala_terminou`, `elenco_primeira_academia`, `papel_da_sala`, `ponto_do_coach`, `saida_devida`, `saida_terminou` |
| `honra_mural.gd` (`_honra`) | 6c2: Honra, hall, mural, vozes dos mentores, linha "FALTA" da prévia (segundo plano) | `honra`, `hall_lista`, `comprar_hall`, `mural`, `mural_na_sala`, `voz_do_mentor`, `aguardar_falta` |

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
