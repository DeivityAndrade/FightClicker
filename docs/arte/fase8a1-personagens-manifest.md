# Fase 8a1: adversários da liga regional (entradas para o manifest)

Artista de Personagens, pela skill `padrao-personagem`. Quem grava no `assets/sprites/manifest.json` é o
`python tools/art/manifest_8a1_personagens.py` (idempotente; `--check` só mostra; aceita outro caminho para testar numa cópia).
Ele lê `tools/art/fase8a1_personagens.json`: 114 entradas de `sprites` e 4 de `by_data_id` (`opp_reg_1`, `opp_reg_2`,
`opp_reg_3`, `opp_james`). Nenhum arquivo antigo foi sobrescrito. Folha de conferência: `docs/arte/mockups/fase8a1_personagens.png`.

## Contrato (igual aos 6 adversários de hoje)
- Quadro **112x104**, pivô **(56,98)**, `facing: esquerda`, `pos` (346,318). Trocar o adversário = trocar o prefixo do id.
- Cada um tem as **26 ações de sempre** (`idle jab heavy hit dodge block tired victory ko hit_body hit_head hit_up ko_back
  ko_knees fall ground_bottom_idle ground_hit ground_punch hit_clinch tap_out fall_spin held_clinch hit_leg hit_spin limp
  limp_heavy`) com os mesmos quadros, `hit_frame`, `hold_last` e `ground_frame` dos outros. Mãos e `hit_point` = do
  jogador × escala, espelhados (a mesma regra). A tela de luta funciona sem código novo.
- `by_data_id.<id>.actions.signature` = a pose de assinatura (a UI pode tocar `signature` sem saber o nome).
- `scale`: Bigorna 1,02 · Estaca 1,08 · Sabão 1,00 · **James 1,12** (pedido do Diretor de Cutscenes). O `head_point`
  padrão (4,−80) × escala serve para os 4 (a cabeça do James no idle fica 1 px acima, dentro da folga); não criei `head_point` próprio.
- Retrato do HUD: `portrait_<id>` 32x32, igual aos outros. O James usa `ui_portrait_frame_gold` (dono do cinturão).

## Quem é quem
| id | Silhueta | Roupa e paleta | Assinatura (ação nova) |
|---|---|---|---|
| `opp_reg_1` Zé Bigorna | baixo e largo, sem pescoço, queixo quadrado enorme, **guarda baixa** (mostra o queixo) | escovinha, regata vinho, calção preto com cós de aço, luva cor de aço | `shake_head` (10 q, 12 fps): leva no queixo, a cabeça vai e volta, sacode e bate a luva no queixo, rindo |
| `opp_reg_2` Tião Estaca | alto, pernas grossas, **base sempre larga** | careca de barba cheia, camiseta cinza-cimento manchada, calça de lona, botina, luva verde | `plant_feet` (9 q, 10 fps): os pés **não saem do lugar em nenhum quadro**; o quadril afunda, ele pesa por cima e empurra; poeira nos pés |
| `opp_reg_3` Rony Sabão | magro e solto, na ponta dos pés, mãos moles | gel no cabelo com rabicho, bigode fino, sem camisa, calção azul-claro, descalço, luva amarelo-sabão | `slip_clinch` (10 q, 14 fps): pego pela nuca, afunda, gira e escorrega 10 px para trás com bolhas; volta ao pivô |
| `opp_james` James Blindado | alto, ombros em V, peito estufado, queixo erguido | topete loiro, calção azul-marinho com cós dourado, bota branca, luva dourada | `guard`, `idle` próprio, `scorn`, `block` próprio (abaixo) |

## James (nomes do `docs/fases/fase8a1-cutscene-james.md` §5)
| Sprite | Quadros / fps | O que é |
|---|---|---|
| `opp_james_guard` | 4 / 6, loop | **guarda fechada** (Blindado, 1º round): as duas luvas na frente do queixo, cotovelos colados, os olhos aparecem por cima. Também é o J0 e o fim da apresentação |
| `opp_james_idle` | 4 / 5, loop | peito estufado, queixo erguido, mãos baixas, meio sorriso (substitui o idle do rig) |
| `opp_james_scorn` | 6 / 7 (0,86 s) | **gesto de desprezo**: olha a própria luva, tira um fiapo e dá um peteleco para trás, para longe do adversário (nunca para ele), com uma poeirinha. `peak_frame: 3` (o 4º quadro) = onde toca o `tap_glove` |
| `opp_james_block` | 3 / 14 | o soco bate na guarda fechada e ele recua 2 px sem abrir as luvas (substitui o block do rig) |
| `opp_james_victory` / `ko` / `tired` / `ko_back` | do rig | depois da derrota ele fica no chão (último quadro do `ko`, `hold_last`) ou cansado (`tired`) |
| `portrait_opp_james` | 32x32 | HUD da luta e prévia (meio sorriso) |
| `portrait_opp_james_dialog` | 48x48, 3 quadros | **caixa de diálogo**: busto 3/4 de roupão azul-marinho com debrum e brasão dourados, fundo transparente, mostrar em 2x. Quadro = expressão: 0 `smirk` (fala normal), 1 `sneer` (desprezo pela escola), 2 `laugh` (quando vence). Mapa: `faces` na entrada |

## Onde cada sinal entra (pedido à UI/UX; não mexi em `ui/`)
- **Bigorna, AGUENTOU!** (`opp_block` do Queixo de ferro): `signature` no lugar do `ko`/`hit_head`; e (só visual, §9.4) quando o
  embalo do jogador chega a 5.
- **Estaca, NÃO CAIU** (`opp_block` da Base larga): `signature` no lugar do `fall`, começando no `hit_frame` da queda do jogador.
  Na prancha ele aparece por cima do jogador (quem está por cima desenha depois).
- **Sabão, ESCAPOU!** (`opp_block` do Ensaboado): `signature` no lugar do `held_clinch`, a partir do `hit_frame` do `thai_clinch`.
- **James, 1º round:** `guard` no lugar do `idle` e `block` em todo acerto enquanto t < 5,33 s; `scorn` na apresentação e,
  se a UI quiser, quando a guarda abre ("A GUARDA ABRIU").

## Como foi gerado (dá para rodar de novo)
Poses em dados: `python tools/art/poses_8a1.py` → `tools/art/golpes_8a1_adv.json` (cada reação tem `who`);
retrato: `python tools/art/retrato_james_8a1.py` → `tools/art/retrato_james_8a1.json`. Numa pasta temporária com
`project.godot` vazio (nunca no projeto), APPDATA temporário, `--headless --max-fps 30`:
```
FC_GOLPES=<repo>/tools/art/<n>.json godot --headless --path <tmp> --script <repo>/tools/art/make_golpes_jogador.gd -- <tmp>/exp_<n> nada
   (n = golpes, golpes_7a1_adv, golpes_7b1_adv, golpes_8a1_adv: só expande as reações)
FIGHTCLICKER_ROOT=<repo>/ godot --headless --path <tmp> --script <repo>/tools/art/make_sprites_elenco.gd -- <tmp>/out <tmp>/old regional \
   <tmp>/exp_golpes/reacoes_expandidas.json <tmp>/exp_golpes_7a1_adv/reacoes_expandidas.json \
   <tmp>/exp_golpes_7b1_adv/reacoes_expandidas.json <tmp>/exp_golpes_8a1_adv/reacoes_expandidas.json \
   <repo>/tools/art/golpes_8a1_adv.json <repo>/tools/art/retrato_james_8a1.json
godot --headless --path <tmp> --script <repo>/tools/art/make_mockup_fase8a1_personagens.gd -- <repo> <tmp>/out <saida.png>
```
Depois copiar `<tmp>/out/opponents/*` para `assets/sprites/opponents/` e `<tmp>/out/fase8a1_personagens.json` para `tools/art/`.
Mudanças no `make_sprites_elenco.gd` só acrescentam (cabeças, fichas, modo `regional`); os modos antigos dão o mesmo resultado.

## Conferência
- 0 divergências de quadros/mãos; nenhuma mão fora da luva.
- Avisos de borda que **já existem no Seu Muralha** (mesma escala 1,12), idênticos pixel a pixel na contagem: a luva erguida do
  `victory` encosta na linha de cima e a bota encosta na lateral no fim do `ko_back` e do `fall_spin` do James.
- Alguns membros chegam 0,2–1 px além do alcance em poses extremas (vitória, chute da queda), como nos outros: o IK estica 1 px.
