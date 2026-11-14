class_name PortaFaccao
extends Area2D
## Recompensa de facção (GD-01 §6.3): ao encostar, abre a TelaRecompensa com 3 dádivas da facção.
## O emblema da facção fica em cima da porta (provisório até a ART: brasa Kharn, verde Vesh).
## Enquanto o gerador de salas não existe, a porta fica na sala e é pega ao encostar.
## Pegar uma porta do grupo "portas_sala" fecha as outras (o jogador escolhe 1 saída).

const GRUPO: StringName = &"portas_sala"

@export var catalogo: CatalogoFaccao
## Sala Elite: garante Raro ou melhor.
@export var elite: bool = false

var _usada: bool = false


func _ready() -> void:
	add_to_group(GRUPO)
	collision_layer = 0
	collision_mask = Camadas.JOGADOR
	if get_child_count() == 0:
		var forma := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(24, 40)
		forma.shape = r
		forma.position = Vector2(0, -20)
		add_child(forma)
	body_entered.connect(_ao_entrar)


func foi_usada() -> bool:
	return _usada


func _ao_entrar(corpo: Node2D) -> void:
	var jogador := corpo as Jogador
	if _usada or jogador == null or jogador.esta_morto() or catalogo == null:
		return
	var tela := get_tree().get_first_node_in_group(TelaRecompensa.GRUPO) as TelaRecompensa
	if tela == null or tela.esta_aberta():
		return
	_usada = true
	fechar_outras_portas(self)
	tela.abrir.call_deferred(jogador, catalogo, elite)
	queue_redraw()


## O jogador escolheu esta saída: as outras portas da sala somem.
static func fechar_outras_portas(escolhida: Node) -> void:
	for p in escolhida.get_tree().get_nodes_in_group(GRUPO):
		if p != escolhida:
			p.queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cor: Color = catalogo.cor if catalogo != null else Color.WHITE
	draw_rect(Rect2(-12, -40, 24, 40), Color("3b3f4a") if not _usada else Color("23262d"))
	draw_rect(Rect2(-12, -40, 24, 40), Color("5b616e"), false, 1.0)
	if _usada:
		return
	var y: float = -60.0 + roundf(sin(Time.get_ticks_msec() / 400.0))
	# Emblema provisório: losango na cor da facção com a inicial.
	draw_colored_polygon(PackedVector2Array([Vector2(0, y - 10), Vector2(10, y), Vector2(0, y + 10), Vector2(-10, y)]), Color(cor, 0.85))
	draw_polyline(PackedVector2Array([Vector2(0, y - 10), Vector2(10, y), Vector2(0, y + 10), Vector2(-10, y), Vector2(0, y - 10)]), Color("16111c"), 1.0)
	var inicial: String = catalogo.nome.substr(catalogo.nome.rfind(" ") + 1, 1) if catalogo != null else "?"
	draw_string(Fontes.texto(), Vector2(-6, y + 4), inicial, HORIZONTAL_ALIGNMENT_CENTER, 12, Fontes.TAMANHO_TEXTO, Color("16111c"))
