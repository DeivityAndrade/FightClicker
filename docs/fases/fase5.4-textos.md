# Fase 5.4 — Textos da árvore grande

Dono: Roteirista. Data: 2026-11-13.
Base: `fase5.4-design.md` (seção 8), `fase5.4-escopo.md`, `direcao-narrativa.md`, `arte/direcao-visual.md` §21 e os nomes que já estão em `data/skill_tree.json`.
Limites: nome ≤ 16 caracteres, frase ≤ 44. Conferi todos. Os textos de efeito (`effect_text`) são os do Designer, sem mudança.

## 1. Linha de tom
- Humor de bairro e o legado do velho: a árvore é "o que o velho te ensinou" e o que os discípulos anteriores deixaram. Os nós falam de coisas pequenas (esparadrapo, varal, pão de queijo), nunca de números.
- Garagem: casa e improviso. Academia: um degrau acima, ainda com pé no chão. Boxe e Jiu-jitsu: ofício. Campanha: papelada e fama de bairro. Ligações: favor entre regiões.

## 2. Os 27 nós novos
Mantive os provisórios do Designer, que já seguem o tom. Mudei só uma frase (`gar_crew_start`: dizia "o vizinho", mas o efeito dá 5).

| id | Nome | Frase |
|---|---|---|
| `gar_tape` | Fita no punho | Esparadrapo da farmácia. Segura tudo. |
| `gar_radio` | Rádio no muro | Pagode baixinho. A turma treina no ritmo. |
| `gar_rope` | Corda montada | O varal agora é seu. A vizinha desistiu. |
| `gar_metro` | Pêndulo de casa | O tique-taque já mora na garagem. |
| `gar_crew_start` | Turma de sempre | Cinco vizinhos já chegam de luva. (mudou) |
| `gar_shoes` | Tênis de sola | Sola nova, pé firme, soco sentado. |
| `camp_poster` | Cartaz na venda | Seu nome do lado do pão de queijo. |
| `camp_sponsor` | Rádio do bairro | O locutor erra seu nome. Mas fala. |
| `camp_diary` | Caderno do velho | Cada luta anotada. Cada erro também. |
| `camp_extra_day` | Um dia a mais | O empresário empurra a data. Você agradece. |
| `gym_membership` | Carteirinha | Sócio da academia. Tem até foto 3x4. |
| `gym_mirror` | Espelho grande | Você se vê errando. Erra menos. |
| `gym_league` | Liga do bairro | Tabela na parede, seu nome a lápis. |
| `gym_fan` | Ventilador novo | Ninguém desmaia. Todo mundo treina. |
| `gym_partner` | Parceiro fixo | Segura o saco e não reclama. |
| `box_counter` | Contragolpe | Ele erra, você não perdoa. |
| `box_wraps` | Faixa nas mãos | Enrolada do jeito que o velho mandou. |
| `box_footwork` | Jogo de pernas | Dança na ponta do pé. Bate parado. |
| `box_bell` | Ouvido de sino | Você ouve a pera até dormindo. |
| `bjj_guard` | Base firme | Empurra, puxa. Você não sai do lugar. |
| `bjj_knot` | Nó da faixa | Apertado. Não solta nem no banho. |
| `bjj_breath` | Respirar fundo | Embaixo dele, você conta até dez. |
| `bjj_patience` | Paciência | Quem tem pressa bate no chão. |
| `link_shout` | Grito mais alto | A garagem inteira grita junto. |
| `link_mat` | Colchão no chão | Dois colchões velhos e muita vontade. |
| `link_mirror` | Pera emprestada | A academia empresta. Você devolve suado. |
| `link_ring` | Cartaz da liga | Seu nome impresso. Com acento e tudo. |

(Os 12 do centro não mudam. "Caderno do velho" tem 16 caracteres, o limite.)

## 3. Textos da tela do mapa
Tamanhos pela §21.2: título em (29,11), dica 12 px depois do título, Legado termina em x 610. Fonte 1x, ~6 px por caractere.

| Peça | Texto | Caracteres | Observação |
|---|---|---|---|
| Título | O QUE O VELHO TE ENSINOU | 24 | Já existe (`tree_title`). Ocupa ~144 px, de x 29 a ~173 |
| Dica | ARRASTE OU USE A RODA | 21 | ~126 px, de ~185 a ~311. Sobra espaço até o Legado |
| Faixa do cartão | VALE NA PRÓXIMA CAMPANHA | 24 | Pé do cartão, ao lado do ícone de calendário |
| Cartão, Grito sem Grito | PEDE O GRITO DA EQUIPE (LOJA) | 29 | No `link_shout` quando o Grito não foi comprado |
| Botão da sala, linha 1 | ÁRVORE | 6 | Já existe (`tree_button`) |
| Botão, linha 2 (n ≥ 2) | {n} NÓS PARA COMPRAR | até 21 | cor `col_text_2` |
| Botão, linha 2 (n = 1) | 1 NÓ PARA COMPRAR | 17 | singular |
| Botão, linha 2 (n = 0) | NADA PARA COMPRAR AGORA | 23 | botão sem brilho |

**Regiões (plaquinha, 13 px de altura, nome 1x):**
| id | Nome | Obs. |
|---|---|---|
| `garage` | GARAGEM | |
| `gym` | ACADEMIA | |
| `boxing` | BOXE | |
| `bjj` | JIU-JITSU | o mais longo, 9 caracteres, ~54 px |
| `campaign` | CAMPANHA | ver nota |

**Nota sobre CAMPANHA:** o ramo do centro e a região leste têm o mesmo nome. Na tela não colide, porque o centro não tem plaquinha (§21.7). Se o dono estranhar, a alternativa é trocar só a região leste para **AGENDA** (6 caracteres), que combina com "Um dia a mais" e "Caderno do velho". Hoje deixei CAMPANHA, como o Designer aplicou.

## 4. JSON para colar

### 4.1 `skill_tree.json`: só os campos de texto
Cada item vale para o nó de mesmo `id`. Só `gar_crew_start.description` difere do que já está no arquivo.
```json
{
  "gar_tape":       {"name": "Fita no punho",    "description": "Esparadrapo da farmácia. Segura tudo."},
  "gar_radio":      {"name": "Rádio no muro",    "description": "Pagode baixinho. A turma treina no ritmo."},
  "gar_rope":       {"name": "Corda montada",    "description": "O varal agora é seu. A vizinha desistiu."},
  "gar_metro":      {"name": "Pêndulo de casa",  "description": "O tique-taque já mora na garagem."},
  "gar_crew_start": {"name": "Turma de sempre",  "description": "Cinco vizinhos já chegam de luva."},
  "gar_shoes":      {"name": "Tênis de sola",    "description": "Sola nova, pé firme, soco sentado."},
  "camp_poster":    {"name": "Cartaz na venda",  "description": "Seu nome do lado do pão de queijo."},
  "camp_sponsor":   {"name": "Rádio do bairro",  "description": "O locutor erra seu nome. Mas fala."},
  "camp_diary":     {"name": "Caderno do velho", "description": "Cada luta anotada. Cada erro também."},
  "camp_extra_day": {"name": "Um dia a mais",    "description": "O empresário empurra a data. Você agradece."},
  "gym_membership": {"name": "Carteirinha",      "description": "Sócio da academia. Tem até foto 3x4."},
  "gym_mirror":     {"name": "Espelho grande",   "description": "Você se vê errando. Erra menos."},
  "gym_league":     {"name": "Liga do bairro",   "description": "Tabela na parede, seu nome a lápis."},
  "gym_fan":        {"name": "Ventilador novo",  "description": "Ninguém desmaia. Todo mundo treina."},
  "gym_partner":    {"name": "Parceiro fixo",    "description": "Segura o saco e não reclama."},
  "box_counter":    {"name": "Contragolpe",      "description": "Ele erra, você não perdoa."},
  "box_wraps":      {"name": "Faixa nas mãos",   "description": "Enrolada do jeito que o velho mandou."},
  "box_footwork":   {"name": "Jogo de pernas",   "description": "Dança na ponta do pé. Bate parado."},
  "box_bell":       {"name": "Ouvido de sino",   "description": "Você ouve a pera até dormindo."},
  "bjj_guard":      {"name": "Base firme",       "description": "Empurra, puxa. Você não sai do lugar."},
  "bjj_knot":       {"name": "Nó da faixa",      "description": "Apertado. Não solta nem no banho."},
  "bjj_breath":     {"name": "Respirar fundo",   "description": "Embaixo dele, você conta até dez."},
  "bjj_patience":   {"name": "Paciência",        "description": "Quem tem pressa bate no chão."},
  "link_shout":     {"name": "Grito mais alto",  "description": "A garagem inteira grita junto."},
  "link_mat":       {"name": "Colchão no chão",  "description": "Dois colchões velhos e muita vontade."},
  "link_mirror":    {"name": "Pera emprestada",  "description": "A academia empresta. Você devolve suado."},
  "link_ring":      {"name": "Cartaz da liga",   "description": "Seu nome impresso. Com acento e tudo."}
}
```
(São 27 nós novos, mais `gar_crew_start`, que já estava. A lista acima tem 27 entradas.)

Regiões (já no arquivo, sem mudança): `GARAGEM`, `ACADEMIA`, `BOXE`, `JIU-JITSU`, `CAMPANHA`.

### 4.2 `ui_texts.json`: chaves novas
`tree_title`, `tree_button`, `tree_legacy` e `tree_branch_career` já existem e ficam como estão.
```json
{
  "map_hint": "ARRASTE OU USE A RODA",
  "map_next_campaign": "VALE NA PRÓXIMA CAMPANHA",
  "map_needs_shout": "PEDE O GRITO DA EQUIPE (LOJA)",
  "map_button_tip_many": "{n} NÓS PARA COMPRAR",
  "map_button_tip_one": "1 NÓ PARA COMPRAR",
  "map_button_tip_none": "NADA PARA COMPRAR AGORA",
  "map_region_garage": "GARAGEM",
  "map_region_gym": "ACADEMIA",
  "map_region_boxing": "BOXE",
  "map_region_bjj": "JIU-JITSU",
  "map_region_campaign": "CAMPANHA"
}
```
Sem travessão em nenhum texto. Nenhum número de balanceamento foi tocado, e não editei `data/` nem código.
