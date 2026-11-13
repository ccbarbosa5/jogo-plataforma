class_name GuerreiroCla
extends Inimigo
## Guerreiro de Clã (Kharn) — GD-02, seção 4.1.
## ~2× o Ryker, armadura frontal, peso Médio. Avança devagar e para para atirar.
## Ataque: rajada de 3 tiros lentos, anunciada 0,6 s antes (o canhão brilha).
## Só ataca se conseguir uma ficha de ataque (teto de 3 ataques anunciados).

enum Estado { AVANCAR, AVISO, RAJADA, DESCANSO }

## tiles/s
@export var velocidade_avanco: float = 1.25
## Para de avançar a esta distância do alvo (tiles).
@export var distancia_preferida: float = 7.0
## Alcance para começar o ataque (tiles: horizontal, vertical).
@export var alcance_ataque: Vector2 = Vector2(16.0, 8.0)
@export var tempo_aviso: float = 0.6
@export var tiros_por_rajada: int = 3
## Segundos entre os tiros da rajada.
@export var intervalo_rajada: float = 0.18
## tiles/s (180 px/s)
@export var velocidade_tiro: float = 11.25
## Blocos de vida por tiro.
@export var dano_tiro: int = 1
## Segundos de descanso depois da rajada.
@export var descanso: float = 1.6
@export var cena_projetil: PackedScene

var estado: Estado = Estado.AVANCAR

var _timer_estado: float = 0.0
var _tiros_restantes: int = 0
var _direcao_tiro: Vector2 = Vector2.LEFT
var _alvo: Node2D


func _comportamento(delta: float) -> void:
	_timer_estado -= delta
	_alvo = escolher_alvo(Vector2(Unidades.px(alcance_ataque.x), Unidades.px(alcance_ataque.y)))
	match estado:
		Estado.AVANCAR:
			_avancar()
			if _alvo != null and Combate.pedir_ficha(self):
				estado = Estado.AVISO
				_timer_estado = tempo_aviso
				olhar_para(_alvo)
		Estado.AVISO:
			velocity.x = 0.0
			if _alvo != null:
				olhar_para(_alvo)
			if _timer_estado <= 0.0:
				_direcao_tiro = _mirar()
				_tiros_restantes = tiros_por_rajada
				_timer_estado = 0.0
				estado = Estado.RAJADA
		Estado.RAJADA:
			velocity.x = 0.0
			if _timer_estado <= 0.0:
				_atirar()
				_tiros_restantes -= 1
				_timer_estado = intervalo_rajada
				if _tiros_restantes <= 0:
					Combate.devolver_ficha(self)
					estado = Estado.DESCANSO
					_timer_estado = descanso
		Estado.DESCANSO:
			velocity.x = 0.0
			if _alvo != null:
				olhar_para(_alvo)
			if _timer_estado <= 0.0:
				estado = Estado.AVANCAR


func esta_anunciando() -> bool:
	return estado == Estado.AVISO and not esta_atordoado() and not esta_sendo_puxado()


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.AVISO or estado == Estado.RAJADA:
		estado = Estado.DESCANSO
		_timer_estado = descanso


func _avancar() -> void:
	var alvo_qualquer: Node2D = escolher_alvo(Vector2(Unidades.px(30.0), Unidades.px(17.0)))
	if alvo_qualquer == null:
		velocity.x = 0.0
		return
	olhar_para(alvo_qualquer)
	var distancia: float = absf(alvo_qualquer.global_position.x - global_position.x)
	if distancia > Unidades.px(distancia_preferida) and is_on_floor() and ha_chao_a_frente():
		velocity.x = olhando * Unidades.px(velocidade_avanco)
	else:
		velocity.x = 0.0


func _ponto_canhao() -> Vector2:
	return global_position + Vector2(olhando * (tamanho.x * 0.5 + 4.0), -tamanho.y * 0.6)


## A direção fica travada no fim do aviso: dá para desviar andando.
func _mirar() -> Vector2:
	if _alvo == null:
		return Vector2(olhando, 0.0)
	var destino: Vector2 = MiraAutomatica.centro_de(_alvo)
	var direcao: Vector2 = (destino - _ponto_canhao()).normalized()
	if direcao.x * olhando <= 0.1:
		direcao = Vector2(olhando, direcao.y).normalized()
	return direcao


func _atirar() -> void:
	if cena_projetil == null:
		return
	var projetil: Projetil = cena_projetil.instantiate()
	var destino: Node = container_projeteis if container_projeteis != null else get_parent()
	destino.add_child(projetil)
	var info := InfoDano.criar(dano_tiro, self)
	var mascara: int = Camadas.MUNDO | Camadas.JOGADOR
	if ataca_faccao_rival:
		mascara |= Camadas.INIMIGOS
	projetil.faccao_autor = faccao
	projetil.configurar(_ponto_canhao(), _direcao_tiro, Unidades.px(velocidade_tiro), info, 4.0,
			Camadas.PROJETEIS_INIMIGO, mascara)


func _draw() -> void:
	var cor: Color = Color("8a4b3a")
	if _timer_flash > 0.0:
		cor = Color.WHITE
	var corpo := Rect2(Vector2(-tamanho.x * 0.5, -tamanho.y), tamanho)
	draw_rect(corpo, cor)
	draw_rect(Rect2(Vector2(olhando * 6.0 - 4.0, -tamanho.y + 6.0), Vector2(8, 5)), Color("ffd43b"))  # olhos
	if armadura_frontal:
		var x_placa: float = tamanho.x * 0.5 - 5.0 if olhando > 0 else -tamanho.x * 0.5
		draw_rect(Rect2(Vector2(x_placa, -tamanho.y + 14.0), Vector2(5.0, tamanho.y - 22.0)), Color("c0c5ce"))
	# Canhão no braço.
	var canhao: Vector2 = Vector2(olhando * (tamanho.x * 0.5), -tamanho.y * 0.6)
	var cor_canhao: Color = Color("3b4252")
	if estado == Estado.AVISO and int(_timer_estado * 16.0) % 2 == 0:
		cor_canhao = Color("ff3b3b")
		draw_rect(Rect2(Vector2(-2.0, -tamanho.y - 16.0), Vector2(4, 9)), Color("ff3b3b"))
		draw_rect(Rect2(Vector2(-2.0, -tamanho.y - 5.0), Vector2(4, 2)), Color("ff3b3b"))
	draw_rect(Rect2(canhao + Vector2(minf(olhando * 10.0, 0.0), -3.0), Vector2(10, 6)), cor_canhao)
	_desenhar_status()
