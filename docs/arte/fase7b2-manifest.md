# Fase 7b2 — arte da 2ª passiva (Diretor de Arte)

Placeholder gerado por código, original. Regra visual em `direcao-visual.md` §33.
- Gerar de novo: `godot --headless --path <projeto> --script res://tools/art/make_arte_fase7b2.gd` (APPDATA temporário) e depois
  `python tools/art/manifest_7b2.py`. Textos dos letreiros: constantes `TXT_*` no topo do gerador.
- Todos em `assets/sprites/ui/`, folha horizontal (quadros lado a lado), filtro nearest, já importados (`.import`).
- No `assets/sprites/manifest.json`: `sprites.<id>` (tamanho, pivô, nota) e `by_data_id.passive_2_card`, `by_data_id.counter_hud`,
  `by_data_id.passive_2_banners`, `by_data_id.<boxing|bjj|muay_thai>.passive_2_icon(_9|_locked)`.

## Cartão da arte (2ª opção: cadeado e meta "{n}/3")
| id | Quadro | Quadros | Pivô | Onde a UI usa |
|---|---|---|---|---|
| `ui_passive_lock` | 9x12 | 3 (trancado cinza / clarão / aberto ouro) | 4,6 | à direita do nome da 2ª opção; 0→1→2 e some quando a meta bate |
| `ui_passive_progress_bar` | 8x6 | 1 | — | moldura 9-slice (2 px) da barra da meta, embaixo da linha "{n}/{m} {fim}" |
| `ui_passive_progress_fill` | 4x4 | 2 (enchendo / cheia) | — | repetido dentro da moldura; largura = interior × n/m; quadro 1 quando n ≥ m |
| `ui_passive_progress_tick` | 1x4 | 1 | — | divisória em cada 1/m da barra |
| `ui_passive_goal_pip` | 7x7 | 3 (falta / feita / acendendo) | 3,3 | alternativa à barra: m estrelas, passo 9 px |
O texto "{n}/{m} {fim}" (`art_card_passive_progress`) é da fonte do tema, em `y1`; nome trancado em `g1`.

## Ícones das 2ªs passivas
| id | Tamanho | Onde a UI usa |
|---|---|---|
| `passive_counter_punch` | 16x16 | Contragolpista (Boxe): cartão da arte, prévia, tela de fim (`passive2_unlocked_line`) |
| `passive_counter_punch_9` | 9x9 | linha da prévia, motivo da derrota, HUD |
| `passive_counter_punch_locked` | 16x16 | 2ª opção trancada |
| `passive_top_control` | 16x16 | Por cima (Jiu-jitsu): cartão, prévia, fim |
| `passive_top_control_9` | 9x9 | prévia, motivo, HUD "no chão" (`ground` = true) |
| `passive_top_control_locked` | 16x16 | 2ª opção trancada |
| `passive_thai_clinch` | 16x16 | Clinch (Muay Thai): cartão, prévia, fim |
| `passive_thai_clinch_9` | 9x9 | prévia, motivo, HUD aceso enquanto `clinch` = true |
| `passive_thai_clinch_locked` | 16x16 | 2ª opção trancada |
Os ids batem com `arts[].passive_2.icon` de `data/arts.json`.

## Carga do Contragolpista (HUD)
| id | Quadro | Quadros | Pivô | Onde a UI usa |
|---|---|---|---|---|
| `ui_charge_pip` | 9x9 | 4 (vazia / carregada / acendendo / cheia) | 4,4 | 3 losangos, passo 11 px, ao lado da SUA vida (sugestão: abaixo dela a partir de x 50, y 35); evento `charge` = quantos acesos; ao subir, quadro 2 por ~0,08 s e depois 1; com 3, alternar 1/3 a 6 fps |
| `icon_charge` | 9x9 | 1 | — | linha da prévia e motivo da derrota do Contragolpista |

## Letreiros
| id | Quadro (1x) | Pivô | Texto | Onde a UI usa |
|---|---|---|---|---|
| `ui_banner_counter_ko` | 209x68 (2 linhas) | 104,34 | K.O. NO CONTRAGOLPE! | fim com `finish = counter_ko`, (320,118) em 2x, no lugar do K.O.! |
| `ui_banner_ground_stop` | 209x40 | 104,20 | O JUIZ PAROU! | fim com `finish = ground_stop`, (320,118) 2x, no lugar do FINALIZOU! |
| `ui_banner_knee_ko` | 155x40 | 77,20 | JOELHADA! | fim com `finish = knee_ko`, (320,118) 2x, no lugar do K.O.! |
| `ui_banner_charge_full` | 70x28 | 35,14 | CARGA! | opcional: pisca com as 3 cargas cheias |
| `ui_banner_stood_up` | 102x28 | 51,14 | LEVANTOU | opcional: quando ele levanta no Por cima |
| `ui_banner_clinch` | 78x28 | 39,14 | CLINCH! | opcional: quando prende no clinch |
Mesma entrada do K.O.! (tremida de 2 px). Os pequenos podem ser trocados por texto do tema; se usados, 1x perto do HUD ou 2x perto do lutador (UI/UX).

## Animação
Nenhuma nova. Guarda alta = pose `block` existente (opcional do Artista de Personagens não feito).

## Mockups
- `docs/arte/mockups/fase7b2_pecas_x4.png` — todas as peças em 4x, comparadas com as da 1ª passiva.
- `docs/arte/mockups/fase7b2_cartao_x2.png` — sugestão das 2 opções no cartão (trancada 1/3, liberada 3/3, trancada 0/3).
- `docs/arte/mockups/fase7b2_letreiros.png` — os 3 letreiros em 2x nas duas arenas, com a guarda alta e as 3 cargas cheias.
