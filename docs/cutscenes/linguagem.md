# Cutscenes — guia de linguagem

Dono: Diretor de Cutscenes. Versão 1 (2026-11-11).
Base: `docs/cutscenes/ideia-do-dono.md`, `docs/direcao-narrativa.md` (manda), `docs/arte/direcao-visual.md`, `assets/sprites/manifest.json`.
Tudo aqui é proposta até o dono aprovar. Nomes de personagens são provisórios: `primeiro` (1º lutador), `treinador` (treinador original), `discipulo` (lutador da campanha atual).

## 1. Ideia em uma frase
A cena é **a própria sala com a interface apagada**: ninguém troca de tela, a câmera quase não se mexe, e o que emociona é reconhecer um gesto, um som e um lugar que o jogador já viu centenas de vezes treinando.

Três regras que decidem qualquer dúvida:
1. **O gesto antes da fala.** Primeiro a pose, depois (se precisar) o texto. Se a cena funciona sem o balão, ela está certa.
2. **Um movimento por vez.** Enquanto alguém faz um gesto ou fala, o resto só respira.
3. **A cena não é dona de nada.** O que muda no jogo (marco, foto no mural, mentor presente) é gravado pelo jogo no gatilho; a cena só *mostra*. Por isso pular nunca quebra nada.

## 2. Câmera e enquadramento

Base 640x360, pixel inteiro, sem rotação, sem escala quebrada, sem zoom suave (zoom suave passa por escalas não inteiras). Só existem **três planos**:

| Plano | O que é | Quando |
|---|---|---|
| **Plano da sala (1x)** | A sala fica **exatamente onde está no jogo** (x 128..511, y 18..289 = 384x272). Some a interface: painéis laterais e barras viram `ink`. A "janela de cena" é o retângulo da sala. | Padrão. 80% do tempo de qualquer cena. |
| **Plano médio (2x)** | **Corte seco** para uma região de 192x136 da sala, mostrada em 2x dentro da mesma janela 384x272. A sala inteira é ampliada junto (nunca um sprite só). Pode deslizar em pixel inteiro da origem (1 px da origem = 2 px na tela), no máximo 24 px por cena. | Um gesto de mão que não se lê em 1x. **No máximo 1 por cena** nas cenas do cotidiano. |
| **Janela na luta** | Na tela de luta (640x360 inteira), a cena fecha a imagem na **mesma janela 384x272**, em (128,52), com pilares laterais e barras `ink`. Ao devolver o controle, a janela **abre** para os 640. | Reencontro final e vinhetas de adversário. |

Regras:
- **Barras = a interface apagada.** Na sala, a barra de cima cobre o HUD (y 0..17) e a de baixo cobre a barra de botões (y 290..359); os painéis laterais escurecem. Não existe barra por cima do cenário: nada da sala é cortado.
- **Sem fade para preto** nas cenas do cotidiano: a cena nasce da sala viva e volta para ela. Fade (3 passos de dither `ink`) só para elipse de tempo, e só na vitória final.
- **Corte** só existe entre 1x e 2x. Máximo de 2 cortes por cena (ir e voltar).
- **Tremida** de 1 px só em impacto físico (banco quebrando, porta emperrando). Nunca para "drama".
- **Luz como enquadramento:** a garagem tem uma lâmpada só e cantos escuros; a academia, tubos frios. Entrar e sair da luz vale mais que mexer a câmera. Sombra por cima de personagem = sprite de máscara em dither, sem multiplicação livre de cor (regra da direção visual).
- **Esconder parte de alguém** se faz com o cenário (porta de enrolar meio aberta, borda da luz), não com a borda da tela.
- O plano 2x aumenta o pixel dos placeholders; se no animatic o gesto ler bem em 1x, o corte sai.

## 3. Tempo e gestos

| Coisa | Valor |
|---|---|
| Duração total (com controle preso) | cotidiano 10–15 s · reencontro e vitória final até 25 s · vinheta 3–5 s (versão curta ≤ 1,5 s) |
| Animação | 8–12 fps, poses-chave autorais (skill `padrao-personagem`) |
| Pose-chave | antecipação de 2 quadros, depois **segurar ≥ 0,4 s**. Pixel art se lê parado. |
| Andar | 48 px/s normal · 32 px/s cansado ou solene · 72 px/s apressado/cômico. Sempre pixel inteiro. |
| Pausa sem texto | 1 por cena, de 2 a 3 s, reservada ao momento de reconhecer |
| Texto | cotidiano: até 3 balões por cena, 2 linhas, 26 caracteres por linha |
| Olhar | virar a cabeça (ou o corpo) **antes** de andar ou falar com alguém |

Vocabulário de gestos (repetir sempre os mesmos, para o jogador aprender a ler):
- **Parar o saco com as duas mãos** = acabou o treino.
- **Olhar para a entrada** = alguém vem.
- **Passar por baixo da porta de enrolar emperrada** = chegar nesta escola (todo mundo que entra faz).
- **Mão aberta apontando um lugar no chão** = "é a sua vez".
- **Gesto de assinatura do 1º lutador** (`docs/cutscenes/gesto-assinatura.md`) = só ele.

## 4. Como a cena começa, termina e devolve o controle

**Começo (0,3 s):**
1. O jogo grava o marco e salva (ver §5). O relógio do calendário para.
2. A interface apaga em 2 quadros de dither (50% → `ink`). A sala não se mexe.
3. **Guarda de clique:** os primeiros 0,4 s ignoram clique e tecla. O jogador de clicker está clicando rápido quando a cena começa; sem isso ele pularia a primeira fala sem ver.
4. Quem já estava se mexendo na sala termina o ciclo e para. O primeiro gesto novo começa aos 0,5 s.

**Fim (0,25 s):**
1. Os personagens da cena já estão **no ponto e na pose em que o jogo os desenha** (o discípulo em `foco_saco` com `fighter_idle`, o mentor no ponto dele). Não existe "troca" visível.
2. A interface volta. **O clique no alvo já vale no primeiro quadro da volta**, antes de os painéis terminarem de aparecer.
3. Gestos que sobraram (alguém indo sentar, porta descendo) continuam **com o jogador no controle**.
4. Se a cena prepara uma reação ("no primeiro clique o mentor reage"), ela fica armada e toca por cima do treino, sem prender nada.

**A cena nunca espera o jogador.** Os balões avançam sozinhos. A única espera permitida é uma tela obrigatória (criar o discípulo).

**Fila:** uma cena por vez. Nunca começa por cima de uma janela aberta, no dia de luta parado, nem durante uma luta (exceto as vinhetas de entrada, que são da luta). Se duas ficarem prontas juntas, a segunda espera o próximo momento calmo.

## 5. Pular

- **Clique ou ESPAÇO:** completa a fala que está sendo escrita; de novo, passa para o próximo passo com fala. Não pula a cena.
- **Segurar ESC ou ESPAÇO por 0,5 s, ou clicar em PULAR:** pula a cena. O botão PULAR (canto inferior direito da faixa de baixo, com um anel que enche) aparece no primeiro toque do jogador e some sozinho em 2 s.
- **Pular = ir para o estado final em até 0,3 s:** personagens no ponto final, objetos no lugar, interface de volta. Sem tela preta.
- **O marco fica gravado mesmo ao pular**, porque foi gravado **no começo** da cena, junto com tudo que ela dá (foto, mentor na sala). Fechar o jogo no meio da cena também não a repete.
- Pular até uma tela obrigatória para nela (criar o discípulo); depois dela dá para pular de novo.
- Cena sem controle preso (afastamento do mentor) não tem botão: qualquer ação do jogador que abra janela ou luta termina a cena no estado final.
- **Nenhuma informação de jogo mora só na cena.** O que a cena ensina (ex.: "a carreira passou para outro") também está na interface.

## 6. Evolução da linguagem ao longo do jogo

| | **Cotidiano** (6a–8b) | **Espetáculo** (9–10) | **Simples** (11) |
|---|---|---|---|
| Onde | garagem, academia | arenas das ligas altas e torneios secretos | a última arena, quieta |
| Plano | sala 1x; um 2x em gesto de mão | 1x aberto, holofotes, faixas, tremidas | a mesma janela 384x272 da garagem, dentro da arena |
| Cortes | 0 a 2 | 2 a 4, rápidos | 2 |
| Nome na tela | não tem | **faixa de apresentação** exagerada: nome em 2x, apelido, título inventado, estouro de cor | só o nome, em 1x, sem título nem moldura |
| Som | sons da sala (corrente, lâmpada, porta) | bumbo, fanfarra, torcida, locutor em blip agudo | passos, couro, lâmpada; sem música |
| Humor | pequeno e no fundo do quadro | é o assunto da vinheta | nenhum |
| Ritmo | calmo, pausas curtas | 3–5 s, uma piada, sino | lento, com a pausa de 2–3 s |
| Texto | 1 a 3 balões | 0 ou 1 (pode ser interrompido) | 2 balões |

O exagero cresce **de liga em liga** (cada vinheta um pouco mais alta que a anterior), para que o silêncio do reencontro seja sentido como falta de barulho. A última cena começa como mais uma apresentação exagerada e **desliga**: holofotes procuram, ninguém aparece, apagam; sobra uma lâmpada.

O que nunca muda, em nenhum registro: o balão, o blip de voz, as regras de pular e a sinceridade entre mestre e discípulo (piada só com adversário e com objeto, nunca com o vínculo).

## 7. Fala: balão e voz

### 7.1 Balão
Um componente só, usado nas cenas e nos comentários do dia a dia. É um **balão preso ao personagem** (não uma caixa no rodapé): o olho fica no gesto e os pés não são cobertos.

| Item | Valor (px da base) |
|---|---|
| Largura | do texto + 8 de margem de cada lado; máximo 172 (26 caracteres de 6 px) |
| Altura | 1 linha = 17 · 2 linhas = 26; mais 5 do rabicho |
| Posição | centrado 6 px acima da cabeça de quem fala; empurrado para caber na janela de cena com 4 px de margem; o rabicho continua apontando a cabeça |
| Cores | fundo `cream`, contorno `ink` 1 px, sombra 1 px; texto `ink` sem sombra |
| Fonte | 5x7 1x, **com minúsculas** (a interface é toda em maiúsculas; minúscula = voz de gente) |
| Nome | plaquinha na borda de cima, à esquerda, na cor do personagem. Aparece na 1ª fala de cada personagem na cena; nos comentários do dia a dia, sempre |
| Fim da fala | seta `▼` piscando a 2 fps no canto (só em cena) |
| Entrada/saída | 2 quadros (meio tamanho → inteiro); some em 1 quadro |

Dois modos:
- **cena:** dentro de uma cutscene; avança sozinho ou no clique.
- **passivo:** comentário com o jogador no controle; não recebe clique, não bloqueia nada, some sozinho, nunca cobre o alvo central (se o personagem estiver perto do alvo, o balão vai para o lado de fora).

O balão passa pela skill `alinhamento-ui` (texto centrado, nada cortado, posições inteiras, 0 problemas) em pelo menos estes estados: 1 linha, 2 linhas cheias, encostado na borda esquerda, encostado na direita, com plaquinha de nome, na tela de luta.

### 7.2 Texto aparecendo
| Item | Valor |
|---|---|
| Velocidade padrão | **28 caracteres por segundo** (1 letra a cada ~36 ms). Letra aparece inteira, sem fade |
| Vírgula | pausa de 0,12 s |
| Ponto, `!`, `?` | pausa de 0,28 s |
| Reticências | 0,13 s por ponto (0,4 s no total) |
| Travessão / corte de fala | o texto para e o balão some na hora (fala interrompida) |
| Depois da última letra | o balão fica `max(1,2 s; 0,06 s x nº de caracteres)` e avança sozinho |
| Clique enquanto escreve | completa a fala na hora, sem som |
| Guarda de clique | 0,15 s depois de completar, para o clique rápido não pular a fala seguinte |
| Velocidade por personagem | pode variar de 12 a 34 c/s (ver timbres) |

### 7.3 Voz (blip)
Estilo do gênero (som curto repetido enquanto o texto aparece), **feito por nós**: sintetizado pelo nosso gerador (`tools/sfx/make_sfx.gd`), sem amostra de fora e sem imitar a voz de nenhum jogo.

- Um blip a cada **2 letras** mostradas (espaço e pontuação não contam nem tocam). Na velocidade padrão dá ~14 blips por segundo.
- Cada blip dura 35–45 ms. Um blip novo corta o anterior (nunca empilha).
- **A vogal muda a nota:** cada personagem tem 5 notas (a, e, i, o, u), da mais grave à mais aguda dentro de uma quinta. A fala ganha melodia de sílaba sem gravar voz.
- Variação aleatória de ±3% na nota, para não soar máquina.
- `?` no fim: os 3 últimos blips sobem. PALAVRA EM MAIÚSCULAS: +2 semitons e um pouco mais forte.
- Volume: mais baixo que o soco no saco (cerca de −8 dB). O clique continua sendo o som principal do jogo.
- Texto completado no clique não toca blip.

Timbres (ponto de partida; o Roteirista descreve a voz, o Programador afina):

| Personagem | Timbre | Nota base | Velocidade |
|---|---|---|---|
| `primeiro` (1º lutador) | onda quadrada macia, ataque curto ("bup") | ~180 Hz | 28 c/s |
| `primeiro` no reencontro | **o mesmo timbre**, uma terça abaixo, com um leve chiado | ~145 Hz | 24 c/s |
| `treinador` | grave e rouco (quadrada + ruído) | ~110 Hz | 22 c/s |
| `discipulo` | triangular limpa; 3 variações de altura escolhidas pelo nome (sem tela nova) | 220 / 260 / 300 Hz | 30 c/s |
| mentores seguintes | herdam o timbre que tinham como discípulos | — | 26 c/s |
| rival | serrilhada, nasal | ~240 Hz | 32 c/s |
| locutor das vinhetas | pulso estreito, agudo e estridente | ~520 Hz | 34 c/s |
| ciborgue | uma nota só (não muda com a vogal), com modulação metálica | 330 Hz | 20 c/s, regular |
| urso | ruído grave filtrado | ~70 Hz | 12 c/s |
| veterano de cinema | quadrada cheia com vibrato | ~160 Hz | 18 c/s, com pausas longas |

O timbre do 1º lutador é o que o jogador mais ouve nas fases 6a–6c. No reencontro, o ouvido reconhece antes de o nome aparecer.

## 8. Checagem de toda cena antes de entregar
1. Cabe no tempo (§3) e tem versão pulada com o mesmo estado final.
2. Funciona sem ler nenhum balão.
3. Funciona se a 1ª carreira durou 3 minutos e em save antigo com várias carreiras.
4. Não repete depois de reset; se o momento se repete, existe a versão curta.
5. Começa e termina com os personagens nos pontos do jogo (`manifest.json`).
6. Todas as posições são inteiras; nenhum sprite fora da grade.
7. Balões passaram pela `alinhamento-ui`.
8. Nada lembra fala, personagem ou música de outra obra.
