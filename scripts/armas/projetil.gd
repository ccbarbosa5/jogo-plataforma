class_name Projetil
extends Area2D
## Projétil genérico: anda em linha reta e entrega um InfoDano a quem tiver receber_ataque().
## Quem atira define camada, máscara e o InfoDano. Tiros do jogador também acertam pontos fracos.
## Tiros da arma do jogador avisam a ControleArma antes e depois de cada acerto (Marca, crítico,
## empurrão...). Ricochete e curva (Rebite Guiado) vêm das Gambiarras e da árvore (GD-07).

@export var cor: Color = Color.WHITE
@export var tamanho: Vector2 = Vector2(6, 2)

var velocidade: Vector2 = Vector2.ZERO
var info: InfoDano = InfoDano.new()
var tempo_restante: float = 1.0
## Facção de quem atirou: o tiro atravessa aliados da mesma facção.
var faccao_autor: StringName = &""
## Sprite (apontando para a direita). Vazio = retângulo.
var textura: Texture2D
## Quantos inimigos ainda pode atravessar.
var perfuracoes: int = 0
## Atravessa todo inimigo leve e para no primeiro médio ou pesado.
var perfura_leves: bool = false
## Quantas vezes ainda quica em parede ou chão (Ricochete, Balins Quicantes).
var ricochetes: int = 0
## Rebite Guiado: quanto ainda pode curvar (graus), a que velocidade e até que distância busca.
var guiado_graus: float = 0.0
var guiado_graus_por_s: float = 120.0
var guiado_alcance_px: float = 160.0
## Queda de dano por distância percorrida (0 = sem queda).
var queda_dano_px: float = 0.0
var mult_queda_dano: float = 1.0
## Explode ao acertar (raio em px; 0 = não explode).
var raio_explosao: float = 0.0
var dano_explosao: int = 0
## Quem trata os acertos (ControleArma). Pode ser null.
var controle: Object
## Disparo ao qual este projétil pertence (Empurrão: um empurrão por alvo por disparo).
var disparo: Disparo
## &"" normal, &"arena" (Grande Arena), &"prego" (Prego do Rato), &"carregado" (Artilharia)
## ou &"central" (Bala Central).
var especial: StringName = &""
## Fragmento do Ferrão Partido (não se divide de novo).
var fragmento: bool = false
## Abalo da explosão (Munição de Clã).
var abalo_explosao: float = 0.0
var origem: Vector2 = Vector2.ZERO
var _ativo: bool = true
var _ja_acertados: Array[Node] = []


func configurar(posicao: Vector2, direcao: Vector2, velocidade_px: float, info_dano: InfoDano,
		duracao: float, camada: int, mascara: int) -> void:
	global_position = posicao
	origem = posicao
	velocidade = direcao.normalized() * velocidade_px
	rotation = velocidade.angle()
	info = info_dano
	info.direcao = velocidade.normalized()
	tempo_restante = duracao
	collision_layer = camada
	collision_mask = mascara


func _ready() -> void:
	body_entered.connect(_ao_tocar_corpo)
	area_entered.connect(_ao_tocar_area)


func _physics_process(delta: float) -> void:
	if guiado_graus > 0.0:
		_curvar(delta)
	position += velocidade * delta
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		queue_free()


## Rebite Guiado: vira aos poucos para o inimigo vivo mais próximo à frente.
func _curvar(delta: float) -> void:
	var melhor: Inimigo = null
	var menor: float = guiado_alcance_px
	for no in get_tree().get_nodes_in_group("inimigos"):
		var inimigo := no as Inimigo
		if inimigo == null or not inimigo.esta_vivo() or inimigo in _ja_acertados:
			continue
		var para: Vector2 = inimigo.centro() - global_position
		if para.length() < menor and velocidade.dot(para) > 0.0:
			menor = para.length()
			melhor = inimigo
	if melhor == null:
		return
	var diferenca: float = velocidade.angle_to(melhor.centro() - global_position)
	var giro: float = clampf(diferenca, -deg_to_rad(guiado_graus_por_s) * delta, deg_to_rad(guiado_graus_por_s) * delta)
	giro = clampf(giro, -deg_to_rad(guiado_graus), deg_to_rad(guiado_graus))
	velocidade = velocidade.rotated(giro)
	rotation = velocidade.angle()
	guiado_graus = maxf(guiado_graus - rad_to_deg(absf(giro)), 0.0)


## Não acerta este inimigo (fragmentos nascem dentro do alvo que dividiu o tiro).
func ignorar(inimigo: Node) -> void:
	_ja_acertados.append(inimigo)


func distancia_percorrida() -> float:
	return global_position.distance_to(origem)


func _ao_tocar_area(area: Area2D) -> void:
	if _ativo and area is PontoFraco:
		_acertar(area)


func _ao_tocar_corpo(corpo: Node2D) -> void:
	if not _ativo:
		return
	if faccao_autor != &"" and corpo.get("faccao") == faccao_autor:
		return  # aliado
	# Se no mesmo instante também tocou o ponto fraco desse corpo, ele tem prioridade.
	for area in get_overlapping_areas():
		if area is PontoFraco and (area as PontoFraco).dono() == corpo:
			_acertar(area)
			return
	_acertar(corpo)


func _acertar(alvo: Node) -> void:
	var inimigo: Inimigo = (alvo as PontoFraco).dono() if alvo is PontoFraco else alvo as Inimigo
	if inimigo != null and inimigo in _ja_acertados:
		return
	if not alvo.has_method("receber_ataque"):
		if ricochetes > 0 and _quicar():
			return
		_explodir()
		_destruir()
		return
	var golpe: InfoDano = info.copiar()
	if queda_dano_px > 0.0 and distancia_percorrida() >= queda_dano_px:
		golpe.multiplicador *= mult_queda_dano
	if controle != null and inimigo != null:
		controle.antes_do_acerto(self, inimigo, golpe)
	# Alvo invulnerável (ex.: durante o dash) deixa o tiro passar.
	if not alvo.receber_ataque(golpe):
		return
	if inimigo != null:
		_ja_acertados.append(inimigo)
		if controle != null:
			controle.depois_do_acerto(self, inimigo, golpe, not inimigo.esta_vivo())
	_explodir()
	if inimigo != null and perfura_leves and inimigo.peso == Inimigo.Peso.LEVE:
		return
	if inimigo != null and perfuracoes > 0:
		perfuracoes -= 1
		return
	_destruir()


## Ricochete: reflete na superfície (normal achada com um raio curto para trás e para a frente).
func _quicar() -> bool:
	var dir: Vector2 = velocidade.normalized()
	var consulta := PhysicsRayQueryParameters2D.create(global_position - dir * 10.0, global_position + dir * 6.0, Camadas.MUNDO)
	var resultado: Dictionary = get_world_2d().direct_space_state.intersect_ray(consulta)
	if resultado.is_empty():
		return false
	var normal: Vector2 = resultado["normal"]
	ricochetes -= 1
	velocidade = velocidade.bounce(normal)
	rotation = velocidade.angle()
	global_position = (resultado["position"] as Vector2) + normal * 2.0
	return true


## Explosão no impacto (Artilharia): dano em área, sem armadura frontal.
func _explodir() -> void:
	if raio_explosao <= 0.0:
		return
	var raio: float = raio_explosao
	raio_explosao = 0.0
	for no in get_tree().get_nodes_in_group("inimigos"):
		var inimigo := no as Inimigo
		if inimigo == null or not inimigo.esta_vivo():
			continue
		if inimigo.centro().distance_to(global_position) <= raio + inimigo.tamanho.x * 0.5:
			var golpe := InfoDano.criar(dano_explosao, info.autor, inimigo.centro() - global_position)
			golpe.explosao = true
			golpe.abalo = abalo_explosao
			if inimigo.receber_ataque(golpe) and controle != null:
				controle.depois_do_acerto(self, inimigo, golpe, not inimigo.esta_vivo())


func _destruir() -> void:
	_ativo = false
	set_deferred("monitoring", false)
	queue_free()


func _draw() -> void:
	if textura != null:
		draw_texture(textura, -textura.get_size() * 0.5)
	else:
		draw_rect(Rect2(-tamanho * 0.5, tamanho), cor)
