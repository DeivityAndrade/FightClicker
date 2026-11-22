# Fase 8a1 — Textos da liga regional (Roteirista, VERSÃO FINAL)

Tudo abaixo já está gravado em `data/ui_texts.json`, `data/league_regional.json` e `data/dialogos.json`. Ids e "quem trava quem" seguem o `fase8a1-design.md`.
Tela em MAIÚSCULAS. Balão (falas) em **minúsculas**, máx. 26 caracteres por linha, 2 linhas, só caracteres da fonte do balão (sem `º`, sem `à`).

## 1. Nomes
| Item | Nome |
|---|---|
| Liga | LIGA REGIONAL DO VALE (`league_regional_name`) |
| Arena | CLUBE FERROVIÁRIO (`arena_regional_name`): ginásio de clube antigo, à noite, ringue de verdade, faixa "Autopeças Vale Forte" (só faixa; patrocínio jogável é da 8a2) |
| Cinturão | CINTURÃO DO VALE (`belt_regional_title`) |

## 2. Adversários (campos de texto em `league_regional.json`)
| id | Nome | Descrição | Entrada | Se ele vence | Se ele perde |
|---|---|---|---|---|---|
| `opp_reg_1` | Zé Bigorna | O Queixo Duro. Já tomou de tudo e nunca se queixou. | Pode bater. Eu espero. | Eu avisei: queixo é herança. | Tá. Doeu. Um pouquinho. |
| `opp_reg_2` | Tião Estaca | O Pé de Cimento. Quem tenta derrubar acaba cavando. | Pode empurrar. Eu cresci aqui. | Plantei e ficou. | Arrancaram a raiz. Que feio. |
| `opp_reg_3` | Rony Sabão | O Escorrega. Sai de qualquer abraço sem deixar recibo. | Me segura, se for capaz. | Nem me tocou. Que pena. | Escorreguei na própria fama. |
| `opp_james` | James Blindado | O que a bala não fura. Acha a Raízes uma piada. | Então é essa a Raízes? Fofo. | Academia de verdade se vê no cartaz. | Sorte. Escola pequena tem isso. |

## 3. Passivas dos adversários (ui_texts)
Chaves por id da passiva (`adv_iron_chin`, `adv_wide_base`, `adv_slippery`, `adv_blindado`).
| Chave (`<id>`) | iron_chin | wide_base | slippery | blindado |
|---|---|---|---|---|
| `opp_passive_<id>_name` | QUEIXO DE FERRO | BASE LARGA | ENSABOADO | BLINDADO |
| `opp_passive_<id>_line` | NÃO CAI NO EMBALO: SEGURA O K.O. DE EMBALO | PLANTA OS PÉS: A QUEDA DO POR CIMA NÃO ENTRA | ESCORREGA DO ABRAÇO: O CLINCH PRENDE POUCO E SOLTA FÁCIL | GUARDA FECHADA NO 1º ROUND: CORTA QUALQUER JEITO. PACIÊNCIA |
| `opp_passive_<id>_jeito` (o `{jeito}`) | K.O. DE EMBALO | POR CIMA | CLINCH | TODOS NO 1º ROUND |
| `fight_opp_block_<id>` (letreiro do sinal) | AGUENTOU! | NÃO CAIU | ESCAPOU! | (usa `fight_guard_closed`) |
| `reason_opp_<id>` | ELE NÃO CAIU NO EMBALO | A QUEDA NÃO ENTROU: ELE PLANTOU OS PÉS | VOCÊ NÃO PRENDEU: ELE ESCORREGOU | A GUARDA SEGUROU {n}% DA VIDA DELE NO 1º ROUND |
| `tip_opp_<id>` (lista de 2) | TENTE OUTRO JEITO: ESPERE O CONTRAGOLPE / O QUEIXO DELE NÃO ACEITA EMBALO. ACEITA PACIÊNCIA | A FINALIZAÇÃO AINDA PEGA. OU TREINE MAIS FORÇA / ELE PLANTA OS PÉS. FINALIZAÇÃO NÃO PRECISA DE QUEDA | O CHUTE RODADO NÃO PRECISA DE ABRAÇO / PRENDER SÓ COM FORÇA E O DEFENSIVO. OU CHUTE DE LONGE | SEGURE O FÔLEGO E ESPERE A GUARDA ABRIR / CONTRAGOLPE, FINALIZAÇÃO E CANELA SOFREM MENOS COM ELA |

Chaves soltas: `opp_passive_hits` ("ATRAPALHA: {jeito}"), `opp_passive_misses` ("NÃO ATRAPALHA O SEU JEITO"), `opp_passive_guard_hits` ("ATRAPALHA: TODOS NO 1º ROUND"), `fight_guard_closed` ("GUARDA FECHADA"), `fight_guard_open` ("A GUARDA ABRIU").
Só o `reason_opp_adv_blindado` tem `{n}` (% da vida dele que a guarda segurou, `guard_absorbed`); os outros 3 não usam número.
Ícones (arte): `adv_iron_chin` queixo/bigorna, `adv_wide_base` pé plantado, `adv_slippery` bolha/sabão, `adv_blindado` escudo.

## 4. Liga e cinturão (ui_texts)
| Chave | Texto |
|---|---|
| `league_regional_next` | PRÓXIMA LUTA REGIONAL: {d} DIAS |
| `league_regional_invite_title` | CONVITE: LIGA REGIONAL DO VALE |
| `league_regional_invite_line` | O KID PERDEU. O VALE QUER CONHECER A RAÍZES |
| `belt_regional_title` / `belt_regional_label` | CINTURÃO DO VALE |
| `belt_regional_line` | O BLINDADO CAIU. A RAÍZES É DO VALE |
| `belt_regional_unlock` | CENTRO DE TREINAMENTO LIBERADO |
| `belt_regional_soon` | A MUDANÇA CHEGA NA PRÓXIMA VERSÃO |
| `belt_regional_lost` (James venceu) | O BLINDADO FICA COM O CINTURÃO. VOLTE MAIS FORTE |

Cartaz da parede: objeto `regional_poster` em `dialogos.json → objects` (título "LIGA REGIONAL DO VALE"; texto "CAMPEÃO: JAMES BLINDADO" + linha "O QUE A BALA NÃO FURA" entre aspas).

## 5. James Blindado (`dialogos.json`)
Cast novo: `rival` (James Blindado, curto `james`, cor `b1`, voz `rival` 240 Hz / 32 c/s). Vaidoso, nunca cruel: zomba da **escola**, nunca do jogador; nunca elogia, agradece nem ameaça (respeito só na 8b). Sem cena nova, tudo na caixa de diálogo, pulável.

### 5.1 Gatilhos novos (`triggers`) e como ligar
| Gatilho | Quem fala | Quando | Como o Programador liga |
|---|---|---|---|
| `regional_league_opened` | Osmar | 1ª vez que a linhagem vence o Kid (marco `regional_league_opened`; save antigo: ao carregar com `indice_escada >= 6`) | fala `cl_liga_regional` já tem `milestone_present: [regional_league_opened]`; mostrar junto do cartaz |
| `regional_belt_first` | Osmar | 1º cinturão regional da linhagem (marco `regional_belt_first`) | fala `cl_cinturao_regional`, mesma regra do marco |
| `james_intro` | James | ao apertar LUTAR contra ele, 1 vez por campanha | tocar **em ordem** os ids do grupo da situação (abaixo); sem condição no JSON: quem escolhe é o código |
| `james_after` | James | fim da tela de luta, antes da janela de fim (decisão do Produtor, ver fase8a1-cutscene-james.md), 1 vez por campanha | tocar o id único da combinação resultado x situação |

O validador de falas (`dialogos_data.gd`) não tem condição para o placar da escola, então a escolha da situação é do **código** (sem mudar o validador): ele monta o id e busca a fala pelo id. Falas do James ficam `repeat: rest`.

### 5.2 Apresentação (`james_intro`; ids tocados em ordem)
| Situação (`escola.rival`) | Ids | Falas |
|---|---|---|
| `first` (`met == 0`) | `rival_james_intro_first_1..3` | então é essa a raízes? / ainda batendo em saco de areia? fofo. (reservada da Fase 2) / o cinturão fica aqui. na academia de verdade. |
| `many` (`met >= 3`, vence as outras) | `rival_james_intro_many_1..2` | vocês, outra vez. já decorei o cartaz. / vamos ver o que ensinaram desta vez. |
| `school_won` (`school_wins >= 1`) | `rival_james_intro_school_won_1..2` | de novo a raízes? isso virou mania. / aquilo foi sorte. sorte não se repete. |
| `revenge` (senão: já encontrou, escola só perdeu) | `rival_james_intro_revenge_1..2` | voltaram? a raízes não se cansa? / mesma sala, mesma sorte: nenhuma. |

### 5.3 Depois da luta (`james_after`; 1 id por combinação)
Situação: `first` = `met == 1`; `many` = `met >= 3`; `school_won` = escola já tinha vencido antes desta luta; qualquer outro caso (ex.: `met == 2`, escola só perdeu) usa `many`. Precedência: `many` > `school_won` > `first`.
| Resultado | first | school_won | many |
|---|---|---|---|
| James venceu | `rival_james_after_win_first_1`: academia de verdade se vê no cartaz. | `rival_james_after_win_school_won_1`: dessa vez, sem acidente. escola pequena, fim. | `rival_james_after_win_many_1`: escola pequena não dura. volte quando crescer. |
| James perdeu | `rival_james_after_lose_first_1`: sorte de principiante. escola pequena tem isso. | `rival_james_after_lose_school_won_1`: duas sortes. coincidência da escola, só isso. | `rival_james_after_lose_many_1`: noite ruim, só isso. a raízes que não se iluda. |

## 6. Osmar
- `cl_liga_regional` (uma vez): é o blindado. já ouvi / falar da academia dele.
- `cl_cinturao_regional` (uma vez): o cinturão é do vale. / o resto a gente vê.

## 7. Para o Programador (resumo)
- Chaves por id da passiva usam o `passive.id` do JSON (`adv_iron_chin` etc.): `opp_passive_<id>_name/_line/_jeito`, `fight_opp_block_<id>`, `reason_opp_<id>`, `tip_opp_<id>` (esta é lista de 2, como `tip_passive_*`).
- `{jeito}` em `opp_passive_hits` = `opp_passive_<id>_jeito` da passiva dele.
- Gatilhos novos: `regional_league_opened`, `regional_belt_first` (marcos de mesmo nome), `james_intro`, `james_after`; falas do James por **id** (§5), pois o placar não é uma condição do validador.
- Falas de James: lembrar que balão é minúsculo; `{first}` etc. não são usados.
