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
## Cor do sprite (variantes provisórias: Soldado, Elite).
@export var tinta: Color = Color.WHITE

const PASTA_SPRITES: String = "res://assets/sprites/inimigos/kharn/guerreiro_cla/"

var estado: Estado = Estado.AVANCAR
var sprite: FolhaSprite

var _timer_estado: float = 0.0
var _tiros_restantes: int = 0
var _direcao_tiro: Vector2 = Vector2.LEFT
var _alvo: Node2D
var _aviso_final_emitido: bool = false


func _ready() -> void:
	super()
	_criar_sprite()


func _comportamento(delta: float) -> void:
	_timer_estado -= delta
	_alvo = escolher_alvo(Vector2(Unidades.px(alcance_ataque.x), Unidades.px(alcance_ataque.y)))
	match estado:
		Estado.AVANCAR:
			_avancar()
			if _alvo != null and Combate.pedir_ficha(self):
				estado = Estado.AVISO
				_timer_estado = tempo_aviso
				_aviso_final_emitido = false
				olhar_para(_alvo)
		Estado.AVISO:
			velocity.x = 0.0
			if _alvo != null:
				olhar_para(_alvo)
			if _timer_estado <= DURACAO_AVISO_FINAL and not _aviso_final_emitido:
				_aviso_final_emitido = true
				aviso_final.emit(self)
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


# --- Visual (folhas da ART: assets/sprites/inimigos/kharn/guerreiro_cla/) ---

func _criar_sprite() -> void:
	sprite = FolhaSprite.new()
	sprite.name = "Sprite"
	add_child(sprite)
	for sufixo: String in ["", "_sem_armadura"]:
		sprite.registrar(StringName("andar" + sufixo), FolhaSprite.carregar(PASTA_SPRITES + "guerreiro_andar%s.png" % sufixo), 6, 8.0)
		sprite.registrar(StringName("aviso" + sufixo), FolhaSprite.carregar(PASTA_SPRITES + "guerreiro_aviso%s.png" % sufixo), 2)
		sprite.registrar(StringName("tiro" + sufixo), FolhaSprite.carregar(PASTA_SPRITES + "guerreiro_tiro%s.png" % sufixo), 2)


func _atualizar_sprite() -> void:
	if sprite == null:
		return
	var sufixo: String = "" if armadura_frontal else "_sem_armadura"
	sprite.flip_h = olhando < 0
	sprite.modulate = Color(1.8, 1.8, 1.8) if _timer_flash > 0.0 else tinta
	match estado:
		Estado.AVISO:
			# D-043: brasa durante o aviso (quadro 0) e flash AVISO só nos últimos 0,2 s (quadro 1).
			sprite.tocar(StringName("aviso" + sufixo))
			sprite.definir_quadro(1 if _timer_estado <= DURACAO_AVISO_FINAL else 0)
		Estado.RAJADA:
			sprite.tocar(StringName("tiro" + sufixo))
			sprite.definir_quadro(0 if _timer_estado > intervalo_rajada - 0.05 else 1)
		Estado.AVANCAR:
			sprite.tocar(StringName("andar" + sufixo))
			if absf(velocity.x) < 1.0 or esta_atordoado():
				sprite.definir_quadro(0)
		_:
			sprite.tocar(StringName("andar" + sufixo))
			sprite.definir_quadro(0)


func arrancar_protecao() -> bool:
	if not super():
		return false
	var placa: Texture2D = FolhaSprite.carregar(PASTA_SPRITES + "guerreiro_placa_caida.png")
	if placa != null and get_parent() != null:
		var e := EfeitoFolha.new()
		e.iniciar(get_parent(), centro(), placa, 1, 0.0, olhando < 0, true)
		e.soltar_no_chao(Camadas.MUNDO | Camadas.PLATAFORMAS)
	return true


func _criar_efeito_morte() -> void:
	var sufixo: String = "" if armadura_frontal else "_sem_armadura"
	var folha: Texture2D = FolhaSprite.carregar(PASTA_SPRITES + "guerreiro_morte%s.png" % sufixo)
	if folha != null and get_parent() != null:
		EfeitoFolha.new().iniciar(get_parent(), global_position, folha, 6, 10.0, olhando < 0)


func _draw() -> void:
	_atualizar_sprite()
	_desenhar_status()
