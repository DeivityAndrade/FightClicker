# Fase 6d3: QA dos ajustes depois da 6d

QA, 2026-11-18. Branch `fase-6d` (sem commit, HEAD `109ef42`). Só reportado: nada foi corrigido em `scripts/`, `scenes/`, `ui/`, `data/`.
Todas as execuções usaram `APPDATA` apontando para uma pasta temporária (inclusive `run_tests.ps1`) e `--position 1950,40` nas janelas.
O `save.json` real tem o mesmo SHA-256 antes e depois (`CC99AF83...2DAB`); fiz cópia dele antes de começar. Nenhum processo alheio foi encerrado.
O worktree temporário de `origin/main` (`fbfa0ca`) foi criado e já removido.

## Veredito

**NÃO está pronta para o Diretor ainda: 2 bugs MÉDIOS (B1, B2) e 4 BAIXOS (B3 a B6).** Todos os automáticos passam (`run_tests`, auditoria
inteira 2 vezes com 0 problemas, `validar_cenas`, foto idêntica). Os médios são de arte/layout: o John (e o discípulo sentado) fica em
cima do carro novo da garagem, que o dono pediu para conferir, e o ícone ao lado de "GARAGEM SALVA" ainda tem o símbolo antigo.

## Resumo por item

| # | Item | Resultado |
|---|---|---|
| 1 | Números com o nome inteiro | **APROVADO** |
| 2 | Painel da direita (sem FIXAR) | **APROVADO** (B3 BAIXA: texto órfão no JSON) |
| 3 | Botão SEGURAR na faixa de baixo | **APROVADO** (B4 BAIXA: 1 px de altura a menos que o "?") |
| 4 | "?" 16x16, ícone do mural, prévia 2x | **APROVADO** |
| 5 | Lutador piscando | **APROVADO** |
| 6 | Arte (garagem, academia, fundo da luta) | **REPROVADO por B1** (pessoa em cima do carro). O resto passa |
| 7 | Símbolo novo (R de raiz) em todo lugar | **REPROVADO por B2** (ícone GARAGEM SALVA ainda é a lâmpada) |
| 8 | Automáticos | **APROVADO** |

## Item 1: números com o nome inteiro

- Teste novo `tests/qa_f6d3_numeros.gd` (headless): 5 focos (BJJ/boneco, pera, saco, esteira, corda) x 8 ganhos (0,001 até 1e30) x crítico
  sim/não x 6 pontos de clique (cantos e bordas da sala, incluindo x=2 e x=638). 804 números vistos, `FALHAS 0`: nenhum termina em
  FOR/AGI/RES (regex ` (FOR|AGI|RES)!?$`), nenhum com `retangulo()` fora de x 0..640 (maior largura 224 px), nunca mais de 3 novos por clique.
- Auditoria `f6d_numeros_bjj`, `_bjj_critico`, `_pera`, `_um_atributo` verdes (checam nome completo, caber na sala, 3 por clique, maior ganho
  maior). Captura `f6d_numeros_bjj_critico.png`: "+360 RESISTÊNCIA!" em 2x, "+150 FORÇA" e "+90 AGILIDADE" em 1x, empilhados e dentro da sala.
- `grep left(3)`: só sobra `ui/painel_loja.gd:511`, sigla do cartão da loja (não é número flutuante, comentado). Observação: `focus_split`
  (`data/ui_texts.json:265`, `scripts/estado/textos.gd:183`) ainda diz "FOR / AGI / RES", mas é a linha do cartão de foco, fora do pedido.

## Item 2: painel da direita

`tests/qa_f6d2_tela.gd` (atualizado pelo time, janela real, cliques e teclas de verdade): 17 PASS, `FALHAS 0`.
- L abre na aba loja; E troca para equipe; E de novo fecha; L de novo fecha; H liga/desliga "só a sala"; L sai do "só a sala" e abre.
- Clique na sala (duas vezes) não fecha; clique na aba/seta (centro 496,149) fecha; com a loja aberta, E só troca a aba; E na mesma aba fecha.
- Cena da academia: painel fecha durante a cena e volta aberto; L durante a cena não mostra o painel.
- Meu teste `tests/qa_f6d3_botao.gd`: com o painel aberto (L), clicar no saco (336,222) treina (força 0 para 1) e o painel continua aberto.
- Referências quebradas: `grep` por `fixar|FIXAR|esta_fixado|fechar_se_solto|_fixo|pin_panel` em `.gd`/`.json`: **zero uso em código**; testes e
  verificador já usam `definir_estado(aberto)`. Nenhum texto órfão na tela (auditoria 0 problemas). Sobram só as 2 chaves mortas do JSON (B3).

## Item 3: botão SEGURAR

`tests/qa_f6d3_botao.gd` (janela real): `FALHAS 0`.
- Retângulo do botão = (464,337) 20x15, pai `FaixaAssistido` (z 1250, acima da faixa de 1200). Clique no centro e nos 4 cantos liga o assistido
  (`assistido_segurando()` true, estado `active`); soltar o mouse desliga. Painel continua aberto depois.
- "?" = (488,337) 16x16; LUTAR = (507,3,102,24) na faixa: nenhuma interseção. Folga de 4 px entre o botão e o "?".
- Capturas `scratchpad/botao_barra_hover.png`, `botao_barra_varios.png`: botão com moldura igual à dos outros, "?" ao lado, LUTAR! inteiro.
- Dica da faixa: `_posicionar_dica` limita a 460 px; com 3 focos (92 + 3x90 = 362) ela cabe (a barra "varios" mostra "L LOJA E EQUIPE H SÓ A SALA" no
  balão do "?", dentro da tela). Com 4 focos o código deixa a dica sumir (sem 70 px livres), como já era o desenho.
- `X_SALVO = 456` (rótulo "salvo") ocupa 456..486 x 340..363, ou seja, sobrepõe o botão novo (464..484). O texto fica vazio fora do instante de
  salvar, então não vi colisão visível; não consegui provocar o "SALVO" aparecendo. Anotado em B4.

## Item 4: "?" 16x16, ícone do mural, prévia 2x

- "?" 16x16 confirmado (item 3), com moldura, centrado a 1 px do botão ao lado. Texto "?" claro e centralizado (captura).
- Fim de campanha (`f6c2_fim_honra_1.png`): ÁRVORE, MURAL e NOVO DISCÍPULO alinhados; o ícone do MURAL (`icon_honor_16`) tem o mesmo
  tamanho do da ÁRVORE, nada cortado.
- Criação do discípulo (`f6b2_criar.png`): prévia em 2x dentro do cartão 90x150, com sombra 2x, SORTEAR embaixo, nada cortado; janela
  alta continua no meio e dentro da tela (estados `f6b1_*` e `f6b2_*` com 0 problemas, inclusive nome de 14 letras).

## Item 5: lutador piscando

- `tests/test_luta_disc_piscando.gd` passa dentro do `run_tests` (troca de pose x 17 poses + luta ganha + luta perdida, cada quadro).
- Meu teste independente `tests/qa_f6d3_piscando.gd` (janela real, 1 leitura por quadro desenhado, discípulo pele 5 / coque loiro /
  regata amarela / faixa vermelha / calção roxo): luta ganha 756 quadros, 7 poses, **0 quadros com a folha padrão**; luta perdida 524 quadros,
  4 poses, **0**. As duas chegaram ao fim.

## Item 6: arte

Conferido em `f6d2_garagem_cheia.png`, `f6d2_garagem_pequena.png`, `f6d2_academia_cheia.png`, `f6c2_mural_garagem.png`, `f6c2_simbolo_luta.png`
e nas pranchas `docs/arte/mockups/fase6d3_*.png`.

| Pedido | Resultado |
|---|---|
| Carro azul maior com lona cinza na metade de trás | OK (155x58, lona cinza-azulada atrás, rodas, vidros, farol) |
| Pneus novos, um em pé | OK |
| Geladeira nova | OK (puxadores, bilhete, rádio em cima) |
| Sem escada, sem ralo/retângulo preto, sem círculo de giz, sem miolo preto na mancha de óleo | OK |
| Lâmpada só no fio | OK (sem anel de pontos) |
| Academia: "BOA ESQUINA" inteiro | OK |
| Academia: espelho com uma trinca só | OK |
| Fundo da luta: ferrugem e "07" da porta | OK (o "07" lê "07"; a ferrugem é discreta no escuro) |
| **Nenhuma pessoa em cima do carro** | **FALHOU: B1** |
| Garagem cheia/pequena sem aparelho em cima de outra peça | OK (esteira e saco livres; ver B5 para o painel) |

## Item 7: símbolo R de raiz

- Peito e coxa de todas as poses: `tests/qa_f6d3_simbolo2.gd` desenha as camadas. Nas folhas `stand_bare`, `walk_bare` e `duck_under`, a
  versão normal e a `_left` mostram o R do peito na mesma orientação (não espelhado). Folhas de luta, retrato 32x32 e busto do mural têm o R.
  Na coxa o desenho é parcial (tapado pela perna) e muda de forma entre quadros; é o esperado, não é espelhamento.
- OK em: parede da garagem salva (`wall_school_symbol.png`, R azul com raízes), plaquinha do mural (garagem e academia, `R` na cortiça),
  caixas (`box_big`/`box_small` modificados), selo do mural (`ui_mural_seal`), selo GARAGEM SALVA (`f6a_vitoria_selo.png`, R no selo), peito do
  discípulo na garagem, na luta e nas cenas (`fase6d_qa2_p23_*` do `qa_f6d_cenas.gd p=2,3`: FALHAS 0).
- **Sobrou símbolo antigo:** `assets/sprites/ui/icon_garage_saved.png` (o ícone de 16x16 ao lado do texto "GARAGEM SALVA" na janela de vitória)
  ainda tem o selo azul com a lâmpada/raiz antiga. Não foi regenerado (não aparece no `git status`). B2.

## Item 8: automáticos

| Comando | Resultado |
|---|---|
| `tools/run_tests.ps1` (APPDATA temp) | **TODOS OS TESTES PASSARAM** (exit 0, ~3 min; guarda do save real nos dois lados OK; cena principal sem erros) |
| `ui_audit.gd -- --estados todos --resolution 1280x720 --position 1950,40`, **rodada 1** | `ESTADOS 383 \| PROBLEMAS 0`, 7 min 36 s |
| idem, **rodada 2** | `ESTADOS 383 \| PROBLEMAS 0`, 7 min 36 s |
| `tools/cenas/validar_cenas.gd` headless | 4 cenas, 0 erros, 0 avisos, 0 pendências (tempo preso 2,4 / 14,7 / 15,8 / 0 s); exit 0 |
| `tools/refatoracao/foto.gd` (worktree `origin/main` x pasta) | `fc`: **nenhuma diferença** (247.650 bytes nos dois). Nem os textos diferem, pois a foto não lê as chaves removidas |

Travamento da auditoria: **não travou** em nenhuma das 2 rodadas inteiras, mesma duração. Ritmo: ~40 capturas/min no começo, caindo para ~10/min
nas cenas da 6c1 (`f6c1_saida_*`) e no trecho do mapa; foi o período em que eu também rodava o `validar_cenas` e a foto em paralelo (headless), então
pode ter pesado. Rodei os dois jobs paralelos só na rodada 1; a rodada 2 correu sozinha e levou o mesmo tempo (7:35). O console do Godot só mostra a saída ao final
(stdout bufferizado), então "parece parado" por minutos sem estar travado. Se o designer teve travamento, não reproduzi; suspeita: janela em
segundo plano sendo suspensa pelo Windows ou rodar em paralelo com outro Godot.

## Bugs

**B1 (MÉDIA, arte/layout; quem corrige: Programador com o Artista de Personagens/Diretor de Arte) Pessoas em cima do carro novo da garagem.**
O John (ponto do coach, aprox. x 190..215, y 175..235 na base 640x360) fica de frente para o carro e o cobre: cabeça sobre a lona e o torso
sobre a lataria traseira. Com o mural, o discípulo sentado na caixa (x ~118..145) também fica em frente ao capô/porta. O dono pediu
explicitamente para checar isso.
Reproduzir: abrir o jogo novo (garagem); ou rodar `ui_audit` estado `f6d2_garagem_pequena` e abrir `f6d2_garagem_pequena.png`; também aparece em
`f6c2_mural_garagem.png` e em todos os quadros da cena `fase6d_qa2_p23_s2_00.png`. Sugestão: mover `ponto_do_coach` (e o assento do sentado)
para fora do intervalo x do carro (160..485 em 1280 = 80..243 em 640) ou levar o carro para a esquerda.

**B2 (MÉDIA, arte; quem corrige: Diretor de Arte) Ícone "GARAGEM SALVA" ainda com o símbolo antigo.**
`assets/sprites/ui/icon_garage_saved.png` (16x16) é gerado por `tools/art/make_cenario_fase6a.gd:450` e não foi refeito por
`make_arte_fase6d3_simbolo.gd`. Reproduzir: vitória com o 1º cinturão (`ui_audit` estado `f6a_vitoria_selo`), olhar a 4ª linha de prêmio. O
selo à direita está novo (R), o ícone ao lado ainda é a lâmpada com raízes. Pedido do dono: "não pode sobrar nenhum símbolo antigo".

**B3 (BAIXA, dados; quem corrige: Programador) Chaves mortas de FIXAR.** `data/ui_texts.json:26-27` (`pin_panel`, `pin_panel_on`) não têm mais
nenhum uso. Não aparecem na tela. Também `docs/estado-atual.md:8` ainda cita "FIXAR" (documentação).

**B4 (BAIXA, UI; quem corrige: Designer UI/UX) Botão SEGURAR e rótulo "salvo" se sobrepõem em tese; altura do botão.**
(a) `ui/barra_baixo.gd` `X_SALVO = 456` (rótulo 456..486 x 340..363) cobre o botão (464..484 x 337..352). Fica invisível enquanto o texto está
vazio; se "SALVO" aparecer (autosave), vai por cima do botão. Reproduzir: ler `_salvo` na `BarraBaixo` (`qa_f6d3_botao.gd` imprime
`salvo label: [P: (456.0, 340.0), S: (30.0, 23.0)]`), forçar texto e conferir. Não consegui provocar na janela.
(b) O botão tem altura 15 e o "?" 16: topos alinhados em y 337, bases diferem 1 px (visível no zoom x4). Alinhar centro em y 345 (faixa 330..360).

**B5 (BAIXA, visual) Pés de personagem espiando abaixo do painel aberto.** Com o painel da direita aberto (agora o padrão depois de
abrir com L e sem fecha-ao-clicar), um personagem do canto inferior direito fica coberto pelo painel e só os pés aparecem em x ~1160..1200, y ~637
(1280x720) logo abaixo da borda do painel (`f6d2_garagem_cheia.png`, `f6d2_academia_cheia.png`). Parece um glitch. Sugestão: o painel descer
até a faixa de baixo, ou esconder/mover esse figurante com o painel aberto.

**B6 (BAIXA, higiene) Meus testes e os da equipe regravam capturas rastreadas.** `qa_f6d2_tela.gd` e `qa_f6d_cenas.gd` escrevem em
`docs/arte/mockups/fase6d2_qa_*.png` e `fase6d_qa2_*.png`, arquivos já versionados: rodar os testes deixa dezenas de PNG como "modified" no git
(vi ~40). Aviso ao Produtor ao commitar: decidir se esses PNG entram ou se os testes passam a gravar em pasta temporária. Meus novos
testes gravam só no scratchpad ou não gravam.

## Riscos
- Painel aberto como padrão cobre a faixa direita da sala (x 508..640) e figurantes passam por baixo; depende de o jogador fechar. É a decisão do dono.
- A auditoria inteira leva ~7,5 min e fica sem saída no console até o final: parece travada para quem acompanha.
- O R é placeholder por código; versão final pede pixel artist (já anotado pelo Diretor de Arte).
- A foto de balanço não cobre UI nem arte, então as mudanças desta rodada dependem dos testes de tela e das capturas acima.

## Arquivos
- Testes novos meus: `E:\Fightclicker\tests\qa_f6d3_numeros.gd`, `qa_f6d3_botao.gd`, `qa_f6d3_piscando.gd`, `qa_f6d3_simbolo.gd`, `qa_f6d3_simbolo2.gd`.
- Capturas da auditoria (rodada 1 e 2): `C:\Users\deivi\AppData\Local\Temp\claude\4ea5d9e6a0b1fa65\ba632f0d-dc81-4067-8465-81b47bdd6b21\scratchpad\audit1\` e `...\audit2\`.
- Log do `run_tests`: `...\scratchpad\run_tests.txt`.
