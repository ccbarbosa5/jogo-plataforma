class_name Fontes
## Fontes do jogo.
## D-056: todo texto é desenhado na resolução nativa da tela, com uma fonte limpa e de boa
## leitura. O projeto usa o modo de escala "canvas_items": o mundo continua numa grade de
## 480×270 (pixel art com filtro Nearest), mas o texto é rasterizado no tamanho real da janela.
## D-046: toda fonte precisa ter os acentos e o ç do português (teste automático).
##
## Fonte: Atkinson Hyperlegible, escolhida pela ART (licença OFL, assets/CREDITS.md e
## assets/fonts/atkinson_hyperlegible/). Regular nas falas e no HUD; Bold na placa, nos botões
## e nos títulos. Os tamanhos são em unidades da tela de 480×270: em 1080p a escala é 4×,
## então 6 vira 24 px (D-056: ~20–24 px em 1080p).

const CAMINHO_REGULAR: String = "res://assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Regular.ttf"
const CAMINHO_NEGRITO: String = "res://assets/fonts/atkinson_hyperlegible/AtkinsonHyperlegible-Bold.ttf"

## Caracteres que toda fonte do jogo precisa ter (teste automático).
const CARACTERES_OBRIGATORIOS: String = "áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ"
## Falas, descrições e nomes de opções.
const TAMANHO_TEXTO: int = 6
## HUD, ajuda e rótulos curtos.
const TAMANHO_PEQUENA: int = 5
## Placa de nome (D-057): Bold 44 px em 1080p (ART: 46).
const TAMANHO_PLACA: int = 11
## Botões dos menus (ART: 34 px em 1080p).
const TAMANHO_BOTAO: int = 8
## Títulos de tela, como PAUSA e CONTROLES (ART: 44 px em 1080p).
const TAMANHO_TITULO: int = 11


static func texto() -> Font:
	return load(CAMINHO_REGULAR) as Font


static func pequena() -> Font:
	return texto()


## Negrito: placa de nome, botões e títulos.
static func placa() -> Font:
	return load(CAMINHO_NEGRITO) as Font


## Deixa a fonte das falas como padrão de todo Label/Control sem fonte própria.
static func aplicar_padrao() -> void:
	ThemeDB.fallback_font = texto()
	ThemeDB.fallback_font_size = TAMANHO_TEXTO
