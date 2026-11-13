# Ferramentas de arte (ART)

Python 3 + Pillow + numpy. Rodar sempre da raiz do repositório.

| Script | O que faz |
|---|---|
| `tratar_ia.py` | **Tratamento das imagens geradas por IA (D-039).** Tira o fundo, acha a grade de pixels, reduz para o tamanho exato, converte para a paleta oficial (ampliada no modo retrato), limpa pixels soltos, refaz o contorno, encaixa no quadro com a origem nos pés e monta a folha. `python3 ferramentas/arte/tratar_ia.py --help` |
| `teste_tratar_ia.py` | Teste da ferramenta: estraga sprites de verdade como um gerador de imagem estraga (escala quebrada, borrão, ruído, JPEG, fundo magenta) e confere se ela os recupera (silhueta ≥ 85%, cores do miolo ≥ 85%) e se o modo retrato nunca usa a cor AVISO. |
| `sprites_v02.py` | Gera por código os sprites provisórios do Ryker e do Guerreiro de Clã, o tileset e o parallax de Varrek e a tela de conferência `assets/sprites/conceito/mockup_v02_varrek.png`. |
| `prancha_estilo.py` | Paleta oficial v0.1 (D-033) e a prancha de estilo. Os outros scripts importam a paleta daqui. |

Os prompts que geram as imagens ficam no projeto do Claude, em `ART/prompts/`.
