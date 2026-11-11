# Cutscenes — formato de dados (proposta)

Dono: Diretor de Cutscenes. Versão 1 (2026-11-11). **Proposta para o Programador (fase 6b); nenhum arquivo foi criado em `data/`.**
Objetivo: toda cena é um arquivo em `data/cutscenes/<id>.json`, tocado por **um único player de cena**. Nenhuma cena escrita à mão em código. O Diretor de Cutscenes monta e ajusta as cenas só mexendo nesses arquivos.

Convenções iguais às do resto de `data/`: chaves em inglês `snake_case`, textos em português. Posições em pixels inteiros da base 640x360, personagens pelo ponto dos pés. Tempos em segundos.

## 1. Princípios
1. **A cena só mostra.** O marco e o que ele dá (mentor na sala, foto no mural, retrato revelado) são gravados pelo jogo **quando a cena começa**, a partir do bloco `grants`. Tocar inteira, pular ou fechar o jogo no meio dão o mesmo save.
2. **Estado final declarado.** Cada cena diz onde tudo termina (`end_state`). Pular = aplicar o `end_state`.
3. **A cena não espera o jogador**, exceto no passo `open_screen`.
4. **Uma fila só.** O player recebe eventos do jogo, confere os gatilhos e toca uma cena por vez.
5. **Falas separadas dos passos**, no bloco `lines`: o Roteirista edita texto sem tocar em tempo nem posição.
6. **Nomes lógicos de animação** (`gesture`, `duck_under`), resolvidos pelo `manifest.json` para o personagem e a vista. A cena não conhece nome de arquivo.

## 2. Estrutura do arquivo

```json
{
  "id": "primeira_sucessao",
  "version": 1,
  "milestone": "cena_primeira_sucessao",
  "once": true,
  "blocking": true,
  "register": "cotidiano",
  "max_seconds": 16,

  "trigger": {
    "event": "campaign_started",
    "requires": { "milestone_missing": ["cena_primeira_sucessao"], "campaigns_finished_min": 1 }
  },

  "grants": [
    { "type": "mentor_in_room", "character": "first_fighter" }
  ],

  "stage": {
    "view": "room",
    "location": "garage",
    "window": [128, 18, 384, 272],
    "hide": ["player", "crew"],
    "props": {
      "door":   { "sprite": "garage_door", "pos": [382, 100], "frame": 0, "layer": "wall" },
      "gloves": { "sprite": "art_hung_glove_old", "pos": [336, 186], "visible": false }
    }
  },

  "actors": {
    "first":    { "character": "first_fighter", "pos": [303, 272], "facing": "right", "anim": "idle" },
    "disciple": { "character": "current_player", "pos": [423, 221], "facing": "left", "visible": false }
  },

  "lines": {
    "suc_guarda": { "speaker": "first", "text": "Vamos ver sua guarda." },
    "suc_isso":   { "speaker": "first", "text": "Isso." }
  },

  "steps": [
    { "type": "ui", "hide": "all", "seconds": 0.3 },
    { "type": "pose", "actor": "first", "anim": "punch", "times": 3, "gap": 0.2 },
    { "type": "pose", "actor": "first", "anim": "hold_bag", "hold": 1.5, "face": "tired" },
    { "type": "sound", "id": "chain_creak", "stop": true },
    { "type": "camera", "scale": 2, "rect": [222, 154, 192, 136] },
    { "type": "pose", "actor": "first", "anim": "gloves_off" },
    { "type": "pose", "actor": "first", "anim": "hang_gloves" },
    { "type": "prop", "id": "gloves", "visible": true },
    { "type": "camera", "scale": 1 },
    { "type": "sound", "id": "door_shake" },
    { "type": "pose", "actor": "first", "anim": "look_door", "hold": 1.2 },

    { "type": "open_screen", "screen": "customize_disciple", "checkpoint": "depois_criar" },

    { "type": "prop", "id": "door", "anim": "open_jam", "wait": true },
    { "type": "show", "actor": "disciple" },
    { "type": "wait", "seconds": 0.5 },
    { "type": "move", "actor": "disciple", "to": [410, 236], "anim": "duck_under", "seconds": 0.7 },
    { "type": "move", "actor": "disciple", "to": [392, 258], "speed": 48 },
    { "type": "parallel", "steps": [
      { "type": "move", "actor": "disciple", "to": [303, 272], "speed": 48 },
      { "type": "sequence", "steps": [
        { "type": "move", "actor": "first", "to": [268, 268], "speed": 48 },
        { "type": "pose", "actor": "first", "anim": "point_spot", "facing": "right" },
        { "type": "say", "line": "suc_guarda" }
      ] }
    ] },
    { "type": "pose", "actor": "disciple", "anim": "take_gloves" },
    { "type": "prop", "id": "gloves", "visible": false },
    { "type": "return_control" },

    { "type": "prop", "id": "door", "anim": "close" }
  ],

  "reactions": [
    { "when": "first_click", "once": true, "steps": [
      { "type": "pose", "actor": "first", "anim": "taps_bare" },
      { "type": "say", "line": "suc_isso", "mode": "passive" },
      { "type": "wait", "seconds": 1.5 },
      { "type": "move", "actor": "first", "to": "mentor_spot", "speed": 48 },
      { "type": "pose", "actor": "first", "anim": "sit_rest", "loop": true }
    ] },
    { "when": "idle_seconds", "seconds": 6, "once": true, "steps": [
      { "type": "move", "actor": "first", "to": "mentor_spot", "speed": 48 },
      { "type": "pose", "actor": "first", "anim": "sit_rest", "loop": true }
    ] }
  ],

  "end_state": {
    "actors": { "first": { "pos": "mentor_spot", "anim": "sit_rest" }, "disciple": "hand_to_game" },
    "props": { "door": { "frame": 0 }, "gloves": { "visible": false } },
    "camera": { "scale": 1 },
    "ui": "show_all"
  }
}
```

## 3. Blocos

| Bloco | Para quê |
|---|---|
| `id`, `version` | nome do arquivo e versão do conteúdo |
| `milestone` | **marcador de evento**: nome gravado no save da escola (ver §6) |
| `once` | `true` = cena única; nunca toca de novo se o marco existe |
| `blocking` | `true` prende o controle; `false` toca com o jogador no controle (afastamento do mentor), sem barras e sem botão de pular |
| `register` | `cotidiano` / `espetaculo` / `simples` (só documenta o tom e deixa o validador conferir limites) |
| `max_seconds` | teto de tempo preso; o validador soma os passos e reprova se passar |
| `trigger` | evento do jogo + condições (§5) |
| `grants` | o que o marco dá ao jogo, aplicado no começo: `mentor_in_room`, `mentor_leaves`, `photo` (mural), `reveal_opponent`, `prop_permanent` |
| `stage` | onde a cena acontece: `view` (`room` ou `fight`), `location`, `window`, o que esconder da sala viva (`hide`) e os adereços da cena (`props`) |
| `actors` | quem está em cena: `character` é um id do elenco (`first_fighter`, `first_fighter_old`, `coach`, `current_player`, `mentor:N`, `opp_<id>`, `helper`); `current_player` usa a aparência e a luva do discípulo atual |
| `lines` | falas por id: `speaker` (um ator) e `text`. Aceita `{disciple_name}`, `{first_name}`, `{school_name}` |
| `steps` | a cena, em ordem |
| `versions` | opcional: `{ "full": [...], "short": [...] }` no lugar de `steps`. `full` na primeira vez; `short` nas seguintes (vinhetas, reencontro). Com `versions`, `once` vale só para a `full` |
| `reactions` | passos armados para depois do controle voltar (`first_click`, `idle_seconds`) |
| `end_state` | onde tudo fica ao terminar ou pular |

## 4. Tipos de passo

Todo passo aceita: `wait` (padrão `true`: o próximo só começa quando este acaba; `false` = segue junto), `if` (condição, ex.: `{ "last_campaign_end": "defeat" }`) e `checkpoint` (nome; ver "pular").

| `type` | Campos | O que faz |
|---|---|---|
| `wait` | `seconds` | **Espera.** |
| `say` | `line`; `mode` (`scene` padrão ou `passive`); `hold` (segundos depois de escrever; padrão da linguagem); `cps` (velocidade, padrão do personagem); `cut_after` (segundos: corta a fala no meio) | **Fala** no balão, letra a letra, com o blip do personagem. |
| `move` | `actor`, `to` ([x,y] ou nome de ponto do manifest), `speed` (px/s) **ou** `seconds`, `anim` (padrão `walk`), `facing` | **Mover** em pixel inteiro. |
| `pose` | `actor`, `anim`, `loop`, `times`, `gap`, `hold` (segura o último quadro), `face` (expressão), `facing`, `slow` (versão lenta do gesto) | **Pose / animação.** Sem `hold`, dura a folha. |
| `face` | `actor`, `face`, `facing` | Troca só o rosto ou o lado. |
| `show` / `hide` | `actor` ou `prop` | Liga/desliga alguém. |
| `sound` | `id`, `volume`, `loop`, `stop`, `fade` | **Som.** `stop` para um som em laço. |
| `camera` | `scale` (1 ou 2), `rect` ([x,y,w,h] da origem, obrigatório em 2x), `pan_to` ([x,y], no máximo 24 px), `seconds` | **Câmera / quadro.** Trocar de `scale` é sempre corte seco. |
| `frame` | `window` ([x,y,w,h]) ou `"full"`, `seconds` | Fecha ou abre a janela de cena na tela de luta (pilares e barras). |
| `ui` | `hide` / `show`: `"all"` ou lista (`hud`, `panels`, `bottom_bar`), `seconds` | Apaga ou devolve a interface. |
| `prop` | `id`, `visible`, `anim`, `frame`, `pos`, `layer` | Adereço da cena (porta, luvas penduradas, banco, foto). |
| `fx` | `sprite`, `pos` ou `actor` + `offset` | Efeito de uma vez (poeira, brilho, faísca). |
| `shake` | `px` (1 ou 2), `frames` | Tremida. |
| `light` | `id`, `on` | Liga/desliga uma luz do palco (tubo, holofote, máscara de sombra). |
| `name_card` | `actor`, `style` (`plain` ou `show`), `seconds` | Nome na tela: simples (1x) ou faixa de apresentação. |
| `photo` | `id`, `wall` (`garage` / `gym`), `slot`, `subjects` | **Foto no mural:** o *momento* em que ela aparece na parede. A foto em si vem de `grants`; pulando, ela já está lá. |
| `open_screen` | `screen`, `checkpoint` | Abre uma tela do jogo (criar discípulo) e espera fechar. Pular para aqui. |
| `return_control` | — | **Devolve o controle:** barras saem, interface volta, clique vale. Os passos depois dele tocam com o jogador no controle. |
| `start_fight` | — | Na vista de luta: HUD entra, sino, a luta começa (fim da cena). |
| `parallel` | `steps` | Toca os filhos juntos; termina quando todos terminam. |
| `sequence` | `steps` | Filhos em ordem (para usar dentro de `parallel`). |

**Pular:** segurar a tecla ou clicar em PULAR leva ao próximo passo `open_screen` (se houver à frente) ou aplica o `end_state` e executa `return_control` / `start_fight`. Passos `sound` em laço param; `reactions` continuam armadas.

## 5. Gatilhos

| `event` | Quando o jogo avisa | Usado por |
|---|---|---|
| `campaign_started` | "receber novo discípulo" confirmado, garagem pronta | primeira sucessão |
| `location_reached` (`location`) | a escola chega a um local | chegada à academia |
| `returned_to_room` (`after`: `fight_won`) | volta à sala depois de uma luta | afastamento do mentor |
| `fight_intro` (`opponent`) | entrada de uma luta | vinhetas, reencontro |
| `fight_won` (`opponent`) | vitória | vitória final |

`requires` aceita: `milestone_missing`, `milestone_present`, `campaign_min`, `campaigns_finished_min`, `location`, `opponent`, `calm` (sem janela aberta, sem dia de luta parado).
Se a cena não puder tocar na hora (`calm` falso), fica na fila até o próximo momento calmo. Cenas `blocking: false` são descartadas (e o marco gravado) se o jogador abrir janela ou luta.

## 6. Marcador de evento (nunca repetir depois do reset)

- Os marcos moram no save **da escola**, fora do que zera a cada campanha: `school.milestones = { "cena_primeira_sucessao": { "campaign": 2, "version": 1 } }`.
- O marco é gravado **no começo da cena**, com salvamento imediato, junto com os `grants`.
- Nova campanha, derrota, aposentadoria e reset de carreira **não apagam** `school.milestones`. Só "apagar tudo" do save apaga.
- `once: true` + marco presente = a cena não entra na fila. Com `versions`, toca a `short`.
- Mudar o conteúdo de uma cena (`version` 2) **não** faz ela tocar de novo.
- Save antigo, sem `school.milestones`: começa vazio; cada cena única toca na próxima vez que o gatilho dela acontecer.
- Testes automáticos usam o save de teste, nunca o save do dono (regra do projeto).

## 7. Validador e captura (pedido ao Programador)
- **Validador** (`tools/`): confere, sem abrir o jogo, que todo `anim`, `sprite`, `sound`, `line` e ponto nomeado existe; posições inteiras; `rect` de 2x com 192x136; soma dos passos `blocking` ≤ `max_seconds`; texto ≤ 2 linhas de 26 caracteres; existe `end_state`; existe `return_control` ou `start_fight`.
- **Captura de cena:** rodar uma cena pelo id com save de teste e salvar um quadro a cada 0,5 s (e o estado final pulado), para o Diretor de Cutscenes conferir sem mexer em `scripts/`.
- O balão em cena entra nos estados do `tools/ui/ui_audit.gd` (skill `alinhamento-ui`).

## 8. O que o formato não faz (de propósito)
- Não decide nada de jogo: sem condição de vitória, sem dar dinheiro, sem mudar atributo.
- Não tem escolha de diálogo.
- Não tem zoom suave, rotação nem escala quebrada.
- Não carrega cenário novo sozinho: usa os fundos e pontos do `manifest.json`.
