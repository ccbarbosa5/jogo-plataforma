class_name ArtilheiroKharn
extends Inimigo
## Artilheiro Kharn (GD-02 §4.1): 32×56, 80 de vida, peso Médio sem proteção.
## Fica no fundo da sala e mantém distância. Ataque: morteiro em arco [PESADO] que cai num
## alvo marcado no chão; o aviso é a própria marca, 1,0 s antes do impacto.

enum Estado { POSICIONAR, AVISO, DESCANSO }

## tiles/s
@export var velocidade: float = 1.0
## Recua se o alvo chegar mais perto que isto (tiles).
@export var distancia_minima: float = 8.0
## Alcance para atirar (tiles).
@export var alcance: Vector2 = Vector2(24.0, 12.0)
## Tempo do aviso = voo do morteiro até o alvo marcado.
@export var tempo_aviso: float = 1.0
@export var raio_explosao: float = 24.0
## [PESADO]: 2 blocos.
@export var dano_morteiro: int = 2
@export var descanso: float = 2.0

var estado: Estado = Estado.POSICIONAR
var morteiro: ProjetilArco
var _timer: float = 0.0
var _alvo: Node2D


func _comportamento(delta: float) -> void:
	_timer -= delta
	_alvo = escolher_alvo(Vector2(Unidades.px(alcance.x), Unidades.px(alcance.y)))
	match estado:
		Estado.POSICIONAR:
			_posicionar()
			if _alvo != null and is_on_floor() and Combate.pedir_ficha(self):
				_disparar()
		Estado.AVISO:
			velocity.x = 0.0
			if _timer <= 0.0:
				Combate.devolver_ficha(self)
				estado = Estado.DESCANSO
				_timer = descanso
		Estado.DESCANSO:
			_posicionar()
			if _timer <= 0.0:
				estado = Estado.POSICIONAR


## O morteiro sai na hora e cai no alvo marcado depois de `tempo_aviso` (a marca é o aviso).
func _disparar() -> void:
	olhar_para(_alvo)
	var destino: Vector2 = _alvo.global_position
	var pai: Node = container_projeteis if container_projeteis != null else get_parent()
	morteiro = ProjetilArco.lancar(pai, ProjetilArco.Tipo.MORTEIRO, self, global_position + Vector2(olhando * 8.0, -tamanho.y),
			destino, tempo_aviso, 72.0)
	morteiro.raio = raio_explosao
	morteiro.dano = dano_morteiro
	estado = Estado.AVISO
	_timer = tempo_aviso
	aviso_final.emit.call_deferred(self)


func esta_anunciando() -> bool:
	return estado == Estado.AVISO and not esta_atordoado()


func _cancelar_ataque() -> void:
	super()
	if estado == Estado.AVISO:
		estado = Estado.DESCANSO
		_timer = descanso


## Fica longe: recua quando o alvo se aproxima, sem cair das plataformas.
func _posicionar() -> void:
	var alvo: Node2D = escolher_alvo(Vector2(Unidades.px(30.0), Unidades.px(17.0)))
	velocity.x = 0.0
	if alvo == null:
		return
	olhar_para(alvo)
	var d: float = alvo.global_position.x - global_position.x
	if absf(d) < Unidades.px(distancia_minima) and is_on_floor():
		var fuga: float = -signf(d) if d != 0.0 else -float(olhando)
		var antes: int = olhando
		olhando = int(fuga)
		if ha_chao_a_frente() and not is_on_wall():
			velocity.x = fuga * Unidades.px(velocidade)
		olhando = antes


func _draw() -> void:
	# Corpo Kharn magro, com o tubo do morteiro nas costas.
	var w: float = tamanho.x
	var h: float = tamanho.y
	var cor_tubo: Color = Inimigo.cor_do_aviso(_timer) if estado == Estado.AVISO else Color("4b4753")
	draw_rect(Rect2(-w * 0.5 + 4, -h, w - 8, h - 14), Color("56604a"))
	draw_rect(Rect2(-w * 0.5 + 6, -14, 8, 14), Color("363d30"))
	draw_rect(Rect2(w * 0.5 - 14, -14, 8, 14), Color("363d30"))
	draw_rect(Rect2(-6 + olhando * 4, -h - 6, 12, 10), Color("7c8a6c"))
	draw_rect(Rect2(-olhando * 10 - 4, -h - 10, 8, 26), cor_tubo)
	draw_rect(Rect2(-w * 0.5 + 4, -h + 18, w - 8, 4), Color("dccfae"))
	if _timer_flash > 0.0:
		draw_rect(Rect2(-w * 0.5, -h, w, h), Color(1, 1, 1, 0.5))
	_desenhar_status()
