# Fase 5 — QA: academia de bairro e artes marciais

Dono: QA. Data: 2026-11-07. Base: `fase5-escopo.md` (critérios e "Decisões do Diretor"), `fase5-design.md`, `fase5-api.md`, `fase5-textos.md`.
Nada em `scripts/`, `scenes/`, `ui/`, `data/` foi alterado pelo QA. Save real do dono: intacto (guarda `test_real_save_guard.gd` passou antes e depois; `save.json` com data de 2026-11-07 00:09, anterior à sessão).

**alinhamento-ui: 98 estados, 0 problemas**

Veredito curto: **quase pronto. Falta 1 correção trivial (B1, erro no console ao abrir a janela de arte), que reprova o critério 19 ao pé da letra.** Os outros bugs são baixos.

## 1. O que rodei

| Verificação | Comando | Resultado |
|---|---|---|
| Bateria | `powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1` | `TODOS OS TESTES PASSARAM` (inclui `test_fase5.gd`, `test_apparatus_ui.gd`, guarda do save real, cena principal 120 frames) |
| Cena principal | `Godot --headless --path E:\Fightclicker --quit-after 300 -- --save-dir=user://test/cena_qa300/` | sem ERROR, WARNING nem SCRIPT ERROR |
| Alinhamento | `Godot --path E:\Fightclicker --resolution 1280x720 --script res://tools/ui/ui_audit.gd -- --estados todos` | `ESTADOS 98 \| PROBLEMAS 0`. Olhei as 35 capturas `f5_*` (todas geradas na hora, 10:54). Console do verificador: 1 ERROR (B1) e 1 WARNING (artefato do verificador: save deixado pelo estado anterior, ver nota em B8) |
| Simulador Fase 5 | `fase5_sim.py` seções precos, curvas, identidade, b23, controle, assistido, carreiras | todas rodaram; resultados no item 3 |
| Regressão 4b e 4 | `fase4b_sim.py`, `fase4_sim.py` | **quebram** a partir de `curvas` (B5). `precos`, `metronomo` e `revanche` rodam e batem |
| Extras (QA) | `tests/qa_f5_extra.gd`, `tests/qa_f5_extra2.gd` (headless), `tests/qa_f5_ui.gd` (janela real), `tests/qa_f5_play.gd` (sessão jogada pela UI) | resultados no item 4 |

## 2. Critérios de aceite

| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Sem cinturão MUDAR não existe; com cinturão aparece com preço; apagado sem $ | **OK** | `f5_mudar_travado.png` (sem botão), `f5_mudar_pronto.png` (verde "MUDAR $1.00K"), `f5_mudar_sem_dinheiro.png` (apagado, "FALTA DINHEIRO"). `qa_f5_extra` Q1: $999.99 recusa, $1000 muda |
| 2 | Mudar: sala nova, aparelhos `_gym`, tudo intacto, $ descontado uma vez, multiplicador | **OK** | `qa_f5_ui`: duas chamadas seguidas de `pressed` no botão, `local_id=gym`, `dinheiro=0` (uma cobrança). Garagem "AUTO +27/S, POR CLIQUE +1" vira academia "AUTO +54/S" (x2) e "POR CLIQUE +3" com Boxe (1 x 2 x 1,5). `test_fase5._teste_mudanca` confere geradores/melhorias/luva/Metrônomo/aparelhos |
| 3 | NOVA CARREIRA (derrota ou aposentadoria) volta à garagem | **OK** | `qa_f5_extra` Q7: depois de aposentar e depois de perder na academia, `local_id=garage`, `arte_id=""`, escolha pendente, MUDAR `locked`. Na UI: `qa_f5_ui` e `qa_f5_play` (derrota para o Kid, carreira 3 começa na garagem) |
| 4 | 1ª chegada: janela abre, 1 clique, 2 artes liberadas | **OK** | `f5_arte_primeira.png`; `qa_f5_play`: "JanelaArte aberta (primeira=true)", clique em ESCOLHER, `arte_id=bjj`; `artes_liberadas()` = boxing, bjj |
| 5 | Carreira seguinte: escolha no início, antes do cartão; sem troca dentro da carreira | **OK** | `f5_nova_carreira.png` (janela, subtítulo "CARREIRA 3: ESCOLHA A ARTE", selo "ÚLTIMA") e `f5_nova_carreira_cartao.png` (cartão com "ARTE: JIU-JITSU" depois). `qa_f5_extra`: `escolher_arte` recusa trocar, recusa id vazio e inexistente. UI: ESC, Espaço e clique fora não fecham nem escolhem |
| 6 | Aparelho da arte: marca de fita, só após esteira, custa Treino, chega com efeito, zera na NOVA CARREIRA, o da outra arte não aparece | **OK** | `f5_garagem_pera_marca`, `f5_garagem_boneco_depois` ("DEPOIS DA ESTEIRA"), `f5_chegada_pera/boneco` (poeira/brilho), `f5_gym_*_marca`. `qa_f5_extra` Q6: com Boxe, `estado_aparelho(grappling_dummy)="absent"`, compra e foco recusados. Reaparece trancado após NOVA CARREIRA |
| 7 | Regra: Boxe só no clique manual (não Metrônomo/assistido); Jiu-jitsu na equipe até o teto | **OK** | `por_auto_soco()` idêntico com Boxe e com Jiu-jitsu (2,0); `por_clique()` 3,0 só com Boxe. Jiu-jitsu: +32% aos 60 s, teto exato 1,0 com 1e9 s e valor finito com 1e308 s; HUD mostra "(MÁX.)" (`f5_chip_jj_max.png`) |
| 8 | Prévia mostra o traço; teste de risco honesto continua | **OK** | `f5_previa_tonhao.png` ("BOXE: +10% DE DANO"), `f5_previa_kid.png` ("JIU-JITSU: -10% DE DANO RECEBIDO"). `qa_f5_extra2`: 600 lutas por caso, Tonhão e Kid x sem arte/Boxe/Jiu-jitsu x 3 táticas: prévia x resultado real dentro de 2,5 pontos (ruído de 600 lutas = 1,6), e `GameState.lutar()` dá o mesmo resultado do motor com o traço |
| 9 | 1ª chegada entre a 2ª e a 4ª carreira; 23b continua | **OK** | `carreiras`: 1ª chegada na carreira 2 (1-3) em todos os perfis. `b23` (400): cinturão na 1ª carreira 17,0% (5/s) e 24,2% (4/s), mais cedo 23:51 e 27:20. 23a: mediana do cinturão na carreira 2 |
| 10 | Nenhuma arte domina (≤ 15%); só assistido: Jiu-jitsu na frente; 5/s: Boxe na frente | **OK** (nota B6) | Seção "Critério 10" (188 carreiras): 5/s Boxe 8:25 x Jiu-jitsu 8:55 (5,9%, Boxe na frente); 4/s 8:55 x 9:25; 3/s 11:25 x 10:50 (5,3%, Jiu-jitsu na frente). Só assistido: Jiu-jitsu 18:25 x Boxe 30:57 |
| 11 | 2º adversário em 1 a 2 carreiras depois da chegada (4-5/s, perfil no amarelo); mesma carreira ≤ 25% | **OK** | G2 depois da chegada (mediana): Boxe 5/s 1, Jiu-jitsu 5/s 2, Boxe 4/s 2, Jiu-jitsu 4/s 2. Na mesma carreira: 16%, 16%, 0%, 0%. 3/s Jiu-jitsu 1 (Boxe 4, aceito pelo Diretor) |
| 12 | Carreira 1 igual à de hoje | **OK** | `identidade`: 64 de 64 carreiras 1 idênticas em 5/s, 4/s e 3/s |
| 13 | Tempo morto na academia ≤ 10 min (p90) com robô que aposenta após 8 min no vermelho, e a dica aos 5 min | **OK** | p90 = 8:00 (7:32 em Boxe 5/s) em todos os perfis, pior 8:00. Dica: `qa_f5_extra2` mostra `dica_aposentar().show` em t=300,1 s; texto "APOSENTAR AGORA LEVA 750 DE LEGADO" (`f5_dica_aposentar.png`); some com a tela de fim e na nova carreira |
| 14 | Do save novo até a carreira seguinte com a outra arte em ≤ 90 min (4-5/s) | **OK** | `carreiras`: mediana 41:06 a 46:15, p90 55:18 a 66:10 (3/s: 61:21 e 73:48) |
| 15 | Save v5 abre na v6 sem perder nada; v0 a v6; guarda do save real | **OK** | `test_fase5._teste_migracao_v5`, `test_migration.gd`. Extra: v5 com cinturão e dinheiro 0, 500, 999, 999,5 vira $1.000 e MUDAR "ready"; 1000 e 1000,5 ficam como estão |
| 16 | `data/` muda o jogo sem código | **OK** | `test_fase5._teste_dados_mudam_o_jogo` passou |
| 17 | `run_tests.ps1` passa inteiro | **OK** | `TODOS OS TESTES PASSARAM` |
| 18 | Alinhamento: 0 problemas (garagem/academia, com/sem arte, aparelho trancado/comprado, janela de arte, aba ESTILO) | **OK** | 98 estados, 0 problemas. Capturas olhadas uma a uma. Defeitos visuais que o verificador não pega: B2 e B3 (baixos) |
| 19 | Sessão de 40 min com 3 carreiras (uma chegando à academia), sem erro no console | **FALHOU** (B1) | `qa_f5_play.gd`, 3 carreiras, 61 min de jogo: carreira 1 perde para o Tank (25:19); carreira 2 cinturão aos 16:52, MUDAR clicado na UI, janela de arte, Jiu-jitsu, vence o Tonhão, perde para o Kid (29:32); carreira 3 janela de arte "primeira=false", escolhe Boxe. Console: **1 ERROR** `Resource file not found: res://` na hora que a janela de arte abre |
| F4 8 | Árvore CORPO+CARREIRA+ESTILO fecha entre a 5ª e a 8ª carreira (4-5/s) | **OK** | `carreiras`: Boxe 5/s 5 (4-7), Jiu-jitsu 5/s 5 (4-8), Boxe 4/s 6 (5-6), Jiu-jitsu 4/s 6 (4-7). "Só no verde" 4, aceito pelo Diretor |
| F4 23a/23b/24 | 23a, 23b, 24 | **OK** | 23a mediana na 2ª; 23b 17,0%/24,2%/23:51; 24: tempo morto p90 por carreira ≤ 8:01 (carreiras 2-4), igual ao fechado no design |

## 3. Simulador (resumo dos números reproduzidos)

- `controle` (1 carreira com arte desde o minuto 0, 48 jogadores): cinturão em 11:55 (Boxe 5/s e Jiu-jitsu 5/s), 12:55 (4/s), 14:55 e 14:25 (3/s). Só assistido: Jiu-jitsu 18:55, Boxe 33:57. Idêntico ao `fase5-design.md`.
- `assistido` (12 jogadores, 6 carreiras): os dois chegam ao cinturão na carreira 2; Jiu-jitsu 18:25, Boxe 30:57. Jiu-jitsu vence o G2 em 6 carreiras, Boxe em 0 (o assistido de Boxe não é a build para isso, é o esperado do critério).
- `carreiras` (32 por perfil, 8 carreiras): tabela completa no item 2 (critérios 9, 11, 13, 14, F4 8). Dois números do design não reproduzem exatamente (ver B6): "na mesma carreira" do Boxe 5/s deu 16%, o design diz 19%; p90 da chegada 55:18, o design diz 55:39. Nada sai da meta.
- Preços lidos do `data/`: mudança $1.000 x2, Boxe +50%, Jiu-jitsu +20% (+12% por minuto até +100%), Tonhão (260K/100K/1,10M), Kid (500K/1,00M/2,00M), pera e boneco 2.500 de Treino, nós ESTILO 1.200 de Legado.

## 4. Tentei quebrar

| Cenário | Resultado |
|---|---|
| MUDAR sem $, com $999,99, na luta, na tela de fim, duas vezes | recusa sempre; cobra uma vez só |
| Fechar com a escolha de arte pendente e reabrir | `qa_f5_extra` e `qa_f5_ui`: reabre na academia com a janela de arte aberta; clique, compra, luta e aposentar bloqueados |
| Escolher arte no meio da carreira / arte inexistente | recusa |
| LOJA com reserva (luva, Nelson, Metrônomo) | com $1.000 exatos nenhum dos três compra; com folga o Nelson compra e sobra exatamente $1.000; depois de mudar a reserva vira 0; sem cinturão não há reserva. Na tela: `f5_loja_reserva.png` ("GUARDE $1.00K PARA A MUDANÇA" no cabeçalho e "GUARDE $1.00K" na luva) |
| Boxe com Metrônomo/assistido | não aplica (item 2, critério 7) |
| Teto do Jiu-jitsu | exato 100%, finito até com 1e308 s |
| Tecla 4 sem arte, com aparelho trancado, comprado; teclas 2 e 3 trancadas | `qa_f5_ui`: nada acontece onde deve; com o boneco comprado a tecla 4 dá foco nele |
| Aparelho de outra arte | `absent`; compra e foco recusados; save com aparelho da outra arte o remove (teste do Programador) |
| NOVA CARREIRA após derrota e após aposentadoria | garagem, sem arte, janela de arte antes do cartão |
| Migração v5 com cinturão e dinheiro menor que $1.000 (user://test/) | vira $1.000 e MUDAR aceso |
| Save corrompido (local numérico, arte em lista, `art_seconds` 1e999, dinheiro negativo, escada 99, `arts_unlocked` string, arquivo ilegível) | não quebra: volta ao padrão, números finitos, avisos no console (esperado). Save ilegível vira jogo novo |
| Save com `location: gym`, escada 4, sem artes liberadas | abre na academia sem janela de arte e sem artes (só um save editado chega aqui; ver risco R2) |
| Compras extremas (3.000 compras com 1e300 de Treino) | valores finitos |
| Aba ESTILO antes e depois de liberar | `f5_arvore_sem_artes.png` (sem a aba) e `f5_arvore_estilo.png` / `_dica.png` (com a aba, nós centralizados) |
| Dica de aposentar | aos 300 s de PERIGOSO; some na nova carreira |
| Aba TREINO com 4 aparelhos + equipe | rolagem máxima 46 px; no fim aparece o cartão "GUARDA FECHADA" (`qa5/d_treino_rolado_baixo.png`). A roda do mouse sintética não rolou no meu script (posição do mouse, não é bug confirmado); rolar por código funciona |
| Tonhão e Kid com cada arte | prévia e luta honestas (item 2, critério 8) |
| Textos | acentos corretos; nenhum travessão renderizado (os `—` do `ui_texts.json` viram ":" ou "-" no código); "O BONECO" (masculino) e "A PERA" (feminino) corretos nas dicas e nas plaquinhas; nada cortado, exceto B2 e B3 |

## 5. Bugs

| ID | Gravidade | Dono | Descrição | Como reproduzir |
|---|---|---|---|---|
| B1 | **Média** (reprova o critério 19) | diretor-de-arte (criar o sprite) ou designer-ui-ux (não pedir o estado `disabled`) | `Resource file not found: res://` no console toda vez que a janela de arte abre pela primeira vez na sessão. `UiTema.botao_estilizado` (`ui/ui_tema.gd:432`) carrega `<prefixo>_disabled`; o manifest só tem `ui_button_art_normal`, `_hover` e `_pressed` (`assets/sprites/manifest.json:1255-1257`, falta `ui_button_art_disabled`). Chamado de `ui/janela_arte.gd:114`. Sem efeito visível (o botão nunca fica apagado), mas o `run_tests.ps1` não pega porque nenhum teste abre a janela | Rodar o `ui_audit` (aparece no console) ou `qa_f5_ui.gd`, ou jogar até o MUDAR |
| B2 | Baixa | designer-ui-ux | O acento de "ÚLTIMA: BOXE" / "ÚLTIMA: JIU-JITSU" fica cortado pelo topo do selo; lê-se "ULTIMA" (`f5_arte_ultima.png`, `f5_nova_carreira.png`; recorte ampliado confirma) | Começar a carreira 3 com as artes liberadas |
| B3 | Baixa | designer-ui-ux (ordem de desenho/posição) ou diretor-de-arte | Na garagem, a plaquinha "BONECO / DEPOIS DA ESTEIRA" é parcialmente coberta pelo parceiro de treino quando ele está à esquerda: o "D" de DEPOIS some (`f5_garagem_boneco_depois.png`). Intermitente, depende da posição do parceiro | Carreira com Jiu-jitsu, esteira ainda não comprada |
| B4 | Baixa | programador (condição) + roteirista (texto) | A dica extra `tip_move_belt` ("GUARDE O DINHEIRO. A BOA ESQUINA ESPERA" / "NA PRÓXIMA, MUDE PARA A ACADEMIA") também aparece para quem já mudou e aposentou antes de lutar com o Tonhão (`GameState._dica_extra`, `game_state.gd:1921` só olha vitórias). A dica "mude para a academia" é errada para quem já mudou. Nas 30 sementes testadas saiu sempre a mesma variante | Mudar para a academia, aposentar sem lutar; ver a tela de fim (`qa5/e_fim_academia.png`) |
| B5 | Baixa (ferramenta) | designer-de-jogo | `fase4b_sim.py` e `fase4_sim.py` quebram com os dados da Fase 5: `KeyError: 'speed_bag'` (curvas, inicio, carreiras da 4b) e `KeyError: 'art_rule_bonus'` / `TypeError` (curvas e carreiras da 4). Só `precos`, `metronomo` e `revanche` funcionam. A regressão hoje depende do `identidade` do `fase5_sim.py` (64/64, bom) | `python fase4b_sim.py` e `python fase4_sim.py curvas` |
| B6 | Baixa (documentação) | designer-de-jogo | (a) A seção `controle` imprime "diferença 0.0% (Jiu-jitsu na frente)" em 5/s e 4/s, mas é empate; o "Boxe na frente a 5/s" do critério 10 só aparece na seção `carreiras` (8:25 x 8:55). (b) Dois números do `fase5-design.md` não reproduzem exatamente (16% x 19% e 55:18 x 55:39). Nenhum cruza uma meta | `fase5_sim.py controle` e `carreiras` |
| B7 | Informativo | designer-ui-ux | A rolagem da aba TREINO só responde à roda do mouse (e às setas da lista); sem barra nem teclado. Quem joga em trackpad pode não achar a MELHORIA/técnica do 4º aparelho. O Produtor já decidiu que a aba rola, então é só registro | Aba TREINO com os 4 aparelhos |
| B8 | Informativo | programador | O verificador imprime um WARNING "Escada passou do 1º adversário de 'gym' na garagem" em `_novo_jogo` (`tools/ui/ui_audit.gd:853`): é o save de teste do estado anterior sendo relido, não é bug do jogo | Rodar o `ui_audit` |

## 6. Riscos

- **R1. B1 passa batido.** Só um teste que abra a janela de arte pegaria; o `run_tests.ps1` não pega. Sugestão: um teste de UI que abre `JanelaArte` e falha em ERROR do console.
- **R2. Save editado "na academia sem artes".** Quem cai nesse estado (só por edição manual) joga a carreira inteira sem arte e sem janela; as artes só liberam na próxima MUDANÇA. Não acontece por jogo normal.
- **R3. O tempo e a produção passam com a janela de arte aberta** (o `tick` não pausa; só ações são bloqueadas). Sem ganho indevido: o relógio do Jiu-jitsu só começa na escolha.
- **R4. Margem curta no 23b a 4/s** (24,2% contra o limite de 25%), igual à 4b.
- **R5. Boxe a 3/s leva 4 carreiras para o Kid.** Aceito pelo Diretor (decisão 3); fica para a avaliação do dono jogando.
- **R6. Ferramentas.** Sem B5 corrigido, a próxima fase não tem regressão 4b automática.

## 7. Arquivos de QA criados

`E:\Fightclicker\tests\qa_f5_extra.gd`, `qa_f5_extra2.gd`, `qa_f5_ui.gd`, `qa_f5_play.gd` (não são `test_*`, o `run_tests.ps1` não os roda; usam só `user://test/`). Capturas e saídas em `C:\Users\deivi\AppData\Local\Temp\claude\4ea5d9e6a0b1fa65\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\` (`qa5\`, `sim_*.txt`, `play5.txt`).

## 8. Veredito

**Ainda não.** Tudo fecha (17 de 19 critérios sem ressalva, 18 com 0 problemas, o balanço dentro das metas), exceto o 19 por causa do ERROR de B1, que é uma correção de um sprite (ou de uma linha). Corrigido B1, a fase está pronta para o Diretor revisar. B2 a B4 são pequenos e podem ir junto; B5 e B6 são dívida de ferramenta/documentação.
