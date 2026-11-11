# Cenas curtas — storyboards resumidos

Dono: Diretor de Cutscenes. Versão 1 (2026-11-11). Seguem a ideia do dono (`ideia-do-dono.md`) e a `linguagem.md`.
Falas são rascunho para o Roteirista. Posições na base 640x360, pelos pés. Os storyboards completos (quadro a quadro com dados) saem na fase de cada cena.

---

## 1. Primeira chegada à academia (fase 6c) — "o espaço ainda precisa virar casa"

**Gatilho:** a primeira vez que a escola chega à Academia Boa Esquina (qualquer discípulo), logo depois da mudança e **antes** da janela de escolha da arte. Marco `cena_chegada_academia`. Save antigo que já esteve na academia: toca na próxima chegada.
**Tempo preso:** ≈ 13 s. **Registro:** cotidiano, com uma piada no fundo.
**Palco:** `gym_bg` **sem aparelhos e sem gente**, um tubo de luz só (o outro apagado). Porta da rua à direita (x ≈ 404..454).

| # | Tempo | O que acontece | Som |
|---|---|---|---|
| 1 | 0,0–2,0 | A interface apaga. Academia vazia, meio escura, um tubo piscando. A porta da rua abre. | tubo zumbindo; porta |
| 2 | 2,0–6,0 | A equipe entra em fila, da porta para a esquerda: o **lutador da campanha** com o **saco remendado** no ombro, até (303,272); atrás, alguém com uma **caixa** (o 1º mentor, se ainda estiver na escola; senão um ajudante do bairro); no fundo, um **ajudante tenta passar com a esteira velha atravessada na porta**: bate, recua, bate de novo. Ele continua tentando ao fundo até o fim da cena. | passos; baque de metal na porta (2x) |
| 3 | 6,0–10,0 | **Corte para 2x** na parede. O `treinador` pendura a **fotografia antiga**, dá um passo atrás, inclina a cabeça e **entorta a foto um pouco**, do jeito que ela ficava na garagem. **"Agora sim."** | prego; moldura raspando; blip |
| 4 | 10,0–13,0 | **Corte para 1x:** o segundo tubo acende, o saco é pendurado no gancho (poeira), o ajudante finalmente passa com a esteira de lado. A academia aparece inteira. Interface de volta; abre a escolha da arte. | 2 estalos de tubo; `fx_arrive_dust` |

**Se pular:** academia montada, foto na parede, janela da arte aberta.
**O que fica:** a foto antiga na parede da academia (torta), para sempre. Proposta: a foto acompanha a escola, isto é, aparece na garagem quando o discípulo treina na garagem e na academia quando ele está na academia; a garagem não fica "abandonada".
**Chegadas seguintes (outras campanhas):** sem cena. O discípulo entra pela porta (2 s, sem prender o controle) e a foto já está lá.
**Elenco depende do estado:** o lutador pode ser o próprio 1º lutador (se a Carreira 1 chegar lá) ou um discípulo; a cena não muda.

Fala: `acad_agora_sim` — `treinador`: "Agora sim."

---

## 2. Afastamento do primeiro mentor (fase 6c) — ação no cenário

**Jogador no controle o tempo todo.** Sem barras, sem interface apagada, sem música, sem plano 2x, sem gesto de assinatura. Balões no modo passivo.
**Gatilho proposto (ajuste ao item 8 do feedback, para o Diretor de Jogo decidir):** na **volta à sala depois da 1ª vitória de um discípulo (Carreira 2+) na academia**. Se disparasse na própria chegada à academia, cairia junto com a cena da chegada e a escolha da arte. Reserva: início da Carreira 4, na garagem. Marco `cena_saida_primeiro_mentor`.
**Duração:** ≈ 12 s de ação ao fundo.

| # | Tempo | O que acontece | Som |
|---|---|---|---|
| 1 | 0–3 | `primeiro` levanta do lugar dele, pega uma **bolsa** e anda até perto da saída. | passos |
| 2 | 3–6 | Para, vira e **olha a sala** (1,5 s). **"Vou procurar meu rumo. Cuidem bem disso aqui."** | blip |
| 3 | 6–9 | Alguém responde sem parar o que está fazendo (o `treinador`, ou quem estiver na sala): **"Vê se manda notícia."** Ele acena com a cabeça. | blip |
| 4 | 9–12 | Ele sai. A porta fecha. O treino continua. | porta |

**Se o jogador abrir janela ou luta no meio:** a cena termina na hora, com ele já fora.
**O que fica:** o lugar dele vazio (o caixote continua; o próximo mentor senta lá). A foto dele já estava no mural desde o fim da campanha dele. **Nenhum objeto deixado para trás.**
**Na garagem (reserva):** igual, e ele passa por baixo da porta de enrolar como sempre fez. Sem ênfase.

Falas: `saida_rumo` — `primeiro`: "Vou procurar meu rumo. Cuidem bem disso aqui." (2 balões) · `saida_resposta` — `treinador`: "Vê se manda notícia."

---

## 3. Vinhetas de adversário (fase 10) — registro Espetáculo

Regras das três:
- Tocam **na entrada da luta**. **Completa (3–5 s) só na primeira vez** que a escola enfrenta aquele adversário (marco `vinheta_<id>`); depois, **curta (≤ 1,5 s)**, que cabe na entrada normal: a piada não atrasa nenhuma tentativa.
- Faixa de apresentação exagerada (nome em 2x, título inventado, estouro de cor), holofotes, torcida.
- A piada é com o adversário e com o objeto. Nomes e títulos são do Roteirista.
- Pular: sino e luta, com o adversário já na guarda.

### 3a. Ciborgue (≈ 4 s)
| Tempo | O que acontece | Som |
|---|---|---|
| 0,0–1,2 | Luz apaga. Uma linha vermelha varre a arena. Ele **cai do alto** em pé (tremida de 2 px). Faixa de apresentação. | queda metálica; locutor em blip |
| 1,2–2,4 | Ergue os braços para a pose imponente. O braço direito **trava no meio do caminho**. | servo subindo e engasgando |
| 2,4–3,4 | Ele olha o braço e **bate três vezes no próprio cotovelo**, cada vez mais forte. O braço destrava e sobe de uma vez. (Três, e irregulares: os dois toques ritmados são só do 1º lutador.) | 3 batidas de lata; "plim" |
| 3,4–4,0 | Guarda. Sino. | `bell_start` |

Curta: entra já dando um tapa no cotovelo; guarda; sino.

### 3b. Urso (≈ 4,5 s)
| Tempo | O que acontece | Som |
|---|---|---|
| 0,0–1,2 | Faixa de apresentação. O urso anda até o córner, calmo. | passos pesados; torcida |
| 1,2–2,2 | Senta no **banco do córner**. | madeira rangendo |
| 2,2–2,8 | O banco **quebra** (tremida de 1 px). | estalo |
| 2,8–3,8 | **Ele continua sentado nos destroços**, sem expressão. Um segundo parado. | silêncio; uma tosse na torcida |
| 3,8–4,5 | Sino. Ele levanta. | `bell_start` |

Curta: já começa sentado nos destroços; levanta no sino. Os destroços ficam no chão durante a luta. Opcional: a cada nova tentativa, um banco quebrado a mais na pilha (até 3).

### 3c. Veterano de cinema (≈ 4 s)
| Tempo | O que acontece | Som |
|---|---|---|
| 0,0–1,0 | Faixa de apresentação. Luz de contraluz. Começa uma **fanfarra** (4 notas subindo, nossa). | fanfarra |
| 1,0–3,0 | Ele vira de perfil, ergue o braço devagar para a **pose motivacional** e começa a falar: "Escuta, campeão: lá em cima, na montanha, eu aprendi que" | blip lento com vibrato |
| 3,0–3,4 | **O sino toca antes de ele terminar.** O balão some no meio da frase e a fanfarra para como fita cortada. Ele pisca, com o braço ainda no ar. | `bell_start`; fanfarra cortada |
| 3,4–4,0 | Baixa o braço, arma a guarda. Luta. | — |

Curta: ergue o dedo, "Escu", sino.
**Cuidado de identidade:** personagem, fala e fanfarra são nossos. A piada é com o costume do discurso motivacional de filme de luta, não com um filme. O Roteirista não usa nem parafraseia frase de filme real; a fanfarra não pode lembrar tema conhecido.

Fala: `vet_discurso` — veterano: "Escuta, campeão: lá em cima, na montanha, eu aprendi que" (cortada pelo sino).

---

## 4. Ainda por fazer (fase 11)
- **Vitória final:** mão estendida, a troca de falas, corte para a academia, foto dos dois no mural, o quadro abre para as fotos das gerações, som de alguém treinando. Storyboard completo depois que o reencontro for aprovado. Proposta já anotada: na última imagem, o discípulo faz o gesto do 1º lutador pela primeira vez.
- **Abertura da 6a** (garagem em dificuldade, humilhação): depende de o Roteirista definir a forma da humilhação.
