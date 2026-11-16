# Onde paramos (atualizado em 2026-11-16, fim do dia)

Documento do Produtor para retomar noutra sessão/conta. Vale sobre memórias antigas.

## Situação agora
- **Pasta de trabalho:** `E:\Fightclicker` (pasta principal), branch **`fase-6c2`**, enviada ao GitHub. O worktree antigo `.claude/worktrees/agents-subagents-setup-7a8cc6` e as pastas temporárias `%TEMP%c_pr14` / `fc_main` sobraram (limpas; podem ser removidas com `git worktree remove --force`). A branch local `backup/6c-copia-antiga` guarda a cópia velha da 6c1 — não usar.
- **Na main:** fases 1 a 6c1, correção da 6c1 (PR #13) e o **PR #14 do Matheus** (K.O. no quadro certo, simuladores, testes de queda e soak).
- **6c2 "Mais longe que eu": pronta e testada, falta só a revisão do Diretor e integrar.**
  - Feito: design (Designer em raciocínio alto), textos, arte (mural, retratos, símbolo, ícones), lógica (Honra, hall, retrato, mural, falas de mentor, símbolo, save v13), telas.
  - QA (`docs/fases/fase6c2-qa.md`): aprovou com ressalvas; **B1–B6 corrigidos** (PAROU NUMA LUTA, símbolo nas costas na luta, mural vazio, seta apagada, plaquinha "beto", linha FALTA pelo atributo destacado).
  - Verificado no fim: `tools/run_tests.ps1` **TODOS OS TESTES PASSARAM** (APPDATA temporário); `ui_audit` 358 estados, 0 problemas (2 rodadas).
  - **Falta:** (1) Diretor escrever `docs/fases/fase6c2-revisao.md` (parou no limite de uso; pedido: decidir se fecha a 6c, perguntas aos testadores, o que vai para o pixel artist, o que vem na 7a); (2) abrir PR de `fase-6c2` para a main e integrar (o dono deixa integrar sempre).
- **Atenção:** 13 PNGs de `assets/sprites/opponents/opp_leslie/` aparecem modificados e **não foram commitados** (origem desconhecida, provavelmente um gerador rodado por agente). Conferir com `git diff --stat` antes de commitar ou descartar.
- **Próxima fase:** 7a — Lutas por arte (Boxe e Jiu-jitsu lutam diferente, habilidades passivas, arena da academia).

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
