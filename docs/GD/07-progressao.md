# GD-07 — Progressão (D-058) e mira 360° (D-052) · v0.1

Autor: GD · Atende aos itens GD-1 e GD-2 da CENTRAL (seção 5).
**O que este doc substitui:** a árvore de arma, as assinaturas, os Pontos de Aprimoramento e a porta e a loja de Aprimoramento (GD-05, seções 2, 4 e 8); a lista de melhorias permanentes (GD-01, seção 9.2); o Grilhão (GD-02, seção 1.1); a mira em 8 direções (GD-01, seção 3). Os upgrades de facção e o Chamado continuam iguais.
Unidades: 1 tile = 16 px. Todos os números são iniciais, para ajustar no playtest.

---

## 1. Armas base, sem assinatura (item e)
No nível 1 as armas só atiram. Não há Embalo nem Coice. `peso_disparo` e `fator_efeito` continuam, porque os upgrades de facção dependem deles.

| Campo (`DadosArma`) | Mordida | Bramido |
|---|---|---|
| `cadencia` (disparos/s) | 8,0 | 1,5 |
| `dano` | 10 | 9 por balim |
| `projeteis_por_tiro` | 1 | 6 |
| `velocidade_projetil` (tiles/s) | 37,5 | 25,0 |
| `duracao_projetil` (s) | 1,0 | 0,2 (alcance de 80 px) |
| `espalhamento_graus` (para cada lado) | 0 | 15 |
| Queda de dano | — | −50% a partir de 48 px |
| `peso_disparo` | 1,0 | 2,5 |
| `fator_efeito` | 1,0 | 0,35 |

## 2. Grilhão refeito (item d)
- **Não interrompe o tiro.** Ryker lança a corrente com o botão direito, na direção do mouse, e continua atirando. Também atira durante a puxada.
- **Base:** alcance de 96 px · viagem de 0,12 s · **1 carga** · recarga de 3,0 s contada a partir da volta (1,0 s se errar) · **10 de dano**.
- **Marca:** todo alvo acertado fica **Marcado por 4 s** e leva **+25% de dano dos tiros** (só da arma).

| Alvo | Efeito |
|---|---|
| Leve | Puxado até 24 px do Ryker e atordoado por 1,0 s |
| Médio com escudo ou placa | Perde a proteção pelo resto da luta e cambaleia por 0,6 s |
| Médio sem proteção | Cambaleia por 0,6 s. Se estiver numa plataforma acima do Ryker, é **derrubado** (puxão de 2 tiles na direção dele) |
| Pesado, elite ou ponto de ancoragem | **Puxa o Ryker** até o alvo (gancho), com invulnerabilidade durante a puxada e por 0,2 s depois |

O Golpe de Arena sai do jogo (o lugar dele passa a ser da Marca). O contra-ataque em Ur-Kesh continua: acertar o Grilhão quando ele ergue o machado o deixa atordoado por 2,0 s.

## 3. Árvore Passiva — permanente, igual para todos (item a)
Fica com Vossa Margem, na nave, e é comprada com Núcleos. Cada nível exige o anterior. Substitui a lista de melhorias permanentes do GD-01, seção 9.2.

| Ramo | Nó | Efeito por nível | Níveis | Custo (Núcleos) |
|---|---|---|---|---|
| **Corpo** | Blindagem | +1 bloco de vida máximo | 2 | 40 / 90 |
| | Sinal de Emergência *(exige Blindagem 1)* | Volta 1 vez por run com 2 blocos | 1 | 120 |
| **Movimento** | Passada | +5% de velocidade de corrida | 2 | 30 / 60 |
| | Pernas de Mineiro | +6% de altura do pulo | 2 | 30 / 60 |
| | Propulsores | −0,1 s na recarga do dash | 2 | 40 / 80 |
| **Fortuna** | Contato no Mercado | Começa a run com +30 Créditos | 3 | 20 / 40 / 60 |
| | Recalibrar | +1 reroll por run (vale para portas e Gambiarras) | 2 | 50 / 100 |
| | Memória da Âncora | +10% de XP | 3 | 40 / 70 / 100 |
| | Coleta Fina | +10% de Núcleos | 2 | 60 / 120 |

**Total: 1.210 Núcleos.** A renda de Núcleos não muda (GD-01, seção 8). Isso dá cerca de 20 a 25 runs para completar tudo. O Cinto de Granadas saiu desta lista e foi para a árvore de Combate.

## 4. Árvore de Combate do Ryker — permanente, por nível (item b)

### 4.1 XP e nível
- **XP por inimigo:** Zangão 2 · Cuspidor 3 · Guerreiro de Clã 6 · Artilheiro 6 · Muralha 8 · Ninho 10 · elite 30 · Ur-Kesh 120 (+100 só na 1ª vitória).
- **XP para subir do nível n para n+1:** `60 + 20 × n`. Do nível 1 ao 2 são 80; do 9 ao 10, 240.
- **Nível máximo: 25.** **1 ponto por nível**, ou seja, 24 pontos no máximo.
- **O XP e o nível são permanentes:** a morte não tira nada (pilar 2). Uma run do VS rende ~150 XP numa derrota cedo e ~420 numa vitória. Isso dá cerca de nível 5 depois de 2 a 3 runs, nível 10 depois de 5 a 6, e nível 25 só no jogo completo.
- O XP aparece no fim da run, na tela de reconstrução, e não no HUD durante o combate.

### 4.2 Regras
- **Abre só na nave**, no Arsenal com Garrak. **Redistribuir é grátis** entre as runs. Nada muda durante a run.
- Em cada ramo, os nós são comprados **em ordem**.
- **Custo dos nós:** 1, 1, 2, 2 e Ápice 3 (o ramo do Dash tem só 3 nós: 1, 2, 2).
- **No máximo 2 Ápices na build.**
- O ramo da arma que não foi levada na run fica inativo. Com 24 pontos e 9 por ramo, nunca dá para ter tudo: o jogador escolhe entre **build de arma** e **build de habilidades**.

### 4.3 Ramos
| Ramo | Nó 1 (1) | Nó 2 (1) | Nó 3 (2) | Nó 4 (2) | Ápice (3) |
|---|---|---|---|---|---|
| **Mordida** | Rebite Afiado: +15% de dano | Gatilho de Mina: +15% de cadência | Perfurante: o tiro atravessa 1 inimigo | Três Golpes: o 3º acerto seguido no mesmo alvo é crítico (×2) | **Grande Arena:** cada 10º tiro é um rebite de 40 de dano que atravessa tudo (×2 em elites e chefes) |
| **Bramido** | Balins Pesados: +15% de dano | Boca Larga: +2 balins, ±20° | Abre-Couraça: acertar a 24 px ou menos quebra a armadura frontal por 3 s | Cano Duplo: carregador de 2 (0,15 s entre os disparos, 0,9 s para recarregar) | **Recuo de Gladiador:** o disparo empurra o Ryker 24 px para trás, mais um impulso no ar 1 vez por pulo |
| **Granada** | Cinto: +1 granada por sala | Pavio Curto: +25% de raio | Estilhaços: a explosão solta 4 estilhaços de 10 de dano | Recarga de Campo: a cada 3 mortes, +1 granada (até o limite da sala) | **Bomba de Fragmentação:** a explosão solta 3 granadas menores (25 de dano, 24 px) |
| **Grilhão** | Corrente Longa: alcance de 128 px | Marca Funda: Marca de +40% por 6 s | Duas Cargas: +1 carga | Arrastão: puxa até 3 inimigos leves a até 32 px do alvo; médios passam a ser puxados (sem atordoar); elites cambaleiam 0,4 s | **Corrente Explosiva:** o impacto explode (40 de dano, 40 px) e arranca escudos e placas na área |
| **Dash** | Passo Leve: −0,15 s de recarga | Dash Duplo (2): +1 carga | Esquiva de Arena (2): atravessar um golpe ou projétil durante a invulnerabilidade deixa o próximo tiro em até 1 s com +50% de dano | — | — |

Os personagens 2 e 3 terão árvores próprias no mesmo formato (Fase 3).

## 5. Gambiarras — só na run (item c)

### 5.1 Regras
- **Quando aparece:** ao limpar cada sala de **Combate ou Elite**, e também depois de vencer o chefe nas runs de vários atos. Não aparece em Loja, Reparo nem na sala 0.
- **A tela:** 3 cartas, 1 clique, sem tempo-limite e com o jogo pausado. Só aparecem Gambiarras da arma que está em uso.
- **Raridades e chance:** Comum 65% · Rara 28% · Épica 7%. Salas Elite garantem pelo menos 1 Rara ou melhor entre as 3.
- **Sorteio:** as 3 opções são sempre diferentes. Uma Gambiarra **única** já pega não volta, e uma **acumulável** não volta depois de chegar ao máximo.
- As Gambiarras **acumulam** e **somem na morte**. Somam com a árvore de Combate (cada uma vira um `ModificadorArma`).
- O Recalibrar (árvore Passiva) troca as 3 cartas uma vez por nível.
- No VS, uma run tem cerca de 6 a 7 Gambiarras.
- **Portas:** sai a porta "Aprimoramento de Arma" e sai o item da loja. As outras recompensas não mudam.
- **Desbloqueio por Dados:** o "Treino com Garrak" (30 Dados) passa a fazer a run **começar com 1 Gambiarra Comum à escolha**.

### 5.2 Banco da Mordida (12)
| # | Nome | Raridade | Efeito | Máx. |
|---|---|---|---|---|
| 1 | Rebite Duplo | C | A cada 5 tiros, o próximo sai duplo (2 projéteis lado a lado) | 2 (a cada 4 tiros) |
| 2 | Ricochete | C | O tiro ricocheteia 1 vez em parede ou chão | 2 |
| 3 | Rebite Grosso | C | +10% de dano, projétil 25% maior | 3 |
| 4 | Gatilho Leve | C | +8% de cadência | 3 |
| 5 | Cano Longo | C | +30% de velocidade e de alcance do projétil | 1 |
| 6 | Rebite Incandescente | R | Cada acerto seguido no mesmo alvo dá +3% de dano (até +30%); zera ao trocar de alvo | 1 |
| 7 | Perfura-Casco | R | Atravessa +1 inimigo | 2 |
| 8 | Leque | R | +2 projéteis a ±6°, com 50% do dano cada | 1 |
| 9 | Caçador de Marca | R | +20% de dano em alvos Marcados (soma com a Marca) | 1 |
| 10 | Tiro de Aviso | R | +50% de dano em inimigo que está anunciando um ataque | 1 |
| 11 | Rebite Guiado | É | O projétil curva até 15° na direção do inimigo mais próximo | 1 |
| 12 | Prego do Rato | É | A cada 20 tiros, um rebite gigante (60 de dano, atravessa tudo) | 1 |

### 5.3 Banco do Bramido (12)
| # | Nome | Raridade | Efeito | Máx. |
|---|---|---|---|---|
| 1 | Balim Extra | C | +1 balim | 3 |
| 2 | Pólvora Kharn | C | +10% de dano | 3 |
| 3 | Choque Concentrado | C | −5° de dispersão | 2 |
| 4 | Alcance de Cerco | C | +25% de alcance; a queda de dano começa 16 px mais longe | 2 |
| 5 | Engatilho Rápido | C | +10% de cadência | 3 |
| 6 | Bala Central | R | Cada disparo solta também 1 projétil reto de 30 de dano que alcança a tela inteira | 1 |
| 7 | Balins Quicantes | R | Os balins ricocheteiam 1 vez | 1 |
| 8 | Empurrão de Campeão | R | Acertos empurram inimigos leves e médios 16 px (uma vez por disparo) | 1 |
| 9 | Estilhaço Vivo | R | O balim que mata solta 2 estilhaços de 5 de dano | 2 |
| 10 | Queima-Roupa | R | +40% de dano a 24 px ou menos | 1 |
| 11 | Carregador de Arena | É | Carregador de 2 (0,15 s entre os disparos, 0,9 s para recarregar). Com o Cano Duplo da árvore, vira carregador de 3. | 1 |
| 12 | Artilharia | É | Segurar o tiro por 1,0 s carrega um disparo que explode (90 de dano, 40 px). Soltar antes dispara normal. Com o tiro automático ligado, carrega sozinho. | 1 |

## 6. Mira 360° com o mouse (D-052) — o que muda (GD-2)
- **Os tiros saem no ângulo exato do mouse.** O tronco do Ryker usa a mais próxima das 8 poses. **Mirar para baixo no ar** continua valendo, agora em qualquer ângulo.
- **"Travar mira" sai do teclado:** com o mouse, ficou desnecessária. No gamepad, o analógico direito mira em 360°.
- **Assistências (continuam, D-017):**
  - **Assistida:** puxa até 10° na direção do inimigo mais próximo da linha de mira.
  - **Total:** mira no centro do corpo do alvo prioritário (mesmas regras do GD-01, seção 3.1). Com a mira Total, o Grilhão também é guiado.
  - **Padrão sugerido:** Desligada no mouse e **Assistida no gamepad**.
- **Pontos fracos:** como a mira ficou precisa, eles continuam valendo **×2**, mas a habilidade cobrada passa a ser **posição e tempo**, e não ângulo:
  - os pontos fracos ficam **pequenos (8×8 px)**;
  - ficam **atrás ou em cima** do inimigo (radiador de Ur-Kesh, tanque do Brutamontes) ou **só expostos em janelas** (andador ajoelhado, Ninho pulsando).
  - A mira automática nunca mira ponto fraco.
- **Inimigos:**
  - a **armadura frontal** e o **teto de 3 ataques anunciados** não mudam;
  - o **Artilheiro** passa a ficar atrás de cobertura (só pode ser acertado por cima ou pelo lado, ou com granada);
  - o **Ninho** ganha uma carapaça na frente (o ponto fraco fica em cima).
  - Vida e dano ficam iguais até o playtest.
- **Para o QA medir:** tempo para matar cada inimigo e dano recebido por sala, com mouse e com gamepad. Se o mouse ficar muito mais fácil, a primeira mudança é **+20% de vida nos inimigos voadores** (Zangão de 10 para 12).

## 7. Resumo para o DEV (item 12 da CENTRAL)
1. **Tirar:** Embalo, Coice, árvore de arma por run, Pontos de Aprimoramento, porta e loja de Aprimoramento, Golpe de Arena.
2. **Dados base** das armas: seção 1.
3. **Grilhão:** seção 2 (não bloqueia o tiro; Marca; 4 tipos de alvo; derrubar de plataforma).
4. **Árvore Passiva** no Vossa Margem: seção 3. **XP, nível e árvore de Combate** no Arsenal: seção 4 (redistribuição grátis, no máximo 2 Ápices).
5. **Gambiarras:** seção 5. Cada uma é um `ModificadorArma` com raridade, máximo de acúmulos e um marcador quando precisar de código novo (ricochete, guiado, carga, estilhaço, empurrão, a cada N tiros).
6. **Testes:**
   - XP para subir de nível = `60 + 20n`;
   - nível e XP persistem depois da morte;
   - no máximo 2 Ápices;
   - redistribuição devolve todos os pontos;
   - Gambiarra única não é oferecida duas vezes, e acumulável respeita o máximo;
   - Elite garante pelo menos 1 Rara;
   - Gambiarras somem na morte;
   - o Grilhão não interrompe o tiro;
   - a Marca dá +25% só no dano da arma.
