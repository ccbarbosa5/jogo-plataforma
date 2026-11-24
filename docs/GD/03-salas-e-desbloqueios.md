# GD-03 — Sala 0, montagem das salas e desbloqueios (v0.2)

Autor: Game Design (GD) · Base: GD-01 v0.4, GD-02 v0.2, GD-05 v0.1, NAR-01, D-013 a D-038.
Status: aprovado em D-036, com ajustes nesta versão. Números iniciais, que serão ajustados nos playtests.

**Mudanças desde a v0.1:** ajustado para a mudança de 2026-11-13 14:35 (D-038). A porta "Arma pesada" virou **"Aprimoramento de Arma"**. Nos desbloqueios, a Escopeta sai (o Canhão do Campeão agora é ganho pela história) e entra o **Treino com Garrak**.

---

## 1. Sala 0 — A Queda (tutorial)

### 1.1 Princípios
- **Ensinar jogando, sem paredes de texto.** Cada lição é um obstáculo que só passa quem usa a ação. Um ícone do botão aparece perto do obstáculo (teclado ou gamepad, conforme o dispositivo em uso) e some depois que a ação é usada.
- **As regras de dano são as normais.** Os inimigos são poucos e fracos, então morrer na sala 0 é raro. Se acontecer, vale como run normal.
- Dura **2 a 3 min na 1ª run** e **15 a 20 s nas runs seguintes**.

### 1.2 Roteiro da 1ª run (as falas são as do NAR-01, seção 3)
| # | Trecho | Lição | Obstáculo | Fala |
|---|---|---|---|---|
| 1 | Cápsula cai (cena de 4 s; dá para pular a partir da 2ª vez) | — | — | QUED_01 ao sair da cápsula |
| 2 | Deserto de ferro | Mover e pular | Destroços com degraus de 1 a 3 tiles e um buraco de 3 tiles | — |
| 3 | Carcaça baixa | Atirar e agachar | 3 Zangões vêm pela frente, e depois um cano de vapor na altura da cabeça, que só passa agachado | QUED_04 na 1ª morte de inimigo |
| 4 | Poço entre cascos | Atirar para cima e para baixo no ar | 2 Zangões parados acima, e depois 1 Cuspidor no chão de um poço (pular e atirar para baixo) | — |
| 5 | Parede de casco | **Grilhão** em ponto de ancoragem | Uma parede de 6 tiles que só se sobe com o Grilhão até um gancho marcado | QUED_03 no 1º uso |
| 6 | Corredor de tiro | **Dash** | Um **Guerreiro de Clã** atrás de uma barricada atira rajadas num corredor estreito; é preciso passar pelos tiros com dash | QUED_02 antes de ele aparecer |
| 7 | Ninho pequeno | Granada | Um Ninho jovem (vida 80) atrás de uma mureta, que só granada alcança. Depois de destruído, solta Créditos. | — |
| 8 | Mini-arena | Tudo junto | Câmera trava: 1 onda (Guerreiro + 4 Zangões) | — |
| 9 | Saída | Escolher a porta | **2 portas, uma Kharn e uma Vesh**, para garantir o primeiro upgrade e a primeira cena de patrona (NAR-01, seções 4 e 5) | — |

**Assistências:** quando o jogador entra no trecho 3 pela primeira vez, aparece uma única nota no canto, que some sozinha: "Mira e tiro automáticos: Opções → Assistências". Ela nunca mais aparece.

**Árvore da arma:** a primeira porta "Aprimoramento de Arma" da 1ª run (a partir da sala 2) abre a tela da árvore com **um único destaque piscando** no nó 1 de cada ramo, sem texto de tutorial.

### 1.3 Runs seguintes
- A cápsula cai em **1 de 3 variantes curtas** de campo de queda (mesmo bioma, 1 tela e meia cada).
- 1 onda pequena (orçamento de ameaça 4, ver 2.4), sem ícones de botão.
- A saída tem **2 portas**, com as recompensas seguindo a seção 2.6.

## 2. Regras de montagem das salas

### 2.1 Anatomia de uma sala
```
[ENTRADA] → [TRECHO] ×1–3 → [ARENA] → [SAÍDA com portas]
  ½ tela      1 tela cada    1–2 telas   ½ tela
```
- **Entrada (entrada justa, D-036):** chão plano, nenhum inimigo a menos de 6 tiles, e 1,0 s de invulnerabilidade ao entrar. Nunca se toma dano no primeiro segundo de uma sala (pilar 1).
- **Trecho:** rolagem lateral com inimigos **colocados à mão** no bloco. Não trava a câmera.
- **Arena:** a câmera trava e as ondas vêm do **banco de ondas** (2.4).
- **Saída:** as portas aparecem quando a última onda morre.

### 2.2 Regra de encaixe dos blocos (para que qualquer bloco encaixe em qualquer outro)
| Regra | Valor |
|---|---|
| Altura da tela | 17 tiles (270 px). O chão de conexão fica sempre na **linha 14** (contando de cima, começando em 0). |
| Bordas | Toda borda esquerda e direita tem **chão na linha 14 e 4 tiles livres acima dele**. |
| Largura | Múltiplos de meia tela (15 tiles). |
| Teto | Nenhum bloco tem teto abaixo da linha 6, para os pulos e os Zangões terem espaço. |
| Buracos | Buracos sem fundo só em trechos, nunca em arenas, e com no máximo 4 tiles (o pulo alcança 5,5 tiles com dash). Cair num buraco tira 1 bloco de vida e devolve Ryker à última plataforma (D-036). |

### 2.3 Etiquetas de cada bloco
| Etiqueta | Valores |
|---|---|
| bioma | queda, carcaça, linha_kharn, ninhos_vesh, zona_guerra, reliquia |
| tipo | entrada, trecho, arena, saída |
| largura | em meias telas |
| dificuldade | 1, 2 ou 3 |
| tags | `ancoragem` (tem gancho para o Grilhão), `plataforma_alta`, `apertado` (pouco espaço vertical), `cobertura` |
| pontos de surgimento (só arenas) | chão_esq, chão_dir, ar, parede, fundo (onde surge o Artilheiro) |

### 2.4 Orçamento de ameaça e banco de ondas
**Custo de cada inimigo:**
| Inimigo | Custo |
|---|---|
| Zangão | 1 |
| Cuspidor | 2 |
| Guerreiro de Clã | 4 |
| Artilheiro Kharn | 4 |
| Muralha | 5 |
| Ninho | 6 |
| Elite | 12 |

**Orçamento de cada sala (Ato 1):**
| Sala | 0 (repetição) | 1 | 2 | 3 | 5 | 6 (elite) |
|---|---|---|---|---|---|---|
| Orçamento | 4 | 8 | 10 | 12 | 16 | 12 + elite |

- **O banco de ondas é feito à mão.** Cada onda tem custo, bioma, facção e pontos de surgimento. O gerador **sorteia ondas do banco** até gastar o orçamento, em **2 ou 3 ondas** por arena.
- **Próxima onda:** entra quando sobra 25% ou menos do custo da onda atual, ou depois de 20 s.
- **Surgimento justo:** nenhum inimigo surge a menos de 6 tiles de Ryker. Todo inimigo surge com uma **animação de entrada de 0,5 s**, durante a qual não ataca.
- As fichas de ataque valem sempre (teto de 3, D-026).
- Na **sala 5** o banco usa ondas mistas Kharn × Vesh, com as regras de briga entre facções (GD-02, seção 4.4).

### 2.5 Ordem das salas
A ordem segue o mapa do GD-01, seção 7.3. O que é sorteado: os blocos de cada sala, as ondas e as recompensas das portas. Uma mesma run nunca repete um trecho ou uma arena.

### 2.6 Recompensas nas portas
- Salas 1 e 2 têm **2 portas**; as demais têm **3**.
- **Nunca duas portas com o mesmo tipo de recompensa** na mesma saída.
- **Garantia de facção:** nenhum trecho fica mais de 2 salas seguidas sem uma porta de upgrade de facção.
- **Aprimoramento de Arma** (1 Ponto de Aprimoramento, GD-05): **no máximo 3 portas por ato, nunca na sala 1**. Garantia: se até a sala 5 nenhuma porta de Aprimoramento tiver aparecido, a saída da sala 5 mostra uma.
- **Núcleos ou Dados:** cerca de 30% das portas.
- **+1 bloco de vida máximo:** no máximo 1 por ato, e só a partir da sala 3.
- A **sala 4** sorteia entre Loja e Reparo. A **sala 7** é sempre Reparo.
- O **chefe** dá 1 Ponto de Aprimoramento garantido (GD-02, seção 5).

### 2.7 Banco mínimo de blocos para o VS
| Bioma | Trechos | Arenas | Outros |
|---|---|---|---|
| Queda | — | — | 1 sala 0 completa (1ª run) + 3 variantes curtas |
| Carcaça (sala 1) | 4 | 2 | — |
| Linha Kharn (sala 2) | 4 | 2 | — |
| Ninhos Vesh (sala 3) | 4 | 2 | — |
| Zona de guerra (sala 5) | 3 | 2 | — |
| Elite (salas 3 e 6) | — | 2 | — |
| Fixas | — | — | Loja, Reparo, Aproximação da relíquia (sala 7), Arena do chefe |

São cerca de **19 trechos, 10 arenas e 7 salas fixas**. Cada sala tem pelo menos 4 × 2 combinações possíveis, fora a variação das ondas.

### 2.8 Pontos de ancoragem e segredos
- Cerca de 1 em cada 3 trechos tem um **atalho alto** alcançável com o Grilhão.
- Alguns atalhos levam a um **Terminal dos Antigos**, que dá **+3 Dados de Inteligência**. Isso recompensa explorar, sem ser obrigatório.

## 3. Desbloqueios com Dados de Inteligência

### 3.1 De onde vêm os Dados
| Fonte | Quantidade |
|---|---|
| Porta com recompensa de Dados | 8 a 12 |
| Matar uma elite | 5 |
| Terminal dos Antigos (segredo) | 3 |
| Primeira vitória sobre Ur-Kesh | 25 (nas vitórias seguintes: 10) |

Uma run média rende de 10 a 25 Dados. A NAR pode chamar alguns deles de "amostras" no texto (D-036).

### 3.2 Onde se gasta
- **Arsenal (Garrak):** treino com armas.
- **Ponte (ECO):** o "Arquivo", que guarda conhecimento das facções e das rotas.

**As armas universais não custam Dados:** elas são desbloqueadas pela história (D-038; o Canhão do Campeão vem na 1ª vitória sobre Ur-Kesh).

### 3.3 Lista de desbloqueios do VS
| Desbloqueio | Onde | Custo | Efeito |
|---|---|---|---|
| **Treino com Garrak** | Arsenal | 30 | Começa toda run com **1 Ponto de Aprimoramento** (GD-05) |
| Arquivo Kharn | Ponte | 25 | Adiciona 3 upgrades Kharn ao sorteio (de 7 para 10) |
| Arquivo Vesh | Ponte | 25 | Adiciona 3 upgrades Vesh ao sorteio (de 7 para 10) |
| Rotas de Varrek I | Ponte | 20 | +1 trecho e +1 arena em cada bioma |
| Rotas de Varrek II | Ponte | 35 | Mais +1 trecho e +1 arena em cada bioma (o banco completo da seção 2.7) |
| Leitura de Sinal | Ponte | 40 | Mostra a recompensa da sala **seguinte** à porta escolhida |

O total é **175 Dados**, o que dá cerca de 8 a 12 runs, no mesmo ritmo dos Núcleos.

**Os upgrades bloqueados no começo** (entram com os Arquivos) são os de efeito mais avançado, para não sobrecarregar a primeira run:
- Kharn: *Calibre Pesado*, *Inabalável*, *Grito de Guerra*.
- Vesh: *Ferrão Ácido*, *Colmeia Faminta*, *Nós Somos Muitos*.

**Até o Rotas I ser comprado, o banco começa menor:** 2 trechos e 1 arena por bioma. As primeiras runs são mais previsíveis (aprendizado), e a variedade cresce com o progresso (pilar 2).

### 3.4 Registro automático (sem custo)
Inimigos, upgrades, armas e personagens vistos entram sozinhos num **Códice** na Ponte, com texto da NAR. Ver coisas novas já é progresso (pilar 2).

## 4. Requisitos de teste (para o DEV)
1. Nenhum inimigo surge a menos de 6 tiles do jogador, e nenhum ataca durante a animação de entrada.
2. O gerador nunca passa do orçamento e nunca repete um trecho ou uma arena na mesma run.
3. Nunca há duas portas com o mesmo tipo de recompensa, e a garantia de facção a cada 2 salas é respeitada.
4. Todo bloco tem chão na linha 14 nas duas bordas (teste que valida os arquivos de bloco).
5. Os Dados persistem depois da morte, e os desbloqueios mudam o sorteio de upgrades e o banco de salas.
6. A porta de Aprimoramento aparece no máximo 3 vezes por ato, nunca na sala 1, e a garantia da sala 5 funciona.
