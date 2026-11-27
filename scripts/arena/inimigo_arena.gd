class_name InimigoArena
extends Node2D
## Inimigo da arena visto de cima (GD-09 §9). Persegue o Ryker e fere por contato.
## O Zangão anda em zigue-zague e voa (passa sobre os destroços). Visual (ART-02 §1): os sprites
## de lado de sempre, virando com flip_h, com sombra no chão. A posição do nó é a dos pés.

signal morreu(inimigo: InimigoArena)

const GRUPO: StringName = &"inimigos_arena"
## Folha de animação de cada tipo: [arquivo, quadros, qps, deslocamento do desenho, altura do voo].
const VISUAL: Dictionary = {
	"roedor": ["res://assets/sprites/inimigos/vesh/roedor/roedor_correr.png", 4, 12.0, Vector2(0, -6), 0.0],
	"zangao": ["res://assets/sprites/inimigos/vesh/zangao/zangao_voo.png", 4, 16.0, Vector2(0, -8), 8.0],
}
const COR_SOMBRA: Color = Color(0.086, 0.067, 0.11, 0.45)

var tipo: String
var vida: int
var velocidade: float
var dano: int
var sucata: int
var raio: float
var alvo: Node2D
var limites: Rect2 = Rect2(0, 0, 640, 384)
var obstaculos: ObstaculosArena
var voa: bool = false
var sprite: Sprite2D
## Ácido (Ferrão, GD-09 §5.2): acúmulos que ferem com o tempo.
var acido: int = 0
var _acido_tempo: float = 0.0
var _acido_tique: float = 0.0

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
	voa = bool(d.get("voa", false))
	_tempo = randf() * 10.0
	_montar_visual()


func _montar_visual() -> void:
	var v: Array = VISUAL.get(tipo, [])
	if v.is_empty():
		return
	sprite = Sprite2D.new()
	sprite.texture = load(String(v[0]))
	sprite.hframes = int(v[1])
	# Voadores ficam no alto; a sombra continua no chão.
	sprite.offset = (v[3] as Vector2) - Vector2(0, float(v[4]))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)


func _ready() -> void:
	add_to_group(GRUPO)


func _physics_process(delta: float) -> void:
	if alvo == null or not is_instance_valid(alvo):
		return
	_tempo += delta
	_passo_acido(delta)
	if vida <= 0:
		return
	var para_alvo: Vector2 = alvo.position - position
	var dir: Vector2 = para_alvo.normalized()
	if _zigue_amplitude > 0.0:
		# Zigue-zague: soma um balanço de lado que some perto do alvo.
		var lado: Vector2 = dir.orthogonal() * sin(_tempo * TAU * _zigue_frequencia)
		dir = (dir + lado * clampf(para_alvo.length() / _zigue_amplitude, 0.0, 1.0)).normalized()
	position = (position + dir * velocidade * delta).clamp(limites.position, limites.end)
	if obstaculos != null and not voa and obstaculos.bloqueia(position, raio):
		# Desliza pela borda do destroço em vez de parar nele.
		position = obstaculos.resolver(position + dir.orthogonal() * velocidade * delta * signf(dir.x + 0.01), raio)
	if sprite != null:
		var v: Array = VISUAL[tipo]
		sprite.frame = int(_tempo * float(v[2])) % int(v[1])
		if absf(dir.x) > 0.05:
			sprite.flip_h = dir.x < 0.0
	if alvo is JogadorArena:
		var j: JogadorArena = alvo
		if position.distance_to(j.position) <= raio + j.raio:
			j.levar_dano(dano)


## Põe 1 acúmulo de Ácido (até o máximo) e renova a duração.
func aplicar_acido(duracao_extra: float = 0.0) -> void:
	var a: Dictionary = ConfigArena.secao("acido")
	acido = mini(acido + 1, int(a["maximo"]))
	_acido_tempo = float(a["duracao"]) + duracao_extra
	modulate = Color(0.8, 1.15, 0.7)


func _passo_acido(delta: float) -> void:
	if acido <= 0:
		return
	var a: Dictionary = ConfigArena.secao("acido")
	_acido_tempo -= delta
	_acido_tique += delta
	var intervalo: float = float(a["intervalo"])
	if _acido_tique >= intervalo:
		_acido_tique -= intervalo
		var dano_acido: int = maxi(roundi(float(a["dano_por_acumulo_por_segundo"]) * intervalo * acido), 1)
		vida -= dano_acido
		NumerosDano.mostrar(self, dano_acido, NumerosDano.Tipo.EFEITO)
		if vida <= 0:
			_morrer()
			return
	if _acido_tempo <= 0.0:
		acido = 0
		modulate = Color.WHITE


func _morrer() -> void:
	remove_from_group(GRUPO)
	morreu.emit(self)
	queue_free()


## Devolve true se o golpe matou.
func levar_dano(valor: int) -> bool:
	if vida <= 0:
		return false
	vida -= valor
	NumerosDano.mostrar(self, valor, NumerosDano.tipo_do_acerto(valor, 1.0))
	if vida <= 0:
		_morrer()
		return true
	return false


## Sombra no chão, nos pés (ART-02 §1).
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, raio + 2.0, COR_SOMBRA)
