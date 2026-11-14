class_name DadosUpgrade
extends Resource
## Um upgrade de facção (GD-02 §6, GD-01 §6). O catálogo de cada facção guarda um modelo de
## cada upgrade; a oferta cria uma cópia com a raridade sorteada (com_raridade).
## A raridade muda o VALOR do efeito, não o efeito (Comum / Raro / Épico).
## O efeito de cada id está em EfeitosUpgrades.

enum Slot { TIRO, GRANADA, DASH, FERRAMENTA, CHAMADO, PASSIVO }
enum Raridade { COMUM, RARO, EPICO }

const NOMES_SLOT: Array[String] = ["Tiro", "Granada", "Dash", "Ferramenta", "Chamado", "Passivo"]
const NOMES_RARIDADE: Array[String] = ["Comum", "Raro", "Épico"]

@export var id: StringName = &""
@export var nome: String = ""
@export var faccao: StringName = &""
@export var slot: Slot = Slot.PASSIVO
@export var raridade: Raridade = Raridade.COMUM
## IDs de upgrades que o jogador precisa ter antes (Upgrades de Aliança, GD-06).
@export var requisitos: Array[StringName] = []
## Texto com {v} no lugar do valor da raridade (ex.: "+{v}% de dano").
@export_multiline var descricao: String = ""
## Valor principal por raridade: [Comum, Raro, Épico].
@export var valores: Array[float] = [0.0, 0.0, 0.0]
## Números fixos do efeito (raio, Abalo, duração...), iguais em todas as raridades.
@export var extras: Dictionary = {}
## Bloqueado no começo do jogo: liberado pelos Arquivos (flag "arquivo_<id>", GD-03).
@export var bloqueado_no_inicio: bool = false


static func criar(id_: StringName, slot_: Slot, faccao_: StringName = &"", requisitos_: Array[StringName] = []) -> DadosUpgrade:
	var u := DadosUpgrade.new()
	u.id = id_
	u.slot = slot_
	u.faccao = faccao_
	u.requisitos = requisitos_
	return u


## Cópia deste modelo com a raridade escolhida.
func com_raridade(r: Raridade) -> DadosUpgrade:
	var u: DadosUpgrade = duplicate()
	u.raridade = r
	return u


func valor() -> float:
	return valores[raridade] if raridade < valores.size() else 0.0


func extra(chave: String, padrao: float = 0.0) -> float:
	return float(extras.get(chave, padrao))


func liberado(progresso: DadosProgresso) -> bool:
	return not bloqueado_no_inicio or (progresso != null and progresso.tem_flag("arquivo_" + String(id)))


## Descrição com o valor da raridade no lugar de {v}.
func texto() -> String:
	var v: float = valor()
	var mostrado: String
	if v > 0.0 and v < 1.0:
		mostrado = str(roundi(v * 100.0))
	else:
		mostrado = str(roundi(v))
	var t: String = descricao.replace("{v}", mostrado)
	# Couro de Arena: Comum não recarrega; Raro e Épico recarregam em {v} s.
	if extras.has("complemento") and v > 0.0:
		t += " Recarrega em %s s." % mostrado
	return t
