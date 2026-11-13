# Varrek, o Cemitério — tileset e parallax v0.2 (ART)

## `varrek_tileset.png` (128×64, tiles de 16×16)
**Linhas 0 e 1 — terreno de casco (16 tiles).** Feitos para o modo **"Match Sides"** do terrain set do Godot 4. O índice do tile na folha (da esquerda para a direita, linha 0 e depois linha 1) é o número formado pelos vizinhos sólidos:

| Bit | Vizinho |
|---|---|
| 1 | em cima (N) |
| 2 | à direita (L) |
| 4 | embaixo (S) |
| 8 | à esquerda (O) |

Ex.: tile 15 = cercado dos 4 lados (miolo); tile 14 = sem nada em cima (superfície do chão); tile 0 = bloco solto.

**Linha 2:**
| Coluna | Tile |
|---|---|
| 0–2 | Variantes do miolo (grade de ventilação, cabo, placa de casco humano). Sortear para quebrar a repetição. |
| 3–5 | Plataforma fina de antena: esquerda, meio, direita. **Atravessável por baixo** (one-way). A colisão ocupa só os 6 px de cima. |
| 6 | **Argola de ancoragem do Grilhão.** Todo ponto de gancho usa este tile. O destaque laranja indica "isto é para o Ryker". |

**Linha 3 — decoração (sem colisão):** 0 cabo pendurado · 1 e 2 luz de socorro humana (alternar a cada 0,5 s para piscar) · 3 sucata no chão.

O cenário não tem contorno escuro (só os personagens têm): é isso que separa o que é chão do que é perigo.

## Parallax (480×270 cada)
| Arquivo | Fator de rolagem sugerido | Repete na horizontal? |
|---|---|---|
| `varrek_parallax_0_ceu_anel.png` | 0,0 (fixo) | não precisa (céu + anel quebrado dos Antigos) |
| `varrek_parallax_1_cascos_longe.png` | 0,2 | sim, sem emenda (`motion_mirroring = 480`) |
| `varrek_parallax_2_cascos_meio.png` | 0,5 | sim, sem emenda |
| `varrek_parallax_3_primeiro_plano.png` | 1,3, **na frente do jogo** | sim, sem emenda. Só cabos no topo da tela, nunca na faixa de combate. |

Tela de conferência com tudo junto: `assets/sprites/conceito/mockup_v02_varrek.png`.
