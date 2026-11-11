# Fase 5 — Academia de bairro e artes marciais: revisão

Dono: Diretor de Jogo. Data: 2026-11-11.
Base: branch `integra/fase5-ui` (Fase 5 + PRs 1 e 2 do Matheus), `fase5-escopo.md` (com respostas do dono, decisões e "Rebalanceamento pós-PRs"), `fase5-design.md` (R8 vale sobre R3–R5), `fase5-qa.md` (refeito em 11/11), `docs/propostas/feedback-2026-11-11.md`. Conferi no código: `golden_event` e `special_hits` lidos de `data/`, `_fechar_vitoria` idempotente, `tip_move_belt` só para quem aposentou com o cinturão ainda na garagem.

## Veredito
**Aprovado com 3 condições** (todas pequenas, antes de mostrar ao dono):
1. `tools/run_tests.ps1` passa inteiro com os valores novos (o Programador está atualizando os testes).
2. Os valores padrão da luva no código (`scripts/training_data.gd`, `PADRAO_EVENTO`) passam a ser os de `data/`: ×7, 6 s, espera 60–100 s, 7 s na sala. Hoje são os do PR (45–90 s, 12 s): se o bloco sumir do JSON, o jogo volta em silêncio para a luva que quebra o 23b. Pedido do Designer em R8 que ainda não está no código.
3. QA curto de regressão sobre N1 a N5, com o `ui_audit` em **0 problemas** (N3 e N5 mexeram em tela). Não precisa refazer o QA inteiro.

## O que ficou bom
- **A fase entrega a visão:** o cinturão virou porta de saída da garagem, a academia é um degrau novo e a escolha da arte no começo da carreira dá o "desta vez vou de Jiu-jitsu". Boxe = mão, Jiu-jitsu = equipe; a diferença se sente sem ler número.
- **Estabilidade:** QA com 98 estados de tela e 0 problemas, sessão de 3 carreiras sem erro do jogo, save v0 → v6 e guarda do save real OK.
- **3 rounds:** só apresentação (rótulo e relógio), resultado idêntico ao motor, golpes determinísticos, prévia continua honesta. É o jeito certo: mais luta na tela sem mexer no balanço.
- **Mudança automática com prêmio:** o Muralha paga $2.500, a mudança custa $1.000 e o lutador chega com $1.500. Resolve o "cheguei seco" (item 13). A vitória agora só tem CONTINUAR, sem falsa escolha (N2 resolvido).
- **Metrônomo e Shift mais fortes:** atendem o item 5 em número (Metrônomo de 0,83 a 2,5 socos/s; Shift dobrou) sem passar a mão.
- **Luva dourada:** ×7 por 6 s, a cada 60–100 s. Número grande na tela, motivo para olhar a sala, e +35% de treino de clique para quem pega 80%. Quem ignora não fica para trás.
- **O clique continua sendo o mais forte:** 5 min depois de mudar, a 5/s, a mão dá 70% do treino com Boxe e 53% com Jiu-jitsu. As melhorias novas (×3 a 400K/4M; técnicas 600K/6M) sobem o teto sem fechar a academia numa carreira só.
- **A dificuldade foi segurada nos adversários,** como o dono pediu (Tonhão ×1,5, Kid ×2,3, Muralha +5%), e não cortando o clique.
- **Boxe × Jiu-jitsu até o cinturão:** 8,0% / 0% / 5,0% (meta ≤ 10%). Nenhuma arte domina.

## O que desvia da visão (e foi aceito)
- **"A mudança é uma compra desejada, não uma tela automática"** (escopo, Sensação). O dono mudou isso no feedback (item 13), e está certo: a compra virava "ganhei e perdi o prêmio na hora". Fica registrado como mudança de visão. A reserva de $1.000 da LOJA vira só rede de segurança (save migrado ou jogo fechado na vitória), sem custo (N6).
- **Carreira 1 não é mais idêntica à de antes dos PRs:** ganhou Metrônomo forte e luva. As metas dela (1ª derrota 11:14 / 12:44, cinturão na carreira 2) continuam valendo, então aceito.

## Decisões do Diretor

### 1. 23b (26,2% a 5/s, 25,2% a 4/s, contra ≤ 25%): **aceito, sem encurtar a luva**
- São 5 e 1 jogadores em 400. O Designer mostrou que a porcentagem balança ±3–5 pontos sozinha (o robô olha a prévia de 30 em 30 s); 25% e 26% não se distinguem.
- A medida estável fecha: **ninguém antes de 20:24** (meta 20:00). É esta a trava dura que eu protejo, porque é ela que garante que o cinturão não sai no "piloto automático".
- Encurtar a luva para 5 s tira justamente o que o dono pediu ("×7, clique como coisa mais forte") para ganhar 1 ponto de ruído.
- **Regra daqui em diante:** o 23b passa a ser lido como "**≤ 25% com tolerância de ruído de 2 pontos, e nunca antes de 20:00**". Se o "mais cedo" cair abaixo de 20:00 em qualquer mudança futura, aí sim a alavanca é `frenzy_seconds` 5 em `data/`.

### 2. Jiu-jitsu a 3/s leva 3 carreiras para o Kid (meta 1–2): **aceito como dívida da 5.2, com prazo**
- O problema é real e de visão: o Jiu-jitsu é "a arte de quem deixa a equipe trabalhar", e hoje, a 3/s, o Boxe chega ao Kid antes (2 carreiras contra 3). Até o cinturão o Jiu-jitsu ainda sai na frente a 3/s (9:21 × 9:49).
- A causa é o teto novo ser só de clique. A **5.2 (Clique sem teto)** já vai mexer exatamente nisso: variante da luva que paga a equipe ("Bolsa da torcida") e componente de clique que cresce com a equipe. Ajustar o Kid agora para refazer tudo daqui a uma fase é trabalho jogado fora.
- **Critério obrigatório da 5.2:** "a 3/s, o Jiu-jitsu vence o Kid em 1–2 carreiras (mediana) e nunca depois do Boxe no mesmo perfil".
- O que segura até lá: a 4–5/s as duas artes fecham (1–2 carreiras), e o tempo morto na academia fica ≤ 8 min (p90), então quem clica pouco demora mas não fica parado.

### 3. Curva do Jiu-jitsu subida sem pedido (+30% → +130%): **dentro do papel; aceito**
- Mexer em número de `data/` para manter uma meta que o dono aprovou (Boxe × Jiu-jitsu ≤ 10%) é exatamente o trabalho do Designer. Não criou sistema, não mudou escopo, não enfraqueceu o clique (respeita "não segurar a dificuldade no clique"), simulou e escreveu o motivo em R8.
- A alternativa (deixar o Boxe 14% na frente) quebrava um critério de aceite e o risco R3 do escopo ("uma arte dominar").
- **Ajuste de processo para as próximas fases:** número que o dono não citou e que o Designer mexer vai numa linha própria "mudei sem pedido" no topo da seção, para o Produtor mostrar ao dono. Aqui estava no texto, mas misturado.

### 4. Espera da luva dourada: **60–100 s (a do Designer)**
- O "mantém o intervalo" do dono foi dito comparando com a proposta R3, que já estava em 60–100 s em `data/`. Leio como "não mexam mais no intervalo".
- 60–100 s é a única versão simulada que fecha a trava dura (20:24). Com 45–90 s o ganho sobe de +35% para +41%, e com 7 s de frenesi o cinturão já caía para 18:50; o risco de furar 20:00 é alto.
- Na mão do jogador a diferença é pequena: uma luva a cada ~80 s em vez de ~67 s.
- Vai como pergunta 1 ao dono. Se ele quiser a do PR, troca em `data/` e o Designer simula de novo antes (sem código).

## Bugs do QA
| ID | Situação |
|---|---|
| N1 travamento da janela de arte | Resolvido (`_fechar_vitoria` idempotente). Confirmar no QA curto |
| N2 vitória com 2 botões | Resolvido: só CONTINUAR |
| N3 plaquinha do boneco coberta | Resolvido (placa mudou de lugar). Confirmar no `ui_audit` |
| N4 dica "guarde o dinheiro" sem sentido | Resolvido: só para quem aposentou com o cinturão ainda na garagem |
| N5 acento de "ÚLTIMA" na borda | Resolvido. Confirmar no `ui_audit` |
| N6 reserva da LOJA quase sem uso | Fica como rede de segurança, sem ação |
| N7 `tempo_jogo` anda com a escolha aberta | Dívida, sem ganho indevido. Polimento |

## O que fica para depois
**5.1 Garagem clara:** hierarquia da garagem (informação demais), prévia com respiro, altura da corda e os 2 quadros de repouso tortos, caixa de aparelho (3 cliques), top 3 animações.
**5.2 Clique sem teto:** luvas L3/L4 em $ (gastar os $1.500 da chegada e os prêmios da academia), variante da luva que paga a equipe, ajuste fino de Metrônomo/Shift se o dono pedir, medida de late game ("o clique vale ≥ X% da renda"), **Jiu-jitsu a 3/s no Kid em 1–2 carreiras**, e o 23b remedido com 400 jogadores.
**Depois:** calendário (5.3), árvore grande escondida (5.4), história e linhagem (6a–6c), lutas por arte e arena da academia (7a), Muay Thai (7b), regional e local 3 (8a).
**Dívidas técnicas (sem fase própria, entram quando a área for mexida):** os testes de UI do QA (`qa_f5_ui*`) fora da bateria; seções 4.2, 5.2, 7.1 e 10 do `fase5-design.md` com números antigos (vale R8); N7.

## Roteiro de teste para o dono (~10 min)

**Antes de começar:** peça ao Produtor uma cópia do seu save. A Parte B usa o F12, que mexe no save de verdade.

### Parte A — sem F12 (~6 min)
1. **Abra o jogo.** O save abre onde você parou, sem perder nada.
2. **Clique no saco por 1–2 minutos e fique de olho na sala.** Uma luva dourada aparece de tempos em tempos (mais ou menos a cada minuto e meio) e fica uns 7 segundos. Clique nela: aparece "FRENESI X7!" e um contador de 6 segundos. Clique rápido enquanto dura e veja os números saltarem.
3. **Deixe uma luva passar sem clicar.** Ela some sozinha e nada de ruim acontece.
4. **Teste o Shift ou o Metrônomo** (o que você tiver): segure o Shift parado, ou só olhe o Metrônomo tocar. Compare com 10 s clicando. Clicar tem que render bem mais, mas o automático já não pode parecer inútil.
5. **Abra a prévia do próximo adversário e lute.** A luta agora tem **3 rounds** ("1º ROUND", "2º ROUND", "3º ROUND") com relógio, barra de ESPECIAL que enche com o combo e golpes e quedas novos. Se ninguém cair, aparece "TEMPO! POR PONTOS". O resultado bate com a cor de risco da prévia.
6. **Se o seu save já estiver na academia:** clique na pera (Boxe) ou no boneco (Jiu-jitsu) e pule para o passo B5.

### Parte B — com F12 (~4 min)
1. **F12 → SALDO x1000** (multiplica o Treino) e **+10 DE CADA GERADOR**. Compre esteira, corda e as melhorias. Clique e troque o foco (teclas 1 a 3) até a prévia do Seu Muralha ficar verde.
2. **Vença o Seu Muralha.** A tela de vitória mostra o cinturão e o prêmio de $2.500 com um único botão, **CONTINUAR**. Ao apertar, você **se muda sozinho** para a academia: o $1.000 da mudança sai do prêmio e sobram $1.500. Tudo o que você tinha veio junto.
3. **Escolha a arte.** Abre a janela com Boxe e Jiu-jitsu. Um clique escolhe. Veja a sala nova e o "ACADEMIA: TREINO X2" no topo.
4. **Compre o aparelho da arte** na aba TREINO (2.500 de Treino): a pera ou o boneco chega com poeira e o foco vai para ele (tecla 4). Compre a técnica "Jab duplo" ou "Guarda fechada" e clique: o número sobe na hora. Só o aparelho da sua arte existe na sala.
5. **Lute com o Tonhão e depois com o Kid Navalha**, os dois em 3 rounds. A prévia mostra o traço da sua arte (Boxe bate mais forte, Jiu-jitsu apanha menos). O Kid é o teto da fase: é normal ele estar vermelho. Se der vermelho por 5 min, aparece a dica "APOSENTAR AGORA LEVA ... DE LEGADO".
6. **Aposente.** Abra a árvore e veja a aba **ESTILO**: 1 nó por arte, só vale jogando daquela arte. Compre o da sua arte se o Legado der.
7. **Comece uma NOVA CARREIRA.** Antes do cartão de início aparece a escolha da arte, já marcada com a última ("ÚLTIMA: ..."). Escolha a **outra** arte. Você volta para a **garagem**, só com o saco, e a marca de fita do aparelho da nova arte já está no chão, esperando a esteira. A luva dourada continua aparecendo.

## Perguntas para o dono
1. **A luva dourada a cada ~80 s ficou rara ou boa?** Deixei 60–100 s (a do PR era 45–90 s), porque é a única que mantém o cinturão fora do alcance antes dos 20 min. Se quiser mais frequente, é um número em `data/` e o Designer simula antes.
2. **Quem clica pouco e joga de Jiu-jitsu leva 3 carreiras para vencer o Kid** (o Boxe leva 2). Aceito até a 5.2, que traz a luva que paga a equipe e deve corrigir isso. Tudo bem esperar uma fase?
3. **Metrônomo e Shift ficaram fortes o bastante?** Pelos números, sim (o Metrônomo no topo vale metade de uma mão). Se ainda parecerem fracos jogando, o ajuste fino entra na 5.2.

## Resumo para o Produtor
A Fase 5 está **aprovada com 3 condições pequenas**: bateria de testes passando com os valores novos, padrões da luva no código iguais aos de `data/`, e um QA curto de N1–N5 com o alinhamento em 0 problemas.
Decidi: aceitar o 23b no limite (é ruído; ninguém pega o cinturão antes de 20:24), aceitar o Jiu-jitsu a 3/s em 3 carreiras como critério obrigatório da 5.2, aceitar a curva do Jiu-jitsu subida pelo Designer (dentro do papel) e manter a luva a cada 60–100 s.
Entregue: 3 rounds, mudança automática com sobra de $1.500, Metrônomo/Shift fortes, luva ×7 e o clique ainda como a coisa mais forte. Mostre o roteiro de ~10 min e as 3 perguntas. Depois vem a 5.1 (Garagem clara + caixa).
