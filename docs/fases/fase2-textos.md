# Fase 2 — Textos da garagem

Dono: Roteirista. Versão 1 (2026-11-05). Só texto: números ficam com o Designer.
Ids em inglês são **propostas**; se o Designer já usou outro, vale o dele e o texto acompanha.
Limites: nome até ~16 caracteres (fonte 5x7 em maiúsculas, painel de 128 px), descrição até ~44 caracteres.
Acentos mantidos (a fonte tem Ç Ã Á Â É Ê Í Ó Ô Õ Ú). Na tela tudo sai em maiúsculas; aqui está em caixa normal para leitura.

## Local

| id | Nome | Ambientação (1 frase) |
|---|---|---|
| `garage` | Fundo de garagem | Uma lâmpada, um carro coberto de lona e um saco que já apanhou mais que você. |

Dica de primeira vez (rodapé, some depois do 1º clique): **Clique no saco para treinar**
Dica alternativa, se o rodapé ficar sem função depois: **Clique no saco. Ele aguenta.**

## Os 3 aparelhos

### Saco de pancada (`punching_bag`) — Força, vermelho

| Campo | Texto |
|---|---|
| Nome do aparelho | Saco remendado |
| Botão de foco (linha 1 / 2) | FORÇA / SACO |
| Verbo do número flutuante | `+12 FORÇA` |
| Dica do atributo (1 linha) | Força: quanto dói o seu soco. |
| Dica de primeira vez | Clique no saco para treinar |

Críticos (`crit_texts.strength`, sortear):
1. NA MOSCA!
2. PEGOU DE JEITO!
3. ESSE DEIXOU MARCA!
4. A VIGA TREMEU!
5. DESSA ELE LEMBRA!

### Corda de pular (`jump_rope`) — Agilidade, azul

| Campo | Texto |
|---|---|
| Nome do aparelho | Corda de varal |
| Botão de foco | AGILIDADE / CORDA |
| Verbo do número flutuante | `+12 AGILIDADE` |
| Dica do atributo | Agilidade: golpe certeiro e corpo que sai da frente. |
| Dica de primeira vez | Clique na corda para pular |

Críticos (`crit_texts.agility`):
1. SEM TROPEÇAR!
2. PULO DUPLO!
3. LEVE COMO PENA!
4. NEM TOCOU O CHÃO!
5. ESSA FOI LIMPA!

### Esteira (`treadmill`) — Resistência, amarelo

| Campo | Texto |
|---|---|
| Nome do aparelho | Esteira enferrujada |
| Botão de foco | RESISTÊNCIA / ESTEIRA |
| Verbo do número flutuante | `+12 RESISTÊNCIA` |
| Dica do atributo | Resistência: quanto você aguenta apanhar. |
| Dica de primeira vez | Clique na esteira para correr |

Críticos (`crit_texts.endurance`):
1. SEGUROU A ONDA!
2. SEGUNDO FÔLEGO!
3. AINDA TEM GÁS!
4. A ESTEIRA GEMEU!
5. NEM SUOU!

Observação para o Programador: o número flutuante usa o formato `+N ATRIBUTO`, o crítico troca por `+N ATRIBUTO` em 2x mais o texto de crítico em linha acima, sempre com "!" (os textos acima já trazem).

## Geradores — gente do bairro

| id | Nome | Descrição (1 linha) | Aparece na sala como |
|---|---|---|---|
| `neighbor_kid` | Vizinho da casa 12 | Veio "só olhar". Está no terceiro round. | Rapaz de chinelo, no aparelho lateral |
| `retired_uncle` | Tio aposentado | Treina de camisa social. Sabe de tudo, ajuda em nada. | Senhor de calça de tergal e luva velha |

Alternativas se o Designer quiser mais de dois nomes depois: Entregador da padaria, Dona do mercadinho, Primo do cunhado.
Ordem: o vizinho é o primeiro (barato), o tio é o segundo (5 a 8 min).
Tom: eles não cobram. Nada de "contratar"; o botão de compra pode dizer **Chamar** (futuro: **Contratar** só com dinheiro na Fase 3).
Texto do botão de compra: **CHAMAR**

## Melhorias de aparelho (6 itens)

Nível 1 troca o sprite (gambiarra). Nível 2 é um pouco melhor, sem prometer luxo.

| id | Nível | Nome | Descrição (1 linha) |
|---|---|---|---|
| `bag_patch` | 1 | Fita nova no saco | Mais fita, menos areia no chão. |
| `bag_sand` | 2 | Areia peneirada | Soco que volta com juros. |
| `rope_laundry` | 1 | Corda sem nó | Agora só prende duas vezes por minuto. |
| `rope_handles` | 2 | Cabos de cabo de vassoura | Pega firme. Serragem inclusa. |
| `treadmill_oil` | 1 | Óleo de cozinha na esteira | Range menos. Cheira a batata frita. |
| `treadmill_belt` | 2 | Correia emendada | Dá voltas inteiras sem pular. |

Nome do atributo do efeito na tela fica com a UI (ex.: "+25% FORÇA no saco").

## Nome dos painéis e rótulos curtos (sugestão)

| id | Texto |
|---|---|
| `hud_training` | TREINO |
| `panel_team` | EQUIPE |
| `panel_upgrades` | MELHORIAS |
| `per_click` | POR CLIQUE |
| `auto` | AUTO |
| `focus_label` | FOCO DE TREINO |
| `can_afford_hint` | Falta treino |

## Rótulos da UI v2 (ui_texts.json)

- `upgrade_effect`: "x{mult} POR CLIQUE: {alvo}" (neutro para saco, corda e esteira; antes gerava "NO CORDA").
- Novas chaves: `panel_attributes` ATRIBUTOS; `upgrade_button` MELHORAR; `saved_footer` SALVO {hora}; `fullscreen_hint` F11 TELA CHEIA.
- Depuração F12: `debug_add_currency` SALDO x1000; `debug_add_generators` +10 DE CADA GERADOR; `debug_save` SALVAR; `debug_reload` RECARREGAR; `debug_wipe_save` APAGAR SAVE; `debug_confirm` CONFIRMAR.

## Falas reservadas (NÃO entram na Fase 2)

Marcadas como **reservadas**. Mentor e rival só aparecem na Fase 8; ficam aqui só para guardar o tom.

- `mentor_garage_intro` (reservada): "Esse saco já me aguentou muito. Agora é teu."
- `mentor_first_gen` (reservada): "Não é academia. Mas já tem gente."
- `rival_garage_cameo` (reservada): "Ainda batendo em saco de areia? Fofo."

## Checagem de escopo

Sem dinheiro, luta, fama, Legado, aposentadoria, mentor ou rival na tela. As falas acima não são carregadas.
