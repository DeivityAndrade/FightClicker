# Fase 6c2 — Mais longe que eu: escopo

Dono: Diretor de Jogo. Data: 2026-11-16.
Base: `PROMPT.md`, `docs/estado-atual.md`, `fase6c1-revisao.md` (OBS-C), `fase6c1-design.md`, `fase6c1-api.md`, `data/escola.json`, `data/ui_texts.json`.

## Visão

A academia deixa de ser só um local de treino e vira o **coração da linhagem**. O mural na parede registra quem passou por ali; a Honra transforma vitórias e marcos em progresso permanente dentro da campanha atual; o símbolo no peito mostra que o lutador pertence àquela escola. A sensação é de pertencimento e continuidade: "outros vieram antes, eu sigo adiante, e meu nome fica".

Tom pé no chão com escala emocional: nada de medalhas brilhantes ou fanfarra. O mural é tinta e prego; a Honra é respeito medido em atos; o símbolo é discreto. Tudo original, sem copiar sistemas de prestígio ou árvores de talento genéricas de outros incrementais.

## O que entra

| # | Item | Justificativa |
|---|---|---|
| 1 | **Mural na academia** (`mural_spot`) | Fecha o arco da saída do John ("foi seguir o rumo dele") e dá suporte visual à linhagem. Texto depende da resposta dos testadores sobre a saída discreta (§8). Inclui estados de `ui_audit` da foto e hover `old_photo_gym` (OBS-C da revisão 6c1). |
| 2 | **Sistema de Honra** | Nova mecânica de progressão intra-campanha. Recompensa feitos (vitórias, recordes, marcos) com bônus temporários ou permanentes na campanha atual. Diferente de Legado (que é entre campanhas). Designer usa raciocínio **alto** aqui. |
| 3 | **Árvore do hall** | Interface para gastar Honra. Nós visuais, desbloqueáveis, ligados ao mural e ao símbolo. Não é árvore de talento genérica: cada nó conta uma história da escola. |
| 4 | **Bônus de retrato** | Hover na foto antiga revela texto contextualizado por campanha/marco. Reforça identidade e memória sem custo de sistema novo. Entra junto com o mural (mesma parede). |
| 5 | **Falas de mentor (recorde e revanche)** | Mentores comentam quando o discípulo bate recorde pessoal ou vence alguém que já derrotou o mentor. Dá voz à linhagem sem cutscene nova. Dados em `dialogos.json`, gatilhos leves. |
| 6 | **Símbolo da escola** | Sprite pequeno no peito do lutador na academia. Visual puro, sem efeito mecânico. Marca pertencimento. Diretor de Arte define forma e paleta. |
| 7 | **Estados de `ui_audit` (foto + hover)** | OBS-C da revisão 6c1: foto reta/torta e hover `old_photo_gym` precisam de estados auditáveis. Entram agora porque a parede recebe o mural; fazer separado seria retrabalho. |

## O que fica de fora

| Item | Motivo | Entra em |
|---|---|---|
| Voz dos mentores | Depende de gravação/sintetizador externo; não bloqueia a mecânica de falas. | Fase futura (voz/narrativa avançada) |
| "Igual ao anterior" na criação de discípulo | Feature de UX, não ligada ao tema da 6c2. | Fase de polimento/UX |
| Comentário do Osmar sobre a saída na volta à garagem | Só se os testadores não perceberem a saída (§8). Condicional, não certo. | 6c2 (condicional) ou 6c3 |
| Novos geradores passivos | A 6c2 é narrativa/mecânica leve, não econômica. Geradores ficam para fases de gestão. | Fase de gestão pós-hall |
| Segunda arte / MMA | Pertence ao sistema de prestígio/Legado, não à Honra intra-campanha. | Fase de prestígio (camada 4) |
| Conquistas Steam | Integração externa, postergada até fase Steam. | Fase 9 |
| Balanço econômico/luta | Nenhum número muda nesta fase. Simulação deve bater idêntica à 6c1. | — |

## Critérios de aceite

1. Mural visível na academia após marco `cena_saida_primeiro_mentor` ou `cena_primeira_academia` (qualquer que venha primeiro).
2. Texto do mural reflete estado da linhagem: cita John se ele saiu, cita último mentor se houve sucessão.
3. Hover na foto antiga exibe texto `old_photo_gym` na academia e `old_photo` na garagem, com estados cobertos pelo `ui_audit`.
4. `ui_audit` passa com 0 problemas incluindo estados novos (foto reta/torta, hover, mural vazio/preenchido).
5. Sistema de Honra acumula pontos por feitos verificáveis (vitória, recorde, marco); saldo visível na árvore do hall.
6. Árvore do hall abre, mostra nós compráveis com Honra, aplica bônus imediatamente na campanha atual.
7. Bônus da árvore **não** persistem entre campanhas (diferente de Legado).
8. Falas de mentor (recorde/revanche) tocam nos gatilhos certos, respeitam regra "só fala quem está desenhado" e não travam o loop.
9. Símbolo da escola aparece no sprite do lutador apenas na academia, sem efeito em atributos.
10. Save v12 sem migração: marcos e dados novos da 6c2 cabem na estrutura existente de `escola.milestones` ou blocos `_6c2`.
11. Balanço inalterado: `fase5_sim.py` e testes comparativos no Godot batem idênticos à 6c1.
12. Cena do mural (se houver) ≤ 15 s, pulável em ≤ 0,3 s, relógio parado durante ela.
13. Testes verdes em save de teste, janela no 2º monitor (`--position 1950,40`).

## Dependências

- **6c1 integrada:** cena da academia, saída do John, Osmar na academia, foto, mentores por local. Sem isso, mural e falas não têm base.
- **Resposta dos testadores (§8):** texto do mural depende da pergunta 3 da revisão 6c1 ("perceberam a saída?"). Design pode começar; texto final espera.
- **Designer em effort alto:** sistema de Honra exige raciocínio elevado. Não adiantar sem esse design.
- **Diretor de Arte:** símbolo da escola e integração visual do mural/hall dependem de direção visual coerente com §25 da `direcao-visual.md`.
- **Roteirista:** textos do mural, hover e falas de mentor precisam de tom consistente com `direcao-narrativa.md`.
- **Skill `alinhamento-ui`:** qualquer mudança em tela (mural, árvore, hover) passa pela skill até 0 problemas.

## Nota para o Designer

- **Honra:** use raciocínio **alto**. Defina fontes de Honra, custos da árvore e bônus de forma que: (a) recompense jogo ativo e passivo sem criar decadência/bloqueio; (b) seja distinto de Legado (intra-campanha vs. entre campanhas); (c) escale com o tom (começa modesto, fica absurdo nas campanhas tardias). Documente fórmulas e justificativas em `fase6c2-design.md`.
- **Mural:** especifique estados (vazio, com John, com N mentores, com símbolos) e como o `ui_audit` cobre cada um. O texto "foi seguir o rumo dele" é placeholder até a resposta dos testadores; prepare variante caso eles não tenham percebido a saída.
- **Árvore do hall:** defina nós, pré-requisitos e efeitos. Cada nó deve ter nome e descrição diegéticos (não "+10% dano", mas "respeito do bairro: seus socos ecoam"). Efeitos mecânicos são secundários à narrativa.
- **Falas de mentor:** liste gatilhos exatos (ex.: `personal_record_strength`, `revenge_win_vs_X`) e condições (mentor desenhado, intervalo mínimo). Não crie falas novas para esta fase; use as existentes ou peça ao Roteirista.
- **Bônus de retrato:** defina variações de texto por marco/campanha. É leitura, não mecânica.

## Decisões do dono (2026-11-16)

1. **Texto do mural:** explícito — "foi seguir o rumo dele". Fecha a narrativa da saída discreta e dá resposta aos testadores.
2. **Árvore do hall:** já ramificar por arte agora. Onde não houver conteúdo futuro planejado, usar placeholder "em breve". Não esperar pela 6c3.
3. **Símbolo da escola:** nasce pronto na 6c2. Fixo, sem evolução visual. Identidade definida de uma vez.

## Resumo para o Produtor

- A 6c2 transforma a academia em coração da linhagem: mural, Honra, árvore do hall, símbolo e falas de mentor. Tom pé no chão, identidade original.
- Nada de balanço, geradores novos ou sistemas de fases futuras. Save v12 sem migração.
- O Designer usa raciocínio alto só na Honra; o texto do mural espera resposta dos testadores sobre a saída do John.
- Critérios de aceite incluem `ui_audit` 0 problemas (com estados novos), balanço idêntico à 6c1 e testes no 2º monitor.
- Três perguntas abertas para o dono antes de fechar o design: texto do mural, ramificações da árvore e evolução do símbolo.