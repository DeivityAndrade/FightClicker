# Fase 7b1 — Muay Thai: revisão do Diretor

Diretor de Jogo, 2026-11-21. Worktree `continue-agents-config-722700`, sem commit. Base: `fase7b-escopo.md` (§3, §7 e **decisões
do dono**), `fase7b1-design.md`, `fase7b1-textos.md`, `fase7b1-qa.md`, `docs/arte/direcao-visual.md` §32 e
`docs/arte/fase7b1-poses-manifest.md`.

## Veredito
**Aprovada com ressalvas.** Nenhuma ressalva mexe em número, tela ou save. São duas conferências rápidas antes de mostrar ao dono:
1. **QA:** medir a linha "N EM 10 VITÓRIAS POR CHUTE RODADO" contra a luta real (ver ponto 2 abaixo).
2. **QA:** olhar de novo as 3 capturas da prévia (`f7b1_previa_mt_*`) e a do letreiro com o B1 e o B2 corrigidos. O verificador não
   pega texto sobre ícone, e é por isso que o B1 escapou da primeira vez.

O UI/UX já corrigiu B1, B2 e B3. O `ui_audit` dá 447 estados e 0 problemas, e o `run_tests.ps1` está verde.

## O que ficou bom
- **A arte tem cara própria.** O Muay Thai muda o adversário: ele fica marcado, manca e fica mais lento. O Boxe muda o seu ritmo e o
  Jiu-jitsu muda o tempo da luta. É exatamente a diferença que a §3.1 pedia, e não ficou com cara de "Boxe com chute".
- **Arte completa, sem corte.** Saíram guarda tailandesa, chute baixo, joelhada, clinch e chute rodado. Os adversários ganharam
  acerto na perna, `limp` e `limp_heavy` (dois níveis de mancar), preso no clinch e queda pelo rodado. O Artista ainda fez o
  `hit_spin`, para o rodado que não derruba, que é uma boa solução. O saco chega com chute de canela de verdade, e o letreiro
  CHUTE RODADO! lê bem nas duas arenas.
- **Prévia honesta:** a diferença média fica abaixo de 2 pontos em todos os adversários, e a linha muda com a tática.
- **Nada mudou para quem não usa a arte:** a foto bate com a main (só as diferenças esperadas) e o simulador deu 3.000/3.000 lutas
  idênticas.
- **Balanço:** pela mediana, as três artes ficam a no máximo 1% uma da outra, como o dono pediu. O Muay Thai fica entre o Boxe e o
  Jiu-jitsu e não passou do Boxe a 4/s. O ajuste foi feito só nele.
- **Choque do Muay Thai:** quem clica no tempo vence, e quem clica afobado não vence nenhuma. É o "ritmo e precisão" da arte. O
  teto ficou em 7,9% na política principal.
- **Liberação como prêmio:** a arte chega na 1ª vitória contra o Kid, e o save antigo recebe a arte com a fala do Osmar uma vez só.
  O tom da fala está certo, pé no chão e com o exagero do Osmar.
- **Save:** continua v13 e aguentou os 10 casos de save sujo.

## Os pontos para decidir

### 1. Chute rodado no Defensivo contra o Tonhão (16–24% das vitórias): **passa.**
- O critério 1 serve para **reconhecer a arte olhando**. Chute baixo e adversário mancando aparecem nas 3 táticas, porque no
  Defensivo as marcas também enchem, só que no 3º round. O chute rodado aparece em 58–80% das vitórias no Agressivo, em 94–98% no
  Contra-ataque, em 43% com o robô misto e em 45–47% na campanha. A arte cumpre o critério.
- O Defensivo é, de propósito, a tática "errada" para a Canela. O escopo (§3.1) já dizia "marca devagar e fica mais seguro". Forçar
  1/3 de chute rodado também nele apagaria a diferença entre as táticas, e a escolha da tática perderia sentido.
- A prévia avisa antes da luta, com o rodado raro no Defensivo. Ninguém é enganado: o jogador escolhe o caminho seguro sabendo o que
  perde. Isso é escolha, não defeito.
- **Não volta para o Designer.** Mexer no `spin_ko` ou nas marcas só no Defensivo mudaria o tempo até o Kid, que está equilibrado
  pela mediana, em troca de quase nada.
- **Condição:** o teste de reconhecimento por uma pessoa (que o QA não fez) é feito com a tática que o cartão recomenda, Contra-ataque
  ou Agressivo. Ver o roteiro, item 3.

### 2. A conta do "N EM 10" tem que bater (conferência do QA, antes de mostrar)
A captura do Defensivo mostra "0 EM 10 VITÓRIAS POR CHUTE RODADO", mas o QA viu de 12% a 22% das vitórias **terminando** no rodado
no Defensivo. Pode ser só uma montagem diferente: a captura parece usar o caso fraco da tabela do design (§4, linhas com 0). Mesmo
assim, a prévia honesta é regra do jogo e tem que valer para essa linha também.
- **Pedido:** com os mesmos atributos da captura (e com os do `qa_f7b1_rodado.gd`), comparar o N da prévia com a fração real em
  1.000 lutas, nas 3 táticas. A tolerância é de ±1 em 10.
- Se bater, está fechado. Se não bater, o erro está na conta da linha e volta para o **Programador**, sem mexer em balanço.

### 3. Teto do minigame, caso `cedo_max` (10,9% a 3/s): **aceito, como na 7a2.**
O dono confirmou que o teto é medido em dias de campanha. Nessa medida o `cedo_max` luta no amarelo sem o custo da derrota. Na 7a2
ficou provado, com o controle de AQUECIDO zerado, que esse ganho vem de lutar cedo, e não do minigame. A política principal (7,9%)
cumpre o teto, e nenhum número travado mudou.
- **Registro, sem bloquear:** quando o Designer tocar no simulador de novo, ele acrescenta a linha de controle (AQUECIDO 0) para o
  Muay Thai, como fez na 7a2 §8.5, para deixar a prova completa.

### 4. Jiu-jitsu ~5% mais lento na média a 4/s: **segue assim** (decisão do dono)
Está dentro dos 15%. A distância vem da cauda do próprio Jiu-jitsu desde a 7a1, e o escopo proíbe mexer em outra arte nesta fase.

## Desvios e pendências
| # | O quê | Peso | Quem |
|---|---|---|---|
| D1 | Conferir o "N EM 10" contra a luta real, ±1 (ponto 2) | **antes de mostrar** | QA (Programador, se não bater) |
| D2 | Olhar as capturas da prévia e do letreiro depois da correção de B1 e B2 | **antes de mostrar** | QA |
| D3 | Ninguém viu em janela o especial dos cliques (SUPER) do Muay Thai, o balão da fala do Osmar nem as animações em movimento. Vão para o roteiro do dono | dono testa | Produtor |
| D4 | Linha de controle (AQUECIDO 0) do `cedo_max` para o Muay Thai | registro | Designer, na próxima vez |
| D5 | O lutador de Muay Thai usa as mesmas luvas vermelhas de boxe. **Está certo:** Muay Thai se luta de luva, e a luva é o item equipado do jogo. A arte se reconhece pelas pernas e pelo calção. Só avisar o dono | informar | Produtor |
| D6 | O saco, as marcas em 11 px e o ícone da arte em 9 px são placeholders honestos (§32). Ficam para a rodada de arte à mão | futuro | Diretor de Arte |

## Nada adiantado
Não entrou nada da 7b2: nem 2ª passiva, nem meta, nem cadeado no cartão. O clinch entrou só como golpe, como o escopo previa. Também
não entrou arena nova, nem rival, nem personagem novo: quem ensina o Muay Thai é o Osmar. Panfletagem, AQUECIDO e números travados
ficaram iguais.

## Como o dono testa a 7b1 (~20 min)
Use um save que **já venceu o Kid**, ou vença o Kid numa carreira com Boxe ou Jiu-jitsu.
1. **Liberação:** ao voltar para a sala, o Osmar solta a fala do chute guardado **uma vez só**. Confira o balão: ele deve estar
   inteiro e não pode cobrir nada. Feche e abra o jogo: a fala não pode se repetir depois de ter passado.
2. **Escolha da arte:** na próxima carreira aparecem 3 cartões lado a lado, inteiros. Escolha o Muay Thai.
3. **Reconhecer a arte (o teste principal):** lute contra o Tonhão no **Contra-ataque** ou no **Agressivo** e só olhe a luta, sem
   ler o HUD. Você deve ver o chute baixo, o adversário **mancando cada vez mais** e o chute rodado decidindo a luta. Depois lute uma
   no **Defensivo**: a perna enche no fim, e o rodado quase não sai, como a prévia avisa.
4. **Especial dos cliques:** encha o SUPER clicando na luta. O golpe tem que ser chute ou joelhada, com o letreiro CHUTE RODADO!.
   Não pode aparecer nenhum golpe de boxe.
5. **Prévia:** troque de tática e veja a linha da Canela mudar. O texto não pode passar por cima das marcas desenhadas.
6. **Saco de chute:** compre, abra a caixa e treine com foco "CHUTE". O clique tem picos: críticos mais frequentes (20%) e mais fortes. Diga se
   parece diferente do Boxe.
7. **Choque do Muay Thai:** jogue um clicando afobado e outro no ritmo, fechando o combo com o chute. O segundo tem que render
   muito mais.
8. **Árvore:** a região MUAY THAI (corda trançada, laranja) só aparece nesta carreira.
9. **Sensação:** com Muay Thai, dá vontade de "quebrar a perna e esperar o rodado"? Alguma das 3 artes parece a escolha certa?

## Resumo para o Produtor
- A 7b1 está **aprovada com ressalvas**. Antes de mostrar ao dono, o QA faz duas conferências rápidas: a linha "N em 10 vitórias por
  chute rodado" tem que bater com a luta real (±1), e as capturas da prévia corrigida precisam ser olhadas uma vez.
- O chute rodado raro no Defensivo **passa**. O Defensivo é a tática segura, a prévia avisa, e nas outras táticas o rodado sai em 58%
  a 98% das vitórias. Nada volta para o Designer.
- A arte saiu completa, sem corte, e tem cara própria: o adversário manca. O balanço está pela mediana (≤1%), como o dono pediu.
- O dono testa em janela o que ninguém viu: o especial dos cliques, o balão do Osmar e as animações em movimento (roteiro acima).
