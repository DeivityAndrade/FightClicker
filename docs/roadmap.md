# Roadmap — Fightclicker

Base: PROMPT §7, revisado com as decisões do dono de 2026-11-05 (ver "Decisões do dono" em `docs/visao.md`): pixel art, sala de treino com alvo central, progressão de locais, carreira por run (derrota encerra), aposentadoria voluntária e árvore de habilidades.
**Revisado em 2026-11-11** com as respostas do dono ao feedback (`docs/propostas/feedback-2026-11-11.md`) e a direção narrativa do dono (`docs/direcao-narrativa.md`). O que mudou está em "Histórico de mudanças", no fim.

Regra: cada fase termina **jogável**, com aprovação do dono antes da próxima. Nada de adiantar.

## Visão geral (versão 2026-11-11)
| Fase | Nome | O que traz | Arco da história |
|---|---|---|---|
| 1 | Fundação | projeto, save, pixel art | — |
| 2 | Treino na garagem | loop na sala, alvo central | — |
| 3 | Lutas e fim de carreira | escada amadora, derrota encerra, aposentar, Legado | — |
| 4 | Árvore de habilidades | 12 nós, Metrônomo | — |
| 5 | Academia de bairro e artes | 1ª mudança, Boxe e Jiu-jitsu | — |
| 5.1 | Garagem clara | hierarquia da tela, prévia, corda, **caixa de aparelho** | — |
| 5.2 | Clique sem teto | luvas L3/L4, evento dourado da equipe, Metrônomo/Shift, medida de late game | — |
| 5.3 | Calendário da campanha | dias, data por luta, **luta obrigatória no dia** com Lutar / Passar o posto | — |
| 5.4 | Árvore grande | mapa **escondido** que se revela, no lugar das 3 abas | — |
| 6a | Prólogo e voz | caixa de diálogo com som de voz, 1º lutador fixo, treinador | Abertura, Arco 1 |
| 6b | Primeira sucessão | player de cena, personalização a partir do 2º discípulo, mentor | Sucessão |
| 6c | Um lugar nosso | cena da academia, saída do 1º mentor, mural/hall, Honra | Arco 2, início do 3 |
| 7a | Lutas por arte | Boxe e Jiu-jitsu lutam diferente, habilidades passivas, arena da academia | — |
| 7b | Muay Thai | 3ª arte | — |
| 8a | Regional | liga + arena regional, local 3, rival | Arco 4 |
| 8b | Nacional | liga + arena nacional, local 4 | Arco 4 (fim) |
| 9 | Topo do mundo | liga + arena mundial, segunda arte, local 5 | Arco 5 |
| 10 | Absurdo | torneios secretos, local 6, elenco absurdo | Arco 5 (fim) |
| 11 | Até onde chegamos | último adversário = 1º lutador, final, créditos | Arco 6 |
| 12 | Pós-jogo | modo infinito e torre | — |
| 13 | Polimento | offline, sons, opções, balanço, nome final | — |
| 14 | Steam | GodotSteam, conquistas, nuvem | — |

Regras que atravessam todas as fases (desde 2026-11-11):
- **Late game nunca parado:** cada fase mede tempo morto ≤ 10 min também no fim do seu conteúdo, e o clique continua valendo (número do Designer).
- **Top 3 animações** pedidas pelo dono entram em cada fase; o resto vai para o Polimento.
- **Arena por liga:** cada liga traz sua arena, junto com ela, nunca antes.
- **Nada de diálogo antes da 6a.**

---

## Fase 1 — Fundação
- Igual ao plano aprovado: projeto, pastas, `GameState`, formatador, save/load, autosave, testes.
- **Muda:** projeto configurado para pixel art (resolução base pequena com escala inteira, filtro "nearest"). Sem arte da garagem ainda.
- Detalhe em `docs/fases/fase1-escopo.md`.

## Fase 2 — Treino na garagem
- **Sala da garagem** em pixel art (placeholder do Diretor de Arte é aceitável) como tela principal.
- **Alvo central:** lutador + aparelho em foco no meio da tela, sempre no mesmo lugar.
- **3 aparelhos básicos** (saco = Força, corda = Agilidade, esteira = Resistência); trocar de aparelho = trocar o foco.
- **Juice:** número flutuando em todo clique, aparelho balança, tremida leve, som de impacto.
- **Primeiros geradores** (aparecem como gente treinando na sala) e **primeiros upgrades de aparelho** (aparelho muda de visual).
- Fica de fora: lutas, dinheiro de luta, outros locais, artes, árvore.
- Moeda da fase (decidido pelo Diretor): os itens da garagem custam **Treino**, agora e depois. O dinheiro entra na Fase 3 com itens próprios. Ver `docs/fases/fase2-escopo.md`.
- Detalhe em `docs/fases/fase2-escopo.md`.

## Fase 3 — Lutas e fim de carreira
- Escada de adversários **amadora** (1ª camada) com perfis diferentes (forte, rápido, resistente).
- **Prévia de luta:** seus atributos x os dele + indicador de risco.
- Simulação automática com barras de vida, poucos segundos, impacto visual; escolha tática (agressivo / defensivo / contra-ataque).
- Vitória: dinheiro, fama, avanço; cinturão amador no topo (a mudança de local ainda não acontece: aparece como "liberado, chega na Fase 5").
- **Derrota encerra a carreira:** tela de fim com o que faltou, Legado ganho (50%) e "Nova carreira" voltando à garagem.
- **Aposentar** entre lutas: Legado cheio (100%).
- Legado é **contado e salvo**, mas ainda não tem onde gastar (a árvore é a Fase 4). O relatório da fase deixa isso claro para o dono.
- Fica de fora: árvore, artes, mudança de local, regional em diante.

## Fase 4 — Árvore de habilidades (inicial)
- Tela da árvore entre carreiras, comprada com Legado.
- **Poucos nós** (ordem de 8–12), ramos Corpo e Carreira. Primeiros nós baratos: a primeira derrota já compra algo.
- Os bônus valem na carreira seguinte e aparecem de forma visível (ex.: "começa com +20% de Força por clique").
- **Fecha o critério do protótipo** (abaixo), com a marca de revanche e a dica "lute quando ficar verde".
- **Metrônomo** (auto-clique na LOJA, aprovado pelo dono) e o nó **Memória muscular**. Se a fase crescer demais, o Metrônomo é o primeiro a ir para uma 4b.
- Save v4 e medição de tempo morto (≤ 10 min seguidos).
- Fica de fora: ramo Linhagem (artes, segunda arte, começar em local melhor): Fases 5 e 7.
- Detalhe em `docs/fases/fase4-escopo.md`.

## Fase 5 — Academia de bairro e artes marciais
- **Primeira mudança de local:** cinturão amador + dinheiro → academia de bairro (cenário novo, aparelhos em versão nova, multiplicador).
- **Escolha da arte** na chegada à academia (1ª carreira); depois, desbloqueada, escolhida no início das carreiras seguintes.
- **2–3 artes** com efeito na curva e **aparelho assinatura** na sala (recomendado: Boxe, Muay Thai, Jiu-jitsu).
- Primeiros nós de arte na árvore (desbloquear arte).
- Fica de fora: segunda arte (Fase 9), locais 3+ (Fase 8a em diante).
- *(acrescentado em 2026-11-11)* Entraram por PR externo (Matheus, integrados em 2026-11): luta em 3 rounds, golpes por estilo só visuais (`moves.json`), reações e quedas de K.O., barra de especial só visual, evento dourado (FRENESI), Metrônomo em 5 níveis, assistido mais rápido, 4 melhorias por aparelho, prêmio do Muralha $2.500 e mudança automática para a academia. Validados no fechamento da Fase 5.

## Fase 5.1 — Garagem clara *(nova, 2026-11-11)*
- Hierarquia de leitura da garagem em 3 níveis (sala/alvo/Treino; próxima luta e compra mais barata; o resto em hover ou recolhido).
- Prévia de luta com respiro.
- Altura da corda na parede.
- **Caixa de aparelho:** toda carreira começa só com o saco; corda e esteira compradas chegam numa caixa que o jogador abre com cliques.
- Top 3 animações do dono.
- Fica de fora: teto do clique (5.2), calendário (5.3), árvore (5.4), qualquer fala (6a).

## Fase 5.2 — Clique sem teto *(nova, 2026-11-11)*
- Luvas L3/L4 e teto do clique.
- Variante do evento dourado que paga em renda da equipe; tudo em `data/`.
- Ajuste fino de Metrônomo/Shift.
- Medida de late game: tempo morto e valor do clique no fim do conteúdo atual.
- Fica de fora: calendário, árvore.

## Fase 5.3 — Calendário da campanha *(nova, 2026-11-11)*
- Dias passando na sala (segundos por dia em `data/`), cada luta da liga com **data**, "faltam X dias" sempre visível.
- Avisos a 3 dias e a 1 dia. Adiantar a luta é livre.
- **No dia, a luta é obrigatória:** relógio e treino param, a prévia abre e o jogador escolhe **Lutar** ou **Passar o posto** (aposentar, 100% do Legado). A luta nunca começa sozinha.
- O relógio só anda com o jogo aberto, na sala.
- Fica de fora: textos de história (6a), offline (13).

## Fase 5.4 — Árvore grande *(nova, 2026-11-11)*
- Mapa único **no lugar das 3 abas**, **escondido** atrás de um botão (a sala continua sendo o jogo), que se revela ao comprar.
- Regiões CORPO, CARREIRA, ESTILO, Garagem, Academia; nós de ligação entre regiões; ~35–40 nós; os 12 atuais no centro, mesmo id e efeito (ninguém perde Legado).
- Paga com Legado.
- Fica de fora: regiões dos locais 3+ (entram com cada local), árvore do hall (6c).
- Sai da árvore o nó "começar na academia": todo discípulo começa na garagem (direção narrativa).

## Fase 6a — Prólogo e voz *(nova, 2026-11-11)*
- **Caixa de diálogo com som de voz por letra/sílaba** (timbre por personagem, som original). Toda fala pulável.
- **1º lutador fixo** (nome, visual, gesto) na Carreira 1; o **treinador** original.
- Abertura curta (garagem em dificuldade, humilhação). **Arco 1 — Salvar a garagem** em narração passiva: aviso de cobrança, foto antiga, recorte; a garagem fica salva no 1º cinturão amador da escola.
- Comentários contextuais curtos e espaçados (treinador).
- Diretor de Cutscenes entra: caixa de diálogo, som de voz e storyboard da 1ª sucessão (só doc).
- Fica de fora: player de cena e personalização (6b).

## Fase 6b — Primeira sucessão *(nova, 2026-11-11)*
- **Player de cena por dados** (`data/cutscenes/`) e a cena **"Primeira sucessão"** ao fim da Carreira 1.
- **Personalização a partir do 2º discípulo:** nome, pele, cabelo, calção (só visual). Mentores mantêm a identidade.
- 1º lutador como mentor na garagem. Textos "passar o posto", "nova campanha", "receber novo discípulo".
- Fica de fora: hall e Honra (6c).

## Fase 6c — Um lugar nosso *(nova, 2026-11-11)*
- Cena **"Primeira chegada à academia"**; comentários sobre a arte escolhida (nenhuma arte é "a certa").
- **Saída discreta do 1º mentor** (proposta: quando um discípulo da Carreira 2+ chega à academia; senão, no início da Carreira 4).
- **Mural/hall da escola:** todo lutador entra; quem saiu por vontade deixa bônus pequeno. **Honra** (só ao se aposentar) e **árvore do hall**, pequena e separada.
- Começo do **Arco 3 — Mais longe que eu**: mentor reconhece recorde e revanche.

## Fase 7a — Lutas por arte *(era parte da Fase 6a do plano v1)*
- Boxe e Jiu-jitsu **lutam diferente** (golpes, animações, ritmo).
- **Habilidades passivas de luta** liberadas por meta; cada adversário traz 1, mostrada na prévia. Prévia continua honesta.
- Arena da liga da academia.

## Fase 7b — Muay Thai
- 3ª arte: aparelho, técnicas, chute rodado, golpes e ritmo próprios.

## Fase 8a — Regional *(era a primeira metade da Fase 6)*
- Liga regional com arena própria; cinturão libera o **centro de treinamento** (local 3); fama, patrocínio, gente na sala.
- **Arco 4 — Nosso nome no circuito:** entra o **rival** (lutador de academia tradicional, menospreza a escola).

## Fase 8b — Nacional *(era a segunda metade da Fase 6)*
- Liga nacional com arena; cinturão libera o **complexo de elite** (local 4).
- Rival passa a se preparar contra a escola e termina em respeito (fim do Arco 4).

## Fase 9 — Topo do mundo *(era a Fase 7)*
- Liga mundial com arena e cinturão mundial; libera o **templo na montanha** (local 5). O campeão mundial é um personagem próprio, não o rival.
- **Segunda arte / híbridos.**
- **Arco 5 — As histórias do velho** começa: histórias do treinador se confirmam.

## Fase 10 — Absurdo *(era parte da Fase 8)*
- **Torneios secretos** com arena e o **dojo no fim da realidade** (local 6). Elenco absurdo (ciborgue, urso, mestres impossíveis). A academia reage à escala.
- O último desafio é anunciado (sem investigar quem é).

## Fase 11 — Até onde chegamos *(nova, 2026-11-11)*
- **Arco 6:** último adversário no topo dos torneios secretos = **o 1º lutador**. Cena "Reencontro final", luta, cena "Vitória final", foto no mural, créditos.

## Fase 12 — Pós-jogo *(nova, 2026-11-11)*
- **Modo infinito** e **torre** de combates. As hipóteses da direção narrativa (§10) são validadas com o dono antes do escopo.
- O infinito precisa manter "formar outro discípulo" como decisão interessante.

## Fase 13 — Polimento *(era a Fase 9)*
- Progresso offline (~25%, teto 8 h) e "Enquanto você estava fora…". **Offline nunca pula para o dia de uma luta.**
- Conquistas preparadas para a Steam, sons, opções.
- Balanceamento das primeiras 2–3 horas **contando várias carreiras**.
- Passe final de animação e arte que ainda estiver em placeholder.
- **Nome final** do jogo, depois de checar a Steam.

## Fase 14 — Steam *(era a Fase 10)*
- GodotSteam, conquistas, nuvem, build de distribuição.

---

## Critério de sucesso do protótipo (revisa o PROMPT §8; fecha na Fase 4)
Em ~20 minutos de jogo, o jogador:
1. sente o impacto do clique no alvo central (número em todo clique);
2. compra geradores e vê a renda passiva crescer e a garagem ganhar movimento;
3. perde uma luta, **entende por que perdeu** e vê a carreira acabar;
4. compra pelo menos um nó da árvore com o Legado;
5. começa uma nova carreira, chega mais longe e **vence o adversário que o derrotou**;
6. e quer jogar mais uma carreira.

## Arte por fase (para o Diretor de Arte planejar)
| Fase | Arte necessária |
|---|---|
| 1 | nenhuma (só um padrão de teste de pixels) |
| 2 | garagem, lutador, 3 aparelhos (2 níveis visuais cada), 1–2 tipos de gerador |
| 3 | tela/arena de luta, 3–4 adversários amadores |
| 5 | academia de bairro, aparelhos de 2–3 artes |
| 5.1 | caixa de aparelho (fechada, rachando, aberta), corda reposicionada, ícones de hierarquia |
| 5.2 | luva L4 |
| 5.3 | calendário no HUD, faixa de aviso |
| 5.4 | nós e moldura do mapa, botão da árvore |
| 6a | 1º lutador com gesto, treinador, aviso de cobrança, foto, recorte, caixa de diálogo |
| 6b | paletas de personalização, mentor na garagem, poses da cena de sucessão |
| 6c | mural/hall com retratos, poses da chegada à academia |
| 7a | golpes de Boxe e Jiu-jitsu (lutador e adversários), arena da academia |
| 7b | Muay Thai: aparelho e golpes |
| 8a / 8b | centro de treinamento, complexo de elite, arenas regional e nacional, rival |
| 9 | templo, arena mundial, campeão mundial |
| 10 | dojo no fim da realidade, arena dos torneios secretos, elenco absurdo |
| 11 | 1º lutador no auge, poses do reencontro e da vitória final |
| 12 | inimigos do infinito, torre |

---

## Histórico de mudanças
### 2026-11-11 (respostas do dono ao feedback + direção narrativa)
- **Novas fases 5.1–5.4** antes da Fase 6: garagem clara com caixa de aparelho, clique sem teto, calendário, árvore grande.
- **Calendário com luta obrigatória no dia** (decisão do dono). Proteção: avisos, "faltam X dias" visível, adiantar livre, no dia a escolha é Lutar ou Passar o posto, nunca luta sozinha.
- **Árvore grande substitui as 3 abas** e fica escondida atrás de um botão.
- **História costurada na carreira** seguindo `docs/direcao-narrativa.md`. Antes, "Narrativa e absurdo" era uma fase só (8); agora a linhagem e a história inicial vêm logo depois da árvore (6a–6c) e o fim tem fase própria (11).
- **1º lutador fixo**, personalização a partir do 2º discípulo; o 1º lutador vira mentor e é o **último adversário**. O **rival deixa de ser o chefe do mundial** e termina em respeito.
- **Hall dos aposentados = mural da escola**, com Honra (só ao se aposentar) e árvore do hall pequena.
- **Ramo Linhagem** da árvore se espalha: personalização e hall em 6b–6c; segunda arte na 9; o nó "começar na academia" **sai** (todo discípulo começa na garagem).
- **Lutas por arte** (7a) separadas do **Muay Thai** (7b); **arena por liga** entra com cada liga.
- **Pós-jogo** (12: infinito e torre) novo. Polimento e Steam viram 13 e 14.
- Diretor de Cutscenes e som de voz entram na 6a.

Correspondência com a numeração antiga: 6 → 8a + 8b · 7 → 9 (e Linhagem → 6b/6c) · 8 → 6a–6c, 10, 11 · 9 → 13 · 10 → 14.

### 2026-11-05 (versão anterior, substituída a partir da Fase 6)
| Fase | Nome | PROMPT original | O que mudou |
|---|---|---|---|
| 1 | Fundação | Fase 1 | + configuração de pixel art |
| 2 | Treino na garagem | Fase 2 | o loop acontece na sala da garagem, com alvo central |
| 3 | Lutas e fim de carreira | Fase 3 | derrota encerra a carreira; aposentadoria voluntária; Legado contado |
| 4 | Árvore de habilidades | parte da Fase 6 | **nova**: meta-progressão precisa vir cedo, logo depois da derrota |
| 5 | Academia de bairro e artes | Fase 4 | escolha da arte acontece na 1ª mudança de local |
| 6 | Escalada e gestão | Fase 5 | + locais 3 e 4, escadas regional e nacional |
| 7 | Topo do mundo | resto da Fase 6 | cinturão mundial, segunda arte, ramo Linhagem |
| 8 | Narrativa e absurdo | Fase 7 | + locais 5 e 6, torneios secretos, nome final; rival chefe do mundial; mentor = lutador anterior |
| 9 | Polimento | Fase 8 | balanceamento pensando em várias carreiras |
| 10 | Steam | Fase 9 | sem mudança |
