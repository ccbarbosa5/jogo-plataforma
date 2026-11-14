extends Node
## Autoload "Ciclo": o caminho nave → cápsula → run → (morte ou vitória) → nave (GD-01 §9).
## Guarda o que passa de uma cena para a outra: a arma escolhida no Arsenal e o resultado da run.

const CENA_NAVE: String = "res://scenes/nave/nave_eco.tscn"
const CENA_RUN: String = "res://scenes/run/run_ato1.tscn"
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
	if trocar_cena:
		get_tree().change_scene_to_file.call_deferred(CENA_RUN)


## Fim da run: o que vale guardar da run vira flag salva, e a ECO reconstrói o Ryker na nave.
func voltar_para_nave(resultado_: String) -> void:
	resultado = resultado_
	ultima_run = Progresso.estado_run.duplicate()
	if Progresso.estado_run.get("pegou_vesh_na_run", false):
		Progresso.definir_flag("pegou_vesh_na_run")  # o Sete chega na Ponte (NAR-01)
	Progresso.salvar()
	if trocar_cena:
		get_tree().change_scene_to_file.call_deferred(CENA_NAVE)
