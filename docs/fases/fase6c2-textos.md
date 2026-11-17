# Fase 6c2: textos (Mais longe que eu)

Dono: Roteirista. Data: 2026-11-16. Base: `fase6c2-escopo.md`, `direcao-narrativa.md`, `fase6c1-textos.md`, `data/ui_texts.json`, `data/dialogos.json`.
Tocados: apenas textos e dados de texto. Código, números e mecânicas são com o Designer e o Programador.
Tom: pé no chão, melancolia leve, orgulho contido. Escala para o absurdo só nas campanhas tardias; na 6c2 ainda é bairro e academia.
Balão: minúsculas, máx. 2 linhas de 26 caracteres. Letras da lista 5x7 (á â ã ç é ê í ó õ ú minúsculos); sem hífen.
Identidade: 100% original. Nada de Punch Club ou outros incrementais.

## 1. Texto do mural

Decisão do dono (2026-11-16): explícito — "foi seguir o rumo dele". Fecha a saída discreta do John e dá resposta aos testadores.

| Chave | Onde | Texto | Nota |
|---|---|---|---|
| `mural_john_text` | `ui_texts.json` | foi seguir o rumo dele. | Mural com John apenas (pós-saída, pré-outros-mentores). Uma linha, 22 chars. |
| `mural_mentors_text` | `ui_texts.json` | cada um deixou o seu. | Variante curta para quando há 2+ mentores no mural. Uma linha, 21 chars. |
| `mural_empty_text` | `ui_texts.json` | a parede espera. | Estado vazio (antes da saída do John ou antes de qualquer marco). Uma linha, 16 chars. |

- O mural aparece após `cena_saida_primeiro_mentor` OU `cena_primeira_academia` (o que vier primeiro), conforme critério de aceite #1.
- `mural_john_text` é o texto principal enquanto só o John saiu. Quando um segundo mentor passa o posto, troca para `mural_mentors_text`.
- `mural_empty_text` cobre o estado anterior à saída; pode ser usado como placeholder visual antes do marco.

## 2. Hover da foto antiga (`old_photo_gym`)

Texto base já existe em `dialogos.json` → `objects.old_photo_gym`: "A foto veio da garagem.\nEra torta. Aqui ficou reta." Mantido.

Variações por marco/campanha (bônus de retrato, §6 abaixo). O hover muda conforme o momento da campanha; a chave base permanece `old_photo_gym`, e as variações são sufixos ou chaves derivadas.

| Chave | Marco | Texto |
|---|---|---|
| `old_photo_gym` | Padrão (sem marco específico) | A foto veio da garagem.\nEra torta. Aqui ficou reta. |
| `old_photo_gym_post_belt` | Após cinturão amador | A foto endireitou.\nO cinturão também. |
| `old_photo_gym_post_succession` | Após primeira sucessão | A foto continua.\nQuem vem depois também. |
| `old_photo_gym_post_hall` | Após abrir a árvore do hall | A foto lembra.\nA parede agora conta. |

- Na garagem, `old_photo` permanece inalterado: "Osmar, bem antes das histórias."
- Programador: usar `old_photo_gym` quando local = gym; as variações são escolhidas por marco presente no save.

## 3. Falas de mentor (recorde pessoal)

Gatilho: `personal_record_{atributo}` (strength, agility, endurance). Tom: orgulho contido, sem fanfarra. Mentor fala, não o discípulo.
Condição: mentor desenhado na sala. Intervalo mínimo respeitado pelo sistema de comentários.

| Id | Gatilho | Texto | Grupo |
|---|---|---|---|
| `cl_recorde_forca_1` | `personal_record_strength` | o saco sentiu. / eu também. | recorde_forca |
| `cl_recorde_forca_2` | `personal_record_strength` | marca nova. / eu vi. | recorde_forca |
| `cl_recorde_forca_3` | `personal_record_strength` | passou da minha. / tá certo. | recorde_forca |
| `cl_recorde_agil_1` | `personal_record_agility` | rápido assim / eu não era. | recorde_agil |
| `cl_recorde_agil_2` | `personal_record_agility` | a mão voou. / anotei. | recorde_agil |
| `cl_recorde_agil_3` | `personal_record_agility` | mais rápido que / a lembrança. | recorde_agil |
| `cl_recorde_resist_1` | `personal_record_endurance` | aguentou mais / que eu. | recorde_resist |
| `cl_recorde_resist_2` | `personal_record_endurance` | fôlego novo. / bom sinal. | recorde_resist |
| `cl_recorde_resist_3` | `personal_record_endurance` | ficou de pé. / eu caí antes. | recorde_resist |

- Todas `repeat: rest`, `speaker: coach` (ou mentor presente; o sistema escolhe quem está desenhado).
- Textos curtos, 2 linhas máx., leitura em <2s. Sem exclamação, sem "parabéns". O orgulho está no reconhecimento, não na festa.
- As falas existentes `cl_recorde_1..3` em `dialogos.json` são genéricas (`fight_won` + `record: true`). Estas novas são específicas por atributo e usam gatilho dedicado `personal_record_{attr}`.

## 4. Falas de mentor (revanche)

Gatilho: `revenge_win_vs_{adversario}`. Tom: reconhecimento, passagem de bastão. Mentor venceu por aquele adversário; agora o discípulo venceu também.
Condição: mentor desenhado, adversário identificado no save como derrota anterior do mentor.

| Id | Gatilho | Texto | Grupo |
|---|---|---|---|
| `cl_revanche_mentor_1` | `revenge_win_vs_*` | ele me pegou. / você não. | revanche_mentor |
| `cl_revanche_mentor_2` | `revenge_win_vs_*` | conta velha. / você quitou. | revanche_mentor |
| `cl_revanche_mentor_3` | `revenge_win_vs_*` | eu perdi ali. / você trouxe. | revanche_mentor |
| `cl_revanche_mentor_4` | `revenge_win_vs_*` | foi além de mim. / tá certo. | revanche_mentor |

- `revenge_win_vs_*` é padrão; o sufixo é o id do adversário. O sistema dispara qualquer uma do grupo `revanche_mentor` quando o gatilho bate.
- Diferente das `cl_revanche_1..3` existentes (que são do Osmar sobre revanches genéricas do discípulo). Estas são específicas para quando o discípulo vence alguém que já derrotou o mentor.
- Tom de passagem de bastão: "você fez o que eu não fiz". Sem drama, sem lição de moral. Reconhecimento seco.

## 5. Nós da árvore do hall

Árvore ramificada por arte (decisão do dono). Ramificação boxe agora; outras artes como "em breve". Cada nó tem nome e descrição diegéticos — nunca "+X% dano". Efeitos mecânicos são definidos pelo Designer em `fase6c2-design.md`; aqui só texto.

### 5.1 Tronco (comum, independente de arte)

| Chave | Nome | Descrição |
|---|---|---|
| `hall_node_root` | Raiz da escola | O chão que segura tudo. |
| `hall_node_name` | Nome na parede | Seu nome entra no mural. |
| `hall_node_symbol` | Símbolo no peito | A escola veste você. |
| `hall_node_memory` | Memória viva | Cada luta deixa marca. |

### 5.2 Ramo Boxe

| Chave | Nome | Descrição |
|---|---|---|
| `hall_boxe_guard` | Guarda fechada | O queixo some, o soco passa. |
| `hall_boxe_rhythm` | Ritmo de saco | A mão sabe quando voltar. |
| `hall_boxe_respect` | Respeito do bairro | Seus socos ecoam na rua. |
| `hall_boxe_legacy` | Luva passada | A luva do John pesa menos. |
| `hall_boxe_crown` | Coroa de lona | O cinturão conhece seu nome. |

### 5.3 Ramo Jiu-Jitsu (placeholder)

| Chave | Nome | Descrição |
|---|---|---|
| `hall_bjj_soon` | Em breve | O tatame espera. |

### 5.4 Ramo MMA / Segunda arte (placeholder)

| Chave | Nome | Descrição |
|---|---|---|
| `hall_mma_soon` | Em breve | A mistura vem depois. |

- Chaves seguem padrão `hall_{ramo}_{identificador}`. Programador usa essas chaves em `data/hall_tree.json` (ou equivalente); Designer define custos e efeitos.
- Descrições são diegéticas: contam história, não número. O efeito mecânico aparece na UI como tooltip separado; a descrição é sabor.
- `hall_node_symbol` é o nó que libera o sprite do símbolo no peito. Nasce pronto e fixo (decisão do dono).
- Placeholders "Em breve" são diegéticos: o tatame espera, a mistura vem depois. Não soam como erro ou conteúdo faltando; soam como promessa da escola.

## 6. Bônus de retrato (variações do hover da foto)

O hover da foto antiga muda conforme marcos da campanha. Reforça identidade e memória sem custo de sistema novo. Textos curtos, 2 linhas máx.

| Marco | Chave | Texto |
|---|---|---|
| Nenhum (padrão) | `old_photo_gym` | A foto veio da garagem.\nEra torta. Aqui ficou reta. |
| Primeira vitória na academia | `old_photo_gym_first_gym_win` | A foto viu.\nA primeira daqui. |
| Cinturão amador | `old_photo_gym_post_belt` | A foto endireitou.\nO cinturão também. |
| Primeira sucessão | `old_photo_gym_post_succession` | A foto continua.\nQuem vem depois também. |
| Árvore do hall aberta | `old_photo_gym_post_hall` | A foto lembra.\nA parede agora conta. |
| Recorde pessoal batido | `old_photo_gym_post_record` | A foto marcou.\nVocê também. |
| Revanche vencida | `old_photo_gym_post_revenge` | A foto sabe.\nA conta fechou. |

- Programador: verificar marcos presentes no save e escolher a chave correspondente. Prioridade: marco mais recente vence. Se nenhum marco especial, usar `old_photo_gym`.
- Textos mantêm o tom da foto base: memória, continuidade, pertencimento. Sem fanfarra, sem "conquista desbloqueada".
- Na garagem, `old_photo` nunca muda. As variações são exclusivas da academia.

## 7. Notas para integração

- **Chaves novas em `ui_texts.json`:** `mural_john_text`, `mural_mentors_text`, `mural_empty_text`.
- **Chaves novas em `dialogos.json`:** `cl_recorde_forca_1..3`, `cl_recorde_agil_1..3`, `cl_recorde_resist_1..3`, `cl_revanche_mentor_1..4`. Adicionar em `lines` com `trigger` adequado e `repeat: rest`.
- **Chaves de hover em `dialogos.json` → `objects`:** `old_photo_gym_first_gym_win`, `old_photo_gym_post_belt`, `old_photo_gym_post_succession`, `old_photo_gym_post_hall`, `old_photo_gym_post_record`, `old_photo_gym_post_revenge`.
- **Nós do hall:** tabela acima. Designer define estrutura de dados; Programador implementa leitura. Textos ficam em `ui_texts.json` ou arquivo dedicado (`data/hall_texts.json`), a decidir pelo Programador.
- **Gatilhos novos:** `personal_record_strength`, `personal_record_agility`, `personal_record_endurance`, `revenge_win_vs_{adversario}`. Designer especifica condições exatas; Programador implementa disparo.
- **Não mexer:** `old_photo`, `old_photo_gym` (base), falas existentes de recorde/revanche genéricas. As novas coexistem.
- **Balão:** todos os textos respeitam limite de 2 linhas de 26 chars e lista de letras 5x7. Verificado manualmente.

## 8. Pendências

- **Designer:** definir custos e efeitos dos nós do hall; especificar condições exatas dos gatilhos `personal_record_*` e `revenge_win_vs_*`; confirmar se `hall_node_symbol` libera o sprite ou se o símbolo é sempre visível pós-marco.
- **Programador:** implementar leitura dos textos novos; mapear marcos para variações de hover; adicionar gatilhos ao sistema de comentários; integrar nós do hall na árvore.
- **Diretor de Arte:** símbolo da escola (sprite no peito) e integração visual do mural/hall. O texto `hall_node_symbol` assume que o símbolo nasce pronto e fixo.
- **QA:** verificar que os textos aparecem nos gatilhos certos, que o hover muda por marco, e que o mural exibe o texto correto por estado. Testes no 2º monitor (`--position 1950,40`).