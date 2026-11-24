# Pacote 02 — Ryker Vale: retrato grande, 4 expressões (D-032, D-044) · v2

**v2 (2026-11-13):** o Ryker agora é descrito como **campeão de arena** (pedido do dono, ver pacote 01 v2).
**Antes:** pacote 00 (briefing) colado. **Rode só depois do pacote 01 aprovado.** Quando o 01 tiver "Descrição fixa aprovada", troque o parágrafo PERSONAGEM abaixo por ela.
**O que gerar:** 1 imagem larga com 4 retratos de meio corpo do Ryker, lado a lado, um por expressão.
**Quantas variações:** 2.
**O que mandar de volta:** as 2 imagens no tamanho original.

**Uso no jogo:** retrato de ~144×208 px à esquerda da caixa de diálogo, virado para a direita (D-032). Placa: **RYKER VALE / Krat'zu, o Gladiador Fugitivo**. Expressões (NAR-01, seção 0): **neutro** (padrão), **deboche**, **raiva**, **abalado**.

## PROMPT (copie tudo entre as linhas)
---
Quatro retratos de diálogo em pixel art detalhada do mesmo personagem, lado a lado numa única imagem larga, para um jogo de ação 2D.

PERSONAGEM: Ryker Vale, um homem humano de uns trinta e poucos anos, **campeão invicto de arenas de luta de alienígenas gigantes**, agora fugitivo. Corpo de lutador: atlético, ombros largos para o tamanho dele, braços fortes e definidos, coberto de cicatrizes de batalha. Cabelo castanho-escuro curto, raspado dos lados, bagunçado em cima; pele morena clara; barba por fazer; nariz quebrado; uma cicatriz atravessando a sobrancelha; olhar firme e provocador. Parte de cima de um macacão laranja de mineração, sem mangas e rasgado, usado aberto; uma ombreira grande de osso de monstro no ombro direito, presa com tiras de couro e rebites; faixas de luta nas mãos e nos antebraços; um colar com um dente enorme de réptil; uma marca de ferro em brasa antiga no ombro esquerdo. No pulso ESQUERDO, uma algema de ferro pesada com um pedaço de corrente quebrada. Um brilho âmbar fraco atrás da nuca, de um pequeno implante.

ENQUADRAMENTO: cada retrato é de meio corpo, da cintura para cima, em vista de três quartos, com o corpo e o rosto virados para o lado DIREITO da imagem. Os quatro retratos têm exatamente o mesmo tamanho, enquadramento, roupa, luz e pose; só mudam o rosto e os ombros. Cada retrato é alto (proporção de uns 9 de largura por 13 de altura). A base de cada retrato é cortada reta na cintura, encostando na borda de baixo da imagem. Deixe espaço vazio entre os quatro retratos; eles não podem se encostar.

EXPRESSÕES, da esquerda para a direita:
1. Neutro: sério, atento, confiante, de quem já viu de tudo; o rosto padrão.
2. Deboche: meio sorriso torto, uma sobrancelha levantada, provocando o adversário.
3. Raiva: dentes cerrados, testa franzida, inclinado para a frente, a mão da algema fechada em punho, pronto para atacar.
4. Abalado: acabou de voltar da morte; pálido, olhos arregalados, suado, a mão no peito. Mesmo assustado, o corpo continua de lutador.

ESTILO: pixel art detalhada, com mais detalhe que um sprite de jogo: pixels quadrados, nítidos e todos do mesmo tamanho, como se cada retrato tivesse uns 144 por 208 pixels e depois fosse ampliado. Sombreamento rico, com 5 a 7 tons por material (pele, tecido, osso, metal), textura visível na pele, nas cicatrizes e no tecido gasto, mas sem desfoque e sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita, com um leve contorno de luz âmbar quente vindo de trás da nuca. Rostos expressivos, levemente exagerados, fáceis de ler em tamanho pequeno.

CORES: monte todos os tons a partir destas cores-base: #16111c, #2b2236, #c4652e, #82391f, #eba35c, #dca07a, #a0644a, #33241f, #3d4c60, #263142, #5e6370, #a4abb6, #dccfae, #9d9175 e #ffc95c (âmbar, só no brilho da nuca).

FUNDO: magenta liso #FF00FF, de borda a borda. Sem moldura, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| Os 4 retratos mudam de roupa, cabelo ou ângulo | "Deixe os quatro retratos idênticos: mesma roupa, mesmo cabelo, mesmo ângulo e mesma luz; mude só a expressão do rosto." |
| Parece um prisioneiro comum | "Ele é um campeão de arena lendário: corpo de lutador, cicatrizes, ombreira de osso e olhar confiante." |
| Retratos se encostando | "Coloque espaço magenta vazio entre os quatro retratos." |
| Olhando para a esquerda | "Os quatro têm que estar virados para o lado direito da imagem." |
| Ficou "pintura" e não pixel art | "Refaça como pixel art nítida, com pixels quadrados visíveis, sem desfoque." |

## O que a ART faz depois (para registro)
```
python3 ferramentas/arte/tratar_ia.py ryker_retratos.png assets/sprites/retratos/ryker/ryker_retratos.png \
  --modo retrato --separar --quadro 144x208 --cores kKoOhsScbBmMxXawW
```
Saída: 4 quadros 144×208, na ordem neutro, deboche, raiva, abalado.
