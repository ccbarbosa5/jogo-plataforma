class_name CameraJogo
extends Camera2D
## Câmera que segue a média dos alvos (pronta para co-op) dentro de um retângulo de limites.
## Para travar a câmera numa arena (paradas estilo Metal Slug), a sala troca os limites
## e a câmera desliza suavemente até eles.

## px à frente do jogador, na direção em que ele olha.
@export var antecipacao: float = 32.0
## Quanto maior, mais rápido a câmera alcança o alvo.
@export var suavizacao: float = 6.0

var alvos: Array[Node2D] = []
var limites: Rect2 = Rect2(0, 0, 480, 270)


func definir_limites(novos: Rect2) -> void:
	limites = novos


func posicionar_imediato() -> void:
	global_position = _ponto_alvo()


func _physics_process(delta: float) -> void:
	var alvo: Vector2 = _ponto_alvo()
	global_position = global_position.lerp(alvo, 1.0 - exp(-suavizacao * delta))


func _ponto_alvo() -> Vector2:
	var soma: Vector2 = Vector2.ZERO
	var quantidade: int = 0
	var direcao: float = 0.0
	for alvo in alvos:
		if is_instance_valid(alvo):
			soma += alvo.global_position
			quantidade += 1
			if alvo is Jogador:
				direcao += (alvo as Jogador).olhando
	if quantidade == 0:
		return global_position
	var ponto: Vector2 = soma / quantidade
	ponto.x += signf(direcao) * antecipacao
	return _limitar(ponto)


func _limitar(ponto: Vector2) -> Vector2:
	var meia: Vector2 = get_viewport_rect().size * 0.5 / zoom
	ponto.x = _limitar_eixo(ponto.x, limites.position.x + meia.x, limites.end.x - meia.x)
	ponto.y = _limitar_eixo(ponto.y, limites.position.y + meia.y, limites.end.y - meia.y)
	return ponto


func _limitar_eixo(valor: float, minimo: float, maximo: float) -> float:
	if minimo > maximo:
		return (minimo + maximo) * 0.5
	return clampf(valor, minimo, maximo)
