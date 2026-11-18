# Fase 6c2 (Mais longe que eu): relatório do QA

Data: 2026-11-16. Branch `fase-6c2` (working copy, 6b7be86 + alterações não commitadas). QA: `qa-tester`.
Escopo: `docs/fases/fase6c-escopo.md` (critérios 12 a 21), `fase6c2-design.md`, `fase6c2-api.md`, `fase6c2-textos.md`, `data/hall.json`, `data/escola.json`, `docs/arte/direcao-visual.md` §26.

Regras seguidas: Godot sempre com `APPDATA` numa pasta temporária nova (`...\scratchpad\appdata1..5`); o save real do dono nunca foi tocado (md5 de `save.json` antes e depois: `7f65ca02...5645611`, igual; os testes `test_real_save_guard` e o guarda dos testes passaram); janelas com `--position 1950,40`; nenhum Godot alheio foi encerrado; nada de `git stash/switch/checkout`; nenhum arquivo de `scripts/ scenes/ ui/ data/` foi alterado. Scripts novos em `tests/qa_f6c2_*.gd`.

## Veredito curto

**Pronto para o Diretor revisar, com ressalvas.** Todos os critérios de aceite passam (a lógica, o save, o balanço idêntico à 6c1, o `ui_audit` com 0 problemas, `run_tests` verde). Não há bug Crítico nem Alto. Há **1 bug Médio** (texto torto no mural com o save real do dono), **1 Médio-baixo de arte** (símbolo quase invisível na luta com parte de cima) e 4 Baixos/cosméticos. Nenhum bloqueia a fase; o B1 vale corrigir antes de o dono abrir o mural no save dele.

## Resumo dos bugs

| # | Gravidade | Resumo | Responsável |
|---|---|---|---|
| B1 | Média | Mural do save real do dono: o John mostra "PAROU EM " (sem nome) | Programador (+ Roteirista, texto de reserva) |
| B2 | Média-baixa | Símbolo da escola praticamente invisível na luta com parte de cima; a pose "hit" não o tem | Artista de Personagens (+ Diretor de Arte) |
| B3 | Baixa | Mural aberto na Carreira 1 (John jogando) mostra uma grade em branco, sem aviso | Designer UI/UX |
| B4 | Baixa (cosmético) | Seta de página desligada continua com o glifo branco | Designer UI/UX |
| B5 | Baixa (cosmético) | Etiqueta do balão do John em minúscula ("john"), a do discípulo em maiúscula e minúscula ("Beto Cruz") | Roteirista / UI |
| B6 | Baixa (observação) | `FALTA UNS N DE ATRIBUTO` pode citar um atributo diferente do que a prévia destaca em vermelho | Designer de Jogo / Designer UI/UX |

(Observações sem número no fim do documento.)

## Critérios de aceite, um a um

### 1. Testes e verificador de alinhamento
| Item | Resultado | Evidência |
|---|---|---|
| `tools/run_tests.ps1` | **OK** | `TODOS OS TESTES PASSARAM`: 30 arquivos `test_*.gd`, 3547/3547 PASS, 0 FAIL; `test_fase6c2.gd` 145/145; cena principal 120 frames sem erro; guarda do save real antes e depois OK. |
| Cena principal `--quit-after 300` (headless, `--save-dir=user://test/...`) | **OK** | Saída só com a linha de versão do Godot, sem `ERROR`. |
| `ui_audit --estados todos` (1280x720) | **OK** | `ESTADOS 357 | PROBLEMAS 0`, `EXIT 0`. Comando: `--resolution 1280x720 --position 1950,40 --script res://tools/ui/ui_audit.gd -- --estados todos --saida <pasta>`. 32 capturas `f6c2_*` conferidas a olho (ver abaixo). |
| Capturas `f6c2_*` | **OK com observações** | Mural na garagem e na academia fora do alvo e das cabeças; foto reta da academia com hover novo; janela do mural com 1, 4, 9, 30 retratos e nomes longos sem corte; hall nada/meio/tudo; "+N HONRA" na tela de fim; prévia com FALTA; balões dos mentores. Observações cosméticas em B4, B5 e no fim do documento. |

### 2. Honra
| Item | Resultado | Evidência |
|---|---|---|
| Fórmula 1, 3, 6, 15 (cinturão), 20, 27 | **OK** | `honra_da_saida`: 0→0, 1→1, 2→3, 3→6, 4+cinturão→15, 5→20, 6→27 (`qa_f6c2_logica.gd`, `test_fase6c2.gd`). Extremos: wins 7 = 29, wins 20 = 120 (a lista repete o último valor), wins -1 = 0, 0 vitórias com cinturão = 0. |
| Só por saída voluntária com 1+ vitória | **OK** | Aposentar com 0 vitórias: `honor_gained 0`, sem sinal `honra_mudou`. Derrota no Muralha com 3 vitórias: `fim.honor_gained 0`, saldo 0. Passar o posto no dia da luta com 2 vitórias: 3. |
| Aparece na confirmação e na tela de fim, nunca no HUD | **OK** | Capturas `f6c2_aposentar_honra(_cinturao)`: "E +15 DE HONRA / A HONRA FICA NO MURAL DA ESCOLA"; `f6c2_fim_honra_1/27`: "+27 HONRA" e "HONRA: 27"; `f6c2_fim_sem_honra`: "HONRA SÓ COM 1 VITÓRIA"; `f6c2_fim_derrota_mural`: nada sobre Honra. `grep honra\|honor ui/*.gd`: só nas janelas de fim, aposentar, mural e no cartão de início (fora do HUD). |
| Nunca multiplicada | **OK** | Com o nó "Caderno do velho" (+15% de Legado) ativo e 6 vitórias com cinturão: Legado sobe, Honra fica em 27. `aposentar()` com fim pendente devolve `{}` e não duplica Honra nem Legado. Soma 27 + 1 = 28 ao acumular duas campanhas. |

### 3. Hall
| Item | Resultado | Evidência |
|---|---|---|
| 6 nós com os nomes finais | **OK** | `hall_lista()`: FITA FROUXA, VAQUINHA, CADERNINHO, TURMA DA ESCOLA, LUVA NO GANCHO, PAREDE MAIOR (custos 10/20/30/35/45/50 = 190). |
| Compra só entre campanhas, sem reembolso | **OK** | Fora do fim: `comprar_hall` recusa e o estado é `closed`; depois de `nova_carreira`, recusa. Compra com saldo exato (10 com 10) deixa 0; recompra recusada; `honra_total` não desce; um `salvar()` por compra (save lido logo depois mostra saldo e `hall_nodes`). Comprar nó de Legado não mexe na Honra e vice-versa. |
| Efeitos na campanha seguinte (caminho real `receber_discipulo` → `confirmar_discipulo`) | **OK** | Com os 6 nós: `treino 500.0`, atributos 0; `nivel_luva 1`, `gestos_calcados [1]`, sem caixa; `cliques_para_abrir 2`; teto de retratos 8; equipe x1,10 (e x1,02 do retrato). A compra no fim não muda a campanha encerrada. Recarregar o save no meio da campanha: efeitos e saldo estáveis; caixa com 1 clique salva e recarregada fica "falta 1". Linha FALTA: vista em `f6c2_previa_falta` e `_max` (aparece só fora do verde, depois do cálculo em segundo plano). |
| Cliques da caixa na dica "caixa fechada" | **OK** | `ui/sala.gd:1299` agora usa `GameState.cliques_para_abrir()` (pendência da API fechada). |

### 4. Retrato com selo
**OK.** `mult_escola()`: 0 selos = 1,00; 3 = 1,06; 12 selos = 1,10 (teto 5); com `hall_wall` 12 selos = 1,16; 8 selos fazem o clique multiplicar 1,16 exatamente (um fator só, também no Metrônomo e na equipe). Derrota e saída com 0 vitórias não dão selo. Cartão de início mostra "O MURAL: +2% DE TREINO".

### 5. Mural
| Item | Resultado | Evidência |
|---|---|---|
| Na parede da garagem e da academia (academia só depois da cena) | **OK** | `mural_na_sala()`: garagem sempre; academia `{}` sem o marco `cena_primeira_academia` e com spot depois; local desconhecido `{}` (`qa_f6c2_gate.gd`). |
| O quadro cresce com o roster; abre a qualquer hora na sala | **OK** | Regra 1/2/4/8 em `ui/sala.gd:1713`. Clique real (evento de mouse) no centro e no canto do `click_rect` abre a janela em garagem e academia; Esc fecha e libera o jogo; com a prévia aberta não abre outra; clique duplo abre uma janela só; hover "MURAL DA ESCOLA / Todo mundo que vestiu a camisa."; da tela de fim o botão MURAL abre e fechar volta ao fim (`qa_f6c2_clique.gd`, 18/18). |
| John primeiro, 30 entradas por páginas, nomes longos | **OK** | `qa_f6c2_logica.gd`: 31 entradas, John na posição 0, `end_text` sem marcador cru. Capturas: páginas 1/3 e 3/3 (10 por página, 5x2), nomes de 25+ letras quebram em 2 linhas sem cortar. Ver B1 (texto) e B3 (mural vazio). |
| Não cobre foto, Osmar, mentores nem alvo | **OK** | `qa_f6c2_balao.gd` (janela real, garagem e academia, mentor John e discípulo): o retângulo do mural (176,128 54x22) não cruza a faixa do alvo, nem a cabeça do Osmar, do lutador, do mentor sentado ou do 2º mentor. Foto da academia (212,158) 8 px abaixo, sem sobreposição na captura. O balão do mentor passa por cima do mural (aceito no §26.1 do Diretor de Arte). |

### 6. Falas dos mentores
| Item | Resultado | Evidência |
|---|---|---|
| Ordem revanche, recorde, "mais longe que eu" com tetos | **OK** | `test_fase6c2.gd` (145 asserts) e leitura de `_fala_do_mentor` (`scripts/game_state.gd:4900`): ordem de `escola.json`, no máximo uma por vitória, `revanche` e `marca` com teto 1 por campanha, o teto só é gasto quando a fala toca. Mentor com `wins -1` nunca dispara "mais longe". |
| `own` ganha na revanche do próprio mentor | **OK** | Linhas `ml_revanche_own_*` têm `priority 8` contra 7 das genéricas; `own` verdadeiro quando o algoz é da campanha do mentor sentado. |
| Mentor fala, Osmar não comenta | **OK** | Fila de gatilhos só com `mentor_won`; `fight_won` não é disparado quando `mentor_line` não é vazio. |
| Balão não cobre cabeça | **OK** | `qa_f6c2_balao.gd`: 3 textos x (garagem, academia) x (John, discípulo): 0 falhas contra a cabeça do Osmar, do lutador, do mentor e do 2º mentor; fora do alvo e dentro da sala. `ui_audit` também (`f6c2_balao_mentor_john/last`). |

### 7. Símbolo da escola
| Item | Resultado | Evidência |
|---|---|---|
| Aparece desde a campanha do 1º cinturão da escola | **OK** | `campanha_do_simbolo()` = menor entre o marco `garage_saved`, o roster com `belt` e a campanha atual; antes: ninguém. No save real do dono vale a campanha 3 (marco `garage_saved`). |
| Peito com parte de cima, perna do calção sem ela | **OK** | `DiscVisual.textura`: `chest` se `top != none`, senão `leg`. Capturas `f6c2_simbolo_peito` (carimbo azul na camiseta branca) e `_perna`. |
| Garagem, luta, retrato, mural | **OK com ressalva (B2)** | `qa_f6c2_simbolo.gd`: das 140 folhas em camadas, todas têm `school_symbol` na ordem e nos pontos `chest/leg`; o símbolo muda pixels em todas, exceto `fight_player_hit_disc_layered` (e `_glove_l1..l4`) com parte de cima (0 pixel) e o retrato 32x32 da luta (`portrait_player_*`, só rosto). No retrato do mural o símbolo só aparece com parte de cima (decisão do §26.3). Garagem e mentores (`f6c2_simbolo_peito`): visíveis. |
| O John nunca usa | **OK** | `simbolo_na_entrada` exige `kind == "disciple"`; nenhuma folha do John tem camadas; John sem símbolo nas capturas do mural e do caixote. |

### 8. Save v13
| Item | Resultado | Evidência |
|---|---|---|
| Migração v12→v13 num save sintético | **OK** | `test_fase6c2.gd`: Honra por entrada [15, 0, 27, 0, 1 (wins -1), 3], saldo = total = 46, `hall_nodes []`, `fim.honor_gained 3`, Legado/recorde/mentores/marcos/falas vistas intactos, regravado como versão 13, segunda carga não soma de novo. |
| Cópia do save real (v12, campanha 6, Legado 450, 9 nós, 3 entradas no roster) | **OK** | Copiado para a pasta temporária (original só lido; md5 igual antes e depois). Migrado: Honra 0/0 (as 3 entradas são `defeat`), `hall_nodes []`, Legado 450, `career_number 6`, `best_wins 6`, 9 nós, marco `garage_saved` preservado, regravado `version 13`. Reabrir (duas vezes) mantém 0/0. Também rodado pela cena principal com `--save-dir` apontando para a cópia: migra para 13 sem erro. Mural real: John Bullet "PAROU EM " (B1), Novato "PAROU EM SEU MURALHA" (3 vitórias, com símbolo), Dani Cutelo "PAROU EM DUDU ALONGADO" (0 vitórias, com símbolo). |
| Save v13 corrompido | **OK** | `honor` negativo ou texto, `honor_total` texto, `hall_nodes` não-lista, nó repetido ou desconhecido, `honor > honor_total`, v13 sem campos: tudo saneado com aviso, sem exceção; mural abre. Fim pendente recarregado 3 vezes: Honra e roster estáveis, ticks de 200 s não alteram. |

### 9. Balanço
| Item | Resultado | Evidência |
|---|---|---|
| Hall vazio e sem retratos idêntico à 6c1 | **OK** | `tests/qa_f6c2_balanco.gd` rodado na árvore da 6c2 e numa extração limpa de `git archive origin/main` (0f2b62a): 1800 s de jogo com cliques e compras automáticas, previsões de 4 adversários e Legado de aposentar e de derrota. `diff` das duas saídas: **idêntico** (18 linhas). |
| `tools/sim/fase6c2_sim.py` | **OK (amostra pequena)** | Rodado serial (nota na seção Simulação): `ident` 4 de 4 idênticas; Honra por minuto, hall e teto de 10% batem com o design. A medição grande de `metas` não foi repetida. |

### 10. Pendência da 6c1: foto reta na academia com o hover novo
**OK.** `f6c2_foto_academia_hover.png`: foto reta no quadro 0 em (212,158), tooltip "A FOTO VEIO DA GARAGEM. ERA TORTA. AQUI FICOU RETA.", mural ao lado sem tocar a foto. `foto_antiga()` na academia: `tilted false`, `object_text old_photo_gym`.

### 11. Nenhum ERROR nem vazamento
**OK, com uma nota.** `run_tests` sem `ERROR`; cena principal limpa; meus scripts sem `ERROR`. Nota: abrir a cena principal com a **cópia do save real v12** imprime `ObjectDB instances were leaked at exit` / `1 resources still in use`; o mesmo acontece na extração limpa da 6c1 (`origin/main`) com o mesmo save, e some quando o arquivo já é v13. Não é regressão da 6c2 (anotado como observação O1).

## Bugs

### B1. Mural do save real: o John mostra "PAROU EM " sem adversário
- **Gravidade:** Média (visível no primeiro retrato do mural do dono; texto torto, mas nada quebra).
- **Passos:** copiar `save.json` real (v12, John com `end "defeat"`, `opponent ""`, `wins -1`) para uma pasta de teste; abrir o jogo; clicar no mural.
  Reprodução automática: `tests/qa_f6c2_logica.gd` (`_migracao_real_e_sintetica`) imprime `["John Bullet","PAROU EM ","?",false,""]`.
- **Esperado:** texto que faça sentido sem adversário (por exemplo o texto neutro `mural_end_passed` ou uma variante "PAROU NA DERROTA").
- **Obtido:** "PAROU EM " com o espaço final e nada depois (`preencher("PAROU EM {adversario}", {"adversario": ""})`).
- **Arquivo provável:** `scripts/game_state.gd` função `mural()` (~linhas 4770-4786: ramo `fim_tipo == "defeat"` sem checar `oponente == ""`); `data/ui_texts.json` (`mural_end_defeat`); `data/escola.json > mural.end_texts`.
- **Responsável:** Programador (escolher a chave de reserva); Roteirista (texto da reserva).
- Também vale para qualquer derrota migrada com `opponent` vazio ou com id que `lutas.adversario()` não conhece.

### B2. Símbolo da escola quase invisível na luta com parte de cima; pose "hit" sem símbolo
- **Gravidade:** Média-baixa (critério 7 pede "em todas as poses"; só o visual, a lógica está certa).
- **Passos:** `tests/qa_f6c2_simbolo.gd` (diferença de pixels entre `DiscVisual.textura(folha, look, false/true)`) e `tests/qa_f6c2_img.gd`; ou rodar `ui_audit --estados f6c2_simbolo_luta` e ampliar a captura.
- **Esperado:** símbolo legível no peito em todas as poses de luta de quem veste parte de cima (§26.3 diz "todas as 39 poses").
- **Obtido:** (a) `fight_player_hit_disc_symbol_chest.png` (336x104) tem **0 pixels opacos**; em `fight_player_hit_disc_layered` e `fight_player_hit_glove_l1..l4_disc_layered` com `top tank` o símbolo não muda nenhum pixel; (b) `fight_player_idle_disc_symbol_chest.png` tem 6 pixels opacos nos 4 quadros (1 a 2 por quadro): na captura `f6c2_simbolo_luta(_b)` (regata branca) não se vê nada no peito, o braço de guarda cobre. Sem parte de cima (perna) a luta mostra o símbolo (35 px na pose hit).
- **Arquivo provável:** `assets/sprites/disciple/fight_player_hit_disc_symbol_chest.png`, `fight_player_idle_disc_symbol_chest.png` e as variantes de luva; gerador `tools/art/make_arte_fase6c2.gd` / `personagem_lib.gd`.
- **Responsável:** Artista de Personagens (com o Diretor de Arte).
- Fora a luta, o símbolo aparece (garagem, mentor em pé e sentado, cenas, mural com parte de cima).

### B3. Mural aberto na Carreira 1 mostra a grade em branco
- **Gravidade:** Baixa.
- **Passos:** jogo novo (Carreira 1, John jogando, roster vazio) → clicar no mural da garagem (`QA_N=0 qa_f6c2_clique.gd`, captura `mural0_garage.png`).
- **Esperado:** o escopo diz "mural vazio (só o John)"; a parede mostra o quadro 0 com a foto do John, a janela deveria ter ao menos uma linha ("a escola começa aqui") ou o John.
- **Obtido:** lado esquerdo todo vazio (só "HONRA: 0", "SELOS: 0 (CONTAM 0 DE 5) +0% DE TREINO" e o hall fechado). Nada quebra.
- **Arquivo provável:** `ui/janela_mural.gd` `_grade()` (sem estado vazio); decisão do Designer UI/UX se o John em andamento entra.
- **Responsável:** Designer UI/UX (com o Designer de Jogo para a regra "campanha em andamento não entra").

### B4. Seta de página desligada continua com o glifo branco
- **Gravidade:** Baixa (cosmético).
- **Passos:** `f6c2_tela_mural_30.png` página 1/3: o botão "<" tem o fundo apagado, mas o "<" é branco como o ">" (ampliado em 4x); idem ">" na última página.
- **Esperado:** glifo cinza no estado `disabled`.
- **Arquivo provável:** `ui/janela_mural.gd` `_paginador()` (`botao_conteudo(..., UiTema.WHITE)` sem cor para `disabled`).
- **Responsável:** Designer UI/UX.

### B5. Etiqueta do balão do mentor: "john" em minúscula e "Beto Cruz" com maiúsculas
- **Gravidade:** Baixa (cosmético).
- **Passos:** `f6c2_balao_mentor_john.png` e `f6c2_balao_mentor_last.png`: a etiqueta do John sai "john" (`dialogos.json > cast.first.short`) e a do discípulo "Beto Cruz" (nome do roster, `ui/balao.gd` linha ~199: `nome = ...left(12)`).
- **Esperado:** mesma caixa para os dois (o do Osmar também é "osmar" minúsculo).
- **Responsável:** Roteirista (decidir o padrão) e UI para aplicar.

### B6. `FALTA UNS N DE ATRIBUTO` pode apontar para outro atributo que o realçado na prévia
- **Gravidade:** Baixa (observação de clareza; segue o cálculo do `motivo`, como pede o design §4.2).
- **Passos:** `f6c2_previa_falta.png` (Brutão do Posto): a linha vermelha destacada na tabela é FORÇA (133 contra 27,0K) e a linha nova diz "FALTA UNS 47.6K DE RESISTÊNCIA". Em `f6c2_previa_falta_max.png` os dois coincidem (Resistência).
- **Esperado:** o jogador entende por que atributos diferentes; ou um só critério.
- **Arquivo provável:** `scripts/game_state.gd` `_calcular_falta` / `motor.motivo`; `ui/janela_previa.gd`.
- **Responsável:** Designer de Jogo (decide se o realce acompanha a linha) e Designer UI/UX.

## Simulação (critério 9 e §9 do design)
Python do Blender com `-I`. O `multiprocessing.Pool` do `fase6c2_sim.py` dá `PermissionError: [WinError 5] Acesso negado` nesta máquina (também com `SIM_PROC=1`, porque o script usa `Pool(proc)` mesmo com 1). Contornei **sem alterar o repositório**: um wrapper em `scratchpad\runsim.py` troca `multiprocessing.Pool` por um Pool serial e chama `fase6c2_sim.main()`. Por ser serial, rodei bem menos jogadores que o design (96 × 20): veja os números abaixo; o design continua valendo como a medição grande.

Amostra do QA: 2 jogadores por perfil e 9 campanhas (honra), 2 jogadores por linha (teto), 4 jogadores x 10 campanhas (ident). Saída completa em `...\scratchpad\sim3.txt`. Comando: `SIM_PROC=1 SIM_N6=2 SIM_K6=9 SIM_N_TETO=2 python -I -u runsim.py honra escolha teto`.

| Medida | Design (96 x 20) | QA (amostra pequena) | Confere? |
|---|---|---|---|
| `ident`: hall desligado igual ao `fase5_sim` | idêntico | 4 de 4 sequências idênticas | Sim |
| Honra por vitória e cinturão | 1,3,6,15,20,27 | 0:0, 1:1, 2:3, 3:6, 4:15, 5:20, 6:27 | Sim |
| Honra/min, Boxe 5/s: sai na 1ª vitória / sai com o cinturão / padrão | 0,29 / 1,56 / 2,44 | 0,28 / 1,24 / 1,68 | Sim na ordem (sair cedo rende ~1/6 do padrão e ~1/4 do cinturão); valores absolutos menores pela amostra de 9 campanhas (a metade final dá 0,31 / 1,82 / 2,68) |
| Honra/min, Jiu-jitsu 3/s: 1ª vitória / cinturão / padrão | 0,24 / 1,36 / 2,00 | 0,23 / 1,04 / 1,31 | Sim na ordem |
| Honra por saída com Honra (padrão) | 27 | 27 (p10 27; 3/s: p10 3) | Sim |
| Saídas até o hall cheio (padrão) | 8 | 8 (onde o hall fechou em 9 campanhas; "nunca" nos demais, só 9 campanhas) | Sim |
| Minuto de cada vitória com a árvore cheia, Boxe 5/s (Dudu / Muralha / Kid) | 0:43 / 3:13 / 6:23 | 0:43 / 3:45 / 7:19 | Perto (mediana de 7 campanhas) |
| Sair x lutar no dia da 2ª luta: sair 20 / vencer e sair 80 / perder 10 Legado; Honra a 8,8 L; ponto de virada | 14% sem Honra, 20% com | sair 20 → 29; vencer 80 → 107; perder 10; virada 14% → 20% | Sim (idêntico) |
| Teto do hall, E_H / E_L no cinturão | pior caso 7,7% | Boxe 5/s 6,9%; Boxe 3/s 7,7%; Jiu-jitsu 5/s 3,5% | Sim (≤ 10%) |
| Teto do hall, E_H / E_L no Kid | 3,4% a 4,6% | Boxe 5/s 3,3%; Boxe 3/s 5,1%; Jiu-jitsu 5/s 4,1% | Sim |
| Hall sobre a árvore vazia (para referência) | 28 a 41% | 26 a 42% | Sim (e nunca acontece no jogo) |

Conclusão: o que dá para medir com uma amostra pequena concorda com o design (mesma ordem de grandeza, mesmos números exatos onde são determinísticos). A medição grande (metas da visão: Carreira 1 de 10 a 15 min, cinturão na 2ª a 4ª, tempo morto ≤ 10 min, `sec_metas`) **não foi repetida pelo QA** (muito lenta em modo serial); depende dos números do Designer (§9.4 do design). O que o QA conferiu de forma independente é a premissa dela: com hall vazio e sem retratos o jogo é **idêntico** ao da 6c1 (critério 9, diff acima), então a Carreira 1 e os tempos mortos da 6c1 continuam valendo.


## Observações sem número
- **O1.** Vazamento de `ObjectDB` ao sair ao abrir a cena com o save real v12 (também na 6c1 de `origin/main`; some com o save já v13). Pré-existente; investigar à parte.
- **O2.** `data/hall.json` mantém nomes e textos provisórios (`Vaquinha da escola`, `Caderno de recordes`...); o jogo usa as chaves `hall_*_name/_desc` de `ui_texts.json` (corretas). O `hall.json` pode apontar para elas para não confundir quem ler os dados.
- **O3.** As descrições dos nós têm os números fixos no texto (500, 10%, 3 retratos, "1 clique a menos"): se o Designer mudar `hall.json`, o texto não acompanha. Hoje bate.
- **O4.** Na janela do mural o chip "COMPRADO" / "COMPRA NO FIM DA CAMPANHA" fica encostado na última linha da descrição quando ela quebra em 2 linhas (FITA FROUXA, CADERNINHO, LUVA NO GANCHO, PAREDE MAIOR). O verificador não acusa; a olho está apertado, mas legível. Descrições com 3 linhas seriam cortadas (`mini(2, desc.size())` em `_no`); hoje nenhuma passa de 2.
- **O5.** Tela de criação do discípulo (`ui/tela_criar_discipulo.gd:264`) mostra o novo lutador sem o símbolo, mesmo quando ele já o usará na campanha. Pequena inconsistência visual.
- **O6.** A chave `honor_what` (linha de explicação no mural) existe em `ui_texts.json` mas nenhuma tela a usa.
- **O7.** Há dois comportamentos de Honra por saída "passar o posto": o botão da prévia do dia abre a confirmação (com +N HONRA); o botão da própria prévia não mostra a Honra antes do clique, só na confirmação. É o previsto no design (§2.3 pede a confirmação); anoto para o Diretor.
- **O8.** O cálculo da linha FALTA (`_falta_tarefa`, `WorkerThreadPool`) não é aguardado ao sair: não há `_exit_tree` no `GameState` esperando a tarefa (o mesmo vale para `_motivo_tarefa`, anterior à 6c2). `tests/qa_f6c2_thread.gd`: abrir a prévia com `hall_notes` e liberar o `GameState` sem `aguardar_falta()` imprime "A Thread object is being destroyed without its completion having been realized" e erros de recurso ao sair; com `aguardar_falta()` sai limpo. No jogo só acontece se o dono fechar a janela nos milissegundos do cálculo. Baixa. Arquivo: `scripts/game_state.gd` (acrescentar a espera no fechamento). Responsável: Programador.

## Riscos
- **Prazo do hall:** pelo design o hall fecha em 8 saídas no padrão e 13 a 14 só com cinturão (a borda de cima de 10 ± 3). O Diretor já recebeu esse ponto aberto (design §12.4); a decisão é dele.
- **Texto do John no mural** (`mural_first_left`, "FOI SEGUIR O RUMO DELE") continua provisório, à espera dos testadores da 6c1.
- **Escada de 4 adversários na garagem e 2 na academia (6 no total):** a Honra e as falas de "recorde" e "mais longe" param quando todos chegam ao Kid, como previsto; reavaliar na 8a.
- **Cobertura:** o balão foi testado só com `speaker` de mentor e três textos; falas de 2 linhas de 26 letras ficam no limite (largura 148 px); sem estouro nos testes.

## Arquivos de teste criados
`E:\Fightclicker\tests\qa_f6c2_logica.gd`, `qa_f6c2_efeitos.gd`, `qa_f6c2_reload.gd`, `qa_f6c2_gate.gd`, `qa_f6c2_balanco.gd` (comparável com `origin/main`), `qa_f6c2_simbolo.gd`, `qa_f6c2_img.gd`, `qa_f6c2_balao.gd` (janela), `qa_f6c2_clique.gd` (janela), `qa_f6c2_thread.gd`. Os que usam janela rodam com `--position 1950,40`. Variáveis: `QA_REAL_SAVE` (cópia do save real), `QA_OUT`, `QA_N`, `QA_SHOT`.
