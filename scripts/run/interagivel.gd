class_name Interagivel
extends Area2D
## Base das escolhas da run (D-066): portas de saída, portas de facção, estações de reparo e
## bancas da loja. **Encostar não pega:** perto dela aparecem o nome, o que dá e "E". Só o
## botão Interagir (E) ou um clique em cima dela pega. Com várias perto, E pega só a mais
## próxima do jogador.

const GRUPO: StringName = &"interagiveis"
const COR_NOME: Color = Color("eceff4")
const COR_DESCRICAO: Color = Color("a7adba")
const COR_TECLA: Color = Color("ffc95c")

## Área de toque (centrada no meio da área de baixo para cima, em px).
var tamanho_area: Vector2 = Vector2(24, 40)
var jogador_perto: Jogador


func _ready() -> void:
	add_to_group(GRUPO)
	collision_layer = 0
	collision_mask = Camadas.JOGADOR
	if get_child_count() == 0:
		var forma := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = tamanho_area
		forma.shape = r
		forma.position = Vector2(0, -tamanho_area.y / 2.0)
		add_child(forma)
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


# --- Para as subclasses ---

## Ainda pode ser escolhida?
func pode_interagir() -> bool:
	return true


## Pegou (E ou clique).
func interagir(_jogador: Jogador) -> void:
	pass


func titulo() -> String:
	return ""


func descricao() -> String:
	return ""


func texto_tecla() -> String:
	return "E: pegar"


# --- Proximidade ---

func esta_perto() -> bool:
	return jogador_perto != null and is_instance_valid(jogador_perto)


## A mais próxima do jogador entre as que ele está tocando (E pega só ela).
static func mais_proxima(jogador: Jogador) -> Interagivel:
	var melhor: Interagivel = null
	var menor: float = INF
	for no in jogador.get_tree().get_nodes_in_group(GRUPO):
		var i := no as Interagivel
		if i == null or i.jogador_perto != jogador or not i.pode_interagir() or i.is_queued_for_deletion():
			continue
		var d: float = absf(i.global_position.x - jogador.global_position.x)
		if d < menor:
			menor = d
			melhor = i
	return melhor


## Esta é a escolhida se o jogador apertar E agora?
func e_a_vez() -> bool:
	return esta_perto() and pode_interagir() and mais_proxima(jogador_perto) == self


func _ao_entrar(corpo: Node2D) -> void:
	var jogador := corpo as Jogador
	if jogador == null:
		return
	jogador_perto = jogador
	if not jogador.interagiu.is_connected(_ao_interagir):
		jogador.interagiu.connect(_ao_interagir)


func _ao_sair(corpo: Node2D) -> void:
	if corpo != jogador_perto:
		return
	if jogador_perto.interagiu.is_connected(_ao_interagir):
		jogador_perto.interagiu.disconnect(_ao_interagir)
	jogador_perto = null


func _exit_tree() -> void:
	if esta_perto() and jogador_perto.interagiu.is_connected(_ao_interagir):
		jogador_perto.interagiu.disconnect(_ao_interagir)
	jogador_perto = null


func _ao_interagir(jogador: Jogador) -> void:
	if jogador.esta_morto() or not pode_interagir() or mais_proxima(jogador) != self:
		return
	interagir.call_deferred(jogador)


## Clique em cima dela (D-065/D-066), com o jogador perto.
func _unhandled_input(evento: InputEvent) -> void:
	var clique := evento as InputEventMouseButton
	if clique == null or not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return
	if not esta_perto() or not pode_interagir() or get_tree().paused:
		return
	var area := Rect2(global_position - Vector2(tamanho_area.x / 2.0, tamanho_area.y + 24.0),
			Vector2(tamanho_area.x, tamanho_area.y + 24.0))
	var ponto: Vector2 = get_canvas_transform().affine_inverse() * clique.position
	if area.has_point(ponto):
		get_viewport().set_input_as_handled()
		interagir.call_deferred(jogador_perto)


## Nome, efeito e tecla, desenhados acima da escolha (só a que E pegaria agora).
func desenhar_dica(y: float) -> void:
	if not e_a_vez():
		return
	var fonte: Font = Fontes.pequena()
	var tam: int = Fontes.TAMANHO_PEQUENA
	var linhas: Array[Array] = []
	if not titulo().is_empty():
		linhas.append([titulo(), COR_NOME])
	if not descricao().is_empty():
		linhas.append([descricao(), COR_DESCRICAO])
	linhas.append([texto_tecla(), COR_TECLA])
	var altura: float = fonte.get_height(tam)
	var largura: float = 0.0
	for l in linhas:
		largura = maxf(largura, fonte.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x)
	var topo: float = y - altura * linhas.size()
	draw_rect(Rect2(-largura / 2.0 - 3.0, topo - 2.0, largura + 6.0, altura * linhas.size() + 3.0), Color(0.06, 0.05, 0.08, 0.8))
	for k in linhas.size():
		draw_string(fonte, Vector2(-largura / 2.0, topo + altura * (k + 1) - 2.0), linhas[k][0],
				HORIZONTAL_ALIGNMENT_LEFT, -1, tam, linhas[k][1])
