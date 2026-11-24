# GD-02 — Combate do Ato 1: Ryker, inimigos, chefe e upgrades (v0.3)

Autor: Game Design (GD) · Base: GD-01 v0.4, GD-05 v0.2, GD-06 v0.1 e as decisões D-013 a D-047.
Status: aprovado em D-026 e D-027, com ajustes. Todos os números são valores iniciais e serão ajustados com os playtests de QA.

**Mudanças desde a v0.2:**
- **Números provisórios do DEV (D-037) conferidos no código e confirmados como oficiais** (seção 8).
- Nomes oficiais das armas (D-041): Mordida e Bramido.
- As Alianças Kharn + Vesh completas estão no GD-06.

**Convenções:** 1 tile = 16 px. "Aviso" é o tempo entre o sinal visual ou sonoro e o golpe (pilar 1). Ataques marcados com **[PESADO]** tiram 2 blocos de vida; todos os outros tiram 1.

---

## 1. Ryker Vale — kit (D-016)

### 1.1 Grilhão (slot Ferramenta) — números oficiais (D-027)
A corrente das algemas da arena, transformada em gancho.

| Parâmetro | Valor |
|---|---|
| Direção | 8 direções (segue a mira, inclusive a mira automática) |
| Alcance | 96 px (6 tiles) |
| Tempo até o alvo | 0,12 s |
| Dano no acerto | 15 |
| Recarga | 3,0 s (começa a contar quando a corrente volta) |
| Cancelamento | dá para cancelar a puxada com um dash |

**O que acontece depende do peso do alvo:**
| Peso do alvo | Efeito |
|---|---|
| **Leve** (Vesh pequenos) | **Puxa o inimigo** até Ryker e o atordoa por 1,0 s. Combina com o Bramido e o golpe corpo a corpo. |
| **Médio com proteção** (Kharn com placa ou escudo) | **Arranca a proteção.** O inimigo perde a armadura frontal ou o escudo pelo resto da luta e fica cambaleando por 0,6 s. |
| **Médio sem proteção** (ex.: Artilheiro, ou um Guerreiro que já perdeu a placa) | 15 de dano e cambaleio de 0,6 s. Nenhum dos dois é puxado. **(Valor do DEV confirmado, D-037.)** |
| **Pesado** (elites, chefe) e **pontos de ancoragem** | **Puxa Ryker até o alvo.** Ele fica invulnerável durante a puxada e por 0,2 s depois de chegar. Ao chegar ganha **Golpe de Arena**: por 1,5 s, o dano em pontos fracos é dobrado. |
| Nada no alcance | A corrente volta sozinha, e a recarga cai para 1,0 s (errar não pune tanto). |

**Por que funciona com os pilares:**
- Pilar 3: o humano não puxa o gigante, ele vai até o gigante.
- Pilar 1: é ferramenta de mobilidade e de fuga.
- Resolve o problema dos pontos fracos com mira automática: o Grilhão é a forma "física" de alcançar esses pontos.

### 1.2 Golpe corpo a corpo (automático, como a faca do Metal Slug)
Quando há um inimigo a até 20 px, o botão de atirar vira um **golpe de corrente**: 25 de dano em arco curto, 0,3 s por golpe. Inimigos atordoados pelo Grilhão levam o dobro. **Vale com qualquer arma.**

### 1.3 Granadas (valores do DEV confirmados, D-037)
3 por sala. 50 de dano numa área de 32 px de raio. Explode no impacto ou depois de 1,2 s. Empurra os inimigos a 10 tiles/s. **Arremesso:** velocidade inicial de 9 tiles/s para a frente e 13 tiles/s para cima, gravidade de 38 tiles/s². Isso dá um arco de ~2,2 tiles de altura e ~6 tiles de alcance no chão plano. Sem Abalo no padrão (os upgrades Kharn acrescentam).

## 2. Armas (D-038, D-040, D-041) → ver `GD/05-armas.md`
- No VS: **Mordida** (própria do Ryker; base no Fuzil do código) e **Bramido** (universal Kharn; base na Escopeta do código).
- **Não existem armas pesadas nem munição limitada.**

**Armadura frontal:** reduz em 50% o dano que vem pela frente. Não reduz explosões, golpes corpo a corpo nem dano pelas costas. O Grilhão arranca essa armadura, e o nó B2 do Bramido a quebra por 3 s.

## 3. Status das facções
| Status | Regras |
|---|---|
| **Abalo** (Kharn) | Cada fonte Kharn adiciona Abalo. Com 100 pontos, o inimigo fica **atordoado** (1,5 s em inimigos comuns, 0,75 s em elites, 0,4 s no chefe) e leva **+25% de dano** enquanto atordoado. O Abalo zera depois do atordoamento. **Queda:** depois de 0,5 s sem receber golpe, cai 20 pontos/s (valor do DEV confirmado, D-037). |
| **Ácido** (Vesh) | Acumula até **5 vezes**. Cada acúmulo causa 3 de dano/s e reduz em 10% a resistência da armadura. Dura 4 s, e cada novo acúmulo renova a duração. |
| **Revelado** (Vigílios, Fase 3) | Ver GD-06. |

## 4. Inimigos do Ato 1

### 4.1 Domínio Kharn (lentos, enormes, golpes pesados)
| Inimigo | Tamanho | Vida | Peso | Comportamento | Ataque e aviso |
|---|---|---|---|---|---|
| **Guerreiro de Clã** | ~2× Ryker (32×64) | 120 | Médio + armadura frontal | Avança devagar e para para atirar (números completos na seção 8) | Rajada de 3 tiros lentos (180 px/s). **Aviso: 0,6 s** (o canhão brilha; flash AVISO nos últimos 0,2 s, D-043). |
| **Artilheiro Kharn** | 32×56 | 80 | Médio | Fica no fundo da sala e mantém distância | Morteiro em arco **[PESADO]**. **Aviso: 1,0 s** (alvo marcado no chão). |
| **Muralha** | 40×64 | 150 | Médio + escudo-torre (bloqueia 100% pela frente) | Avança com o escudo erguido | Investida **[PESADO]** de 160 px. **Aviso: 0,8 s** (rugido e pé raspando o chão). Sem o escudo, cai e fica vulnerável por 1,5 s. |

A Muralha **ensina o Grilhão**: dá para pular por cima, jogar granada ou arrancar o escudo.

### 4.2 Enxame Vesh (pequenos, muitos, rápidos)
| Inimigo | Tamanho | Vida | Peso | Comportamento | Ataque e aviso |
|---|---|---|---|---|---|
| **Zangão** | 12×12, voa | 10 | Leve | Chega em grupos de 5 a 8 e circula | Mergulho em linha reta. **Aviso: 0,4 s** (para no ar e zumbe). |
| **Cuspidor** | 20×14, rasteja e escala paredes | 25 | Leve | Mantém média distância | Cusparada em arco que deixa uma **poça de ácido** no chão por 3 s. **Aviso: 0,5 s** (o corpo infla). |
| **Ninho** | 48×48, fixo | 200 | Pesado (dá para se puxar até ele) | Gera 1 Zangão a cada 4 s (até 6 vivos) | Não ataca. Tem um **ponto fraco** pulsante que leva o dobro de dano. |

### 4.3 Elites (salas Elite: 1 elite + ondas menores)
| Elite | Vida | Ataques e aviso |
|---|---|---|
| **Brutamontes Kharn** (48×72, armadura frontal, peso Pesado) | 400 | (a) Metralhadora giratória em varredura: um laser de mira mostra a linha **0,8 s** antes. Dá para passar por baixo com dash ou pular por cima. (b) Pisão **[PESADO]**: onda de choque no chão, **aviso de 0,7 s**, desviada com um pulo. **Ponto fraco:** o tanque de munição nas costas. |
| **Ceifadora Vesh** (32×40, rápida, peso Médio) | 250 | (a) Sequência de 3 cortes em avanço. **Aviso: 0,5 s** (as lâminas brilham). (b) Some na parede e reaparece do lado oposto: um **sinal no chão dura 0,6 s** antes. Puxada pelo Grilhão, fica atordoada por 1,0 s. |

### 4.4 Sala 5 — zona de guerra (Kharn × Vesh, D-026)
- Kharn e Vesh **atacam uns aos outros**. Cada inimigo escolhe o alvo mais próximo da lista de alvos (jogadores + facção rival), com **peso 2× para o jogador**.
- Morteiros Kharn ferem Vesh, e poças de ácido ferem Kharn.
- Ryker ganha **+5 Créditos** por inimigo morto pela facção rival.

### 4.5 Composição de ondas (referência; o banco de ondas segue o GD-03)
| Sala | Ondas (exemplo) |
|---|---|
| 1 Carcaça | 6 Zangões → 3 Cuspidores + 4 Zangões |
| 2 Linha Kharn | 2 Guerreiros → 1 Artilheiro + 2 Guerreiros |
| 3 Ninhos Vesh | 1 Ninho + 4 Cuspidores (ou a elite Ceifadora) |
| 5 Zona de guerra | 2 Guerreiros + 1 Muralha × 2 Ninhos + Zangões |
| 6 Elite | Brutamontes + 2 Guerreiros, ou Ceifadora + 6 Zangões |

**Teto de perigo simultâneo (D-026):** no máximo **3 ataques anunciados ao mesmo tempo** ("fichas de ataque").

## 5. Chefe — Ur-Kesh, Campeão do Clã Kesh
Arena plana de 2 telas de largura (960 px), com 2 plataformas altas e **3 pontos de ancoragem** no teto. Duração-alvo de 3 a 4 minutos.

### Fase 1 — o andador de guerra (vida: 1500)
| Ataque | Aviso | Como desviar |
|---|---|---|
| Varredura do Bramido (o canhão do braço) | Laser de mira, 0,8 s | Pular ou passar por baixo com dash |
| Salto com pisão **[PESADO]** | Sombra no ponto de pouso, 1,0 s. Depois, uma onda de choque nos dois sentidos. | Sair da sombra e pular a onda |
| Saraivada de mísseis | 5 alvos no chão, 1,2 s | Ficar entre os alvos |

**Ponto fraco:** o radiador nas costas do andador. Para alcançar, Ryker se puxa com o Grilhão até a perna do andador (peso Pesado) e usa o Golpe de Arena.

### Fase 2 — andador danificado (a partir de 66% da vida)
- Os ataques ficam 15% mais rápidos, mas **os avisos não diminuem**.
- A cada 12 s o andador **ajoelha** por 3 s e expõe o núcleo, que leva o triplo de dano.
- Uma nave Kharn deixa **2 Guerreiros de Clã** na arena. Eles param de vir quando o andador cai.

### Fase 3 — a pé, a revanche da arena (vida: 600)
Ur-Kesh sai do andador destruído. Ele tem ~2,5× a altura de Ryker e luta com um machado de energia. Falas no NAR-01.

| Ataque | Aviso | Como desviar |
|---|---|---|
| Avanço com machado **[PESADO]** | Ergue o machado, 0,7 s | Dash através dele |
| Machado arremessado (vai e volta como bumerangue) | Gira o machado acima da cabeça, 0,8 s | Pular a ida e a volta |
| Rugido do clã | Bate no peito, 1,0 s | Chama 4 Zangões atraídos pelo barulho |

**Contra-ataque de gladiador:** acertar Ur-Kesh com o Grilhão **enquanto ele ergue o machado** quebra a guarda dele: fica 2,0 s atordoado e leva o dobro de dano.

**Recompensa:** a Chave de Salto, 50 Núcleos, Dados de Inteligência e **1 Ponto de Aprimoramento** (vale para o ato seguinte; no VS a run termina aqui). **Na 1ª vitória, desbloqueia o Bramido** (Ryker o arranca do andador; Garrak o entrega no Arsenal, falas ARSE_B* do NAR-03).

## 6. Upgrades das facções (VS)
**Barra de Chamado:** enche com 1 ponto a cada 10 de dano causado. Com 100 pontos, o Chamado pode ser usado (cerca de um a cada 25 s de combate).

**Slot Tiro × árvore da arma (GD-05, seção 2.3):** os upgrades de Tiro mudam o **efeito** do acerto; a árvore muda o **comportamento** da arma. Efeitos que contam tiros usam `peso_disparo`; efeitos "ao acertar" usam `fator_efeito`.

### 6.1 Domínio Kharn — Impacto (10 upgrades)
| Slot | Nome | Efeito (Comum / Raro / Épico) |
|---|---|---|
| Tiro | **Munição de Clã** | A cada 5 tiros (contados por `peso_disparo`), o próximo disparo explode (raio de 24 px): 30 / 40 / 55 de dano, mais 25 de Abalo |
| Tiro | **Calibre Pesado** | +30 / 45 / 60% de dano, −15% de cadência, acertos empurram e causam 10 de Abalo (× `fator_efeito`). É a única exceção que mexe em cadência. |
| Granada | **Carga de Cerco** | Raio +50%, dano +40 / 70 / 100%, mais 100 de Abalo (atordoa direto) |
| Dash | **Investida do Clã** | O dash causa 20 / 30 / 45 de dano, empurra e causa 50 de Abalo |
| Ferramenta | **Corrente Rubra** | Ao acertar com a Ferramenta: explosão de 30 / 45 / 60 de dano em 32 px de raio |
| Chamado | **Bombardeio de Artilharia** | Caem 6 / 8 / 10 projéteis sobre os inimigos na tela, 60 de dano cada |
| Passivo | **Couro de Arena** | Anula o 1º acerto recebido em cada sala (Raro: recarrega em 40 s; Épico: em 25 s) |
| Passivo | **Honra do Campeão** | +15 / 25 / 35% de dano contra elites e chefes |
| Passivo | **Inabalável** | Inimigos atordoados levam +20 / 30 / 45% de dano a mais (soma com o bônus base de 25%) |
| Passivo | **Grito de Guerra** | Ao entrar em uma sala, os inimigos começam com 30 / 50 / 70 de Abalo |

### 6.2 Enxame Vesh — Multiplicação (10 upgrades)
| Slot | Nome | Efeito (Comum / Raro / Épico) |
|---|---|---|
| Tiro | **Ferrão Partido** | Ao acertar, o projétil se divide em 2 fragmentos com 35 / 50 / 65% do dano. A chance de dividir é 100% × `fator_efeito`. Fragmentos não se dividem de novo. |
| Tiro | **Ferrão Ácido** | 20 / 30 / 40% (× `fator_efeito`) de chance por acerto de aplicar 1 acúmulo de Ácido |
| Granada | **Ovo de Ninhada** | A granada libera 3 / 4 / 5 larvas que perseguem inimigos (10 de dano + 2 de Ácido cada) |
| Dash | **Rastro de Enxame** | O dash deixa uma trilha de ácido por 2 s (1 acúmulo a cada 0,5 s), com 15 / 22 / 30 de dano por segundo |
| Ferramenta | **Corrente Infestada** | O alvo acertado pela Ferramenta recebe 3 / 4 / 5 acúmulos de Ácido |
| Chamado | **Nuvem de Zangões** | 4 / 6 / 8 zangões aliados por 8 s, 8 de dano por mordida |
| Passivo | **Corpo Solto** | Ao matar, 10 / 15 / 20% de chance de surgir um zangão aliado (dura 10 s, máximo de 3) |
| Passivo | **Carne Mole** | Inimigos com 5 acúmulos de Ácido levam +25 / 35 / 50% de dano |
| Passivo | **Colmeia Faminta** | Inimigo que morre com Ácido vira uma poça que passa 2 / 3 / 4 acúmulos para quem estiver por perto |
| Passivo | **Nós Somos Muitos** | +4 / 6 / 8% de dano para cada aliado invocado ativo (zangões, larvas) |

Upgrades bloqueados no início (liberados pelos Arquivos, GD-03): Kharn *Calibre Pesado*, *Inabalável*, *Grito de Guerra*; Vesh *Ferrão Ácido*, *Colmeia Faminta*, *Nós Somos Muitos*.

### 6.3 Como as duas facções se combinam
- **Kharn** concentra dano em **poucos alvos grandes** (elites, chefe).
- **Vesh** espalha dano em **muitos alvos pequenos** (ondas, Zangões).
- Misturar as duas é sempre viável. Ex.: Carga de Cerco (atordoa) + Carne Mole (Ácido) contra a Muralha.

### 6.4 Upgrades de Aliança Kharn + Vesh → ver `GD/06-vigilios-e-aliancas.md`, parte B
São 6 Alianças com regras de pré-requisito e oferta. O sistema de upgrades precisa aceitar pré-requisitos com "ou".

### 6.5 Loja do mercador Ilo (D-020)
| Item | Preço (Créditos) |
|---|---|
| Upgrade aleatório (Kharn ou Vesh, escolhido antes da compra) | 80 |
| Cura de 1 bloco | 40 |
| **Aprimoramento de Arma** (1 ponto; no máximo 1 por loja) | 90 |
| Reroll da loja | 20 |

**Créditos no VS:** 2 a 5 por inimigo comum, 25 por elite, e a recompensa de Créditos na porta vale 40 a 60.

## 7. Requisitos de teste (para os testes automáticos do DEV, D-012)
1. O Grilhão puxa um alvo Leve, arranca a armadura de um alvo Médio e puxa Ryker até um alvo Pesado.
2. A armadura frontal reduz em 50% o dano pela frente e não reduz o dano por trás nem de explosões.
3. Com 100 de Abalo o inimigo fica atordoado, e o Abalo zera em seguida.
4. O Ácido acumula até 5 e renova a duração.
5. Um ataque [PESADO] tira 2 blocos, e a invulnerabilidade pós-dano impede dano em sequência.
6. O teto de 3 ataques anunciados ao mesmo tempo é respeitado.
7. Um upgrade novo substitui o anterior no mesmo slot, e os Passivos se acumulam.
8. A barra de Chamado enche 1 ponto a cada 10 de dano.

Os testes das armas e da árvore estão no GD-05, seção 6. Os das Alianças, no GD-06, seção B.3.

## 8. Números do DEV confirmados (D-037) — conferidos no código da `main`
Conferidos em `scripts/inimigos/guerreiro_cla.gd`, `scripts/armas/dados_granada.gd`, `scripts/jogador/grilhao.gd` e `scripts/comum/regras_combate.gd`. **Todos ficam como oficiais**, sem mudança:

| Item | Valor |
|---|---|
| Guerreiro: velocidade de avanço | 1,25 tiles/s (20 px/s) |
| Guerreiro: distância preferida do alvo | 7 tiles |
| Guerreiro: alcance para iniciar o ataque | 16 tiles na horizontal × 8 na vertical |
| Guerreiro: intervalo entre os tiros da rajada | 0,18 s |
| Guerreiro: descanso depois da rajada | 1,6 s (ciclo completo de ~2,6 s) |
| Guerreiro: dano por tiro | 1 bloco |
| Granada: arremesso, gravidade e empurrão | 9 × 13 tiles/s; 38 tiles/s²; 10 tiles/s |
| Grilhão em Médio sem proteção | 15 de dano + 0,6 s de cambaleio |
| Abalo: atraso e velocidade de queda | 0,5 s; 20 pontos/s |

**Motivo:** o ciclo de ~2,6 s do Guerreiro deixa janelas claras para avançar e puxar a armadura, e o arco da granada alcança a mureta do Ninho jovem da sala 0 (GD-03, trecho 7). QA pode pedir ajuste depois do playtest.
