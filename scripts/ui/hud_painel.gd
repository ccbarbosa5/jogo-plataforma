class_name HudPainel
extends Control
## Desenha o estado do jogador: vida em blocos bem visíveis (pedido de GD), dash, Grilhão,
## granadas, barra de Chamado e arma.

const COR_ELO: Color = Color("c0c5ce")
const COR_ELO_QUEBRADO: Color = Color("3a3346")
const COR_VAZIO: Color = Color("4c566a")
const COR_DASH: Color = Color("7fdcff")
const COR_GRILHAO: Color = Color("ebcb8b")
const COR_GRANADA: Color = Color("6c8a3e")
const COR_CHAMADO: Color = Color("b48ead")

var jogador: Jogador


const PASTA_HUD: String = "res://assets/sprites/ui/hud/"

var _elo: Texture2D = FolhaSprite.carregar(PASTA_HUD + "elo_vida.png")
var _chamado_fundo: Texture2D = FolhaSprite.carregar(PASTA_HUD + "barra_chamado_fundo.png")
var _chamado_cheia: Texture2D = FolhaSprite.carregar(PASTA_HUD + "barra_chamado_cheia.png")
var _chamado_completa: Texture2D = FolhaSprite.carregar(PASTA_HUD + "barra_chamado_completa.png")


## Elo da corrente (folha da ART: 2 quadros de 11×8, cheio / quebrado).
func _desenhar_elo(pos: Vector2, cheio: bool) -> void:
	if _elo == null:
		draw_rect(Rect2(pos, Vector2(11, 8)), COR_ELO if cheio else COR_ELO_QUEBRADO, false, 2.0)
		return
	var regiao := Rect2(0.0 if cheio else 11.0, 0.0, 11.0, 8.0)
	draw_texture_rect_region(_elo, Rect2(pos, Vector2(11, 8)), regiao)


## Barra da ART (52×5): fundo + parte cheia cortada pela fração; "completa" quando no máximo.
func _desenhar_barra(pos: Vector2, fracao: float, fundo: Texture2D, cheia: Texture2D, completa: Texture2D, cor_reserva: Color) -> void:
	fracao = clampf(fracao, 0.0, 1.0)
	if fundo == null or cheia == null:
		draw_rect(Rect2(pos, Vector2(52, 5)), COR_VAZIO)
		draw_rect(Rect2(pos, Vector2(52.0 * fracao, 5)), cor_reserva)
		return
	draw_texture(fundo, pos)
	var textura: Texture2D = completa if fracao >= 1.0 and completa != null else cheia
	var largura: float = roundf(52.0 * fracao)
	if largura > 0.0:
		draw_texture_rect_region(textura, Rect2(pos, Vector2(largura, 5)), Rect2(0, 0, largura, 5))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(jogador):
		return
	# Vida = elos de corrente (D-033).
	var vida: Vida = jogador.vida
	for i in vida.maxima:
		_desenhar_elo(Vector2(i * 13.0, 0.0), i < vida.atual)
	var y: float = 11.0
	# (A barra de Embalo da Mordida entra aqui, logo abaixo dos elos, junto com as armas.)
	for i in jogador.parametros.cargas_dash:
		draw_rect(Rect2(Vector2(i * 13.0, y), Vector2(11.0, 2.0)), COR_DASH if i < jogador.cargas_dash else COR_VAZIO)
	var grilhao := jogador.ferramenta as Grilhao
	if grilhao != null:
		var pronto: float = 1.0 if grilhao.esta_pronto() else 0.0
		if not grilhao.esta_pronto() and grilhao.estado == Grilhao.Estado.PRONTO:
			pronto = 1.0 - grilhao.recarga_restante() / grilhao.recarga
		draw_rect(Rect2(Vector2(26.0, y), Vector2(24.0, 2.0)), COR_VAZIO)
		draw_rect(Rect2(Vector2(26.0, y), Vector2(24.0 * clampf(pronto, 0.0, 1.0), 2.0)), COR_GRILHAO)
	y += 5.0
	_desenhar_barra(Vector2(0.0, y), jogador.barra_chamado / Combate.regras.chamado_maximo,
			_chamado_fundo, _chamado_cheia, _chamado_completa, COR_CHAMADO)
	y += 8.0
	for i in jogador.granadas:
		draw_rect(Rect2(Vector2(i * 7.0, y), Vector2(5.0, 5.0)), COR_GRANADA)
	y += 15.0
	if jogador.arma != null:
		draw_string(Fontes.pequena(), Vector2(0.0, y), jogador.arma_equipada.nome(), HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_PEQUENA)
