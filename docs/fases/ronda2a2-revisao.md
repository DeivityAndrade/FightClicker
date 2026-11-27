# Ronda 2a2 (o chefe Apagão): revisão do Diretor

Diretor de Jogo, 2026-11-26. Base: `ronda2a-escopo.md` (§5, 2a2, e §6), `ronda2a2-design.md` (B1–B16), `ronda2a2-qa.md`
(APROVADO, com as correções do Produtor) e `ronda2-ideias.md`.

## Veredito
**Aprovado**, com uma condição antes do PR: o teste ponta a ponta do QA entra na suíte (decisão 4).

## Decisões que já valiam (registradas)
- Escala do Apagão 0,8× (420M/840M/1,24B): vence em mediana na 2ª noite aberta, todas as artes até a campanha 11, 4% nunca até a
  14ª. Falha o critério (a) do design; o Produtor aceitou. "Mais forte, mas não tão mais forte" é a direção do dono.
- Capuz a cada 5 min de sala; limiares 1/10/24/42/64.
- "Bairro agradece" em +20%, teto 8,8% (≤ 10%).
- Letreiro "O APAGÃO" antes da vitória, como no design. O nome real (NÉLSON VOLT) fica oculto até vencer.

## Decisões desta revisão
1. **Placar de `ignore`.** A meta ≤ 15 desta fase vale para as **telas da fase**, como na 2a1 (7 nos estados dela). A 2a2 deu 8
   e não acrescentou nenhum `ignore`: **passa**. O 26 da rodada completa é dívida das telas antigas, não da 2a2, mas o D2 da
   identidade pedia o jogo inteiro ≤ 15 e isso não fechou.
   - **Quem paga:** UI/UX (telas) e Programador (isenções por tipo no verificador).
   - **Quando:** item técnico na abertura da 8b, antes de qualquer tela nova. Meta: rodada completa ≤ 15. No mesmo pacote, o BUG-3
     (deixar `f6b1_s8` e `f8a1_luta_guarda_clink` determinísticos).
2. **O2 (chefe colorido na luta).** **Mantém.** O "??? em todo lugar" do escopo protege a **identidade** (nome, rosto da ficha,
   retrato, cartão, prévia, Dossiê), não o corpo no ringue. Lutar contra uma silhueta mataria o juice e jogaria fora a arte que
   o dono aprovou. A primeira luta é a hora de ver o Apagão; o nome continua "???" no HUD.
3. **Arte das poses do meio.** **Não bloqueia.** Bateria escondida deitado, cotovelo no chão no `ground_punch` e o salto entre os
   quadros 2 e 3 do K.O. ficam para um passe do Artista de Personagens **logo depois do teste do dono**, juntando o que ele
   apontar. O salto do K.O. é o mais visível (é o momento de juice da vitória) e vai primeiro. O Produtor avisa o dono antes
   do teste, para não parecer descuido.
4. **`tests/qa_ronda2a2_e2e.gd`.** **Entra agora**, antes do PR. É barato e cobre o que mais quebra: save reaberto do disco entre
   noites, aproximação natural, destrave pelo Esconderijo e a varredura do apagão. O Programador renomeia para
   `tests/test_ronda2a2_e2e.gd`, tira os `print` de depuração e o ramo da sucessão sem verificação, e roda `run_tests.ps1` verde.
5. **PR e teste do dono.** Sim, depois do item 4.

## O que ficou bom
- Foto idêntica à da main (B1) e quem briga = quem só faz SUSTO (B2): o chefe não mexe na economia.
- Perder é pequeno de verdade: lenda +1, nada some, REVANCHE, capuz volta em 300 s.
- Apagão só visual e só depois de 10,7 s: 0 violações em 108 lutas. Honesto.
- O prêmio fecha a fantasia: capacete normal/raro na prateleira, título, cartaz no menu, FIO DESENCAPADO no calção.
- Tom certo: eletricista de bairro que apaga a luz, sem sangue, sem nada de morcego.
- O Produtor achou e corrigiu um bug real (OCORRÊNCIAS: 0 no nível 5) que valia também para a 2a1.

## O que desvia da visão (aceito)
- A curva do chefe ficou mais fácil que o critério (a). É decisão do dono; reavaliar se os testadores acharem o chefe "de graça".
- O letreiro mostra o apelido antes da vitória. Aceito: apelido é lenda de rua, o nome é o segredo.

## Fica para depois
| Item | Quem | Quando |
|---|---|---|
| Placar de `ignore` da rodada completa 26 → ≤ 15 + BUG-3 | UI/UX + Programador | abertura da 8b |
| Poses do meio (K.O. primeiro, cotovelo, bateria) | Artista de Personagens | logo após o teste do dono |
| BUG-2 (Dossiê sem texto do bandido aberto não vencido) | UI/UX | mesmo pacote da 8b |
| Refazer `ronda2a_sim.py chefe` e cronometrar 1 noite animada | Designer + QA | antes de fechar a 8b |
| Repetir `ronda2a_sim.py teto` a cada mudança de equipe/Legado/região (margem 8,8%) | Designer | na 8b |

## Resumo para o Produtor
- Ronda 2a2 aprovada: o Apagão está jogável, honesto e não mexe na economia (foto igual, teto 8,8%).
- Antes do PR: o Programador limpa e põe o teste ponta a ponta do QA na suíte.
- O `ignore` passa na fase (8, nada novo); o 26 das telas antigas vira item técnico da abertura da 8b.
- O chefe colorido na luta fica: o segredo é o nome e a ficha, não o corpo.
- Avisar o dono que as poses do meio (o K.O. principalmente) ganham um passe de arte depois do teste dele.

**Aprovado**
