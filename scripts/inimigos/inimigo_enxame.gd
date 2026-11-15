class_name InimigoEnxame
extends Inimigo
## Base dos inimigos de enxame (GD-08 §2): pequenos, vêm em bando, morrem com 1 ou 2 tiros e
## machucam só por contato. Não usam fichas de ataque nem disparam projéteis. Sempre Leves para
## o Grilhão. IA barata: anda ou voa em direção ao jogador.
## - Depois de tocar o jogador, recua 1 tile e fica parado 0,5 s (sem dano em sequência).
## - Fuga (fim da sala, GD-08 §3.2): corre para a direita e some sem dar XP nem Créditos.
## - Pool (D-062): quando morre ou foge, volta para o PoolEnxame em vez de ser apagado.

## Velocidade em tiles/s.
@export var velocidade: float = 4.5
## Recuo depois de tocar o jogador (tiles) e tempo parado (s).
@export var recuo_tiles: float = 1.0
@export var parado_depois_do_toque: float = 0.5

var fugindo: bool = false
## Quem guarda este inimigo quando ele sai de cena (null = apaga ao morrer).
var pool: PoolEnxame
var tipo: String = ""

## Some depois de fugir por este tempo (s), apagando aos poucos.
const TEMPO_FUGA: float = 2.0

## Abaixo disto (px) caiu num buraco: some sem dar XP.
const LIMITE_QUEDA_Y: float = 400.0

var _timer_recuo: float = 0.0
var _timer_fuga: float = 0.0
## Cada um mira um pouco ao lado do jogador, para o bando se espalhar em vez de virar um bolo.
var desvio_x: float = 0.0
var _alvo_recuo: float = 0.0


func _init() -> void:
	peso = Peso.LEVE
	sobe_plataformas = true
	creditos = Vector2i(1, 1)
	chance_creditos = 0.1  # GD-08 §4: 10% de chance de 1 Crédito


func _ready() -> void:
	super()
	_timer_entrada = 0.0  # vem de fora da tela: sem a pausa de entrada dos pesados
	desvio_x = randf_range(-14.0, 14.0)


func _physics_process(delta: float) -> void:
	super(delta)
	if global_position.y > LIMITE_QUEDA_Y and is_inside_tree():
		sumir()


## Volta ao estado de recém-criado (pool).
func reiniciar() -> void:
	vida.reiniciar()
	fugindo = false
	velocity = Vector2.ZERO
	abalo = 0.0
	acidos = 0
	_timer_atordoado = 0.0
	_timer_empurrao = 0.0
	_timer_flash = 0.0
	_timer_recuo = 0.0
	_timer_fuga = 0.0
	_timer_entrada = 0.0
	_timer_armadura_quebrada = 0.0
	_puxado_por = null
	ataca_faccao_rival = false
	modulate = Color.WHITE
	if has_meta("ultimo_golpe_de"):
		remove_meta("ultimo_golpe_de")
	_ao_reiniciar()


func esta_recuando() -> bool:
	return _timer_recuo > 0.0


## Começa a fugir pela direita (fim da sala).
func fugir() -> void:
	fugindo = true


func _comportamento(delta: float) -> void:
	if _timer_recuo > 0.0:
		_timer_recuo -= delta
		# Primeiro recua (1 tile), depois fica parado.
		var dx: float = _alvo_recuo - global_position.x
		velocity.x = signf(dx) * Unidades.px(velocidade) if absf(dx) > 2.0 else 0.0
		if voa:
			velocity.y = move_toward(velocity.y, 0.0, Unidades.px(20.0) * delta)
		return
	if fugindo:
		_fugir(delta)
		return
	var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(40.0), Unidades.px(20.0)))
	_perseguir(alvo, delta)


## IA de cada tipo (chamada fora do recuo e da fuga).
func _perseguir(_alvo: Node2D, _delta: float) -> void:
	pass


func _fugir(delta: float) -> void:
	olhando = 1
	velocity.x = Unidades.px(velocidade)
	if voa:
		velocity.y = -Unidades.px(velocidade) * 0.3
	_timer_fuga += delta
	modulate.a = clampf(1.0 - _timer_fuga / TEMPO_FUGA, 0.0, 1.0)
	if _timer_fuga >= TEMPO_FUGA:
		sumir()


func _ao_reiniciar() -> void:
	pass


func _causar_dano_contato() -> void:
	if dano_contato <= 0 or _contato == null or not _contato.monitoring or _timer_recuo > 0.0 or fugindo:
		return
	for corpo in _contato.get_overlapping_bodies():
		if not pode_ferir(corpo) or not corpo.has_method("receber_ataque"):
			continue
		var lado: float = signf(corpo.global_position.x - global_position.x)
		if lado == 0.0:
			lado = float(olhando)
		corpo.receber_ataque(InfoDano.criar(dano_contato, self, Vector2(lado, 0)))
		# GD-08 §2: recua 1 tile e espera 0,5 s, toque valendo ou não (invulnerável).
		_alvo_recuo = global_position.x - lado * Unidades.px(recuo_tiles)
		_timer_recuo = parado_depois_do_toque + recuo_tiles / velocidade
		break


func _ao_morrer() -> void:
	Combate.devolver_ficha(self)
	_criar_efeito_morte()
	morreu.emit(self)
	_sair()


## D-071: preso fora da tela (pulou e não saiu do lugar): some e volta ao pool; o diretor
## solta outro numa entrada válida.
func _ao_ficar_preso() -> void:
	if not esta_na_tela():
		sumir()


## Sai de cena sem morrer (fugiu da tela).
func sumir() -> void:
	_sair()


func _sair() -> void:
	if pool != null and is_instance_valid(pool):
		pool.devolver(self)
	else:
		queue_free()
