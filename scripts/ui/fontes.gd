class_name Fontes
## Fontes do jogo.
## D-056: todo texto é desenhado na resolução nativa da tela, com uma fonte limpa e de boa
## leitura. O projeto usa o modo de escala "canvas_items": o mundo continua numa grade de
## 480×270 (pixel art com filtro Nearest), mas o texto é rasterizado no tamanho real da janela.
## D-046: toda fonte precisa ter os acentos e o ç do português (teste automático).
##
## Fonte: Open Sans SemiBold, que já vem embutida no Godot (licença aberta, dentro da licença do
## motor; funciona igual no Windows e na Web). Para trocar por outra, mude só texto().
## Os tamanhos são em unidades da tela de 480×270: em 1080p a escala é 4×, então 6 vira 24 px
## (D-056: ~20–24 px em 1080p).

## Caracteres que toda fonte do jogo precisa ter (teste automático).
const CARACTERES_OBRIGATORIOS: String = "áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ"
## Falas, descrições e nomes de opções.
const TAMANHO_TEXTO: int = 6
## HUD, ajuda e rótulos curtos.
const TAMANHO_PEQUENA: int = 5
## Placa de nome (D-057) e títulos de tela.
const TAMANHO_PLACA: int = 8
## Quanto a placa engrossa a letra (FontVariation.variation_embolden).
const NEGRITO_PLACA: float = 0.6

static var _placa: FontVariation


static func texto() -> Font:
	return ThemeDB.get_default_theme().default_font


static func pequena() -> Font:
	return texto()


## Versão em negrito, para a placa de nome e os títulos.
static func placa() -> Font:
	if _placa == null:
		_placa = FontVariation.new()
		_placa.base_font = texto()
		_placa.variation_embolden = NEGRITO_PLACA
	return _placa


## Deixa a fonte das falas como padrão de todo Label/Control sem fonte própria.
static func aplicar_padrao() -> void:
	ThemeDB.fallback_font = texto()
	ThemeDB.fallback_font_size = TAMANHO_TEXTO
