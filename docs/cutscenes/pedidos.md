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
