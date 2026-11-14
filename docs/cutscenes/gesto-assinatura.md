# Gesto de assinatura do 1º lutador

Dono: Diretor de Cutscenes. Versão 1.1 (2026-11-13). **Opção A escolhida pelo dono (2026-11-11).** Uso na 6a confirmado na última seção.
**Nomes (dono, 2026-11-13):** o `primeiro` deste documento é **John Bullet**; o treinador é Osmar Brandão; a escola é Raízes Fight Club.
Por quê cedo: o reencontro final (fase 11) só funciona se o jogador tiver visto e ouvido o gesto dezenas de vezes na primeira hora de jogo.

O gesto precisa: (1) ler num boneco de ~64 px; (2) ter **som próprio**, para ser reconhecido fora de quadro; (3) caber em menos de 1 s, para entrar na luta sem atrasar nada; (4) poder ser mostrado com a cabeça escondida; (5) ter uma versão sem luvas, para a fase em que ele é mentor.

## Opções

### A. "Fecho e dois toques" — recomendada
Ele leva a luva esquerda à boca, **puxa o fecho com os dentes** (cotovelo abre, cabeça dá um tranco de 1 px), baixa e **bate o punho esquerdo duas vezes na luva direita**, na altura do peito. Volta à guarda.
- Som: `rrrip` (fecho) + `toc, toc` (couro em couro, intervalo fixo de 0,22 s). O ritmo dos dois toques é a assinatura sonora.
- Completo: 0,89 s (8 quadros a 9 fps). **Curto:** só os dois toques, 0,44 s (4 quadros a 9 fps).
- Sem luvas (mentor): punho fechado batendo duas vezes no outro punho. Mesmo ritmo, som mais seco.
- **Tem avesso:** tirar a luva abrindo o fecho com os dentes é a mesma pose ao contrário. É o que liga a primeira sucessão (ele tira) ao reencontro (ele aperta).
- Funciona com a cabeça escondida: a luva sobe, some atrás de uma borda, ouve-se o `rrrip`, ela desce e bate duas vezes.
- Risco: a mordida tem 1–2 px de boca. Quem carrega a leitura é a silhueta (luva na boca, cotovelo aberto) e os dois toques, não o detalhe do dente.

### B. "Bate na madeira"
Antes de começar qualquer coisa, ele bate duas vezes com os nós dos dedos no que estiver na frente (saco, batente, poste do córner) e encosta a luva na testa.
- A favor: conversa com o cenário; no reencontro ele bateria duas vezes na porta antes de entrar.
- Contra: depende de ter objeto ao alcance (no meio do ringue não tem); a silhueta parece um jab curto; não tem avesso; sem objeto o som some.

### C. "Risca o chão"
Arrasta a ponta do pé de trás duas vezes no chão, como quem marca o lugar, e arma a guarda. As marcas de giz da garagem seriam dele.
- A favor: liga o gesto ao chão da garagem; os pés aparecem primeiro numa entrada.
- Contra: são 2–3 px de movimento no pé (não lê); o som se confunde com passo; briga com a regra do pé de apoio fixo da `padrao-personagem`.

**Recomendação: A.** É a mais legível, a única com som inconfundível, tem versão curta, versão sem luva e avesso. É também o exemplo que o dono deu, com um ajuste: "testar a mão duas vezes" vira **dois toques de luva em luva**, porque toque tem som e silhueta; abrir e fechar a mão dentro da luva não aparece.

## Onde o gesto aparece no jogo (opção A)

Regra geral: **nunca soma tempo e nunca atrasa um clique.** Qualquer clique do jogador cancela o gesto na hora.

| Momento | Versão | Quem | Fase |
|---|---|---|---|
| Primeira imagem da Carreira 1 (abertura) | completa | `primeiro` | 6a |
| **Começo de toda luta** da Carreira 1 | completa, dentro da entrada que já existe (`intro_seconds` = 1,5 s; o gesto ocupa de 0,3 a 1,2 s) | `primeiro` | 6a |
| Vitória | curta, antes da pose de braços erguidos (dentro do `outro_seconds`) | `primeiro` | 6a |
| Calçar luva nova (depois de abrir a caixa da luva) | completa, uma vez | `primeiro` | 6a |
| Garagem parada (20 s sem clique) | curta, a cada 30–60 s | `primeiro` | 6a |
| **Primeira sucessão** | **avesso** (abre o fecho com os dentes e tira as luvas) | `primeiro` | 6b |
| 1º clique do discípulo; vitória do discípulo; discípulo passa a marca dele | sem luvas (dois toques de punho), no máximo 1 por minuto | `primeiro` como mentor | 6b–6c |
| Foto dele no mural | parado na pose da luva na boca | — | 6c |
| Afastamento do mentor | **não faz** (a saída é discreta) | — | 6c |
| Fases 7a a 10 | **o gesto some do jogo.** Só a foto lembra | — | — |
| **Reencontro final** | completa e mais lenta (1,4 s), primeiro com a cabeça escondida | `primeiro` mais velho | 11 |
| Lutas seguintes contra ele | curta, na entrada | `primeiro` mais velho | 11 |
| Vitória final (proposta para o storyboard da cena) | o **discípulo** faz o gesto pela primeira vez, na última imagem | `discipulo` | 11 |

Regras de dono do gesto:
- **Só ele faz.** Nenhum discípulo, mentor ou adversário usa os dois toques, até a última imagem do jogo. Se virar "gesto da escola", o reencontro perde o reconhecimento.
- O **intervalo de 0,22 s** entre os toques é o mesmo em todo lugar (garagem, luta, reencontro). Não acelerar nem variar.
- Numa primeira carreira de 10–15 minutos, o jogador vê o gesto umas 15–25 vezes; como mentor, mais umas 10. É o suficiente para gravar.

## O que o Artista de Personagens precisa (em `tools/art/personagem_lib.gd`)

Hoje o lutador do jogador vira o 1º lutador (sugestão do Diretor de Jogo). O que falta desenhar:

1. **Rosto novo "morde"** nos dois mapas: `FACES_34["bite"]` (garagem) e `FACES_SIDE["bite"]` (luta): boca aberta para o lado do punho, sobrancelha baixa. E **"sorriso"** leve (`smile`), diferente do `joy` da vitória (usado na sucessão e no reencontro).
2. **Fecho da luva:** uma ponta de fita de 2–3 px (`cream`) saindo do punho nos quadros da mordida, desenhada pelo gancho de pose `"end"`. Conferir se as 5 orientações de luva cobrem "antebraço subindo para a própria boca"; se não, um mapa novo (`GLOVE_MOUTH`).
3. **Folhas de animação** (mesmos quadros, pivôs e sufixos de luva das que já existem):

| Folha | Vista | Quadro | Quadros | fps |
|---|---|---|---|---|
| `fighter_gesture` | garagem 3/4 | 48x72, pivô (22,67) | 8 | 9 |
| `fighter_gesture_short` | garagem 3/4 | idem | 4 | 9 |
| `fight_player_gesture` | luta, perfil | 112x104, pivô (56,98) | 8 | 9 |
| `fight_player_gesture_short` | luta, perfil | idem | 4 | 9 |
| `mentor_first_taps` | garagem 3/4, sem luvas (`glove: "fist"`) | 48x72 | 4 | 9 |

Quadros da completa: 0 guarda · 1 luva esquerda sobe à boca, cabeça inclina (rosto `bite`) · 2 puxa (cabeça recua 1 px, cotovelo desce 2 px, fita esticada) · 3 solta, luva desce · 4 punho esquerdo recua 3 px · 5 **1º toque** · 6 separa 2 px · 7 **2º toque**. A curta são os quadros 4 a 7.
4. **No manifest:** `bite_frame: 1`, `tap_frames: [5, 7]` (para o som e as 2 faíscas de impacto) e as mãos por quadro (`hands`), como nos golpes.
5. **Regras da skill que apertam aqui:** comprimento do braço constante (IK) com a luva na boca; a luva gira com o antebraço; pés fixos durante todo o gesto.
6. Versões com as luvas da loja (`_glove_l1..l3` e a L4 da 5.2): o gerador já pinta por sufixo; conferir a fita do fecho em cada estilo.
7. **Fase 11:** o mesmo corpo mais velho (ver `reencontro-final.md`), com as mesmas folhas de gesto em vista de luta e a versão lenta de 1,4 s: os mesmos 8 quadros, com os quadros 0 a 4 a 5 fps e os quadros 5 a 7 no tempo normal (o intervalo de 0,22 s entre os toques não muda).

Sons (Programador, no gerador de sons): `strap_rip`, `strap_open` (o avesso), `tap_glove`, `tap_fist`.

## Fase 6a — onde e quando o gesto A toca (confirmado em 2026-11-13)

Batido com `docs/fases/fase6a-design.md` §3.2 (mesmos momentos e as chaves `gesture.*`). Só o John faz: `lutador_atual() == "first"`. O discípulo padrão **não faz**.

**Correção desta versão:** as duas folhas curtas passam de 10 para **9 fps**. A 10 fps os toques caíam com 0,20 s; a 9 fps caem com 0,22 s, igual à completa. O som do 2º toque sai de um temporizador de **0,22 s** depois do 1º, não do quadro.

Tempos dentro do gesto: completo (8 quadros, 0,89 s): `strap_rip` em 0,11 s (quadro 1), toques em 0,56 s e 0,78 s (quadros 5 e 7). Curto (4 quadros, 0,44 s): toques em 0,11 s e 0,33 s.

| Momento | Versão | Janela de tempo | Detalhe |
|---|---|---|---|
| **Abertura** | completa | t = 0,30 a 1,19 s da abertura | `abertura-6a.md`. Uma vez |
| **Começo de toda luta** da campanha dele | completa | dentro de `intro_seconds` (1,5 s): gesto de **0,30 a 1,19 s**; sobram 0,31 s em guarda antes do sino | `fight_player_gesture`. `strap_rip` em 0,41 s; toques em 0,86 e 1,08 s. `intro_seconds` não muda |
| **Vitória** | curta | dentro de `outro_seconds` (1,5 s): gesto de **0,15 a 0,59 s**; a pose de braços erguidos entra em 0,60 s | `fight_player_gesture_short`. Na derrota não toca |
| **Calçar luva nova** | completa | na garagem, 0,3 s depois de `caixa_aberta(item, "glove")`, já com a luva nova no lutador | uma vez por nível de luva (`career.gestured_gloves`). Cancelado pelo clique, conta como feito |
| **Garagem parada** | curta | 1ª aos **20 s** sem clique, com a sala ativa e sem balão | repete a cada 30–60 s (sorteio) enquanto parado. **Sugestão ao Designer:** no máximo 3 por período parado e som 6 dB mais baixo que na luta, para o jogo deixado aberto não ficar batendo toc-toc |

Regras (valem para os cinco):
1. **Qualquer clique cancela no mesmo quadro** (saco, botão ou fora do alvo) e o lutador volta à guarda; se o clique foi no saco, já é o soco normal naquele quadro. O `strap_rip` é cortado e o 2º toque não é agendado; um toque que já começou (0,075 s) termina.
2. **Nunca soma tempo.** O gesto é só visual: não trava clique, não mexe em `sala_ativa` nem em `_ocioso`, não segura relógio de luta, calendário nem janela. A duração da luta medida pelo QA tem que ser a mesma da 5.x.
3. O gesto só começa quando a folha atual é a parada (`fighter_idle` / guarda da luta). Não toca com janela aberta, com a sala escurecida nem no dia de luta parado.
4. **Um movimento por vez:** não começa enquanto um balão está escrevendo; o comentário do treinador que cairia durante o gesto espera ele acabar ou ser cancelado (`comments.after_gesture`).
5. Gesto cancelado não é refeito (o próximo gatilho traz outro).

Para o Designer confirmar: com `victory_short_before_pose`, a pose de braços erguidos entra 0,60 s depois do começo do `outro_seconds`, sem mudar o tempo total. Se não puder, o gesto curto da vitória é o primeiro a sair.
