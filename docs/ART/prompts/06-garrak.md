# Pacote 06 — Garrak, o Exilado: referência + retrato (D-032, D-046)

**Antes:** pacote 00 (briefing) colado. **Dois prompts na mesma conversa do ChatGPT, nesta ordem:** 6A (referência) e, logo depois, 6B (retrato). Assim o ChatGPT mantém o mesmo personagem.
**Variações:** 2 de cada. **Mandar de volta:** todas, dizendo qual é 6A e qual é 6B.

**Quem é (para a ART, não vai para o prompt):** Kharn velho, mestre de armas da arena que treinou o Ryker; exilado por se recusar a executá-lo; agora cuida do Arsenal da nave. Sem pintura de clã (exilado). Placa: **GARRAK** (D-046). Expressões (NAR-01): **severo** (padrão), orgulho contido, vergonha, raiva.

## PROMPT 6A — referência (copie tudo entre as linhas)
---
Folha de referência de personagem em pixel art, para um jogo de ação 2D.

PERSONAGEM: Garrak, um guerreiro alienígena réptil, velho e enorme, ex-mestre de armas de uma arena de lutas. Corpo maciço e curvado para a frente, mais que o dobro da altura de um homem, cabeça pequena e mandíbula pesada, cauda grossa, pernas fortes de réptil. Pele cinza-esverdeada, grossa e escamosa, cheia de cicatrizes antigas; um olho cortado por uma cicatriz; olhos cor de brasa. Usa o que sobrou de uma armadura de guerreiro: ombreiras de osso rachadas e placas de ferro gastas, presas com couro velho. Num dos ombros, a marca do antigo clã foi raspada à força, deixando só uma cicatriz. Leva uma lâmina larga e curva de ferro apoiada no ombro. Postura severa, digna e cansada, de um mestre que já viu muitos campeões morrerem.

COMPOSIÇÃO: duas vistas de corpo inteiro do mesmo personagem, do mesmo tamanho, lado a lado, com espaço vazio entre elas: (1) de frente, (2) de perfil, virado para a direita. Postura parada e firme. Da cabeça à cauda e aos pés, tudo visível, nada cortado.

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se cada figura tivesse uns 64 pixels de altura e depois fosse ampliada. Sem suavização, sem desfoque, sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita. Silhueta pesada e imponente.

CORES: use só estas cores e tons delas: #16111c, #2b2236, #56604a, #363d30, #7c8a6c, #dccfae, #9d9175, #4b4753, #7d7886, #5e6370, #a4abb6, #82391f e #ff5a2e (só nos olhos).

FUNDO: magenta liso #FF00FF ocupando a imagem inteira, de borda a borda. Sem chão, sem sombra, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## PROMPT 6B — retrato, 4 expressões (copie tudo entre as linhas)
---
Agora quatro retratos de diálogo em pixel art detalhada do mesmo Garrak da imagem anterior, lado a lado numa única imagem larga.

ENQUADRAMENTO: cada retrato é da cintura para cima, em vista de três quartos, com o corpo e o rosto virados para o lado DIREITO da imagem. Ele é tão grande que a cabeça e os ombros quase enchem o quadro. Os quatro retratos têm exatamente o mesmo tamanho, enquadramento, armadura, lâmina no ombro, luz e pose; só mudam o rosto e um pouco a postura. Cada retrato é alto (proporção de uns 9 de largura por 13 de altura). A base de cada retrato é cortada reta, encostando na borda de baixo da imagem. Deixe espaço vazio entre os quatro; eles não podem se encostar.

EXPRESSÕES, da esquerda para a direita:
1. Severo: sério, olhar firme e duro, mandíbula fechada; o rosto padrão.
2. Orgulho contido: o mesmo rosto duro, mas com um quase sorriso no canto da boca e o olhar mais suave.
3. Vergonha: cabeça um pouco baixa, olhar desviado para o lado, os ombros caídos.
4. Raiva: mandíbula aberta mostrando os dentes, olhos de brasa mais acesos, inclinado para a frente.

ESTILO: pixel art detalhada, com mais detalhe que um sprite de jogo: pixels quadrados, nítidos e todos do mesmo tamanho, como se cada retrato tivesse uns 144 por 208 pixels e depois fosse ampliado. Sombreamento rico, com 5 a 7 tons por material (escamas, osso, ferro, couro), textura nas escamas e nas cicatrizes, sem desfoque e sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita.

CORES: as mesmas da imagem anterior: #16111c, #2b2236, #56604a, #363d30, #7c8a6c, #dccfae, #9d9175, #4b4753, #7d7886, #5e6370, #a4abb6, #82391f e #ff5a2e (só nos olhos).

FUNDO: magenta liso #FF00FF, de borda a borda. Sem moldura, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| Pintura de guerra ou símbolos de clã no corpo | "Ele é exilado: sem pintura de guerra e sem símbolos de clã; só a cicatriz da marca raspada no ombro." |
| Parece jovem ou magro | "Ele é velho, enorme e maciço, curvado para a frente, cheio de cicatrizes." |
| Os 4 retratos mudam de roupa ou ângulo | "Deixe os quatro retratos idênticos: mesma armadura, mesma lâmina, mesmo ângulo; mude só a expressão." |
| Virado para a esquerda | "Virado para o lado direito da imagem." |

## O que a ART faz depois
```
python3 ferramentas/arte/tratar_ia.py garrak_ref.png assets/sprites/personagens/garrak/garrak_referencia.png --separar --altura 62 --quadro 64x64 --cores kKgGlwWxXmMOf
python3 ferramentas/arte/tratar_ia.py garrak_retratos.png assets/sprites/retratos/garrak/garrak_retratos.png --modo retrato --separar --quadro 144x208 --cores kKgGlwWxXmMOf
```
