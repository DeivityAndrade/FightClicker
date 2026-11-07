# Fase 4 — QA

Dono: QA. Data: 2026-11-06. Código não foi alterado (só criados `tests/qa_f4_play.gd`, `qa_f4_extra.gd`, `qa_f4_visual.gd`, `qa_crop.gd`, `qa_sheet.gd`).
Save real do dono: backup feito antes e hash idêntico depois (`save.json` e `.bak`). Nenhum processo Godot ficou aberto.
Capturas: `C:\Users\deivi\AppData\Local\Temp\claude\4ea5d9e6a0b1fa65\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\qa4\` (`ui\` = verificador; `p1_*` = jogada do zero; `m_*`, `c_*`, `f_*`, `g_*`, `s_*`, `z_*` = verificações visuais e de personagens).

## Resultado geral
- `tools\run_tests.ps1`: **TODOS OS TESTES PASSARAM** (test_fase4 253/253, test_fight_game 287/287, test_migration 57/57, guarda do save real 4/4, cena principal sem erro).
- Verificador de alinhamento (`--estados todos`, 1280x720): **40 estados, 0 problemas**. Olhei as capturas novas (árvore, fim, prévia, cartão, loja). Um desalinhamento visível que o verificador não pegou (bug B1).
- Simulador `fase4_sim.py` (SIM_N=32, 8 carreiras, 120 na revanche): reproduz as tabelas do design.
- Não encontrei bug que bloqueie a fase. 2 bugs baixos e 3 observações.

## Critérios de aceite

**Árvore**
1. OK. Tela de fim tem botão ÁRVORE (1 clique); janela mostra "LEGADO: N" e 10 nós com nome, efeito, preço/estado (`ui\arvore_mista.png`, `p1_arvore_c1.png`).
2. OK. 10 nós (5 Corpo, 5 Carreira) com Memória muscular e Olho clínico (prévia com %); nenhum de Linhagem, arte ou local (test_fase4 + captura).
3. OK. test_fase4 (desconto exato, recusa sem saldo/sem anterior). Extra: `qa_f4_extra` com Legado 5 tentando nó de 500 recusou e Legado ficou ≥ 0. Na jogada: compra de `body_jab` com Legado 10 deixou 0.
4. OK. `Fluxo.abrir_arvore()` exige `arvore_aberta()` (só com fim pendente); só a tela de fim tem o botão; `comprar_no` fora da tela de fim recusa (testado).
5. OK. Jogada: derrota -> NOVA CARREIRA = 1 clique; com árvore = ÁRVORE + NOVA CARREIRA = 2 cliques além das compras.

**Preços**
6. OK. Nós de 10 nos dois ramos; derrota no Dinho (40) compra os dois (simulador, seção Preços).
7. OK. Cinturão + aposentar = 750 de 3.175 = 24% (33% com torcida).
8. OK. Árvore fecha na carreira 6 (p10-p90: 5-7 a 5/s; 5-8 a 4/s), lento 6. Mediana dentro de 5-8.

**Bônus visíveis**
9. OK. Cartão "CARREIRA 2 — O QUE VOCÊ TROUXE:" (`p1_cartao_c2.png`). Mediu 1,76 s até sumir (<= 2 s). Fecha com clique **no próprio cartão**; um clique no alvo continua socando e não fecha (ver O1).
10. OK, com ressalva de método. Cada nó tem teste automático do valor prometido (test_fase4, 253 verificações) e vi na tela: clique "+2" com `body_jab` (`p1_cartao_c2.png`, "POR CLIQUE +2"), prêmio "$75 (+50%) + 15 FAMA (+50%)", porcentagem na prévia (`ui\previa_revanche_porcentagem.png`), Metrônomo no minuto 0 (jogada: carreira 3 abriu com `metronomo=1`). Não comprei os 10 nós um a um na tela; os de passivo, fama e Saber cair foram só pelo teste automático e pela árvore.
11. OK. test_fase4 (efeito só na carreira seguinte, não duplica ao recarregar).

**Metrônomo**
12. OK. Na LOJA: "PÊNDULO FIRME ... 1 SOCO A CADA 1.0 S"; nível 1 = $80 (<= 2 vitórias; Dudu paga $50 + Brutão $150). Comprei pelo botão real e o nível passou a 1 (`m_loja_nivel1.png`).
13. OK. 1000 auto-socos: 88 críticos (chance 0,1; faixa 70-130); luva de lona dobra por-clique (1.0 -> 2.0); treino vai para o atributo em foco.
14. OK. `_shake_t` = 0 durante os auto-socos e 0,054 no clique do jogador; auto-soco usa som −14 dB (vs clique), número em z abaixo do jogador, opacidade menor; lutador anima o jab com a luva atual (`sala.gd:401-418`).
15. OK. Medido na janela: nível 3 = 14 socos em 10 s (1,40/s). Máximo 1,429/s. Razões do simulador: 3,1x / 3,8x / 4,5x.
16. OK. 4 lutas + fim: 0 auto-socos. Prévia aberta por 3 s: 0 socos; depois de VOLTAR A TREINAR: 4 socos em 3 s.
17. OK. NOVA CARREIRA zera; com Memória muscular começa em 1 e a LOJA oferece o nível 2.

**Revanche e dica**
18. OK. Jogada: derrota no Brutão -> carreira 2 mostra "VOCÊ PERDEU PRA ELE" no HUD e na prévia (`p1_previa_opp_strong_c2.png`). Aposentadoria sem marca: teste automático.
19. OK. Vitória sobre o Brutão mostra "REVANCHE! / BRUTÃO DO POSTO NÃO ESPERAVA ESSA." uma vez (`p1_vitoria_c2_i2.png`).
20. OK. Derrota (não azar) mostrou "VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE" (`p1_fim_c1.png`, `ui\fim_derrota.png`); `ui\fim_azar.png` só com a dica de azar.
21. OK. "ESPERE FICAR VERDE" no HUD do Dudu na carreira 2 (`p1_cartao_c2.png`, algoz = Brutão) e na prévia (`ui\previa_revanche.png`); some quando a prévia está verde (teste automático + prévia do Brutão fácil sem a linha).

**Balanço**
22. OK. Simulador: 1ª derrota mediana 11:44 (5/s) e 13:44 (4/s).
23. OK. Cinturão: carreira 2 (mediana) para 5/s e 4/s. 23b: 5 de 32 (16%) fazem cinturão na 1ª, aos 23:22 (5/s) e 26:55 (4/s): <= 20% e >= 20 min.
24. OK. Tempo morto carreira 1: mediana 5:00/6:00, p90 11:01/12:32 (<= 13:00); carreiras 2-4: p90 <= 7:30.
25. OK. Revanche (com L1, como o jogo implementa): Dinho 95% (5/s) e 94% (4/s); Muralha 89% (5/s) e 79% (4/s). O 79% do Muralha a 4/s fica 1 ponto abaixo de 80%, mas o critério exige >= 60% para o Muralha. Ver R2: a tabela principal do simulador ainda mostra o Muralha sem L1 (22-32%).

**Protótipo**
26. OK nos itens 1-5, uma jogada. Do zero, sem F12, 4,5 cliques/s sintéticos (time_scale 3), seed 1: 4381 cliques, **0 sem número flutuante**; Vizinho aos 0:59 e Nelson aos 3:43; derrota no Brutão aos 8:23 (tela aponta Resistência/esteira e manda esperar o verde); comprou `body_jab`; carreira 2 mostrou o cartão e o bônus (+2) e venceu o algoz aos 5:56. Itens 1-5 em ~14:30 de jogo (meta ~20, limite 25). Simulador: 20:58 (5/s) e 23:28 (4/s). Item 6: nesta jogada a carreira 2 acabou em derrota no Dinho com Legado 40: comprou `career_purse` e `body_muscle_memory`, e a próxima carreira abriu com cartão e Metrônomo 1 (meta visível: Olho clínico por 25). O "quer jogar mais uma" é do dono (critério 27).
27. Fica para o dono.

**Save, dados e saúde**
28. OK. Save v3 **real do dono** (Legado 18, carreira 6, 6,9 s) abriu na v4 com Legado 180, carreira e tempo intactos, sem nós/algoz, regravou como versão 4 e reabrir não multiplicou de novo. v3 com fim pendente: Legado 140, ganho 40/total 140, árvore abre. Cadeia v0->v4 em test_migration.
29. OK (parcial pela jogada). Saves com nós inválidos/repetidos/sem anterior, Legado negativo ou 1e300, nível de Metrônomo 99 ou -3, arquivo corrompido e arquivo vazio: sem crash, Legado nunca negativo, nível recortado (`qa_f4_extra`). Não reabri o jogo com a árvore aberta na janela; cobertura por teste automático.
30. OK. test_fase4 muda custo, valor e intervalo em JSON de teste.
31. OK. `run_tests.ps1` passa inteiro.
32. Parcial. Jogada de ~17,5 min de jogo, 3 carreiras iniciadas, console limpo. Não rodei a sessão contínua de 40 min. Nada de arte marcial, local clicável ou Linhagem nas capturas.
33. OK. Do clique em LUTAR! até a arena: vitória 21-37 ms, derrota 22-25 ms (3 rodadas cada; o 37 ms é a 1ª luta da sessão). Sem diferença perceptível.

## Personagens refeitos (checklist da seção 6 do padrao-personagem)
- Folhas de contato das 4 lutas, jab e heavy de todos os lutadores (`f_luta1..3.png`, `s_jab.png`, `s_heavy.png`, ampliações `z_punch_*.png`), garagem cheia (`g_garagem_cheia.png`, `z_garagem_cheia.png`).
- Sem buraco, emenda aberta ou membro mudando de tamanho que eu consiga ver nos quadros; pés ancorados no chão (sombra no lugar) nas folhas de luta. Luva do jogador igual à equipada: velha vermelha no cursor/garagem/jab, lona bege, couro marrom (garagem, luta e folhas de sprite). O disco claro no soco é o efeito `fx_fight_hit` no ponto de contato, não luva errada.
- Limites da checagem: olhei quadros ampliados 2x a 7x, não pixel a pixel de todos os 100+ quadros. `f_luta0.png` (Dudu) pegou a janela de vitória e não a luta (luta curta demais); o Dudu foi coberto só por `s_jab.png`/`s_heavy.png`. Ver O3.
- O sprite `fighter_*_glove_l3` existe mas a loja só vende l1 e l2: sem efeito no jogo.

## Bugs
- **B1 (baixa, UI, `ui\painel_loja.gd`, linha do Metrônomo)**: na LOJA o texto "1 SOCO A CADA 1.0 S" começa na borda esquerda do cartão, sem o recuo das outras linhas ("X2 POR CLIQUE", "+25/S"). Passos: abrir a LOJA com Metrônomo à venda (`m_loja_nivel1.png`, `z_m_loja.png`). O verificador não acusou. Dono: ui.
- **B2 (baixa, texto/ui)**: a revisão da Fase 3 pedia deixar claro "LEGADO EM JOGO"; na vitória está certo ("+60 LEGADO EM JOGO"), mas o HUD superior ainda abrevia "LEGADO EM JOGO ..." num campo estreito que corta o número em janela pequena. Visto em `ui\garagem_*.png`; não confirmei corte, por isso só observação de checagem. Dono: ui.
- Nenhum bug de lógica, save ou balanço.

## Observações (não são bugs)
- **O1**: o cartão "o que você trouxe" só fecha com clique nele mesmo; quem clica no alvo continua treinando e o cartão some sozinho em 1,76 s. Atende o critério 9 ("sozinho em até 2 s ou com 1 clique"), mas a documentação diz que o alvo não aceita clique durante o cartão e na prática aceita (treino mudou). O Metrônomo pausa corretamente.
- **O2**: números de dano na luta legíveis, mas pequenos (fonte 7 px) e o número do dano some depois de ~1 s sobre a cabeça; no zoom 1280x720 dá para ler.
- **O3**: nas folhas de heavy, a luva da frente do Dinho (`opp_fast_heavy`, quadros 3-4) parece levemente descolada da manga; sugiro o artista de personagens conferir ampliado. Não consegui confirmar um buraco real.

## Riscos
- **R1**: a mediana do protótipo é 20:58 (5/s) e 23:28 (4/s), mas só 22 de 27 jogadores do simulador fecham os itens 1-5 (~1/6 cai no caminho do Muralha, 42-48 min, ou faz cinturão na 1ª e adia). Dizer isso ao dono.
- **R2**: a tabela principal do `fase4_sim.py` ("típico ... dica") ainda calcula a revanche do Muralha **sem** a alavanca L1 (1 de 5 a 5/s). Só as linhas "alavanca L1" refletem o jogo aprovado. Quem ler só a tabela principal vai achar que o critério 25 falha. Dono: design.
- **R3**: o robô de QA lutou no amarelo contra o Brutão e perdeu: a derrota logo na 2ª luta é possível e coerente com o design, que só mede derrotas no Dudu (~9%), no Dinho e no Muralha; o texto de fim e a árvore (Legado 10) funcionam nesse caso.
- **R4**: critério 32 (40 min contínuos) e fechar/reabrir com a árvore aberta em janela não foram exercitados ao vivo.
- **R5**: árvore completa em 6 carreiras e depois "fim do protótipo" (R3 do escopo): o dono precisa ser avisado.

## Veredito
Pronto para o Diretor revisar. Todos os critérios verificáveis passam (testes, verificador 0 problemas, simulador e jogada do zero); restam 2 ajustes baixos de UI e 3 observações. A fase não tem bloqueio.
