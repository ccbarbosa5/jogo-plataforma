class_name JogadorArena
extends Node2D
## O Ryker na arena (GD-09 §4): anda em 8 direções, tem dash e carrega até 6 armas que
## atiram sozinhas. Visual (ART-02 §1): os sprites de lado de sempre (pernas + tronco, dash),
## virando com flip_h, com sombra no chão. A posição do nó é a dos pés.

signal vida_mudou(vida: int, vida_max: int)
signal morreu
signal subiu_de_nivel(nivel: int)

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
## Atributos da run (níveis + itens, GD-09 §6.3).
var atributos := AtributosArena.new()
## Nível da run e experiência dentro do nível (a Sucata pega vira XP, GD-09 §6.2).
var nivel: int = 1
var xp: int = 0
## Níveis ganhos que ainda esperam a escolha de atributo (no fim da onda).
var niveis_pendentes: int = 0
var rng := RandomNumberGenerator.new()
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
var _regenerar: float = 0.0


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
	_passo_regeneracao(delta)
	if ler_entrada:
		direcao = Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
		if Input.is_action_just_pressed("dash"):
			dar_dash()
	if direcao != Vector2.ZERO:
		_dash_direcao = direcao.normalized()
	var passo: Vector2 = direcao.limit_length(1.0) * velocidade_atual() * delta
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
	_invencivel = invencivel_duracao
	if rng.randf() * 100.0 < atributos.chance_esquiva():
		return false  # esquivou: só a invencibilidade curta
	dano = maxi(roundi(dano * atributos.fator_armadura()), 1)
	vida = maxi(vida - dano, 0)
	NumerosDano.mostrar(self, dano, NumerosDano.Tipo.JOGADOR)
	vida_mudou.emit(vida, vida_max)
	if vida == 0:
		morto = true
		morreu.emit()
	return true


func velocidade_atual() -> float:
	return velocidade * maxf(1.0 + atributos.valor("velocidade_pct") / 100.0, 0.3)


func raio_ima() -> float:
	return ima + atributos.valor("coleta")


## Cada acerto das armas: chance de Roubo de vida (cura 1).
func ao_acertar() -> void:
	if rng.randf() * 100.0 < atributos.valor("roubo_vida"):
		curar(1)


func curar(quanto: int) -> void:
	if morto or vida >= vida_max:
		return
	vida = mini(vida + quanto, vida_max)
	vida_mudou.emit(vida, vida_max)


## Experiência para passar do nível atual ao próximo: (n + 3)².
func xp_para_proximo() -> int:
	return (nivel + 3) * (nivel + 3)


func ganhar_xp(quanto: int) -> void:
	xp += quanto
	while xp >= xp_para_proximo():
		xp -= xp_para_proximo()
		nivel += 1
		niveis_pendentes += 1
		var extra: int = int(ConfigArena.secao("nivel")["vida_por_nivel"])
		vida_max += extra
		curar(extra)
		subiu_de_nivel.emit(nivel)


## Soma um atributo (carta de nível ou item). Vida máx. também cura o que ganhou.
func aplicar_efeitos(efeitos: Dictionary) -> void:
	atributos.somar_efeitos(efeitos)
	var vida_extra: int = int(efeitos.get("vida_max", 0))
	if vida_extra != 0:
		vida_max = maxi(vida_max + vida_extra, 1)
		vida = clampi(vida + maxi(vida_extra, 0), 1, vida_max)
		vida_mudou.emit(vida, vida_max)


func _passo_regeneracao(delta: float) -> void:
	var intervalo: float = atributos.intervalo_regeneracao()
	if intervalo <= 0.0:
		return
	_regenerar += delta
	if _regenerar >= intervalo:
		_regenerar -= intervalo
		curar(1)


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


## Bônus de família (GD-09 §5.3): recalcula pelas armas atuais; a vida máx. entra pela diferença.
func _atualizar_familias() -> void:
	var ids: Array = inventario.armas.map(func(item: Dictionary) -> String: return String(item["id"]))
	var vida_antes: int = int(atributos.bonus.get("vida_max", 0.0))
	atributos.bonus = AtributosArena.bonus_de_familias(ids)
	var diferenca: int = int(atributos.bonus.get("vida_max", 0.0)) - vida_antes
	if diferenca != 0:
		vida_max = maxi(vida_max + diferenca, 1)
		vida = clampi(vida + maxi(diferenca, 0), 1, vida_max)
		vida_mudou.emit(vida, vida_max)


func _refazer_armas() -> void:
	_atualizar_familias()
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
