# Armas — projéteis e ícones v0.3 (ART)

Armas do VS (D-040, D-041): **Mordida** (arma própria do Ryker, rebitadeira de mineração) e **Bramido** (universal Kharn, canhão dos campeões do Clã Kesh). O Ryker segurando cada uma está em `assets/sprites/personagens/ryker/`.

**Cor da Mordida:** o NAR-03 fala em "amarela e preta". Nos sprites ela é **laranja e preta**, porque o amarelo-claro é a cor AVISO, reservada (D-033), e o laranja é a cor do Ryker (D-043).

## Projéteis (`projeteis/`)
Todos desenhados **apontando para a direita**: gire o sprite pela direção do tiro (`rotation = direcao.angle()`). Tiros do jogador não têm contorno, para não se confundirem com os inimigos (que têm).

| Arquivo | Tamanho | Uso |
|---|---|---|
| `rebite.png` | 7×3 | Mordida, tiro normal |
| `rebite_rajada.png` | 10×3 | Mordida no modo rajada (ramo B Rajada): rastro mais longo, cabeça mais clara |
| `golpe_do_campeao.png` | 14×7 | Mordida, Ápice A3 "Grande Arena" (projétil grande) |
| `balim.png` | 3×3 | Bramido, cada balim |
| `bala_cerco.png` | 13×5 | Bramido no modo bala única (ramo A Cerco) |
| `bala_carregada.png` | 16×9 | Bramido, Ápice A3 "Artilharia" (disparo carregado que explode) |

A explosão do disparo carregado e os impactos ficam para a entrega de efeitos.

## Ícones (`icones/`)
| Arquivo | Tamanho | Uso |
|---|---|---|
| `icone_mordida.png` | 32×16 | Arsenal, tela da árvore, HUD |
| `icone_bramido.png` | 48×24 | idem (maior de propósito: é quase do tamanho do Ryker) |

Gerado por `ferramentas/arte/sprites_v02.py`.
