# Balão de fala e voz — especificação final da 6a

Dono: Diretor de Cutscenes. Versão 1 (2026-11-13). Fase 6a.
Fecha os valores de `linguagem.md` §7. **Onde este documento e o §7 divergem, vale este** (ordem das notas por vogal, pausa de `:` e `;`). Ids e chaves seguem `docs/fases/fase6a-design.md` §1.1 (`first`, `coach`, `typing`, `voices`).
Todos os números vão para `data/` (arquivo e chaves são do Programador). Tela passa pela skill `alinhamento-ui`.

## 1. Peças (Diretor de Arte)

| Peça | Tamanho | Descrição |
|---|---|---|
| `ui_balloon` (9-slice) | 16x16, cantos de 5 px | fundo `cream`, contorno `ink` 1 px, canto arredondado de 2 px, **sombra dura de 1 px** embaixo e à direita (cor da paleta, sem alpha). Miolo liso |
| `ui_balloon_tail` | 7x6 | triângulo para baixo, ponta de 1 px, mesma cor e contorno. A linha de cima (1 px) é `cream` e **apaga o contorno** da borda de baixo do balão. Fica 5 px para fora |
| `ui_balloon_tag` (9-slice) | 9 px de altura, cantos de 2 px | plaquinha de nome, cor do personagem, texto 5x7 |
| `ui_balloon_next` | 5x4 | seta `▼` do modo de cena (2 quadros, 2 fps). Pronta na 6a, usada na 6b |

## 2. Medidas (px da base, sempre inteiras)

| Item | Valor |
|---|---|
| Fonte | 5x7 1x, **minúsculas**, avanço 6 px, cor `ink`, sem sombra |
| Linhas | no máximo **2**, de até **26 caracteres** cada. Quebra **escolhida pelo Roteirista** (`\n` no texto); o jogo não quebra nem hifeniza |
| Margem interna | 8 px à esquerda e à direita, 5 px em cima e embaixo; 2 px entre linhas |
| Largura | maior linha x 6 + 16. Mínimo 40, máximo **172** |
| Altura | 1 linha = **17** · 2 linhas = **26** · + 5 do rabicho · + 5 da plaquinha saindo por cima |
| Texto | linhas alinhadas à esquerda; o bloco fica centrado no balão |
| Tamanho | calculado com a **fala inteira** antes de escrever. O balão não cresce nem anda enquanto o texto aparece |
| Plaquinha | x = esquerda do balão + 6; y = topo do balão − 5. Largura = nome x 6 + 6; nome até 12 caracteres, minúsculas. Nos comentários do dia a dia aparece sempre |
| Entrada / saída | entra em 2 quadros (metade do tamanho, depois inteiro); some em 1 quadro. Sem fade |

Cor da plaquinha (proposta para o Diretor de Arte): `first` (John) = `r2` · `coach` (Osmar) = `y0` · discípulo padrão = `b3`.

Validação de texto (o Programador recusa no carregamento, com erro no log): linha > 26, mais de 2 linhas, linha começando com pontuação, caractere fora da fonte.

## 3. Posição em relação ao personagem

Cada personagem tem um **ponto da cabeça** (`head_anchor`): deslocamento fixo a partir do pivô dos pés, no manifest, tirado da pose parada. Proposta: `first` e discípulo (0,−62); `coach` a medir na folha parada. O balão usa sempre esse ponto, **não o quadro da animação**: não treme com soco nem com gesto.

Zona proibida `no_cover` = `click_area` com 2 px de folga = **(310,180,52,94)**, na garagem e na academia.
Área útil: sala (132..507, 22..285); na luta, tela inteira com 4 px de margem.

Ordem de tentativa:
1. **Em cima:** balão centrado em x no ponto da cabeça; a ponta do rabicho fica **6 px acima** do ponto. Empurrar para dentro da área útil.
2. Se tocar a `no_cover`: **deslizar para o lado** de onde o personagem está (cabeça à esquerda de x 336 → esquerda; senão direita) até a borda do balão ficar 2 px fora da zona.
3. O rabicho fica em `x = limitar(cabeça.x, balão.x + 8, balão.x + largura − 8)`. Se com isso ele ficar a **mais de 6 px** da cabeça, o passo 2 não vale: voltar ao centro e **subir** o balão até a ponta do rabicho ficar em y ≤ 178.
4. Se nada couber, a fala não toca (comentário descartado) e o log avisa.

Casos conferidos na conta (balão máximo, 2 linhas, com plaquinha):

| Quem | Ponto | Resultado |
|---|---|---|
| John (`first`) em `foco_saco` (303,272) | cabeça (303,210) | desliza: x 136..308, y 168..199, rabicho em x 300 |
| lutador em `foco_corda` (336,272) | cabeça (336,210) | sobe: rabicho termina em y 178 (flutua 32 px acima da cabeça) |
| Osmar (`coach`) em (236,238) | cabeça ≈ (236,176) | em cima, sem ajuste: x 150..322, y 134..165 |

Outras regras:
- **Um balão por vez** na tela.
- Fica acima da sala e **abaixo de qualquer janela**. Janela abrindo fecha o balão na hora (a fala é descartada).
- Não cobre a faixa de aviso do topo da sala: se houver faixa, o balão que subiria por cima dela não toca.

## 4. Texto aparecendo

| Item | Valor |
|---|---|
| Velocidade padrão | **28 caracteres/s** (1 a cada ~36 ms); por personagem, ver §6. Letra aparece inteira |
| Espaço | conta como caractere para o tempo; não toca blip |
| `,` `;` `:` | pausa de **0,12 s** depois do sinal |
| `.` `!` `?` | pausa de **0,28 s** |
| `...` | 0,13 s por ponto |
| `—` no fim | fala interrompida: o texto para e o balão some na hora |
| Último caractere | sem pausa: começa o tempo de leitura |
| Tempo de leitura (passivo e cena) | `max(1,2 s; 0,06 s x caracteres)` (`typing.hold_min`, `hold_per_char`); depois some sozinho |
| MAIÚSCULAS | no máximo 1 palavra por balão (ênfase) |

## 5. Acelerar e pular

**Modo passivo (o único usado na 6a):**
- O balão **não recebe mouse** (ignora o ponteiro). O clique no alvo e em qualquer botão passa direto.
- **Clique na sala fora da `no_cover`** (e fora de caixa, botão da árvore ou outro objeto clicável): completa a fala na hora, **sem blip**. O tempo de leitura continua. Segundo clique não faz nada (0,15 s de guarda, depois ignora).
- **Clique no saco: nunca completa, nunca fecha, nunca é consumido.**
- **ESPAÇO (decidido pelo Produtor em 2026-11-13, sobre a minha recomendação):** no modo passivo o ESPAÇO **só treina**, como já faz em `ui/garagem.gd`, e **não completa a fala**. Motivo: se completasse, quem treina no teclado completaria toda fala na primeira letra e nunca ouviria uma voz. Completar com ESPAÇO vale só no **modo de cena** (6b). Isto corrige o escopo §3.1, o design §5.2 e `fase6a-textos.md` §3, que diziam "ESPAÇO completa a fala". Chave `typing.space_completes_passive` = **false**.
- **Segurar ESC 0,5 s:** só na abertura, pula tudo (`abertura-6a.md` §6). Indicação mínima (UI/UX): texto pequeno `esc: pular` no canto de baixo da sala durante a abertura, com um filete que enche em 0,5 s. O botão PULAR com anel é da 6b.

## 6. Voz (blip)

### 6.1 Regras
- Contam só **letras e números** mostrados. Toca na 1ª, 3ª, 5ª... (um blip **a cada 2 letras**). Espaço e pontuação não contam.
- **Nota pela vogal:** usa a vogal do par (a letra que toca o blip ou a seguinte). Sem vogal no par, repete a última nota. Vogal acentuada vale a vogal simples; `y` = `i`; número = `a`.
- Escala por vogal, do grave ao agudo, dentro de uma quinta (segue o brilho natural das vogais):

| Vogal | u | o | a | e | i |
|---|---|---|---|---|---|
| Semitons acima da base | 0 | +2 | +4 | +5 | +7 |
| Multiplicador | 1,000 | 1,122 | 1,260 | 1,335 | 1,498 |

- Nos dados, `voices.<id>.vowel_steps` = `[0, 2, 4, 5, 7]` lido na ordem **u, o, a, e, i** (sugestão: gravar `"vowel_order": "uoaei"` ao lado, para ninguém ler como a-e-i-o-u).
- Um arquivo por timbre e por vogal (15 arquivos): a duração não muda com a nota.
- Na hora de tocar: variação aleatória de **±3%** (`pitch_scale` 0,97..1,03); palavra em MAIÚSCULAS x1,122 e +2 dB; fala terminada em `?`: os 3 últimos blips x1,06, x1,12, x1,19.
- **Um tocador só para a voz**: o blip novo corta o anterior.
- Fala completada no clique: nenhum blip.
- Volume: os arquivos saem cheios (pico perto do soco) e tocam com `typing.blip_volume_db` = **−8 dB**. Afinar por esse número, sem regerar.

### 6.2 Timbres da 6a

| Timbre (id) | Quem | Base (u) | Notas u·o·a·e·i (Hz) | Velocidade | Blips/s | Caráter |
|---|---|---|---|---|---|---|
| `first` | 1º lutador | 180 Hz | 180 · 202 · 227 · 240 · 270 | 28 c/s | 14 | "bup" macio, firme, de quem fala pouco |
| `coach` | treinador | 110 Hz | 110 · 123 · 139 · 147 · 165 | 22 c/s | 11 | grave e rouco, devagar |
| `disciple` | discípulo padrão (Carreira 2+) | 260 Hz | 260 · 292 · 328 · 347 · 390 | 30 c/s | 15 | limpo e leve, sem peso |

De olhos fechados a diferença tem que vir de três coisas juntas: altura (110 / 180 / 260), onda (rouca / quadrada macia / triangular) e ritmo (11 / 14 / 15 por segundo).
O `disciple` fica **gerado e pronto, sem uso na 6a**: pelo design, o discípulo padrão não fala nesta fase. Entra na 6b, quando chegam também as 3 alturas por nome (220/260/300).

### 6.3 Síntese (para `tools/sfx/make_sfx.gd`)
A ferramenta existe e hoje tem uma função por som, sem tabela de parâmetros. Pedido: uma função `_voz(timbre, f0)` e os 15 `_salvar("voice_<timbre>_<vogal>", ...)`. Formato igual ao resto: 22050 Hz, 16 bits, mono.
**Gerar depois de todos os sons que já existem**, porque o gerador de ruído tem semente fixa e a ordem muda os sons antigos.

| Parâmetro | `first` | `coach` | `disciple` |
|---|---|---|---|
| Duração | 0,040 s | 0,048 s | 0,034 s |
| Onda | quadrada (sinal do seno) passada num passa-baixa de 1 polo `lp += (x − lp) * 0,30`, mais 0,15 x seno da fundamental | quadrada com passa-baixa `* 0,18`, mais ruído | triangular pura |
| Ruído | não | ruído branco com passa-baixa `* 0,5`, ganho 0,30, **só na metade positiva da onda** (é a rouquidão) | não |
| Frequência no tempo | `f0 * (1 + 0,10 * exp(−t * 90))`: começa 10% acima e cai (o "bup") | `f0 * (1 − 0,05 * t / dur)`: cai um pouco | `f0 * (1 + 0,04 * t / dur)`: sobe um pouco |
| Ataque (linear) | 3 ms | 6 ms | 2 ms |
| Queda | `exp(−(t − ataque) * 38)` | `exp(−(t − ataque) * 26)` | `exp(−(t − ataque) * 45)` |
| Soltura (linear até zero) | últimos 5 ms | últimos 6 ms | últimos 4 ms |
| Pico final (depois de normalizar) | 0,85 | 0,90 | 0,78 |

Sem `tanh` no fim (a onda tem que ficar limpa); normalizar pelo pico. Começar a fase em 0 para não estalar.

### 6.4 Sons do gesto (mesma ferramenta)

| Som | Duração | Síntese |
|---|---|---|
| `strap_rip` | 0,16 s | Ruído branco com passa-alta (`x − lp`, `lp += (x − lp) * 0,25`), depois passa-baixa com coeficiente subindo de 0,35 a 0,80 (o rasgo fica mais agudo). Volume em **grãos**: um grão a cada 1/70 s no começo até 1/150 s no fim, cada um com `exp(−tg * 400)`. Envelope geral crescendo (`(t/dur)^0,6`), corte com 8 ms de soltura. Pico 0,5 |
| `tap_glove` | 0,075 s | Seno com `f = 150 + 90 * exp(−t * 60)` Hz e volume `0,8 * exp(−t * 48)`, mais ruído com passa-baixa `* 0,35` e volume `0,6 * exp(−t * 170)`. `tanh(v * 1,2)`. Pico 0,6. Mais curto e mais seco que `punch_N`, mais grave que `block` |

Os dois toques são **o mesmo arquivo tocado duas vezes, com 0,22 s exatos** entre os inícios (temporizador, não quadro de animação).
`strap_open` e `tap_fist` são da 6b.

## 7. Capturas para a `alinhamento-ui` (UI/UX)
Os 6 estados de `linguagem.md` §7.1 (1 linha, 2 linhas cheias, borda esquerda, borda direita, com plaquinha, tela de luta) mais:
- `primeiro` em `foco_saco` (caso "desliza"), garagem e academia;
- lutador em `foco_corda` (caso "sobe");
- `treinador` no ponto dele, garagem e academia.
Em todas: 0 problemas e nenhum pixel do balão dentro da `no_cover`.

## 8. O que o dono valida de ouvido
Reconhecer `first` e `coach` sem olhar; se o blip incomoda com clique rápido por cima. Se incomodar, primeiro baixar `typing.blip_volume_db`, depois passar para 1 blip a cada 3 letras (chave de dados), antes de pensar em desligar.
