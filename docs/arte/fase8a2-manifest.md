# Fase 8a2: Centro de Treinamento Raízes (arte e entradas do manifest)

Diretor de Arte, 2026-11-22. Gerador: `tools/art/make_arte_fase8a2.gd` (headless; `-- --no-assets` só refaz os mockups).
Registro: `python tools/art/manifest_8a2.py` (lê `tools/art/fase8a2_sprites.json`; idempotente; tab/CRLF). Os alunos são do
Artista de Personagens (`manifest_8a2_personagens.py`; pontos do centro já gravados no `fase8a2_personagens.json`, então rodar
os dois em qualquer ordem dá o mesmo manifest). Direção: `direcao-visual.md` §35. Tudo placeholder por código, original.

## Mockups (`docs/arte/mockups/`)
| Arquivo | O quê |
|---|---|
| `fase8a2_centro_cheia_boxe(_x2).png`, `..._fixado_x2.png` | centro cheio (Boxe: pera na parede), 4 alunos, painel solto e fixado |
| `fase8a2_centro_chegada(_x2).png` | chegada (Muay Thai: saco comprido deitado), 1 aluno |
| `fase8a2_centro_cheia_jiujitsu_envelope(_x2).png` | Jiu-jitsu (boneco no tatame) com o envelope PROPOSTA no chão |
| `fase8a2_centro_conferencia_x2.png` | ocupação de tudo (todos os quadros), zona do alvo, borda do painel fixado |
| `fase8a2_fundo_centro(_x2).png` | só o fundo |
| `fase8a2_aparelhos_x2.png` | academia x centro, as 37 folhas |
| `fase8a2_cartaz_vencido.png` | cartaz da liga vencido na academia, sem e com a marca, zooms |
| `fase8a2_canto_memoria_x4.png` | recorte emoldurado + foto torta |
| `fase8a2_patrocinio.png`, `fase8a2_envelope_locais_x2.png` | marca, remendo do calção, envelope nos 3 locais |

## Sprites novos
| id | Tamanho | Onde / regra |
|---|---|---|
| `center_bg` | 640x360 | `by_data_id.center.bg`, (0,0), z -100 |
| `center_led` | 40x8, 2 quadros | só a falha (o fundo já tem os 4 acesos); `light_positions` |
| `<aparelho>_l0|l1_<folha>_center` (37) | iguais às da academia/garagem | `suffix: "_center"`; saco idle/hit/side, corda idle/swing/swing_back, esteira idle/run/side, pera idle/hit/wall/wall_swing, boneco idle/hit/rest, saco comprido idle/hit/rest. Mesma forma, pivô, `positions`, `sort_y`, anim |
| `wall_clipping_regional_framed` | 36x36 | `layout.center_clipping_spot` (78,96), hover `regional_clipping` |
| `wall_photo_old_center` (atalho p/ `wall_photo_old_gym`) | 18x21 | `layout.center_photo_spot` (120,104), **quadro 1 (torta)**, hover `old_photo_center` |
| `wall_poster_league_regional_won_gym` | 42x58, 2 quadros | mesmo canto (412,54); 0 = vencido, 1 = vencido + marca |
| `ui_poster_league_regional_won_zoom` | 124x160, 2 quadros | zoom opcional |
| `ui_clipping_regional_zoom` | 124x92 | zoom opcional do recorte |
| `sponsor_vale` / `_wide` / `_9` | 20x20 / 89x20 / 9x9 | contrato, título, linha da vitória |
| `sponsor_vale_patch` | 5x3, pivô (2,0) | calção: `anchors[q].hip + (-2,+3)`, espelhar x se virado, abaixo do `front_mask` |
| `sponsor_envelope` | 16x11, 3 quadros | `layout.sponsor_envelope_spot` (250,302) **nos 3 locais**, camada do chão |
| `icon_students` | 16x16 | `by_data_id.center_students.icon` (painel EQUIPE) |
| `icon_region_center(_9)`, `ui_map_region_label_center`, `map_tile_center_region`, `map_node_s|b_owned_steel` | | região CENTRO do mapa (tom `steel`) |
| atalhos `_center` | — | `coach_idle|talk_center`, `garage_crate_center`, `wall_mural_center`, `wall_clipping_black_cat_center`, `icon_location_center` (mesmo arquivo da academia) |

## Pontos da sala do centro
Iguais aos da academia (6d2): Osmar (196,236), John/caixote (132,254)/(116,234), 2º mentor (62,256), equipe antiga
(`people_pos`), saco (336,183), saco de lado (258,160), corda no gancho (296,166), pera na parede (436,46), esteira (466,324),
arte deitada (192,318), caixas (`box_slots`), Metrônomo (240,118), mural (176,128), recorte do vulto (340,60).
Novos: alunos `student_1` (390,250) sombra, `student_2` (436,257) corda, `student_3` (530,316) corrida, `student_4` (24,300)
joelhada; cada um no lado da própria folha (sem espelhar: o R do peito continua legível). Recorte emoldurado (78,96), foto torta
(120,104), envelope (250,302).
**Conferência (gerador):** 0 problemas: nenhum pixel dos alunos, do recorte, da foto ou do envelope encosta em pessoa, caixa ou
aparelho (todos os quadros, com Boxe, Jiu-jitsu e Muay Thai), nada na zona do alvo nem na faixa de baixo, parede lisa atrás do
recorte e da foto, envelope em chão livre na garagem, na academia e no centro. Aviso aceito: `student_3` fica atrás do painel
fixado (como o vizinho 3 e o Nelson na 6d2). Os pontos propostos pelo Artista (150,258)/(232,254) batiam no caixote do John e no
saco de lado; (438,254)/(500,260) no tio 2.

## Para o Programador / UI/UX (não é meu, só o que a arte pede)
1. `sala.gd`: no centro, a lâmpada **não** aparece (`no_lamp`; hoje ela some só quando `light == "gym_tube"`); os objetos de parede
   que hoje testam `local_id == "gym"` (foto, mural, recorte do vulto, cartaz) precisam do ramo `center` com os pontos acima; a foto
   no centro usa o quadro 1 (torta). O cartaz da liga **não** aparece no centro.
2. Pera, boneco e saco comprido no foco: a sala chama `*_idle`/`*_hit` sem sufixo; passar por `UiTema.com_local` para pegar o `_center`.
3. **Mapa (bug latente):** a região nova se chama `center`, e `janela_mapa.gd` já usa a chave `center` para a cortiça do miolo
   (`reg in CENTRO -> chave = "center"`). Com a região CENTRO fechada, `aberta["center"] = false` pinta o miolo como parede. Usar
   `map_tile_center_region` para a região e separar as chaves (ver `skill_map.region_tiles`). `ORDEM_REGIOES` precisa do `center`.
4. **Achado da 8a1 (academia, Boxe):** a pera na parede (436,46) e o cartaz da liga (412,54) se sobrepõem em **538 px** (cartaz da
   8a1 e o vencido). Proposta: mover a pera na academia para a parede do pilar direito ou o cartaz para outro trecho de parede lisa; precisa de decisão
   (não mexi em pontos da academia nesta fase).

## Placeholder / precisa de pixel artist
- O fundo é montagem por código (blocos, janelas com reflexo em diagonal, vitrine simples). À mão: concreto com textura, treliça
  de verdade, vitrine com volume, luz do dia entrando em feixe.
- Os aparelhos do centro são troca de material sobre a forma da academia (pedido do escopo). Um artista daria forma nova a cada um
  (painel da esteira, plataforma de pera maior, corrente de navio no saco de lona).
- O recorte tem uma silhueta de 7 px; o remendo do calção é uma etiqueta de 5x3 (só "lê" como marca no contexto).
