# Fase 6d3: varredura de arte (Diretor de Arte)

Pedido do dono: "veja o que destoa nas telas em geral e melhore". Olhei as 383 capturas do verificador
(`tools/ui/ui_audit.gd -- --estados todos`, 1280x720, APPDATA temporário): garagem e academia (vazia, pequena, cheia), luta,
criação do discípulo, mapa, mural/hall, cenas, fim e vitória.

Pranchas: `mockups/fase6d3_varredura_antes_depois.png` (telas inteiras) e `mockups/fase6d3_varredura_detalhes.png` (recortes);
garagem: `mockups/fase6d3_garagem_antes_depois.png`.

## Corrigido nesta rodada (arte)
| Prio | Tela | O que destoava | O que ficou | Arquivo / gerador |
|---|---|---|---|---|
| 1 | Garagem | Carrinho de 96x50 que não lia como carro | Sedã velho de lado, 126x58, rodas, vidros, faróis, lanterna; com a lona cinza-azulada da 6d2 na metade de trás (pedido do dono; as lonas marrom/verde não funcionaram) | `garage_bg` / `make_mockup_fase6d2_layout.gd` |
| 1 | Garagem | "Retângulo preto" no chão (era o ralo) | Tirado | idem |
| 1 | Garagem (salva) | Mancha amarela com raízes no alto da parede: era o **símbolo da escola** pintado, em amarelo vivo, lendo como borrão aceso | Emblema a estêncil na tinta azul da escola, lâmpada creme dentro do disco, raízes para fora | `garage/wall_school_symbol` / `make_arte_fase6d3.gd` |
| 1 | Garagem | Lâmpada com anel de pontinhos laranja (faísca/borrão) | Lâmpada no fio, sem anel; o brilho fica na luz do fundo | `garage/lamp` (3 quadros iguais em tamanho/pivô) / `make_arte_fase6d3.gd` |
| 2 | Garagem | Escada torta na parede direita | Tirada | `garage_bg` |
| 2 | Garagem | Pneus = elipses pretas | Pilha com banda, sulcos, brilho e furo + um em pé com roda | `garage_bg` |
| 2 | Garagem | Geladeira chapada | Lado/tampo, cromados, bilhete, foto, ímãs, rádio | `garage_bg` |
| 2 | Garagem | Mancha de óleo com miolo chapado (lia como buraco) e círculo de giz solto | Óleo só em dither, mais claro; círculo e risco claro tirados | `garage_bg` |
| 2 | Garagem | Bancada inteira atrás do carro (ruído) | Tirada; a chapa de ferramentas ficou | `garage_bg` |
| 2 | Luta | 18 manchas redondas marrons na chapa (borrões) | Ferrugem escorrendo pelos vales da chapa e no pé | `fight/arena_bg` / `make_arte_fase6d3.gd` (cópia fiel do `make_arena` da Fase 3, conferida: 0 px diferentes) |
| 2 | Luta | "07" da porta com dither por cima (lia "0T") | "07" limpo, pintado | idem |
| 2 | Luta | Anéis tracejados laranja em volta das 2 lâmpadas pequenas | Brilho discreto em dither | idem |
| 2 | Academia | Nome pintado com pixels faltando: "BOA" lia "BOR" | Nome inteiro, descascado só na borda das letras | `gym_bg` / `gym_fix_6d3` |
| 2 | Academia | Espelho com estrela de trincas, anel e fita em X (lia como teia/vidro estourado, roubava o olho do saco) | Espelho limpo com reflexo e uma trinca curta no canto, com fita | idem (`gym_half_dark` refeito junto) |

Nenhum ponto do manifest mudou, ninguém foi movido e nenhum tamanho, pivô ou quadro mudou. Notas no manifest:
`python tools/art/manifest_6d3.py`.

## Para o Designer UI/UX (é de tela; não mexi)
| Prio | Tela | O que destoa | Sugestão |
|---|---|---|---|
| 1 | Garagem / academia | Uma **tecla SHIFT** solta no chão da sala, à esquerda (x ~146..166, y ~274..289 na base 640x360), sem texto: o `_chip_icone` do `ui/faixa_assistido.gd` (`icon_key_shift`). Lê como "caixa de metal no chão" | Prender o chip à faixa de foco/HUD ou mostrar só com o texto do modo assistido; nunca solto sobre o chão |
| 2 | Garagem / academia | Botão "?" pequeno ao lado do LUTAR!, sem moldura igual à dos outros botões | Mesma moldura/chanfro dos botões da faixa, ou ícone dentro do LUTAR |
| 3 | Fim de campanha | Botões da fileira de baixo com pesos diferentes (NOVO DISCÍPULO em fonte 2x, ÁRVORE/MURAL em 1x) e ícones de tamanhos diferentes | Hierarquia é intencional; só alinhar o tamanho dos ícones (16 px) |
| 3 | Criação do discípulo | O boneco de prévia é 1x dentro de uma moldura grande (fica pequeno e solto) | Mostrar a prévia em 2x (nearest), como o retrato do mural |

## Ficou de fora (anotado, não corrigido agora)
| Prio | Tela | O que destoa | Por que não agora / quem |
|---|---|---|---|
| 2 | Luta | Público = blocos retangulares chapados com luzinhas; é a parte mais "placeholder" da tela | Pede folha de público nova (silhuetas com cabeça/ombro, 2-3 alturas) — Artista de Personagens |
| 3 | Luta | Arco tracejado laranja embaixo do refletor (`arena_lamp`), mesmo vício dos anéis que saíram | Peça animada (3 quadros); trocar junto com o público |
| 3 | Mapa | Regiões de terra marrom com textura de ruído forte; ao lado dos nós limpos lê como borrão | Mexer na textura das regiões do §21 (material por região); fica para uma rodada do mapa |
| 3 | Academia | Faixa de "tinta descascada" no topo do barrado verde = fileira de retângulos claros que parece dente | Pequeno; refazer junto com a próxima mexida no `gym_bg` |
| 3 | Garagem | Corda enrolada no gancho lê como espelho oval pendurado | Sprite de aparelho (`rope_l0_idle`); redesenhar com voltas visíveis numa rodada de aparelhos |
| 3 | Mural | Estampa da escola na camiseta em amarelo e o símbolo na parede/carimbos em azul | Decidir uma cor da escola com o Diretor de Jogo; hoje as duas convivem |

## Precisa de artista humano (versão final)
Carro (volume dos para-lamas, reflexo na lataria, uma lona com peso de verdade), pneus (sulcos à mão), símbolo da escola (traço de
pincel e estêncil reais), público da luta, texturas do mapa.
