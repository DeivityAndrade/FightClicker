# Levantamento para a varredura de alinhamento (identidade visual)

Só leitura de código (ui/, scenes/, tools/ui/ui_audit.gd). Godot não foi rodado.
Contagens por grep; "estimativa" quando dependem de interpretação.

## Resumo em números
- `ui_align = ignore` declarados: **30** (29 em ui/*.gd + 1 em scenes/garagem.tscn). Um `ignore` vale para o nó **e todos os descendentes**.
- Com motivo escrito (comentário): **8**. Sem motivo: **22**. O verificador não exige motivo.
- Classificação: OK 17, TROCAR 7, PROIBIDO 6 (ignore em botão ou que engole botão/texto fixo).
- Texto desenhado por `draw_string`/`draw_char`/`draw_multiline_string`: **0** no projeto inteiro (todo texto é `Label` criado por `UiTema.rotulo`). Os `_draw()` existentes só desenham retângulos/texturas.
- Chamadas `UiTema.rotulo(` em ui/: **~197**. Só ~60 passam por helper/declaração (`rotulo_centrado`, `rotulo_centro`, `alinhar`, `botao_conteudo`). Estimativa: **~130 Labels** de posição fixa (x/y numéricos, `LEFT`) sem nenhuma intenção, e portanto o verificador só confere se não estão cortados/fora da tela, não se estão no centro.
- Há **24** contas manuais de centro (`320.0 - ...`, `roundf(x - largura/2)`) em ui/*.gd: centralização "à mão" sem declaração, que o verificador não cobra.

## 1. Tabela de `ui_align = ignore`

Legenda: B=botão, TF=texto fixo, TD=texto dinâmico, DEC=decoração, MUN=mundo/sprite, CONT=contêiner (herdado engole filhos).

| Arquivo:linha | Nó | O que é | Motivo escrito | Classe |
|---|---|---|---|---|
| scenes/garagem.tscn:33 | Sala | MUN: sala inteira (sprites, números flutuantes) | não | OK (mundo) |
| ui/balao.gd:184 | _raiz do balão | CONT: sobreposição com rótulo que cresce letra a letra (TD) | sim | OK, mas ver nota B1 |
| ui/cartao_adversario.gd:41 | fundo (nine_patch ui_card) | DEC | não | TROCAR: é o fundo do cartão, `center` no pai ou dispensar (nó sem texto) |
| ui/cartao_passiva.gd:56 | fundo (nine_patch ui_card) | DEC | não | TROCAR (idem) |
| ui/cena_ui.gd:35 | CenaUi (raiz da cena de história) | CONT: engole `_montar_pular` = **botão PULAR** e o player | não | PROIBIDO (ignore herdado em botão) |
| ui/cena_ui.gd:65 | _barras | DEC: faixas pretas cinematográficas | não | OK |
| ui/faixa_assistido.gd:50 | FaixaAssistido (raiz) | CONT: chip + **~14 botões/Labels** (botão ASSISTIDO etc.) | sim ("canto esquerdo, de propósito") | PROIBIDO (botões e texto fixo ficam sem checagem; trocar por `left` na raiz e declarar cada filho) |
| ui/janela_arte.gd:163 | borda (ColorRect) | DEC: moldura da opção | não | OK |
| ui/janela_arte.gd:169 | fundo (ColorRect) | DEC | não | OK |
| ui/janela_arte.gd:203 | botao (Button flat, sem texto) | B: área de clique da opção | não | PROIBIDO (é botão; sem texto, então trocar por `center`/`ui_pos` ou `ui_align_row=free`) |
| ui/janela_arte.gd:229 | t (TextureRect, ícone/quadro) | DEC/ícone | não | TROCAR (`center_v` na linha) |
| ui/janela_arte.gd:244 | nine_patch da barra de meta | DEC | não | OK |
| ui/janela_arte.gd:268 | enchimento da barra | DEC | não | OK |
| ui/janela_arte.gd:276 | tick da barra | DEC | não | OK |
| ui/janela_vitoria.gd:99 | ic (ícone do bônus) | DEC; o grupo ícone+Label é centralizado à mão (`roundf(320 - grupo/2)`) e o Label é `left` | não | TROCAR (declarar o grupo como `center_h` no contêiner e não ignorar o ícone) |
| ui/janela_vitoria.gd:126 | caixa (bloco da liga) | DEC: caixa translúcida; os Labels dentro têm x fixo | não | TROCAR (`center_h` na caixa; labels dentro ficam sem checagem de margem) |
| ui/janela_vitoria.gd:181 | caixa (passiva 2) | DEC (idem) | não | TROCAR |
| ui/janela_vitoria.gd:304 | caixa do aviso "CENTRO LIBERADO" | DEC; comentário diz "NÃO é botão" | parcial | TROCAR (`center_h` e Labels `left` com margem simétrica) |
| ui/painel_loja.gd:169 | hov_luva | Control invisível só para hover | não | OK |
| ui/tela_choque.gd:234 | q (degraus do kick) | DEC contendo Label centrado (`rotulo_centrado`, `center`) | não | **PROIBIDO**: o ignore engole o Label que declarou `center`; é o contrário do pedido. Tirar o ignore do degrau |
| ui/tela_criar_discipulo.gd:69 | cartao (prévia) | DEC | não | OK |
| ui/tela_criar_discipulo.gd:100 | _nome_caixa | CONT do LineEdit | não | OK (campo de texto, mas ver B3) |
| ui/tela_criar_discipulo.gd:121 | _nome (LineEdit) | texto digitado | sim | OK |
| ui/tela_criar_discipulo.gd:167 | g (grupo de setas) | CONT: recebe `reparent` de **botões esq/dir** | não | PROIBIDO (botões de seta ficam sem checagem) |
| ui/tela_criar_discipulo.gd:173 | valor (nine_patch) | CONT: nome da opção/contador + chips "centralizados à mão" | sim | PROIBIDO na prática (texto centralizado à mão, sem medição; trocar por `rotulo_centrado` + `center`) |
| ui/tela_luta.gd:269 | _ropes_side | MUN (Sprite2D) | sim (z_index) | OK |
| ui/tela_luta.gd:389 | b (banner de fim) | MUN | não | OK |
| ui/tela_luta.gd:401 | sp (sinal pequeno) | MUN | não | OK |
| ui/tela_luta.gd:428 | sp (sinal do adversário) | MUN | não | OK |
| ui/tela_luta.gd:442 | _cinturao | MUN | não | OK |
| (Sprite2D/Node2D) | — | `_coletar` já ignora Node2D sozinho; esses 6 `ignore` em Sprite2D/AnimSprite são redundantes | — | OK (redundante) |

Documentado como padrão (não é linha de meta, mas é ignore de fato): `ui/janela_mapa.gd:9` diz que os nós do mapa são `ignore` (a meta é posta via `UiTema.alinhar`/diagnostico próprio, `ui_tema.gd:365` é o helper genérico). O mapa tem `diagnostico()` próprio, então é OK.

Nota B1: balão — Label dentro de ignore; texto de fala com `left`; o verificador não confere margem do texto no balão.
Nota B3: `_nome` LineEdit com texto centralizado só visualmente.

Contagem final: OK 17 (6 são Sprite2D/AnimSprite, redundantes), TROCAR 7 (cartao_adversario:41, cartao_passiva:56, janela_arte:229, janela_vitoria:99/126/181/304), PROIBIDO 6 (cena_ui:35, faixa_assistido:50, janela_arte:203, tela_choque:234, tela_criar_discipulo:167 e :173).

Outros "equivalentes" ao ignore:
- `ui_align_row = free` (cobra largura igual entre botões irmãos): `barra_baixo.gd:62`, `janela_arte.gd:54`, `janela_fim.gd:236` (1 botão largo). Aceitável; só barra_baixo merece motivo escrito.
- `ui_pos = center_h`/ declarado: ~20 usos (janela_base, janela_mapa, janela_arte, etc.). Não é ignore.
- Filhos que não são `Control` (Node2D, Sprite2D, AnimSprite) são pulados por `_coletar` sem metadata nenhuma.
- `_recortado()` pula Controls fora da área visível de pais com `clip_contents` (aba TREINO rolada).
- Controles invisíveis (`visible=false`) são pulados. Qualquer janela que só aparece depois (ex.: banners) só é auditada no estado que a mostra.

## 2. Texto desenhado por código
- `draw_string` / `draw_char` / `draw_multiline_string`: **nenhum** em ui/, scripts/, scenes/. Único `get_string_size`: `ui/ui_tema.gd:115` (`largura()`), base de toda a conta de centro.
- Texto = `Label` via `UiTema.rotulo(pai, txt, cor, x, y, largura, alinhar, ...)` (`ui_tema.gd:163`). Posição de `x` calculada:
  - pela largura medida (`UiTema.largura`/`largura_visivel`): ~70 pontos (contagem de usos em barra_baixo, hud, janela_vitoria, janela_mural, janela_fim, painel_loja, cartao_passiva...).
  - por número fixo: maioria dos ~197 rótulos. Os mais sensíveis: `painel_loja.gd` (32 rótulos, 5 usos de largura), `janela_previa.gd` (14/6), `janela_vitoria.gd` (15/8, e `320.0 - grupo/2`), `bloco_proxima.gd` (11/4), `tela_luta.gd` (12/7), `janela_fim.gd` (15/6), `janela_mapa.gd` (9/5).
- `_draw()` existentes (só retângulos/texturas, sem texto): `painel_loja.gd:1192` (setinha, 4 px), `sala.gd:2267` (textura repetida), `sala.gd:2384` (setinha com `cx = 336` fixo), `tela_choque.gd:565` (barra do kick; a janela de acerto e a linha usam `ZONA_X` fixo), `janela_mapa.gd:409` (faíscas).
- Contas manuais de centro `320.0 - ...`/`roundf(x - largura/2)`: 24 ocorrências (janela_vitoria, janela_fim, hud...). Cobertas só quando o nó acaba declarado (`rotulo_centro` com cx = meio do pai vira `center_h`); quando o código faz `rotulo(..., x, y)` com x calculado, nada é conferido.

## 3. Nós de UI sem intenção declarada (estimativa por arquivo)
Intenção = `rotulo_centrado`, `rotulo_centro` (só se cx = meio), `alinhar`, `botao_conteudo`, `ui_align`, `ui_pos`. Botões têm `center` implícito; Labels sem declaração são conferidos só contra corte/fora da tela.
Estimativa de Labels sem intenção (rotulo - declarações): painel_loja ~20, janela_previa ~8, janela_vitoria ~7, bloco_proxima ~7, janela_fim ~8, tela_luta ~7, janela_mural ~4, hud ~3, cartao_passiva ~4, tela_choque ~4, janela_mapa ~3, outros arquivos ~1-2 cada. Total **~130**.
ColorRect/TextureRect/nine_patch decorativos sem declaração: dezenas em janela_vitoria, janela_previa, painel_loja, janela_fim (não estimado; geralmente inofensivos).
Arquivos sem nenhuma declaração (0): `debug_overlay.gd`, `pular_abertura.gd` (**botão PULAR tem texto?** conferir), `garagem.gd` (7 botões criados por código, só o `center` implícito).

## 4. Propostas de endurecimento do verificador (custo estimado)
1. **Proibir `ignore` em Button/Label com texto, ou ancestral com botão/Label**: ao encontrar `ignore`, percorrer descendentes; se achar `Button` visível ou `Label` não vazio, é problema `IGNORE_PROIBIDO` com a lista dos filhos. Pega os 6 PROIBIDOs acima. Custo: ~30 linhas, 30 min. Exigirá corrigir os 6 casos (1-2 h).
2. **Exigir `ui_align_motivo`** em todo `ignore` e `ui_align_row = free` (string não vazia; helper `UiTema.ignorar(no, motivo)` que seta as duas metas). Troca os 30 sets por chamada do helper. Custo: 1 h de helper + 30 edições; o verificador falha sem motivo.
3. **Auditar texto fixo `left` com margens**: para todo Label `LEFT` sem declaração cujo pai seja janela/painel/cartão (nine_patch), medir margem esquerda do texto à borda e direita da área útil; falhar se `|esq - dir| > 1` quando o Label está sozinho na linha, ou se for linha com 2 colunas (aviso). Custo: ~60 linhas, 1-2 h, e vai gerar muitos achados reais (os ~130 Labels).
4. **Centro de texto por hook**: como não há `draw_string`, não precisa; basta tratar `rotulo()` como base. Opcional: marcar `rotulo()` com meta `ui_x_calc = centro` quando o x vem de `320 - largura/2` (helper `rotulo_no_centro(pai, txt, cx, y)` que usa `rotulo_centro`), e o verificador confere esse meta contra o centro do pai. Migrar as 24 contas manuais. Custo: 1 h helper + 2-3 h migração.
5. **Janelas: margens simétricas**: para todo nó `nine_patch`/`PanelContainer`/janela (raiz de `JanelaBase`), conferir que o retângulo é simétrico em 640x360 (esq = dir, topo = base ou topo/base conforme declarado) e que o conteúdo (união dos filhos visíveis) tem margens internas simétricas (±1 px). Hoje só checa centro da janela declarada. Custo: ~50 linhas, 1-2 h.
6. **Nada opaco sai da tela**: checar `CanvasItem` não-ignorado (inclui Node2D/Sprite2D hoje pulados) com alpha ≥ 0,9 cujo retângulo vaza para fora de 640x360 além de 0 px, salvo whitelist `ui_align_motivo`. Custo: ~25 linhas, 1 h; evita sprites/sombras vazando.
7. **Fileira de botões**: já existe; endurecer `ui_align_row=free` para exigir motivo (item 2) e checar que o conjunto de irmãos é simétrico no pai (centro do grupo = centro do pai quando o pai declara `center_h`). 1 h.
8. **Estados cobertos**: listar telas só visíveis em certos estados (banners, balão, janelas de prêmio) e falhar o `--estados todos` se alguma cena de `ui/*.gd` instanciada não for visitada. Custo: 2 h; evita o "aprovado porque invisível".

Ordem sugerida: 1 → 2 → 5 → 3 (+4) → 6/8.
