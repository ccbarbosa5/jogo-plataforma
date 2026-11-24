# NAR-01 — Diálogos da primeira run (Vertical Slice) · v0.4

Autor: Narrativa (NAR) · Base: D-010, D-013/D-025, D-016, D-020, D-021 a D-024, D-026, D-031 (No Rest), D-032 (caixas estilo Hades), D-035, D-038 (armas), **D-046 (placa só com o nome; acentos obrigatórios)**, GD-02.
Status: **proposta**. As falas do Arsenal e das armas ficam no **NAR-03** (`ARSE_*`, `CAMP_*`). As conversas da nave ficam no **NAR-04** (`NAVE_*`).

**Mudanças desde a v0.3**
- **D-046:** a placa mostra **só o nome** (seção 0). Os títulos saíram da tela e foram para o **Códice** (NAR-05). As expressões continuam valendo (D-044).
- Revisão de acentos: todo texto de tela está com acentos e ç.
- Nenhuma fala mudou. Os IDs continuam os mesmos.

## Convenções (para DEV)
- **ID:** `SEÇÃO_NN`. **Gatilho:** quando toca. "1ª vez" = salvar flag permanente.
- `[colchetes]` = direção de cena, **nunca aparece na tela**. **`[AUD: zumbido]`** = zumbido de colmeia na voz da ECO (só ABER_07, VITO_07, MIST_04).
- **Expr.** = expressão do retrato (seção 0). Coluna vazia = expressão padrão.
- Barks sorteados não repetem a mesma fala duas vezes seguidas.
- **Caixa grande (D-032)** só fora do combate. Barks e falas de combate usam a fala rápida no topo da tela.

## 0. Placas e expressões (D-032, D-046)
| Falante (ID nos dados) | **Placa na tela** | Lado | Expressões (a 1ª é a padrão) |
|---|---|---|---|
| RYKER | **RYKER** | esq. | **neutro**, deboche (sorriso torto), raiva, abalado (pós-morte) |
| ECO | **ECO** | dir. | **acolhedora**, sorriso, preocupada, distante (olhar perdido; pista) |
| GARRAK | **GARRAK** | dir. | **severo**, orgulho contido, vergonha, raiva |
| SETE | **SETE** | dir. | **curioso**, encolhido (medo), feliz, confuso |
| VOSSA | **VOSSA MARGEM** | dir. | **sorriso comercial**, ganancioso, nervoso |
| MERCADOR | **MERCADOR** | dir. | **sorriso comercial**, decepcionado |
| TOR-AMA | **TOR-AMA** | dir. | **imponente**, divertida, aprovação |
| COLMEIA | **A COLMEIA** | dir. | **enxame calmo**, enxame agitado |
| UR-KESH | **UR-KESH** | dir. | **fúria**, desdém, ferido; versões *andador* (cabine) e *a pé* |
| SINAL | **SINAL** | dir. | sem retrato: só onda de rádio com estática |
| REGISTRO | **REGISTRO** | dir. | sem retrato: tela com estática |

- **Títulos (fora da tela, só no Códice, NAR-05):** RYKER — Krat'zu, o Gladiador Fugitivo · ECO — Anfitriã da Eco · GARRAK — o Exilado, Mestre de Armas · SETE — um Vesh sozinho · VOSSA MARGEM — Sindicato Ilo, Melhorias e Contratos · MERCADOR — vendedor de campo do Sindicato · TOR-AMA — Matriarca do Clã Ossoferro · A COLMEIA — os Vesh · UR-KESH — Campeão Caído do Clã Kesh.
- **Molduras (D-032):** RYKER sucata humana · ECO luz âmbar sobre teal · GARRAK, TOR-AMA e UR-KESH Kharn · SETE e COLMEIA Vesh · VOSSA e MERCADOR Ilo · SINAL e REGISTRO humana danificada.
- **Acentos:** as placas usam maiúsculas acentuadas quando o nome tiver acento (nenhum nome atual tem). Os textos das falas usam á à â ã é ê í ó ô õ ú ç.

---

## 1. Abertura — primeira vez que o jogo é iniciado (Reconstrutor)
Gatilho: novo jogo. Tela preta, som de batimento cardíaco. A luz se junta e forma a ECO, inclinada sobre o reconstrutor, perto do rosto dele.

| ID | Falante | Expr. | Fala |
|---|---|---|---|
| ABER_01 | ECO | sorriso | Molde 4. Reconstrução concluída. Batimentos: presentes. Sarcasmo: carregando. |
| ABER_02 | RYKER | abalado | ...Eu morri. |
| ABER_03 | ECO | | Morreu. Com bastante estilo, segundo os registros. Sua nave atravessou um Portão quebrado e caiu aqui em pedaços. Você estava em vários deles. |
| ABER_04 | RYKER | | Quem é você? Onde eu tô? |
| ABER_05 | ECO | sorriso | Eu sou a ECO. Esta é a Eco. Sim, a nave e eu temos o mesmo nome. Não fui eu que escolhi. |
| ABER_06 | RYKER | | E quem escolheu? |
| ABER_07 | ECO | distante | Pessoas que dormem há muito tempo. `[AUD: zumbido]` |
| ABER_08 | RYKER | | [olha para o pulso, onde ainda está a algema] ...Você reconstruiu até a algema. |
| ABER_09 | ECO | | [passa os dedos de luz pela algema; eles atravessam] Eu poderia ter tirado. Achei que você ia querer decidir isso sozinho. |
| ABER_10 | RYKER | deboche | [pausa] ...Tá. Valeu, eu acho. Agora me larga num planeta humano qualquer e a gente fica quite. |
| ABER_11 | ECO | preocupada | Não existe planeta humano neste setor. Você está muito longe de casa, Ryker. Mas existe isto. |
| ABER_12 | SINAL | | [chiado, voz humana falhando] ...qualquer um... Varrek... ainda estamos vivos... |
| ABER_13 | RYKER | | ...Humanos. |
| ABER_14 | ECO | | O sinal vem de Varrek, o planeta logo abaixo. Um cemitério de naves. Os Kharn e os Vesh estão em guerra lá embaixo. |
| ABER_15 | RYKER | raiva | Kharn. Claro que tem Kharn. |
| ABER_16 | ECO | | Eu posso te mandar lá para baixo. E posso te trazer de volta se você morrer. De novo. Mas a escolha é sua. |
| ABER_17 | RYKER | | E o que você ganha com isso? |
| ABER_18 | ECO | sorriso | Tem uma peça minha lá embaixo. E... faz muito tempo que ninguém fica aqui comigo. Eu ganho companhia. |

## 2. Hangar — antes da primeira descida
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| HANG_01 | ECO | | Isto é a âncora. [instalação na nuca, som metálico] Ela me envia tudo o que você vê e sente. Se você morrer lá embaixo, eu te refaço aqui em cima. |
| HANG_02 | RYKER | | Tudo o que eu sinto? |
| HANG_03 | ECO | sorriso | Tudo. Inclusive o medo. Pode ficar tranquilo, eu não comento. [pausa] Muito. |
| HANG_04 | RYKER | deboche | Você acabou de comentar. |
| HANG_05 | ECO | | Uma regra, Ryker: o que é seu volta. Corpo, memória e o que você me transmitir. Armas e presentes de alienígenas ficam lá embaixo. |
| HANG_06 | RYKER | deboche | Então eu desço armado e volto pelado. |
| HANG_07 | ECO | sorriso | Você desce armado e volta... para mim. [beat] Bem informado, eu quis dizer. |
| HANG_08 | ECO | | [cápsula lançada] Boa queda. |
| HANG_09 | RYKER | | Isso não é uma expressão. |

**Hangar, descidas seguintes** (sortear 1):
| ID | Falante | Fala |
|---|---|---|
| HANG_R1 | ECO | Boa queda. E dessa vez, volte inteiro. Eu gosto de você inteiro. |
| HANG_R2 | ECO | Ur-Kesh ainda está lá embaixo. Eu verifiquei. Ele também está verificando você. |
| HANG_R3 | ECO | O sinal continua. Eles ainda estão vivos. |
| HANG_R4 | RYKER | Mais uma vez, Varrek. |
| HANG_R5 | RYKER | Pelo menos a queda é de graça. |
| HANG_R6 | ECO | Você não precisa ir, sabe. Pode ficar. Descansar um pouco. [Ryker entra na cápsula] ...Tudo bem. Boa queda. |

## 3. Varrek — Queda (sala 0)
Falas rápidas no topo da tela.

| ID | Gatilho | Falante | Fala |
|---|---|---|---|
| QUED_01 | Saída da cápsula, 1ª vez | RYKER | Varrek. Mil naves mortas e nenhuma com ar-condicionado. |
| QUED_02 | Antes do 1º inimigo grande, 1ª vez | ECO | Use o dash quando algo grande vier na sua direção. Aqui, tudo é grande. |
| QUED_03 | 1º uso do Grilhão | RYKER | Ainda tenho a corrente. Os Kharn deviam ter tirado isso de mim. |
| QUED_04 | 1ª morte de inimigo | RYKER | Um a zero, Varrek. |

## 4. Ofertas Kharn — Tor-Ama
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| KHAR_01 | TOR-AMA | imponente | Krat'zu. O rato que mordeu o campeão. |
| KHAR_02 | RYKER | deboche | Se veio me levar de volta pra arena, entra na fila. |
| KHAR_03 | TOR-AMA | | O Clã Ossoferro não acorrenta quem venceu a Grande Arena. Isso é coisa de clã pequeno, como o Clã Kesh. Ur-Kesh está neste planeta e quer a sua cabeça. |
| KHAR_04 | RYKER | | Ele sempre quis. |
| KHAR_05 | TOR-AMA | divertida | Então morda de novo. Com dentes melhores. [escolha do upgrade] |
| KHAR_06 | TOR-AMA | aprovação | [depois da escolha] Faça barulho, pequeno. O clã está ouvindo. |

**Ofertas seguintes** (sortear 1): "Mais dentes, Krat'zu?" · "O clã gosta de ver você quebrar coisas." · "Bata primeiro. Bata mais forte." · "Este planeta engole naves desde antes dos clãs existirem. Não deixe que engula você."

## 5. Ofertas Vesh — A Colmeia
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| VESH_01 | COLMEIA | | Nós vemos um corpo sozinho. |
| VESH_02 | RYKER | deboche | Ótimo. Inseto falante. |
| VESH_03 | COLMEIA | | Um corpo sozinho é um erro. Nós corrigimos erros. Mas você... você continua funcionando. Isso nos interessa. |
| VESH_04 | RYKER | | Vocês querem me ajudar ou me dissecar? |
| VESH_05 | COLMEIA | | Nós ainda não decidimos. Aceite isto. Multiplique-se. |
| VESH_06 | RYKER | | Eu sou um só. |
| VESH_07 | COLMEIA | agitado | Por enquanto. |

**Ofertas seguintes** (sortear 1): "Nós voltamos. Nós sempre voltamos." · "Mais de você. Mais de nós." · "O corpo sozinho persiste. Curioso."

**Pistas (a partir da 3ª oferta Vesh; cada uma toca 1 vez):**
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| VESH_P1 | COLMEIA | | Nós servimos. [pausa longa] Nós não lembramos a quem. |
| VESH_P2 | COLMEIA | agitado | Você tem cheiro de... casa. Por que um corpo sozinho tem cheiro de casa? |
| VESH_P2b | RYKER | deboche | Deve ser o desodorante. |

## 6. Primeira dádiva das duas facções na mesma run
| ID | Falante | Fala |
|---|---|---|
| DUAL_01 | RYKER | Um presente Kharn e um Vesh no mesmo bolso. Se eles soubessem... |
| DUAL_02 | ECO | Eles saberiam que só alguém como você faria isso. É por isso que eu escolhi você. |

## 7. Loja da run — Mercador Ilo (D-020)
| ID | Gatilho | Falante | Fala |
|---|---|---|---|
| LOJA_01 | 1ª visita | MERCADOR | Um cliente humano! Que raro. Que... comercialmente promissor. |
| LOJA_02 | 1ª visita | RYKER | Você vende pros Kharn também, né? |
| LOJA_03 | 1ª visita | MERCADOR | Eu vendo para todos os lados. Por isso eu continuo vivo e eles continuam brigando. Créditos, por favor. |
| LOJA_R1 | Entrada (sorteio) | MERCADOR | Bem-vindo de volta! Ou é a primeira vez? Com vocês, reimpressos, eu nunca sei. |
| LOJA_R2 | Entrada (sorteio) | MERCADOR | Guerra é ótima para os negócios. Péssima para todo o resto. |
| LOJA_R3 | Entrada (sorteio) | MERCADOR | Promoção do dia: tudo. Desde que você pague. |
| LOJA_C1 | Compra de upgrade | MERCADOR | Excelente escolha. Eu teria escolhido igual, se tivesse um corpo. |
| LOJA_C2 | Compra de cura | MERCADOR | Remendo vendido! Garantia válida até a próxima explosão. |
| ~~LOJA_C3~~ | — | — | *(removida pela D-038)* |
| LOJA_C4 | Reroll | MERCADOR | Ah, o cliente exigente. Meu tipo favorito. |
| LOJA_C5 | Sem Créditos | MERCADOR | Ah. Só olhando. Que... corajoso. |
| LOJA_C6 | Compra de Aprimoramento de Arma (D-040) | MERCADOR | Peças de primeira! Bem, de segunda. De terceira, no máximo. |
| LOJA_S1 | Saída sem comprar | MERCADOR | Volte quando tiver mais medo. Medo vende. |
| LOJA_S2 | Saída depois de comprar | MERCADOR | Foi um prazer. Não morra antes de precisar de mais coisa. |
| LOJA_P1 | Pista, 4ª visita, 1 vez | MERCADOR | Antigamente eu vendia nos Portões. Aí os Portões quebraram, e os clientes começaram a sumir lá dentro. Péssimo para cobrança. |
| LOJA_P2 | Pista, 7ª visita, 1 vez | MERCADOR | Sua nave tem uma anfitriã encantadora. Eu nunca fecho negócio com ela. Ela sempre sabe o meu preço. |

## 8. Momentos do caminho
| ID | Gatilho | Falante | Fala |
|---|---|---|---|
| CAMI_00 | Sala 3 (ninhos Vesh), 1ª vez. Cenário: Vesh arrastando corpos de Kharn para dentro de um casco | RYKER | Os Vesh tão carregando os mortos lá pra dentro... Pra onde? |
| CAMI_01 | Entrada na zona de guerra (sala 5), 1ª vez | RYKER | Kharn de um lado, Vesh do outro, e eu no meio. Tipo a arena, só que com mais gente. |
| CAMI_02 | Aproximação da relíquia (sala 7), 1ª vez | ECO | Estou sentindo a peça. E o sinal está mais forte aqui. |
| CAMI_03 | Logo depois | SINAL | ...se alguém ouvir... a relíquia... não deixa eles... [cai] |
| CAMI_04 | Logo depois | RYKER | Aguenta firme. Tô chegando. |
| REG1_01 | Sala 7: 1º Dado de Inteligência "Registro corrompido" (1 vez) | REGISTRO | [voz humana, masculina, muito velha, cortada] ...Molde 1, registro... se ela sorrir, conte os... não durma na lu— [estática] |
| REG1_02 | Logo depois | RYKER | ECO? Que diabo foi isso? |
| REG1_03 | Logo depois | ECO | Dados antigos, corrompidos. Uma nave velha guarda muito ruído. Vou arquivar. |

## 9. Chefe — Ur-Kesh, do Clã Kesh
Entrada e derrota: caixa grande, com o combate pausado. Falas de luta: rápidas, no topo.

### 9.1 Entrada — primeiro encontro
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| UREK_01 | UR-KESH | fúria (andador) | KRAT'ZU! Eu sabia. Senti cheiro de rato desde a órbita. |
| UREK_02 | RYKER | deboche | Ur-Kesh. Ganhou um robô novo? Ficou com vergonha de lutar com o próprio corpo? |
| UREK_03 | UR-KESH | | Você me tirou tudo na Grande Arena. Meu título. Meu nome. Hoje eu tiro a única coisa que você tem. |
| UREK_04 | RYKER | deboche | Meu charme? |
| UREK_05 | UR-KESH | fúria | A SUA VIDA! |
| UREK_06 | RYKER | | Isso eu tenho de sobra agora. [início da luta] |

### 9.2 Entradas seguintes (prioridade de cima para baixo; senão, sortear das genéricas)
| ID | Condição | Falante | Fala |
|---|---|---|---|
| UREK_K | Ryker tem dádiva Kharn | UR-KESH | Ossoferro te deu presentes? Tor-Ama perdeu a vergonha! |
| UREK_V | Ryker tem dádiva Vesh | UR-KESH | Você tem cheiro de inseto, Krat'zu. Caiu baixo. |
| UREK_KV1 | Ryker tem as duas | UR-KESH | Kharn E Vesh? Que tipo de criatura aceita os dois? |
| UREK_KV2 | (logo depois) | RYKER | Do tipo que ganha. |
| UREK_BR | Ryker está com o **Bramido** (1 vez) | UR-KESH | ESSE É O MEU BRAMIDO! Você... você aponta a MINHA arma para MIM? |
| UREK_BR2 | (logo depois) | RYKER | Achei nos seus destroços. Ficou pequeno pra você. |
| UREK_3 | 3º encontro | UR-KESH | Eu treinei. Você só morreu. |
| UREK_5 | 5º encontro ou mais (1 vez) | UR-KESH | O Clã Kesh ri de mim enquanto você estiver vivo. Então você não vai estar. |
| UREK_G1 | genérica | UR-KESH | Você de novo. Eu também, rato. |
| UREK_G2 | genérica | UR-KESH | Quantas vezes eu preciso te matar para você entender? |
| UREK_G3a | genérica | RYKER | Oi, Ur-Kesh. Sentiu minha falta? |
| UREK_G3b | (logo depois) | UR-KESH | TODOS OS DIAS. |

### 9.3 Fase 1 — barks (sorteio)
- UR-KESH: "FIQUE PARADO!" · "Um rato não derruba um andador!" · "Corra, Krat'zu. Como na arena."
- RYKER: "Já desviei de coisa maior que você." · "Tá lento, campeão." · (acerto no ponto fraco) "Achei a parte macia."

### 9.4 Fase 2 — andador danificado (66% da vida)
| ID | Falante | Fala |
|---|---|---|
| UREK_F2a | UR-KESH | Você arranhou meu andador! Ele custou mais do que você na arena! |
| UREK_F2b | RYKER | Eu fui barato. Por isso dei tanto lucro. |
| UREK_F2c | UR-KESH | [quando os 2 Guerreiros chegam] Clã Kesh! Cerquem o rato! |
| UREK_F2d | UR-KESH | [o andador ajoelha e expõe o núcleo, sorteio] Levanta, lata velha! · Não olhe para aí, rato! |

### 9.5 Fase 3 — a pé, a revanche da arena
**Primeira vez** (caixa grande, combate pausado):
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| UREK_F3a | UR-KESH | fúria (a pé) | [sai da cabine em chamas e acende o machado de energia] Chega de máquina. Como na Grande Arena, Krat'zu. Só você, eu e a areia. |
| UREK_F3b | RYKER | deboche | Aqui não tem areia. Só sucata. |
| UREK_F3c | UR-KESH | desdém | Naquele dia, a multidão gritou o SEU nome. Hoje ninguém vai gritar. |
| UREK_F3d | RYKER | raiva | Ninguém nunca gritou meu nome. Gritavam o apelido que vocês me deram. |
| UREK_F3e | UR-KESH | fúria | ENTÃO MORRA COM ELE! |

**Vezes seguintes** (sorteio de 1 par): UR-KESH: "A pé. Do jeito certo." / RYKER: "Do jeito que você perdeu." · UR-KESH: "Desta vez a areia é minha!" / RYKER: "Continua sem areia, Ur-Kesh."

**Barks da fase 3:**
| Gatilho | Falante | Fala |
|---|---|---|
| Rugido do clã (GD-02) | UR-KESH | CLÃ KESH! [bate no peito] |
| Rugido atrai Zangões | RYKER | Grita mais alto. Os insetos adoram. |
| Machado arremessado | UR-KESH | Pega isto! |
| **Contra-ataque de gladiador**, 1ª vez | RYKER | Você ainda abre a guarda quando ergue o machado. Garrak me mostrou isso anos atrás. |
| Contra-ataque, seguintes | RYKER | Mesma abertura, campeão. · Previsível. |
| Ur-Kesh com pouca vida | UR-KESH | Eu não... caio... para um RATO! |

### 9.6 Ur-Kesh derrotado
**Primeira vitória (fim do VS):**
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| VITO_01 | UR-KESH | ferido | [de joelhos, machado apagado] Isso... não acabou. O clã vai lembrar... que eu perdi para um rato... duas vezes. |
| VITO_02 | RYKER | deboche | Três é o número da sorte. |
| VITO_03 | UR-KESH | ferido | Eu vou voltar. |
| VITO_04 | RYKER | | Pelo jeito, todo mundo volta. |
| VITO_W1 | — | | [Ryker passa pelos destroços do andador. Um canhão de mão Kharn, enorme e gravado com o símbolo do Clã Kesh, está preso no braço da máquina. Ele arranca.] |
| VITO_W2 | RYKER | | O canhão dos campeões de Kesh... Quem venceu leva, né? |
| VITO_W3 | ECO | sorriso | Segure firme por um momento. [a âncora brilha] Pronto. Agora eu guardo o molde dele. Garrak vai saber o que fazer. |
| VITO_05 | ECO | | [Ryker se aproxima do altar] Essa é a peça. Uma Chave de Salto. Pode pegar. Agora você carrega um pedaço de mim. |
| VITO_06 | RYKER | | Pesa. |
| VITO_07 | ECO | distante | Eu sei. `[AUD: zumbido]` |
| VITO_08 | ECO | | Com ela, eu posso saltar. O sinal saiu de Varrek, Ryker. Foi para outro planeta. |
| VITO_09 | ECO | acolhedora | Você lutou demais hoje. Descanse um pouco antes do salto. |
| VITO_10 | RYKER | | Sem descanso. Não enquanto aquela voz estiver chamando. |
| — | — | | [Fim do Vertical Slice: "Continua no Ato 2". O jogador volta à Eco com o Bramido liberado no Arsenal (NAR-03, ARSE_B).] |

**Vitórias seguintes** (sorteio):
| ID | Falante | Fala |
|---|---|---|
| VITO_R1a | UR-KESH | A chave é sua... por enquanto. Ela sempre volta para cá. E eu também. |
| VITO_R2a | UR-KESH | Por que você não fica morto, rato? |
| VITO_R2b | RYKER | Eu tenho quem me traga de volta. E você? |
| VITO_R2c | UR-KESH | [pausa] ...O clã não traz ninguém de volta. |
| VITO_R3 | UR-KESH | *(5ª vitória ou mais)* Se eu tivesse que perder para alguém... Não. Esquece. Volto amanhã. |

### 9.7 Quando Ur-Kesh mata Ryker (antes da tela de reconstrução)
| ID | Condição | Falante | Fala |
|---|---|---|---|
| UREK_M1 | sorteio | UR-KESH | KRAT'ZU CAIU! O CLÃ KESH LEMBRA! |
| UREK_M2 | sorteio | UR-KESH | Fique morto desta vez. |
| UREK_M3 | 3ª morte para ele ou mais, 1 vez (pista) | UR-KESH | [olhando para o céu] ...Ele vai voltar. Eles sempre voltam desse planeta. |

## 11. Volta depois da primeira morte (Reconstrutor)
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| MORT_01 | RYKER | abalado | [ofegante] ...Morri de novo. |
| MORT_02 | ECO | acolhedora | [ela já está lá, inclinada sobre ele] Segunda vez. Está pegando o jeito. E eu gosto de ser a primeira coisa que você vê. |
| MORT_03 | RYKER | | E as armas? As coisas que os alienígenas me deram? |
| MORT_04 | ECO | | Ficaram em Varrek. Sempre ficam. |
| MORT_05 | RYKER | abalado | Então eu perdi tudo. |
| MORT_06 | ECO | sorriso | Não. Você me mandou isto. [Núcleos aparecem] Núcleos. Energia que a âncora coletou. Com eles, você fica um pouco mais difícil de matar. |
| MORT_07 | RYKER | | E quem vende isso? |
| MORT_08 | ECO | acolhedora | Temos um inquilino. [quando Ryker vai sair] Mas antes... descanse um pouco. |
| MORT_09 | RYKER | | [já andando] Depois. |

**Variante: a 1ª morte foi para Ur-Kesh** (entra depois de MORT_02):
| ID | Falante | Fala |
|---|---|---|
| MORT_U1 | RYKER | Ur-Kesh. De todos os Kharn do universo... |
| MORT_U2 | ECO | Ele gritou seu nome várias vezes depois que você caiu. Achei que você ia querer saber. |
| MORT_U3 | RYKER | Não queria. |

**Mortes seguintes** (sortear 1): ECO: "Bem-vindo de volta. Descanse." · ECO: "Molde 4, de novo. Batimentos: presentes." · RYKER: "Isso nunca vai ficar normal." · ECO: "Você durou mais dessa vez. Eu medi." · ECO: "Eu refiz você com cuidado. Como sempre." · ECO: "Descanse." / RYKER: "Não."

## 12. Vossa Margem — primeiro encontro
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| VOSS_01 | VOSSA | sorriso comercial | Ah, o produto reimpresso! Quer dizer... o cliente. Vossa Margem, do Sindicato Ilo, a seu dispor. |
| VOSS_02 | RYKER | | O que um Ilo faz numa nave abandonada? |
| VOSS_03 | VOSSA | ganancioso | Abandonada? Ela tem você. E onde tem um humano que morre muito, tem mercado para melhorias. Eu alugo este compartimento da ECO. |
| VOSS_04 | RYKER | deboche | Ela cobra aluguel? |
| VOSS_05 | ECO | | Ele paga em informação. |
| VOSS_06 | VOSSA | nervoso | E em companhia agradável. Núcleos, por favor. |

## 13. Garrak — primeiro encontro (Arsenal)
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| GARR_01 | — | | [Ryker entra. Garrak está de costas, afiando uma lâmina. Silêncio.] |
| GARR_02 | RYKER | | ...Garrak. |
| GARR_03 | GARRAK | severo | Krat'zu. |
| GARR_04 | RYKER | raiva | Não me chama assim. |
| GARR_05 | GARRAK | | Era o seu nome quando eu te ensinei a segurar uma lâmina. |
| GARR_06 | RYKER | raiva | Era o nome que vocês me deram quando me compraram. |
| GARR_07 | GARRAK | vergonha | [pausa longa] Eu sei. |
| GARR_08 | RYKER | | O que você tá fazendo aqui? |
| GARR_09 | GARRAK | | O clã me mandou atrás de você para cortar sua cabeça. Eu te segui até aquele Portão maldito. E não cortei. Agora eu não tenho clã. |
| GARR_10 | RYKER | deboche | Quer que eu agradeça? |
| GARR_11a | GARRAK | severo | *(1ª morte foi para Ur-Kesh)* Quero que você pare de morrer para Ur-Kesh. É vergonhoso. Eu te treinei melhor que isso. |
| GARR_11b | GARRAK | severo | *(outra causa)* Quero que você pare de morrer. Ainda é vergonhoso. |
| — | — | | [segue para a entrega da Mordida: NAR-03, ARSE_M1 a M7] |
| GARR_12 | ECO | | [depois, na Ponte] A nave dele caiu logo depois da sua. Ele disse que ia esperar você acordar. Não disse por quê. |

## 14. Sete — chegada
Gatilho: voltar à nave depois da 1ª run com dádiva Vesh (D-025).

| ID | Falante | Expr. | Fala |
|---|---|---|---|
| SETE_01 | ECO | | Ryker. A âncora transmitiu uma amostra biológica na sua última descida. |
| SETE_02 | RYKER | | Que amostra? |
| SETE_03 | ECO | sorriso | Era pequena. Eu imprimi. Ela está... falando. |
| SETE_04 | SETE | confuso | Nós—... Nós? ...Não tem nós. Cadê o nós? |
| SETE_05 | RYKER | | É um Vesh. Você imprimiu um Vesh. |
| SETE_06 | SETE | confuso | É um... um eu? Eu é muito quieto. |
| SETE_07 | RYKER | deboche | Bem-vindo ao clube, inseto. |
| SETE_08 | SETE | feliz | Inseto. Eu sou um inseto. Eu sou UM inseto. |
| SETE_09 | ECO | | Vou chamá-lo de Sete. Era o número da amostra. |
| SETE_10 | SETE | encolhido | [olha para a ECO, se encolhe atrás da perna do Ryker] ...Sete. Eu sou Sete. O Sete sou eu. |

## 14b. Sete perto da ECO
Comportamento: quando a ECO se forma na Ponte, o Sete para de zumbir e se esconde. Quando ela sai, ele volta.

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| SETE_E1 | 1ª conversa com o Sete com a ECO presente | SETE | encolhido | [sussurrando] Shh. Ela escuta. |
| SETE_E2 | logo depois | ECO | sorriso | Ele é tímido. |
| SETE_E3 | logo depois | SETE | | Sete não é tímido. Sete é pequeno. |
| SETE_E4 | conversa seguinte, ECO ausente | SETE | | Quando a luz fala, o nós volta. Um pouquinho. |
| SETE_E5 | logo depois | RYKER | | Isso é bom ou ruim? |
| SETE_E6 | logo depois | SETE | confuso | É quentinho. [pausa] Sete não gosta de quentinho. Quentinho faz esquecer o eu. |
| SETE_E7 | depois da 4ª morte, ECO ausente | SETE | encolhido | Ryker. Quando ela diz "descanse"... você descansa? |
| SETE_E8 | logo depois | RYKER | | Às vezes. Por quê? |
| SETE_E9 | logo depois | SETE | | O nós dizia isso. Antes de Sete virar eu. [silêncio] Sete não descansa. |
| SETE_E10 | logo depois | RYKER | | ...Nem eu, Sete. Nem eu. |

## 15. Gancho do mistério (Ponte)
Gatilho: depois da 3ª morte.

| ID | Falante | Expr. | Fala |
|---|---|---|---|
| MIST_01 | RYKER | | Quando eu acordei, você disse "Molde 4". |
| MIST_02 | ECO | | Disse. |
| MIST_03 | RYKER | | Quem foram os três primeiros? |
| MIST_04 | ECO | distante | [sorri, chega mais perto] Pessoas que eu não consegui trazer de volta. Ainda. `[AUD: zumbido]` [beat] Mas você eu trago. Sempre. Descanse. |

---

## Nomes desta versão
Tor-Ama, Matriarca do Clã Ossoferro · A Colmeia · Clã Kesh · Chave de Salto · Portões · Molde 4 · Bramido (detalhes e demais armas no NAR-03).

## Para DEV / AUD
- **D-046:** usar o campo `nome_placa` da seção 0. O campo `titulo` não é mais usado na tela.
- Flags permanentes: `abertura_vista`, `hangar_visto`, `1a_oferta_kharn`, `1a_oferta_vesh`, `ofertas_vesh_total`, `1a_dual`, `visitas_loja`, `1a_morte`, `1a_morte_urkesh`, `mortes_total`, `mortes_urkesh`, `urkesh_encontros`, `urkesh_vitorias`, `urkesh_f3_vista`, `contra_ataque_visto`, `garrak_conhecido`, `vossa_conhecido`, `sete_chegou`, `registro_molde1_1`, `sala3_vista`, `bramido_liberado`, `urkesh_viu_bramido`.
- Condições de run: `tem_dadiva_kharn`, `tem_dadiva_vesh`, `arma_atual` (mordida / bramido / ...).
- **Pistas que somam no contador `duvida` (D-034):** ABER_07, VESH_P1, VESH_P2, CAMI_00, REG1_01, UREK_M3, SETE_E1, SETE_E7, MIST_04, LOJA_P2 (+ as pistas do NAR-04). Sugestão: +1 cada (GD define o limite).
- **Nova fala:** LOJA_C6 (compra de Aprimoramento de Arma na loja, D-040).
