# Fase 6d3: propostas de símbolo da escola Raízes Fight Club (só mockup)

Pedido do dono: trocar a lâmpada com raízes por algo que junte raiz e luta. Nada foi aplicado nos assets.
Prancha: `mockups/fase6d3_simbolo_opcoes.png`, gerada por `tools/art/make_mockup_fase6d3_simbolo.gd`.

Cada proposta foi desenhada à mão em 3 tamanhos (nenhum é redução do outro):
- 16x16: UI, e base da parede em 2x;
- 9x9: selo do mural e carimbos;
- 5x5: estampa no peito do discípulo.

A prancha mostra, para cada uma: o símbolo ampliado x8, a parede da garagem salva (32x40 em 344,38, tamanho real x3), a regata
branca com estampa azul e a camiseta preta com estampa amarela (tamanho real e x4), e o selo do mural (20x24, real e x4).
Regra do §29.1: uma cor de tinta mais o creme. No peito o creme vira vazio (aparece o pano).

| | Nome | Ideia | Como ficou |
|---|---|---|---|
| **A** | Punho-raiz | Soco de lado: punho fechado (dedos marcados em creme), antebraço deitado e raízes caindo dele. "A força vem de baixo." | Lê como soco no 16 e na parede. No 5x5 vira um bloco com dois pés: dá para ler sabendo o que é. |
| **B** | Luva na raiz | Uma luva pendurada pelo cadarço numa raiz grossa, como as luvas do John no gancho da garagem. | A ideia é a mais nossa (é a cena da garagem), mas por código a luva pendurada lê como bomba ou bicho. Precisaria de artista. |
| **C** | Brasão da raiz | Escudo com um broto em cima da linha do chão e as raízes grandes embaixo. "A escola é o que não se vê." | Forte na parede e no selo. No 5x5 vira um escudo com um risco, o que é bom como marca. No 16, broto e raízes juntos podem ler como máscara. |
| **D** | R de raiz | Um "R" de traço grosso cujas pernas viram raízes. | É a mais legível em todos os tamanhos: o R aparece até no 5x5 do peito e no selo. Liga direto com o nome. Ficou com menos "luta" que as outras. |
| **E** | Selo do toco | Selo redondo com um toco cortado (anéis à mostra) e raízes fortes até a borda. | Fica bem como carimbo grande, mas no 9 e no 5 lê como sino ou fantasminha. |

## Recomendação
**D (R de raiz)** como símbolo da escola: é a única que sobrevive no 5x5 do peito, que é onde o jogador mais vê a marca.
Ela também faz par com o nome, e na parede lê como letreiro pintado.
Se o dono quiser mais "luta" no desenho, a minha 2ª opção é **A (punho-raiz)**. Dá para usar as duas juntas: o D no peito e no
selo, e o A grande na parede e na tela do mural.

## Limites (placeholder)
Os desenhos são pixel a pixel por código. Um pixel artist faria a versão final da escolhida: curvas das raízes, o peso do punho
ou do R e um 5x5 ainda mais limpo. Os nomes e tamanhos dos arquivos ficam os mesmos (`school_symbol_5/9/16/32`,
`wall_school_symbol`, a camada `school_symbol` do discípulo, `ui_mural_seal`), então trocar é só gerar os arquivos de novo.
