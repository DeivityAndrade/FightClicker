# Roadmap — Fightclicker

Base: PROMPT §7, revisado com as decisões do dono de 2026-11-05 (ver "Decisões do dono" em `docs/visao.md`): pixel art, sala de treino com alvo central, progressão de locais, carreira por run (derrota encerra), aposentadoria voluntária e árvore de habilidades.

Regra: cada fase termina **jogável**, com aprovação do dono antes da próxima. Nada de adiantar.

## Visão geral
| Fase | Nome | PROMPT original | O que mudou |
|---|---|---|---|
| 1 | Fundação | Fase 1 | + configuração de pixel art |
| 2 | Treino na garagem | Fase 2 | o loop acontece na sala da garagem, com alvo central |
| 3 | Lutas e fim de carreira | Fase 3 | derrota encerra a carreira; aposentadoria voluntária; Legado contado |
| 4 | Árvore de habilidades | parte da Fase 6 | **nova**: meta-progressão precisa vir cedo, logo depois da derrota |
| 5 | Academia de bairro e artes | Fase 4 | escolha da arte acontece na 1ª mudança de local |
| 6 | Escalada e gestão | Fase 5 | + locais 3 e 4, escadas regional e nacional |
| 7 | Topo do mundo | resto da Fase 6 | cinturão mundial, segunda arte, ramo Linhagem |
| 8 | Narrativa e absurdo | Fase 7 | + locais 5 e 6, torneios secretos, nome final |
| 9 | Polimento | Fase 8 | balanceamento pensando em várias carreiras |
| 10 | Steam | Fase 9 | sem mudança |

A fase a mais vem de **dividir** o prestígio (que agora é a estrutura do jogo inteiro), não de somar sistemas. Cada fase continua pequena.

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
- Fica de fora: segunda arte (Fase 7), locais 3+ (Fase 6).

## Fase 6 — Escalada e gestão
- Escadas **regional** e **nacional**; cinturões liberam **centro de treinamento** e **complexo de elite**.
- Fama, patrocínio, geradores avançados (camada 3 do PROMPT: a sala fica cheia de alunos e logos).
- Risco: é a fase mais carregada. Se o design passar do tamanho, dividir em 6a (regional + local 3) e 6b (nacional + local 4).

## Fase 7 — Topo do mundo
- Escada **mundial** e cinturão mundial (chefe final em versão provisória; a identidade do rival vem na Fase 8).
- **Segunda arte / híbridos** e ramo **Linhagem** da árvore (começar com geradores, começar na academia de bairro).
- Fica de fora: templo, torneios secretos, local final (Fase 8).

## Fase 8 — Narrativa e absurdo
- **Rival recorrente** (pode encerrar suas primeiras carreiras; chefe do mundial), **mentor** = seu lutador anterior, falas curtas e puláveis.
- Garagem com marcas dos mentores anteriores.
- **Torneios secretos** e os locais **5 (templo na montanha)** e **6 (dojo no fim da realidade)**: a escalada para o absurdo.
- **Nome final** do jogo, depois de checar a Steam.

## Fase 9 — Polimento
- Progresso offline (~25%, teto 8 h) e "Enquanto você estava fora…".
- Conquistas preparadas para a Steam, sons, opções.
- Balanceamento das primeiras 2–3 horas **contando várias carreiras** (meta de dificuldade da visão).
- Arte final dos locais que ainda estiverem em placeholder.

## Fase 10 — Steam
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
| 6 | centro de treinamento, complexo de elite |
| 8 | templo, dojo no fim da realidade, rival, mentor |
