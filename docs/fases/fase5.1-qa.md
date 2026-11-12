# Fase 5.1 — Garagem clara + caixa: QA

Data: 2026-11-12. Branch `fase-5.1`. Save real do dono: md5 igual antes e depois (277af7c2...). Nada de `scripts/`, `scenes/`, `ui/`, `data/` foi alterado pelo QA.

alinhamento-ui: 126 estados, 0 problemas

## Evidências
- `tools/run_tests.ps1` -> `TODOS OS TESTES PASSARAM` (guarda do save real: 4/4).
- `ui_audit.gd --estados todos` -> `ESTADOS 126 | PROBLEMAS 0`. Capturas f51_* e f5_* (regressão) vistas.
- Novos testes do QA: `tests/qa_f51_extra.gd` (42/42 PASS), `tests/qa_f51_ui.gd` (teclas, janela, geometria), `tests/qa_f51_shot.gd`, `tests/qa_f51_play.gd` (sessão pela UI).
- Simulador: `fase5_sim.py b23 caixa carreiras`.

## Critérios de aceite
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | 5 s: onde clicar, Treino, onde lutar | OK (por inspeção) | `f51_garagem.png`: Treino 1,25K em fonte grande, "POR CLIQUE" grande, LUTAR é o maior botão. Precisa do teste com pessoa real (dono) |
| 2 | Nenhum texto fixo sobre a cena | OK | Sem plaquinhas/"SEGURE SHIFT"/chip. Só o botão-ícone de assistido (sem texto) abaixo do alvo e a marca de fita sem texto. Textos flutuantes são juice. Ver B3 e nota sobre o pôster "SOCO" (arte de cenário) |
| 3 | ≤ 3 tamanhos; uma cor por moeda; preço nunca vermelho | OK | Hero x2, resto x1; Treino verde, Dinheiro dourado, Fama rosa, Legado roxo; preços sem saldo apagados (f51_garagem/previa). Resistência amarelo-escuro como decidido |
| 4 | Fama, Legado, local, prêmio, teclas, "?" , bloqueados, fita, Shift em ≤ 1 hover/clique | OK | `f51_hover_fama/legado/local/proxima/teclas/assist/atributo/foco`, `f51_loja_trancado`, `f51_marca_hover/trancada` |
| 4b | Dica "Segure SHIFT" só nas 3 primeiras vezes | OK | `faixa_assistido.gd:14` `DICA_VEZES := 3` (contador por sessão, decisão já aceita) |
| 5 | Prévia com respiro; ui_audit 0 | OK | `f51_previa.png`: blocos separados, aviso de perder continua; audit 0 |
| 6 | Corda no gancho (296,166) nas 2 salas, sem quadro torto | OK | `manifest rope_hook [296,166]`; `f51_corda_gancho`, `f51_gym`; mockup `fase51_animacoes_corda_quadros_x3.png` com 6 quadros, nenhum torto |
| 7 | Caixa: compra gera caixa, 3 cliques, não some (foco/luta/save) | OK | test_fase51 118 checks + `qa_f51_extra` (reabre com hits 2; 10 batidas = 3 aceitas) + `qa_f51_ui` |
| 8 | Nova carreira só com o saco | OK | `qa_f51_extra`: caixas [], aparelhos ["punching_bag"], luva 0. Depois de aposentar na academia coberto por test_fase51 |
| 9 | Melhorias instantâneas | OK | test_fase51 ("melhoria não gera caixa") |
| 10 | Balanço: 1ª derrota 10–15; cinturão ≥ 20:00; tempo morto ≤ 10 | OK | Sim: 1ª derrota 11:14 (5/s) e 12:44 (4/s); cinturão mais cedo 20:25 / 22:52; tempo morto mediana carreira 1 = 5:00 / 5:30 / 6:30 (p90 até 13:32 a 3/s, só p90) |
| 11 | Save v6 -> v7, aparelho antigo não vira caixa | OK | test_fase51 e `qa_f51_extra` (v0->v7 em cadeia) |
| 12 | run_tests passa; não toca save real | OK | acima |

## Checagens da caixa (lista pedida)
| Item | Resultado |
|---|---|
| Abre com 3 cliques; clique na caixa não treina; Espaço nunca bate | OK (`clicar()` x50 e Espaço x10 = 0 hits; clique na caixa: hits 1, `clicou` 0; clique no alvo não bate na caixa) |
| Ignora clique com janela/prévia/luta/arte/árvore/aposentar | OK (prévia aberta: hits inalterados; luta: `bater_caixa` false; código `sala.caixa_liberada`) |
| Mantém cliques após foco, luta, MUDAR, save/reload | OK |
| Some em NOVA CARREIRA | OK |
| Corda/arte travadas com esteira em caixa; luva seguinte travada | OK (`pode_comprar_luva` false, `comprar_luva` recusa) |
| ≤ 5 caixas por carreira, ≤ 3 juntas | OK (sim: 5; max juntas na prática: corda + arte + luva = 3) |
| Animação ≤ 1,5 s | OK (open_seconds 1,2; timeline 0,6 + 0,3 = 0,9 s de sprite) |
| Caixas não cobrem alvo nem lutador | OK (nenhuma área intersecta ALVO nem lutador) — ver B2 para sobreposição entre caixas |
| Teclas 1–4 não focam aparelho em caixa | OK (2,3,4 com esteira em caixa: foco continua `punching_bag`) |
| `applies_to.glove=false` = luva instantânea | OK |
| Save corrompido sanitizado | OK (boxes string/dict/null/número/200 repetidas/hits NaN, INF, 1e30, string/ item vazio/ json truncado: sempre ≤ 1 caixa válida, hits 0..2, reabre igual) |

## Contagem de caixas por carreira (sim, 16 jogadores x 8 carreiras)
Mediana e máximo 5 em todos os perfis (meta ≤ 6). Mão na caixa: 15,5 s (5/s), 16,5 s (4/s), 17,5 s (3/s) = 1,4–1,7% da carreira.

## Sessão longa pela UI (`qa_f51_play.gd`, escala 3x, 4,5 cliques/s)
Caixas abertas por clique de mouse real: esteira, corda, luva 1, luva 2, pera; zero "BUG: clique na caixa treinou". Chegou à academia, escolheu arte (Boxe), comprou o aparelho da arte e abriu a caixa dele (foco foi para ele). O script do QA acusou um erro próprio (janela liberada ao fechar) após a escolha da arte; não é erro do jogo. Sessão interrompida por tempo, sem carreira 2 completa pela UI (a nova carreira está coberta por teste unitário).

## Bugs
| # | Gravidade | Descrição | Passos | Dono |
|---|---|---|---|---|
| B1 | Baixa | Caixa do boneco (`box_big`, 56x45) e da corda (`box_small`) têm áreas de clique que se sobrepõem em ~14x6 px (Jiu-jitsu, com as duas caixas fechadas). Visualmente se tocam. O clique na faixa comum vai sempre para a 1ª da lista | Carreira Jiu-jitsu: comprar corda e boneco sem abrir; clicar em (242..256, 240..246) da sala. Reproduzido por `tests/qa_f51_ui.gd` e `qa51/bjj_3caixas.png` | UI/UX ou Diretor de Arte (afastar slot ou reduzir click_rect) |
| B2 | Baixa | Caixa da luva (386,288, área até y=290) encosta na borda inferior da sala; o rodapé do sprite fica no limite do chão (visível, mas sem folga) | `f51_caixas_varias.png`, canto inferior direito da sala | Diretor de Arte |
| B3 | Muito baixa | Textos flutuantes da abertura ("CHEGOU: ESTEIRA!", "RACHOU!", "ABRIU!") se empilham/sobrepõem no mesmo ponto durante o 3º clique | `f51_caixa_abrindo.png` | UI/UX |
| B4 | Muito baixa | Botão-ícone do treino assistido fica no chão da sala logo abaixo do alvo e cobre a ponta da esteira quando ela está em foco | `f51_anim_esteira.png` (ícone sobre a esteira) | UI/UX |

Nenhum bug bloqueante. Nenhum problema de alinhamento.

## Riscos
- Critério 1 (5 s) e a clareza geral só se confirmam com pessoa real (item 1 da seção 7 do escopo).
- Dica "Segure SHIFT" conta por sessão: jogador que abre o jogo de novo vê de novo (decisão aceita).
- Tempo morto p90 da carreira 1 a 3–4 cliques/s passa de 10 min (11:31–13:32); a mediana fecha. A caixa adicionou ~30 s no p90 (já previsto pelo Designer).
- Derrotas do robô no Dudu subiram com a caixa (3 s a menos de treino aos 3:00); jogador real vê o selo de risco.
- Processos de teste do QA (`qa_f51_play.gd`) podem ter ficado em segundo plano (não consegui encerrá-los; terminam sozinhos no limite de 25 min).

## Veredito
Pronto para o Diretor revisar. Bugs B1–B4 são baixos e não impedem a fase.
