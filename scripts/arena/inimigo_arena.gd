class_name InimigoArena
extends Node2D
## Inimigo da arena visto de cima (GD-09 §9). Persegue o Ryker e fere por contato.
## O Zangão anda em zigue-zague. Protótipo: círculo colorido até a arte do ART-9.

signal morreu(inimigo: InimigoArena)

const GRUPO: StringName = &"inimigos_arena"
const CORES: Dictionary = {"roedor": Color("8a5a44"), "zangao": Color("8fdc5a")}

var tipo: String
var vida: int
var velocidade: float
var dano: int
var sucata: int
var raio: float
var alvo: Node2D
var limites: Rect2 = Rect2(0, 0, 640, 384)

var _zigue_amplitude: float = 0.0
var _zigue_frequencia: float = 0.0
var _tempo: float = 0.0


## onda = número da onda na run (a força sobe com ela).
func configurar(tipo_: String, onda: int) -> void:
	tipo = tipo_
	var d: Dictionary = ConfigArena.inimigo(tipo)
	var forca: Dictionary = ConfigArena.forca(onda)
	vida = maxi(roundi(float(d["vida"]) * float(forca["vida"])), 1)
	dano = maxi(roundi(float(d["dano"]) * float(forca["dano"])), 1)
	velocidade = float(d["velocidade"])
	sucata = int(d["sucata"])
	raio = float(d["raio"])
	_zigue_amplitude = float(d.get("zigue_amplitude", 0.0))
	_zigue_frequencia = float(d.get("zigue_frequencia", 0.0))
	_tempo = randf() * 10.0


func _ready() -> void:
	add_to_group(GRUPO)


func _physics_process(delta: float) -> void:
	if alvo == null or not is_instance_valid(alvo):
		return
	_tempo += delta
	var para_alvo: Vector2 = alvo.position - position
	var dir: Vector2 = para_alvo.normalized()
	if _zigue_amplitude > 0.0:
		# Zigue-zague: soma um balanço de lado que some perto do alvo.
		var lado: Vector2 = dir.orthogonal() * sin(_tempo * TAU * _zigue_frequencia)
		dir = (dir + lado * clampf(para_alvo.length() / _zigue_amplitude, 0.0, 1.0)).normalized()
	position = (position + dir * velocidade * delta).clamp(limites.position, limites.end)
	if alvo is JogadorArena:
		var j: JogadorArena = alvo
		if position.distance_to(j.position) <= raio + j.raio:
			j.levar_dano(dano)


## Devolve true se o golpe matou.
func levar_dano(valor: int) -> bool:
	if vida <= 0:
		return false
	vida -= valor
	NumerosDano.mostrar(self, valor, NumerosDano.tipo_do_acerto(valor, 1.0))
	if vida <= 0:
		remove_from_group(GRUPO)
		morreu.emit(self)
		queue_free()
		return true
	return false


func _draw() -> void:
	draw_circle(Vector2.ZERO, raio, CORES.get(tipo, Color.WHITE))
