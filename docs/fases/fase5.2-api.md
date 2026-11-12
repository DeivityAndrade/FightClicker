# Fase 5.2: contrato de lógica para a UI

Tudo em `GameState` (autoload). Números sempre de `data/`.

## Luvas L3 e L4
- `lutas.luvas` agora tem 4 níveis (`shop.json -> gloves.levels`). Mesmas regras da 5.1: compra gera caixa (`caixa_criada(item, "glove")`), a próxima luva só fica à venda com a anterior aberta (`luva_em_caixa()`, `pode_comprar_luva()`, `proxima_luva()`). Nada novo no save.
- Textos da caixa: `ui_texts.json -> box_label / box_stamp` com `glove_l3`, `glove_l4`.

## Evento dourado: dois tipos
- Dados (`training.json -> golden_event`): `crew_chance` (padrão 0 = só a luva x7), `crew_seconds` (45), `crew_floor_clicks` (40), `frenzy_sprite`, `crew_sprite`. Lidos em `dados.golden_crew_chance`, `golden_crew_seconds`, `golden_crew_floor_clicks`, `golden_frenzy_sprite`, `golden_crew_sprite`.
- `evento_dourado_tipo: String` = `"frenzy"` | `"crew"`. É sorteado ANTES de o sinal `evento_dourado(duracao)` ser emitido: no handler, leia `GameState.evento_dourado_tipo` e `dados.golden_*_sprite` para escolher o sprite.
- `pegar_evento_dourado() -> bool` (mesmo clique): `frenzy` liga o FRENESI (como antes); `crew` paga a bolsa de uma vez e emite `bolsa_paga(ganho: float)`. Não liga FRENESI e não critica.
- `valor_bolsa() -> float` = `max(crew_seconds x renda_sem_mao(), crew_floor_clicks x por_clique())` (para o hover). O ganho cai no saldo de Treino e no atributo do foco.
- Textos: `golden_crew_name`, `golden_crew_hover` (`{nome}`, `{n}`), `golden_crew_toast` (`{n}`).

## Grito da equipe
- Dados: `lutas.crew_click` = `{id, cost, crew_share, icon, name, description, appears_as}` (`{}` = melhoria inexistente: não mostrar linha).
- Estado: `crew_click_comprado: bool`. `pode_comprar_crew_click()`, `comprar_crew_click()` (gasta $, respeita a reserva da mudança), sinal `crew_click_mudou(comprado)` (compra, carga do save, NOVA CARREIRA não emite: ouça `nova_carreira_iniciada`/`carregado`).
- `por_clique()` = clique antigo + `bonus_crew_click()` (`crew_share x producao_total()`); só a mão. `por_auto_soco()` não muda.
- `texto_efeito_crew_click()` devolve "CLIQUE +N (1 S DA EQUIPE)" com o valor atual.
- `renda_sem_mao()` = `producao_total() + socos_por_segundo_metronomo() x por_auto_soco()`.
- `menor_preco_loja()` inclui o Grito enquanto não comprado.

## Save v8
`career.crew_click: bool` (ausente/inválido = false). Migração `_migrar_7_para_8` acrescenta `crew_click: false`. O evento dourado não é salvo.
