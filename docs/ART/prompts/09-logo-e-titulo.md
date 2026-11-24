# Pacote 09 — Logo de No Rest e fundo da tela de título (D-053)

**Antes:** pacote 00 (briefing) colado. **Dois prompts na mesma conversa do ChatGPT:** 9A (logo) e 9B (fundo).
**Variações:** 2 a 4 de cada. **Mandar de volta:** todas, dizendo qual é 9A e qual é 9B.

**Para a ART (não vai para o prompt):**
- Já existe um logo provisório por código (`logo_no_rest_provisorio.png`) e um fundo em 3 camadas; este pacote é para o definitivo.
- Ideia: chapa de metal laranja batida, como uma placa de arena; uma corrente partida (o gladiador que fugiu). Nenhum segredo da história (nada da Rainha, nada da ECO).
- O fundo precisa deixar espaço livre no centro e embaixo para os botões do menu.

## PROMPT 9A — logo (copie tudo entre as linhas)
---
Logo de videogame em pixel art, com o nome "NO REST" escrito em letras maiúsculas grandes, grossas e pesadas, levemente inclinadas para a frente, como se estivessem em movimento.

As letras parecem chapas de metal laranja batidas e marcadas por golpes, como uma placa velha de arena de gladiadores: topo de cada letra com um fio de luz claro, corpo laranja e base laranja-escura, com profundidade em bloco 3D para baixo e para a direita, em roxo bem escuro. Embaixo do nome, uma corrente de ferro atravessa o logo de ponta a ponta e está partida no meio, com os elos abertos e algumas faíscas cor de brasa saindo da quebra.

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se o logo tivesse uns 240 pixels de largura e depois fosse ampliado. Sem suavização, sem desfoque, sem degradê suave. Contorno muito escuro de 1 pixel (#16111c) em volta de tudo. Escreva exatamente "NO REST", sem nenhuma outra palavra, sem subtítulo.

CORES: use só estas cores e tons delas: #16111c, #2b2236, #82391f, #c4652e, #eba35c, #dccfae, #5e6370, #a4abb6 e #ff5a2e (só nas faíscas).

FUNDO: magenta liso #FF00FF ocupando a imagem inteira, de borda a borda. Sem cenário, sem sombra no chão, sem marca d'água.
---

## PROMPT 9B — fundo da tela de título (copie tudo entre as linhas)
---
Cenário em pixel art para a tela de título de um jogo de ação 2D, em formato largo 16:9.

CENA: ao entardecer, num planeta deserto e poeirento, as ruínas de uma arena de gladiadores gigantesca, construída para lutadores muito maiores que um homem. Muralhas curvas com dois andares de arcos, parte delas desabada; correntes enormes penduradas de pilares quebrados. Ao fundo, mesas de pedra e torres distantes. No céu, de cima para baixo, o roxo escuro vira vermelho e depois laranja; algumas estrelas; e um anel de pedra gigantesco e quebrado atravessando o céu, com pequenas luzes verde-azuladas apagando. Brasas pequenas sobem no ar.

COMPOSIÇÃO: o centro da imagem e a metade de baixo do centro ficam mais vazios e escuros (ali vão o logo e os botões do menu); os detalhes ficam nas laterais. Visto de frente, sem personagens.

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se a imagem tivesse 480 por 270 pixels e depois fosse ampliada. Cores de cenário com pouca saturação, para o logo e os botões se destacarem. Pontilhado (dithering) na passagem de cor do céu. Sem desfoque, sem degradê suave, sem texto, sem logo, sem marca d'água.

CORES: use só estas cores e tons delas: #1e1424, #3a1f30, #6a3030, #a2523a, #c9773f, #4a2a33, #2f1d28, #20141d, #16111c, #4fb0a6 (só nas luzinhas do anel) e #eba35c (só nas brasas).
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| Escreveu errado ou acrescentou palavras | "Escreva só NO REST, exatamente assim, sem nenhuma outra palavra." |
| Letras finas ou elegantes demais | "Letras grossas, pesadas, de metal batido, como uma placa de arena." |
| Logo em cima de um cenário | "Só o logo, sobre fundo magenta liso #FF00FF." |
| Fundo cheio demais no meio | "Deixe o centro e a parte de baixo do centro mais vazios e escuros, para o menu." |
| Aparece um personagem | "Sem personagens: só a arena em ruínas e o céu." |

## O que a ART faz depois
```
python3 ferramentas/arte/tratar_ia.py logo.png assets/sprites/ui/titulo/logo_no_rest.png --cores kKOohwmMf --rampas
python3 ferramentas/arte/tratar_ia.py fundo.png assets/sprites/ui/titulo/fundo_titulo_ia.png --fundo nenhum --altura 270 --quadro 480x270 --sem-contorno
```
O fundo da IA não tem magenta, por isso usa `--fundo nenhum`. Se ele não puder ser separado em camadas para o parallax, entra parado, só com as brasas por cima.
