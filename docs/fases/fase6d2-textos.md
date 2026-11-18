# Fase 6d2: levantamento de "bloat texts" (proposta, nada foi apagado)

Roteirista, 2026-11-18. Pedido do dono: tirar os textos inúteis. Critério: fica só o que informa uma escolha, um custo,
um estado ou um perigo. Texto que repete o ícone, o número ou o nome do botão ao lado sai.

Fonte: `data/ui_texts.json` (chaves) e `ui/*.gd` (quem usa). Linhas citadas são do `.gd` onde a string é desenhada; para o
resto vale a chave. **Nada foi alterado em ui/, scripts/, data/ ou assets/.** A remoção entra junto com a tela C.

Convenção: TIRAR = some da tela (a chave pode continuar no JSON até a implementação limpar). ENCURTAR = troca o texto.
MANTER = fica como está. Os textos de fala (rival, mentor, John, cutscenes, dicas pós-derrota) não entram aqui: são
pulavéis, aparecem uma vez e carregam o tom do jogo.

## 1. Tela principal (a que o jogador vê 95% do tempo)

| Chave / arquivo:linha | Texto atual | Onde aparece | Decisão | Texto novo |
|---|---|---|---|---|
| `per_click` / barra_baixo.gd:53 | POR CLIQUE | legenda pequena acima do "+1" (faixa de baixo) | TIRAR | o "+1" em 2x já diz; na faixa fina da C vira só "+1" com o ícone da mão. O pop-up/hover pode dizer "por clique" |
| `focus_label` / barra_baixo.gd:59 | FOCO DE TREINO | título sobre a fileira de botões de foco | TIRAR | os botões de foco com ícone e o nome do aparelho já se explicam; na faixa de 30 px da C não há linha para título |
| `fullscreen_hint` / barra_baixo.gd:60 | F11 TELA CHEIA | já nasce invisível, só aparece sem chip de arte | TIRAR | fica só no "?" (`hint_keys`) |
| `saved_footer` / barra_baixo.gd:73 | SALVO 14:32 | rodapé fixo | ENCURTAR | só um "salvo" discreto que pisca 2 s ao salvar e some. Texto fixo permanente não ajuda decisão |
| `hint_keys` / barra_baixo.gd:253 | ESPAÇO ou clique: treinar / SHIFT: treino assistido / 1 a 4: foco F11: tela cheia | dica do "?" (sob demanda) | ENCURTAR | "ESPAÇO treina  SHIFT assiste  1-4 foco  F11 tela" (+ "L loja  E equipe" quando a tela C entrar) |
| `space_hint` | ESPAÇO OU CLIQUE PARA TREINAR | não aparece mais (lembrete virou nível 3) | TIRAR | apagar a chave do JSON (órfã) |
| `assist_hint` | SEGURE SHIFT: TREINO ASSISTIDO | chip do assistido (faixa_assistido.gd:200) | TIRAR | o botão SEGURAR e o hover `hint_assist` bastam. Fica só `hint_assist_first` nas primeiras vezes |
| `assist_hint_short` / `assist_waiting` / `assist_active` / `assist_metronome` | SEGURE SHIFT / ESPERANDO A MÃO PARAR / ASSISTIDO / METRÔNOMO TOCANDO | chip do assistido, 4 estados | ENCURTAR | manter só 2 estados: parado (sem texto, botão apagado) e ativo ("ASSISTIDO"). "Esperando a mão parar" e "metrônomo tocando" tiram: o chip pulsando já mostra |
| `hint_assist_first` | Dica: segure SHIFT. | primeiras vezes | MANTER | ensina a mecânica uma vez |
| `panel_attributes` / painel_atributos.gd:25 | ATRIBUTOS | título do painel de atributos | TIRAR | na C são miniaturas com ícone + barra + número; título não cabe e não é preciso |
| `panel_team` / painel_loja.gd:74 | EQUIPE | título de seção no painel Treino | MANTER | é o que separa gerador de melhoria |
| `panel_upgrades` / painel_loja.gd:80 | MELHORIAS | título de seção | MANTER | idem (com `panel_team` formam o único cabeçalho do painel) |
| `shop_title` / painel_loja.gd:108 | LOJA | título dentro da aba LOJA | TIRAR | a aba já se chama LOJA (painel_loja.gd:173). Título repetido |
| `shop_sub` / painel_loja.gd:109 | Dinheiro de luta, só aqui. | subtítulo da LOJA | TIRAR | o ícone de dinheiro nos botões diz a moeda. Exceção: quando `texto_reserva` (GUARDE $N PARA A MUDANÇA) ocupa a mesma linha, esse fica (é aviso) |
| `hud_training` (hud.gd:31) | TREINO | legenda do grupo no HUD de cima | MANTER | única legenda do HUD; o ícone sozinho confunde Treino com Dinheiro |
| `hud_money` / `hud_fame` / `hud_legacy_run` / `hud_legacy_total` | DINHEIRO / FAMA / LEGADO EM JOGO / LEGADO | legendas dos outros grupos do HUD | ENCURTAR | cada grupo já tem ícone próprio e dica no hover (`hint_fame`, `hint_legacy`). Tirar as legendas pequenas e deixar só ícone + número, menos TREINO |
| `hud_campaign_day` / `hud_career` / `hud_disciple_career` | DIA 12 / CAMPANHA 2 / Nome C2 | HUD e folhinha da próxima luta | ENCURTAR | "C2" sozinho já se entende ao lado do nome; `hud_career` tira onde o nome do discípulo aparece |
| `hud_art_boxing` / `hud_art_bjj` / `_max` | BOXE: +50% NO SEU CLIQUE / JIU-JITSU: EQUIPE +48% (MÁX.) | chip da arte na faixa de baixo | ENCURTAR | "BOXE +50%" / "JIU-JITSU +48%". O ícone da arte já diz o resto; "no seu clique" e "equipe" vão para o hover. Cai de ~24 para ~10 caracteres |
| `hud_location_mult` | ACADEMIA: TREINO x2 | chip do local | ENCURTAR | "TREINO x2" (o fundo já é a academia) |
| `hud_next_move` | PRÓXIMA: MUDE PARA A ACADEMIA | bloco da próxima luta, depois do cinturão | ENCURTAR | "MUDE PARA A ACADEMIA" |
| `no_more_fights_gym` | CAMPANHA COMPLETA. PASSAR O POSTO VALE MAIS. | bloco da próxima luta (fim da escada) | ENCURTAR | "PASSAR O POSTO VALE MAIS" (a folhinha dourada já diz CAMPANHA COMPLETA, repetia) |
| `no_more_fights` | SEM MAIS ADVERSÁRIOS POR ENQUANTO | bloco da próxima luta (garagem sem rival) | ENCURTAR | "SEM LUTA POR ENQUANTO" |
| `map_hint` / janela_mapa.gd:127 | ARRASTE OU USE A RODA | linha no topo do mapa (árvore) | TIRAR | quem abre um mapa arrasta. Se quiser, vira dica só na 1ª abertura |
| `map_button_tip_*` / botao_mapa.gd:47 | ÁRVORE / NADA PARA COMPRAR AGORA / 1 NÓ PARA COMPRAR / N NÓS PARA COMPRAR | hover do botão do mapa | ENCURTAR | 2ª linha só quando há algo: "2 NÓS". Sem nós, só "ÁRVORE" |
| `hint_fame` | Fama / O bairro já ouviu falar de você. | hover da Fama | ENCURTAR | "Fama: abre lutas maiores" (a frase de efeito vira flavor sem função; se a Fama não abre nada, "Fama: o nome que corre" ou tirar o hover) |
| `hint_legacy` | Legado em jogo / Vira permanente ao passar o posto. / Perder leva metade. | hover do Legado | MANTER | informa regra e perigo |
| `hint_prize` / `hint_prize_belt` | Prêmio / $N e N fama. | hover da folhinha | ENCURTAR | "$N + N fama" (a palavra "Prêmio" no começo repete o contexto) |
| `focus_boxed` / `shop_glove_boxed` / `tape_boxed` / `box_hover_closed` / `box_hover_left` / `tape_*` | Na caixa. Abra para treinar. / Abra a caixa antes. / Caixa da escola. Clique 3 vezes. / Faltam N cliques para abrir. | dicas de hover de itens em caixa (3 variações do mesmo recado) | ENCURTAR | unificar: "Na caixa: clique 3 vezes" e "Faltam N cliques". As demais variações saem (`focus_boxed`, `shop_glove_boxed` viram "Na caixa") |
| `tape_open` | NOME / N de treino. Vem em caixa. | hover do aparelho comprável | ENCURTAR | "NOME  N treino" ("vem em caixa" já é ensinado pela primeira caixa) |
| `tape_owned` | NOME / Já está no lugar. | hover de aparelho comprado | TIRAR | o aparelho está na sala; hover de item comprado não precisa de frase. Só o nome |
| `tape_short` | NOME / Falta treino. Falta N. | hover sem saldo | ENCURTAR | "NOME  falta N" |
| `can_afford_hint` | Falta treino | hover do botão sem saldo | ENCURTAR | "Falta N" (o número já diz do que) |
| `shop_no_money` / `move_no_money` | Falta dinheiro | hover do botão sem saldo | ENCURTAR | "Falta $N" |
| `hint_locked_item` / `attr_locked` / `unlock_after` / `floor_mark_after` / `focus_locked_after` | Trancado. Compre a X antes. / COMPRE A X PARA TREINAR / DEPOIS DA X | cartões e botões trancados, hover | ENCURTAR | uma só forma: "DEPOIS DA X" no cartão e "Compre a X antes" no hover. `attr_locked` ("COMPRE A X PARA TREINAR") some: o botão trancado já diz "DEPOIS DA X" |
| `shop_glove_effect` / `shop_generator_effect` / `shop_metronome_effect` / `upgrade_effect` / `shop_crew_click_effect` | x2 POR CLIQUE / +N/S / 1 SOCO A CADA 2 S / x2 POR CLIQUE: ALVO / CLIQUE +N (1 S DA EQUIPE) | linha de efeito dos cartões | ENCURTAR | tirar "POR CLIQUE" quando o cartão já está sob o título do clique: "x2". Equipe fica "+N/S". `shop_crew_click_effect` vira "CLIQUE +N" |
| `shop_metronome_now` | AGORA: 1 SOCO A CADA N S COM SHIFT | cartão do metrônomo comprado | TIRAR | repete `shop_metronome_effect`; o botão já é "COMPRADO"/"MÁXIMO" |
| `maxed` | MÁXIMO | botão de cartão no máximo | MANTER | estado claro, 6 letras |
| `shop_crew_click_bought` | COMPRADO | idem | MANTER | |
| `move_title` / `move_effect` / `move_keeps` / `move_per_career` / `move_reserve` / `move_reserve_short` | ACADEMIA BOA ESQUINA / TREINO x2 / 2 LUTAS DA CASA / TUDO O QUE VOCÊ COMPROU VAI JUNTO / VALE ATÉ O FIM DESTA CAMPANHA / GUARDE $N PARA A MUDANÇA | cartão da mudança na loja | ENCURTAR | manter título, `move_effect` ("TREINO x2 / 2 LUTAS DA CASA", escolha e risco) e `move_reserve`. TIRAR `move_keeps` e `move_per_career` (garantias que ninguém duvidava; vão para o hover se quiser) |
| `move_arrived` | BEM-VINDO À BOA ESQUINA! | letreiro ao chegar | MANTER | é um momento, 1 vez |
| `unlock_arrived` / `box_arrived` / `box_click` | CHEGOU: X! / TOC! / RACHOU! / ABRIU! | letreiros de caixa | MANTER | feedback do clique, curto e com graça |
| `frenzy_start` / `frenzy_label` | FRENESI X2! / FRENESI X2  12S | letreiro e chip | MANTER | estado temporário que muda o ganho |
| `golden_crew_hover` / `golden_crew_toast` | NOME: +N DE TREINO / A TORCIDA ENCHEU A BOLSA! +N | hover e toast do dourado | ENCURTAR | toast só "+N" com o nome "Bolsa da torcida"; a frase vira bandeira do tom. Manter só se couber em 1 linha |
| `skip_hint` / `skip_chip` | pular / SEGURE ESC: PULAR | cutscenes | MANTER | única forma de saber como pular |

## 2. Janelas de decisão (só entram quando o jogador abre)

| Chave / arquivo:linha | Texto atual | Onde aparece | Decisão | Texto novo |
|---|---|---|---|---|
| `preview_title` | PRÓXIMA LUTA | título da janela da prévia | MANTER | |
| `preview_him` / `preview_you` | ELE / VOCÊ | colunas da comparação | MANTER | |
| `tactic_label` | TÁTICA | janela_previa.gd:129 | MANTER | escolha |
| `risk_label` | RISCO | rótulo do risco | TIRAR | o risco já vem em verde/amarelo/vermelho com FÁCIL/EQUILIBRADO/PERIGOSO; "RISCO:" na frente repete |
| `stake_win` | SE VENCER: $N + N FAMA | prévia | ENCURTAR | "VENCER: $N + N FAMA" |
| `stake_belt` | SE VENCER: O CINTURÃO AMADOR | prévia | ENCURTAR | "VENCER: CINTURÃO AMADOR" |
| `stake_lose` / `stake_lose_pct` | PERDER ENCERRA A CAMPANHA (METADE DO LEGADO) | prévia | MANTER | perigo real. Encurtar só se faltar largura: "PERDER: FIM DA CAMPANHA (METADE DO LEGADO)" |
| `time_rule` | SEM K.O. NO TEMPO: VENCE QUEM TEM MAIS VIDA | janela_previa.gd:162 | ENCURTAR | "NO TEMPO: VENCE QUEM TEM MAIS VIDA" |
| `time_rule_tie` | EMPATE EXATO: FICA COM ELE | janela_previa.gd:164 | MANTER | perigo, mas só mostrar quando o empate é plausível (risco PERIGOSO) |
| `lead_strength` / `lead_agility` / `lead_endurance` | ELE É MUITO MAIS FORTE / RÁPIDO / AGUENTA MUITO MAIS | destaque do atributo gritante | MANTER | decide o treino |
| `preview_missing_line` | FALTA UNS N DE ATRIBUTO | prévia com Caderninho | MANTER | |
| `preview_wait_green` / `tip_wait_green` | ESPERE FICAR VERDE / VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE | prévia; tela de derrota | ENCURTAR | prévia mantém "ESPERE FICAR VERDE"; `tip_wait_green` vira "ESPERE O VERDE" |
| `revenge_mark` | VOCÊ PERDEU PRA ELE | fita vermelha | MANTER | tom e contexto |
| `fight_day_title` / `fight_day_line` | DIA DA LUTA / NOME chegou. Lutar ou passar o posto? | janela do dia | ENCURTAR | tira `fight_day_line`: título + nome do adversário + os dois botões já fazem a pergunta |
| `back_button` | VOLTAR A TREINAR | prévia | ENCURTAR | "VOLTAR" (o par é LUTAR!) |
| `retire_hint` / `retire_hint_short` | PASSAR O POSTO AGORA LEVA N DE LEGADO | hover/linha do botão | MANTER | custo/ganho |
| `retire_confirm_*` | PASSAR O POSTO? / VOCÊ LEVA N DE LEGADO / INCLUI +N / TUDO DESTA CAMPANHA SE PERDE | janela de confirmar | MANTER | decisão sem volta |
| `retire_confirm_honor_help` | A HONRA FICA NO MURAL DA ESCOLA | confirmar | TIRAR | o botão MURAL e o `honor_what` já explicam |
| `retire_no_honor` | HONRA SÓ COM 1 VITÓRIA | confirmar e fim | MANTER | regra que o jogador precisa saber |
| `victory_gain` / `victory_next` | +$N +N FAMA +N LEGADO EM JOGO / PRÓXIMO: NOME | vitória | MANTER | o que ganhou |
| `belt_unlock` | VOCÊ SE MUDA PARA A ACADEMIA BOA ESQUINA | vitória do cinturão | MANTER | |
| `belt_hint` | A MUDANÇA SAI DO PRÊMIO E SOBRA DINHEIRO PARA GASTAR. | idem, linha cinza embaixo | TIRAR | explica um detalhe de balanço que o `move_reserve` já avisa depois |
| `belt_line` | O bairro viu. Uns quinze. | idem | MANTER | tom (é a graça da cena) |
| `art_title` / `art_sub_first` / `art_sub_career` / `art_whole_career` / `art_choose` | QUE TIPO DE LUTADOR... / AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE / CAMPANHA N: ESCOLHA A ARTE / VALE A CAMPANHA INTEIRA / ESCOLHER | janela da arte | ENCURTAR | tirar `art_sub_career` (o título já pergunta), `art_whole_career` repete em cada cartão: trocar por uma frase só no rodapé, "VALE A CAMPANHA INTEIRA" |
| `art_last` | ÚLTIMA: NOME | selo | MANTER | ajuda a escolher |
| `legacy_note` | O LEGADO FICA GUARDADO. VAI SERVIR NA PRÓXIMA VERSÃO. | tela de fim | TIRAR | frase-desculpa do protótipo; o legado já tem árvore |
| `end_support_line` / `retire_line` / `retire_line_belt` | A luva fica no gancho... / A escola segue... | fim | MANTER | tom, 1 vez por campanha |
| `sum_title` / `sum_*` | RESUMO DA CAMPANHA N, VITÓRIAS, CINTURÕES, FAMA... | tela de fim | MANTER | números do resumo; dispensa `sum_title_named`/`sum_title` duplicados: um só título |
| `reason_*` / `stat_*` / `tip_*` | explicação da derrota e dica pós-derrota | tela de derrota | ENCURTAR | hoje são 3 camadas (motivo + número + dica). Mostrar motivo + 1 estatística + 1 dica; `stat_luck_*` só no caso azar. Variantes múltiplas continuam (sorteio), é tom |
| `box_sender` / `box_to` / `box_stamp` | DA ESCOLA / PARA O NOVATO / PESADO, NÃO MOLHAR... | texto da própria caixa na sala (arte) | MANTER | é parte do cenário, não UI |
| `disc_title` / `disc_label_*` / `disc_opt_*` / `disc_roll` / `disc_confirm` | tela de criar discípulo | tela própria | MANTER | formulário; só tirar `disc_glove_line` ("LUVA: O PAR DO JOHN") que repete `glove_start_desc` |
| `tree_*` / `tree_short_*` | árvore de legado | janela do mapa | MANTER | `tree_missing` e `tree_locked` redundantes entre si: manter `tree_locked` (diz o que falta) |
| `mural_*` / `hall_*` | mural e hall | janela | ENCURTAR | `hall_between` ("O HALL SÓ SE COMPRA ENTRE CAMPANHAS") e `hall_buy_only_end` ("COMPRA NO FIM DA CAMPANHA") dizem a mesma coisa: ficar com o segundo. `honor_what` só no hover de HONRA |
| `debug_*` | SALDO x1000 etc. | só overlay de debug | MANTER | fora do jogo normal |

## 3. A tela C (faixa fina + painel pela direita)

- Faixa de baixo de 30 px não tem espaço para título nem legenda: **ficam só** "+1" (com ícone), os focos (ícone + nome), LUTAR e PASSAR O POSTO.
  Saem junto: POR CLIQUE, FOCO DE TREINO, a linha de divisão do foco (`focus_split`: "FOR 40% / AGI 45% / RES 15%"), o rodapé SALVO e o F11.
- O painel que entra pela direita já tem aba (TREINO / LOJA) e as seções EQUIPE / MELHORIAS: **não repetir título**. LOJA sem título nem subtítulo.
- Atributos em miniatura: ícone + barra + número. Sem "ATRIBUTOS". A abreviação "RESIST." fica só como hover.
- "FIXAR ABERTO" é o único texto novo; sugestão curta: "FIXAR". Os atalhos L e E vão para o "?" e para o hover da aba, não para a tela.
- Selo de compráveis: número, sem texto.

## 4. Resumo do que sai da tela principal (sala, HUD, faixa de baixo, painel)

Contando só o que o jogador lê em partida normal, sem abrir janelas:

| | Hoje | Depois |
|---|---|---|
| Legendas fixas na tela (POR CLIQUE, FOCO DE TREINO, ATRIBUTOS, LOJA, "Dinheiro de luta, só aqui.", SALVO hora, DINHEIRO, FAMA, LEGADO) | 9 | 0 (TREINO fica; o chip SALVO vira piscada de 2 s) |
| Chip da arte | ~24 caracteres | ~10 |
| Linhas de dica/chip do assistido | 4 estados de texto | 2 |
| Hovers de aparelho/item | 5 frases-padrão diferentes | 2 (nome + custo; "Na caixa") |
| **Total de caracteres fixos na tela principal** | ~190 | ~70 (menos ~60%) |

Nas janelas, o corte é menor (cerca de 15% das linhas) porque quase tudo ali é custo ou perigo.

## 5. Os 10 cortes mais importantes

1. `per_click` POR CLIQUE: o "+1" em 2x já diz.
2. `focus_label` FOCO DE TREINO: título de uma fileira de botões com nome e ícone.
3. `panel_attributes` ATRIBUTOS: título de miniaturas com ícone, barra e número.
4. `shop_title` LOJA + `shop_sub` "Dinheiro de luta, só aqui.": a aba já é LOJA, o ícone de dinheiro é a moeda.
5. `saved_footer` SALVO hora: texto fixo que vira piscada de 2 s.
6. Legendas pequenas do HUD (DINHEIRO, FAMA, LEGADO EM JOGO): o ícone e o hover bastam; TREINO fica.
7. Chip da arte: "BOXE: +50% NO SEU CLIQUE" vira "BOXE +50%".
8. Chip do assistido: de 4 textos (`assist_hint`, `_waiting`, `_active`, `_metronome`) para 1 ("ASSISTIDO").
9. `tape_owned` ("Já está no lugar") e variações de hover de caixa/trancado: 5 frases viram nome + custo / "Na caixa".
10. `move_keeps` + `move_per_career` + `belt_hint` + `legacy_note`: garantias e desculpas que ninguém pediu.

## 6. Observações para a implementação

- Antes de apagar chaves do JSON, conferir com `Grep` se alguma é usada em `scripts/` (ex.: `texto_ui("move_*")` em `scripts/estado/academia_artes.gd`).
  As que só `ui/` lia podem ser removidas; as dos scripts são do Programador.
- Os textos acima que ficam, mas encurtam, exigem passar pela skill `alinhamento-ui` (largura muda).
- Dono dos números não sou eu: nada aqui altera valores, só rótulos.
