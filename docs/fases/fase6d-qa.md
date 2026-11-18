# Fase 6d + 6d2: QA completo

QA, 2026-11-18. Branch `fase-6d` (sem commit). Só reportado, nada corrigido em `scripts/`, `scenes/`, `ui/`, `data/`.
Todas as execuções usaram `APPDATA` apontando para uma pasta temporária nova e `--position 1950,40` nas janelas. O `save.json` real
(modificado em 15/11) ficou intocado; a única marca na pasta real são arquivos de log de 4 comandos `--headless` de recorte de imagem
que rodei pelo bash (sem save, sem projeto aberto).

## Veredito

**NÃO está pronta para o Diretor ainda: 1 bug MÉDIO (B1) e 4 BAIXOS.** Tudo o que era bloqueante na parte 1 (C1, R1, C2, R2) está
corrigido e confirmado. Todos os critérios de aceite passam, `run_tests.ps1` verde, `ui_audit` com 0 problemas, `validar_cenas` 0 erros,
balanço idêntico. O B1 é um defeito visível de alinhamento (chip do assistido por cima do vizinho 2 da sala larga), que pela regra
do dono reprova a fase até ser corrigido. Os outros quatro podem ir junto ou depois, a critério do Diretor.

## Resumo por item

| # | Item | Resultado |
|---|---|---|
| 1 | Cenas com o lutador criado (6+ visuais), C1/R1 | **APROVADO** |
| 2 | Caminho do John na saída (C2/R2) | **APROVADO** |
| 3 | Balão perto do cursor (loja, mapa/árvore, hall) | **APROVADO** (com B2, BAIXA, fora do escopo estrito) |
| 4 | Números por atributo | **APROVADO** |
| 5 | Tela C (HUD, miniaturas, faixa, painel, FIXAR, L/E/H, clique, cenas) | **APROVADO** com observações O1 e O2; B3 e B4 (BAIXAS) |
| 6 | Equipamento não comprado invisível | **APROVADO** |
| 7 | Textos inúteis retirados, nada importante sumiu | **APROVADO** |
| 8 | Sala larga (garagem e academia) | **REPROVADO por B1** (chip do assistido sobre o vizinho 2). Fora isso, aprovado |
| 9 | `run_tests.ps1`, `ui_audit`, `validar_cenas` | **APROVADO** |
| 10 | Foto de balanço igual à da main | **APROVADO** (diferença só em texto e ponto de mentor) |

## Item 1: cenas com o lutador criado (C1 / R1)

Comando (4 jogos completos, um por par de visuais): `godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_cenas.gd -- p=A,B`
com `p=2,3`, `p=4,5`, `p=6,7`, `p=7,1` (APPDATA próprio por execução). Resultado dos quatro: `FALHAS 0`. O script foi atualizado por mim
(`SALA` agora cobre a sala larga; as imagens saem como `docs/arte/mockups/fase6d_qa2_*.png`).

Visuais (índices de `LOOKS` no script): 1 preto/buzz/sem cima/sem faixa/calção verde/sem meião; 2 pele 5, coque loiro, regata branca,
faixa vermelha, calção azul, meião; 3 pele 1, volume platinado, camiseta preta, faixa preta, calção preto, meião; 4 pele 5, short preto,
camiseta branca, faixa branca, calção branco, meião; 5 pele 3, coque cobre, sem cima, faixa amarela, calção roxo, meião; 6 pele 2,
volume castanho-escuro, regata amarela, sem faixa, calção amarelo, sem meião; 7 pele 4, buzz castanho, camiseta verde, faixa verde,
calção verde, meião. Cobre os 4 cortes, os 3 estados de parte de cima, com e sem faixa, com e sem meião, peles 1 a 5, extremos
(preto sobre preto, branco sobre branco, platinado).

| Cena | Visuais | Resultado | Evidência |
|---|---|---|---|
| Primeira sucessão, parte 2 (porta, `walk_bare_left`, `duck_under`, `take_gloves`, idle) | 2, 4, 6, 7 (olhei 2, 4, 6, 7 em quadros) | OK, sem "pop" para o visual padrão | `fase6d_qa2_p23_s2_00.png`, `p45_s2_00.png`, `p67_s2_00.png`, `p71_s2_00.png` |
| Chegada curta (2ª sucessão) | 3, 5, 7, 1 | OK | `fase6d_qa2_p23_s2b_chegada_00.png`, `p67_s2b_chegada_00.png` |
| Mentores sentado (John) e em pé (último que passou o posto) | todos | OK, símbolo e cores certos | `fase6d_qa2_p67_gar_b_mentores.png`, `p71_gym_depois.png` |
| Chegada à academia | 3 (e John, Aurelio) | OK | `fase6d_qa2_p23_gym_chegada_*.png` |
| Saída do John (garagem e academia) | 3 | OK, ver item 2 | `fase6d_qa2_p23_saida_gar_*.png`, `_saida_gym_*.png` |
| Mural (busto, 7 visuais + John, com selo) | 7 + John | OK | `fase6d_qa2_mural_0.png` |

**R1 (confirmado corrigido).** A passada por baixo da porta (`duck_under`, quadros 2 a 4 da folha `_s2_00`) sai agora com o visual
escolhido (calção azul/amarelo/branco/verde, regata branca/amarela, meião). Sem troca de visual no primeiro passo. Em todos os pares.
**Momento da esteira na academia (`treadmill_put_right`):** capturei quadro a quadro a cena da academia com a esteira da casa comprada
(o ajudante só existe se `owned: treadmill`; sem a esteira não aparece, como previsto). O ajudante vira a esteira (fora do 2x), anda até
(470,300), agacha ao largá-la (`treadmill_put_right`) e fica em pé ao lado. A esteira pousa em (466,324), sem sobrepor ninguém.
Imagens: `fase6d2_qa_gymhelper_10.png`, `_11.png` (script `tests/qa_f6d2_gymhelper.gd`).

## Item 2: caminho do John na saída (C2 / R2)

Garagem e academia (`saida_gar_*`, `saida_gym_*`): o John sai do caixote (132,254), sobe pela parede, passa ATRÁS do saco (cobertura
por y correta, só cabeça e ombros aparecem sobre o saco), contorna pela direita e vai à porta. Não atravessa aparelho nem pessoa.
Em relação ao lutador: no início da caminhada a distância entre os pés do John e a cabeça (boné/coque) do lutador é de uns 12 px
(antes eram 0 a 2). **R2 resolvido.**

## Item 3: balão perto do cursor

- Latência: o balão liga `visible` no mesmo quadro do `mouse_entered` (`ui/dica.gd:_mostrar`), sem temporizador. Medido por quadros no
  teste ao vivo: aparece em 1 quadro (16 ms) nos itens que têm balão. Bem abaixo de 0,15 s.
- Posição e cobertura: `tests/qa_f6d2_dica.gd` (hover em todos os botões visíveis da loja e da equipe, painel fixado e solto, com
  saldo e sem saldo): 0 fora da tela, 0 cobrindo cartão apontado, distância máxima do cursor ao balão: 10 px. Fuzz de
  `Dica.posicionar` do relatório anterior continua valendo (20.000 casos, 0 falhas).
- Mapa/árvore e hall: `f6d_balao_mapa.png`, `f6d_balao_hall.png` (capturas do verificador): ao lado do nó, dentro da tela, sem cobrir.
- Some ao tirar o mouse: o teste move o mouse para fora após cada hover, 0 balões presos.
- Ressalva: B2 (balão sem item-alvo nos botões da faixa e na aba do painel).

## Item 4: números por atributo

`f6d_numeros_bjj.png`: `+120 RES` grande, `+50 FOR` e `+30 AGI` menores, na cor de cada atributo, empilhados e legíveis (divisão 60/25/15).
Crítico (`f6d_numeros_bjj_critico.png`): `+360 RES!` vermelho grande, os outros dois pequenos. Aparelho de um atributo
(`f6d_numeros_um_atributo.png`): igual ao de antes (`+1 FORÇA`). Máximo de 3 por clique (`NUMEROS_MAX_POR_CLIQUE`, `ui/sala.gd:12`).
Nada a reportar.

## Item 5: tela C

Script `tests/qa_f6d2_tela.gd` (jogo de verdade, teclas e cliques sintéticos) + capturas `docs/arte/mockups/fase6d2_qa_tela_*.png`. `FALHAS 0`.

| Verificação | Resultado |
|---|---|
| Painel começa fechado, só a aba de borda com selo (⚡N / $N) | OK (`tela_fechada.png`) |
| `L` abre na aba LOJA; `E` abre/troca para EQUIPE; repetir a tecla na mesma aba fecha | OK |
| `H` mostra só a sala (HUD só com Treino, LUTAR; tudo o mais some); `H` de novo volta tudo | OK (`tela_H_*.png`) |
| Clique na sala fecha o painel solto | OK |
| FIXAR ABERTO fixa (texto vira FIXADO), clique na sala não fecha; segundo clique solta e mantém aberto | OK (`tela_fixado.png`) |
| Painel fecha sozinho durante a cena (primeira sucessão e chegada à academia), mesmo fixado, e volta fixado depois | OK |
| `L` durante cena não faz o painel aparecer | OK |
| HUD, atributos em miniatura (ícone + barra + número), faixa de baixo (+N/CLIQUE, focos, LUTAR, PASSAR O POSTO com ícone) | OK, sem texto cortado (ui_audit 0 problemas) |
| Selo de compráveis na aba (número verde/dourado) | OK |

Observações (não são bugs, mas peço decisão):
- **O1.** Com `H` ligado (só a sala), `L` e `E` ainda mudam o estado do painel, mesmo invisível: abre `H`, aperta `L` e o painel fecha
  sem ninguém ver; ao desligar `H`, ele volta já fechado. Sugestão: ignorar `L`/`E` durante `H`.
- **O2.** `L` (ou `E`) com o painel FIXADO e na mesma aba fecha o painel e também solta o FIXAR (`PainelLoja.fechar()` zera `_fixo`). Se
  a intenção é "fixado = fica até o jogador soltar", `L` não deveria desafixar.

## Item 6: equipamento não comprado invisível

Garagem e academia sem comprar: nenhum pontilhado, fita, silhueta nem cadeado na sala (`f6d2_aparelho_invisivel.png`,
`f6d2_academia_pequena.png`). Comprou: só a caixa, no ponto novo (`f6d2_aparelho_caixa.png`). Abriu: o aparelho (esteira em
(466,324), boneco em (192,318)). Confirmado também na cena da academia (esteira só pousa se foi comprada). O "dá para comprar" mora só no
botão trancado da faixa e no cartão do painel (`f6d2_foco_trancado.png`).

## Item 7: textos inúteis

Conferido com `git diff data/ui_texts.json` contra `fase6d2-textos.md` e nas capturas. Saíram/encurtaram: legendas POR CLIQUE, FOCO DE
TREINO, ATRIBUTOS, título e subtítulo da LOJA, SALVO com hora (agora "SALVO" que pisca), chip da arte (BOXE +50%), SE VENCER, frases de caixa,
`hint_prize`, `hint_keys`. **Nada importante sumiu:** custo (`CONTRATAR $50`, `COMPRAR 500`), falta de dinheiro (`FALTA $1.41K` nos cartões da
loja, `FALTA $700` na mudança, `ESTEIRA | FALTA 499` no foco trancado), perigo da luta (`PERIGOSO`, `PERDER ENCERRA A CAMPANHA`), dias
para a luta. Único ponto que desvia do documento: o sufixo `/CLIQUE` ficou ao lado do `+N` (o texto do Roteirista pedia só "+1"); é discreto, não reportei como bug.

## Item 8: sala larga

Capturas: `f6d2_garagem_cheia.png`, `f6d2_garagem_pequena.png`, `f6d2_academia_cheia.png`, `f6d2_academia_pequena.png` e as das cenas.
Três fileiras (fundo, alvo, frente) bem distribuídas, alvo central (lutador em x 303), caixas à frente do lutador, esteira na frente à direita,
mentores à esquerda (John no caixote, segundo mentor junto da janela), caminho da porta livre. Vizinho 3 e Prof. Nelson ficam atrás do painel
fixado, como o Diretor de Arte já avisou (aceito).
**Reprova por B1.**

## Item 9: automáticos

- `tools/run_tests.ps1` (APPDATA temporário `fcqa6d_ad`): `TODOS OS TESTES PASSARAM`, `EXIT=0`, guarda do save real passou.
- Cena principal `--headless --quit-after 300`: `exit=0`, sem `ERROR`.
- `tools/ui/ui_audit.gd -- --estados todos` (1280x720, `--position 1950,40`): **`ESTADOS 384 | PROBLEMAS 0`**, 0 `SCRIPT ERROR`. Capturas
  em `C:\Users\deivi\AppData\Local\Temp\fcqa6d_audit\` (inclui os 14 estados `f6d2_*` e os 12 `f6d_*`).
- `tools/cenas/validar_cenas.gd` headless: `chegada_discipulo`, `primeira_academia`, `primeira_sucessao`, `saida_primeiro_mentor`,
  todos com `0 erro(s), 0 aviso(s), 0 pendência(s)`.

## Item 10: foto de balanço

`godot --headless --path . --script res://tools/refatoracao/foto.gd -- --out=<arquivo>` nesta pasta e num worktree de `origin/main`
(daa89fe, a base da branch; o `main` local está atrasado em 0f2b62a e não serve). Tamanhos: main 247.672 bytes, 6d 247.650. `diff` linha a
linha: 11 linhas diferem, todas por 2 motivos: (a) `stake_win` "SE VENCER: $50 + 10 FAMA" virou "VENCER: ..." (texto encurtado da prévia); (b) o
ponto do mentor mudou na sala larga (`mentor_spot` [254,252] → [132,254], `mentor_2_spot` [150,262] → [62,256]). Depois de normalizar essas duas
coisas, `diff` vazio. **Nenhuma diferença numérica.** Worktree removido (`git worktree prune`).

## Bugs

### B1 (MÉDIA, UI/UX): o chip do assistido fica por cima do vizinho 2 na sala larga
- **Onde:** garagem e academia, com o vizinho 2 contratado (equipe cheia ou quase).
- **Passos:** `godot --path . --resolution 1280x720 --position 1950,40 --script res://tools/ui/ui_audit.gd -- --estados f6d2_garagem_cheia` (ou jogar até contratar o 2º vizinho) e olhar o canto inferior esquerdo da sala.
- **Esperado:** nada de interface sobre pessoa da sala.
- **Obtido:** o botão do chip do assistido (caixinha com ícone de SHIFT, em ~x 132..151, y 273..288) fica na frente do corpo e do braço do vizinho 2, que agora está em (126,322). Quando o chip mostra "DICA: SEGURE SHIFT" o texto se estende pela sala (x 132..245). O chip foi desenhado para a sala antiga.
- **Imagem:** `C:\Users\deivi\AppData\Local\Temp\fcqa6d_audit\f6d2_garagem_cheia.png` (recorte 4x: `C:\Users\deivi\AppData\Local\Temp\crop5.png`); também `docs/arte/mockups/fase6d2_qa_tela_fixado.png` e `fase6d_qa2_p23_saida_gym_02.png`.
- **Arquivo provável:** `ui/faixa_assistido.gd` (posição do chip) em relação a `neighbor_2.pos` do manifest (126,322).
- **Quem corrige:** UI/UX (mover o chip para um ponto livre da faixa de baixo ou da sala larga). O verificador não acusou porque a sala é `ignore`.

### B2 (BAIXA, UI/UX): o balão de descrição dos botões sem "alvo" pode cobrir o botão apontado
- **Onde:** aba de borda do painel (`ui/painel_loja.gd:295`), botões de foco, `?`, PASSAR O POSTO da faixa de baixo (`ui/barra_baixo.gd:131,170,187`), HUD, atributos, mapa. Todos chamam `Dica.pedir(texto)` sem o segundo parâmetro (o item apontado).
- **Passos:** `tests/qa_f6d2_dica.gd` (cursor fixado no centro do botão): aba de borda: balão `[436,136 57x25]` cobre 9 px da aba `[484,120 24x58]`; botão ESTEIRA: balão `[155,332 67x25]` cobre parte do botão `[182,335 86x20]` e do vizinho SACO; PASSAR O POSTO: balão `[547,326 91x16]`.
- **Esperado (critério 2):** nunca cobre o item apontado.
- **Obtido:** o balão evita só a ponta do cursor, não o botão. A loja, o mapa e o hall (que passam o alvo) estão certos.
- **Gravidade:** BAIXA, porque o escopo cita loja, mapa e hall, e o ponto do cursor nunca é coberto.
- **Quem corrige:** UI/UX: passar o `Control` apontado como segundo argumento nos 9 `mouse_entered` acima.

### B3 (BAIXA, UI/UX): a dica "CLIQUE NO SACO PARA TREINAR" passa por cima do 4º botão de foco
- **Passos:** academia com arte escolhida, sem treinar ainda (dica da primeira vez ativa). Veja `docs/arte/mockups/fase6d2_qa_tela_academia.png`, faixa de baixo: o texto amarelo (`ui/barra_baixo.gd:71`, x 364, 88 px) cai sobre o botão PERA/BONECO (x ~362..447), e o ícone trancado e a palavra aparecem "fantasma" atrás do texto.
- **Obtido:** texto sobre texto na faixa de baixo.
- **Gravidade:** BAIXA, é raro no jogo real (a dica some no primeiro treino da carreira e na academia o jogador já treinou).
- **Quem corrige:** UI/UX (limitar a dica à largura livre depois do último botão, ou escondê-la quando houver 4 focos).

### B4 (BAIXA, UI/UX / Roteirista): o cartão da mudança quebra "TREINO X2 / 2 LUTAS DA CASA" no lugar errado
- **Passos:** garagem, dinheiro menor que o preço da mudança, olhar o cartão ACADEMIA BOA ESQUINA do bloco da próxima luta (`f5_mudar_sem_dinheiro.png`, capturado pelo verificador).
- **Obtido:** linha 1 "TREINO X2 / 2", linha 2 "LUTAS DA CASA" (o "2" fica com o lado errado). A string `move_effect` não mudou nesta fase; a quebra pode ser anterior.
- **Quem corrige:** UI/UX (quebra por palavras do bloco) ou Roteirista (trocar "/" por quebra de linha fixa).

## Riscos

- O balão do hover foi testado com o cursor ancorado por `Dica.ancora_fixa` (o gancho de verificador), porque o mouse sintético do Godot não
  atualiza `get_local_mouse_position()` no teste. A lógica de posição é a mesma; a leitura do mouse real não foi exercitada por mim nesta rodada
  (o dono pode confirmar a sensação ao mouse).
- O Prof. Nelson, o vizinho 3 e 28 px da ponta da esteira ficam atrás do painel fixado (aceito pelo Diretor de Arte).
- `test_golpes.gd` teve falha intermitente reportada pelo programador na rodada anterior; nesta rodada a bateria passou limpa.
- Arte de pessoas: a luz pintada para os pontos antigos deixa vizinhos da frente esquerda e o Nelson um pouco claros/escuros demais (já
  anotado em `fase6d2-layout.md` §8).

## Arquivos de QA desta rodada (todos em `tests/`)

- `qa_f6d_cenas.gd` (atualizado: sala larga, prefixo `fase6d_qa2_`), `qa_f6d_mural.gd` (prefixo `fase6d_qa2_`).
- Novos: `qa_f6d2_tela.gd` (painel, atalhos, cenas), `qa_f6d2_dica.gd` (balão ao vivo), `qa_f6d2_gymhelper.gd` (esteira na academia).
- Capturas: `docs/arte/mockups/fase6d_qa2_*.png`, `fase6d2_qa_*.png`; verificador: `C:\Users\deivi\AppData\Local\Temp\fcqa6d_audit\`.

## Como reproduzir

```
$env:APPDATA = "<pasta temporaria nova>"
godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_cenas.gd -- p=2,3
godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d2_tela.gd
godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d2_dica.gd
godot --path E:\Fightclicker --resolution 1280x720 --position 1950,40 --script res://tools/ui/ui_audit.gd -- --estados todos
```
