# ART-02 — Guia da arena vista de cima (D-077, GD-09) · v0.1

Autor: Arte (ART) · Atende ao **ART-9** da CENTRAL. Complementa o `01-guia-de-estilo.md`: **paleta, contorno, cor AVISO, laranja do Ryker e legibilidade continuam iguais.**

## 1. A câmera e o ângulo **[PROPOSTA: padrão em uso]**
- **O chão é visto de cima** (a arena é um retângulo de 640×384 px, câmera seguindo o Ryker).
- **Os personagens e inimigos são desenhados de lado**, como já são hoje, virando para a esquerda com `flip_h`. É o padrão do gênero: lê bem em tamanho pequeno e mostra a silhueta de cada inimigo.
- Cada personagem ganha uma **sombra no chão** (elipse escura #16111c a 45%, largura = largura do corpo, altura 4 px), centrada nos pés. Voadores (Zangão) têm a sombra 8 px abaixo do corpo, para parecer que voam.
- **Ordem de desenho:** quem está mais embaixo na tela fica na frente (`y_sort` no Godot).

**Por que assim:** **todos os sprites que já existem** (Ryker, Roedor, Chacal, Zangão, Cuspidor, Guerreiro, Muralha, Ninho, Ur-Kesh...) servem na arena sem redesenhar. Só o **chão da arena** e os **destroços** são novos. Economiza semanas de arte.

## 2. Escala
| Coisa | Tamanho | Observação |
|---|---|---|
| Tile do chão | 16×16 | igual ao jogo atual |
| Arena | 640×384 (40×24 tiles) | 16 px de parede em volta |
| Ryker | corpo ~14×28 (quadros de 48×48 existentes) | hitbox do GD-09: círculo de 6 px **nos pés** |
| Inimigos | os sprites atuais | hitbox: círculo nos pés (raio do `arena.json`) |
| Sucata | 8×8 | losango de metal cinza-azulado com um ponto teal, contorno 1 px |
| Ícone de arma (loja/HUD) | 24×24 | por código, a partir dos sprites das armas |
| Ícone de família | 12×12 | Arena = punho laranja, Kharn = crânio-garra brasa, Vesh = favo roxo e verde, Ilo = moeda latão, Vigília = olho teal |

## 3. A arena de Varrek
- **Chão:** areia e ferrugem do cemitério de naves vistas de cima: placas de casco quebradas meio enterradas, rebites, marcas de arrasto, manchas de óleo. Tons **escuros e dessaturados** (camada "cenário jogável" do guia 01, seção 4), para os personagens saturados se destacarem.
- **Variação:** 1 imagem de fundo inteira (640×384) gerada pela IA (pacote 11A), com 6 a 8 "manchas" decorativas por código por cima, para a arena não parecer sempre igual.
- **Paredes:** borda de 16 px com cascos tombados vistos de cima (mais escuros), sem contorno.
- **Destroços (obstáculos, GD-09 §3):** 5 tipos de 32×32 a 48×32, vistos de cima e um pouco de frente (pacote 11B). Contorno de 1 px, porque são sólidos e precisam ler como obstáculo.
- **Marca de nascimento:** círculo pulsante na cor **AVISO** (#fff3a0) que fecha em 1,0 s (já é ataque anunciado). O DEV troca o vermelho provisório.

## 4. Interface da arena
- **HUD:** canto de cima à esquerda: barra de vida (laranja, D-043) + número; Sucata com o ícone; onda e tempo no centro de cima, grandes.
- **Loja do Ilo:** painel nine-patch dos menus atuais; cartas de 104×60 com ícone de 24×24, nome, nível em cor (I cinza #9d9175, II azul #6a8fc4, III roxo #9a5ec4, IV vermelho #c43a3a) e preço. O retrato do Ilo entra quando existir.
- **Números de dano (D-067):** iguais aos de hoje.

## 5. O que a IA faz e o que é código (D-047)
| Peça | Quem |
|---|---|
| Chão de Varrek visto de cima (640×384) | **IA**, pacote 11A |
| Destroços/obstáculos (referência) | **IA**, pacote 11B → ART redesenha em pixel por código |
| Sombra, Sucata, marca de nascimento, ícones, HUD | código (ART) |
| Ryker e inimigos | **já existem** (sprites de lado) |

## 6. Pedidos
- [PARA: DEV] DEV 34: trocar as formas provisórias pelos sprites atuais (seção 1), com sombra, `flip_h` pelo movimento e `y_sort`; marca de nascimento na cor AVISO.
- [PARA: DONO] Gerar o **pacote 11** (2 prompts) e mandar as imagens para a Arte.
