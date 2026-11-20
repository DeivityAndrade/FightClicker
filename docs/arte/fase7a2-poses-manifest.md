# Fase 7a2: personagens do Treino fora de hora (entradas para o manifest)

Artista de Personagens. Registrado pelo `tools/art/manifest_7a2.py` do Diretor de Arte (bloco `sprites` e `minigame_layout` abaixo).
PNG em `assets/sprites/fight/` e `assets/sprites/disciple/` (discípulo, com camadas e as 5 luvas), `assets/sprites/characters/`
(discípulo com os panfletos) e `assets/sprites/minigame/` (parceiro e passantes). Nenhum arquivo antigo foi sobrescrito.

## Como foi gerado (dá para rodar de novo)
Poses em dados em `tools/art/golpes_7a2.json` (autoria: `python tools/art/poses_7a2.py`, que também trava a mão no alcance do braço).
Numa pasta temporária com `project.godot` vazio (nunca no projeto):
```
FC_LUTADOR=disc FC_CAMADAS=1 FC_GOLPES=E:/Fightclicker/tools/art/golpes_7a2.json godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_golpes_jogador.gd -- <tmp>/out_j
godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_sprites_fase7a2.gd -- <tmp>/out_j <tmp>/out <pranchas>
python tools/art/doc_manifest_7a2.py <tmp>/out_j <tmp>/out
```
Mudança pequena em `make_golpes_jogador.gd`: chave `prop` nas poses da garagem (maço / panfleto na mão, atrás dos dedos). Nada que já
existia muda de resultado.

## Contrato
- Choque: os dois de pé nos pivôs da luta (`minigame_layout.spar`: 296 e 346, pés em y 318), quadro 112x104, pivô (56,98). O parceiro
  é um aluno da Raízes (um pouco mais alto e magro que o discípulo): capacete azul, regata e luva verde no Boxe; quimono azul com faixa
  branca e mãos nuas no Jiu-jitsu. Folhas dele já viradas para a esquerda.
- Panfletagem: discípulo em 3/4 da sala (48x72, pivô 22,67) em `fighter_spot`; passantes em perfil na escala da sala, quadro
  **48x76, pivô (24,71)** (o 48x72 cortava a cabeça no andar), pés em y 300. 4 tipos, cada um com o seu jeito de "não quero".
- Osmar: as folhas de hoje (`coach_idle` / `coach_idle_gym`), sem animação nova (o design não pede).

## Pedidos ao Programador / UI/UX
1. Ordem de desenho no Choque: Boxe como na luta (quem bate por cima); JJ com o discípulo por cima.
2. Estados do parceiro e do discípulo: ver `minigame_layout.spar.partner_states` e `player_actions`. Avisos (`warn`, `feint`) e a
   puxada forte (`jj_yank`) seguram o último quadro até o padrão acabar.
3. `spar_jj_take` tocado ao contrário = soltar (não há folha própria).
4. Passantes: espelhar a folha para quem anda para a esquerda; a folha `tell` repete os quadros 3-5 enquanto durar o `tell_s`.
5. Panfleto voando: sai de `hand_flyer` do `fighter_flyer_give` no `hit_frame`.

## Tabela (folhas planas; cada `*_disc` tem também a `_layered`)
| id | quadro | quadros | pivô | fps | loop | hit (quadro / ponto) |
|---|---|---|---|---|---|---|
| `fight_player_spar_box_counter_disc` | 112x104 | 7 | [56, 98] | 16.0 | não | 3 / [35.0, -60.0] |
| `fight_player_spar_box_counter_glove_l1_disc` | 112x104 | 7 | [56, 98] | 16.0 | não | 3 / [35.0, -60.0] |
| `fight_player_spar_box_counter_glove_l2_disc` | 112x104 | 7 | [56, 98] | 16.0 | não | 3 / [35.0, -60.0] |
| `fight_player_spar_box_counter_glove_l3_disc` | 112x104 | 7 | [56, 98] | 16.0 | não | 3 / [35.0, -60.0] |
| `fight_player_spar_box_counter_glove_l4_disc` | 112x104 | 7 | [56, 98] | 16.0 | não | 3 / [35.0, -60.0] |
| `fight_player_spar_box_guard_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_box_guard_glove_l1_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_box_guard_glove_l2_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_box_guard_glove_l3_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_box_guard_glove_l4_disc` | 112x104 | 2 | [56, 98] | 4.0 | sim | - |
| `fight_player_spar_box_idle_disc` | 112x104 | 4 | [56, 98] | 6.0 | sim | - |
| `fight_player_spar_box_idle_glove_l1_disc` | 112x104 | 4 | [56, 98] | 6.0 | sim | - |
| `fight_player_spar_box_idle_glove_l2_disc` | 112x104 | 4 | [56, 98] | 6.0 | sim | - |
| `fight_player_spar_box_idle_glove_l3_disc` | 112x104 | 4 | [56, 98] | 6.0 | sim | - |
| `fight_player_spar_box_idle_glove_l4_disc` | 112x104 | 4 | [56, 98] | 6.0 | sim | - |
| `fight_player_spar_box_push_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [34.0, -60.0] |
| `fight_player_spar_box_push_glove_l1_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [34.0, -60.0] |
| `fight_player_spar_box_push_glove_l2_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [34.0, -60.0] |
| `fight_player_spar_box_push_glove_l3_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [34.0, -60.0] |
| `fight_player_spar_box_push_glove_l4_disc` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [34.0, -60.0] |
| `fight_player_spar_box_recoil_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_box_recoil_glove_l1_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_box_recoil_glove_l2_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_box_recoil_glove_l3_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_box_recoil_glove_l4_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_jj_grip_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_grip_glove_l1_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_grip_glove_l2_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_grip_glove_l3_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_grip_glove_l4_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_pull_disc` | 112x104 | 4 | [56, 98] | 8.0 | sim | - |
| `fight_player_spar_jj_pull_glove_l1_disc` | 112x104 | 4 | [56, 98] | 8.0 | sim | - |
| `fight_player_spar_jj_pull_glove_l2_disc` | 112x104 | 4 | [56, 98] | 8.0 | sim | - |
| `fight_player_spar_jj_pull_glove_l3_disc` | 112x104 | 4 | [56, 98] | 8.0 | sim | - |
| `fight_player_spar_jj_pull_glove_l4_disc` | 112x104 | 4 | [56, 98] | 8.0 | sim | - |
| `fight_player_spar_jj_release_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_release_glove_l1_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_release_glove_l2_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_release_glove_l3_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_release_glove_l4_disc` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `fight_player_spar_jj_take_disc` | 112x104 | 4 | [56, 98] | 12.0 | não | - |
| `fight_player_spar_jj_take_glove_l1_disc` | 112x104 | 4 | [56, 98] | 12.0 | não | - |
| `fight_player_spar_jj_take_glove_l2_disc` | 112x104 | 4 | [56, 98] | 12.0 | não | - |
| `fight_player_spar_jj_take_glove_l3_disc` | 112x104 | 4 | [56, 98] | 12.0 | não | - |
| `fight_player_spar_jj_take_glove_l4_disc` | 112x104 | 4 | [56, 98] | 12.0 | não | - |
| `fight_player_spar_jj_yanked_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_jj_yanked_glove_l1_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_jj_yanked_glove_l2_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_jj_yanked_glove_l3_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fight_player_spar_jj_yanked_glove_l4_disc` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `fighter_flyer_give_disc` | 48x72 | 6 | [22.0, 67.0] | 12.0 | não | 3.0 / mão [15, -41] |
| `fighter_flyer_give_glove_l1_disc` | 48x72 | 6 | [22.0, 67.0] | 12.0 | não | 3.0 / mão [15, -41] |
| `fighter_flyer_give_glove_l2_disc` | 48x72 | 6 | [22.0, 67.0] | 12.0 | não | 3.0 / mão [15, -41] |
| `fighter_flyer_give_glove_l3_disc` | 48x72 | 6 | [22.0, 67.0] | 12.0 | não | 3.0 / mão [15, -41] |
| `fighter_flyer_give_glove_l4_disc` | 48x72 | 6 | [22.0, 67.0] | 12.0 | não | 3.0 / mão [15, -41] |
| `fighter_flyer_idle_disc` | 48x72 | 4 | [22.0, 67.0] | 5.0 | sim | - |
| `fighter_flyer_idle_glove_l1_disc` | 48x72 | 4 | [22.0, 67.0] | 5.0 | sim | - |
| `fighter_flyer_idle_glove_l2_disc` | 48x72 | 4 | [22.0, 67.0] | 5.0 | sim | - |
| `fighter_flyer_idle_glove_l3_disc` | 48x72 | 4 | [22.0, 67.0] | 5.0 | sim | - |
| `fighter_flyer_idle_glove_l4_disc` | 48x72 | 4 | [22.0, 67.0] | 5.0 | sim | - |
| `fighter_flyer_miss_disc` | 48x72 | 6 | [22.0, 67.0] | 10.0 | não | - |
| `fighter_flyer_miss_glove_l1_disc` | 48x72 | 6 | [22.0, 67.0] | 10.0 | não | - |
| `fighter_flyer_miss_glove_l2_disc` | 48x72 | 6 | [22.0, 67.0] | 10.0 | não | - |
| `fighter_flyer_miss_glove_l3_disc` | 48x72 | 6 | [22.0, 67.0] | 10.0 | não | - |
| `fighter_flyer_miss_glove_l4_disc` | 48x72 | 6 | [22.0, 67.0] | 10.0 | não | - |
| `ped_estudante_false` | 48x76 | 7 | [24, 71] | 9.0 | não | - |
| `ped_estudante_flyer` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_estudante_pockets` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_estudante_refuse` | 48x76 | 5 | [24, 71] | 10.0 | não | - |
| `ped_estudante_tell` | 48x76 | 6 | [24, 71] | 8.0 | não | - |
| `ped_estudante_walk` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_moca_false` | 48x76 | 7 | [24, 71] | 9.0 | não | - |
| `ped_moca_flyer` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_moca_phone` | 48x76 | 8 | [24, 71] | 9.0 | sim | - |
| `ped_moca_refuse` | 48x76 | 5 | [24, 71] | 10.0 | não | - |
| `ped_moca_tell` | 48x76 | 6 | [24, 71] | 8.0 | não | - |
| `ped_moca_walk` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_senhora_crossed` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_senhora_false` | 48x76 | 7 | [24, 71] | 9.0 | não | - |
| `ped_senhora_flyer` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_senhora_refuse` | 48x76 | 5 | [24, 71] | 10.0 | não | - |
| `ped_senhora_tell` | 48x76 | 6 | [24, 71] | 8.0 | não | - |
| `ped_senhora_walk` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_trabalhador_false` | 48x76 | 7 | [24, 71] | 9.0 | não | - |
| `ped_trabalhador_flyer` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `ped_trabalhador_hurry` | 48x76 | 8 | [24, 71] | 15.0 | sim | - |
| `ped_trabalhador_refuse` | 48x76 | 5 | [24, 71] | 10.0 | não | - |
| `ped_trabalhador_tell` | 48x76 | 6 | [24, 71] | 8.0 | não | - |
| `ped_trabalhador_walk` | 48x76 | 8 | [24, 71] | 10.0 | sim | - |
| `spar_partner_box_burst` | 112x104 | 6 | [56, 98] | 12.0 | sim | - |
| `spar_partner_box_feint` | 112x104 | 6 | [56, 98] | 12.0 | não | - |
| `spar_partner_box_idle` | 112x104 | 4 | [56, 98] | 6.0 | sim | - |
| `spar_partner_box_pause` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `spar_partner_box_push` | 112x104 | 6 | [56, 98] | 16.0 | não | 2 / [-34.0, -60.0] |
| `spar_partner_box_recoil` | 112x104 | 6 | [56, 98] | 14.0 | não | - |
| `spar_partner_box_warn` | 112x104 | 3 | [56, 98] | 10.0 | não | - |
| `spar_partner_jj_feint` | 112x104 | 6 | [56, 98] | 12.0 | não | - |
| `spar_partner_jj_grip` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `spar_partner_jj_pause` | 112x104 | 4 | [56, 98] | 5.0 | sim | - |
| `spar_partner_jj_pull` | 112x104 | 4 | [56, 98] | 8.0 | sim | - |
| `spar_partner_jj_take` | 112x104 | 4 | [56, 98] | 12.0 | não | - |
| `spar_partner_jj_warn` | 112x104 | 3 | [56, 98] | 10.0 | não | - |
| `spar_partner_jj_yank` | 112x104 | 6 | [56, 98] | 12.0 | não | - |
| `spar_partner_jj_yanked` | 112x104 | 6 | [56, 98] | 14.0 | não | - |

## Entradas completas para `sprites` (169 chaves)
```json
{
 "fight_player_spar_box_idle_disc": {
  "action": "spar_box_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_idle_disc.png",
  "fps": 6.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe parado (guarda, respiração)."
 },
 "fight_player_spar_box_idle_disc_layered": {
  "action": "spar_box_idle",
  "facing": "direita",
  "fps": 6.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_idle_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_idle_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_idle_glove_l1_disc": {
  "action": "spar_box_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_idle_glove_l1_disc.png",
  "fps": 6.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe parado (guarda, respiração)."
 },
 "fight_player_spar_box_idle_glove_l1_disc_layered": {
  "action": "spar_box_idle",
  "facing": "direita",
  "fps": 6.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_idle_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_idle_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_idle_glove_l2_disc": {
  "action": "spar_box_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_idle_glove_l2_disc.png",
  "fps": 6.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe parado (guarda, respiração)."
 },
 "fight_player_spar_box_idle_glove_l2_disc_layered": {
  "action": "spar_box_idle",
  "facing": "direita",
  "fps": 6.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_idle_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_idle_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_idle_glove_l3_disc": {
  "action": "spar_box_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_idle_glove_l3_disc.png",
  "fps": 6.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe parado (guarda, respiração)."
 },
 "fight_player_spar_box_idle_glove_l3_disc_layered": {
  "action": "spar_box_idle",
  "facing": "direita",
  "fps": 6.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_idle_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_idle_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_idle_glove_l4_disc": {
  "action": "spar_box_idle",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_idle_glove_l4_disc.png",
  "fps": 6.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -62.0
    ],
    "hand_front": [
     14.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe parado (guarda, respiração)."
 },
 "fight_player_spar_box_idle_glove_l4_disc_layered": {
  "action": "spar_box_idle",
  "facing": "direita",
  "fps": 6.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_idle_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_idle_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_idle_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -72.0
    ],
    "head_box": [
     54,
     19,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -62.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     19,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_idle_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_push_disc": {
  "action": "spar_box_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_push_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.9,
     -59.99
    ]
   },
   {
    "hand_back": [
     7.5,
     -61.5
    ],
    "hand_front": [
     30.7565597667638,
     -59.5954810495627
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   34.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, cada clique: jab curto que empurra. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_push_disc_layered": {
  "action": "spar_box_push",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_push_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
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
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -70.3690185546875
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.75,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_push_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_push_glove_l1_disc": {
  "action": "spar_box_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_push_glove_l1_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.9,
     -59.99
    ]
   },
   {
    "hand_back": [
     7.5,
     -61.5
    ],
    "hand_front": [
     30.7565597667638,
     -59.5954810495627
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   34.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, cada clique: jab curto que empurra. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_push_glove_l1_disc_layered": {
  "action": "spar_box_push",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_push_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
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
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -70.3690185546875
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.75,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_push_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_push_glove_l2_disc": {
  "action": "spar_box_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_push_glove_l2_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.9,
     -59.99
    ]
   },
   {
    "hand_back": [
     7.5,
     -61.5
    ],
    "hand_front": [
     30.7565597667638,
     -59.5954810495627
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   34.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, cada clique: jab curto que empurra. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_push_glove_l2_disc_layered": {
  "action": "spar_box_push",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_push_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
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
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -70.3690185546875
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.75,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_push_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_push_glove_l3_disc": {
  "action": "spar_box_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_push_glove_l3_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.9,
     -59.99
    ]
   },
   {
    "hand_back": [
     7.5,
     -61.5
    ],
    "hand_front": [
     30.7565597667638,
     -59.5954810495627
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   34.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, cada clique: jab curto que empurra. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_push_glove_l3_disc_layered": {
  "action": "spar_box_push",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_push_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
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
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -70.3690185546875
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.75,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_push_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_push_glove_l4_disc": {
  "action": "spar_box_push",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_push_glove_l4_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -62.0
    ],
    "hand_front": [
     34.9,
     -59.99
    ]
   },
   {
    "hand_back": [
     7.5,
     -61.5
    ],
    "hand_front": [
     30.7565597667638,
     -59.5954810495627
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 2,
  "hit_point": [
   34.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, cada clique: jab curto que empurra. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_push_glove_l4_disc_layered": {
  "action": "spar_box_push",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_push_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_push_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_push_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
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
     -71.0
    ],
    "head_box": [
     53,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     1.0,
     -61.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -70.0
    ],
    "head_box": [
     60,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -61.0
    ],
    "tw": 1.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -70.3690185546875
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -61.0
    ],
    "tw": 0.75,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     53,
     20,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_push_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_counter_disc": {
  "action": "spar_box_counter",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_counter_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     7.44897959183674,
     -60.9183673469388
    ],
    "hand_front": [
     13.5,
     -58.5
    ]
   },
   {
    "hand_back": [
     35.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     36.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     29.8542274052478,
     -60.198250728863
    ],
    "hand_front": [
     13.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, clique na PAUSA dele (x2): direto de trás com o quadril. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_counter_disc_layered": {
  "action": "spar_box_counter",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_counter_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     0.0,
     -60.0
    ],
    "tw": -0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.35639953613281,
     -69.830451965332
    ],
    "head_box": [
     53,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -36.25
    ],
    "top": [
     2.25,
     -60.0
    ],
    "tw": 0.275,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -69.7380447387695
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -60.5
    ],
    "tw": 1.15,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_counter_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_counter_glove_l1_disc": {
  "action": "spar_box_counter",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_counter_glove_l1_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     7.44897959183674,
     -60.9183673469388
    ],
    "hand_front": [
     13.5,
     -58.5
    ]
   },
   {
    "hand_back": [
     35.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     36.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     29.8542274052478,
     -60.198250728863
    ],
    "hand_front": [
     13.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, clique na PAUSA dele (x2): direto de trás com o quadril. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_counter_glove_l1_disc_layered": {
  "action": "spar_box_counter",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_counter_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     0.0,
     -60.0
    ],
    "tw": -0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.35639953613281,
     -69.830451965332
    ],
    "head_box": [
     53,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -36.25
    ],
    "top": [
     2.25,
     -60.0
    ],
    "tw": 0.275,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -69.7380447387695
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -60.5
    ],
    "tw": 1.15,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_counter_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_counter_glove_l2_disc": {
  "action": "spar_box_counter",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_counter_glove_l2_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     7.44897959183674,
     -60.9183673469388
    ],
    "hand_front": [
     13.5,
     -58.5
    ]
   },
   {
    "hand_back": [
     35.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     36.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     29.8542274052478,
     -60.198250728863
    ],
    "hand_front": [
     13.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, clique na PAUSA dele (x2): direto de trás com o quadril. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_counter_glove_l2_disc_layered": {
  "action": "spar_box_counter",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_counter_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     0.0,
     -60.0
    ],
    "tw": -0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.35639953613281,
     -69.830451965332
    ],
    "head_box": [
     53,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -36.25
    ],
    "top": [
     2.25,
     -60.0
    ],
    "tw": 0.275,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -69.7380447387695
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -60.5
    ],
    "tw": 1.15,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_counter_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_counter_glove_l3_disc": {
  "action": "spar_box_counter",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_counter_glove_l3_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     7.44897959183674,
     -60.9183673469388
    ],
    "hand_front": [
     13.5,
     -58.5
    ]
   },
   {
    "hand_back": [
     35.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     36.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     29.8542274052478,
     -60.198250728863
    ],
    "hand_front": [
     13.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, clique na PAUSA dele (x2): direto de trás com o quadril. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_counter_glove_l3_disc_layered": {
  "action": "spar_box_counter",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_counter_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     0.0,
     -60.0
    ],
    "tw": -0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.35639953613281,
     -69.830451965332
    ],
    "head_box": [
     53,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -36.25
    ],
    "top": [
     2.25,
     -60.0
    ],
    "tw": 0.275,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -69.7380447387695
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -60.5
    ],
    "tw": 1.15,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_counter_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_counter_glove_l4_disc": {
  "action": "spar_box_counter",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_counter_glove_l4_disc.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     7.44897959183674,
     -60.9183673469388
    ],
    "hand_front": [
     13.5,
     -58.5
    ]
   },
   {
    "hand_back": [
     35.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     36.0,
     -60.0
    ],
    "hand_front": [
     12.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     29.8542274052478,
     -60.198250728863
    ],
    "hand_front": [
     13.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "hit_frame": 3,
  "hit_point": [
   35.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe, clique na PAUSA dele (x2): direto de trás com o quadril. Reação dele: spar_partner_box_recoil."
 },
 "fight_player_spar_box_counter_glove_l4_disc_layered": {
  "action": "spar_box_counter",
  "facing": "direita",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_counter_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_counter_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_counter_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -36.0
    ],
    "top": [
     0.0,
     -60.0
    ],
    "tw": -0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     4.35639953613281,
     -69.830451965332
    ],
    "head_box": [
     53,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -36.25
    ],
    "top": [
     2.25,
     -60.0
    ],
    "tw": 0.275,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     11.0,
     -69.0
    ],
    "head_box": [
     60,
     22,
     13,
     13
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     3.0,
     -37.0
    ],
    "top": [
     9.0,
     -60.0
    ],
    "tw": 2.0,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.78587341308594,
     -69.7380447387695
    ],
    "head_box": [
     58,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.5,
     -37.0
    ],
    "top": [
     5.5,
     -60.5
    ],
    "tw": 1.15,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     52,
     20,
     21,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_counter_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_guard_disc": {
  "action": "spar_box_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_guard_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     12.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -67.0
    ],
    "hand_front": [
     12.0,
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
  "note": "Fase 7a2: Choque Boxe, segurando (guarda fechada): loop enquanto segura; anula a rajada."
 },
 "fight_player_spar_box_guard_disc_layered": {
  "action": "spar_box_guard",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_guard_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_front.png",
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
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -69.0
    ],
    "head_box": [
     52,
     22,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
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
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_guard_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_guard_glove_l1_disc": {
  "action": "spar_box_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_guard_glove_l1_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     12.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -67.0
    ],
    "hand_front": [
     12.0,
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
  "note": "Fase 7a2: Choque Boxe, segurando (guarda fechada): loop enquanto segura; anula a rajada."
 },
 "fight_player_spar_box_guard_glove_l1_disc_layered": {
  "action": "spar_box_guard",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_guard_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_front.png",
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
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -69.0
    ],
    "head_box": [
     52,
     22,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
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
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_guard_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_guard_glove_l2_disc": {
  "action": "spar_box_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_guard_glove_l2_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     12.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -67.0
    ],
    "hand_front": [
     12.0,
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
  "note": "Fase 7a2: Choque Boxe, segurando (guarda fechada): loop enquanto segura; anula a rajada."
 },
 "fight_player_spar_box_guard_glove_l2_disc_layered": {
  "action": "spar_box_guard",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_guard_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_front.png",
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
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -69.0
    ],
    "head_box": [
     52,
     22,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
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
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_guard_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_guard_glove_l3_disc": {
  "action": "spar_box_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_guard_glove_l3_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     12.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -67.0
    ],
    "hand_front": [
     12.0,
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
  "note": "Fase 7a2: Choque Boxe, segurando (guarda fechada): loop enquanto segura; anula a rajada."
 },
 "fight_player_spar_box_guard_glove_l3_disc_layered": {
  "action": "spar_box_guard",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_guard_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_front.png",
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
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -69.0
    ],
    "head_box": [
     52,
     22,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
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
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_guard_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_guard_glove_l4_disc": {
  "action": "spar_box_guard",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_guard_glove_l4_disc.png",
  "fps": 4.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 2,
  "hands": [
   {
    "hand_back": [
     10.0,
     -66.0
    ],
    "hand_front": [
     12.0,
     -65.0
    ]
   },
   {
    "hand_back": [
     10.0,
     -67.0
    ],
    "hand_front": [
     12.0,
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
  "note": "Fase 7a2: Choque Boxe, segurando (guarda fechada): loop enquanto segura; anula a rajada."
 },
 "fight_player_spar_box_guard_glove_l4_disc_layered": {
  "action": "spar_box_guard",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_guard_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_guard_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_guard_disc_front.png",
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
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -69.0
    ],
    "head_box": [
     52,
     22,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
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
    "tw": 0.2,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -70.0
    ],
    "head_box": [
     52,
     21,
     13,
     14
    ],
    "head_box_max": [
     52,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -37.0
    ],
    "top": [
     0.0,
     -62.0
    ],
    "tw": 0.2,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_guard_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_recoil_disc": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_recoil_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -62.0
    ],
    "hand_front": [
     9.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     3.5,
     -61.5
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe: empurrado para trás (ele empurrou / ENCOSTOU em você)."
 },
 "fight_player_spar_box_recoil_disc_layered": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_recoil_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -4.0,
     -69.0
    ],
    "head_box": [
     45,
     22,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -3.0,
     -36.0
    ],
    "top": [
     -6.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -5.0,
     -70.0
    ],
    "head_box": [
     44,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -5.0,
     -36.0
    ],
    "top": [
     -7.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -3.0,
     -70.0
    ],
    "head_box": [
     46,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -4.0,
     -36.0
    ],
    "top": [
     -5.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     1.0,
     -70.5
    ],
    "head_box": [
     50,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -36.5
    ],
    "top": [
     -1.5,
     -60.5
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_recoil_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_recoil_glove_l1_disc": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_recoil_glove_l1_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -62.0
    ],
    "hand_front": [
     9.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     3.5,
     -61.5
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe: empurrado para trás (ele empurrou / ENCOSTOU em você)."
 },
 "fight_player_spar_box_recoil_glove_l1_disc_layered": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_recoil_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -4.0,
     -69.0
    ],
    "head_box": [
     45,
     22,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -3.0,
     -36.0
    ],
    "top": [
     -6.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -5.0,
     -70.0
    ],
    "head_box": [
     44,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -5.0,
     -36.0
    ],
    "top": [
     -7.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -3.0,
     -70.0
    ],
    "head_box": [
     46,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -4.0,
     -36.0
    ],
    "top": [
     -5.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     1.0,
     -70.5
    ],
    "head_box": [
     50,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -36.5
    ],
    "top": [
     -1.5,
     -60.5
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_recoil_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_recoil_glove_l2_disc": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_recoil_glove_l2_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -62.0
    ],
    "hand_front": [
     9.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     3.5,
     -61.5
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe: empurrado para trás (ele empurrou / ENCOSTOU em você)."
 },
 "fight_player_spar_box_recoil_glove_l2_disc_layered": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_recoil_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -4.0,
     -69.0
    ],
    "head_box": [
     45,
     22,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -3.0,
     -36.0
    ],
    "top": [
     -6.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -5.0,
     -70.0
    ],
    "head_box": [
     44,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -5.0,
     -36.0
    ],
    "top": [
     -7.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -3.0,
     -70.0
    ],
    "head_box": [
     46,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -4.0,
     -36.0
    ],
    "top": [
     -5.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     1.0,
     -70.5
    ],
    "head_box": [
     50,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -36.5
    ],
    "top": [
     -1.5,
     -60.5
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_recoil_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_recoil_glove_l3_disc": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_recoil_glove_l3_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -62.0
    ],
    "hand_front": [
     9.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     3.5,
     -61.5
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe: empurrado para trás (ele empurrou / ENCOSTOU em você)."
 },
 "fight_player_spar_box_recoil_glove_l3_disc_layered": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_recoil_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -4.0,
     -69.0
    ],
    "head_box": [
     45,
     22,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -3.0,
     -36.0
    ],
    "top": [
     -6.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -5.0,
     -70.0
    ],
    "head_box": [
     44,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -5.0,
     -36.0
    ],
    "top": [
     -7.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -3.0,
     -70.0
    ],
    "head_box": [
     46,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -4.0,
     -36.0
    ],
    "top": [
     -5.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     1.0,
     -70.5
    ],
    "head_box": [
     50,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -36.5
    ],
    "top": [
     -1.5,
     -60.5
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_recoil_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_box_recoil_glove_l4_disc": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_box_recoil_glove_l4_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     1.0,
     -62.0
    ],
    "hand_front": [
     9.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     2.0,
     -62.0
    ],
    "hand_front": [
     10.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     3.5,
     -61.5
    ],
    "hand_front": [
     12.0,
     -59.0
    ]
   },
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque Boxe: empurrado para trás (ele empurrou / ENCOSTOU em você)."
 },
 "fight_player_spar_box_recoil_glove_l4_disc_layered": {
  "action": "spar_box_recoil",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_box_recoil_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_box_recoil_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_box_recoil_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -4.0,
     -69.0
    ],
    "head_box": [
     45,
     22,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -3.0,
     -36.0
    ],
    "top": [
     -6.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -5.0,
     -70.0
    ],
    "head_box": [
     44,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -5.0,
     -36.0
    ],
    "top": [
     -7.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     -3.0,
     -70.0
    ],
    "head_box": [
     46,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -4.0,
     -36.0
    ],
    "top": [
     -5.0,
     -60.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     1.0,
     -70.5
    ],
    "head_box": [
     50,
     21,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -36.5
    ],
    "top": [
     -1.5,
     -60.5
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     44,
     20,
     23,
     16
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_box_recoil_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_take_disc": {
  "action": "spar_jj_take",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_take_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     19.6444444444444,
     -54.9888888888889
    ],
    "hand_front": [
     25.5833333333333,
     -59.6444444444444
    ]
   },
   {
    "hand_back": [
     28.4311111111111,
     -51.3822222222222
    ],
    "hand_front": [
     32.5333333333333,
     -60.6311111111111
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: da guarda para a pegada (gola + manga). Tocar AO CONTRÁRIO ao soltar."
 },
 "fight_player_spar_jj_take_disc_layered": {
  "action": "spar_jj_take",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_take_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.44444274902344,
     -68.7777786254883
    ],
    "head_box": [
     58,
     22,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.11111068725586,
     -35.8888893127441
    ],
    "top": [
     6.44444274902344,
     -59.3333320617676
    ],
    "tw": 0.577777777777778,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     12.1111145019531,
     -67.4444427490234
    ],
    "head_box": [
     61,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.77777862548828,
     -35.2222213745117
    ],
    "top": [
     9.11111450195313,
     -58.3333320617676
    ],
    "tw": 0.744444444444444,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_take_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_take_glove_l1_disc": {
  "action": "spar_jj_take",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_take_glove_l1_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     19.6444444444444,
     -54.9888888888889
    ],
    "hand_front": [
     25.5833333333333,
     -59.6444444444444
    ]
   },
   {
    "hand_back": [
     28.4311111111111,
     -51.3822222222222
    ],
    "hand_front": [
     32.5333333333333,
     -60.6311111111111
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: da guarda para a pegada (gola + manga). Tocar AO CONTRÁRIO ao soltar."
 },
 "fight_player_spar_jj_take_glove_l1_disc_layered": {
  "action": "spar_jj_take",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_take_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.44444274902344,
     -68.7777786254883
    ],
    "head_box": [
     58,
     22,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.11111068725586,
     -35.8888893127441
    ],
    "top": [
     6.44444274902344,
     -59.3333320617676
    ],
    "tw": 0.577777777777778,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     12.1111145019531,
     -67.4444427490234
    ],
    "head_box": [
     61,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.77777862548828,
     -35.2222213745117
    ],
    "top": [
     9.11111450195313,
     -58.3333320617676
    ],
    "tw": 0.744444444444444,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_take_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_take_glove_l2_disc": {
  "action": "spar_jj_take",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_take_glove_l2_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     19.6444444444444,
     -54.9888888888889
    ],
    "hand_front": [
     25.5833333333333,
     -59.6444444444444
    ]
   },
   {
    "hand_back": [
     28.4311111111111,
     -51.3822222222222
    ],
    "hand_front": [
     32.5333333333333,
     -60.6311111111111
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: da guarda para a pegada (gola + manga). Tocar AO CONTRÁRIO ao soltar."
 },
 "fight_player_spar_jj_take_glove_l2_disc_layered": {
  "action": "spar_jj_take",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_take_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.44444274902344,
     -68.7777786254883
    ],
    "head_box": [
     58,
     22,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.11111068725586,
     -35.8888893127441
    ],
    "top": [
     6.44444274902344,
     -59.3333320617676
    ],
    "tw": 0.577777777777778,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     12.1111145019531,
     -67.4444427490234
    ],
    "head_box": [
     61,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.77777862548828,
     -35.2222213745117
    ],
    "top": [
     9.11111450195313,
     -58.3333320617676
    ],
    "tw": 0.744444444444444,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_take_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_take_glove_l3_disc": {
  "action": "spar_jj_take",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_take_glove_l3_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     19.6444444444444,
     -54.9888888888889
    ],
    "hand_front": [
     25.5833333333333,
     -59.6444444444444
    ]
   },
   {
    "hand_back": [
     28.4311111111111,
     -51.3822222222222
    ],
    "hand_front": [
     32.5333333333333,
     -60.6311111111111
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: da guarda para a pegada (gola + manga). Tocar AO CONTRÁRIO ao soltar."
 },
 "fight_player_spar_jj_take_glove_l3_disc_layered": {
  "action": "spar_jj_take",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_take_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.44444274902344,
     -68.7777786254883
    ],
    "head_box": [
     58,
     22,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.11111068725586,
     -35.8888893127441
    ],
    "top": [
     6.44444274902344,
     -59.3333320617676
    ],
    "tw": 0.577777777777778,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     12.1111145019531,
     -67.4444427490234
    ],
    "head_box": [
     61,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.77777862548828,
     -35.2222213745117
    ],
    "top": [
     9.11111450195313,
     -58.3333320617676
    ],
    "tw": 0.744444444444444,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_take_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_take_glove_l4_disc": {
  "action": "spar_jj_take",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_take_glove_l4_disc.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     5.0,
     -61.0
    ],
    "hand_front": [
     14.0,
     -58.0
    ]
   },
   {
    "hand_back": [
     19.6444444444444,
     -54.9888888888889
    ],
    "hand_front": [
     25.5833333333333,
     -59.6444444444444
    ]
   },
   {
    "hand_back": [
     28.4311111111111,
     -51.3822222222222
    ],
    "hand_front": [
     32.5333333333333,
     -60.6311111111111
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: da guarda para a pegada (gola + manga). Tocar AO CONTRÁRIO ao soltar."
 },
 "fight_player_spar_jj_take_glove_l4_disc_layered": {
  "action": "spar_jj_take",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_take_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_take_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_take_disc_front.png",
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
   5.0,
   -82.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     5.0,
     -71.0
    ],
    "head_box": [
     54,
     20,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -37.0
    ],
    "top": [
     2.0,
     -61.0
    ],
    "tw": 0.3,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     9.44444274902344,
     -68.7777786254883
    ],
    "head_box": [
     58,
     22,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.11111068725586,
     -35.8888893127441
    ],
    "top": [
     6.44444274902344,
     -59.3333320617676
    ],
    "tw": 0.577777777777778,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     12.1111145019531,
     -67.4444427490234
    ],
    "head_box": [
     61,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     1.77777862548828,
     -35.2222213745117
    ],
    "top": [
     9.11111450195313,
     -58.3333320617676
    ],
    "tw": 0.744444444444444,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     54,
     20,
     21,
     18
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_take_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_grip_disc": {
  "action": "spar_jj_grip",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_grip_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ parado com a pegada (respira)."
 },
 "fight_player_spar_jj_grip_disc_layered": {
  "action": "spar_jj_grip",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_grip_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_grip_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_grip_glove_l1_disc": {
  "action": "spar_jj_grip",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_grip_glove_l1_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ parado com a pegada (respira)."
 },
 "fight_player_spar_jj_grip_glove_l1_disc_layered": {
  "action": "spar_jj_grip",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_grip_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_grip_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_grip_glove_l2_disc": {
  "action": "spar_jj_grip",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_grip_glove_l2_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ parado com a pegada (respira)."
 },
 "fight_player_spar_jj_grip_glove_l2_disc_layered": {
  "action": "spar_jj_grip",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_grip_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_grip_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_grip_glove_l3_disc": {
  "action": "spar_jj_grip",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_grip_glove_l3_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ parado com a pegada (respira)."
 },
 "fight_player_spar_jj_grip_glove_l3_disc_layered": {
  "action": "spar_jj_grip",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_grip_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_grip_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_grip_glove_l4_disc": {
  "action": "spar_jj_grip",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_grip_glove_l4_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.12,
     -50.28
    ],
    "hand_front": [
     35.0,
     -61.0
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ parado com a pegada (respira)."
 },
 "fight_player_spar_jj_grip_glove_l4_disc_layered": {
  "action": "spar_jj_grip",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_grip_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_grip_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_grip_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -68.0
    ],
    "head_box": [
     62,
     23,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -59.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     23,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_grip_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_pull_disc": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_pull_disc.png",
  "fps": 8.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   },
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ segurando = puxa (loop enquanto segura)."
 },
 "fight_player_spar_jj_pull_disc_layered": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "fps": 8.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_pull_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_front.png",
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
   8.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_pull_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_pull_glove_l1_disc": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_pull_glove_l1_disc.png",
  "fps": 8.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   },
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ segurando = puxa (loop enquanto segura)."
 },
 "fight_player_spar_jj_pull_glove_l1_disc_layered": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "fps": 8.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_pull_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_front.png",
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
   8.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_pull_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_pull_glove_l2_disc": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_pull_glove_l2_disc.png",
  "fps": 8.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   },
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ segurando = puxa (loop enquanto segura)."
 },
 "fight_player_spar_jj_pull_glove_l2_disc_layered": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "fps": 8.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_pull_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_front.png",
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
   8.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_pull_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_pull_glove_l3_disc": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_pull_glove_l3_disc.png",
  "fps": 8.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   },
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ segurando = puxa (loop enquanto segura)."
 },
 "fight_player_spar_jj_pull_glove_l3_disc_layered": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "fps": 8.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_pull_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_front.png",
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
   8.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_pull_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_pull_glove_l4_disc": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_pull_glove_l4_disc.png",
  "fps": 8.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   },
   {
    "hand_back": [
     26.49,
     -50.97
    ],
    "hand_front": [
     30.66,
     -59.77
    ]
   },
   {
    "hand_back": [
     24.62,
     -50.15
    ],
    "hand_front": [
     28.66,
     -59.53
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ segurando = puxa (loop enquanto segura)."
 },
 "fight_player_spar_jj_pull_glove_l4_disc_layered": {
  "action": "spar_jj_pull",
  "facing": "direita",
  "fps": 8.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_pull_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_pull_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_pull_disc_front.png",
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
   8.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     8.0,
     -69.0
    ],
    "head_box": [
     57,
     22,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -1.0,
     -35.0
    ],
    "top": [
     5.0,
     -59.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     6.0,
     -68.0
    ],
    "head_box": [
     55,
     23,
     13,
     14
    ],
    "head_box_max": [
     55,
     22,
     15,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     -2.0,
     -34.0
    ],
    "top": [
     3.0,
     -58.0
    ],
    "tw": 0.4,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_pull_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_release_disc": {
  "action": "spar_jj_release",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_release_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ solto (recupera o fôlego), perto dele."
 },
 "fight_player_spar_jj_release_disc_layered": {
  "action": "spar_jj_release",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_release_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_front.png",
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
   10.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_release_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_release_glove_l1_disc": {
  "action": "spar_jj_release",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_release_glove_l1_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ solto (recupera o fôlego), perto dele."
 },
 "fight_player_spar_jj_release_glove_l1_disc_layered": {
  "action": "spar_jj_release",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_release_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_front.png",
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
   10.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_release_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_release_glove_l2_disc": {
  "action": "spar_jj_release",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_release_glove_l2_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ solto (recupera o fôlego), perto dele."
 },
 "fight_player_spar_jj_release_glove_l2_disc_layered": {
  "action": "spar_jj_release",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_release_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_front.png",
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
   10.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_release_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_release_glove_l3_disc": {
  "action": "spar_jj_release",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_release_glove_l3_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ solto (recupera o fôlego), perto dele."
 },
 "fight_player_spar_jj_release_glove_l3_disc_layered": {
  "action": "spar_jj_release",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_release_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_front.png",
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
   10.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_release_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_release_glove_l4_disc": {
  "action": "spar_jj_release",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_release_glove_l4_disc.png",
  "fps": 5.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "hands": [
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   },
   {
    "hand_back": [
     15.0,
     -53.0
    ],
    "hand_front": [
     21.0,
     -52.0
    ]
   }
  ],
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ solto (recupera o fôlego), perto dele."
 },
 "fight_player_spar_jj_release_glove_l4_disc_layered": {
  "action": "spar_jj_release",
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_release_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_release_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_release_disc_front.png",
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
   10.0,
   -80.0
  ],
  "anchors": [
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -70.0
    ],
    "head_box": [
     59,
     21,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -60.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   },
   {
    "face": "tired",
    "head": [
     10.0,
     -69.0
    ],
    "head_box": [
     59,
     22,
     13,
     14
    ],
    "head_box_max": [
     59,
     21,
     13,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -36.0
    ],
    "top": [
     7.0,
     -59.0
    ],
    "tw": 0.5,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_release_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_yanked_disc": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_yanked_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     36.0,
     -50.0
    ],
    "hand_front": [
     39.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     34.18,
     -50.09
    ],
    "hand_front": [
     37.425,
     -60.48
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: segurou na PUXADA FORTE dele e foi puxado meio passo."
 },
 "fight_player_spar_jj_yanked_disc_layered": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_yanked_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     18.0,
     -66.0
    ],
    "head_box": [
     67,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -35.0
    ],
    "top": [
     15.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     16.5,
     -66.5
    ],
    "head_box": [
     66,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.5,
     -35.0
    ],
    "top": [
     13.5,
     -57.5
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_yanked_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_yanked_glove_l1_disc": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_yanked_glove_l1_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     36.0,
     -50.0
    ],
    "hand_front": [
     39.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     34.18,
     -50.09
    ],
    "hand_front": [
     37.425,
     -60.48
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: segurou na PUXADA FORTE dele e foi puxado meio passo."
 },
 "fight_player_spar_jj_yanked_glove_l1_disc_layered": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_yanked_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     18.0,
     -66.0
    ],
    "head_box": [
     67,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -35.0
    ],
    "top": [
     15.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     16.5,
     -66.5
    ],
    "head_box": [
     66,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.5,
     -35.0
    ],
    "top": [
     13.5,
     -57.5
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_yanked_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_yanked_glove_l2_disc": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_yanked_glove_l2_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     36.0,
     -50.0
    ],
    "hand_front": [
     39.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     34.18,
     -50.09
    ],
    "hand_front": [
     37.425,
     -60.48
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: segurou na PUXADA FORTE dele e foi puxado meio passo."
 },
 "fight_player_spar_jj_yanked_glove_l2_disc_layered": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_yanked_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     18.0,
     -66.0
    ],
    "head_box": [
     67,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -35.0
    ],
    "top": [
     15.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     16.5,
     -66.5
    ],
    "head_box": [
     66,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.5,
     -35.0
    ],
    "top": [
     13.5,
     -57.5
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_yanked_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_yanked_glove_l3_disc": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_yanked_glove_l3_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     36.0,
     -50.0
    ],
    "hand_front": [
     39.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     34.18,
     -50.09
    ],
    "hand_front": [
     37.425,
     -60.48
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: segurou na PUXADA FORTE dele e foi puxado meio passo."
 },
 "fight_player_spar_jj_yanked_glove_l3_disc_layered": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_yanked_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     18.0,
     -66.0
    ],
    "head_box": [
     67,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -35.0
    ],
    "top": [
     15.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     16.5,
     -66.5
    ],
    "head_box": [
     66,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.5,
     -35.0
    ],
    "top": [
     13.5,
     -57.5
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_yanked_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fight_player_spar_jj_yanked_glove_l4_disc": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "file": "res://assets/sprites/fight/fight_player_spar_jj_yanked_glove_l4_disc.png",
  "fps": 14.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hands": [
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   },
   {
    "hand_back": [
     36.0,
     -50.0
    ],
    "hand_front": [
     39.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     37.0,
     -50.0
    ],
    "hand_front": [
     40.0,
     -60.0
    ]
   },
   {
    "hand_back": [
     34.18,
     -50.09
    ],
    "hand_front": [
     37.425,
     -60.48
    ]
   },
   {
    "hand_back": [
     31.36,
     -50.18
    ],
    "hand_front": [
     34.85,
     -60.96
    ]
   }
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "who": "discipulo",
  "note": "Fase 7a2: Choque JJ: segurou na PUXADA FORTE dele e foi puxado meio passo."
 },
 "fight_player_spar_jj_yanked_glove_l4_disc_layered": {
  "action": "spar_jj_yanked",
  "facing": "direita",
  "fps": 14.0,
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
  "file": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fight_player_spar_jj_yanked_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fight_player_spar_jj_yanked_disc_front.png",
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
   13.0,
   -78.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     18.0,
     -66.0
    ],
    "head_box": [
     67,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     5.0,
     -35.0
    ],
    "top": [
     15.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     20.0,
     -66.0
    ],
    "head_box": [
     69,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     7.0,
     -35.0
    ],
    "top": [
     17.0,
     -57.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "pain",
    "head": [
     16.5,
     -66.5
    ],
    "head_box": [
     66,
     25,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     4.5,
     -35.0
    ],
    "top": [
     13.5,
     -57.5
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     13.0,
     -67.0
    ],
    "head_box": [
     62,
     24,
     13,
     14
    ],
    "head_box_max": [
     62,
     24,
     20,
     15
    ],
    "head_rot": 0.0,
    "hip": [
     2.0,
     -35.0
    ],
    "top": [
     10.0,
     -58.0
    ],
    "tw": 0.8,
    "view": "side",
    "flipped": false
   }
  ],
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fight_player_spar_jj_yanked_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_idle_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_idle_disc.png",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_idle",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem parado: maço de panfletos no peito, mãos nuas (as 5 luvas dão o mesmo corpo). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_idle_disc_layered": {
  "action": "flyer_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_idle_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_idle_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_idle_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_idle_disc_front.png",
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
     13,
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
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     -58.0
    ],
    "head_box": [
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     13,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_idle_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_idle_glove_l1_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_idle_glove_l1_disc.png",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_idle",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem parado: maço de panfletos no peito, mãos nuas (as 5 luvas dão o mesmo corpo). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_idle_glove_l1_disc_layered": {
  "action": "flyer_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_idle_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_idle_disc_front.png",
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
     13,
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
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     -58.0
    ],
    "head_box": [
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     13,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_idle_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_idle_glove_l2_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_idle_glove_l2_disc.png",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_idle",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem parado: maço de panfletos no peito, mãos nuas (as 5 luvas dão o mesmo corpo). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_idle_glove_l2_disc_layered": {
  "action": "flyer_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_idle_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_idle_disc_front.png",
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
     13,
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
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     -58.0
    ],
    "head_box": [
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     13,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_idle_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_idle_glove_l3_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_idle_glove_l3_disc.png",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_idle",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem parado: maço de panfletos no peito, mãos nuas (as 5 luvas dão o mesmo corpo). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_idle_glove_l3_disc_layered": {
  "action": "flyer_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_idle_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_idle_disc_front.png",
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
     13,
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
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     -58.0
    ],
    "head_box": [
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     13,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_idle_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_idle_glove_l4_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_idle_glove_l4_disc.png",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_idle",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem parado: maço de panfletos no peito, mãos nuas (as 5 luvas dão o mesmo corpo). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_idle_glove_l4_disc_layered": {
  "action": "flyer_idle",
  "facing": "direita",
  "fps": 5.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 4,
  "loop": true,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_idle_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_idle_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_idle_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_idle_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_idle_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_idle_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_idle_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_idle_disc_front.png",
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
     13,
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
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     -58.0
    ],
    "head_box": [
     17,
     3,
     13,
     13
    ],
    "head_box_max": [
     17,
     3,
     13,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     13,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_idle_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_give_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_give_disc.png",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "hit_frame": 3.0,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_give",
  "who": "discipulo",
  "hand_flyer": [
   15,
   -41
  ],
  "note": "Fase 7a2: Panfletagem ACEITOU: tira um panfleto e estende para a frente (hit_frame = panfleto na mão estendida; soltar o ui_flyer_fly daí). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_give_disc_layered": {
  "action": "flyer_give",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_give_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_give_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_give_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_give_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_give_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_give_disc_front.png",
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
     4,
     15,
     13
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
     4,
     15,
     13
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
     2.0,
     -57.0
    ],
    "head_box": [
     18,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     2.0,
     -50.0
    ],
    "tw": 0.2,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
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
     4,
     15,
     13
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_give_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_give_glove_l1_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_give_glove_l1_disc.png",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "hit_frame": 3.0,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_give",
  "who": "discipulo",
  "hand_flyer": [
   15,
   -41
  ],
  "note": "Fase 7a2: Panfletagem ACEITOU: tira um panfleto e estende para a frente (hit_frame = panfleto na mão estendida; soltar o ui_flyer_fly daí). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_give_glove_l1_disc_layered": {
  "action": "flyer_give",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_give_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_give_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_give_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_give_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_give_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_give_disc_front.png",
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
     4,
     15,
     13
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
     4,
     15,
     13
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
     2.0,
     -57.0
    ],
    "head_box": [
     18,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     2.0,
     -50.0
    ],
    "tw": 0.2,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
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
     4,
     15,
     13
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_give_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_give_glove_l2_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_give_glove_l2_disc.png",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "hit_frame": 3.0,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_give",
  "who": "discipulo",
  "hand_flyer": [
   15,
   -41
  ],
  "note": "Fase 7a2: Panfletagem ACEITOU: tira um panfleto e estende para a frente (hit_frame = panfleto na mão estendida; soltar o ui_flyer_fly daí). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_give_glove_l2_disc_layered": {
  "action": "flyer_give",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_give_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_give_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_give_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_give_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_give_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_give_disc_front.png",
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
     4,
     15,
     13
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
     4,
     15,
     13
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
     2.0,
     -57.0
    ],
    "head_box": [
     18,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     2.0,
     -50.0
    ],
    "tw": 0.2,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
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
     4,
     15,
     13
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_give_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_give_glove_l3_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_give_glove_l3_disc.png",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "hit_frame": 3.0,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_give",
  "who": "discipulo",
  "hand_flyer": [
   15,
   -41
  ],
  "note": "Fase 7a2: Panfletagem ACEITOU: tira um panfleto e estende para a frente (hit_frame = panfleto na mão estendida; soltar o ui_flyer_fly daí). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_give_glove_l3_disc_layered": {
  "action": "flyer_give",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_give_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_give_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_give_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_give_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_give_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_give_disc_front.png",
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
     4,
     15,
     13
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
     4,
     15,
     13
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
     2.0,
     -57.0
    ],
    "head_box": [
     18,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     2.0,
     -50.0
    ],
    "tw": 0.2,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
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
     4,
     15,
     13
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_give_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_give_glove_l4_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_give_glove_l4_disc.png",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "hit_frame": 3.0,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_give",
  "who": "discipulo",
  "hand_flyer": [
   15,
   -41
  ],
  "note": "Fase 7a2: Panfletagem ACEITOU: tira um panfleto e estende para a frente (hit_frame = panfleto na mão estendida; soltar o ui_flyer_fly daí). Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_give_glove_l4_disc_layered": {
  "action": "flyer_give",
  "facing": "direita",
  "fps": 12.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_give_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_give_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_give_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_give_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_give_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_give_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_give_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_give_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_give_disc_front.png",
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
     4,
     15,
     13
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
     4,
     15,
     13
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
     2.0,
     -57.0
    ],
    "head_box": [
     18,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
    ],
    "top": [
     2.0,
     -50.0
    ],
    "tw": 0.2,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     13
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
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
     4,
     15,
     13
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_give_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_miss_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_miss_disc.png",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_miss",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem NÃO, VALEU: oferece, a pessoa recusa, recolhe e dá de ombros. Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_miss_disc_layered": {
  "action": "flyer_miss",
  "facing": "direita",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_miss_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_miss_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_miss_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_miss_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_miss_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_miss_disc_front.png",
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
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -56.0
    ],
    "head_box": [
     17,
     5,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
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
    "face": "effort",
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
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     4,
     15,
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
     4,
     15,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_miss_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_miss_glove_l1_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_miss_glove_l1_disc.png",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_miss",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem NÃO, VALEU: oferece, a pessoa recusa, recolhe e dá de ombros. Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_miss_glove_l1_disc_layered": {
  "action": "flyer_miss",
  "facing": "direita",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l1_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_miss_glove_l1_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l1_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_miss_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_miss_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_miss_disc_front.png",
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
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -56.0
    ],
    "head_box": [
     17,
     5,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
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
    "face": "effort",
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
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     4,
     15,
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
     4,
     15,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_miss_glove_l1_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_miss_glove_l2_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_miss_glove_l2_disc.png",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_miss",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem NÃO, VALEU: oferece, a pessoa recusa, recolhe e dá de ombros. Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_miss_glove_l2_disc_layered": {
  "action": "flyer_miss",
  "facing": "direita",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l2_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_miss_glove_l2_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l2_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_miss_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_miss_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_miss_disc_front.png",
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
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -56.0
    ],
    "head_box": [
     17,
     5,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
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
    "face": "effort",
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
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     4,
     15,
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
     4,
     15,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_miss_glove_l2_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_miss_glove_l3_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_miss_glove_l3_disc.png",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_miss",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem NÃO, VALEU: oferece, a pessoa recusa, recolhe e dá de ombros. Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_miss_glove_l3_disc_layered": {
  "action": "flyer_miss",
  "facing": "direita",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l3_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_miss_glove_l3_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l3_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_miss_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_miss_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_miss_disc_front.png",
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
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -56.0
    ],
    "head_box": [
     17,
     5,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
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
    "face": "effort",
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
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     4,
     15,
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
     4,
     15,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_miss_glove_l3_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "fighter_flyer_miss_glove_l4_disc": {
  "facing": "direita",
  "file": "res://assets/sprites/characters/fighter_flyer_miss_glove_l4_disc.png",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "action": "flyer_miss",
  "who": "discipulo",
  "note": "Fase 7a2: Panfletagem NÃO, VALEU: oferece, a pessoa recusa, recolhe e dá de ombros. Tela: minigame_layout.flyers.fighter_spot (pivô nos pés)."
 },
 "fighter_flyer_miss_glove_l4_disc_layered": {
  "action": "flyer_miss",
  "facing": "direita",
  "fps": 10.0,
  "frame_size": [
   48,
   72
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   22.0,
   67.0
  ],
  "file": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l4_disc_body.png",
  "palette_swap": "disciple_palette",
  "same_as": "fighter_flyer_miss_glove_l4_disc",
  "who": "discipulo",
  "layers": {
   "body": "res://assets/sprites/disciple/fighter_flyer_miss_glove_l4_disc_body.png",
   "top": {
    "tank": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tank.png",
    "tee": "res://assets/sprites/disciple/fighter_flyer_miss_disc_top_tee.png"
   },
   "socks": "res://assets/sprites/disciple/fighter_flyer_miss_disc_socks.png",
   "school_symbol": {
    "chest": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_chest.png",
    "leg": "res://assets/sprites/disciple/fighter_flyer_miss_disc_symbol_leg.png"
   },
   "head": {
    "short": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_short.png",
    "buzz": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_buzz.png",
    "volume": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_volume.png",
    "bun": "res://assets/sprites/disciple/fighter_flyer_miss_disc_head_bun.png"
   },
   "band": "res://assets/sprites/disciple/fighter_flyer_miss_disc_band.png",
   "front_mask": "res://assets/sprites/disciple/fighter_flyer_miss_disc_front.png",
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
   -67.0
  ],
  "anchors": [
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     3.0,
     -57.0
    ],
    "head_box": [
     19,
     4,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     1.0,
     -31.0
    ],
    "top": [
     3.0,
     -50.0
    ],
    "tw": 0.4,
    "view": "34",
    "flipped": false
   },
   {
    "face": "normal",
    "head": [
     1.0,
     -56.0
    ],
    "head_box": [
     17,
     5,
     13,
     13
    ],
    "head_box_max": [
     17,
     4,
     15,
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
    "face": "effort",
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
     4,
     15,
     14
    ],
    "head_rot": 0.0,
    "hip": [
     0.0,
     -31.0
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
     4,
     15,
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
     4,
     15,
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
  "note": "Discípulo EM CAMADAS (Fase 7a2): mesmos quadros, fps, pivô, mãos e hit de fighter_flyer_miss_glove_l4_disc; montar na ordem de layers.order e trocar as cores-chave (by_data_id.disciple_palette). Símbolo R já no lado certo (folha não espelhada)."
 },
 "ped_estudante_false": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_estudante_false.png",
  "fps": 9.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SINAL FALSO: diminui, olha de relance (vira), desvia de cara fechada e acelera. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_estudante_flyer": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_estudante_flyer.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: ACEITOU: segue andando com o panfleto na mão, olhando para ele. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_estudante_pockets": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_estudante_pockets.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SEM INTERESSE (fone): fone de ouvido, mãos no bolso. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_estudante_refuse": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_estudante_refuse.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 5,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: NÃO, VALEU (clicou errado): para, levanta a mão espalmada, baixa e segue. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_estudante_tell": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_estudante_tell.png",
  "fps": 8.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "tell_loop": [
   3,
   5
  ],
  "note": "Fase 7a2: SINAL (interessado): diminui, para, vira para a câmera e estende a mão aberta. Quadros 3-5 em loop enquanto durar o sinal. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_estudante_walk": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_estudante_walk.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: Andar normal (8 quadros). Virar a folha para quem anda para a esquerda. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_moca_false": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_moca_false.png",
  "fps": 9.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SINAL FALSO: diminui, olha de relance (vira), desvia de cara fechada e acelera. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_moca_flyer": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_moca_flyer.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: ACEITOU: segue andando com o panfleto na mão, olhando para ele. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_moca_phone": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_moca_phone.png",
  "fps": 9.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SEM INTERESSE (celular): mão de perto segurando o celular na altura do peito, cabeça baixa, passo curto. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_moca_refuse": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_moca_refuse.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 5,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: NÃO, VALEU (clicou errado): para, levanta a mão espalmada, baixa e segue. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_moca_tell": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_moca_tell.png",
  "fps": 8.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "tell_loop": [
   3,
   5
  ],
  "note": "Fase 7a2: SINAL (interessado): diminui, para, vira para a câmera e estende a mão aberta. Quadros 3-5 em loop enquanto durar o sinal. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_moca_walk": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_moca_walk.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: Andar normal (8 quadros). Virar a folha para quem anda para a esquerda. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_senhora_crossed": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_senhora_crossed.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SEM INTERESSE (braço cruzado): braços cruzados no peito, cara séria. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_senhora_false": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_senhora_false.png",
  "fps": 9.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SINAL FALSO: diminui, olha de relance (vira), desvia de cara fechada e acelera. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_senhora_flyer": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_senhora_flyer.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: ACEITOU: segue andando com o panfleto na mão, olhando para ele. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_senhora_refuse": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_senhora_refuse.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 5,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: NÃO, VALEU (clicou errado): para, levanta a mão espalmada, baixa e segue. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_senhora_tell": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_senhora_tell.png",
  "fps": 8.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "tell_loop": [
   3,
   5
  ],
  "note": "Fase 7a2: SINAL (interessado): diminui, para, vira para a câmera e estende a mão aberta. Quadros 3-5 em loop enquanto durar o sinal. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_senhora_walk": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_senhora_walk.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: Andar normal (8 quadros). Virar a folha para quem anda para a esquerda. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_trabalhador_false": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_trabalhador_false.png",
  "fps": 9.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 7,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SINAL FALSO: diminui, olha de relance (vira), desvia de cara fechada e acelera. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_trabalhador_flyer": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_trabalhador_flyer.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: ACEITOU: segue andando com o panfleto na mão, olhando para ele. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_trabalhador_hurry": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_trabalhador_hurry.png",
  "fps": 15.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: SEM INTERESSE (pressa): passada longa, tronco à frente, braços balançando forte. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_trabalhador_refuse": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_trabalhador_refuse.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 5,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: NÃO, VALEU (clicou errado): para, levanta a mão espalmada, baixa e segue. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_trabalhador_tell": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_trabalhador_tell.png",
  "fps": 8.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 6,
  "loop": false,
  "pivot": [
   24,
   71
  ],
  "tell_loop": [
   3,
   5
  ],
  "note": "Fase 7a2: SINAL (interessado): diminui, para, vira para a câmera e estende a mão aberta. Quadros 3-5 em loop enquanto durar o sinal. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "ped_trabalhador_walk": {
  "facing": "direita",
  "file": "res://assets/sprites/minigame/ped_trabalhador_walk.png",
  "fps": 10.0,
  "frame_size": [
   48,
   76
  ],
  "frames": 8,
  "loop": true,
  "pivot": [
   24,
   71
  ],
  "note": "Fase 7a2: Andar normal (8 quadros). Virar a folha para quem anda para a esquerda. Virado para a direita; quem anda para a esquerda: espelhar a folha (pivô x 23).",
  "who": "pedestre"
 },
 "spar_partner_box_burst": {
  "action": "burst",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_box_burst.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "loop": true,
  "pivot": [
   56,
   98
  ],
  "note": "Fase 7a2: RAJADA (1,5 s): jab, direto, jab na linha da cintura, em loop. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_box_feint": {
  "action": "feint",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_box_feint.png",
  "fps": 12.0,
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
  "note": "Fase 7a2: FINTA: começa igual ao aviso e, na metade, abaixa o ombro e solta a guarda (sem soco). Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_box_idle": {
  "action": "idle",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_box_idle.png",
  "fps": 6.0,
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
  "note": "Fase 7a2: Choque Boxe parado (guarda, respiração). Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_box_pause": {
  "action": "pause",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_box_pause.png",
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
  "note": "Fase 7a2: PAUSA: guarda baixa, respira de boca aberta (janela do contragolpe). Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_box_push": {
  "action": "push",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_box_push.png",
  "fps": 16.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 6,
  "hit_frame": 2,
  "hit_point": [
   -34.0,
   -60.0
  ],
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "note": "Fase 7a2: Choque Boxe, 1 clique: jab curto que empurra (antecipação de 1 quadro, contato no 2, volta à guarda). Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_box_recoil": {
  "action": "recoil",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_box_recoil.png",
  "fps": 14.0,
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
  "note": "Fase 7a2: Empurrado para trás (encostaram em você): recua meio passo e volta. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_box_warn": {
  "action": "warn",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_box_warn.png",
  "fps": 10.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 3,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "note": "Fase 7a2: AVISO da rajada: ombro de trás recua, luva armada. Segurar o último quadro. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_feint": {
  "action": "feint",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_feint.png",
  "fps": 12.0,
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
  "note": "Fase 7a2: FINTA: afunda como na puxada forte e, na metade, sobe de novo sem puxar. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_grip": {
  "action": "grip",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_grip.png",
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
  "note": "Fase 7a2: Choque JJ parado com a pegada (respira). Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_pause": {
  "action": "pause",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_pause.png",
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
  "note": "Fase 7a2: PAUSA: solta a manga, só a gola presa, ombros caídos (janela do contragolpe). Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_pull": {
  "action": "pull",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_pull.png",
  "fps": 8.0,
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
  "note": "Fase 7a2: Choque JJ segurando = puxa (quadril para trás, cotovelos dobram, puxões curtos). Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_take": {
  "action": "take",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_take.png",
  "fps": 12.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 4,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "note": "Fase 7a2: Choque JJ: da guarda à pegada (gola + manga). Tocar AO CONTRÁRIO = soltar. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_warn": {
  "action": "warn",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_warn.png",
  "fps": 10.0,
  "frame_size": [
   112,
   104
  ],
  "frames": 3,
  "loop": false,
  "pivot": [
   56,
   98
  ],
  "note": "Fase 7a2: AVISO da puxada forte: afunda o quadril, carrega os cotovelos. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_yank": {
  "action": "yank",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_yank.png",
  "fps": 12.0,
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
  "note": "Fase 7a2: PUXADA FORTE: arranca para trás com o corpo todo e meio passo; segurar o último quadro até acabar. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 },
 "spar_partner_jj_yanked": {
  "action": "yanked",
  "facing": "esquerda",
  "file": "res://assets/sprites/minigame/spar_partner_jj_yanked.png",
  "fps": 14.0,
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
  "note": "Fase 7a2: Puxado para a frente (segurou na puxada forte dele): tropeça meio passo e volta. Virado para a ESQUERDA (o pivô continua 56,98).",
  "who": "parceiro"
 }
}
```

## minigame_layout (acrescentar)
```json
{
 "spar": {
  "player_actions": {
   "box": {
    "idle": "fight_player_spar_box_idle",
    "click": "fight_player_spar_box_push",
    "counter": "fight_player_spar_box_counter",
    "guard": "fight_player_spar_box_guard",
    "pushed": "fight_player_spar_box_recoil"
   },
   "jj": {
    "take": "fight_player_spar_jj_take",
    "release": "fight_player_spar_jj_take (ao contrário)",
    "grip": "fight_player_spar_jj_grip",
    "hold": "fight_player_spar_jj_pull",
    "free": "fight_player_spar_jj_release",
    "yanked": "fight_player_spar_jj_yanked"
   }
  },
  "player_sheet_note": "Ids sem o sufixo: o jogo acrescenta a luva (_glove_lN) e _disc / _disc_layered como nas ações da luta.",
  "partner_actions": {
   "box": {
    "idle": "spar_partner_box_idle",
    "push": "spar_partner_box_push",
    "recoil": "spar_partner_box_recoil",
    "warn": "spar_partner_box_warn",
    "burst": "spar_partner_box_burst",
    "pause": "spar_partner_box_pause",
    "feint": "spar_partner_box_feint"
   },
   "jj": {
    "take": "spar_partner_jj_take",
    "grip": "spar_partner_jj_grip",
    "pull": "spar_partner_jj_pull",
    "yanked": "spar_partner_jj_yanked",
    "warn": "spar_partner_jj_warn",
    "yank": "spar_partner_jj_yank",
    "pause": "spar_partner_jj_pause",
    "feint": "spar_partner_jj_feint"
   }
  },
  "partner_states": {
   "box": {
    "base": "idle (e push de vez em quando = base_push)",
    "warn": "warn (segurar o último quadro)",
    "burst": "burst (loop 1,5 s)",
    "pause": "pause (loop)",
    "feint": "feint (segurar o último quadro)",
    "pushed": "recoil",
    "reset": "idle"
   },
   "jj": {
    "base": "grip / pull",
    "warn": "warn",
    "burst": "yank (segurar o último quadro)",
    "pause": "pause",
    "feint": "feint",
    "pushed": "yanked",
    "reset": "take ao contrário + take"
   }
  },
  "draw_order": "Boxe: quem bate por cima (como na luta). JJ: o discípulo por cima (as luvas dele ficam na gola do parceiro)."
 },
 "flyers": {
  "fighter_actions": {
   "idle": "fighter_flyer_idle",
   "give": "fighter_flyer_give",
   "miss": "fighter_flyer_miss"
  },
  "pedestrian_types": [
   "estudante",
   "senhora",
   "trabalhador",
   "moca"
  ],
  "pedestrian_actions": {
   "estudante": {
    "walk": "ped_estudante_walk",
    "no": "ped_estudante_pockets",
    "tell": "ped_estudante_tell",
    "false": "ped_estudante_false",
    "refuse": "ped_estudante_refuse",
    "accepted": "ped_estudante_flyer"
   },
   "senhora": {
    "walk": "ped_senhora_walk",
    "no": "ped_senhora_crossed",
    "tell": "ped_senhora_tell",
    "false": "ped_senhora_false",
    "refuse": "ped_senhora_refuse",
    "accepted": "ped_senhora_flyer"
   },
   "trabalhador": {
    "walk": "ped_trabalhador_walk",
    "no": "ped_trabalhador_hurry",
    "tell": "ped_trabalhador_tell",
    "false": "ped_trabalhador_false",
    "refuse": "ped_trabalhador_refuse",
    "accepted": "ped_trabalhador_flyer"
   },
   "moca": {
    "walk": "ped_moca_walk",
    "no": "ped_moca_phone",
    "tell": "ped_moca_tell",
    "false": "ped_moca_false",
    "refuse": "ped_moca_refuse",
    "accepted": "ped_moca_flyer"
   }
  },
  "pedestrian_frame": [
   48,
   76
  ],
  "pedestrian_pivot": [
   24,
   71
  ],
  "pedestrian_pivot_flipped": [
   23,
   71
  ],
  "pedestrian_head_top": -67,
  "pedestrian_note": "Quem quer: walk -> tell (quadros 0-2 uma vez, 3-5 em loop enquanto durar o tell_s) -> walk; clicou certo: flyer até sair. Quem não quer: a folha 'no' do tipo a travessia toda (fone, braço cruzado, pressa, celular). Sinal falso: walk -> false -> walk. Clicou errado: refuse -> volta ao que fazia. O ? (ui_tell_mark) fica em y = pés - 71."
 }
}
```
