# GD-09 — Arena e ondas: o novo jogo (D-077) · v0.1

Autor: Game Design (GD) · Atende ao **GD-9** da CENTRAL. Segue para **ART-9**, **NAR-6** e **DEV 33**.
Base: **D-077** (arena com visão de cima, formato do gênero do Brotato), D-061 (mira e tiro automáticos), D-063, D-065 a D-068, D-072 (Oferta), D-045 (segredos).
Unidades: **tile = 16 px**. Tela 480×270 = 30×17 tiles.

> Seguimos o **gênero** (arena + ondas + loja + várias armas automáticas). Nomes, armas, itens, inimigos e mundo são do No Rest.
> Os pontos marcados **[PROPOSTA]** dependem do dono (seção 12). O DEV pode começar o protótipo (DEV 33) com eles como estão.

---

## 1. A partida em uma frase
O Ryker desce de cápsula num planeta, sobrevive a **5 ondas curtas** numa arena fechada, compra armas e itens com a **Sucata** que os inimigos soltam e enfrenta o **chefe** do planeta na 5ª onda. A Eco salta para o próximo planeta. **Morrer = voltar para a nave** e a run acaba.

## 2. Estrutura da run **[PROPOSTA]**
| | Valor |
|---|---|
| Planetas por run | 4 (Varrek → Tarvo → Zhinn → Vigília) |
| Ondas por planeta | 5; a 5ª é a do **chefe** |
| Ondas na run | **20** (numeradas 1–20 na run inteira; a dificuldade usa esse número) |
| Duração das ondas comuns | 1ª do planeta **30 s**, 2ª **40 s**, 3ª **50 s**, 4ª **60 s** |
| Onda do chefe | termina ao **matar o chefe** (os inimigos comuns param de nascer aos 90 s) |
| Duração da run | ~4–5 min por planeta, **~18 min** a run inteira |
| Entre as ondas | 1) tela de **nível** (se subiu) → 2) **loja do Ilo** → 3) próxima onda |
| Entre planetas | depois da loja, cena curta da Eco saltando (NAR-6) e a cápsula cai no planeta seguinte |

**Enquanto só Varrek existe (VS):** a run são as **5 ondas de Varrek** com Ur-Kesh na 5ª. Ao vencer, libera o modo **Sem Descanso**: ondas infinitas em Varrek, de 60 s, com dificuldade crescendo e recorde de ondas salvo.

Ao fim de cada onda: os inimigos vivos **somem** (fumaça), as balas inimigas somem e **toda a Sucata no chão voa até o Ryker**.

## 3. A arena
- **Tamanho:** 40×24 tiles (**640×384 px**), maior que a tela. A câmera segue o Ryker e para nas bordas.
- **Bordas:** paredes de carcaça de nave (sólidas). Sem buracos e sem plataformas.
- **Obstáculos:** 3 a 5 destroços sólidos espalhados (2×2 a 3×2 tiles), sempre a ≥ 4 tiles uns dos outros e do centro. O Ryker nasce no centro.
- **Uma arena por planeta**, com o visual do planeta (ART-9). Varrek: chão de ferrugem e areia com cascos ao fundo.

## 4. O Ryker
| Atributo base | Valor |
|---|---|
| Vida máxima | **10** |
| Velocidade | **110 px/s** (≈ 6,9 tiles/s), 8 direções, aceleração instantânea |
| Ímã de Sucata | raio **48 px** (3 tiles) |
| Invencibilidade depois de levar dano | 0,5 s (pisca) |
| Slots de arma | **6** |
| Arma inicial | **Mordida I** |
| **Dash** **[PROPOSTA]** | Shift / botão B: 64 px em 0,15 s, invencível durante o dash, recarga **1,5 s** |

**Controles (adapta a D-052):** WASD/analógico esquerdo movem; Shift = dash; Esc = pausa; E/clique = escolher na loja e no nível. **Espaço, Q, U e botão direito não fazem nada na arena.**
**Mira (D-061):** padrão **automática** (cada arma mira no inimigo mais perto dentro do seu alcance). Opção **Mira manual** nas Opções: todas as armas miram no mouse/analógico direito.

## 5. Armas
### 5.1 Regras
- Até **6 armas** ao mesmo tempo. Todas atiram **sozinhas**, cada uma com seu tempo de recarga, a partir de pontos em volta do Ryker (círculo de 14 px de raio, espaçados por igual).
- Cada arma tem **4 níveis de qualidade**: **I** (cinza), **II** (azul), **III** (roxo), **IV** (vermelho).
- **Fundir:** comprar uma arma igual e de mesmo nível de uma que já se tem, com os 6 slots cheios, funde as duas em uma do nível seguinte. Na loja, também dá para clicar numa arma e escolher **Fundir** se houver par.
- **Vender:** devolve **30%** do preço pago (na loja).
- Cada arma tem uma **família**. Ter várias da mesma família dá um **bônus de família** (5.3). Uma arma conta só uma vez, mesmo repetida.

### 5.2 As 8 armas do VS
Valores do nível I. Nível II = dano ×1,5 · III = ×2,2 · IV = ×3,2; a recarga cai 10% a cada nível.

| Arma | Família | Tipo | Dano | Recarga | Alcance | Efeito |
|---|---|---|---|---|---|---|
| **Mordida** (Ryker) | Arena | distância | 6 | 0,40 s | 200 px | Projétil a 600 px/s. **Embalo:** cada acerto dá +1% de cadência (até +20%); levar dano zera. |
| **Grilhão** (Ryker) | Arena | corpo a corpo | 12 | 1,00 s | 64 px | Corrente em arco de 90°. **Puxa** inimigos leves 24 px para perto. |
| **Bramido** (Kharn) | Kharn | distância | 4 × 5 balins | 1,20 s | 110 px | Dispersão de 30°. **Coice:** empurra leves e médios 16 px. |
| **Granada de Clã** (Kharn) | Kharn | área | 15 | 1,80 s | 220 px | Arremesso em arco; explode em 32 px de raio; 25 de Abalo. |
| **Ferrão** (Vesh) | Vesh | distância | 3 | 0,50 s | 180 px | 40% de chance de **Ácido** (1 acúmulo: 2 de dano/s por 3 s, até 5). |
| **Ninhada** (Vesh) | Vesh | invocação | 5 por larva | 2,00 s | 160 px | Solta 2 larvas que perseguem o inimigo mais perto e somem ao morder. |
| **Liquidação** (Ilo) | Ilo | distância | 8 | 0,80 s | 200 px | Ricocheteia em 2 inimigos. **Lucro:** matar dá 20% de chance de +1 Sucata. |
| **Lanterna da Vigília** (Vigília) | Vigília | orbital | 6 por toque | — | 40 px | 2 esferas que giram em volta do Ryker (1 volta/s). Cada esfera fere o mesmo inimigo no máximo 2×/s. |

O **Bramido**, a **Liquidação** e a **Lanterna** vêm das armas do GD-05; o **Grilhão** e a **Granada** deixam de ser habilidades e viram armas.

### 5.3 Bônus de família (contam armas diferentes)
| Família | 2 armas | 3 armas | 4+ armas |
|---|---|---|---|
| **Arena** | +5% de cadência | +10% de cadência, +1 Vida máx. | +15% de cadência, +2 Vida máx. |
| **Kharn** | +10% de empurrão e Abalo | +1 Armadura | +2 Armadura, +15% de dano em área |
| **Vesh** | +10% de chance de Ácido | Ácido dura +1 s | +1 larva/projétil extra |
| **Ilo** | +5% de Sucata | +10% de Sucata | +15% de Sucata, 1 reroll grátis por loja |
| **Vigília** | +5% de dano | +10% de dano | +15% de dano, +1 esfera |

## 6. Sucata, nível e atributos
### 6.1 Sucata **[PROPOSTA: nome]**
Um só recurso que é **dinheiro e experiência** ao mesmo tempo (cada Sucata pega = +1 na carteira e +1 de XP).

| Inimigo | Sucata solta |
|---|---|
| Enxame (Roedor, Zangão, Chacal) | 1 |
| Médio (Cuspidor, Guerreiro, Artilheiro) | 3 |
| Pesado (Muralha, Ninho) | 6 |
| Elite | 15 |
| Chefe | 50 |

A Sucata fica no chão até ser pega (ímã de 48 px) ou até o fim da onda (seção 2). Máximo de 150 peças no chão: acima disso, as novas se somam à peça mais próxima (vale 2, 3...).

### 6.2 Nível
- XP para passar do nível *n* para *n+1*: **(n + 3)²** → 16, 25, 36, 49, 64...
- Cada nível dá **+1 Vida máx.** na hora.
- **Ao fim da onda**, para cada nível ganho: tela com **4 atributos** sorteados → escolher 1 (clique ou E, D-066). Reroll: 1ª vez **2 Sucata**, depois +2 a cada vez (zera na próxima onda).
- Raridade da carta: Comum 70% · Rara 22% · Épica 7% · Lendária 1% (sobe 1 ponto por nível para as melhores, até Lendária 5%).

### 6.3 Atributos
Valores do atributo na carta **Comum / Rara / Épica / Lendária**.

| Atributo | Efeito | C / R / E / L |
|---|---|---|
| Vida máx. | + vida | 3 / 6 / 9 / 12 |
| Regeneração | cura 1 de vida a cada (5 / nível) s | 2 / 3 / 4 / 5 níveis |
| Roubo de vida | % de chance de curar 1 ao acertar | 1 / 2 / 3 / 4 % |
| Dano | % de dano em tudo | 5 / 8 / 12 / 16 % |
| Dano corpo a corpo | + dano fixo (corpo a corpo e orbital) | 2 / 3 / 4 / 5 |
| Dano à distância | + dano fixo (distância) | 1 / 2 / 3 / 4 |
| Cadência | % menos recarga | 5 / 8 / 12 / 16 % |
| Crítico | % de chance de dano ×2 | 3 / 5 / 7 / 9 % |
| Alcance | + px de alcance (corpo a corpo vale metade) | 15 / 25 / 35 / 45 |
| Armadura | dano recebido: ×(1 − 0,07·Arm) até −60% | 1 / 2 / 3 / 4 |
| Esquiva | % de chance de não levar o acerto (máx. 60%) | 3 / 5 / 7 / 9 % |
| Velocidade | % de velocidade | 3 / 5 / 7 / 9 % |
| Sorte | melhora a raridade na loja/nível e o drop extra | 5 / 8 / 12 / 16 |
| Coleta | + raio do ímã | 16 / 24 / 32 / 40 px |

## 7. Loja do Ilo (entre as ondas)
- **4 ofertas** por vez (armas e itens). Chance de arma: 35% em cada oferta.
- **Reroll:** custa **1 + onda** Sucata; +1 a cada reroll na mesma loja.
- **Travar** (cadeado): a oferta travada fica para a próxima loja.
- **Preço** = base × (1 + 0,10 × (onda − 1)), arredondado.

| Raridade / nível | Arma (base) | Item (base) |
|---|---|---|
| I / Comum | 15 | 12 |
| II / Raro | 35 | 30 |
| III / Épico | 70 | 60 |
| IV / Lendário | 120 | 100 |

- **Chance de raridade** na loja (onda 1 → onda 20, subindo em linha reta): Comum 90% → 40% · Rara 9% → 35% · Épica 1% → 20% · Lendária 0% → 5% (a Lendária só a partir da onda 8). Sorte melhora (+1% por ponto nas três de cima).
- Botão **"Pronto"** começa a próxima onda. Esc volta para a loja e não pula nada (D-065).

## 8. Itens
Passivos que se acumulam, sem limite de quantidade (alguns são **únicos**, máx. 1). Três tipos:

### 8.1 Itens comuns (exemplos do VS, 12)
| Item | Raridade | Efeito |
|---|---|---|
| Couro de Arena | Rara | Anula o 1º acerto de cada onda (único) |
| Honra do Campeão | Rara | +25% de dano em elites e chefes |
| Grito de Guerra | Épica | Os inimigos nascem com 30 de Abalo |
| Carne Mole | Rara | Inimigos com 5 acúmulos de Ácido levam +35% de dano |
| Corpo Solto | Épica | Matar: 10% de chance de um zangão aliado (10 s, máx. 3) |
| Colmeia Faminta | Épica | Quem morre com Ácido vira poça que passa 2 acúmulos |
| Bolso Fundo | Comum | +5% de Sucata, −1 Armadura |
| Botas de Mineiro | Comum | +5% de velocidade |
| Cantil Velho | Comum | +2 Vida máx., +1 Regeneração |
| Mira de Sucata | Comum | +2% de crítico, +10 de alcance |
| Placa de Casco | Rara | +2 Armadura, −3% de velocidade |
| Ímã de Carcaça | Comum | +24 px de Coleta |

Os nomes vêm dos upgrades Kharn/Vesh do GD-02 (seção 6), que viram itens.

### 8.2 Gambiarras = itens de arma
As **Gambiarras** passam a ser itens que mudam **todas as armas de um tipo** (ex.: "Cano Serrado: armas à distância +1 projétil, −20% de dano"; "Corrente Longa: corpo a corpo +20 px de alcance"). O DEV usa o mesmo `ModificadorArma`. A tela de 3 cartas sai; elas aparecem na loja.

### 8.3 Ofertas de facção (D-072)
Depois de vencer cada **chefe**, a Eco abre uma escolha de **Oferta**: 1 entre 3 (uma Kharn, uma Vesh e uma aleatória), grátis e forte (raridade Épica ou Lendária). É o único momento de escolha obrigatória fora do nível.

## 9. Inimigos (visão de cima)
### 9.1 Regras
- **Nascimento:** num ponto aleatório da arena, com **marca no chão 1,0 s antes** (o Roedor sai de toca, como no DEV 30). Nunca a menos de **6 tiles** do Ryker. Em grupo: até 6 juntos, num raio de 2 tiles.
- **Na tela ao mesmo tempo (mantém a D-062):** 15–25 normalmente, picos de 30–40, **teto de 40**.
- **Força por onda** (*w* = número da onda na run): vida × (1 + 0,15 × (w − 1)) · dano × (1 + 0,06 × (w − 1)).
- **Dano de contato** com 0,5 s de invencibilidade (seção 4). Ataques à distância sempre com aviso (mantém os avisos do GD-02).
- No máximo **3 ataques anunciados ao mesmo tempo** (fichas de ataque, D-026).

### 9.2 Inimigos de Varrek (VS)
| Inimigo | Facção | Vida | Velocidade | Dano | Comportamento |
|---|---|---|---|---|---|
| **Roedor** | Vesh | 6 | 70 px/s | 1 | Corre direto para o Ryker |
| **Zangão** | Vesh | 5 | 85 px/s | 1 | Voa em zigue-zague até o Ryker; passa sobre os destroços |
| **Chacal de Clã** | Kharn | 10 | 60 px/s | 2 | Para a 5 tiles, avisa 0,5 s (linha no chão) e salta 5 tiles em linha reta |
| **Cuspidor** | Vesh | 15 | 40 px/s | 2 | Fica a 7 tiles; aviso 0,5 s; cuspe que deixa poça de ácido 2 s |
| **Guerreiro de Clã** | Kharn | 35 | 35 px/s | 3 | Anda até 8 tiles; aviso 0,6 s; rajada de 3 tiros lentos (180 px/s) |
| **Artilheiro** | Kharn | 25 | 30 px/s | 4 | Fica longe; marca um círculo no chão 1,0 s antes do morteiro (raio 24 px) |
| **Muralha** | Kharn | 60 | 40 px/s | 3 | Escudo bloqueia 100% pela frente; aviso 0,8 s e investida de 6 tiles |
| **Ninho** | Vesh | 60 | parado | — | Gera 1 Zangão a cada 4 s (até 6). Nasce só nas ondas 3+ |

**Elite (1 na onda 4 de Varrek):** Brutamontes Kharn (vida 300, metralhadora em varredura com laser de aviso 0,8 s, pisão em círculo de 48 px com aviso 0,7 s).
**Chefe (onda 5): Ur-Kesh**, vida **1200** em 2 fases. Fase 1 (andador): investida com aviso 1,0 s e 3 morteiros marcados. Fase 2 (≤ 50%): a pé, mais rápido, chama 6 Chacais a cada 20 s. O GD detalha no GD-09 v0.2 depois do protótipo.

### 9.3 Ondas de Varrek
| Onda | Duração | Inimigos por segundo (início → fim) | Mistura |
|---|---|---|---|
| 1 | 30 s | 0,8 → 1,2 | Roedor 85%, Zangão 15% |
| 2 | 40 s | 1,0 → 1,5 | Roedor 60%, Zangão 20%, Chacal 20% |
| 3 | 50 s | 1,2 → 1,8 | Roedor 45%, Chacal 20%, Cuspidor 20%, Guerreiro 10%, 1 Ninho aos 20 s |
| 4 | 60 s | 1,4 → 2,2 | Roedor 40%, Chacal 15%, Cuspidor 15%, Guerreiro 15%, Artilheiro 10%, Muralha 5%; **Brutamontes aos 30 s** |
| 5 | chefe | 0,6 (até 90 s) | **Ur-Kesh** + Roedores e Chacais |

**Pico:** nos últimos 10 s das ondas 3 e 4, a taxa dobra (respeitando o teto de 40).

## 10. Progressão permanente (versão pequena, D-077)
Substitui as árvores Passiva e de Combate da D-058.
- **Núcleos** ganhos na run: **2 por onda vencida + 10 por chefe**. Vencer as 5 ondas de Varrek rende 20.
- Gastos com **Vossa Margem**, na nave. Total: **320 Núcleos** (cerca de 16 a 25 runs).

| Melhoria | Efeito por nível | Níveis | Custo |
|---|---|---|---|
| Blindagem | +2 Vida máx. | 2 | 15 / 35 |
| Contato no Mercado | Começa com +10 Sucata | 3 | 10 / 20 / 30 |
| Recalibrar | +1 reroll grátis na 1ª loja de cada planeta | 1 | 40 |
| Memória da Âncora | +5% de XP | 2 | 20 / 40 |
| Propulsores | −0,2 s na recarga do dash | 2 | 20 / 40 |
| Estoque do Ilo | A loja mostra 5 ofertas em vez de 4 | 1 | 50 |

**Desbloqueios (sem custo):** armas e itens novos entram no sorteio por conquistas: vencer Ur-Kesh libera o Bramido; encontrar o Ilo na nave libera a Liquidação; e assim por diante (NAR-6 e DEV ligam ao Códice). Começam liberadas: Mordida, Grilhão, Granada de Clã, Ferrão e Ninhada.

**Personagens:** no VS, só o **Ryker**. Mais tarde, os **Moldes** já previstos na história (Caçadora de Titãs, Último Lanceiro) entram como personagens com regras próprias (arma inicial e 1 vantagem/1 desvantagem).

## 11. O que se aproveita do jogo atual
| Aproveita (adaptar) | Sai |
|---|---|
| Sistema de armas (`DadosArma`, `ModificadorArma`), projéteis, números de dano (D-067), status Ácido e Abalo | Pulo, gravidade, plataformas, quedas, teste da D-070 |
| Spawner de ondas e enxame (DEV 18, 30), fichas de ataque, avisos | Salas, portas, sorteio de recompensas por porta |
| IA dos inimigos: perseguir e atacar (tirar pulo e gravidade) | Tela de Gambiarra de 3 cartas (o código da carta pode servir à tela de nível) |
| Upgrades Kharn/Vesh com pré-requisitos → itens | Árvores Passiva e de Combate (viram a lista da seção 10) |
| Loja do Ilo (vira a loja entre ondas), Créditos → Sucata | Chamado e barra de Chamado |
| Nave, diálogos, Códice, menus, save, opções, logo, abertura, testes | Sprites de jogo vistos de lado (ART-9 refaz) |

## 12. Perguntas ao dono (propostas padrão)
1. **Estrutura:** 4 planetas × 5 ondas (20 ondas, ~18 min); no VS, só Varrek + modo Sem Descanso. **Proposta: sim.**
2. **Nome do recurso:** "**Sucata**" (dinheiro + experiência), no lugar de Créditos. **Proposta: Sucata.**
3. **Dash fica** como única ação do jogador (o gênero não tem); Granada e Grilhão viram armas automáticas. **Proposta: sim.**
4. **Vida pequena** (10 no início, como no gênero), no lugar dos blocos de vida. **Proposta: sim.**
5. **Gambiarras** viram itens de arma na loja, e as **Ofertas** viram a escolha grátis depois de cada chefe. **Proposta: sim.**

## 13. Testes (para o DEV)
1. A run tem 5 ondas por planeta; as durações são 30/40/50/60 s; a onda do chefe só termina com o chefe morto.
2. No fim da onda, inimigos e balas somem e toda a Sucata vai para o Ryker.
3. Seis slots: a 7ª arma igual e de mesmo nível funde; a 7ª arma diferente não entra.
4. Fundir duas armas I dá uma II com dano ×1,5 e recarga −10%.
5. Cada arma automática atira no inimigo mais perto dentro do alcance; sem inimigo no alcance, não atira.
6. Bônus de família: 2 armas Arena diferentes dão +5% de cadência; 2 Mordidas contam como 1.
7. XP: 16 Sucata levam do nível 1 ao 2; a tela de nível aparece no fim da onda, uma vez por nível ganho.
8. Loja: reroll custa 1 + onda e sobe +1 por reroll; a oferta travada continua na loja seguinte; o preço segue a fórmula da seção 7.
9. Inimigo nunca nasce a menos de 6 tiles do Ryker e sempre com marca de 1,0 s antes.
10. Nunca mais que 40 inimigos vivos.
11. Vida e dano dos inimigos sobem com a onda pela fórmula da seção 9.1.
12. Armadura: 3 de Armadura → dano ×0,79; nunca abaixo de ×0,40.
13. Morrer leva para a nave e dá os Núcleos da seção 10.
