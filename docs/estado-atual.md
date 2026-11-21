# Onde paramos (atualizado em 2026-11-21)

Documento do Produtor para retomar noutra sessão/conta. Vale sobre memórias antigas.

## Situação agora (2026-11-21, tarde)
- **Fase 7b2 fechada** (2ª passiva das 3 artes): Boxe **CONTRAGOLPISTA** (guarda alta, esquiva enche carga 0–3, contragolpe pode
  derrubar no 3º round; pede Contra-ataque), Jiu-jitsu **POR CIMA** (derruba e castiga no chão até o juiz parar; FORÇA + Agressivo),
  Muay Thai **CLINCH** (prende, joelhada crítica pode derrubar; FORÇA+RESISTÊNCIA + Defensivo). Escolhida no começo da carreira,
  substitui a 1ª e vale a carreira inteira. Libera com **3 vitórias pela 1ª passiva** somando a linhagem (dono reduziu de 5 para 3).
  Equilíbrio medido pela **mediana** (dono aceitou; cauda do Por cima a 3/s só em observação). Save v13.
- Letreiros de fim agora limpam os números de dano da área (vale também para os da 7b1/7a1).
- Docs: `fase7b2-design.md`, `fase7b2-textos.md`, `fase7b2-qa.md`, `fase7b2-revisao.md` (aprovada com ressalvas; roteiro do dono e
  tarefas futuras D2–D7 lá: prévia otimista contra Brutão/Dudu, medir a meta de 3 com o robô que busca a meta, arte à mão dos ícones).
- **Próximo:** esperar o dono testar a 7b ou mandar seguir para a próxima fase.

## Situação anterior (2026-11-21, manhã)
- **Fase 7b1 fechada** (Muay Thai): passiva **CANELA** (chute baixo marca a perna até 3 marcas, adversário manca, com a perna
  cheia o crítico vira **CHUTE RODADO**, que pode derrubar), crítico do clique 20% x4,1, **saco comprido de chute** (50/35/15),
  4 nós na região MUAY THAI (um é "Pé de pluma"), **Choque no compasso** (batida 0,5 s, 3º clique no tempo vira chute), liberação
  na 1ª vitória contra o Kid (fala do Osmar; save antigo com best_wins >= 6 recebe). Save v13.
- Balanço: dono pediu "as três mais ou menos na mesma %"; mediana do tempo até o Kid a ≤1% entre as artes. Na média a 4/s o
  Jiu-jitsu fica ~5% mais lento — dono: "seguir assim".
- Docs: `fase7b1-design.md`, `fase7b1-textos.md`, `fase7b1-qa.md`, `fase7b1-revisao.md` (aprovada com ressalvas; roteiro do dono lá).
- **Próximo: 7b2** (2ª passiva das 3 artes: Contragolpista, Por cima, Clinch; meta M1 de 5 vitórias pela passiva) — o dono já aprovou
  o escopo (`fase7b-escopo.md`). Esperar o dono testar a 7b1 ou mandar seguir.
- A pasta principal `E:\Fightclicker` (branch `fase-7b`) ainda tem cópias soltas e antigas do começo da 7b1, não commitadas.
  A versão certa é a do PR da 7b1. Descartar aquelas mudanças antes de usar a pasta (pedir ao dono).

## Situação anterior (2026-11-20)
- **Fase 7a2 fechada** ("Treino fora de hora"): convite do Osmar (300 s / 240 s, some em 60 s), minigames **Choque** (Boxe por
  cliques, JJ segurar/soltar; fôlego, rajada, pausa X2, finta; 6 níveis) e **Panfletagem** (sinais, FAMA), bônus **AQUECIDO** (+3%
  nos atributos na próxima luta, prévia honesta), relógio parado fora da sala (equipe só produz durante o minigame), semente do
  vulto mascarado (recorte na parede a partir da campanha 2 + boato do Osmar). Ignorar convites = jogo idêntico à main. Save v13.
  Docs: `fase7a2-design.md`, `fase7a2-textos.md`, `fase7a2-qa.md`, `fase7a2-revisao.md` (aprovada).
- **Teto de 10% dos minigames: em dias de campanha** (confirmado pelo dono em 2026-11-20; pior caso 9,2%).
- **Para o dono testar:** 7a1 e 7a2 (roteiro em `fase7a1-revisao.md` e `fase7a2-revisao.md`). Carro comprido de 2 portas fica anotado.
- **Próximo:** 7b (Muay Thai, 2ª passiva) só com ordem do dono. Poupar GPU: um Godot por vez, headless sempre que der.

## Situação anterior (2026-11-19, fim do dia)
- **Fase 7a1 fechada** (cada arte luta do seu jeito): Boxe "Mão rápida" (embalo, K.O. cedo, cansa no 3º round), Jiu-jitsu
  "Finalização" (barra de pegada, queda, chão, FINALIZOU!, especial "SUPER PEGADA!"), arena da liga **GINÁSIO ALVORADA** (opção A),
  prévia honesta (±2 pontos), sem arte idêntico. Docs: `fase7a-escopo.md` (§8 decisões do dono), `fase7a1-design.md`,
  `fase7a1-textos.md`, `fase7a1-qa.md`, `fase7a1-revisao.md` (aprovada). Save continua v13.
- **Próximo: 7a2** — minigames Choque (Boxe/JJ) e Panfletagem, bônus AQUECIDO, semente do Gato Preto. O dono autorizou seguir sem
  esperar teste dele ("pode tocar ficha"); ele testa tudo depois.
- **Anotado pelo dono (2026-11-19), fazer depois:** voltar ao **modelo do carro da 1ª versão da 6d3** (sedã comprido, de 2 portas,
  ~155 px — print do dono com o Osmar na frente), mas com a **lona cinza no estilo de antes** (a marrom saiu). Cuidado: o carro
  comprido foi encurtado porque cobria gente; conferir os pontos novos da garagem (Osmar 52,258; mentor 210,254; 2º mentor 26,304).
- Agentes: comandos longos (>180 s) vão para segundo plano sozinhos; mandar gravar saída em arquivo e esperar lendo o arquivo.

## Situação anterior (2026-11-19)
- **Rodada 6d3 fechada** (pedidos do dono depois de jogar a 6d): números com o nome inteiro do atributo; painel da direita
  só fecha quando o jogador manda (FIXAR removido); lutador piscando na luta corrigido (`ui/anim_sprite.gd`); garagem nova
  (carro azul com lona, pneus, geladeira, sem escada/ralo); varredura de arte (`docs/arte/fase6d3-varredura.md`);
  **símbolo da escola = "R de raiz"** (opção D) em todo lugar; botão SEGURAR na faixa de baixo; pontos da garagem mudaram
  (Osmar 52,258; mentor sentado 210,254; 2º mentor 26,304). QA `fase6d3-qa.md`, Diretor `fase6d3-revisao.md` (aprovada).
- Cor do R no peito: azul em roupa clara, amarelo em roupa escura (o dono aceitou manter assim para não sumir).
- Pendências pequenas: luz pintada do Osmar/John sentado é dos pontos antigos; público da luta, textura do mapa; o "SALVO"
  some com 4 focos; testes de QA regravam PNGs em `docs/arte/mockups/`.
- **Próximo: Fase 7a** (lutas por arte + minigame opcional em tela própria). O dono disse que, com tudo certo, pode seguir.

## Situação anterior (2026-11-18, noite)
- **Refatoração do GameState** na main (PR #19): núcleo + `scripts/estado/`; mapa em `docs/codigo/mapa.md`.
- **Fase 6d + 6d2 fechada** na main (PR #20): balão perto do cursor, números por atributo, cenas com o lutador criado,
  tela C (painel pela direita, FIXAR, atalhos L/E/H), sala larga repensada, aparelho invisível até a caixa, menos texto.
  QA em `docs/fases/fase6d-qa.md`; Diretor: aprovada com ressalvas (`docs/fases/fase6d-revisao.md`). Testes verdes, ui_audit 384/0.
- Pendências pequenas da 6d (não travam): 2 dicas sem item apontado (`painel_loja.gd:534`, `sala.gd:1172`); luz do vizinho
  da frente e do Nelson; painel fixado esconde Nelson/vizinho 3/ponta da esteira (ouvir o dono); "/CLIQUE" ao lado do +N; conferir o balão com o mouse real.
- **Próxima fase: 7a** (lutas por arte + minigame opcional em tela própria). **Não começar sem ordem do dono.**
- Os `.import` modificados na pasta só mudaram fim de linha (não commitar).

## Situação anterior (2026-11-18, manhã)
- **Fase 6c fechada.** A 6c2 está na main (PR #16), aprovada pelo QA (B1–B6 corrigidos) e pelo Diretor (`docs/fases/fase6c2-revisao.md`). Testes verdes e ui_audit com 358 estados e 0 problemas.
- O **PR #15** (6c2 feita por outra IA) foi **fechado sem integrar**, por decisão do dono. Tudo daquela IA é ignorado.
- Um **trio de adversários** (Bileco, Leslie Chow, Sapão), que veio dessa IA, foi tirado da 6c2. As mudanças soltas dela ficaram só na branch local `backup/outra-ia-2026-11-17` (não usar).
- **Pasta de trabalho:** `E:\Fightclicker`, branch `pos-6c` (igual à main). Os worktrees antigos em `.claude/worktrees/` e em `%TEMP%` sobraram e podem ser removidos.
- **Próximo passo:** o dono tem um comando antes de qualquer fase nova. **Não começar a 7a sem ordem dele.**

## Decisões do dono desta rodada
- Rival **James Blindado**: entra na 8a, menospreza a escola, termina em respeito; o **campeão mundial é outro** (fase 9).
- Saída do John: 1º momento calmo após a 1ª vitória de um discípulo na academia, ou campanha F+3.
- Modelos: Fable não é usado; pensadores em Opus médio (Designer em alto só na Honra da 6c2), executores em Sonnet.
- PR pode ser integrado na main sempre; executável só quando o dono pedir.

## Anotado para depois (não trava nada)
- Pixel artist humano: saco carregado menor que o pendurado (salto no `hang_bag` q1→q2); giro da esteira achatado; mãos simples; braço no agachamento do `john_pick_duffel`; peças de cenário do §25.4 da `direcao-visual.md`.
- Com a equipe máxima, vizinhos cobrem o Osmar na academia (aceito pelo dono, como na garagem; revisitar com arte à mão).
- OBS-2 do QA: com a vitória já armada, a saída do John sai logo depois da escolha da arte.
- Rodar `fase5_sim.py` antes do balanço da 6c2.
- Avisar os testadores que a saída do John é discreta de propósito (sem dizer quando acontece). O texto do John no mural da 6c2 ("foi seguir o rumo dele") espera a resposta deles.

## Como a equipe trabalha (lembretes práticos)
- Modelos: pensadores (Diretor de Jogo, Designer, Diretor de Arte, Artista, Diretor de Cutscenes) em Opus médio; executores (Programador, UI/UX, Roteirista, QA) em Sonnet. Fable não é usado. Na 6c2, o Designer usa raciocínio **alto** só no design da Honra.
- **Sessão em worktree:** os agentes só podem escrever dentro do worktree da sessão (um hook bloqueia `E:\Fightclicker`). Passe o caminho do worktree nos pedidos e `--path` do Godot nele (com `--import` antes).
- **Pasta principal `E:\Fightclicker`:** está na branch `fase-6c` com uma cópia **antiga e incompleta** da 6c1, nunca commitada. A versão certa está na main. Antes de usar essa pasta: descartar essas mudanças e voltar para a main (pedir ao dono).
- Commits: o worktree não tem identidade git; use `-c user.name=DeivityAndrade -c user.email=DeivityAndrade@users.noreply.github.com`.
- Testes sempre com `APPDATA` numa pasta temporária; janelas com `--position 1950,40`; telas passam pela skill `alinhamento-ui` até 0 problemas.
