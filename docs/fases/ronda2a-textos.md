# Ronda 2a1 (brigas do Gato Preto): textos (Roteirista)

Tudo abaixo já está em `data/ui_texts.json` (bloco novo no fim). `data/ronda.json` e `data/disciples.json` já apontavam para essas chaves (nomes, `alley_*`, `disc_opt_*`), então **não precisaram de edição**. Nenhum número, script ou tela foi tocado. Tela em MAIÚSCULAS.

## Decisões de tom
- Sujo e de bairro: estepe, cadeado, portão, conta de luz. Ninguém sangra; todo mundo "apaga", "sai tonto" ou "sai mancando".
- Manchetes sobem um tom: estepe (miúdo) -> cadeado (esperto) -> portão (absurdo de leve) -> luz do bairro (começa o fantasioso).
- Vulto: sem rosto, sem nome. As testemunhas só falam do que viram ("o vulto"), nunca de quem é. Dos bandidos, quem nomeia é o jornal.
- Busca por sangue, batman, morcego, gotham: nenhum resultado.

## 1. Os 3 bandidos
| id | Nome | Apelido | Ficha (o que faz / mania) |
|---|---|---|---|
| `tire` | ZECA ESTEPE | O CHAVE DE RODA | Leva estepe de carro parado. Mania: sempre deixa o macaco no lugar. |
| `bike` | FIO | BRAÇO DE ALICATE | Corta cadeado de bicicleta. Mania: assobia a música do sorveteiro. |
| `gate` | SEU PÉ DE CABRA | O PORTEIRO | Abre portão alheio no pé de cabra. Mania: só trabalha depois do jornal. |

| id | Testemunha (nunca diz quem é o vulto) | Manchete do recorte (dossiê) | Recorte curto (hover) |
|---|---|---|---|
| `tire` | "NEM FALOU. SÓ APONTOU O ESTEPE DE VOLTA." - DONA NEIDE, DA JANELA | GATO PRETO APAGA O CHAVE DE RODA. ESTEPES DORMEM EM PAZ | CHAVE DE RODA APAGADO NO BECO |
| `bike` | "A BICICLETA FEZ UM 8 NO BECO. O VULTO NEM PISCOU." - GAROTO DO PÃO | FIO CORTOU 40 CADEADOS. GATO PRETO CORTOU A CARREIRA DELE | FIO LARGA O ALICATE E A BICICLETA |
| `gate` | "O PORTÃO RANGEU, O PORTEIRO RANGEU. O VULTO NÃO." - SEU AMADEU, DO BOTECO | SEU PÉ DE CABRA ABRIA TODO PORTÃO. GATO PRETO FECHOU A CONTA | PORTEIRO PERDE O PORTÃO |

Nomes na aproximação (`alley_occ_*`): ZECA, NO ESTEPE / FIO, NA BICICLETA / SEU PÉ DE CABRA.

## 2. Supervilão: APAGÃO (2a2)
O nome fica **APAGÃO** como apelido (curto, lê em 1x, dá a piada do prêmio). Civil: **NÉLSON VOLT** (trocadilho de bairro).
| Campo | Texto |
|---|---|
| `alley_apagao_name` / `_nick` | NÉLSON VOLT / O APAGÃO |
| Ficha | O QUE FAZ: CORTA A LUZ DO BAIRRO DE PROPÓSITO. MANIA: JURA QUE A BATERIA É O CORAÇÃO DELE. |
| Manchete | O APAGÃO ACABOU. A CONTA DE LUZ, INFELIZMENTE, NÃO |
| Testemunha (semente da 8b) | "NO ESCURO ELE NÃO ERROU UM GOLPE. O VULTO LUTA COMO GENTE DE ACADEMIA." - VENDEDOR DE ESPETINHO |
| Recorte curto | APAGÃO ACABOU. LUZ VOLTOU |

## 3. Textos de tela
| Chave | Texto |
|---|---|
| `night_alley_name` | BRIGA NO BECO |
| `night_alley_tip` | SEGURE PARA ANDAR. SOLTE QUANDO ELE OLHAR. PERTO, CLIQUE! SE ELE VIRAR, A BRIGA SAI DO MESMO JEITO. |
| `hint_release_click` | SOLTE E CLIQUE! |
| `fighter_name_hidden` | ??? |

**Esconderijo**
| Chave | Texto |
|---|---|
| `hideout_title` | ESCONDERIJO |
| `hideout_board_title` | ESTA NOITE |
| `hideout_scare_card` | RONDA NO BAIRRO |
| `hideout_kind_scare` / `_fight` / `_challenge` / `_revenge` | SUSTO / BRIGA / DESAFIO / REVANCHE |
| `hideout_go` / `hideout_back` | IR / VOLTAR |
| `hideout_quiet` | O BECO ESTÁ QUIETO. POR ENQUANTO. |
| `hideout_dossier_title` / `hideout_shelf_title` / `hideout_shelf_empty` | DOSSIÊ / TROFÉUS / AINDA VAZIA |
| `alley_revenge_mark` | REVANCHE |
| `dossier_missing_legend` | PRECISA DA LENDA {n} |
| `dossier_missing_prev` | VENÇA {nome} PRIMEIRO |
| `dossier_won_stamp` | VENCIDO NA {n}ª CAMPANHA |

**Prévia**
| Chave | Texto |
|---|---|
| `challenge_chance_line` | CHANCE DO DESAFIO: {n}% |
| `alley_ch_done` / `alley_ch_lost` (só o desafio de surpresa) | DESAFIO: FEITO / DESAFIO: PERDIDO |
| `alley_approach_scare` / `_seen` / `_time` | PEGOU DE SURPRESA / ELE VIROU / ELE PERCEBEU |

**Resultado**
| Chave | Texto |
|---|---|
| `alley_ko_banner` | APAGOU! |
| `alley_points_win` | SAIU TONTO E FUGIU |
| `alley_lose_line` | SAIU MANCANDO |
| `alley_prize_title` (vitória) | BRIGA GANHA |
| `alley_win_line` | O BECO FICOU QUIETO. O DOSSIÊ ANOTOU. |
| `alley_lose_title` (derrota) | NOITE PERDIDA |
| `alley_lose_sub` | O CAPUZ VOLTA NO PRÓXIMO RELÓGIO. A REVANCHE FICA NO QUADRO. |
| `alley_challenge_cleared` | DESAFIO CUMPRIDO |
| `alley_style_unlocked` | ESTILO NOVO: {estilo} |
| `alley_dossier_new` / `alley_clipping_new` | FICHA NOVA NO DOSSIÊ / RECORTE NA PAREDE |

**Desafios (1 linha)**
| Bandido | Chave | Texto |
|---|---|---|
| `tire` | `alley_ch_surprise` | PEGUE DE SURPRESA E VENÇA |
| `bike` | `alley_ch_early` | VENÇA ATÉ O 2º ROUND |
| `gate` | `alley_ch_clean` | VENÇA COM 60% DA VIDA |
Aviso: o "2º" e o "60%" estão escritos no texto. Se o Designer mexer em `max_round` ou `min_life` (P2 do design), o texto tem de acompanhar.

## 4. Estilos (personalização)
| Chave | Texto | Vem de |
|---|---|---|
| `disc_opt_headband_color_night` | FAIXA DA NOITE | Zeca Estepe |
| `disc_opt_socks_night_wraps` | ATADURA DA NOITE | Fio |
| `disc_opt_shorts_color_night` | CALÇÃO ESCURO | Seu Pé de Cabra |
| `disc_color_night` | NOITE | (nome curto, se a linha de cor usar `disc_color_<id>`) |

## 5. Título da imprensa (2a2)
`press_title_apagao`: **O VULTO QUE RELIGOU A LUZ** (25 caracteres). Alternativas, se não couber: O RELIGA-BAIRRO / O QUE ACENDEU O BECO.

## Para o Programador e UI/UX
- `revenge_mark` **já existe** (texto da liga, "VOCÊ PERDEU PRA ELE"). Por isso a marca da briga é `alley_revenge_mark` (REVANCHE). O design previa `revenge_mark`; usar a nova chave.
- `alley_<id>_portrait` (em `dossier.portrait` do `ronda.json`) é id de arte, não de texto: não gravei nada.
- As chaves do Apagão (`alley_apagao_*`, `press_title_apagao`) estão gravadas, mas o bloco `boss` do `ronda.json` é da 2a2.
- `alley_tire_rap` e as outras fichas têm `\n` entre "O QUE FAZ" e "MANIA".
- Placeholders novos: `{estilo}`, `{nome}`, `{n}`.
- **Ajuste pós-QA (B2/B4):** nome do bandido só após a vitória. Chaves anônimas novas: `alley_occ_<id>_anon` (topo da aproximação) e `alley_<id>_anon` (prévia); `<id>` = tire, bike, gate. Tela cheia usa as chaves normais depois de vencer.
- B4: `alley_bike_nick` agora "O BRAÇO DE ALICATE" (os 3 apelidos têm artigo, então "VENÇA O ... PRIMEIRO" fica certo). `ronda_level_label` = "LENDA {n}" e `dossier_missing_legend` = "LENDA {n}".
- Os nomes de botão têm no máximo 21 caracteres (maior: ATADURA DA NOITE, 16; RONDA NO BAIRRO, 15). As frases longas (`night_alley_tip`, `alley_lose_sub`, testemunhas) são de caixa de texto, não de botão.
