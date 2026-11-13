extends Node
## Autoload "Dialogos": carrega o banco do VS e toca cenas na CaixaDialogo da cena atual.
## Uso: Dialogos.tocar("queda_grilhao")

signal cena_terminou(id_cena: String)

const ARQUIVO_VS: String = "res://data/dialogos/vs_varrek.json"

var banco: BancoDialogos = BancoDialogos.new()
var diretor: DiretorDialogo


func _ready() -> void:
	var erro: Error = banco.carregar(ARQUIVO_VS)
	if erro != OK:
		push_error("Diálogos: não foi possível carregar %s (%s)" % [ARQUIVO_VS, error_string(erro)])
	diretor = DiretorDialogo.new(banco, get_node("/root/Progresso") as DadosProgresso)


## Toca a cena, se ela puder tocar agora. Retorna true se tocou.
func tocar(id_cena: String) -> bool:
	var caixa := get_tree().get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	if caixa == null:
		return false
	var falas: Array[Dictionary] = diretor.preparar(id_cena)
	if falas.is_empty():
		return false
	caixa.mostrar(id_cena, falas, diretor.modo(id_cena), banco)
	if not caixa.terminou.is_connected(_ao_terminar):
		caixa.terminou.connect(_ao_terminar)
	return true


## Mostra uma cena sem mexer no progresso (sem flags nem "duvida"), para NAR, ART e QA
## revisarem as falas no jogo. Usa a primeira entrada de cada parte.
func previsualizar(id_cena: String) -> bool:
	var caixa := get_tree().get_first_node_in_group("caixa_dialogo") as CaixaDialogo
	if caixa == null or not banco.tem_cena(id_cena):
		return false
	var c: Dictionary = banco.cena(id_cena)
	var falas: Array[Dictionary] = []
	var fonte: Array = c.get("falas", [])
	if fonte.is_empty() and not c.get("prioridade", []).is_empty():
		fonte = c["prioridade"][0].get("falas", [])
	if fonte.is_empty() and not c.get("variantes", []).is_empty():
		fonte = c["variantes"][0]
	for f: Dictionary in fonte:
		falas.append(f)
	caixa.mostrar(id_cena, falas, "conversa", banco)
	return true


func _ao_terminar(id_cena: String) -> void:
	cena_terminou.emit(id_cena)
