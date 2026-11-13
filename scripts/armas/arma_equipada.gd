class_name ArmaEquipada
extends RefCounted
## A arma que o jogador leva na run (D-038): os dados-base (DadosArma, escolhidos no Arsenal)
## mais os modificadores ganhos na run (mini árvore de habilidades).
## Não existe troca de arma durante a run nem munição limitada.
## Os modificadores zeram ao fim da run (limpar()).

signal mudou

var base: DadosArma
var modificadores: Array[ModificadorArma] = []


func _init(dados: DadosArma = null) -> void:
	base = dados


func adicionar(modificador: ModificadorArma) -> void:
	modificadores.append(modificador)
	mudou.emit()


func remover(id: StringName) -> void:
	for i in range(modificadores.size() - 1, -1, -1):
		if modificadores[i].id == id:
			modificadores.remove_at(i)
	mudou.emit()


## Fim da run: a árvore volta ao zero.
func limpar() -> void:
	modificadores.clear()
	mudou.emit()


func tem_marcador(marcador: StringName) -> bool:
	for m in modificadores:
		if marcador in m.marcadores:
			return true
	return false


func nome() -> String:
	return base.nome if base != null else ""


func dano() -> int:
	var valor: float = base.dano
	for m in modificadores:
		valor += m.soma_dano
	for m in modificadores:
		valor *= m.mult_dano
	return maxi(roundi(valor), 0)


func cadencia() -> float:
	var valor: float = base.cadencia
	for m in modificadores:
		valor *= m.mult_cadencia
	return maxf(valor, 0.01)


## tiles/s
func velocidade_projetil() -> float:
	var valor: float = base.velocidade_projetil
	for m in modificadores:
		valor *= m.mult_velocidade_projetil
	return valor


func duracao_projetil() -> float:
	var valor: float = base.duracao_projetil
	for m in modificadores:
		valor *= m.mult_duracao_projetil
	return valor


func espalhamento_graus() -> float:
	var valor: float = base.espalhamento_graus
	for m in modificadores:
		valor += m.soma_espalhamento_graus
	return maxf(valor, 0.0)


func projeteis_por_tiro() -> int:
	var valor: int = base.projeteis_por_tiro
	for m in modificadores:
		valor += m.soma_projeteis_por_tiro
	return maxi(valor, 1)
