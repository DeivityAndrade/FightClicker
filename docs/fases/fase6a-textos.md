# Fase 6a: textos (nomes, humilhação, abertura, treinador, Arco 1)

Dono: Roteirista. Data: 2026-11-13 (atualizado após a escolha do dono). Base: `fase6a-escopo.md`, `direcao-narrativa.md` (manda), `docs/cutscenes/` (`linguagem.md` §7, `gesto-assinatura.md`, `pedidos.md`).
**Decisões do dono:** 1º lutador **John Bullet**; treinador **Osmar Brandão**; escola **Raízes Fight Club**; humilhação **A, "a ficha em branco"**, com a ficha amassada como objeto na parede. "Bullet" e "Fight Club" ficam em inglês, como o dono escolheu. Nenhum arquivo de `data/` ou de código foi tocado.

## 0. Regras de texto desta fase
- **Balão:** no máximo 2 linhas de 26 caracteres, tudo em minúsculas (a plaquinha leva o nome). Todas as falas abaixo respeitam isso; o Programador deve ter teste que reprova linha > 26.
- **Nenhuma fala explica mecânica.** O treinador reage, não ensina.
- **Nada presume resultado.** Só as variantes `c2mais` falam em "já vimos isso".
- **Gênero neutro** nas falas do treinador (o discípulo da 6b pode ser qualquer pessoa). Só o John é "ele".
- **Sem travessão** em nenhum texto. Sem lutador real nem filme.
- **Fonte 5x7:** nas falas uso só á â ã ç é ê í ó õ ú minúsculos (lista de `pedidos.md`). O único acento em MAIÚSCULA é o `Í` de `RAÍZES` (plaquinha da escola, ficha, errata em caixa alta). Se o Diretor de Arte achar que não lê, usar **RAIZES** em todo texto de objeto; nas falas em minúscula não há problema.
- Humor de bairro; a piada é com o objeto, o Muralha e o exagero do Osmar, nunca com o vínculo entre John e Osmar.

## 1. Nomes (escolhidos)

| Papel | Nome | Plaquinha | Voz (1 linha, para o timbre) |
|---|---|---|---|
| 1º lutador | **John Bullet** | `John` | baixa, curta e meio seca, de quem pensa antes e solta um sorriso no fim da frase (quadrada macia, ataque curto, 28 c/s) |
| Treinador original | **Osmar Brandão** | `Osmar` (os outros dizem "seu Osmar") | rouca e lenta, de quem já gritou em muita arquibancada e empolga quando a história cresce (grave com ruído, 22 c/s) |
| Escola | **Raízes Fight Club** | `Raízes` na parede e na ficha; "a escola" nas falas | n/a |

Observações para a equipe:
- O nome inglês do John convive bem com o bairro: o apelido "Bullet" pode virar piada de vizinho depois ("quem botou bala nesse?"), sem mudar nada agora.
- **Símbolo da escola:** o escopo propunha a lâmpada por causa do nome antigo. Com "Raízes", sugiro ao Diretor de Arte uma **raiz em 5x5 px** (tronco que se abre em duas pontas) e deixar a lâmpada só como luz da garagem. A decisão visual é dele; os textos abaixo não dependem disso.

## 2. A humilhação (escolhida: A, "a ficha em branco")
John foi se inscrever no torneio do bairro. Na ficha havia o campo **ESCOLA**. Ele não tinha o que escrever, o fiscal escreveu "nenhuma" e o Seu Muralha, que passava, **riu** (sem maldade, como quem lê placa engraçada). Todo mundo riu junto.
- É dor de nome, sem soco, sem crueldade.
- O 1º cinturão amador (dono: Seu Muralha) salva a garagem **e** fecha a revanche: a ficha passa de `ESCOLA: NENHUMA` para `ESCOLA: RAÍZES FIGHT CLUB`.
- **Objeto na parede (confirmado pelo dono):** a ficha amassada, em 2 estados (antes e depois). Pedido ao Diretor de Arte: 2 sprites pequenos, perto do aviso de cobrança, legíveis em MAIÚSCULA. O texto do "depois" tem 25 caracteres; se não couber no sprite, usar `RAÍZES FIGHT CLUB` sozinho.

## 3. A abertura (ids `open_1` a `open_4`)
Toca na sala viva. **O saco aceita clique desde o primeiro quadro** (o critério é ≤ 3 s). Balões passivos: não recebem clique, não cobrem o alvo, somem sozinhos. Clique fora do alvo ou ESPAÇO completa a fala; ESC por 0,5 s pula tudo.

| id | t aprox. | Quem | Texto (cada `\n` é quebra de linha) | Obs |
|---|---|---|---|---|
| (gesto) | 0,3 a 1,2 s | John | gesto A completo (`rrrip`, toc, toc) | Vem **antes** da fala. Qualquer clique cancela. |
| `open_1` | 1,4 s | Osmar | `chegou outro aviso, john.` | O olho vai para o aviso na parede. 25 car. |
| `open_2` | 4,4 s | Osmar | `ainda formo campeão aqui.` | O sonho. 25 car. |
| `open_3` | 7,5 s | John | `o muralha riu da ficha:\nescola: nenhuma.` | A humilhação. 23 e 16 car. |
| `open_4` | 12,0 s | John | `vou botar um nome ali.` | A decisão, olhando a ficha. 22 car. |

Duração estimada: cerca de **15 s** (28 c/s o John, 22 c/s o Osmar, pausas de `linguagem.md` §7.2, balão some depois de `max(1,2 s; 0,06 s x car.)`), folga de 5 s sob o limite de 20 s. Quem monta a abertura confirma medindo. Passa as 3 ideias: dificuldade (aviso), sonho do treinador, humilhação com vontade de provar.

## 4. Comentários do treinador (Osmar)

### 4.1 Gatilhos
Frequência real (60 s mínimo, nunca na luta, janela aberta, dia de luta parado ou balão na tela) é do Designer. Aqui: `unica` = uma vez na vida do save; `repetivel` = 3 variantes, com descanso (não repete na mesma campanha nem na seguinte). Prioridade sugerida (maior ganha a disputa): garagem salva 10, primeira derrota 9, luva do John 8, revanche 7, recorde 6, primeira academia 6, derrota 5, luta marcada 4, compra/caixa 3, parado 1.

| Gatilho | Quando dispara | Frequência | Campanha | Variantes |
|---|---|---|---|---|
| `primeira_compra` | 1ª compra marcante da escola | **unica** | qualquer | 1 |
| `primeira_caixa` | 1ª caixa aberta da escola | **unica** | qualquer | 1 |
| `primeira_derrota` | 1ª derrota da escola | **unica** | qualquer | 1 |
| `luva_par` | 1ª luva nova calçada na escola | **unica** | qualquer | 1 |
| `garagem_salva` | próxima vez na garagem depois do cinturão | **unica** | qualquer | 1 |
| `primeira_academia` | 1ª chegada à academia da escola | **unica** | qualquer | 1 |
| `passar_posto` | passagem do posto | **unica** (reservada 6b, desligada) | 6b | 1 |
| `compra` | compra marcante, depois da 1ª | repetivel | qualquer | 3 |
| `caixa` | caixa aberta, depois da 1ª | repetivel | qualquer | 3 |
| `derrota` | derrota, depois da 1ª | repetivel | `c1` | 3 |
| `derrota_recall` | derrota, "já vimos isso" | repetivel | `c2mais` | 3 |
| `revanche` | vitória contra quem te derrotou nesta campanha | repetivel | qualquer | 3 |
| `recorde` | passou a marca anterior (só se existia marca) | repetivel | qualquer | 3 |
| `luta_marcada` | luta marcada perto, sala parada | repetivel | qualquer | 3 |
| `parado` | 20 s sem clique, depois do gesto curto | repetivel | qualquer | 3 |
| `academia_volta` | chegada à academia nas campanhas seguintes | repetivel | `c2mais` | 3 |
| `arte` | escolha da arte, sem arte "certa" | repetivel (reservada 6c, desligada) | 6c | 3 |

Notas: `revanche` só toca se a vitória for contra quem derrotou a escola nesta campanha (dado do Designer). `derrota` (c1) e `derrota_recall` (c2mais) são o mesmo gatilho; muda só a campanha. O Osmar **não** comenta a garagem salva no selo (o selo é interface); fala uma vez na volta.

### 4.2 Falas (cada `\n` é quebra de linha)

**Únicas**
| Gatilho | Texto |
|---|---|
| `primeira_compra` | `isso, enche a sala.` |
| `primeira_caixa` | `cheiro de coisa nova.\nfaz tempo, hein.` |
| `primeira_derrota` | `todo mundo cai primeiro.\neu caí em três países.` |
| `luva_par` | `a velha é o par do john.\npassa de mão em mão.` |
| `garagem_salva` | `o aviso saiu da parede.\nainda é nossa, viu?` |
| `primeira_academia` | `a garagem vai junto,\nmesmo sem a lâmpada.` |
| `passar_posto` (6b) | `a escola não para.\nquem sai ensina.` |

**Repetíveis (3 variantes)**
| Gatilho | V1 | V2 | V3 |
|---|---|---|---|
| `compra` | `a sala tá ficando gente.` | `comprou bem. eu acho.` | `no meu tempo era cimento\nnum saco de batata.` |
| `caixa` | `abre aí, que eu espio.` | `caixa nova, dia bom.` | `essa caixa vira banco.` |
| `derrota` | `foi só um dia ruim.` | `eu apanhei de um poste.` | `senta, bebe água, volta.` |
| `derrota_recall` | `eu também já perdi aqui.` | `a escola já levantou.` | `cai, mas a gente volta.` |
| `revanche` | `conta quitada, hein.` | `ele não esperava essa.` | `agora ele que lembre.` |
| `recorde` | `marca nova, e eu vi.` | `isso aí passou da marca.` | `quem diria, hein.` |
| `luta_marcada` | `tá chegando a luta.` | `bota a luva e respira.` | `ombro solto, queixo baixo.` |
| `parado` | `saco não bate sozinho.` | `tá dormindo em pé?` | `a lâmpada tá piscando, ó.` |
| `academia_volta` | `já sabe o caminho, né?` | `cheiro de tatame, hein?` | `aqui o espelho é maior.` |
| `arte` (6c) | `cada um tem seu jeito.` | `escolheu? vai até o fim.` | `eu lutei de todo jeito.` |

As histórias exageradas ("apanhei de um poste", "cimento num saco de batata", "caí em três países") são a semente do Arco 5.

### 4.3 Peças soltas
- **Luva inicial, descrição (item, ≤ 44):** `O par do John. Velha, mas fecha direito.` (40 car.). É a única menção a "o par dele" na 6a, junto com a fala `luva_par`.
- **Selo da tela de vitória (UI, MAIÚSCULAS, sem acento):** título `GARAGEM SALVA`, linha menor `O LUGAR CONTINUA NOSSO`.

## 5. Arco 1: textos dos objetos
Texto de objeto fica na legenda (tooltip), 1 linha, sem balão.

| Objeto | Quando | Texto |
|---|---|---|
| **Aviso de cobrança** | desde o começo; sai quando a garagem é salva | título `AVISO DE COBRANÇA` (Ç e Ã em maiúscula: conferir; plano B `AVISO FINAL`); corpo `Aluguel em atraso. Regularize ou desocupe.` |
| **Foto antiga** | desde o começo, fica | `Osmar, bem antes das histórias.` |
| **Ficha amassada** (objeto confirmado) | antes: desde o começo; depois: garagem salva | antes `ESCOLA: NENHUMA`; depois `ESCOLA: RAÍZES FIGHT CLUB` (plano B `RAIZES`) |
| **Recorte de jornal** | próxima vitória da escola depois da 6a | manchete `GARAGEM FAZ BARULHO NO BAIRRO`; subtítulo `Ninguém sabia que ali treinava gente.`; rodapé `Errata: o nome é Raízes Fight Club.` |
| **Foto da equipe** | garagem salva, fica | `A escola inteira. Pouca gente, muita raiz.` |
| **Símbolo da escola** | garagem salva | sem texto; só o desenho na parede (ver sugestão da raiz, §1) |
| **Selo da vitória** | tela de vitória do 1º cinturão amador | `GARAGEM SALVA` / `O LUGAR CONTINUA NOSSO` |
| **Fala do Osmar (única)** | volta à garagem depois do cinturão | `o aviso saiu da parede.\nainda é nossa, viu?` |

O recorte, a ficha e a foto da equipe são os textos de objeto que citam a escola pelo nome.

## 6. Pedidos a outros papéis
- **Diretor de Arte:** conferir `á â ã ç é ê í ó õ ú` minúsculas na 5x7 antes de tudo; maiúsculas `Í Ç Ã` só em texto de objeto (plano B: RAIZES, AVISO FINAL). Sprites da ficha amassada (2 estados) e símbolo da escola (sugestão: raiz 5x5).
- **Programador:** validador que reprova mais de 2 linhas, linha > 26 car. em fala, caractere `—` e maiúscula acentuada em fala.
- **Diretor de Cutscenes:** ajustar a sucessão aos nomes (`John`, `Osmar`), mantendo o verbo **ver** em `suc_guarda` (`vamos ver sua guarda.`) e `fim_ver` (`quero ver o que aprenderam.`); `suc_isso` = `isso.`
- **Designer:** frequência real, prioridade, descanso e o dado de `revanche`.

## 7. JSON pronto para colar (`data/dialogos.json`, proposta)
`speaker` usa o id de timbre de `linguagem.md` (`primeiro`, `treinador`); `trigger` é o gatilho; `frequency` é `unica` ou `repetivel`; `group` agrupa variantes; `campaign` é `qualquer`, `c1` ou `c2mais`; `enabled` desliga falas de fases futuras. `\n` é a quebra de linha do balão. Números de intervalo e prioridade ficam com o Designer.

```json
{
  "versao": 1,
  "personagens": {
    "primeiro":  { "nome": "John", "nome_completo": "John Bullet", "voz": "primeiro" },
    "treinador": { "nome": "Osmar", "nome_completo": "Osmar Brandão", "voz": "treinador" }
  },
  "escola": { "nome": "Raízes Fight Club", "nome_plano_b": "RAIZES FIGHT CLUB" },
  "falas": [
    { "id": "open_1", "speaker": "treinador", "text": "chegou outro aviso, john.", "trigger": "abertura", "frequency": "unica", "campaign": "qualquer", "order": 1, "enabled": true },
    { "id": "open_2", "speaker": "treinador", "text": "ainda formo campeão aqui.", "trigger": "abertura", "frequency": "unica", "campaign": "qualquer", "order": 2, "enabled": true },
    { "id": "open_3", "speaker": "primeiro", "text": "o muralha riu da ficha:\nescola: nenhuma.", "trigger": "abertura", "frequency": "unica", "campaign": "qualquer", "order": 3, "enabled": true },
    { "id": "open_4", "speaker": "primeiro", "text": "vou botar um nome ali.", "trigger": "abertura", "frequency": "unica", "campaign": "qualquer", "order": 4, "enabled": true },

    { "id": "osm_primeira_compra", "speaker": "treinador", "text": "isso, enche a sala.", "trigger": "primeira_compra", "frequency": "unica", "campaign": "qualquer", "enabled": true },
    { "id": "osm_primeira_caixa", "speaker": "treinador", "text": "cheiro de coisa nova.\nfaz tempo, hein.", "trigger": "primeira_caixa", "frequency": "unica", "campaign": "qualquer", "enabled": true },
    { "id": "osm_primeira_derrota", "speaker": "treinador", "text": "todo mundo cai primeiro.\neu caí em três países.", "trigger": "primeira_derrota", "frequency": "unica", "campaign": "qualquer", "enabled": true },
    { "id": "osm_luva_par", "speaker": "treinador", "text": "a velha é o par do john.\npassa de mão em mão.", "trigger": "luva_par", "frequency": "unica", "campaign": "qualquer", "enabled": true },
    { "id": "osm_garagem_salva", "speaker": "treinador", "text": "o aviso saiu da parede.\nainda é nossa, viu?", "trigger": "garagem_salva", "frequency": "unica", "campaign": "qualquer", "enabled": true },
    { "id": "osm_primeira_academia", "speaker": "treinador", "text": "a garagem vai junto,\nmesmo sem a lâmpada.", "trigger": "primeira_academia", "frequency": "unica", "campaign": "qualquer", "enabled": true },
    { "id": "osm_passar_posto", "speaker": "treinador", "text": "a escola não para.\nquem sai ensina.", "trigger": "passar_posto", "frequency": "unica", "campaign": "qualquer", "enabled": false },

    { "id": "osm_compra_1", "speaker": "treinador", "text": "a sala tá ficando gente.", "trigger": "compra", "frequency": "repetivel", "group": "compra", "campaign": "qualquer", "enabled": true },
    { "id": "osm_compra_2", "speaker": "treinador", "text": "comprou bem. eu acho.", "trigger": "compra", "frequency": "repetivel", "group": "compra", "campaign": "qualquer", "enabled": true },
    { "id": "osm_compra_3", "speaker": "treinador", "text": "no meu tempo era cimento\nnum saco de batata.", "trigger": "compra", "frequency": "repetivel", "group": "compra", "campaign": "qualquer", "enabled": true },

    { "id": "osm_caixa_1", "speaker": "treinador", "text": "abre aí, que eu espio.", "trigger": "caixa", "frequency": "repetivel", "group": "caixa", "campaign": "qualquer", "enabled": true },
    { "id": "osm_caixa_2", "speaker": "treinador", "text": "caixa nova, dia bom.", "trigger": "caixa", "frequency": "repetivel", "group": "caixa", "campaign": "qualquer", "enabled": true },
    { "id": "osm_caixa_3", "speaker": "treinador", "text": "essa caixa vira banco.", "trigger": "caixa", "frequency": "repetivel", "group": "caixa", "campaign": "qualquer", "enabled": true },

    { "id": "osm_derrota_1", "speaker": "treinador", "text": "foi só um dia ruim.", "trigger": "derrota", "frequency": "repetivel", "group": "derrota", "campaign": "c1", "enabled": true },
    { "id": "osm_derrota_2", "speaker": "treinador", "text": "eu apanhei de um poste.", "trigger": "derrota", "frequency": "repetivel", "group": "derrota", "campaign": "c1", "enabled": true },
    { "id": "osm_derrota_3", "speaker": "treinador", "text": "senta, bebe água, volta.", "trigger": "derrota", "frequency": "repetivel", "group": "derrota", "campaign": "c1", "enabled": true },

    { "id": "osm_derrota_recall_1", "speaker": "treinador", "text": "eu também já perdi aqui.", "trigger": "derrota", "frequency": "repetivel", "group": "derrota_recall", "campaign": "c2mais", "enabled": true },
    { "id": "osm_derrota_recall_2", "speaker": "treinador", "text": "a escola já levantou.", "trigger": "derrota", "frequency": "repetivel", "group": "derrota_recall", "campaign": "c2mais", "enabled": true },
    { "id": "osm_derrota_recall_3", "speaker": "treinador", "text": "cai, mas a gente volta.", "trigger": "derrota", "frequency": "repetivel", "group": "derrota_recall", "campaign": "c2mais", "enabled": true },

    { "id": "osm_revanche_1", "speaker": "treinador", "text": "conta quitada, hein.", "trigger": "revanche", "frequency": "repetivel", "group": "revanche", "campaign": "qualquer", "enabled": true },
    { "id": "osm_revanche_2", "speaker": "treinador", "text": "ele não esperava essa.", "trigger": "revanche", "frequency": "repetivel", "group": "revanche", "campaign": "qualquer", "enabled": true },
    { "id": "osm_revanche_3", "speaker": "treinador", "text": "agora ele que lembre.", "trigger": "revanche", "frequency": "repetivel", "group": "revanche", "campaign": "qualquer", "enabled": true },

    { "id": "osm_recorde_1", "speaker": "treinador", "text": "marca nova, e eu vi.", "trigger": "recorde", "frequency": "repetivel", "group": "recorde", "campaign": "qualquer", "enabled": true },
    { "id": "osm_recorde_2", "speaker": "treinador", "text": "isso aí passou da marca.", "trigger": "recorde", "frequency": "repetivel", "group": "recorde", "campaign": "qualquer", "enabled": true },
    { "id": "osm_recorde_3", "speaker": "treinador", "text": "quem diria, hein.", "trigger": "recorde", "frequency": "repetivel", "group": "recorde", "campaign": "qualquer", "enabled": true },

    { "id": "osm_luta_marcada_1", "speaker": "treinador", "text": "tá chegando a luta.", "trigger": "luta_marcada", "frequency": "repetivel", "group": "luta_marcada", "campaign": "qualquer", "enabled": true },
    { "id": "osm_luta_marcada_2", "speaker": "treinador", "text": "bota a luva e respira.", "trigger": "luta_marcada", "frequency": "repetivel", "group": "luta_marcada", "campaign": "qualquer", "enabled": true },
    { "id": "osm_luta_marcada_3", "speaker": "treinador", "text": "ombro solto, queixo baixo.", "trigger": "luta_marcada", "frequency": "repetivel", "group": "luta_marcada", "campaign": "qualquer", "enabled": true },

    { "id": "osm_parado_1", "speaker": "treinador", "text": "saco não bate sozinho.", "trigger": "parado", "frequency": "repetivel", "group": "parado", "campaign": "qualquer", "enabled": true },
    { "id": "osm_parado_2", "speaker": "treinador", "text": "tá dormindo em pé?", "trigger": "parado", "frequency": "repetivel", "group": "parado", "campaign": "qualquer", "enabled": true },
    { "id": "osm_parado_3", "speaker": "treinador", "text": "a lâmpada tá piscando, ó.", "trigger": "parado", "frequency": "repetivel", "group": "parado", "campaign": "qualquer", "enabled": true },

    { "id": "osm_academia_volta_1", "speaker": "treinador", "text": "já sabe o caminho, né?", "trigger": "academia_volta", "frequency": "repetivel", "group": "academia_volta", "campaign": "c2mais", "enabled": true },
    { "id": "osm_academia_volta_2", "speaker": "treinador", "text": "cheiro de tatame, hein?", "trigger": "academia_volta", "frequency": "repetivel", "group": "academia_volta", "campaign": "c2mais", "enabled": true },
    { "id": "osm_academia_volta_3", "speaker": "treinador", "text": "aqui o espelho é maior.", "trigger": "academia_volta", "frequency": "repetivel", "group": "academia_volta", "campaign": "c2mais", "enabled": true },

    { "id": "osm_arte_1", "speaker": "treinador", "text": "cada um tem seu jeito.", "trigger": "arte", "frequency": "repetivel", "group": "arte", "campaign": "qualquer", "enabled": false },
    { "id": "osm_arte_2", "speaker": "treinador", "text": "escolheu? vai até o fim.", "trigger": "arte", "frequency": "repetivel", "group": "arte", "campaign": "qualquer", "enabled": false },
    { "id": "osm_arte_3", "speaker": "treinador", "text": "eu lutei de todo jeito.", "trigger": "arte", "frequency": "repetivel", "group": "arte", "campaign": "qualquer", "enabled": false }
  ],
  "objetos": {
    "aviso_cobranca": { "titulo": "AVISO DE COBRANÇA", "texto": "Aluguel em atraso. Regularize ou desocupe." },
    "foto_antiga": { "texto": "Osmar, bem antes das histórias." },
    "ficha_antes": { "texto": "ESCOLA: NENHUMA" },
    "ficha_depois": { "texto": "ESCOLA: RAÍZES FIGHT CLUB", "texto_plano_b": "ESCOLA: RAIZES FIGHT CLUB" },
    "recorte": { "titulo": "GARAGEM FAZ BARULHO NO BAIRRO", "texto": "Ninguém sabia que ali treinava gente.", "rodape": "Errata: o nome é Raízes Fight Club." },
    "foto_equipe": { "texto": "A escola inteira. Pouca gente, muita raiz." },
    "selo_garagem_salva": { "titulo": "GARAGEM SALVA", "texto": "O LUGAR CONTINUA NOSSO" },
    "luva_inicial_desc": { "texto": "O par do John. Velha, mas fecha direito." }
  }
}
```

## 8. Resumo
- Nomes fixados: John Bullet, Osmar Brandão, Raízes Fight Club. Humilhação A com a ficha amassada na parede (muda para `ESCOLA: RAÍZES FIGHT CLUB` quando a garagem é salva).
- Abertura com ids `open_1` a `open_4`, cerca de 15 s.
- Pendências: Diretor de Arte confere `Í` maiúsculo (plano B RAIZES) e decide o símbolo (sugestão: raiz 5x5, já que o nome saiu da lâmpada).
