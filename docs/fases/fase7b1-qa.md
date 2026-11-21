# Fase 7b1 (Muay Thai) — relatório do QA

Pasta `E:\Fightclicker\.claude\worktrees\continue-agents-config-722700`, sem commit. Tudo com `APPDATA` temporário (o save real do dono nem foi tocado; o guarda de save passou). Um Godot por vez; janela só no `ui_audit` (`--max-fps 30 --position 1950,40`). Para a comparação com a main usei uma cópia isolada de `HEAD` (= `origin/main`, 8c1531d), apagada depois. Capturas do audit em `C:\Users\deivi\AppData\Local\Temp\qa7b1\caps\` (`f7b1_*`).

## Veredito
**Quase pronto: NÃO passa ainda por causa do B1 (texto da prévia sobreposto às marcas).** O verificador marcou 0 problemas, mas na captura o texto da linha da Canela passa por cima dos ícones das marcas nas 3 táticas. Pela regra do dono ("algo visivelmente torto que o verificador não pegou é bug e a fase não passa"), volta para o UI/UX. Todo o resto passa, com as observações abaixo.

## Automáticos
| Item | Resultado |
|---|---|
| `tools/run_tests.ps1` | **OK** — "TODOS OS TESTES PASSARAM" (4.329 PASS, 0 FAIL; inclui `test_fase7b1.gd`, guarda do save real, cena principal 120 frames). Os WARNING do console são dos testes de dado sujo (esperados) |
| `ui_audit --estados todos` (com janela, uma vez) | **OK pelo verificador** — `ESTADOS 447 \| PROBLEMAS 0`; 18 capturas `f7b1_*` olhadas. **Mas veja B1** (o verificador não pega sobreposição de texto com ícone) |
| Foto `foto.gd` x `origin/main` | **OK, só diferenças esperadas.** Valores (treino, dinheiro, fim, sucessão) idênticos nos 60 pontos do robô e nas 3 lutas do roteiro. Diferem só: (1) chave nova `upgrades.kick_bag: 0` nos `estado` (hash muda por isso); (2) `arvore_mapa` com 4 nós novos do Muay Thai e 3 `estado`; (3) ponto do mentor `first` na sala, [210,254] -> [232,270] (mentor do manifest). Nenhuma outra linha mudou |
| Simulador `fase7b1_sim.py ident choque teto forca campanha` | **OK** — `ident` 3.000/3.000 idênticas (sem arte, Boxe, JJ); tabela do Choque igual à do design; `teto` e `forca` iguais ao design; `campanha` refeita (100 jogadores x 6 campanhas) |

## Critérios de aceite (escopo §7, itens 1–8, 13, 14)
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Reconhecer a arte; chute baixo, mancando e chute rodado em >= 1 de 3 vitórias contra o Tonhão | **OK com ressalva** | Pelo jogo de verdade (`tests/qa_f7b1_rodado.gd`, 150 lutas por linha, atributos 2/2/1 com chance 0,60/0,80/0,95): chute rodado **visto** nas vitórias: Agressivo 58–80%, Contra-ataque 94–98%, **Defensivo 16–24%** (abaixo de 1/3). Com o robô do simulador (misto) 43% pela passiva. Marcas, mancando e `PERNA CHEIA!` aparecem nas capturas. O teste do "testador humano que vê 3 lutas sem HUD" **não foi feito** (só automático). Ver Obs. 1 |
| 2 | Prévia honesta (±5) e linha muda com a tática | **OK** | `tests/qa_f7b1_extra.gd`: 6 adversários x 8 estados x 1.000 lutas reais, sem e com o nó `mt_shin`. Diferença média por adversário: de -0,9 a +1,9 pontos (pior: Kid com `mt_shin`, +1,9). Pior estado individual 5,0 pts (sem nó) e 7,0 pts (Kid com `mt_shin`, ruído das 200 sementes da prévia). Linha por tática confirmada no teste do Programador e nas capturas (Agressivo "ELE CONTRAGOLPEIA", Contra-ataque "SEU CONTRAGOLPE MARCA A PERNA", Defensivo sem aviso). "A PERNA SÓ ENCHE EM 2 DE 10 LUTAS" aparece (`f7b1_previa_mt_tarde`). **Texto sobreposto: B1** |
| 3 | Nada muda para quem não usa o Muay Thai | **OK** | Foto sem arte = main, salvo as diferenças esperadas acima. `ident` do simulador 3.000/3.000 (sem arte, Boxe, JJ). Boxe: crítico do clique 10%/x3 e +50%; Jiu-jitsu sem mudança (teste do Programador + o meu) |
| 4 | Luta curta 8–20 s, inclusive com chute rodado | **OK** | 6 adversários x 3 táticas x 600 lutas: `t_end` 5,00 a 16,00 s, que na tela (+1,5 s de intro e +1,5 s de saída) dá **8,0 a 19,0 s**. Só as lutas que terminam em chute rodado: também dentro |
| 5 | Balanço das 3 artes (<= 15%) | **OK (medida da campanha)** | `campanha`, 100 x 6: tempo até o 1º Kid, mediana: Boxe 40:56 / JJ 41:45 / MT 41:22 (4/s) e 46:11 / 46:33 / 46:32 (3/s); diferença mediana <= 2,0%, média <= 4,4%. Metas da visão iguais (1ª carreira 13:56 e 15:26; cinturão na campanha 2). Na medida `forca` (sem calendário) o JJ fica 17,4% (4/s) e 14,1% (3/s) atrás do Boxe: já era assim na 7a1; o Muay Thai fica entre os dois (+6,5% e +5,4% do Boxe) |
| 6 | Escolha da arte: 3 cartões inteiros, sem corte e sem rolagem; Muay Thai só depois da meta; save antigo recebe a arte | **OK** | `f7b1_arte_3cartoes`: três cartões lado a lado, textos e botões ESCOLHER inteiros. Liberação: ver abaixo |
| 7 | Choque do Muay Thai: no tempo rende mais que afobado; teto <= 10% | **OK com ressalva** | Jogo de verdade (`ChoqueLogica`, 60 partidas por perfil): nota média no tempo 1,00 / 0,96 / 0,95 (níveis 0/3/5, vence 60/53/50 de 60); afobado (9/s) e parado 0,25 e **0 vitórias** em todos os níveis. Teto (simulador `teto`): todos_max pior trecho **7,9%** (MT 3/s, Muralha). **Ressalva:** `cedo_max` dá 10,9% (Muralha) e 10,5% (Tonhão) a 3/s, acima de 10%; o Designer já documentou e justificou (mede lutar no amarelo sem custo, não o minigame; o JJ da 7a2 teve o mesmo, 11,1–16,8%). Decisão do Diretor |
| 8 | Saco de chute em caixa, divisão própria; região MUAY THAI só com a arte; nó antigo não muda | **OK** | `tests/qa_f7b1_saco.gd` 23/23: compra com Treino (2.500; recusa sem Treino, sem esteira, Treino negativo, repetida), chega em **caixa**, não foca antes de abrir, divisão medida **0,500/0,350/0,150**, 4 melhorias e não 5, Boxe e Jiu-jitsu não veem nem compram nem focam o saco, Muay Thai não vê pera nem boneco. Árvore: 4 nós novos, trava `art:muay_thai`; `git diff` dos JSON só tem linhas acrescentadas (nenhum nó antigo mudou); captura `f7b1_arvore_mt` sem sobreposição |
| 13 | `run_tests.ps1` verde com save de teste; cópia do save do dono abre sem erro | **OK** | Acima. Save v13 antigo gravado em arquivo e aberto pelo caminho normal: ver "Save" |
| 14 | `ui_audit` com 0 problemas, com os estados pedidos | **OK com B1** | 0 problemas. Estados presentes: 3 cartões, prévia nas 3 táticas + "tarde", HUD das marcas, `PERNA CHEIA!`, letreiro do chute rodado na liga e na borracharia, sala (saco em foco, chutando, descanso, caixa), Choque (começo, combo, chute, prêmio), árvore |

### Mudanças de última hora
- Botão de foco **"CHUTE"** (`focus_label` do saco): cabe, centralizado, mesma largura dos outros (`f7b1_sala_saco_foco`, `f7b1_sala_saco_chute`).
- **"BATIDA"** e **"COMBO"** (Choque): cabem e não cortam (`f7b1_choque_mt_combo`). Ficam encostados em cima da barra/caixas (Obs. 3).

## Liberação do Muay Thai
- Primeira chegada à academia: só Boxe e Jiu-jitsu (2 cartões). **OK**.
- Vitória **de verdade** contra o Kid (`gs.lutar()` + `concluir_luta()`, atributos 20x): a arte só entra ao concluir; entra no mesmo `para_save()` com o marco; repetir `concluir_luta` não duplica. Vencer outro adversário ou perder para o Kid: não libera (teste do Programador). **OK**.
- Save v13 antigo **em arquivo** (`best_wins` 6, sem a arte e sem o marco): abre com `muay_thai`, mostra 3 cartões e pede a fala do Osmar **uma vez** (`cl_muay_thai`, `once`, `defer`). A fala só deixa de ser pedida quando passa na tela (decisão do Programador: "nunca se perde"); recarregar sem a fala ter passado pede de novo, por desenho. **OK**.
- Fala escrita no `dialogos.json` (speaker `coach`, 2 linhas, condição de marco). A cena real com o balão **não foi vista** (o audit não tem estado para a fala); só o motor de diálogo foi testado.

## Choque MT, especial dos cliques e crítico do clique
- **Choque:** 5.000 apertos no mesmo quadro + `passo` NaN/INF/-3/1e9 + nível 99: barra e nota finitas. Determinismo conferido pelo Programador.
- **Especial dos cliques (SUPER):** `tela_luta.gd:832` usa `spin_kick`/`hit_spin` (ou `knee`/`hit_body`); nunca `uppercut` no Muay Thai (só lido no código e nos textos: `fight_special_banner_muay_thai` = "CHUTE RODADO!"). Não reproduzi o especial na janela. Obs. 4.
- **Crítico do clique:** 20% e x4,1 no manual (6.000 cliques: dentro de +-2,5 pts), 10% e x3 no auto-soco (Metrônomo), sem mudar o Boxe (teste do Programador).

## Save (tentar quebrar)
`tests/qa_f7b1_extra.gd` (`_save_sujo`): 10 casos sujos aplicados a um jogo novo e salvos de volta, sem erro de script: `arts_unlocked` com lixo/duplicata/inteiro/null/string/nulo; `career.art` e `last_art` = `muay_thai` sem liberar (caem para "sem arte"); `best_wins` 1e30 / string; `ladder_index` negativo; foco `kick_bag` sem aparelho montado (volta ao padrão); marco e `lines_seen` com tipo errado; `finish` com tipo errado; luta salva com números absurdos (1e30, NaN, 1e400). Em todos a lista de artes ficou só com ids válidos e sem repetição, `luta_atual()`, `previa()` e `artes_para_escolha()` seguem montando e o save regrava. Arquivo truncado (`{"version": 13, "permanent": {"arts_unlo`): abre como jogo novo. `VERSAO_ATUAL` continua 13.

## Valores extremos (motor)
`chance`, `lutar`, `estado_passiva` e `chance_detalhada` com zeros, adversário zero, ambos zero, 1e300, 1e-300, negativos, só FORÇA, NaN, nas 3 táticas, com e sem `mt_shin`: tudo finito, chance em [0,1], `t_end` <= 60. Luta e prévia no jogo com atributos 1e300 e 0: sem erro. `bonus_arte_critico` com ESTILO 1e9: finito e chance <= 1. Soak do robô (`tests/qa_f7b1_soak.gd`: 4 carreiras x 6.000 passos, escolhendo Muay Thai em metade, comprando saco e nós do Muay Thai, lutando nas 3 táticas, aposentando): 0 erro de script, treino/dinheiro finitos, 22 lutas terminando em chute rodado.

## Bugs
**B1 — média — Na prévia, o texto da passiva (Canela) passa por cima dos ícones das marcas, nas 3 táticas.**
Como ver: `f7b1_previa_mt_aggressive`, `f7b1_previa_mt_counter`, `f7b1_previa_mt_defensive` (ampliar o cartão "CANELA" à direita da janela). A linha da passiva tem 4 a 6 linhas ("... ELE CONTRAGOLPEIA", "... SEU CONTRAGOLPE MARCA A PERNA", "... ELE 36% MAIS LENTO") e a última se sobrepõe à fileira dos 3 ícones de perna e "Nº ROUND": no Agressivo "CONTRAGOLPEIA" fica cortada pelos ícones; no Contra-ataque "PERNA" e a última linha; no Defensivo "LENTO". No Contra-ataque a última linha do cartão ("0 EM 10 VITÓRIAS POR CHUTE RODADO") também fica rente ao fim da caixa. O `ui_audit` não acusa (não mede texto x ícone dentro do cartão). Pior caso é o do Contra-ataque (6 linhas). Quem corrige: **UI/UX** (`ui/cartao_passiva.gd`: calcular a altura do texto antes de posicionar a fileira das marcas, ou encurtar a linha em `data/ui_texts.json`, ex. `passive_muay_thai_line`, com o Roteirista) e rodar o `alinhamento-ui` de novo, **olhando** a captura.

**B2 — baixa (cosmético) — O letreiro pequeno "CHUTE RODADO!" nasce parcialmente coberto por números de dano.** `f7b1_luta_mt_cheia`: o texto sob "690K / 802K" fica ilegível por uns instantes (o grande, do fim da luta, lê bem nas duas arenas: `f7b1_luta_mt_rodado_liga` e `..._borracharia`). Quem corrige: UI/UX (se quiser, subir a camada do letreiro).

**B3 — baixa (cosmético) — "BATIDA" e "COMBO" do Choque encostam na barra/nas caixas (1–2 px).** `f7b1_choque_mt_combo`: sem sobreposição e sem corte, mas o rótulo "COMBO" quase toca as caixas 1/2/CHUTE. Quem corrige: UI/UX, se quiser um respiro de 2 px.

Nenhum bug de lógica, de save ou de balanço foi encontrado.

## Observações e riscos (decisão do Diretor)
1. **Defensivo contra o Tonhão mostra pouco chute rodado** (16–24% das vitórias vistas, 12–22% terminando nele; `qa_f7b1_rodado.gd`). O critério "1 de 3" vale se o testador usar Agressivo ou Contra-ataque (a tática certa do Muay Thai, 94–98%). Quem escolher o Defensivo vê a prévia avisar ("0 EM 10 VITÓRIAS POR CHUTE RODADO"), então é honesto, mas pode frustrar o teste de "reconhecer a arte". Se o Diretor quiser garantir 1 de 3 em qualquer tática, é ajuste do Designer.
2. **Teto de 10% (minigame):** a política principal passa (7,9%); `cedo_max` 3/s passa de 10% (10,9% e 10,5%), já documentado pelo Designer. Margem curta; qualquer mudança no prêmio exige rodar o simulador de novo.
3. Prévia honesta: estados individuais com as 200 sementes da prévia chegam a 5–7 pontos de diferença (ruído); a média por adversário fica a menos de 2 pontos.
4. Não vi na janela: o especial dos cliques do Muay Thai (SUPER), o balão da fala do Osmar na sala e a animação do chute baixo/joelhada/clinch em movimento (só quadros parados nas capturas). O teste de reconhecimento por um humano (critério 1) também não foi feito.
5. Cosmético: o lutador de Muay Thai usa luvas de boxe vermelhas em todas as telas (luta, saco, Choque). Não é bug; só registrar caso o Diretor de Arte queira outra coisa.

## Arquivos de teste que deixei
`tests/qa_f7b1_extra.gd` (prévia nos 6 adversários, duração, extremos, save sujo/antigo, liberação real, Choque por perfis; 90/90 PASS), `tests/qa_f7b1_rodado.gd` (chute rodado visto por tática, no jogo), `tests/qa_f7b1_saco.gd` (23/23), `tests/qa_f7b1_soak.gd`. Logs e capturas em `C:\Users\deivi\AppData\Local\Temp\qa7b1\`.

## Veredito curto
**Não está pronto para o Diretor ainda: corrigir o B1 (UI/UX) e repetir o `alinhamento-ui` olhando a captura.** B2 e B3 são opcionais. Depois disso, a fase passa; as observações 1 e 2 são decisões de design para o Diretor.

## Conferência extra pedida pelo Diretor: "N EM 10 VITÓRIAS POR CHUTE RODADO" x luta real
`tests/qa_f7b1_share.gd` (headless, APPDATA temporário, 1.000 lutas por estado e tática, `previa().passive_tactics[t].share_n` x `round(10 x rodados / vitórias)` do motor com os mesmos atributos e adversário da prévia). Estados: os atributos da captura `f7b1_previa_mt_defensive` (Kid, 4,83M/9,66M/21,7M) e 4 estados contra o Tonhão (0,7x a 1,1x do total dele, foco FOR+AGI). 5 estados x 3 táticas = 15 comparações, tolerância 1 em 10.
**Resultado: bateu em todas (16/16 PASS, 0 diferença maior que 1).**
- Captura do Defensivo (Kid): prévia 0 x real 0 (Agressivo 10 x 10, Contra-ataque 0 x 0). O "0 EM 10" é honesto: com esses atributos quase não há vitória pelo Defensivo e a perna só enche em 2 de 10 lutas.
- Tonhão, pares prévia x real: Agressivo 10x9, 5x5, 4x3, 3x2; Defensivo 0x0, 4x4, 2x2, 1x1; Contra-ataque 9x10, 9x8, 7x7, 6x6.
- Os 12%–22% de finais em chute rodado que medi antes no Defensivo viram "1 a 2 EM 10" na prévia, coerente. Em 5 dos 15 casos a diferença é exatamente 1 (arredondamento), nunca 2.
Nenhum bug novo. (Aviso do console: o `print` informativo do meu teste tem um `%` mal escapado; não afeta as verificações.)
