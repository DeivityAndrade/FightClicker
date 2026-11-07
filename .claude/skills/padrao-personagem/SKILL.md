---
name: padrao-personagem
description: Padrão de qualidade para personagens em pixel art do Fightclicker (lutador, adversários, ajudantes, figurantes) — anatomia, proporções, encaixe das partes do corpo, sombreamento e animação. Use SEMPRE que for criar, gerar, revisar ou alterar qualquer sprite de personagem ou animação de personagem (arquivos em assets/sprites/characters, fight, opponents, ou geradores em tools/art que desenham gente), e quando o dono reclamar que os personagens parecem pouco humanos, duros, com encaixe estranho ou animação contraditória.
---

# Padrão de personagem — Fightclicker

O dono achou os personagens "pouco humanos" e o encaixe das partes do corpo estranho. Personagem é o que o jogador olha o tempo todo (o lutador fica no centro da tela), então ele precisa parecer **uma pessoa inteira se mexendo**, não peças coladas. Este padrão existe para que todo personagem novo ou refeito passe pelo mesmo crivo.

## 1. Comece pelo corpo inteiro, não pelas peças
Desenhe primeiro a **silhueta completa em guarda** (a pose mais vista). Só depois divida em partes, se a animação precisar. Peças desenhadas isoladas e montadas por coordenadas dão buracos, emendas e proporções que mudam a cada quadro — foi exatamente o problema rejeitado.

## 2. Proporções (lutador de ~64 px de altura)
- Cabeça ≈ 1/5 da altura (12–13 px) — estilizado, mas humano; nunca uma bola maior que o tronco.
- Ombros visivelmente mais largos que o quadril no lutador; braço até o meio da coxa; mãos (luvas) maiores que o normal, de propósito, para ler o soco.
- Pescoço existe (1–2 px), mesmo curto.
- Pés apoiados com peso: base afastada na guarda, joelhos levemente dobrados.
- Cada adversário muda **silhueta** (largo, magro, alto, baixo, barriga), não só a cor da roupa.

## 3. Encaixes (onde as peças se encontram)
- Ombro: o braço nasce **por baixo** da manga/ombro do tronco; nunca uma linha reta separando braço e tronco, nunca buraco na camiseta.
- Cotovelo e joelho: as duas peças se **sobrepõem** com ponta arredondada; o contorno da articulação some na sobreposição (sem "risco" atravessando o membro).
- Quadril: cintura/faixa/calção cobre a junção com as coxas.
- Luva: encaixa no punho com uma faixa/punho visível; a luva acompanha a direção do antebraço (não fica "de frente" quando o braço está de lado).
- Contorno: 1 px escuro na silhueta externa; entre partes do mesmo corpo, use sombra (cor mais escura da rampa), não contorno preto — senão vira boneco recortado.

## 4. Sombreamento e cor
- Luz de cima/frente-esquerda, igual em todos os personagens e quadros.
- 3 tons por material (luz, base, sombra) + contorno; pele com tom quente na sombra, não cinza.
- Nada de "pillow shading" (sombra contornando tudo igual); volumes claros: peito, ombro, coxa.
- Detalhe que cabe em 1 px não existe: rosto com 2–4 pixels bem escolhidos (olho, sobrancelha, boca/barba) legíveis em 1x.

## 5. Animação
- **Poses-chave autorais**, não interpolação de pontos: guarda → antecipação → contato → recuperação.
- Peso: o quadril e os pés participam do soco (gira o tronco, o pé de trás empurra); no golpe forte, o corpo inteiro avança.
- Antecipação e acompanhamento: recuar antes de bater, passar um pouco do alvo depois.
- Coerência entre quadros: membros não trocam de comprimento, a cabeça não muda de tamanho, a luva não troca de lado; o mesmo pixel de pivô fica no chão.
- Queda (K.O.): joelhos cedem primeiro, depois o tronco; termina apoiado no chão, não rígido girando.
- Guarda/respiração: 2–4 quadros sutis (ombros sobem 1 px), nunca o corpo todo pulando.

## 5b. Regras aprendidas no diagnóstico (2026-11-05)
Vieram do diagnóstico em `docs/arte/personagens-diagnostico.md`; cada uma corrige um defeito real dos sprites antigos.
1. **Contorno só na silhueta.** Nada de carimbar cada parte com contorno próprio — isso criava riscos pretos no ombro, quadril, joelho e queixo (efeito boneco recortado). Junta ligada = sem linha; sobreposição = sombra de contato.
2. **Comprimento dos membros constante** por personagem em todos os quadros (use IK de 2 ossos: mão/pé no alvo, braço e antebraço com tamanho fixo).
3. **Uma vista por cena:** cabeça, tronco e pés na mesma vista (nada de tronco de frente com cabeça e tênis de perfil).
4. **Mesma proporção** do personagem na garagem e na luta.
5. **Luva com orientação por quadro** (de frente, de lado, de cima), acompanhando o antebraço — inclusive girando com o corpo no K.O.
6. **Ponta do pé de apoio fixa** durante o golpe, salvo se houver um passo desenhado; o calcanhar pode subir.
7. **Luva de trás sempre ligada ao braço**, desenhada na ordem certa (nunca solta na frente do corpo).
8. **Nenhum pixel de pele** aparecendo entre o calção e as coxas.

## 6. Checagem antes de entregar
1. Folha de contato em 1x e 3x com todos os quadros, e antes/depois lado a lado.
2. Olhar cada articulação ampliada: há buraco, emenda, risco de contorno atravessando, peça mudando de tamanho?
3. Ver o ciclo em movimento (GIF ou sequência) no fundo real (garagem/arena), não só no fundo liso.
4. Conferir que tamanho de quadro, pivô, `hit_frame`, `hit_point` e mãos por quadro continuam batendo com `assets/sprites/manifest.json`.
5. Relatório: o que melhorou, o que ainda pede pixel artist humano, caminhos das imagens.
