# Fase 7a1 — Cada arte luta do seu jeito: revisão do Diretor

Diretor de Jogo, 2026-11-19. Base: `PROMPT.md`, `fase7a-escopo.md` (inclusive §8, decisões do dono), `fase7a1-design.md`,
`fase7a1-qa.md`, correções feitas depois do QA (B1–B9) e leitura pontual de `data/ui_texts.json` e `ui/tela_luta.gd`.

## Veredito
**Aprovado, com 1 ajuste pequeno recomendado antes de mostrar ao dono (A1).** Todos os critérios da 7a1 (1–6, 13, 14) passaram;
os 3 bugs médios do QA (B1–B3) e os baixos (B4–B9) foram corrigidos; testes verdes; `ui_audit` com 401 estados e 0 problemas.

## O que bate com o pedido do dono (§8)
- **Boxe — Mão rápida:** K.O. cresce com AGILIDADE e com o embalo (0–5, zera na esquiva); cansa no 3º round; Agressivo acaba cedo e
  leva contragolpe. Exatamente a "tática agressiva acaba cedo, mas arrisca contragolpe".
- **Jiu-jitsu — Finalização:** a barra de pegada enche por round; RESISTÊNCIA para chegar, FORÇA para fechar; Defensivo enche mais rápido.
- **Focos com "certo" diferente por arte** (§6.1 do design) e **nós ESTILO reforçando a passiva** (Contragolpe: K.O. +50%; Base firme: pegada +50%).
- **Prévia mostra embalo/pegada e a chance real**, e muda com a tática. Honesta: 36 de 36 células a ≤ 2 pontos (meta ±5).
- **Arena GINÁSIO ALVORADA** (opção A): Tonhão e Kid lá; os 4 amadores ficam na borracharia. Fim depois de derrota com arena (pendência 5.4/B2) fechado.
- **Passiva dos adversários ficou para a 8a**, como o dono decidiu.
- **"EMBALO" fica no Boxe; o bônus do minigame será AQUECIDO**: o conflito de nomes que o Designer apontou está resolvido.

## O que ficou bom
- A diferença entre as artes é de **jeito**, não de número: Boxe ganha na frente e cedo, Jiu-jitsu vira luta difícil no fim.
- Os traços +10%/−10% saíram em vez de somar: nenhuma arte ficou mais forte que antes.
- Sem arte, nada mudou (foto igual à main; só as diferenças esperadas dos nós e da arena).
- Balanço: Boxe × JJ a 0,8–2,0% no tempo até o Kid; o JJ deixou de ficar "1 campanha atrás" a 3/s (1,91 → 1,56 campanhas).
- Lutas continuam curtas (8 a 19 s). Tonhão finalizado em ~60% das vitórias do JJ (meta: 1 em 3).
- A derrota explica a passiva ("VOCÊ CANSOU", "ELE ESCAPOU 1 VEZ", etc.) sem simulação nova.
- Pé no chão: ginásio de bairro, empurrão no clinch, queda e luta no chão. Nada copiado.

## Nada da 7a2 foi adiantado
- Nenhum convite, minigame, Choque, Panfletagem nem Gato Preto em `scripts/`, `ui/`, `data/` ou `scenes/`.
- Única semente: a chave `bonus_warm_name: "AQUECIDO"` em `data/ui_texts.json`, **sem uso no código**. É só o nome decidido pelo dono;
  pode ficar (não muda nada no jogo).

## Ajuste recomendado antes de mostrar ao dono
- **A1 — O especial dos cliques no Jiu-jitsu ainda é "SUPER UPPERCUT!".** No chão o golpe virou `ground_pressure` (B2), mas o letreiro
  continua "SUPER UPPERCUT!"; e **em pé, antes da queda, o lutador de JJ ainda dá um uppercut de boxe**. É o único golpe de boxe que sobra
  no JJ e quebra o "o testador diz a arte só olhando". Correção pequena, só visual:
  - Roteirista: 1 texto para o especial do JJ (ex.: "PEGADA DE FERRO!"), chave própria no `ui_texts.json`;
  - UI/UX: com Jiu-jitsu, o especial em pé usa `clinch_push` (ou `takedown`, se a fase permitir) e o letreiro do JJ; no chão, o mesmo letreiro.
  - Não muda número, prévia nem save. Rodar `alinhamento-ui` de novo.

## Pendências registradas (não bloqueiam)
- **R1 — prévia por estado isolado:** a média é honesta, mas um estado raro pode errar a cor (verde/amarelo) por uma faixa. Aceito;
  rever na 8a com as passivas dos adversários.
- **R2 — p90 do JJ:** 1 em 10 jogadores de JJ leva uma campanha a mais até o Kid (média dentro dos 15%). Acompanhar na 8a.
- **R3 — Kid fácil a 4/s (~92%):** melhorou (era ~96%), resto vai para a 8a (passiva do Kid). Correto não mexer agora.
- **Texto (opcional, Roteirista):** a dica "PEGOU, MAS NÃO FECHOU. FORÇA NO SACO" tem duplo sentido em português. Se o dono não
  quiser a piada, trocar por "FORÇA NO SACO DE PANCADA".
- **`bjj_grip_late`** não apareceu numa tela real no QA (só no teste lógico). Texto curto; risco baixo.

## O que o dono deve testar com as próprias mãos (~15 min, com um save que já tenha arte)
1. **Boxe, Agressivo, contra o Tonhão:** ver as 5 bolinhas de embalo acendendo, o K.O. no 1º/2º round com "EMBALO N".
   Perder uma de propósito no Agressivo contra o Kid e ler a nota do contragolpe.
2. **Boxe, Defensivo:** a prévia diz "CANSA MENOS"; a luta vai mais longe e não aparece "CANSADO".
3. **Jiu-jitsu, Defensivo, contra o Tonhão:** empurrão em pé, "PEGADA!", a queda inteira (sem corte), os dois no chão, "FINALIZOU!"
   com o adversário batendo. Fazer combo alto para ver o especial no chão (e conferir o A1).
4. **Prévia:** trocar de tática e ver a linha da passiva e o "N EM 10 VITÓRIAS" mudarem.
5. **Arena:** Tonhão e Kid no GINÁSIO ALVORADA; um amador ainda na borracharia.
6. **Pergunta para ele:** olhando só a luta, dá para saber a arte? Boxe e Jiu-jitsu parecem jeitos diferentes de jogar, ou só números?

## Resumo para o Produtor
- **7a1 aprovada.** Boxe luta rápido e vence por K.O. com embalo (cansa no 3º round); Jiu-jitsu luta lento, leva ao chão e vence por
  finalização com a pegada. Arena GINÁSIO ALVORADA na liga da academia.
- Prévia continua honesta (≤ 2 pontos), as artes estão equilibradas (≤ 2% no tempo até o Kid) e sem arte nada mudou.
- **1 ajuste pequeno recomendado:** o especial dos cliques no Jiu-jitsu ainda aparece como "SUPER UPPERCUT!" (e uppercut em pé).
- Nada da 7a2 foi adiantado (só o nome AQUECIDO guardado nos textos, sem uso).
- O dono deve jogar Boxe Agressivo e Jiu-jitsu Defensivo contra o Tonhão e dizer se sente as artes diferentes.
