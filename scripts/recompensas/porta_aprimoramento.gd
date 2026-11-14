@tool
class_name PortaAprimoramento
extends Area2D
## Recompensa "Aprimoramento de Arma" (GD-05 §2.2): +1 Ponto de Aprimoramento.
## Ao pegar, a sala abre a tela da árvore (Jogador.ganhou_aprimoramento).
## Enquanto o gerador de salas não existe, a porta fica na sala e é pega ao encostar.

signal pega(jogador: Jogador)

const ICONE: String = "res://assets/sprites/ui/portas/porta_aprimoramento_de_arma.png"

@export var pontos: int = 1

var _icone: Texture2D
var _usada: bool = false


func _ready() -> void:
	_icone = FolhaSprite.carregar(ICONE)
	if Engine.is_editor_hint():
		return
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
	if _usada or jogador == null or jogador.esta_morto():
		return
	_usada = true
	jogador.ganhar_aprimoramento.call_deferred(pontos)
	pega.emit(jogador)
	if not Dialogos.tocar("campo_aprimoramento_primeiro"):
		Dialogos.tocar("campo_aprimoramento")
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Batente provisório da porta + ícone da ART flutuando em cima.
	var cor: Color = Color("3b3f4a") if not _usada else Color("23262d")
	draw_rect(Rect2(-12, -40, 24, 40), cor)
	draw_rect(Rect2(-12, -40, 24, 40), Color("5b616e"), false, 1.0)
	if _usada:
		return
	var y: float = -64.0 + roundf(sin(Time.get_ticks_msec() / 400.0))
	if _icone != null:
		draw_texture(_icone, Vector2(-12, y))
	else:
		draw_rect(Rect2(-12, y, 24, 24), Color("e8742c"))
