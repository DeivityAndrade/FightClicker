# Fase 1 — Fundação: relatório de QA

Data: 2026-11-05. Godot 4.7.2. Código não foi alterado (só criei testes extras em `tests/qa_*.gd`).

## Resumo
Os 11 critérios passam. Nenhum bug bloqueante. 3 bugs de gravidade baixa (todos em casos extremos) e 3 riscos de UX/decisão. Veredito no fim.

## Preparação e segurança do save real
- `%APPDATA%\Godot\app_userdata\Fightclicker\` existia, mas **sem `save.json` real** (só `logs`, `shader_cache`, `test`). Backup das pastas em `...\scratchpad\qa1\backup_userdata` (cópia parcial, porque o cache de shader tem caminhos longos; não havia save para proteger).
- Para provar o guarda, criei um `save.json` + `.bak` "sentinela" na pasta real e, no fim, **apaguei os dois** (a raiz ficou como estava: sem arquivos de save).
- **O guarda funciona**:
  - Bateria completa com a sentinela presente: `PASS save real do dono igual antes e depois da bateria inteira`, hash SHA-256 idêntico depois.
  - Sabotagem (mexi na sentinela entre `--antes` e `--depois`): `FAIL save real do dono igual antes e depois da bateria inteira`, exit 1, mostrando antes/agora com md5 diferente. Ou seja, detecta mudança de verdade.

## 1. Comando único
`powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1`
Saída (resumo): guarda 3/3, test_game_state 27/27, test_number_format 45/45, test_save 60/60, `PASS cena principal roda 120 frames sem erros`, guarda 4/4, `TODOS OS TESTES PASSARAM`, exit 0. Rodei 2 vezes (com e sem sentinela), mesmo resultado. Os WARNING impressos são esperados (testes de corrupção/futuro).

## 2. Critérios de aceite

| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Roda (F5) sem erros/avisos | **OK** | `godot --path E:\Fightclicker --quit-after 300 -- --save-dir=user://test/qa_c1/` janela real: saída só com as 2 linhas de versão/GPU, exit 0. |
| 2 | Treino sobe sozinho; "+1" soma 1 | **OK** | Janela real: "Treino: 10" aos ~5 s, "34" aos ~35 s (1/s). `qa_ui.gd`: pressionar "+1 treino (teste)" → `0.0 -> 1.0`. |
| 3 | x1000 passa por K/M/B/T/científico; perto de 1e300 não trava | **OK** | `qa_ui.gd`: 8 cliques → label `Treino: 1.00e24`; 12 cliques → 1e36, finito. `test_game_state`: x1000 repetido nunca vira infinito (trava em 1.797e308, mostra `1.80e308`). Varredura do formatador (test_number_format e `qa_fase1.gd`): nenhum `1000K`, `0.xx` ou texto quebrado até 1e307. |
| 4 | Lista de exemplos | **OK** | Screenshot `fullscreen.png`: `1->1`, `999->999`, `1200->1.20K`, `3400000->3.40M`, `3450000->3.45M`, `1.23e15->1.23e15`, `1e300->1.00e300`, `12345->12.3K`, `123456->123K`, `999999->1.00M`, `9.99e14->999T`. Formato do dono (3 dígitos, ponto) respeitado. |
| 5 | Fechar pelo X, reabrir, mesmo treino (±1 s) | **OK** | Teste real: sentinela com treino 12345, abri a janela ~17 s, mandei `CloseMainWindow` (equivale ao X): arquivo gravado com `12362.386` = 12345 + ~17,4 s de produção, processo saiu. Também `test_game_state` "fechar pelo X". |
| 6 | 30 s sem clicar → novo horário de autosave | **OK** | Janela real com pasta vazia: t=5 s nenhum arquivo; t=35 s `save.json` criado (`treino 30.0017`, `saved_at_unix` 1793874116) e status mostra "Último save: 07:21:56" (`c6_t35.png`); t=65 s apareceu `.bak` (2º autosave). |
| 7 | Save apagado/lixo → carrega backup + aviso | **OK** (ver nota do .bak) | `save.json`="lixo {{{" + `.bak` válido: carregou treino 1234567, aviso laranja na tela "Save corrompido (guardado como save.json.corrompido-...): carregado o backup." (`shot_1280x720.png`), nada travou. O arquivo ruim foi renomeado, não apagado. Sem `.bak` (só existe após o 2º save), o jogo começa novo e guarda o corrompido (`test_save`). Corrompidos testados: vazio, só espaços, `[]`, `"texto"`, `null`, JSON truncado, `version` inválida. |
| 8 | Testes com 1 comando, passam, save real igual | **OK** | Item 1 e sabotagem do guarda acima. README documenta o comando. |
| 9 | Mudar treino/s em `data/` sem tocar no código | **OK** | Editei temporariamente `data/config.json` (treino/s 7.5, autosave 5) → `QA tps=7.5 autosave=5.0`; restaurei o arquivo (conferido byte a byte) → `tps=1.0 autosave=30.0`. Config ausente/inválida/fora de faixa cai nos padrões com aviso (test_game_state). |
| 10 | 30 e 144 FPS ganham o mesmo em 10 s | **OK** | `10 s a 30 FPS = 30.0000000000002`, `60 = ...0003`, `144 = 29.9999999999994`, frames irregulares = 30.0. |
| 11 | Escala inteira e nítida em 1280x720 e 1920x1080 | **OK** (com ressalva de UX R1) | Capturas de tela reais (CopyFromScreen). Janela 1280x720: padrão uniforme x2 (`crop_win_pattern.png`). **Tela cheia 1920x1080: x3 exato**, tudo 3 px por pixel, xadrez/listras nítidos, sem borrão, texto legível (`fullscreen.png`, `crop_fullscreen_pattern.png`). Maximizada: nítida, mas escala x2 com faixas pretas (R1). Resoluções 1366x768 e 960x540 também pelo `--resolution` (x2 e x1,5 não permitido: a janela de 960x540 renderizou 640x360, i.e. x1, sem erro). |

Observação sobre os screenshots `shot_*.png` do script `qa_shot.gd`: `root.get_texture()` devolve a imagem na resolução lógica, então eles servem para ver o conteúdo/aviso, não a escala; a prova de escala são os `fullscreen.png`, `win_1280x720.png`, `maximized.png`.

## 3. Tentar quebrar (resultados)
Script: `E:\Fightclicker\tests\qa_fase1.gd` (26/35 PASS no primeiro run; os FAIL foram 2 erros do meu teste (pasta limpa duas vezes, valor `inf` na varredura) e os bugs abaixo; após corrigir o teste, os únicos FAIL são os bugs B1 e B2).

- **v0 `{"treino": 42}`** migra para v1, treino 42 (`test_save` e `qa_fase1`).
- **Tipos errados** (`"abc"`, `null`, `true`, `-5`, `state:null`, `state:[...]`, campo desconhecido, BOM UTF-8): sempre treino válido (0 ou valor), sem erro.
- **`1e999` no JSON**: vira o máximo do float (1.797e308), finito.
- **version 999 / 2**: não abre, não sobrescreve (arquivo idêntico byte a byte), nenhum `.bak`/`.tmp`, mesmo após 70 s de ticks (2 autosaves), `salvar()` explícito e fechar. Principal corrompido + `.bak` de versão futura também bloqueia o save.
- **Valores extremos**: `tick(1e308)` x5, `tick(INF)`: treino finito, trava em 1.797e308, salva e recarrega igual, mostra `1.80e308`. `NumberFormat.fmt` de NaN → `0`, ±INF → `Infinito`/`-Infinito`, negativos ok.
- **300 saves seguidos**: último valor correto, só `save.json` + `.bak` na pasta.
- **Matar o processo no meio do save** (`qa_kill.gd`, 25 mortes forçadas durante loop de gravação, ~100 saves/s): 25/25 reaberturas carregaram (24 pelo principal, 1 pelo backup com aviso). Nunca perdeu tudo. Sobra `save.json.tmp` (inofensivo, sobrescrito no próximo save).
- **Apagar com confirmação** (`qa_ui.gd`): clicar "Apagar save" abre o diálogo e o arquivo continua; Cancelar mantém save e treino; Confirmar apaga e zera o treino.

## 4. Bugs

**B1 (baixa) — `version` gigante/não representável vira "corrompido" em vez de "futuro".**
`scripts/save_store.gd:144-148`. Para `version` = `1e30`, `9223372036854775807` ou `1e308`, `int(float(v))` estoura (vira `-9223372036854775808`), não passa em `versao > VERSAO_ATUAL`, `_migrar` falha ("sem migração da versão -9223372036854775808") e o arquivo é renomeado para `.corrompido-N` e substituído por jogo novo. Passos: gravar `{"version": 1e30, "state":{"treino":777}}` em `save.json`, abrir o jogo. Efeito: save "do futuro" absurdo deixa de ser protegido (o conteúdo ainda existe como `.corrompido`, nada é apagado). Cenário irreal na prática; correção simples: comparar `float(v) > VERSAO_ATUAL` antes de converter para int.

**B2 (baixa) — `tick(NaN)` desativa o autosave para sempre.**
`scripts/game_state.gd:54` (`if delta <= 0.0` não pega NaN) e `:59` (`_tempo_autosave += NaN` fica NaN; `NaN >= intervalo` é sempre falso). Passos: `gs.tick(NAN)` e depois `tick(30.1)`: nenhum autosave (`qa_fase1.gd`: `FAIL autosave continua funcionando depois de tick(NAN)`). O Godot não entrega delta NaN em jogo normal, então é só robustez. Correção: `if not (delta > 0.0) or is_inf(delta): return`.

**B3 (baixa/decisão) — "Apagar save" apaga também um save de versão futura.**
`scripts/game_state.gd:105-112` + `ui/verification_screen.gd:94,127`. Com save v999 bloqueado, "Apagar save" (após confirmar) remove o arquivo; o texto do diálogo não avisa que o arquivo é de uma versão mais nova. Foi intencional pedir confirmação, mas vale decisão do Diretor: avisar no diálogo ou não deixar apagar quando `store.bloqueado`.

## 5. Riscos e observações
- **R1 (UX, Fase 2):** janela *maximizada* em monitor 1080p tem área útil ~1920x1010, então a escala inteira escolhe **x2** e sobram faixas pretas grandes (`maximized.png`). Só em tela cheia (ou janela sem barra de título) se obtém x3. Não viola o critério 11 (nítido, sem pixels desiguais), mas o dono pode estranhar. Considerar modo tela cheia por atalho (F11) na Fase 2.
- **R2:** arquivos `save.json.corrompido-<tempo>` acumulam sem limite (cada recuperação cria um). Baixo impacto.
- **R3:** `canvas_items` renderiza o texto na resolução real (nítido, não pixelado). É o que o `project.godot` documenta; se o Diretor de Arte quiser texto em pixel art "puro" terá de trocar para `viewport` e revalidar a legibilidade.
- **R4:** em `--script` o GameState usa `user://test/autoload/` automaticamente, então scripts de QA/CI nunca tocam o save real (bom). Mas `--save-dir=` tem precedência, então um argumento mal passado poderia apontar para outra pasta. Aceitável.
- O guarda só tira foto dos arquivos da raiz de `user://` (não recursivo); suficiente porque o save real fica na raiz.
- Não testado: botão "Recarregar save" por clique (só a função); janela real em monitor com DPI > 100% (usei 100%).

## Arquivos de teste e evidências
- Testes extras (mantidos): `E:\Fightclicker\tests\qa_fase1.gd`, `qa_kill.gd`, `qa_ui.gd`, `qa_shot.gd` (não são pegos pelo runner, que só roda `test_*.gd`).
- Screenshots em `C:\Users\deivi\AppData\Local\Temp\claude\d03e7314839aa25e\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\qa1\`:
  - 1280x720 janela real: `win_1280x720.png` (e `c6_t05.png`, `c6_t35.png`)
  - 1920x1080 tela cheia real: `fullscreen.png`, zoom `crop_fullscreen_pattern.png`; zoom da janela 1280: `crop_win_pattern.png`
  - Maximizada: `maximized.png`
  - Aviso de save corrompido na tela: `shot_1280x720_save_corrompido.png`, `shot_1280x720.png`

## Veredito
**Pronto para o Diretor revisar.** Todos os critérios de aceite passam com evidência; o guarda do save real foi provado funcionando (inclusive falhando de propósito). Os bugs B1/B2/B3 são de baixa gravidade e podem ficar como dívida ou virar correção rápida antes da Fase 2; R1 (escala x2 quando maximizada) merece decisão do Diretor/Diretor de Arte.
