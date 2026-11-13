class_name EfeitoFolha
extends FolhaSprite
## Toca uma animação de folha uma vez e some (ex.: morte de inimigo).
## Opcionalmente cai até o chão (ex.: a placa arrancada do Guerreiro).

var cair: bool = false
var _velocidade_y: float = 0.0
var _chao_y: float = INF


## Uso: EfeitoFolha.new().iniciar(pai, posicao, textura, quadros, fps)
func iniciar(pai: Node, posicao: Vector2, textura: Texture2D, quadros: int, fps: float,
		virar: bool = false, ficar: bool = false) -> void:
	registrar(&"efeito", textura, quadros, fps, false)
	flip_h = virar
	pai.add_child(self)
	global_position = posicao
	tocar(&"efeito")
	if not ficar:
		terminou.connect(func(_a: StringName) -> void: queue_free())


## Faz o efeito cair até o chão (raio para baixo) e parar lá.
func soltar_no_chao(mascara: int) -> void:
	cair = true
	var consulta := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 400), mascara)
	var r: Dictionary = get_world_2d().direct_space_state.intersect_ray(consulta)
	if not r.is_empty():
		_chao_y = r["position"].y


func _process(delta: float) -> void:
	super(delta)
	if cair and global_position.y < _chao_y:
		_velocidade_y += 600.0 * delta
		global_position.y = minf(global_position.y + _velocidade_y * delta, _chao_y)
