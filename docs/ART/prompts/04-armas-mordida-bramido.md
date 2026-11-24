# Pacote 04 — Mordida e Bramido: folha de referência das armas (D-041)

**Antes:** pacote 00 (briefing) colado.
**O que gerar:** 1 imagem com as 2 armas do VS, de perfil, lado a lado.
**Quantas variações:** 3.
**O que mandar de volta:** as 3 imagens no tamanho original.

**Para quê:** fixa o desenho das armas antes das poses do Ryker. Serve de referência para os sprites do tronco (feitos por código, D-039), os ícones do Arsenal e da árvore, e os próximos prompts.

**Ajuste de cor da ART:** o NAR-03 descreve a Mordida como "amarela e preta". Nos sprites, ela usa **faixas de perigo laranja e pretas**, porque o amarelo-claro é a cor AVISO, reservada aos ataques inimigos (D-033), e o laranja é a cor do Ryker (D-043). Registrado como pedido para a NAR.

## PROMPT (copie tudo entre as linhas)
---
Folha de referência de duas armas em pixel art, para um jogo de ação 2D de plataforma visto de lado.

ARMA 1 — MORDIDA: uma rebitadeira industrial de mineração, adaptada à mão para virar um rifle. Corpo robusto de ferramenta pesada, com faixas de perigo laranja e pretas pintadas e gastas. Reforços de sucata alienígena presos com rebites e arame: placas de osso claro e ferro escuro. Um carregador grosso de rebites embaixo. A ponta do cano tem um brilho laranja de rebite incandescente. No cabo, riscos entalhados contando vitórias. Na lateral, um encaixe de metal com um elo de corrente quebrado preso. Ela parece uma ferramenta de trabalho que virou arma, nunca um fuzil militar limpo. Tamanho: cerca de metade da altura de um homem.

ARMA 2 — BRAMIDO: um canhão de braço alienígena enorme e brutal, arrancado do braço de um robô de guerra e adaptado para mão humana. Feito de ferro escuro e placas de osso, com listras vermelho-escuras pintadas por um clã de guerreiros. A boca é larga, com um brilho vermelho-alaranjado de brasa lá dentro. Uma empunhadura humana improvisada, cortada e soldada, e uma alça de couro gasta. É quase do tamanho de um homem: pesado demais para quem carrega.

COMPOSIÇÃO: as duas armas de perfil, com o cano apontando para a DIREITA, lado a lado (Mordida à esquerda, Bramido à direita), na mesma escala, com espaço vazio entre elas. Nenhuma mão segurando, nada cortado.

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se a Mordida tivesse uns 32 pixels de comprimento e o Bramido uns 56, depois ampliados. Sem suavização, sem desfoque, sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita.

CORES: só estas cores e tons delas: #16111c, #2b2236, #4b4753, #7d7886, #5e6370, #a4abb6, #c4652e, #82391f, #eba35c, #dccfae, #9d9175, #9c3527, #ff5a2e.

FUNDO: magenta liso #FF00FF ocupando a imagem inteira, de borda a borda. Sem chão, sem sombra, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| A Mordida parece um fuzil militar | "A Mordida tem que parecer uma ferramenta industrial pesada de mineração, adaptada à mão, não um fuzil militar." |
| Faixas amarelas | "As faixas de perigo da Mordida são laranja e pretas, sem amarelo." |
| O Bramido ficou pequeno | "O Bramido é quase do tamanho de um homem; deixe ele bem maior que a Mordida." |
| Armas apontando para a esquerda | "As duas armas apontam para a direita." |
| Mãos ou personagem na imagem | "Só as armas, sem mãos e sem personagem." |

## O que a ART faz depois (para registro)
```
python3 ferramentas/arte/tratar_ia.py armas.png assets/sprites/armas/armas_referencia.png \
  --separar --altura 16 --cores kKxXmMoOhwWef
```
As duas saem na escala do jogo e viram a base dos troncos do Ryker com cada arma e dos ícones do Arsenal e da árvore.
