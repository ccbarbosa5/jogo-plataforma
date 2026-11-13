# Ryker Vale — sprites v0.4 (ART) · PROVISÓRIOS, visual de campeão

> **D-039:** a versão final do Ryker vai ser gerada por IA (pacotes em `ART/prompts/`) e tratada pela ART com `ferramentas/arte/tratar_ia.py`. Estes sprites são a **versão provisória** (D-043: ficam na `main` até as finais chegarem). **A especificação abaixo (quadros, origem, deslocamentos, nomes) vale também para a versão final**, então o código feito para estes arquivos continua servindo.

**Mudanças desde a v0.2 (ninguém ligou as folhas nas cenas ainda, então nada quebra):**
- o tronco e o corpo inteiro passaram de 32 para **48×48** (as armas reais não cabiam em 32);
- a carabina provisória virou a **Mordida**, e entrou o **Bramido** (D-041);
- cada folha de tronco ganhou um **4º quadro**, o disparo do modo especial.

## Regras gerais
- **Desenhado olhando para a direita.** Para a esquerda, use `flip_h`.
- **Duas partes (D-033):** um nó de **pernas** e, por cima, um nó de **tronco**. O tronco troca pela direção da mira e pela arma equipada; as pernas, pelo movimento.
- Corpo desenhado com ~14×28 px, igual à hitbox de 12×28 (12×18 agachado).

| Tipo de folha | Quadro | Origem (pés) | `offset` com `centered = true` |
|---|---|---|---|
| Pernas | 32×32 | (16, 32) | `Vector2(0, -16)` |
| Tronco e corpo inteiro | **48×48** | (24, 48) | `Vector2(0, -24)` |

Como os dois têm a origem nos pés, basta pôr os dois nós na mesma posição.

## Pernas
| Arquivo | Quadros | Velocidade sugerida | Deslocamento do tronco por quadro (px para baixo) |
|---|---|---|---|
| `ryker_pernas_parado.png` | 1 | — | 0 |
| `ryker_pernas_correr.png` | 8 | 12 qps | 3, 1, 1, 2, 3, 1, 1, 2 |
| `ryker_pernas_pulo.png` | 7: subida 0–1, topo 2, queda 3–4, pouso 5–6 | por estado; pouso a 15 qps | 0, 0, 0, 0, 0, 2, 1 |
| `ryker_pernas_agachado.png` | 1 | — | **10** (o tronco desce 10 px) |
| `ryker_pernas_agachado_andar.png` | 6 | 10 qps | 10 em todos |

O deslocamento existe porque o pé de apoio sempre encosta no chão: o tronco precisa descer junto com o quadril. Basta somar o valor ao `position.y` do nó do tronco no quadro correspondente.

## Tronco (mira × arma)
**5 direções desenhadas**; as outras 3 são as mesmas espelhadas (`flip_h`). **↓ só no ar** (D-043).

| Direção | **Mordida** (arma própria) | **Bramido** (universal Kharn) |
|---|---|---|
| → | `ryker_tronco_frente.png` | `ryker_tronco_bramido_frente.png` |
| ↗ | `ryker_tronco_diag_cima.png` | `ryker_tronco_bramido_diag_cima.png` |
| ↑ | `ryker_tronco_cima.png` | `ryker_tronco_bramido_cima.png` |
| ↘ | `ryker_tronco_diag_baixo.png` | `ryker_tronco_bramido_diag_baixo.png` |
| ↓ (só no ar) | `ryker_tronco_baixo.png` | `ryker_tronco_bramido_baixo.png` |

**4 quadros por folha:**
| Quadro | Mordida | Bramido |
|---|---|---|
| 0 | parado | parado |
| 1 | disparo normal (clarão pequeno) | disparo de **balins** (clarão em leque, recuo de 2 px) |
| 2 | recuo | recuo |
| 3 | disparo em **rajada** (ramo B: 3 clarões em fila) | disparo da **bala de cerco** (ramo A: jato longo e estreito) |

Sequência de tiro: quadro 1 (ou 3, no modo especial) por 1/30 s, quadro 2 por 1/30 s, volta ao 0. No Bramido, use 1/20 s para cada um (o tiro é mais pesado). Os clarões usam laranja, brasa e branco-ciano, nunca a cor AVISO.

Na folha `bramido_baixo`, a boca passa um pouco do quadro, mas essa direção só existe no ar.

## Corpo inteiro (substitui pernas + tronco enquanto toca)
| Arquivo | Quadros | Notas |
|---|---|---|
| `ryker_dash.png` | 4, 20 qps | Rastro de luz âmbar atrás (a âncora). Desenhado com a Mordida; serve para as duas armas. |
| `ryker_morte.png` | 8, 12 qps | O corpo vira poeira âmbar subindo: a âncora puxando para a Eco. O último quadro fica quase vazio. |

## v0.4: visual de campeão (decisão do dono)
O tronco foi redesenhado por código seguindo a referência aprovada: cabelo raspado dos lados, colete laranja aberto mostrando o peito, **ombreira de osso** no ombro da frente, **faixas de luta** nos antebraços e cinto com fivela de osso. **Nomes, quadros, origens e deslocamentos não mudaram**: o código que liga estas folhas continua igual.

## Poses-chave (IA + tratamento, D-039) — referência
`ryker_poses_chave.png`: 8 quadros 48×48, origem nos pés: 0 parado atirando · 1 correndo · 2 pulando · 3 agachado · 4 mirando para cima · 5 esquiva · 6 lançando a corrente · 7 atingido. **São referência para a ART, não sprites de jogo**: reduzidos a 28 px, os detalhes da IA viram ruído. Por isso a ART redesenha os sprites por código seguindo essas poses (e vai usar a 6 e a 7 para o Grilhão e o dano, que ainda não existem).

## Folha de referência aprovada (IA + tratamento, D-039)
`ryker_referencia.png`: 2 quadros 48×48 (frente, perfil), origem nos pés. É o **Ryker campeão** do pacote 01 v2 (pedido do dono): ombreira de osso no ombro direito, faixas de luta, cinto de campeão, colar de dente, marca de ferro no ombro esquerdo. **Não é animação:** é a referência que os sprites provisórios vão seguir na próxima entrega da ART, e a base dos próximos prompts.

## Grilhão e dano (v0.5, por código, seguindo as poses-chave 6 e 7)
Corpo inteiro, quadro 48×48, origem (24, 48), substitui pernas + tronco enquanto toca. Desenhadas com a Mordida; servem também para o Bramido (a arma fica junto ao corpo).

| Arquivo | Quadros | Estado do Grilhão (`grilhao.gd`) | Notas |
|---|---|---|---|
| `ryker_grilhao_lancar.png` | 3, 20 qps, para no último | `LANCANDO` | preparo · arremesso · braço esticado |
| `ryker_grilhao_puxar_se.png` | 2 | `PUXANDO_JOGADOR` | quadro 0 durante a puxada; quadro 1 na chegada (Golpe de Arena) |
| `ryker_grilhao_puxar_inimigo.png` | 3, 15 qps | `PUXANDO_INIMIGO` | braço recolhendo a corrente |
| `ryker_dano.png` | 2, 12 qps | ao levar dano | jogado para trás · recompondo (junto com o piscar de `modulate`) |

**A corrente** entre a mão e o alvo é desenhada pelo jogo: `corrente_elo.png` (4×3, repete na horizontal; use num `Line2D` com `texture_mode = TILE` ou sprites em fila, girando pela direção) e `corrente_ponta.png` (6×6, a manilha quebrada na ponta). Ela sai da mão do braço de trás, que está a ~(+9, -16) da origem no quadro 2 do lançamento.

## Projéteis e ícones
Em `assets/sprites/armas/` (ver o LEIAME de lá).

## Ainda não feito (próximas entregas)
Grilhão (lançar, puxar-se, puxar inimigo), golpe de corrente, granada, saída da cápsula e respiração no parado. Por enquanto, dano = piscar com `modulate`, como o código já faz.
