# ID4: contrato entre a lógica (Programador) e a tela do menu (UI/UX)

Escrito pelo Programador em 2026-11-25, antes do código. Quem consome: `ui/menu_principal.gd` (UI/UX).

## 1. O que a UI/UX entrega

- `ui/menu_principal.gd`: `class_name MenuPrincipal`, `extends Control`, 640x360, `mouse_filter = STOP` (come todo clique).
- Sinal `escolheu(acao: String)` com `acao` em `"continuar"`, `"novo_jogo"` ou `"sair"`.
  - `"novo_jogo"` só é emitido **depois** da confirmação dupla (a tela de confirmação é da UI/UX). O Fluxo faz a cópia e o apagamento.
  - A tela de OPÇÕES é um painel dentro do menu; não emite nada, só lê e grava em `GameState` (seção 3).
- O Fluxo cria o menu com `MenuPrincipal.new()` (sem argumentos, sem cena) e o adiciona como filho dele. O `_ready()` do menu monta tudo.
  Se o menu precisar de uma `.tscn`, avise: o Fluxo passa a usar `load(...).instantiate()` em vez de `.new()`.
- O menu **não** chama `GameState.salvar()`, `apagar_save()` nem `novo_jogo_com_copia()`. Só lê. Quem age é o Fluxo.

## 2. O que a lógica entrega (GameState, `scripts/estado/menu_opcoes.gd`)

| Chamada | O que devolve |
|---|---|
| `GameState.tem_save() -> bool` | há `save.json` (ou o backup `.bak`) na pasta de save. CONTINUAR só existe se for true. |
| `GameState.parede_menu() -> Array` | ids (String) das camadas visíveis **na ordem do `parede.json`** (desenhe nessa ordem, por cima do fundo e por baixo da faixa). Sem save = só as de `requires` vazio. |
| `GameState.parede_camadas() -> Array` | o mesmo, mas já com os dicionários do `parede.json` (`id`, `file`, `pos`, `size`). Mais prático para desenhar. |
| `GameState.volume_geral`, `volume_efeitos` | float 0.0 a 1.0 (padrão 1.0). Atribuir **não** aplica nem grava: chame `opcoes_aplicar()` e depois `opcoes_salvar()`. |
| `GameState.tela_cheia` | bool (padrão false). |
| `GameState.opcoes_aplicar()` | põe os valores nos buses de áudio (`Master` e `Efeitos`) e na janela. Use a cada mudança do controle (o jogador ouve na hora). |
| `GameState.opcoes_salvar()` | grava `user://opcoes.cfg` (nunca o save). Chame ao soltar o controle ou ao fechar OPÇÕES. |
| `GameState.opcoes_carregar()` | lê o arquivo e aplica. Já é chamado na inicialização; a UI não precisa chamar. |

Fatos úteis para o desenho:
- Os valores de volume são lineares (0 a 1); a conversão para dB é nossa.
- F11 (AppControls) também alterna tela cheia. Depois de F11 o `tela_cheia` do GameState pode estar desatualizado:
  leia `GameState.tela_cheia_atual()` ao abrir OPÇÕES (devolve o estado real da janela).
- Texto "CONTINUAR" pode mostrar o horário do último save: `GameState.ultimo_save_unix` (0 = nenhum).

## 3. Fluxo (`ui/fluxo.gd`)

- Ao abrir o jogo (cena principal, fora de `--script`), o Fluxo chama `mostrar_menu()` em `_ready`.
  Os testes (`--script`) e o flag `--sem-menu` pulam o menu, então nada que já existe muda.
- `Fluxo.mostrar_menu() -> bool`: devolve false (e o jogo segue como hoje, direto na sala/abertura) se `ui/menu_principal.gd` não existe.
- `signal menu_escolheu(acao: String)` do Fluxo: repete a escolha do menu depois que o Fluxo agiu (`"continuar"`, `"novo_jogo"`, `"sair"`).
  Valor extra `"copia_falhou"`: a cópia de segurança não foi possível, o save **foi mantido** e o menu continua aberto; a UI pode mostrar
  um aviso (o texto também está em `GameState.avisos`).
- Enquanto o menu está aberto: `GameState.menu_aberto == true`, o jogo fica parado (`definir_modal`), **nada é salvo** (autosave e fechar a janela
  não gravam; assim um menu parado sem save não cria save), e nenhuma janela/pendência abre por baixo (fim de carreira, luta pendente, escolha de arte).
- `"continuar"`: fecha o menu e roda as pendências de sempre (fim pendente, luta pendente, escolha de arte, prévia do dia). O resumo
  "Enquanto você estava fora..." fica onde está hoje (depois do CONTINUAR).
- `"novo_jogo"`: com save, `GameState.novo_jogo_com_copia()` (copia para `user://save_copia_AAAAMMDD_HHMMSS.json`, apaga o save, zera o estado);
  sem save, só zera o estado. Fecha o menu e a **abertura toca de novo** (o marco `prologue_seen` some junto com o save).
- `"sair"`: `get_tree().quit()` sem salvar.
- O menu some com `queue_free()` feito pelo Fluxo; a UI não se remove sozinha.

## 4. Parede: como ler o `requires`

Já resolvido em `parede_menu()`. Para referência: `milestone` = `GameState.marco(id)`; `black_cat_rounds_min` = `GameState.lenda().rounds >= n`.
Chave desconhecida em `requires` = camada escondida (nunca aparece por engano). Várias chaves = todas precisam valer.

## 5. Dúvidas deixadas para o Produtor

- "Enquanto você estava fora..." (§5.11 do PROMPT) não existe no código hoje (não achei a tela). O gancho ficou documentado, nada foi inventado.
- Áudio: não havia bus "Efeitos". Criei em tempo de execução e mando todo `AudioStreamPlayer` novo para ele (sem tocar nos arquivos de UI).
