# Fase 7a2 (Treino fora de hora) — relatório do QA

Branch `fase-7a2`, sem commit. Tudo com `APPDATA` temporário; o save real do dono não mudou (SHA-256 antes e depois iguais). Um Godot por vez; janela só no `ui_audit` (`--max-fps 30 --position 1950,40`). Worktree temporário de `origin/main` (fba7439) criado e removido.

## Veredito
**Quase pronto: 1 bug de severidade média (B1) precisa de decisão/correção antes do Diretor.** Todo o resto passa.

## Automáticos
| Item | Resultado |
|---|---|
| `tools/run_tests.ps1` | **OK** — "TODOS OS TESTES PASSARAM" (inclui `tests/test_fase7a2.gd`, guarda do save real, cena principal) |
| Cena principal `--quit-after 300` (headless) | **OK** — 0 ERROR |
| `ui_audit --estados todos` (com janela, uma vez) | **OK** — `ESTADOS 430 \| PROBLEMAS 0`; capturas em scratchpad `caps/` (f7a2_* conferidas) |
| `validar_cenas` | **OK** — 0 erros, 0 avisos, 0 pendências |
| Foto `foto.gd` (7a2 x `origin/main`) | **OK** — `cmp` idêntico (247.818 bytes) |
| Simulador `fase7a2_sim.py forca ident` (Blender Python, `-I`) | **OK** — maior ganho em dias de campanha: **9,2%** (Boxe 3/s, Muralha, todos_max); Kid 3,7–5,7%; `ident` = 80/80 idênticas. `campanha` não rodado (só forca/ident) |

## Por item do pedido
1. **Convite do Osmar — OK.** 300 s / 240 s / some em 60 s sem acumular (teste do Programador + meus). Escondido e relógio parado com fim pendente, sucessão, saída do John, toque, gesto de calçar, janela, luta; não abre no dia da luta (mesmo com relógio vencido: `qa_f7a2_extra`); academia sem a cena = Osmar ausente, relógio parado; MUDAR fecha; alternância e elegibilidade (sem arte só Panfletagem; sem `garage_saved` só Choque; 1ª carreira antes do cinturão nada). Clique no Osmar = IR: conferido no código (`ui/garagem.gd:241`), não por clique real. Caixa abrindo: só na UI (`sala.gd:1290`), capturas `f7a2_balao_espera` sem problema. Observação: a cena `cena_sala` testada com 30 s de tick foi limpa pela trava de segurança do jogo (artefato do meu teste, refeito com 4 s: ok).
2. **Choque — OK.** SAIR em 0, 1, 2, 2,02, 10, 29,98, 30, 31 s nas duas artes: sempre prêmio > 0, nota ≥ 0,25, sala devolvida. 5000 apertar/soltar no mesmo quadro, `passo(NaN/INF/-5/1e9)`, entrada depois do fim: sem quebrar, barra e fôlego finitos. 9/s rende menos que 4,3/s (teste do Programador). Foco: `TelaTreino._notification` solta o botão em `FOCUS_OUT` e `_input` solta no release (código lido; não reproduzi perda de foco real). Níveis (jogador simples que lê avisos, 60 partidas): Boxe vence 100% nos níveis 0–3 e 93% nos 4–5; JJ 100% no 0 e 71% no 5 — dificuldade sobe, mas o Boxe é folgado.
3. **Panfletagem — OK.** Erro custa 0,5, nunca < 0; mão ocupada 0,35/0,8 s; sinal falso some na metade; contador "N DE 10". FAMA cheia e piso nos 6 adversários = tabela (5/8/15/25/30/50 e 1/2/4/6/8/13). Ler o sinal (14,0–14,6 líquidos) x clicar em todos (0): ler vence em todos os níveis. **Enfeite fixo não entrega**: `(id*7+tipo)%3` na tela é independente do interesse (36,1% x 36,2% de interessados em "fone/celular" x "andando normal", 200 partidas) e `pessoas()` não expõe interesse nem falso.
4. **Relógio — OK.** `segundos_campanha` não muda no minigame e o Treino sobe exatamente `produção x tempo` (dev test); nada de fala/gesto/cena nasce durante o minigame; voltar não dispara fala acumulada. **Ressalva: B1** (tela de prêmio).
5. **AQUECIDO — OK.** Ícone no HUD e linha na prévia (capturas `f7a2_hud_aquecido`, `f7a2_previa_aquecido`: "AQUECIDO: +3% NOS ATRIBUTOS (+N NA CHANCE)"). Honestidade medida: estado com chance 0,52 → prévia 0,520 sem / 0,935 com; 1500 lutas reais pelo motor: 0,500 / 0,933; "+41" na prévia x +43,3 medido. `warm_gains` por tática coerente. Gasto na luta (x1,03 uma vez só, não x1,0609); não soma; zera na nova campanha. Nota: em estado íngreme +3% vale +41 pontos de chance (o design dizia +6 a +12 em média, máximo +32); é honesto, mas o Diretor pode querer saber.
6. **Gato Preto — OK.** Recorte só na campanha 2+ com `garage_saved`, garagem e academia (depois da cena), hover amplia (`f7a2_recorte_garagem`); boato uma vez na abertura da Panfletagem; visual é um gato preto de silhueta com lua e jornal "VULTO MASCARADO", sem cara de Batman (grep por batman/morcego/gotham: nada).
7. **Save — OK.** Sem `training_invite`: abre com padrões. Sujo (null, lista, string, negativos, 1e400, tipos trocados, `open_since` no futuro): sempre carrega com convite válido e segue estável. Fechar no meio do minigame: coberto pelo dev test (volta à sala, sem prêmio, nada em dobro). IR duas vezes e concluir/voltar repetidos: nada em dobro. Prêmios com valores gigantes e FAMA no teto ficam finitos/limitados. Aviso do Godot "Exponent too high" ao ler `1e400` vem do parser JSON, inofensivo.
8. **Ignorar = mesmo jogo — OK** (foto idêntica; sim 80/80; teto 9,2% < 10%, com margem pequena).
9. **Automáticos — OK** (tabela acima).
10. **Poses — OK pelas capturas e pelo código.** Sem `flip`/`scale.x` nas telas; o "R" do calção/camisa lê normal; no JJ o discípulo tem `z_index` 320 sobre o parceiro 318 (`tela_choque.gd:357`) e aparece por cima (`f7a2_choque_jj_rajada`).

## Bugs
**B1 — média — Tela de prêmio parada rende produção grátis com o relógio parado (fura o teto de 10%).**
Passos: IR no Choque, SAIR (ou fim), NÃO clicar VOLTAR e deixar a tela aberta. Resultado (`tests/qa_f7a2_extra.gd`, `_tela_de_premio_parada`): em 100 s a equipe produziu 100 s de produção (prod 30/s) com `treino_fora="spar"` e `segundos_campanha` parado; só devolve a sala na trava de 120 s (`scripts/estado/treino_fora.gd:8`, `_tick_fora` produz mesmo com `fase == "fim"`). O design/simulador contam ~38 s fora por convite; deixar 120 s dá ~3x isso e pode passar de 10% (já são 9,2% no pior caso com 38 s). Correção sugerida: no `_tick_fora`, parar a produção quando `j.fase == "fim"` (ou contar só até o fim do jogo). Quem corrige: Programador (`treino_fora.gd`); Designer confirma se a produção na tela de prêmio deve valer.

**B2 — baixa (cosmético) — "ELE ENCOSTOU" cai em cima de uma placa da parede no Choque.** Em `f7a2_choque_boxe_pausa.png` e `f7a2_choque_jj_rajada.png` o texto flutuante cobre a placa "UOTI/VAI" (legibilidade ruim). O verificador não acusa. Quem corrige: UI/UX (subir o texto ou dar contorno/fundo).

## Riscos / não coberto
- Perda de foco da janela com o botão apertado não foi reproduzida de verdade (só leitura do código).
- Seção `campanha` do simulador (tempo real com calendário) não foi rodada; só `forca` e `ident`.
- Margem do teto é pequena (9,2% x 10%): qualquer aumento de `max_seconds`/`attr_bonus` exige rodar o simulador de novo.
- Os testes extras ficaram em `tests/qa_f7a2_extra.gd` e `tests/qa_f7a2_panf.gd` (o último "FAIL" de `qa_f7a2_panf` — convite aberto às 400 s — é artefato: o balão de 300 s já tinha sumido aos 360 s; o dev test cobre).
