# Fase 6b1: textos (Passar o posto)

Dono: Roteirista. Data: 2026-11-14. Base: `fase6b-escopo.md`, `prancha-6b.md`, `direcao-narrativa.md` (manda), `fase6a-textos.md`.
Chaves novas em `data/ui_texts.json` (só acrescentadas) e banco de nomes em `data/nomes_discipulos.json`. `data/cutscenes/`, `scripts/` e `ui/` não foram tocados.

## 1. Falas da cena (balão: minúsculas, máx. 2 linhas de 26)
| id | Quem | Texto | Chave |
|---|---|---|---|
| `suc_guarda` | John (cena, S8) | `vamos ver sua guarda.` (21 car.) | `suc_guarda` |
| `suc_isso` | John (passivo, S10) | `isso.` | `suc_isso` |

- Osmar fica calado. O discípulo não fala.
- Polimento: tirei qualquer enfeite. "vamos ver" mantém o verbo da dupla com `fim_ver` ("quero ver o que aprenderam."), e é jeito de treinador de bairro, não de discurso. "isso." é aprovação seca, de quem pouco fala.

## 2. Tela "RECEBER NOVO DISCÍPULO"
| Chave | Texto |
|---|---|
| `disc_title` | RECEBER NOVO DISCÍPULO |
| `disc_label_name` | NOME |
| `disc_label_skin` | PELE |
| `disc_label_hair` | CABELO |
| `disc_label_shorts` | CALÇÃO |
| `disc_roll` | SORTEAR |
| `disc_confirm` | CONFIRMAR |
| `disc_glove_line` | LUVA: O PAR DO JOHN |

Rótulos da 6b2 (corte, parte de cima, faixa, meião) ficam para a próxima fase.

## 3. Luva inicial (cartão)
- `glove_start_desc`: `O par do John. Velha, mas fecha direito.` (40 car., igual à 6a).
- `glove_start_desc_disc` (variante para o discípulo): `O par do John. Agora é seu. Fecha bem.` (38 car.).

## 4. Botões e textos de campanha
| Chave | Texto | Uso |
|---|---|---|
| `new_disciple_button` | RECEBER NOVO DISCÍPULO | botão do fim de campanha (substitui `new_career_button`) |
| `new_disciple_button_short` | NOVO DISCÍPULO | plano B se os 22 caracteres não couberem no botão de 188 px |
| `tree_new_disciple` | NOVO DISCÍPULO | substitui `tree_new_career` |
| `end_support_line_disc` | O par fica no saco. O próximo vai pegar. | substitui `end_support_line`, porque as luvas agora ficam penduradas no saco, não no gancho |

## 5. "Carreira N" vira o nome do discípulo
O nome entra em MAIÚSCULA onde o texto é de interface (a UI aplica `.to_upper()` em `{nome}`).
| Chave | Texto | Substitui |
|---|---|---|
| `hud_disciple` | `{nome}` | `hud_career` ("CAMPANHA {n}") |
| `hud_disciple_career` | `{nome}  C{n}` | versão com o número pequeno, se o Designer quiser |
| `sum_title_named` | `RESUMO DE {nome}` | `sum_title` |
| `career_card_title_named` | `{nome}: O QUE VOCÊ TROUXE` | `career_card_title` |
| `art_sub_career_named` | `{nome}: ESCOLHA A ARTE` | `art_sub_career` |

As chaves antigas ficam no arquivo (só acrescentei). Quem implementar escolhe qual usar e remove as velhas depois.

## 6. Botão de pular
- `skip_button`: `PULAR` (botão com anel).
- `skip_chip`: `SEGURE ESC: PULAR` (corrige o chip "ESC esc: pular").

## 7. Banco de nomes (`data/nomes_discipulos.json`)
- 42 nomes, formato "Nome Apelido", todos originais, de lutador de bairro (o apelido é ferramenta, material de obra ou peça de oficina). Nenhum é pessoa real conhecida nem personagem de outro jogo. Neutros quanto a gênero no conjunto (mistura de masculinos e femininos), então o sorteio serve para qualquer aparência.
- Máximo 14 caracteres (o maior tem 14); a tela deve limitar o nome digitado a 14, o valor `max_caracteres` do arquivo.
- Letras: só A-Z e `á é í ó ú ã ç` minúsculos. Evitei `ô`, que a lista de caracteres da 6a não garante na fonte 5x7. Sem pontuação nem hífen.
- **Nome padrão** para o discípulo já existente no save do dono: `Novato` (chave `disciple_default_name` e campo `nome_padrao` do arquivo). Combina com "PARA O NOVATO" da caixa da escola.

## 8. Pendências
- Diretor de Arte: confirmar `Í`, `Ã`, `Ç` maiúsculos na 5x7 (já usados em `CINTURÃO`, `ÁRVORE` e agora `DISCÍPULO`, `CALÇÃO`).
- UI/UX: conferir se `RECEBER NOVO DISCÍPULO` cabe no botão; se não, usar `new_disciple_button_short`.
