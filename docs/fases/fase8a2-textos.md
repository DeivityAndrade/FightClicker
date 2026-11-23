# Fase 8a2 — Textos do centro de treinamento (Roteirista)

Tudo abaixo já está gravado em `data/center.json`, `data/locations.json`, `data/ui_texts.json`, `data/dialogos.json` (e uma linha em `data/skill_tree.json`, ver D12). Tela em MAIÚSCULAS; balão em minúsculas, 2 linhas, máx. 26 caracteres, sem `º` e sem `à`. Números nunca foram tocados.

## 1. Nomes e textos
| Item | Texto |
|---|---|
| Local (`locations.json`) | Centro de Treinamento Raízes (mantido do rascunho). Ambiência: "Pé-direito alto, piso de borracha e a foto da garagem pendurada torta, de propósito." |
| Botão / descrição da mudança | MUDAR / "Sai da academia. Mais treino, alunos novos e aparelhos de verdade." |
| Gerador | **Alunos da Raízes** (confirmado). "Vieram pelo recorte do jornal. Ficaram pelo saco." Aparece como: gente de camisa preta com o R no peito |
| Região da árvore | CENTRO |
| Nós | Porta aberta (+50% TREINO POR CLIQUE) / Agenda do centro (+1 DIA DE PREPARO ANTES DE CADA LUTA) / Piso de borracha (TREINO FORA DA GARAGEM +25%) |

### 5ª melhoria (só no centro; textos do rascunho confirmados)
| id | Nome | Descrição |
|---|---|---|
| `bag_center` | Saco de competição | Couro de verdade. Nem parece nosso. |
| `treadmill_center` | Esteira com painel | Tem botão de subida. Ninguém usa o de descida. |
| `rope_center` | Corda de rolamento | Gira sozinha. O pé que se vire. |
| `tech_boxing_center` | Plataforma de pera | Madeira maciça. O eco chega na recepção. |
| `tech_bjj_center` | Boneco de competição | Tem braço que dobra. E reclama. |
| `tech_mt_center` | Saco de lona dupla | Pendurado em corrente de navio. |

## 2. Patrocinador
Marca: **Autopeças Vale Forte** (a mesma da faixa do Clube Ferroviário na 8a1, então o patrocínio "se paga" no cenário). Para a linha curta da vitória uso `short_name` **VALE FORTE**.
| Campo | Texto |
|---|---|
| `name` / `short_name` | Autopeças Vale Forte / VALE FORTE |
| Envelope (`sponsor_envelope`) | PROPOSTA |
| `offer_title` | PROPOSTA DE PATROCÍNIO |
| `offer_line` | Metade da bolsa a mais em cada vitória. Em troca, o nosso nome no seu calção. |
| `accept_button` / `close_button` | ASSINAR / AGORA NÃO |
| `win_line` | PATROCÍNIO {marca}: +${n}  (`{marca}` = `short_name`) |
| Estado assinado (`sponsor_signed`) | CONTRATO ASSINADO |

## 3. Mudança (ui_texts)
| Chave | Texto |
|---|---|
| `move_title_center` | CENTRO RAÍZES |
| `move_effect_center` | TREINO x{mult} / ALUNOS NOVOS |
| `move_no_fights_center` (aviso: aqui não há luta nova) | SEM LUTA NOVA POR ENQUANTO |
| `move_arrived_center` (toast) | BEM-VINDO AO CENTRO RAÍZES! |
| `hud_next_move_center` | MUDE PARA O CENTRO |
| `belt_regional_soon` (trocada; estava "CHEGA NA PRÓXIMA VERSÃO") | O CENTRO ESPERA: USE O MUDAR |
| `map_region_center` | CENTRO |
Aviso de custo: reaproveita `move_price`, `move_no_money` ("FALTA ${n}") e `move_reserve` ("GUARDE ${n} PARA A MUDANÇA"), que já são genéricos. O número vem do código (25.000), nunca no texto.

## 4. Osmar na chegada (`dialogos.json`)
| id | Quando | Fala |
|---|---|---|
| `cl_primeiro_centro` | 1ª chegada da linhagem (`once`) | pendura a foto ali, torta. / pra lembrar da garagem. |
| `cl_centro_volta_1` | chegadas seguintes (`rest`, grupo `centro_volta`) | casa grande. a foto torta / continua na parede. |
| `cl_centro_volta_2` | idem | tem lugar pra todo mundo. / menos pra desculpa. |
| `cl_centro_volta_3` | idem | daqui o vale inteiro / enxerga a raízes. |

## 5. Foto, cartaz vencido e recorte (`dialogos.json → objects`)
| Objeto | Texto |
|---|---|
| `old_photo_center` (foto torta na parede do centro) | A foto veio da garagem. / Torta de novo. De propósito. |
| `regional_poster_won` (cartaz na academia, hover) | título LIGA REGIONAL DO VALE; "RAÍZES LEVA O CINTURÃO DO VALE" / "COM {nome}" (`{nome}` = discípulo daquela campanha) |
| `regional_poster_sponsor` (linha extra, só com contrato assinado) | APOIO: {marca} (`short_name`) |
| `regional_clipping` (recorte; D10: preso no cartaz na academia, emoldurado no centro) | título ESCOLA DE GARAGEM DERRUBA O BLINDADO; "O cinturão do Vale agora mora na Raízes."; rodapé "Dessa vez acertaram: {school}." (piada de volta do recorte do Gato Preto, onde a errata errava o nome) |

## Decisões
- **D12:** o Ventilador novo (`gym_fan`) e o Piso de borracha passam a dizer **"TREINO FORA DA GARAGEM +{pct}%"**. Só texto (o efeito não mudou), e fica correto na academia e no centro. Alterei `effect_text` em `data/skill_tree.json` (único campo de texto mexido fora dos arquivos novos). Nenhum teste procura a frase antiga.
- Marca do patrocínio ficou **Autopeças Vale Forte** (não "Auto Peças Vale") para casar com a faixa da 8a1.
- `short_name` é campo novo opcional em `sponsor`: se o código preferir só `name`, a linha da vitória fica longa (~40 caracteres); recomendo usar o `short_name`.
- Gatilho novo `center_arrival` criado em `dialogos.json → triggers` (prioridade 6, adiado, 1 por campanha, como o `gym_arrival`).

## Para o Programador
- Gatilho `center_arrival`: disparar em `mudar()` para o centro, depois de gravar o marco `center_arrival`. As falas usam `conditions.location: "center"`; a única usa `milestone_present: ["center_arrival"]`, as de volta usam `after_line: "cl_primeiro_centro"` (mesmo padrão de `cl_primeira_academia`).
- Chaves por local: a UI do cartão da mudança deve ler `move_title_<local>`, `move_effect_<local>`, `move_arrived_<local>`, `hud_next_move_<local>` (a academia continua nas chaves sem sufixo; o centro tem as `_center`). `move_no_fights_center` é aviso opcional no cartão.
- Objetos (via `texto_objeto`): `old_photo_center` (foto no centro), `regional_poster_won` (placeholder `{nome}`), `regional_poster_sponsor` (`{marca}`), `regional_clipping` (`{school}`).
- `sponsor.short_name` e `win_line` com `{marca}`/`{n}`; `sponsor_envelope` e `sponsor_signed` em `ui_texts`.
- `map_region_center` para o rótulo da região no mapa da árvore; o `region.name` no `center.json` também é CENTRO.
