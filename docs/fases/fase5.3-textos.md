# Fase 5.3: textos (Roteirista)

Ideia: passar o posto não é fim triste, é a escola continuando. Tom de bairro, frases curtas, sem travessão.
Placa do HUD: 14 caracteres por linha (direcao-visual §20.2). "Faltam 12 dias" tem exatamente 14, é o teto.
Por isso o HUD fica em duas linhas: linha 1 é a data, linha 2 é o adversário (a UI já tem o nome, **não entra em `hud_fight_date*`**).

## Decisões
- "Aposentar" some de vez. Botão e confirmação dizem **PASSAR O POSTO**; o botão de recusa fica **VOLTAR**.
- "Carreira" vira "campanha" nos textos que o jogador vê na fase 5.3 (resumo, fim, botão novo). Os textos de "PRÓXIMA CARREIRA" nas dicas e `hud_career` ficam como estão (fora do escopo desta lista); sugestão para depois: trocar tudo junto.
- A saída ("SAIU POR CIMA") vira **PASSOU O POSTO**, com fala de continuidade.
- Não usa "receber novo discípulo" (6b).

## Tabela

| Chave | Texto | Tam. |
|---|---|---|
| `hud_fight_date` | Faltam {n} dias | 14 (n com 2 dígitos) |
| `hud_fight_date_one` | Falta 1 dia | 11 |
| `hud_fight_today` | É HOJE! | 7 |
| `hud_campaign_day` | DIA {n} | ≤ 7 |
| `hud_campaign_complete` | CAMPANHA\nCOMPLETA | 8 por linha |
| `warn_3_days` | Faltam 3 dias para {nome}. | ≤ 36 |
| `warn_1_day` | Amanhã é {nome}. Gaste o que tiver. | ≤ 36 |
| `retire_hint` | PASSAR O POSTO AGORA LEVA {n} DE LEGADO | 39 + n |
| `enrolled_toast` | Inscrição feita: {nome} em {n} dias. | ≤ 40 |
| `fight_day_title` | DIA DA LUTA | 11 |
| `fight_day_line` | {nome} chegou. Lutar ou passar o posto? | ≤ 44 |
| `fight_day_fight` | LUTAR | 5 |
| `fight_day_pass` | PASSAR O POSTO | 14 |
| `retire_button` | PASSAR O POSTO | 14 |
| `retire_confirm_title` | PASSAR O POSTO? | 15 |
| `retire_confirm_lose` | TUDO DESTA CAMPANHA SE PERDE | 28 |
| `retire_yes` | PASSAR | 6 |
| `retire_no` | VOLTAR | 6 |
| `retire_title` | PASSOU O POSTO | 14 |
| `retire_line` | A escola segue. O saco fica pra quem vem. | 41 |
| `retire_line_belt` | Cinturão na parede. A escola segue de pé. | 41 |
| `end_title_campaign` | CAMPANHA ENCERRADA | 18 |
| `end_defeat_title` | CAMPANHA ENCERRADA | 18 |
| `new_career_button` | NOVA CAMPANHA | 13 |
| `tree_new_career` | NOVA CAMPANHA | 13 |
| `sum_title` | RESUMO DA CAMPANHA {n} | ≤ 24 |
| `sum_days` | DIAS DE CAMPANHA | 16 |
| `no_more_fights_gym` | CAMPANHA COMPLETA. PASSAR O POSTO VALE MAIS. | 44 |
| `hint_legacy` | Legado em jogo\nVira permanente ao passar o posto.\nPerder leva metade. | (dica) |

Chaves antigas a trocar ou remover: `gym_retire_hint` vira `retire_hint`; a dica solta da lista de dicas
"APOSENTAR TAMBÉM É UMA BOA LUTA" vira **"PASSAR O POSTO TAMBÉM É UMA BOA LUTA"** (ver bloco).
`stake_lose` e `stake_lose_pct` ("PERDER ENCERRA A CARREIRA") ficam, ou trocar por "CAMPANHA" junto com o resto depois.

## JSON pronto para colar (em `data/ui_texts.json`, substituindo as chaves que já existem)

```json
{
	"hud_fight_date": "Faltam {n} dias",
	"hud_fight_date_one": "Falta 1 dia",
	"hud_fight_today": "É HOJE!",
	"hud_campaign_day": "DIA {n}",
	"hud_campaign_complete": "CAMPANHA\nCOMPLETA",
	"warn_3_days": "Faltam 3 dias para {nome}.",
	"warn_1_day": "Amanhã é {nome}. Gaste o que tiver.",
	"retire_hint": "PASSAR O POSTO AGORA LEVA {n} DE LEGADO",
	"enrolled_toast": "Inscrição feita: {nome} em {n} dias.",
	"fight_day_title": "DIA DA LUTA",
	"fight_day_line": "{nome} chegou. Lutar ou passar o posto?",
	"fight_day_fight": "LUTAR",
	"fight_day_pass": "PASSAR O POSTO",
	"retire_button": "PASSAR O POSTO",
	"retire_confirm_title": "PASSAR O POSTO?",
	"retire_confirm_lose": "TUDO DESTA CAMPANHA SE PERDE",
	"retire_yes": "PASSAR",
	"retire_no": "VOLTAR",
	"retire_title": "PASSOU O POSTO",
	"retire_line": "A escola segue. O saco fica pra quem vem.",
	"retire_line_belt": "Cinturão na parede. A escola segue de pé.",
	"end_title_campaign": "CAMPANHA ENCERRADA",
	"end_defeat_title": "CAMPANHA ENCERRADA",
	"new_career_button": "NOVA CAMPANHA",
	"tree_new_career": "NOVA CAMPANHA",
	"sum_title": "RESUMO DA CAMPANHA {n}",
	"sum_days": "DIAS DE CAMPANHA",
	"no_more_fights_gym": "CAMPANHA COMPLETA. PASSAR O POSTO VALE MAIS.",
	"hint_legacy": "Legado em jogo\nVira permanente ao passar o posto.\nPerder leva metade."
}
```

Dica da lista de dicas (item de array, linha 253 de hoje), trocar o texto por:
`"PASSAR O POSTO TAMBÉM É UMA BOA LUTA"`

Mantidos sem mudança: `retire_confirm_take`, `retire_confirm_bonus`, `retire_confirm_zero` (não citam "aposentar"), `end_support_line`.

## Para a UI conferir no `ui_audit`
- `retire_hint` com n grande passa de 40; se estourar, encurtar para `PASSAR O POSTO LEVA {n} DE LEGADO`.
- `fight_day_line` com nome longo (Muralha, Tonhão) pode passar de 44; se estourar, quebrar em duas linhas.
- `hud_campaign_complete` precisa do `\n` tratado como quebra.
