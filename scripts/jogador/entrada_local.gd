class_name EntradaLocal
extends EntradaJogador
## Lê teclado, mouse e gamepad pelas ações do Input Map (GD-01 §3; controles da D-052).
## Mira: o mouse aponta no mundo; o analógico direito aponta em 360°. Quem mexeu por último
## manda (mexer o mouse volta para o mouse; mexer o analógico direito passa para o gamepad).
## Antes de mexer em qualquer um dos dois, vale a mira de 8 direções (só teclado ou só o
## analógico esquerdo).
## Co-op (D-018): cada jogador terá um EntradaLocal com o próprio `prefixo`
## ("" para o P1, "p2_" para o P2...), lendo ações ligadas só ao seu dispositivo.

enum Dispositivo { NENHUM, MOUSE, GAMEPAD }

const LIMIAR_ANALOGICO: float = 0.5
## Zona morta do analógico direito para começar a mirar.
const ZONA_MORTA_MIRA: float = 0.35
## Quanto o mouse precisa andar (px da tela 480×270) para a mira voltar a ele.
const MOVIMENTO_MINIMO_MOUSE: float = 0.5

var prefixo: String = ""
var dispositivo: Dispositivo = Dispositivo.NENHUM
## Última direção do analógico direito (o tiro continua nela ao soltar o analógico).
var ultima_mira_analogica: Vector2 = Vector2.ZERO

var _ultimo_mouse: Vector2 = Vector2.INF


func _init(prefixo_acoes: String = "") -> void:
	prefixo = prefixo_acoes


func atualizar() -> void:
	var x: float = Input.get_axis(_a("mover_esquerda"), _a("mover_direita"))
	var y: float = Input.get_axis(_a("mirar_cima"), _a("mirar_baixo"))
	direcao = Vector2i(_discretizar(x), _discretizar(y))
	pular_segurado = Input.is_action_pressed(_a("pular"))
	pular_pressionado = Input.is_action_just_pressed(_a("pular"))
	atirar_segurado = Input.is_action_pressed(_a("atirar"))
	atirar_pressionado = Input.is_action_just_pressed(_a("atirar"))
	dash_pressionado = Input.is_action_just_pressed(_a("dash"))
	travar_mira_segurado = Input.is_action_pressed(_a("travar_mira"))
	granada_pressionada = Input.is_action_just_pressed(_a("granada"))
	chamado_pressionado = Input.is_action_just_pressed(_a("chamado"))
	ferramenta_pressionada = Input.is_action_just_pressed(_a("ferramenta"))
	interagir_pressionado = Input.is_action_just_pressed(_a("interagir"))
	_atualizar_mira()


func _atualizar_mira() -> void:
	var analogico: Vector2 = Input.get_vector(_a("mira_esquerda"), _a("mira_direita"), _a("mira_cima"), _a("mira_baixo"))
	if analogico.length() >= ZONA_MORTA_MIRA:
		dispositivo = Dispositivo.GAMEPAD
		ultima_mira_analogica = analogico.normalized()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		dispositivo = Dispositivo.MOUSE
	var tela: Viewport = _viewport()
	if tela != null:
		var mouse: Vector2 = tela.get_mouse_position()
		if _ultimo_mouse != Vector2.INF and mouse.distance_to(_ultimo_mouse) >= MOVIMENTO_MINIMO_MOUSE:
			dispositivo = Dispositivo.MOUSE
		_ultimo_mouse = mouse
		ponto_mira = tela.get_canvas_transform().affine_inverse() * mouse
	match dispositivo:
		Dispositivo.NENHUM:
			mira_analogica = Vector2.ZERO
			mira_por_ponto = false
		Dispositivo.MOUSE:
			mira_analogica = Vector2.ZERO
			mira_por_ponto = tela != null
		Dispositivo.GAMEPAD:
			mira_por_ponto = false
			mira_analogica = ultima_mira_analogica


func _viewport() -> Viewport:
	var arvore := Engine.get_main_loop() as SceneTree
	return arvore.root if arvore != null else null


func _a(acao: String) -> StringName:
	return StringName(prefixo + acao)


func _discretizar(valor: float) -> int:
	if valor >= LIMIAR_ANALOGICO:
		return 1
	if valor <= -LIMIAR_ANALOGICO:
		return -1
	return 0
