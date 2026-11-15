class_name Chacal
extends InimigoEnxame
## Chacal de Clã (Kharn, enxame, GD-08 §2): 14×10, 22 de vida (2 tiros), 6 tiles/s.
## Corre pelo chão e, a cada ~2,5 s, salta em arco até o jogador. Aviso de 0,3 s (agacha e
## brilha; a cor AVISO só nos últimos 0,2 s). O salto não usa ficha.

enum Estado { CORRER, AVISO, SALTO }

const PASTA_SPRITES: String = "res://assets/sprites/inimigos/kharn/chacal/"

@export var intervalo_salto: float = 2.5
@export var tempo_aviso: float = 0.3
## Tempo de voo do salto (s) e alcance máximo (tiles).
@export var duracao_salto: float = 0.6
@export var alcance_salto_tiles: float = 7.0

var estado: Estado = Estado.CORRER
var sprite: FolhaSprite
var _timer: float = 0.0
var _proximo_salto: float = 0.0
var _destino: Vector2 = Vector2.ZERO


func _ready() -> void:
	super()
	_proximo_salto = randf_range(1.0, intervalo_salto)
	sprite = FolhaSprite.new()
	sprite.name = "Sprite"
	add_child(sprite)
	sprite.registrar(&"correr", FolhaSprite.carregar(PASTA_SPRITES + "chacal_correr.png"), 6, 14.0)
	sprite.registrar(&"aviso", FolhaSprite.carregar(PASTA_SPRITES + "chacal_aviso.png"), 2)
	sprite.registrar(&"salto", FolhaSprite.carregar(PASTA_SPRITES + "chacal_salto.png"), 2)
	sprite.registrar(&"recuo", FolhaSprite.carregar(PASTA_SPRITES + "chacal_recuo.png"), 1)
	sprite.tocar(&"correr")


func _ao_reiniciar() -> void:
	estado = Estado.CORRER
	_proximo_salto = randf_range(1.0, intervalo_salto)


func esta_anunciando() -> bool:
	return estado == Estado.AVISO and not esta_atordoado()


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.AVISO:
		estado = Estado.CORRER
		_proximo_salto = intervalo_salto


func _perseguir(alvo: Node2D, delta: float) -> void:
	_proximo_salto -= delta
	match estado:
		Estado.CORRER:
			if alvo == null:
				velocity.x = move_toward(velocity.x, 0.0, Unidades.px(30.0) * delta)
				return
			var dx: float = alvo.global_position.x - global_position.x
			if absf(dx) > 2.0:
				olhando = 1 if dx > 0.0 else -1
			velocity.x = olhando * Unidades.px(velocidade)
			if is_on_floor() and is_on_wall():
				velocity.y = -sqrt(2.0 * _gravidade() * Unidades.px(1.75))
			if _proximo_salto <= 0.0 and is_on_floor() and absf(dx) <= Unidades.px(alcance_salto_tiles):
				estado = Estado.AVISO
				_timer = tempo_aviso
				_destino = alvo.global_position
		Estado.AVISO:
			velocity.x = 0.0
			_timer -= delta
			if alvo != null:
				_destino = alvo.global_position
			if _timer <= DURACAO_AVISO_FINAL and _timer + delta > DURACAO_AVISO_FINAL:
				aviso_final.emit(self)
			if _timer <= 0.0:
				_saltar()
		Estado.SALTO:
			if is_on_floor() and velocity.y >= 0.0:
				estado = Estado.CORRER
				_proximo_salto = intervalo_salto


## Arco balístico até o destino em `duracao_salto` segundos.
func _saltar() -> void:
	estado = Estado.SALTO
	var d: Vector2 = _destino - global_position
	d.x = clampf(d.x, -Unidades.px(alcance_salto_tiles), Unidades.px(alcance_salto_tiles))
	var t: float = duracao_salto
	velocity = Vector2(d.x / t, d.y / t - 0.5 * _gravidade() * t)
	olhando = 1 if d.x >= 0.0 else -1


func _physics_process(delta: float) -> void:
	super(delta)
	if sprite == null:
		return
	sprite.flip_h = olhando < 0
	sprite.modulate = Color(1.8, 1.8, 1.8) if _timer_flash > 0.0 else Color.WHITE
	if esta_recuando():
		sprite.tocar(&"recuo")
	elif estado == Estado.AVISO:
		sprite.tocar(&"aviso")
		sprite.definir_quadro(1 if _timer <= DURACAO_AVISO_FINAL else 0)
	elif estado == Estado.SALTO:
		sprite.tocar(&"salto")
		sprite.definir_quadro(1 if velocity.y > 0.0 else 0)
	else:
		sprite.tocar(&"correr")


func _criar_efeito_morte() -> void:
	var folha: Texture2D = FolhaSprite.carregar(PASTA_SPRITES + "chacal_morte.png")
	if folha != null and get_parent() != null:
		EfeitoFolha.new().iniciar(get_parent(), global_position, folha, 4, 12.0, olhando < 0)
