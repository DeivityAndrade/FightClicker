# Fightclicker (nome de trabalho)

Jogo incremental de luta em Godot 4.7 (GDScript). Briefing: `PROMPT.md`. Fase atual: **Fase 4 — Árvore de habilidades** (sobre a Fase 3: lutas e carreira com adversários, prévia e táticas, fim de carreira, Legado, aposentar e loja em $).

## O jogo agora
Você treina na garagem (Fase 2: clique, aparelhos, melhorias, equipe, atributos) e agora **luta**. O botão **LUTAR!** enfrenta o próximo adversário da escada: a luta é decidida e salva na hora e depois animada (a UI só anima os eventos). Antes de lutar há uma **prévia** ELE x VOCÊ com o risco (FÁCIL / EQUILIBRADO / PERIGOSO, sem porcentagem) e a escolha de **tática** (cada uma muda dano, defesa e esquiva e recalcula o risco). Vitória dá **$** e fama e sobe a escada até o cinturão. **Derrota** encerra a carreira: tela de fim com o motivo (atributo que faltou, estatística e dica). Entre lutas dá para **aposentar** e sair por cima. Os dois fins somam **Legado**, que vale para a próxima carreira. A **loja em $** vende o Prof. Nelson (gerador pago) e as luvas de lona e de couro; tudo isso é da carreira e some na carreira seguinte (só o Legado fica). O motivo da derrota é calculado em segundo plano durante a animação e salvo antes do resultado ser aplicado.

## Novo na Fase 4
- **Árvore de habilidades entre carreiras**: comprada com **Legado**, só entre carreiras e sem reembolso. Duas colunas (CORPO e CARREIRA), 10 nós em `data/skill_tree.json` (ex.: Jab de base e Bolsa negociada a 10, Memória muscular a 30, Olho clínico a 25). A tela de fim tem o botão **ÁRVORE** ao lado de NOVA CARREIRA.
- **Metrônomo na loja** ($80 / $150 / $300): objeto na prateleira que faz o lutador socar sozinho, devagar, sem tremer a tela e com número e som menores. Para quando há janela aberta.
- **Memória muscular** (nó da árvore): a carreira já começa com o Metrônomo tocando.
- **Revanche**: contra quem te derrotou, o bloco PRÓXIMA e a prévia mostram **"VOCÊ PERDEU PRA ELE"**, e a vitória mostra **"REVANCHE!"**.
- **Dica "ESPERE FICAR VERDE"** na prévia, apontando o aparelho para treinar até o risco baixar.
- **Cartão de início** ("O QUE VOCÊ TROUXE"): aparece ~2 s na nova carreira com os bônus da árvore.
- **Personagens refeitos** no padrão novo de personagem (lutador, adversários e luvas equipadas).
- Save na **versão 4** (o save antigo migra sozinho; o Legado antigo é multiplicado por 10). Textos em `data/ui_texts.json`, contrato em `docs/fases/fase4-api.md`.

## Novo na Fase 4b
- **Aparelhos comprados na carreira**: cada carreira começa só com o **saco**. A **esteira** (500 Treino) e depois a **corda** (1.500, pede a esteira) são compradas no cartão da aba TREINO; antes disso a sala mostra marcas de fita com plaquinha de preço e os botões de foco ficam trancados. Tudo volta ao saco na NOVA CARREIRA.
- **Treino assistido (segure Shift ou o botão SEGURAR)**: com a mão parada por 1 s, o lutador dá 1 soco a cada 3 s. Bem mais fraco que clicar; não funciona na luta, janelas, fim, árvore nem cartão; some quando o Metrônomo é comprado.
- Save na **versão 5** (a carreira em andamento de um save antigo ganha os 3 aparelhos). Contrato em `docs/fases/fase4b-api.md`; roteiro em `docs/fases/fase4b-revisao.md`.

## Como abrir
1. Abra o Godot 4.7.2 (`E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64.exe`).
2. "Importar" → escolha `E:\Fightclicker\project.godot`.
3. Aperte **F5**.

Save real: `%APPDATA%\Godot\app_userdata\Fightclicker\save.json` (backup: `save.json.bak`).
Valores ajustáveis: `data/config.json` (autosave, depuração), `data/training.json`, `data/generators.json`, `data/ui_texts.json`. Contrato para a UI: `docs/fases/fase2-api.md`. Fase 3: `data/` de lutas/adversários/táticas e `docs/fases/fase3-api.md`. Fase 4: `data/skill_tree.json`, `data/shop.json` (Metrônomo).

## Teclas
- **Espaço**: treina um clique no aparelho em foco (igual a clicar no alvo). Conta só no aperto: segurar não repete. Não funciona com janela aberta, durante a luta, na tela de fim nem com a depuração (F12) por cima.
- **1 / 2 / 3**: trocam o foco de treino (saco / corda / esteira).
- **F11**: alterna tela cheia (em 1080p dá escala x3).
- **F12**: mostra/esconde a depuração (saldo x1000, +10 de cada gerador, salvar, recarregar, apagar save). Só em build de debug; a lógica está em `GameState.debug_*`.

## Executavel para Windows

O preset `Windows Desktop` gera uma versao release de 64 bits com os recursos
embutidos no executavel (sem precisar instalar o Godot no computador de quem joga).
Com os templates de exportacao do Godot 4.7.2 instalados, crie a pasta
`build/Fightclicker-Windows` e execute:

```powershell
& "E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --export-release "Windows Desktop" "build/Fightclicker-Windows/Fightclicker.exe"
```

A pasta `build/` e ignorada pelo Git. Distribua o executavel sem incluir seus saves.

## Como testar
Um comando roda todos os testes (sem abrir janela) e a cena principal por 120 frames:

```
powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1
```

No fim aparece `TODOS OS TESTES PASSARAM` (código de saída 0) ou o que falhou.
Os testes usam só `user://test/` e **nunca** tocam o save real: o runner tira uma "foto" do save real antes e confere no fim que continua igual.

Um teste isolado:
```
E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path E:\Fightclicker --script res://tests/test_save.gd
```

## Simuladores de balanceamento
`tools/sim/fase3_sim.py` (lutas e escada da Fase 3) e `tools/sim/fase4_sim.py` (carreiras, Legado e árvore da Fase 4) simulam sobre `data/`, com o mesmo comando abaixo trocando o arquivo. Obs.: a tabela principal do `fase4_sim.py` calcula a revanche do Muralha sem a L1 (pendência registrada na revisão).

`tools/sim/fase2_sim.py` (Fase 2) simula jogadores de 3/5/8 cliques/s sobre `data/training.json` e `data/generators.json` e mostra os marcos de tempo (não há python no PATH; use o do Blender):
```
"C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe" E:\Fightclicker\tools\sim\fase2_sim.py
```

## Verificador de alinhamento da UI
Toda mudança de tela passa por ele (0 problemas, capturas em pasta de saída):
```
E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tools/ui/ui_audit.gd -- --estados todos
```
Usa save de teste isolado (`user://test/ui_audit/`); sai com código 1 se houver problema.

## Roteiro de teste da Fase 4 (resumo, ~15 min)
Para guardar a carreira atual, copie o `save.json` antes. Ao abrir, o save antigo vira v4.

**Parte A, sem F12 (a que importa):**
1. F12 -> APAGAR SAVE -> CONFIRMAR -> F12 (esconde). Recomeça na garagem.
2. Clique no saco por 1 min; compre o Vizinho e a Fita (aba TREINO) e veja a gente nova na sala.
3. Lute contra o Dudu quando a prévia não estiver vermelha.
4. Na LOJA compre o Metrônomo ($80): o lutador soca sozinho, devagar; abra a prévia e ele para.
5. Siga até perder (Brutão ou Dinho): a tela de fim diz o atributo, o aparelho e "volte quando a prévia ficar verde".
6. ÁRVORE: compre 1 ou 2 nós (Jab de base e Bolsa negociada, 10 cada); o Legado desce. Depois NOVA CARREIRA.
7. Carreira 2: o cartão "O QUE VOCÊ TROUXE" aparece ~2 s (clicar só fecha o cartão); o 1º clique mostra "+2" se comprou o Jab.
8. Revanche: PRÓXIMA e prévia mostram "VOCÊ PERDEU PRA ELE" e "ESPERE FICAR VERDE"; treine até ficar verde, lute e veja "REVANCHE!".
9. Responda: quer jogar mais uma carreira?

**Parte B, com F12 (atalho, só mostra conteúdo, não vale para julgar ritmo):** "+10 DE CADA GERADOR" algumas vezes para ver o Seu Muralha, o cinturão, APOSENTAR, a árvore cheia e a Memória muscular. "SALDO x1000" multiplica só o Treino.

Placeholders: ícones dos nós, prop do Metrônomo, moldura da árvore, sons de impacto, nome do jogo. Roteiro completo: `docs/fases/fase4-revisao.md`.

## Simulador de sessão longa (jogando pela UI)
`tests/qa_soak.gd` joga sozinho pela UI (cliques sintéticos e compras por heurística). Não entra no runner:
```
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path E:\Fightclicker --script res://tests/qa_soak.gd -- <cliques_por_s> <rodizio 0|1> <minutos>
```
(15 min = 54000 frames.) Os outros `tests/qa_*.gd` são scripts de QA manuais.

## Pastas
`scenes/` cenas · `scripts/` lógica (GameState, save, formatador) · `ui/` telas · `data/` dados ajustáveis ·
`assets/` arte e som · `tests/` testes headless · `tools/` scripts de apoio · `docs/` documentos do estúdio.
