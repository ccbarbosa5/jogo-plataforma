class_name EstacaoReparo
extends Area2D
## Sala de Reparo (GD-01 §7.2): cura 2 blocos OU dá um upgrade extra; o jogador escolhe 1.
## São duas estações lado a lado; usar uma desliga a outra. Desenho provisório.

signal usada(estacao: EstacaoReparo, jogador: Jogador)

const CURA_BLOCOS: int = 2

var tipo: String = "cura"  # "cura" ou "dadiva"
var par: EstacaoReparo
var desligada: bool = false


static func criar_par(pai: Node, pos_cura: Vector2, pos_dadiva: Vector2) -> Array[EstacaoReparo]:
	var a := EstacaoReparo.new()
	a.tipo = "cura"
	a.position = pos_cura
	var b := EstacaoReparo.new()
	b.tipo = "dadiva"
	b.position = pos_dadiva
	a.par = b
	b.par = a
	pai.add_child(a)
	pai.add_child(b)
	return [a, b]


func _ready() -> void:
	add_to_group(&"estacoes_reparo")
	collision_layer = 0
	collision_mask = Camadas.JOGADOR
	var forma := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(24, 24)
	forma.shape = r
	forma.position = Vector2(0, -12)
	add_child(forma)
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node2D) -> void:
	var jogador := corpo as Jogador
	if desligada or jogador == null or jogador.esta_morto():
		return
	usar(jogador)


func usar(jogador: Jogador) -> void:
	desligada = true
	if par != null and is_instance_valid(par):
		par.desligada = true
		par.queue_redraw()
	if tipo == "cura":
		jogador.vida.curar(CURA_BLOCOS)
	usada.emit(self, jogador)
	# A dádiva extra é aberta pela run (TelaRecompensa), que escuta o grupo.
	var run := get_tree().get_first_node_in_group(&"run_ato")
	if run != null and tipo == "dadiva":
		run.oferecer_dadiva_extra(jogador)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cor: Color = Color("dca07a") if tipo == "cura" else Color("ffc95c")
	if desligada:
		cor = Color("3f4250")
	draw_rect(Rect2(-10, -8, 20, 8), Color("4b4753"))
	draw_rect(Rect2(-6, -22, 12, 14), Color(cor, 0.9))
	var texto: String = "Cura: +2 blocos" if tipo == "cura" else "Dádiva extra"
	if not desligada:
		draw_string(Fontes.pequena(), Vector2(-50, -28 + roundf(sin(Time.get_ticks_msec() / 400.0))), texto,
				HORIZONTAL_ALIGNMENT_CENTER, 100, Fontes.TAMANHO_PEQUENA, Color("eceff4"))
