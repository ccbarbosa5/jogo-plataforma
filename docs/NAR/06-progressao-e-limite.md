# NAR-06 — Falas da progressão (NAR-1) e revisão do limite de caracteres (NAR-2) · v0.1

Autor: Narrativa (NAR) · Atende aos itens **NAR-1** e **NAR-2** da CENTRAL (seção 5).
Base: D-058 e GD-07 (árvore Passiva, árvore de Combate, Gambiarras), D-063 (limite de ~120 caracteres), D-046 (placas), D-060 (Códice, Open Sans).
Dados conferidos no repositório: `data/dialogos/vs_varrek.json`, `data/nave/melhorias.json`, `scripts/nave/nave_eco.gd`.

**Regra deste doc:** toda fala nova tem **no máximo 90 caracteres** (folga para o limite que o DEV vai medir no item 16). O script de conferência está descrito na seção 4.

---

## 1. NAR-1 (a) — Vossa Margem: árvore Passiva
**Onde:** ao interagir com o Vossa (`_usar_vossa`), depois de `vossa_primeira`. São falas **rápidas** (uma linha, sem pausar), mostradas na própria tela da árvore Passiva, no lugar da mensagem "feito". Falante: VOSSA.

### 1.1 Primeira vez que a árvore abre (conversa, 1 vez)
Gatilho: 1ª abertura da árvore Passiva depois de `vossa_primeira`. Cena `vossa_arvore_primeira`, `uma_vez: "vossa_arvore_vista"`.

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| PASS_01 | — | VOSSA | sorriso comercial | Catálogo completo! Corpo, Movimento e Fortuna. Tudo pago em Núcleos. |
| PASS_02 | logo depois | RYKER |  | Tem garantia? |
| PASS_03 | logo depois | VOSSA | ganancioso | Vale até a sua próxima morte. Ou seja: depois dela também. Você volta, a melhoria fica. |

### 1.2 Ao abrir a tela (rápida, sortear 1)
Cena `vossa_arvore_abrir`, `condicao: "vossa_arvore_vista"`.

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| PASS_A1 | sorteio | VOSSA | sorriso comercial | O cliente favorito voltou! |
| PASS_A2 | sorteio | VOSSA | ganancioso | Núcleos frescos? Sinto o cheiro daqui. |
| PASS_A3 | sorteio | VOSSA |  | Hoje o preço é o mesmo de ontem. Aproveite essa emoção. |
| PASS_A4 | sem Núcleos para nada | VOSSA | nervoso | Olhar é grátis. Por enquanto. |

### 1.3 Ao comprar cada melhoria (rápida, por `id` de `melhorias.json`)
Toca uma das duas: a primeira na **1ª compra** daquela melhoria, a segunda nas compras seguintes. Substitui o texto "X comprado." quando existir.

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| PASS_C_blindagem | 1ª compra | VOSSA | sorriso comercial | Blindagem! Mais um pedaço de você que não quebra. |
| PASS_C_blindagem2 | seguintes | VOSSA |  | Mais placa. Você vai ranger igual ao Garrak. |
| PASS_C_sinal | compra (só 1 nível) | VOSSA | nervoso | Sinal de Emergência. Volta uma vez. Não me pergunte como, eu só vendo. |
| PASS_C_passada | 1ª compra | VOSSA |  | Passada! Para fugir mais rápido dos seus problemas. |
| PASS_C_passada2 | seguintes | VOSSA |  | Mais rápido ainda. Os problemas também correm, aviso. |
| PASS_C_pernas | 1ª compra | VOSSA | sorriso comercial | Pernas de Mineiro. Pulo mais alto. A tecnologia é sua, eu só cobro. |
| PASS_C_pernas2 | seguintes | VOSSA |  | Mais alto. Cuidado com o teto. |
| PASS_C_propulsores | 1ª compra | VOSSA | ganancioso | Propulsores Ilo! Usados só uma vez. Por um Ilo que explodiu. Detalhe. |
| PASS_C_propulsores2 | seguintes | VOSSA |  | Dash mais curto de espera. Pressa é bom negócio. |
| PASS_C_contato | 1ª compra | VOSSA | sorriso comercial | Contato no Mercado. O contato sou eu. Você vai descer com Créditos. |
| PASS_C_contato2 | seguintes | VOSSA | ganancioso | Mais Créditos lá embaixo. E mais clientes para o meu primo de campo. |
| PASS_C_recalibrar | 1ª compra | VOSSA |  | Recalibrar. Não gostou do que o destino ofereceu? Peça outro. |
| PASS_C_recalibrar2 | seguintes | VOSSA |  | Mais uma troca. O destino odeia clientes como você. |
| PASS_C_memoria | 1ª compra | VOSSA | nervoso | Memória da Âncora. Você lembra mais do que viveu. Não pergunte para a ECO. |
| PASS_C_memoria2 | seguintes | VOSSA |  | Mais memória. Guarde as boas. |
| PASS_C_coleta | 1ª compra | VOSSA | ganancioso | Coleta Fina! Mais Núcleos para você. E, por consequência, para mim. |
| PASS_C_coleta2 | seguintes | VOSSA | ganancioso | Economia circular. Eu adoro círculos. |

`id` de cada linha (em `melhorias.json`): blindagem · sinal_emergencia · passada · pernas_de_mineiro · propulsores · contato_mercado · recalibrar · memoria_da_ancora · coleta_fina.

### 1.4 Outros momentos (rápida)

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| PASS_X1 | melhoria chega ao máximo | VOSSA |  | Completo. Não tem mais o que vender aí. Que tristeza. |
| PASS_X2 | Núcleos insuficientes | VOSSA | nervoso | Faltam Núcleos. Desça, morra com estilo e volte. |
| PASS_X3 | árvore inteira comprada (1 vez) | VOSSA | sorriso comercial | Você comprou tudo. Tudo! Vou mandar fazer uma placa com o seu nome. |
| PASS_X4 | fechar a tela (sorteio) | VOSSA |  | Volte sempre. Literalmente, no seu caso. |

---

## 2. NAR-1 (b) — Garrak: árvore de Combate e Gambiarras
**Onde:** Arsenal (`_usar_garrak`). Falante: GARRAK. Falas **rápidas** dentro da tela da árvore de Combate, salvo as marcadas como conversa.

### 2.1 Primeira vez que a árvore de Combate abre (conversa, 1 vez)
Cena `arsenal_combate_primeira`, `uma_vez: "arvore_combate_vista"`. Entra na lista do `_usar_garrak` **antes** de `arsenal_bramido`.

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| COMB_01 | — | GARRAK | severo | Tudo o que você aprende lá embaixo fica aqui. No corpo e na cabeça. |
| COMB_02 | logo depois | RYKER |  | E a morte não apaga? |
| COMB_03 | logo depois | GARRAK |  | A luz te refaz com o que você aprendeu. Então aprenda. Escolha onde pôr cada ponto. |
| COMB_04 | logo depois | GARRAK | orgulho contido | E se escolher mal, desfaz. Aqui eu não cobro. Na arena eu cobrava. |

### 2.2 Ao abrir a árvore (rápida, sorteio)

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| COMB_A1 | sorteio | GARRAK |  | Mostre o que aprendeu. |
| COMB_A2 | sorteio | GARRAK | severo | Pontos parados não matam ninguém. Gaste. |
| COMB_A3 | há pontos livres | GARRAK |  | Você subiu. Dá para ver no jeito que segura a arma. |
| COMB_A4 | nenhum ponto livre | GARRAK |  | Nada novo. Desça e volte com mais. |

### 2.3 Ao comprar o 1º nó de cada ramo (rápida, 1 vez por ramo)

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| COMB_R_mordida | 1º nó do ramo Mordida | GARRAK | orgulho contido | A Mordida de sempre, só que com mais dente. |
| COMB_R_bramido | 1º nó do ramo Bramido | GARRAK |  | Bramido. Segure com o corpo inteiro, como eu ensinei. |
| COMB_R_granada | 1º nó do ramo Granada | GARRAK |  | Granada. Arma de quem pensa antes de chegar perto. |
| COMB_R_grilhao | 1º nó do ramo Grilhão | GARRAK | vergonha | A corrente da arena... Que ela sirva para alguma coisa boa, então. |
| COMB_R_dash | 1º nó do ramo Dash | GARRAK |  | Pés. Na arena, quem não sabe sair do lugar não sai vivo. |
| COMB_R_x | outros nós (sorteio) | GARRAK |  | Bom. · Isso. · Mais um. · Hm. Aceitável. |

### 2.4 Ápices (rápida, 1 vez por Ápice)

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| COMB_P_grande_arena | Ápice Grande Arena (Mordida) | GARRAK | orgulho contido | Grande Arena. O golpe que você deu na final. Eu vi da grade. |
| COMB_P_recuo | Ápice Recuo de Gladiador (Bramido) | GARRAK |  | O coice que joga você para trás... vai te salvar a vida. Ou não. |
| COMB_P_fragmentacao | Ápice Bomba de Fragmentação | GARRAK |  | Uma granada que solta outras. Os Kharn chamariam isso de covardia. Eu chamo de esperto. |
| COMB_P_explosiva | Ápice Corrente Explosiva | GARRAK | raiva | Corrente que explode. Se o Clã Kesh visse isso, morreria de inveja. |
| COMB_P_2 | 2º Ápice da build (1 vez) | GARRAK | severo | Dois Ápices. Mais que isso, nem o melhor campeão aguenta. |
| COMB_P_limite | tenta um 3º Ápice | GARRAK | severo | Não. Dois. Escolha qual tirar. |

### 2.5 Redistribuir e marcos de nível

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| COMB_D1 | redistribuir (sorteio) | GARRAK |  | Desfazer não é vergonha. Morrer igual duas vezes é. |
| COMB_D2 | redistribuir (sorteio) | GARRAK |  | Começa de novo. Igual cada descida. |
| COMB_N5 | chega ao nível 5 (conversa curta, 1 vez) | GARRAK | orgulho contido | Nível cinco. Na arena, isso era um gladiador que valia a aposta. |
| COMB_N10 | nível 10 (1 vez) | GARRAK |  | Dez. Eu já não teria muito o que te ensinar. Ainda assim, vou tentar. |
| COMB_N25 | nível 25 (1 vez) | GARRAK | orgulho contido | Nada mais para aprender comigo, Ryker. Só com você mesmo. |

COMB_N25 usa "Ryker" porque, no nível 25, o jogador já terá visto NAVE_GARR_6 (NAR-04). Se a flag `garrak_chama_ryker` não estiver ligada, usar "Krat'zu".

### 2.6 Gambiarras
As Gambiarras aparecem durante a run, numa tela de 3 cartas com o jogo pausado (GD-07, seção 5). Garrak não está lá, então **na run quem fala é o Ryker** (bark curto ao escolher), e **na nave o Garrak comenta**.

**Ao escolher uma Gambiarra (rápida, Ryker, sortear 1).** Reaproveita as falas `CAMP_A1` e `CAMP_A2*`, que hoje estão presas ao Aprimoramento que saiu:

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| CAMP_A1 | 1ª Gambiarra escolhida no jogo | RYKER |  | Sucata boa. Dá pra fazer estrago com isso. |
| CAMP_A2a | seguintes (sorteio) | RYKER |  | Mais uma peça. |
| CAMP_A2b | seguintes (sorteio) | RYKER |  | Gambiarra nível arena. |
| CAMP_A2c | seguintes (sorteio) | RYKER |  | Isso aqui era de uma nave Kharn. Agora é meu. |
| GAMB_E1 | 1ª Gambiarra Épica (1 vez) | RYKER | deboche | Essa aqui nem os Kharn têm. |
| GAMB_P | pega a Épica "Prego do Rato" (1 vez) | RYKER |  | O prego do rato. Agora em tamanho de campeão. |

**Na nave, Garrak comenta a run que acabou (rápida, no Arsenal, 1 por volta, só se a run teve Gambiarra):**

| ID | Gatilho | Falante | Expr. | Fala |
|---|---|---|---|---|
| GAMB_G1 | run teve 5 ou mais Gambiarras | GARRAK |  | Quanta sucata soldada. Parecia uma loja Ilo com gatilho. |
| GAMB_G2 | run teve Gambiarra Épica | GARRAK | orgulho contido | Vi a peça grande que você montou. Pena que ficou lá embaixo. |
| GAMB_G3 | sorteio | GARRAK |  | A arma volta limpa. O que você inventou, inventa de novo. |
| GAMB_G4 | sorteio | GARRAK | severo | Gambiarra salva a run. Não salva quem não desvia. |

### 2.7 Destino do diálogo `arsenal_aprimoramento`
- **Hoje:** a cena existe no `vs_varrek.json`, mas a condição `1o_aprimoramento_pego` nunca liga, porque o Aprimoramento de Arma saiu do jogo (D-058).
- **Destino (proposta):** **manter a cena e o texto** (ARSE_A1 a A3: "Vi o que você fez com a arma lá embaixo. Sucata de nave soldada no cano.") e **trocar a condição** para a **1ª Gambiarra escolhida no jogo**. O texto já descreve uma Gambiarra.
  - `condicao`: `1a_gambiarra_pega` (flag nova, ligada quando o jogador escolhe a primeira Gambiarra em qualquer run).
  - `uma_vez`: `arsenal_aprimoramento_visto` (igual).
  - A ordem em `_usar_garrak` continua: `garrak_primeira` → `arsenal_bramido` → `arsenal_aprimoramento` → `arsenal_treino_primeiro`. Entra também `arsenal_combate_primeira` (2.1), logo depois de `garrak_primeira`.
- **Outras cenas presas ao sistema antigo:**
  - `campo_aprimoramento_primeiro` e `campo_aprimoramento`: passam a tocar **ao escolher uma Gambiarra** (2.6). O nome da cena pode continuar.
  - `campo_morte_com_arvore` (CAMP_A3, ECO: "As melhorias ficaram lá embaixo..."): trocar a condição `usou_arvore` por **"morreu com pelo menos 1 Gambiarra"**. O texto continua certo.
  - `campo_primeiro_apice` (CAMP_AP, "Isso... isso é o que eu fazia na final."): o Ápice agora é comprado **na nave**, não na run. Proposta: tocar na **1ª descida depois de comprar o 1º Ápice**, no 1º abate.
- **Treino com Garrak** (agora começa a run com 1 Gambiarra Comum à escolha, GD-07): as falas ARSE_T1 a T3 continuam valendo sem mudança ("Antes de descer: um truque.").

---

## 3. NAR-2 — Falas que passam do limite da D-063

**Situação:** o item 16 do DEV (medir o limite exato) ainda não foi feito. Por isso a NAR mediu o `vs_varrek.json` atual com o limite provisório de **120 caracteres**, contando só o texto que aparece na tela (sem direção de cena).
- **166 falas** no arquivo. **5 passam de 120.** **8 ficam entre 101 e 120** (zona de risco, caso o limite medido saia menor).
- **Regra usada:** dividir em **duas falas seguidas do mesmo falante**, cortando no fim de uma frase. A primeira mantém o ID, e a segunda recebe o mesmo ID com "b". Assim a divisão sai no ponto certo mesmo antes da divisão automática do DEV.

### 3.1 Passam de 120 (dividir já)

| ID | Falante | Tam. | Fala 1 (mantém o ID) | ID novo | Fala 2 |
|---|---|---|---|---|---|
| ABER_03 | ECO | 142 | Morreu. Com bastante estilo, segundo os registros. | ABER_03b | Sua nave atravessou um Portão quebrado e caiu aqui em pedaços. Você estava em vários deles. |
| HANG_05 | ECO | 130 | Uma regra, Ryker: o que é seu volta. Corpo, memória e o que você me transmitir. | HANG_05b | Armas e presentes de alienígenas ficam lá embaixo. |
| KHAR_03 | TOR-AMA | 151 | O Clã Ossoferro não acorrenta quem venceu a Grande Arena. Isso é coisa de clã pequeno, como o Clã Kesh. | KHAR_03b | Ur-Kesh está neste planeta e quer a sua cabeça. |
| VOSS_03 | VOSSA | 127 | Abandonada? Ela tem você. E onde tem um humano que morre muito, tem mercado para melhorias. | VOSS_03b | Eu alugo este compartimento da ECO. |
| GARR_09 | GARRAK | 130 | O clã me mandou atrás de você para cortar sua cabeça. Eu te segui até aquele Portão maldito. | GARR_09b | E não cortei. Agora eu não tenho clã. |

A expressão e a direção de cena da fala original ficam na **fala 1**. A fala 2 herda a mesma expressão.

### 3.2 Zona de risco (101 a 120): ponto de corte já escolhido
Não precisam mudar se o limite medido for 120 ou mais. Se o limite sair menor, cortar **exatamente no ponto marcado com ⫽**:

| ID | Falante | Tam. | Fala com o ponto de corte |
|---|---|---|---|
| ABER_14 | ECO | 115 | O sinal vem de Varrek, o planeta logo abaixo. Um cemitério de naves. ⫽ Os Kharn e os Vesh estão em guerra lá embaixo. |
| ABER_16 | ECO | 106 | Eu posso te mandar lá para baixo. E posso te trazer de volta se você morrer. ⫽ De novo. Mas a escolha é sua. |
| ABER_18 | ECO | 101 | Tem uma peça minha lá embaixo. ⫽ E... faz muito tempo que ninguém fica aqui comigo. Eu ganho companhia. |
| HANG_01 | ECO | 111 | Isto é a âncora. Ela me envia tudo o que você vê e sente. ⫽ Se você morrer lá embaixo, eu te refaço aqui em cima. |
| VESH_03 | COLMEIA | 108 | Um corpo sozinho é um erro. Nós corrigimos erros. ⫽ Mas você... você continua funcionando. Isso nos interessa. |
| LOJA_03 | MERCADOR | 103 | Eu vendo para todos os lados. Por isso eu continuo vivo e eles continuam brigando. ⫽ Créditos, por favor. |
| MORT_06 | ECO | 116 | Não. Você me mandou isto. Núcleos. ⫽ Energia que a âncora coletou. Com eles, você fica um pouco mais difícil de matar. |
| ARSE_M5 | GARRAK | 104 | Eu lembro. Eu estava lá. ⫽ Eu troquei o gatilho dela três vezes naquele ano. Você nunca perguntou por quê. |

### 3.3 Falas dos docs que ainda não estão no jogo (NAR-04 e NAR-05)
Já reescritas dentro do limite, para o DEV usar quando ligar essas cenas:

| ID | Falante | Fala 1 | Fala 2 (ID + "b") |
|---|---|---|---|
| NG5_05 | GARRAK | Uma voz. Mandava eu largar a lâmina. Mandava eu descansar. | Acordei em Varrek com a lâmina na mão. Apertando tanto que a palma sangrava. |
| NE4_03 | ECO | Eu senti o seu coração. Ele bateu igual na final da Grande Arena. | Eu tenho as duas memórias, sabia? E são o mesmo coração. |
| NV3_04 | VOSSA | Alguns pediam reembolso. Diziam que tinham dormido. Num lugar quente. Com alguém cantando. | Golpe, claro! O Sindicato nunca pagou. |
| LEIL_01 | ARREMATE | Senhoras, senhores e colmeias! Lote 4: um humano reimpresso. Levemente usado. | Muito resistente. Lance inicial: dois Créditos. |
| LEIL_D3 | ARREMATE | Eu vendo o que o Caminho cospe. Se não fosse eu, seria outro. | Ah, e aquela gravação de voz de mulher no cofre... Fique. Por conta da casa. |
| VIGI_D4 | ÚLTIMO VIGIA | Porque perdi. E porque, de todos os que vieram, você é o único que ainda resiste. | Não durma. |

O DEV não precisa mexer no NAR-04 e no NAR-05: as versões acima valem quando essas falas entrarem no `vs_varrek.json`.


---

## 4. Conferência
- Script da NAR: lê todas as falas deste doc e o `vs_varrek.json` e mede o número de caracteres do texto de tela.
- **Resultado:** todas as falas novas da seção 1 e 2 têm **até 90 caracteres**; todas as falas divididas na seção 3 têm **até 120**.
- Acentos e ç conferidos (D-046).
- **Para o DEV (item 16):** quando o limite exato for medido, rodar o teste automático. Se ainda sobrar alguma fala acima do limite, a NAR revisa na hora.
