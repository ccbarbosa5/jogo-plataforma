class_name ArmaEquipada
extends RefCounted
## A arma que o jogador leva na run (D-038, GD-07): os dados-base (DadosArma, escolhidos no
## Arsenal) mais os modificadores — nós do ramo da arma na árvore de Combate (permanentes) e as
## Gambiarras da run (somem na morte). Não existe troca de arma nem munição limitada.

signal mudou

var base: DadosArma
var modificadores: Array[ModificadorArma] = []
## Ids dos modificadores que vêm da árvore de Combate (não saem em limpar()).
var permanentes: Array[StringName] = []


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


## Nós da árvore de Combate: ficam até a próxima escolha na nave.
func adicionar_permanente(modificador: ModificadorArma) -> void:
	permanentes.append(modificador.id)
	adicionar(modificador)


## Fim da run: as Gambiarras somem; os nós da árvore de Combate ficam.
func limpar() -> void:
	for i in range(modificadores.size() - 1, -1, -1):
		if not modificadores[i].id in permanentes:
			modificadores.remove_at(i)
	mudou.emit()


## Quantas vezes o modificador `id` foi pego (Gambiarras acumuláveis).
func acumulos(id: StringName) -> int:
	var n: int = 0
	for m in modificadores:
		if m.id == id:
			n += 1
	return n


## Quantos modificadores têm o marcador (acumula).
func contar_marcador(marcador: StringName) -> int:
	var n: int = 0
	for m in modificadores:
		if marcador in m.marcadores:
			n += 1
	return n


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


func perfuracoes() -> int:
	var valor: int = 0
	for m in modificadores:
		valor += m.soma_perfuracoes
	return maxi(valor, 0)


func ricochetes() -> int:
	var valor: int = 0
	for m in modificadores:
		valor += m.soma_ricochetes
	return maxi(valor, 0)


func tamanho_projetil() -> float:
	var valor: float = 1.0
	for m in modificadores:
		valor *= m.mult_tamanho_projetil
	return valor


## px a partir dos quais o dano cai (0 = sem queda).
func queda_dano_px() -> float:
	if base.queda_dano_px <= 0.0:
		return 0.0
	var valor: float = base.queda_dano_px
	for m in modificadores:
		valor += m.soma_queda_px
	return valor


func projeteis_por_tiro() -> int:
	var valor: int = base.projeteis_por_tiro
	for m in modificadores:
		valor += m.soma_projeteis_por_tiro
	return maxi(valor, 1)
