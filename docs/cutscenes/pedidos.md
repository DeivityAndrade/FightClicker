# Cutscenes — pedidos por papel e por fase

Dono: Diretor de Cutscenes. Versão 1 (2026-11-11).
Documentos de origem: `linguagem.md`, `gesto-assinatura.md`, `primeira-sucessao.md`, `reencontro-final.md`, `cenas-curtas.md` (chegada à academia, afastamento do mentor, 3 vinhetas), `formato-dados.md`.
Nada aqui adianta fase: cada pedido entra na fase indicada. Poses de personagem seguem a skill `padrao-personagem`; tudo que é balão, botão ou texto na tela passa pela `alinhamento-ui`.

## Decisões que precisam do dono (antes da 6a)
1. **Gesto de assinatura:** opção A, B ou C (`gesto-assinatura.md`). Recomendo A, "fecho e dois toques".
2. **Porta de enrolar que emperra** como motivo visual das duas cenas centrais.
3. **Última arena simples** (sala de concreto, uma lâmpada, porta de enrolar) ou plano B (qualquer arena, só um foco de luz).
4. **Fala em balão preso ao personagem**, no lugar de caixa no rodapé.
5. **A luva velha é o par do 1º lutador**, passado a cada discípulo (só sentido novo para uma regra que já existe).

## Pontos para o Diretor de Jogo / Designer
- **Gatilho do afastamento do mentor:** proponho "volta à sala depois da 1ª vitória de um discípulo (Carreira 2+) na academia", no lugar de "ao chegar à academia" (item 8 do feedback), para não cair junto com a cena da chegada e a escolha da arte. Reserva: início da Carreira 4.
- **Prévia da última luta** sem revelar quem é até o marco do reencontro (silhueta e título), com os números honestos.
- **Gesto dentro do tempo que já existe** na luta (`intro_seconds` 1,5 s e `outro_seconds`): confirmar que não muda a duração da luta.
- **A foto antiga acompanha a escola** (garagem ou academia, conforme onde o discípulo treina).
- **Save antigo:** cada cena única toca na próxima vez que o gatilho acontecer.
- **Símbolo da escola** nasce quando? Proposta: pintado na parede quando a garagem é salva (1º cinturão amador) e, a partir daí, na roupa dos discípulos.

---

## Fase 6a — Prólogo e voz

| Papel | Entrega |
|---|---|
| **Roteirista** | Nome do 1º lutador, do treinador e da escola. Descrição da voz de cada um em uma linha (para afinar o timbre). Regras de texto de fala: até 2 linhas de 26 caracteres por balão, minúsculas. Forma da humilhação (trava o storyboard da abertura). Polir as falas da sucessão (`suc_guarda`, `suc_isso`), mantendo o verbo "ver". |
| **Artista de Personagens** | Fixar o 1º lutador (o sprite atual do jogador). **Gesto de assinatura:** rostos `bite` e `smile` nas duas vistas, ponta do fecho da luva, folhas `fighter_gesture`, `fighter_gesture_short`, `fight_player_gesture`, `fight_player_gesture_short` com todos os sufixos de luva, e `bite_frame` / `tap_frames` no manifest (detalhe em `gesto-assinatura.md`). Treinador original: parado, olhar para o lado, falar (3 folhas). |
| **Diretor de Arte** | Balão de fala (9-slice `cream`/`ink`, rabicho, plaquinha de nome, seta `▼`). Conferir as **minúsculas acentuadas** da fonte 5x7 (ç ã á â é ê í ó ô õ ú). Símbolo da escola legível em 5x5 px (proposta: a lâmpada). **Prancha de quadros-chave** das duas cenas centrais (8 quadros cada, com os placeholders, como as tiras de `fase3_luta_x2.png`): é o animatic que o dono pediu antes de produzir o resto. |
| **Programador** | Sistema de fala: letra a letra, pausas na pontuação, blip por 2 letras com nota por vogal, timbre e velocidade por personagem, completar no clique, guardas de clique (valores em `linguagem.md` §7, todos em `data/`). Blips e sons do gesto no gerador `tools/sfx/make_sfx.gd`: `voice_<timbre>`, `strap_rip`, `strap_open`, `tap_glove`, `tap_fist`. Gesto na entrada e na vitória da luta, ao calçar luva e na garagem parada, sempre cancelado pelo clique. `school.milestones` no save (fora do reset), com teste em save de teste. |
| **UI/UX** | Layout do balão nos dois modos (cena e passivo) e nos 6 estados de auditoria (`linguagem.md` §7.1); regra de nunca cobrir o alvo central. `alinhamento-ui` com 0 problemas. |

### 6a — complemento de 2026-11-13 (depois do escopo aprovado)

Documentos novos: `abertura-6a.md` (abertura na sala viva), `balao-e-voz.md` (especificação final do balão e dos blips; **vale sobre `linguagem.md` §7 onde divergir**) e a seção "Fase 6a" de `gesto-assinatura.md` (onde e quando o gesto toca). Ids seguem `docs/fases/fase6a-design.md`: `first`, `coach`, `open_1..4`, `prologue_seen`.

| Papel | Pedido novo ou ajustado |
|---|---|
| **Roteirista** | A abertura proposta (111 letras, ≈ 14 s) cabe com folga; os tempos finais estão em `abertura-6a.md` §3 e substituem os "t aprox." de `fase6a-textos.md` §3. Usar os ids `open_1..4` (hoje `ab_1..4`). Trocar os nomes escolhidos pelo dono (John Bullet, Osmar Brandão, Raízes Fight Club) em todas as falas e objetos. Se reescrever: ordem Osmar, Osmar, John, John, e o balão 4 fazendo sentido com e sem a ficha na parede. Nome de plaquinha até 12 caracteres. |
| **Artista de Personagens** | Folhas curtas do gesto a **9 fps** (não 10), para os toques caírem com 0,22 s. Treinador: `coach_idle` (encostado no carro), `coach_look` (de lado, olhando a parede), `coach_talk`. `head_anchor` no manifest para o 1º lutador, o discípulo padrão e o treinador (ponto fixo da cabeça na pose parada; o balão usa esse ponto). |
| **Diretor de Arte** | Peças do balão nas medidas de `balao-e-voz.md` §1 (`ui_balloon` 16x16 com cantos de 5, `ui_balloon_tail` 7x6, `ui_balloon_tag`, `ui_balloon_next`) e cores das plaquinhas. **Ponto do treinador:** proposta (236,238), reserva (160,252). **Parede da memória** (x 180..262, y 56..104): aviso de cobrança em ~(200,62), foto antiga, **ficha amassada** (≤ 24x24; peço que entre) e os lugares do recorte e da foto da equipe. |
| **Programador** | 15 blips `voice_<first/coach/disciple>_<u/o/a/e/i>`, `strap_rip` e `tap_glove` com os parâmetros de `balao-e-voz.md` §6.3 e §6.4, **gerados depois dos sons antigos** (o ruído tem semente fixa). Posição do balão pelo algoritmo do §3 (`no_cover` = (310,180,52,94)). Abertura como sequência por tempo (`abertura-6a.md` §3 e §6). Gesto nas janelas da seção "Fase 6a" de `gesto-assinatura.md`; 2º toque por temporizador de 0,22 s. Segurar ESC 0,5 s sem conflitar com o ESC de `ui/fluxo.gd`. |
| **UI/UX** | Capturas extras do balão (`balao-e-voz.md` §7). Indicação `esc: pular` com filete durante a abertura. |
| **Diretor de Jogo / Designer** | Decidido em 2026-11-13: na sala viva o ESPAÇO só treina e não completa fala (`balao-e-voz.md` §5). Corrigir a frase no escopo §3.1 e no design §5.2. |
| **Designer** | Confirmar a pose de vitória entrando 0,60 s depois do começo de `outro_seconds`. Avaliar o teto de 3 gestos por período parado. `vowel_steps` lido na ordem u, o, a, e, i. |

### 6a — Prancha de quadros-chave (animatic): pedido de imagem

**Para:** Diretor de Arte (monta a prancha) e Artista de Personagens (poses). **Aprova:** o dono. **Destrava a 6b.**
**Quando:** depois que existirem o balão, o treinador e as folhas do gesto da 6a, porque a prancha reaproveita os três.

**O que é:** imagens paradas, geradas por script em `tools/art/`, com os cenários e bonecos do jogo. Pose nova entra como **um quadro só, em rascunho** (sem animação, sem sufixos de luva, sem entrar no manifest). Não é arte final: serve para o dono dizer "é isso" ou "muda" antes de alguém produzir as folhas.

**Arquivos pedidos** (em `docs/arte/mockups/`):
1. `fase6a_prancha_sucessao_x2.png`: 8 quadros, S1 a S8.
2. `fase6a_prancha_reencontro_x2.png`: 8 quadros, R1 a R8.
3. `fase6a_prancha_pares_x2.png`: os 3 pares lado a lado (ver "Pares").

**Formato de cada quadro:** a janela de cena **384x272** inteira. Na sucessão é a sala em (128,18); no reencontro é a janela (128,52) da tela de luta, com os pilares e barras `ink` em volta só no R1. Interface apagada. Embaixo de cada quadro, legenda de 2 linhas: número, tempo, plano (1x ou 2x) e o som principal. Balão desenhado com a peça real. Quadro 2x mostra a região de 192x136 ampliada na mesma janela.

**Sucessão** (`primeira-sucessao.md`; garagem zerada, só o saco; Osmar no ponto dele; aviso de cobrança na parede):

| Quadro | Tempo | Plano | O que mostra | Poses |
|---|---|---|---|---|
| S1 | 0,0–1,8 | 1x | Último soco no saco, saco balançando forte. John em (303,272). | `fighter_punch`, `bag_l0_hit` (existem) |
| S2 | 1,8–3,6 | 1x | **Segura o saco com as duas luvas.** Saco parado, rosto cansado. | nova `hold_bag` |
| S3 | 3,6–6,0 | **2x**, região (222,154,192,136) | Luva esquerda na boca, **abrindo o fecho com os dentes**, fita esticada. | quadro 2 de `fighter_gesture` (6a), rosto `bite` |
| S4 | 6,6–9,0 | 1x | Luvas **penduradas na argola** do saco (336,186). Mãos nuas. Ele **olha a porta**; sombra de dois pés na fresta de luz. | nova `look_door` sem luvas; `door_gap_shadow`; luvas penduradas |
| — | — | — | (aqui entra a tela de criar o discípulo; não é quadro da prancha) | — |
| S5 | parte 2, 0,8–1,3 | 1x | **Porta emperrada na altura do peito**, luz do dia no chão. Discípulo padrão visto **do peito para baixo** em (423,221). | `garage_door` emperrada; discípulo parado, cortado pela porta |
| S6 | parte 2, 1,3–2,6 | 1x | Discípulo **passando por baixo da porta**. John com sorriso leve. | nova `duck_under`; rosto `smile` |
| S7 | parte 2, 2,6–4,6 | 1x | John em (268,268), **mão aberta apontando** o lugar em frente ao saco. Balão: "vamos ver sua guarda." Discípulo no meio do caminho. | nova `point_spot`; discípulo em `walk` (1 quadro) |
| S8 | parte 2, 6,2+ | 1x | **Estado final:** discípulo de guarda em (303,272) com a luva velha; John **sentado no caixote** em (268,266); porta fechada. | `fighter_idle` na paleta do discípulo; nova `sit_rest`; caixote |

**Reencontro** (`reencontro-final.md`; última arena simples: concreto, a lâmpada da garagem em (320,66), círculo de giz, porta de enrolar em x 382..464):

| Quadro | Tempo | Plano | O que mostra | Poses |
|---|---|---|---|---|
| R1 | 0,0–2,5 | tela → janela | Holofotes varrendo a entrada, **ninguém**. Pilares fechando. Discípulo de guarda em (296,318). | 3 feixes em rascunho; `fight_player_idle` com o símbolo da escola |
| R2 | 2,5–5,0 | 1x | Só a lâmpada acesa. Discípulo sozinho à esquerda. **Porta emperrada no peito**; John do peito para baixo em (423,256), luvas caídas. | `final_door` emperrada; corpo dele cortado pela porta |
| R3 | 5,0–6,4 | **2x**, região (327,123,192,136) | A luva esquerda **sobe e some atrás da borda da porta** (o fecho, sem mostrar a cabeça). | quadro 2 de `fight_player_gesture`, cabeça coberta |
| R4 | 6,4–8,2 | **2x**, mesma região | **Dois toques** de luva em luva, 2 faíscas. | quadro 7 de `fight_player_gesture` |
| R5 | 8,2–8,9 | 1x | Ele **passa por baixo da porta**, na mesma pose do S6. | `duck_under` em vista de luta |
| R6 | 11,0–13,6 | 1x | Sob a lâmpada em (346,318), braços baixos: **o rosto mais velho** e **só o nome**, pequeno, 8 px abaixo dos pés. Sem balão. | John mais velho parado; cartão de nome simples |
| R7 | 15,8–17,6 | 1x | Ele **olha o símbolo** no discípulo (a cabeça baixa um pouco); brilho no símbolo. A legenda lembra a fala anterior: "então vocês chegaram." | nova `look_emblem` |
| R8 | 17,6–20,4 | 1x | Ele **arma a guarda**, sorriso leve. Balão: "quero ver o que aprenderam." | guarda de luta, rosto `smile` |

**Pares (a 3ª imagem):** três colunas, sucessão em cima e reencontro embaixo, na mesma escala e com o mesmo recorte de 192x136, para conferir no olho que batem:

| Par | Sucessão | Reencontro | O que tem que ser igual |
|---|---|---|---|
| A porta | S5 | R2 | Porta no mesmo x do quadro (382..464), emperrada na mesma altura do corpo; quem chega visto do peito para baixo |
| O gesto | S3 | R3 + R4 | Mãos na mesma altura do quadro (78 px abaixo do topo do recorte); mesma pose da luva na boca. Lá ele abre, aqui ele aperta |
| Passar por baixo | S6 | R5 | A mesma pose `duck_under`, uma em 3/4 e a outra de perfil |

Dois ecos que não precisam de recorte, só de conferir nos quadros inteiros: **quem espera fica à esquerda, virado para a direita** (S4 é o John; R2 é o discípulo, no lugar que era dele) e **a fala com o verbo "ver"** (S7 e R8).

**Rascunhos novos que a prancha precisa** (um quadro cada):
- John, garagem: `hold_bag`, `look_door` (sem luvas), `point_spot`, `sit_rest`.
- Discípulo padrão, garagem: `duck_under` e um quadro de `walk`.
- John mais velho, vista de luta: parado de braços baixos, `duck_under`, `look_emblem`, guarda com `smile`; os 2 quadros do gesto reaproveitados com a paleta dele (têmpora e barba grisalhas, luva velha, sem símbolo).
- Cenário e objetos: `garage_door` emperrada com a luz no chão, `door_gap_shadow`, caixote, fundo da última arena em rascunho, 3 holofotes, cartão de nome, brilho do símbolo (usar o `school_symbol` provisório).

**O que o dono responde olhando a prancha:**
1. A porta emperrada e o "passar por baixo" leem como a mesma coisa nas duas cenas?
2. O gesto lê em 1x, ou o corte para 2x é mesmo necessário?
3. Dá para reconhecer o John mais velho pela silhueta antes do rosto?
4. A última arena simples serve, ou vai o plano B (um foco de luz em qualquer arena)?
5. O John sentado no caixote (S8) passa "ele continua com a gente"?

**Fora da prancha:** animação, sons, folhas completas e `data/cutscenes/`. Isso é 6b (sucessão) e 11 (reencontro), e só depois do "sim" do dono. Com os nomes e a humilhação escolhidos, o Diretor de Cutscenes ajusta `primeira-sucessao.md` antes de a 6b começar.

## Fase 6b — Primeira sucessão

| Papel | Entrega |
|---|---|
| **Roteirista** | Falas finais da sucessão. Textos "passar o posto", "nova campanha", "receber novo discípulo". Comentários do 1º lutador como mentor (curtos, espaçados). |
| **Artista de Personagens** | `primeiro`, vista garagem: `hold_bag`, `gloves_off` (o gesto ao contrário), `hang_gloves`, `look_door`, `walk` sem luvas, `point_spot`, `mentor_first_taps`, `sit_rest` (pose parada de mentor). Discípulo: `walk`, `duck_under`, `take_gloves`. **As poses do discípulo têm que funcionar com a personalização** (pele, cabelo, calção por troca de paleta): por isso são só três novas. Opcional: esparadrapo na sobrancelha. |
| **Diretor de Arte** | `garage_door` (fechada, 1/3, emperrada no peito) com a luz do dia no chão; `door_gap_shadow` (sombra de pés na fresta); caixote do mentor e **ponto do mentor** (proposta (268,266); conferir contra `neighbor_2` em (220,258) e o saco em descanso em (258,160)); posição das luvas penduradas na argola do saco (336,186). |
| **Programador** | **Player de cena por dados** (`formato-dados.md`): passos, `parallel`, `open_screen`, `return_control`, `reactions`, pular com `end_state`, fila e gatilhos. Validador e captura de cena. Sons: `bag_catch`, `chain_creak`, `lamp_hum`, `door_shake`, `door_roll`, `door_jam`. Chegada curta dos discípulos seguintes (porta, passar por baixo, 2 s, sem prender). |
| **UI/UX** | Botão PULAR com anel de segurar; interface apagando e voltando em dither; entrada e saída da tela de criar discípulo por cima da garagem escurecida. `alinhamento-ui`. |
| **Diretor de Cutscenes** | Montar `data/cutscenes/primeira_sucessao.json` e conferir nas capturas. Storyboard completo da chegada à academia. |

## Fase 6c — Um lugar nosso

| Papel | Entrega |
|---|---|
| **Roteirista** | `acad_agora_sim`, `saida_rumo`, `saida_resposta` (resposta casual, que sirva para o treinador ou outro presente). Comentários sobre a arte, sem arte "certa". |
| **Artista de Personagens** | Carregar saco no ombro, carregar caixa, ajudante com a esteira atravessada (bate, recua, passa de lado); treinador: pendurar, passo atrás, ajeitar a foto; `primeiro`: andar com bolsa, olhar a sala, acenar com a cabeça. Retrato do 1º lutador **na pose da luva na boca** para a foto do mural. |
| **Diretor de Arte** | Academia "vazia" (um tubo só, sem aparelhos); porta da rua aberta; fotografia antiga em 2 estados (reta, torta) e o lugar dela na parede da academia; **faixa do mural** (lugares das fotos, na garagem e na academia); bolsa; símbolo da escola na roupa dos discípulos. |
| **Programador** | Cenas `blocking: false`; passo `photo` e `grants` de foto e de `mentor_leaves`; gatilhos `location_reached` e `returned_to_room`. |
| **UI/UX** | Balão passivo convivendo com o HUD da academia; janela da arte abrindo logo depois da cena. |
| **Diretor de Cutscenes** | Montar `chegada_academia.json` e `saida_primeiro_mentor.json`; revisar se os comentários da fase não atrasam o treino. |

## Fase 10 — Absurdo (vinhetas)

| Papel | Entrega |
|---|---|
| **Roteirista** | Nomes, apelidos e títulos inventados das faixas de apresentação; fala cortada do veterano (`vet_discurso`), **sem citar nem parafrasear filme real**. |
| **Artista de Personagens** | Ciborgue: cair em pé, braço travado, bater no cotovelo. Urso: andar, sentar, sentado nos destroços, levantar. Veterano: pose motivacional com braço subindo, piscar. Cada um com a versão curta. |
| **Diretor de Arte** | Faixa de apresentação exagerada (crescendo a cada liga), holofotes, banco do córner inteiro e quebrado. |
| **Programador** | `versions` (completa na 1ª vez, curta depois), `say` com `cut_after`, `name_card` no estilo `show`. Sons: locutor, fanfarra própria de 4 notas, servo, lata, madeira. |
| **Diretor de Cutscenes** | Storyboards completos e os 3 arquivos de dados; conferir que a versão curta cabe em 1,5 s. |

## Fase 11 — Até onde chegamos

| Papel | Entrega |
|---|---|
| **Roteirista** | `fim_chegaram`, `fim_ver` e a troca da vitória final; título que substitui o nome na prévia antes do marco. |
| **Artista de Personagens** | **1º lutador mais velho** (mesmo corpo, grisalho, luva velha, sem símbolo): conjunto completo de luta, gesto lento e curto, `duck_under` e `walk` em vista de luta, `look_emblem`, sorriso, retrato e silhueta. Discípulo: levantar a cabeça. Poses da vitória final (mão estendida, levantar). |
| **Diretor de Arte** | Última arena (proposta) com a porta em x 382..464 e a lâmpada da garagem, ou a máscara de sombra do plano B; `final_door`; cartão de nome simples; brilho do símbolo; foto dos dois e o mural com as gerações. |
| **Programador** | Passos `frame` (janela 384x272 na luta) e `start_fight`; `grants` `reveal_opponent`; prévia em silhueta antes do marco. Sons: `glove_rub`, `intro_drums`. |
| **UI/UX** | Prévia e bloco PRÓXIMA LUTA em estado "desconhecido"; entrada do HUD quando a janela abre. `alinhamento-ui`. |
| **Diretor de Cutscenes** | Montar `reencontro_final.json` (com `short`); storyboard e dados da "Vitória final". |

## Ordem que destrava tudo
1. Dono escolhe o gesto e aprova (ou muda) a porta e o balão.
2. Diretor de Arte e Artista de Personagens fazem a **prancha de quadros-chave** das duas cenas (6a).
3. Dono aprova o animatic.
4. Só então o resto das poses e as outras cenas.
