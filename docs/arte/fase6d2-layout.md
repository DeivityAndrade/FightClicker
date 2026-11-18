# Fase 6d2: sala larga de verdade e pontos novos (proposta)

Diretor de Arte, 2026-11-18. **Aprovado pelo dono e aplicado** em `assets/sprites` e no manifest (ver direcao-visual.md §28).
Pedido do dono: "no fim você só aumentou o chão e as paredes"; pessoas, aparelhos e elementos mais espaçados e bem posicionados;
aparelho não comprado totalmente invisível até a caixa ser aberta.

## Como olhar
| O quê | Arquivo (`docs/arte/mockups/`) |
|---|---|
| Antes x depois (6d esticada x 6d2), painel fechado e aberto/fixado | `fase6d2_layout_garagem_comparacao.png`, `fase6d2_layout_academia_comparacao.png` |
| Tela pronta, 1x e 2x (`_x2`) | `fase6d2_layout_<garagem\|academia>_<fechado\|fixado>_<cheia\|pequena>.png` |
| Só o fundo novo 640x360 | `fase6d2_fundo_garagem.png`, `fase6d2_fundo_academia.png` (+ `_x2`) |
| Conferência (zonas, caminhos, cabeças, balão, fileiras) | `fase6d2_layout_<local>_conferencia_x2.png` |

- **Cheia** = fim de jogo naquela sala: tudo comprado, equipe máxima, John no caixote, 2º mentor, mural com 8+ fotos
  (garagem com a pera na parede, academia com o boneco de Jiu-jitsu no tatame).
- **Pequena** = começo: garagem na 1ª carreira (2 da equipe, caixa da esteira e da luva esperando, corda ainda não comprada =
  nada na parede); academia recém-chegada (3 da equipe, John no caixote, caixa do boneco e da luva, corda não comprada).
- Gerador: `tools/art/make_mockup_fase6d2_layout.gd` (como rodar no topo do arquivo). Ele monta tudo com os sprites reais, nos
  pontos novos, e confere pixel a pixel (todos os quadros de cada folha). Resultado: **0 problemas** nas duas salas.

## 1. O fundo largo
- **Parede do fundo cresce de 300 para 500 px** (x 70..569). Mesmo ponto de fuga (320,-28), mesma linha do chão (y 220).
  As paredes laterais ficam estreitas (cunhas nas bordas): lê como sala larga, não como corredor.
- **O chão vai até y 329** (a faixa de baixo da opção C começa em 330): 110 px de fundo, contra 70 de hoje. É isso que cria
  espaço de verdade: quem está na fileira da frente (pés em y 318..327) não encosta em quem está no fundo (pés até y 257).
- **O miolo da parede de hoje (x 171..469) fica igual** (colado do `garage_bg` / `gym_bg`): porta, carro, prateleira, pôster,
  espelho, relógio, foto, mural, parede da memória, gancho da corda, pera na parede. Nenhum ponto de parede e nenhuma cena
  da porta muda.
- **Dois pilares** (x 164..174 e 468..478) marcam o "vão" de hoje e escondem as emendas. A sala vira 3 vãos.
- Luz: a mesma conta de cada sala, estendida. Garagem ganha a **janela basculante** à esquerda e uma **luminária de obra** à
  direita (cantos continuam escuros, mas ninguém some no breu). Academia ganha **2 tubos** novos (x 104 e 536, pintados no fundo).

| | Garagem (objetos novos) | Academia (objetos novos) |
|---|---|---|
| Parede esquerda | janela basculante com grade e vidro canelado, cano de água | 2 janelas altas com grade |
| Ala esquerda (fundo) | chapa de ferramentas (martelo, chave, serrote, alicate, trena) e **bancada** com morsa, caixa de ferramentas, lata, balde e aro de bicicleta | **quadro branco** da semana (rabisco ilegível), **suporte de halteres** de 2 andares, kettlebell e medicine ball |
| Ala direita (fundo) | **geladeira velha** com ímãs e bilhete, **pilha de pneus**, relógio de luz, mangueira enrolada | 3 **armários de aço** (cadeado, adesivo), **bebedouro** com galão, **árvore de anilhas** |
| Parede direita | escada de alumínio encostada | **espaldar** (barras de madeira) |
| Chão | concreto com juntas, manchas de óleo, ralo, giz da corda, círculo de giz | placas de borracha em xadrez em toda a largura, **tatame** azul na frente à esquerda (mudou de lugar com o boneco) |

Nada repete o que já existe. Nenhum texto legível novo na sala (regra da 5.1).

## 2. O alvo fica onde está
Lutador (303,272), saco (336,183), focos (corda 336,272; esteira 336,280; pera 330,274; boneco 338,279): **iguais**.
Com o painel fechado ele fica no meio da tela; com o painel fixado, um pouco à direita do meio da área visível, o que já era
assim. Mudar o alvo mexeria em todos os pontos de foco, efeitos e nas 4 cenas, sem ganho claro.
Zona protegida continua x 273..370, y 150..291 (nada entra; conferido).

## 3. Como a sala foi organizada
- **Três fileiras:** fundo (pés y 236..262), alvo (y 272) e frente (pés y 318..327). Fundo e frente não se tocam.
- **Ala esquerda = a escola:** os mentores no fundo (2º mentor, John no caixote, Osmar), a equipe da casa na frente (vizinhos 1 e 2,
  virados para o saco) e o tatame com o boneco.
- **Frente do lutador = entrega:** as caixas pequenas (luva e corda) aparecem logo abaixo dos pés dele, onde o olho já está.
  As grandes ficam onde o aparelho vai morar (esteira e boneco).
- **Ala direita = porta e esteira:** caminho da porta livre, esteira encostada na frente à direita, os tios virados para o saco.
- **Canto direito (x 506..639) = só com o painel solto:** decoração + 2 pessoas que não decidem nada (vizinho 3 e Prof. Nelson).
  Com o painel fixado eles ficam atrás dele (de propósito; o número deles continua no painel). Tudo o que pede clique (caixas)
  ou conta a história (Osmar, mentores, mural, foto) fica em x ≤ 505.

## 4. Tabela de pontos (antigo → novo)
Os mesmos pontos nas duas salas (como hoje). Pontos = pés (pivô), salvo indicação.

| Quem / o quê | Chave no manifest | Antes | **Novo** | Nota |
|---|---|---|---|---|
| Vizinho 1 | `sprites.neighbor_1.pos`, `gym.people_pos` | 176,284 | **72,322** | frente esquerda, olha o saco |
| Vizinho 2 | `neighbor_2` | 220,258 | **126,322** | frente esquerda |
| Vizinho 3 | `neighbor_3` | 488,286 | **590,322** | canto da frente à direita; só com o painel solto |
| Tio 1 | `uncle_1` | 455,236 | **400,324** | frente, à direita do alvo (x 376..415) |
| Tio 2 | `uncle_2` | 398,230 | **484,262** | fundo à direita da porta, fora do caminho |
| Prof. Nelson | `coach_1` | 394,280 | **548,250** | fundo à direita (pneus / armários); só com o painel solto |
| Osmar | `coach_point`, `gym_coach_spot` | 196,236 | **196,236 (igual)** | em frente ao carro / ao banco; as folhas da foto dependem desta distância |
| John / último sentado | `mentor_spot`, `gym_mentor_spot` | 254,252 | **132,254** | em frente à bancada / ao suporte de halteres; longe do alvo (era 3 px da folga) |
| Caixote | `...mentor_spot.crate.pos` (canto sup. esq.) | 238,232 | **116,234** | mesma conta (pés + (-16,-20)) |
| 2º mentor (de pé) | `mentor_2_spot`, `gym_mentor_2_spot` | 150,262 | **62,256** | junto da parede esquerda, embaixo da janela; `head_anchor_abs` 63,191; ocupa 50..74 x 191..257 |
| Mural | `mural_spot`, `gym_mural_spot` | 176,128 | **176,128 (igual)** | já estava num lugar bom; agora ninguém fica embaixo dele |
| Foto antiga (academia) | `gym_photo_spot` | 212,158 | **212,158 (igual)** | presa ao ponto do Osmar |
| Saco de lado | `bag_lN_side` `lado_esquerdo` | 258,160 | **igual** | |
| Corda no gancho | `layout.rope_hook` | 296,166 | **igual** | |
| Pera na parede | `speed_bag_lN_wall` `parede` | 436,46 | **igual** | |
| Esteira encostada | `treadmill_lN_side/_idle` `lado_direito` | 445,267 | **466,324** | sai da frente da porta; 28 px da ponta ficam atrás do painel fixado |
| Boneco deitado | `grappling_dummy_lN_rest` `canto` | 228,283 | **192,318** | em cima do tatame novo |
| Caixa da esteira (grande) | `layout.box_slots.treadmill` | 445,268 | **466,324** | onde a esteira vai ficar |
| Caixa da arte (grande ou pequena) | `box_slots.art` | 204,283 | **192,318** | onde o boneco vai ficar (a pera usa a pequena no mesmo ponto) |
| Caixa da luva (pequena) | `box_slots.glove` | 386,280 | **292,327** | na frente do lutador, à esquerda (x 268..315, y 292..329) |
| Caixa da corda (pequena) | `box_slots.jump_rope` | 424,287 | **348,327** | na frente do lutador, à direita (x 324..371) |
| Bolsa do John (só na saída) | `gym_arrival_scene.duffel` | 268,242 | **146,244** | segue o caixote (+30,+10) |

**Conferido** (`fase6d2_layout_<local>_conferencia_x2.png`, saída do gerador): nenhuma pessoa, caixa ou aparelho encosta em outro
(0 px opacos, todos os quadros), nada entra na zona do alvo, nada no caminho da porta (garagem: 423,221 → 410,236 → 392,258 →
303,272; academia: 428,224 → 400,246 → 352,262 → 303,272), nada passa da faixa de baixo, o balão do Osmar (120,132 154x36) não cobre
cabeça nenhuma, e as caixas, mentores, Osmar, mural e foto ficam à vista com o painel fixado.
Avisos aceitos: vizinho 3 e Nelson inteiros atrás do painel fixado; a esteira encostada com 28 de 1161 px atrás dele; o saco de lado
continua 2 px dentro da folga do alvo (igual a hoje).

Antes, com a equipe máxima, o vizinho 2 cobria 167 px do Osmar e o vizinho 1 cobria as pernas dele (aviso da 6c1, §25.2 da direção
visual). **Na proposta isso some**: não sobra nenhuma sobreposição.

## 5. Aparelho não comprado = invisível
Regra nova: **antes de comprar, nada** (nem fita, nem silhueta pontilhada, nem cadeado). **Comprou: aparece só a caixa**, no ponto da
tabela. **Abriu a caixa: aparece o aparelho** (as animações de chegada de hoje continuam). Vale nas duas salas e para pera e boneco.

**Sprites:** nenhum sprite é redesenhado. Deixam de ser usados na sala (ficam no projeto, marcados "sem uso desde 6d2"):
- `tape_mark_treadmill|rope|speed_bag|grappling_dummy` + `_hi` + `_dim` (12 arquivos);
- `ghost_treadmill|rope|speed_bag|grappling_dummy` + `_dim` (8 arquivos);
- `mark_padlock`.
`box_big`, `box_small`, `fx_box_*`, `fx_arrive_*` e os ícones/botões trancados da faixa de foco (`ui_button_focus_locked_*`,
`icon_*_locked*`) continuam: o "dá para comprar" passa a morar só na faixa e no painel.

**Manifest (`by_data_id.unlock_treadmill|unlock_jump_rope|unlock_speed_bag|unlock_grappling_dummy`):**
- tirar (ou marcar como sem uso) `floor_mark`, `ghost`, `ghost_dim`, `mark_states`, `mark_pos`, `lock`, `lock_pos`, `sign` e as notas
  "marca embaixo da caixa"; acrescentar `"room_before_box": "nothing"`;
- `box.pos` igual ao `layout.box_slots` novo (esteira 466,324; corda 348,327);
- `arrive.fx_pos`: esteira 445,267 → **466,324**; boneco 228,283 → **192,318** (corda e pera não mudam);
- `layout._nota_fase5` / `box_slots._nota`: trocar "a marca fica embaixo da caixa" por "antes da caixa não há nada na sala".

**Código (não é meu, só o que precisa mudar):** em `ui/sala.gd`, `_montar_marcas` / `_atualizar_marcas` deixam de desenhar fita,
silhueta e cadeado; o clique na fita (`marca_clicada`, "aponta a compra") e a dica de hover da fita somem junto. O caminho para
comprar fica o botão trancado da faixa de foco e o painel (sugestão ao UI/UX: clicar no foco trancado abre o painel no cartão do
aparelho, que é o que `marca_clicada` fazia).

## 6. O que muda no manifest (resumo, quando for aprovado)
1. `garage_bg` e `gym_bg`: novos fundos **640x360**, `pos` (0,0); `room_rect` vira (0,18,640,312). Os originais (384x272)
   ficam guardados em `tools/art/fonte_6d2/` (com `.gdignore`), de onde o gerador parte. **Aplicado.**
2. Pontos da tabela da §4: `sprites.<pessoa>.pos`, `by_data_id.gym.people_pos`, `mentor_spot(_info)`, `gym_mentor_spot(_info)`,
   `mentor_2_spot(_info)`, `gym_mentor_2_spot(_info)`, `by_data_id.mentor_spot`, `by_data_id.mentor_2_spot`, `layout.box_slots`,
   `positions.lado_direito` de `treadmill_lN_idle|side(_gym)`, `positions.canto` de `grappling_dummy_lN_rest(_gym)`,
   `gym_arrival_scene.crate|duffel`.
3. Regras do §5 nos 4 `unlock_*`.
4. Peças geradas a partir do fundo que precisam ser refeitas sobre o fundo novo: `garage_daylight` (chão +1 junto da porta),
   `gym_daylight`, `gym_half_dark` (vira 640x360, com furo na porta).
5. `balao.gd` (área útil 132..507): com a sala larga pode ir a x 4..636 com o painel solto e 4..502 com ele fixado (UI/UX + DC).

## 7. Para o Diretor de Cutscenes (ajustes das cenas)
Nenhuma cena sai pela borda da tela: todas entram e saem pelas portas, que não mudaram. O que muda é a distância até os pontos novos.
- **Painel durante cena:** fecha sozinho quando a cena começa (mesmo fixado) e volta como estava no fim. Sem isso, tudo à direita de
  x 506 some atrás dele (hoje a saída pela porta não é afetada, mas o Nelson, o vizinho 3 e a ponta da esteira sim).
- **`primeira_sucessao`:** o John vai de (303,272) ao `mentor_spot` com `step_back` em 1,1 s (52,9 px). Agora são **~172 px**: virar
  meia-volta + `walk` (~3,6 s a 48 px/s) ou um `step_back` curto e depois andar. O `point_spot` continua apontando o chão do saco.
- **`primeira_academia`:** quem traz o caixote anda de (396,246) até o `gym_mentor_spot`: era 142 px (2,95 s), agora **~264 px**
  (~5,5 s), passando atrás do lutador e na frente do Osmar (ordem por y resolve). O ajudante com a esteira velha ia até (440,250) e a
  esteira virava objeto em (445,267): agora ela pousa em **(466,324)**; sugiro ele andar até ~(470,300) antes de largar.
- **`saida_primeiro_mentor`:** o John sai do caixote novo (132,254); a 1ª perna até (274,224) passa de ~36 px para **~145 px**. A bolsa
  no chão vai para (146,244). O último que passou o posto anda do `mentor_2_spot` (62,256) ao caixote: **~70 px** (era 104; 1,46 s).
- **`chegada_discipulo`:** caminho da porta igual; nada muda.
- Com mais chão à esquerda, a câmera das cenas (zoom no 1x/2x) pode precisar mirar um pouco mais à esquerda quando o John estiver no
  caixote novo.

## 8. Placeholder / o que pede pixel artist humano
- Os dois fundos são montagem por código: bancada, geladeira, pneus, armários, espaldar e o suporte de halteres são formas simples.
  Um artista faria o material (madeira gasta, esmalte da geladeira, borracha dos pneus, aço riscado) e a "história" de cada canto.
- Os pilares escondem as emendas com a sala de hoje; à mão, o fundo seria pintado inteiro de uma vez.
- As pessoas têm a luz da lâmpada pintada para os pontos antigos: nos pontos novos ficam um pouco claras ou escuras demais
  (vizinhos da frente esquerda e o Nelson no canto). Para a versão final, gerar de novo com a luz de cada ponto (Artista de Personagens).
- Tamanhos e pivôs de tudo continuam os mesmos: trocar a arte depois é trocar o arquivo.
