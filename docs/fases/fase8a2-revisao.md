# Fase 8a2 — Centro de treinamento: revisão do Diretor

Diretor de Jogo, 2026-11-22. Worktree `continue-agents-config-722700` (branch `fase-8a2`), sem commit. Base: `fase8a-escopo.md` (§4,
§6, critérios 11–18 e "Decisões do dono"), `fase8a2-design.md`, `fase8a2-textos.md`, `fase8a2-qa.md`, `docs/arte/fase8a2-manifest.md`
e `fase8a2-personagens-manifest.md`. O dono está fora: as decisões D1–D12 do Designer foram tomadas no lugar dele e estão listadas
abaixo para ele confirmar.

## Veredito
**Aprovada com ressalvas.** Os bugs do QA estão corrigidos, segundo o Produtor:
- **B1** (a fala da 1ª chegada se perdia): corrigido, com teste novo. Era o único que derrubava um critério (12).
- **B2** (teste velho do John): corrigido. Depois disso a suíte inteira passou.
- **B3, B4, B5, B6 e B8:** a pera e o cartaz da academia não se sobrepõem mais, o zoom do cartaz não cobre texto, o "COM" solto sumiu, o
  dado da foto diz "torta", e a tela de fim no centro diz "O CENTRO RAÍZES É A NOSSA CASA".
- **B7** (saco de Muay Thai verde) vai para a rodada de arte. Não bloqueia.

**Antes do merge (pequeno, 2 itens):**
1. **Programador, O1:** a oferta de patrocínio não pode nascer ao **recarregar o save** na própria campanha do 1º Cinturão do Vale. Hoje
   ela não sai na hora e sai depois de recarregar. Regra: só oferecer em campanhas **depois** da `first_regional_belt_campaign`. Mais um
   teste pequeno para isso.
2. **UI/UX + Roteirista, O1:** quando a proposta chegar, mostrar **1 aviso curto** (toast, no padrão do "BEM-VINDO AO CENTRO RAÍZES!"),
   por exemplo "CHEGOU UMA PROPOSTA PARA A RAÍZES". É só tela, não entra na foto e não muda a economia. Passa pelo `alinhamento-ui`.

Depois disso, rodar de novo o `test_fase8a2` e o audit dos estados do envelope. Se o audit de "estados afetados" do B3 não incluiu as
salas da academia com Boxe das fases antigas (6d2, 7b1, 8a1), o Produtor roda só esses estados, e não o audit inteiro.

## O que bate com a visão
- **O cinturão tem prêmio visível.** Vencer o James, MUDAR por $25.000 e entrar numa sala nova e larga, com treino ×4. O prêmio do James
  sempre paga a mudança: ninguém fica com o cinturão e sem ter como ir.
- **Nada muda até o 1º Cinturão do Vale.** A foto é igual à da main (só os 3 nós inertes e o texto do Ventilador no mapa). O motor deu
  37.800 lutas idênticas, e o simulador deu 96 de 96 jogadores iguais (288 de 288 no do Designer). A reserva da LOJA antes do James
  continua 0.
- **A renda cresce de forma visível.** O 1º aluno sai no 1º segundo e dobra a equipe. Aos 10 minutos o Treino/s está ×5 (×11 no
  Jiu-jitsu) e os alunos aparecem na sala (1, 2, 3, 4 pessoas). A aba EQUIPE, que tinha parado, volta a ter sentido.
- **O clique continua mandando.** 1 clique vale de 67% a 123% da renda/s, e a meta é ≥ 25%.
- **Sem tempo morto.** O pior intervalo sem compra nos 10 primeiros minutos é 5:46 (p90 ≤ 4:01). As 5ªs melhorias saem em sequência, e
  não tudo de uma vez.
- **Chegada sem cena, com memória.** Sai 1 fala do Osmar, e a foto torta da garagem fica na parede, ao lado do recorte emoldurado. É o
  tom certo: orgulho pé no chão.
- **O Arco 4 contado pelo cenário.** O cartaz do James ganha o adesivo do R e o recorte ("ESCOLA DE GARAGEM DERRUBA O BLINDADO", com o
  rodapé "Dessa vez acertaram", que responde à errata do Gato Preto). Ninguém perde o controle.
- **Patrocínio pequeno, como o dono pediu.** Dá ~17% a mais de dinheiro, ignorar não custa nada, AGORA NÃO não perde a oferta, e a marca
  é a mesma da faixa do Clube Ferroviário, então o patrocinador "já estava lá".
- **A árvore cresce sem mexer no antigo.** A região CENTRO tem 3 nós que se sentem (clique +50%, +1 dia de preparo, academia +20%), usa só
  tipos de efeito que já existem e fecha 1 campanha depois da 1ª mudança.
- **Save v13**, só com campos opcionais, aguentou 18 casos de save sujo, e a cópia do save do dono abre sem nada novo.
- **Nada adiantado.** Não entrou luta nova no centro, liga nacional, respeito do James nem Ronda Noturna. O texto "SEM LUTA NOVA POR
  ENQUANTO" é honesto com o jogador.

## O1: o envelope só a partir da 2ª campanha com o Cinturão do Vale
- **A regra é boa. Fica.** Ela protege o "nada muda até o cinturão" e conta a história na ordem certa: primeiro o jornal, depois o
  patrocinador. Na campanha do 1º cinturão o patrocínio também não serviria para nada, porque no centro não há luta e não haveria vitória
  para pagar o bônus.
- **O problema é ver.** O envelope tem 16x11 px, fica no chão da sala, aparece no meio da campanha (depois do Tonhão ou do Dinho), não
  vem com fala e cai numa sala cheia de gente. A chance de o jogador nem saber que existe é alta, e aí o "1º uso da fama" some.
- **Correção (antes do merge, itens 1 e 2 acima):** o aviso curto na chegada da proposta e o fim da oferta ao recarregar. Não vira
  janela no meio do jogo: o envelope continua sendo o lugar da decisão.
- **No teste do dono:** a pergunta é se ele percebeu o envelope **sem ninguém avisar**. Se não percebeu nem com o aviso, a próxima
  alavanca é 1 fala do Osmar (o padrão de gatilho já existe), e não mais tela.

## R1: o Legado volta a sobrar depois da região CENTRO
- **Na 8a2 não é problema, e eu não mexo.** Nada quebra, o número continua subindo e a região CENTRO absorveu as campanhas 6 e 7, como
  pedido.
- **Mas é o recado mais importante para a 8b.** Na campanha 8 sobram 7–18 mil, e na 10 sobram 22–42 mil sem destino. Um número que cresce
  sem ter onde gastar vira "acabou o jogo" e não "estou ficando forte".
- **Tarefa para o escopo da 8b (Diretor, quando o dono pedir):** a 1ª coisa que a 8b abre tem que dar destino ao Legado parado (uma região
  nova ligada à liga nacional ou ao complexo de elite), com custo medido para quem chega com ~20–40 mil guardados. Não adiantei nada
  disso aqui.

## A sensação "o jogo virou outro" ao chegar no centro
- **Na economia e no cenário: sim.** O Treino/s salta, a equipe volta a crescer, a sala é nova e larga, e tem gente com a camisa do R. A
  sensação é "a escola cresceu".
- **No loop: não, e é de propósito.** O dono decidiu que o centro fica sem luta nova até a 8b. São 5–8 minutos de compras em sequência, e
  depois a jogada natural é passar o posto. O centro é a **volta da vitória**, não uma fase nova.
- **Onde "virou outro" de verdade:** nas campanhas **seguintes**. Elas ficam mais curtas (região CENTRO), o cartaz da academia mostra que a
  Raízes ganhou, chega o patrocinador, e a marca aparece no calção. É ali que a linhagem sente que subiu de patamar.
- **O que pode enfraquecer:** o fundo e os aparelhos do centro são montagem por código (troca de material sobre a forma da academia). Se o
  dono achar que é "fundo trocado" e não "casa nova", a rodada de arte começa pelo fundo do centro (concreto, luz entrando, vitrine), antes
  dos aparelhos.

## Ressalvas que viram tarefa futura
| # | O quê | Peso | Quem |
|---|---|---|---|
| E1 | O1: a oferta não nasce ao recarregar na campanha do 1º cinturão, com teste | **antes do merge** | Programador |
| E2 | O1: aviso curto quando a proposta chega, com `alinhamento-ui` | **antes do merge** | UI/UX + Roteirista |
| E3 | Save de teste da 8a2 (ver roteiro), estendendo o `tools/teste/criar_save_8a1.gd` | antes do dono testar | Programador |
| E4 | Destino do Legado que sobra depois da região CENTRO | escopo da 8b | Diretor + Designer |
| E5 | B7: saco de Muay Thai do centro em lona crua, como no mockup | rodada de arte | Diretor de Arte |
| E6 | Fundo do centro e aparelhos `_center` à mão (hoje são placeholders por código) | rodada de arte | Diretor de Arte |
| E7 | Marca no calção: a etiqueta de 5x3 só lê no contexto. O Artista não fez o calção próprio | rodada de arte | Artista de Personagens |
| E8 | Alunos: braço da corrida e o R coberto na joelhada | rodada de arte | Artista de Personagens |
| E9 | Pendências da 8a1 ainda abertas: `qa_f8a1_ident.gd` fixo na suíte (E6 de lá), `test_fase6a` sem relógio real (E7 de lá) | pequena | Programador |
| E10 | Ninguém ouviu a fala do Osmar com voz na chegada, nem fez teste humano do patrocínio | dono testa | Produtor |
| E11 | No design, §9 cita "decisão D6" para o save antigo, mas é a D11. Só corrigir o texto | mínima | Designer |

## Decisões D1–D12 para o dono confirmar
Foram tomadas no lugar do dono. Cada uma pode voltar atrás só mexendo em dado, sem refazer a fase.
1. **D1:** tudo o que é do centro fica num arquivo próprio (`center.json`), e os arquivos antigos não mudam.
2. **D2:** a mudança para o centro custa **$25.000**, menos que o prêmio do James, então quem vence o James sempre consegue mudar.
3. **D3:** no centro o treino vale **×4** (o dobro da academia). O Ventilador e o nó novo valem na academia e no centro.
4. **D4:** os "aparelhos novos" são uma versão visual nova mais **1 melhoria a mais (×3)** em cada aparelho, só no centro.
5. **D5:** o patrocinador só aparece para quem **já ganhou um Cinturão do Vale** antes, quando a fama da campanha chega a 200.
6. **D6:** o patrocínio paga **metade da bolsa a mais** em cada vitória, e o envelope **fica na sala** até o fim da campanha (AGORA NÃO não perde).
7. **D7:** nenhum nó da árvore aumenta o patrocínio.
8. **D8:** a região CENTRO da árvore tem **3 nós** (22.000 de Legado no total): clique +50%, +1 dia de preparo e treino fora da garagem +25%.
9. **D9:** na 1ª chegada o Osmar diz uma fala única, e nas chegadas seguintes diz uma de 3 falas curtas, sem cena.
10. **D10:** o recorte de jornal fica **preso no cartaz do James** na academia e **emoldurado** na parede do centro.
11. **D11:** um save antigo parado depois do James com menos de $25.000 não muda nesta campanha. O próximo discípulo chega lá normalmente.
12. **D12:** o texto do Ventilador mudou para **"TREINO FORA DA GARAGEM +25%"** (o Roteirista trocou, porque agora vale no centro também). O efeito não mudou.

Também para confirmar, do Roteirista: o patrocinador se chama **Autopeças Vale Forte** (a mesma marca da faixa da arena regional).

## Como o dono testa a 8a2 (~25 min)
O centro só abre depois do 1º Cinturão do Vale. Para ir direto, peça ao Produtor um **save de teste separado**, como na 8a1. O seu
save fica guardado antes. O Programador estende o `tools/teste/criar_save_8a1.gd` (e o `jogar_teste_8a1.ps1`, ou um `jogar_teste_8a2.ps1`)
com duas opções:
- **`--vale`:** academia, **James já vencido nesta campanha** (CAMPANHA COMPLETA), $30.000 ou mais, a fala do cinturão já vista. Basta
  clicar MUDAR.
- **`--patrocinio`:** a campanha seguinte. A linhagem já tem 1 Cinturão do Vale e já chegou ao centro, tem 22.000 de Legado guardado, e o
  discípulo está na academia **antes do Tonhão**, com a fama perto de 200.

**Com o save `--vale`:**
1. **Cartaz vencido:** na parede da academia, o cartaz do James tem o adesivo do R e o recorte. Passe o mouse (aparece o nome do discípulo)
   e clique para o zoom. Nada pode ficar cortado.
2. **MUDAR:** o cartão mostra $25.000 e "SEM LUTA NOVA POR ENQUANTO". Clique.
3. **Chegada:** não toca cena. O Osmar diz "pendura a foto ali, torta." **Ouça a voz.** Procure a foto torta e o recorte emoldurado.
4. **Sala nova:** compre o 1º aluno e veja o Treino/s pular. Com 5, 12 e 25 alunos aparece mais gente na sala. Abra os aparelhos: cada um tem
   uma 5ª melhoria.
5. **Fique uns 5 minutos.** Sempre teve algo para comprar? Em que momento deu vontade de passar o posto?
6. **Passe o posto.** A tela de fim diz "O CENTRO RAÍZES É A NOSSA CASA". Na árvore aparece a região **CENTRO** com 3 nós.

**Com o save `--patrocinio`:**
7. **Árvore:** compre os 3 nós da região CENTRO (5.000, 7.000 e 10.000).
8. **Proposta:** vença a próxima luta. Aparecem o aviso e o envelope **PROPOSTA** no chão. **Você teria percebido sozinho?** Clique, aperte
   AGORA NÃO e veja que o envelope continua lá. Depois assine.
9. **Bônus:** na próxima vitória, a tela mostra "PATROCÍNIO VALE FORTE: +$...". Repare na etiqueta no calção e, na academia, na marca no
   cartaz.
10. **Volta ao centro (opcional):** chegue ao centro de novo. A fala do Osmar tem que ser outra.
11. **Sensação:** o centro pareceu uma **casa nova** ou um **fundo trocado**? A campanha depois do cinturão pareceu "subimos de patamar"?
12. **Confirme as decisões D1–D12** acima (pode responder só "sim" ou dizer qual muda).

## Resumo para o Produtor
- A 8a2 está **aprovada com ressalvas**. Com B1 a B6 e B8 corrigidos e a suíte verde, ela cumpre os critérios 11–18. O B7 (saco verde) vai
  para a rodada de arte.
- Antes do merge, 2 coisas pequenas: o **Programador** impede que a proposta de patrocínio nasça ao recarregar o save na campanha do 1º
  cinturão, e o **UI/UX com o Roteirista** põe um aviso curto quando a proposta chega. Sem isso, o envelope pequeno no chão passa batido.
- O Legado volta a sobrar depois da região CENTRO. Não é problema agora, mas é a 1ª coisa que o escopo da 8b tem que resolver.
- O centro é a "volta da vitória", e não um jogo novo. A sensação de "subimos de patamar" vem nas campanhas seguintes (árvore, cartaz,
  patrocínio). O dono confirma as 12 decisões e testa com 2 saves novos (`--vale` e `--patrocinio`).
