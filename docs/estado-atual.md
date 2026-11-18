# Onde paramos (atualizado em 2026-11-16, fim do dia)

Documento do Produtor para retomar noutra sessão/conta. Vale sobre memórias antigas.

## Situação agora (2026-11-18)
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
