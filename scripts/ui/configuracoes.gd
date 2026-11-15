extends Node
## Autoload "Config": opções do jogador, salvas fora do progresso (D-054).
## - Teclas: cada ação trocável tem as suas teclas de teclado e mouse.
## - Controle (gamepad): as ações de botão (pular, atirar, Grilhão...) podem trocar de botão.
##   Andar e mirar continuam nos analógicos e no direcional.
## - Volume geral, tela cheia e acessibilidade (mira e tiro automáticos, GD-01 §3.1).
## Fica em user://configuracoes.cfg. Os testes usam outro caminho.

signal mudou

const CAMINHO_PADRAO: String = "user://configuracoes.cfg"
## Ações que o jogador pode trocar na tela de Controles, na ordem da tela.
const ACOES_TROCAVEIS: Array[StringName] = [
	&"mover_esquerda", &"mover_direita", &"mirar_baixo", &"pular", &"atirar", &"ferramenta",
	&"dash", &"granada", &"chamado", &"interagir",
]
const NOMES_ACOES: Dictionary = {
	&"mover_esquerda": "Andar para a esquerda",
	&"mover_direita": "Andar para a direita",
	&"mirar_baixo": "Agachar",
	&"pular": "Pular",
	&"atirar": "Atirar",
	&"ferramenta": "Grilhão",
	&"dash": "Dash",
	&"granada": "Granada",
	&"chamado": "Chamado",
	&"interagir": "Interagir",
}
## Teclas que não podem ir para uma ação trocável (Esc abre a pausa).
const TECLAS_RESERVADAS: Array[Key] = [KEY_ESCAPE]
## Ações que trocam de botão no controle (as de andar e mirar ficam nos analógicos).
const ACOES_CONTROLE: Array[StringName] = [
	&"pular", &"atirar", &"ferramenta", &"dash", &"granada", &"chamado", &"interagir",
]
## Botões do controle que não podem ir para uma ação (Start abre a pausa).
const BOTOES_RESERVADOS: Array[JoyButton] = [JOY_BUTTON_START]
## Nomes dos botões no padrão Xbox (o Godot usa esse padrão para todos os controles).
const NOMES_BOTOES: Dictionary = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_GUIDE: "Guia", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Direcional cima", JOY_BUTTON_DPAD_DOWN: "Direcional baixo",
	JOY_BUTTON_DPAD_LEFT: "Direcional esq.", JOY_BUTTON_DPAD_RIGHT: "Direcional dir.",
}
const NOMES_MIRA: Array[String] = ["Desligada", "Assistida", "Total"]

var caminho: String = CAMINHO_PADRAO
## 0 a 1.
var volume: float = 0.8
var tela_cheia: bool = false
var modo_mira: int = Assistencias.ModoMira.DESLIGADA
var tiro_automatico: bool = false

## ação -> teclas e botões de mouse de fábrica (para "Restaurar padrão").
var _padrao: Dictionary = {}
## ação -> botões do controle de fábrica.
var _padrao_controle: Dictionary = {}


func _init() -> void:
	# O padrão de fábrica é guardado antes de qualquer troca (o Input Map já está carregado).
	_guardar_padrao()


func _ready() -> void:
	carregar()


# --- Teclas ---

## Teclas e botões de mouse de uma ação (sem o gamepad).
func eventos_da_acao(acao: StringName) -> Array[InputEvent]:
	var lista: Array[InputEvent] = []
	for e in InputMap.action_get_events(acao):
		if _e_teclado_ou_mouse(e):
			lista.append(e)
	return lista


## Texto para a tela de Controles, ex.: "A / Seta esq.".
func texto_da_acao(acao: StringName) -> String:
	var nomes: Array[String] = []
	for e in eventos_da_acao(acao):
		nomes.append(nome_do_evento(e))
	return " / ".join(nomes) if not nomes.is_empty() else "—"


## Só a primeira tecla, para dicas curtas.
func tecla_principal(acao: StringName) -> String:
	var lista: Array[InputEvent] = eventos_da_acao(acao)
	return nome_do_evento(lista[0]) if not lista.is_empty() else "—"


static func nome_do_evento(e: InputEvent) -> String:
	if e is InputEventMouseButton:
		match (e as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "Botão esquerdo"
			MOUSE_BUTTON_RIGHT:
				return "Botão direito"
			MOUSE_BUTTON_MIDDLE:
				return "Botão do meio"
			_:
				return "Botão %d" % (e as InputEventMouseButton).button_index
	if e is InputEventKey:
		var codigo: Key = (e as InputEventKey).physical_keycode
		if codigo == KEY_NONE:
			codigo = (e as InputEventKey).keycode
		match codigo:
			KEY_SPACE:
				return "Espaço"
			KEY_ESCAPE:
				return "Esc"
			KEY_LEFT:
				return "Seta esq."
			KEY_RIGHT:
				return "Seta dir."
			KEY_UP:
				return "Seta cima"
			KEY_DOWN:
				return "Seta baixo"
			KEY_ENTER:
				return "Enter"
			KEY_CTRL:
				return "Ctrl"
		return OS.get_keycode_string(codigo)
	return "?"


## Troca as teclas de `acao` por `evento`. Se outra ação trocável já usava essa tecla, as duas
## trocam de tecla (ninguém fica sem). Devolve a outra ação, ou &"" se não houve troca.
## Teclas reservadas (Esc, Tab) são recusadas: devolve &"reservada" e não muda nada.
func trocar_tecla(acao: StringName, evento: InputEvent) -> StringName:
	var novo: InputEvent = _normalizar(evento)
	if novo == null or not ACOES_TROCAVEIS.has(acao):
		return &"reservada"
	if novo is InputEventKey and TECLAS_RESERVADAS.has((novo as InputEventKey).physical_keycode):
		return &"reservada"
	var antigos: Array[InputEvent] = eventos_da_acao(acao)
	var trocou_com: StringName = &""
	for outra in ACOES_TROCAVEIS:
		if outra == acao:
			continue
		for e in eventos_da_acao(outra):
			if _mesmo_evento(e, novo):
				InputMap.action_erase_event(outra, e)
				if eventos_da_acao(outra).is_empty():
					for antigo in antigos:
						InputMap.action_add_event(outra, antigo.duplicate())
				trocou_com = outra
	for e in antigos:
		InputMap.action_erase_event(acao, e)
	InputMap.action_add_event(acao, novo)
	salvar()
	mudou.emit()
	return trocou_com


func restaurar_teclas() -> void:
	for acao in ACOES_TROCAVEIS:
		_definir_eventos(acao, _padrao.get(acao, []))
	for acao in ACOES_CONTROLE:
		_definir_eventos_controle(acao, _padrao_controle.get(acao, []))
	salvar()
	mudou.emit()


# --- Controle (gamepad) ---

## Botões (e gatilhos) do controle de uma ação.
func eventos_do_controle(acao: StringName) -> Array[InputEvent]:
	var lista: Array[InputEvent] = []
	for e in InputMap.action_get_events(acao):
		if _e_botao_do_controle(e):
			lista.append(e)
	return lista


func texto_do_controle(acao: StringName) -> String:
	var nomes: Array[String] = []
	for e in eventos_do_controle(acao):
		nomes.append(nome_do_botao(e))
	return " / ".join(nomes) if not nomes.is_empty() else "—"


static func nome_do_botao(e: InputEvent) -> String:
	if e is InputEventJoypadButton:
		var b: JoyButton = (e as InputEventJoypadButton).button_index
		return NOMES_BOTOES.get(b, "Botão %d" % b)
	if e is InputEventJoypadMotion:
		return "LT" if (e as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_LEFT else "RT"
	return "?"


## Troca o botão do controle de `acao` por `evento` (botão ou gatilho). Se outra ação já usava
## esse botão, as duas trocam. Devolve a outra ação, &"" sem troca, ou &"reservada".
func trocar_botao(acao: StringName, evento: InputEvent) -> StringName:
	var novo: InputEvent = _normalizar_controle(evento)
	if novo == null or not ACOES_CONTROLE.has(acao):
		return &"reservada"
	if novo is InputEventJoypadButton and BOTOES_RESERVADOS.has((novo as InputEventJoypadButton).button_index):
		return &"reservada"
	var antigos: Array[InputEvent] = eventos_do_controle(acao)
	var trocou_com: StringName = &""
	for outra in ACOES_CONTROLE:
		if outra == acao:
			continue
		for e in eventos_do_controle(outra):
			if _mesmo_botao(e, novo):
				InputMap.action_erase_event(outra, e)
				if eventos_do_controle(outra).is_empty():
					for antigo in antigos:
						InputMap.action_add_event(outra, antigo.duplicate())
				trocou_com = outra
	for e in antigos:
		InputMap.action_erase_event(acao, e)
	InputMap.action_add_event(acao, novo)
	salvar()
	mudou.emit()
	return trocou_com


## O evento serve para trocar um botão? (botão apertado ou gatilho puxado até o fim)
static func serve_para_controle(e: InputEvent) -> bool:
	if e is InputEventJoypadButton:
		return (e as InputEventJoypadButton).pressed
	if e is InputEventJoypadMotion:
		var m := e as InputEventJoypadMotion
		return (m.axis == JOY_AXIS_TRIGGER_LEFT or m.axis == JOY_AXIS_TRIGGER_RIGHT) and m.axis_value > 0.6
	return false


# --- Opções ---

func definir_volume(valor: float) -> void:
	volume = clampf(valor, 0.0, 1.0)
	_aplicar_volume()
	salvar()
	mudou.emit()


func definir_tela_cheia(sim: bool) -> void:
	tela_cheia = sim
	_aplicar_tela_cheia()
	salvar()
	mudou.emit()


func definir_modo_mira(modo: int) -> void:
	modo_mira = wrapi(modo, 0, 3)
	_aplicar_nos_jogadores()
	salvar()
	mudou.emit()


func definir_tiro_automatico(sim: bool) -> void:
	tiro_automatico = sim
	_aplicar_nos_jogadores()
	salvar()
	mudou.emit()


## O Jogador chama ao nascer.
func aplicar_assistencias(opcoes: Assistencias) -> void:
	opcoes.modo_mira = modo_mira as Assistencias.ModoMira
	opcoes.tiro_automatico = tiro_automatico


# --- Arquivo ---

func salvar() -> void:
	var cfg := ConfigFile.new()
	for acao in ACOES_TROCAVEIS:
		var codigos: Array[String] = []
		for e in eventos_da_acao(acao):
			codigos.append(_codificar(e))
		cfg.set_value("teclas", String(acao), codigos)
	for acao in ACOES_CONTROLE:
		var botoes: Array[String] = []
		for e in eventos_do_controle(acao):
			botoes.append(_codificar(e))
		cfg.set_value("controle", String(acao), botoes)
	cfg.set_value("opcoes", "volume", volume)
	cfg.set_value("opcoes", "tela_cheia", tela_cheia)
	cfg.set_value("opcoes", "modo_mira", modo_mira)
	cfg.set_value("opcoes", "tiro_automatico", tiro_automatico)
	cfg.save(caminho)


## Lê o arquivo (se existir) e aplica tudo. Sem arquivo, fica o padrão.
func carregar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(caminho) == OK:
		for acao in ACOES_TROCAVEIS:
			var codigos: Array = cfg.get_value("teclas", String(acao), [])
			var eventos: Array[InputEvent] = []
			for c in codigos:
				var e: InputEvent = _decodificar(String(c))
				if e != null:
					eventos.append(e)
			if not eventos.is_empty():
				_definir_eventos(acao, eventos)
		for acao in ACOES_CONTROLE:
			var eventos_controle: Array[InputEvent] = []
			for c in cfg.get_value("controle", String(acao), []):
				var e: InputEvent = _decodificar(String(c))
				if e != null:
					eventos_controle.append(e)
			if not eventos_controle.is_empty():
				_definir_eventos_controle(acao, eventos_controle)
		volume = cfg.get_value("opcoes", "volume", volume)
		tela_cheia = cfg.get_value("opcoes", "tela_cheia", tela_cheia)
		modo_mira = cfg.get_value("opcoes", "modo_mira", modo_mira)
		tiro_automatico = cfg.get_value("opcoes", "tiro_automatico", tiro_automatico)
	_aplicar_volume()
	if tela_cheia:
		_aplicar_tela_cheia()


## Volta tudo ao padrão de fábrica (teclas e opções), sem tocar no arquivo. Usado pelos testes.
func redefinir_sem_salvar() -> void:
	for acao in ACOES_TROCAVEIS:
		_definir_eventos(acao, _padrao.get(acao, []))
	for acao in ACOES_CONTROLE:
		_definir_eventos_controle(acao, _padrao_controle.get(acao, []))
	volume = 0.8
	tela_cheia = false
	modo_mira = Assistencias.ModoMira.DESLIGADA
	tiro_automatico = false
	_aplicar_volume()


# --- Internos ---

func _guardar_padrao() -> void:
	for acao in ACOES_TROCAVEIS:
		var copia: Array[InputEvent] = []
		for e in eventos_da_acao(acao):
			copia.append(e.duplicate())
		_padrao[acao] = copia
	for acao in ACOES_CONTROLE:
		var botoes: Array[InputEvent] = []
		for e in eventos_do_controle(acao):
			botoes.append(e.duplicate())
		_padrao_controle[acao] = botoes


func _definir_eventos(acao: StringName, eventos: Array) -> void:
	for e in eventos_da_acao(acao):
		InputMap.action_erase_event(acao, e)
	for e: InputEvent in eventos:
		InputMap.action_add_event(acao, e.duplicate())


func _definir_eventos_controle(acao: StringName, eventos: Array) -> void:
	for e in eventos_do_controle(acao):
		InputMap.action_erase_event(acao, e)
	for e: InputEvent in eventos:
		InputMap.action_add_event(acao, e.duplicate())


func _aplicar_volume() -> void:
	AudioServer.set_bus_mute(0, volume <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))


func _aplicar_tela_cheia() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if tela_cheia else DisplayServer.WINDOW_MODE_WINDOWED)


func _aplicar_nos_jogadores() -> void:
	for no in get_tree().get_nodes_in_group("jogadores"):
		var j := no as Jogador
		if j != null:
			aplicar_assistencias(j.assistencias)


static func _e_teclado_ou_mouse(e: InputEvent) -> bool:
	return e is InputEventKey or e is InputEventMouseButton


## Botão do controle ou gatilho (LT/RT). Os eixos dos analógicos ficam de fora.
static func _e_botao_do_controle(e: InputEvent) -> bool:
	if e is InputEventJoypadButton:
		return true
	if e is InputEventJoypadMotion:
		var a: JoyAxis = (e as InputEventJoypadMotion).axis
		return a == JOY_AXIS_TRIGGER_LEFT or a == JOY_AXIS_TRIGGER_RIGHT
	return false


static func _normalizar_controle(evento: InputEvent) -> InputEvent:
	if evento is InputEventJoypadButton:
		var b := InputEventJoypadButton.new()
		b.device = -1
		b.button_index = (evento as InputEventJoypadButton).button_index
		return b
	if evento is InputEventJoypadMotion:
		var a: JoyAxis = (evento as InputEventJoypadMotion).axis
		if a != JOY_AXIS_TRIGGER_LEFT and a != JOY_AXIS_TRIGGER_RIGHT:
			return null
		var m := InputEventJoypadMotion.new()
		m.device = -1
		m.axis = a
		m.axis_value = 1.0
		return m
	return null


static func _mesmo_botao(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return (a as InputEventJoypadButton).button_index == (b as InputEventJoypadButton).button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return (a as InputEventJoypadMotion).axis == (b as InputEventJoypadMotion).axis
	return false


## Cópia limpa do evento (só o que identifica a tecla), ou null se não serve.
static func _normalizar(evento: InputEvent) -> InputEvent:
	if evento is InputEventKey:
		var k := InputEventKey.new()
		var tecla := evento as InputEventKey
		k.physical_keycode = tecla.physical_keycode if tecla.physical_keycode != KEY_NONE else tecla.keycode
		return k if k.physical_keycode != KEY_NONE else null
	if evento is InputEventMouseButton:
		var m := InputEventMouseButton.new()
		m.button_index = (evento as InputEventMouseButton).button_index
		return m
	return null


static func _mesmo_evento(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return (a as InputEventKey).physical_keycode == (b as InputEventKey).physical_keycode
	if a is InputEventMouseButton and b is InputEventMouseButton:
		return (a as InputEventMouseButton).button_index == (b as InputEventMouseButton).button_index
	return false


static func _codificar(e: InputEvent) -> String:
	if e is InputEventJoypadButton:
		return "joy:%d" % (e as InputEventJoypadButton).button_index
	if e is InputEventJoypadMotion:
		return "gatilho:%d" % (e as InputEventJoypadMotion).axis
	if e is InputEventMouseButton:
		return "mouse:%d" % (e as InputEventMouseButton).button_index
	return "tecla:%d" % (e as InputEventKey).physical_keycode


static func _decodificar(codigo: String) -> InputEvent:
	var partes: PackedStringArray = codigo.split(":")
	if partes.size() != 2 or not partes[1].is_valid_int():
		return null
	match partes[0]:
		"tecla":
			var k := InputEventKey.new()
			k.physical_keycode = int(partes[1]) as Key
			return k
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = int(partes[1]) as MouseButton
			return m
		"joy":
			var b := InputEventJoypadButton.new()
			b.device = -1
			b.button_index = int(partes[1]) as JoyButton
			return b
		"gatilho":
			var g := InputEventJoypadMotion.new()
			g.device = -1
			g.axis = int(partes[1]) as JoyAxis
			g.axis_value = 1.0
			return g
	return null
