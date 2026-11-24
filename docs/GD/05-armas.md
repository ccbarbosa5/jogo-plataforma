# GD-05 — Armas e árvores de habilidade (v0.2)

Autor: Game Design (GD) · Aprovado na D-040 · Nomes oficiais na D-041 (NAR-03).
Este doc define jogabilidade e números. Nome, origem e falas de cada arma estão no NAR-03.

> ⚠ **Parcialmente substituído pelo GD-07 (D-058) e pelo GD-08:** a árvore de arma por run, as assinaturas (Embalo, Coice), os Pontos de Aprimoramento e a porta/loja de Aprimoramento saíram. Vale aqui o que o GD-07 não substitui (tabela das 6 armas, `peso_disparo`, `fator_efeito`, ideias para as armas futuras).

**Mudanças desde a v0.1:**
- Os nomes oficiais da D-041 entraram no lugar dos provisórios.
- Nova **seção 8, "Mapa para o código"**: cada nó traduzido em `ModificadorArma` (campos e marcadores), atendendo ao pedido do DEV.
- Dados-base do Bramido em unidades do código.
- Os nomes dos ramos e dos nós continuam os da v0.1 (a NAR aprovou).

---

## 1. Regras gerais (D-038)
- **6 armas principais no jogo completo:** 3 próprias (uma por personagem, exclusivas) + 3 universais (desbloqueadas pela história, qualquer personagem usa).
- Antes da run, o jogador **escolhe 1 arma no Arsenal** (com Garrak). Não se troca de arma durante a run.
- **Munição infinita.** Não existem armas pesadas nem armas que caem na fase.
- Cada arma tem **uma assinatura**, uma regra própria que está sempre ativa e que define o jeito de jogar com ela, e uma **mini árvore**.
- Granada, Grilhão (Ferramenta), golpe corpo a corpo, dash e Chamado **não dependem da arma**.

## 2. Mini árvore de habilidades (D-040)

### 2.1 Estrutura
```
          [ARMA + assinatura]
     /            |             \
 Ramo A        Ramo B         Ramo C
 A1 (1 pt)     B1 (1 pt)      C1 (1 pt)
 A2 (2 pt)     B2 (2 pt)      C2 (2 pt)
 A3 ÁPICE (3)  B3 ÁPICE (3)   C3 ÁPICE (3)
```
- **3 ramos com 3 nós cada.** Cada ramo representa **um jeito diferente de usar a arma**, e não só números maiores.
- Dentro de um ramo, os nós são comprados **em ordem** (1 → 2 → 3).
- **Custo:** nó 1 = 1 ponto, nó 2 = 2, Ápice = 3. Um ramo completo custa 6 pontos e a árvore inteira, 18.
- **Só 1 Ápice por run.** Comprar um Ápice tranca os outros dois naquela run.
- **A árvore zera ao fim da run** (morte ou vitória). Na história, só o molde da arma fica guardado (NAR-03).
- A tela da árvore usa sempre a **moldura humana** (D-047).

### 2.2 Pontos de Aprimoramento
| Fonte | Pontos |
|---|---|
| Porta **"Aprimoramento de Arma"** | 1 |
| Chefe vencido (garantido) | 1 |
| Loja Ilo: "Aprimoramento de Arma" (no máximo 1 por loja) | 1 (90 Créditos) |
| Melhoria **Treino com Garrak** (30 Dados, GD-03) | Começa a run com 1 |

- **No máximo 3 portas de Aprimoramento por ato**, nunca na sala 1, com uma garantida até a sala 5 (GD-03, seção 2.6).
- **Pontos esperados:** de 3 a 5 por ato. Uma run completa de 4 atos dá de 12 a 16 pontos, o que nunca completa a árvore (18).
- **No VS:** de 2 a 4 pontos. O Ápice é o "sonho" que puxa o jogador para a próxima run.
- **Os pontos podem ser guardados.** Ao pegar um ponto, a tela da árvore abre (jogo pausado). O jogador gasta na hora ou fecha e guarda. No menu de pausa, a árvore só abre fora de combate.

### 2.3 Como a árvore convive com o slot "Tiro" das facções
- A **árvore muda o comportamento** da arma: cadência, carga, dispersão, perfuração, rajada, recuo.
- A **facção muda o efeito** do acerto: Abalo, Ácido, explosão, divisão, Revelado (GD-06).
- Os nós da árvore **nunca aplicam status de facção**, e os upgrades de facção **nunca mudam cadência, carga ou dispersão**. A única exceção é Calibre Pesado (Kharn, −15% de cadência).

**Dois números por arma (campos novos em `DadosArma`, pedido ao DEV):**
| Campo | Para que serve | Mordida | Bramido |
|---|---|---|---|
| `peso_disparo` | Quantos "tiros" cada disparo vale nos efeitos que contam tiros (ex.: Munição de Clã, "a cada 5 tiros") | 1 | 2,5 |
| `fator_efeito` | Multiplica a **chance** e o **acúmulo** dos efeitos "ao acertar" de cada projétil | 1,0 | 0,35 por balim (1,0 com a Bala de Cerco) |

### 2.4 Assistências (D-017) e a árvore
- **Tiro automático com nós de carga:** a arma carrega sozinha enquanto houver alvo na linha e dispara quando a carga completa.
- **Rajadas:** o tiro automático dispara rajadas completas.
- Nenhum nó exige mira rápida.

## 3. As 6 armas (nomes da D-041)

| # | Arma | Tipo | Dono / origem (NAR-03) | Papel | Assinatura | No VS? |
|---|---|---|---|---|---|---|
| 1 | **Mordida** | Própria | Ryker (rebitadeira de mineração, "o prego do rato") | Tiro rápido e equilibrado, que recompensa não levar dano | **Embalo** (4.1) | ✔ |
| 2 | **Arpão de Titã** | Própria | Caçadora de Titãs (Molde 2) | Disparo único e carregado, que recompensa acertar pontos fracos | **Ferida Aberta:** cada acerto num ponto fraco deixa o próximo acerto ali 30% mais forte (acumula até 3 vezes) | — |
| 3 | **Lança do Vazio** | Própria | Último Lanceiro (Molde 3) | Feixe de média distância que atravessa inimigos, mais estocada corpo a corpo | **Formação:** atravessar 3 ou mais inimigos com um disparo devolve 1 s da recarga do dash | — |
| 4 | **Bramido** | Universal | Kharn, Clã Kesh (canhão do andador de Ur-Kesh) | Explosão de perto, empurrão, controle de espaço | **Coice** (4.2) | ✔ (1ª vitória sobre Ur-Kesh) |
| 5 | **Liquidação** | Universal | Ilo (1ª vitória sobre o Leiloeiro, Ato 2) | Feixe que ricocheteia entre superfícies | **Lucro:** matar com ricochete dá +1 Crédito | — |
| 6 | **Lanterna da Vigília** | Universal | Vigílios (entregue pelo Último Vigia, Ato 4) | Esferas de luz que orbitam e depois perseguem | **Feitiço:** segurar o tiro conjura até 3 esferas; soltar o botão lança todas. **As esferas Revelam** (status do GD-06). | — |

**Código existente:** o Fuzil atual vira a base da Mordida, e a Escopeta, a do Bramido (D-040).

## 4. As 2 armas do VS

### 4.1 Mordida (Ryker)
**Base:** 10 de dano · 8 tiros/s · projétil a 600 px/s (37,5 tiles/s) · duração 1,0 s · sem dispersão · `peso_disparo` 1 · `fator_efeito` 1,0.

**Assinatura — Embalo** (o show do gladiador que não se machuca):
- Cada acerto dá **+1 de Embalo** (até 20). Cada ponto dá **+1,25% de cadência**, então 20 pontos dão **+25%**.
- Levar dano zera o Embalo. Ficar 1,5 s sem acertar nada faz o Embalo cair, a 5 pontos/s.
- No HUD, uma barrinha laranja embaixo dos elos de vida (D-043).

| Ramo | Nó | Custo | Efeito |
|---|---|---|---|
| **A — Ovação** | A1 Plateia Fiel | 1 | Embalo máximo sobe para 30 (+37,5%). Levar dano tira **só metade** do Embalo. |
| | A2 Ritmo de Arena | 2 | Com o Embalo cheio, os tiros **atravessam 1 inimigo**. |
| | A3 **ÁPICE — Grande Arena** | 3 | Com o Embalo cheio, cada 10º tiro é um **Golpe do Campeão**: projétil grande de 40 de dano, com dano dobrado contra elites e chefes. |
| **B — Rajada** | B1 Disciplina | 1 | **Rajadas de 3 tiros** (0,06 s entre as balas), +20% de dano por bala e 0,25 s entre rajadas. Segurar o botão continua disparando. |
| | B2 Três Golpes | 2 | Se as 3 balas da rajada acertam o mesmo alvo, **a 3ª é crítica (×2)**. |
| | B3 **ÁPICE — Execução** | 3 | Um crítico num inimigo comum com menos de 25% de vida **mata na hora**. Em elites e chefes, o crítico causa ×3 em vez de ×2. |
| **C — Corrente** | C1 Marca do Escravo | 1 | O alvo acertado pelo Grilhão fica **marcado por 4 s** e leva **+25% de dano** da Mordida. |
| | C2 Caçada | 2 | Matar um alvo marcado **devolve 2 s da recarga do Grilhão**. |
| | C3 **ÁPICE — Algema Viva** | 3 | Tiros num alvo marcado têm 30% de chance de **prendê-lo no lugar** (leves: 1,0 s; médios: 0,5 s; não funciona em elites e chefes). |

### 4.2 Bramido (universal Kharn)
**Base:** 6 balins × 9 de dano · 1,5 disparo/s · balins a 400 px/s (25 tiles/s) · duração 0,2 s (alcance de 80 px) · o dano cai 50% a partir de 48 px · dispersão de ±15° (30° no total) · `peso_disparo` 2,5 · `fator_efeito` 0,35 por balim.

**Assinatura — Coice:** todo disparo que acerta **empurra** inimigos leves e médios 16 px (uma vez por disparo, os balins não somam). Inimigos pesados não se mexem. Na história, a arma é quase do tamanho do Ryker (NAR-03), e o coice também se vê nele (2 px de recuo visual, sem efeito no jogo).

| Ramo | Nó | Custo | Efeito |
|---|---|---|---|
| **A — Cerco** | A1 Bala de Cerco | 1 | **Troca os 6 balins por 1 projétil único** de 50 de dano, a 600 px/s, com duração de 1,0 s (tela inteira), sem dispersão. `fator_efeito` passa a 1,0. |
| | A2 Perfurador | 2 | O projétil único **atravessa todos os inimigos leves** e para no primeiro médio ou pesado. |
| | A3 **ÁPICE — Artilharia** | 3 | **Segurar o tiro carrega** por 1,0 s. O disparo carregado **explode** no impacto (raio de 40 px, 90 de dano). Soltar antes de 1,0 s dispara a bala normal. |
| **B — Brecha** | B1 Boca Larga | 1 | +2 balins (8 no total), dispersão de ±20°, e +30% de dano a menos de 32 px. |
| | B2 Abre-Couraça | 2 | Acertar à queima-roupa (24 px ou menos) **quebra a armadura frontal por 3 s**, mesmo sem o Grilhão. |
| | B3 **ÁPICE — Recuo de Gladiador** | 3 | O disparo **empurra Ryker 24 px para trás**. No ar, ele ganha também um pequeno impulso para cima (1 vez por pulo). |
| **C — Fornalha** | C1 Cano Duplo | 1 | **Carregador de 2:** dois disparos rápidos (0,15 s entre eles), depois 0,9 s de recarga. |
| | C2 Recarga de Combate | 2 | Dar um dash recarrega o Bramido na hora. |
| | C3 **ÁPICE — Fogo Contínuo** | 3 | Matar um inimigo **devolve 1 disparo** ao carregador na hora. |

## 5. Rascunho dos ramos das armas futuras (Fase 3, sem números)
| Arma | Ramo A | Ramo B | Ramo C |
|---|---|---|---|
| Arpão de Titã | **Gancho** (o arpão prende e puxa) | **Rajada de Agulhas** (vários disparos menores, sem carga) | **Golpe Final** (carga longa, dano enorme em ponto fraco) |
| Lança do Vazio | **Falange** (feixe mais largo) | **Estocada** (o disparo vira avanço corpo a corpo) | **Arremesso** (a lança é jogada e volta) |
| Liquidação | **Juros** (mais forte quanto mais tempo no mesmo alvo) | **Ricochete** (mais quicadas) | **Dividendos** (mais Créditos e economia) |
| Lanterna da Vigília | **Constelação** (mais esferas orbitando, que protegem) | **Cometa** (1 esfera grande e lenta) | **Maldição** (as esferas aplicam uma maldição Vigílio, ver GD-06) |

**Regra da Lanterna:** ela é "a única arma que Ryker não modifica" (NAR-03), mas tem árvore como as outras (D-038). **Proposta:** na história, os nós dela são **ritos aprendidos** e não gambiarra. A tela usa a moldura humana (D-047) com ícones de rito. A NAR escolhe o texto.

## 6. Requisitos de teste (para o DEV)
1. Nós de um ramo só podem ser comprados em ordem, e o custo é 1, 2 e 3 pontos.
2. Comprar um Ápice tranca os outros dois na mesma run.
3. A árvore e os pontos zeram na morte e no fim da run.
4. Pontos não gastos ficam guardados até o fim da run.
5. `peso_disparo` e `fator_efeito` são aplicados (ex.: Munição de Clã dispara no 2º disparo do Bramido, porque 2 × 2,5 ≥ 5).
6. Embalo: sobe por acerto, zera ao levar dano (metade com o nó A1) e cai depois de 1,5 s sem acertar.
7. Bala de Cerco troca os balins por 1 projétil, e Recuo de Gladiador empurra o jogador.
8. Com o tiro automático ligado, os nós de carga disparam sozinhos quando a carga completa.

## 7. Dados-base em unidades do código (`DadosArma`, tile de 16 px)
| Campo | Mordida (`mordida.tres`) | Bramido (`bramido.tres`) |
|---|---|---|
| `cadencia` | 8,0 | 1,5 |
| `dano` | 10 | 9 |
| `velocidade_projetil` (tiles/s) | 37,5 | 25,0 |
| `duracao_projetil` (s) | 1,0 | 0,2 |
| `espalhamento_graus` (para cada lado) | 0 | 15 |
| `projeteis_por_tiro` | 1 | 6 |
| `peso_disparo` *(campo novo)* | 1,0 | 2,5 |
| `fator_efeito` *(campo novo)* | 1,0 | 0,35 |
| marcador de assinatura | `embalo` | `coice` |

## 8. Mapa para o código — cada nó como `ModificadorArma` (pedido do DEV)
Campos atuais do `ModificadorArma`: `mult_dano`, `mult_cadencia`, `mult_velocidade_projetil`, `mult_duracao_projetil`, `soma_dano`, `soma_projeteis_por_tiro`, `soma_espalhamento_graus`, `marcadores`. Quando só os campos numéricos bastam, não há marcador. **Cada marcador é um comportamento que precisa de código.**

### 8.1 Mordida
| Nó | Campos numéricos | Marcador (comportamento novo) |
|---|---|---|
| A1 Plateia Fiel | — | `embalo_estendido` (máximo 30; dano tira metade) |
| A2 Ritmo de Arena | — | `perfura_com_embalo_cheio` (atravessa 1) |
| A3 Grande Arena | — | `golpe_do_campeao` (cada 10º tiro com Embalo cheio) |
| B1 Disciplina | `mult_dano` 1,2 | `rajada_3` (3 balas a 0,06 s, pausa de 0,25 s) |
| B2 Três Golpes | — | `rajada_critico_3` |
| B3 Execução | — | `execucao` |
| C1 Marca do Escravo | — | `marca_grilhao` (4 s, +25% de dano) |
| C2 Caçada | — | `marca_devolve_grilhao` (2 s) |
| C3 Algema Viva | — | `algema_viva` |

### 8.2 Bramido
| Nó | Campos numéricos | Marcador (comportamento novo) |
|---|---|---|
| A1 Bala de Cerco | `soma_projeteis_por_tiro` −5, `soma_espalhamento_graus` −15, `soma_dano` +41, `mult_velocidade_projetil` 1,5, `mult_duracao_projetil` 5,0 | `bala_unica` (troca o `fator_efeito` para 1,0 e desliga a queda de dano por distância) |
| A2 Perfurador | — | `perfura_leves` |
| A3 Artilharia | — | `carga_explosiva` (1,0 s; 90 de dano em 40 px) |
| B1 Boca Larga | `soma_projeteis_por_tiro` +2, `soma_espalhamento_graus` +5 | `bonus_perto` (+30% a menos de 32 px) |
| B2 Abre-Couraça | — | `quebra_armadura_perto` (24 px; 3 s) |
| B3 Recuo de Gladiador | — | `recuo_jogador` (24 px; impulso no ar 1 vez por pulo) |
| C1 Cano Duplo | — | `carregador_2` (0,15 s entre os dois; 0,9 s de recarga) |
| C2 Recarga de Combate | — | `recarga_no_dash` |
| C3 Fogo Contínuo | — | `devolve_disparo_ao_matar` |

**Total para o VS:** 2 assinaturas (`embalo`, `coice`) + 18 marcadores, sendo 9 por arma. Nenhum deles aplica status de facção (D-040).
