# Pacote 01 — Ryker Vale: folha de referência (frente + perfil) · v2

**v2 (2026-11-13, pedido do dono):** a v1 gerou um Ryker que "parece um escravo comum, não um lutador". Na história, ele é o **campeão da Grande Arena**, o único humano a vencer, e fugiu. A v2 pede corpo de lutador, postura de campeão e troféus de arena, mantendo o laranja de mineiro, a algema e a âncora.

**Antes:** pacote 00 (briefing) colado.
**O que gerar:** 1 imagem com o Ryker de corpo inteiro, de frente e de perfil, desarmado.
**Quantas variações:** 3.
**O que mandar de volta:** as 3 imagens no tamanho original.

## PROMPT (copie tudo entre as linhas)
---
Folha de referência de personagem em pixel art, para um jogo de ação 2D de plataforma visto de lado.

PERSONAGEM: Ryker Vale, um homem humano de uns trinta e poucos anos, **campeão invicto de arenas de luta de alienígenas gigantes**: o único humano que já venceu a grande final. Era minerador, foi vendido para as arenas, virou lenda e fugiu. Ele é mais baixo que os monstros que enfrenta, mas tem **corpo de lutador**: atlético, ombros largos para o tamanho dele, braços fortes e definidos, músculos secos de quem treinou e lutou a vida inteira (não é fisiculturista, é um gladiador). O corpo é coberto de cicatrizes de batalha. Cabelo castanho-escuro curto, raspado dos lados, bagunçado em cima; pele morena clara; barba por fazer; nariz quebrado; uma cicatriz atravessando a sobrancelha; olhar firme e provocador, um meio sorriso de canto de quem não tem medo de nada.

ROUPA E EQUIPAMENTO DE ARENA:
- a parte de cima de um macacão laranja de mineração, sem mangas e rasgado, usado aberto como uniforme de luta;
- **uma única ombreira grande no ombro direito**, feita de um pedaço de osso de um monstro gigante, presa com tiras de couro e rebites: o troféu da final;
- **faixas de luta** enroladas nas mãos e nos antebraços;
- **um cinto largo de campeão**, de couro e metal, com uma placa de osso no centro;
- um colar com um dente enorme de réptil;
- uma marca de ferro em brasa antiga no ombro esquerdo, a marca de quando ele era propriedade;
- calça de lona azul-acinzentada gasta e botas de trabalho marrons e pesadas;
- no pulso ESQUERDO, uma algema de ferro pesada com um pedaço de corrente quebrada (cinco elos) pendurado;
- na nuca, um pequeno implante de metal com uma única luz âmbar acesa.

COMPOSIÇÃO: duas vistas de corpo inteiro do mesmo personagem, do mesmo tamanho, lado a lado, com espaço vazio entre elas: (1) de frente, (2) de perfil, virado para a direita. **Postura de campeão:** peito aberto, queixo erguido, punhos meio fechados, o peso numa perna, pronto para a luta. Mãos vazias, sem arma. Da cabeça às botas, tudo visível nas duas vistas, nada cortado.

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se cada figura tivesse uns 48 pixels de altura e depois fosse ampliada. Sem suavização, sem desfoque, sem degradê suave, sem textura de pintura. Contorno muito escuro de 1 pixel (#16111c) em volta da figura inteira. Luz vindo do alto, pela direita. Silhueta forte e fácil de ler, proporções levemente exageradas: cabeça um pouco grande, mãos, ombros e botas grandes. Ele tem que parecer **perigoso e lendário**, um campeão, não um prisioneiro qualquer.

CORES: use só estas cores: #16111c, #2b2236, #c4652e, #82391f, #eba35c, #dca07a, #a0644a, #33241f, #3d4c60, #263142, #5e6370, #a4abb6, #dccfae e #9d9175 (osso da ombreira, do cinto e do dente) e #ffc95c (só na luz da nuca).

FUNDO: magenta liso #FF00FF ocupando a imagem inteira, de borda a borda. Sem chão, sem sombra, sem cenário, sem texto, sem rótulos, sem marca d'água.
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| Ainda parece um prisioneiro ou trabalhador comum | "Ele é um campeão de arena lendário: deixe o corpo mais atlético e marcado, a postura mais confiante e o equipamento de gladiador (ombreira de osso, faixas nas mãos, cinto de campeão) bem visível." |
| Grande e musculoso demais (fisiculturista) | "Mantenha ele baixo, com músculos secos de lutador, não um fisiculturista." |
| Fundo não é magenta liso | "A mesma imagem, mas com o fundo todo em magenta liso #FF00FF, sem chão e sem sombra." |
| Pixels borrados, cara de pintura | "Refaça como pixel art de verdade: pixels quadrados, todos do mesmo tamanho, sem suavização e sem degradê." |
| Algema no pulso errado ou sem corrente | "A algema de ferro com a corrente quebrada tem que estar no pulso ESQUERDO dele." |
| Ombreira no ombro errado | "A ombreira de osso fica só no ombro DIREITO." |
| Com arma | "Tire a arma; as mãos dele estão vazias." |

## O que a ART faz depois (para registro)
```
python3 ferramentas/arte/tratar_ia.py ryker_ref.png assets/sprites/personagens/ryker/ryker_referencia.png \
  --separar --altura 28 --quadro 32x32 --cores kKoOhsScbBmMxXawW
```

## Histórico
- **v1 (recusada pelo dono, 2026-11-13):** saiu um mineiro maltrapilho, sem nada de campeão.

## Descrição fixa aprovada
*(a preencher pela ART quando uma variação for aprovada; vai em todos os prompts seguintes do Ryker)*
