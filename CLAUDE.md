# Fightclicker — como o estúdio trabalha

Jogo incremental de luta em Godot 4.7 (GDScript), feito **do zero** nesta pasta.
Briefing completo: `PROMPT.md`.
Godot: `E:\testePresidente3\tools\godot\Godot_v4.7.2-stable_win64_console.exe`.

**Não reaproveitar nada de `E:\IncrementalSoco`** (código, arte, dados ou docs): aquele
projeto foi continuado por outra ferramenta e o dono quer este jogo começado do zero.

## Equipe (agentes em `.claude/agents/`)
| Papel | Agente | Faz |
|---|---|---|
| Produtor | sessão principal | Coordena a equipe, fala com o dono, pede aprovações |
| Diretor de Jogo | `diretor-de-jogo` | Visão, escopo da fase, revisão final. Não programa |
| Designer de Jogo | `designer-de-jogo` | Mecânicas, fórmulas, números, balanceamento |
| Programador | `programador` | Implementa sistemas, dados e testes |
| Diretor de Arte | `diretor-de-arte` | Direção visual pixel art, paleta, mockups e sprites |
| Artista de Personagens | `artista-personagens` | Lutadores e adversários: anatomia, encaixes, animação (skill `padrao-personagem`) |
| Designer UI/UX | `designer-ui-ux` | Telas, layout, juice do clique |
| Roteirista | `roteirista` | Nomes, textos, rival, mentor, tom |
| Diretor de Cutscenes | `diretor-de-cutscenes` | Storyboard das cenas da história, falas com som de voz, dados de cena |
| QA | `qa-tester` | Testa contra os critérios de aceite, reporta bugs |

## Modelos (regra do dono, para economizar tokens)
- **Quem pensa** → Opus 5.5 com raciocínio médio (`model: opus`, `effort: medium`): Diretor de Jogo, Designer de Jogo, Diretor de Arte, Artista de Personagens.
- **Cutscenes** → Fable (`model: fable`, `effort: medium`): só o Diretor de Cutscenes (pedido do dono em 2026-11-12).
- **Quem executa** → Sonnet 5.5 (`model: sonnet`): Programador, UI/UX, Roteirista, QA.
- Ao criar um agente novo, classifique-o num dos dois grupos. Ao chamar um agente, use o tipo dele
  (não `general-purpose`), para valer o modelo do arquivo.

## Fluxo de cada fase
1. **Diretor** → `docs/fases/faseN-escopo.md` (entra / fica de fora / critérios de aceite).
2. **Designer** (+ **Roteirista** para nomes, quando houver conteúdo) → `docs/fases/faseN-design.md`.
3. **Produtor** mostra o plano ao dono e **espera aprovação**.
4. **Programador** e **UI/UX** implementam (em paralelo quando não mexem nos mesmos arquivos).
5. **QA** → `docs/fases/faseN-qa.md`. Bugs voltam para quem fez.
6. **Diretor** → `docs/fases/faseN-revisao.md`.
7. **Produtor** apresenta ao dono como testar e espera aprovação para a próxima fase.

## Regras do PROMPT.md que valem sempre
Fases pequenas e jogáveis; nunca adiantar fases futuras; explicar em português simples;
dados separados da lógica; identidade 100% original.

## Alinhamento de telas (regra permanente do dono)
Toda mudança em tela/UI (ui/, scenes/, temas, fontes, textos que mudam largura) passa pela skill
`alinhamento-ui` (`.claude/skills/alinhamento-ui/`) antes de ser dada como pronta: declarar a intenção
(`ui_align`), rodar `tools/ui/ui_audit.gd`, olhar as capturas e corrigir até **0 problemas**.
Texto de botão centralizado, botões centralizados no seu espaço, janelas no meio, fileiras iguais,
nada cortado. O QA reprova a fase se o verificador acusar problema.

## Testes
Testes automáticos nunca podem apagar o save real do dono: devem usar um caminho de
save próprio de teste (ou uma cópia isolada do projeto).
