extends Node
## Autoload "Combate": regras globais e as fichas de ataque.
##
## Fichas de ataque (GD-02, seção 4.5; D-026): no máximo `teto_ataques_anunciados`
## inimigos podem estar anunciando ou executando um ataque ao mesmo tempo.
## O inimigo pede uma ficha antes do aviso e devolve quando o ataque termina,
## quando é atordoado ou quando morre. Sem ficha, ele espera.

const CAMINHO_REGRAS: String = "res://scenes/comum/regras_combate.tres"

var regras: RegrasCombate
var _portadores: Array[Node] = []


func _init() -> void:
	# Carrega já na criação (antes do _ready), para valer desde o primeiro frame.
	regras = load(CAMINHO_REGRAS) as RegrasCombate
	if regras == null:
		regras = RegrasCombate.new()


func pedir_ficha(inimigo: Node) -> bool:
	_limpar()
	if inimigo in _portadores:
		return true
	if _portadores.size() >= regras.teto_ataques_anunciados:
		return false
	_portadores.append(inimigo)
	return true


func devolver_ficha(inimigo: Node) -> void:
	_portadores.erase(inimigo)


func tem_ficha(inimigo: Node) -> bool:
	return inimigo in _portadores


func fichas_em_uso() -> int:
	_limpar()
	return _portadores.size()


## Zera tudo (troca de sala, testes).
func reiniciar() -> void:
	_portadores.clear()


func _limpar() -> void:
	for i in range(_portadores.size() - 1, -1, -1):
		var no: Node = _portadores[i]
		if not is_instance_valid(no) or no.is_queued_for_deletion() or not no.is_inside_tree():
			_portadores.remove_at(i)
