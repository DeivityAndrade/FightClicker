# Fase 5.2 — Clique sem teto: QA

Dono: QA. Data: 2026-11-12. Branch: `fase-5.2`. Contra: `fase5.2-escopo.md` (12 critérios + "Decisões do Diretor"), `fase5.2-design.md`, `fase5.2-api.md`, `fase5.2-textos.md`.
Nada em `scripts/`, `scenes/`, `ui/`, `data/` foi tocado. Save real do dono: copiado antes, conferido por MD5 depois (igual) e o guarda da bateria também passou.

**alinhamento-ui: 144 estados, 0 problemas** (inclui os 18 estados `f52_*`; capturas em `%APPDATA%\Godot\app_userdata\Fightclicker\ui_audit_saida\`).

## 1. O que rodei
| Item | Comando / arquivo | Resultado |
|---|---|---|
| Bateria | `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1` | **TODOS OS TESTES PASSARAM** (2288 PASS, 0 FAIL, cena principal 120 frames sem erro, save real igual antes/depois) |
| Alinhamento | `Godot_console --path E:\Fightclicker --resolution 1280x720 --script res://tools/ui/ui_audit.gd -- --estados todos` | `ESTADOS 144 \| PROBLEMAS 0` (saída 0). Olhei as 18 capturas `f52_*` (ver 3) |
| QA extra | `tests/qa_f52_extra.gd` (novo, save em `user://test/qa52_*`) | **144/144 PASS** |
| Sessão pela UI | `tests/qa_f52_play.gd` (novo, copiado do `qa_f51_play.gd`; cliques de mouse sintéticos, janela 1280x720) | 4 sessões, 0 `sem_numero`, 0 avisos (ver 8) |
| Simulador | `tools/sim/fase5_sim.py precos b23 controle carreiras f52` (padrão: 400 no 23b, 48 por perfil na f52) | 13 min; tabelas na seção 5 |
| Simulador, amostra maior | `SIM_N52=96 ... f52` e `SIM_N_23B=2000 ... b23` | seção 5 (há um alerta no 23b) |

## 2. Critérios de aceite
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | L3 e L4 na LOJA, em $, caixa de 3 cliques, arte nova | **OK** | `qa_f52_extra` `_luvas`: cada luva compra -> `luva_em_caixa()`; 1º e 2º clique não abrem, 3º abre; ×2 só conta depois de abrir; sufixo `_glove_l3`/`_glove_l4`. Arte: 32 arquivos `*glove_l4*` contra 32 `*glove_l3*` (nenhum faltando, conferi um a um); manifest tem `glove_l4`, `icon_glove_l4`, `cursor_glove_l4` (+x2/x3), `art_hung_glove_l4`, `fight_player_*_glove_l4`, `event_golden_crew`, `icon_crew_click`. Capturas `f52_l4_sala` e `f52_l4_luta` mostram a luva azul de torneio na sala e na luta; `f52_loja_*` mostra o ícone da L3/L4 e "MÁXIMO". O cursor usa `"cursor" + sufixo_luva()` (`ui/ui_tema.gd:298`): `cursor_glove_l4` existe. Cursor em movimento não dá para ver em captura estática (conferido só por código/manifest) |
| 2 | L3 em ≤ 5 min depois de chegar; clique ≥ 2× | **OK** | Sim: "L3 depois de mudar" mediana 0:00–0:04, p90 ≤ 2:59 (os 6 perfis). Sessão UI (`play4`): L3 comprada 4 s de jogo depois de chegar à academia com $1.500; `multiplicador_luva` ×2 por nível |
| 3 | Luva dourada da equipe: aparece, paga 30–45 s, visual diferente, muda por dado | **OK** | `crew_chance` 0,5 -> 51,3% de bolsas em 4.000 eventos; 0,25 -> ~25% (só trocando `dados.golden_crew_chance`); espera 60,5–100,0 s. Bolsa paga exatamente `max(45 × renda_sem_mao, 40 × por_clique)` (conferido 3 vezes na UI: "previsto 86.4K" = ganho). Sprite `event_golden_crew` (saco de moedas) x `event_golden_glove` (luva): `f52_evento_bolsa` e `f52_evento_luva` distinguem de longe |
| 4 | Clique no fim do conteúdo ≥ X (X = 25% do Designer, decisão do Diretor mantém) | **OK** | 1 clique / renda sem a mão: 54–72% (mediana), pior caso 52% (96 jogadores x 8 carreiras, 3/4/5 por s) |
| 5 | Tempo morto: carreira 1 ≤ 10:00 a 4–5/s e **≤ 10:32 a 3/s**; academia ≤ 10:00 | **OK (3/s no limite)** | p90 carreira 1: **8:01** (5/s), **9:01** (4/s), **10:32** (3/s; 96 jogadores; 10:02 com 48). Academia p90 4:01–7:00. "Próxima coisa" p90 ≤ 6:44 (garagem), ≤ 4:40 (academia): bem abaixo de 10:00 |
| 6 | **OBRIGATÓRIO:** Jiu-jitsu 3/s vence o Kid em 1–2 carreiras e nunca depois do Boxe | **OK** | Mediana **1 x 1** (Boxe x Jiu-jitsu), 96 jogadores: média **1,38 (Boxe) x 1,31 (Jiu-jitsu)**; 48 jogadores: 1,27 x 1,21. Kid em ≤ 2: 81% x 85%. Ver nota R2 (por jogador e a 5/s) |
| 7 | 23b: ≤ 25% (±2), nenhum cinturão antes de 20:00, 400 jogadores | **OK com alerta** | 400 jogadores: **25,5%** (5/s) e **24,8%** (4/s); mais cedo **20:20** (5/s) e 22:51 (4/s). Nenhum antes de 20:00: **a condição do Diretor (subir a melhoria 3 para $300K) não disparou**. **ALERTA R1:** com 2.000 jogadores o mais cedo cai para **19:48** (5/s) e a taxa vai a 26,6% / 26,2% |
| 8 | 1ª derrota 10–15 min; Boxe x Jiu-jitsu ≤ 10% (controle, decisão 2); Kid em 1–2 carreiras a 4–5/s | **OK (medido pelo controle)** | 1ª derrota 13:14 (5/s) / 14:44 (4/s). Controle: 0,1% / 3,8% / 12,3% (3/s fica em 12,3%, "ruído aceito" pelo Diretor). Sequência: 14,0% / 27,0% / 30,3% (Jiu-jitsu na frente), é a dívida registrada para a 5.4. Kid: mediana 1 a 4/s e 5/s nas duas artes |
| 9 | Robô x Dudu: causa explicada, taxa de volta ao nível da Fase 5 | **OK** | Design seção 6 (o robô). Medi: 49 derrotas em 2.000 (5/s, 2,5%) e 70 (4/s, 3,5%); em 400: 9 e 13. Nenhum número do jogo mudou por causa dele |
| 10 | Save migra sem perder; quem tem L2 vê a L3; caixa fechada de save antigo continua | **OK** | `qa_f52_extra`: v7 com `glove_level 2` -> L3 à venda, x4 preservado; v7 com caixa da L2 (1 clique batido) continua, trava a L3 até abrir; v7 -> v8 mantém treino, dinheiro, fama, luva, escada, nº da carreira, sem avisos; `glove_level` 5/99/-1/2.5/"3"/null/1e30 vira 0–4 |
| 11 | Telas mexidas com `ui_audit` em 0 problemas | **OK** | 144 estados, 0 problemas; olhei LOJA (L3, L4 na caixa, L4 sem dinheiro, Grito comprável/sem dinheiro/hover/comprado), caixas L3 e L4, evento luva, evento bolsa, hover e aviso da bolsa, L4 na sala e na luta, contador, crítico menor, destaque único |
| 12 | `run_tests.ps1` passa inteiro e não toca o save real | **OK** | primeira linha da seção 1; MD5 do `save.json` e do `save.json.bak` igual ao backup |

### Itens específicos pedidos
**Luvas.** L3/L4 chegam na caixa (3 cliques); a próxima fica trancada (`pode_comprar_luva()` e `comprar_luva()` recusam) enquanto a anterior está na caixa; ×2, ×4, ×8, ×16 com as quatro (`gs.multiplicador_luva() == 16.0`); 100 tentativas de compra com $1e12 compram só 4 luvas e o gasto bate ($1.200 + $2.500 + $120 + $500 + $1.500, 1 Grito só). L4 aparece na sala, na luta, no cursor (manifest/código) e na LOJA.

**Evento dourado.** Frequência de bolsa ~50% (0,513 em 4.000). A bolsa **não liga o FRENESI** (`frenesi_restante` igual antes e depois, inclusive com FRENESI já ligado: continua 3,0 s e a bolsa não multiplica por 7). Luva ×7 continua `mult_frenesi() == 7`. Segundo clique no mesmo evento recusa e não paga em dobro. Janela aberta (`definir_modal`) ou luta aberta por 400 s: nenhum evento aparece, e `pegar_evento_dourado()` recusa com janela aberta. O ganho cai no atributo do foco.

**Grito da equipe.** Comprado com $ (`$1.500`); respeita a reserva da mudança (com cinturão e destino pendente: `loja_estado` = "reserve" com `custo + reserva - 1`, compra com `custo + reserva`, dinheiro restante = reserva). Cada clique manual soma `crew_share × producao_total()` (clique 241 com equipe 240/s na sessão UI; soma exata no teste). `auto_socar()` e o assistido **não** ganham (assistido ≥ 6× abaixo do clique). Crítico multiplica clique + Grito. Persiste: save grava `crew_click: true`, recarrega e `por_clique()` bate. **NOVA CARREIRA zera** (`crew_click_comprado == false`, e o save depois fica `false`). Entra no `menor_preco_loja()`.

**Save.** v7 -> v8 com o save em `user://test/`; `crew_click` corrompido (`"sim"`, 1, 0, 1.0, null, [], {}, "true", -1, 1e308) vira `false` sem perder o resto do save. v8 com L4 na caixa (2 batidas) e Grito carrega certo (3 luvas abertas).

## 3. Capturas olhadas (`f52_*`)
Todas limpas: texto centralizado nos botões, "COMPRAR $1.20K" / "$2.50K" alinhados, "MÁXIMO" no lugar do botão, "ABRA A CAIXA ANTES." ocupando a linha certa, ícone da luva azul no card da L4, caixa pequena de papelão ao lado do lutador. Pontos que são decisão (não bug): aviso da bolsa "A TORCIDA ENCHEU A BOLSA! +1.22K", crítico grande "+1.50K RES!" com 3 letras, LOJA com rolagem (o card do Grito aparece cortado embaixo até rolar; a seta amarela indica), retrato do jogador no topo da luta ainda com luva vermelha.

## 4. Desvios da 5.1 (2.7)
| Desvio | Resultado |
|---|---|
| Um destaque só na loja | **OK**: na LOJA só o "CONTRATAR" tem contorno amarelo; na aba TREINO só a Esteira (laranja). Nunca os dois no mesmo cartão (`f52_destaque_unico`) |
| Contador "0/4" com folga | **OK**: fica embaixo do ícone, sem encostar no texto (`f52_contador`) |
| Texto flutuante grande menor | **OK**: "A ESTEIRA GEMEU!" em 1x e "+1.50K RES!" (3 letras) não cobre a sala inteira (`f52_critico_menor`). Ainda é o maior texto da sala; decisão do Diretor |

## 5. Balanceamento (simulador, números do próprio QA)
| Medida | Meta | Medido | OK? |
|---|---|---|---|
| Jiu-jitsu 3/s: Kid (mediana, 96 jogadores) | 1–2, nunca depois do Boxe | 1 x 1; média 1,31 x 1,38 | OK |
| 23b (400): cinturão na 1ª | ≤ 25% (±2) | 25,5% / 24,8% | OK |
| 23b (400): mais cedo | ≥ 20:00 | 20:20 / 22:51 | OK, 20 s de folga |
| 23b (2.000): mais cedo | (observação) | **19:48** / 21:56; 26,6% / 26,2% | **ALERTA R1** |
| 1ª derrota carreira 1 | 10–15 min | 13:14 / 14:44 | OK |
| Tempo morto carreira 1 (p90) | ≤ 10:00 (4–5/s), ≤ 10:32 (3/s) | 8:01 / 9:01 / 10:32 | OK (3/s igual ao limite) |
| Tempo morto academia (p90) | ≤ 10:00 | 4:01–7:00 (pior caso 8:00) | OK |
| 1 clique / renda sem a mão no fim | ≥ 25% | 54–72% (pior 52%) | OK |
| "Próxima coisa" (p90) | ≤ 10:00 | garagem ≤ 6:44, academia ≤ 4:40 | OK |
| Kid mediana 4–5/s, duas artes | 1–2 | 1 | OK |
| Kid na carreira da chegada, 5/s | (decisão 4: aceito) | 44% (Boxe) / 39% (Jiu-jitsu) | aceito |

## 6. Bugs
Nenhum bug funcional encontrado. Falhas dos meus testes extras (3) eram erros do próprio teste (fórmula e comparação de tipo), corrigidos no `qa_f52_extra.gd`.

| # | Gravidade | Dono | Descrição |
|---|---|---|---|
| B1 | Baixa (pendência conhecida) | UI/UX ou Artista | Retrato do jogador no topo da luta continua com luva vermelha com a L4 (`f52_l4_luta.png`). Decisão do Diretor: registrar como pendente, baixa prioridade |

## 7. Riscos
| # | Risco | Detalhe |
|---|---|---|
| R1 | **Cinturão antes de 20:00 aparece com amostra maior (ALERTA)** | Com o 23b pedido (400 jogadores) ninguém chega antes de 20:00 (mais cedo 20:20) e a condição do Diretor não dispara. Mas rodando `SIM_N_23B=2000` o mais cedo a 5/s é **19:48** (12 s antes) e a taxa sobe para 26,6%. É 1 jogador raro em 2.000 (azar de FRENESI + bolsa), mas a folga de 20 s do design não segura a cauda. Se o Diretor quiser a margem de verdade: subir `bag_leather`, `treadmill_motor`, `rope_beads` para $300.000 (a alavanca que ele escreveu) e remedir 5, 7 e 8 |
| R2 | Jiu-jitsu x Boxe por jogador e a 5/s | A meta mandatória (3/s) fecha na mediana e na média. Por jogador (mesma semente), o Jiu-jitsu chega ao Kid **depois** do Boxe em 28 de 96 a 3/s (23 a 5/s, 21 a 4/s). A 5/s a média do Jiu-jitsu (1,00) fica pior que a do Boxe (0,85), com 96 jogadores. Escopo só obriga a 3/s; fica como informação para a 5.4 |
| R3 | Boxe x Jiu-jitsu na sequência | 14,0% / 27,0% / 30,3% (Jiu-jitsu na frente), controle 0,1% / 3,8% / 12,3%. Aceito pelo Diretor (decisão 2); vira obrigatório ≤ 10% na 5.4 |
| R4 | Tempo morto 3/s no limite | p90 10:32 = o teto aceito; qualquer mexida em número pode estourar. Com 48 jogadores deu 10:02 (degraus de 30 s do robô) |
| R5 | Sessão pela UI curta | As sessões pela UI não passam da academia sem ajuda (a máquina de 4x de velocidade rodou ~1/4 do tempo de jogo esperado com o simulador rodando em paralelo). Cobri o caminho L3/L4/bolsa/FRENESI na academia injetando o estado inicial (cinturão, arte, atributos) e a compra do Grito na garagem com dinheiro extra. Uma sessão limpa de 60 min reais de ponta a ponta não foi feita |
| R6 | Aviso no console do auditor | `ui_audit` imprime "WARNING: GameState: Escada passou do 1º adversário de 'gym' na garagem" no estado montado do auditor (`_novo_jogo`); vem do estado fabricado, não do jogo normal. Sem efeito |

## 8. Sessões pela UI (`tests/qa_f52_play.gd`)
- **play (4/s, do zero, 25 min reais):** 3 carreiras, bolsa e luva ×7 pegas clicando na sala; 0 cliques sem número flutuante; 0 avisos. Não passou da garagem (robô fraco).
- **play2 (garagem com $7.000 e eventos a cada 12–20 s):** Grito comprado ("clique agora 241, equipe 240/s"), L1/L2 abertas pela caixa; eventos pegos: luva ×7 = 8, bolsa = 4. Bolsa pagou exatamente o previsto: "80.1K -> 83.2K (valor_bolsa previsto 3.11K)", "123K -> 133K (previsto 10.2K)"; FRENESI não ligou na bolsa.
- **play3 (academia, $1.500, eventos a cada 15–25 s):** 10 bolsas e 2 luvas ×7 pegas; "BOLSA 78.5K -> 94.8K (previsto 16.3K)"; sem erro.
- **play4 (academia, L1 e L2 já abertas):** `comprou luva nivel 3` 4 s depois de chegar, `caixa glove_l3 aberta` ao vencer o Tonhão (VITORIA, $2.520), `comprou luva nivel 4`, `caixa glove_l4 aberta` 1 s depois (3 cliques pelo mouse); 3 bolsas e 4 luvas ×7 pegas depois da L4; derrota para o Kid sem erro e NOVA CARREIRA entrou.
- A L4 aparece na sala/luta/LOJA nas capturas do auditor; o cursor da L4 conferido por manifest e arquivos, não por captura em movimento.

## 9. Arquivos novos do QA
- `E:\Fightclicker\tests\qa_f52_extra.gd` (144 asserts, save de teste).
- `E:\Fightclicker\tests\qa_f52_play.gd` (sessão pela UI; argumentos `-- <prefixo> <semente> <escala> <cps> <max_carreiras> [gym|boost]`).

## Veredito
**Pronto para o Diretor revisar**, com 1 alerta para ele decidir: o 23b com 400 jogadores passa (25,5% / 24,8%, mais cedo 20:20), mas com 2.000 aparece um cinturão aos 19:48 (R1); se quiser margem de verdade, sobe a melhoria 3 para $300K antes de integrar. Nenhum bug funcional; a única pendência é o retrato da luta (B1, baixa).
