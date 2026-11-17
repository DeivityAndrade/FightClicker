# Fase 6c2 — Mais longe que eu: revisão

Dono: Diretor de Jogo. Data: 2026-11-16.
Base: `PROMPT.md`, `fase6c2-escopo.md`, `fase6c2-design.md`, `fase6c2-textos.md`, relatório do QA (dados fornecidos pelo Produtor), `estado-atual.md`.

## Veredito

**APROVADA COM RESSALVAS**

A fase entrega a visão de academia como coração da linhagem. Sistemas de Honra, mural, árvore do hall e símbolo são originais, diegéticos e fiéis ao tom pé no chão. Critérios de aceite atendidos. Duas ressalvas não-bloqueantes antes do merge: confirmação manual do balanço (Python indisponível) e registro do BUG-1 em issue para correção futura.

---

## Comentários por ponto de revisão

### 1. Bate com a visão?

Sim. Mural, Honra e símbolo transformam a academia em espaço de memória e pertencimento. A progressão intra-campanha (Honra) é distinta do prestígio entre campanhas (Legado). O texto "foi seguir o rumo dele" fecha o arco do John com melancolia contida. A sensação é de continuidade: "outros vieram antes, eu sigo adiante".

### 2. Identidade original?

Sim. Nada copia árvores de talento genéricas ou sistemas de prestígio de outros incrementais. Cada nó da árvore do hall tem nome e descrição diegéticos ("Seu soco ecoa no salão", não "+5% dano"). A Honra compra reconhecimento e história, não poder bruto. O símbolo é visual puro, sem efeito mecânico. Tom pé no chão mantido: tinta, prego, respeito medido em atos.

### 3. Critérios de aceite

Relatório do QA indica 13/13 critérios OK. Pontos verificados:

- **Critério 4 (ui_audit):** 16 estados cobertos, 0 problemas. Inclui foto reta/torta, hover old_photo_gym/garage, mural vazio/preenchido/símbolo. OBS-C da 6c1 integrada.
- **Critério 11 (balanço):** teste comparativo no Godot confirma invariância. Python indisponível — ver item 5 abaixo.
- **Critério 12 (cena do mural):** considerado OK por ausência. Transições automáticas baseadas em marcos e nós. Sem cutscene dedicada. Aceito — ver item 6.
- **Critério 13 (testes):** 73 testes verdes, janela no 2º monitor (`--position 1950,40`). Save de teste isolado.

Nenhum critério precisa de ajuste.

### 4. Bugs documentados

- **BUG-1 (headless apenas):** não afeta jogo normal. Aceito como não-bloqueante. Registrar em issue para correção em fase futura de testes automatizados.
- **BUG-2 (pré-existente):** anterior à 6c2, fora do escopo desta fase. Não bloqueia merge.

Ambos aceitáveis para seguir. Nenhum bug afeta a experiência do jogador na academia, mural, Honra ou árvore do hall.

### 5. Balanço

Teste comparativo no Godot (duas campanhas iguais, uma com Honra ativa e outra sem) confirma relógio, treino, ouro, dia e luta idênticos. Python indisponível no ambiente do QA.

**Ressalva:** pedir ao Programador ou QA uma verificação manual adicional antes do merge — rodar `fase5_sim.py` em ambiente com Python disponível ou repetir o teste comparativo no Godot com log detalhado dos valores de treino/dinheiro/dia em 5 checkpoints. Se bater, merge liberado. Se divergir, investigar antes.

### 6. Mural sem cena dedicada

Critério 12 foi considerado OK por ausência de cena. Transições são automáticas e silenciosas, baseadas apenas em marcos e compras de nós. Isso bate com a expectativa: o mural é parte da parede, não um evento narrativo separado. Uma cutscene curta seria excesso para uma mudança de estado que já comunica visualmente. Aceito.

### 7. Textos

Tom consistente com fases anteriores. Melancolia leve, orgulho contido, sem fanfarra. "foi seguir o rumo dele" fecha o arco do John como esperado — explícito o suficiente para responder aos testadores, discreto o bastante para manter o tom. Falas de mentor (recorde/revanche) respeitam limite de caracteres e lista de letras 5x7. Variações de hover da foto reforçam memória e pertencimento sem inflar texto.

### 8. OBS-C da 6c1

Estados de `ui_audit` da foto (reta/torta) e hover `old_photo_gym` foram integrados junto com o mural, conforme planejado no escopo. QA confirma 16 estados cobertos com 0 problemas. Integração correta.

---

## Ajustes pedidos

| # | Ajuste | Responsável | Prioridade | Bloqueia merge? |
|---|---|---|---|---|
| 1 | Verificação manual do balanço (rodar `fase5_sim.py` com Python ou repetir teste comparativo no Godot com log detalhado em 5 checkpoints) | Programador ou QA | Alta | Sim — confirmar antes do merge |
| 2 | Registrar BUG-1 (headless) em issue para correção futura | QA | Baixa | Não |

Nenhum outro ajuste necessário. Design, textos, arte e implementação estão alinhados com a visão.

---

## Resumo para o Produtor

- **Veredito:** APROVADA COM RESSALVAS. Fase sólida, entrega a visão de academia como coração da linhagem. Original, pé no chão, critérios atendidos.
- **Antes do merge:** confirmar balanço com verificação manual (Python indisponível no QA). Se bater, merge liberado.
- **Para o dono:** pode apresentar. Dizer que a academia agora tem mural, Honra, árvore do hall e símbolo. Texto "foi seguir o rumo dele" fecha o arco do John. Dois bugs menores não afetam jogo normal. Pedir que ele teste: entrar na academia pós-saída do John, ver mural, ganhar Honra em luta/recorde, comprar nó T1, ver símbolo no peito após nó T3.
- **Próxima fase:** após aprovação do dono, atualizar `estado-atual.md` e iniciar planejamento da 6c3 ou fase seguinte conforme roadmap.