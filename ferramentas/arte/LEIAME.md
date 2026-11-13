# Ferramentas de arte (ART)

Python 3 + Pillow + numpy. Rodar sempre da raiz do repositório.

| Script | O que faz |
|---|---|
| `tratar_ia.py` | **Tratamento das imagens geradas por IA (D-039).** Tira o fundo, acha a grade de pixels, reduz para o tamanho exato, converte para a paleta oficial (ampliada no modo retrato), limpa pixels soltos, refaz o contorno, encaixa no quadro com a origem nos pés e monta a folha. `python3 ferramentas/arte/tratar_ia.py --help` |
| `teste_tratar_ia.py` | Teste da ferramenta: estraga sprites de verdade como um gerador de imagem estraga (escala quebrada, borrão, ruído, JPEG, fundo magenta) e confere se ela os recupera (silhueta ≥ 85%, cores do miolo ≥ 85%) e se o modo retrato nunca usa a cor AVISO. |
| `sprites_v02.py` | Gera por código os sprites provisórios do Ryker (com a **Mordida** e o **Bramido**) e do Guerreiro de Clã, os projéteis e ícones das armas, o tileset e o parallax de Varrek e a tela de conferência `mockup_v02_varrek.png`. |
| `ui_v03.py` | Interface por código: molduras da caixa de diálogo (D-032), peças da tela da árvore (D-040), ícone da porta "Aprimoramento de Arma", elos e barras do HUD, e a tela de conferência `mockup_v03_arvore.png`. |
| `prancha_estilo.py` | Paleta oficial v0.1 (D-033) e a prancha de estilo. Os outros scripts importam a paleta daqui. |

Os prompts que geram as imagens ficam no projeto do Claude, em `ART/prompts/`.
