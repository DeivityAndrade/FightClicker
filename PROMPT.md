# Prompt — Jogo incremental de luta (Godot 4)

Use este documento como briefing completo para desenvolver o jogo. Leia tudo antes de começar.

---

## 1. Papel e forma de trabalhar

Você é um desenvolvedor de jogos experiente em **Godot 4 (GDScript)** e em design de **jogos incrementais** (Cookie Clicker, Antimatter Dimensions, Realm Grinder etc.).

**Regras de trabalho (importante):**
- Trabalhe **em fases pequenas**. Ao final de cada fase, pare, mostre o que foi feito, explique como testar e **espere minha aprovação** antes de seguir.
- Não se adiante: nada de implementar sistemas de fases futuras "porque já estava ali".
- Antes de escrever código de uma fase, apresente um plano curto (arquivos, cenas, responsabilidades) e confirme comigo.
- Explique decisões técnicas em linguagem simples, em português.
- Prefira soluções simples e legíveis a arquiteturas sofisticadas.

---

## 2. Visão do jogo

Um **jogo incremental ativo** com temática de **lutador em ascensão**. O jogador clica para treinar, fica mais forte, escolhe e evolui uma **arte marcial**, enfrenta adversários cada vez mais fortes e busca o título de campeão. Depois se aposenta, vira mestre e treina um discípulo que começa com bônus permanentes.

- **Plataforma:** PC / Steam.
- **Motor:** Godot 4.7.x (instalado localmente), GDScript.
- **Estilo de jogo:** **ativo** (o clique e a atenção são recompensados), com **progresso offline modesto** para não punir quem sai.
- **Originalidade:** inspirado no gênero e na temática de jogos de luta/treino, mas com personagens, nomes, arte e identidade **100% próprios**. Não copiar Punch Club nem outro jogo existente.

---

## 3. Tom e narrativa

**Tom: começa pé no chão e escala para o absurdo.** O mundo acompanha os números exponenciais.
- **Início:** academia de bairro, saco de areia velho, luta clandestina valendo pouco dinheiro. Realista, um pouco melancólico.
- **Meio:** circuito profissional, patrocinadores, rivais caricatos.
- **Fim:** torneios secretos, mestres lendários, adversários absurdos (ex.: um urso, um monge milenar, alguém que soca tão forte que distorce a realidade).

**Narrativa leve, em pílulas** (nunca travar o loop):
- **Rival recorrente** que aparece em cada camada; humilha no começo e é o chefe final do título mundial.
- **Mentor** com falas curtas comentando o progresso.
- **A linhagem é a história:** ao se aposentar, o lutador vira o mentor do próximo discípulo.
- Diálogos curtos apenas em marcos (antes de lutas importantes), **sempre puláveis**.

---

## 4. Loop principal

> Clica para treinar → atributos sobem → vence lutas → ganha dinheiro e fama → compra treinadores/equipamentos (renda passiva) e técnicas → enfrenta adversários mais difíceis → conquista cinturões → aposenta e treina um discípulo com bônus de Legado → repete mais rápido, testando outra arte marcial.

---

## 5. Sistemas

### 5.1 Recursos
- **Treino:** gerado por clique e passivamente; é convertido em atributos.
- **Dinheiro:** ganho em lutas; compra geradores e upgrades.
- **Fama:** ganha em vitórias; desbloqueia adversários, patrocinadores e camadas.
- **Legado:** moeda de prestígio, permanente entre aposentadorias.

### 5.2 Atributos
- **Força:** dano.
- **Agilidade:** chance de crítico e esquiva.
- **Resistência:** vida e redução de dano.

O jogador escolhe um **foco de treino** (qual atributo recebe o treino); o clique e a renda passiva vão para o foco atual.

### 5.3 Clique
- Ações de treino (saco de pancada, corda, corrida…) ligadas aos atributos.
- **Feedback forte ("juice")**: números flutuando, leve tremida de tela, escala no botão, som de impacto.
- O clique deve **perder relevância gradualmente** para a renda passiva; upgrades podem converter uma % da renda passiva em força de clique, para manter o clique útil.

### 5.4 Geradores passivos (exemplos — nomes podem mudar)
Parceiro de treino → Treinador → Academia própria → Alunos → Patrocinadores → Rede de academias → …
Cada um com custo crescente exponencial e produção de treino por segundo.

### 5.5 Upgrades
- **Equipamento** (luvas, bandagem, tênis): multiplicadores.
- **Dieta/suplementos:** multiplicadores globais.
- **Técnicas** da arte marcial: efeitos específicos (ex.: "Jab duplo: +100% dano de clique").

### 5.6 Lutas
- **Resolvidas pelos números**, não por reflexo. Simulação automática com barras de vida, durando poucos segundos e com impacto visual.
- Antes da luta, uma **escolha tática leve**: agressivo / defensivo / contra-ataque (modificadores).
- Opcional: cliques durante a luta dão um pequeno boost (nunca obrigatório).
- **Escada de adversários** por camada: amador → regional → nacional → mundial. Cada cinturão libera geradores e mecânicas novas.
- Derrota não deve frustrar: ganha um pouco de dinheiro e feedback de quanto faltou.

### 5.7 Artes marciais (builds)
Cada arte muda a curva de crescimento:
- **Boxe:** dano de clique alto — ideal para jogo ativo.
- **Muay Thai:** crítico e combos.
- **Jiu-jitsu:** escala com renda passiva/tempo.
- **Judô/Wrestling:** bônus percentuais sobre atributos.

Com o prestígio é possível desbloquear uma **segunda arte** e combinar estilos (**MMA/híbridos**).

### 5.8 Prestígio — Aposentadoria e Linhagem
- Após conquistar o título da camada final disponível, o jogador pode **se aposentar**.
- Ganha **Legado** com base no progresso (vitórias, cinturões, fama).
- O **discípulo** recomeça do zero com bônus permanentes comprados com Legado e a chance de escolher outra arte.

### 5.9 Camadas (desbloqueio progressivo)
1. **Treino** (clique + atributos)
2. **Carreira de lutas** (adversários, cinturões)
3. **Gestão da academia** (geradores, alunos, patrocínio)
4. **Linhagem e legado** (prestígio, artes híbridas)

Cada camada nova deve dar a sensação de que o jogo "virou outro".

### 5.10 Evitar (anti-incremental)
- Decadência de atributos com o tempo.
- Fome/energia que bloqueiam o jogador.
- Se quiser tensão: **cansaço que se recupera sozinho** ou **lesão temporária** após lutas difíceis.

### 5.11 Progresso offline
- Ao reabrir, conceder **~25% da renda passiva** do tempo ausente (com teto, ex.: 8 h) e mostrar um resumo "Enquanto você estava fora…".

### 5.12 Conquistas
Ex.: "Nocaute no 1º round", "Invicto em 50 lutas", "Faixa preta em 3 artes". Preparadas para virar conquistas da Steam depois.

---

## 6. Diretrizes técnicas

- **Godot 4.7.x, GDScript**, projeto 2D, interface com nós `Control`.
- **Dados separados da lógica:** geradores, upgrades, adversários e artes definidos em `Resource` (`.tres`) ou JSON, para balancear sem mexer em código.
- **Estado do jogo** em um autoload (ex.: `GameState`) com sinais para atualizar a UI.
- **Números grandes:** planejar desde o início uma forma de lidar com valores enormes (float com formatação 1.2K / 3.4M / 5.6e12, ou uma classe de número grande se necessário).
- **Fórmula de custo padrão:** `custo = base * crescimento^quantidade` (crescimento ~1.15, ajustável).
- **Save/load** em `user://` (JSON), com autosave periódico e versão do save.
- **Tick** de produção passiva em `_process` com delta, separado da UI.
- **Steam (fase posterior):** integração via **GodotSteam** (conquistas, nuvem). Não implementar no começo.
- Código organizado em pastas: `scenes/`, `scripts/`, `data/`, `ui/`, `assets/`.
- Arte inicial com placeholders simples; arte final vem depois.

---

## 7. Fases sugeridas

Cada fase termina com algo **jogável** e com minha aprovação antes da próxima.

1. **Fundação:** projeto Godot, estrutura de pastas, `GameState`, formatação de números, save/load.
2. **Loop de treino:** clique, foco de atributo, feedback visual, primeiros geradores e upgrades.
3. **Lutas:** escada de adversários da 1ª camada, simulação com barras de vida, escolha tática, recompensas.
4. **Artes marciais:** escolha inicial e efeitos de 2–3 artes.
5. **Gestão da academia:** geradores avançados, fama, patrocínio.
6. **Prestígio:** aposentadoria, Legado, discípulo, segunda arte.
7. **Narrativa e tom:** rival, mentor, diálogos puláveis, escalada para o absurdo.
8. **Polimento:** offline, conquistas, sons, balanceamento das primeiras 2–3 horas.
9. **Steam:** GodotSteam, conquistas, nuvem, build de distribuição.

---

## 8. Critério de sucesso do protótipo (fases 1–3)

Em ~15 minutos de jogo o jogador deve: sentir o impacto do clique, comprar geradores e ver a renda passiva crescer, perder uma luta, entender por que perdeu, treinar e vencer em seguida — e querer continuar.

---

**Comece apenas pela Fase 1: apresente o plano e aguarde minha aprovação.**
