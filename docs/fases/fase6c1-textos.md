# Fase 6c1: textos (Casa nova)

Dono: Roteirista. Data: 2026-11-15. Base: `fase6c-escopo.md`, `direcao-narrativa.md` (manda), `cenas-curtas.md` §1 e §2.
Tocados: `data/dialogos.json` e `data/ui_texts.json` (só falas e textos da 6c1). `scripts/`, `ui/` e `data/cutscenes/` não foram tocados. O rival não é citado.
Balão: minúsculas, máx. 2 linhas de 26. Letras só da lista da 5x7 (á â ã ç é ê í ó õ ú minúsculos); nenhum hífen.

## 1. Cena da chegada (prefixo `aca_`, em `ui_texts.json`)
| Chave | Quem | Texto |
|---|---|---|
| `aca_agora_sim` | Osmar (`coach`), depois de entortar a foto | `agora sim.` |

Polimento: nenhum. É curta, de quem arruma a foto e dá o assunto por encerrado. Substitui o nome `acad_agora_sim` do pedido da prancha antiga; o Diretor de Cutscenes usa `aca_agora_sim` em `lines` (speaker `coach`, `text_key` igual).

## 2. Saída do John (prefixo `saida_`, em `ui_texts.json`)
| Chave | Quem | Texto |
|---|---|---|
| `saida_rumo_1` | John (`first`), passivo | `vou procurar meu rumo.` |
| `saida_rumo_2` | John (`first`), passivo, logo depois | `cuidem bem disso aqui.` |
| `saida_resposta` | Osmar (`coach`), passivo, sem parar o que faz | `vê se manda notícia.` |

- Duas falas, as do escopo, divididas em dois balões de uma linha para a leitura de 2 segundos. Se o Diretor de Cutscenes preferir um balão só: `vou procurar meu rumo.\ncuidem bem disso aqui.` (22 + 22).
- O John não cita ninguém pelo nome nem explica o porquê. O Osmar responde casual; o aceno de cabeça do John é gesto, não fala.
- Se o Osmar não estiver na sala, quem estiver presente dá a resposta; é decisão de cena, o texto serve para qualquer um.
- **Objeto deixado: nenhum.** O escopo (§3 item 10) manda sem bilhete, luva ou lembrança; o John leva a bolsa. A foto dele já está no mural.

## 3. Dica (hover) da foto antiga na academia
Chave nova: `objects.old_photo_gym` em `dialogos.json`.
> `A foto veio da garagem.`
> `Torta de novo. É de propósito.`

A garagem continua com `old_photo`: "Osmar, bem antes das histórias." **Pedido ao Programador:** em `_texto_parede`, o caso `photo_old` deve usar `old_photo_gym` quando o local for a academia.

## 4. Osmar na academia (`data/dialogos.json`)
Condição de local: valor `gym` (id de `locations.json`). Falas sem `location` valem nos dois lugares.

### 4.1 Revisadas
| Id | Antes | Agora |
|---|---|---|
| `cl_primeira_academia` | `location: garage` | `location: gym`. Texto igual: "a garagem vai junto, / mesmo sem a lâmpada." Toca uma vez, no 1º momento calmo na academia |
| `cl_arte_1..3` | desligadas, garagem | ligadas, **sem trava de local** (a escolha pode abrir em qualquer sala). Texto de `_2` ajustado: "escolheu? então capricha." (antes "vai até o fim", que soava a compromisso) |
| `cl_compra_1,2`, `cl_caixa_1,2`, `cl_derrota_1..3`, `cl_derrota_recall_2,3`, `cl_revanche_*`, `cl_recorde_*`, `cl_luta_marcada_*`, `cl_parado_1,2` | `location: garage` | trava removida: valem nos dois lugares (são genéricas) |
| Ficam só na garagem | | `cl_compra_3` (cimento), `cl_caixa_3` (vira banco), `cl_derrota_recall_1` ("perdi aqui"), `cl_parado_3` (lâmpada), e as `once` de garagem (compra, caixa, derrota, luva, garagem salva) |

As `cl_academia_volta_*` continuam na garagem e só falam depois de `cl_primeira_academia`.

### 4.2 Novas
Todas `repeat: rest`, nos mesmos grupos das garagem, com `location: gym`, salvo as de arte.
| Id | Grupo | Texto |
|---|---|---|
| `cl_ac_compra_1` | compra | aqui sobra chão pra isso. |
| `cl_ac_compra_2` | compra | tá ficando coisa séria. |
| `cl_ac_caixa_1` | caixa | caixa grande, sala grande. |
| `cl_ac_derrota_1` | derrota | o tatame perdoa mais. |
| `cl_ac_derrota_2` | derrota | a garagem também / derrubava. a gente volta. |
| `cl_ac_luta_marcada_1` | luta_marcada | o espelho vai te ver / entrar de queixo baixo. |
| `cl_ac_parado_1` | parado | o espelho tá olhando. |
| `cl_ac_parado_2` | parado | ventilador ligado. / sem desculpa. |
| `cl_ac_parado_3` | parado | a lâmpada daqui / não pisca. estranho. |
| `cl_ac_chegada_1..3` | academia_chegada (`gym_arrival`, depois de `cl_primeira_academia`) | a foto já tá no lugar. / torta, como manda. / esse lugar é nosso. |
| `cl_arte_4` | arte | no meu tempo era só / apanhar e aprender. |

- **Arte:** nenhuma fala chama uma arte de certa. Todas valem para qualquer escolha.
- `cl_ac_chegada_*` são as chegadas das campanhas seguintes (sem cena): uma frase, a foto já na parede.
- O estilo segue o Osmar: curto, um exagero de vez em quando, gênero neutro com o discípulo.

## 4.3 Ajustes pedidos pelo Designer
- `cl_academia_volta_*` agora com `location: gym`.
- `cl_ac_derrota_1,2` valem nos dois locais; textos novos: "chão duro ensina igual." e "garagem ou academia, / a gente volta."
- `cl_primeira_academia` com `milestone_present: ["cena_primeira_academia"]`.
- Gatilho `art_choice`: prioridade 5, `defer: true`, teto 1.

## 5. Pendências
- **Programador:** conferir o grupo novo `academia_chegada` e as `cl_ac_*` no carregador; usar `old_photo_gym` no hover da academia; trocar o texto do `Osmar` conforme o ponto `gym_coach_spot`.
- **Diretor de Cutscenes:** usar as chaves `aca_agora_sim`, `saida_rumo_1`, `saida_rumo_2`, `saida_resposta` do `ui_texts.json`. Não encontrei `docs/cutscenes/prancha-6c1.md` na hora de escrever; se ele quiser outros nomes, pedir a troca.
- **Designer:** `cl_primeira_academia` e `cl_ac_chegada_*` disputam o mesmo gatilho (`gym_arrival`); só uma toca por chegada, `after_line` já separa as duas.
