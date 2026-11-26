# Ronda 2a1 (brigas de beco): contrato de lógica para a UI/UX

Programador, 2026-11-26. Base: `ronda2a-design.md` (§9.3 é o contrato de origem; este arquivo o detalha e o torna a referência).
Tudo mora em `scripts/estado/ronda.gd` (módulo `_ronda`) com repasses de uma linha no `GameState`. A UI só **lê** e **chama**; nunca
sorteia, nunca grava e nunca chama `RondaLogica.passo` (o tick do GameState anda a noite).
Textos: sempre por `GameState.texto_ui(chave, padrao)`; as respostas abaixo já trazem os textos resolvidos quando dizem "texto".

## 1. Fluxo (o que a UI faz, em ordem)
1. O capuz no prego é o de sempre (`capuz_visivel()`, `capuz_info()`). `capuz_info()` ganhou `hideout` (true = a briga está aberta).
   - `hideout == false`: clique chama `ronda_ir()` (SUSTO direto, como na Ronda 1).
   - `hideout == true`: clique abre a tela do **Esconderijo** (nada muda no jogo: o relógio continua; só `ronda_ir` congela).
     VOLTAR no Esconderijo = fechar a tela, nada gravado, o capuz continua no prego.
2. Esconderijo: `esconderijo()` (tudo de uma vez) ou `quadro_noite()` / `dossie()` separados. Botão IR de cada cartão:
   - cartão SUSTO: `ronda_ir("scare")` (igual a `ronda_ir()`).
   - cartão de bandido / DESAFIO: `ronda_ir("alley", bandit_id)`. Devolve `{}` se o bandido não pode (fora de ordem, sem capuz, janela aberta).
3. Aproximação: `ronda_ativa == "alley"`; `ronda_jogo()` é uma `RondaLogica` de 1 ocorrência (mesmo `estado()`/`apertar()`/`soltar()`/
   `pegar_eventos()` da Ronda 1). Contagem 2 s, depois até 8 s (com o intro de 0,8 s dentro). SAIR: `ronda_concluir()` (ver §6).
4. Fim da aproximação (`ronda_jogo().estado().fase == "fim"`; o tick já resolveu e `briga_estado().fase` virou `"previa"`; o sinal
   `briga_mudou("previa")` sai no mesmo quadro): mostrar a prévia com `briga_previa()`.
5. LUTAR com a tática escolhida: `briga_lutar(tatica_id)` (**grava tudo agora**, §5). Devolve o mesmo dicionário de `luta_atual()`
   (eventos, `opp_passive`, `result.finish`...) para a `tela_luta` animar, mais `night_prize`. A luta não usa `GameState.luta`.
6. Prêmio: `briga_resultado()` (ou o `night_prize` que veio no `briga_lutar`). VOLTAR: `ronda_voltar()`. Trava: 120 s na tela de
   prêmio devolvem a sala sozinhos (como na Ronda 1).
7. Nada de `definir_tatica`: a tática da noite vale só para a noite e **não** muda `GameState.tatica` (é salvo na carreira).

## 2. `esconderijo()` / `quadro_noite()` / `dossie()`
```
esconderijo() -> {
  open: bool,                 # briga_aberta()
  legend: lenda(),            # {legend, level, next_level_at, max_level, scares, rounds, shown_level}
  board: [...],               # = quadro_noite()
  dossier: [...],             # = dossie()
  boss: {known: false, missing_text},   # 4ª ficha (silhueta do chefe da 2a2): "PRECISA DA LENDA 5"
  trophies: []                # vazio na 2a1 (a 2a2 enche); a prateleira desenha 4 lugares vazios
}
```
`board` (na ordem em que os cartões aparecem; o SUSTO é sempre o primeiro):
| night | campos |
|---|---|
| `"scare"` | `name` (texto `hideout_scare_card`), `level`, `legend` |
| `"alley"` | `bandit` (id), `name` ("???" enquanto não venceu), `nickname`, `profile` (FORTE/RÁPIDO/RESISTENTE), `passive {id, name, icon}`, `challenge {type, text}`, `challenge_text`, `revenge` (bool: perdeu e ainda não venceu), `challenge_only` (bool: já venceu, falta o desafio: cartão menor "DESAFIO"), `style {id, field, option}`, `portrait` (id do retrato), `known` |
| `"quiet"` | só quando os 3 bandidos já foram vencidos: ocupa o lugar do cartão do próximo bandido (logo depois do SUSTO); `text` (`hideout_quiet`) |
Ordem dos cartões: SUSTO, o 1º bandido não vencido (ou `quiet`), e depois um cartão `challenge_only` por bandido vencido sem o desafio.
Chaves de texto que o Programador usou e o Roteirista ainda não tem: `dossier_missing_league` (ficha fechada porque falta entrar na liga
regional; fallback "ENTRE NA LIGA REGIONAL").
`dossie()` = lista com 1 item por bandido, na ordem dos dados:
`{bandit, known (venceu alguma vez), won, lost, first_win_campaign, challenge (desafio cumprido), style {id, field, option},
  style_unlocked (bool), portrait, name, nickname, rap_sheet, headline, witness, clipping, profile, passive {id, name, icon},
  challenge_text, stamp ("VENCIDO NA {n}ª CAMPANHA", só known), revenge, missing_text}`.
Quem não é `known` traz `name` = "???", `rap_sheet/headline/witness/stamp` = "" e `missing_text`
("PRECISA DA LENDA 3" se a briga ainda está fechada; "VENÇA {nome} PRIMEIRO" se falta o bandido anterior; "" se já dá para ir).
Nunca há nome do discípulo em nenhum campo.

## 3. `ronda_ir(noite = "", bandido = "")`
- `ronda_ir()` / `ronda_ir("scare")`: como na Ronda 1 (devolve o mesmo dicionário de sempre).
- `ronda_ir("alley", bandido)`: congela o jogo (`ronda_ativa = "alley"`), cria a `RondaLogica` (ciclos do `_rng_ronda`), **não grava**,
  e devolve `{night "alley", kind "alley_fight", bandit, name, tip, countdown_s, approach_s, night_s (= approach_s), level, legend,
  layers, occurrences [id], occurrence_names [texto], challenge {type, text}, challenge_only, revenge, nickname, profile,
  hold_hint_s, spot}`. Emite `ronda_mudou("alley")`.
- `estado()` da `RondaLogica` ganhou `segurando_perto_s` (s segurando sem parar perto do fim do muro), `hold_hint_s` e **`dica_soltar`**
  (bool): é a dica D2. Quando `dica_soltar` for true, a tela troca o sinal PERTO por `hint_release_click` ("SOLTE E CLIQUE!"), piscando.
  Vale na Ronda 1 e na aproximação. Só texto: não muda regra nem sorteio.

## 4. `briga_estado()` e `briga_previa()`
`briga_estado() -> {fase "aproximacao"|"previa"|"luta"|"", bandit, approach "scare"|"seen"|"time"|"" (vazio até acabar), challenge_only, revenge}`.
`ronda_ativa == "alley"` e `fase == "previa"` é quando a prévia aparece. Sinal: `briga_mudou(fase)`.

`briga_previa()` (só na fase `previa`; calcula as 3 táticas com 200 sementes, ~0,1 s; guardado em cache até a noite acabar):
mesmo formato do `previa()` da carreira, com o bandido no lugar do adversário, mais:
- `night: "alley"`, `bandit`, `opponent` (dados do bandido; `name` já "???" e `nickname`), `you` (atributos crus; AQUECIDO não vale e não é gasto).
- `risks {tática: {label, chance, percent}}` (a chance é a do motor, `Luta.chance_detalhada`), `risk`, `percent`, `percent_text`,
  `show_percent` (sempre true na noite), `tactic` (a tática sugerida: a de `GameState.tatica`), `lead`.
- `passive_name/line/state/share/tactics`, `art`, `art_fight_text`, `art_passive` (só com arte) e `opp_passive_id|name|line|hits|hits_text|icon`
  (as chaves da passiva dele, como na liga).
- `challenge {type, text, by_tactic {tática: pct 0-100}, done}`: `by_tactic` conta o desafio nas **mesmas 200 lutas** da chance (no
  `surprise` vem vazio: `done` = true se a aproximação foi SUSTO, false se não; a linha é "FEITO"/"PERDIDO", sem porcentagem). `line_by_tactic`
  = texto pronto `challenge_chance_line` ("CHANCE DO DESAFIO: N%") por tática (vazio no `surprise`).
- `approach {result, text}` (`alley_approach_scare|seen|time`), `revenge`.

## 5. `briga_lutar(tatica_id)` (a gravação única)
Fase `previa`, tática válida; senão devolve `{}`. Numa gravação só (`salvar()` uma vez):
1. semente = `_rng_ronda.randi()`; luta = `Luta.lutar(atributos crus, [F, A, R, passiva], tatica, semente)`;
2. grava em `permanent.black_cat`: `alley[bandido]` (`won`/`lost`, `first_win_campaign`, `challenge`), `legend` (+`floor` +`per_scare` se SUSTO +`win` se venceu),
   `rounds` +1, `scares` +1 se SUSTO, `shown_level`;
3. esvazia o prego (`capuz.open = ""`, `next_at = hood_s + interval_s`).
Fechar o jogo antes disso: nada mudou. Fechar depois: tudo gravado uma vez só; reabrir devolve a sala com o capuz fora do prego.
Retorno = o de `luta_atual()` (formato da `tela_luta`: `events`, `result {win, ko, t_ko, t_end, round, pct_player, pct_opponent, finish}`,
`life_max`, `intro_seconds`, `outro_seconds`, `screen_seconds`, `loser`, `grogue`, `opp_passive`, `opp_blocks`, passivas da sua arte...) com:
- `arena: "arena_alley"`, `night: "alley"`, `bandit`, `fighter_name` ("???": `fighter_name_hidden`), `ko_banner` (`alley_ko_banner`),
  `points_banner` (`alley_points_win`), `lose_line` (`alley_lose_line`);
- `night_prize` (§7).
- **`art`** (novo, lido de `manifest.by_data_id.alley_fight`): `{opponent, vulto, arena, portrait}`. `opponent` é o `by_data_id` do bandido
  (`opp_alley_tire|bike|gate`, com `actions` próprias: `idle`, `jab`, `heavy`, `guard`, `ko`, `ko_back`, `ko_knees`, `fall_spin`, `flee`
  = SAIU TONTO E FUGIU, `signature`...), `vulto` = `vulto_fight` (ações `fight_vulto_<ação>`, camadas pela `disciple_palette`, nunca espelhar;
  `portrait_vulto` no HUD com o nome "???"), `arena` = `arena_alley` (`_bg`, `_lamp`, `_crowd_back`, `_crowd_front`), `portrait` =
  `portrait_opp_alley_<id>`. O lutador da esquerda é o vulto; o `ko_banner` vale em K.O., `points_banner` na vitória por pontos
  e o bandido que perde por pontos usa `flee`.
**Sem `GameState.luta`**: `luta_atual()` continua `{}` e a carreira nem sabe da noite.

## 6. SAIR (`ronda_concluir()`) e VOLTAR (`ronda_voltar()`) na `alley`
- Na aproximação e na prévia: `ronda_concluir()` não grava nada, devolve `{left: true}` e **já devolve a sala** (o capuz continua no prego,
  lenda 0). Chamar `ronda_voltar()` depois é inofensivo.
- Depois do LUTAR (`fase == "luta"`): `ronda_concluir()` devolve o prêmio de sempre (o mesmo `night_prize`); `ronda_voltar()` devolve a sala.

## 7. `night_prize` / `briga_resultado()`
```
{night "alley", bandit, win, ko, finish, round, approach, scare (bool),
 legend_gain, legend, level_before, level, level_up, level_up_line, max_level, next_level_at,
 challenge_done (cumpriu agora, e antes não tinha), challenge_ever (tem o desafio feito), style_unlocked ("" | id do estilo novo),
 style {id, field, option}, style_text ("ESTILO NOVO: {estilo}"), dossier_new (1ª vitória: ficha nova), clipping_new (1ª vitória: recorte novo),
 revenge (perdeu e ainda não venceu esse bandido),
 title, line (alley_win_line | alley_lose_line), sub (alley_lose_sub, só derrota), headline, clipping_text, dossier_line, clipping_line, challenge_line}
```
`BRIGA GANHA` (`alley_prize_title`) na vitória, `NOITE PERDIDA` (`alley_lose_title`) na derrota. Sinais emitidos na hora do LUTAR: `dossie_mudou()`
(sempre que mudou a ficha), `lenda_mudou(nivel)` (se subiu), `permanente_mudou()`.

## 8. Estilos (personalização do próximo discípulo)
- `GameState.estilo_liberado(style_id) -> bool` (derivado: a ficha do bandido daquele estilo tem `challenge`).
- `GameState.disciples.opcoes_ativas(campo)` já devolve as opções normais e, **no fim da lista**, os estilos liberados (travados não aparecem).
  `linhas_tela_criacao()` traz o mesmo em `opcoes` e ganhou `marcas` ({id: "cat"}): o id que tiver `"cat"` leva o ícone do gato.
- Nunca entram no sorteio do rascunho. Look salvo com estilo não liberado volta ao padrão do campo (com aviso).
- Texto do nome do estilo: `disc_opt_<campo>_<opção>` (ex. `disc_opt_socks_night_wraps`).
- **DiscVisual** (`ui/disc_visual.gd`): a pequena mudança foi feita por mim (lógica de visual): opção com `requires` (faixa/calção `night`, meião
  `night_wraps`, e o meião "on" sobre o calção `night`) pinta pelas cores do `disciples.json` (nomes dos slots = chaves do manifest);
  a paleta do manifest não precisa de entradas novas.

## 9. Save (v13, sem migração)
`permanent.black_cat.alley = {"<bandido>": {won, lost, first_win_campaign, challenge}}`, opcional; só bandidos com `won + lost > 0`.
Validação na carga: número ruim/negativo = 0, gigante = teto; `challenge` sem vitória = false; id desconhecido = ignorado (com aviso);
`first_win_campaign` > campanha atual = campanha atual. A foto apaga `permanent.black_cat` inteiro (nada a mudar lá).
Não vai para o save: a escolha da noite, a aproximação, a prévia e a semente (só existem em memória até o LUTAR).

## 10. Dados lidos (`data/ronda.json`)
`night_order ["scare","alley"]`, `hood.hideout_from "alley"`, `nights.scare.hold_hint_s 0.6`, `nights.alley` (requires, countdown_s, approach_s,
prize_s, legend {floor, per_scare, win}, bandits[]). O resto do contrato de dados é o §9.1 do design.

## 11. Arte integrada (manifest e paleta)
`assets/sprites/manifest.json` recebeu os 120 sprites e os 6 `by_data_id` da 2a1 (`tools/art/ronda2a_manifest.json`) e a paleta
`disciple_palette` ganhou `night` (faixa e calção), `night_wraps` (meião) e `school_symbol_source.leg.map.night = yellow` (só somados).
`DiscVisual` desenha a camada do meião com `socks != "none"` (inclui `night_wraps`) e agora troca as cores do meião por
`options.socks[night_wraps]` quando o look usa a bandagem (antes só pelo id do calção).

## 12. Pedidos do UI/UX (2a1)
- Sem mudança de contrato de lógica. Duas chaves de texto novas usadas só com fallback no código (Roteirista pode gravar em `ui_texts.json`): `hideout_read` ("LER", botão da ficha no Dossiê) e `hideout_close` ("FECHAR", ficha aberta).
- A luta da noite usa `luta.art` (opponent/vulto/arena) e termina em `terminou({night:"alley", win, prize})` sem chamar `concluir_luta()`.
