# Fase 7b1: poses do Muay Thai (entradas para o manifest)

Artista de Personagens. Registrado pelo `tools/art/manifest_7b1.py` (blocos `sprites` e `by_data_id` abaixo).
PNG em `assets/sprites/fight/`, `assets/sprites/disciple/` (discípulo, com camadas e as 5 luvas), `assets/sprites/characters/`
(chute no saco) e `assets/sprites/opponents/<id>/`. Nenhum arquivo antigo foi sobrescrito.

## Como foi gerado (dá para rodar de novo)
Poses em dados em `tools/art/golpes_7b1.json` e `golpes_7b1_adv.json` (autoria: `python tools/art/poses_7b1.py`).
Numa pasta temporária com `project.godot` vazio (nunca no projeto), `<repo>` = esta pasta:
```
FC_LUTADOR=disc FC_CAMADAS=1 FC_GOLPES=<repo>/tools/art/golpes_7b1.json godot --headless --path <tmp> --script <repo>/tools/art/make_golpes_jogador.gd -- <tmp>/out_j
FC_GOLPES=<repo>/tools/art/golpes_7b1_adv.json godot --headless --path <tmp> --script <repo>/tools/art/make_golpes_jogador.gd -- <tmp>/out_a nada
FIGHTCLICKER_ROOT=<repo>/ godot --headless --path <tmp> --script <repo>/tools/art/make_sprites_elenco.gd -- <tmp>/out_o <tmp>/old reacoes <tmp>/out_a/reacoes_expandidas.json
godot --headless --path <tmp> --script <repo>/tools/art/make_mockup_fase7b1_poses.gd -- <repo> <tmp>/out_j <tmp>/out_o <pranchas>
python tools/art/doc_manifest_7b1.py <tmp>/out_j <tmp>/out_o
python tools/art/manifest_7b1.py
```
Mudanças pequenas nos geradores (chaves novas e opcionais; sem elas o resultado é o mesmo de antes):
- `personagem_lib.gd`: `angf`/`angb` (luta) e `angl`/`angr` (garagem) giram o tênis (pé esticado no chute); `legs_swap` = chute
  com a perna de trás (o quadril girou: a perna que chuta sai do quadril da frente e é desenhada na frente do corpo).
- `make_golpes_jogador.gd`: `hit_key` no golpe = contato que não é a luva (canela, joelho, sola); `frame_size` nos golpes da
  garagem (o chute no saco usa 64x72).

## Contrato
- Luta: quadro 112x104, pivô (56,98), pivôs da arena 296/346 **sem mudança**. O passo do chute rodado (12 px) e da joelhada
  (13 px) é desenhado dentro do quadro e volta no fim.
- Ordem de desenho: quem ataca por cima (como hoje). No clinch, o discípulo por cima.
- Reação do adversário começa no `hit_frame` do golpe (como hoje). `held_clinch` termina junto com o `thai_clinch`;
  `fall_spin` segura o último quadro (como o `ko`).
- Treino: `fighter_low_kick` é **64x72** (o resto do treino é 48x72), mesmo pivô (22,67) em `foco_saco` (303,272).

## Pedidos ao Programador (não mexi em ui/ nem scripts/)
1. **Idle do Muay Thai:** com a arte `muay_thai`, o repouso do jogador na luta é `mt_idle` (guarda tailandesa), não `idle`.
   Todos os golpes do Muay Thai começam e terminam nessa guarda.
2. **Golpes** (`moves.json`, estilo `muay_thai`): `low_kick`, `knee`, `thai_clinch`, `spin_kick` = ações novas de `player_fight`.
   Reações: `hit_leg`, `hit_body` (já existe), `held_clinch`, `fall_spin`.
3. **Chute rodado sem derrubar:** o design manda `fall_spin` em todo rodado; mas `fall_spin` termina deitado. Fiz também
   `hit_spin` (torce e volta à guarda mancando): usar `hit_spin` quando o rodado **não** derruba e `fall_spin` só no K.O.
4. **Mancando:** idle do adversário com 2 marcas = `limp`; com 3 = `limp_heavy` (sem ela, `limp`).
5. **Saco comprido:** no foco `kick_bag`, o lutador usa `fighter_low_kick` (quadro 64x72) no lugar do `fighter_punch`
   (`by_data_id.kick_bag.fighter`). hit em (326,250).
6. **Choque do Muay Thai:** `minigame_layout.spar.player_actions.mt` (abaixo). O parceiro reaproveita as folhas do Boxe.
7. Só discípulo (`*_disc` + `_layered`), como na 7a1: a 1ª carreira não tem arte.

## Tabela (folhas planas; cada `*_disc` tem também a `_layered`)
| id | quadro | quadros | pivô | fps | loop | hit (quadro / ponto) |
|---|---|---|---|---|---|---|
| `fight_player_knee_disc` | 112x104 | 10 | [56, 98] | 14.0 | não | 3 / [36.0, -45.0] |
| `fight_player_knee_glove_l1_disc` | 112x104 | 10 | [56, 98] | 14.0 | não | 3 / [36.0, -45.0] |
| `fight_player_knee_glove_l2_disc` | 112x104 | 10 | [56, 98] | 14.0 | não | 3 / [36.0, -45.0] |
| `fight_player_knee_glove_l3_disc` | 112x104 | 10 | [56, 98] | 14.0 | não | 3 / [36.0, -45.0] |
| `fight_player_knee_glove_l4_disc` | 112x104 | 10 | [56, 98] | 14.0 | não | 3 / [36.0, -45.0] |
| `fight_player_low_kick_disc` | 112x104 | 10 | [56, 98] | 16.0 | não | 4 / [37.0, -24.0] |
| `fight_player_low_kick_glove_l1_disc` | 112x104 | 10 | [56, 98] | 16.0 | não | 4 / [37.0, -24.0] |
| `fight_player_low_kick_glove_l2_disc` | 112x104 | 10 | [56, 98] | 16.0 | não | 4 / [37.0, -24.0] |
| `fight_player_low_kick_glove_l3_disc` | 112x104 | 10 | [56, 98] | 16.0 | não | 4 / [37.0, -24.0] |
| `fight_player_low_kick_glove_l4_disc` | 112x104 | 10 | [56, 98] | 16.0 | não | 4 / [37.0, -24.0] |
| `fight_player_mt_idle_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_mt_idle_glove_l1_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_mt_idle_glove_l2_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_mt_idle_glove_l3_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_mt_idle_glove_l4_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_mt_guard_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_mt_guard_glove_l1_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_mt_guard_glove_l2_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_mt_guard_glove_l3_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_mt_guard_glove_l4_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_mt_kick_disc` | 112x104 | 8 | [56, 98] | 16.0 | não | 3 / [35.0, -42.0] |
| `fight_player_spar_mt_kick_glove_l1_disc` | 112x104 | 8 | [56, 98] | 16.0 | não | 3 / [35.0, -42.0] |
| `fight_player_spar_mt_kick_glove_l2_disc` | 112x104 | 8 | [56, 98] | 16.0 | não | 3 / [35.0, -42.0] |
| `fight_player_spar_mt_kick_glove_l3_disc` | 112x104 | 8 | [56, 98] | 16.0 | não | 3 / [35.0, -42.0] |
| `fight_player_spar_mt_kick_glove_l4_disc` | 112x104 | 8 | [56, 98] | 16.0 | não | 3 / [35.0, -42.0] |
| `fight_player_spar_mt_push_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [35.0, -57.0] |
| `fight_player_spar_mt_push_glove_l1_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [35.0, -57.0] |
| `fight_player_spar_mt_push_glove_l2_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [35.0, -57.0] |
| `fight_player_spar_mt_push_glove_l3_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [35.0, -57.0] |
| `fight_player_spar_mt_push_glove_l4_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [35.0, -57.0] |
| `fight_player_spin_kick_disc` | 112x104 | 13 | [56, 98] | 14.0 | não | 4 / [43.0, -72.0] |
| `fight_player_spin_kick_glove_l1_disc` | 112x104 | 13 | [56, 98] | 14.0 | não | 4 / [43.0, -72.0] |
| `fight_player_spin_kick_glove_l2_disc` | 112x104 | 13 | [56, 98] | 14.0 | não | 4 / [43.0, -72.0] |
| `fight_player_spin_kick_glove_l3_disc` | 112x104 | 13 | [56, 98] | 14.0 | não | 4 / [43.0, -72.0] |
| `fight_player_spin_kick_glove_l4_disc` | 112x104 | 13 | [56, 98] | 14.0 | não | 4 / [43.0, -72.0] |
| `fight_player_thai_clinch_disc` | 112x104 | 10 | [56, 98] | 12.0 | não | 2 / [42.0, -66.0] |
| `fight_player_thai_clinch_glove_l1_disc` | 112x104 | 10 | [56, 98] | 12.0 | não | 2 / [42.0, -66.0] |
| `fight_player_thai_clinch_glove_l2_disc` | 112x104 | 10 | [56, 98] | 12.0 | não | 2 / [42.0, -66.0] |
| `fight_player_thai_clinch_glove_l3_disc` | 112x104 | 10 | [56, 98] | 12.0 | não | 2 / [42.0, -66.0] |
| `fight_player_thai_clinch_glove_l4_disc` | 112x104 | 10 | [56, 98] | 12.0 | não | 2 / [42.0, -66.0] |
| `fighter_low_kick_disc` | 64x72 | 6 | [22, 67] | 18.0 | não | 2 / [326.0, 250.0] |
| `fighter_low_kick_glove_l1_disc` | 64x72 | 6 | [22, 67] | 18.0 | não | 2 / [326.0, 250.0] |
| `fighter_low_kick_glove_l2_disc` | 64x72 | 6 | [22, 67] | 18.0 | não | 2 / [326.0, 250.0] |
| `fighter_low_kick_glove_l3_disc` | 64x72 | 6 | [22, 67] | 18.0 | não | 2 / [326.0, 250.0] |
| `fighter_low_kick_glove_l4_disc` | 64x72 | 6 | [22, 67] | 18.0 | não | 2 / [326.0, 250.0] |
| `opp_fast_fall_spin` | 112x104 | 10 | [56, 98] | 12.0 | não | chão 5.0 |
| `opp_fast_held_clinch` | 112x104 | 9 | [56, 98] | 12.0 | não | - |
| `opp_fast_hit_leg` | 112x104 | 7 | [56, 98] | 14.0 | não | - |
| `opp_fast_hit_spin` | 112x104 | 8 | [56, 98] | 12.0 | não | - |
| `opp_fast_limp` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_fast_limp_heavy` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_gym_1_fall_spin` | 112x104 | 10 | [56, 98] | 12.0 | não | chão 5.0 |
| `opp_gym_1_held_clinch` | 112x104 | 9 | [56, 98] | 12.0 | não | - |
| `opp_gym_1_hit_leg` | 112x104 | 7 | [56, 98] | 14.0 | não | - |
| `opp_gym_1_hit_spin` | 112x104 | 8 | [56, 98] | 12.0 | não | - |
| `opp_gym_1_limp` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_gym_1_limp_heavy` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_gym_2_fall_spin` | 112x104 | 10 | [56, 98] | 12.0 | não | chão 5.0 |
| `opp_gym_2_held_clinch` | 112x104 | 9 | [56, 98] | 12.0 | não | - |
| `opp_gym_2_hit_leg` | 112x104 | 7 | [56, 98] | 14.0 | não | - |
| `opp_gym_2_hit_spin` | 112x104 | 8 | [56, 98] | 12.0 | não | - |
| `opp_gym_2_limp` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_gym_2_limp_heavy` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_strong_fall_spin` | 112x104 | 10 | [56, 98] | 12.0 | não | chão 5.0 |
| `opp_strong_held_clinch` | 112x104 | 9 | [56, 98] | 12.0 | não | - |
| `opp_strong_hit_leg` | 112x104 | 7 | [56, 98] | 14.0 | não | - |
| `opp_strong_hit_spin` | 112x104 | 8 | [56, 98] | 12.0 | não | - |
| `opp_strong_limp` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_strong_limp_heavy` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_tank_fall_spin` | 112x104 | 10 | [56, 98] | 12.0 | não | chão 5.0 |
| `opp_tank_held_clinch` | 112x104 | 9 | [56, 98] | 12.0 | não | - |
| `opp_tank_hit_leg` | 112x104 | 7 | [56, 98] | 14.0 | não | - |
| `opp_tank_hit_spin` | 112x104 | 8 | [56, 98] | 12.0 | não | - |
| `opp_tank_limp` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_tank_limp_heavy` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_warmup_fall_spin` | 112x104 | 10 | [56, 98] | 12.0 | não | chão 5.0 |
| `opp_warmup_held_clinch` | 112x104 | 9 | [56, 98] | 12.0 | não | - |
| `opp_warmup_hit_leg` | 112x104 | 7 | [56, 98] | 14.0 | não | - |
| `opp_warmup_hit_spin` | 112x104 | 8 | [56, 98] | 12.0 | não | - |
| `opp_warmup_limp` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |
| `opp_warmup_limp_heavy` | 112x104 | 4 | [56, 98] | 4.0 | sim | - |

## by_data_id (ações novas)
```json
{
 "player_fight.actions (acrescentar)": {
  "mt_idle": "fight_player_mt_idle",
  "low_kick": "fight_player_low_kick",
  "knee": "fight_player_knee",
  "thai_clinch": "fight_player_thai_clinch",
  "spin_kick": "fight_player_spin_kick"
 },
 "opp_*.actions (acrescentar)": {
  "opp_fast": {
   "fall_spin": "opp_fast_fall_spin",
   "held_clinch": "opp_fast_held_clinch",
   "hit_leg": "opp_fast_hit_leg",
   "hit_spin": "opp_fast_hit_spin",
   "limp": "opp_fast_limp",
   "limp_heavy": "opp_fast_limp_heavy"
  },
  "opp_gym_1": {
   "fall_spin": "opp_gym_1_fall_spin",
   "held_clinch": "opp_gym_1_held_clinch",
   "hit_leg": "opp_gym_1_hit_leg",
   "hit_spin": "opp_gym_1_hit_spin",
   "limp": "opp_gym_1_limp",
   "limp_heavy": "opp_gym_1_limp_heavy"
  },
  "opp_gym_2": {
   "fall_spin": "opp_gym_2_fall_spin",
   "held_clinch": "opp_gym_2_held_clinch",
   "hit_leg": "opp_gym_2_hit_leg",
   "hit_spin": "opp_gym_2_hit_spin",
   "limp": "opp_gym_2_limp",
   "limp_heavy": "opp_gym_2_limp_heavy"
  },
  "opp_strong": {
   "fall_spin": "opp_strong_fall_spin",
   "held_clinch": "opp_strong_held_clinch",
   "hit_leg": "opp_strong_hit_leg",
   "hit_spin": "opp_strong_hit_spin",
   "limp": "opp_strong_limp",
   "limp_heavy": "opp_strong_limp_heavy"
  },
  "opp_tank": {
   "fall_spin": "opp_tank_fall_spin",
   "held_clinch": "opp_tank_held_clinch",
   "hit_leg": "opp_tank_hit_leg",
   "hit_spin": "opp_tank_hit_spin",
   "limp": "opp_tank_limp",
   "limp_heavy": "opp_tank_limp_heavy"
  },
  "opp_warmup": {
   "fall_spin": "opp_warmup_fall_spin",
   "held_clinch": "opp_warmup_held_clinch",
   "hit_leg": "opp_warmup_hit_leg",
   "hit_spin": "opp_warmup_hit_spin",
   "limp": "opp_warmup_limp",
   "limp_heavy": "opp_warmup_limp_heavy"
  }
 }
}
```

## minigame_layout.spar.player_actions.mt (acrescentar)
```json
{
 "idle": "fight_player_mt_idle",
 "click": "fight_player_spar_mt_push",
 "kick": "fight_player_spar_mt_kick",
 "guard": "fight_player_spar_mt_guard",
 "pushed": "fight_player_spar_box_recoil"
}
```

## Entradas completas para `sprites` (126 chaves)
```json
{
 "fight_player_mt_idle_disc": {
  "action": "mt_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_mt_idle_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -71.0
    ],
    "hand_front": [
     12.0,
     -69.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -69.0
    ],
    "hand_front": [
     12.0,
     -67.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Guarda tailandesa (idle da luta com Muay Thai): luvas na testa, cotovelos fechados, pé da frente leve; o calcanhar da frente sobe e desce no ritmo. Começo e fim de todos os golpes do Muay Thai."
 },
 "fight_player_mt_idle_disc_layered": {
  "action": "mt_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_mt_idle_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_mt_idle_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_mt_idle_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_mt_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_mt_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_mt_idle_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -73.0
    ],
    "head_box": [
     52,
     18,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -63.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     52,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_mt_idle_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_mt_idle_glove_l1_disc": {
  "action": "mt_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_mt_idle_glove_l1_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -71.0
    ],
    "hand_front": [
     12.0,
     -69.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -69.0
    ],
    "hand_front": [
     12.0,
     -67.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Guarda tailandesa (idle da luta com Muay Thai): luvas na testa, cotovelos fechados, pé da frente leve; o calcanhar da frente sobe e desce no ritmo. Começo e fim de todos os golpes do Muay Thai."
 },
 "fight_player_mt_idle_glove_l1_disc_layered": {
  "action": "mt_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_mt_idle_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_mt_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_mt_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_mt_idle_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -73.0
    ],
    "head_box": [
     52,
     18,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -63.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     52,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_mt_idle_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_mt_idle_glove_l2_disc": {
  "action": "mt_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_mt_idle_glove_l2_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -71.0
    ],
    "hand_front": [
     12.0,
     -69.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -69.0
    ],
    "hand_front": [
     12.0,
     -67.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Guarda tailandesa (idle da luta com Muay Thai): luvas na testa, cotovelos fechados, pé da frente leve; o calcanhar da frente sobe e desce no ritmo. Começo e fim de todos os golpes do Muay Thai."
 },
 "fight_player_mt_idle_glove_l2_disc_layered": {
  "action": "mt_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_mt_idle_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_mt_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_mt_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_mt_idle_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -73.0
    ],
    "head_box": [
     52,
     18,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -63.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     52,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_mt_idle_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_mt_idle_glove_l3_disc": {
  "action": "mt_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_mt_idle_glove_l3_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -71.0
    ],
    "hand_front": [
     12.0,
     -69.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -69.0
    ],
    "hand_front": [
     12.0,
     -67.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Guarda tailandesa (idle da luta com Muay Thai): luvas na testa, cotovelos fechados, pé da frente leve; o calcanhar da frente sobe e desce no ritmo. Começo e fim de todos os golpes do Muay Thai."
 },
 "fight_player_mt_idle_glove_l3_disc_layered": {
  "action": "mt_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_mt_idle_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_mt_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_mt_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_mt_idle_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -73.0
    ],
    "head_box": [
     52,
     18,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -63.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     52,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_mt_idle_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_mt_idle_glove_l4_disc": {
  "action": "mt_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_mt_idle_glove_l4_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -71.0
    ],
    "hand_front": [
     12.0,
     -69.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -69.0
    ],
    "hand_front": [
     12.0,
     -67.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Guarda tailandesa (idle da luta com Muay Thai): luvas na testa, cotovelos fechados, pé da frente leve; o calcanhar da frente sobe e desce no ritmo. Começo e fim de todos os golpes do Muay Thai."
 },
 "fight_player_mt_idle_glove_l4_disc_layered": {
  "action": "mt_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_mt_idle_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_mt_idle_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_mt_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_mt_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_mt_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_mt_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_mt_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_mt_idle_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -73.0
    ],
    "head_box": [
     52,
     18,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -63.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     52,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     18,
     13,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_mt_idle_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_low_kick_disc": {
  "action": "low_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_low_kick_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -62.0
    ],
    "hand_front": [
     19.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -52.0
    ],
    "hand_front": [
     23.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     1.83044982698962,
     -51.3217993079585
    ],
    "hand_front": [
     23.5,
     -63.5
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -49.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     4.0,
     -58.0
    ],
    "hand_front": [
     16.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute baixo (perna de trás na coxa da frente dele). hit_point = canela. Reação dele: hit_leg."
 },
 "fight_player_low_kick_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_low_kick_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_low_kick_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_low_kick_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     8.0,
     -38.0
    ],
    "top": [
     5.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.25,
     -71.75
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     9.25,
     -37.75
    ],
    "top": [
     5.44875335693359,
     -61.7756233215332
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     57,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     12.0,
     -37.0
    ],
    "top": [
     6.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -72.0
    ],
    "head_box": [
     56,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     6.0,
     -38.0
    ],
    "top": [
     4.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_low_kick_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_low_kick_glove_l1_disc": {
  "action": "low_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_low_kick_glove_l1_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -62.0
    ],
    "hand_front": [
     19.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -52.0
    ],
    "hand_front": [
     23.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     1.83044982698962,
     -51.3217993079585
    ],
    "hand_front": [
     23.5,
     -63.5
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -49.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     4.0,
     -58.0
    ],
    "hand_front": [
     16.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute baixo (perna de trás na coxa da frente dele). hit_point = canela. Reação dele: hit_leg."
 },
 "fight_player_low_kick_glove_l1_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_low_kick_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_low_kick_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_low_kick_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     8.0,
     -38.0
    ],
    "top": [
     5.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.25,
     -71.75
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     9.25,
     -37.75
    ],
    "top": [
     5.44875335693359,
     -61.7756233215332
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     57,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     12.0,
     -37.0
    ],
    "top": [
     6.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -72.0
    ],
    "head_box": [
     56,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     6.0,
     -38.0
    ],
    "top": [
     4.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_low_kick_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_low_kick_glove_l2_disc": {
  "action": "low_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_low_kick_glove_l2_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -62.0
    ],
    "hand_front": [
     19.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -52.0
    ],
    "hand_front": [
     23.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     1.83044982698962,
     -51.3217993079585
    ],
    "hand_front": [
     23.5,
     -63.5
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -49.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     4.0,
     -58.0
    ],
    "hand_front": [
     16.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute baixo (perna de trás na coxa da frente dele). hit_point = canela. Reação dele: hit_leg."
 },
 "fight_player_low_kick_glove_l2_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_low_kick_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_low_kick_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_low_kick_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     8.0,
     -38.0
    ],
    "top": [
     5.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.25,
     -71.75
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     9.25,
     -37.75
    ],
    "top": [
     5.44875335693359,
     -61.7756233215332
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     57,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     12.0,
     -37.0
    ],
    "top": [
     6.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -72.0
    ],
    "head_box": [
     56,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     6.0,
     -38.0
    ],
    "top": [
     4.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_low_kick_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_low_kick_glove_l3_disc": {
  "action": "low_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_low_kick_glove_l3_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -62.0
    ],
    "hand_front": [
     19.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -52.0
    ],
    "hand_front": [
     23.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     1.83044982698962,
     -51.3217993079585
    ],
    "hand_front": [
     23.5,
     -63.5
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -49.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     4.0,
     -58.0
    ],
    "hand_front": [
     16.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute baixo (perna de trás na coxa da frente dele). hit_point = canela. Reação dele: hit_leg."
 },
 "fight_player_low_kick_glove_l3_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_low_kick_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_low_kick_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_low_kick_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     8.0,
     -38.0
    ],
    "top": [
     5.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.25,
     -71.75
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     9.25,
     -37.75
    ],
    "top": [
     5.44875335693359,
     -61.7756233215332
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     57,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     12.0,
     -37.0
    ],
    "top": [
     6.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -72.0
    ],
    "head_box": [
     56,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     6.0,
     -38.0
    ],
    "top": [
     4.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_low_kick_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_low_kick_glove_l4_disc": {
  "action": "low_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_low_kick_glove_l4_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -62.0
    ],
    "hand_front": [
     19.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -52.0
    ],
    "hand_front": [
     23.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     1.83044982698962,
     -51.3217993079585
    ],
    "hand_front": [
     23.5,
     -63.5
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -48.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -49.0
    ],
    "hand_front": [
     25.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     4.0,
     -58.0
    ],
    "hand_front": [
     16.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute baixo (perna de trás na coxa da frente dele). hit_point = canela. Reação dele: hit_leg."
 },
 "fight_player_low_kick_glove_l4_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   37.0,
   -24.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_low_kick_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_low_kick_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_low_kick_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     8.0,
     -38.0
    ],
    "top": [
     5.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.25,
     -71.75
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     9.25,
     -37.75
    ],
    "top": [
     5.44875335693359,
     -61.7756233215332
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.0,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     13.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     57,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     12.0,
     -37.0
    ],
    "top": [
     6.0,
     -61.0
    ],
    "tw": -0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -72.0
    ],
    "head_box": [
     56,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     6.0,
     -38.0
    ],
    "top": [
     4.0,
     -62.0
    ],
    "tw": -0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     19,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_low_kick_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_knee_disc": {
  "action": "knee",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_knee_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     19.0,
     -67.0
    ],
    "hand_front": [
     22.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     29.0,
     -64.0
    ],
    "hand_front": [
     32.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -60.0
    ],
    "hand_front": [
     41.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     27.0,
     -65.0
    ],
    "hand_front": [
     30.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     12.0,
     -70.0
    ],
    "hand_front": [
     15.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Joelhada (joelho de trás na barriga, com passo para dentro; o corpo desliza até 13 px e volta). Reação: hit_body."
 },
 "fight_player_knee_disc_layered": {
  "action": "knee",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_knee_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_knee_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_knee_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_knee_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_knee_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_knee_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_knee_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_knee_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_knee_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_knee_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_knee_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_knee_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_knee_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_knee_glove_l1_disc": {
  "action": "knee",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_knee_glove_l1_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     19.0,
     -67.0
    ],
    "hand_front": [
     22.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     29.0,
     -64.0
    ],
    "hand_front": [
     32.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -60.0
    ],
    "hand_front": [
     41.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     27.0,
     -65.0
    ],
    "hand_front": [
     30.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     12.0,
     -70.0
    ],
    "hand_front": [
     15.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Joelhada (joelho de trás na barriga, com passo para dentro; o corpo desliza até 13 px e volta). Reação: hit_body."
 },
 "fight_player_knee_glove_l1_disc_layered": {
  "action": "knee",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_knee_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_knee_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_knee_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_knee_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_knee_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_knee_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_knee_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_knee_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_knee_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_knee_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_knee_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_knee_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_knee_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_knee_glove_l2_disc": {
  "action": "knee",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_knee_glove_l2_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     19.0,
     -67.0
    ],
    "hand_front": [
     22.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     29.0,
     -64.0
    ],
    "hand_front": [
     32.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -60.0
    ],
    "hand_front": [
     41.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     27.0,
     -65.0
    ],
    "hand_front": [
     30.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     12.0,
     -70.0
    ],
    "hand_front": [
     15.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Joelhada (joelho de trás na barriga, com passo para dentro; o corpo desliza até 13 px e volta). Reação: hit_body."
 },
 "fight_player_knee_glove_l2_disc_layered": {
  "action": "knee",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_knee_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_knee_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_knee_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_knee_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_knee_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_knee_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_knee_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_knee_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_knee_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_knee_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_knee_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_knee_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_knee_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_knee_glove_l3_disc": {
  "action": "knee",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_knee_glove_l3_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     19.0,
     -67.0
    ],
    "hand_front": [
     22.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     29.0,
     -64.0
    ],
    "hand_front": [
     32.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -60.0
    ],
    "hand_front": [
     41.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     27.0,
     -65.0
    ],
    "hand_front": [
     30.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     12.0,
     -70.0
    ],
    "hand_front": [
     15.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Joelhada (joelho de trás na barriga, com passo para dentro; o corpo desliza até 13 px e volta). Reação: hit_body."
 },
 "fight_player_knee_glove_l3_disc_layered": {
  "action": "knee",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_knee_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_knee_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_knee_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_knee_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_knee_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_knee_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_knee_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_knee_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_knee_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_knee_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_knee_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_knee_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_knee_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_knee_glove_l4_disc": {
  "action": "knee",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_knee_glove_l4_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     19.0,
     -67.0
    ],
    "hand_front": [
     22.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     29.0,
     -64.0
    ],
    "hand_front": [
     32.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -61.0
    ],
    "hand_front": [
     41.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     38.0,
     -60.0
    ],
    "hand_front": [
     41.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     27.0,
     -65.0
    ],
    "hand_front": [
     30.0,
     -64.0
    ]
   },
   {
    "hand_back": [
     12.0,
     -70.0
    ],
    "hand_front": [
     15.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Joelhada (joelho de trás na barriga, com passo para dentro; o corpo desliza até 13 px e volta). Reação: hit_body."
 },
 "fight_player_knee_glove_l4_disc_layered": {
  "action": "knee",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   36.0,
   -45.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_knee_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_knee_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_knee_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_knee_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_knee_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_knee_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_knee_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_knee_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_knee_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_knee_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_knee_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_knee_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_knee_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     68,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -39.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -38.0
    ],
    "top": [
     3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -71.0
    ],
    "head_box": [
     55,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_knee_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_thai_clinch_disc": {
  "action": "thai_clinch",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_thai_clinch_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -69.0
    ],
    "hand_front": [
     34.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     40.0,
     -68.0
    ],
    "hand_front": [
     42.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -57.0
    ],
    "hand_front": [
     35.0,
     -55.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -58.0
    ],
    "hand_front": [
     35.0,
     -56.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     23.0,
     -64.0
    ],
    "hand_front": [
     26.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Clinch tailandês (dois corpos): pega a nuca no hit_frame 2 (a reação held_clinch começa aqui e termina junto), puxa para baixo e dá a joelhada no quadro 5 (bom quadro para o número/impacto extra). Reação: held_clinch."
 },
 "fight_player_thai_clinch_disc_layered": {
  "action": "thai_clinch",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_thai_clinch_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     10.0,
     -71.0
    ],
    "head_box": [
     63,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": 0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     71,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     59,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_thai_clinch_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_thai_clinch_glove_l1_disc": {
  "action": "thai_clinch",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_thai_clinch_glove_l1_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -69.0
    ],
    "hand_front": [
     34.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     40.0,
     -68.0
    ],
    "hand_front": [
     42.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -57.0
    ],
    "hand_front": [
     35.0,
     -55.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -58.0
    ],
    "hand_front": [
     35.0,
     -56.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     23.0,
     -64.0
    ],
    "hand_front": [
     26.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Clinch tailandês (dois corpos): pega a nuca no hit_frame 2 (a reação held_clinch começa aqui e termina junto), puxa para baixo e dá a joelhada no quadro 5 (bom quadro para o número/impacto extra). Reação: held_clinch."
 },
 "fight_player_thai_clinch_glove_l1_disc_layered": {
  "action": "thai_clinch",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_thai_clinch_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     10.0,
     -71.0
    ],
    "head_box": [
     63,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": 0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     71,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     59,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_thai_clinch_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_thai_clinch_glove_l2_disc": {
  "action": "thai_clinch",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_thai_clinch_glove_l2_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -69.0
    ],
    "hand_front": [
     34.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     40.0,
     -68.0
    ],
    "hand_front": [
     42.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -57.0
    ],
    "hand_front": [
     35.0,
     -55.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -58.0
    ],
    "hand_front": [
     35.0,
     -56.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     23.0,
     -64.0
    ],
    "hand_front": [
     26.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Clinch tailandês (dois corpos): pega a nuca no hit_frame 2 (a reação held_clinch começa aqui e termina junto), puxa para baixo e dá a joelhada no quadro 5 (bom quadro para o número/impacto extra). Reação: held_clinch."
 },
 "fight_player_thai_clinch_glove_l2_disc_layered": {
  "action": "thai_clinch",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_thai_clinch_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     10.0,
     -71.0
    ],
    "head_box": [
     63,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": 0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     71,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     59,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_thai_clinch_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_thai_clinch_glove_l3_disc": {
  "action": "thai_clinch",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_thai_clinch_glove_l3_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -69.0
    ],
    "hand_front": [
     34.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     40.0,
     -68.0
    ],
    "hand_front": [
     42.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -57.0
    ],
    "hand_front": [
     35.0,
     -55.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -58.0
    ],
    "hand_front": [
     35.0,
     -56.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     23.0,
     -64.0
    ],
    "hand_front": [
     26.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Clinch tailandês (dois corpos): pega a nuca no hit_frame 2 (a reação held_clinch começa aqui e termina junto), puxa para baixo e dá a joelhada no quadro 5 (bom quadro para o número/impacto extra). Reação: held_clinch."
 },
 "fight_player_thai_clinch_glove_l3_disc_layered": {
  "action": "thai_clinch",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_thai_clinch_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     10.0,
     -71.0
    ],
    "head_box": [
     63,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": 0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     71,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     59,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_thai_clinch_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_thai_clinch_glove_l4_disc": {
  "action": "thai_clinch",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_thai_clinch_glove_l4_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -69.0
    ],
    "hand_front": [
     34.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     40.0,
     -68.0
    ],
    "hand_front": [
     42.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -57.0
    ],
    "hand_front": [
     35.0,
     -55.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -58.0
    ],
    "hand_front": [
     35.0,
     -56.0
    ]
   },
   {
    "hand_back": [
     34.0,
     -60.0
    ],
    "hand_front": [
     36.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     23.0,
     -64.0
    ],
    "hand_front": [
     26.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Clinch tailandês (dois corpos): pega a nuca no hit_frame 2 (a reação held_clinch começa aqui e termina junto), puxa para baixo e dá a joelhada no quadro 5 (bom quadro para o número/impacto extra). Reação: held_clinch."
 },
 "fight_player_thai_clinch_glove_l4_disc_layered": {
  "action": "thai_clinch",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   42.0,
   -66.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_thai_clinch_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_thai_clinch_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_thai_clinch_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     10.0,
     -71.0
    ],
    "head_box": [
     63,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -37.0
    ],
    "top": [
     7.0,
     -61.0
    ],
    "tw": 0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     71,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -72.0
    ],
    "head_box": [
     70,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -39.0
    ],
    "top": [
     8.0,
     -62.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -71.0
    ],
    "head_box": [
     69,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -38.0
    ],
    "top": [
     8.0,
     -61.0
    ],
    "tw": 1.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -71.0
    ],
    "head_box": [
     59,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     3.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     32,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_thai_clinch_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spin_kick_disc": {
  "action": "spin_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spin_kick_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     17.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -50.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -44.0
    ],
    "hand_front": [
     23.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -46.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     14.0,
     -60.0
    ],
    "hand_front": [
     22.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     20.0,
     -68.0
    ],
    "hand_front": [
     23.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     17.0829903978052,
     -68.8340192043896
    ],
    "hand_front": [
     20.0,
     -67.5
    ]
   },
   {
    "hand_back": [
     14.0,
     -70.0
    ],
    "hand_front": [
     17.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute rodado (perna de trás no rosto) com passo de 12 px para a frente dentro do quadro (o pivô não muda; o passo volta no fim). Contato segura 3 quadros. Reação: fall_spin (derrubou) ou hit_spin (aguentou)."
 },
 "fight_player_spin_kick_disc_layered": {
  "action": "spin_kick",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spin_kick_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spin_kick_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spin_kick_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spin_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spin_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spin_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     56,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -39.0
    ],
    "top": [
     1.0,
     -62.0
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     64,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -4.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -1.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     68,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -38.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": -1.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     67,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     5.0,
     -61.0
    ],
    "tw": -0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.5,
     -71.5
    ],
    "head_box": [
     62,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     2.5,
     -61.5
    ],
    "tw": 0.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spin_kick_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spin_kick_glove_l1_disc": {
  "action": "spin_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spin_kick_glove_l1_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     17.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -50.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -44.0
    ],
    "hand_front": [
     23.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -46.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     14.0,
     -60.0
    ],
    "hand_front": [
     22.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     20.0,
     -68.0
    ],
    "hand_front": [
     23.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     17.0829903978052,
     -68.8340192043896
    ],
    "hand_front": [
     20.0,
     -67.5
    ]
   },
   {
    "hand_back": [
     14.0,
     -70.0
    ],
    "hand_front": [
     17.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute rodado (perna de trás no rosto) com passo de 12 px para a frente dentro do quadro (o pivô não muda; o passo volta no fim). Contato segura 3 quadros. Reação: fall_spin (derrubou) ou hit_spin (aguentou)."
 },
 "fight_player_spin_kick_glove_l1_disc_layered": {
  "action": "spin_kick",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spin_kick_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spin_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spin_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spin_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     56,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -39.0
    ],
    "top": [
     1.0,
     -62.0
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     64,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -4.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -1.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     68,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -38.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": -1.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     67,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     5.0,
     -61.0
    ],
    "tw": -0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.5,
     -71.5
    ],
    "head_box": [
     62,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     2.5,
     -61.5
    ],
    "tw": 0.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spin_kick_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spin_kick_glove_l2_disc": {
  "action": "spin_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spin_kick_glove_l2_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     17.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -50.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -44.0
    ],
    "hand_front": [
     23.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -46.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     14.0,
     -60.0
    ],
    "hand_front": [
     22.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     20.0,
     -68.0
    ],
    "hand_front": [
     23.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     17.0829903978052,
     -68.8340192043896
    ],
    "hand_front": [
     20.0,
     -67.5
    ]
   },
   {
    "hand_back": [
     14.0,
     -70.0
    ],
    "hand_front": [
     17.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute rodado (perna de trás no rosto) com passo de 12 px para a frente dentro do quadro (o pivô não muda; o passo volta no fim). Contato segura 3 quadros. Reação: fall_spin (derrubou) ou hit_spin (aguentou)."
 },
 "fight_player_spin_kick_glove_l2_disc_layered": {
  "action": "spin_kick",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spin_kick_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spin_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spin_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spin_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     56,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -39.0
    ],
    "top": [
     1.0,
     -62.0
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     64,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -4.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -1.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     68,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -38.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": -1.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     67,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     5.0,
     -61.0
    ],
    "tw": -0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.5,
     -71.5
    ],
    "head_box": [
     62,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     2.5,
     -61.5
    ],
    "tw": 0.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spin_kick_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spin_kick_glove_l3_disc": {
  "action": "spin_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spin_kick_glove_l3_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     17.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -50.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -44.0
    ],
    "hand_front": [
     23.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -46.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     14.0,
     -60.0
    ],
    "hand_front": [
     22.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     20.0,
     -68.0
    ],
    "hand_front": [
     23.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     17.0829903978052,
     -68.8340192043896
    ],
    "hand_front": [
     20.0,
     -67.5
    ]
   },
   {
    "hand_back": [
     14.0,
     -70.0
    ],
    "hand_front": [
     17.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute rodado (perna de trás no rosto) com passo de 12 px para a frente dentro do quadro (o pivô não muda; o passo volta no fim). Contato segura 3 quadros. Reação: fall_spin (derrubou) ou hit_spin (aguentou)."
 },
 "fight_player_spin_kick_glove_l3_disc_layered": {
  "action": "spin_kick",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spin_kick_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spin_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spin_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spin_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     56,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -39.0
    ],
    "top": [
     1.0,
     -62.0
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     64,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -4.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -1.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     68,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -38.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": -1.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     67,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     5.0,
     -61.0
    ],
    "tw": -0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.5,
     -71.5
    ],
    "head_box": [
     62,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     2.5,
     -61.5
    ],
    "tw": 0.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spin_kick_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spin_kick_glove_l4_disc": {
  "action": "spin_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spin_kick_glove_l4_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     17.0,
     -66.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -50.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -44.0
    ],
    "hand_front": [
     23.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -42.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     3.0,
     -46.0
    ],
    "hand_front": [
     20.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     14.0,
     -60.0
    ],
    "hand_front": [
     22.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     20.0,
     -68.0
    ],
    "hand_front": [
     23.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     17.0829903978052,
     -68.8340192043896
    ],
    "hand_front": [
     20.0,
     -67.5
    ]
   },
   {
    "hand_back": [
     14.0,
     -70.0
    ],
    "hand_front": [
     17.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Chute rodado (perna de trás no rosto) com passo de 12 px para a frente dentro do quadro (o pivô não muda; o passo volta no fim). Contato segura 3 quadros. Reação: fall_spin (derrubou) ou hit_spin (aguentou)."
 },
 "fight_player_spin_kick_glove_l4_disc_layered": {
  "action": "spin_kick",
  "facing": "direita",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 13,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 4,
  "hit_point": [
   43.0,
   -72.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spin_kick_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spin_kick_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spin_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spin_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spin_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spin_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spin_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spin_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     56,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.0,
     -72.0
    ],
    "head_box": [
     61,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -39.0
    ],
    "top": [
     1.0,
     -62.0
    ],
    "tw": -0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -0.9,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -72.0
    ],
    "head_box": [
     63,
     19,
     12,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -8.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": -1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     64,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": -4.0,
    "hip": [
     8.0,
     -40.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": -1.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     7.0,
     -71.0
    ],
    "head_box": [
     68,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -38.0
    ],
    "top": [
     4.0,
     -61.0
    ],
    "tw": -1.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -71.0
    ],
    "head_box": [
     67,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     5.0,
     -61.0
    ],
    "tw": -0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.5,
     -71.5
    ],
    "head_box": [
     62,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     2.5,
     -61.5
    ],
    "tw": 0.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     57,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     52,
     19,
     29,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spin_kick_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_push_disc": {
  "action": "spar_mt_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_push_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     13.0,
     -63.0
    ],
    "hand_front": [
     16.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -59.0
    ],
    "hand_front": [
     35.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -59.0
    ],
    "hand_front": [
     36.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     21.0,
     -64.5
    ],
    "hand_front": [
     24.0,
     -62.5
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, clique fora do tempo: empurrão curto com as duas mãos. Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_push_disc_layered": {
  "action": "spar_mt_push",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_push_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.5,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.95,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_push_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_push_glove_l1_disc": {
  "action": "spar_mt_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_push_glove_l1_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     13.0,
     -63.0
    ],
    "hand_front": [
     16.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -59.0
    ],
    "hand_front": [
     35.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -59.0
    ],
    "hand_front": [
     36.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     21.0,
     -64.5
    ],
    "hand_front": [
     24.0,
     -62.5
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, clique fora do tempo: empurrão curto com as duas mãos. Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_push_glove_l1_disc_layered": {
  "action": "spar_mt_push",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_push_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.5,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.95,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_push_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_push_glove_l2_disc": {
  "action": "spar_mt_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_push_glove_l2_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     13.0,
     -63.0
    ],
    "hand_front": [
     16.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -59.0
    ],
    "hand_front": [
     35.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -59.0
    ],
    "hand_front": [
     36.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     21.0,
     -64.5
    ],
    "hand_front": [
     24.0,
     -62.5
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, clique fora do tempo: empurrão curto com as duas mãos. Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_push_glove_l2_disc_layered": {
  "action": "spar_mt_push",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_push_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.5,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.95,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_push_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_push_glove_l3_disc": {
  "action": "spar_mt_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_push_glove_l3_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     13.0,
     -63.0
    ],
    "hand_front": [
     16.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -59.0
    ],
    "hand_front": [
     35.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -59.0
    ],
    "hand_front": [
     36.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     21.0,
     -64.5
    ],
    "hand_front": [
     24.0,
     -62.5
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, clique fora do tempo: empurrão curto com as duas mãos. Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_push_glove_l3_disc_layered": {
  "action": "spar_mt_push",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_push_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.5,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.95,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_push_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_push_glove_l4_disc": {
  "action": "spar_mt_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_push_glove_l4_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     13.0,
     -63.0
    ],
    "hand_front": [
     16.0,
     -62.0
    ]
   },
   {
    "hand_back": [
     32.0,
     -59.0
    ],
    "hand_front": [
     35.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     33.0,
     -59.0
    ],
    "hand_front": [
     36.0,
     -57.0
    ]
   },
   {
    "hand_back": [
     21.0,
     -64.5
    ],
    "hand_front": [
     24.0,
     -62.5
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, clique fora do tempo: empurrão curto com as duas mãos. Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_push_glove_l4_disc_layered": {
  "action": "spar_mt_push",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 2,
  "hit_point": [
   35.0,
   -57.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_push_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_push_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_push_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     14.0,
     -70.0
    ],
    "head_box": [
     63,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -37.0
    ],
    "top": [
     11.0,
     -60.0
    ],
    "tw": 1.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.5,
     -71.0
    ],
    "head_box": [
     58,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.5
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.95,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     51,
     19,
     25,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_push_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_kick_disc": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_kick_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     8.25,
     -69.5
    ],
    "hand_front": [
     11.5,
     -67.75
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, 3º clique no tempo = CHUTE: teep (sola do pé da frente na barriga). Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_kick_disc_layered": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_kick_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -0.75,
     -38.25
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -72.0
    ],
    "head_box": [
     50,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     -2.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_kick_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_kick_glove_l1_disc": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_kick_glove_l1_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     8.25,
     -69.5
    ],
    "hand_front": [
     11.5,
     -67.75
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, 3º clique no tempo = CHUTE: teep (sola do pé da frente na barriga). Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_kick_glove_l1_disc_layered": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_kick_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -0.75,
     -38.25
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -72.0
    ],
    "head_box": [
     50,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     -2.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_kick_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_kick_glove_l2_disc": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_kick_glove_l2_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     8.25,
     -69.5
    ],
    "hand_front": [
     11.5,
     -67.75
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, 3º clique no tempo = CHUTE: teep (sola do pé da frente na barriga). Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_kick_glove_l2_disc_layered": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_kick_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -0.75,
     -38.25
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -72.0
    ],
    "head_box": [
     50,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     -2.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_kick_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_kick_glove_l3_disc": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_kick_glove_l3_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     8.25,
     -69.5
    ],
    "hand_front": [
     11.5,
     -67.75
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, 3º clique no tempo = CHUTE: teep (sola do pé da frente na barriga). Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_kick_glove_l3_disc_layered": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_kick_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -0.75,
     -38.25
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -72.0
    ],
    "head_box": [
     50,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     -2.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_kick_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_kick_glove_l4_disc": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_kick_glove_l4_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     8.25,
     -69.5
    ],
    "hand_front": [
     11.5,
     -67.75
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     6.0,
     -68.0
    ],
    "hand_front": [
     10.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   },
   {
    "hand_back": [
     9.0,
     -70.0
    ],
    "hand_front": [
     12.0,
     -68.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, 3º clique no tempo = CHUTE: teep (sola do pé da frente na barriga). Reação do parceiro: spar_partner_box_recoil."
 },
 "fight_player_spar_mt_kick_glove_l4_disc_layered": {
  "action": "spar_mt_kick",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -42.0
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_kick_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_kick_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   3.0,
   -83.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -0.75,
     -38.25
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -72.0
    ],
    "head_box": [
     49,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -39.0
    ],
    "top": [
     -3.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -72.0
    ],
    "head_box": [
     50,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     -2.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -72.0
    ],
    "head_box": [
     52,
     19,
     13,
     14
    ],
    "head_box_max": [
     49,
     19,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -38.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_kick_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_guard_disc": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_guard_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     8.0,
     -69.0
    ],
    "hand_front": [
     11.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     8.0,
     -68.0
    ],
    "hand_front": [
     11.0,
     -66.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, segurando: guarda fechada com a canela levantada (loop)."
 },
 "fight_player_spar_mt_guard_disc_layered": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_guard_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   2.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -70.0
    ],
    "head_box": [
     51,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_guard_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_guard_glove_l1_disc": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_guard_glove_l1_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     8.0,
     -69.0
    ],
    "hand_front": [
     11.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     8.0,
     -68.0
    ],
    "hand_front": [
     11.0,
     -66.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, segurando: guarda fechada com a canela levantada (loop)."
 },
 "fight_player_spar_mt_guard_glove_l1_disc_layered": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_guard_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   2.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -70.0
    ],
    "head_box": [
     51,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_guard_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_guard_glove_l2_disc": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_guard_glove_l2_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     8.0,
     -69.0
    ],
    "hand_front": [
     11.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     8.0,
     -68.0
    ],
    "hand_front": [
     11.0,
     -66.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, segurando: guarda fechada com a canela levantada (loop)."
 },
 "fight_player_spar_mt_guard_glove_l2_disc_layered": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_guard_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   2.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -70.0
    ],
    "head_box": [
     51,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_guard_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_guard_glove_l3_disc": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_guard_glove_l3_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     8.0,
     -69.0
    ],
    "hand_front": [
     11.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     8.0,
     -68.0
    ],
    "hand_front": [
     11.0,
     -66.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, segurando: guarda fechada com a canela levantada (loop)."
 },
 "fight_player_spar_mt_guard_glove_l3_disc_layered": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_guard_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   2.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -70.0
    ],
    "head_box": [
     51,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_guard_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fight_player_spar_mt_guard_glove_l4_disc": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_mt_guard_glove_l4_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     8.0,
     -69.0
    ],
    "hand_front": [
     11.0,
     -67.0
    ]
   },
   {
    "hand_back": [
     8.0,
     -68.0
    ],
    "hand_front": [
     11.0,
     -66.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7b1: Choque Muay Thai, segurando: guarda fechada com a canela levantada (loop)."
 },
 "fight_player_spar_mt_guard_glove_l4_disc_layered": {
  "action": "spar_mt_guard",
  "facing": "direita",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_mt_guard_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_mt_guard_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_mt_guard_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   2.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     2.0,
     -71.0
    ],
    "head_box": [
     51,
     20,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -38.0
    ],
    "top": [
     -1.0,
     -62.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     2.0,
     -70.0
    ],
    "head_box": [
     51,
     21,
     13,
     14
    ],
    "head_box_max": [
     51,
     20,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -37.0
    ],
    "top": [
     -1.0,
     -61.0
    ],
    "tw": 0.6,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_mt_guard_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fighter_low_kick_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_low_kick_disc.png",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "action": "low_kick",
  "who": "discipulo",
  "note": "Fase 7b1: chute baixo no SACO COMPRIDO (kick_bag), tocado inteiro a cada clique, no lugar do fighter_punch. Quadro 64x72 (o pé passa dos 48 px), pivô (22,67) igual ao do fighter_punch em foco_saco (303,272); hit_point = canela no gasto da lona (326,250): disparar kick_bag_lN_hit, impacto e número no hit_frame."
 },
 "fighter_low_kick_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "file": "res://assets/sprites/disciple/fighter_low_kick_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_low_kick_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_low_kick_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   1.0,
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fighter_low_kick_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fighter_low_kick_glove_l1_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_low_kick_glove_l1_disc.png",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "action": "low_kick",
  "who": "discipulo",
  "note": "Fase 7b1: chute baixo no SACO COMPRIDO (kick_bag), tocado inteiro a cada clique, no lugar do fighter_punch. Quadro 64x72 (o pé passa dos 48 px), pivô (22,67) igual ao do fighter_punch em foco_saco (303,272); hit_point = canela no gasto da lona (326,250): disparar kick_bag_lN_hit, impacto e número no hit_frame."
 },
 "fighter_low_kick_glove_l1_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "file": "res://assets/sprites/disciple/fighter_low_kick_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_low_kick_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_low_kick_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   1.0,
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fighter_low_kick_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fighter_low_kick_glove_l2_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_low_kick_glove_l2_disc.png",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "action": "low_kick",
  "who": "discipulo",
  "note": "Fase 7b1: chute baixo no SACO COMPRIDO (kick_bag), tocado inteiro a cada clique, no lugar do fighter_punch. Quadro 64x72 (o pé passa dos 48 px), pivô (22,67) igual ao do fighter_punch em foco_saco (303,272); hit_point = canela no gasto da lona (326,250): disparar kick_bag_lN_hit, impacto e número no hit_frame."
 },
 "fighter_low_kick_glove_l2_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "file": "res://assets/sprites/disciple/fighter_low_kick_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_low_kick_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_low_kick_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   1.0,
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fighter_low_kick_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fighter_low_kick_glove_l3_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_low_kick_glove_l3_disc.png",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "action": "low_kick",
  "who": "discipulo",
  "note": "Fase 7b1: chute baixo no SACO COMPRIDO (kick_bag), tocado inteiro a cada clique, no lugar do fighter_punch. Quadro 64x72 (o pé passa dos 48 px), pivô (22,67) igual ao do fighter_punch em foco_saco (303,272); hit_point = canela no gasto da lona (326,250): disparar kick_bag_lN_hit, impacto e número no hit_frame."
 },
 "fighter_low_kick_glove_l3_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "file": "res://assets/sprites/disciple/fighter_low_kick_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_low_kick_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_low_kick_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   1.0,
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fighter_low_kick_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "fighter_low_kick_glove_l4_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_low_kick_glove_l4_disc.png",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "action": "low_kick",
  "who": "discipulo",
  "note": "Fase 7b1: chute baixo no SACO COMPRIDO (kick_bag), tocado inteiro a cada clique, no lugar do fighter_punch. Quadro 64x72 (o pé passa dos 48 px), pivô (22,67) igual ao do fighter_punch em foco_saco (303,272); hit_point = canela no gasto da lona (326,250): disparar kick_bag_lN_hit, impacto e número no hit_frame."
 },
 "fighter_low_kick_glove_l4_disc_layered": {
  "action": "low_kick",
  "facing": "direita",
  "fps": 18.0,
  "frame_size": [
   64,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22,
   67
  ],
  "hit_frame": 2,
  "hit_point": [
   326.0,
   250.0
  ],
  "positions": {
   "foco_saco": [
    303,
    272
   ]
  },
  "file": "res://assets/sprites/disciple/fighter_low_kick_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_low_kick_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_low_kick_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_low_kick_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_low_kick_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_low_kick_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_low_kick_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_low_kick_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_low_kick_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_low_kick_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_low_kick_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_low_kick_disc_front.png",
   "order": [
    "body",
    "top",
    "socks",
    "school_symbol",
    "head",
    "band",
    "front_mask"
   ]
  },
  "head_anchor": [
   1.0,
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     0.0,
     -58.0
    ],
    "head_box": [
     20,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     4.0,
     -32.0
    ],
    "top": [
     0.0,
     -51.0
    ],
    "tw": -0.6,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -58.0
    ],
    "head_box": [
     19,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -32.0
    ],
    "top": [
     1.0,
     -51.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -57.0
    ],
    "head_box": [
     17,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     16,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     1.0,
     -50.0
    ],
    "tw": 0.0,
    "view": "34",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7b1): mesmos quadros, fps, pivô, mãos e hit de fighter_low_kick_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette)."
 },
 "opp_fast_fall_spin": {
  "action": "fall_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_fast/opp_fast_fall_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "ground_frame": 5.0,
  "hands": [
   {
    "hand_back": [
     5.51999998092651,
     -57.0400009155273
    ],
    "hand_front": [
     -3.6800000667572,
     -59.7999992370605
    ]
   },
   {
    "hand_back": [
     12.8800001144409,
     -51.5200004577637
    ],
    "hand_front": [
     1.8400000333786,
     -57.0400009155273
    ]
   },
   {
    "hand_back": [
     11.039999961853,
     -40.4799995422363
    ],
    "hand_front": [
     0.0,
     -44.1599998474121
    ]
   },
   {
    "hand_back": [
     16.5599994659424,
     -27.6000003814697
    ],
    "hand_front": [
     5.51999998092651,
     -30.3600006103516
    ]
   },
   {
    "hand_back": [
     29.4400005340576,
     -11.039999961853
    ],
    "hand_front": [
     12.8800001144409,
     -14.7200002670288
    ]
   },
   {
    "hand_back": [
     40.4799995422363,
     -5.51999998092651
    ],
    "hand_front": [
     14.7200002670288,
     -9.65999984741211
    ]
   },
   {
    "hand_back": [
     40.4799995422363,
     -7.3600001335144
    ],
    "hand_front": [
     14.7200002670288,
     -11.960000038147
    ]
   },
   {
    "hand_back": [
     40.4799995422363,
     -5.51999998092651
    ],
    "hand_front": [
     14.7200002670288,
     -9.65999984741211
    ]
   },
   {
    "hand_back": [
     40.4799995422363,
     -5.51999998092651
    ],
    "hand_front": [
     14.7200002670288,
     -9.65999984741211
    ]
   },
   {
    "hand_back": [
     40.4799995422363,
     -5.51999998092651
    ],
    "hand_front": [
     14.7200002670288,
     -9.65999984741211
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: queda pelo chute rodado (K.O.): a cabeça vira, os joelhos cedem, depois o tronco, cai de costas e fica (segurar o último quadro, como o ko). ground_frame = quadro em que bate no chão.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_fast_held_clinch": {
  "action": "held_clinch",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_fast/opp_fast_held_clinch.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 9,
  "hands": [
   {
    "hand_back": [
     -9.19999980926514,
     -53.3600006103516
    ],
    "hand_front": [
     -12.8800001144409,
     -51.5200004577637
    ]
   },
   {
    "hand_back": [
     -11.960000038147,
     -47.8400001525879
    ],
    "hand_front": [
     -13.8000001907349,
     -46.0
    ]
   },
   {
    "hand_back": [
     -11.960000038147,
     -45.0800018310547
    ],
    "hand_front": [
     -13.8000001907349,
     -43.2400016784668
    ]
   },
   {
    "hand_back": [
     -7.3600001335144,
     -43.2400016784668
    ],
    "hand_front": [
     -10.1199998855591,
     -41.4000015258789
    ]
   },
   {
    "hand_back": [
     -7.3600001335144,
     -43.2400016784668
    ],
    "hand_front": [
     -10.1199998855591,
     -41.4000015258789
    ]
   },
   {
    "hand_back": [
     -11.960000038147,
     -45.0800018310547
    ],
    "hand_front": [
     -13.8000001907349,
     -43.2400016784668
    ]
   },
   {
    "hand_back": [
     -3.6800000667572,
     -50.6000022888184
    ],
    "hand_front": [
     -10.1199998855591,
     -47.8400001525879
    ]
   },
   {
    "hand_back": [
     -4.06364917755127,
     -52.8635292053223
    ],
    "hand_front": [
     -11.2709465026855,
     -50.1418914794922
    ]
   },
   {
    "hand_back": [
     -4.59999990463257,
     -56.028003692627
    ],
    "hand_front": [
     -12.8800001144409,
     -53.3600006103516
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: preso no clinch tailandês (começa no hit_frame 2 do thai_clinch e termina junto): puxado pela nuca, a joelhada acerta no quadro 3, é solto e volta à guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_fast_hit_leg": {
  "action": "hit_leg",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_fast/opp_fast_hit_leg.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     -4.59999990463257,
     -56.028003692627
    ],
    "hand_front": [
     -12.8800001144409,
     -53.3600006103516
    ]
   },
   {
    "hand_back": [
     -2.75999999046326,
     -47.8400001525879
    ],
    "hand_front": [
     -10.1199998855591,
     -46.0
    ]
   },
   {
    "hand_back": [
     -1.8400000333786,
     -44.1599998474121
    ],
    "hand_front": [
     -9.19999980926514,
     -40.4799995422363
    ]
   },
   {
    "hand_back": [
     -1.8400000333786,
     -44.1599998474121
    ],
    "hand_front": [
     -9.19999980926514,
     -40.4799995422363
    ]
   },
   {
    "hand_back": [
     -2.20649242401123,
     -46.7254486083984
    ],
    "hand_front": [
     -9.93298435211182,
     -41.5794792175293
    ]
   },
   {
    "hand_back": [
     -2.75999999046326,
     -50.6000022888184
    ],
    "hand_front": [
     -11.039999961853,
     -43.2400016784668
    ]
   },
   {
    "hand_back": [
     -4.59999990463257,
     -56.028003692627
    ],
    "hand_front": [
     -12.8800001144409,
     -53.3600006103516
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute baixo na coxa da frente (o joelho dobra, o pé sai do chão, o tronco desaba e volta). Reação ao low_kick; começar no hit_frame do golpe.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_fast_hit_spin": {
  "action": "hit_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_fast/opp_fast_hit_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     5.51999998092651,
     -57.0400009155273
    ],
    "hand_front": [
     -3.6800000667572,
     -59.7999992370605
    ]
   },
   {
    "hand_back": [
     12.8800001144409,
     -51.5200004577637
    ],
    "hand_front": [
     1.8400000333786,
     -57.0400009155273
    ]
   },
   {
    "hand_back": [
     12.8800001144409,
     -51.5200004577637
    ],
    "hand_front": [
     1.8400000333786,
     -57.0400009155273
    ]
   },
   {
    "hand_back": [
     12.8800001144409,
     -51.5200004577637
    ],
    "hand_front": [
     1.8400000333786,
     -57.0400009155273
    ]
   },
   {
    "hand_back": [
     5.05999994277954,
     -51.060001373291
    ],
    "hand_front": [
     -4.59999990463257,
     -50.1399993896484
    ]
   },
   {
    "hand_back": [
     -2.75999999046326,
     -50.6000022888184
    ],
    "hand_front": [
     -11.039999961853,
     -43.2400016784668
    ]
   },
   {
    "hand_back": [
     -3.6800000667572,
     -53.3140029907227
    ],
    "hand_front": [
     -11.960000038147,
     -48.2999992370605
    ]
   },
   {
    "hand_back": [
     -4.59999990463257,
     -56.028003692627
    ],
    "hand_front": [
     -12.8800001144409,
     -53.3600006103516
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute rodado e NÃO caiu: a cabeça vira, o corpo torce, volta mancando para a guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_fast_limp": {
  "action": "limp",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_fast/opp_fast_limp.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -2.75999999046326,
     -50.6000022888184
    ],
    "hand_front": [
     -11.039999961853,
     -43.2400016784668
    ]
   },
   {
    "hand_back": [
     -2.75999999046326,
     -50.6000022888184
    ],
    "hand_front": [
     -11.039999961853,
     -43.2400016784668
    ]
   },
   {
    "hand_back": [
     -2.75999999046326,
     -49.6800003051758
    ],
    "hand_front": [
     -11.039999961853,
     -42.3199996948242
    ]
   },
   {
    "hand_back": [
     -2.75999999046326,
     -49.6800003051758
    ],
    "hand_front": [
     -11.039999961853,
     -42.3199996948242
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: MANCANDO (idle com 2 marcas): peso no pé de trás, a perna da frente dobrada na ponta, guarda mais baixa. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_fast_limp_heavy": {
  "action": "limp_heavy",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_fast/opp_fast_limp_heavy.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -3.6800000667572,
     -46.9200019836426
    ],
    "hand_front": [
     -7.3600001335144,
     -26.6800003051758
    ]
   },
   {
    "hand_back": [
     -3.6800000667572,
     -46.9200019836426
    ],
    "hand_front": [
     -7.3600001335144,
     -26.6800003051758
    ]
   },
   {
    "hand_back": [
     -3.6800000667572,
     -46.0
    ],
    "hand_front": [
     -7.3600001335144,
     -25.7600002288818
    ]
   },
   {
    "hand_back": [
     -3.6800000667572,
     -46.0
    ],
    "hand_front": [
     -7.3600001335144,
     -25.7600002288818
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: mancando mais torto (idle com 3 marcas): a mão da frente segura a coxa, o pé da frente sai do chão. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_1_fall_spin": {
  "action": "fall_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_1/opp_gym_1_fall_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "ground_frame": 5.0,
  "hands": [
   {
    "hand_back": [
     6.23999977111816,
     -64.4799957275391
    ],
    "hand_front": [
     -4.15999984741211,
     -67.5999984741211
    ]
   },
   {
    "hand_back": [
     14.5599994659424,
     -58.2399978637695
    ],
    "hand_front": [
     2.07999992370605,
     -64.4799957275391
    ]
   },
   {
    "hand_back": [
     12.4799995422363,
     -45.7599983215332
    ],
    "hand_front": [
     0.0,
     -49.9199981689453
    ]
   },
   {
    "hand_back": [
     18.7199993133545,
     -31.1999988555908
    ],
    "hand_front": [
     6.23999977111816,
     -34.3199996948242
    ]
   },
   {
    "hand_back": [
     33.2799987792969,
     -12.4799995422363
    ],
    "hand_front": [
     14.5599994659424,
     -16.6399993896484
    ]
   },
   {
    "hand_back": [
     45.7599983215332,
     -6.23999977111816
    ],
    "hand_front": [
     16.6399993896484,
     -10.9200000762939
    ]
   },
   {
    "hand_back": [
     45.7599983215332,
     -8.31999969482422
    ],
    "hand_front": [
     16.6399993896484,
     -13.5199995040894
    ]
   },
   {
    "hand_back": [
     45.7599983215332,
     -6.23999977111816
    ],
    "hand_front": [
     16.6399993896484,
     -10.9200000762939
    ]
   },
   {
    "hand_back": [
     45.7599983215332,
     -6.23999977111816
    ],
    "hand_front": [
     16.6399993896484,
     -10.9200000762939
    ]
   },
   {
    "hand_back": [
     45.7599983215332,
     -6.23999977111816
    ],
    "hand_front": [
     16.6399993896484,
     -10.9200000762939
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: queda pelo chute rodado (K.O.): a cabeça vira, os joelhos cedem, depois o tronco, cai de costas e fica (segurar o último quadro, como o ko). ground_frame = quadro em que bate no chão.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_1_held_clinch": {
  "action": "held_clinch",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_1/opp_gym_1_held_clinch.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 9,
  "hands": [
   {
    "hand_back": [
     -10.3999996185303,
     -60.3199996948242
    ],
    "hand_front": [
     -14.5599994659424,
     -58.2399978637695
    ]
   },
   {
    "hand_back": [
     -13.5199995040894,
     -54.0799980163574
    ],
    "hand_front": [
     -15.5999994277954,
     -52.0
    ]
   },
   {
    "hand_back": [
     -13.5199995040894,
     -50.9599990844727
    ],
    "hand_front": [
     -15.5999994277954,
     -48.879997253418
    ]
   },
   {
    "hand_back": [
     -8.31999969482422,
     -48.879997253418
    ],
    "hand_front": [
     -11.4399995803833,
     -46.7999992370605
    ]
   },
   {
    "hand_back": [
     -8.31999969482422,
     -48.879997253418
    ],
    "hand_front": [
     -11.4399995803833,
     -46.7999992370605
    ]
   },
   {
    "hand_back": [
     -13.5199995040894,
     -50.9599990844727
    ],
    "hand_front": [
     -15.5999994277954,
     -48.879997253418
    ]
   },
   {
    "hand_back": [
     -4.15999984741211,
     -57.1999969482422
    ],
    "hand_front": [
     -11.4399995803833,
     -54.0799980163574
    ]
   },
   {
    "hand_back": [
     -4.59368991851807,
     -59.7587699890137
    ],
    "hand_front": [
     -12.7410697937012,
     -56.6821365356445
    ]
   },
   {
    "hand_back": [
     -5.19999980926514,
     -63.3359985351563
    ],
    "hand_front": [
     -14.5599994659424,
     -60.3199996948242
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: preso no clinch tailandês (começa no hit_frame 2 do thai_clinch e termina junto): puxado pela nuca, a joelhada acerta no quadro 3, é solto e volta à guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_1_hit_leg": {
  "action": "hit_leg",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_1/opp_gym_1_hit_leg.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     -5.19999980926514,
     -63.3359985351563
    ],
    "hand_front": [
     -14.5599994659424,
     -60.3199996948242
    ]
   },
   {
    "hand_back": [
     -3.11999988555908,
     -54.0799980163574
    ],
    "hand_front": [
     -11.4399995803833,
     -52.0
    ]
   },
   {
    "hand_back": [
     -2.07999992370605,
     -49.9199981689453
    ],
    "hand_front": [
     -10.3999996185303,
     -45.7599983215332
    ]
   },
   {
    "hand_back": [
     -2.07999992370605,
     -49.9199981689453
    ],
    "hand_front": [
     -10.3999996185303,
     -45.7599983215332
    ]
   },
   {
    "hand_back": [
     -2.49429559707642,
     -52.820068359375
    ],
    "hand_front": [
     -11.228590965271,
     -47.0028839111328
    ]
   },
   {
    "hand_back": [
     -3.11999988555908,
     -57.1999969482422
    ],
    "hand_front": [
     -12.4799995422363,
     -48.879997253418
    ]
   },
   {
    "hand_back": [
     -5.19999980926514,
     -63.3359985351563
    ],
    "hand_front": [
     -14.5599994659424,
     -60.3199996948242
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute baixo na coxa da frente (o joelho dobra, o pé sai do chão, o tronco desaba e volta). Reação ao low_kick; começar no hit_frame do golpe.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_1_hit_spin": {
  "action": "hit_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_1/opp_gym_1_hit_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     6.23999977111816,
     -64.4799957275391
    ],
    "hand_front": [
     -4.15999984741211,
     -67.5999984741211
    ]
   },
   {
    "hand_back": [
     14.5599994659424,
     -58.2399978637695
    ],
    "hand_front": [
     2.07999992370605,
     -64.4799957275391
    ]
   },
   {
    "hand_back": [
     14.5599994659424,
     -58.2399978637695
    ],
    "hand_front": [
     2.07999992370605,
     -64.4799957275391
    ]
   },
   {
    "hand_back": [
     14.5599994659424,
     -58.2399978637695
    ],
    "hand_front": [
     2.07999992370605,
     -64.4799957275391
    ]
   },
   {
    "hand_back": [
     5.71999979019165,
     -57.7199974060059
    ],
    "hand_front": [
     -5.19999980926514,
     -56.6799964904785
    ]
   },
   {
    "hand_back": [
     -3.11999988555908,
     -57.1999969482422
    ],
    "hand_front": [
     -12.4799995422363,
     -48.879997253418
    ]
   },
   {
    "hand_back": [
     -4.15999984741211,
     -60.2679977416992
    ],
    "hand_front": [
     -13.5199995040894,
     -54.5999984741211
    ]
   },
   {
    "hand_back": [
     -5.19999980926514,
     -63.3359985351563
    ],
    "hand_front": [
     -14.5599994659424,
     -60.3199996948242
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute rodado e NÃO caiu: a cabeça vira, o corpo torce, volta mancando para a guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_1_limp": {
  "action": "limp",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_1/opp_gym_1_limp.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -3.11999988555908,
     -57.1999969482422
    ],
    "hand_front": [
     -12.4799995422363,
     -48.879997253418
    ]
   },
   {
    "hand_back": [
     -3.11999988555908,
     -57.1999969482422
    ],
    "hand_front": [
     -12.4799995422363,
     -48.879997253418
    ]
   },
   {
    "hand_back": [
     -3.11999988555908,
     -56.1599960327148
    ],
    "hand_front": [
     -12.4799995422363,
     -47.8399963378906
    ]
   },
   {
    "hand_back": [
     -3.11999988555908,
     -56.1599960327148
    ],
    "hand_front": [
     -12.4799995422363,
     -47.8399963378906
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: MANCANDO (idle com 2 marcas): peso no pé de trás, a perna da frente dobrada na ponta, guarda mais baixa. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_1_limp_heavy": {
  "action": "limp_heavy",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_1/opp_gym_1_limp_heavy.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -4.15999984741211,
     -53.0399971008301
    ],
    "hand_front": [
     -8.31999969482422,
     -30.1599998474121
    ]
   },
   {
    "hand_back": [
     -4.15999984741211,
     -53.0399971008301
    ],
    "hand_front": [
     -8.31999969482422,
     -30.1599998474121
    ]
   },
   {
    "hand_back": [
     -4.15999984741211,
     -52.0
    ],
    "hand_front": [
     -8.31999969482422,
     -29.1199989318848
    ]
   },
   {
    "hand_back": [
     -4.15999984741211,
     -52.0
    ],
    "hand_front": [
     -8.31999969482422,
     -29.1199989318848
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: mancando mais torto (idle com 3 marcas): a mão da frente segura a coxa, o pé da frente sai do chão. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_2_fall_spin": {
  "action": "fall_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_2/opp_gym_2_fall_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "ground_frame": 5.0,
  "hands": [
   {
    "hand_back": [
     6.48000049591064,
     -66.9599990844727
    ],
    "hand_front": [
     -4.32000017166138,
     -70.2000045776367
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     12.9600009918213,
     -47.5200004577637
    ],
    "hand_front": [
     0.0,
     -51.8400039672852
    ]
   },
   {
    "hand_back": [
     19.4400005340576,
     -32.4000015258789
    ],
    "hand_front": [
     6.48000049591064,
     -35.6400032043457
    ]
   },
   {
    "hand_back": [
     34.560001373291,
     -12.9600009918213
    ],
    "hand_front": [
     15.1200008392334,
     -17.2800006866455
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -8.64000034332275
    ],
    "hand_front": [
     17.2800006866455,
     -14.0400009155273
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: queda pelo chute rodado (K.O.): a cabeça vira, os joelhos cedem, depois o tronco, cai de costas e fica (segurar o último quadro, como o ko). ground_frame = quadro em que bate no chão.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_2_held_clinch": {
  "action": "held_clinch",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_2/opp_gym_2_held_clinch.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 9,
  "hands": [
   {
    "hand_back": [
     -10.8000001907349,
     -62.6400032043457
    ],
    "hand_front": [
     -15.1200008392334,
     -60.4800033569336
    ]
   },
   {
    "hand_back": [
     -14.0400009155273,
     -56.1600036621094
    ],
    "hand_front": [
     -16.2000007629395,
     -54.0000038146973
    ]
   },
   {
    "hand_back": [
     -14.0400009155273,
     -52.9200019836426
    ],
    "hand_front": [
     -16.2000007629395,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -8.64000034332275,
     -50.7600021362305
    ],
    "hand_front": [
     -11.8800001144409,
     -48.6000022888184
    ]
   },
   {
    "hand_back": [
     -8.64000034332275,
     -50.7600021362305
    ],
    "hand_front": [
     -11.8800001144409,
     -48.6000022888184
    ]
   },
   {
    "hand_back": [
     -14.0400009155273,
     -52.9200019836426
    ],
    "hand_front": [
     -16.2000007629395,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -59.4000015258789
    ],
    "hand_front": [
     -11.8800001144409,
     -56.1600036621094
    ]
   },
   {
    "hand_back": [
     -4.7703709602356,
     -62.0571899414063
    ],
    "hand_front": [
     -13.2311115264893,
     -58.8622245788574
    ]
   },
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: preso no clinch tailandês (começa no hit_frame 2 do thai_clinch e termina junto): puxado pela nuca, a joelhada acerta no quadro 3, é solto e volta à guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_2_hit_leg": {
  "action": "hit_leg",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_2/opp_gym_2_hit_leg.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -56.1600036621094
    ],
    "hand_front": [
     -11.8800001144409,
     -54.0000038146973
    ]
   },
   {
    "hand_back": [
     -2.16000008583069,
     -51.8400039672852
    ],
    "hand_front": [
     -10.8000001907349,
     -47.5200004577637
    ]
   },
   {
    "hand_back": [
     -2.16000008583069,
     -51.8400039672852
    ],
    "hand_front": [
     -10.8000001907349,
     -47.5200004577637
    ]
   },
   {
    "hand_back": [
     -2.59023022651672,
     -54.8516120910645
    ],
    "hand_front": [
     -11.6604604721069,
     -48.8106918334961
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute baixo na coxa da frente (o joelho dobra, o pé sai do chão, o tronco desaba e volta). Reação ao low_kick; começar no hit_frame do golpe.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_2_hit_spin": {
  "action": "hit_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_2/opp_gym_2_hit_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     6.48000049591064,
     -66.9599990844727
    ],
    "hand_front": [
     -4.32000017166138,
     -70.2000045776367
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     5.94000005722046,
     -59.9400024414063
    ],
    "hand_front": [
     -5.40000009536743,
     -58.8600006103516
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -62.5860023498535
    ],
    "hand_front": [
     -14.0400009155273,
     -56.7000007629395
    ]
   },
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute rodado e NÃO caiu: a cabeça vira, o corpo torce, volta mancando para a guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_2_limp": {
  "action": "limp",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_2/opp_gym_2_limp.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -58.3200035095215
    ],
    "hand_front": [
     -12.9600009918213,
     -49.6800003051758
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -58.3200035095215
    ],
    "hand_front": [
     -12.9600009918213,
     -49.6800003051758
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: MANCANDO (idle com 2 marcas): peso no pé de trás, a perna da frente dobrada na ponta, guarda mais baixa. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_gym_2_limp_heavy": {
  "action": "limp_heavy",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_gym_2/opp_gym_2_limp_heavy.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -4.32000017166138,
     -55.0800018310547
    ],
    "hand_front": [
     -8.64000034332275,
     -31.3200016021729
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -55.0800018310547
    ],
    "hand_front": [
     -8.64000034332275,
     -31.3200016021729
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -54.0000038146973
    ],
    "hand_front": [
     -8.64000034332275,
     -30.2400016784668
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -54.0000038146973
    ],
    "hand_front": [
     -8.64000034332275,
     -30.2400016784668
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: mancando mais torto (idle com 3 marcas): a mão da frente segura a coxa, o pé da frente sai do chão. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_strong_fall_spin": {
  "action": "fall_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_strong/opp_strong_fall_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "ground_frame": 5.0,
  "hands": [
   {
    "hand_back": [
     6.48000049591064,
     -66.9599990844727
    ],
    "hand_front": [
     -4.32000017166138,
     -70.2000045776367
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     12.9600009918213,
     -47.5200004577637
    ],
    "hand_front": [
     0.0,
     -51.8400039672852
    ]
   },
   {
    "hand_back": [
     19.4400005340576,
     -32.4000015258789
    ],
    "hand_front": [
     6.48000049591064,
     -35.6400032043457
    ]
   },
   {
    "hand_back": [
     34.560001373291,
     -12.9600009918213
    ],
    "hand_front": [
     15.1200008392334,
     -17.2800006866455
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -8.64000034332275
    ],
    "hand_front": [
     17.2800006866455,
     -14.0400009155273
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   },
   {
    "hand_back": [
     47.5200004577637,
     -6.48000049591064
    ],
    "hand_front": [
     17.2800006866455,
     -11.3400001525879
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: queda pelo chute rodado (K.O.): a cabeça vira, os joelhos cedem, depois o tronco, cai de costas e fica (segurar o último quadro, como o ko). ground_frame = quadro em que bate no chão.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_strong_held_clinch": {
  "action": "held_clinch",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_strong/opp_strong_held_clinch.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 9,
  "hands": [
   {
    "hand_back": [
     -10.8000001907349,
     -62.6400032043457
    ],
    "hand_front": [
     -15.1200008392334,
     -60.4800033569336
    ]
   },
   {
    "hand_back": [
     -14.0400009155273,
     -56.1600036621094
    ],
    "hand_front": [
     -16.2000007629395,
     -54.0000038146973
    ]
   },
   {
    "hand_back": [
     -14.0400009155273,
     -52.9200019836426
    ],
    "hand_front": [
     -16.2000007629395,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -8.64000034332275,
     -50.7600021362305
    ],
    "hand_front": [
     -11.8800001144409,
     -48.6000022888184
    ]
   },
   {
    "hand_back": [
     -8.64000034332275,
     -50.7600021362305
    ],
    "hand_front": [
     -11.8800001144409,
     -48.6000022888184
    ]
   },
   {
    "hand_back": [
     -14.0400009155273,
     -52.9200019836426
    ],
    "hand_front": [
     -16.2000007629395,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -59.4000015258789
    ],
    "hand_front": [
     -11.8800001144409,
     -56.1600036621094
    ]
   },
   {
    "hand_back": [
     -4.7703709602356,
     -62.0571899414063
    ],
    "hand_front": [
     -13.2311115264893,
     -58.8622245788574
    ]
   },
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: preso no clinch tailandês (começa no hit_frame 2 do thai_clinch e termina junto): puxado pela nuca, a joelhada acerta no quadro 3, é solto e volta à guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_strong_hit_leg": {
  "action": "hit_leg",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_strong/opp_strong_hit_leg.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -56.1600036621094
    ],
    "hand_front": [
     -11.8800001144409,
     -54.0000038146973
    ]
   },
   {
    "hand_back": [
     -2.16000008583069,
     -51.8400039672852
    ],
    "hand_front": [
     -10.8000001907349,
     -47.5200004577637
    ]
   },
   {
    "hand_back": [
     -2.16000008583069,
     -51.8400039672852
    ],
    "hand_front": [
     -10.8000001907349,
     -47.5200004577637
    ]
   },
   {
    "hand_back": [
     -2.59023022651672,
     -54.8516120910645
    ],
    "hand_front": [
     -11.6604604721069,
     -48.8106918334961
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute baixo na coxa da frente (o joelho dobra, o pé sai do chão, o tronco desaba e volta). Reação ao low_kick; começar no hit_frame do golpe.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_strong_hit_spin": {
  "action": "hit_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_strong/opp_strong_hit_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     6.48000049591064,
     -66.9599990844727
    ],
    "hand_front": [
     -4.32000017166138,
     -70.2000045776367
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     15.1200008392334,
     -60.4800033569336
    ],
    "hand_front": [
     2.16000008583069,
     -66.9599990844727
    ]
   },
   {
    "hand_back": [
     5.94000005722046,
     -59.9400024414063
    ],
    "hand_front": [
     -5.40000009536743,
     -58.8600006103516
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -62.5860023498535
    ],
    "hand_front": [
     -14.0400009155273,
     -56.7000007629395
    ]
   },
   {
    "hand_back": [
     -5.40000009536743,
     -65.7720031738281
    ],
    "hand_front": [
     -15.1200008392334,
     -62.6400032043457
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute rodado e NÃO caiu: a cabeça vira, o corpo torce, volta mancando para a guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_strong_limp": {
  "action": "limp",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_strong/opp_strong_limp.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -59.4000015258789
    ],
    "hand_front": [
     -12.9600009918213,
     -50.7600021362305
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -58.3200035095215
    ],
    "hand_front": [
     -12.9600009918213,
     -49.6800003051758
    ]
   },
   {
    "hand_back": [
     -3.24000024795532,
     -58.3200035095215
    ],
    "hand_front": [
     -12.9600009918213,
     -49.6800003051758
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: MANCANDO (idle com 2 marcas): peso no pé de trás, a perna da frente dobrada na ponta, guarda mais baixa. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_strong_limp_heavy": {
  "action": "limp_heavy",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_strong/opp_strong_limp_heavy.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -4.32000017166138,
     -55.0800018310547
    ],
    "hand_front": [
     -8.64000034332275,
     -31.3200016021729
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -55.0800018310547
    ],
    "hand_front": [
     -8.64000034332275,
     -31.3200016021729
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -54.0000038146973
    ],
    "hand_front": [
     -8.64000034332275,
     -30.2400016784668
    ]
   },
   {
    "hand_back": [
     -4.32000017166138,
     -54.0000038146973
    ],
    "hand_front": [
     -8.64000034332275,
     -30.2400016784668
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: mancando mais torto (idle com 3 marcas): a mão da frente segura a coxa, o pé da frente sai do chão. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_tank_fall_spin": {
  "action": "fall_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_tank/opp_tank_fall_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "ground_frame": 5.0,
  "hands": [
   {
    "hand_back": [
     6.72000026702881,
     -69.4400024414063
    ],
    "hand_front": [
     -4.48000001907349,
     -72.8000030517578
    ]
   },
   {
    "hand_back": [
     15.6800003051758,
     -62.7200012207031
    ],
    "hand_front": [
     2.24000000953674,
     -69.4400024414063
    ]
   },
   {
    "hand_back": [
     13.4400005340576,
     -49.2799987792969
    ],
    "hand_front": [
     0.0,
     -53.7600021362305
    ]
   },
   {
    "hand_back": [
     20.1599998474121,
     -33.5999984741211
    ],
    "hand_front": [
     6.72000026702881,
     -36.9599990844727
    ]
   },
   {
    "hand_back": [
     35.8400001525879,
     -13.4400005340576
    ],
    "hand_front": [
     15.6800003051758,
     -17.9200000762939
    ]
   },
   {
    "hand_back": [
     49.2799987792969,
     -6.72000026702881
    ],
    "hand_front": [
     17.9200000762939,
     -11.7600002288818
    ]
   },
   {
    "hand_back": [
     49.2799987792969,
     -8.96000003814697
    ],
    "hand_front": [
     17.9200000762939,
     -14.5600004196167
    ]
   },
   {
    "hand_back": [
     49.2799987792969,
     -6.72000026702881
    ],
    "hand_front": [
     17.9200000762939,
     -11.7600002288818
    ]
   },
   {
    "hand_back": [
     49.2799987792969,
     -6.72000026702881
    ],
    "hand_front": [
     17.9200000762939,
     -11.7600002288818
    ]
   },
   {
    "hand_back": [
     49.2799987792969,
     -6.72000026702881
    ],
    "hand_front": [
     17.9200000762939,
     -11.7600002288818
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: queda pelo chute rodado (K.O.): a cabeça vira, os joelhos cedem, depois o tronco, cai de costas e fica (segurar o último quadro, como o ko). ground_frame = quadro em que bate no chão.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_tank_held_clinch": {
  "action": "held_clinch",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_tank/opp_tank_held_clinch.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 9,
  "hands": [
   {
    "hand_back": [
     -11.1999998092651,
     -64.9599990844727
    ],
    "hand_front": [
     -15.6800003051758,
     -62.7200012207031
    ]
   },
   {
    "hand_back": [
     -14.5600004196167,
     -58.2400016784668
    ],
    "hand_front": [
     -16.7999992370605,
     -56.0
    ]
   },
   {
    "hand_back": [
     -14.5600004196167,
     -54.8800010681152
    ],
    "hand_front": [
     -16.7999992370605,
     -52.6399993896484
    ]
   },
   {
    "hand_back": [
     -8.96000003814697,
     -52.6399993896484
    ],
    "hand_front": [
     -12.3199996948242,
     -50.4000015258789
    ]
   },
   {
    "hand_back": [
     -8.96000003814697,
     -52.6399993896484
    ],
    "hand_front": [
     -12.3199996948242,
     -50.4000015258789
    ]
   },
   {
    "hand_back": [
     -14.5600004196167,
     -54.8800010681152
    ],
    "hand_front": [
     -16.7999992370605,
     -52.6399993896484
    ]
   },
   {
    "hand_back": [
     -4.48000001907349,
     -61.5999984741211
    ],
    "hand_front": [
     -12.3199996948242,
     -58.2400016784668
    ]
   },
   {
    "hand_back": [
     -4.94705104827881,
     -64.355598449707
    ],
    "hand_front": [
     -13.721152305603,
     -61.0423049926758
    ]
   },
   {
    "hand_back": [
     -5.59999990463257,
     -68.2080001831055
    ],
    "hand_front": [
     -15.6800003051758,
     -64.9599990844727
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: preso no clinch tailandês (começa no hit_frame 2 do thai_clinch e termina junto): puxado pela nuca, a joelhada acerta no quadro 3, é solto e volta à guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_tank_hit_leg": {
  "action": "hit_leg",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_tank/opp_tank_hit_leg.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     -5.59999990463257,
     -68.2080001831055
    ],
    "hand_front": [
     -15.6800003051758,
     -64.9599990844727
    ]
   },
   {
    "hand_back": [
     -3.3600001335144,
     -58.2400016784668
    ],
    "hand_front": [
     -12.3199996948242,
     -56.0
    ]
   },
   {
    "hand_back": [
     -2.24000000953674,
     -53.7600021362305
    ],
    "hand_front": [
     -11.1999998092651,
     -49.2799987792969
    ]
   },
   {
    "hand_back": [
     -2.24000000953674,
     -53.7600021362305
    ],
    "hand_front": [
     -11.1999998092651,
     -49.2799987792969
    ]
   },
   {
    "hand_back": [
     -2.68616461753845,
     -56.8831520080566
    ],
    "hand_front": [
     -12.0923290252686,
     -50.6184921264648
    ]
   },
   {
    "hand_back": [
     -3.3600001335144,
     -61.5999984741211
    ],
    "hand_front": [
     -13.4400005340576,
     -52.6399993896484
    ]
   },
   {
    "hand_back": [
     -5.59999990463257,
     -68.2080001831055
    ],
    "hand_front": [
     -15.6800003051758,
     -64.9599990844727
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute baixo na coxa da frente (o joelho dobra, o pé sai do chão, o tronco desaba e volta). Reação ao low_kick; começar no hit_frame do golpe.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_tank_hit_spin": {
  "action": "hit_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_tank/opp_tank_hit_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     6.72000026702881,
     -69.4400024414063
    ],
    "hand_front": [
     -4.48000001907349,
     -72.8000030517578
    ]
   },
   {
    "hand_back": [
     15.6800003051758,
     -62.7200012207031
    ],
    "hand_front": [
     2.24000000953674,
     -69.4400024414063
    ]
   },
   {
    "hand_back": [
     15.6800003051758,
     -62.7200012207031
    ],
    "hand_front": [
     2.24000000953674,
     -69.4400024414063
    ]
   },
   {
    "hand_back": [
     15.6800003051758,
     -62.7200012207031
    ],
    "hand_front": [
     2.24000000953674,
     -69.4400024414063
    ]
   },
   {
    "hand_back": [
     6.15999984741211,
     -62.1599998474121
    ],
    "hand_front": [
     -5.59999990463257,
     -61.0400009155273
    ]
   },
   {
    "hand_back": [
     -3.3600001335144,
     -61.5999984741211
    ],
    "hand_front": [
     -13.4400005340576,
     -52.6399993896484
    ]
   },
   {
    "hand_back": [
     -4.48000001907349,
     -64.9039993286133
    ],
    "hand_front": [
     -14.5600004196167,
     -58.7999992370605
    ]
   },
   {
    "hand_back": [
     -5.59999990463257,
     -68.2080001831055
    ],
    "hand_front": [
     -15.6800003051758,
     -64.9599990844727
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute rodado e NÃO caiu: a cabeça vira, o corpo torce, volta mancando para a guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_tank_limp": {
  "action": "limp",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_tank/opp_tank_limp.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -3.3600001335144,
     -61.5999984741211
    ],
    "hand_front": [
     -13.4400005340576,
     -52.6399993896484
    ]
   },
   {
    "hand_back": [
     -3.3600001335144,
     -61.5999984741211
    ],
    "hand_front": [
     -13.4400005340576,
     -52.6399993896484
    ]
   },
   {
    "hand_back": [
     -3.3600001335144,
     -60.4799995422363
    ],
    "hand_front": [
     -13.4400005340576,
     -51.5200004577637
    ]
   },
   {
    "hand_back": [
     -3.3600001335144,
     -60.4799995422363
    ],
    "hand_front": [
     -13.4400005340576,
     -51.5200004577637
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: MANCANDO (idle com 2 marcas): peso no pé de trás, a perna da frente dobrada na ponta, guarda mais baixa. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_tank_limp_heavy": {
  "action": "limp_heavy",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_tank/opp_tank_limp_heavy.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -4.48000001907349,
     -57.1199989318848
    ],
    "hand_front": [
     -8.96000003814697,
     -32.4799995422363
    ]
   },
   {
    "hand_back": [
     -4.48000001907349,
     -57.1199989318848
    ],
    "hand_front": [
     -8.96000003814697,
     -32.4799995422363
    ]
   },
   {
    "hand_back": [
     -4.48000001907349,
     -56.0
    ],
    "hand_front": [
     -8.96000003814697,
     -31.3600006103516
    ]
   },
   {
    "hand_back": [
     -4.48000001907349,
     -56.0
    ],
    "hand_front": [
     -8.96000003814697,
     -31.3600006103516
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: mancando mais torto (idle com 3 marcas): a mão da frente segura a coxa, o pé da frente sai do chão. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_warmup_fall_spin": {
  "action": "fall_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_warmup/opp_warmup_fall_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 10,
  "ground_frame": 5.0,
  "hands": [
   {
    "hand_back": [
     5.88000011444092,
     -60.7600021362305
    ],
    "hand_front": [
     -3.92000007629395,
     -63.7000007629395
    ]
   },
   {
    "hand_back": [
     13.7200002670288,
     -54.8800010681152
    ],
    "hand_front": [
     1.96000003814697,
     -60.7600021362305
    ]
   },
   {
    "hand_back": [
     11.7600002288818,
     -43.120002746582
    ],
    "hand_front": [
     0.0,
     -47.0400009155273
    ]
   },
   {
    "hand_back": [
     17.6399993896484,
     -29.4000015258789
    ],
    "hand_front": [
     5.88000011444092,
     -32.3400001525879
    ]
   },
   {
    "hand_back": [
     31.3600006103516,
     -11.7600002288818
    ],
    "hand_front": [
     13.7200002670288,
     -15.6800003051758
    ]
   },
   {
    "hand_back": [
     43.120002746582,
     -5.88000011444092
    ],
    "hand_front": [
     15.6800003051758,
     -10.289999961853
    ]
   },
   {
    "hand_back": [
     43.120002746582,
     -7.84000015258789
    ],
    "hand_front": [
     15.6800003051758,
     -12.7399997711182
    ]
   },
   {
    "hand_back": [
     43.120002746582,
     -5.88000011444092
    ],
    "hand_front": [
     15.6800003051758,
     -10.289999961853
    ]
   },
   {
    "hand_back": [
     43.120002746582,
     -5.88000011444092
    ],
    "hand_front": [
     15.6800003051758,
     -10.289999961853
    ]
   },
   {
    "hand_back": [
     43.120002746582,
     -5.88000011444092
    ],
    "hand_front": [
     15.6800003051758,
     -10.289999961853
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: queda pelo chute rodado (K.O.): a cabeça vira, os joelhos cedem, depois o tronco, cai de costas e fica (segurar o último quadro, como o ko). ground_frame = quadro em que bate no chão.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_warmup_held_clinch": {
  "action": "held_clinch",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_warmup/opp_warmup_held_clinch.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 9,
  "hands": [
   {
    "hand_back": [
     -9.80000019073486,
     -56.8400001525879
    ],
    "hand_front": [
     -13.7200002670288,
     -54.8800010681152
    ]
   },
   {
    "hand_back": [
     -12.7399997711182,
     -50.9599990844727
    ],
    "hand_front": [
     -14.7000007629395,
     -49.0
    ]
   },
   {
    "hand_back": [
     -12.7399997711182,
     -48.0200004577637
    ],
    "hand_front": [
     -14.7000007629395,
     -46.060001373291
    ]
   },
   {
    "hand_back": [
     -7.84000015258789,
     -46.060001373291
    ],
    "hand_front": [
     -10.7800006866455,
     -44.1000022888184
    ]
   },
   {
    "hand_back": [
     -7.84000015258789,
     -46.060001373291
    ],
    "hand_front": [
     -10.7800006866455,
     -44.1000022888184
    ]
   },
   {
    "hand_back": [
     -12.7399997711182,
     -48.0200004577637
    ],
    "hand_front": [
     -14.7000007629395,
     -46.060001373291
    ]
   },
   {
    "hand_back": [
     -3.92000007629395,
     -53.9000015258789
    ],
    "hand_front": [
     -10.7800006866455,
     -50.9599990844727
    ]
   },
   {
    "hand_back": [
     -4.32866954803467,
     -56.3111534118652
    ],
    "hand_front": [
     -12.0060091018677,
     -53.4120178222656
    ]
   },
   {
    "hand_back": [
     -4.90000009536743,
     -59.6820030212402
    ],
    "hand_front": [
     -13.7200002670288,
     -56.8400001525879
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: preso no clinch tailandês (começa no hit_frame 2 do thai_clinch e termina junto): puxado pela nuca, a joelhada acerta no quadro 3, é solto e volta à guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_warmup_hit_leg": {
  "action": "hit_leg",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_warmup/opp_warmup_hit_leg.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     -4.90000009536743,
     -59.6820030212402
    ],
    "hand_front": [
     -13.7200002670288,
     -56.8400001525879
    ]
   },
   {
    "hand_back": [
     -2.94000005722046,
     -50.9599990844727
    ],
    "hand_front": [
     -10.7800006866455,
     -49.0
    ]
   },
   {
    "hand_back": [
     -1.96000003814697,
     -47.0400009155273
    ],
    "hand_front": [
     -9.80000019073486,
     -43.120002746582
    ]
   },
   {
    "hand_back": [
     -1.96000003814697,
     -47.0400009155273
    ],
    "hand_front": [
     -9.80000019073486,
     -43.120002746582
    ]
   },
   {
    "hand_back": [
     -2.35039401054382,
     -49.7727584838867
    ],
    "hand_front": [
     -10.5807886123657,
     -44.2911834716797
    ]
   },
   {
    "hand_back": [
     -2.94000005722046,
     -53.9000015258789
    ],
    "hand_front": [
     -11.7600002288818,
     -46.060001373291
    ]
   },
   {
    "hand_back": [
     -4.90000009536743,
     -59.6820030212402
    ],
    "hand_front": [
     -13.7200002670288,
     -56.8400001525879
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute baixo na coxa da frente (o joelho dobra, o pé sai do chão, o tronco desaba e volta). Reação ao low_kick; começar no hit_frame do golpe.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_warmup_hit_spin": {
  "action": "hit_spin",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_warmup/opp_warmup_hit_spin.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 8,
  "hands": [
   {
    "hand_back": [
     5.88000011444092,
     -60.7600021362305
    ],
    "hand_front": [
     -3.92000007629395,
     -63.7000007629395
    ]
   },
   {
    "hand_back": [
     13.7200002670288,
     -54.8800010681152
    ],
    "hand_front": [
     1.96000003814697,
     -60.7600021362305
    ]
   },
   {
    "hand_back": [
     13.7200002670288,
     -54.8800010681152
    ],
    "hand_front": [
     1.96000003814697,
     -60.7600021362305
    ]
   },
   {
    "hand_back": [
     13.7200002670288,
     -54.8800010681152
    ],
    "hand_front": [
     1.96000003814697,
     -60.7600021362305
    ]
   },
   {
    "hand_back": [
     5.39000034332275,
     -54.3899993896484
    ],
    "hand_front": [
     -4.90000009536743,
     -53.4099998474121
    ]
   },
   {
    "hand_back": [
     -2.94000005722046,
     -53.9000015258789
    ],
    "hand_front": [
     -11.7600002288818,
     -46.060001373291
    ]
   },
   {
    "hand_back": [
     -3.92000007629395,
     -56.7910003662109
    ],
    "hand_front": [
     -12.7399997711182,
     -51.4500007629395
    ]
   },
   {
    "hand_back": [
     -4.90000009536743,
     -59.6820030212402
    ],
    "hand_front": [
     -13.7200002670288,
     -56.8400001525879
    ]
   }
  ],
  "loop": false,
  "note": "Fase 7b1: levou o chute rodado e NÃO caiu: a cabeça vira, o corpo torce, volta mancando para a guarda.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_warmup_limp": {
  "action": "limp",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_warmup/opp_warmup_limp.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -2.94000005722046,
     -53.9000015258789
    ],
    "hand_front": [
     -11.7600002288818,
     -46.060001373291
    ]
   },
   {
    "hand_back": [
     -2.94000005722046,
     -53.9000015258789
    ],
    "hand_front": [
     -11.7600002288818,
     -46.060001373291
    ]
   },
   {
    "hand_back": [
     -2.94000005722046,
     -52.9200019836426
    ],
    "hand_front": [
     -11.7600002288818,
     -45.0800018310547
    ]
   },
   {
    "hand_back": [
     -2.94000005722046,
     -52.9200019836426
    ],
    "hand_front": [
     -11.7600002288818,
     -45.0800018310547
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: MANCANDO (idle com 2 marcas): peso no pé de trás, a perna da frente dobrada na ponta, guarda mais baixa. Loop.",
  "pivot": [
   56,
   98
  ]
 },
 "opp_warmup_limp_heavy": {
  "action": "limp_heavy",
  "facing": "esquerda",
  "file": "res://assets/sprites/opponents/opp_warmup/opp_warmup_limp_heavy.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     -3.92000007629395,
     -49.9799995422363
    ],
    "hand_front": [
     -7.84000015258789,
     -28.4200000762939
    ]
   },
   {
    "hand_back": [
     -3.92000007629395,
     -49.9799995422363
    ],
    "hand_front": [
     -7.84000015258789,
     -28.4200000762939
    ]
   },
   {
    "hand_back": [
     -3.92000007629395,
     -49.0
    ],
    "hand_front": [
     -7.84000015258789,
     -27.4400005340576
    ]
   },
   {
    "hand_back": [
     -3.92000007629395,
     -49.0
    ],
    "hand_front": [
     -7.84000015258789,
     -27.4400005340576
    ]
   }
  ],
  "loop": true,
  "note": "Fase 7b1: mancando mais torto (idle com 3 marcas): a mão da frente segura a coxa, o pé da frente sai do chão. Loop.",
  "pivot": [
   56,
   98
  ]
 }
}
```
