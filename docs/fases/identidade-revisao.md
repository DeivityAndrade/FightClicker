# Identidade visual (ID1 a ID4): revisão final

Diretor de Jogo, 2026-11-25. Base: `identidade-escopo.md`, QA da ID2, ID3 e ID4, achados do verificador, contrato da ID4,
`identidade-direcoes.md`, `tema-c-spec.md` e as pranchas em `docs/arte/mockups/identidade/`. O jogo não foi rodado nesta revisão.

## Veredito: APROVADO COM RESSALVAS
A fase cumpriu o objetivo: o jogo tem cara própria (cartaz de luta), tem porta de entrada e a mecânica não mudou. As ressalvas
não travam a próxima fase e viram tarefas (D1 a D8).

## Critérios de aceite
| # | Critério | Resultado |
|---|---|---|
| 1 | 3 mockups iguais e escolha do dono | OK. A, B e C com as mesmas peças; o dono escolheu C |
| 2 | Sem o marrom-acinzentado | OK. A paleta é fechada (vermelho, azul R, creme, asfalto) e o marrom saiu de todo painel |
| 3 | Contraste de 4,5:1 contra o ponto mais claro | **Parcial.** O gerador mede o contraste por cor; não houve medição por pixel contra o cenário dos 3 locais (D3) |
| 4 | Números lidos em menos de 2 s | OK no olho do QA (ID2) nos 3 locais. Não houve teste cronometrado |
| 5 | Juice do clique igual ou melhor | Sem regressão apontada pelo QA. O dono confirma no teste |
| 6 | Menu | OK nos testes e no jogo real sem save. **Falta o dono testar** NOVO JOGO com save no jogo real |
| 7 | `foto.gd` idêntica | OK (md5 igual ao da main) |
| 8 | Verificador e placar de `ignore` | **Parcial.** As regras funcionam e a cena torta reprova. O placar ficou em cerca de 16 no jogo, mais 3 no menu, contra a meta de 15. Todos têm motivo e nenhum está em botão ou texto fixo |
| 9 | 0 problemas no `ui_audit` | OK. 586 estados do jogo e 16 do menu, inclusive no `--estrito` |
| 10 | Itens tortos que o dono viu | OK. B1 e B2 da ID2 e da ID3 foram corrigidos (commit 81bb12e), e a regra FOLGA_VIZINHO entrou para pegar o mesmo caso no futuro |
| 11 | `run_tests.ps1` verde | OK. 3 rodadas, save real intocado (md5 igual) |

## O que ficou bom
- **A direção C é nossa.** Lambe-lambe, faixa vermelha, carimbo R e asfalto vêm da história, não de moda. A "cara de IA" sumiu.
- **O menu tem tom.** Composição reta, faixa animada e uma parede de cartazes que se enche por marcos (SOCO e ALUGA-SE no começo;
  LIGA, CAMPEÕES e VULTO depois). Conta a jornada sem spoiler. Escala do pé no chão para o absurdo, como pede a visão.
- **O HUD saiu da frente.** Na sala, o lutador aparece e os números (TREINO, $, FAMA) se leem logo.
- **O verificador ficou duro de verdade:** foi de 234 `ignore` sem motivo para cerca de 19, todos com motivo.
- **NOVO JOGO é seguro:** 2 confirmações, cópia com data e hora, `opcoes.cfg` fora do save, e o menu parado não cria save.
- Nada de mecânica mudou, e a foto prova.

## Tarefas futuras
| # | Tarefa | Dono sugerido | Quando |
|---|---|---|---|
| D1 | Trocar os placeholders feitos por código (logo, peças do tema, itens da parede) por arte final desenhada | Diretor de Arte | fase 13 (polimento) |
| D2 | Baixar o placar de `ignore` de cerca de 19 para no máximo 15, com isenções por tipo (hover sem desenho, `ReferenceRect`, peça sem texto dentro de moldura, raiz `Node2D` de mundo) | Programador (regra) + UI/UX (telas) | antes da Ronda 2 ou junto com ela |
| D3 | Medir o contraste por pixel no `ui_audit`: texto do HUD e dos botões contra o ponto mais claro atrás, nos 3 locais, com a sala vazia e cheia | Programador | fase 13 |
| D4 | CONTINUAR fica com destaque fixo (vermelho ou carimbo) mesmo sem foco, porque é o botão principal. O foco continua indicado pelas setas | UI/UX | pequena, na próxima passada de UI |
| D5 | Tela "Enquanto você estava fora…" (§5.11): não existe no código. O gancho depois do CONTINUAR está pronto | Designer + UI/UX | o Produtor encaixa numa fase (sugiro a 13) |
| D6 | Painel F12 de depuração atrás dos cartazes da parede (B3 da ID2). Só aparece em debug; dar `z_index` alto | UI/UX | quando for mexer na sala |
| D7 | Números de dano empilhados sob o "CLINCH!" no MT (B5 da ID3), se ainda aparecer | UI/UX | próxima passada da luta |
| D8 | Topo do mapa escuro: fica como está, por decisão ("mundo noturno"). Revisitar só se o dono pedir | — | — |

## Riscos para frente
- Telas novas da Ronda 2 têm de nascer no tema C e passar no `--estrito`. Placar de `ignore` não pode subir.
- Quando D1 trocar as peças, as larguras podem mudar: rodar o `ui_audit` completo de novo.

## Resumo para o Produtor (repassar ao dono)
- Fase Identidade visual **aprovada com ressalvas**. Direção C aplicada no jogo todo, menu com parede de cartazes por marcos, 0
  problemas no verificador e mecânica idêntica (foto igual).
- Ressalvas: o placar de `ignore` ficou em cerca de 19 (meta 15), o logo e as peças ainda são placeholder feito por código, e o
  contraste não foi medido por pixel. Viraram as tarefas D1 a D3.
- **O que o dono testa:** (1) abrir com o save atual, NOVO JOGO, passar pelas 2 confirmações e conferir o `save_copia_*.json` na
  pasta do save (guarde uma cópia sua antes); (2) OPÇÕES: mexer no volume e na tela cheia, fechar e abrir de novo; (3) clicar no
  saco e ver se o clique tem o mesmo impacto de antes.
- Decisão rápida pedida: o CONTINUAR fica vermelho fixo (recomendo, D4) ou só quando tem foco?
