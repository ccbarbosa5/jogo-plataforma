# Pacote 05 — Ryker com a Mordida: poses-chave (D-039)

**Antes:** pacote 00 (briefing) colado. Usa as **descrições fixas** aprovadas do Ryker e da Mordida (`descricoes-fixas.md`).
**O que gerar:** 1 imagem com 8 poses do Ryker de corpo inteiro, de perfil, em 2 linhas de 4.
**Quantas variações:** 2.
**O que mandar de volta:** as 2 imagens no tamanho original.

**Para quê:** são as poses-chave das animações (D-039). A ART trata, separa e usa como base para redesenhar as folhas do Ryker (pernas + tronco, 5 direções), completando os quadros intermediários. Também viram referência para os quadros de Grilhão e de dano, que ainda não existem.

## PROMPT (copie tudo entre as linhas)
---
Folha com 8 poses de ação do mesmo personagem em pixel art, para um jogo de ação 2D de plataforma visto de lado.

PERSONAGEM: Ryker Vale, um homem humano de uns trinta e poucos anos, campeão invicto de arenas de luta de alienígenas gigantes, agora fugitivo. Baixo perto dos monstros, mas com corpo de lutador: atlético, ombros largos, peito e abdômen definidos, braços fortes cobertos de cicatrizes vermelhas de batalha. Cabelo castanho-escuro curto, raspado dos lados e arrepiado em cima; pele morena clara; barba por fazer; nariz quebrado; uma cicatriz vermelha na diagonal atravessando a testa e a sobrancelha. Veste a parte de cima de um macacão laranja de mineração como um colete aberto, sem mangas e com as bordas rasgadas. No ombro DIREITO, uma ombreira grande de osso de monstro, presa com tiras de couro marrom e rebites. Colar de couro com um dente grande de réptil. Cinto largo de couro marrom com uma fivela triangular de osso. Faixas de luta cinzentas nas mãos e nos antebraços. No pulso ESQUERDO, uma algema de ferro rebitada com uma corrente quebrada pendurada. Calça de lona azul-acinzentada rasgada nos joelhos e botas de trabalho marrons e pesadas. Na nuca, um pequeno implante com uma luz âmbar acesa.

ARMA (nas mãos dele, nas duas mãos): a MORDIDA, uma rebitadeira industrial de mineração adaptada para virar um rifle; corpo robusto com faixas de perigo laranja e pretas em diagonal; uma placa de osso claro amarrada no topo com corda vermelha; carregador grosso de metal embaixo; bico de metal com um brilho laranja de rebite incandescente.

POSES (todas de perfil, viradas para a DIREITA, mesmo tamanho e mesma escala), primeira linha da esquerda para a direita:
1. Parado em posição de tiro: pernas firmes, a Mordida apontada reto para a frente.
2. Correndo: passada larga, inclinado para a frente, ainda mirando para a frente.
3. Pulando: joelhos dobrados no ar, mirando na diagonal para cima.
4. Agachado: um joelho quase no chão, mirando reto para a frente.
Segunda linha, da esquerda para a direita:
5. Mirando para cima: em pé, a Mordida apontada reto para o céu.
6. Esquiva rápida: o corpo bem inclinado para a frente, as pernas esticadas para trás, um rastro de luz âmbar atrás dele.
7. Lançando a corrente: a mão esquerda esticada para a frente, a corrente quebrada da algema voando reta para a frente; a outra mão segura a Mordida junto ao corpo.
8. Atingido: jogado para trás, o rosto contorcido de dor, a arma ainda na mão.

COMPOSIÇÃO: 2 linhas de 4 poses, com bastante espaço vazio entre todas elas; nenhuma pose encosta na outra. Corpo inteiro visível em todas, da cabeça às botas, nada cortado. Os pés de todas as poses da mesma linha na mesma altura (menos a 3, no ar).

ESTILO: pixel art com pixels grandes, quadrados, nítidos e todos do mesmo tamanho, como se cada figura tivesse uns 48 pixels de altura e depois fosse ampliada. Sem suavização, sem desfoque, sem degradê suave. Contorno muito escuro de 1 pixel (#16111c). Luz vindo do alto, pela direita. Poses exageradas e cheias de energia, fáceis de ler.

CORES: use só estas cores: #16111c, #2b2236, #c4652e, #82391f, #eba35c, #dca07a, #a0644a, #33241f, #9c3527, #3d4c60, #263142, #5e6370, #a4abb6, #4b4753, #7d7886, #dccfae, #9d9175 e #ffc95c (só na luz da nuca e no rastro da esquiva).

FUNDO: magenta liso #FF00FF ocupando a imagem inteira, de borda a borda. Sem chão, sem sombra, sem cenário, sem texto, sem números, sem rótulos, sem marca d'água.
---

## Quando pedir de novo
| Problema | Frase para mandar no ChatGPT |
|---|---|
| Poses se encostando ou fora de ordem | "Separe bem as 8 poses, em 2 linhas de 4, na ordem que eu pedi, com espaço magenta entre todas." |
| Virado para a esquerda | "Todas as poses viradas para a direita." |
| Roupa ou rosto mudando entre as poses | "Mantenha o mesmo personagem em todas: mesma roupa, mesma ombreira no ombro direito, mesmo cabelo." |
| A arma virou um fuzil comum | "A arma é uma rebitadeira industrial de mineração com faixas laranja e pretas, não um fuzil militar." |
| Números ou rótulos nas poses | "Tire os números e os rótulos." |

## O que a ART faz depois (para registro)
```
python3 ferramentas/arte/tratar_ia.py ryker_poses.png /tmp/ryker_poses.png \
  --separar --altura 30 --quadro 48x48 --cores kKoOhsScbBmMxXawWe
```
As 8 poses saem em quadros 48×48, na ordem. A ART usa como base para refazer as folhas do Ryker (mesmos nomes e quadros do LEIAME, D-043).
