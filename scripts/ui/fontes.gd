class_name Fontes
## Fontes do jogo (D-046: precisam ter todos os acentos e o ç do português).
## - texto: falas, placas de nome e títulos de tela (Jersey 10, tamanho 13).
## - pequena: HUD, ajuda e rótulos curtos (Micro 5, tamanho 10).
## Ambas com licença OFL (assets/CREDITS.md). A fonte padrão do tema é a de texto.

const CAMINHO_TEXTO: String = "res://assets/fonts/jersey10/Jersey10-Regular.ttf"
const CAMINHO_PEQUENA: String = "res://assets/fonts/micro5/Micro5-Regular.ttf"
## Tamanhos em que cada fonte fica nítida na grade de pixels (480×270).
const TAMANHO_TEXTO: int = 13
const TAMANHO_PEQUENA: int = 10
## Caracteres que toda fonte do jogo precisa ter (teste automático).
const CARACTERES_OBRIGATORIOS: String = "áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ"


static func texto() -> Font:
	return load(CAMINHO_TEXTO) as Font


static func pequena() -> Font:
	return load(CAMINHO_PEQUENA) as Font


## Deixa a fonte das falas como padrão de todo Label/Control sem fonte própria.
static func aplicar_padrao() -> void:
	ThemeDB.fallback_font = texto()
	ThemeDB.fallback_font_size = TAMANHO_TEXTO
