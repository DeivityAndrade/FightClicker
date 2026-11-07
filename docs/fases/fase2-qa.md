# Fase 2 — Treino na garagem: relatório de QA

Dono: QA. Data: 2026-11-05. Godot 4.7.2 (build DEBUG), Windows 11, GPU NVIDIA (GL Compatibility).
Base: `fase2-escopo.md` (24 critérios), `fase2-design.md`, `fase2-api.md`, `fase2-textos.md`, `direcao-visual.md`.
Nenhum arquivo de `scripts/`, `scenes/`, `ui/`, `data/` foi alterado. O save real do dono não existia antes
(só `logs`, `shader_cache`, `test`) e continua inexistente depois; os saves de teste que criei fora de `user://test/` foram apagados.

Screenshots em `C:\Users\deivi\AppData\Local\Temp\claude\d03e7314839aa25e\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\qa2\`
(prefixos `r720_*`, `r1080_*`, `real_*` = captura da janela real, `z_*` = recortes ampliados).

## Como foi testado

| O quê | Comando / arquivo | Resultado |
|---|---|---|
| Bateria automática | `powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1` | **452 PASS, 1 FAIL** (ver BUG-1). Cena principal 120 frames: sem erros. Guarda do save real: PASS |
| Simulador de balanceamento | `...\python.exe E:\Fightclicker\tools\sim\fase2_sim.py` | Reproduz exatamente as tabelas do `fase2-design.md` (usa os `data/` reais) |
| Jogo com janela, entrada sintética (mouse/teclado), 1280x720 e 1920x1080 | `tests/qa_play.gd` (novo, QA) | Saída em `scratchpad\qa2\play720.txt`, `play1080.txt` |
| Jogo com janela e **mouse real do Windows** (SetCursorPos/mouse_event, captura do client) | PowerShell, `--save-dir=user://qa2_real/` | Cursor, rajada de cliques, fechar pelo X. Capturas `real_*.png` |
| Sessão longa simulada, jogando pela UI (clique sintético + compras) | `tests/qa_soak.gd` (novo), 15 min de jogo em ~9 s (`--fixed-fps 60`), headless e com janela | 0 erros de script em 6 execuções (3, 4, 5, 8 cliques/s, rodízio) |
| Saves estranhos | `tests/qa_save.gd` (novo) | ver critérios 21 e 22 |
| Sobreposição de números | `tests/qa_overlap.gd` (novo) | ver seção "Saúde visual" |

`tests/qa_*.gd` não entram no `run_tests.ps1` (só `test_*.gd`).

---

## Critérios de aceite

### Abertura e tela
| # | Critério | Veredito | Evidência |
|---|---|---|---|
| 1 | F5 abre na garagem, sem erros; depuração por tecla escondida documentada | **OK** | `godot --path . --resolution 1280x720 --quit-after 300` (janela real): console só com a linha do driver, sem `ERROR`/`WARNING`. `run/main_scene="res://scenes/garagem.tscn"`. F12 consta em `README.md` ("Teclas"). Ressalva: o resto do README ainda descreve a tela de verificação (BUG-6) |
| 2 | 1280x720 e 1920x1080 nítidos, escala inteira, nenhum painel cobre a sala, texto legível | **OK** | 1280x720: `final_transform` = escala 2,0 origem (0,0). Janela em 1920x1080 (client 1920x1061): escala 2 com faixas, origem (320,171), inteira. F11 (tela cheia 1920x1080): escala 3,0 origem (0,0). Captura real `real_mouse_fora.png`: pixels nítidos, texto de 5x7 legível. Painéis ocupam x 0–128 e 512–640, barra y 290–360; a sala (128–512 x 18–290) fica livre. Só a depuração (F12) sobrepõe a sala, de propósito |
| 3 | Sem dinheiro, fama, Legado, luta, aposentar, próximo local | **OK** | Capturas de todas as telas e `grep` em `ui/*.gd` e `data/*.json`: nenhum `$`, FAMA, LEGADO, LUTAR, APOSENTAR, PRÓXIMO. Ícone de raio = Treino. O cartaz da parede diz "SOCO" (arte) |

### Alvo central e foco
| # | Critério | Veredito | Evidência |
|---|---|---|---|
| 4 | Em até 10 s o jogador novo descobre onde clicar | **OK (por inspeção; falta teste com pessoa)** | Seta amarela balançando sobre o saco + rodapé "CLIQUE NO SACO PARA TREINAR" piscando + luva-cursor (`real_mouse_fora.png`). Some no 1º clique (`dica_ativa` = false). Não há como medir 10 s sem um humano novo |
| 5 | Mesmo ponto da tela conta nos 3 focos | **OK** | `qa_play` seção E: clique em (336,222) sem mover o mouse após trocar foco: botão 2 -> +1 AGILIDADE, botão 3 -> +1 RESISTÊNCIA, botão 1 -> +1 FORÇA (também por teclas 3/2/1). Cantos do alvo (312,182) e (359,271) contam; 1 px fora nos 4 lados: 0 cliques |
| 6 | Trocar foco = 1 clique, grátis, foco destacado na cor, lutador no aparelho certo | **OK** | Botões 1/2/3, teclas 1/2/3 e clique no aparelho lateral trocam na hora, sem custo (saldo igual; clique lateral gera 0 treino e 0 `clicou`). Capturas `r720_e_foco_*.png`: botão e painel na cor (vermelho/azul/amarelo), lutador no saco, na corda (saco vai pra esquerda) e na esteira |
| 7 | Passivo só no foco; trocar desvia na hora | **OK** | 5 vizinhos (5/s), foco corda por 2 s: agilidade +10,0, resto 0. Troca p/ esteira por 2 s: resistência +10,0, resto 0 |

### Juice
| # | Critério | Veredito | Evidência |
|---|---|---|---|
| 8 | Todo clique mostra número, inclusive 10 cliques/s por 10 s; sem queda de FPS; legível | **OK** (com ressalva de legibilidade, BUG-2) | 101 cliques em 10 s, `sem_numero=0` (checado a cada clique). Quadro médio 6,5 ms (165 FPS, vsync do monitor), pior 27–32 ms (coincide com a captura de tela do teste). Máx. 16 números ativos de 24 no pool |
| 9 | Número = valor que entrou no atributo e no saldo; 20 cliques | **OK** | 20 cliques: soma dos números = 22,0 = delta de saldo = delta de Força (outras execuções 24,0 e 20,0). Texto do rótulo comparado clique a clique com `NumberFormat.fmt(ganho)`: 0 divergências |
| 10 | Aparelho, golpe, tremida 1–2 px inteiros, traços, som; sem som idêntico 10x | **OK** | Código `sala.gd:278-286`: tremida `int` 1 (normal) ou 2 (crítico), offsets inteiros. Capturas mostram faísca de impacto, saco e lutador em pose de golpe. `sfx.gd`: 4 amostras de soco, nunca repete a mesma em seguida, + tom ±4%; corda 2 amostras ±7%; passos 2 ±6%. WAVs não vazios (picos 17–30 mil de 32 mil). **Não consegui ouvir** (sem saída de áudio no teste): julgamento de "agradável" fica com o dono |
| 11 | Crítico na proporção, maior, `r3`, "!"; chance em `data/` muda a frequência | **OK** | 200 cliques: 22 críticos (11%; faixa 9–31). Soak: 8–12% em milhares de cliques. Todos os 22 com número 2x terminado em "!" e frase (ex. "NA MOSCA!"). Chance 1,0 -> 10/10; 0,0 -> 0/10. `test_data` cobre a leitura de `data/` |
| 12 | Cursor = luva, mesma da mão | **OK** | Janela real: luva desenhada no ponto do mouse sobre a sala (`real_mouse_sala.png`), achatada com botão apertado (`real_clique_rajada.png`), some sobre painéis e fora da janela (`real_mouse_saiu.png`), cursor do sistema escondido (`mouse_mode=HIDDEN`). `manifest.json`: `cursor_glove` e a mão do lutador usam a mesma arte. Nota: nas execuções sintéticas (sem mouse real) a luva aparece parada abaixo do saco; não acontece com mouse real |

### Geradores, melhorias, crescimento
| # | Critério | Veredito | Evidência |
|---|---|---|---|
| 13 | 1º gerador em até 1 min (4–5 cliques/s) | **OK** | Sim: 4/s 0:13, 5/s 0:10. Jogando pela UI (soak) o robô comprou a melhoria antes: 5/s vizinho aos 0:54, 4/s 1:09 (por escolha dele; o vizinho de 60 já era pagável aos ~0:15) |
| 14 | 1ª melhoria em até 3 min e troca o sprite na hora | **OK** | Soak: 0:50 (5/s), 1:04 (4/s), 1:22 (3/s). Troca de sprite confirmada nos 3 aparelhos (`r720_g_melhoria_*_n1.png`, `g_nivel1_foco_*`): saco sem remendo, corda azul com cabos, esteira com display verde. `nivel_visual` = 1 após a 1ª compra |
| 15 | 2º gerador entre 5 e 8 min | **OK, com ressalvas** | Sim (compra "melhor"): 3/s 7:45, 4/s 6:18, 5/s 5:20. Soak: 5/s 5:52, 4/s 7:04, 3/s **8:39**. 8/s: 3:36–3:54 (**cedo**; o designer já avisou: calibrado para 4–5/s). Quem compra tudo "barato" demora 8:28–11:02 (admitido no design) |
| 16 | Toda compra muda /s ou por clique na hora; 1º gerador põe pessoa na sala | **OK** | `economia_mudou` -> `_atualizar_tudo` imediato (HUD "+x/S", AUTO, POR CLIQUE). `g_pessoas_1.png`: 1 vizinho + 1 tio desenhados após a 1ª compra de cada, com entrada animada |
| 17 | 200 unidades: compra funciona, sala não quebra nem lota | **OK** | `debug_somar_geradores` x20: 250 vizinhos e 225 tios; `pessoas_desenhadas` fica em 3 e 2; custo 1,02e26 mostrado como `1.27e26`/`1.60e25` no botão sem estourar; compra com 250 funciona e desconta. `r720_g_200.png`: 5 pessoas, sala íntegra |
| 18 | Gastar nunca reduz atributo; custo = `base * crescimento^n` | **OK** | Teste automático (`test_career`) + `qa_save`: 20.000 ações aleatórias (clique, compras, troca de foco, ticks): soma dos atributos = ganho total (88163,8 = 88163,8), saldo = ganho - gasto, saldo nunca negativo. Custos conferem com a tabela do design (60, 75, 94...) |
| 19 | Aos 10 min passivo >= ~30% do clique e clicar ainda rende mais | **OK, com ressalvas** | Soak (foco fixo, compra por razão ganho/custo), passivo/clique aos 10 min: 3/s 48%, 4/s 61%, 5/s 69%, 8/s 62%. Sem clicar o jogador perde ~60% da renda e não sai do zero (precisa de 60 cliques). **Ressalva (conhecida do design):** rodízio de foco a 5/s com compra "melhor" deu **194%** aos 10 min (passivo > clique), e aos 15 min o foco fixo chega a 99–115% |

### Dados, save, testes
| # | Critério | Veredito | Evidência |
|---|---|---|---|
| 20 | Mudar preço base em `data/` muda o preço sem código | **OK** | `test_data.gd` "critério 20" (base 100 muda o 1º preço) PASS. Valores reais de `data/generators.json` e `training.json` = tabelas do design |
| 21 | Save v1 abre como v2 sem perder treino | **OK** | Arquivo real `{"version":1,...,"state":{"treino":500}}` aberto na janela (`--save-dir`): HUD "TREINO 500"; ao fechar virou `version:2`, `career.training = 500.0`, atributos 0, foco `punching_bag`; original guardado em `save.json.bak`. Extras (`qa_save`): v1 negativo -> 0; v1 texto -> 0; v1 sem `state` -> 0; v0 `{"treino":42}` -> 42; v1 com 1e308 -> aceito sem infinito |
| 22 | Fechar pelo X salva tudo; diferença máx. 1 s de produção | **OK** | Mouse real: 12 cliques, `CloseMainWindow()`; o processo saiu e o `save.json` tem `training 12`, `strength 12`. Gerador/melhoria/foco: `test_save` e `qa_save` v2 completo (saldo 1234,5; atributos; foco esteira; 12 vizinhos, 3 tios; níveis 2/0/1) voltaram idênticos, com `por_clique` 3, 36/s, `nivel_visual` 1 |
| 23 | `run_tests.ps1` passa tudo e o save real fica igual | **FALHOU** | 1 de 452: `test_career.gd:148`, "texto do efeito (obtido: x3 POR CLIQUE: SACO, esperado: x3 POR CLIQUE NO SACO)". Causa: `data/ui_texts.json:13` mudou para `"x{mult} POR CLIQUE: {alvo}"` (ajuste em andamento do Roteirista). Resto PASS e guarda do save real PASS. Quando o texto for fechado, o teste ou o texto precisa ser alinhado (BUG-1) |
| 24 | 15 min seguidos sem erro no console | **OK (simulado; ver ressalva)** | `qa_soak`: 15 min de jogo por execução (5 configs, 2 delas com janela e render), clicando via UI e comprando tudo, rodízio de foco, autosave a cada 30 s de jogo: 0 `SCRIPT ERROR`, `avisos=[]`. Ressalva: o tempo foi simulado (`--fixed-fps 60`), não 15 min de relógio; vazamento de memória em sessão longa não foi medido |

**Resumo: 23 OK (7 com ressalvas), 1 FALHOU (23, por texto em andamento).**

---

## Balanceamento (simulador + jogo)

`fase2_sim.py` reproduz o design (ex.: 5/s foco fixo: vizinho 0:10, fita 0:53, areia 4:51, tio 5:20; aos 10 min clique 90/s, passivo 62/s = 69%). O jogo jogado pela UI concorda:

| Cliques/s | 1º gerador | 1ª melhoria | Tio | Passivo/clique aos 10 min | Passivo/clique aos 15 min |
|---|---|---|---|---|---|
| 3 | 1:29* | 1:22 | 8:39 | 48% | 115% |
| 4 | 1:09* | 1:04 | 7:04 | 61% | 111% |
| 5 | 0:54* | 0:50 | 5:52 | 69% | 99% |
| 8 | 3:30* | 0:31 | 3:54 | 62% | 74% |
| 5, rodízio | 0:53* | 0:49 | 6:40 | **194%** | 69% |

\* O robô prefere a melhoria de 300 quando ela rende mais; o vizinho de 60 estaria pagável bem antes (design: 0:10–0:17).

Observações:
- Com 8 cliques/s (jogador muito ativo) o tio chega aos 3:36, antes dos 5 min. Aceito pelo design; vale o dono saber.
- Em 3 cliques/s o tio passa de 8 min (8:39) quando o jogador gasta primeiro na melhoria. Limite do critério 15 estoura por pouco.
- Aos 15 min o passivo empata/passa o clique (99–115%): "clique perde relevância" previsto, mas a Fase 2 não tem mais nada para o clique depois do nível 2 (design cita as fases futuras).
- Crítico real: 10–11% e média 1,2x, como no design.

---

## Textos e fonte pixel

- `data/training.json`, `generators.json`, `ui_texts.json` conferidos contra `fase2-textos.md`: nomes, dicas de atributo, dicas de 1ª vez, 15 frases de crítico, descrições de geradores e melhorias, "CHAMAR", "MÁXIMO", "MELHORAR": **iguais**.
- Efeito da melhoria na tela: "X3 POR CLIQUE: SACO" (era "x3 POR CLIQUE NO SACO" em `fase2-design.md`/`fase2-api.md`). **Não reportado como bug novo** (Roteirista está ajustando); só gera a falha do teste (BUG-1).
- Acentos: a fonte `fightclicker_5x7(.fnt/_contorno.fnt)` tem 113 glifos (maiúsculas, minúsculas e Ç Ã Á Â É Ê Í Ó Ô Õ Ú à ç etc.). Varredura de todos os textos dos três JSON em maiúsculas: único caractere fora da fonte são `{` e `}` dos modelos (`{mult}`, `{alvo}`), que são trocados antes de exibir. Na tela: "FORÇA", "RESISTÊNCIA", "MÁXIMO", "ÓLEO DE COZINHA NA ESTEIRA", "SOCO", "SACO" saem corretos (recortes `z_inicio_*.png`). **Nenhum caso de "SACO" virando "SAÇO".** O cartaz da parede diz "SOCO" na arte, o texto do jogo diz "SACO" (coerente com "soco"/"saco" do painel).
- Mistura de caixa: dica do atributo ("Força: quanto dói o seu soco."), ambientação e descrições saem em caixa mista, o resto em maiúsculas. O Roteirista escreveu "na tela tudo sai em maiúsculas". É escolha da UI para legibilidade em 5x7; vale confirmar com o dono (BUG-5, trivial).
- Os textos de crítico ("DESSA ELE LEMBRA!") aparecem acima do número 2x, em creme com contorno: legíveis.

---

## Saúde visual

**Número flutuante em fundo vermelho/qualquer fundo.** Os números têm contorno escuro (`fightclicker_5x7_contorno`) e ficam legíveis sobre parede, portão cinza e saco vermelho (`z_rajada0.png`, `z_rajada2.png`). O mais frágil é o "+N FORÇA" vermelho claro sobre o saco vermelho: legível pelo contorno, mas com pouco contraste de cor. Em rajada de 10/s os "+1 FORÇA" se empilham sobrepondo meia linha (`z_rajada1.png`), ainda dá para ler o último.

**Crítico sobrepondo normais.** Medi com `qa_overlap.gd` (60 s, caixas de texto, considera "coberto" só o que é desenhado por cima):

| Ritmo | Quadros com crítico visível | Crítico parcialmente coberto | Cobertura média | Pior caso | Quadros com 2 críticos sobrepostos |
|---|---|---|---|---|---|
| 5 cliques/s | 4.370 | 44% | 3,9% | 54% | 835 (19%) |
| 10 cliques/s | 9.306 | 69% | 12,3% | 64% | 3.385 (36%) |

Leitura: o crítico não some, mas num ritmo de 10 cliques/s um crítico novo cai sobre o anterior em mais de 1/3 do tempo (ex. `z_crit.png`: "+3 FORÇA!" sobre "+3 FORÇA!" e a frase de uma sobre a outra). Não chega a ser ilegível no uso normal; é feio e o dono pode notar na rajada. Causa: todos os números têm o mesmo `z_index` (900) e a ordem de desenho é a do índice no pool, não a do mais recente (`ui/sala.gd:14`, `:126-127`, `:303-310`); o crítico dura 0,85 s e sai com desvio de x de apenas -30/0/+30 px (`:13`). Ver BUG-2.

**Tremida.** Normal 1 px / 0,07 s, crítico 2 px / 0,16 s, inteiros. Em rajada de 10/s a sala treme quase continuamente (1 px). Não incomoda nas capturas; é subjetivo (risco do escopo, "juice demais cansa"). Opção de desligar só na Fase 9.

**Cenas.** Estados conferidos: início, foco nos 3 aparelhos, melhorias nível 1 e 2 (MÁXIMO, preço some, botão desabilitado), pessoas 1/10/25/50/200, números 1e30, 1,50e20, 999T (cabem nos painéis), F11 e F12.

---

## Bugs

| ID | Gravidade | De quem | O quê / como reproduzir | Onde |
|---|---|---|---|---|
| BUG-1 | **Média** (bloqueia o critério 23) | Texto + Programador | `run_tests.ps1` termina com "1 GRUPO(S) DE TESTE FALHARAM". Passos: rodar o script; `test_career.gd`: "texto do efeito (obtido: x3 POR CLIQUE: SACO, esperado: x3 POR CLIQUE NO SACO)". O modelo em `ui_texts.json` mudou e o teste (e `fase2-api.md`, `fase2-design.md` §5) ficaram com o texto antigo. Também o valor padrão em `game_state.gd:189` ("x{mult} POR CLIQUE NO {alvo}") difere do JSON | `tests/test_career.gd:148`; `data/ui_texts.json:13`; `scripts/game_state.gd:189` |
| BUG-2 | **Baixa-média** | UI | Críticos se sobrepõem entre si e são cobertos por números normais em rajada (tabela acima). Reproduzir: clicar 10x/s por 20 s e olhar os críticos. Sugestão: dar a cada número um `z_index` crescente por recência (ou reordenar o nó ao iniciar) e espalhar o x do crítico, ou subir a frase do crítico por mais tempo sem sobrepor o 2º | `ui/sala.gd:13-14,126-127,296-299,303-310,507-523` |
| BUG-3 | **Baixa** | UI/Texto | Com a linha de melhorias completa (MÁXIMO), passar o mouse no botão mostra no painel esquerdo o nome do aparelho do nível 0 ("ESTEIRA ENFERRUJADA", "SACO REMENDADO", "CORDA DE VARAL") mesmo já melhorado e com o sprite novo. Reproduzir: comprar os 2 níveis da esteira e passar o mouse no botão "MÁXIMO" (`r720_g_200.png`). Sugestão: usar o nome da última melhoria ou "ESTEIRA" | `ui/painel_loja.gd:139` |
| BUG-4 | **Baixa** | Programador | Resíduo da Fase 1: `tests/qa_fase1.gd` (script de QA antigo) usa `treino_por_segundo`, que não existe mais. Não roda; não está no `run_tests`. Apagar ou atualizar | `tests/qa_fase1.gd:82,88` |
| BUG-5 | **Trivial** | UI/Texto | Mistura de maiúsculas e caixa mista (dicas de atributo, ambientação, descrição de item) contra o combinado "tudo em maiúsculas" do `fase2-textos.md`. Decidir e documentar | `ui/painel_atributos.gd:79-86` |
| BUG-6 | **Baixa** | Programador | `README.md` ainda diz "Fase atual: Fase 1", que F5 abre a "tela de verificação" e cita "+1 treino (teste)", "treino/s de teste" (`data/config.json` já não tem). F11/F12 estão corretas | `README.md` linhas 3-4, 8-13 |

Nenhum bug de dados: nenhuma compra sem saldo passou, nenhum saldo negativo, nenhum atributo diminuiu, nenhum NaN/infinito entrou no save.

Testes extras que **passaram** (todos em `tests/qa_save.gd` / `qa_play.gd`):
- Compra sem saldo: `comprar_gerador/melhoria` devolvem `false`, estado idêntico; botão CHAMAR desabilitado e clicar nele não compra. Saldo 59,999999999 compra o vizinho de 60; 59,9 não. Compra com saldo 60 deixa 0,012 (nunca negativo).
- Comprar tudo: melhorias dos 3 aparelhos até 2/2 via cliques nos botões; botão vira "MÁXIMO", desabilitado, `comprar_melhoria` além do limite = `false`; multiplicador 15.
- 1.000 tentativas seguidas de compra com 1e18: 161 compradas, saldo coerente.
- Saves: lixo, vazio, `[1,2,3]` -> jogo novo e arquivo guardado como `.corrompido-…`; principal corrompido + `.bak` bom -> restaura (77); `version` 9 -> não abre e não sobrescreve; v2 com campos ruins (treino -5, atributo texto, foco inexistente, quantidade negativa/fracionária, nível 9, ids fantasma) -> valores saneados (0, 0, `punching_bag`, 0, 3, 2).
- `tick(NaN/Inf/-1)` ignorado; `tick(1000)` com saldo 1e308 não vira infinito.
- F11 liga/desliga e o clique continua mapeando certo em tela cheia (escala 3). F12 abre/fecha a depuração; "SALDO x1000" mexe só no saldo (agilidade ficou 5,0).

---

## Riscos

1. **F12 só em build de debug** (`OS.is_debug_build()`): o código está certo (`app_controls.gd:28`, `game_state.gd:247-261`: `debug_*` retornam sem fazer nada fora de debug), mas **não testei um build exportado** (só o editor/debug). Conferir quando houver export.
2. **Equilíbrio fora da faixa de 4–5 cliques/s**: 8 cliques/s acha o tio em ~3:40, 3 cliques/s em ~8:40; jogador de rodízio e o "impulsivo" ficam com passivo > clique aos 10 min. O design já registra e propõe `growth` 1.3 do vizinho se doer.
3. **Aos 15 min o passivo iguala o clique** e não há mais melhoria de clique: a partir daí o jogador só clica por prazer (esperado até a Fase 3, mas é a sensação de "fim de conteúdo" da Fase 2).
4. **Critério 4 (10 s para achar onde clicar)** só se prova com uma pessoa nova.
5. **Juice em sessão longa**: tremida de 1 px quase contínua a 10 cliques/s e sons repetidos (corda e esteira têm só 2 amostras) podem cansar; sem opção de desligar até a Fase 9. Não testei com áudio ligado.
6. **Arte e som são placeholder** (sprites gerados por `tools/art`, sons por `tools/sfx/make_sfx.gd`); parecem finais e bons, mas o relatório tem de dizer ao dono que são placeholder.
7. **Sessão de 15 min simulada**, não de relógio; vazamento de memória/handles em horas de jogo não foi medido.
8. **Aviso de saída do Godot** ("ObjectDB instances leaked", "resources still in use") aparece ao encerrar os meus scripts de teste (`--script`). Não aparece com `--quit-after` na cena principal; é do modo `--script`, mas vale o Programador olhar se não é nó órfão.
9. **Resolução 1920x1080 em janela** dá escala 2 com faixas pretas grandes (320 px de cada lado em x), e só a tela cheia (F11) dá 3x. Está como o design disse, mas o dono pode estranhar a janela "pequena" num monitor 1080p.

---

## Veredito

**Quase pronto para o Diretor revisar.** A fase cumpre 23 dos 24 critérios, com evidência em janela real, mouse real, 1280x720, 1080p e tela cheia, e os números batem com a simulação do Designer. O que impede o "tudo verde" é só o **BUG-1** (um teste falhando porque o texto do efeito da melhoria está sendo mexido): fechar o texto e alinhar o teste/`fase2-api.md`, rodar `run_tests.ps1` de novo e o critério 23 passa. O **BUG-2** (críticos se sobrepondo em rajada) é o único defeito visível que o dono pode notar; recomendo corrigir antes da demonstração, mas não bloqueia a revisão. Os demais bugs são baixos ou triviais.
