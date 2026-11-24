# GD-04 — Avaliação: a Rainha como chefe (Fase 3, fora do VS) · v0.1

Autor: Game Design (GD) · Atende ao pedido DIR → GD · Base: D-021 a D-025.
Status: **avaliação e proposta**. Nada aqui entra no VS. Depende da NAR v0.4 (nome, voz e plano de revelação da Rainha).

---

## 1. Recomendação
**A Rainha não é o chefe do Ato 4. Ela é o chefe do "final verdadeiro"**, alcançado depois de várias vitórias, como no Hades, onde o final de verdade só vem depois de escapar várias vezes.

**Por quê:**
- **D-024 manda revelar aos poucos.** Se ela fosse o chefe normal do último ato, o jogador a encontraria na primeira run vitoriosa, e a revelação aconteceria cedo demais e de uma vez.
- **Pilar 2:** dá às runs depois da primeira vitória um propósito forte ("tem algo errado com a ECO").
- **Pilar 3:** ela é o maior gigante do jogo, e o jogador precisa chegar a ela já experiente.

**Estrutura proposta:**
1. **Runs normais:** Ato 1 → Ato 4. O Ato 4 tem um chefe próprio, a definir com a NAR (sugestão: o guardião do último portal da rede dos Antigos).
2. **Vitórias acumulam a "Dúvida":** cada vitória e cada pista encontrada desbloqueia diálogos novos (NAR).
3. **Depois de N vitórias** (sugestão: 3), com pistas suficientes, Ryker pode **recusar o salto de volta** no fim do Ato 4 e seguir a rede de portais até o fundo dela. Isso abre a **Ruptura**, uma sala extra que só existe então, com a Rainha.

## 2. Conceito da luta (3 fases)

**Regras visuais e de design para cumprir D-021:**
- Nada de aranha, teia ou fios.
- A linguagem visual é de **cupinzeiro**: galerias de terra e resina, câmaras, operárias e soldados-cupim.
- Os viajantes capturados estão em **casulos de resina** presos às paredes da câmara.

### Fase 1 — "A nave" (a ilusão)
- A luta começa **dentro da Eco**: o reconstrutor, a Ponte, o Arsenal.
- A ECO fala normalmente até o primeiro sinal de que algo está errado. Então Garrak, Vossa e Sete se revelam **servos-cupim disfarçados**, e o jogador luta contra os personagens queridos.
- **A ilusão sempre dá pistas (pilar 1):** todo inimigo disfarçado tem um sinal visual (um tremor da imagem) e um sinal sonoro (o zumbido de colmeia que a AUD já prevê para a ECO) antes de atacar. Nunca há ataque escondido.

### Fase 2 — "A câmara real"
- A ilusão se desfaz e aparece a câmara: **o corpo colossal, imóvel e pálido** ocupa o fundo da arena. A **cabeça pequena** fica no alto. Ela é o único **ponto fraco**.
- **O caminho até a cabeça é pelo Grilhão:** Ryker se puxa de casulo em casulo até o alto (pontos de ancoragem vivos).
- **Libertar viajantes:** atirar num casulo solta um viajante capturado, que ajuda por alguns segundos (tiro de apoio). Alguns são humanos, o que conversa com o sinal humano (NAR).
- Ataques do corpo: ondas de servos saindo das galerias, **jatos de resina** que prendem o chão por 2 s (aviso de 1,0 s) e pulsos de feromônio que puxam os inimigos para cima de Ryker.

### Fase 3 — "Piedade"
- A Rainha tenta prender Ryker numa **ilusão confortável**: a tela vira a **noite da vitória na Grande Arena**, com a multidão gritando o nome dele, e os ataques chegam disfarçados de "comemoração".
- **Sair da ilusão é a mecânica:** acertar 3 âncoras de luz escondidas na cena (cada uma com som próprio) faz a ilusão quebrar. A cada quebra, a cabeça da Rainha fica exposta por 4 s.
- Liga com o arco do Ryker ("nunca mais ser propriedade de ninguém"): ele recusa a ilusão, e com isso recusa uma prisão confortável.

## 3. Os upgrades Vesh durante a luta (proposta com cuidado)
**Pela D-024, os Vesh obedecem à Rainha sem saber.** Mecânica possível: **na Fase 2, os upgrades Vesh do jogador "hesitam"**. Por 5 s depois de cada pulso de feromônio, os efeitos Vesh param de funcionar.

- **Risco:** punir quem montou um build Vesh sem aviso viola o pilar 1.
- **Como evitar:**
  1. Avisar com antecedência ao longo das runs. Na nave, os ícones dos upgrades Vesh piscam quando a ECO fala por muito tempo (combinar com NAR e ART).
  2. A pausa dura pouco (5 s) e aparece na tela.
  3. Os upgrades Vesh ganham um bônus de compensação na Fase 3 (os Vesh "se libertam" junto com Ryker).
- **Recomendação de GD:** testar no protótipo da Fase 3. Se QA medir frustração, a mecânica sai.

## 4. Pistas mecânicas permitidas antes da revelação (sem confirmar nada, D-024)
Ferramentas que GD oferece à NAR. A NAR decide quais usar e quando.

| Pista | Onde | Regra |
|---|---|---|
| Contador de "Dúvida" | Sistema (sem aparecer na tela) | Soma vitórias, pistas vistas e diálogos. Os gatilhos de NAR consultam esse valor. |
| A Colmeia "reconhece" algo | Ofertas Vesh | Nas ofertas raras, a Colmeia diz "nós sentimos ela em você" (uma vez a cada X runs) |
| Falha no reconstrutor | Volta à nave | Raramente (5%, só depois da 1ª vitória), Ryker reaparece por 1 s numa sala da nave que não existe |
| Sete evita a ECO | Nave | Sete não fica na mesma sala que o holograma da ECO (comportamento do personagem, sem mecânica) |

**No VS:** só a "falha no reconstrutor" desligada e o contador de Dúvida já gravando dados (custo zero agora, útil na Fase 3).

## 5. Pedidos
- [PARA: NAR] Nome da Rainha, quantas vitórias abrem a Ruptura (proposta: 3) e o chefe do Ato 4 (proposta: guardião do último portal).
- [PARA: ART] Visual de cupinzeiro e resina, sem teia. A cabeça pequena precisa ser legível como ponto fraco num corpo enorme. A ilusão da Grande Arena precisa de um tremor visual nos inimigos disfarçados.
- [PARA: AUD] O zumbido da colmeia serve como **aviso de jogo** (toca antes de ataques disfarçados), além de pista narrativa.
- [PARA: DEV] Registrar desde já um contador permanente `duvida` e as flags de pista, mesmo sem uso no VS.
