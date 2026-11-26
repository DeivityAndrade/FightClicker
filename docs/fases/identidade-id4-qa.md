# ID4 (menu principal): relatório de QA

Data: 2026-11-25. Branch `identidade-visual`. Tudo rodado com `APPDATA` temporário (um Godot por vez).

## Veredito: APROVADO (0 bugs bloqueantes; 3 observações menores)

## Resultados

| # | Conferência | Resultado | Evidência |
|---|---|---|---|
| 1 | `tools/run_tests.ps1` headless, 3 vezes | OK | 3 rodadas, saída 0, "TODOS OS TESTES PASSARAM" (5189 / 5189 / 5190 linhas PASS; a diferença é só texto com tempo medido). Nenhum FAIL, nenhum SCRIPT ERROR, nenhum aviso de vazamento (leak / still in use). `test_menu` e `test_menu_real` passaram nas 3. Vazamento intermitente **não reproduziu**. |
| 2 | `ui_audit --estrito` só nos 16 estados do menu, com janela | OK | `ESTADOS 16 \| PROBLEMAS 0`, estrito: 0 achados em todas as regras. Placar de ignore: 3, todos com motivo (Parede, Faixa, LogoGrupo; arte sem texto). |
| 2b | Capturas (parede vazia / meio / cheia) | OK | Vazia: só SOCO, LUTA SÁBADO, ALUGA-SE, luvas. Meio: acrescenta GARAGEM, RAÍZES, polaroide, foto antiga, faixas JB, LIGA. Cheia: acrescenta CAMPEÕES, DERRUBA, VULTO, capuz. Sem spoiler no save novo. |
| 2c | Foco, confirmações, opções, intro | OK | Foco nos 4 botões com setas dos dois lados. Confirmação 1 e 2 com título centrado. Opções com 2 barras, TELA CHEIA e VOLTAR centrados. Intro: faixa entrando e impacto com lascas, sem corte. |
| 3 | Jogo de verdade (cena principal sem `--script`, janela no monitor 2, ~1 min, teclado por mensagens de janela) | OK | Menu aparece primeiro, intro toca e o brilho do logo roda. Sem save: só NOVO JOGO / OPÇÕES / SAIR (CONTINUAR não existe). Seta para baixo + Enter abre OPÇÕES; seta esquerda x3 baixou EFEITOS de 100% para 85%; Esc volta ao menu. NOVO JOGO (sem save, sem confirmação) leva à abertura (garagem com "SEGURE ESC: PULAR"). |
| 4a | Cópia de segurança idêntica | OK | `test_menu`: "a cópia é idêntica ao save apagado", nome `save_copia_AAAAMMDD_HHMMSS.json`, duas cópias seguidas com nomes diferentes. Não exercitado no jogo real com save (só nos testes). |
| 4b | `opcoes.cfg` fora do save | OK | Arquivo próprio ao lado do save (`geral=1.0, efeitos=0.85, tela_cheia=false` gravado no jogo real). `test_menu`: NOVO JOGO não apaga `opcoes.cfg`. |
| 4c | Abrir e ficar no menu não cria save | OK | No jogo real: 10 s e depois +20 s com menu aberto e OPÇÕES visitado, só `opcoes.cfg` na pasta. `save.json` só apareceu depois do NOVO JOGO (jogo começou). |
| 4d | Save real do dono intocado | OK | md5 antes e depois idênticos: `save.json` 74e12cca041b988137886584be0b630b, `save.json.bak` cf80e90de76a0d676f553f69c32ea71f. Cópia de segurança dos dois arquivos feita fora do projeto e não precisou ser usada. |
| 5 | `foto.gd` idêntica à da origin/main | OK | `git archive origin/main` extraído em pasta própria: as duas fotos (716 linhas) têm md5 d1549e8f4a2a3d533012cd59f07ef781, `cmp` sem diferença. |
| extra | `tools/ui/verificar_menu.gd` (headless) | OK | 19 PASS, "MENU: OK (0 falhas)": intro, pular intro, 4 botões, setas, 2 confirmações, Esc, opções, SAIR. |

## Bugs
Nenhum bloqueante.

## Observações menores (não reprovam, para o Diretor decidir)
1. CONTINUAR perde o destaque vermelho quando o foco vai para outro botão e fica em asfalto escuro (`menu_foco_sair.png`). O spec diz "CONTINUAR em `c_btn_foco`". Parece escolha de design (só o botão com foco é vermelho) e lê bem. Dono: UI/UX, se quiser o destaque fixo.
2. NOVO JOGO **com save** pelo jogo real (2 confirmações, cópia e abertura) foi verificado só pelos testes (`test_menu_real`, `verificar_menu`) e pelas capturas das telas de confirmação; no jogo real foi o caminho sem save. Teste manual pelo dono sugerido: abrir com um save, NOVO JOGO, conferir a `save_copia_*.json` na pasta.
3. Tela cheia no jogo real não foi alternada (evitei mexer na janela do dono); coberto só em memória pelo teste.

## Riscos
- Autosave e fechar a janela não gravam com o menu aberto (por contrato). Se o jogo for fechado no menu, nada se perde, pois nada mudou desde a abertura.
- O processo de teste do jogo real foi encerrado por mim (PID conferido pela linha de comando) ao fim; nenhum Godot ficou aberto.

alinhamento-ui: 16 estados verificados, 0 problemas. Capturas: `C:\Users\deivi\AppData\Local\Temp\claude\4ea5d9e6a0b1fa65\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\qa_menu_cap\`
