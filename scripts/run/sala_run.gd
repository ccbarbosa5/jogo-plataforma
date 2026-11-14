class_name SalaRun
extends Node2D
## Uma sala do Ato montada pelo MontadorSala (GD-03 §2.1):
## [ENTRADA] → [TRECHO] ×1–3 → [ARENA] → [SAÍDA com portas].
## - trechos: inimigos colocados à mão, sem travar a câmera;
## - arena: a câmera trava e as ondas do plano entram uma depois da outra
##   (a próxima entra com 25% ou menos do custo da atual vivo, ou depois de 20 s);
## - saída: as portas aparecem quando a última onda morre (ou logo, em loja e reparo).

signal arena_comecou
signal concluida
signal porta_escolhida(porta: PortaSaida)

const ATRASO_PROXIMA_ONDA: float = 20.0
const FRACAO_PROXIMA_ONDA: float = 0.25
## Distância da borda da arena em que ela começa (px).
const ENTRADA_ARENA: float = 40.0

var plano: Dictionary = {}
var largura_px: float = 480.0
var inicio: Vector2 = Vector2(48, 224)
var arena: Rect2 = Rect2()
var surgimentos: Dictionary = {}  # letra -> Array[Vector2]
var pontos_porta: Array[Vector2] = []
var inimigos_fixos: Array[Dictionary] = []
var estacoes_reparo: Array[Dictionary] = []
var falas: Array[Dictionary] = []
var dicas: Array[Vector2] = []

var jogador: Jogador
var camera: CameraJogo
var projeteis: Node
var banco_ondas: BancoOndas
var inimigos: Node2D

var arena_ativa: bool = false
var arena_concluida: bool = false
var portas: Array[PortaSaida] = []
var onda_atual: int = -1
var vivos_da_onda: Array[Inimigo] = []
var _custo_onda: int = 0
var _timer_onda: float = 0.0
var _paredes: Array[Bloco] = []
var _falas_tocadas: Array[int] = []
var _dica: Label


func limites() -> Rect2:
	return Rect2(0, 0, largura_px, BancoBlocos.ALTURA * MontadorSala.T)


func tem_arena() -> bool:
	return arena.size.x > 0.0


## Chamado pela run depois de pôr a sala na árvore.
func iniciar(jogador_: Jogador, camera_: CameraJogo, projeteis_: Node, banco: BancoOndas) -> void:
	jogador = jogador_
	camera = camera_
	projeteis = projeteis_
	banco_ondas = banco
	inimigos = Node2D.new()
	inimigos.name = "Inimigos"
	add_child(inimigos)
	# Paredes da sala (não deixam sair pelas pontas) e as da arena (só durante o combate).
	for x: float in [-16.0, largura_px]:
		_parede(x, true)
	if tem_arena():
		_paredes.append(_parede(arena.position.x - 16.0, false))
		_paredes.append(_parede(arena.end.x, false))
	for f in inimigos_fixos:
		_criar_inimigo(f["tipo"], f["posicao"], false)
	for e in estacoes_reparo:
		if e["tipo"] == "cura":
			var outra: Dictionary = {}
			for e2 in estacoes_reparo:
				if e2["tipo"] == "dadiva":
					outra = e2
			EstacaoReparo.criar_par(self, e["posicao"], outra.get("posicao", e["posicao"] + Vector2(64, 0)))
	for d in dicas:
		_dica = Label.new()
		_dica.text = "O: Grilhão — mire no gancho"
		_dica.add_theme_font_override("font", Fontes.pequena())
		_dica.add_theme_font_size_override("font_size", Fontes.TAMANHO_PEQUENA)
		_dica.position = d + Vector2(-40, -60)
		add_child(_dica)
		var grilhao := jogador.ferramenta as Grilhao
		if grilhao != null:
			grilhao.lancou.connect(func() -> void:
				if is_instance_valid(_dica):
					_dica.queue_free(), CONNECT_ONE_SHOT)
	jogador.limite_queda_y = limites().end.y + 24.0
	if not tem_arena():
		_abrir_portas()


func _parede(x: float, ativa: bool) -> Bloco:
	var p := Bloco.new()
	p.position = Vector2(x, 0)
	p.tamanho = Vector2(16, BancoBlocos.ALTURA * MontadorSala.T)
	p.cor = Color(0, 0, 0, 0)
	p.ativo = ativa
	add_child(p)
	return p


func _physics_process(delta: float) -> void:
	if jogador == null or not is_instance_valid(jogador):
		return
	for i in falas.size():
		if not i in _falas_tocadas and jogador.global_position.x >= falas[i]["x"]:
			_falas_tocadas.append(i)
			Dialogos.tocar(falas[i]["cena"])
	if tem_arena() and not arena_ativa and not arena_concluida \
			and jogador.global_position.x >= arena.position.x + ENTRADA_ARENA:
		comecar_arena()
	if arena_ativa:
		_atualizar_ondas(delta)


func comecar_arena() -> void:
	arena_ativa = true
	camera.definir_limites(arena)
	for p in _paredes:
		p.ativo = true
	arena_comecou.emit()
	_proxima_onda()


func _atualizar_ondas(delta: float) -> void:
	_timer_onda += delta
	var vivos: Array[Inimigo] = []
	for i in vivos_da_onda:
		if is_instance_valid(i) and i.esta_vivo():
			vivos.append(i)
	vivos_da_onda = vivos
	var ultima: bool = onda_atual >= plano["ondas"].size() - 1
	if ultima:
		if vivos_da_onda.is_empty() and _inimigos_vivos_na_arena() == 0:
			_concluir_arena()
		return
	var custo_vivo: int = 0
	for i in vivos_da_onda:
		custo_vivo += int(i.get_meta("custo", 0))
	if custo_vivo <= _custo_onda * FRACAO_PROXIMA_ONDA or _timer_onda >= ATRASO_PROXIMA_ONDA:
		_proxima_onda()


func _inimigos_vivos_na_arena() -> int:
	var n: int = 0
	for i in inimigos.get_children():
		var inimigo := i as Inimigo
		if inimigo != null and inimigo.esta_vivo() and arena.has_point(inimigo.global_position - Vector2(0, 1)):
			n += 1
	return n


func _proxima_onda() -> void:
	onda_atual += 1
	_timer_onda = 0.0
	var onda: Dictionary = plano["ondas"][onda_atual]
	_custo_onda = banco_ondas.custo(onda)
	var usados: Dictionary = {}
	var limite := Vector2(arena.position.x + 16.0, arena.end.x - 16.0)
	var jogadores: Array[Vector2] = []
	for no in get_tree().get_nodes_in_group("jogadores"):
		jogadores.append((no as Node2D).global_position)
	for item: Dictionary in onda["inimigos"]:
		var letra: String = item.get("ponto", "R")
		var pontos: Array = surgimentos.get(letra, surgimentos.get("R", surgimentos.get("L", [arena.get_center()])))
		var n: int = usados.get(letra, 0)
		usados[letra] = n + 1
		var base: Vector2 = pontos[n % pontos.size()]
		# Vários no mesmo ponto: um ao lado do outro, para dentro da arena.
		var lado: float = 1.0 if base.x < arena.get_center().x else -1.0
		var desejada: Vector2 = base + Vector2(lado * 36.0 * (n / pontos.size()), 0)
		# Surgimento justo (D-036, GD-03 §2.4): nunca a menos de 6 tiles do jogador.
		var pos: Vector2 = RegrasSurgimento.posicao_justa(desejada, jogadores, limite)
		var inimigo := _criar_inimigo(item["tipo"], pos, true)
		inimigo.set_meta("custo", banco_ondas.custo_inimigo(item["tipo"]))
		vivos_da_onda.append(inimigo)


func _criar_inimigo(tipo: String, posicao: Vector2, de_onda: bool) -> Inimigo:
	var inimigo: Inimigo = MontadorSala.cena_inimigo(tipo).instantiate()
	inimigo.position = posicao
	inimigo.container_projeteis = projeteis
	inimigo.set_meta("de_onda", de_onda)
	inimigos.add_child(inimigo)
	return inimigo


func _concluir_arena() -> void:
	arena_ativa = false
	arena_concluida = true
	for p in _paredes:
		p.ativo = false
	camera.definir_limites(limites())
	concluida.emit()
	_abrir_portas()


func _abrir_portas() -> void:
	var tipos: Array = plano.get("portas", [])
	if tipos.is_empty():
		return
	var pontos: Array[Vector2] = pontos_porta.duplicate()
	if pontos.is_empty():
		pontos.append(Vector2(largura_px - 48.0, inicio.y))
	# Duas portas usam os pontos das pontas; uma porta usa o do meio.
	var escolhidos: Array[Vector2] = []
	if tipos.size() == 1:
		escolhidos.append(pontos[pontos.size() / 2])
	elif tipos.size() == 2 and pontos.size() >= 3:
		escolhidos.assign([pontos[0], pontos[pontos.size() - 1]])
	else:
		escolhidos = pontos
	for i in tipos.size():
		var porta := PortaSaida.new()
		porta.tipo = tipos[i]
		porta.position = escolhidos[mini(i, escolhidos.size() - 1)]
		porta.escolhida.connect(_ao_escolher_porta)
		add_child.call_deferred(porta)
		portas.append(porta)


func _ao_escolher_porta(porta: PortaSaida) -> void:
	for p in portas:
		if p != porta and is_instance_valid(p):
			p.queue_free()
	porta_escolhida.emit(porta)
