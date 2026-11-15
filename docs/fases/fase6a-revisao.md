# Fase 6a — Prólogo e voz: revisão do Diretor

Dono: Diretor de Jogo. Data: 2026-11-14. Branch `fase-6a`.
Li: `fase6a-escopo.md` (com as "Escolhas do dono (2026-11-13)"), `fase6a-design.md`, `fase6a-textos.md`, `fase6a-api.md`, `fase6a-qa.md`, `docs/direcao-narrativa.md` (prevalece), `docs/cutscenes/` (`primeira-sucessao.md` já usa John, Osmar e a ficha) e os testes B1–B3 em `tests/test_fase6a.gd`. Capturas conferidas: `f6a_abertura_b1`, `f6a_abertura_b2`, `f6a_john_esteira`, `f6a_gym_osmar`, `f6a_vitoria_selo`, `f6a_parede_depois`, `f6a_hover_ficha_depois` e `f6a_gesto_luta`.
Depois do QA, o Produtor corrigiu os bugs B1 a B4:
- **B1:** o Osmar só fala na garagem. A `cl_primeira_academia` fica guardada para a 6c, e uma abertura que começa na academia espera a volta à garagem.
- **B2:** a 1ª derrota é rearmada quando o save carrega.
- **B3:** `lines_seen` só é gravado quando a interface aceita o balão.
- **B4:** o balão do John segue a cabeça dele na esteira.

O `run_tests` passa e o `ui_audit` dá 216 estados com 0 problemas.

## 1. Veredito
**Aprovado.** A fase está pronta para o dono testar.
- Os 11 critérios de aceite passam, com 2 que dependem do dono: o **4** (reconhecer as vozes de olhos fechados) e o **7** (número de comentários na Carreira 1).
- Os 4 bugs do QA foram corrigidos, e o B1, o B2 e o B3 ganharam teste automático (`test_fase6a.gd`, seções "B1"/"B2" e `fala_recusada`).
- O balanço continua idêntico ao da 5.4: o QA rodou a mesma simulação nas duas versões e a saída foi igual. A história não somou nenhum segundo à luta.

## 2. A visão foi entregue?
| Pedido (escopo / direção narrativa) | Entregue? | Como |
|---|---|---|
| História que acompanha o treino sem atrasar | **Sim** | A sala nunca sai da tela, o saco vale no 1º quadro, o balão é passivo e não recebe clique, e a abertura dura 13,9 s (o teto era 20) |
| Abertura com 3 ideias: dificuldade, sonho e humilhação | **Sim** | "chegou outro aviso, john." / "ainda formo campeão aqui." / "o muralha riu da ficha: escola: nenhuma.", com o aviso e a ficha na parede |
| John Bullet com nome, rosto e gesto | **Sim** | O gesto "fecho e dois toques" aparece na abertura, na luta, na vitória, ao calçar luva e com a sala parada, e qualquer clique cancela. Os discípulos da Carreira 2 em diante não fazem o gesto |
| Osmar Brandão comentando de vez em quando | **Sim, só na garagem** | Mínimo de 60 s entre falas, falas únicas ou com descanso, nada na luta, com janela aberta ou no dia de luta |
| Arco 1 contado pela parede | **Sim** | Aviso, foto antiga, recorte e ficha. Na garagem salva, o aviso sai, entram a foto da equipe e a lâmpada pintada, e a ficha vira "ESCOLA: RAÍZES FIGHT CLUB" (`f6a_hover_ficha_depois`) |
| Conquista da escola, e não só do John | **Sim** | A garagem é salva no 1º cinturão amador de qualquer discípulo (`by_first`). O selo aparece na tela do cinturão (`f6a_vitoria_selo`) |
| Nada se repete depois do reset | **Sim** | `school.milestones` fica fora do reset, e a abertura e o aviso nunca voltam (critério 8) |
| Save antigo do dono | **Sim** | Testado em cópia: a campanha atual vira a do John, o Legado, a árvore e o calendário ficam iguais, e o próximo cinturão salva a garagem |

### O que ficou bom
- **A abertura é a própria sala.** O dono vê o Osmar, o aviso e a ficha sem largar o saco. É exatamente a regra da direção: comunicar rápido e deixar treinar.
- **A ficha amassada é o melhor achado da fase.** É um objeto só que conta a humilhação, vira prova da conquista e fica na parede para sempre. Ela é original e sincera, e não humilha o jogador.
- **O tom está certo.** As falas são minúsculas, curtas e pé no chão ("o bairro viu. uns quinze."), e o selo diz "o lugar continua nosso".
- **A parede depois da garagem salva é visivelmente outra** (`f6a_parede_depois`). A lâmpada pintada grande ficou melhor que os 5x5 px que eu tinha proposto.
- **As correções do QA protegem as falas únicas.** Uma fala única não se perde mais por janela recusada, por fechar o jogo ou por estar na academia.

### Pontos de atenção (não bloqueiam)
- **O Osmar fica calado fora da garagem.** Com o B1, ele só fala na garagem. A minha recomendação era falar nos dois lugares, mas mudo de posição: na 6a ele não aparece na academia, e um balão sem personagem é pior que o silêncio. A presença dele na academia fica para a 6c, junto com a `cl_primeira_academia`.
- **O critério 7 pode ficar abaixo do mínimo.** A simulação deu 4 comentários e o mínimo era 5. O `fight_won` só fala em revanche ou recorde, e agora o Osmar também não fala na academia. Aceito como está, porque a frequência é uma das validações do dono (pergunta 3). Se ele achar pouco, o ajuste é **só de dados**: uma variante comum de vitória, com descanso.
- **O estado `f6a_gym_osmar` do audit ficou velho.** Ele ainda força um balão do Osmar na academia, que aponta para a parede vazia (captura atual). O audit não acusa nada, mas a captura mostra algo que o jogo não faz mais.
  - **Condição para o merge:** trocar esse estado por "academia sem balão do Osmar", ou removê-lo.
- **O chip de pular mostra "ESC esc: pular"**, repetindo a tecla. É detalhe de polimento. Se o UI/UX mexer no chip na 6b, corrige ali.

## 3. Algo passou do escopo?
**Não.**
- O modo de cena do balão ficou pronto, mas sem uso, como pedia o escopo.
- A paleta do discípulo padrão é só uma troca de cor, sem tela nova.
- O símbolo aparece só na parede.
- Nenhum preço, luta ou data mudou.

## 4. Pendências
| Pendência | Decisão |
|---|---|
| `descricao_luva_inicial()` não aparece na UI | **Aceita para a 6b.** A promessa "o par dele" chega hoje pela fala `cl_luva_par`, e a descrição só faz sentido junto com o gesto de passar a luva, que é da 6b |
| A versão larga do selo (`seal_garage_saved_text`) não foi usada | **Aceita.** O selo curto lê bem na captura. O texto continua nos dados para a fase 13 |
| `fight_won` só fala em revanche ou recorde | **Aceita.** O dono julga a frequência (ver §2) |
| O timbre das vozes | **É do dono.** Não há como validar sem ouvir |
| A prancha de quadros-chave para a 6b não foi feita | **Não bloqueia o teste da 6a, mas trava a 6b.** O escopo diz que o dono aprova a prancha antes da 6b. O Diretor de Cutscenes e o Diretor de Arte entregam a prancha (sucessão e reencontro) **antes** de o escopo da 6b ser mostrado ao dono |
| `cl_luva_par` toca também na Carreira 2 em diante | **Aceita.** A fala faz sentido para qualquer discípulo que recebe a luva velha do John |

## 5. O que fica para as próximas fases
| Item | Fase |
|---|---|
| Prancha de quadros-chave (sucessão e reencontro), aprovada pelo dono | **antes do escopo da 6b** |
| Descrição "o par do John" no cartão da luva e o gesto de tirar a luva e passar | **6b** |
| Player de cena, cena "Primeira sucessão", John como mentor na garagem, personalização e porta de enrolar | **6b** |
| Variante comum de `fight_won` e opção de desligar blips (sobe da 13) | **6b**, só se o dono pedir |
| Chip "ESC esc: pular" | **6b**, se mexerem no chip, ou **13** |
| Osmar na academia e `cl_primeira_academia` | **6c** |
| Selo largo e revisão do som do selo | **13** |

## 6. Roteiro de teste do dono (cerca de 10 min)
Use o save de sempre. Ele vira a campanha do John.

1. **Abertura (30 s).** Abra o jogo e comece a socar o saco na hora.
   - Valide: o soco vale desde o começo? Os balões do Osmar e do John dão para ler sem parar de clicar? Dá para entender "garagem em apuro, sonho do Osmar, ficha em branco"?
2. **Vozes (1 min).** Preste atenção no som das letras.
   - Valide: o John e o Osmar soam diferentes? O blip incomoda no meio dos socos?
3. **Parede (30 s).** Passe o mouse no aviso e na ficha amassada.
4. **Gesto (2 min).** Marque uma luta. Na entrada, o John puxa o fecho da luva com os dentes e dá dois toques. Depois, clique durante o gesto.
   - Valide: dá para ver o gesto? O som "rrrip" marca? O clique corta o gesto na hora?
5. **Sala parada (1 min).** Fique 20 s sem clicar.
   - Valide: o gesto curto aparece. Isso cansa?
6. **Osmar (o resto da campanha).** Jogue normalmente: compre, abra a caixa, ganhe e perca.
   - Valide: ele fala pouco, na medida ou demais?
7. **Garagem salva (quando ganhar o cinturão amador).** Veja o selo na tela do cinturão. Na próxima vez que estiver na garagem, olhe a parede.
   - Valide: o aviso sumiu, apareceram a foto da equipe e a lâmpada pintada, e a ficha diz "ESCOLA: RAÍZES FIGHT CLUB"? O Osmar comenta uma vez?
8. **Carreira 2.** Comece uma campanha nova.
   - Valide: o discípulo novo (com outra cor de cabelo e calção) serve até a personalização chegar na 6b?

## 7. Perguntas para o dono
1. **A abertura** passa a ideia (garagem em apuro, sonho do treinador, a ficha "escola: nenhuma") sem tirar a vontade de clicar?
2. **As vozes:** você reconhece o John e o Osmar só pelo som? O blip incomoda? Se incomodar, a opção de desligar sobe para a 6b.
3. **O Osmar fala pouco, na medida ou demais?** Hoje ele só fala na garagem.
4. **O gesto do fecho e dois toques** é marcante ou cansa? Se cansar, a primeira coisa que sai é o gesto com a sala parada.
5. **A garagem salva:** o selo e a parede mudada emocionam o suficiente? A lâmpada pintada serve como símbolo da escola?
6. **O discípulo com outra cor** serve até a 6b?
7. **Seu save** virar a campanha do John funcionou para você?

## Resumo para o Produtor
- **Aprovado para o dono testar.** A 6a dá voz à garagem sem atrasar o treino: abertura de 14 s na própria sala, a ficha "escola: nenhuma", John com o gesto, Osmar comentando só na garagem e a parede mudando quando a garagem é salva. O balanço é idêntico ao da 5.4.
- B1 a B4 foram corrigidos, e o B1 a B3 têm teste. **Condição para o merge:** trocar ou remover o estado `f6a_gym_osmar` do audit, que ainda mostra um balão que o jogo não faz mais.
- O dono valida as vozes, a frequência do Osmar, o gesto, o momento da garagem salva e o discípulo com outra cor (7 perguntas, cerca de 10 min).
- Ficam para a 6b: a prancha de quadros-chave (precisa estar aprovada **antes** do escopo da 6b), a descrição "o par do John" na luva e, se o dono pedir, mais falas de vitória e a opção de desligar o blip.
