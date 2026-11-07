# Fase 4b — Textos: aparelhos que chegam e treino assistido

Dono: Roteirista. Versão 1 (2026-11-06). Só texto; números e preços ficam com o Designer.
Base: `fase4b-escopo.md` (respostas do dono), `fase4b-design.md` §7.2, `fase2-textos.md`.
Limites: nome até 16 caracteres, descrição até 44. Na tela tudo sai em maiúsculas (aqui, caixa normal onde é prosa).

## Decisões de texto
- **`{nome}` é sempre o nome curto: ESTEIRA e CORDA.** Os dois são femininos, então "A {nome}", "DEPOIS DA {nome}" e "COMPRE A {nome}" funcionam sem exceção. Por isso `unlock.name` é curto (o "enferrujada" e o "de varal" ficam na descrição e no nome do aparelho da Fase 2, que não muda).
- **Esteira e corda chegam de jeito improvisado**: ferro-velho, varal da vizinha. Nada de loja, nada de "comprou" com pompa.
- **Assistido é acessibilidade.** Tom gentil e direto, sem "truque" nem "trapaça". O verbo é SEGURAR. Nunca aparece "ligar/desligar", porque não existe isso.
- A dica `assist_hint` é a mais longa (30 caracteres). Se não couber no botão de foco, o UI/UX usa a variante curta `assist_hint_short` (opcional, ver bloco).

## Aparelhos

| id | `name` | `description` (≤44) | `arrives_as` |
|---|---|---|---|
| `unlock_treadmill` | Esteira | Gira, geme e cheira a ferrugem. Mas corre. | Veio do ferro-velho num carrinho de mão. |
| `unlock_jump_rope` | Corda | Um varal, dois cabos e muita paciência. | Tirada do varal da vizinha. Ela nem notou. |

Contagem: nomes 7 e 5; descrições 42 e 40.

Reserva (se o dono preferir outro clima): esteira "Doada por uma academia que fechou." / corda "Emprestada pelo vizinho. Com juros."

## Chaves de `ui_texts.json`

| chave | texto | obs. |
|---|---|---|
| `unlock_buy` | COMPRAR | botão da linha na aba TREINO |
| `unlock_price` | {n} TREINO | |
| `unlock_after` | DEPOIS DA {nome} | |
| `floor_mark_price` | {nome} — {n} TREINO | plaquinha; "CORDA — 1.5K TREINO" cabe |
| `floor_mark_after` | {nome} — DEPOIS DA {anterior} | "CORDA — DEPOIS DA ESTEIRA" (25) |
| `focus_locked_price` | {n} | só o número; o cadeado já diz o resto |
| `focus_locked_after` | DEPOIS DA {nome} | 17 caracteres com ESTEIRA |
| `attr_locked` | COMPRE A {nome} PARA TREINAR | |
| `unlock_arrived` | CHEGOU: {nome}! | neutro, sem artigo |
| `tip_unlock_treadmill` | lista de 3 | ver bloco |
| `tip_unlock_jump_rope` | lista de 3 | ver bloco |
| `tip_unlock` | COMPRE A {nome} CEDO NA PRÓXIMA CARREIRA | reserva |
| `assist_hint` | SEGURE SHIFT: TREINO ASSISTIDO | |
| `assist_hint_short` | SEGURE SHIFT | opcional, se a dica longa não couber |
| `assist_button` | SEGURAR | botão para quem só usa o mouse |
| `assist_waiting` | ESPERANDO A MÃO PARAR | segurando, mas ainda clicou há menos de 1 s |
| `assist_active` | ASSISTIDO | |
| `assist_metronome` | METRÔNOMO TOCANDO | |
| `shop_metronome_now` | AGORA: 1 SOCO A CADA {s} S COM SHIFT | 36 caracteres; cabe nos 44 |

Mudança em relação ao rascunho do design: `assist_waiting` deixou de ser "MÃO PARADA = ASSISTIDO" (soava como ordem) e virou "ESPERANDO A MÃO PARAR", que descreve o que acontece sem cobrar nada do jogador. `shop_metronome_now` encurtou "SÓ SEGURANDO SHIFT" para "COM SHIFT" para respeitar os 44.

## Bloco JSON (colar em `data/ui_texts.json`)

```json
{
	"unlock_buy": "COMPRAR",
	"unlock_price": "{n} TREINO",
	"unlock_after": "DEPOIS DA {nome}",
	"floor_mark_price": "{nome} — {n} TREINO",
	"floor_mark_after": "{nome} — DEPOIS DA {anterior}",
	"focus_locked_price": "{n}",
	"focus_locked_after": "DEPOIS DA {nome}",
	"attr_locked": "COMPRE A {nome} PARA TREINAR",
	"unlock_arrived": "CHEGOU: {nome}!",
	"tip_unlock_treadmill": [
		"COMPRE A ESTEIRA CEDO NA PRÓXIMA CARREIRA",
		"ESTEIRA PRIMEIRO. FÔLEGO NÃO SE IMPROVISA",
		"A ESTEIRA ESTÁ ESPERANDO. CHAME ELA CEDO"
	],
	"tip_unlock_jump_rope": [
		"COMPRE A CORDA CEDO NA PRÓXIMA CARREIRA",
		"CORDA CEDO. FICAR PARADO SAI CARO",
		"O VARAL ESTÁ LIVRE. PEGUE A CORDA CEDO"
	],
	"tip_unlock": "COMPRE A {nome} CEDO NA PRÓXIMA CARREIRA",
	"assist_hint": "SEGURE SHIFT: TREINO ASSISTIDO",
	"assist_hint_short": "SEGURE SHIFT",
	"assist_button": "SEGURAR",
	"assist_waiting": "ESPERANDO A MÃO PARAR",
	"assist_active": "ASSISTIDO",
	"assist_metronome": "METRÔNOMO TOCANDO",
	"shop_metronome_now": "AGORA: 1 SOCO A CADA {s} S COM SHIFT"
}
```

## Bloco JSON dos aparelhos (campos `unlock` em `data/training.json`; só os textos)

```json
"unlock_treadmill": {
	"name": "Esteira",
	"description": "Gira, geme e cheira a ferrugem. Mas corre.",
	"arrives_as": "Veio do ferro-velho num carrinho de mão."
},
"unlock_jump_rope": {
	"name": "Corda",
	"description": "Um varal, dois cabos e muita paciência.",
	"arrives_as": "Tirada do varal da vizinha. Ela nem notou."
}
```

(Cada um vai dentro do bloco `unlock` do aparelho correspondente, ao lado de `id`, `cost` e `requires`, que são do Designer.)

## Contagens das dicas de fim
Todas até 42 caracteres, no mesmo tamanho das `tip_*` existentes.
