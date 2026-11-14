class_name ArvoreRun
extends RefCounted
## A árvore de UMA arma durante a run (GD-05 §2):
## - nós de um ramo em ordem (1 → 2 → Ápice), custando 1, 2 e 3 pontos;
## - só 1 Ápice por run: comprar um tranca os outros dois;
## - pontos podem ser guardados; tudo zera ao fim da run (morte ou vitória).
## Cada nó comprado vira um ModificadorArma na ArmaEquipada.

signal mudou

enum Estado { TRANCADO, DISPONIVEL, COMPRADO, BLOQUEADO }

var arma: ArmaEquipada
var pontos: int = 0
## Nível já comprado em cada ramo (0 = nenhum, 3 = ramo completo).
var niveis: Array[int] = [0, 0, 0]
## Ramo cujo Ápice foi comprado (-1 = nenhum).
var ramo_apice: int = -1
## Pontos ganhos na run (HUD e teste; não volta quando se gasta).
var pontos_ganhos: int = 0


func _init(arma_: ArmaEquipada = null) -> void:
	arma = arma_


func dados() -> DadosArvore:
	return arma.base.arvore if arma != null and arma.base != null else null


func ganhar_pontos(n: int = 1) -> void:
	pontos += n
	pontos_ganhos += n
	mudou.emit()


func estado(ramo: int, nivel: int) -> Estado:
	if niveis[ramo] > nivel:
		return Estado.COMPRADO
	if nivel == DadosArvore.NOS_POR_RAMO - 1 and ramo_apice >= 0 and ramo_apice != ramo:
		return Estado.BLOQUEADO
	if niveis[ramo] == nivel:
		return Estado.DISPONIVEL
	return Estado.TRANCADO


## true se o nó é o próximo do ramo, não está bloqueado e há pontos.
func pode_comprar(ramo: int, nivel: int) -> bool:
	return dados() != null and estado(ramo, nivel) == Estado.DISPONIVEL and pontos >= DadosArvore.custo(nivel)


func comprar(ramo: int, nivel: int) -> bool:
	if not pode_comprar(ramo, nivel):
		return false
	pontos -= DadosArvore.custo(nivel)
	niveis[ramo] = nivel + 1
	if nivel == DadosArvore.NOS_POR_RAMO - 1:
		ramo_apice = ramo
	arma.adicionar(dados().no(ramo, nivel))
	mudou.emit()
	return true


func comprados() -> int:
	return niveis[0] + niveis[1] + niveis[2]


## Fim da run (morte ou vitória): árvore, modificadores e pontos voltam ao zero.
func limpar() -> void:
	pontos = 0
	pontos_ganhos = 0
	niveis = [0, 0, 0]
	ramo_apice = -1
	if arma != null:
		arma.limpar()
	mudou.emit()
