class_name CaixaDialogo
extends CanvasLayer
## Caixa de diálogo (D-032).
## - modo "conversa" (fora do combate): estilo Hades — cenário escurecido, retrato grande de
##   meio corpo passando por cima da borda, placa com nome e título, caixa larga com moldura
##   da facção de quem fala e seta de continuar. Jogáveis à esquerda; interlocutor à direita.
##   Pausa o jogo; avança com Interagir, Pular ou Atirar.
## - modo "rapida" (durante o combate): faixa pequena no topo, sem pausar (pilar 1).
## Os nós visuais são montados por código; o visual final de ART entra por cima.

signal terminou(id_cena: String)

const COR_TEXTO: Color = Color("eceff4")
const COR_DIRECAO: Color = Color("a7adba")

## Segundos por caractere no modo rápido (com um mínimo).
@export var segundos_por_caractere: float = 0.05
@export var minimo_rapida: float = 1.8
## Tempo mínimo antes de aceitar o comando de avançar (evita pular a fala sem querer).
@export var trava_avanco: float = 0.15

## Comandos do jogador que conduz o diálogo. Sem isso, lê o Input direto.
var entrada: EntradaJogador

var escurecer: ColorRect
var retrato_esquerda: RetratoDialogo
var retrato_direita: RetratoDialogo
var caixa: MolduraDialogo
var placa: MolduraDialogo
var nome: Label
var texto: Label
var direcao: Label
var rapida: MolduraDialogo
var rapida_nome: Label
var rapida_texto: Label

var _id_cena: String = ""
var _falas: Array[Dictionary] = []
var _indice: int = 0
var _modo: String = "conversa"
var _banco: BancoDialogos
var _timer: float = 0.0
var _trava: float = 0.0
var _pausou: bool = false
var _ativa: bool = false


func _ready() -> void:
	add_to_group("caixa_dialogo")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_montar()
	_esconder_tudo()


func esta_ativa() -> bool:
	return _ativa


func fala_atual() -> Dictionary:
	return _falas[_indice] if _indice < _falas.size() else {}


func nome_atual() -> String:
	return rapida_nome.text if _modo == "rapida" else nome.text


func mostrar(id_cena: String, falas: Array[Dictionary], modo: String, banco: BancoDialogos) -> void:
	if _ativa:
		_encerrar()
	_id_cena = id_cena
	_falas = falas
	_indice = 0
	_modo = modo
	_banco = banco
	_ativa = true
	retrato_esquerda.visible = false
	retrato_direita.visible = false
	if _modo == "conversa" and not get_tree().paused:
		get_tree().paused = true
		_pausou = true
	_exibir()


func avancar() -> void:
	if not _ativa:
		return
	_indice += 1
	if _indice >= _falas.size():
		_encerrar()
	else:
		_exibir()


func _exibir() -> void:
	var fala: Dictionary = _falas[_indice]
	var falante: String = fala.get("falante", "")
	var nome_falante: String = _banco.nome_do_falante(falante) if not falante.is_empty() else ""
	var cor: Color = _banco.cor_do_falante(falante)
	_trava = trava_avanco
	_timer = maxf(minimo_rapida, String(fala.get("texto", "")).length() * segundos_por_caractere)
	if _modo == "rapida":
		_esconder_conversa()
		rapida.visible = true
		rapida.moldura = _banco.moldura_do_falante(falante)
		rapida_nome.text = nome_falante
		rapida_nome.add_theme_color_override("font_color", cor)
		rapida_texto.text = fala.get("texto", "")
		return
	rapida.visible = false
	escurecer.visible = true
	caixa.visible = true
	var moldura: String = _banco.moldura_do_falante(falante) if not falante.is_empty() else "humano"
	caixa.moldura = moldura
	texto.text = fala.get("texto", "")
	texto.add_theme_color_override("font_color", COR_TEXTO)
	var dir: String = fala.get("direcao", "")
	direcao.text = "[%s]" % dir if not dir.is_empty() else ""
	if falante.is_empty():
		# Só direção de cena: vira o texto principal, em tom apagado, sem placa.
		texto.text = dir
		texto.add_theme_color_override("font_color", COR_DIRECAO)
		direcao.text = ""
		placa.visible = false
		retrato_esquerda.ativo = false
		retrato_direita.ativo = false
		return
	# Os dois lados podem aparecer (mockup v04 da ART); quem não fala fica mais escuro.
	var lado: String = _banco.lado_do_falante(falante)
	var retrato: RetratoDialogo = retrato_esquerda if lado == "esquerda" else retrato_direita
	var outro: RetratoDialogo = retrato_direita if lado == "esquerda" else retrato_esquerda
	var expressao: String = fala.get("expressao", "")
	var expressoes: Array = _banco.expressoes_do_falante(falante)
	if expressao.is_empty() and not expressoes.is_empty():
		expressao = expressoes[0]
	retrato.mostrar(falante, expressao, expressoes, cor, moldura, _banco.retrato_do_falante(falante))
	retrato.ativo = true
	outro.ativo = false
	# Placa só com o NOME (D-046), encostada no lado de quem fala.
	placa.visible = true
	placa.moldura = moldura
	nome.text = nome_falante.to_upper()
	nome.add_theme_color_override("font_color", cor)
	var largura_nome: float = Fontes.texto().get_string_size(nome.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Fontes.TAMANHO_TEXTO).x
	placa.size = Vector2(maxf(largura_nome + 28.0, 64.0), 24.0)
	nome.position = Vector2(14.0, 4.0)
	nome.size = Vector2(placa.size.x - 28.0, 16.0)
	var y_placa: float = caixa.position.y - placa.size.y + 4.0
	if lado == "direita":
		placa.position = Vector2(caixa.position.x + caixa.size.x - placa.size.x - 8.0, y_placa)
	else:
		placa.position = Vector2(caixa.position.x + 8.0, y_placa)


func _process(delta: float) -> void:
	if not _ativa:
		return
	_trava = maxf(_trava - delta, 0.0)
	if _modo == "rapida":
		_timer -= delta
		if _timer <= 0.0:
			avancar()
		return
	if _trava <= 0.0 and _pediu_avancar():
		avancar()


func _pediu_avancar() -> bool:
	if entrada != null:
		entrada.atualizar()
		var pediu: bool = entrada.interagir_pressionado or entrada.pular_pressionado or entrada.atirar_pressionado
		entrada.fim_do_frame()
		return pediu
	return Input.is_action_just_pressed("interagir") or Input.is_action_just_pressed("pular") \
			or Input.is_action_just_pressed("atirar")


func _encerrar() -> void:
	_ativa = false
	_esconder_tudo()
	if _pausou:
		get_tree().paused = false
		_pausou = false
	var id: String = _id_cena
	_falas = []
	terminou.emit(id)


func _esconder_conversa() -> void:
	escurecer.visible = false
	retrato_esquerda.visible = false
	retrato_direita.visible = false
	caixa.visible = false
	placa.visible = false


func _esconder_tudo() -> void:
	_esconder_conversa()
	rapida.visible = false


# --- Montagem dos nós (tela de 480×270; layout do mockup v04 da ART) ---

func _montar() -> void:
	var tela := Vector2(480, 270)
	escurecer = ColorRect.new()
	escurecer.color = Color(0.03, 0.02, 0.05, 0.62)
	escurecer.size = tela
	escurecer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(escurecer)

	# Retratos nas laterais, atrás da caixa (o corte da cintura fica escondido por ela).
	retrato_esquerda = RetratoDialogo.new()
	retrato_esquerda.position = Vector2(-6, tela.y - RetratoDialogo.TAMANHO.y)
	retrato_esquerda.size = RetratoDialogo.TAMANHO
	retrato_esquerda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(retrato_esquerda)
	retrato_direita = RetratoDialogo.new()
	retrato_direita.espelhar = true
	retrato_direita.position = Vector2(tela.x - RetratoDialogo.TAMANHO.x + 6, tela.y - RetratoDialogo.TAMANHO.y)
	retrato_direita.size = RetratoDialogo.TAMANHO
	retrato_direita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(retrato_direita)

	caixa = MolduraDialogo.new()
	caixa.position = Vector2(92, 192)
	caixa.size = Vector2(296, 72)
	add_child(caixa)
	texto = _rotulo(caixa, Fontes.texto(), Fontes.TAMANHO_TEXTO, COR_TEXTO)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.position = Vector2(14, 9)
	texto.size = Vector2(caixa.size.x - 28, 46)
	direcao = _rotulo(caixa, Fontes.pequena(), Fontes.TAMANHO_PEQUENA, COR_DIRECAO)
	direcao.position = Vector2(14, caixa.size.y - 18)
	direcao.size = Vector2(caixa.size.x - 44, 12)
	direcao.clip_text = true

	placa = MolduraDialogo.new()
	placa.mostrar_seta = false
	add_child(placa)
	nome = _rotulo(placa, Fontes.texto(), Fontes.TAMANHO_TEXTO, Color.WHITE)

	rapida = MolduraDialogo.new()
	rapida.mostrar_seta = false
	rapida.position = Vector2(132, 4)
	rapida.size = Vector2(tela.x - 136, 44)
	add_child(rapida)
	rapida_nome = _rotulo(rapida, Fontes.pequena(), Fontes.TAMANHO_PEQUENA, Color.WHITE)
	rapida_nome.position = Vector2(12, 5)
	rapida_nome.size = Vector2(rapida.size.x - 24, 10)
	rapida_texto = _rotulo(rapida, Fontes.texto(), Fontes.TAMANHO_TEXTO, COR_TEXTO)
	rapida_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rapida_texto.position = Vector2(12, 14)
	rapida_texto.size = Vector2(rapida.size.x - 24, 28)


func _rotulo(pai: Control, fonte: Font, tamanho_fonte: int, cor: Color) -> Label:
	var r := Label.new()
	r.add_theme_font_override("font", fonte)
	r.add_theme_font_size_override("font_size", tamanho_fonte)
	r.add_theme_color_override("font_color", cor)
	r.add_theme_constant_override("line_spacing", 0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(r)
	return r
