# Ronda 2a1 (brigas de beco): relatório do QA

## Reteste (2026-11-26)
**Veredito: PRONTA para o Diretor.** B1-B5 corrigidos. Restam 2 bugs de ferramenta (T1 e T2, do Programador), nenhum do jogo, e 3 observações baixas.

| Bug | Resultado | Evidência |
|---|---|---|
| B1 recorte na parede | **OK** | `r2a_sala_{1,2,3}_{garage,gym,center}.png`: 1, 2 e 3 recortes aparecem nos 3 locais, na parede, sem cobrir o cartaz principal; o hover (`r2a_sala_hover.png`) mostra a manchete "PORTEIRO PERDE O PORTÃO". O cartão cinza ao lado do cartaz da LIGA na academia é o capuz no prego (já existia na Ronda 1, ver `ronda_capuz_academia.png`). |
| B2 nome escondido | **OK** | Aproximação (`r2a_aprox_nome_oculto`): "LADRÃO DO ESTEPE"; depois de vencer (`..._nome_aberto`) vira o nome. Prévia: retrato em silhueta e "LADRÃO DO ESTEPE" sem vitória; "O CHAVE DE RODA" com retrato depois de vencer. HUD da luta: "O LADRÃO DO ESTEPE". |
| B3 selo de desafio e cadeado | **OK** | Dossiê com selo de desafio feito (`r2a_dossie_desafio_feito`) e fichas trancadas com cadeado ("VENÇA O BRAÇO DE ALICATE PRIMEIRO", "LENDA 5") em `r2a_dossie_meio` e `r2a_dossie_ficha`. |
| B4 artigos e "LENDA n" | **OK** | "O PORTEIRO", "O BRAÇO DE ALICATE", "O CHAVE DE RODA", "LENDA 5", "LENDA 3" nas capturas. |
| B5 vulto x morcego | **OK, risco baixo** | Ver abaixo. |

**B5.** `docs/arte/mockups/ronda2a_vulto_antes_depois.png`: a capa agora é de lona cinza-clara, curta, com remendo azul e barra torta; as orelhas ficaram baixas e
arredondadas; na silhueta chapada sumiu a capa pontuda e a orelha em ponta. Na luta (`r2a_luta_beco`) lê-se como moleque de touca de gato com lona nas costas, não
como herói de capa preta. Sobra a ideia "touca com orelhas + capa" do conceito que o dono aprovou, mas cores e cortes já não lembram o Batman. Se o dono ainda
achar parecido, o próximo passo é tirar a capa e deixar só a touca.

### T1. Instabilidade de `r2a_aprox_dica` (Programador corrige)
`ui_audit --estados r2a_aprox_dica --estrito` com janela (`--position 1950,40 --max-fps 30`), 8 execuções: **5 passaram e 3 falharam (execuções 6, 7 e 8) com
"PROBLEMAS 2"**. A falha reproduz.
- **Causa:** `scripts/estado/briga_beco.gd:251` faz `gs._rng_ronda.randomize()` a cada aproximação (certo no jogo: cada noite sorteia seus ciclos). O estado
  (`tools/ui/audit/estados_ronda2a.gd`, linhas 247-265) anda o minigame com um robô de 3000 quadros que só segura enquanto o ladrão trabalha. Com uma sorteada ruim
  (gaps curtos e avisos falsos) a noite de 30 s acaba antes de o vulto segurar 0,6 s perto: `fase "fim", restante 0, distancia 0.77, dica_soltar false`.
  O jogo não tem bug; o verificador depende do sorteio.
- **Correção:** no estado do verificador. Como o `randomize()` roda dentro do início da aproximação, ajustar `_rng_ronda.seed` antes do IR não adianta. Opções:
  (a) depois de `_entrar`, trocar `au.gs._ronda_jogo` por `RondaLogica.new(cfg, null)` (sem rng usa o gap médio e sem avisos falsos, sempre igual) ou com um
  `RandomNumberGenerator` de semente fixa; (b) um gancho de teste em `briga_beco.gd` que pula o `randomize()` quando uma semente é pedida. Os estados de prévia e
  luta usam `_ate_previa` e não falharam nas execuções.

### T2. `--estados` com nome inexistente (Programador corrige)
Confirmado: `ui_audit --estados estado_que_nao_existe --estrito` e `--estados "r2a_*"` terminam com **exit 0** e `ESTADOS 0 | PROBLEMAS 0`, sem aviso. Um erro de
digitação passa como "verde". Esperado: falhar (exit 1) quando algum nome pedido não existe ou quando roda 0 estados (`_quer` em `tools/ui/ui_audit.gd` só compara
`nome in pedidos`; glob não é suportado: ou suportar, ou avisar).

### Testes, foto e save
- `tools/run_tests.ps1` headless: **TODOS OS TESTES PASSARAM**, 0 `FAIL`, 0 `SCRIPT ERROR`, 0 `ERROR:`; todos os blocos `n/n PASS` fechados (inclui `test_ronda2a`).
- `tests/qa_ronda2a.gd`: **122/122 PASS**.
- **Foto** (`foto.gd`, worktree x `git archive` da origin/main ecce6a3): mesmo tamanho (302.750 bytes), 6 linhas diferentes (79, 161, 241, 322, 405, 485); nó a
  nó, em todas muda só o `id` **`cat_thanks`** (+40% para +20%). **A única diferença é o corte aprovado.**
- **Save real** (`%APPDATA%\Godot\app_userdata\Fightclicker`): `save.json` e `save.json.bak` com `LastWriteTime` 23/11/2026 22:37, MD5 `74E12CCA041B988137886584BE0B630B`
  e `CF80E90DE76A0D676F553F69C32EA71F` (iguais aos do primeiro relatório). Todo Godot deste reteste rodou com `APPDATA` temporário; backup extra no scratchpad; o guarda
  "save real do dono não mudou" passou.

### Observações baixas (não bloqueiam)
- O HUD da luta mostra o retrato real do bandido com o nome escondido ("O LADRÃO DO ESTEPE"); a prévia usa silhueta. O retrato entrega quem é.
- Prévia "LADRÃO DO ESTEPE" (sem artigo, por largura) x HUD da luta "O LADRÃO DO ESTEPE".
- Prêmio da vitória (`r2a_premio_vitoria`): "+4 LENDA" com "LENDA 3" e pontinhos 3 vazios e 2 cheios; segue o mesmo padrão da Ronda 1 (`ronda_premio_normal`).

---


QA, 2026-11-26. Worktree `ronda-2a` (HEAD 474b0a7 + trabalho não commitado). Base: `ronda2a-escopo.md`, `ronda2a-design.md` (§10 A1–A14 e
"Decisão do dono": `cat_thanks` 0,2), `ronda2a-contrato.md`, `ronda2a-textos.md`. Nada de `scripts/`, `scenes/`, `ui/`, `data/` ou `assets/` foi
alterado. Único arquivo novo do QA: `tests/qa_ronda2a.gd`.

## Veredito
**NÃO está pronta para o Diretor.** Tudo o que é lógica, save, números e verificador está verde, mas **o recorte dos bandidos na parede da sala
não foi implementado** (B1), e o critério A10 e a promessa "RECORTE NA PAREDE" da janela de prêmio dependem dele. Corrigido o B1 (ou o Diretor
decidir adiar e tirar a linha do prêmio), o resto é aprovável com os ajustes baixos B2–B5.

## 1. Testes automáticos
| Comando | Resultado |
|---|---|
| `tools/run_tests.ps1` (1ª vez, headless) | TODOS OS TESTES PASSARAM, 0 `FAIL`, 0 `SCRIPT ERROR` (45 arquivos de teste, verificador "cena torta" e cena principal 120 frames incluídos) |
| `tools/run_tests.ps1` (2ª vez) | idem, TODOS OS TESTES PASSARAM, 0 `FAIL` |
| `tests/test_ronda2a.gd` (dentro do run_tests) | 477/477 PASS |
| cena principal `--quit-after 300 -- --save-dir=user://test/cena_qa/` | sai com 0, 0 `ERROR` |
| `tests/qa_ronda2a.gd` (novo, QA) | 122/122 PASS |
Os `WARNING: RondaData ... ausente ou inválido` no console do `test_ronda2a` vêm do teste que carrega dados ruins de propósito.

### Cenários extras do QA (`tests/qa_ronda2a.gd`)
- **Abuso da API:** ids vazios/inválidos/caixa errada, IR duas vezes, SUSTO durante a briga, táticas ruins, LUTAR 2x e 3x (devolve `{}` e o save
  não muda), `ronda_concluir` e `ronda_voltar` repetidos (mesmo prêmio, lenda não soma de novo), SAIR na prévia e depois LUTAR (recusa).
- **Extremos:** atributos 0, 1e300 e mistos; lenda 9999; lenda a 999.999.999 nunca passa de 1e9; lenda da noite sempre entre 1 e 4.
- **Saves sujos (15 formas de `alley` + 5 de `black_cat` + capuz sujo):** string, array, null, número, INF, NAN, strings no lugar de números,
  negativos, gigantes (9.2e18), id com espaço/caixa errada, `challenge` não booleano ou sem vitória, `first_win_campaign` absurdo. Todos carregam,
  o Esconderijo abre e o bloco fica coerente (nada negativo, `won` e `lost` ≤ 1e9, `challenge` só com vitória, campanha ≤ atual).
- **80 noites seguidas** (vencendo, perdendo, com as 3 táticas e os 3 fins de aproximação): `rounds` = noites, `scares ≤ 3 × rounds`, os 3
  bandidos acabam vencidos, ida e volta no disco idêntica.
- **Prévia x motor com 1000 sementes independentes** (4 escalas de atributo x 3 bandidos x 3 táticas): pior diferença 3 pontos (ex.:
  tire/defensivo mostra 95,0%, real 92,3%); a prévia usa 200 sementes, então 3 pontos é o esperado.
- **Relógio e sorteios:** 30 s de aproximação + prévia + prêmio não mexem em `play_seconds`, `campaign_seconds`, dinheiro nem nos 5 sorteios
  (`rng`, `_rng_evento`, `_rng_fala`, `_rng_sucessao`, `_rng_treino`); a trava de 120 s devolve a sala.
- **Disco:** `save.json` com o mesmo md5 durante aproximação e prévia; autosave no meio da prévia não grava nada (reabrir = capuz no prego, sem
  `alley`); fechar logo depois do LUTAR = tudo gravado uma vez e reabrir 2x idêntico; versão do save em disco continua 13.
- **Estilos:** 500 rascunhos com os 3 estilos liberados, nenhum sorteou estilo; o estilo é o último da lista e leva a marca do gato nos 3 campos;
  se a ficha some o estilo some da lista.
- **"Quem briga = quem só faz SUSTO", roteiro B diferente do dos desenvolvedores** (lê Esconderijo/Dossiê, SAI na aproximação, entra de novo,
  mexe na prévia, taticas variadas, ganha e perde): 10 noites, save campo a campo igual (sem `black_cat` e sem `career.black_cat_hood`) e os 5
  sorteios iguais.

## 2. Critérios A1–A14
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| A1 | `foto.gd` igual à main | **OK** (com a única diferença aceita) | ver §3 |
| A2 | quem briga = quem só faz SUSTO, sucessão com 3 estilos | **OK** | `test_ronda2a` `_teste_quem_briga_igual` + `qa_ronda2a` roteiro B (ver §1); rascunho igual com 3 estilos liberados (sorteio e 500 rascunhos) |
| A3 | teto ≤ 10% com `cat_thanks` 0,2 | **OK, 8,8%** | ver §4; o jogo usa o valor do json (teste `cat_thanks = +20% (equipe x1,2)`) |
| A4 | perder: carreira igual, lenda +1 (+1 com SUSTO), capuz em 240 s, REVANCHE, Dossiê intacto | **OK** | `test_ronda2a` `_teste_derrota_pequena` (239 s sem capuz, 240 s com) e QA (lenda entre 1 e 4 em extremos) |
| A5 | destrave: lenda 29 ou sem marco = SUSTO; lenda 30 + marco = Esconderijo; ordem 1º, 2º, 3º | **OK** | `_teste_destrave` (lenda 29, 30 sem marco, 30 com marco, 2º/3º fechados, `pode_ir`) e QA (lenda 9999) |
| A6 | chance da prévia = motor; casos do Python; luta só usa `_rng_ronda` | **OK** | `_teste_python_exato` e `_teste_previa_honesta` (6 combinações, 3 bandidos); QA 1000 sementes ≤ 3 pontos; 5 sorteios intactos |
| A7 | contagem + aproximação ≤ 10 s; SAIR deixa o capuz e não grava | **OK** | contagem 2 s + 8 s = 10,0 s; SAIR na aproximação e na prévia: save igual byte a byte; noite inteira (prévia, luta ≤ 19 s, prêmio ~3 s) dentro de ~45 s pelo design (não cronometrei a luta animada) |
| A8 | K.O. com letreiro, sem sangue, vulto sem rosto nem nome | **OK nas capturas** | ver §6; `sangue` só aparece no comentário `ui/tela_luta.gd:1622` ("sem sangue"); vulto com máscara e faixa vermelha nos olhos, nome "???" |
| A9 | batman/morcego/gotham = 0 | **OK** | grep em `data/ scripts/ ui/ scenes/ tools/ui` = 0 (só o próprio teste cita as palavras). Risco visual em B5 |
| A10 | ficha, recorte e estilo no lugar certo e persistem | **FALHOU em parte** | ficha e estilo OK (Esconderijo, Dossiê, personalização, persistem em `permanent.black_cat`). **Recorte na parede não existe** (B1) |
| A11 | save v13: fechar antes = nada; depois = uma vez; saves sujos carregam | **OK** | `_teste_fechar_o_jogo` + QA disco/autosave + 20 saves sujos; cópia sem o campo abre igual |
| A12 | run_tests verde, save de teste, `--position 1950,40`, um Godot por vez | **OK** | 2 execuções verdes; guarda do save real 4/4 PASS nas duas |
| A13 | `ui_audit --estrito` 0 problemas | **OK** | 22 estados `r2a_*`: **ESTADOS 22 / PROBLEMAS 0**; placar de `ignore` 7 (meta ≤ 15), 7 com motivo, 0 sem motivo |
| A14 | D2 SOLTE E CLIQUE! com 0,6 s | **OK** | `_teste_d2_dica` (0,5 s sem dica, 0,63 s com, soltar apaga, regra inalterada) e captura `r2a_aprox_dica` |

## 3. Foto
Comando: `foto.gd` da worktree contra `git archive origin/main` (ecce6a3, ainda sem `alley` e com `cat_thanks` 0,4), mesmo `--out`, `APPDATA` temporário.
- **Quem não joga = igual:** os dois arquivos têm 717 linhas e 302.750 bytes e diferem em **6 linhas** (79, 161, 241, 322, 405, 485), todas o mesmo
  trecho do mapa da árvore: `cat_thanks` `effect_text` "+40% TREINO/S DA EQUIPE" → "+20% ...", `effect_value` 0.4 → 0.2. É exatamente o corte aprovado
  pelo dono. Nenhuma outra diferença (comparei trecho a trecho).
- **Quem briga = quem só faz SUSTO:** igual (testes do dev + roteiro B do QA, §1).

## 4. Teto de 10%
`ronda2a_sim.py teto` com Blender Python `-I`, `SIM_NF=24` (24 jogadores por linha), `SIM_TETO_VARS=tudo_max` (+ `base`), 6 combinações x 4 e 3 cliques/s x CENTRO
cheio e vazio, `cat_thanks` do `ronda.json` (0,2). **Pior trecho de todas as linhas: 8,8%** (Boxe Contragolpista 4/s, CENTRO cheio, Muralha). Próximos: JJ
Finalização 3/s 8,7%, JJ 3/s CENTRO vazio 8,2%, JJ Por cima 3/s 8,1%. Todas ≤ 10%; esperado do design ~8,7%. Margem de ~1,2 ponto (ruído de 24 jogadores
é de 1 a 2 pontos): se a 8b mexer em equipe, Legado ou região, medir de novo.

## 5. Save real
`%APPDATA%\Godot\app_userdata\Fightclicker\save.json` (md5 74E12CCA041B988137886584BE0B630B) e `save.json.bak` (CF80E90DE76A0D676F553F69C32EA71F) têm `LastWriteTime` de
23/11/2026 22:37, antes desta sessão; o `test_real_save_guard.gd` (`--antes`/`--depois`) e o checador de cada teste confirmaram "save real não mudou" nas duas
execuções. Observação: o md5 "antes" que gravei no início ficou truncado (formatação da tabela), por isso a prova é o `LastWriteTime` e o guarda, não a comparação de hash.
Os testes só escreveram em `user://test/` e na pasta temporária do APPDATA usada para foto e verificador.

## 6. Tom, vulto e capturas (`r2a_*`, 22 estados, janela em 1950,40 a 30 fps)
- **Sangue:** nenhum texto. Nos sprites de K.O. (`opp_alley_*` e `vulto/fight_vulto_ko*`) procurei pixels vermelhos: o vermelho `(212,71,58)` do vulto é a faixa
  dos olhos da máscara; o do `bike` são ~10 pixels de detalhe; o da arena é o pichado "VILA". Nas capturas do K.O. (`r2a_luta_beco_fim`) o bandido cai sem sangue e a tela
  de prêmio aparece por cima. OK.
- **Vulto sem rosto:** máscara de gato com faixa vermelha nos olhos; retrato do HUD mostra o mesmo; lutador da esquerda = "???". Nenhum dado da noite traz o nome do discípulo.
- **Esconderijo, quadro, Dossiê, ficha, aproximação (contagem e com a dica), prévia (tire e gate), luta no beco (com e sem estilos), prêmios (vitória, derrota, desafio, nível), personalização:**
  tudo alinhado, nada cortado ou colado; texto lê bem. Achados de leitura estão em B2–B4.

## 7. Bugs
| # | Gravidade | Onde | Problema | Quem corrige |
|---|---|---|---|---|
| **B1** | **Alta** (reprova A10) | `ui/sala.gd`, `assets/sprites/manifest.json`, arte | O **recorte de cada bandido vencido na parede dos 3 locais** (design §6.2, escopo §3.3, pontos `alley_clipping_spot`, `gym_alley_clipping_spot`, `center_alley_clipping_spot`) não existe: `grep alley_clipping` no manifest e em `ui/` = 0, `ui/sala.gd` não trata bandido nem Dossiê, e `docs/arte/ronda2a-manifest.md` não cita recorte. A janela de prêmio diz "RECORTE NA PAREDE" (`alley_clipping_new`) e nada aparece na sala. Para reproduzir: vencer o `tire` e ir para a sala. | Diretor de Arte (sprites + 3 pontos) e Designer UI/UX (`sala.gd`); ou o Diretor decide adiar e o Roteirista/UI/UX tiram a linha do prêmio |
| B2 | Baixa | `data/ronda.json` (`alley_occ_*`) / HUD da aproximação e prévia | O **nome do bandido aparece antes de vencer**: "ZECA, NO ESTEPE" no topo da aproximação do `tire`, "SEU PÉ DE CABRA" na prévia do `gate`, enquanto o Esconderijo e o Dossiê mostram "???" (design §1 e §6.1). É o que o texto do Roteirista manda, mas contradiz o design. | Decisão do Diretor/Designer; depois Roteirista (`alley_occ_*`) |
| B3 | Baixa | `ui/tela_esconderijo.gd:218-221` | Dossiê: desafio **feito** e **por fazer** quase não se distinguem (texto INK x G0 `#4a4552` e ícone do gato escurecido, sobre papel claro). O design pede selo do gato quando feito. | Designer UI/UX |
| B4 | Baixa (texto) | `data/ui_texts.json` | "VENÇA BRAÇO DE ALICATE PRIMEIRO" sem artigo (o 1º sai "VENÇA O CHAVE DE RODA PRIMEIRO"); o cartão do SUSTO diz "NÍVEL 3" e o da briga "PRECISA DA LENDA 3" (mesmo conceito, dois nomes). | Roteirista |
| B5 | Risco (não bug) | arte do vulto em luta | A silhueta do vulto (capuz com orelhas pontudas e capa) lê quase como o Batman, apesar de ser "Gato Preto". Os textos passam na busca; o risco é visual e de identidade 100% original. | Diretor de Arte / Diretor de Jogo decidem |

## 8. Riscos
- **Teto com margem curta (8,8% x 10%).** O corte de +20% foi o que fez passar; qualquer mudança em equipe, Legado ou região na 8b exige repetir `ronda2a_sim.py teto`.
- A prévia da noite não tem tempo limite (o relógio está parado): intencional, mas a tela pode ficar aberta para sempre. Não achei efeito colateral.
- Medi a duração da aproximação (10 s) e a trava do prêmio (120 s), mas não cronometrei uma noite inteira com a luta animada; o ~45 s vem do design.
- `esc_travado` (Esconderijo com a briga fechada) só existe no verificador: no jogo o capuz leva direto ao SUSTO, então o jogador não o vê.
- O dossiê "ficha do chefe" mostra "PRECISA DA LENDA 5" mesmo antes de existir o chefe (2a2): é o que o design quer, mas promete algo que só chega depois.
