# GD-08 — Horda e ritmo (D-061 + D-062) · v0.1

Autor: GD · Atende ao item GD-3 da CENTRAL.
**Revisa:** GD-07, seção 1 (armas base) e seção 4.1 (curva de XP); GD-02, seções 4 e 5 (vida dos inimigos, Zangão, composição de ondas); GD-03, seção 2.4 (orçamento de ondas).
**Não mexe em:** mira e tiro automáticos (D-061), fichas de ataque (no máximo 3 avisos ao mesmo tempo), entrada justa.
Unidades: 1 tile = 16 px. Ryker corre a 7 tiles/s.

---

## 1. Armas mais lentas (a)
O poder sai da base e passa para as Gambiarras e a árvore de Combate. Mesmo com o tiro automático ligado, a arma sozinha **não segura a horda**: o jogador precisa se mover.

| Arma (nível 1) | Antes | **Agora** | Dano por segundo |
|---|---|---|---|
| Mordida | 8 tiros/s × 10 | **3,5 tiros/s × 14** | 80 → **49** |
| Bramido | 1,5 disparo/s × 6 balins de 9 | **1,0 disparo/s × 6 balins de 10** | 81 → **60** (tudo acertando de perto) |

O resto do GD-07, seção 1, não muda: velocidade, alcance, dispersão, `peso_disparo` e `fator_efeito`.

**A cadência nas outras fontes sobe um pouco**, para compensar a base menor:
| Fonte | Antes | **Agora** |
|---|---|---|
| Gambiarra Gatilho Leve (Mordida) | +8%, até 3× | **+12%, até 3×** (+36% no total) |
| Gambiarra Engatilho Rápido (Bramido) | +10%, até 3× | **+15%, até 3×** |
| Árvore de Combate, Gatilho de Mina | +15% | **+20%** |
| Árvore de Combate, Cano Duplo (Bramido) | carregador de 2 | sem mudança |

**Ficam mais valiosas na horda, sem mudar os números:** perfuração, Leque, Ricochete, Balim Extra, Estilhaço Vivo, granada e o golpe corpo a corpo automático (25 de dano quando o inimigo está colado). É intencional.

## 2. Inimigos de enxame em Varrek (b)
**Regra do enxame:** é pequeno, vem em bando, morre com 1 ou 2 tiros e **machuca só por contato**. Não usa fichas de ataque nem dispara projéteis. É sempre **Leve** para o Grilhão. A IA é barata: anda ou voa em direção ao jogador.

| Inimigo | Facção | Tamanho | Vida | Velocidade | Comportamento | Bando | XP |
|---|---|---|---|---|---|---|---|
| **Roedor** (novo) | Vesh | 10×8 | 12 (1 tiro da Mordida) | 4,5 tiles/s | Corre pelo chão e pula degraus de até 1,5 tile. Sobe paredes curtas (até 2 tiles). | 6 a 12 | 1 |
| **Chacal de Clã** (novo) | Kharn | 14×10 | 22 (2 tiros) | 6 tiles/s | Corre pelo chão e, a cada ~2,5 s, **salta** em arco até o jogador. **Aviso de 0,3 s** (agacha e brilha). O salto não usa ficha. | 3 a 6 | 2 |
| **Zangão** (reclassificado) | Vesh | 12×12 | 10 → **8** | 5 tiles/s | Voa em zigue-zague até o jogador. **Perde o mergulho anunciado**: agora é só contato. | 5 a 10 | 1 |

**Regras de contato (pilar 1):**
- Cada toque tira **1 bloco**, e depois o jogador tem os 0,8 s normais de invulnerabilidade.
- Depois de tocar, o inimigo **recua 1 tile e fica parado por 0,5 s**, para não haver dano em sequência quando a invulnerabilidade acaba.
- **O dash atravessa o bando** (invulnerável), e o Roedor e o Zangão são **mais lentos que o Ryker**. Correr e pular sempre resolvem. O Chacal é mais rápido, mas o salto é anunciado.

**Pedidos:** NAR — nome e uma linha do Códice para o Roedor e o Chacal (sugestão: Chacais são bestas que os Kharn usam para caçar escravos fugidos). ART-4 — sprites desses inimigos.

**Os pesados ficam com menos vida**, para acompanhar a arma mais lenta (−20% em média):
| Inimigo | Antes | **Agora** |
|---|---|---|
| Guerreiro de Clã | 120 | **100** |
| Artilheiro Kharn | 80 | **70** |
| Muralha | 150 | **130** |
| Cuspidor | 25 | 25 |
| Ninho | 200 | **160** |
| Brutamontes (elite) | 400 | **320** |
| Ceifadora (elite) | 250 | **200** |
| Ur-Kesh | fase 1 e 2: 1500 · fase 3: 600 | **1200 · 500** |

## 3. Ondas (c)

### 3.1 De onde vêm os inimigos
| Origem | Parte do enxame | Regra |
|---|---|---|
| **Direita, à frente (principal)** | **~80%** | Surgem 2 tiles fora da borda direita da tela e entram correndo ou voando |
| Por trás (esquerda) | no máximo 10% | **Só em picos.** Uma seta pisca na borda esquerda **1,0 s antes** |
| De cima (Zangões descendo) | no máximo 10% | **Só em picos.** Sombra ou zumbido **1,0 s antes** |
| Buracos ou túneis no cenário (Roedores) | dentro dos 10% "de cima" | O buraco brilha **1,0 s antes**; nunca a menos de 6 tiles do jogador |

Os **pesados** (Guerreiro, Artilheiro, Muralha, Cuspidor, elites) entram **sempre pela direita**, com os 0,5 s de entrada sem atacar.

### 3.2 Ritmo de cada sala
- **Trecho (rolagem):** enxame contínuo pela direita enquanto o jogador avança. Se ele parar por mais de 4 s, a taxa sobe 50% (a horda "alcança" quem fica parado).
- **Arena (câmera travada):** fluxo contínuo de enxame durante a **duração da arena** + pesados entrando a cada 8 a 10 s + **1 pico**.
- **Pico:** acontece aos ~60% da duração. São 12 a 20 inimigos de enxame em 4 s, anunciados por um **tremor de tela + som 1,5 s antes**. É o único momento com entradas por trás e de cima.
- **Teto de inimigos vivos:** se o teto for atingido, novas entradas esperam.
- **Como a sala termina:**
  1. a duração acaba e as entradas param;
  2. os pesados restantes precisam morrer;
  3. depois de 8 s, o enxame que sobrou **foge pela direita** (sem dar XP);
  4. as portas aparecem.

### 3.3 Números por sala (Ato 1)
| Sala | Enxame no trecho | Duração da arena | Enxame na arena | Pesados (orçamento do GD-03) | Teto de vivos |
|---|---|---|---|---|---|
| 0 (repetição) | — | 15 s | 1,0/s (~15) | 0 | 15 |
| 1 Carcaça | 1,0/s | 40 s | 1,5/s (~60) | 4 | 20 |
| 2 Linha Kharn | 1,2/s | 45 s | 2,0/s (~90) | 10 | 22 |
| 3 Ninhos Vesh | 1,5/s | 50 s | 2,2/s (~110) | 12 | 25 |
| 5 Zona de guerra | 2,0/s | 60 s | 2,8/s (~170) | 16 | 35 |
| 6 Elite | 1,0/s | até a elite morrer (máx. 75 s) | 1,2/s | elite + 8 | 25 + elite |
| Chefe Ur-Kesh | — | — | Fase 2: 4 Chacais a cada 10 s (no lugar dos 2 Guerreiros). Fase 3: o rugido chama 8 Zangões. | — | 20 |

- **Pico:** 12 inimigos nas salas 1 a 3, 20 na sala 5. Teto de vivos durante o pico: **40**.
- **Mistura do enxame:**
  - Salas Kharn: 60% Chacal, 40% Roedor.
  - Salas Vesh: 50% Roedor, 50% Zangão.
  - Sala 5: Chacais e Vesh **brigam entre si** (GD-02, seção 4.4), e o pico dela é o que tem mais entradas por trás (até 15%).
- **Fichas de ataque:** continuam no máximo 3 avisos ao mesmo tempo, mas só para os pesados. O enxame não usa fichas, porque ataca por contato.
- **Desempenho (DEV):** 60 fps com 40 inimigos vivos + tiros. O enxame deve usar pool de objetos.

## 4. O que muda nas outras contas (d)
- **XP:**
  - **XP por inimigo de enxame:** Roedor 1, Zangão 1, Chacal 2. Os pesados não mudam (GD-07, seção 4.1).
  - **Nova curva de XP para subir do nível n:** `150 + 50 × n` (antes era `60 + 20 × n`).
  - Uma run vitoriosa no VS rende ~1.100 XP; uma derrota cedo, ~400.
  - Isso dá **nível 5 em 1 a 2 runs**, **nível 10 em 5 a 6 runs** (3.600 XP) e nível 25 só no jogo completo (18.600 XP). O nível máximo continua 25.
- **Núcleos:** não mudam. Eles não vêm por inimigo morto (GD-01, seção 8).
- **Créditos:**
  - Cada inimigo de enxame tem **10% de chance de soltar 1 Crédito**.
  - Os pesados continuam soltando 2 a 5 Créditos.
  - A loja continua com os mesmos preços.
- **Barra de Chamado:** continua enchendo 1 ponto a cada 10 de dano. Com mais alvos, o dano total por sala sobe, e o Chamado fica um pouco mais frequente. Isso é bom para a horda.
- **Mira automática (sem mudar o que já existe):** na horda, "o mais próximo" vale **dentro de 6 tiles à frente** primeiro. Assim a mira não fica presa num inimigo atrás quando a onda vem pela direita.
- **GD-02:** a seção 4.5 (exemplos de onda) é **substituída** pela seção 3.3 deste doc. As vidas são as da seção 2 deste doc.
- **GD-03:** na seção 2.4, o orçamento de ameaça passa a valer **só para os pesados**. O enxame é medido em inimigos por segundo (seção 3.3). As regras de bloco e de porta não mudam, mas as **arenas precisam de largura para o enxame entrar pela direita** (pelo menos 1 tela; ideal 1,5).

## 5. Testes (DEV)
1. ~80% das entradas de enxame vêm da direita. Entradas por trás e de cima só acontecem em picos e sempre com aviso de 1,0 s.
2. O teto de vivos é respeitado (40 no máximo).
3. Depois de tocar o jogador, o inimigo de enxame recua 1 tile e espera 0,5 s.
4. Nada surge a menos de 6 tiles do jogador.
5. A sala termina: as entradas param, os pesados morrem, o enxame foge em 8 s e as portas aparecem.
6. 60 fps com 40 inimigos e tiros (teste de desempenho).
7. Nova curva de XP: `150 + 50n`.
