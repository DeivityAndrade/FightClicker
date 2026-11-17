# Onde paramos (atualizado em 2026-11-16)

Documento do Produtor para retomar o trabalho noutra sessão. Vale sobre memórias antigas.

## Fases
| Fase | Situação |
|---|---|
| 1 a 6b2 | Na main. |
| **6c1 — Casa nova** | Na main (PR #12): cena da 1ª chegada à academia, saída discreta do John, caixote do mentor na academia, Osmar/foto/mentores por local, comentário da arte, 7 sons novos, cenário e poses. QA e Diretor aprovaram (`docs/fases/fase6c1-qa.md`, `fase6c1-revisao.md`), inclusive com cópia do save real. |
| **Correção da 6c1** | Na main (PR #13 integrado). Poses de carga sem atravessar, foto torta→reta aprovadas pelo QA e Diretor. Revisão pós-6c1 também integrada (PR #14). |
| **6c2 — Mais longe que eu** | **Iniciando.** Diretor de Jogo definindo escopo. Mural, Honra, árvore do hall, bônus de retrato, falas de mentor (recorde/revanche), símbolo da escola. OBS-C da revisão da 6c1 entra aqui: estados de `ui_audit` da foto e hover `old_photo_gym` junto com o mural. |

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
