# Ronda 2a1: arte da briga de beco (vulto lutando, 3 bandidos, beco, estilos) no manifest

Artista de Personagens, 2026-11-26. Skill `padrao-personagem`. Prancha para o dono: `docs/arte/mockups/ronda2a_amostra_luta.png`.

**Entradas:** `tools/art/ronda2a_manifest.json` (o Programador mescla):
- `sprites`: 120 entradas, todas novas, nenhum id do manifest atual é sobrescrito;
- `by_data_id`: 6 entradas novas (`opp_alley_tire`, `opp_alley_bike`, `opp_alley_gate`, `vulto_fight`, `arena_alley`, `alley_fight`);
- `disciple_palette_add`: **acrescentar** às listas de `by_data_id.disciple_palette`, sem substituir (ver Estilos).

## 1. Vulto lutando (`by_data_id.vulto_fight`)
- **28 ações**, as mesmas do `player_fight`, cobrindo Boxe, Jiu-jitsu e Muay Thai. O id é `fight_vulto_<ação>`, e os arquivos ficam em `assets/sprites/ronda2a/vulto/`.
- **Contrato igual ao do discípulo:** a entrada copia de `fight_player_<ação>_disc_layered` o quadro 112x104, o pivô (56,98), os quadros, o fps, `hands`, `hit_frame`, `hit_point`, `ground_frame` e `loop`. A tela de luta não precisa de conta nova.
- **Montagem:** a mesma do `DiscVisual.textura(nome, look, simbolo)`, com o look do discípulo da vez e a troca de cor pela `disciple_palette`. `layers.order` = body → top → socks → school_symbol (só `leg`) → head.<hair_style> → front_mask.
  - `body` (arquivo novo): o corpo do discípulo com a **luva da noite** (pano escuro com punho vermelho) e a **capa desenhada atrás do corpo**, só onde o corpo é vazio. A capa nunca tapa braço, perna nem luva.
  - `head.<corte>` (4 arquivos novos): o **capuz** com orelhas e a faixa vermelha nos olhos, o mesmo mapa aprovado na Ronda 1. Ele é carimbado no ponto e no giro da cabeça de cada quadro (`anchors.head`/`head_rot` da folha do discípulo) e substitui a cabeça.
  - `top`, `socks`, `school_symbol.leg` e `front_mask` apontam para os **mesmos arquivos do discípulo**.
  - Não tem `band` (o capuz cobre a faixa), nem `school_symbol.chest`, nem `anchors`. Sem `anchors`, o remendo do patrocinador (8a2) não aparece no traje.
- **Sem `_glove_lN`:** de noite a luva é a do traje.
- **Nunca espelhar** a folha. O vulto luta virado para a direita, como o jogador, então o R de raiz da coxa lê certo.
- **Sem rosto:** aparece só o queixo, como na Ronda 1. No K.O. o olho de gato da fresta apaga.
- **`portrait_vulto`** (32x32) é para o HUD, com o nome "???". Ele tem as chaves de pele e cabelo: trocar pela paleta do look ou usar como está.
- **Risco do escopo resolvido:** a capa **coube** nas 3 artes. O corte "só o capuz" não foi preciso. Se um dia for, basta trocar o `body` pela camada do discípulo com a luva da noite.

## 2. Bandidos (`opp_alley_tire` / `_bike` / `_gate`)
- **Mesmo contrato dos adversários da liga:** 112x104, pivô (56,98), `facing: esquerda`, `pos` (346,318), retrato `portrait_<id>` 32x32 (serve também para o Dossiê).
- **Ações:** as 26 de sempre, com os mesmos quadros, `hit_frame`, `hold_last` e `ground_frame`. Mãos e contato vêm do jogador × escala.
- **Pose da passiva**, a mesma da liga, em `actions.signature`:

| id | Corpo | Escala | Luva | `signature` |
|---|---|---|---|---|
| `opp_alley_tire` Zeca Estepe | baixinho largo, gorro verde, regata, bermuda jeans, chinelo | 0,90 | borracha amarela | `plant_feet` (Base larga, NÃO CAIU) |
| `opp_alley_bike` Fio | magrelo comprido, boné para trás, corta-vento roxo, moletom | 1,08 | fita cinza | `guard`, e o `block` próprio da guarda fechada (Blindado) |
| `opp_alley_gate` Seu Pé de Cabra | barrigudo careca de bigodão, camisa social, jeans com cinto, botina | 1,04 | couro de obra | `shake_head` (Queixo de ferro, AGUENTOU!) |

- **Fuga tonta** (`daze_flee` = `actions.flee`): 6 quadros a 9 fps, em loop. É o "SAIU TONTO E FUGIU": ele recua cambaleando, com olho em x, e a tela leva o x para a direita.
- **K.O. sem sangue:** é o `ko` do rig ("APAGOU"), com olho em x e nada vermelho. Também servem `ko_back`, `ko_knees` e `fall_spin`.
- A tela usa as passivas como na liga: `_guarda_fechada` pela passiva `adv_blindado`, e `signature` no `opp_block`.

## 3. Beco (`arena_alley`: `_bg`, `_lamp`, `_crowd_back`, `_crowd_front`), em `assets/sprites/ronda2a/arena/`
- **Contrato das arenas:** 640x360, y 0..45 em ink liso (conferido: 0 px fora), pés em y 318, chão livre x 200..440.
- **Luz:** a arandela fica no alto do meio. A parede atrás dos lutadores fica em **meio-tom** (tijolo br1, com a luz decidida por tijolo) e escurece para as bordas.
- **`_lamp`:** é a arandela, com 3 quadros (acesa, fraca, apagada). O `swing` da tela vira "pisca".
- **`_crowd_back`:** é a **garoa** (no beco não tem público). Tem 2 quadros, `frame_size` 640x314 e `pos` (0,46): a tela precisa usar o `frame_size` e o `pos` do manifest.
- **`_crowd_front`:** só nos cantos (conferido: 0 px em x 138..502).
- Pedir a arena pelo `kind`: `alley_fight` → `arena_alley`. O mapa está em `by_data_id.alley_fight`.

## 4. Estilos da noite (`disciple_palette_add`): só cor, na arte que já existe
| Estilo | Opção | Rampa |
|---|---|---|
| Faixa da noite | `headband_color.night` | light y0 (borda âmbar), dark d1, deep ink |
| Calção escuro | `shorts_color.night` | band y0 (cós âmbar), light d2, mid d1, dark/deep ink. **E `school_symbol_source.leg.map.night = yellow`** |
| Bandagem | `socks.night_wraps` | base cream, shadow g2, stripe g1 |

**Código necessário (Programador):** hoje o `DiscVisual` só desenha a camada `socks` com `look.socks == "on"` e pega as cores pela entrada com o id do calção. Para a bandagem, ele precisa desenhar também com `night_wraps` e usar `options.socks[night_wraps]`. Na prancha (seção 4) está como deve ficar.

## Como gerar de novo
Tudo headless, de uma pasta temporária com `project.godot` vazio e APPDATA temporário, um Godot por vez:
1. Rodar `python tools/art/poses_ronda2a.py`, que gera `golpes_ronda2a_adv.json`.
2. Expandir as reações (`FC_GOLPES=tools/art/<n>.json make_golpes_jogador.gd -- <tmp>/exp_<n> nada`) para golpes, golpes_7a1_adv, golpes_7b1_adv, golpes_8a1_adv e golpes_ronda2a_adv.
3. Gerar os bandidos: `FIGHTCLICKER_ROOT=<repo>/ make_sprites_elenco.gd -- <saida> <tmp> alley <exp_golpes> <exp_7a1> <exp_7b1> <exp_8a1> <exp_r2a> tools/art/golpes_8a1_adv.json tools/art/golpes_ronda2a_adv.json`.
4. Gerar o vulto, o beco e a prancha: `make_sprites_ronda2a.gd -- <repo> <saida> vulto beco prancha`. Ele lê os bandidos de `<saida>/opponents`.
5. Copiar `<saida>/opponents/*` e `<saida>/ronda2a/*` para `assets/sprites/`, rodar o `--import` headless e juntar os dois JSON da saída em `tools/art/ronda2a_manifest.json`.

As mudanças no `make_sprites_elenco.gd` só acrescentam (o modo `alley` e as fichas `opp_alley_*`). Os modos antigos dão o mesmo resultado.

## Conferência e limites
- **Bandidos:** nenhum toca a borda do quadro. O IK estica até 1,2 px em poses extremas (vitória do Zeca, chão), como nos outros adversários.
- **Vulto:** 24.019 px de luva trocados nas 28 folhas. A luva sai da diferença entre as camadas body das luvas velha, L1, L2 e L3, então nada fora dela muda.
- **Ainda pede pixel artist humano:**
  - **Capa:** é uma função (pregas e atraso pelo movimento do tronco), não pano desenhado quadro a quadro. Deitada vira um montinho. (B5: agora mais curta e pesada, quase não abre no soco.)
  - **Capuz:** o capuz girado no K.O. deitado põe o colarinho sobre o peito, e lê como mancha escura.
  - **Rosto dos bandidos:** tem 2 a 4 px. A fuga tonta é um ciclo curto de 6 quadros.
  - **Beco:** é placeholder de cenário (formas retas, chuva parada no fundo). A garoa animada tem só 2 quadros a 2 fps na tela.
  - **Bandagem:** é só cor no meião (lê como meião creme com listra). Uma bandagem de verdade, com faixas cruzadas, pede uma camada nova por pose.

## B1. Recorte de cada bandido vencido na parede (Diretor de Arte, 2026-11-26)
Gerador: `tools/art/make_arte_ronda2a_recortes.gd`, rodado headless de uma pasta com `project.godot` vazio:
`godot --headless --max-fps 30 --path <vazia> --script <worktree>/tools/art/make_arte_ronda2a_recortes.gd -- --root <worktree> [--caps <capturas do ui_audit>]`.

**Entradas:** `tools/art/ronda2a_recortes.json`. Quem mescla (Programador ou UI/UX) põe `sprites` em `manifest.sprites` e `layout` em `manifest.layout`. Todas as chaves são novas e nenhuma existente é sobrescrita.

**Pranchas:**
- `docs/arte/mockups/ronda2a_recortes_locais.png`: as peças, os 3 locais com 1, 2 e 3 vencidos, e a sala inteira em 1x.
- `ronda2a_recortes_garagem_x2.png`, `ronda2a_recortes_academia_x2.png` e `ronda2a_recortes_centro_x2.png`: a sala em 2x.

### Sprites (15x18, 1 quadro, pivô 0,0, camada `wall`, z −45)
| id | Arquivo | Onde |
|---|---|---|
| `wall_clipping_alley_tire` / `_bike` / `_gate` | `garage/wall_clipping_alley_<id>.png` | garagem (papel creme, luz da lâmpada pela esquerda) |
| `wall_clipping_alley_<id>_gym` | `gym/wall_clipping_alley_<id>_gym.png` | academia (papel branco) |
| `wall_clipping_alley_<id>_center` | mesmo arquivo do `_gym` | centro |

**Sem texto legível em 1x:** não cabe em 15x18. Cada recorte se reconhece por três coisas:
- a **foto** do que o bandido largou: o estepe e a chave de roda, a bicicleta, ou o portão e o pé de cabra;
- 2 barras de manchete;
- o **carimbo vermelho do gato**.

A manchete inteira vai no **hover**, com a chave `alley_<id>_clipping` de `data/ui_texts.json`. O recorte de nível da lenda (Ronda 1, 23x28) não muda.

### Pontos (canto de cima à esquerda, 1x; mesmo sistema do `clipping_spot`)
| Local | Ponto no layout | tire | bike | gate | `click_rect` (os 3) |
|---|---|---|---|---|---|
| Garagem | `alley_clipping_spot` | (269,108) | (284,112) | (275,127) | (269,108,30,37) |
| Academia | `gym_alley_clipping_spot` | (365,39) | (378,43) | (370,55) | (365,39,28,34) |
| Centro Raízes | `center_alley_clipping_spot` | (365,103) | (378,107) | (370,121) | (365,103,28,36) |

- **Garagem:** os recortes ficam embaixo do pôster SOCO (até y 104) e à esquerda do recorte do Gato Preto (que começa em x 304), acima da corda no gancho (296,166) e da zona do alvo (y 150).
- **Academia:** ficam à direita do recorte do Gato Preto (até x 363), acima do relógio de rounds (y 74), antes do cartaz da liga (x 394, também na versão VENCIDA 42x58) e abaixo do teto.
- **Centro:** ficam à direita do capuz no prego (o `click_rect` dele vai até x 362), embaixo do relógio de rounds (até y 100) e antes da porta de vidro (x 399).

**Conferência do gerador: 0 problemas.** Nenhum recorte encosta em:
- recorte do Gato Preto, capuz no prego (352,95) ou corrente do saco;
- zona do alvo, cards (x < 128) ou painel (x ≥ 506);
- espelho, relógio, cartaz, portas ou tubos de luz;
- qualquer coisa que o manifest posiciona.

A parede embaixo é lisa nos 3 fundos: só tijolo `g0/g1/g2` na garagem e reboco `white/cream/g3` na academia e no centro.

### Para a UI/UX ligar em `ui/sala.gd` (só o que a arte pede)
O ponto do local atual é `alley_clipping_spot` (garagem), `gym_alley_clipping_spot` (academia) ou `center_alley_clipping_spot` (centro).
1. **Desenho:** para cada id de `layout.<ponto>_info.order` (`tire`, `bike`, `gate`) já vencido (`permanent.alley`), desenhar
   `sprite_by_id[id]` em `layout.<ponto>[id]`, nessa ordem. Assim o último fica por cima.
2. **Camada:** `wall`, z −45, como o recorte do Gato Preto. Some junto com ele quando `wall_objects` está em `_cena_oculta`.
3. **Hover:**
   - área: a união dos retângulos dos recortes já desenhados. O `click_rect` do `_info` é a união dos 3, para quando todos foram vencidos;
   - texto: `object_text_by_id[id]` do vencido mais recente, ou seja, o último de `order` que já foi vencido;
   - não há zoom em imagem.
4. Sem clique e sem animação.

## B5. O vulto foge do morcego (Diretor de Arte, 2026-11-26)
O QA viu a silhueta da luta lembrar o morcego. O conceito aprovado pelo dono continua o mesmo: capuz preto de moletom com orelhas de gato costuradas, a faixa da escola como máscara e uma capa de lona. Só os traços que fogem do morcego foram reforçados, na skill `padrao-personagem`.

**Orelhas** (mapa `HOOD`, linhas 0–3, e o corte `bun`):
- **Antes:** pontas de 1 px que subiam 4 linhas.
- **Agora:** orelhas baixas de ponta arredondada (2 px em cima, 4–5 na base), sem o rosa de dentro.
- **Costura:** pontos `g1` alternados na base (chave nova `t`).
- O mapa continua 16x22, com a mesma âncora (8,11).

**Capa** (`cape_draw` e `cape_params`):
- **Material:** **lona cinza** (`g0/g1/g2`), bem mais clara que o capuz preto, com 2 pregas largas e duras.
- **Barra cortada torta:** corte reto inclinado, com um dente de tesoura. Substitui a barra em gomos, que fazia pontas de asa.
- **Detalhes:** **3 ilhós** de metal (`g3` com anel `d2`) na beira de trás e no canto, e um **remendo de lona azul** (`b1`) com pontos `g3`.
- **Caimento mais pesado e mais curto:**
  - comprimento: de 30 para 24 (deitado, de 21 para 17);
  - onda: de 0,6+1,2v para 0,25+0,45v;
  - o golpe empurra a capa metade do que empurrava.

**Faixa:** continua vermelha (`r1/r2/r3`).

**Contrato igual:** as 28 entradas `fight_vulto_*` e o `portrait_vulto` do JSON gerado são **idênticos** aos do manifest: quadro 112x104, pivô (56,98), mãos, hit e anchors de origem. Só mudaram os PNG de `assets/sprites/ronda2a/vulto/*` (141 arquivos, mesmos nomes).

**Pranchas:**
- `docs/arte/mockups/ronda2a_vulto_antes_depois.png`: poses 3x, **silhueta chapada**, capuz e capa em 6x, e a cena no beco.
- `ronda2a_amostra_luta.png`: refeita com o vulto novo.

Para refazer: `make_sprites_ronda2a.gd -- <repo> <saida> vulto antes_depois`, com `FC_ANTES=<pasta com as folhas antigas>`.

### Ronda 1: o mesmo ajuste, para o vulto ser um só
O ajuste também foi feito na Ronda 1. O vulto da rua e o da luta são a mesma pessoa, e o capuz no prego é o mesmo capuz. Orelha pontuda e capa escura lá, com orelha redonda e lona aqui, ficaria incoerente.

**Prova de que só mudou o vulto:**
- Antes de mexer, o `make_sprites_ronda.gd` sem mudança regenerou as 72 folhas **byte a byte iguais** às do repo.
- Depois, só mudaram as 35 folhas `minigame/ronda_vulto_*`: body, head e socks (a capa mais curta mostra mais meião).
- As folhas dos ladrões não mudaram, e o `ronda_personagens.json` saiu idêntico. O manifest não muda.

**O que mudou nos geradores:**
- `make_sprites_ronda.gd`: o mesmo mapa de orelhas e a capa de lona cinza (barra torta, ilhós, remendo azul, comprimento ×0,85, onda ×0,5). As poses são as mesmas: telhado, andando, estátua, pulo, SUSTO e visto.
- `make_arte_ronda.gd`: o capuz no prego (`hood_on_nail`, `hood_on_nail_gym`) perdeu a ponta de 1 px das orelhas e ganhou a costura na base. A opção nova `--so-capuz` refaz só esses 2 arquivos.

**Prancha:** `docs/arte/mockups/ronda_vulto_antes_depois_r1.png`. Para refazer: modo `antes_depois_r1`, com `FC_ANTES_R1=<cópia antiga>`.

**O que não mudou, e por quê:** os recortes de jornal da Ronda 1 e da 7a2 (silhueta de 7–18 px) e as camadas da rua (estêncil, bandeirinhas). Nesse tamanho a orelha já é um bloco de 1–2 px, e mexer exigiria refazer peças aprovadas sem ganho de leitura.

**Mockups antigos desatualizados:** `ronda_capuz_*`, `ronda_amostra_vulto.png` e `ronda_elenco.png` ainda mostram a orelha antiga. Os PNG do jogo estão certos. Para atualizar, rodar o `make_arte_ronda.gd` completo e o `make_sprites_ronda.gd` com folha de conferência quando der.

### Ainda pede pixel artist humano
- **Capa:** ainda é uma função (pregas e atraso). À mão, a lona seria desenhada quadro a quadro, com peso, vinco duro e barra desfiada.
- **Ilhós e costura:** têm 1 px. Em 1x leem como "detalhe claro"; só em 2x ou mais leem como ilhó e costura.
- **Recortes dos bandidos:** estão retos (sem giro) para caber em 15x18 sem serrilhado. À mão, ficariam levemente tortos e com a foto mais viva.
