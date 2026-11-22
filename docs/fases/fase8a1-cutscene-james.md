# Fase 8a1 — apresentação do James Blindado (storyboard)

Dono: Diretor de Cutscenes. Versão 1 (2026-11-21).
Base: `fase8a-escopo.md` §3.3 (decisão do dono: James só no cartaz, apresentação antes da luta e 1 fala depois; zomba da
escola, nunca do jogador; continua arrogante ao perder), `fase8a1-design.md` §5, `fase8a1-textos.md` §5, `data/dialogos.json`
(cast `rival`, voz `rival`, falas `rival_james_*`), `docs/cutscenes/balao-e-voz.md` (balão e blip, vale tudo de lá).

**Não é cena nova.** Nada vai para `data/cutscenes/`, não passa pelo `CenaPlayer`, não tem `grants` nem `end_state`.
É a **tela de luta normal** com uma espera antes do "1º ROUND" e o **balão de fala** já existente em cima da cabeça do James.
Quem escolhe a situação e grava `rival_spoke` / `escola.rival` é o código (design §5, §8). A luta já está decidida por
`GameState.lutar()` antes da apresentação: pular ou assistir não muda nada. Nenhuma mecânica depende de ler a fala.

## 1. Onde acontece
- **Gatilho:** `james_intro`, ao apertar LUTAR contra `opp_james`, se `career.rival_spoke.before == false` (1 vez por campanha).
  Ids tocados **em ordem**, grupo escolhido por `escola.rival` (textos §5.2): `first` (met == 0) → `many` (met ≥ 3) →
  `school_won` (school_wins ≥ 1) → `revenge`.
- **Palco:** a tela de luta como ela abre hoje: arena regional, jogador em (296,318), James em (346,318), HUD com o **retrato
  e o nome dele** no canto direito (é ali que o retrato aparece; a caixa de diálogo é o balão com a plaquinha "james").
- **Relógio parado:** o relógio da luta não anda, nada de "1º ROUND" nem público gritando até a apresentação acabar.
  Depois dela, a entrada normal de 1,5 s segue igual (1º ROUND → LUTEM! + sino).

## 2. Storyboard — 1º encontro (`first`, 3 falas)

Tempos medidos com os números de `dialogos.json` (rival 32 c/s; pausas 0,12/0,28; leitura `max(1,2; 0,06 x letras)`;
0,3 s entre falas). "t" conta do aperto em LUTAR.

| Quadro | t (s) | James | Jogador | Balão / som |
|---|---|---|---|---|
| J0 Abre | 0,0–0,6 | `guard` fechada (a pose do 1º round, ver §5), parado, queixo erguido | `idle` de guarda | público baixo (`sfx.publico(-16)` como hoje), sem sino |
| J1 | 0,6–2,6 | sai da guarda para `idle`, olha a plateia de lado | idem | `rival_james_intro_first_1` "então é essa a raízes?" — 0,7 s escrevendo + 1,3 s de leitura |
| J2 | 2,9–6,5 | `idle`; **gesto de desprezo** começa quando aparece o "f" de "fofo." (≈ 1,2 s depois do início da fala) e dura 0,9 s | idem | `rival_james_intro_first_2` "ainda batendo em saco / de areia? fofo." — 1,4 + 2,2 s. `tap_glove` 1x no quadro em que a luva "espanta" |
| J3 | 6,8–11,1 | volta à guarda **fechada** nas últimas 0,4 s da leitura (anuncia a passiva Blindado sem texto) | idem | `rival_james_intro_first_3` "o cinturão fica aqui. / na academia de verdade." — 1,7 + 2,6 s |
| J4 Luta | 11,1–12,6 | guarda fechada | guarda | entrada normal: 1º ROUND, LUTEM!, sino. Luta começa |

**Total do LUTAR ao sino: ~12,6 s** (limite 15 s). Só as falas: 10,5 s.

## 3. Variações (2 falas cada, cabem com folga)

| Situação | Falas (ids `_1`, `_2`) | Falas (s) | LUTAR → sino | Onde entra o gesto |
|---|---|---|---|---|
| `revenge` | voltaram? a raízes / não se cansa? · mesma sala, mesma sorte: / nenhuma. | 6,6 | ~8,7 s | na fala 2, ao aparecer "nenhuma." |
| `school_won` | de novo a raízes? / isso virou mania. · aquilo foi sorte. / sorte não se repete. | 7,3 | ~9,4 s | na fala 1, ao aparecer "mania." (ele finge tédio) |
| `many` (3+) | vocês, outra vez. / já decorei o cartaz. · vamos ver o que / ensinaram desta vez. | 7,3 | ~9,4 s | na fala 1, ao aparecer "cartaz." |

Em todas: J0 (0,6 s, guarda) → falas → volta à guarda nas últimas 0,4 s da última leitura → entrada normal de 1,5 s.
**O gesto de desprezo sai 1 vez por apresentação, sempre.** Nunca é dirigido ao jogador: a luva "espanta" para o lado da
plateia/cartaz, não para o rosto do discípulo.

Regra de corte (garante ≤ 15 s mesmo se o Roteirista alongar falas): se a soma passar de **13,0 s** de falas, a leitura de cada
fala cai para `max(1,2; 0,04 x letras)` só nesta apresentação. Com as falas de hoje isso nunca acontece.

## 4. Pular e acelerar
Tela de luta não tem clique de treino, então vale o **modo de cena** do balão (`balao-e-voz.md` §5, 6b), sem faixas pretas:
- **Clique em qualquer lugar da tela ou ESPAÇO:** 1º toque completa a fala (sem blip); 2º toque (depois de 0,15 s de guarda)
  pula para a próxima fala. Seta `ui_balloon_next` no canto do balão quando a fala está completa.
- **Segurar ESC 0,5 s** (ou o botão **PULAR** com anel, o mesmo do `CenaUi`, em (570,334,62,18)): encerra a apresentação na
  hora. O James vai para a guarda fechada e começa a entrada normal de 1,5 s. Ninguém pula a luta por aqui.
- Pular ou fechar o jogo no meio dá o mesmo save: `rival_spoke.before = true` é gravado **quando a apresentação começa**
  (como o `grants` das cenas). Reabrir o jogo não repete a apresentação nesta campanha.
- Janela que abre por cima (pausa, opções) fecha o balão; ao voltar, a apresentação é encerrada como se pulada.

## 5. Pedidos ao Artista de Personagens (`padrao-personagem`)
Conferido em 2026-11-21: ainda **não há** sprite do James em `assets/sprites/opponents/` nem no manifest. Nomes pedidos
(seguir o padrão dos outros: `by_data_id.opp_james.actions`, quadro 112x104, pivô (56,98), `facing: esquerda`):

| Nome lógico | Sprite | Uso nesta apresentação | Notas |
|---|---|---|---|
| `guard` | `opp_james_guard` | J0 e fim de cada variação; é a pose do 1º round (Blindado) | guarda **fechada**: antebraços colados na frente do rosto, cotovelos no tronco, queixo baixo atrás das luvas. Lê "não fura" de longe |
| `idle` | `opp_james_idle` | durante as falas | **peito estufado, queixo erguido, olhar por cima** (vaidoso). Mãos baixas, relaxado: ele não leva a escola a sério |
| `scorn` (gesto de desprezo) | `opp_james_scorn` | 1x por apresentação, 0,9 s, ~6 quadros a 7 fps | proposta: ele olha para a própria luva como quem tira um fiapo, **dá um peteleco/abano curto para o lado** (espantando a "escola" como poeira) e volta ao idle sem olhar para o adversário. Pico do abano no quadro 4 (é ali que toca `tap_glove`). Nada de dedo apontado nem gesto ofensivo |
| retrato | `portrait_opp_james` (+ moldura) | HUD da luta e prévia; identifica quem fala | mesma expressão do `idle`: sobrancelha arqueada, meio sorriso de canto. Moldura: sugiro `ui_portrait_frame_gold` (dono do cinturão, como o Muralha) — decisão do Diretor de Arte |
| `victory` / `ko` / `tired` | do rig comum | fala de depois (§7) | o `victory` dele pode reaproveitar o `scorn` no fim (ver §7) |

Também preciso no manifest: `scale` (sugiro 1,12, como o Muralha) e, se a cabeça dele ficar fora do padrão, um
`head_point` próprio. O balão usa o `head_point` (4,−80) x escala, espelhado: com 1,12 a cabeça fica em (342,228).

## 6. Som de voz
- Timbre `rival` já está nos dados (240 Hz, 32 c/s, 1 blip a cada 2 letras → 16 blips/s, o mais rápido do elenco: fala
  apressado, de quem não tem tempo para a escola). Notas u·o·a·e·i: **240 · 269 · 302 · 320 · 360 Hz**.
- **Faltam os 5 arquivos** `assets/sfx/voice_rival_{u,o,a,e,i}.wav`. Síntese para `tools/sfx/make_sfx.gd` (`_voz("rival", f0)`),
  "serrilhada e nasal", diferente dos outros três de olhos fechados:

| Parâmetro | `rival` |
|---|---|
| Duração | 0,036 s |
| Onda | **dente de serra** (`2 x fase_normalizada − 1`), passada num passa-alta de 1 polo (`hp = x − lp; lp += (x − lp) * 0,10`, tira o peito da voz = nasal) e depois passa-baixa `* 0,45` (lixa o agudo sem perder o serrilhado) |
| Frequência no tempo | `f0 * (1 + 0,02 * sin(TAU * 30 * t))`: tremidinho curto, o "serrilhado" |
| Ruído | não |
| Ataque / queda / soltura | 2 ms / `exp(−(t − ataque) * 40)` / últimos 4 ms |
| Pico final | 0,75 (serra soa mais alta que a quadrada no mesmo pico) |

  Gerar **depois de todos os sons que já existem** (o ruído tem semente fixa; acrescentar no fim do `_ready`, depois dos da 6c1).
  Volume pelo `typing.blip_volume_db` como os outros.
- Fala terminada em `?` (3 das falas) já sobe os 3 últimos blips: combina com o tom de deboche, nada a mudar.
- Som 100% original (sintetizado), nada de amostra.

## 7. Fala de depois (`james_after`) — como fica na tela
Não pedia storyboard, mas precisa de lugar: o balão some quando uma janela abre (`balao-e-voz.md` §3), então a fala **não pode
tocar com a janela de fim aberta**. Proposta: tocar no **fim da tela de luta**, antes da janela, esticando o `outro_seconds`
pelo tempo da fala (3,9–4,6 s; pulável igual ao §4).
- **James venceu:** pose `victory`; nas últimas 0,9 s da leitura, o `scorn` (gesto curto). Balão na cabeça de pé.
- **James perdeu:** ele **continua arrogante** (decisão do dono): se caiu por K.O./finalização, fala do chão, balão no
  `ko_head_point` (−36,−12) espelhado; por pontos, fala em `tired`, de pé. Sem gesto (perdeu, não tem palco).
- Grava `rival_spoke.after = true` quando a fala começa.

## 8. Ajuste de fala (feito em `data/dialogos.json`, só texto, id e gatilho iguais)
| Id | Antes | Agora | Motivo |
|---|---|---|---|
| `rival_james_after_lose_many_1` | não é sobre vocês. / é cartaz mal impresso. | **noite ruim, só isso. / a raízes que não se iluda.** | pela regra de textos §5.3, este id também toca com `met == 2` quando a escola vence o James pela **1ª vez**; "não é sobre vocês" e "cartaz mal impresso" não faziam sentido ali. A nova serve para qualquer encontro, zomba da escola, não ameaça e não elogia. 20 e 26 caracteres |

Roteirista: atualizar a tabela de `fase8a1-textos.md` §5.3 com o texto novo (não mexi no doc dele). As outras 15 falas
conferem: ≤ 26 por linha, minúsculas, sem º/à, nenhuma dirigida ao jogador.

## 9. O que cada um faz

**Programador** (`ui/tela_luta.gd` é do UI/UX; a parte de estado é sua)
1. `GameState` (módulo do James): função que devolve a apresentação a tocar, por exemplo
   `fala_previa_james() -> Array[String]` (ids em ordem, vazio se não for o James ou se `rival_spoke.before`), e outra para a
   fala de depois (`fala_depois_james(resultado) -> String`). Marcar `rival_spoke.before/after = true` ao **começar** a fala.
2. Passar esses ids em `GameState.lutar()` (ex.: campo `intro_lines`/`outro_line` no dicionário da luta), sem mudar o
   resultado nem o `screen_seconds` gravado: a apresentação é tempo de tela fora da luta.
3. `tools/sfx/make_sfx.gd`: timbre `rival` (§6) no fim; gerar os 5 `voice_rival_*`.
4. Teste: as 4 situações escolhem o grupo certo; pular no meio grava o mesmo save; a 2ª luta contra o James na mesma
   campanha (se existir) não toca de novo; soma das falas de cada grupo ≤ 13 s (conta da §3).

**UI/UX** (`ui/tela_luta.gd`, `ui/balao.gd`; passa pela `alinhamento-ui`)
1. Estado "apresentação" na tela de luta: relógio parado antes da entrada, toca os ids em ordem no `Balao` com a cabeça do
   James (head_point x escala, espelhado), 0,3 s entre falas, poses `guard` → `idle` → `scorn` → `guard` (§2–3).
2. No balão: na tela de luta **não vale a `NO_COVER` da sala** (hoje ela é constante e jogaria o balão para y 178); passar a
   zona como parâmetro ou desligá-la na luta. Evitar só a cabeça do jogador e a faixa do HUD (y < 46).
3. Modo de cena do balão (§4): clique/ESPAÇO completa e avança; ESC 0,5 s / PULAR com anel encerra. Reaproveitar o botão do `CenaUi`.
4. Plaquinha "james": `tag_by_speaker.rival` no manifest. A cor `b1` cairia no `blue`, que já é do discípulo: pedir ao Diretor
   de Arte uma `ui_balloon_tag_steel` (aço escuro, texto branco); até lá usar `gray`.
5. Fala de depois na saída da tela de luta, antes da janela (§7).
6. Capturas para o `ui_audit`: balão do James com a maior fala de cada grupo (2 linhas cheias), no 1º encontro e com o James
   caído (fala de depois). 0 problemas, nada cobrindo o HUD nem a cabeça do jogador.

**Artista de Personagens:** §5 (`guard`, `idle`, `scorn`, retrato; `scale`/`head_point` no manifest).
**Diretor de Arte:** moldura do retrato e a plaquinha `ui_balloon_tag_steel`.
**Roteirista:** atualizar `fase8a1-textos.md` §5.3 (§8 acima).
**QA:** cronometrar do LUTAR ao sino nas 4 situações (≤ 15 s; esperado 12,6 / 8,7 / 9,4 / 9,4 s); pular com ESC e com
clique; fechar o jogo no meio e reabrir (não repete); o gesto sai 1 vez; ouvir a voz `rival` contra `first`/`coach`/`disciple`.
