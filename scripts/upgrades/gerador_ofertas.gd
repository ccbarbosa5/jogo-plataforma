class_name GeradorOfertas
extends RefCounted
## Monta a oferta de uma recompensa de facção (GD-01 §6.3): 3 opções da mesma facção,
## sem repetir upgrade que o jogador já tem, só os liberados, com raridade sorteada
## (Comum 70% / Raro 25% / Épico 5%; sala Elite garante Raro ou melhor).

const CHANCE_RARO: float = 0.25
const CHANCE_EPICO: float = 0.05
const OPCOES: int = 3


static func sortear_raridade(rng: RandomNumberGenerator, elite: bool = false) -> DadosUpgrade.Raridade:
	var x: float = rng.randf()
	if x < CHANCE_EPICO:
		return DadosUpgrade.Raridade.EPICO
	if x < CHANCE_EPICO + CHANCE_RARO or elite:
		return DadosUpgrade.Raridade.RARO
	return DadosUpgrade.Raridade.COMUM


static func gerar(catalogo: CatalogoFaccao, upgrades: UpgradesJogador, rng: RandomNumberGenerator,
		progresso: DadosProgresso = null, elite: bool = false, quantidade: int = OPCOES) -> Array[DadosUpgrade]:
	var candidatos: Array[DadosUpgrade] = []
	for modelo in catalogo.upgrades:
		if modelo.liberado(progresso) and not upgrades.tem(modelo.id) and upgrades.pode_receber(modelo):
			candidatos.append(modelo)
	var oferta: Array[DadosUpgrade] = []
	while oferta.size() < quantidade and not candidatos.is_empty():
		var modelo: DadosUpgrade = candidatos.pop_at(rng.randi_range(0, candidatos.size() - 1))
		oferta.append(modelo.com_raridade(sortear_raridade(rng, elite)))
	return oferta
