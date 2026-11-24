# GD-01 — Design do ciclo da run (v0.4)

Autor: Game Design (GD) · Segue as decisões oficiais da CENTRAL (D-001 a D-038).
Inimigos, chefe, upgrades e kit do Ryker estão em `GD/02-combate-ato1.md`. Salas e desbloqueios estão em `GD/03-salas-e-desbloqueios.md`. **Armas e árvores estão em `GD/05-armas.md`.**

**Mudanças desde a v0.3:** ajustado para a mudança de 2026-11-13 14:35 (D-038). As armas pesadas saíram. A seção 5 agora aponta para o GD-05. A porta "Arma pesada" virou "Aprimoramento de Arma".

---

## 0. Resumo em uma frase
Ryker sai da nave Eco, cai em um planeta dentro de uma cápsula e atravessa salas de combate curtas no estilo Metal Slug. No caminho, as facções alienígenas oferecem upgrades e a arma dele evolui. Quando morre, a Eco o reconstrói, e ele gasta o que trouxe para ficar um pouco mais forte e descobrir um pouco mais da história.

## 1. O loop

```
NAVE ECO ──► ARSENAL (escolhe 1 arma: a própria ou uma universal)
   ▲                 │
   │                 ▼
   │          CÁPSULA DE POUSO ──► ATO (planeta): ~8 salas + chefe
   │                                   │
   │   morte → RECONSTRUÇÃO ◄──────────┤
   │   (Eco volta a Varrek)            │ vitória no chefe → Chave de Salto
   └── gasta Núcleos / Dados ◄─────────┴──► a Eco salta → próximo planeta (mesma run)
                                            [VS: fim da run após o Ato 1]
```

**Duração-alvo:** um Ato leva de 10 a 15 min. Uma run completa (~4 atos) leva de 45 a 60 min.

## 2. Run de vários planetas (D-013, D-025)
- Uma run atravessa **Ato 1 → Ato 2 → Ato 3 → Ato 4**, mantendo os upgrades, a árvore da arma, a vida e os Créditos de um planeta para o outro.
- Vencer o chefe entrega a Chave de Salto (D-035), e a nave salta para o próximo planeta. Entre um ato e outro há uma **pausa curta na nave** (só diálogo, sem a loja de melhorias permanentes), seguida de uma nova queda de cápsula.
- Na morte, a Chave volta ao altar e a Eco volta a Varrek. A próxima run começa no Ato 1.
- **Final verdadeiro (D-034):** depois de 3 vitórias, a Ruptura (GD-04).
- **Vertical Slice:** só o Ato 1. Vencer Ur-Kesh mostra a tela de "missão cumprida", com a recompensa completa e diálogo novo. A 1ª vitória desbloqueia a 1ª arma universal (GD-05).

## 3. Controles (D-017, D-027)
Pensados primeiro para **gamepad**, com suporte completo a teclado. A mira é fixa em 8 direções, sem mouse.

| Ação | Teclado | Gamepad |
|---|---|---|
| Mover / mirar | A D (W cima, S agachar/baixo) ou setas | Analógico esquerdo ou D-pad |
| Pular | Espaço | A |
| Atirar | J | X (segurar = fogo contínuo ou carga, conforme a arma) |
| Dash / rolamento | Shift ou L | B |
| Granada | K | Y |
| Ferramenta (Grilhão, no caso do Ryker) | O | LB |
| Travar mira (fica parado e mira em 8 direções) | Segurar I | RB |
| Chamado (especial de facção) | U | RT |
| Interagir / escolher | E | A (perto do objeto) |

- Dash com invulnerabilidade curta. Todo perigo pode ser evitado com habilidade (pilar 1).
- Mirar para baixo **no ar** atira para baixo, como no Metal Slug.
- **Golpe corpo a corpo automático** com a corrente quando um inimigo está colado (GD-02).

### 3.1 Assistências: mira automática e tiro automático (D-017)
São duas opções **independentes** em Opções → Assistências, que podem ser trocadas a qualquer momento. **Elas não reduzem recompensas.**

| Mira automática | Comportamento |
|---|---|
| Desligada | Mira manual em 8 direções (padrão) |
| Assistida | O jogador mira e o jogo corrige para a direção vizinha (±45°) quando há um inimigo nela |
| Total | O jogo escolhe o alvo e mira sozinho, sempre em uma das 8 direções |

- **Prioridade de alvo:** (1) o inimigo que está anunciando um ataque, (2) o mais próximo, (3) o mais próximo da linha de mira atual. Objetos destrutíveis são ignorados.
- **Alvo "grudento":** o alvo só muda quando morre, sai da tela ou quando outro inimigo fica pelo menos 40% mais perto.
- **Travar mira sempre vence a assistência.**
- A mira automática também guia o Grilhão.
- A assistência mira no centro do corpo. **Pontos fracos** só são acertados de propósito, com mira manual ou travada, ou com o Grilhão.
- Um marcador discreto mostra o alvo atual.

**Tiro automático:** a arma atira sozinha quando há um inimigo na linha de mira e na tela. Nas armas com carga, ela carrega sozinha e dispara quando a carga completa (GD-05, seção 2.4). Granada, dash, Grilhão e Chamado nunca são automáticos.

**Regra para todo o design:** nada pode exigir mira rápida para ser possível. A habilidade cobrada está em **posicionamento, desvio e escolhas**.

### 3.2 Parâmetros iniciais (tile de 16 px, D-005)
| Parâmetro | Valor |
|---|---|
| Corrida | 112 px/s (7 tiles/s), aceleração em 0,05 s, frenagem em 0,04 s |
| Pulo | altura máxima de 56 px (3,5 tiles), subida até o topo em 0,35 s → gravidade de subida ≈ 915 px/s², velocidade inicial ≈ 320 px/s |
| Queda | gravidade ×1,6 na descida, velocidade máxima de queda 400 px/s |
| Pulo variável | soltar o botão corta a velocidade de subida para ×0,45 |
| Coyote time / buffer de pulo | 0,10 s / 0,10 s |
| Dash | 48 px em 0,18 s, 0,15 s de invulnerabilidade, 1 carga, recarga de 0,7 s contada a partir do fim do dash (D-027), funciona no ar (1 vez por pulo) |
| Pós-dano | 0,8 s de invulnerabilidade, com o personagem piscando |
| Mira automática | alcance de 1 tela; troca de alvo com 40% de diferença de distância |

Grilhão e inimigos: GD-02. Armas: GD-05.

## 4. Vida e fragilidade (D-017)
- **4 blocos de vida** (no HUD, 4 elos de corrente, D-033). Um ataque comum tira 1 bloco e um ataque pesado tira 2.
- A cura é rara: salas de Reparo, itens específicos e alguns upgrades.
- **Sinal de Emergência** (melhoria permanente): Ryker volta 1 vez por run com 2 blocos.
- Inimigos enormes com barras grandes contra 4 blocos do humano (pilar 3).

## 5. Armas (D-038) → detalhes no GD-05
- Antes da run, o jogador escolhe **1 arma** no Arsenal: a **própria** do personagem ou uma **universal** já desbloqueada pela história. Não se troca de arma durante a run.
- **Munição infinita. Não há armas pesadas** nem armas que caem na fase.
- Cada arma tem uma **assinatura** (regra própria sempre ativa) e uma **mini árvore** (3 ramos × 3 nós). A árvore evolui com os Pontos de Aprimoramento e zera no fim da run.
- **No VS:** o Rifle da Arena (do Ryker) e o Canhão do Campeão (universal Kharn, ganho ao vencer Ur-Kesh pela 1ª vez). Os nomes são provisórios até a NAR definir.
- Os veículos ficam para a Fase 3, e as salas já reservam espaço para eles.

## 6. Upgrades das facções (D-008, D-014, D-026)

### 6.1 Slots
| Slot | O que modifica |
|---|---|
| **Tiro** | O **efeito** dos acertos da arma (status, explosões, divisão). O comportamento da arma é da árvore (GD-05, seção 2.3). |
| **Granada** | Granada |
| **Dash** | Dash |
| **Ferramenta** | A habilidade do personagem (o Grilhão, no caso do Ryker). O texto é genérico, para servir aos 3 personagens. |
| **Chamado** | Especial: a facção intervém. Usa a barra de Chamado, que enche causando dano. |
| **Passivo** | Efeitos gerais |

Cada slot (exceto Passivo) aceita **1 upgrade**. Escolher outro para o mesmo slot **substitui** o anterior, e a tela mostra isso antes da escolha. Os Passivos se acumulam.

Só o humano consegue misturar dádivas de raças diferentes, o que justifica os combos (Upgrades de Aliança, Fase 3).

### 6.2 Facções
| Raça | Mecânica-assinatura | Status que aplica |
|---|---|---|
| **Domínio Kharn** (VS) | Impacto: dano alto, explosões, empurrão | **Abalo** → atordoamento |
| **Enxame Vesh** (VS) | Multiplicação: divisão, drones, invocações | **Ácido** (acumula) |
| **Sindicato Ilo** (Ato 2) | Energia e lucro: ricochete, crítico, escudo, economia | — |
| Raças mágicas (D-030, Fase 3) | Feitiços, bênçãos e maldições, com regras tão claras quanto as tecnológicas | a definir |

A lista completa de upgrades do VS está no GD-02.

### 6.3 Como o upgrade aparece
- A recompensa de facção mostra **3 opções** da mesma facção, e o jogador escolhe 1.
- Raridade: **Comum / Raro / Épico**. Muda o valor do efeito, não o efeito. Chances no VS: 70% / 25% / 5%. Salas Elite garantem Raro ou melhor.
- O ícone da facção aparece na porta antes de entrar.

### 6.4 Rivalidade entre facções (Fase 3)
Aceitar muitos upgrades de uma facção deixa a rival mais agressiva naquele planeta. Fica para avaliar depois do VS.

## 7. Estrutura do Ato

### 7.1 Formato das salas
Cada sala é um **trecho curto de rolagem lateral (30 a 60 s)** que termina em uma **trava de câmera com ondas de inimigos**. Depois de limpar a sala, aparecem **2 ou 3 saídas**, cada uma mostrando a recompensa. As salas são montadas à mão e sorteadas de um banco por planeta (regras no GD-03). Algumas têm **pontos de ancoragem** para o Grilhão.

### 7.2 Tipos de sala
| Tipo | Conteúdo |
|---|---|
| Queda | Sala 0: a cápsula cai e o jogador aprende os controles (GD-03). |
| Combate | Padrão. A recompensa aparece na porta. |
| Elite | Um inimigo de elite mais ondas. Recompensa Rara ou melhor. |
| Loja | Mercador Ilo genérico (D-020). Gasta Créditos. |
| Reparo | Cura 2 blocos **ou** dá um upgrade extra (o jogador escolhe). |
| Chefe | Fim do Ato. Dá 1 Ponto de Aprimoramento garantido. |

### 7.3 Mapa do Ato 1 — Varrek, o Cemitério
```
0 Queda (campo de queda) → 1 Combate (carcaça de cruzador) → 2 Combate (linha de frente Kharn)
  → 3 Combate/Elite (ninhos Vesh) → 4 Loja ou Reparo
  → 5 Combate (zona de guerra Kharn × Vesh) → 6 Elite → 7 Reparo (aproximação da relíquia)
  → 8 CHEFE: Ur-Kesh
```
Na sala 5, **Kharn e Vesh lutam entre si** (D-026).

### 7.4 Recompensas que podem aparecer na porta
Upgrade Kharn · Upgrade Vesh · **Aprimoramento de Arma** · Créditos · +1 bloco de vida máximo · Núcleos · Dados de Inteligência. Regras de sorteio no GD-03, seção 2.6.

## 8. Recursos (D-015)
| Recurso | Escopo | Uso | Na morte |
|---|---|---|---|
| **Créditos** | Run | Loja do mercador Ilo | Perdidos |
| **Pontos de Aprimoramento** | Run | Árvore da arma (GD-05) | Perdidos |
| **Núcleos** | Permanente | Melhorias permanentes (Vossa Margem) | Mantidos |
| **Dados de Inteligência** | Permanente | Desbloqueios (GD-03) | Mantidos |

São no máximo 2 recursos permanentes, como manda a D-015.

**Ganho de Núcleos no VS:** uma run fraca (morte nas salas 1 a 3) rende cerca de 15 a 25, uma run média cerca de 40 a 60, e vencer o chefe rende mais 50.

## 9. Nave Eco e meta-progressão

### 9.1 Áreas (VS)
| Área | Função | Personagem |
|---|---|---|
| Reconstrutor | Onde Ryker reaparece | ECO |
| Arsenal | Escolhe a arma da run; entrega das armas universais | Garrak |
| Compartimento Ilo | Melhorias permanentes com Núcleos | Vossa Margem |
| Ponte | Diálogos, história e desbloqueios com Dados | ECO, Sete |
| Hangar | A cápsula: inicia a run | — |

### 9.2 Melhorias permanentes (VS)
| Melhoria | Efeito | Níveis | Custo (Núcleos) |
|---|---|---|---|
| Blindagem | +1 bloco de vida máximo | 2 | 40 / 90 |
| Sinal de Emergência | Volta 1 vez por run | 1 | 120 |
| Cinto de Granadas | +1 granada por sala | 2 | 30 / 70 |
| Propulsores | +1 carga de dash | 1 | 80 |
| Contato no Mercado | Começa a run com 30 Créditos por nível | 3 | 20 / 40 / 60 |
| Recalibrar | 1 reroll de recompensa por run | 2 | 50 / 100 |

O total é **870 Núcleos** (D-026). **A melhoria permanente ajuda, mas não substitui a habilidade.**

### 9.3 Dificuldade opcional (Fase 3)
O "Nível de Alerta" (o *Heat* do Hades) aumenta a dificuldade em troca de mais recompensa.

## 10. Checagem contra os pilares
| Pilar | Como o design atende |
|---|---|
| 1. Caos controlado | Dash com invulnerabilidade, 8 direções legíveis, assistências, todo ataque anunciado antes, teto de 3 avisos ao mesmo tempo |
| 2. Toda run conta | Núcleos e Dados sempre voltam, história avança a cada morte, a 1ª vitória dá uma arma nova |
| 3. Pequeno entre gigantes | 4 blocos contra inimigos enormes, poder emprestado das raças, o Grilhão puxa Ryker até o gigante, a arma universal Kharn é o canhão de um gigante adaptado por um humano |

## 11. Co-op local (D-018) — fora do VS, código preparado
- O jogador é uma **instância** (P1, P2), nunca um objeto único global.
- O input é separado por dispositivo/jogador.
- A câmera aceita vários alvos.
- Vida, upgrades, **arma e árvore**, barra de Chamado e HUD por jogador.
- Inimigos escolhem alvo a partir de uma **lista de alvos**, que inclui a facção rival (sala 5).

As regras de jogo do co-op ficam para depois do VS.
