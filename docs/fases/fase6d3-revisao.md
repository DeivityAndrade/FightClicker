# Fase 6d3: revisão do Diretor de Jogo

Diretor de Jogo, 2026-11-19. Branch `fase-6d`, sem commit. Base: `docs/fases/fase6d3-qa.md`, `docs/arte/fase6d3-varredura.md`,
capturas `docs/arte/mockups/fase6d3_*.png` e as correções informadas pelo Produtor depois do QA (B1 a B5).

## Veredito
**APROVADO, com uma condição antes do commit:** rodar de novo os estados `f6d2_garagem_pequena`, `f6d2_garagem_cheia`,
`f6c2_mural_garagem`, `f6a_vitoria_selo` e a cena da primeira sucessão (`qa_f6d_cenas.gd p=2,3`) e confirmar 0 problemas.
O QA reprovou por B1 e B2; as correções vieram depois do relatório e ainda não passaram por uma rodada do verificador.

## Pedido do dono x resultado
| Pedido | Situação |
|---|---|
| Números com o nome inteiro do atributo | Feito. 804 números testados, nenhum com sigla, todos dentro da sala |
| Painel da direita só fecha quando o jogador manda (sem FIXAR) | Feito. Clique na sala não fecha; L/E/aba fecham. Chaves mortas removidas (B3) |
| Lutador piscando na luta | Feito. 0 quadros com a folha padrão em luta ganha e perdida |
| Garagem: carro com lona, pneus, geladeira, sem escada nem ralo | Feito. B1 (gente na frente do carro) corrigido: carro em x 69..194, Osmar 52,258, mentor sentado 210,254, 2º mentor 26,304. Na captura nova ninguém cobre o carro |
| Varredura do que destoa | Feita, com lista clara do que entrou, do que é de tela e do que ficou para depois |
| Símbolo novo "R de raiz" (opção D) em todo lugar | Feito em peito, coxa, luta, retrato, mural, caixas, parede, selo. B2 (ícone GARAGEM SALVA e Honra) corrigido |
| Botão SEGURAR na faixa de baixo | Feito, sem bater no "?" nem no LUTAR!. B4 (SALVO por cima e 1 px de altura) corrigido |

## O que ficou bom
- A garagem finalmente lê como garagem: o carro é um carro, os pneus têm volume, a geladeira tem vida. Pé no chão, como pede o começo do jogo.
- O R de raiz é simples, lê em 5 px e em 32 px, e amarra a escola em todos os lugares. Identidade original.
- O número com o nome inteiro deixa o clique mais claro sem perder o impacto (crítico em 2x com "!").
- Painel com o jogador no controle: menos surpresa, nenhuma mecânica escondida.
- Nada da 7a foi adiantado: nenhum minigame, nenhuma tela nova, nenhum sistema novo em `scripts/`, `ui/`, `data/`. A foto de balanço é idêntica à da main.

## O que desvia (pequeno) ou fica pendente
- **Cor da escola:** R amarelo na camiseta do mural e R azul na parede/selos/caixas. Pergunta para o dono (abaixo). Não bloqueia.
- **B6 (higiene):** testes regravam ~40 PNG versionados em `docs/arte/mockups/`. Antes do commit, o Produtor decide: não commitar
  esses PNG regravados (restaurar) ou mudar os testes para gravar em pasta temporária. Recomendo a segunda, numa rodada curta.
- **Tecla SHIFT solta no chão** (varredura, prio 1 para UI/UX): não está entre os pedidos do dono desta rodada; se ainda aparece, corrigir
  junto com a próxima mexida de tela, não agora.
- Ficam para depois, como a varredura anotou: público da luta, arco do refletor, textura do mapa, corda que parece espelho, barrado da academia.
  Nenhum é pedido do dono; não abrir rodada só para isso.
- O R, o carro e os pneus são placeholder por código; versão final é de artista humano.

## Riscos
- Painel aberto como padrão cobre a faixa direita da sala; o painel agora desce até a faixa de baixo (B5), mas figurantes passam por trás.
  Foi pedido do dono; vale ele sentir na mão.
- O rótulo SALVO e o SEGURAR dividem a mesma região; a correção não foi vista na tela pelo QA (o SALVO é rápido de aparecer).

## Pergunta para o dono
1. Cor da escola: o R fica **azul** em tudo (parede, selo, caixas, camiseta) ou a camiseta continua **amarela**?

## O que o dono deve testar com as próprias mãos (cerca de 10 min)
1. Jogo novo: olhar a garagem. Ninguém na frente do carro; carro com lona atrás; pneus e geladeira novos; sem escada, sem ralo.
2. Clicar no saco, na pera e na esteira: os números dizem FORÇA / AGILIDADE / RESISTÊNCIA por inteiro; o crítico vem maior com "!".
3. Apertar L: a loja abre. Clicar na sala várias vezes: continua aberta. E troca para equipe; E de novo fecha. H esconde tudo menos a sala.
4. Segurar o botão SEGURAR na faixa de baixo: o treino assistido liga enquanto segura e para ao soltar. Esperar um autosave ("SALVO") e ver se não cobre o botão.
5. Ir para uma luta e olhar o lutador: não pode piscar com outra roupa/cabelo em nenhum golpe, nem ganhando nem perdendo.
6. Procurar o símbolo antigo (lâmpada): peito do lutador, caixas, parede da garagem salva, janela de vitória com o 1º cinturão
   (ícone ao lado de GARAGEM SALVA), mural e Honra. Só pode aparecer o R.
7. Fazer a primeira sucessão: o John sai e o novo discípulo entra sem ninguém atravessar o carro.

## Resumo para o Produtor repassar ao dono
- Rodada 6d3 aprovada: tudo o que você pediu depois de jogar a 6d está feito (nomes inteiros, painel sob seu controle, sem piscar, garagem nova, R de raiz em todo lugar, SEGURAR embaixo).
- Os dois bugs médios do QA (gente na frente do carro e ícone antigo) foram corrigidos; falta só uma rodada rápida do verificador antes do commit.
- Nada da 7a foi adiantado.
- Uma decisão sua: a cor da escola, R azul em tudo ou camiseta amarela.
- Teste em ~10 min seguindo a lista "O que o dono deve testar" acima.
