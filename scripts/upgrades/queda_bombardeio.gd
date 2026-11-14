class_name QuedaBombardeio
extends Node2D
## Um projétil do Bombardeio de Artilharia (Chamado Kharn): cai do alto da tela sobre um
## inimigo e explode ao chegar. Desenho provisório.

var alvo: Inimigo
var destino: Vector2
var dano: int = 60
var raio: float = 16.0
var autor: Node
var atraso: float = 0.0
var velocidade: float = 420.0


func _physics_process(delta: float) -> void:
	if atraso > 0.0:
		atraso -= delta
		visible = false
		return
	visible = true
	if alvo != null and is_instance_valid(alvo) and alvo.esta_vivo():
		destino = alvo.centro()
	var para: Vector2 = destino - global_position
	if para.length() <= velocidade * delta:
		Explosao.causar(get_parent(), destino, raio, dano, autor, 0.0, 0.0)
		queue_free()
		return
	global_position += para.normalized() * velocidade * delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-2, -6, 4, 8), Color("dccfae"))
	draw_rect(Rect2(-2, 2, 4, 2), Color("ff5a2e"))
