class_name EntradaLocal
extends EntradaJogador
## Lê teclado e gamepad pelas ações do Input Map (GD-01, seção 3).
## Co-op (D-018): cada jogador terá um EntradaLocal com o próprio `prefixo`
## ("" para o P1, "p2_" para o P2...), lendo ações ligadas só ao seu dispositivo.
## No protótipo só existe o P1, com as ações sem prefixo.

const LIMIAR_ANALOGICO: float = 0.5

var prefixo: String = ""


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


func _a(acao: String) -> StringName:
	return StringName(prefixo + acao)


func _discretizar(valor: float) -> int:
	if valor >= LIMIAR_ANALOGICO:
		return 1
	if valor <= -LIMIAR_ANALOGICO:
		return -1
	return 0
