class_name PortaSaida
extends Interagivel
## Saída de uma sala com a recompensa mostrada em cima (GD-01 §7.1 e §7.4).
## D-066: encostar só mostra o nome e o que dá; E (ou clique) escolhe esta saída. Aí as outras
## somem e a run aplica a recompensa e segue.
## Ícones provisórios (losango + texto).

signal escolhida(porta: PortaSaida)

const CORES: Dictionary = {
	"kharn": Color("ff5a2e"), "vesh": Color("a3e23c"),
	"creditos": Color("d9b26a"), "nucleos": Color("4fb0a6"), "dados": Color("b8d4e0"),
	"vida_maxima": Color("dca07a"), "chefe": Color("ff5a2e"), "seguir": Color("eceff4"),
}
## Rótulo curto em cima da porta (o nome completo fica em RegrasRecompensas.NOMES).
const ROTULOS: Dictionary = {
	"vida_maxima": "+1 de vida", "dados": "Dados",
	"kharn": "Dádiva Kharn", "vesh": "Dádiva Vesh", "chefe": "Ur-Kesh",
}

var tipo: String = "seguir"
var _usada: bool = false
var _icone: Texture2D


func _ready() -> void:
	add_to_group(&"portas_saida")
	tamanho_area = Vector2(24, 40)
	super()


func foi_usada() -> bool:
	return _usada


func nome() -> String:
	return RegrasRecompensas.NOMES.get(tipo, tipo)


func titulo() -> String:
	return nome()


func descricao() -> String:
	return RegrasRecompensas.EFEITOS.get(tipo, "")


func texto_tecla() -> String:
	return "E: escolher"


func pode_interagir() -> bool:
	return not _usada


func interagir(jogador: Jogador) -> void:
	if _usada or jogador == null or jogador.esta_morto():
		return
	# Ao pegar uma, as outras deixam de valer (a sala as apaga em seguida).
	for p in get_tree().get_nodes_in_group(&"portas_saida"):
		(p as PortaSaida)._usada = true
	escolhida.emit(self)


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
	if e_a_vez():
		desenhar_dica(y - 14)
	else:
		draw_string(Fontes.pequena(), Vector2(-50, y - 16), ROTULOS.get(tipo, nome()), HORIZONTAL_ALIGNMENT_CENTER, 100,
				Fontes.TAMANHO_PEQUENA, Color("eceff4"))
