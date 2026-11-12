# Fase 5.1: textos (Roteirista)

Status: o `fase5.1-design.md` ainda não existia quando escrevi. **As chaves abaixo são propostas**; o Designer/Programador renomeiam se quiserem e eu ajusto.
Regras seguidas: sem travessão (fonte 5x7), rótulo até 16 caracteres, dica até 44 por linha (`\n` quebra a linha), sem fala, 100% original.

## 1. A caixa da escola (história sem texto)
Ideia: a escola encomenda o equipamento de cada novo discípulo. A caixa mostra remetente e destinatário, e um carimbo com uma graça. Ninguém fala.

| Item | Rótulo (≤16) | Carimbo (≤16) |
|---|---|---|
| Esteira | ESTEIRA | PESADO |
| Corda | CORDA | NÃO EMBARAÇAR |
| Pera (boxe) | PERA | PRA CIMA |
| Boneco (jiu-jitsu) | BONECO | LADO COM CARA |
| Luva de lona | LUVA LONA | PAR |
| Luva de couro | LUVA COURO | NÃO MOLHAR |

- Remetente (etiqueta, igual em todas): `DA ESCOLA` / `PARA O NOVATO`.
- Toast ao abrir: `CHEGOU: {item}!` (ex.: CHEGOU: ESTEIRA!). Com o rótulo da tabela o maior é "CHEGOU: LUVA COURO!" (19), cabe como toast.
- Cliques: 1º `TOC!`, 2º `RACHOU!`, 3º `ABRIU!`.
- Dica ao passar o mouse na caixa fechada: `Caixa da escola. Clique 3 vezes.`; depois do 1º clique `Faltam {n} cliques para abrir.`; com mais de uma `Mais {n} esperando a vez.`

## 2. Dicas que substituem as plaquinhas
Marca de fita no chão, sem texto. A dica aparece no hover: linha 1 nome, linha 2 preço ou requisito.
- Disponível: `{nome}\n{preco} de treino. Vem em caixa.` Exemplo: `Esteira\n500 de treino. Vem em caixa.`
- Bloqueada por requisito: `{nome}\nDepois da {requisito}.` Exemplo: `Corda\nDepois da esteira.`
- Já montada: `{nome}\nJá está no lugar.`
- Falta saldo: `{nome}\nFalta treino. Falta {n}.`
- Shift (substitui "SEGURE SHIFT" e "SEGURAR" fixos): hover do botão `Segure SHIFT ou este botão\npara treino assistido.`; nas primeiras vezes aparece só `Dica: segure SHIFT.` (19) e some.

## 3. Itens que descem de nível (hover)
- **Fama:** `Fama\nO bairro já ouviu falar de você.`
- **Legado em jogo:** `Legado em jogo\nVira permanente ao aposentar.\nPerder leva metade.`
- **Local (nome no HUD):** continua usando `location_ambience` do `ui_texts` atual (a descrição só muda de lugar).
- **Teclas:** `ESPAÇO ou clique: treinar\nSHIFT: treino assistido\n1 a 4: tática   F11: tela cheia`. **Atenção:** assumi que 1 a 4 troca a tática; Designer/Programador confirmam.
- **Item bloqueado da loja** (hover, a linha recolhida mantém só o nome): `Trancado.\nCompre a {requisito} antes.`
- **Prêmio da luta:** `Prêmio\n${n} e {n} fama.` e, no cinturão, `Prêmio\nO cinturão amador.`

## 4. JSON para colar em `ui_texts`
```json
{
  "box_sender": "DA ESCOLA",
  "box_to": "PARA O NOVATO",
  "box_label": {
    "treadmill": "ESTEIRA",
    "jump_rope": "CORDA",
    "boxing": "PERA",
    "bjj": "BONECO",
    "glove_canvas": "LUVA LONA",
    "glove_leather": "LUVA COURO"
  },
  "box_stamp": {
    "treadmill": "PESADO",
    "jump_rope": "NÃO EMBARAÇAR",
    "boxing": "PRA CIMA",
    "bjj": "LADO COM CARA",
    "glove_canvas": "PAR",
    "glove_leather": "NÃO MOLHAR"
  },
  "box_click": ["TOC!", "RACHOU!", "ABRIU!"],
  "box_arrived": "CHEGOU: {item}!",
  "box_hover_closed": "Caixa da escola. Clique 3 vezes.",
  "box_hover_left": "Faltam {n} cliques para abrir.",
  "box_hover_queue": "Mais {n} esperando a vez.",
  "tape_open": "{nome}\n{preco} de treino. Vem em caixa.",
  "tape_locked": "{nome}\nDepois da {requisito}.",
  "tape_owned": "{nome}\nJá está no lugar.",
  "tape_short": "{nome}\nFalta treino. Falta {n}.",
  "hint_assist": "Segure SHIFT ou este botão\npara treino assistido.",
  "hint_assist_first": "Dica: segure SHIFT.",
  "hint_fame": "Fama\nO bairro já ouviu falar de você.",
  "hint_legacy": "Legado em jogo\nVira permanente ao aposentar.\nPerder leva metade.",
  "hint_keys": "ESPAÇO ou clique: treinar\nSHIFT: treino assistido\n1 a 4: tática   F11: tela cheia",
  "hint_locked_item": "Trancado.\nCompre a {requisito} antes.",
  "hint_prize": "Prêmio\n${n} e {n} fama.",
  "hint_prize_belt": "Prêmio\nO cinturão amador."
}
```

Observações para o Programador: as chaves de `box_label`/`box_stamp` seguem ids de aparelho/luva que supus (`treadmill`, `jump_rope`, `boxing`, `bjj`, `glove_canvas`, `glove_leather`); troque pelos ids reais de `shop.json`/`training.json`. Nada em `data/` ou código foi editado.
