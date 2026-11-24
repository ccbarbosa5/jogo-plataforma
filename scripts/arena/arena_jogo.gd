class_name ArenaJogo
extends Node2D
## Protótipo da arena (DEV 33, GD-09, D-077/D-078): o Ryker visto de cima numa arena fechada,
## 3 ondas de Roedores e Zangões, Sucata e a loja do Ilo entre as ondas.
## Fluxo: ONDA → INTERVALO (a Sucata voa até o Ryker) → LOJA → próxima ONDA ... → FIM.
## Não usa nada do código de plataforma (D-078). Arte provisória: formas simples.

enum Estado { ONDA, INTERVALO, LOJA, FIM }

const GRUPO_MUNDO: StringName = &"mundo_arena"
const INTERVALO: float = 1.0
const COR_CHAO: Color = Color("3a2a2e")
const COR_PAREDE: Color = Color("1e1620")
const COR_MARCA: Color = Color("ff4a4a")
const TELA: Vector2 = Vector2(480, 270)

## false = os testes controlam o começo das ondas.
@export var comecar_sozinha: bool = true

var estado: Estado = Estado.INTERVALO
var indice_onda: int = 0
var tempo_onda: float = 0.0
var sucata: int = 0
var venceu: bool = false
var diretor := DiretorOndas.new()
var jogador: JogadorArena
var mundo: Node2D
var loja: LojaArena
## Inimigos anunciados: cada um {"pos": Vector2, "tipo": String, "tempo": float}
var marcas: Array[Dictionary] = []

var _acumulador: float = 0.0
var _tempo_intervalo: float = 0.0
var _no_marcas: Node2D
var _hud: Label
var _camada_fim: CanvasLayer
var _texto_fim: Label
var _camada_pausa: CanvasLayer
var _botao_continuar: Button


func _ready() -> void:
	var area: Rect2 = diretor.area_util()
	mundo = Node2D.new()
	mundo.name = "Mundo"
	mundo.add_to_group(GRUPO_MUNDO)
	add_child(mundo)
	_no_marcas = Node2D.new()
	_no_marcas.name = "Marcas"
	_no_marcas.draw.connect(_desenhar_marcas)
	mundo.add_child(_no_marcas)
	jogador = JogadorArena.new()
	jogador.name = "Ryker"
	jogador.position = area.get_center()
	mundo.add_child(jogador)
	jogador.limites = area
	jogador.morreu.connect(_ryker_morreu)
	jogador.vida_mudou.connect(func(_v: int, _m: int) -> void: _atualizar_hud())
	var camera := Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(area.end.x + area.position.x)
	camera.limit_bottom = int(area.end.y + area.position.y)
	jogador.add_child(camera)
	_montar_hud()
	loja = LojaArena.new()
	loja.arena = self
	loja.terminou.connect(_loja_fechou)
	add_child(loja)
	_montar_fim()
	_montar_pausa()
	if comecar_sozinha:
		comecar_onda(0)


func _exit_tree() -> void:
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false


func _physics_process(delta: float) -> void:
	match estado:
		Estado.ONDA:
			_passo_da_onda(delta)
		Estado.INTERVALO:
			_tempo_intervalo -= delta
			if _tempo_intervalo <= 0.0 and get_tree().get_nodes_in_group(SucataArena.GRUPO).is_empty():
				_depois_do_intervalo()
	_atualizar_hud()


func comecar_onda(indice: int) -> void:
	indice_onda = indice
	tempo_onda = 0.0
	_acumulador = 0.0
	estado = Estado.ONDA


func numero_da_onda() -> int:
	return indice_onda + 1


func inimigos_vivos() -> int:
	return get_tree().get_nodes_in_group(InimigoArena.GRUPO).size()


func _passo_da_onda(delta: float) -> void:
	tempo_onda += delta
	_acumulador += diretor.taxa(indice_onda, tempo_onda) * delta
	while _acumulador >= 1.0:
		_acumulador -= 1.0
		anunciar_inimigo(diretor.sortear_tipo(indice_onda))
	for i in range(marcas.size() - 1, -1, -1):
		marcas[i]["tempo"] = float(marcas[i]["tempo"]) - delta
		if float(marcas[i]["tempo"]) <= 0.0:
			var m: Dictionary = marcas[i]
			marcas.remove_at(i)
			criar_inimigo(String(m["tipo"]), m["pos"])
	_no_marcas.queue_redraw()
	if tempo_onda >= diretor.duracao(indice_onda):
		terminar_onda()


## Marca no chão onde o inimigo vai nascer (aviso de 1,0 s). Respeita o teto de 40.
func anunciar_inimigo(tipo: String) -> bool:
	if inimigos_vivos() + marcas.size() >= diretor.teto():
		return false
	var aviso: float = float(diretor.arena["aviso_nascer"])
	marcas.append({"pos": diretor.ponto_de_nascimento(jogador.position), "tipo": tipo, "tempo": aviso})
	return true


func criar_inimigo(tipo: String, pos: Vector2) -> InimigoArena:
	var inimigo := InimigoArena.new()
	inimigo.configurar(tipo, numero_da_onda())
	inimigo.position = pos
	inimigo.alvo = jogador
	inimigo.limites = diretor.area_util()
	inimigo.morreu.connect(_inimigo_morreu)
	mundo.add_child(inimigo)
	return inimigo


## Fim da onda (GD-09 §2): inimigos, marcas e projéteis somem; toda a Sucata voa até o Ryker.
func terminar_onda() -> void:
	if estado != Estado.ONDA:
		return
	estado = Estado.INTERVALO
	_tempo_intervalo = INTERVALO
	marcas.clear()
	_no_marcas.queue_redraw()
	for no in get_tree().get_nodes_in_group(InimigoArena.GRUPO):
		no.remove_from_group(InimigoArena.GRUPO)
		no.queue_free()
	for no in mundo.get_children():
		if no is ProjetilArena:
			no.queue_free()
	var atracao: float = float(diretor.arena["atracao_fim_onda"])
	for no in get_tree().get_nodes_in_group(SucataArena.GRUPO):
		(no as SucataArena).atrair(atracao)


func _depois_do_intervalo() -> void:
	if numero_da_onda() >= diretor.total_de_ondas():
		_terminar(true)
		return
	estado = Estado.LOJA
	loja.abrir(numero_da_onda())


func _loja_fechou() -> void:
	if estado == Estado.LOJA:
		comecar_onda(indice_onda + 1)


func gastar_sucata(valor: int) -> void:
	sucata = maxi(sucata - valor, 0)


func _inimigo_morreu(inimigo: InimigoArena) -> void:
	var s := SucataArena.new()
	s.valor = inimigo.sucata
	s.jogador = jogador
	s.position = inimigo.position
	s.coletada.connect(func(v: int) -> void: sucata += v)
	mundo.add_child.call_deferred(s)


func _ryker_morreu() -> void:
	_terminar(false)


func _terminar(vitoria: bool) -> void:
	if estado == Estado.FIM:
		return
	estado = Estado.FIM
	venceu = vitoria
	_texto_fim.text = "VOCÊ SOBREVIVEU ÀS %d ONDAS" % diretor.total_de_ondas() if vitoria \
			else "O RYKER CAIU NA ONDA %d" % numero_da_onda()
	_camada_fim.visible = true


# --- Pausa (D-065: Esc sempre volta) ---

func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed("pausa"):
		return
	if _camada_pausa.visible:
		_continuar()
	elif estado == Estado.ONDA:
		get_tree().paused = true
		_camada_pausa.visible = true
		_botao_continuar.grab_focus.call_deferred()
	get_viewport().set_input_as_handled()


func _continuar() -> void:
	_camada_pausa.visible = false
	get_tree().paused = false


func _sair_para_o_menu() -> void:
	get_tree().paused = false
	Ciclo.ir_para_titulo()


# --- Desenho e interface ---

func _draw() -> void:
	var area: Rect2 = diretor.area_util()
	draw_rect(Rect2(Vector2.ZERO, area.end + area.position), COR_PAREDE)
	draw_rect(area, COR_CHAO)


func _desenhar_marcas() -> void:
	var aviso: float = float(diretor.arena["aviso_nascer"])
	for m in marcas:
		var falta: float = clampf(float(m["tempo"]) / aviso, 0.0, 1.0)
		_no_marcas.draw_arc(m["pos"], 3.0 + 5.0 * falta, 0.0, TAU, 12, COR_MARCA, 1.0)


func _atualizar_hud() -> void:
	if _hud == null or jogador == null:
		return
	var resto: int = ceili(maxf(diretor.duracao(indice_onda) - tempo_onda, 0.0)) if estado == Estado.ONDA else 0
	_hud.text = "Vida %d/%d    Sucata %d    Onda %d/%d    %ds" % [
		jogador.vida, jogador.vida_max, sucata, numero_da_onda(), diretor.total_de_ondas(), resto]


func _rotulo(pai: Node, tamanho: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_outline_color", EstiloMenu.COR_SOMBRA)
	l.add_theme_constant_override("outline_size", 2)
	pai.add_child(l)
	return l


func _montar_hud() -> void:
	var camada := CanvasLayer.new()
	camada.name = "Hud"
	camada.layer = 10
	add_child(camada)
	_hud = _rotulo(camada, Fontes.TAMANHO_TEXTO)
	_hud.position = Vector2(8, 6)


func _camada_menu(nome: String, texto: String) -> Array:
	var camada := CanvasLayer.new()
	camada.name = nome
	camada.layer = 30
	camada.process_mode = Node.PROCESS_MODE_ALWAYS
	camada.visible = false
	add_child(camada)
	var raiz := Control.new()
	raiz.size = TELA
	raiz.theme = EstiloMenu.tema()
	camada.add_child(raiz)
	var fundo := ColorRect.new()
	fundo.color = Color(0.03, 0.02, 0.05, 0.7)
	fundo.size = TELA
	raiz.add_child(fundo)
	var titulo := _rotulo(raiz, Fontes.TAMANHO_TITULO)
	titulo.add_theme_font_override("font", Fontes.placa())
	titulo.text = texto
	titulo.size = Vector2(TELA.x, 20)
	titulo.position = Vector2(0, 90)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return [camada, raiz, titulo]


func _montar_fim() -> void:
	var partes: Array = _camada_menu("Fim", "")
	_camada_fim = partes[0]
	_texto_fim = partes[2]
	EstiloMenu.botao(partes[1], "Voltar ao menu", Rect2(190, 140, 100, 16), _sair_para_o_menu)


func _montar_pausa() -> void:
	var partes: Array = _camada_menu("Pausa", "PAUSA")
	_camada_pausa = partes[0]
	_botao_continuar = EstiloMenu.botao(partes[1], "Continuar", Rect2(190, 130, 100, 16), _continuar)
	EstiloMenu.botao(partes[1], "Sair para o menu", Rect2(190, 152, 100, 16), _sair_para_o_menu)
