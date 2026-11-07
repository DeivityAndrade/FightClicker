# Fase 2 — Treino na garagem: escopo

Dono: Diretor de Jogo. Versão 1 (2026-11-05).
Base: `PROMPT.md`, `docs/visao.md` (com "Decisões do dono" e "Assumido pelo estúdio"), `docs/roadmap.md`, `docs/arte/direcao-visual.md` e o mockup `docs/arte/mockups/garagem_x2.png`.

## Objetivo
Trocar a tela de verificação pela **sala da garagem em pixel art** e fazer o loop de treino funcionar: clicar no alvo central, escolher o foco, comprar a primeira gente treinando junto e as primeiras melhorias de aparelho, e ver tudo isso crescer na tela.

## Sensação
- **No primeiro clique:** "esse soco pesou". Número sobe, saco balança, tela treme de leve, som bate.
- **Nos primeiros minutos:** "a garagem está ganhando vida". Alguém aparece treinando, o saco remendado vira um saco melhor, o "/s" do topo sobe a cada compra.
- **Tom:** pé no chão, meio melancólico. Lâmpada fraca, saco com fita, corda de varal. Nada de glamour ainda.

## A pendência: com que recurso se compra na Fase 2
**Decisão: tudo da garagem custa Treino.** Dinheiro não aparece nesta fase.

Como funciona (o princípio; os números ficam com o Designer):
- Cada ponto de treino ganho (clique ou passivo) vai **ao mesmo tempo** para o **atributo em foco** e para o **saldo de Treino**.
- **Gastar Treino nunca diminui atributo.** O atributo é o que o corpo aprendeu; o saldo é o fôlego que você "investe" na garagem.
- Os itens da garagem continuam custando Treino **para sempre**, inclusive depois da Fase 3. Não é uma moeda provisória.

Por que assim:
- **Nenhum recurso falso.** O PROMPT (§5.1) já diz que Treino é gerado por clique e passivamente. Inventar "bicos" ou dinheiro de mentira criaria um sistema que seria jogado fora na Fase 3.
- **Combina com o tom:** na garagem ninguém paga ninguém. O parceiro é gente do bairro que treina junto, e remendar o saco é gambiarra feita no braço. É esforço, não compra.
- **Não adianta a Fase 3 e não a engessa:** dinheiro chega com as lutas e compra só o que dinheiro compra (gente que cobra, coisa de loja, mudança de local). A Fase 3 **soma** uma moeda. Não precisa migrar preço de nada.
- **O loop fecha dentro da fase:** clicar → juntar Treino → comprar → produzir mais Treino. Dá para testar e sentir sem lutas.

## O que entra
**Tela principal**
- A **sala da garagem** (640x360, geometria e paleta de `direcao-visual.md`) vira a tela que abre no F5. A tela de verificação sai. Os botões de depuração continuam acessíveis por uma tecla escondida, para o QA.
- **HUD mínimo:** saldo de Treino, Treino/s, nome do local. Painel esquerdo: os 3 atributos. Painel direito: geradores e melhorias. Barra de baixo: "por clique", "auto /s", os 3 botões de foco.

**Alvo central e foco**
- Lutador + aparelho em foco **no centro, sempre no mesmo ponto da tela** (saco em x≈336, área clicável de ~48x90 px da base).
- **3 aparelhos básicos:** saco = Força, corda = Agilidade, esteira = Resistência.
- Trocar o foco (botão na barra de baixo ou clique no aparelho lateral): instantâneo, grátis e ilimitado. O lutador vai para o aparelho novo, mas o ponto de clique não muda.
- O clique e a renda passiva vão para o atributo em foco (PROMPT §5.2).

**Juice do clique**
- **Número flutuante em todo clique**, saindo do ponto clicado, com valor e atributo (ex.: `+12 FORÇA`), na cor do atributo.
- Aparelho reage (saco empurra e volta; corda faz o arco; esteira corre), lutador faz o golpe ou o movimento.
- Tremida de tela de 1–2 px, só em pixel inteiro e curta. Traços de impacto no ponto do golpe.
- **Som de impacto** a cada clique, com variação leve (tom ou amostra) para não cansar. Placeholder serve, desde que seja feito pelo estúdio ou CC0, com a origem anotada.
- **Crítico de clique simples:** chance e multiplicador fixos, vindos de `data/`, com número maior (2x) e "!". Por enquanto não depende de Agilidade: Agilidade dá crítico **na luta** (Fase 3).
- **Cursor = a luva** sobre a sala (a mesma da mão do lutador). Na Fase 2 a luva é fixa (bandagem/luva velha).

**Geradores (renda passiva)**
- **2 tipos**, ambos gente do bairro que treina junto (nomes com o Roteirista; o mockup usa "Parceiro").
- Custo `base * crescimento^quantidade` (crescimento ~1.15, ajustável em `data/`). Produção em Treino/s.
- Ao comprar o primeiro de cada tipo, **uma pessoa aparece treinando** num aparelho lateral. Mais compras, mais movimento, até um limite **só de desenho**. Comprar nunca é bloqueado.

**Melhorias de aparelho**
- Uma linha de melhorias por aparelho (multiplicador do treino daquele aparelho), paga em Treino.
- **2 níveis visuais por aparelho:** a primeira melhoria troca o sprite (saco remendado → saco novo; corda de varal → corda de verdade; esteira enferrujada → esteira lubrificada). Níveis numéricos a mais podem existir sem sprite novo.
- Preço que não dá para pagar aparece em `r2` (vermelho). O item mostra o que faz antes de comprar.

**Dados e save**
- Geradores, melhorias, crítico, valores de clique e custos em `data/` (JSON), fora do código.
- Save sobe para **versão 2**, com migração da v1 (o treino da v1 é mantido). Guarda: saldo de Treino, os 3 atributos, foco, geradores, melhorias.
- O treino/s de teste da Fase 1 deixa de existir: a renda passiva passa a vir só dos geradores.
- Recomendação ao Programador: guardar o estado desta fase já agrupado como "carreira", porque na Fase 3 a carreira se perde e o permanente fica. Só agrupar, sem criar nenhum sistema de carreira.

**Testes automáticos** (somando aos da Fase 1): fórmula de custo, compra desconta o saldo e não deixa saldo negativo, compra sem saldo é recusada, gasto não mexe em atributo, passivo vai para o foco, produção igual em 30 e 144 FPS, salvar/carregar o estado novo, migração v1→v2.

## O que fica de fora (e onde entra)
| Item | Fase |
|---|---|
| Dinheiro, fama, lutas, adversários, prévia de luta, botão LUTAR | Fase 3 |
| Fim de carreira, aposentadoria, Legado contado (botão APOSENTAR, "Legado em jogo") | Fase 3 |
| Efeito dos atributos (dano, crítico/esquiva, vida) | Fase 3 |
| Gerador pago (treinador), equipamento de loja, troca de luva | Fase 3 em diante, comprados com dinheiro |
| Árvore de habilidades e gasto de Legado | Fase 4 |
| Mudança de local, academia de bairro, artes marciais, 4º foco, combos | Fase 5 |
| Melhoria que converte % da renda passiva em clique | Fase 6 (quando a passiva dispara com geradores avançados) |
| Fama, patrocínio, geradores avançados | Fase 6 |
| Mentor, rival, falas, foto do mentor na parede com significado | Fase 8 (a foto pode estar no cenário, só como decoração) |
| Progresso offline e "Enquanto você estava fora…" | Fase 9 |
| Menu de opções (volume, desligar tremida), conquistas, trilha sonora | Fase 9 |
| Arte final por pixel artist humano | Fase 9 (placeholder do Diretor de Arte vale agora) |

**Para UI/UX e Arte:** o mockup da garagem mostra `$`, FAMA, "Legado em jogo", "Próxima luta", LUTAR!, APOSENTAR e "Próximo local". Na Fase 2 **nada disso aparece**, nem desativado. O espaço fica para atributos e loja (ou vazio). E os preços do mockup em `$` viram preços em Treino.

## Critérios de aceite (verificáveis)
**Abertura e tela**
1. F5 abre direto na garagem, sem erros nem avisos vermelhos no console. A tela de verificação não aparece. A depuração abre só por tecla escondida (documentada no README).
2. Em 1280x720 e 1920x1080 a sala fica nítida, em escala inteira, sem borrão. Nenhum painel cobre a sala, e o texto se lê.
3. Na tela não aparece dinheiro, fama, Legado, luta, aposentar nem próximo local.

**Alvo central e foco**
4. Em **até 10 segundos** sem instrução, um jogador novo descobre onde clicar (o texto "clique no saco para treinar" ajuda).
5. Clicando sempre no **mesmo ponto da tela**, o clique conta nos 3 focos. O QA troca o foco 3 vezes sem mexer o mouse e confere.
6. Trocar o foco leva 1 clique, sem custo nem espera. O foco atual fica destacado na cor do atributo, e o lutador aparece no aparelho certo.
7. Com renda passiva ligada, só o atributo em foco sobe. Trocar o foco desvia a renda na hora.

**Juice**
8. **Todo clique mostra número**, inclusive a 10 cliques/s por 10 s: nenhum clique sem número, nenhuma queda visível de FPS, números legíveis.
9. O número mostrado é igual ao que entrou no atributo e no saldo. O QA soma 20 cliques e confere.
10. Cada clique produz, juntos: reação do aparelho, golpe/movimento do lutador, tremida de 1–2 px (só pixel inteiro), traços de impacto e som. Dez cliques seguidos não tocam o mesmo som idêntico dez vezes.
11. O crítico aparece em cerca da proporção configurada (QA: 200 cliques), maior, em `r3` e com "!". Mudando a chance em `data/`, a frequência muda.
12. Sobre a sala, o cursor é a luva, e é a mesma luva da mão do lutador.

**Geradores, melhorias, crescimento**
13. O **primeiro gerador** sai em **até 1 minuto** de clique normal (~4–5 cliques/s).
14. A **primeira melhoria de aparelho** sai em **até 3 minutos** e troca o sprite do aparelho na hora.
15. O **segundo tipo de gerador** sai entre **5 e 8 minutos** (rápido o bastante para ver, lento o bastante para não ser "fácil").
16. Toda compra muda o "/s" ou o "por clique" na hora, e o primeiro gerador de cada tipo **põe uma pessoa treinando na sala**.
17. Com muitas unidades (ex.: 200, via depuração), a compra continua funcionando e a sala não quebra nem lota além do limite de desenho.
18. Gastar Treino **nunca** reduz atributo. O preço de cada próxima unidade segue `base * crescimento^n` (teste automático e conferência com o design).
19. Em **10 minutos** de jogo, a renda passiva fica visível e relevante (pelo menos ~30% do que o clique ativo rende por segundo), mas **clicar ainda rende mais que não clicar**. O Designer prova isso com uma simulação no `fase2-design.md`, e o QA confere jogando.

**Dados, save, testes**
20. Mudando o preço base de um gerador em `data/` e reabrindo, o preço muda sem mexer no código.
21. Um save da Fase 1 (v1) abre na Fase 2 com o treino mantido, sem erro.
22. Fechar pelo X e reabrir mantém saldo, atributos, foco, geradores e melhorias (diferença máxima de 1 s de produção).
23. `tools/run_tests.ps1` passa todos os testes (antigos e novos), e o save real continua igual.
24. Uma sessão de **15 minutos** seguidos sem nenhum erro no console.

## Riscos de design
- **"Para que serve Agilidade?"** Sem luta, atributo é só um número. Mitigação: cada atributo diz em uma linha para que serve na luta, e as melhorias por aparelho dão um motivo real para variar o foco. Não inventar efeito provisório.
- **Balanceamento sem lutas.** Os números da Fase 2 vão ser reajustados na Fase 3, quando o ritmo de luta existir. O Designer deve deixar tudo em `data/` e mirar nos tempos dos critérios 13–15 e 19. A meta "não tão fácil" vale para a carreira inteira, não para os primeiros 5 minutos: o começo precisa ser rápido e generoso.
- **Juice demais cansa.** Tremida e som a cada clique, a 8 cliques/s, podem irritar. Mitigação: tremida curta e mínima, som variado e volume moderado. Opção de desligar fica para a Fase 9. Se o QA achar desconfortável, reduzir antes disso.
- **Mockup adiantando fases.** O mockup mostra elementos de luta e carreira. Risco de entrarem "desativados". Regra: não aparecem.
- **Arte placeholder parecendo final.** O dono pode julgar o jogo pela arte gerada por código. O relatório deve dizer claramente que é placeholder.
- **Moeda única por enquanto.** Gastar Treino e acumular atributo ao mesmo tempo pode confundir. Mitigação: o HUD separa "Treino (saldo)" dos atributos, e o número flutuante mostra o atributo.

## Perguntas para o dono
**Nada bloqueia a Fase 2.** As 8 perguntas da visão foram assumidas pelo estúdio, com as recomendações do Diretor (ver `docs/visao.md`, "Assumido pelo estúdio"). Dá para revisar depois, sem refazer esta fase.

Não bloqueiam, mas vale o dono confirmar quando vir o plano:
1. **Comprar com Treino** na garagem (e para sempre nos itens da garagem), com dinheiro só a partir das lutas: ok?
2. **Tremida de tela em todo clique**, bem leve: ok, ou prefere só nos críticos?
