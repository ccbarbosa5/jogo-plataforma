class_name PortaSaida
extends Area2D
## Saída de uma sala com a recompensa mostrada em cima (GD-01 §7.1 e §7.4).
## Encostar escolhe esta saída: as outras somem e a run aplica a recompensa e segue.
## Ícones: o da ART para o Aprimoramento; os outros são provisórios (losango + texto).

signal escolhida(porta: PortaSaida)

const CORES: Dictionary = {
	"kharn": Color("ff5a2e"), "vesh": Color("a3e23c"), "aprimoramento": Color("e8742c"),
	"creditos": Color("d9b26a"), "nucleos": Color("4fb0a6"), "dados": Color("b8d4e0"),
	"vida_maxima": Color("dca07a"), "chefe": Color("ff5a2e"), "seguir": Color("eceff4"),
}
## Rótulo curto em cima da porta (o nome completo fica em RegrasRecompensas.NOMES).
const ROTULOS: Dictionary = {
	"aprimoramento": "Aprimoramento", "vida_maxima": "+1 de vida", "dados": "Dados",
	"kharn": "Dádiva Kharn", "vesh": "Dádiva Vesh", "chefe": "Ur-Kesh",
}
const ICONE_APRIMORAMENTO: String = "res://assets/sprites/ui/portas/porta_aprimoramento_de_arma.png"

var tipo: String = "seguir"
var _usada: bool = false
var _icone: Texture2D


func _ready() -> void:
	add_to_group(&"portas_saida")
	collision_layer = 0
	collision_mask = Camadas.JOGADOR
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24, 40)
	forma.shape = r
	forma.position = Vector2(0, -20)
	add_child(forma)
	if tipo == "aprimoramento":
		_icone = FolhaSprite.carregar(ICONE_APRIMORAMENTO)
	body_entered.connect(_ao_entrar)


func foi_usada() -> bool:
	return _usada


func nome() -> String:
	return RegrasRecompensas.NOMES.get(tipo, tipo)


func _ao_entrar(corpo: Node2D) -> void:
	var jogador := corpo as Jogador
	if _usada or jogador == null or jogador.esta_morto():
		return
	_usada = true
	escolhida.emit.call_deferred(self)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cor: Color = CORES.get(tipo, Color.WHITE)
	draw_rect(Rect2(-12, -40, 24, 40), Color("3b3f4a") if not _usada else Color("23262d"))
	draw_rect(Rect2(-12, -40, 24, 40), Color("5b616e"), false, 1.0)
	draw_rect(Rect2(-12, -40, 24, 3), cor)
	if _usada:
		return
	var y: float = -60.0 + roundf(sin(Time.get_ticks_msec() / 400.0))
	if _icone != null:
		draw_texture(_icone, Vector2(-12, y - 12))
	else:
		var pts := PackedVector2Array([Vector2(0, y - 10), Vector2(10, y), Vector2(0, y + 10), Vector2(-10, y)])
		draw_colored_polygon(pts, Color(cor, 0.85))
		pts.append(pts[0])
		draw_polyline(pts, Color("16111c"), 1.0)
	draw_string(Fontes.pequena(), Vector2(-50, y - 16), ROTULOS.get(tipo, nome()), HORIZONTAL_ALIGNMENT_CENTER, 100,
			Fontes.TAMANHO_PEQUENA, Color("eceff4"))
