class_name JogadorArena
extends Node2D
## O Ryker na arena (GD-09 §4): anda em 8 direções, tem dash e carrega até 6 armas que
## atiram sozinhas. Visual (ART-02 §1): os sprites de lado de sempre (pernas + tronco, dash),
## virando com flip_h, com sombra no chão. A posição do nó é a dos pés.

signal vida_mudou(vida: int, vida_max: int)
signal morreu

const PASTA: String = "res://assets/sprites/personagens/ryker/"
const QPS_CORRER: float = 12.0
## Quanto o tronco desce em cada quadro da corrida (LEIAME do Ryker).
const DESCIDA_TRONCO: Array[int] = [3, 1, 1, 2, 3, 1, 1, 2]
const COR_SOMBRA: Color = Color(0.086, 0.067, 0.11, 0.45)

var vida_max: int
var vida: int
var velocidade: float
var raio: float
var ima: float
var invencivel_duracao: float
var dash_distancia: float
var dash_duracao: float
var dash_recarga: float
## Retângulo onde o Ryker pode andar (a arena define).
var limites: Rect2 = Rect2(0, 0, 640, 384)
## Destroços sólidos (a arena define; null = sem obstáculos).
var obstaculos: ObstaculosArena
var inventario: InventarioArmas
## Os testes desligam a entrada do teclado.
var ler_entrada: bool = true
## Direção pedida neste frame (a entrada ou os testes escrevem aqui).
var direcao: Vector2 = Vector2.ZERO
var morto: bool = false

var _invencivel: float = 0.0
var _dash_tempo: float = 0.0
var _dash_espera: float = 0.0
var _dash_direcao: Vector2 = Vector2.RIGHT
var _armas: Node2D
var _pernas: Sprite2D
var _tronco: Sprite2D
var _corpo_dash: Sprite2D
var _anim: float = 0.0


func _ready() -> void:
	var r: Dictionary = ConfigArena.secao("ryker")
	vida_max = int(r["vida_max"])
	vida = vida_max
	velocidade = float(r["velocidade"])
	raio = float(r["raio"])
	ima = float(r["ima"])
	invencivel_duracao = float(r["invencivel"])
	dash_distancia = float(r["dash_distancia"])
	dash_duracao = float(r["dash_duracao"])
	dash_recarga = float(r["dash_recarga"])
	inventario = InventarioArmas.new(int(r["slots"]))
	_pernas = _folha("ryker_pernas_correr.png", 8, Vector2(0, -16))
	_tronco = _folha("ryker_tronco_frente.png", 4, Vector2(0, -24))
	_corpo_dash = _folha("ryker_dash.png", 4, Vector2(0, -24))
	_corpo_dash.visible = false
	_armas = Node2D.new()
	_armas.name = "Armas"
	add_child(_armas)
	adicionar_arma(String(r["arma_inicial"]), 1)


func _physics_process(delta: float) -> void:
	if morto:
		return
	_invencivel = maxf(_invencivel - delta, 0.0)
	_dash_espera = maxf(_dash_espera - delta, 0.0)
	if ler_entrada:
		direcao = Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
		if Input.is_action_just_pressed("dash"):
			dar_dash()
	if direcao != Vector2.ZERO:
		_dash_direcao = direcao.normalized()
	var passo: Vector2 = direcao.limit_length(1.0) * velocidade * delta
	if _dash_tempo > 0.0:
		_dash_tempo -= delta
		passo = _dash_direcao * (dash_distancia / dash_duracao) * delta
	position = (position + passo).clamp(limites.position, limites.end)
	if obstaculos != null:
		position = obstaculos.resolver(position, raio)
	_animar(delta)


func _folha(arquivo: String, quadros: int, deslocamento: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(PASTA + arquivo)
	s.hframes = quadros
	s.offset = deslocamento
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)
	return s


func _animar(delta: float) -> void:
	var andando: bool = direcao.length() > 0.1
	_anim = _anim + delta if andando else 0.0
	if absf(direcao.x) > 0.1:
		for s in [_pernas, _tronco, _corpo_dash]:
			(s as Sprite2D).flip_h = direcao.x < 0.0
	var dash: bool = esta_em_dash()
	_corpo_dash.visible = dash
	_pernas.visible = not dash
	_tronco.visible = not dash
	if dash:
		_corpo_dash.frame = mini(int((dash_duracao - _dash_tempo) / dash_duracao * 4.0), 3)
	var q: int = int(_anim * QPS_CORRER) % 8 if andando else 0
	_pernas.frame = q
	_tronco.offset.y = -24.0 + (DESCIDA_TRONCO[q] if andando else 0)
	# Pisca durante a invencibilidade.
	modulate.a = 0.35 if _invencivel > 0.0 and int(_invencivel * 20.0) % 2 == 0 else 1.0


func dar_dash() -> bool:
	if _dash_espera > 0.0 or morto:
		return false
	_dash_tempo = dash_duracao
	_dash_espera = dash_recarga
	return true


func esta_em_dash() -> bool:
	return _dash_tempo > 0.0


func levar_dano(dano: int) -> bool:
	if morto or _invencivel > 0.0 or esta_em_dash():
		return false
	vida = maxi(vida - dano, 0)
	_invencivel = invencivel_duracao
	NumerosDano.mostrar(self, dano, NumerosDano.Tipo.JOGADOR)
	vida_mudou.emit(vida, vida_max)
	if vida == 0:
		morto = true
		morreu.emit()
	return true


## Põe uma arma no inventário (ou funde) e refaz os nós das armas.
func adicionar_arma(id: String, nivel: int) -> bool:
	if not inventario.adicionar(id, nivel):
		return false
	_refazer_armas()
	return true


func armas() -> Array[ArmaArena]:
	var lista: Array[ArmaArena] = []
	for a in _armas.get_children():
		lista.append(a as ArmaArena)
	return lista


func _refazer_armas() -> void:
	for a in _armas.get_children():
		_armas.remove_child(a)
		a.queue_free()
	var n: int = inventario.armas.size()
	for i in n:
		var item: Dictionary = inventario.armas[i]
		var arma := ArmaArena.new()
		arma.configurar(String(item["id"]), int(item["nivel"]))
		# Pontos de saída em volta do Ryker, espaçados por igual (GD-09 §5.1).
		arma.position = Vector2.RIGHT.rotated(TAU * i / n) * 14.0 + Vector2(0, -14)  # altura do peito
		_armas.add_child(arma)


## Sombra no chão, nos pés (ART-02 §1).
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 8.0, COR_SOMBRA)
