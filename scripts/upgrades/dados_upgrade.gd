class_name DadosUpgrade
extends Resource
## Um upgrade de facção (GD-02, seção 6). Os efeitos entram na Fase 2;
## por enquanto o sistema guarda slots, raridade e pré-requisitos.

enum Slot { TIRO, GRANADA, DASH, FERRAMENTA, CHAMADO, PASSIVO }
enum Raridade { COMUM, RARO, EPICO }

@export var id: StringName = &""
@export var nome: String = ""
@export var faccao: StringName = &""
@export var slot: Slot = Slot.PASSIVO
@export var raridade: Raridade = Raridade.COMUM
## IDs de upgrades que o jogador precisa ter antes (Upgrades de Aliança, GD-02 6.4).
@export var requisitos: Array[StringName] = []
@export_multiline var descricao: String = ""


static func criar(id_: StringName, slot_: Slot, faccao_: StringName = &"", requisitos_: Array[StringName] = []) -> DadosUpgrade:
	var u := DadosUpgrade.new()
	u.id = id_
	u.slot = slot_
	u.faccao = faccao_
	u.requisitos = requisitos_
	return u
