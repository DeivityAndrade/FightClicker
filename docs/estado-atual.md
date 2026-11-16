# Onde paramos (atualizado em 2026-11-16)

Documento do Produtor para retomar o trabalho noutra sessão. Vale sobre memórias antigas.

## Fases
| Fase | Situação |
|---|---|
| 1 a 6b2 | Na main. |
| **6c1 — Casa nova** | Na main (PR #12): cena da 1ª chegada à academia, saída discreta do John, caixote do mentor na academia, Osmar/foto/mentores por local, comentário da arte, 7 sons novos, cenário e poses. QA e Diretor aprovaram (`docs/fases/fase6c1-qa.md`, `fase6c1-revisao.md`), inclusive com cópia do save real. |
| **Correção da 6c1** | Branch `fix/6c1-carga-foto`, PR aberto, **ainda não integrado**. Ver abaixo. |
| **6c2 — Mais longe que eu** | Liberada pelo Diretor, não começada. Mural, Honra, árvore do hall, bônus de retrato, falas de mentor (recorde/revanche), símbolo da escola. |

## A correção da 6c1 (o que o dono pediu em 2026-11-16)
1. **Poses de carga atravessando objetos** (mão no caixote, cabeça no saco). O Artista refez em camadas: braço de trás → objeto → braço/mão da frente; saco menor no ombro; esteira dobrada reconhecível. O gerador `tools/art/make_sprites_fase6c1.gd` ganhou uma conferência automática de atravessamento (`cross_check`): 101 quadros, 0 px com problema. Mesmos tamanhos, quadros e pivôs.
2. **Foto: o Osmar desentorta em vez de entortar** (decisão do dono). A foto entra torta, ele acerta a moldura, "agora sim."; fica reta na academia para sempre (`data/escola.json` `gym.tilted = false`). `coach_nudge_photo` com o dedo subindo. Textos novos: `cl_ac_chegada_2` "reta agora. casa nova." e o hover `old_photo_gym` "A foto veio da garagem. / Era torta. Aqui ficou reta.".
3. Verificado antes do PR: `tools/run_tests.ps1` todo verde (3200 PASS), validador de cenas 0 erros (chegada 12,90 s presos).

**Falta para fechar a correção:**
- O **QA** estava testando quando a sessão parou (seção "Correção: carga e foto" no fim de `docs/fases/fase6c1-qa.md`, capturas `docs/arte/mockups/fase6c1_ui_*.png`, `ui_audit` com os textos novos). Se essa seção não estiver no PR, rodar o QA de novo com o mesmo pedido: olhar ampliado A1–A5 da chegada e a bolsa na saída, procurando atravessamento, objeto flutuando ou pulando, e a foto torta→reta; `ui_audit` com 0 problemas.
- **Revisão rápida do Diretor** da correção.
- Integrar o PR na main (o dono deixa integrar PR sempre).

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
