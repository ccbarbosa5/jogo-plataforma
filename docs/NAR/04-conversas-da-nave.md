# NAR-04 — Conversas da nave (relacionamentos) · v0.1

Autor: Narrativa (NAR) · Atende ao pedido DIR → NAR, item (1) (CENTRAL, seção 6).
Base: D-023 e D-047 (limite da ECO), D-024 e D-035 (pistas, nada confirmado no VS), D-031 (No Rest), D-032 e D-046 (caixa estilo Hades, placa só com o nome), NAR-01 a NAR-03.
Status: **proposta**. Escopo: **Vertical Slice** (Ato 1). Personagens: Garrak, Sete, Vossa Margem e ECO.

---

## 0. Como funciona (para DEV e GD)
- **Uma conversa nova por personagem a cada volta à nave**, no máximo. É como no Hades: o personagem com conversa nova mostra um **"!" âmbar** sobre a cabeça.
- Cada personagem tem uma **fila de conversas em ordem** (`NAVE_GARR_1`, `NAVE_GARR_2`...). A próxima só fica disponível quando:
  1. a anterior foi vista;
  2. a **condição** da tabela foi cumprida (número de runs, flags);
  3. passou **pelo menos 1 run** desde a anterior do mesmo personagem.
- **Prioridade:** se várias conversas estiverem disponíveis, todas aparecem (cada uma no seu personagem). O jogador escolhe a ordem.
- **Conversas obrigatórias do NAR-01** (Vossa, Garrak, Sete, Mistério) **vêm antes** destas. Uma conversa do NAR-04 nunca toca na mesma volta em que uma do NAR-01 do mesmo personagem tocou.
- **Sem conversa nova:** o personagem usa uma **fala curta de ambiente** (seção 6), sorteada.
- **Pistas** (marcadas com 🔎) somam +1 no contador `duvida` (D-034) quando vistas.
- Todas as conversas usam a caixa grande (D-032). Placas: RYKER, ECO, GARRAK, SETE, VOSSA MARGEM (D-046).

## 1. Garrak — "a dívida"
**Arco:** de mestre e escravo para algo perto de pai e filho, sem nenhum dos dois admitir. **Fim do arco no VS:** Garrak passa a chamá-lo de "Ryker" e destrava a fala ARSE_TR (NAR-03).

| Conversa | Condição | Resumo |
|---|---|---|
| NAVE_GARR_1 | `garrak_conhecido` + 1 run | Por que Garrak treinou Ryker tão bem |
| NAVE_GARR_2 | 3 runs | A aposta na final da Grande Arena |
| NAVE_GARR_3 | `urkesh_encontros` ≥ 1 | Garrak treinou Ur-Kesh antes |
| NAVE_GARR_4 | `urkesh_vitorias` ≥ 1 | Orgulho |
| NAVE_GARR_5 🔎 | 6 runs | O sonho no Portão |
| NAVE_GARR_6 | GARR_1 a 5 vistas + 8 runs | O nome (flag `garrak_chama_ryker`) |

### NAVE_GARR_1 — "Lucro"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NG1_01 | RYKER | | Uma coisa eu nunca entendi. Você me treinou melhor que os outros escravos. Por quê? |
| NG1_02 | GARRAK | severo | Escravo bem treinado dura mais. Escravo que dura mais dá mais lucro. |
| NG1_03 | RYKER | deboche | Só isso? |
| NG1_04 | GARRAK | | Só isso. [volta a afiar a lâmina] |
| NG1_05 | RYKER | | Você trocou o gatilho da Mordida três vezes por lucro. |
| NG1_06 | GARRAK | vergonha | ...Vá descer para Varrek, Krat'zu. |

### NAVE_GARR_2 — "A aposta"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NG2_01 | GARRAK | | Na noite da final, todo o Clã apostou em Ur-Kesh. Todo mundo. |
| NG2_02 | RYKER | | Imaginei. |
| NG2_03 | GARRAK | orgulho contido | Eu apostei em você. O salário de uma temporada inteira. |
| NG2_04 | RYKER | | [pausa] ...E aí? |
| NG2_05 | GARRAK | | Ganhei. E na mesma noite perdi o clã. [olha para as próprias mãos] Foi a aposta mais cara e a mais certa da minha vida. |

### NAVE_GARR_3 — "O melhor aluno"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NG3_01 | RYKER | | Ur-Kesh luta igual a você. A guarda, o passo, tudo. |
| NG3_02 | GARRAK | | Porque eu o treinei. Antes de você. Ele foi meu melhor aluno. |
| NG3_03 | RYKER | raiva | E você me mostrou onde a guarda dele abre. |
| NG3_04 | GARRAK | vergonha | Mostrei. |
| NG3_05 | RYKER | | Isso é traição no Clã Kesh, não é? |
| NG3_06 | GARRAK | severo | No Clã Kesh, tudo é traição. Por isso nunca foi o meu clã de verdade. |

### NAVE_GARR_4 — "Duas vezes"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NG4_01 | GARRAK | orgulho contido | Eu vi pela tela da Ponte. O andador caindo. Ur-Kesh de joelhos. |
| NG4_02 | RYKER | deboche | Gostou do show? |
| NG4_03 | GARRAK | | Você venceu o meu melhor aluno duas vezes. [pausa] Então o meu melhor aluno não era ele. |
| NG4_04 | RYKER | | ...Isso foi um elogio? |
| NG4_05 | GARRAK | severo | Foi um fato. Vá embora antes que vire elogio. |

### NAVE_GARR_5 🔎 — "O Portão"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NG5_01 | RYKER | | Como foi atravessar aquele Portão atrás de mim? |
| NG5_02 | GARRAK | | Escuro. Frio. E depois... quente. [para de afiar] |
| NG5_03 | GARRAK | | Eu sonhei, Krat'zu. Kharn não sonham dentro de nave. Mas eu sonhei. |
| NG5_04 | RYKER | | Com o quê? |
| NG5_05 | GARRAK | | Uma voz. Mandava eu largar a lâmina. Mandava eu descansar. [pausa] Acordei em Varrek com a lâmina na mão. Apertando tanto que a palma sangrava. |
| NG5_06 | RYKER | | ...Pesadelo de viagem. |
| NG5_07 | GARRAK | severo | Pode ser. [volta a afiar, mais forte] Pode ser. |

### NAVE_GARR_6 — "O nome"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NG6_01 | GARRAK | | [Ryker vai pegar a arma. Garrak segura a arma um segundo a mais antes de entregar] Mão firme. Cabeça fria. Volte. |
| NG6_02 | RYKER | | Sempre volto. Ela me traz. |
| NG6_03 | GARRAK | | Não. Volte porque você quer voltar. É diferente. [pausa] ...Ryker. |
| NG6_04 | RYKER | | [para] Você disse meu nome. |
| NG6_05 | GARRAK | | É o seu nome. Krat'zu era o nome do escravo. [olha para ele] O escravo ficou naquele Portão. |
| NG6_06 | RYKER | | [demora para responder] ...Obrigado, Garrak. |
| NG6_07 | GARRAK | severo | Não agradeça. Desça. |

Depois desta conversa, a flag `garrak_chama_ryker` é ligada. Garrak passa a dizer "Ryker" nas falas sorteadas, e a fala ARSE_TR ("Mais um, Krat'— ...Ryker") entra no sorteio do Arsenal.

## 2. Sete — "aprendendo a ser eu"
**Arco:** de um inseto perdido sem o "nós" para alguém que escolhe as próprias palavras. Ele tem medo da ECO sem saber por quê. Aqui é plantado o papel dele na Ruptura (NAR-02, seção 8: o único que a Rainha não consegue copiar).

| Conversa | Condição | Resumo |
|---|---|---|
| NAVE_SETE_1 | `sete_chegou` + 1 run | O que é "sozinho" |
| NAVE_SETE_2 | +1 run | Nomes |
| NAVE_SETE_3 | +1 run | Como era no "nós" |
| NAVE_SETE_4 | 1 morte depois de SETE_3 | Sete quer descer junto |
| NAVE_SETE_5 🔎 | 6 runs | A música |
| NAVE_SETE_6 | SETE_1 a 5 vistas | Escolher |

**Regra de cena:** estas conversas só tocam **com a ECO ausente** da Ponte (Sete se esconde quando ela está).

### NAVE_SETE_1 — "Sozinho"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NS1_01 | SETE | curioso | Ryker. O que é "sozinho"? |
| NS1_02 | RYKER | | É quando não tem mais ninguém. |
| NS1_03 | SETE | confuso | Mas Ryker está aqui. Então Sete não está sozinho. |
| NS1_04 | RYKER | | ...Acho que não. |
| NS1_05 | SETE | feliz | E Sete está aqui. Então Ryker também não está sozinho! [zumbido animado] Sete resolveu sozinho! ...Espera. |

### NAVE_SETE_2 — "Nomes"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NS2_01 | SETE | | Sete chama Ryker de "Ryker". Ryker chama Sete de "inseto". |
| NS2_02 | RYKER | deboche | É. |
| NS2_03 | SETE | curioso | É justo? |
| NS2_04 | RYKER | | [pensa] ...Não muito. Desculpa, Sete. |
| NS2_05 | SETE | feliz | Sete aceita. Sete também chama Garrak de "o grande que range" quando ele não ouve. |
| NS2_06 | RYKER | | [segura o riso] Nunca diga isso na frente dele. |

### NAVE_SETE_3 — "O nós"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NS3_01 | RYKER | | Você sente falta? Da colmeia? |
| NS3_02 | SETE | | No nós, ninguém tinha medo. |
| NS3_03 | RYKER | | Parece bom. |
| NS3_04 | SETE | | Ninguém tinha nada. Nem medo, nem nome, nem "Ryker". [pausa] Sete prefere ter medo e ter "Ryker". |

### NAVE_SETE_4 — "Descer junto"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NS4_01 | SETE | curioso | Sete quer descer com Ryker. Sete pode morder. |
| NS4_02 | RYKER | | Lá embaixo tem milhares de Vesh, Sete. Se a colmeia te pega... |
| NS4_03 | SETE | encolhido | ...O eu acaba. [silêncio] |
| NS4_04 | RYKER | | Fica. Alguém precisa cuidar da nave. |
| NS4_05 | SETE | | Então Sete vigia. [sério] Sete vigia tudo. Até quando Ryker não está. |

### NAVE_SETE_5 🔎 — "A música" (AUD: o Sete cantarola uma melodia curta)
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NS5_01 | — | | [Sete está de costas, cantarolando uma melodia baixa e lenta. Para quando vê Ryker.] |
| NS5_02 | RYKER | | Bonito. Que música é essa? |
| NS5_03 | SETE | confuso | Sete não sabe. Estava dentro de Sete quando Sete acordou. |
| NS5_04 | RYKER | | Música da colmeia? |
| NS5_05 | SETE | encolhido | A colmeia não canta. [pausa] Sete não sabe de onde é a música. Sete não gosta de não saber. |

(Para AUD: é a mesma melodia que a colmeia vai cantar no Ato 3 e que o Sete reconhece na voz da ECO. No VS, ninguém liga uma coisa à outra.)

### NAVE_SETE_6 — "Escolher"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NS6_01 | SETE | feliz | Ryker! Sete aprendeu uma palavra nova. "Escolher". |
| NS6_02 | RYKER | | Boa palavra. |
| NS6_03 | SETE | | No nós, ninguém escolhia. A luz também fala "escolher", mas... [pausa] quando a luz fala, parece que já está escolhido. |
| NS6_04 | RYKER | | [olha na direção da Ponte, sem responder] |
| NS6_05 | SETE | curioso | Sete escolhe uma coisa agora. Sete escolhe ser amigo de Ryker. Pode? |
| NS6_06 | RYKER | | Pode. Ninguém escolhe isso por você. |
| NS6_07 | SETE | feliz | [zumbido feliz] Primeira escolha. Sete guarda. |

## 3. Vossa Margem — "o inquilino"
**Arco:** alívio cômico com um medo escondido. Vossa sabe mais do que diz sobre a Eco e sobre os Portões, mas é covarde demais para dizer.

| Conversa | Condição | Resumo |
|---|---|---|
| NAVE_VOSS_1 | `vossa_conhecido` + 1 run | O que ele faz com os Núcleos |
| NAVE_VOSS_2 | +2 runs | Do que é feito um Ilo |
| NAVE_VOSS_3 🔎 | 5 runs | O avô e os Portões |
| NAVE_VOSS_4 🔎 | 7 runs | O contrato sem data de fim |

### NAVE_VOSS_1 🔎 — "Segredo comercial"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NV1_01 | RYKER | | Pra que você quer tanto Núcleo? |
| NV1_02 | VOSSA | sorriso comercial | Revenda! Eu compro de você e vendo com margem. Daí o nome. |
| NV1_03 | RYKER | | Vende pra quem? A gente tá numa nave no meio do nada. |
| NV1_04 | VOSSA | nervoso | Para... a casa. A administração. A ECO compra de volta. Para manter a nave funcionando. E o reconstrutor. E você. |
| NV1_05 | RYKER | | Então eu pago você, você paga ela, e ela me refaz. |
| NV1_06 | VOSSA | ganancioso | Exato! Uma economia perfeitamente circular. Eu fico com 12%. |

(Pista leve: todo Núcleo que Ryker coleta acaba com a ECO.)

### NAVE_VOSS_2 — "Composição"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NV2_01 | RYKER | | Vossa, o que tem dentro desse traje? |
| NV2_02 | VOSSA | sorriso comercial | Quarenta por cento de gás nobre de primeira qualidade. |
| NV2_03 | RYKER | | E o resto? |
| NV2_04 | VOSSA | ganancioso | Os outros sessenta por cento são informação confidencial do Sindicato. |
| NV2_05 | RYKER | deboche | É peido, né? |
| NV2_06 | VOSSA | nervoso | É GÁS DE COMPOSIÇÃO PROPRIETÁRIA. |

### NAVE_VOSS_3 🔎 — "Reembolso"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NV3_01 | VOSSA | | Meu avô vendia passagens nos Portões. Antes da quebra. Ótimo negócio. |
| NV3_02 | RYKER | | E depois da quebra? |
| NV3_03 | VOSSA | nervoso | Péssimo. Os clientes entravam e não saíam. Ou saíam décadas depois, num planeta errado. |
| NV3_04 | VOSSA | | Alguns pediam reembolso. Diziam que tinham dormido. Num lugar quente. Com alguém cantando. [ri alto demais] Golpe, claro! O Sindicato nunca pagou. |
| NV3_05 | RYKER | | ...Claro. |

### NAVE_VOSS_4 🔎 — "Cláusula"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NV4_01 | RYKER | | Quando acaba o seu aluguel aqui? |
| NV4_02 | VOSSA | sorriso comercial | Ah, o contrato com a ECO é excelente. Sem multas, sem reajuste... |
| NV4_03 | RYKER | | E sem data de fim? |
| NV4_04 | VOSSA | nervoso | [silêncio longo] ...Eu tentei sair uma vez. Pela câmara de carga. A porta não abriu. |
| NV4_05 | RYKER | | Defeito? |
| NV4_06 | VOSSA | sorriso comercial | Defeito! Certamente defeito. [baixo] Ela disse que eu precisava descansar. Núcleos, por favor? |

## 4. ECO — "companhia"
**Arco no VS:** o charme e o cuidado dela crescem. Ela fica mais perto, mais pessoal e mais protetora, e Ryker fica cada vez mais à vontade. Para o jogador, ela tem que parecer **a melhor pessoa da nave**. As pistas são raras e sempre têm leitura normal.
**Limite (D-023, D-047):** atração e carisma pelo jeito de falar, de olhar e de lembrar detalhes. **Sem conteúdo sexual, sem cantada explícita.** O retrato segue a ECO v2 aprovada.

| Conversa | Condição | Resumo |
|---|---|---|
| NAVE_ECO_1 | 2 runs | O que ele gosta |
| NAVE_ECO_2 | +1 run | As cicatrizes |
| NAVE_ECO_3 | +1 run | Muito tempo |
| NAVE_ECO_4 | `urkesh_vitorias` ≥ 1 | O coração dele na final |
| NAVE_ECO_5 🔎 | `registro_molde1_1` + MIST_04 vista | O Molde 1 |
| NAVE_ECO_6 | ECO_1 a 5 vistas | "Todos ficam" |

### NAVE_ECO_1 — "Uma coisa boa"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NE1_01 | ECO | acolhedora | Eu conheço cada batimento seu, Ryker. Mas não sei uma coisa simples. Do que você gosta? |
| NE1_02 | RYKER | | Gostar? Na arena a gente não gostava de nada. |
| NE1_03 | ECO | | Antes da arena, então. |
| NE1_04 | RYKER | | [pensa] ...Da estação. Do turno da noite. Quando as máquinas paravam e dava pra ouvir o casco esfriando. |
| NE1_05 | ECO | sorriso | Silêncio depois do trabalho. [sorri] Eu guardo isso. |

(A partir daqui, uma das falas de ambiente da ECO usa isso: "Ouviu? O casco esfriando. Eu deixei a nave mais quieta pra você.")

### NAVE_ECO_2 — "As cicatrizes"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NE2_01 | ECO | | Toda vez que eu te refaço, eu podia tirar as cicatrizes da arena. Seria fácil. |
| NE2_02 | RYKER | | Não. |
| NE2_03 | ECO | sorriso | Eu sei. Por isso deixo. [a mão de luz passa perto do rosto dele, sem tocar] Elas são suas. Você escolheu ficar com elas. |
| NE2_04 | RYKER | | Você sempre me deixa escolher. |
| NE2_05 | ECO | acolhedora | Sempre. É a coisa que você mais quer, não é? |

### NAVE_ECO_3 — "Muito tempo"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NE3_01 | ECO | distante | Você sabe quanto tempo é "muito tempo", Ryker? |
| NE3_02 | RYKER | | Os anos de arena pareceram muito. |
| NE3_03 | ECO | | Anos. [quase ri] Eu esperei nesta órbita até as estrelas mudarem de lugar no céu de Varrek. Sozinha. |
| NE3_04 | RYKER | | Por que não foi embora? |
| NE3_05 | ECO | preocupada | Para onde? Sem as minhas peças eu não salto. Sem alguém... não tem por que saltar. [volta a sorrir] Mas agora tem você. |

### NAVE_ECO_4 — "Final"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NE4_01 | ECO | sorriso | Eu vi tudo pela âncora. Quando Ur-Kesh caiu. |
| NE4_02 | RYKER | deboche | Gostou? |
| NE4_03 | ECO | acolhedora | Eu senti o seu coração. Ele bateu igual na final da Grande Arena. Eu tenho as duas memórias, sabia? E são o mesmo coração. |
| NE4_04 | RYKER | | ...Isso é estranho de ouvir. |
| NE4_05 | ECO | sorriso | Estranho bom ou estranho ruim? |
| NE4_06 | RYKER | | [demora] Só estranho. |
| NE4_07 | ECO | acolhedora | Eu aceito. |

### NAVE_ECO_5 🔎 — "Ele não quis ficar"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NE5_01 | RYKER | | Aquele registro em Varrek. "Molde 1". Era a voz de um homem. |
| NE5_02 | ECO | | Era. |
| NE5_03 | RYKER | | O que aconteceu com ele? |
| NE5_04 | ECO | distante | [pausa longa] Ele não quis ficar. |
| NE5_05 | RYKER | | Ficar onde? |
| NE5_06 | ECO | acolhedora | [a luz dela fica mais quente, e ela sorri] Você estava tão tenso hoje lá embaixo. Os ombros. Eu senti. Senta um pouco. |
| NE5_07 | RYKER | | [não senta] ...Depois. |

### NAVE_ECO_6 — "Todos ficam"
| ID | Falante | Expr. | Fala |
|---|---|---|---|
| NE6_01 | ECO | acolhedora | Um dia você vai cansar, Ryker. De cair, de morrer, de voltar. |
| NE6_02 | RYKER | | Pode ser. |
| NE6_03 | ECO | sorriso | E aí você vai ficar aqui comigo. Descansar de verdade. Todos ficam, no fim. |
| NE6_04 | RYKER | | Eu não sou todos. |
| NE6_05 | ECO | distante | [olha para ele um tempo] ...Não. Você não é. [sorri de novo] É por isso que eu gosto de você. |

## 5. Cena em grupo: Garrak e Sete
Gatilho: `sete_chegou` + NAVE_GARR_2 vista + NAVE_SETE_2 vista. Toca no Arsenal.

| ID | Falante | Expr. | Fala |
|---|---|---|---|
| GRUP_GS1 | — | | [Ryker entra no Arsenal. Sete está em cima da bancada, observando Garrak afiar a lâmina. Garrak finge que não vê.] |
| GRUP_GS2 | SETE | curioso | O grande que range afia a mesma lâmina todo dia. |
| GRUP_GS3 | GARRAK | severo | ...Do que ele me chamou? |
| GRUP_GS4 | RYKER | deboche | Não faço ideia. |
| GRUP_GS5 | SETE | | Por que afia todo dia? |
| GRUP_GS6 | GARRAK | | Porque um dia vou precisar dela afiada e não vou ter tempo de afiar. |
| GRUP_GS7 | SETE | feliz | Igual Sete vigiando a nave! |
| GRUP_GS8 | GARRAK | orgulho contido | [pausa; quase sorri] ...Igual. Pode ficar aí, pequeno. Só não toque na lâmina. |

Depois desta cena, o Sete às vezes aparece no Arsenal ao lado de Garrak (ambiente).

## 6. Falas de ambiente (sem conversa nova, sorteadas)
| Personagem | Falas |
|---|---|
| GARRAK | "Mão firme." · "Cheiro de Varrek no seu casaco." · "O Clã Kesh ainda grita?" · *(com `garrak_chama_ryker`)* "Volte, Ryker." |
| SETE | "Sete vigiou. Nada aconteceu. Quase nada." · "Ryker voltou! Sete contou: de novo." · "Shh." *(se a ECO estiver presente)* |
| VOSSA MARGEM | "Núcleos, Núcleos, Núcleos!" · "Hoje tem desconto. Brincadeira. Nunca tem." · "Morreu bonito dessa vez?" |
| ECO | "Bem-vindo de volta." · "Você está inteiro. Eu conferi." · *(depois de NAVE_ECO_1)* "Ouviu? O casco esfriando. Eu deixei a nave mais quieta pra você." · "Descanse um pouco." / RYKER: "Depois." |

## 7. Para DEV
- **Novas flags:** `garrak_chama_ryker`, `nave_<personagem>_<n>_vista` (uma por conversa), `grupo_gs_vista`.
- **Contador `duvida` (+1 cada):** NAVE_GARR_5, NAVE_SETE_5, NAVE_VOSS_1, NAVE_VOSS_3, NAVE_VOSS_4, NAVE_ECO_5.
- **"!" âmbar** sobre o personagem com conversa nova.
- **Regra do Sete:** NAVE_SETE_* só com a ECO ausente da sala.
- **ARSE_TR** (NAR-03) só entra no sorteio com `garrak_chama_ryker`.
- Total: cerca de 140 falas.

## 8. Checagem
- **Nada confirmado no VS (D-024):** toda pista tem uma leitura normal (pesadelo de viagem, golpe de clientes, defeito na porta, mudança de assunto).
- **ECO dentro do limite (D-023, D-047):** cuidado, proximidade e memória de detalhes. Sem cantada sexual nem conteúdo sexual.
- **D-021:** nada de teia, aranha ou fios. Nenhum nome ou cena da obra de referência.
- **Acentos (D-046):** todos os textos de tela estão com acentos e ç.
