# Fase 6c1 — Casa nova: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-15.
Li: `PROMPT.md`, `docs/direcao-narrativa.md`, `fase6c-escopo.md`, `fase6c1-design.md`, `fase6c1-textos.md`, `fase6c1-api.md`, `fase6c1-qa.md`, `docs/cutscenes/prancha-6c1.md` (v2), `docs/arte/direcao-visual.md` §25. Olhei as capturas `fase6c1_ui_*` (incluindo `ui_audit_*`) e `fase6c1_contato_*`.

## Veredito: APROVADA
Pode ir para os testadores com uma única conferência rápida do QA, descrita na §4. Nenhum código precisa voltar.

## 1. Bate com a visão?
Sim. A sensação pedida era *"esse lugar agora é nosso; o John foi viver a vida dele"*, e as duas cenas entregam isso sem exagero.
- **Chegada:** a sala começa vazia e com metade no escuro. A foto entra reta, o Osmar dá um passo atrás e a entorta de propósito. Depois vem o "agora sim." e o 2º tubo acende. É a imagem certa: a casa só vira casa quando fica do nosso jeito. O plano em 2x (A4–A6) é limpo e o resto da sala fica fora dele.
- **Caixote no lugar do banco:** melhor que o escopo. Quem traz o caixote é quem senta nele, e é dele que o John levanta para ir embora. Fica um fio visual entre as duas cenas sem nenhuma fala a mais.
- **Saída:** do jeito pedido. Acontece atrás do treino, com a interface ligada, o soco valendo e duas frases curtas. O Osmar responde sem parar o que faz. Não tem música, barra nem corte. Na garagem, ele passa por baixo da porta de enrolar "como sempre fez", o que fecha bem o Arco 2.
- **Tom:** pé no chão, com uma piada de fundo (a esteira que não passa pela porta). Não puxa para o drama, como pede a `direcao-narrativa.md`.
- **Anti-incremental:** nada. O relógio fica parado na cena da chegada e a saída tem 0 s presos.
- **Identidade:** original. A foto torta, o caixote e a porta de enrolar são símbolos nossos, criados nas fases 6a e 6b.

## 2. Critérios de aceite da 6c1
| # | Critério | Situação |
|---|---|---|
| 1 | Cena da academia ≤ 15 s, foto torta, arte depois | **Cumprido** (12,90 s no validador) |
| 2 | Pular em ≤ 0,3 s | **Cumprido** |
| 3 | Toca uma vez só; fechar no meio = estado final | **Cumprido** |
| 4 | Elenco certo nos 3 casos | **Cumprido** |
| 5 | Save antigo: cena no próximo MUDAR + `cl_primeira_academia` 1x | **Cumprido em save sintético.** Falta a rodada com a cópia real (§4) |
| 6 | Osmar só onde está desenhado | **Cumprido** |
| 7 | Mentores na academia com a regra da garagem | **Cumprido** |
| 8 | Saída: gatilho, clique livre, interrupções, nunca 2x | **Cumprido** |
| 9 | Depois da saída: John fora, último no caixote, `stand` vazio | **Cumprido** |
| 10 | Comentário da arte | **Cumprido** depois da correção do BUG-1 (Programador) |
| 11 | Balanço inalterado, relógio parado na cena | **Cumprido** pelos testes comparativos no Godot. A simulação Python não rodou (falta Python), mas nenhum arquivo de balanço mudou |
| 20 (6c1) | `ui_audit` 0 problemas | **Cumprido** depois da OBS-1 (UI/UX): 325 estados, 0 problemas, com a saída quadro a quadro na garagem e na academia e os balões do Osmar e do John na academia |
| 21 | Testes verdes, save de teste, 2º monitor | **Cumprido** |

## 3. Decisões que eram minhas
- **Chegada sem esteira comprada** (prancha, decisão 2): aceito como está. O ajudante não entra e a cena perde só a piada do fundo. Não vale uma folha nova de arte.
- **OBS-2 do QA** (saída logo depois da escolha da arte): só acontece com o marco forçado em teste. Num save real, a vitória que arma a saída já acontece na academia com a cena tocada, ou a saída sai antes na garagem. Fica como está. Se um testador vir "cena → arte → saída" em sequência, o Designer acrescenta uma espera até a `cl_primeira_academia` tocar.
- **Decisões do dono e do Produtor** (gatilho, equipe nos pontos da garagem, caixote, vizinho em pé, faixa fora da 1ª chegada): todas respeitadas no que eu vi.

## 4. Antes de liberar (pequeno, não volta código)
- **QA:** uma rodada com a **cópia real do save do dono** (critério 5), em pasta de teste, conferindo: a cena no próximo MUDAR, a `cl_primeira_academia` uma vez e o John ainda sentado (no save dele a reserva é a Carreira 6, F + 3). Se algo falhar, volta para o Programador.
- **Produtor:** avisar os testadores de que a saída do John é discreta de propósito. Não dizer quando acontece: a pergunta 3 da §11 do escopo depende disso.

## 5. Anotado para depois (não trava)
| Item | Quem | Quando |
|---|---|---|
| `john_pick_duffel`: braço cruzando o peito no agachamento | Artista de Personagens | Passe de arte à mão (antes da 13) |
| Esteira carregada parecendo caixa | Artista de Personagens | Idem |
| Inclinação de cabeça do Osmar no `look_photo` discreta (a pausa da cena depende dela) | Artista de Personagens | Primeiro da lista se os testadores não "lerem" a pausa |
| Saco no ombro grande demais | Artista de Personagens | Aceitável como exagero cômico; revisar no mesmo passe |
| Porta meio aberta serrilhada, folha aberta de 8 px, rua chapada, escuro com dither (§25.4) | Diretor de Arte | Passe de arte à mão |
| Equipe máxima cobrindo o Osmar na academia (§25.2/25.5) | Diretor de Arte + Designer | Decisão do dono: revisitar com a arte à mão |
| Na cena, o John/discípulo fica em pé do `put_crate` até o A8 (prancha v2, item 2) | Diretor de Cutscenes + Programador | Só se os testadores estranharem |
| Rodar `fase5_sim.py` quando houver Python | Designer | Antes do balanço da 6c2 (critério 19) |
| Se ninguém perceber a saída: o Osmar comenta uma vez na próxima volta à garagem (risco §8) | Roteirista + Designer | Depois do retorno dos testadores |

## 6. A 6c2 pode começar?
**Sim**, em paralelo com os testadores, como na 6b:
- o design da Honra (Designer em effort high) e o símbolo (Diretor de Arte) não dependem das respostas;
- o mural deve esperar a pergunta 3 dos testadores ("perceberam a saída?") antes de fechar o texto "foi seguir o rumo dele", porque o mural é a 2ª proteção desse risco;
- a pergunta 2 do escopo §10 (rival / `narrativa.md`) continua com o dono e não trava a 6c2.

## Resumo para o Produtor
- A 6c1 está **aprovada**: os 11 critérios e o `ui_audit` (325 estados, 0 problemas) foram cumpridos, e o BUG-1 e a OBS-1 já estão corrigidos.
- Ela entrega a sensação pedida: a foto entortada de propósito torna a academia "nossa", e o John sai atrás do treino, sem drama, deixando o caixote para o próximo.
- Antes de mandar aos testadores, o QA roda uma vez a cópia real do save do dono (critério 5). Nenhum código volta.
- Os pontos fracos de arte (braço da bolsa, esteira com cara de caixa, cabeça do Osmar, saco grande) ficam anotados para o passe de arte à mão.
- A 6c2 pode começar agora. Só o texto do John no mural espera a resposta dos testadores sobre a saída.

---

## Correção: carga e foto (2026-11-16)

**Veredito: APROVADA.** Pode integrar o PR #13 na main.

- **Bate com a visão:** as cargas agora leem como carga (braço de trás, objeto, braço da frente), sem atravessar nada. A foto torta que o Osmar acerta ("agora sim.") mantém a sensação de "casa nossa" e fica mais calorosa que entortar de propósito. Onde esta revisão fala em "foto entortada de propósito", vale a decisão nova do dono.
- **Evidência conferida:** 3201 testes, validador 0 erros (12,90 s presos), `ui_audit` 325 estados / 0 problemas; capturas `fase6c1_qa_foto_torta_para_reta.png` (torta → reta legível no corte 2x), `_chegada_t048_carga_x4.png` e `_saida_gar_pega_bolsa_x6.png` (mão no puxador, sem atravessar).

**Decisão sobre as observações do QA:**
| Obs. | Decisão | Quem / quando |
|---|---|---|
| OBS-A: saco "na ponta da mão", braço quase horizontal | Aceito. Não atravessa nem pula; é só pouco natural. Substitui o item "saco no ombro grande demais" da §5 | Pixel artist humano, no passe de arte à mão |
| OBS-B: foto torta só 1 px | Aceito. A batida é carregada pelo corte 2x do A4/A6, pelo dedo do Osmar e pelo "agora sim.". Se os testadores não perceberem que estava torta, subir para 2 px (só sprite) | Artista de Personagens, só se os testadores não lerem; senão, passe à mão |
| OBS-C: `ui_audit` sem estado da foto antes/depois e do hover `old_photo_gym` | Vai para a 6c2: a parede da academia recebe o mural, então os estados entram juntos (foto reta + hover com o texto novo + mural) | UI/UX, na 6c2 |

## Resumo para o Produtor (correção)
- A correção da 6c1 está **aprovada**; pode integrar o PR #13.
- Cargas sem atravessar e foto torta → reta funcionam e ficam retas ao reabrir o jogo.
- Saco "na ponta da mão" e foto torta de 1 px ficam para o pixel artist humano (a foto só sobe para 2 px se os testadores não perceberem).
- Os estados de `ui_audit` da foto e do hover entram na 6c2, junto com o mural.
