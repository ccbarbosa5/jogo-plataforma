# Ryker Vale — sprites v0.2 (ART) · PROVISÓRIOS

> **D-039:** a versão final do Ryker vai ser gerada por IA (pacotes em `ART/prompts/`) e tratada pela ART com `ferramentas/arte/tratar_ia.py`. Estes sprites são a **versão provisória** para tirar os blocos coloridos do protótipo agora. **A especificação técnica abaixo (quadros, origem, deslocamentos, nomes) vale também para a versão final**, então o código feito para estes arquivos continua servindo.

- **Quadro:** 32×32 px. **Origem: nos pés**, no ponto (16, 32) do quadro. Num `Sprite2D`/`AnimatedSprite2D` com `centered = true`, use `offset = Vector2(0, -16)`.
- **Desenhado olhando para a direita.** Para a esquerda, use `flip_h`.
- **Duas partes (D-033):** um nó de **pernas** e, por cima, um nó de **tronco**. O tronco troca pela direção da mira; as pernas, pelo movimento.
- Corpo desenhado com ~14×28 px, igual à hitbox de 12×28 do DEV.
- **A arma é PROVISÓRIA (D-038).** O tronco segura uma carabina genérica no lugar do Rifle da Arena (nome provisório do GD-05). Quando a NAR fechar a arma, só as folhas de tronco mudam. Nomes e tamanhos ficam iguais.

## Pernas
| Arquivo | Quadros | Velocidade sugerida | Deslocamento do tronco por quadro (px para baixo) |
|---|---|---|---|
| `ryker_pernas_parado.png` | 1 | — | 0 |
| `ryker_pernas_correr.png` | 8 | 12 qps | 3, 1, 1, 2, 3, 1, 1, 2 |
| `ryker_pernas_pulo.png` | 7: subida 0–1, topo 2, queda 3–4, pouso 5–6 | por estado; pouso a 15 qps | 0, 0, 0, 0, 0, 2, 1 |
| `ryker_pernas_agachado.png` | 1 | — | **10** (o tronco desce 10 px: hitbox 12×18) |
| `ryker_pernas_agachado_andar.png` | 6 | 10 qps | 10 em todos |

O deslocamento existe porque o pé de apoio sempre encosta no chão: o tronco precisa descer junto com o quadril, senão ele "flutua". Basta somar o valor ao `position.y` do nó do tronco no quadro correspondente.

## Tronco (mira)
5 folhas, uma por direção. As outras 3 direções são as mesmas espelhadas (`flip_h`, porque o código vira o Ryker para o lado da mira).

| Arquivo | Mira | Quadros |
|---|---|---|
| `ryker_tronco_frente.png` | → | 0 = parado, 1 = disparo (clarão), 2 = recuo |
| `ryker_tronco_diag_cima.png` | ↗ | idem |
| `ryker_tronco_cima.png` | ↑ | idem |
| `ryker_tronco_diag_baixo.png` | ↘ | idem |
| `ryker_tronco_baixo.png` | ↓ (só no ar) | idem |

Sequência de tiro: quadro 1 por 1/30 s, quadro 2 por 1/30 s, volta ao 0. O clarão de boca usa laranja e branco-ciano, nunca a cor AVISO.

## Corpo inteiro (substitui pernas + tronco enquanto toca)
| Arquivo | Quadro | Quadros | Notas |
|---|---|---|---|
| `ryker_dash.png` | **48×32**, origem em (32, 32) → `offset = Vector2(-8, -16)` | 4, 20 qps | Rastro de luz âmbar atrás (ligação com a âncora). |
| `ryker_morte.png` | 32×32 | 8, 12 qps | O corpo vira poeira âmbar subindo: a âncora puxando para a Eco. O último quadro fica quase vazio. |

## Ainda não feito (próximas entregas)
Grilhão (lançar, puxar-se, puxar inimigo), golpe de corrente, granada, saída da cápsula e respiração no parado. Por enquanto, dano = piscar com `modulate`, como o código já faz.
