# Fase 6c2: textos (Mais longe que eu)

Dono: Roteirista. Data: 2026-11-16. Base: `fase6c2-design.md`, `direcao-narrativa.md` (manda), `fase6c1-textos.md`.
Tocados: `data/ui_texts.json` e `data/dialogos.json` (só chaves novas da 6c2). `scripts/`, `ui/`, `hall.json` e `escola.json` não foram tocados. O rival não aparece.
UI em maiúsculas; balões em minúsculas, até 2 linhas de 26. Só letras da 5x7 (á â ã ç é ê í ó õ ú); sem hífen.

## 1. Honra
| Chave (`ui_texts`) | Texto |
|---|---|
| `honor_label` | HONRA |
| `honor_what` (1 linha, no mural) | Honra é o que a escola guarda de quem sai de pé. |
| `retire_confirm_honor` (na confirmação de sair) | E +{n} DE HONRA |
| `retire_confirm_honor_help` | A HONRA FICA NO MURAL DA ESCOLA |
| `retire_no_honor` (0 vitórias) | HONRA SÓ COM 1 VITÓRIA |
| `end_honor_gain` (tela de fim) | +{n} HONRA |
| `mural_honor_balance` | HONRA: {n} |
| `start_card_mural` | O MURAL: +{pct}% DE TREINO |

Derrota: nenhuma linha de Honra (regra do design).

## 2. Hall
| Chave | Texto |
|---|---|
| `hall_title` | O QUE FICOU NA PAREDE |
| `hall_between` (aviso) | O HALL SÓ SE COMPRA ENTRE CAMPANHAS |
| `hall_buy_only_end` (botão apagado) | COMPRA NO FIM DA CAMPANHA |
| `hall_owned` | COMPRADO |
| `hall_missing` | FALTAM {n} DE HONRA |

| Nó | Nome (`_name`) | Descrição (`_desc`) |
|---|---|---|
| hall_box | FITA FROUXA | CAIXAS ABREM COM 1 CLIQUE A MENOS |
| hall_fund | VAQUINHA | COMEÇA COM 500 DE TREINO |
| hall_notes | CADERNINHO | A PRÉVIA MOSTRA O QUE MAIS FALTA |
| hall_crew | TURMA DA ESCOLA | A EQUIPE TREINA 10% MAIS |
| hall_glove | LUVA NO GANCHO | COMEÇA COM A LUVA DE LONA CALÇADA |
| hall_wall | PAREDE MAIOR | MAIS 3 RETRATOS CONTAM NO BÔNUS |

Chaves: `hall_<id sem prefixo>_name` / `_desc` (ex.: `hall_box_name`). Nomes até 16 letras. Os números dentro das descrições estão fixos no texto; se o Designer mudar um valor, o texto muda junto.
Linha da prévia (`hall_notes`): `preview_missing_line` = FALTA UNS {n} DE {atributo} (sem "~": a fonte 5x7 não tem esse sinal).

## 3. Mural
| Chave | Texto |
|---|---|
| `mural_button` | MURAL |
| `mural_title` | MURAL DA ESCOLA |
| `mural_bonus_line` | SELOS: {n} (CONTAM {c} DE {cap}) +{pct}% DE TREINO |
| `mural_career` | CARREIRA {n} |
| `mural_wins` / `mural_wins_one` | {n} VITÓRIAS / 1 VITÓRIA |
| `mural_wins_unknown` | ? |
| `mural_art_none` | SEM ARTE |
| `mural_end_retire` (com selo) | SAIU POR CIMA |
| `mural_end_passed` | PASSOU O POSTO |
| `mural_end_defeat` | PAROU EM {adversario} |
| `mural_first_left` (John) | FOI SEGUIR O RUMO DELE |
| `objects.mural` (dica ao passar o mouse, `dialogos.json`) | MURAL DA ESCOLA / Todo mundo que vestiu a camisa. |

Retrato: nome, CARREIRA n, arte, vitórias (+ cinturão), fim, e "+N HONRA" (`end_honor_gain`) se tem selo.
**PROVISÓRIO:** `mural_first_left` ("foi seguir o rumo dele") espera a pergunta 3 dos testadores da 6c1. Se não perceberam a saída, deixar mais claro ("SAIU PRA SEGUIR A VIDA"); se acharam triste, mais leve ("FOI TREINAR POR CONTA").

## 4. Falas dos mentores (`dialogos.json`, `trigger: mentor_won`)
Todas `speaker: "mentor"`, `repeat: rest`, grupo próprio. Lê o contrato da §6.4 do design. Marcadores: `{adversario}` (vencido), `{mentor}` (quem ele derrubou).

| Id | Condição extra | Texto |
|---|---|---|
| ml_revanche_1 | | {adversario} caiu. / cobrou por {mentor}. |
| ml_revanche_2 | | esse aí derrubou / {mentor}. não mais. |
| ml_revanche_3 | | alguém tinha que / cobrar essa. valeu. |
| ml_revanche_own_1 | `own` | esse aí me derrubou. / agora ele sabe. |
| ml_revanche_own_2 | `own` | lembro desse. me pegou / de jeito. você não. |
| ml_revanche_own_3 | `own` | esperei muito / por essa. |
| ml_recorde_1 | | ninguém da escola / chegou tão longe. |
| ml_recorde_2 | | marca nova na parede. / eu vi daqui. |
| ml_recorde_3 | | daqui pra frente, você / vai ter que nos contar. |
| ml_recorde_first_1 | `mentor_kind first` | eu que ensinei o início. / o resto é seu. |
| ml_mais_longe_1 | | passou de onde / eu parei. |
| ml_mais_longe_2 | | já passou da minha / marca. segue aí. |
| ml_mais_longe_3 | | eu fiquei por aqui. / você foi além. |
| ml_mais_longe_first_1 | `first` | foi mais longe que eu / na garagem. bom. |
| ml_mais_longe_disc_1 | `disciple` | minha campanha acabou / antes disso. segue. |

O mentor fala do passado sem números (não existe marcador de vitórias; se o Programador quiser, `{marca}` com as vitórias dele permitiria "parei na terceira"). Linhas com marcador: até 26 caracteres com nomes de até 12 letras. O trigger `mentor_won` (`priority 7, defer true`) entrou em `triggers`.

## 5. Pedidos
- **Programador:** o locutor `mentor` não está em `cast` (resolve pelo mentor sentado). Linhas `ml_*` usam grupos `ml_revanche`, `ml_revanche_own`, `ml_recorde`, `ml_mais_longe` só para o rodízio `rest`; o teto por campanha segue `escola.json → mentor_lines`.
- **Designer:** `hall.json → nodes[].name` e `effect_text` ficaram provisórios; os textos finais estão nas chaves `hall_*_name/_desc` de `ui_texts.json` (nomes mudaram: Vaquinha, Caderninho, Luva no gancho). Pode apontar o `hall.json` para elas.
