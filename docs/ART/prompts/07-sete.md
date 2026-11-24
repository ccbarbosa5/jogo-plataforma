# Pacote 07 — Sete, um Vesh sozinho: referência + retrato (D-032, D-046)

**Antes:** pacote 00 (briefing) colado. **Dois prompts na mesma conversa, nesta ordem:** 7A (referência) e 7B (retrato).
**Variações:** 2 de cada. **Mandar de volta:** todas, dizendo qual é 7A e qual é 7B.

**Quem é (para a ART, não vai para o prompt):** um Vesh pequeno, separado da colmeia, impresso pela ECO como "amostra"; aprendendo a dizer "eu". Fofo e estranho ao mesmo tempo. Placa: **SETE** (D-046). Expressões (NAR-01): **curioso** (padrão), encolhido (medo), feliz, confuso.
⚠ D-021: Sete é um **inseto de 6 membros**, nunca uma aranha (nada de 8 patas, nada de teia, nada de muitos olhos agrupados).

## PROMPT 7A — referência (copie tudo entre as linhas)
---
Folha de referência de personagem em pixel art, para um jogo de ação 2D.

PERSONAGEM: Sete, um pequeno alienígena inseto, do tamanho de um gato grande, filhote de uma raça de insetos de carapaça roxa. Fica em pé sobre as duas patas de trás, meio curvado, com dois braços finos na frente e duas perninhas menores no meio do corpo: seis membros ao todo, como uma formiga ou um louva-a-deus pequeno, nunca uma aranha. Carapaça roxa brilhante, com bolsas de ácido verde-vivo nas costas que brilham fraco. Duas asinhas transparentes, pequenas demais para voar. Cabeça redonda com duas antenas curtas e **dois olhos grandes demais, cor de âmbar**, brilhantes e curiosos. Parece fofo, desajeitado e um pouco estranho, como um bicho que acabou de nascer e ainda está descobrindo o mundo.

COMPOSIÇÃO: duas vistas de corpo inteiro do mesmo personagem, do mesmo tamanho, lado a lado, com espaço vazio entre elas: (1) de frente, (2) de perfil, virado para a direita. Postura curiosa: cabeça inclinada, antenas para cima. Tudo visível, nada cortado.

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se cada figura tivesse uns 32 pixels de altura e depois fosse ampliada. Sem suavização, sem desfoque, sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita.

CORES: use só estas cores e tons delas: #16111c, #2b2236, #4c2c5e, #2b1838, #7d4c90, #a3e23c, #57901f, #b8d4e0 (asas) e #ffc95c (olhos).

FUNDO: magenta liso #FF00FF ocupando a imagem inteira, de borda a borda. Sem chão, sem sombra, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## PROMPT 7B — retrato, 4 expressões (copie tudo entre as linhas)
---
Agora quatro retratos de diálogo em pixel art detalhada do mesmo Sete da imagem anterior, lado a lado numa única imagem larga.

ENQUADRAMENTO: cada retrato mostra o Sete inteiro, grande no quadro, em vista de três quartos, virado para o lado DIREITO da imagem. Os quatro retratos têm exatamente o mesmo tamanho, enquadramento, luz e corpo; só mudam a cabeça, os olhos, as antenas e os bracinhos. Cada retrato é alto (proporção de uns 9 de largura por 13 de altura). A base de cada retrato encosta na borda de baixo da imagem. Deixe espaço vazio entre os quatro; eles não podem se encostar.

EXPRESSÕES, da esquerda para a direita:
1. Curioso: cabeça inclinada, antenas em pé, os olhões âmbar bem abertos; o padrão.
2. Encolhido: com medo, encolhido, bracinhos na frente do rosto, antenas para trás, olhos tremendo.
3. Feliz: braços para cima, antenas balançando, os olhos apertados de alegria, as asinhas abertas.
4. Confuso: uma antena para cima e outra caída, cabeça bem torta, um bracinho coçando a cabeça.

ESTILO: pixel art detalhada, com mais detalhe que um sprite de jogo: pixels quadrados, nítidos e todos do mesmo tamanho, como se cada retrato tivesse uns 144 por 208 pixels e depois fosse ampliado. Sombreamento rico, com 5 a 7 tons por material (carapaça brilhante, ácido, asas transparentes), sem desfoque e sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita.

CORES: as mesmas da imagem anterior: #16111c, #2b2236, #4c2c5e, #2b1838, #7d4c90, #a3e23c, #57901f, #b8d4e0 e #ffc95c (olhos).

FUNDO: magenta liso #FF00FF, de borda a borda. Sem moldura, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| Parece aranha (8 patas, muitos olhos) | "Ele é um inseto de seis membros, como uma formiga em pé, com só dois olhos grandes. Nada de aranha." |
| Assustador demais | "Deixe ele mais fofo e desajeitado, como um filhote curioso." |
| Olhos de outra cor | "Os dois olhos são grandes e cor de âmbar." |
| Virado para a esquerda | "Virado para o lado direito da imagem." |

## O que a ART faz depois
```
python3 ferramentas/arte/tratar_ia.py sete_ref.png assets/sprites/personagens/sete/sete_referencia.png --separar --altura 20 --quadro 32x32 --cores kKvVpzZua --rampas
python3 ferramentas/arte/tratar_ia.py sete_retratos.png assets/sprites/retratos/sete/sete_retratos.png --modo retrato --separar --quadro 144x208 --cores kKvVpzZua
```
