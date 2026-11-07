---
name: alinhamento-ui
description: Auditoria obrigatória de alinhamento e centralização de telas do Fightclicker (Godot 4, pixel art 640x360). Use SEMPRE que qualquer tela, cena, painel, janela, botão, HUD ou texto de UI for criado ou alterado (arquivos em ui/ ou scenes/, temas, fontes, textos de ui_texts.json que mudam largura), antes de dizer que a tarefa está pronta — mesmo que o pedido não fale em alinhamento. Também quando o dono reclamar de algo "torto", "fora do lugar", "não centralizado", "desalinhado" ou "cortado".
---

# Alinhamento de UI — padrão do Fightclicker

O dono quer que **tudo esteja sempre no seu devido lugar**: texto centralizado dentro do botão, botão centralizado no espaço dele, janelas no meio da tela, colunas alinhadas, nada cortado. Em pixel art a 640x360 ampliado 2x/3x, um erro de 1–2 px vira 3–6 px na tela e salta aos olhos — por isso a checagem é parte de toda mudança de tela, não um polimento opcional.

## Quando terminar qualquer mudança de UI, faça estes 4 passos

### 1. Declare a intenção de alinhamento
O verificador precisa saber o que deveria estar centralizado. Em cada `Control` que tem posição intencional, use a metadata `ui_align` (no .tscn ou no código com `set_meta`):
- `"center"` — centralizado no pai (horizontal e vertical). Padrão para: texto de botão, botões de ação (LUTAR!, APOSENTAR, NOVA CARREIRA), títulos de janela, janelas/pop-ups, selos, números grandes.
- `"center_h"` / `"center_v"` — só um eixo.
- `"left"` / `"right"` — colado a um lado com margem (listas, valores numéricos à direita).
- `"ignore"` — posição livre de propósito (números flutuantes, partículas, sprites da sala).

Botões com texto são `center` por padrão mesmo sem metadata.

### 2. Rode o verificador automático
```
E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe --path E:\Fightclicker --resolution 1280x720 --script res://tools/ui/ui_audit.gd -- --estados todos
```
Ele abre cada tela/estado (garagem, loja, prévia, luta, vitória, fim, aposentar, F12…), usa save de teste isolado e lista problemas com caminho do nó e diferença em pixels (na base 640x360). Ele sai com código 1 se houver problema. Rode com janela (sem `--headless`) para as fontes medirem certo.

O que ele confere (detalhes em `references/regras.md`):
- texto de `Button`/`Label` com alinhamento diferente da intenção, ou não-centralizado de fato (mede a largura real do texto na fonte pixel);
- ícone + texto de botão: o **grupo** fica centralizado, não só o texto;
- filho com `ui_align=center` cujo centro difere do centro do pai em mais de **1 px**;
- irmãos de uma mesma fileira (ex.: 3 botões de foco) com larguras/alturas ou espaçamentos diferentes;
- margens assimétricas em painéis/janelas;
- texto cortado/transbordando (largura mínima do texto > largura do controle);
- controles visíveis fora da tela ou sobrepostos a irmãos fora de containers;
- posições/tamanhos não inteiros na base (borram o pixel art).

### 3. Olhe as capturas
O verificador salva capturas de cada estado em `C:\Users\deivi\AppData\Local\Temp\claude\ui_audit\` (ou na pasta passada em `--saida`). Abra pelo menos as telas que você mexeu e confira a olho: o verificador pega medida, mas não pega "parece torto". Em caso de dúvida, amplie a região.

### 4. Corrija e repita até zerar
Corrija na causa (container certo, `size_flags`, `alignment`, margens simétricas), não com deslocamento manual de pixel. Rode de novo até **0 problemas**. Se um caso for intencional, marque `ui_align="ignore"` e diga por quê no relatório. Depois rode `tools\run_tests.ps1`.

## Como corrigir no Godot (atalhos que resolvem 90%)
- **Texto no botão:** `alignment = HORIZONTAL_ALIGNMENT_CENTER`; o texto não deve estar num `Label` solto por cima do botão. Com ícone, use `icon_alignment` + `expand_icon`, ou um `HBoxContainer` com `alignment = CENTER` dentro de um `CenterContainer`.
- **Botão no espaço dele:** coloque num `CenterContainer` ou use `size_flags_horizontal = SIZE_SHRINK_CENTER` dentro do container pai. Evite `position` fixa.
- **Label que deve centralizar:** `horizontal_alignment`/`vertical_alignment = CENTER` **e** `size_flags = FILL/EXPAND` — sem preencher o espaço, o alinhamento não tem efeito.
- **Fileira de botões iguais:** `HBoxContainer` com `size_flags_horizontal = EXPAND_FILL` e `size_flags_stretch_ratio` igual em todos, ou `custom_minimum_size` igual.
- **Janela/pop-up:** âncoras e offsets centrados (`PRESET_CENTER`) ou `CenterContainer` cobrindo a tela.
- **Paridade de pixel:** na fonte 5x7, texto com largura ímpar num espaço par fica 0,5 px fora — tolerância de 1 px existe por isso; não “corrija” com meio pixel.

## No relatório final de qualquer tarefa de UI
Inclua uma linha: `alinhamento-ui: <N> estados verificados, 0 problemas` (ou a lista do que ficou marcado como `ignore` e por quê) e o caminho das capturas.
