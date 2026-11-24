# Pacote 08 — Vossa Margem, do Sindicato Ilo: referência + retrato (D-032, D-046)

**Antes:** pacote 00 (briefing) colado. **Dois prompts na mesma conversa, nesta ordem:** 8A (referência) e 8B (retrato).
**Variações:** 2 de cada. **Mandar de volta:** todas, dizendo qual é 8A e qual é 8B.

**Quem é (para a ART, não vai para o prompt):** um Ilo, ser de gás vivo dentro de um traje; vende as melhorias permanentes na nave (D-020). Comerciante simpático demais, ganancioso e meio covarde. Placa: **VOSSA MARGEM** (D-046). Expressões (NAR-01): **sorriso comercial** (padrão), ganancioso, nervoso.
**Proposta de cor da ART:** o gás dos Ilo é **azul-pálido luminoso** (as cores de asa e branco-ciano da paleta), dentro de um traje de **latão** (os tons de osso + brilhos laranja). Não usa teal (é dos Antigos), roxo (Vesh) nem verde (ácido).

## PROMPT 8A — referência (copie tudo entre as linhas)
---
Folha de referência de personagem em pixel art, para um jogo de ação 2D.

PERSONAGEM: Vossa Margem, um comerciante alienígena feito de gás vivo, que só existe dentro de um traje. O traje é um escafandro antigo e bojudo de latão polido, com rebites, mangueiras, válvulas e enfeites dourados de quem gosta de ostentar; a cabeça é um capacete redondo com um grande visor de vidro. Dentro do visor e por pequenas janelas de vidro no peito, vê-se o gás azul-pálido e luminoso que é o próprio corpo dele, girando devagar; dentro do capacete, o gás forma dois olhos brilhantes e uma boca. Usa um monóculo dourado preso por fora do visor e uma faixa de comerciante cheia de bolsos e pequenas balanças. Postura de vendedor: corpo inclinado para a frente, mãos enluvadas abertas como quem oferece um negócio. Simpático demais, um pouco suspeito.

COMPOSIÇÃO: duas vistas de corpo inteiro do mesmo personagem, do mesmo tamanho, lado a lado, com espaço vazio entre elas: (1) de frente, (2) de perfil, virado para a direita. Tudo visível, nada cortado.

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se cada figura tivesse uns 48 pixels de altura e depois fosse ampliada. Sem suavização, sem desfoque, sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita.

CORES: use só estas cores e tons delas: #16111c, #2b2236, #dccfae, #9d9175, #eba35c, #c4652e, #5e6370, #a4abb6, #b8d4e0 e #dff8ff (o gás).

FUNDO: magenta liso #FF00FF ocupando a imagem inteira, de borda a borda. Sem chão, sem sombra, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## PROMPT 8B — retrato, 3 expressões (copie tudo entre as linhas)
---
Agora três retratos de diálogo em pixel art detalhada do mesmo Vossa Margem da imagem anterior, lado a lado numa única imagem larga.

ENQUADRAMENTO: cada retrato é da cintura para cima, em vista de três quartos, virado para o lado DIREITO da imagem. Os três retratos têm exatamente o mesmo tamanho, enquadramento, traje, luz e pose; só mudam o rosto de gás dentro do capacete e as mãos. Cada retrato é alto (proporção de uns 9 de largura por 13 de altura). A base de cada retrato é cortada reta, encostando na borda de baixo da imagem. Deixe espaço vazio entre os três; eles não podem se encostar.

EXPRESSÕES, da esquerda para a direita:
1. Sorriso comercial: o gás forma um sorriso largo demais e olhos simpáticos, as mãos abertas oferecendo; o padrão.
2. Ganancioso: olhos de gás apertados e brilhando forte, sorriso torto, esfregando as mãos.
3. Nervoso: o gás agitado e girando rápido, olhos arregalados, uma mão no capacete, gotas de condensação no visor.

ESTILO: pixel art detalhada, com mais detalhe que um sprite de jogo: pixels quadrados, nítidos e todos do mesmo tamanho, como se cada retrato tivesse uns 144 por 208 pixels e depois fosse ampliado. Sombreamento rico, com 5 a 7 tons por material (latão polido, vidro, gás luminoso), sem desfoque e sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita.

CORES: as mesmas da imagem anterior: #16111c, #2b2236, #dccfae, #9d9175, #eba35c, #c4652e, #5e6370, #a4abb6, #b8d4e0 e #dff8ff.

FUNDO: magenta liso #FF00FF, de borda a borda. Sem moldura, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| Aparece um rosto humano no capacete | "Não há rosto humano: dentro do capacete só existe gás azul-pálido que forma dois olhos e uma boca." |
| Gás de outra cor | "O gás é azul-pálido e luminoso." |
| Traje moderno ou robótico | "O traje é um escafandro antigo de latão, bojudo, com rebites, válvulas e enfeites dourados." |
| Virado para a esquerda | "Virado para o lado direito da imagem." |

## O que a ART faz depois
```
python3 ferramentas/arte/tratar_ia.py vossa_ref.png assets/sprites/personagens/vossa/vossa_referencia.png --separar --altura 34 --quadro 48x48 --cores kKwWhomMut --rampas
python3 ferramentas/arte/tratar_ia.py vossa_retratos.png assets/sprites/retratos/vossa/vossa_retratos.png --modo retrato --separar --quadro 144x208 --cores kKwWhomMut
```
