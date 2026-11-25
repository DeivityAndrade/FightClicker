# Ronda Noturna do Gato Preto: elenco (vulto e ladrões) no manifest

Artista de Personagens, 2026-11-25. Skill `padrao-personagem`. Direção: `direcao-visual.md` §36.2 (traje) e §29.2 (o R).
A amostra do vulto foi **aprovada pelo dono com a faixa VERMELHA** (constante `BAND` no gerador).

- Gerador: `tools/art/make_sprites_ronda.gd` (headless, de uma pasta temporária com `project.godot` vazio e APPDATA temporário):
  `godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_sprites_ronda.gd -- <repo> <saida> [<folha.png>] [<seq_antes>]`.
  Grava em `<saida>/minigame/` (copiar para `assets/sprites/minigame/` e rodar `--import` headless), `<saida>/ronda_personagens.json`
  (copiar para `tools/art/`) e a folha de conferência (`docs/arte/mockups/ronda_elenco.png`).
- Registro: `python tools/art/manifest_ronda_personagens.py` (idempotente; relê o manifest logo antes de gravar; recusa gravar se
  faltar algum PNG; apaga `ronda_vulto_*`/`ronda_thief_*` que saírem do gerador; não mexe nas chaves do Diretor de Arte).
- O gerador da amostra (`make_sprites_ronda_vulto.gd`) fica só como histórico da amostra aprovada; as folhas do jogo saem do novo.

## Regras comuns
- **Quadro 96x100, pivô (50,94) = chão entre os pés** em todas as folhas. Pés do vulto em `walk_y` (196) no muro, `land` no SUSTO e
  `rooftop_pose.feet` (552,114) no telhado; pés do ladrão em `occurrences.<id>.thief` (y 314).
- **Nada precisa de espelho.** O vulto olha para a DIREITA; o ladrão trabalha virado para a DIREITA (de costas para o vulto); a
  queda (`fall`) já vem virada para a ESQUERDA; a fuga (`flee`), para a DIREITA. **Nunca espelhar a folha do vulto** (o R não é
  simétrico, §29.2).
- Mapa estado → folha: `by_data_id.ronda_characters` (`vulto`, `vulto_by_state`, `thieves.<id>.<anim>`, `thief_by_state`).

## Vulto (o discípulo da vez com o traje), em camadas
| id | q | fps | loop | Uso |
|---|---|---|---|---|
| `ronda_vulto_sneak_idle` | 4 | 5 | sim | parado no muro (soltou o botão, ladrão de costas): agachado, respira 1 px, o vento mexe a faixa e a capa |
| `ronda_vulto_sneak_walk` | 6 | 10 | sim | segurando: passo agachado na ponta dos pés, **no lugar** (a tela move o x de start a end) |
| `ronda_vulto_freeze` | 2 | 4 | sim | estátua quando o ladrão olha: num pé só, patas no alto; só o pé no ar treme 1 px |
| `ronda_vulto_seen` | 4 | 10 | não, segura 3 | VISTO/ESCAPOU: leva um susto (garras), pula para trás e se encolhe atrás da capa (a tela recua o x nos q 1-2) |
| `ronda_vulto_roof` | 4 | 6 | sim | pose no telhado contra a lua, pés em (552,114) |
| `ronda_vulto_scare` | 7 | 12 | não, segura 5-6 | SUSTO: 0 antecipa, 1 impulso, 2 ápice, 3 descendo, 4 aterrissa, 5 SUSTO!, 6 segura. `air_frames` [1,2,3]: a tela leva o nó de (end, walk_y) até `land`. Garras nos q 2-6 |

**Montagem (igual ao discípulo, pelo `DiscVisual.textura(nome, look, simbolo)`):** `layers.order` = body → `top.<tank|tee>` (se
`look.top != none`) → `socks` (se `look.socks == on`) → `school_symbol.leg` (só se o lutador mostra o símbolo **e** está sem parte de
cima) → `head.<look.hair_style>` (o capuz: 4 variantes, uma por corte). Trocar as cores-chave pela `disciple_palette` (o R pela
`school_symbol_source.leg`). `file` = a camada body (chaves). Sem `band` (a faixa do traje é cor fixa e o capuz cobre a faixa do
discípulo), sem `front_mask` e **sem `school_symbol.chest`** (no perfil o carimbo do peito fica nas costas, que a capa cobre).
Conferência do gerador: montado pelas camadas == desenhado direto em 27 quadros x 4 discípulos (**0 px diferentes**).
Mãos nuas (sem luva de boxe à noite): nenhuma variante `_glove_lN`, e o remendo do patrocinador não entra (folha sem `anchors`).

## Ladrões (paleta fixa, corpo próprio)
| id | Quem |
|---|---|
| `tire` | baixinho largo: gorro de lã verde, bigode, regata encardida, bermuda jeans, chinelo; chave de roda em cruz no cubo do estepe (`ronda_prop_tire` em (212,314) = mão em (20,-10) do pivô) |
| `bike` | magrelo comprido: boné para trás, cavanhaque, corta-vento roxo, calça de moletom; alicate na corrente |
| `gate` | barrigudo careca de bigodão: camisa social cinza-azulada, jeans, botina; pé de cabra no portão |

Folhas `ronda_thief_<id>_<anim>`, uma por estado:
| anim | q | fps | loop | Estado |
|---|---|---|---|---|
| `work` | 4 | 6 | sim | TRABALHA (de costas) |
| `warn` | 2 | 4 | sim | AVISO: para, endireita e levanta a cabeça (o `ui_thief_warn` fica em cima) |
| `look` | 2 | 3 | sim | OLHANDO: vira a cabeça para trás, desconfiado |
| `fake` | 4 | 6 | não | aviso falso (portão, 30%): tapa no mosquito na nuca e volta (o último quadro = `work[0]`) |
| `fall` | 6 | 10 | não, segura 4-5 | SUSTO: pula de susto, vira para o vulto e **cai de bunda**; `dust_frame` 2 (`fx_dust_fall` nos pés); o prop voa no q 0 |
| `flee` | 4 | 12 | sim | fuga em pânico para a direita (depois do `fall`, e direto no VISTO) |

## O que mudou em relação ao parcial do WIP (63bedab) e à amostra
- **Garras do SUSTO:** mão aberta 7x7 com 4 dedos em leque, curvos, unha creme (antes 5x5 de pontinhos, lia como punho).
- **Capuz em 1x:** desce pela nuca e abre num colarinho sobre os ombros, com a beira clara da abertura até o queixo; o pescoço de
  pele sumiu. Antes acabava no queixo e lia "capacete com orelhas".
- **Capa:** 3 pregas em leque que saem franzidas do colarinho (crista `st1`, vão `d1`) e barra recortada que sobe nos vãos (antes:
  vincos aleatórios e barra serrilhada por ruído).
- **R de raiz** na coxa (camada `school_symbol.leg`), desenhado virado para a direita e nunca espelhado.
- Sombra do colarinho no corpo vai para body/top: montado == direto (antes 4 px; com o colarinho seriam 714).
- Estepe: o ladrão agacha perto do estepe (o braço de trás não alcançava o cubo); portão: camisa cinza-azulada (a marrom sumia na
  pele e lia "sem camisa"); braços na queda/fuga na medida de cada ladrão; nada encosta na borda do quadro.
- O gerador nunca tinha rodado (erro de tipo na linha da ferramenta): agora roda limpo.

## Para o UI/UX (`ui/tela_ronda.gd`)
- `NOMES_VULTO` → usar `by_data_id.ronda_characters.vulto_by_state` (`segurando`→`sneak_walk`, `parado`→`sneak_idle`,
  `ladrao_olhando_parado`→`freeze`, `visto`→`seen`, `susto`→`scare`, `fim`→`roof`) e montar com `DiscVisual.textura(...)`.
- `NOMES_LADRAO` → uma folha por estado: `thieves.<id>.<work|warn|look|fake|fall|flee>`.
- Ordem de desenho do §36 de `ronda-manifest.md` continua: vulto atrás do ladrão até o pulo, na frente a partir do q 1 do SUSTO.

## Ainda pede pixel artist humano
- Rostos de 2-4 px nos ladrões (o susto se lê mais pelo corpo do que pela cara); a cabeça virada no `look` é o mapa espelhado.
- Capa: as pregas são uma função, não pano desenhado quadro a quadro (no ar ela estica reta, sem dobra de vento de verdade).
- Garras: 7x7 legíveis em 1x, mas um artista faria a silhueta da mão por pose (hoje é o mesmo mapa girado 0/90°).
- O corpo dos ladrões sai do rig comum com medidas próprias: baixinho e magrelo **diferem na silhueta** e, pela regra do escopo,
  passam pela aprovação do dono (estão na folha `ronda_elenco.png`).
