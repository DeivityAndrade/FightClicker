# Polimento 1: escopo

Diretor de Jogo, 2026-11-27. Base: `docs/fases/polimento1-ideias.md` (itens 1 a 10, retorno do dono jogando).
Entra **antes** da implementação da 8b1 (o design da 8b1 já está na main e será remedido depois do P1b).

## Objetivo
Deixar o que o jogador sente toda hora mais limpo e mais gostoso, e dar mais coisa para comprar, sem abrir sistema novo de fase futura.
**Sensação:** "a tela ficou legível, o crítico estoura, cada arte tem seu aparelho que vale a pena, e sempre tem algo para comprar".

## Já feito
- **Item 5 (caixote invisível):** corrigido no PR #59 (`fix/caixote-invisivel`). Fica só no reteste do QA no P1a (campanha 2 e 3).

## Ordem das subfases
| # | O quê | Por que nesta posição |
|---|---|---|
| **P1a** | Números (só o crítico grande) + chão do Jiu-jitsu | É o que o dono vê a cada clique; só visual, risco baixo, sai rápido |
| **P1b** | Aparelhos das artes + equilíbrio D1 | Mexe na economia do centro; tem de vir antes de qualquer compra nova e antes da 8b1 |
| **P1c** | Árvore: zoom/arrastar + compra com o Legado guardado no meio da campanha | Regra nova e tela nova, ainda com os nós de hoje; o zoom precisa existir antes de a árvore crescer |
| **P1d** | Mais conteúdo: árvore maior e mais funda (com o auto-clique), mais loja, mais equipe | Muda a curva inteira; mede tudo junto, uma vez, sobre a economia já acertada |

Cada subfase é um PR, testado pelo QA e jogável sozinho. Depois do P1d: remedir a 8b1 (§9 e §10 do design) e só então implementá-la.

---

## P1a: números e chão do Jiu-jitsu (só visual)
**Entra**
- Números pipocando: normal **pequeno**, crítico **grande**. Vale para sala, aparelhos das artes (mesmo padrão dos outros aparelhos), auto-soco e luta.
- Na luta, "grande" só no golpe que o motor já marca como crítico/forte. Nenhuma regra nova de crítico.
- Jiu-jitsu com animação própria de chão quando o adversário cai: raspar, passar a guarda, montar, finalizar. Nada de soco no boneco caído.
- Reteste do caixote (item 5).

**Fica de fora**
- Qualquer mudança de número, chance ou dano (P1b/P1d).
- Animação de chão para outras artes (Fase 13, polimento geral, se o dono pedir).

**Critérios de aceite**
1. Em 30 s de clique na sala, só os críticos aparecem grandes; os normais ficam pequenos e a tela continua legível (captura do QA com clique rápido + Metrônomo ligado).
2. Os aparelhos do Boxe, do Jiu-jitsu e do Muay Thai usam o mesmo tamanho e estilo de número dos outros aparelhos.
3. Na luta, o número grande aparece só nos golpes críticos/fortes; os outros saem pequenos.
4. Com o Jiu-jitsu, o adversário caído recebe a sequência de chão (as 4 posições), no estilo e acabamento da arte do jogo; nenhum soco em quem está no chão.
5. `tools/refatoracao/foto.gd`: foto idêntica antes e depois.
6. `ui_audit` nas telas mexidas: 0 problemas.
7. Campanha 2 e 3: o ajudante nunca aparece em pé num caixote invisível.

**Quem faz:** UI/UX (números) · Diretor de Arte + Artista de Personagens (chão do JJ, amostra ao dono antes do elenco) · Programador (encaixe da animação) · QA.
Sem design de números: o Designer só confere que nada mudou.

---

## P1b: aparelhos das artes e equilíbrio D1
**Entra**
- Designer diagnostica por que os aparelhos das artes não dão vontade (ganho, custo, papel próprio, retorno na tela) e propõe o que faz o jogador querer cada um.
- Cada aparelho de arte com um papel claro e diferente dos aparelhos comuns, ligado ao jeito da arte.
- Ressalva D1 da 8b1: o Jiu-jitsu não pode crescer ~2,5× mais que Boxe e Muay Thai no centro (o bônus da equipe da arte multiplicando os Alunos). Corrigir na economia, não no adversário.

**Fica de fora**
- Aparelhos novos (P1d, se o Designer achar que faltam).
- Mudar os nacionais da 8b1 (eles são remedidos depois do P1d).

**Critérios de aceite**
1. Com o simulador, a renda de quem usa o aparelho da sua arte é visivelmente maior que a de quem ignora (o Designer fixa a meta, ex.: ≥ 15% em 10 min de sala), nas 3 artes.
2. O retorno na tela do aparelho deixa claro, em 1 olhada, o que ele dá a mais.
3. D1: no centro, a diferença de crescimento entre as 3 artes cai para **≤ 15%** (mediana por arte, 3/s e 4/s); nenhuma arte fica sem vencer o Cinturão do Vale no ritmo de hoje.
4. Teto de 10% dos minigames medido de novo, com tudo junto: ≤ 10%.
5. `ronda2a_sim.py chefe` refeito: Apagão continua abrindo e sendo vencido nas mesmas faixas (campanha 8–11).
6. Casos exatos das fases antigas continuam passando, ou o Designer lista quais mudam de propósito e por quê.
7. `ui_audit`: 0 problemas.

**Quem faz:** Designer (diagnóstico, números, simulador) · Programador · UI/UX (retorno na tela) · QA.

---

## P1c: árvore com zoom e compra no meio da campanha
**Entra**
- Zoom com a roda do mouse **e** botões + e −; arrastar para andar. Mínimo e máximo definidos pelo UI/UX.
- Abrir a árvore durante a campanha e gastar **só o Legado já guardado**. O nó vale na hora, na campanha atual.
- O Legado que a campanha atual vai render continua entrando só na sucessão, como hoje.
- Regra clara para nós do tipo "começa com…" comprados no meio da campanha (o Designer define: valem na hora ou só na próxima, e a tela diz qual).

**Fica de fora**
- Nós novos (P1d).
- Reembolso ou troca de nó.

**Critérios de aceite**
1. O jogador acha e compra um nó no meio da campanha em menos de 30 s, sem sair da campanha.
2. O saldo gasto sai do Legado guardado; o Legado da campanha atual não aparece como gastável em nenhuma tela.
3. Todo nó comprado no meio da campanha mostra o efeito na hora ou diz "vale no próximo discípulo".
4. Simulador: a compra no meio da campanha acelera a curva em quanto (mediana por arte); tempo morto p90 ≤ 10 min; teto ≤ 10%.
5. `ui_audit` cobre zoom mínimo e máximo, arrastado até as bordas: 0 problemas, nada cortado.
6. Save antigo abre igual; nada se perde.
7. `foto.gd` não vale aqui (a regra muda de propósito); os testes de sucessão continuam passando.

**Quem faz:** Designer (regra e medida) · UI/UX (zoom, botão de abrir) · Programador · QA.

---

## P1d: mais coisa para comprar
**Entra**
- Árvore maior e **mais funda**: ramos mais compridos e níveis a mais, não só nós soltos.
- **Auto-clique nos nós fundos:** opcional, ritmo que sobe aos poucos, só a partir de uma fase adiantada (o Designer escolhe; sugestão: depois do 1º Cinturão do Vale). Clicar na mão continua ajudando. Ver pergunta 1 (Metrônomo).
- Mais itens na loja.
- Mais coisas na aba de equipe.
- Nomes e textos (Roteirista), ícones (Diretor de Arte).

**Fica de fora**
- Sistemas de fases futuras (mundial, absurdo, destino do Legado que sobra da 8b2).
- Auto-clique antes da fase escolhida.
- Se a fase crescer demais, o auto-clique é o primeiro a sair para um P1e.

**Critérios de aceite**
1. Em qualquer momento da campanha (do início ao centro), há algo comprável em até 2 min (simulador, p90).
2. A árvore tem pelo menos 1 nível a mais de profundidade em cada região, com ramos que levam a algo.
3. Auto-clique: antes da fase escolhida, nada; depois, sobe aos poucos; 1 clique manual continua ≥ 25% da renda/s; nunca toma o lugar da equipe (a equipe segue sendo a maior parte da renda passiva).
4. Mediana por arte: nenhuma arte passa de 15% de diferença (mantém o P1b).
5. Teto de 10% e `chefe` medidos de novo: ≤ 10% e Apagão nas mesmas faixas.
6. `ui_audit` na árvore (zoom mínimo e máximo), loja e equipe: 0 problemas.
7. Identidade original: nenhum nome ou item copiado de outro jogo.

**Quem faz:** Designer + Roteirista · Diretor de Arte (ícones) · Programador · UI/UX · QA.

---

## Riscos
- **P1b mexe na economia do centro:** a 8b1 inteira (limiares, ritmo, teto, chefe) foi medida em cima dela. Remedir antes de implementar a 8b1.
- **Compra no meio da campanha + mais nós:** juntos aceleram muito a curva. Por isso P1c e P1d são separados e cada um mede.
- **Auto-clique duplicado:** o Metrônomo da loja (5 níveis) e os nós "Memória muscular" e "Pêndulo de casa" já são auto-clique. Um segundo sistema confunde e fura o teto.
- **Chão do JJ:** é o trabalho de arte mais caro do P1a. Se atrasar, os números saem antes, sozinhos.
- **Árvore funda:** risco de nó de enchimento ("+2%"). Cada ramo novo precisa de um nó que muda o jeito de jogar.
- **Placar de `ignore` (≤ 15):** telas novas (zoom) não podem somar `ignore`.

## Perguntas ao dono
1. **Auto-clique:** o jogo já tem o Metrônomo na loja (5 níveis), que é um auto-clique leve. Recomendo que os nós novos levem o **Metrônomo além do nível 5** nas fases adiantadas, em vez de criar outro auto-clique. Pode ser?
2. **Zoom:** recomendo os dois juntos: roda do mouse e botões + e −. Pode ser?

## Resumo para o Produtor
- Polimento 1 em 4 subfases, nesta ordem: **P1a** (números e chão do JJ, só visual), **P1b** (aparelhos das artes e D1), **P1c** (zoom e compra com o Legado guardado), **P1d** (árvore funda com auto-clique, loja e equipe).
- O P1a é o que o dono sente a cada clique e tem risco baixo: crítico grande, resto pequeno, em todo lugar; Jiu-jitsu com jogo de chão; `foto.gd` igual.
- P1b, P1c e P1d mexem na economia: simulador, mediana por arte e teto de 10% em cada uma. A 8b1 é remedida depois do P1d.
- Caixote (item 5) já feito no PR #59; só o reteste.
- 2 perguntas: auto-clique como Metrônomo além do nível 5? Zoom com roda e botões?
