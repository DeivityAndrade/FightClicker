# Fase 1 — Fundação: revisão do Diretor

Data: 2026-11-05. Base: `docs/fases/fase1-escopo.md`, `docs/fases/fase1-qa.md`, `README.md`, código em `scripts/`, `ui/`, `scenes/`, `data/`, `project.godot` e screenshots do QA (janela 1280x720 e tela cheia 1920x1080).

## Veredito
**Aprovado.** Pode ser mostrado ao dono como está.
- Os 11 critérios de aceite passam, com evidência real (janela, tela cheia, arquivo no disco).
- Os bugs B1, B2 e B3 do QA foram corrigidos e conferidos no código (versão gigante agora conta como "futuro"; `tick(NaN)` é ignorado; o diálogo de apagar avisa quando o save é de versão mais nova).
- A bateria `tools/run_tests.ps1` passa inteira, e o guarda do save real foi provado (inclusive falhando de propósito quando o QA sabotou o arquivo).
- Há uma decisão pendente antes de começar a arte da Fase 2 (modo de esticar a tela, ver "Desvios"). Ela não bloqueia esta fase.

## O que ficou bom
- **Simples e legível.** São 4 scripts pequenos (`game_state.gd`, `save_store.gd`, `number_format.gd`, `game_config.gd`) e uma tela. Não tem classe de número grande, gerenciador de cenas nem sistema de eventos. Era o que o escopo pedia.
- **Save confiável de verdade.** Grava primeiro num arquivo temporário, mantém um `.bak`, migra versões em cadeia, guarda o arquivo corrompido em vez de apagar e não toca em save de versão futura. O processo foi morto 25 vezes no meio da gravação e nunca perdeu tudo. É a parte que mais protege o dono nas próximas fases.
- **Formatador único** e no formato que o dono aprovou (3 dígitos, ponto). Os sufixos ficam num lugar só. Não aparece `1000K`, e NaN/infinito não quebram a tela.
- **O tick não depende do FPS** (30, 60 e 144 FPS rendem o mesmo) e a UI só escuta sinais. A regra "a UI nunca soma recursos" foi respeitada.
- **Dados fora do código:** `data/config.json`, com faixa válida e padrões seguros.
- **Pixel art configurado cedo:** base 640x360, escala só inteira, filtro "nearest" e snap. A tela cheia em 1080p dá x3 exato, com o quadriculado nítido.
- **Nada da Fase 2 foi adiantado no jogo.** O botão "+1" não tem juice, não existem atributos nem custos. A arte e o simulador que já existem em `tools/` e `docs/arte/` são preparação dos outros papéis e não entram no jogo.
- **A tela de verificação cumpre o papel.** Diz que é provisória, mostra tudo funcionando ao vivo e o aviso de save corrompido aparece na tela, em laranja.

## Desvios da visão / do combinado
1. **Modo de esticar a tela diverge da direção de arte.** `project.godot` usa `stretch/mode = canvas_items` (o texto sai liso, na resolução do monitor). Já `docs/arte/direcao-visual.md` pede `viewport`, onde tudo, inclusive o texto, fica preso na grade de 640x360. O escopo deixou essa escolha para o Programador junto com o Diretor de Arte, e ela não foi fechada entre os dois.
   - Por que importa: a Fase 2 traz a fonte bitmap 5x7, números flutuando e tremida de tela. Com `canvas_items`, esses elementos podem parar "entre pixels" e misturar texto liso com arte pixelada. Com `viewport`, tudo fica na grade, mas o texto pequeno precisa continuar legível.
   - Decisão: **resolver no início da Fase 2, antes de qualquer arte entrar na cena**. Minha recomendação é seguir a direção de arte (`viewport` + fonte 5x7) e revalidar a legibilidade em 1280x720. Só voltar para `canvas_items` se a legibilidade falhar.
2. **Detalhe sem impacto:** o botão aparece como "x1.00K treino" em vez de "x1000 treino" porque passa pelo formatador. Aceito, até prova que o formatador está em toda a UI.
3. Fora isso, nenhum desvio. Identidade original, sem mecânica anti-incremental e sem sistema de fase futura.

## Riscos herdados
### Tratar na Fase 2
- **R1. Janela maximizada em 1080p fica com escala x2 e faixas pretas grandes.** A área útil maximizada (~1920x1010) não cabe x3. Na Fase 2 o dono vai olhar a garagem pela primeira vez e não pode achar que "o jogo ficou pequeno".
  - Entra na Fase 2: atalho **F11 para alternar tela cheia** (x3 em 1080p), citado na dica de controles da tela. É uma linha de configuração, não é menu de opções.
  - Fica para a Fase 9: menu de opções com modo de janela, resolução e escala.
- **R3. Texto liso com `canvas_items` vs pixelado com `viewport`.** É o desvio 1 acima. Precisa estar decidido e registrado no `fase2-design.md`.
- **Primeira migração real do save (v1 para v2).** A Fase 2 adiciona atributos, foco, geradores e upgrades. Pedir uma função `_migrar_1_para_2` e um teste que abre um save v1 da Fase 1 e chega na v2 sem perder o treino. O save do dono precisa sobreviver à troca de fase.
- **A tela de verificação será substituída.** Os botões de depuração (x1000, salvar, recarregar, apagar) continuam úteis para balancear. Na Fase 2 eles devem ficar escondidos atrás de uma tecla ou só em build de debug, fora da tela do jogador.
- **DPI do Windows acima de 100% não foi testado.** Com escala de 125% ou 150% num monitor 1080p, a janela inicial pode não caber em x2. O QA da Fase 2 deve testar pelo menos 125%.

### Pode ficar para depois
- **R2. Arquivos `.corrompido-<tempo>` acumulam.** Só aparecem quando há corrupção, o que é raro. Fase 9 (polimento): manter só os 5 mais recentes.
- **Sobra `save.json.tmp` depois de um crash.** É inofensivo, porque o próximo save sobrescreve. Pode ser limpo na Fase 9.
- **R4. `--save-dir=` tem precedência.** Só afeta testes e QA. Aceitável como está.
- **O guarda dos testes não olha subpastas.** Basta enquanto o save real ficar na raiz de `user://`. Revisar se a Fase 3 separar carreira e legado em arquivos diferentes.
- **O horário do último save é `saved_at_unix`.** O progresso offline da Fase 9 depende dele. Lá será preciso tratar relógio do PC adiantado ou atrasado (diferença negativa ou gigante).

## Como o dono testa (uns 3 minutos)
1. Abra o Godot 4.7.2, clique em "Importar", escolha `E:\Fightclicker\project.godot` e abra o projeto.
2. Aperte **F5**. Abre a "Fundação — tela de verificação (provisória)".
3. Observe:
   - "Treino" sobe 1 por segundo sozinho.
   - "+1 treino (teste)" soma 1 na hora.
   - Clique em "x1.00K treino" várias vezes. O número passa por K, M, B, T e vira científico (ex.: `1.23e15`) sem quebrar.
   - A lista da direita mostra `1.20K`, `3.45M`, `1.00e300` etc.
   - O quadriculado em "Teste de pixels" está nítido, sem borrão.
   - Espere 30 segundos. O rodapé mostra um novo horário em "Último save".
4. Feche pelo **X** da janela, aperte F5 de novo e confira que o treino voltou no mesmo valor de antes.
5. (Opcional) Apague o conteúdo de `%APPDATA%\Godot\app_userdata\Fightclicker\save.json` com o jogo fechado e abra de novo. Aparece um aviso laranja e o jogo carrega o backup. O backup só existe a partir do segundo save, então antes disso deixe o jogo aberto pelo menos 1 minuto.
6. (Opcional) Testes automáticos: rode `powershell -ExecutionPolicy Bypass -File E:\Fightclicker\tools\run_tests.ps1`. Tem que terminar com `TODOS OS TESTES PASSARAM`.

## Resumo para o Produtor
A Fase 1 está aprovada: os 11 critérios passam, os 3 bugs baixos foram corrigidos e o save sobrevive a corrupção, crash e versão futura.
O código é pequeno e simples, e nada da Fase 2 foi adiantado.
Antes de a arte da Fase 2 entrar, é preciso decidir o modo de esticar a tela (`viewport`, como pede a direção de arte, ou o `canvas_items` atual).
A Fase 2 também deve trazer F11 para tela cheia, a primeira migração de save (v1 para v2) e esconder os botões de depuração.
Arquivos corrompidos acumulados e menu de opções ficam para a Fase 9.
