# Fase 1 — Fundação: escopo

## Objetivo
Criar a base técnica sobre a qual todas as outras fases vão ser construídas: projeto Godot organizado, estado do jogo central, números grandes bem formatados e save/load confiável. O jogo em si (clique com juice, geradores, upgrades) **ainda não** entra aqui.

## Sensação
- **Para o dono:** "a base é sólida". Ele abre o jogo, vê um número crescendo sozinho, fecha, reabre e o número continua de onde parou. Nada se perde, nada quebra.
- **Para o jogador (futuro):** nenhuma por enquanto. Esta fase é a fundação de uma casa: ninguém mora nela ainda, mas sem ela nada fica de pé.

## O que a Fase 1 entrega para testar: uma Tela de Verificação
O PROMPT pede algo testável no fim de cada fase. Como a Fase 1 é técnica, a entrega é uma **tela de verificação simples**, não uma tela de jogo. Ela deve deixar claro que é provisória (título "Fundação — tela de verificação").

A tela mostra e permite:
- **Treino atual** formatado (ex.: `1.23K`) e **treino por segundo** de teste, crescendo sozinho em tempo real.
- Um botão **"+1 treino (teste)"** simples, **sem juice** (sem tremida, sem número flutuando, sem som). Serve só para provar que o estado muda e a tela atualiza.
- Botões de depuração: **"x1000 treino"** (pular para números enormes), **"Salvar agora"**, **"Recarregar save"**, **"Apagar save"** (com confirmação).
- Uma **lista de exemplos de formatação** (1, 999, 1.2K, 3.4M, 1.23e15, 1e300) gerada pelo formatador real.
- Linha de status: versão do save, horário do último autosave, caminho do arquivo de save.

Toda essa tela será **substituída** na Fase 2. Não investir em layout ou arte.

## O que entra
- **Projeto Godot 4.7.x**, 2D, interface com nós `Control`, janela de PC, **configurado para pixel art** (ver requisito abaixo).
- **Estrutura de pastas:** `scenes/`, `scripts/`, `data/`, `ui/`, `assets/`, `tests/`, `docs/`.
- **GameState (autoload):** guarda o estado do jogo e avisa a UI por **sinais** quando algo muda. Na Fase 1 guarda só o mínimo: treino, treino por segundo (valor de teste), versão do save, data do último save.
- **Formatador de números** (um lugar só, usado por toda a UI).
- **Save/load em `user://` (JSON)**, versionado, com migração, backup e autosave.
- **Tick passivo** separado da UI.
- **Dados em `data/`:** um arquivo de configuração (ex.: intervalo de autosave, treino por segundo de teste) lido na inicialização, provando o caminho "dados fora do código".
- **Testes automáticos** rodando sem abrir janela (headless), com save isolado.
- **Instrução curta** de como abrir, testar e rodar os testes (no relatório do Programador ou num `README` simples).

## Requisitos da fundação (para não travar as fases seguintes)

### Números grandes
- Usar **float do Godot (precisão dupla)**. Ele vai até ~1.8e308, o que cobre a meta de **~1e300**. **Não** criar classe de número grande agora; só se uma fase futura provar que é necessário.
- Formato padrão, sempre com **3 dígitos significativos**:
  - abaixo de 1.000: inteiro (`0`, `42`, `999`);
  - `K` (mil), `M` (milhão), `B` (bilhão), `T` (trilhão): `1.2K`, `3.4M`, `56.7B`, `999T`;
  - a partir de **1e15**: científico, `1.23e15`, `4.56e300`.
- Arredondamento não pode gerar textos errados como `1000K` (deve virar `1.00M`).
- Negativos, zero, `NaN` e infinito não podem travar o jogo nem gerar texto quebrado (mostrar `0` ou um texto seguro, e registrar aviso).
- Os sufixos ficam em um lugar só, fácil de trocar depois (ex.: notação toda científica como opção futura).

### Save/load
- Arquivo em `user://`, formato **JSON** legível.
- Campo **`version`** (número inteiro) em todo save.
- **Migração em cadeia:** uma função por salto de versão (v1→v2, v2→v3…). Um save antigo sempre abre na versão atual. Campos que faltam recebem valor padrão; campos desconhecidos são ignorados sem erro.
- **Gravação segura:** grava primeiro num arquivo temporário e só depois substitui o save. Antes de substituir, o save anterior vira **backup** (`.bak`).
- **Save corrompido** (JSON inválido ou vazio): tenta o backup; se o backup também falhar, começa jogo novo **sem apagar** o arquivo corrompido (renomeia para análise) e avisa na tela.
- Save de **versão maior que a do jogo** (vindo do futuro): não abre e não sobrescreve; avisa na tela.
- Guarda **data/hora do último save** (necessário para o progresso offline da Fase 8; o cálculo offline **não** entra agora).

### Autosave
- A cada **30 segundos** (valor vindo de `data/`), ao fechar a janela e ao clicar "Salvar agora".
- Fechar pelo X da janela tem que salvar antes de sair.

### Testes que nunca apagam o save real
- Testes usam um **caminho de save próprio** (ex.: `user://test/`) definido antes de qualquer leitura/gravação. O caminho do save real nunca é tocado por um teste.
- Um teste verifica explicitamente que o save real continua igual (mesmo conteúdo/data) depois da bateria de testes.
- Testes cobrem no mínimo: formatação (todas as faixas e casos-limite), salvar→carregar mantém os valores, migração de um save v0/v1 de exemplo, save corrompido usa backup, save do futuro não é sobrescrito.

### Tick passivo separado da UI
- A produção passiva é calculada no `GameState` (ou num nó de lógica) com `delta`, **sem depender** de nenhuma tela estar aberta.
- A UI só **escuta sinais** e mostra valores; ela nunca soma recursos.
- A atualização da tela pode ser limitada (ex.: algumas vezes por segundo) para não pesar, sem afetar a produção.
- O tick tem que ser correto com qualquer FPS (60, 144, 30): o treino ganho em 10 segundos é o mesmo.

### Configuração para pixel art (adicionado em 2026-11-05, nova direção do dono)
Mudança mínima, só de configuração, para não ter que refazer nada na Fase 2.
- **Resolução base pequena com escala inteira.** Recomendação: **640x360**, que escala por inteiro para 1280x720 (x2, a janela padrão aprovada), 1920x1080 (x3) e 2560x1440 (x4). O número final é confirmado com o Diretor de Arte (`docs/arte/direcao-visual.md`); se ele escolher outro, vale o dele, desde que escale por inteiro para 1280x720 e 1920x1080.
- **Escala inteira** (sem pixels de tamanhos diferentes) e **filtro de textura "nearest"** como padrão do projeto (pixel nítido, sem borrão).
- Proporção travada em 16:9, com faixas pretas se a janela tiver outra proporção.
- Texto da interface **legível** na janela 1280x720. O modo exato de esticar a tela (que afeta como o texto aparece) fica com o Programador junto com o Diretor de Arte.
- Na tela de verificação: um **padrão de teste de pixels** (ex.: um quadriculado pequeno de 1 pixel ou um sprite de teste qualquer) para provar que a escala está nítida. **Sem** fundo da garagem: a garagem é arte da Fase 2.

### Dados em `data/`
- Valores ajustáveis (intervalo de autosave, valor de teste de treino/s) ficam em arquivo em `data/`, não no código.
- Se o arquivo faltar ou estiver errado, o jogo usa padrões seguros e avisa no console.

## O que fica de fora (e onde entra)
Numeração conforme o novo `docs/roadmap.md` (2026-11-05).

| Item | Fase |
|---|---|
| Sala da garagem em pixel art, alvo central, aparelhos | Fase 2 |
| Clique com juice (números flutuando, tremida, som, aparelho balançando) | Fase 2 |
| Foco de atributo, Força/Agilidade/Resistência | Fase 2 |
| Primeiros geradores e upgrades, fórmula de custo | Fase 2 |
| Dinheiro, lutas, adversários, barras de vida, tática | Fase 3 |
| Fim de carreira (derrota/aposentadoria), Legado | Fase 3 |
| Árvore de habilidades | Fase 4 |
| Mudança de local, artes marciais | Fase 5 |
| Fama, patrocínio, geradores avançados, locais 3–4 | Fase 6 |
| Cinturão mundial, segunda arte | Fase 7 |
| Rival, mentor, diálogos, locais 5–6, nome final do jogo | Fase 8 |
| Cálculo de progresso offline e tela "Enquanto você estava fora…" | Fase 9 |
| Conquistas, sons, menu de opções, notação alternativa | Fase 9 |
| GodotSteam, nuvem, build de distribuição | Fase 10 |
| Arte final, paleta, fontes pixel definitivas | Diretor de Arte, a partir da Fase 2 |

Também fica de fora: sistema de idiomas, menu principal, múltiplos slots de save, classe de número grande.

## Critérios de aceite (verificáveis)
1. O dono abre o projeto no Godot 4.7.2 e roda com **F5** sem erros nem avisos vermelhos no console.
2. Em **até 1 minuto**, o dono vê o treino subir sozinho e o botão "+1 treino (teste)" somar 1 na hora.
3. Clicando "x1000 treino" algumas vezes, o número passa por `K`, `M`, `B`, `T` e entra em científico (`1.23e15`) sem texto quebrado; chegando perto de 1e300 nada trava.
4. A lista de exemplos mostra exatamente o formato aprovado pelo dono (pergunta 2). Com a recomendação de 3 dígitos: `1`, `999`, `1.20K`, `3.40M`, `1.23e15`, `1.00e300`.
5. O dono fecha pelo **X**, reabre, e o treino está no mesmo valor (diferença máxima de 1 segundo de produção).
6. Esperando **30 segundos** sem clicar em nada, a linha de status mostra um novo horário de autosave.
7. Se o dono apagar o conteúdo do arquivo de save (ou escrever lixo nele) e reabrir, o jogo carrega o backup e mostra um aviso, sem travar.
8. Os testes automáticos rodam com um único comando (documentado), passam todos, e o save real do dono **continua igual** depois deles.
9. Mudando o valor de treino/s de teste no arquivo em `data/` e reabrindo, a velocidade muda **sem tocar no código**.
10. Com o jogo limitado a 30 FPS e a 144 FPS, o treino ganho em 10 segundos é o mesmo (verificado por teste automático).
11. Abrindo a janela em 1280x720 e depois em tela de 1920x1080 (ou maximizada), o padrão de teste de pixels continua **nítido**, sem borrão e sem pixels de tamanhos diferentes; o texto continua legível.

## Riscos de design
- **Fase "invisível":** o dono pode achar que nada aconteceu. Mitigação: a tela de verificação mostra tudo funcionando ao vivo e o relatório explica em português simples o que cada coisa garante.
- **Superengenharia:** tentação de criar classe de número grande, sistema de eventos genérico, gerenciador de cenas etc. Regra: só o que os critérios acima exigem.
- **Adiantar a Fase 2:** o botão de teste não pode virar o botão de clique do jogo. Sem juice, sem atributos, sem custos.
- **Formato de número inconsistente** entre telas no futuro. Mitigação: um formatador único e testado desde já.
- **Save frágil:** se o save quebrar na Fase 5, o dono perde horas. Por isso migração, backup e testes entram agora, não depois. Com carreiras por run (Fase 3), o save vai ter duas partes: a carreira atual e o que é permanente (Legado, árvore). **Não** implementar isso agora; só não fechar a porta (o formato JSON com versão e migração já resolve).
- **Pixel art mal configurado:** se a escala inteira e o filtro "nearest" não forem acertados agora, toda a arte da Fase 2 sai borrada e o retrabalho é grande. Por isso a configuração entra já, sem arte.

## Perguntas abertas para o dono
1. **Nome do jogo:** manter "Fightclicker" como nome de trabalho e decidir na Fase 7, ou já escolher entre as sugestões em `docs/visao.md`?
2. **Formato dos números:** prefere sempre 3 dígitos (`1.20K`, `12.3K`, `123K`) ou o mais enxuto (`1.2K`)? Recomendação: 3 dígitos significativos.
3. **Separador decimal:** ponto (`1.2K`, padrão de incrementais e da Steam global) ou vírgula (`1,2K`, padrão brasileiro)? Recomendação: ponto agora, opção de idioma depois.
4. **Resolução/janela:** começar em 1280x720 redimensionável, com tela cheia opcional mais tarde? Recomendação: sim.
5. **Intervalo de autosave:** 30 segundos está bom?

---

## Respostas do dono (2026-11-05)
1. Nome de trabalho: **Fightclicker** (nome definitivo decidido até a Fase 7, após checar a Steam).
2. Formato dos números: **fixo com 3 dígitos significativos** — `1.00K`, `1.20K`, `3.45M`, `123K`.
3. Separador decimal: **ponto**.
4. Janela 1280x720 e autosave a cada 30 s: mantidos como padrão do estúdio (ajustáveis em data/).
