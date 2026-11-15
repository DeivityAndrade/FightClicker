# Fase 5.2: textos

Tom: humor de bairro. Nome ≤ 16, descrição ≤ 44, sem travessão. Substituem os "Provisório" de `data/shop.json`.

## Tabela

| Chave | Nome (≤16) | Descrição (≤44) |
|---|---|---|
| `glove_l3` | Luva de marca | Tem etiqueta e tudo. Parece até de rico. |
| `glove_l4` | Luva de torneio | Digna do Tonhão. O bairro pede autógrafo. |
| `crew_click` | Grito da equipe | Cada clique seu vale 1 s da equipe. |
| bolsa dourada | Bolsa da torcida | (sem descrição; vale o hover abaixo) |

Nota: o nome provisório "Luva de competição" tinha 18 caracteres; virou "Luva de torneio" (15).

## Textos de interface

- `shop_crew_click_effect`: `CLIQUE +{n} (1 S DA EQUIPE)` (27)
- `golden_crew_hover`: `{nome}: +{n} DE TREINO`
- `golden_crew_toast`: `A TORCIDA ENCHEU A BOLSA! +{n}` (31)
- `golden_crew_name`: `Bolsa da torcida` (16)
- Caixa da escola: etiqueta `LUVA MARCA` / `LUVA TORNEIO`; carimbo `ETIQUETA INTACTA` / `NÃO EMPRESTAR`.

## JSON pronto para colar

`data/shop.json` (apenas os campos de texto):

```json
{ "id": "glove_l3", "name": "Luva de marca", "description": "Tem etiqueta e tudo. Parece até de rico." },
{ "id": "glove_l4", "name": "Luva de torneio", "description": "Digna do Tonhão. O bairro pede autógrafo." },
{ "id": "crew_click", "name": "Grito da equipe", "description": "Cada clique seu vale 1 s da equipe." }
```

`data/ui_texts.json` (chaves novas; as duas últimas entram dentro de `box_label` e `box_stamp` existentes):

```json
"shop_crew_click_effect": "CLIQUE +{n} (1 S DA EQUIPE)",
"golden_crew_hover": "{nome}: +{n} DE TREINO",
"golden_crew_toast": "A TORCIDA ENCHEU A BOLSA! +{n}",
"golden_crew_name": "Bolsa da torcida",

"box_label": { "glove_l3": "LUVA MARCA", "glove_l4": "LUVA TORNEIO" },
"box_stamp": { "glove_l3": "ETIQUETA INTACTA", "glove_l4": "NÃO EMPRESTAR" }
```

Para o Programador: `appears_as` do `crew_click` em `shop.json` continua "Provisório (Diretor de Arte)", não é texto meu. Nada em `data/` ou código foi editado.
