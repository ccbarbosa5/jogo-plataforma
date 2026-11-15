class_name SalaRun
extends Node2D
## Uma sala do Ato montada pelo MontadorSala (GD-03 §2.1):
## [ENTRADA] → [TRECHO] ×1–3 → [ARENA] → [SAÍDA com portas].
## - trechos: inimigos colocados à mão e o enxame contínuo pela direita (GD-08 §3.2);
## - arena: a câmera trava; o DiretorHorda solta o enxame, os pesados (as ondas do plano)
##   a cada 8–10 s e o pico; quando a duração acaba e os pesados morrem, o enxame foge;
## - saída: as portas aparecem quando o diretor termina (ou logo, em loja e reparo).

signal arena_comecou
signal concluida
signal porta_escolhida(porta: PortaSaida)
## Um inimigo da sala morreu (Créditos: GD-02 §6.5; +5 se a facção rival matou, §4.4).
signal inimigo_morreu(inimigo: Inimigo, pela_rival: bool)
## O chefe entrou na arena (a run mostra a barra de vida).
signal chefe_apareceu(chefe: UrKesh)

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
var diretor: DiretorHorda
var pool: PoolEnxame
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
	inimigos.child_entered_tree.connect(_vigiar)
	# Paredes da sala (não deixam sair pelas pontas) e as da arena (só durante o combate).
	for x: float in [-16.0, largura_px]:
		_parede(x, true)
	if tem_arena():
		_paredes.append(_parede(arena.position.x - 16.0, false))
		_paredes.append(_parede(arena.end.x, false))
	if tem_arena():
		pool = PoolEnxame.new()
		pool.name = "PoolEnxame"
		add_child(pool)
		diretor = DiretorHorda.new(self)
		diretor.pool = pool
		diretor.configurar(chave_horda(), plano.get("ondas", []))
		add_child(diretor)
		diretor.terminou.connect(_concluir_arena)
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


## Qual configuração de horda vale nesta sala (data/salas/horda_varrek.json).
func chave_horda() -> String:
	var bioma: String = plano.get("bioma", "carcaca")
	if plano.get("elite", false):
		return "elite"
	if bioma == "queda":
		for o: Dictionary in plano.get("ondas", []):
			if o.get("id", "") == "queda_mini_arena":
				return "queda_primeira"
	return bioma


func _parede(x: float, ativa: bool) -> Bloco:
	var p := Bloco.new()
	p.position = Vector2(x, 0)
	p.tamanho = Vector2(16, BancoBlocos.ALTURA * MontadorSala.T)
	p.cor = Color(0, 0, 0, 0)
	p.ativo = ativa
	add_child(p)
	return p


func _physics_process(_delta: float) -> void:
	if jogador == null or not is_instance_valid(jogador):
		return
	for i in falas.size():
		if not i in _falas_tocadas and jogador.global_position.x >= falas[i]["x"]:
			_falas_tocadas.append(i)
			Dialogos.tocar(falas[i]["cena"])
	if diretor != null and diretor.fase == DiretorHorda.Fase.PARADO and not arena_ativa \
			and jogador.global_position.x >= Unidades.px(float(diretor.geral.get("inicio_trecho_tiles", 15))):
		diretor.comecar_trecho()
	if tem_arena() and not arena_ativa and not arena_concluida \
			and jogador.global_position.x >= arena.position.x + ENTRADA_ARENA:
		comecar_arena()


func comecar_arena() -> void:
	arena_ativa = true
	camera.definir_limites(arena)
	for p in _paredes:
		p.ativo = true
	arena_comecou.emit()
	if diretor != null:
		diretor.comecar_arena()


## Área do trecho (antes da arena), onde o enxame do trecho pode entrar.
func area_trecho() -> Rect2:
	var fim: float = arena.position.x if tem_arena() else largura_px
	return Rect2(0, 0, fim, limites().size.y)


func _criar_inimigo(tipo: String, posicao: Vector2, de_onda: bool) -> Inimigo:
	var inimigo: Inimigo = MontadorSala.cena_inimigo(tipo).instantiate()
	inimigo.position = posicao
	inimigo.container_projeteis = projeteis
	inimigo.set_meta("de_onda", de_onda)
	# Zona de guerra (GD-02 §4.4): Kharn e Vesh também atacam a facção rival.
	inimigo.ataca_faccao_rival = plano.get("bioma", "") == "zona_guerra"
	inimigos.add_child(inimigo)
	return inimigo


## Todo inimigo que entra na sala (inclusive os Zangões do Ninho) avisa quando morre.
func _vigiar(no: Node) -> void:
	var inimigo := no as Inimigo
	if inimigo != null and not inimigo.morreu.is_connected(_ao_morrer_inimigo):
		inimigo.morreu.connect(_ao_morrer_inimigo)


func _ao_morrer_inimigo(inimigo: Inimigo) -> void:
	var ultimo: Object = inimigo.get_meta("ultimo_golpe_de") if inimigo.has_meta("ultimo_golpe_de") else null
	var pela_rival: bool = ultimo != null and is_instance_valid(ultimo) and ultimo is Inimigo
	inimigo_morreu.emit(inimigo, pela_rival)


func _concluir_arena() -> void:
	if arena_concluida:
		return
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
