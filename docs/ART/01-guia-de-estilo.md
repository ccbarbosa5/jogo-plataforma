# ART-01 — Guia de estilo visual (v0.4)

Autor: Arte (ART) · Base: D-005, D-016, D-017, D-021 a D-024, D-032, D-033, D-038 a D-047, GD-02, GD-05, NAR-01 v0.3, NAR-03.
Status: **aprovado como base oficial (D-033)**. **Visual oficial do Ryker "campeão" e da ECO v2 aprovado pelo dono (D-046).**
Prancha: `assets/sprites/conceito/prancha_estilo_v01.png`. Telas de conferência: `mockup_v02_varrek.png` (combate), `mockup_v03_arvore.png` (árvore da arma) e `mockup_v04_dialogo.png` (caixa de diálogo).

**Mudanças desde a v0.3.1 (D-046, D-047):**
- Ryker e ECO: visual oficial (seções 5 e 9);
- limite visual da ECO = o das imagens aprovadas (seção 9);
- **placa só com o nome** (seções 10 e 11);
- **fonte própria com acentos** (seção 11);
- divisão IA × código aprovada (seção 13);
- Grilhão e dano do Ryker feitos (seção 5).

---

## 1. Direção geral
- **Pixel art** em 480×270, escala inteira, filtro Nearest (D-005, já no `project.godot`).
- **Peso:** silhuetas grossas, animação exagerada, explosões grandes. **Clima:** cor forte sobre fundo escuro, retratos expressivos. *(As referências de jogo da CENTRAL valem aqui dentro; **nos prompts de IA nunca se cita outra obra**, D-039.)*
- **Pilar 3 na arte:** o humano é a **única figura quente e pequena** da tela. Tudo que é alienígena é maior, mais frio ou mais estranho.
- **Pilar 1 na arte:** legibilidade antes de beleza. Nada no cenário pode ser confundido com perigo, e todo perigo tem a mesma linguagem de aviso.
- **Todo texto na tela tem acentos e ç** (D-046), inclusive nos mockups da ART.

## 2. Escala (D-005, D-033)
- **Tile: 16 px.**
- **Ryker:** corpo de ~14×28 px. **Pernas em quadro 32×32; tronco e corpo inteiro em quadro 48×48.** Origem sempre nos pés, no centro horizontal. Hitbox do código: 12×28 em pé e 12×18 agachado (o tronco desce 10 px).
- Tamanhos dos inimigos seguem o GD-02 (Guerreiro 32×64 num quadro 64×64, Muralha 40×64, Zangão 12×12 etc.). O quadro pode ser maior que o corpo para armas e efeitos.
- A hitbox um pouco menor que o desenho é **desejável**: o tiro de raspão não mata (morte justa).

## 3. Paleta v0.1 (oficial, D-033)
Arquivo: `assets/sprites/paleta_v01.gpl` (34 cores de personagens e efeitos + 11 de cenário). Os scripts usam a mesma paleta a partir de `ferramentas/arte/prancha_estilo.py`.

| Grupo | Cores | Regra |
|---|---|---|
| Contorno | #16111c, #2b2236 | Contorno de 1 px **só em personagens, inimigos, projéteis inimigos e itens**. Cenário não tem contorno. |
| Humanos / Ryker | laranja de macacão #c4652e, lona azul #3d4c60, pele, metal | Únicos tons quentes saturados do primeiro plano. **Laranja = "isto é para o Ryker"** (D-043): a argola do Grilhão, os nós da árvore, a seta de continuar, a barra de Embalo. O cenário não usa laranja vivo. |
| Kharn | pele ardósia #56604a, osso #dccfae, pintura de guerra #9c3527, energia brasa #ff5a2e | Pesados, terrosos. O brilho de arma deles é brasa. |
| Vesh | quitina roxa #4c2c5e, ácido #a3e23c, asas #b8d4e0 | Escuros com pontos de ácido muito vivos. Olhos em âmbar. |
| Ilo (proposta) | latão = tons de osso #dccfae/#9d9175 + brilho #eba35c; gás azul-pálido #b8d4e0/#dff8ff | O gás dos Ilo não usa teal (Antigos), roxo (Vesh) nem verde (ácido). |
| Antigos | teal #4fb0a6 / #2a6a66 | Toda tecnologia dos Antigos: anel de portal, relíquias, interior da nave Eco. |
| ECO | âmbar #ffc95c | Ver seção 9: é a mesma cor dos olhos Vesh, **não** a dos Antigos. O dono confirmou o âmbar (D-033). |
| **AVISO** | #fff3a0 piscando + branco | **Cor reservada.** Só aparece em ataques anunciados. A ferramenta de tratamento a exclui de tudo o que vem da IA, e nenhum objeto do jogo é amarelo-claro. |
| Tiro do jogador | #dff8ff | Fino, rápido e **sem contorno**. Tiros inimigos são grandes, redondos, lentos e com contorno. |

**Retratos (D-032):** a mesma paleta-base, ampliada em rampas de 5 a 7 tons por cor, sem a cor AVISO. A opção `--rampas` usa essas rampas também em sprites que precisam (a ECO, toda em âmbar).

## 4. Legibilidade em combate (pilar 1)
1. **Três camadas de valor:** fundo escuro e dessaturado (com dither) → cenário jogável em cinza-roxo médio → personagens saturados com contorno.
2. **Aviso padronizado (D-043):** cada ataque mostra (a) a pose de preparo própria do inimigo, com brilho de brasa, e (b) **nos últimos 0,2 s**, um flash na cor AVISO no ponto de onde o golpe sai. Marcas no chão usam a mesma cor, piscando.
3. **Primeiro plano decorativo:** sempre escuro e nunca cobrindo a faixa de altura onde há combate.
4. **Partículas** de explosão somem em até 0,4 s e nunca usam a cor AVISO. Os clarões das armas do jogador são laranja, brasa e branco-ciano.
5. **Inimigo atordoado** (Abalo): estrelas/faíscas brasa girando na cabeça. **Ácido:** gotas verdes caindo, 1 gota por acúmulo (até 5).

## 5. Ryker Vale (D-016) — **campeão gladiador, visual oficial (D-046)**
- **Ele é o campeão invicto da Grande Arena e tem que parecer um.** Baixo perto dos gigantes, mas com **corpo de lutador** e **postura de campeão**. Nunca um prisioneiro qualquer, nunca um fisiculturista.
- **Identidade de mineiro:** parte de cima do **macacão laranja de mineração**, sem mangas, rasgado e aberto; calça de lona azul; botas pesadas.
- **Troféus de arena:** **ombreira de osso no ombro direito**, **faixas de luta** nas mãos e nos antebraços, **cinto largo** com fivela de osso, **colar com um dente de réptil**, **marca de ferro** no ombro esquerdo.
- **Algema no pulso esquerdo** com a corrente pendurada (o Grilhão). **Âncora na nuca** em âmbar.
- Cabelo curto, raspado dos lados; barba por fazer; nariz quebrado; cicatriz na sobrancelha.
- Referências aprovadas: `ryker_referencia.png`, `ryker_retratos.png`, `ryker_poses_chave.png`. Descrição fixa: `ART/prompts/descricoes-fixas.md`.

### Armas no sprite (D-040, D-041) — ✔ por código; ✔ referência da IA aprovada (pacote 04)
- **Mordida** (arma própria): rebitadeira de mineração adaptada, com **faixas de perigo laranja e pretas em diagonal** (a cor AVISO é reservada), placa de osso amarrada com corda, carregador de rebites embaixo, elo de corrente na lateral, riscos de vitória no cabo e o bico com o rebite incandescente. **Modo rajada** (ramo B): 3 clarões em fila e o rebite com rastro mais longo.
- **Bramido** (universal Kharn): canhão de ferro com placas de osso, **listras do Clã Kesh**, **boca larga em sino** com brasa dentro, empunhadura de corda e **alça de couro**; **quase do tamanho do Ryker** (pilar 3). **Balins:** clarão em leque. **Bala de cerco** (ramo A): jato longo e estreito.
- Versões grandes (Arsenal, árvore) vêm da IA tratada: `assets/sprites/armas/arsenal/`.

### Animações (✔ = feitas por código seguindo as referências, D-047)
**Corpo em duas partes (pernas + tronco).** **5 direções desenhadas**; as outras 3 são espelhadas. **↓ só no ar** (D-043).

| Parte | Animação | Quadros |
|---|---|---|
| Pernas | ✔ parado / ✔ correr / ✔ agachado / ✔ agachado andando | 1 / 8 / 1 / 6 |
| Pernas | ✔ pulo: subida / topo / queda / pouso | 2 / 1 / 2 / 2 |
| Tronco | ✔ mira em 5 direções × parado, disparo, recuo, modo especial — **Mordida e Bramido** | 4 cada |
| Corpo inteiro | ✔ dash (rastro âmbar) | 4 |
| Corpo inteiro | ✔ morte (vira poeira de luz âmbar = a âncora puxando) | 8 |
| Corpo inteiro | ✔ Grilhão: lançar / puxar-se / puxar inimigo (+ elo e ponta da corrente) | 3 / 2 / 3 |
| Corpo inteiro | ✔ dano (jogado para trás) | 2 |
| Corpo inteiro | golpe de corrente (corpo a corpo) | 4 |
| Corpo inteiro | granada | 4 |
| Corpo inteiro | saída da cápsula | 10 |

Especificação de cada folha: `assets/sprites/personagens/ryker/LEIAME.md`.

## 6. Domínio Kharn
- **Répteis enormes, curvados para frente**, cabeça pequena e mandíbula pesada, cauda grossa, pernas digitígradas. Andam devagar, cada passo levanta poeira.
- **Armadura de osso e ferro** (Clã Ossoferro): ombreiras de osso com espinhos, placas de peito. **A armadura frontal do GD-02 é sempre uma placa de osso visível no peito/escudo.** Quando o Grilhão arranca, ela cai no chão como objeto e o inimigo passa às folhas `_sem_armadura`.
- Pintura de guerra vermelho-óxido, diferente por clã. **Clã Kesh** (de Ur-Kesh, D-035): pintura em listras, sem ossos. As mesmas listras estão no Bramido.
- **Garrak** (exilado): sem pintura de clã; a marca do clã foi raspada do ombro (pacote 06).
- **Inimigos:** Guerreiro ✔ (provisório), Artilheiro, Muralha, Brutamontes.

## 7. Enxame Vesh
- **Insetos de quitina roxa** com glândulas de ácido verde-vivo. Movimento nervoso, em grupo. **Olhos sempre em âmbar.**
- **Sete:** um Vesh pequeno, de 6 membros, olhos âmbar grandes demais, fofo e estranho (pacote 07).
- **Inimigos:** Zangão, Cuspidor, Ninho, Ceifadora.
- **Proibido (D-021/D-022):** nada com 8 patas, nada de teias, nada de fios. Os Vesh constroem com **resina endurecida** e favos.

## 8. Varrek, o Cemitério (Ato 1) — ✔ tileset e parallax
- **Céu:** poeira ferrugem → roxo, com dither, e **o anel quebrado de um Portão dos Antigos** com luzes teal fracas.
- **Parallax em 4 camadas:** céu e anel (fixo) → cascos distantes (0,2) → cascos médios (0,5) → camada jogável (1,0) → primeiro plano escuro (1,3).
- **Tileset da camada jogável:** 16 tiles para o terrain "Match Sides" do Godot, miolos variados, plataformas atravessáveis, decoração. Detalhes: `assets/sprites/cenarios/varrek/LEIAME.md`.
- **Próximo:** variações por sala (Carcaça, Linha Kharn, Ninhos Vesh, Zona de guerra, Relíquia, Arena de Ur-Kesh).
- **Pontos de ancoragem do Grilhão:** sempre a mesma argola de metal com o ponto laranja.

## 9. ECO e a Rainha (D-022 a D-024, D-033, D-046, D-047)

### A pista de cor (aprovada, D-033)
- A nave Eco é dos Antigos, então **todo o interior dela é teal**. **A ECO, porém, é âmbar**, a mesma cor dos olhos Vesh e da resina. É a única luz quente da nave.
- **Nos prompts de IA, nada disso é dito** (D-045).

### A máscara: ECO em holograma — **visual oficial (D-046)**
- **Mulher muito bonita, sensual e glamourosa, feita de luz âmbar:** corpo esguio e curvilíneo, rosto marcante, lábios cheios, olhar sedutor e acolhedor ao mesmo tempo, sorriso de canto charmoso e misterioso.
- **Vestido de festa feito de luz:** tomara-que-caia, justo, com fenda alta; a barra se desfaz em partículas que sobem; sapatos de salto.
- **Limite (D-023, D-047):** o das imagens aprovadas pelo dono. **Sem nudez, sem pose sexual e sem conteúdo sexual explícito.**
- Cabelo longo, volumoso e ondulado de luz, que se desfaz em partículas que **sobem**, nunca em fios radiais.
- Linhas de varredura de holograma; de perto, **pequenas células hexagonais**. **Sem símbolos ou estampas no vestido.**
- No VS, sem glitch. **A partir do Ato 2 (proposta):** em momentos raros, 1 quadro de falha em que o contorno dela fica largo demais na parte de baixo.
- O brilho (cintilar, linhas de varredura animadas, mistura aditiva) é do DEV, por cima do PNG.
- Referências aprovadas: `eco_referencia.png`, `eco_retratos.png`.

### A forma real: Vasha, a Rainha (Ruptura, fora do VS)
- **Rainha-cupim colossal (fisogástrica):** cabeça e tórax pequenos, 6 patas curtas e inúteis, **abdome gigantesco, inchado, pálido creme**, com placas escuras espaçadas e um pulsar lento.
- **Câmara real** de argila e resina, galerias de cupinzeiro, servos Vesh.
- **Viajantes presos em casulos de resina âmbar endurecida**, de olhos fechados e rostos tranquilos.
- **Obrigatório (D-021):** sem 8 patas, sem patas longas, sem teia, sem fios. O contraste com a ECO sedutora é o choque da revelação.

## 10. Retratos de diálogo (D-032, D-046)
- **Pixel art grande e detalhada, ~144×208 px**, meio corpo, cortado na cintura. Rampas de 5 a 7 tons por material; anti-aliasing manual permitido só aqui.
- **Feitos com IA + tratamento da ART (D-039).** Saem da ferramenta já no quadro 144×208.
- **Todos gerados virados para a DIREITA.** O jogo espelha os do lado direito (D-032).
- **Placa só com o NOME** (D-046), em maiúsculas, com a fonte ×2. Os nomes exatos ficam com a NAR.

| Personagem | Placa | Expressões (NAR-01; a 1ª é a padrão) | Status |
|---|---|---|---|
| Ryker | RYKER | **neutro**, deboche, raiva, abalado | ✔ aprovado |
| ECO | ECO | **acolhedora**, sorriso, preocupada, distante (luz mais fraca: pista) | ✔ aprovado |
| Garrak | GARRAK | **severo**, orgulho contido, vergonha, raiva | pacote 06 |
| Sete | SETE | **curioso**, encolhido, feliz, confuso | pacote 07 |
| Vossa Margem | VOSSA MARGEM | **sorriso comercial**, ganancioso, nervoso | pacote 08 |
| Mercador Ilo | MERCADOR | **sorriso comercial**, decepcionado | depois |
| Tor-Ama | TOR-AMA | **imponente**, divertida, aprovação | depois |
| A Colmeia | A COLMEIA | **enxame calmo**, enxame agitado | depois (pode ser por código) |
| Ur-Kesh | UR-KESH | **fúria**, desdém, ferido; *andador* e *a pé* | depois |

- **Animação sutil:** piscar (2 quadros extras por expressão, a fazer) e respiração (o DEV move 1 px). Na ECO, partículas subindo (por código).

## 11. Interface — ✔ molduras, árvore, HUD e fonte (por código)
Arquivos e instruções no Godot: `assets/sprites/ui/LEIAME.md` e `assets/fontes/LEIAME.md`.
- **Vida = 4 elos de corrente.** **Embalo da Mordida:** barrinha laranja embaixo dos elos; fica branco-ciano quando enche. **Chamado** em âmbar. Granadas (3) ao lado.
- **Recarga do Grilhão e do dash:** no próprio Ryker, sem barra extra.
- **Caixa de diálogo (D-032, D-046):** retrato grande passando por cima da borda; **placa só com o NOME**; caixa larga com moldura e seta de continuar; quem não está falando fica apagado (~55%); cenário escurecido atrás. **Molduras** em nine-patch 48×48, margem 12, bordas que repetem sem esticar: **humana**, **Kharn**, **Vesh**, **Ilo**, **ECO**.
- **Durante o combate:** falas rápidas pequenas no topo da tela, sem retrato.
- **Tela da árvore** (D-040): **sempre a moldura humana** (D-047); ícone da arma, nome e assinatura no topo; pontos (porcas de sucata) no canto; 3 ramos em colunas; nós de cima para baixo (1 → 2 → Ápice losango); custo em rebites; Ápice trancado aparece rachado; contorno piscando no 1º uso.
- **Ícone da porta "Aprimoramento de Arma":** chave inglesa, cano e a porca de sucata.
- **Fonte própria do No Rest (D-046):** pixel 5×7, 156 caracteres, **todos os acentos do português**, ç, ª º, — …; `no_rest_5` (texto) e `no_rest_5_x2` (placas). Feita por código, sem licença de terceiros. `fonte_v01.py --verificar` confere se cobre todo o texto dos diálogos.

## 12. Especificação técnica dos arquivos (para DEV)
- PNG, fundo transparente. Import no Godot com filtro desligado (padrão do projeto).
- Pastas: `assets/sprites/personagens/<nome>/`, `assets/sprites/inimigos/<faccao>/<nome>/`, `assets/sprites/armas/`, `assets/sprites/cenarios/<ato>/`, `assets/sprites/ui/`, `assets/sprites/retratos/<nome>/`, `assets/fontes/`.
- Uma folha por animação, em linha, quadros do mesmo tamanho: `<nome>_<animacao>.png`. Quadros, velocidade e offsets vão num `LEIAME.md` da pasta.
- Origem: **nos pés, centro horizontal do quadro**, em todas as folhas de personagem e inimigo. Projéteis e ícones apontam para a direita.
- Tilesets: 16×16, uma folha por ambiente, terreno no modo "Match Sides" (bits N=1, L=2, S=4, O=8).
- Originais da IA: `ferramentas/arte/originais_ia/` (a pasta `ferramentas/` tem `.gdignore`).

## 13. Fluxo de arte com IA (D-039, D-045, D-047)
- **Divisão aprovada (D-047):** a **IA** faz o que é grande (retratos, armas do Arsenal, referências de personagem, poses de referência, arte-chave, capa). **Os sprites de jogo (~28 px)**, tiles, efeitos, interface, molduras e a fonte são **feitos por código pela ART, copiando as referências da IA**: nesse tamanho, o detalhe da IA vira ruído.
- **Prompts:** `ART/prompts/`, **sempre em português** (D-045), e **colados também direto na conversa de Arte**. O **pacote 00, Briefing visual**, é colado uma vez e **não contém nenhum segredo da história**. Fundo magenta liso, paleta com os códigos oficiais, nunca citar outras obras, retratos virados para a direita, nada de texto na imagem.
- **Tratamento:** `ferramentas/arte/tratar_ia.py` (fundo, fase da grade, tamanho exato, paleta com rampas quando preciso, limpeza, contorno, encaixe, separação por linha). Teste em `teste_tratar_ia.py` (silhueta ≥ 85%, cores do miolo ≥ 80%).
- **Consistência:** cada personagem tem uma **folha de referência aprovada + descrição fixa** (`descricoes-fixas.md`), que entra em todo prompt dele.
- **Retoque manual obrigatório depois da ferramenta:** olhos e detalhes de 1 px.
- **Registro:** toda imagem gerada por IA entra marcada em `assets/CREDITS.md` (D-039).
