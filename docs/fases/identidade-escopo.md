# Identidade visual + menu principal + varredura de alinhamento: escopo

Diretor de Jogo, 2026-11-25. Base: `PROMPT.md` §2 (originalidade), §3 (tom), §5.11 (offline) e §7 (fases); `CLAUDE.md` (alinhamento
de telas); pedido do dono de 2026-11-25 (feedback de terceiros: faixas, HUD e barra dos focos marrom-acinzentados com "cara de IA").

**Nome das subfases:** ID1 a ID4. Não uso "9a–9d" porque a fase 9 do plano já é o Arco 5 (histórias do Osmar) e o nome ia confundir.

## 1. Objetivo e sensação
- **Objetivo:** o jogo ganha uma **cara própria** (cores, molduras, botões e um logo) e uma **porta de entrada** (menu principal), e
  nenhuma tela fica torta: o verificador passa a pegar o que hoje deixa passar.
- **Sensação:** quem abre o jogo vê, no primeiro segundo, um jogo com identidade e não um protótipo. O HUD some da frente da cena e
  deixa o lutador aparecer. Nada pula para o lado.

## 2. Entra
- **3 direções em mockup** (Diretor de Arte), todas com as cores da história: vermelho da faixa do vulto, azul do carimbo Raízes, creme
  e asfalto.
  - A. **Vidro pixelado** ("estilo Apple"): painel translúcido com pontilhado, filete claro em cima e contorno escuro.
  - B. **Placa/lona de academia:** lona esticada, ilhós, fita, tinta de pincel.
  - C. **Cartaz de luta:** papel de lambe-lambe, faixas diagonais, letra de cartaz.
  - Cada mockup mostra a mesma coisa, em 640x360 e em 1x: sala da garagem com HUD, barra de baixo e barra dos focos; 1 janela (vitória);
    1 botão nos 4 estados (normal, hover, apertado, travado); o menu principal com logo.
- **Aplicação da direção escolhida:** tema global (`ui_tema.gd`), HUD, faixa de cima, barra de baixo, barra dos focos, molduras de
  janela, botões, balões e dicas. Paleta e medidas registradas em `direcao-visual.md`.
- **Logo FIGHTCLICKER** próprio, na direção escolhida.
- **Menu principal** ao abrir o jogo:
  - **CONTINUAR** (só se há save; é o botão em destaque). O resumo "Enquanto você estava fora…" (§5.11) vem depois dele, como hoje.
  - **NOVO JOGO:** com save existente, pede confirmação dupla e faz **cópia de segurança** do save antes de apagar. Leva à abertura.
  - **OPÇÕES:** só volume (geral e efeitos) e tela cheia/janela, guardados num arquivo próprio (`user://opcoes.cfg`), **fora do save**.
  - **SAIR.**
  - Fundo: a sala do local atual (ou a garagem num jogo novo), parada e escurecida, com o logo. Nada de cenário novo.
- **Verificador mais duro** (`tools/ui/ui_audit.gd`, §5) e **varredura** dos ~73 `ignore` em `ui/*.gd`.

## 3. Fica de fora
| Item | Onde |
|---|---|
| Mudar mecânica, economia, números, save do jogo (continua na versão atual, sem campo novo) | — (proibido nesta fase) |
| Arte de personagens, animações, cenários das salas e das telas | — (não muda) |
| Ícones novos de atributos e itens | só se a direção exigir; senão, fase 13 (polimento) |
| Menu de pausa no meio do jogo (Esc), troca de idioma, teclas configuráveis, resolução | 13 (polimento), se o dono pedir |
| Sons novos de menu e botão (reaproveita os que existem) | 13 |
| Várias vagas de save / perfis | — (não planejado) |
| Tela de créditos | 14 (Steam) |
| Shader de blur de verdade | — (ver risco 1) |

## 4. Subfases
| | Quem | Entrega | Para o dono |
|---|---|---|---|
| **ID1. Mockups + verificador duro** (em paralelo: não mexem nos mesmos arquivos) | Diretor de Arte (mockups e logo); Programador (verificador §5, **sem consertar telas ainda**: só a lista do que ele acusa) | 3 mockups; relatório "o verificador novo acusa N problemas em tais telas" | **escolhe a direção** (pode misturar) |
| **ID2. Tema + sala** | UI/UX (tema, HUD, faixas, barra dos focos, barra de baixo, balões, dicas) | sala dos 3 locais na direção nova, com 0 problemas no verificador duro | testa a sala |
| **ID3. Janelas e telas + varredura** | UI/UX (janelas, loja, luta, vitória, mural, arte, criar discípulo, mapa, minigames, Ronda) | cada tela passa uma vez: veste o tema e zera os `ignore` sem motivo | testa as telas |
| **ID4. Menu principal** | Diretor de Arte (logo final); Programador (fluxo, opções, cópia do save); UI/UX (tela) | menu com os 4 botões e o fluxo abrir → menu → jogo | aprova a fase |

**Por que essa ordem:** o verificador fica duro **antes** de pintar, assim cada tela é pintada e alinhada **uma vez só**. O menu é o
último porque usa o tema pronto e é a parte mais independente (pode ser cortado sem quebrar o resto).

## 5. Verificador mais duro (regras)
1. **Todo `ignore` tem motivo escrito** (`ui_align=ignore:motivo`). Sem motivo, o verificador acusa problema.
2. **`ignore` proibido em `Button` e em texto fixo** (`Label` cujo texto não muda em tempo de jogo). O verificador acusa.
3. **Botões e textos conferidos por padrão**, mesmo sem declaração: texto de botão centralizado no botão, botão inteiro na tela, texto
   sem corte. Declarar passa a servir para pedir **mais** regra, não para ligar a conferência.
4. **Texto desenhado por código:** todo `draw_string` passa por uma função única (ex.: `UiTema.desenhar_texto_centro`) que registra o
   retângulo e o texto para o verificador medir o centro. Um teste por busca acusa `draw_string` fora dela.
5. **Placar de `ignore`:** o verificador imprime o total e a lista com motivo. Meta: **no máximo 15** no fim da fase.
6. **Teste do verificador:** uma cena de propósito torta (botão com texto fora do centro, texto cortado, `ignore` sem motivo, texto de
   código descentralizado) tem de **reprovar** nas 4 regras.

## 6. Critérios de aceite
1. **Escolha:** os 3 mockups mostram as mesmas peças (§2), em 640x360 e 1x, e o dono escolhe uma direção antes de ID2.
2. **Sem "cara de IA":** nenhuma faixa, HUD ou barra usa o marrom-acinzentado de hoje; as cores saem da paleta registrada.
3. **Legível em 640x360 e 1x:** todo texto do HUD e dos botões tem contraste de **pelo menos 4,5:1** contra o ponto **mais claro** do
   cenário atrás dele (medido nas capturas dos 3 locais, com a sala vazia e com equipe máxima).
4. **Os números se leem:** um testador lê dinheiro, FAMA e o foco ativo em menos de 2 s, nos 3 locais.
5. **Clique com juice igual ou melhor:** o clique na sala tem o mesmo impacto de antes (tremida, número subindo, som); o tema novo não
   apaga o efeito.
6. **Menu:** abrir o jogo com save → CONTINUAR → sala em até 2 cliques. Sem save, CONTINUAR não aparece. NOVO JOGO com save pede 2
   confirmações e deixa uma cópia do save. OPÇÕES guarda volume e tela cheia entre aberturas, sem tocar no save do jogo.
7. **Nada mudou no jogo:** a `foto.gd` de uma campanha inteira é **idêntica** à da main.
8. **Verificador:** as 6 regras do §5 funcionam (a cena torta reprova); total de `ignore` ≤ 15, todos com motivo; nenhum em botão
   ou texto fixo.
9. **0 problemas** no `ui_audit` em todas as telas: sala dos 3 locais (vazia e cheia), todas as janelas, luta, minigames, Ronda, mapa,
   criar discípulo, menu e opções.
10. **Os itens que o dono viu tortos** estão corrigidos (o Produtor passa a lista com captura; ver pergunta 4).
11. `tools/run_tests.ps1` verde, com save de teste, janelas em `--position 1950,40`, um Godot por vez e `--max-fps 30`.

## 7. Riscos
1. **"Vidro" em pixel art sem blur:** blur de verdade custa GPU (cópia da tela + shader) e borra o pixel, o que fica feio. Saída: vidro
   **falso**, com preenchimento translúcido de 60–80%, pontilhado (dither) de 1 px, filete claro em cima e contorno escuro. Sem shader.
2. **Contraste:** o painel translúcido em cima de uma cena movimentada (equipe máxima, luz da academia) faz o texto sumir. Saída: o
   texto fica sempre numa "placa" mais opaca dentro do vidro, com contorno de 1 px, e vale o critério 3.
3. **Legibilidade em 640x360:** molduras grossas (lona, ilhós, cartaz rasgado) comem espaço que já é pouco. Saída: borda de no máximo
   2–3 px no HUD; o enfeite fica nas janelas grandes e no menu.
4. **Mudar o tamanho das coisas:** uma fonte ou borda nova muda larguras e quebra telas que hoje passam. Saída: o verificador duro
   antes (ID1) e cada tela passando uma vez em ID3.
5. **Trocar uma cara de IA por outra:** vidro com gradiente é moda e também pode parecer genérico. Saída: a direção tem de usar as
   cores e os objetos da história (faixa vermelha, carimbo R, asfalto), não um vidro neutro.
6. **Apagar o save do dono:** NOVO JOGO é o único ponto perigoso. Saída: confirmação dupla e cópia de segurança, e os testes usam o
   save de teste.
7. **Fase crescer:** é só pele e porta. Qualquer pedido de mecânica nova vai para a fila.

## 8. Perguntas ao dono
1. **Pode misturar direções** (ex.: vidro no HUD e cartaz no menu e nas janelas de vitória)? **Recomendo** permitir só uma base com, no
   máximo, um "sotaque" da outra.
2. **Opções:** só volume e tela cheia (**recomendo**), ou quer mais alguma coisa agora?
3. **NOVO JOGO com save existente:** confirmação dupla + cópia de segurança (**recomendo**), ou esconder o NOVO JOGO enquanto houver
   save?
4. **Quais itens você viu descentralizados?** Uma captura ou o nome da tela de cada um vira critério 10.
5. **A abertura (cena do começo)** continua tocando depois do NOVO JOGO, como hoje (**recomendo**)?

## Resumo para o Produtor
- Fase de pele e porta, em 4 subfases (ID1–ID4): mockups + verificador duro → tema na sala → janelas/telas com varredura → menu
  principal. Nada de mecânica, economia, save ou personagem muda; a `foto.gd` prova.
- O Diretor de Arte faz 3 direções (vidro pixelado, lona de academia, cartaz de luta) com as cores da história; o dono escolhe antes
  de qualquer pintura.
- O verificador passa a conferir botões e textos por padrão, exige motivo em todo `ignore`, proíbe `ignore` em botão e texto fixo e
  mede texto desenhado por código. Meta: de ~73 para no máximo 15 `ignore`.
- O "vidro" é falso (translúcido + pontilhado + filete), sem blur, com contraste mínimo de 4,5:1 medido nos 3 locais.
- 5 perguntas ao dono; a mais urgente é a lista dos itens tortos que ele viu.
