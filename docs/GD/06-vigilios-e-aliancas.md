# GD-06 — Dádivas mágicas dos Vigílios e Alianças Kharn + Vesh (v0.1)

Autor: Game Design (GD) · Atende ao pedido DIR → GD (CENTRAL, seção 6, item 1) · Base: D-008, D-026, D-030, D-034, D-040, D-041, D-042, GD-02 v0.3, GD-05 v0.2.
Status: **proposta**. Os Vigílios são conteúdo da Fase 3 (atos 3 e 4). As Alianças podem entrar no VS (ver a pergunta em GD.md).

---

## Parte A — Os Vigílios: a primeira facção mágica (D-030, D-042)

### A.1 Ideia central
Os Vigílios **nunca dormem**: a vigília é a magia deles. As dádivas recompensam **não parar** (ligação direta com o título *No Rest*, D-031) e **ver o perigo antes** (a luz que revela). As regras são tão claras quanto as das facções tecnológicas (D-030).

**Três tipos de dádiva** (os nomes dos tipos vêm da D-030):
| Tipo | O que é | Onde entra |
|---|---|---|
| **Feitiço** | Muda uma ação: Tiro, Granada, Dash, Ferramenta ou Chamado | Nos slots normais (1 por slot, D-026) |
| **Bênção** | Efeito passivo que cresce com o medidor de **Vigília** | Slot Passivo (acumula) |
| **Voto** (a maldição que o jogador aceita) | Uma restrição por 3 salas, que depois vira uma recompensa para o resto da run | Fora dos slots, no máximo 1 ativo por vez |

### A.2 Regras novas
**Status Revelado (nos inimigos):**
- Dura 4 s e, se o inimigo for revelado de novo, a duração renova (não acumula).
- O inimigo Revelado leva **+20% de dano**.
- Os **avisos de ataque** dele duram **+0,2 s** (o jogador vê o golpe antes). Isso não muda as fichas de ataque.
- Visual: um olho de luz aberto acima do inimigo (ART).
- **Na Ruptura (D-034):** inimigos disfarçados pela ilusão de Vasha perdem o disfarce quando são Revelados. A Lanterna da Vigília também revela (NAR-03, seção 5).

**Medidor de Vigília (no jogador):**
- Só aparece se o jogador tiver pelo menos 1 Bênção.
- Vai de 0 a 100. Sobe **+25/s enquanto Ryker se move** (andar, pular, dash, puxada do Grilhão). Atirar parado não enche.
- Cai **−40/s depois de 0,5 s parado**. Levar dano tira **−30**.
- **Níveis:** 1 (34 ou mais), 2 (67 ou mais), 3 (100). No HUD é um terceiro olho que se abre em 3 etapas, ao lado dos elos de vida (ART).
- **Assistências (D-017):** com a mira automática ou o tiro automático ligados, o medidor funciona igual, porque depende do movimento e não da mira. Nada exige apertar botões mais rápido.

### A.3 Feitiços (slots de ação)
| Slot | Nome (provisório, NAR) | Efeito (Comum / Raro / Épico) |
|---|---|---|
| Tiro | **Olhar que Queima** | Acertos têm 15 / 20 / 25% (× `fator_efeito`) de chance de Revelar o alvo |
| Tiro | **Lume Cego** | Os projéteis de inimigos Revelados ficam 25 / 35 / 45% mais lentos |
| Granada | **Lanterna Lançada** | Depois de explodir, a granada deixa uma lanterna no chão por 4 / 5 / 6 s, que Revela continuamente os inimigos a até 64 px |
| Dash | **Passo Insone** | O dash deixa uma **imagem de luz** onde Ryker estava. Por 0,6 / 0,8 / 1,0 s, os inimigos miram nela em vez de mirar nele. A imagem entra na lista de alvos (D-018) com prioridade máxima. |
| Ferramenta | **Corrente de Vigia** | O alvo acertado pela Ferramenta é Revelado, e também os inimigos a até 48 / 64 / 80 px dele |
| Chamado | **Vigília Coletiva** | Por 6 / 8 / 10 s, todos os inimigos na tela ficam Revelados e o medidor de Vigília fica travado em 100 |

### A.4 Bênçãos (Passivos, acumulam)
| Nome (provisório) | Efeito (Comum / Raro / Épico) |
|---|---|
| **Insone** | +4 / 6 / 8% de dano por nível de Vigília (até 3 níveis) |
| **Terceiro Olho** | Com Vigília no nível 2 ou mais, **todos** os avisos de ataque contra Ryker duram +0,1 / 0,15 / 0,2 s (soma com o Revelado) |
| **Chama que Não Dorme** | Com Vigília no nível 3, recupera 1 bloco de vida a cada 60 / 45 / 30 s de combate. É a única cura contínua do jogo, então os valores são baixos de propósito. |
| **Pálpebra Tatuada** | Inimigos Revelados que morrem enchem a barra de Chamado em +5 / 8 / 12 pontos |
| **Prece em Marcha** | O medidor de Vigília cai 25 / 40 / 55% mais devagar |

### A.5 Votos (as maldições aceitas)
- **Como aparece:** em vez de 3 opções, uma oferta Vigílio pode vir (25% de chance) como **altar de Voto**: 2 Votos à escolha, ou recusar e receber uma Bênção Comum.
- **Regra:** durante as **3 salas** seguintes, a restrição vale. Ao limpar a 3ª sala, a recompensa entra **até o fim da run**.
- **A restrição desliga a coisa, nunca cria uma falha.** O botão da granada fica apagado, os Créditos não caem, e assim por diante. Ninguém "quebra" um Voto sem querer.
- **Votos nunca mexem em:** avisos de ataque, assistências (D-017), fichas de ataque, vida mínima abaixo de 2 blocos. Pilar 1: a restrição corta recursos, nunca informação.

| Voto (provisório) | Restrição por 3 salas | Recompensa até o fim da run |
|---|---|---|
| **Voto de Silêncio** | Sem granadas | +1 granada por sala, e as granadas Revelam tudo o que acertam |
| **Voto de Pobreza** | Os Créditos não caem | A loja fica 30% mais barata |
| **Voto de Ferida** | −1 bloco de vida máximo (nunca abaixo de 2) | +1 bloco de vida máximo e cura total |
| **Voto de Mãos Atadas** | Ferramenta com recarga dobrada | Ferramenta com recarga −30% |
| **Voto de Vigília** | O medidor de Vigília cai 2× mais rápido | O medidor nunca cai abaixo do nível 1 |

### A.6 Onde e quando os Vigílios aparecem
- **Proposta de GD:** a partir do **Ato 3 (Zhinn)**, como 3ª facção das portas, porque os Vigílios descem a Zhinn para enfrentar o enxame. No **Ato 4 (Vigília)** são a facção principal. A NAR decide o motivo na história.
- **Combina com:** Kharn (Revelado aumenta o dano dos atordoamentos) e Vesh (um Ácido lento num alvo Revelado). Alianças Vigílio + Kharn e Vigílio + Vesh ficam para a próxima versão.
- **Ligação com a Ruptura:** as dádivas Vigílio são a melhor resposta às ilusões de Vasha (GD-04). Isso dá ao jogador experiente um motivo para buscá-las antes da Ruptura, sem ser obrigatório.

### A.7 Checagem contra os pilares
| Pilar | Como atende |
|---|---|
| 1. Caos controlado | O Revelado e o Terceiro Olho **aumentam o tempo dos avisos**. O Passo Insone dá uma ferramenta de defesa. Os Votos nunca tiram informação. |
| 2. Toda run conta | Cada Voto cumprido é uma pequena história de superação dentro da run. |
| 3. Pequeno entre gigantes | O humano vence pela atenção e pelo movimento, não pela força. |

## Parte B — Alianças Kharn + Vesh

### B.1 Regras (D-026: o sistema já aceita pré-requisitos)
- Uma **Aliança** só aparece quando o jogador tem os **2 pré-requisitos**: um upgrade de cada facção, em **slots diferentes**. Como cada slot aceita 1 upgrade, nunca dá para exigir dois upgrades de Tiro, por exemplo.
- Ela aparece como **4ª opção** numa oferta Kharn ou Vesh, com 20% de chance quando os pré-requisitos existem. Uma oferta nunca mostra 2 Alianças.
- **Não ocupa slot**, não tem raridade (valor fixo) e é pega no máximo 1 vez por run.
- Se um pré-requisito for **substituído** depois, a Aliança continua, mas pode ficar sem efeito se o efeito de base sumir. A tela avisa isso antes da troca.
- Visual da oferta: a moldura metade Kharn, metade Vesh (ART). Fala de patrona dupla: as duas brigam pela dádiva (NAR).

### B.2 Lista de Alianças
| Aliança (provisório) | Pré-requisito Kharn | Pré-requisito Vesh | Efeito |
|---|---|---|---|
| **Bomba de Ninhada** | Munição de Clã, Carga de Cerco, Corrente Rubra **ou** Bombardeio de Artilharia | Ferrão Ácido, Ovo de Ninhada, Rastro de Enxame, Corrente Infestada **ou** Colmeia Faminta | Toda explosão Kharn aplica **2 acúmulos de Ácido** a quem acertar |
| **Ferrão Explosivo** | Investida do Clã, Inabalável **ou** Grito de Guerra | Ferrão Partido | Fragmentos de Ferrão Partido causam **15 de Abalo** |
| **Enxame de Guerra** | Honra do Campeão **ou** Grito de Guerra | Nuvem de Zangões **ou** Corpo Solto | Zangões aliados causam **10 de Abalo** por mordida e explodem ao sumir (20 de dano, raio de 24 px) |
| **Casca Ácida** | Couro de Arena | Carne Mole **ou** Rastro de Enxame | Quando o Couro de Arena anula um acerto, solta uma onda de ácido: **3 acúmulos** em todos a até 64 px |
| **Arrastão** | Corrente Rubra **ou** Investida do Clã | Corrente Infestada **ou** Rastro de Enxame | Se o dash vier até 1 s depois de acertar a Ferramenta (precisa de um pré-requisito na Ferramenta e outro no Dash, de facções diferentes), Ryker causa uma **explosão ácida**: 40 de dano, 3 de Ácido e 50 de Abalo em 48 px |
| **Colmeia em Chamas** | Bombardeio de Artilharia | Colmeia Faminta **ou** Carne Mole | Cada projétil do Bombardeio deixa uma **poça de ácido** por 3 s (1 acúmulo a cada 0,5 s) |

Exigir uma "ou" outra opção é proposital: mais caminhos levam à mesma Aliança, e ela aparece com mais frequência.

**Equilíbrio:** cada Aliança vale mais ou menos um upgrade Raro. São escolhas de estilo, não obrigatórias.

### B.3 Requisitos de teste (para o DEV)
1. A Aliança só é oferecida com os 2 pré-requisitos, de facções e slots diferentes.
2. Nunca 2 Alianças na mesma oferta, nem a mesma Aliança 2 vezes por run.
3. A Aliança não ocupa slot e continua depois de um pré-requisito ser substituído.
4. Arrastão: a explosão só acontece se o dash vier em até 1 s depois do acerto da Ferramenta.
5. **Vigílios (Fase 3):** o Revelado soma +0,2 s ao aviso sem mudar as fichas; o Voto desliga a ação restrita e entrega a recompensa ao limpar a 3ª sala; nenhum Voto baixa a vida máxima para menos de 2.

## Pedidos deste doc
- [PARA: NAR] Nomes definitivos dos Feitiços, Bênçãos, Votos e Alianças. A patrona dos Vigílios e as falas da oferta e do altar de Voto. O motivo de os Vigílios estarem em Zhinn (Ato 3). As falas das patronas brigando na oferta de Aliança.
- [PARA: ART] Olho de luz do Revelado. Terceiro olho do medidor de Vigília no HUD (3 etapas). Imagem de luz do Passo Insone. Lanterna no chão. Moldura do altar de Voto (moldura Vigílio). Moldura dividida Kharn/Vesh para as Alianças. ⚠ D-021: nada que lembre aranha, olhos agrupados ou teia.
- [PARA: DEV] Fase 2 (só se a DIR puser as Alianças no VS): ofertas com 4ª opção de Aliança, pré-requisitos com "ou", Aliança fora dos slots. Fase 3: status Revelado (+aviso), medidor de Vigília, Votos como restrição + recompensa diferida, alvo-isca na lista de alvos.
- [PARA: AUD] Som de "olho abrindo" no Revelado. Zumbido grave que sobe com o nível de Vigília. Sino para o Voto cumprido.
