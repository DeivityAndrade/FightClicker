# Achados do verificador endurecido (ID1)

Gerado por `tools/ui/ui_audit.gd -- --estados todos --estrito --achados` (586 estados, janela em 1950,40, 30 fps). **Nenhuma tela foi consertada.** Modo padrão continua passando; as regras novas só reprovam com `--estrito`.

## Totais por regra (nós distintos, deduplicados entre estados)

| Regra | Achados |
|---|---|
| IGNORE_SEM_MOTIVO | 237 |
| IGNORE_PROIBIDO | 331 |
| TXT_SOZINHO | 69 |
| JANELA_ASSIM | 4 |
| JANELA_MARGEM | 0 |
| OPACO_FORA | 2 |
| DRAW_TEXTO | 0 |
| **Total** | **643** |

Placar de `ignore`: **234** nós distintos (meta: no máximo 15), **0** com motivo escrito.

Linhas de relatório (estado x nó, sem deduplicar): IGNORE_SEM_MOTIVO 12279, IGNORE_PROIBIDO 3737, TXT_SOZINHO 2650, OPACO_FORA 46, JANELA_ASSIM 18.

Notas:
- `arquivo` é o script do nó ou do ancestral mais próximo; `:linha` vem de busca textual (melhor esforço). Para IGNORE_*, as linhas são todos os `ignore` do arquivo.
- TXT_SOZINHO é a regra mais barulhenta: pega todo Label à esquerda sem declaração, sozinho na linha, com margens desiguais. Muitos são listas legítimas à esquerda; ID3 decide caso a caso (declarar `left` ou centralizar).
- IGNORE_PROIBIDO inclui números flutuantes/rótulos dinâmicos (precisam de `UiTema.ignorar(no, motivo, true)`), que não são erro de alinhamento, e os 6 casos reais do levantamento.

## Por tela (arquivo)

### ui/anim_sprite.gd  (2)
- **IGNORE_SEM_MOTIVO** x1
  - `ui/anim_sprite.gd` Fluxo/@Control/@Node2D/@Sprite2D [f8a1_james_depois_ko] ignore sem motivo escrito (ui_align_motivo)
- **OPACO_FORA** x1
  - `ui/anim_sprite.gd` @Sprite2D [cartao_clique_fecha] opaco sai de 640x360: [-454.0,223.0 14.0x14.0]

### ui/balao.gd  (26)
- **IGNORE_SEM_MOTIVO** x2 (ignore em linhas 184)
  - `ui/balao.gd` @Control/@Control [f6a_abertura_b1] ignore sem motivo escrito (ui_align_motivo)
  - `ui/balao.gd` Fluxo/@Control/Balao/@Control [f8a1_james_first_1] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x24 (ignore em linhas 184)
  - `ui/balao.gd` @Control/@Control [f6a_abertura_b1] ignore engole 2 botão/texto fixo: Label "chegou outro avi", Label "osmar"
  - `ui/balao.gd` @Control/@Control [f6a_abertura_b2] ignore engole 2 botão/texto fixo: Label "ainda formo camp", Label "osmar"
  - `ui/balao.gd` @Control/@Control [f6a_abertura_b3] ignore engole 3 botão/texto fixo: Label "o muralha riu da", Label "escola: nenhuma.", Label "john"
  - `ui/balao.gd` @Control/@Control [f6a_abertura_b4] ignore engole 2 botão/texto fixo: Label "vou botar um nom", Label "john"
  - `ui/balao.gd` @Control/@Control [f6a_osmar_2l] ignore engole 3 botão/texto fixo: Label "o aviso saiu da ", Label "ainda é nossa, v", Label "osmar"
  - `ui/balao.gd` @Control/@Control [f6a_osmar_borda] ignore engole 3 botão/texto fixo: Label "abcdefghijklmnop", Label "abcdefghijklmnop", Label "osmar"
  - `ui/balao.gd` @Control/@Control [f6a_pergunta] ignore engole 2 botão/texto fixo: Label "tem pergunta, os", Label "john"
  - `ui/balao.gd` @Control/@Control [f6b1_s8] ignore engole 2 botão/texto fixo: Label "vamos ver sua gu", Label "john"
  - `ui/balao.gd` @Control/@Control [f6b1_s10] ignore engole 2 botão/texto fixo: Label "isso.", Label "john"
  - `ui/balao.gd` @Control/@Control [f6b2_mentor2_balao_osmar] ignore engole 3 botão/texto fixo: Label "chegou outro avi", Label "ainda é nossa, v", Label "osmar"
  - `ui/balao.gd` @Control/@Control [f6c1_academia_balao_osmar] ignore engole 2 botão/texto fixo: Label "agora sim. essa ", Label "osmar"
  - `ui/balao.gd` @Control/@Control [f6c1_saida_gym_J5] ignore engole 2 botão/texto fixo: Label "cuidem bem disso", Label "john"
  - ... mais 12

### ui/balao_convite.gd  (2)
- **TXT_SOZINHO** x2
  - `ui/balao_convite.gd:3` @Control/@Control/@NinePatchRect/@Label "osmar" [f7a2_balao_garagem_spar] sozinho na linha: margem esquerda 3.0, direita 5.0 (Δ=-2.0px)
  - `ui/balao_convite.gd:3` Fluxo/@Control/@Control/@Control/@NinePatchRect/@Label "osmar" [f7a2_panfleto_comeco] sozinho na linha: margem esquerda 3.0, direita 5.0 (Δ=-2.0px)

### ui/barra_baixo.gd  (40)
- **IGNORE_SEM_MOTIVO** x21 (ignore em linhas 56, 58, 61, 62, 73)
  - `ui/barra_baixo.gd` BarraBaixo [garagem_treino] ui_align_row=free sem motivo escrito
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+1" [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "/CLIQUE" [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "CLIQUE NO SACO PARA TREI" [garagem_dica] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+2.16K" [garagem_maximo] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "SALVO" [luta_inicio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+2" [garagem_metronomo] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+3" [garagem_dica_nos] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+6" [f5_gym_boneco_foco] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+4" [f5_previa_kid_revanche] ignore sem motivo escrito (ui_align_motivo)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+8" [f52_loja_l4_sem_dinheiro] ignore sem motivo escrito (ui_align_motivo)
  - ... mais 9
- **IGNORE_PROIBIDO** x19 (ignore em linhas 56, 58, 61, 62, 73)
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+1" [garagem_treino] ignore engole 1 botão/texto fixo: o próprio Label "+1"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "/CLIQUE" [garagem_treino] ignore engole 1 botão/texto fixo: o próprio Label "/CLIQUE"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "CLIQUE NO SACO PARA TREI" [garagem_dica] ignore engole 1 botão/texto fixo: o próprio Label "CLIQUE NO SACO P"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+2.16K" [garagem_maximo] ignore engole 1 botão/texto fixo: o próprio Label "+2.16K"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "SALVO" [luta_inicio] ignore engole 1 botão/texto fixo: o próprio Label "SALVO"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+2" [garagem_metronomo] ignore engole 1 botão/texto fixo: o próprio Label "+2"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+3" [garagem_dica_nos] ignore engole 1 botão/texto fixo: o próprio Label "+3"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+6" [f5_gym_boneco_foco] ignore engole 1 botão/texto fixo: o próprio Label "+6"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+4" [f5_previa_kid_revanche] ignore engole 1 botão/texto fixo: o próprio Label "+4"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+8" [f52_loja_l4_sem_dinheiro] ignore engole 1 botão/texto fixo: o próprio Label "+8"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+16" [f52_loja_grito_compravel] ignore engole 1 botão/texto fixo: o próprio Label "+16"
  - `ui/barra_baixo.gd` BarraBaixo/@Label "+43" [f52_loja_grito_comprado] ignore engole 1 botão/texto fixo: o próprio Label "+43"
  - ... mais 7

### ui/bloco_proxima.gd  (14)
- **IGNORE_SEM_MOTIVO** x1 (ignore em linhas 95)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@Control [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
- **TXT_SOZINHO** x13
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "TREINO X2" [aposentar_cinturao] sozinho na linha: margem esquerda 7.0, direita 64.0 (Δ=-57.0px)
  - `ui/bloco_proxima.gd:387` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "2 LUTAS DA CASA" [aposentar_cinturao] sozinho na linha: margem esquerda 7.0, direita 30.0 (Δ=-23.0px)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "FALTA $1.00K" [aposentar_cinturao] sozinho na linha: margem esquerda 7.0, direita 50.0 (Δ=-43.0px)
  - `ui/bloco_proxima.gd:4` PainelProxima/@Control/@VBoxContainer/@Label "ESPERE FICAR VERDE" [fim_azar] sozinho na linha: margem esquerda 0.0, direita 11.0 (Δ=-11.0px)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "FALTA $700" [f5_mudar_sem_dinheiro] sozinho na linha: margem esquerda 7.0, direita 56.0 (Δ=-49.0px)
  - `ui/bloco_proxima.gd:6` PainelProxima/@Control/@VBoxContainer/@Label "MUDE PARA O CENTRO" [f5_escada_fim] sozinho na linha: margem esquerda 0.0, direita 11.0 (Δ=-11.0px)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Label "SEM LUTA NOVA POR ENQUAN" [f5_escada_fim] sozinho na linha: margem esquerda 0.0, direita 13.0 (Δ=-13.0px)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "TREINO X4" [f5_escada_fim] sozinho na linha: margem esquerda 7.0, direita 64.0 (Δ=-57.0px)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "ALUNOS NOVOS" [f5_escada_fim] sozinho na linha: margem esquerda 7.0, direita 44.0 (Δ=-37.0px)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "FALTA $25.0K" [f5_escada_fim] sozinho na linha: margem esquerda 7.0, direita 48.0 (Δ=-41.0px)
  - `ui/bloco_proxima.gd:191` PainelProxima/@Control/@VBoxContainer/@Label "LIGA REGIONAL DO VALE" [f8a1_previa_bigorna_aggressive] sozinho na linha: margem esquerda 0.0, direita 21.0 (Δ=-21.0px)
  - `ui/bloco_proxima.gd` PainelProxima/@Control/@VBoxContainer/@Control/@Control/@Label "FALTA $15.0K" [f8a2_mudar_faltando] sozinho na linha: margem esquerda 7.0, direita 50.0 (Δ=-43.0px)
  - ... mais 1

### ui/cartao_adversario.gd  (1)
- **IGNORE_SEM_MOTIVO** x1 (ignore em linhas 41)
  - `ui/cartao_adversario.gd` Fluxo/@Control/@Control/CartaoAdversario/@NinePatchRect [f8a1_previa_bigorna_aggressive] ignore sem motivo escrito (ui_align_motivo)

### ui/cartao_passiva.gd  (1)
- **IGNORE_SEM_MOTIVO** x1 (ignore em linhas 56)
  - `ui/cartao_passiva.gd` Fluxo/@Control/@Control/CartaoPassiva/@Control/@NinePatchRect [f5_previa_tonhao] ignore sem motivo escrito (ui_align_motivo)

### ui/cena_ui.gd  (4)
- **IGNORE_SEM_MOTIVO** x2 (ignore em linhas 35, 65)
  - `ui/cena_ui.gd` @Control [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/cena_ui.gd` @Control/@Control [garagem_pos_cinturao] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x1 (ignore em linhas 35, 65)
  - `ui/cena_ui.gd` @Control [garagem_pos_cinturao] ignore engole 3 botão/texto fixo: Button "PULAR", Label "PULAR", Label "SEGURE ESC: PULA"
- **OPACO_FORA** x1
  - `ui/cena_ui.gd` @Control/@Button/@TextureRect [garagem_pos_cinturao] opaco sai de 640x360: [579.0,337.0 99.0x11.0]

### ui/debug_overlay.gd  (2)
- **TXT_SOZINHO** x2
  - `ui/debug_overlay.gd:3` DebugOverlay/@Label "DEPURAÇÃO (F12)" [f12] sozinho na linha: margem esquerda 6.0, direita 65.0 (Δ=-59.0px)
  - `ui/debug_overlay.gd` DebugOverlay/@Label "FPS 29  SALVO 11:49:55" [f12] sozinho na linha: margem esquerda 6.0, direita 33.0 (Δ=-27.0px)

### ui/dica.gd  (38)
- **IGNORE_SEM_MOTIVO** x1 (ignore em linhas 33)
  - `ui/dica.gd` @Control [b4_info_aparelho] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x37 (ignore em linhas 33)
  - `ui/dica.gd` @Control [b4_info_aparelho] ignore engole 6 botão/texto fixo: Label "ESTEIRA ENFERRUJ", Label "GIRA, GEME E CHE", Label "FERRUGEM. MAS CO"
  - `ui/dica.gd` @Control [b4_assist_botao] ignore engole 2 botão/texto fixo: Label "SEGURE SHIFT OU ", Label "PARA TREINO ASSI"
  - `ui/dica.gd` @Control [f51_hover_fama] ignore engole 3 botão/texto fixo: Label "FAMA", Label "O NOME QUE CORRE", Label "12"
  - `ui/dica.gd` @Control [f51_hover_legado] ignore engole 5 botão/texto fixo: Label "LEGADO EM JOGO", Label "VIRA PERMANENTE ", Label "O POSTO."
  - `ui/dica.gd` @Control [f51_hover_local] ignore engole 4 botão/texto fixo: Label "UMA LÂMPADA, UM ", Label "COBERTO DE LONA ", Label "QUE JÁ APANHOU M"
  - `ui/dica.gd` @Control [f51_hover_proxima] ignore engole 1 botão/texto fixo: Label "$50 + 10 FAMA"
  - `ui/dica.gd` @Control [f51_hover_teclas] ignore engole 3 botão/texto fixo: Label "ESPAÇO TREINA SH", Label "1-4 FOCO F11 TEL", Label "L LOJA E EQUIPE "
  - `ui/dica.gd` @Control [f51_hover_atributo] ignore engole 3 botão/texto fixo: Label "AGILIDADE", Label "AGILIDADE: GOLPE", Label "CORPO QUE SAI DA"
  - `ui/dica.gd` @Control [f51_loja_trancado] ignore engole 1 botão/texto fixo: Label "COMPRE A ESTEIRA"
  - `ui/dica.gd` @Control [f51_hover_foco] ignore engole 2 botão/texto fixo: Label "CORDA", Label "DEPOIS DA ESTEIR"
  - `ui/dica.gd` @Control [f51_caixa_hover] ignore engole 3 botão/texto fixo: Label "ESTEIRA", Label "PESADO", Label "NA CAIXA: CLIQUE"
  - `ui/dica.gd` @Control [f52_loja_grito_hover] ignore engole 5 botão/texto fixo: Label "GRITO DA EQUIPE", Label "CADA CLIQUE SEU ", Label "EQUIPE."
  - ... mais 25

### ui/faixa_assistido.gd  (4)
- **IGNORE_SEM_MOTIVO** x1 (ignore em linhas 50)
  - `ui/faixa_assistido.gd` FaixaAssistido [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x3 (ignore em linhas 50)
  - `ui/faixa_assistido.gd` FaixaAssistido [garagem_treino] ignore engole 1 botão/texto fixo: Button ""
  - `ui/faixa_assistido.gd` FaixaAssistido [b4_assist_dica] ignore engole 2 botão/texto fixo: Button "", Label "DICA: SEGURE SHI"
  - `ui/faixa_assistido.gd` FaixaAssistido [b4_assist_socando] ignore engole 2 botão/texto fixo: Button "", Label "ASSISTIDO"

### ui/hud.gd  (250)
- **IGNORE_SEM_MOTIVO** x125 (ignore em linhas 41, 67, 221, 230, 259)
  - `ui/hud.gd` Hud/@Label "1.25K" [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Control [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "16" [garagem_dica] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "987T" [garagem_numeros_grandes] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "1.24K" [previa_aggressive] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "1.23K" [cinturao] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "1.28K" [garagem_metronomo] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "1.26K" [garagem_loja_metronomo_max] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "1.27K" [garagem_dica_nos] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "616" [b4_esteira_compravel] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "2.01K" [b4_corda_compravel] ignore sem motivo escrito (ui_align_motivo)
  - `ui/hud.gd` Hud/@Label "116" [b4_corda_sem_treino] ignore sem motivo escrito (ui_align_motivo)
  - ... mais 113
- **IGNORE_PROIBIDO** x125 (ignore em linhas 41, 67, 221, 230, 259)
  - `ui/hud.gd` Hud/@Label "1.25K" [garagem_treino] ignore engole 1 botão/texto fixo: o próprio Label "1.25K"
  - `ui/hud.gd` Hud/@Label "16" [garagem_dica] ignore engole 1 botão/texto fixo: o próprio Label "16"
  - `ui/hud.gd` Hud/@Label "987T" [garagem_numeros_grandes] ignore engole 1 botão/texto fixo: o próprio Label "987T"
  - `ui/hud.gd` Hud/@Label "1.24K" [previa_aggressive] ignore engole 1 botão/texto fixo: o próprio Label "1.24K"
  - `ui/hud.gd` Hud/@Label "1.23K" [cinturao] ignore engole 1 botão/texto fixo: o próprio Label "1.23K"
  - `ui/hud.gd` Hud/@Label "1.28K" [garagem_metronomo] ignore engole 1 botão/texto fixo: o próprio Label "1.28K"
  - `ui/hud.gd` Hud/@Label "1.26K" [garagem_loja_metronomo_max] ignore engole 1 botão/texto fixo: o próprio Label "1.26K"
  - `ui/hud.gd` Hud/@Label "1.27K" [garagem_dica_nos] ignore engole 1 botão/texto fixo: o próprio Label "1.27K"
  - `ui/hud.gd` Hud/@Control [garagem_dica_nos] ignore engole 11 botão/texto fixo: Label "NOVATO: O QUE VO", Label "+100% TREINO POR", Label "COMEÇA COM O MET
  - `ui/hud.gd` Hud/@Label "616" [b4_esteira_compravel] ignore engole 1 botão/texto fixo: o próprio Label "616"
  - `ui/hud.gd` Hud/@Label "2.01K" [b4_corda_compravel] ignore engole 1 botão/texto fixo: o próprio Label "2.01K"
  - `ui/hud.gd` Hud/@Label "116" [b4_corda_sem_treino] ignore engole 1 botão/texto fixo: o próprio Label "116"
  - ... mais 113

### ui/janela_arte.gd  (23)
- **IGNORE_SEM_MOTIVO** x6 (ignore em linhas 54, 163, 169, 203, 229, 244, 268, 276)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control [f5_arte_primeira] ui_align_row=free sem motivo escrito
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f5_arte_primeira] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect/@ColorRect [f5_arte_primeira] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect/@TextureRect [f5_arte_primeira] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@Button [f5_arte_primeira] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect/@NinePatchRect [f5_arte_primeira] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x13 (ignore em linhas 54, 163, 169, 203, 229, 244, 268, 276)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f5_arte_primeira] ignore engole 2 botão/texto fixo: Label "MÃO RÁPIDA", Label "SOCA MAIS RÁPIDO"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@Button [f5_arte_primeira] ignore engole 1 botão/texto fixo: o próprio Button
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f5_arte_primeira] ignore engole 2 botão/texto fixo: Label "CONTRAGOLPISTA", Label "0/3 K.O. DE EMBA"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f5_arte_primeira] ignore engole 2 botão/texto fixo: Label "FINALIZAÇÃO", Label "FINALIZAÇÃO: SOC"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f5_arte_primeira] ignore engole 2 botão/texto fixo: Label "POR CIMA", Label "0/3 FINALIZAÇÕES"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f7b1_arte_3cartoes] ignore engole 2 botão/texto fixo: Label "CANELA", Label "CANELA: CHUTE BA"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f7b1_arte_3cartoes] ignore engole 2 botão/texto fixo: Label "CLINCH", Label "0/3 CHUTES RODAD"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f7b2_arte_2de3] ignore engole 2 botão/texto fixo: Label "CONTRAGOLPISTA", Label "2/3 K.O. DE EMBA"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f7b2_arte_2de3] ignore engole 2 botão/texto fixo: Label "POR CIMA", Label "1/3 FINALIZAÇÕES"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f7b2_arte_2de3] ignore engole 2 botão/texto fixo: Label "CLINCH", Label "2/3 CHUTES RODAD"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f7b2_arte_liberada] ignore engole 2 botão/texto fixo: Label "POR CIMA", Label "DERRUBA CEDO E C"
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@Control/@ColorRect [f7b2_arte_selecionada] ignore engole 2 botão/texto fixo: Label "CONTRAGOLPISTA", Label "GUARDA ALTA: ESQ"
  - ... mais 1
- **JANELA_ASSIM** x4
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@NinePatchRect [f5_arte_primeira] margem da tela: esquerda 124.0, direita 326.0 (Δ=-202.0px)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@NinePatchRect [f5_arte_primeira] margem da tela: esquerda 326.0, direita 124.0 (Δ=202.0px)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@NinePatchRect [f7b1_arte_3cartoes] margem da tela: esquerda 29.0, direita 421.0 (Δ=-392.0px)
  - `ui/janela_arte.gd` Fluxo/@Control/@Control/@Control/@NinePatchRect [f7b1_arte_3cartoes] margem da tela: esquerda 421.0, direita 29.0 (Δ=392.0px)

### ui/janela_fim.gd  (1)
- **IGNORE_SEM_MOTIVO** x1 (ignore em linhas 235, 236)
  - `ui/janela_fim.gd` Fluxo/@Control/@Control [fim_derrota] ui_align_row=free sem motivo escrito

### ui/janela_mapa.gd  (35)
- **IGNORE_SEM_MOTIVO** x2 (ignore em linhas 116, 1033)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_mapa_inicio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Label "-15" [f54_revelacao] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x14 (ignore em linhas 116, 1033)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_mapa_inicio] ignore engole 2 botão/texto fixo: Label "10", Label "10"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_mapa_meio] ignore engole 18 botão/texto fixo: Label "500", Label "800", Label "500"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_mapa_completo] ignore engole 8 botão/texto fixo: Label "GARAGEM", Label "ACADEMIA", Label "BOXE"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_cartao_grito_sem_loja] ignore engole 19 botão/texto fixo: Label "500", Label "800", Label "500"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_revelacao] ignore engole 7 botão/texto fixo: Label "30", Label "150", Label "25"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Label "-15" [f54_revelacao] ignore engole 1 botão/texto fixo: o próprio Label "-15"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_revelacao_fim] ignore engole 9 botão/texto fixo: Label "30", Label "150", Label "25"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f54_save_antigo] ignore engole 10 botão/texto fixo: Label "15", Label "20", Label "150"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f6d_balao_mapa] ignore engole 8 botão/texto fixo: Label "30", Label "150", Label "25"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f7b1_arvore_mt] ignore engole 17 botão/texto fixo: Label "30", Label "150", Label "10"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f8a2_mapa_centro_fechado] ignore engole 19 botão/texto fixo: Label "30", Label "150", Label "10"
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/@Control/@Control [f8a2_mapa_centro_aberto] ignore engole 22 botão/texto fixo: Label "30", Label "150", Label "10"
  - ... mais 2
- **TXT_SOZINHO** x19
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "CORDA MONTADA" [f54_cartao_compravel] sozinho na linha: margem esquerda 7.0, direita 94.0 (Δ=-87.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "O VARAL AGORA É SEU. A V" [f54_cartao_compravel] sozinho na linha: margem esquerda 7.0, direita 48.0 (Δ=-41.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "COMEÇA A CAMPANHA COM A " [f54_cartao_compravel] sozinho na linha: margem esquerda 7.0, direita 36.0 (Δ=-29.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "MÃO PESADA" [f54_cartao_sem_legado] sozinho na linha: margem esquerda 7.0, direita 112.0 (Δ=-105.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "SOCO COM O PESO DE QUEM " [f54_cartao_sem_legado] sozinho na linha: margem esquerda 7.0, direita 22.0 (Δ=-15.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "+50% TREINO POR CLIQUE" [f54_cartao_sem_legado] sozinho na linha: margem esquerda 7.0, direita 48.0 (Δ=-41.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "CONTRAGOLPE" [f54_cartao_arte] sozinho na linha: margem esquerda 7.0, direita 104.0 (Δ=-97.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "ELE ERRA, VOCÊ NÃO PERDO" [f54_cartao_arte] sozinho na linha: margem esquerda 7.0, direita 29.0 (Δ=-22.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "BOXE: CHANCE DE K.O. +50" [f54_cartao_arte] sozinho na linha: margem esquerda 7.0, direita 40.0 (Δ=-33.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "SÓ VALE JOGANDO DE BOXE" [f54_cartao_arte] sozinho na linha: margem esquerda 7.0, direita 40.0 (Δ=-33.0px)
  - `ui/janela_mapa.gd` Fluxo/@Control/@Control/CartaoNo/@Label "GRITO MAIS ALTO" [f54_cartao_grito_sem_loja] sozinho na linha: margem esquerda 7.0, direita 88.0 (Δ=-81.0px)
  - `ui/janela_mapa.gd:877` Fluxo/@Control/@Control/CartaoNo/@Label "GRITO DA EQUIPE: CADA CL" [f54_cartao_grito_sem_loja] sozinho na linha: margem esquerda 7.0, direita 16.0 (Δ=-9.0px)
  - ... mais 7

### ui/janela_mural.gd  (46)
- **IGNORE_SEM_MOTIVO** x39 (ignore em linhas 115, 128, 157, 162, 308)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/MuralVazio "AINDA NINGUÉM PASSOU O P" [f6c2_tela_mural_vazio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_box/Hover [f6c2_tela_mural_vazio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_fund/Hover [f6c2_tela_mural_vazio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_notes/Hover [f6c2_tela_mural_vazio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_crew/Hover [f6c2_tela_mural_vazio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_glove/Hover [f6c2_tela_mural_vazio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_wall/Hover [f6c2_tela_mural_vazio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/Retrato_1/@TextureRect/@TextureRect [f6c2_tela_mural_1] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/Retrato_1/Selo [f6c2_tela_mural_1] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/Retrato_2/@TextureRect/@TextureRect [f6c2_tela_mural_4] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/Retrato_3/@TextureRect/@TextureRect [f6c2_tela_mural_4] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/Retrato_4/@TextureRect/@TextureRect [f6c2_tela_mural_4] ignore sem motivo escrito (ui_align_motivo)
  - ... mais 27
- **IGNORE_PROIBIDO** x3 (ignore em linhas 115, 128, 157, 162, 308)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/MuralVazio "AINDA NINGUÉM PASSOU O P" [f6c2_tela_mural_vazio] ignore engole 1 botão/texto fixo: o próprio Label "AINDA NINGUÉM PA"
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/@Label "1/3" [f6c2_tela_mural_30] ignore engole 1 botão/texto fixo: o próprio Label "1/3"
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/@Label "3/3" [f6c2_tela_mural_30_ultima] ignore engole 1 botão/texto fixo: o próprio Label "3/3"
- **TXT_SOZINHO** x4
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_box/@Label "MENOS" [f6c2_tela_mural_vazio] sozinho na linha: margem esquerda 20.0, direita 122.0 (Δ=-102.0px)
  - `ui/janela_mural.gd:294` Fluxo/@Control/@Control/@Control/No_hall_notes/@Label "FALTA" [f6c2_tela_mural_vazio] sozinho na linha: margem esquerda 20.0, direita 122.0 (Δ=-102.0px)
  - `ui/janela_mural.gd` Fluxo/@Control/@Control/@Control/No_hall_glove/@Label "CALÇADA" [f6c2_tela_mural_vazio] sozinho na linha: margem esquerda 20.0, direita 110.0 (Δ=-90.0px)
  - `ui/janela_mural.gd:3` Fluxo/@Control/@Control/@Control/No_hall_wall/@Label "BÔNUS" [f6c2_tela_mural_vazio] sozinho na linha: margem esquerda 20.0, direita 122.0 (Δ=-102.0px)

### ui/janela_vitoria.gd  (2)
- **IGNORE_SEM_MOTIVO** x2 (ignore em linhas 99, 126, 181, 304, 325)
  - `ui/janela_vitoria.gd` Fluxo/@Control/@Control/@TextureRect [cinturao] ignore sem motivo escrito (ui_align_motivo)
  - `ui/janela_vitoria.gd` Fluxo/@Control/@Control/@ColorRect [f7b2_fim_libera] ignore sem motivo escrito (ui_align_motivo)

### ui/painel_atributos.gd  (1)
- **IGNORE_SEM_MOTIVO** x1 (ignore em linhas 42)
  - `ui/painel_atributos.gd` PainelAtributos/@Control [garagem_treino] ignore sem motivo escrito (ui_align_motivo)

### ui/painel_loja.gd  (52)
- **IGNORE_SEM_MOTIVO** x15 (ignore em linhas 138, 169, 229, 275, 279, 284, 424, 499)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Control [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "3" [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Alca/@ReferenceRect [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Alca/@Button [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Button/@ReferenceRect [garagem_loja] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control [garagem_loja] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "2" [garagem_maximo] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Button/@Label "!" [garagem_numeros_grandes] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "4" [garagem_numeros_grandes] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "1" [vitoria] ignore sem motivo escrito (ui_align_motivo)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Button/@ReferenceRect [b4_tres_aparelhos] ignore sem motivo escrito (ui_align_motivo)
  - ... mais 3
- **IGNORE_PROIBIDO** x9 (ignore em linhas 138, 169, 229, 275, 279, 284, 424, 499)
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "3" [garagem_treino] ignore engole 1 botão/texto fixo: o próprio Label "3"
  - `ui/painel_loja.gd` PainelLoja/Alca/@Button [garagem_treino] ignore engole 1 botão/texto fixo: o próprio Button
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "2" [garagem_maximo] ignore engole 1 botão/texto fixo: o próprio Label "2"
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Button/@Label "!" [garagem_numeros_grandes] ignore engole 1 botão/texto fixo: o próprio Label "!"
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "4" [garagem_numeros_grandes] ignore engole 1 botão/texto fixo: o próprio Label "4"
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "1" [vitoria] ignore engole 1 botão/texto fixo: o próprio Label "1"
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "5" [f5_gym_boxe_marca] ignore engole 1 botão/texto fixo: o próprio Label "5"
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "6" [f8a2_mudar_faltando] ignore engole 1 botão/texto fixo: o próprio Label "6"
  - `ui/painel_loja.gd` PainelLoja/Alca/@Label "7" [f8a2_chegada] ignore engole 1 botão/texto fixo: o próprio Label "7"
- **TXT_SOZINHO** x28
  - `ui/painel_loja.gd:4` PainelLoja/Corpo/@Control/@Control/@Label "EQUIPE" [garagem_treino] sozinho na linha: margem esquerda 8.0, direita 87.0 (Δ=-79.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Label "VIZINHO DA CASA 12" [garagem_treino] sozinho na linha: margem esquerda 5.0, direita 20.0 (Δ=-15.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Label "TIO APOSENTADO" [garagem_treino] sozinho na linha: margem esquerda 5.0, direita 36.0 (Δ=-31.0px)
  - `ui/painel_loja.gd:4` PainelLoja/Corpo/@Control/@Control/@Label "MELHORIAS" [garagem_treino] sozinho na linha: margem esquerda 8.0, direita 69.0 (Δ=-61.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Label "CORDA" [garagem_treino] sozinho na linha: margem esquerda 6.0, direita 85.0 (Δ=-79.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Label "+25/S" [garagem_loja] sozinho na linha: margem esquerda 26.0, direita 65.0 (Δ=-39.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Label "FALTA $1.38K" [garagem_loja] sozinho na linha: margem esquerda 10.0, direita 47.0 (Δ=-37.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Label "X2" [garagem_loja] sozinho na linha: margem esquerda 26.0, direita 83.0 (Δ=-57.0px)
  - `ui/painel_loja.gd:571` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Label "1 SOCO A CADA 1.2 S" [garagem_loja] sozinho na linha: margem esquerda 10.0, direita 15.0 (Δ=-5.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Label "FALTA $1.40K" [garagem_loja_metronomo] sozinho na linha: margem esquerda 10.0, direita 47.0 (Δ=-37.0px)
  - `ui/painel_loja.gd` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Label "FALTA $20" [garagem_loja_metronomo] sozinho na linha: margem esquerda 10.0, direita 59.0 (Δ=-49.0px)
  - `ui/painel_loja.gd:571` PainelLoja/Corpo/@Control/@Control/@Control/@Control/@Label "1 SOCO A CADA 0.9 S" [garagem_loja_metronomo] sozinho na linha: margem esquerda 10.0, direita 13.0 (Δ=-3.0px)
  - ... mais 16

### ui/pular_abertura.gd  (1)
- **TXT_SOZINHO** x1
  - `ui/pular_abertura.gd:26` @Control/@Label "SEGURE ESC: PULAR" [f54_save_antigo] sozinho na linha: margem esquerda 19.0, direita 6.0 (Δ=13.0px)

### ui/sala.gd  (21)
- **IGNORE_SEM_MOTIVO** x2 (ignore em linhas 979, 1946, 2008, 2053)
  - `ui/sala.gd` Sala [garagem_treino] ignore sem motivo escrito (ui_align_motivo)
  - `ui/sala.gd` Sala/@TextureRect [f7a2_recorte_garagem] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x19 (ignore em linhas 979, 1946, 2008, 2053)
  - `ui/sala.gd` Sala [garagem_metronomo] ignore engole 1 botão/texto fixo: Label "+2"
  - `ui/sala.gd` Sala [garagem_loja_metronomo_max] ignore engole 1 botão/texto fixo: Label "+1"
  - `ui/sala.gd` Sala [b4_chegada_esteira_poeira] ignore engole 3 botão/texto fixo: Label "TOC!", Label "RACHOU!", Label "ABRIU!"
  - `ui/sala.gd` Sala [b4_assist_esperando] ignore engole 1 botão/texto fixo: Label "+1 FORÇA"
  - `ui/sala.gd` Sala [f5_gym_pera_clique] ignore engole 2 botão/texto fixo: Label "+1 AGILIDADE", Label "+1 FORÇA"
  - `ui/sala.gd` Sala [f51_caixa_1] ignore engole 1 botão/texto fixo: Label "TOC!"
  - `ui/sala.gd` Sala [f51_caixa_2] ignore engole 2 botão/texto fixo: Label "TOC!", Label "RACHOU!"
  - `ui/sala.gd` Sala [f51_caixa_abrindo] ignore engole 2 botão/texto fixo: Label "RACHOU!", Label "ABRIU!"
  - `ui/sala.gd` Sala [f51_caixa_luva_aberta] ignore engole 3 botão/texto fixo: Label "ABRIU!", Label "TOC!", Label "RACHOU!"
  - `ui/sala.gd` Sala [f51_anim_saco] ignore engole 4 botão/texto fixo: Label "+1 FORÇA", Label "+1 FORÇA", Label "+1 FORÇA"
  - `ui/sala.gd` Sala [f51_anim_esteira] ignore engole 2 botão/texto fixo: Label "+3 RESISTÊNCIA!", Label "A ESTEIRA GEMEU!"
  - `ui/sala.gd` Sala [f52_bolsa_toast] ignore engole 1 botão/texto fixo: Label "BOLSA DA TORCIDA"
  - ... mais 7

### ui/tela_choque.gd  (18)
- **IGNORE_SEM_MOTIVO** x4 (ignore em linhas 151, 198, 221, 234)
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_boxe_comeco] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_choque.gd` Fluxo/@Control/@Control/@Node2D [f7a2_choque_boxe_comeco] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_choque.gd` Fluxo/@Control/@Control/@Control [f7a2_choque_boxe_comeco] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_choque.gd` Fluxo/@Control/@Control/@ColorRect [f7b1_choque_mt_comeco] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x14 (ignore em linhas 151, 198, 221, 234)
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_boxe_rajada] ignore engole 3 botão/texto fixo: Label "RAJADA!", Label "ELE ENCOSTOU", Label "ELE ENCOSTOU"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_boxe_pausa] ignore engole 1 botão/texto fixo: Label "ELE ENCOSTOU"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_boxe_finta] ignore engole 5 botão/texto fixo: Label "RAJADA!", Label "ELE ENCOSTOU", Label "ELE ENCOSTOU"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_boxe_folego] ignore engole 1 botão/texto fixo: Label "RAJADA!"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_boxe_ponto] ignore engole 1 botão/texto fixo: Label "ENCOSTOU!"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_boxe_premio] ignore engole 5 botão/texto fixo: Label "ELE ENCOSTOU", Label "ELE ENCOSTOU", Label "ELE ENCOSTOU"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_jj_rajada] ignore engole 2 botão/texto fixo: Label "PUXADA!", Label "ELE ENCOSTOU"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_jj_finta] ignore engole 3 botão/texto fixo: Label "PUXADA!", Label "ELE ENCOSTOU", Label "ELE ENCOSTOU"
  - `ui/tela_choque.gd` Fluxo/@Control/@Node2D [f7a2_choque_jj_premio] ignore engole 4 botão/texto fixo: Label "ELE ENCOSTOU", Label "ELE ENCOSTOU", Label "ELE ENCOSTOU"
  - `ui/tela_choque.gd` Fluxo/@Control/@Control/@ColorRect [f7b1_choque_mt_comeco] ignore engole 1 botão/texto fixo: Label "1"
  - `ui/tela_choque.gd` Fluxo/@Control/@Control/@ColorRect [f7b1_choque_mt_comeco] ignore engole 1 botão/texto fixo: Label "2"
  - `ui/tela_choque.gd` Fluxo/@Control/@Control/@ColorRect [f7b1_choque_mt_comeco] ignore engole 1 botão/texto fixo: Label "CHUTE"
  - ... mais 2

### ui/tela_criar_discipulo.gd  (22)
- **IGNORE_SEM_MOTIVO** x4 (ignore em linhas 69, 100, 121, 167, 173)
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@Panel [f6b1_s5] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@Panel/@LineEdit [f6b1_s5] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@Control [f6b1_s5] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x18 (ignore em linhas 69, 100, 121, 167, 173)
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore engole 1 botão/texto fixo: Label "5/5"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore engole 1 botão/texto fixo: Label "VOLUME"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore engole 1 botão/texto fixo: Label "5/6"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore engole 1 botão/texto fixo: Label "SEM"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore engole 1 botão/texto fixo: Label "3/6"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@Control [f6b1_s5] ignore engole 16 botão/texto fixo: Button "<", Button ">", Button "<"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore engole 1 botão/texto fixo: Label "CAMISETA"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_s5] ignore engole 1 botão/texto fixo: Label "COM"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_criar] ignore engole 1 botão/texto fixo: Label "3/5"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_criar] ignore engole 1 botão/texto fixo: Label "RASPADO"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_criar] ignore engole 1 botão/texto fixo: Label "4/6"
  - `ui/tela_criar_discipulo.gd` Fluxo/@Control/@Control/@NinePatchRect [f6b1_criar] ignore engole 1 botão/texto fixo: Label "2/6"
  - ... mais 6

### ui/tela_luta.gd  (31)
- **IGNORE_SEM_MOTIVO** x2 (ignore em linhas 239, 269, 389, 401, 428, 442)
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [luta_inicio] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D/@Sprite2D [f7b2_luta_cp_ko_liga] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x29 (ignore em linhas 239, 269, 389, 401, 428, 442)
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [luta_meio] ignore engole 3 botão/texto fixo: Label "4.17K", Label "676", Label "5.05K"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [luta_fim_pontos] ignore engole 16 botão/texto fixo: Label "730", Label "ESQUIVOU", Label "1.40K!"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [luta_numeros] ignore engole 7 botão/texto fixo: Label "4.17K", Label "676", Label "5.05K"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7a1_luta_boxe_cansado] ignore engole 2 botão/texto fixo: Label "2.40M!", Label "1.33M"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7a1_luta_boxe_defensivo] ignore engole 1 botão/texto fixo: Label "625K"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7a1_luta_jj_chao] ignore engole 1 botão/texto fixo: Label "PEGADA!"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7a1_fim_derrota_arena] ignore engole 16 botão/texto fixo: Label "1.15M", Label "ESQUIVOU", Label "2.15M!"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7a1_fim_nota_jj] ignore engole 16 botão/texto fixo: Label "736K", Label "818K", Label "843K"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7b1_luta_mt_marcas] ignore engole 8 botão/texto fixo: Label "836K", Label "1.00M", Label "653K"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7b1_luta_mt_cheia] ignore engole 11 botão/texto fixo: Label "836K", Label "1.00M", Label "653K"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7b1_luta_mt_rodado_liga] ignore engole 9 botão/texto fixo: Label "ESQUIVOU", Label "ESQUIVOU", Label "775K!"
  - `ui/tela_luta.gd` Fluxo/@Control/@Node2D [f7b1_luta_mt_rodado_borracharia] ignore engole 9 botão/texto fixo: Label "169K", Label "91.7K", Label "81.8K"
  - ... mais 17

### ui/tela_panfleto.gd  (3)
- **IGNORE_SEM_MOTIVO** x1
  - `ui/tela_panfleto.gd` Fluxo/@Control/@Node2D [f7a2_panfleto_comeco] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x2
  - `ui/tela_panfleto.gd` Fluxo/@Control/@Node2D [f7a2_panfleto_aceitou] ignore engole 2 botão/texto fixo: Label "ACEITOU!", Label "QUANTO É A MENSA"
  - `ui/tela_panfleto.gd` Fluxo/@Control/@Node2D [f7a2_panfleto_erro] ignore engole 2 botão/texto fixo: Label "NÃO, VALEU", Label "DEPOIS EU VEJO"

### ui/tela_ronda.gd  (3)
- **IGNORE_SEM_MOTIVO** x2 (ignore em linhas 122, 165)
  - `ui/tela_ronda.gd` Fluxo/@Control/@Node2D [ronda_contagem] ignore sem motivo escrito (ui_align_motivo)
  - `ui/tela_ronda.gd` Fluxo/@Control/@Node2D/@Control [ronda_contagem] ignore sem motivo escrito (ui_align_motivo)
- **IGNORE_PROIBIDO** x1 (ignore em linhas 122, 165)
  - `ui/tela_ronda.gd` Fluxo/@Control/@Node2D [ronda_aviso] ignore engole 1 botão/texto fixo: Label "SOLTE!"
