extends Node
## Autoload "Ciclo": o caminho menu inicial → nave → cápsula → run → (morte ou vitória) → nave (GD-01 §9).
## Guarda o que passa de uma cena para a outra: a arma escolhida no Arsenal e o resultado da run.

const CENA_TITULO: String = "res://scenes/ui/tela_titulo.tscn"
const CENA_NAVE: String = "res://scenes/nave/nave_eco.tscn"
const CENA_RUN: String = "res://scenes/run/run_ato1.tscn"
const CENA_ABERTURA: String = "res://scenes/ui/abertura_historia.tscn"
const ARMAS: Dictionary = {
	&"mordida": "res://scenes/armas/mordida.tres",
	&"bramido": "res://scenes/armas/bramido.tres",
}

## Arma escolhida no Arsenal para a próxima run.
var arma_escolhida: StringName = &"mordida"
## "" (abriu o jogo), "morte" ou "vitoria".
var resultado: String = ""
## Estado da run que acabou (a nave usa para as falas da reconstrução, ex.: usou_arvore).
var ultima_run: Dictionary = {}
## Os testes desligam a troca de cena.
var trocar_cena: bool = true
## D-073B: true = a abertura foi pedida pelo menu ("Ver abertura") e volta ao menu.
var abertura_rever: bool = false
## Última cena pedida (os testes conferem sem trocar de verdade).
var ultima_cena_pedida: String = ""


func dados_da_arma() -> DadosArma:
	return load(ARMAS.get(arma_escolhida, ARMAS[&"mordida"]))


func arma_liberada(id: StringName) -> bool:
	return id == &"mordida" or (id == &"bramido" and Progresso.tem_flag("bramido_liberado"))


func escolher_arma(id: StringName) -> bool:
	if not arma_liberada(id):
		return false
	arma_escolhida = id
	return true


func ir_para_run() -> void:
	resultado = ""
	_trocar(CENA_RUN)


## Menu inicial (D-053) → nave. "Novo jogo" apaga o progresso antes.
func ir_para_nave_do_titulo() -> void:
	resultado = ""
	_trocar(CENA_NAVE)


## D-073B: abertura da história. rever = pelo menu ("Ver abertura"), volta ao menu no fim.
func ir_para_abertura(rever: bool = false) -> void:
	resultado = ""
	abertura_rever = rever
	_trocar(CENA_ABERTURA)


## Pausa da nave → menu inicial.
func ir_para_titulo() -> void:
	_trocar(CENA_TITULO)


func _trocar(cena: String) -> void:
	ultima_cena_pedida = cena
	if trocar_cena:
		get_tree().change_scene_to_file.call_deferred(cena)


## Fim da run: o que vale guardar da run vira flag salva, e a ECO reconstrói o Ryker na nave.
func voltar_para_nave(resultado_: String) -> void:
	resultado = resultado_
	ultima_run = Progresso.estado_run.duplicate()
	if Progresso.estado_run.get("pegou_vesh_na_run", false):
		Progresso.definir_flag("pegou_vesh_na_run")  # o Sete chega na Ponte (NAR-01)
	Progresso.salvar()
	_trocar(CENA_NAVE)
