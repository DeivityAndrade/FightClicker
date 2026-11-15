# Paletas finais da 6b1 (discípulo)

Dono: Diretor de Arte. Versão 1 (2026-11-14). Fecha o hex do `fase6b1-design.md` §6.3.
**Quem copia para `data/disciples.json`:** Designer/Programador (o Diretor de Arte não edita `data/`). Ids e quantidade não mudam.

## Pele `[sombra, base, luz]`
| Id | Sombra | Base | Luz | Mudou? |
|---|---|---|---|---|
| `skin_1` | `#a8684e` | `#e0a888` | `#f4d0b4` | não |
| `skin_2` | `#8f5238` | `#cc8c62` | `#eebd94` | não |
| `skin_3` | `#7a4632` sk0 | `#b9744f` sk1 | `#e3a275` sk2 | não (padrão, tokens) |
| `skin_4` | **`#5a3029`** | **`#8c5545`** | **`#b8806a`** | sim |
| `skin_5` | **`#422529`** | **`#73453f`** | **`#a06a5a`** | sim |

Por que mudou (diferença de cor medida em CIELAB, ΔE; abaixo de ~12 some em 1 px):
- `skin_5` alvo tinha a base `#6b3e2c` praticamente igual ao `br1` `#6b3f2a` (ΔE 2): cabelo `brown`/`dark_brown` e sobrancelha `copper` sumiam na testa. O degrau sombra→base era 13 (rampa achatada).
  Agora: base 1 passo mais clara e com fundo mais rosado (menos laranja que a madeira), sombra separada do `ink` (ΔE 19), degraus 19 e 17, `br1` ΔE 10→ cabelo `dark_brown` lê pelo contorno e pelo tom de baixo.
- `skin_4` alvo tinha a base quase igual ao `br2` (ΔE 7): cabelo `copper` virava careca. Mesmo ajuste (fundo um pouco mais frio): `br2` ΔE 15.
- `skin_4` × `skin_5` lado a lado: base ΔE 10 (claridade 42 × 35 + fundo diferente). Distinguem na tela de criação.
- Nenhuma pele chega perto do vermelho da luva: `r1`/`r2` ΔE ≥ 27 em todos os tons.

## Cabelo `[escuro, claro, sobrancelha]`
| Id | Tokens finais | Mudou? |
|---|---|---|
| `black` | `d1`, `g0`, `ink` | não |
| `dark_brown` | `br0`, `br1`, `ink` | não |
| `brown` | `br1`, `br2`, `br0` | não (padrão) |
| `copper` | `br2`, `br3`, **`br0`** | sobrancelha `br1` → `br0` |
| `blond` | `y0`, `y1`, **`br0`** | sobrancelha `br2` → `br0` |
| `platinum` | `g3`, `cream`, `g1` | não |

Regra: **sobrancelha nunca mais clara que `br0`** (exceto o `g1` do platinado, que é frio e separa de todas as peles, ΔE ≥ 24).
Com `br1`/`br2` a sobrancelha sumia nas peles 4 e 5 (ΔE 2 a 13). Com `br0` fica ΔE ≥ 20 na pior pele (`skin_5`) e loiro/ruivo de sobrancelha escura lê normal em 1 px.
- `copper` × `blond`: ΔE 31–35 entre os tons. `brown` × `copper`: ΔE 19 (um passo de rampa; o claro do copper é `br3`, que o brown não usa). Distinguem lado a lado.
- `black`/`dark_brown` sobre `skin_5`: o corte lê pelo contorno `ink` de fora e pelo `br0`/`d1` contra a pele (ΔE ≥ 20). O `br1` do castanho escuro fica perto (ΔE 10): por isso o `br1` vai só no brilho do topo, nunca na franja encostada na testa (vale para o Artista).

## Calção `[escuro, médio, claro, cós]`
Sem mudança: `green` (gr0..gr3, padrão), `blue` (b0..b3), `black` (d1, d2, g0, g2), `white` (g2, g3, cream, white), `purple` (p0, p1, p2, cream), `yellow` (br2, y0, y1, y2).
- Todos separam das 5 peles (ΔE ≥ 24 contra base/luz, fora o cós de 1 px do `white`/`purple`, que é `cream` e encosta na luz da `skin_1`: aceito, o cós tem contorno de sombra embaixo).
- Nenhum vermelho. O `black` é o que menos aparece no chão escuro da garagem (lê pelo cós `g2`); aceito.
- `blue` é o calção do John: fica (decisão do Designer); se a cena confundir, troca-se só no JSON.

## Para o Artista de Personagens
- Pinte a folha com as cores do `skin_3` + `brown` + `green` (as cores-chave da troca) e **não use essas cores em mais nada** da folha (luva, olho, boca), senão a troca pinta junto.
- Franja na testa: tom **escuro** do cabelo, não o claro.
