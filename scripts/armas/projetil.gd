class_name Projetil
extends Area2D
## Projétil genérico: anda em linha reta e entrega um InfoDano a quem tiver receber_ataque().
## Quem atira define camada, máscara e o InfoDano. Tiros do jogador também acertam pontos fracos.
## Tiros da arma do jogador avisam a ControleArma antes e depois de cada acerto (assinaturas e
## nós da árvore: Embalo, Coice, crítico, marca...).

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
## Atravessa todo inimigo leve e para no primeiro médio ou pesado (Bramido A2).
var perfura_leves: bool = false
## Queda de dano por distância percorrida (0 = sem queda).
var queda_dano_px: float = 0.0
var mult_queda_dano: float = 1.0
## Explode ao acertar (raio em px; 0 = não explode).
var raio_explosao: float = 0.0
var dano_explosao: int = 0
## Quem trata os acertos (ControleArma). Pode ser null.
var controle: Object
## Disparo ao qual este projétil pertence (Coice: um empurrão por alvo por disparo).
var disparo: Disparo
## Ordem do projétil na rajada (1, 2, 3) ou 0.
var ordem_rajada: int = 0
## &"" normal, &"campeao" (Golpe do Campeão) ou &"carregado" (Artilharia).
var especial: StringName = &""
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
	position += velocidade * delta
	tempo_restante -= delta
	if tempo_restante <= 0.0:
		queue_free()


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


## Explosão no impacto (Bramido A3): dano em área, sem armadura frontal.
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
