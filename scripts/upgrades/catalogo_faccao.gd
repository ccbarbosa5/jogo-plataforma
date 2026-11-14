class_name CatalogoFaccao
extends Resource
## Os upgrades de uma facção (GD-02 §6). Um arquivo .tres por facção em scenes/upgrades/.

@export var faccao: StringName = &""
@export var nome: String = ""
## Moldura da tela de oferta (MolduraDialogo).
@export var moldura: String = ""
## Cor do título e dos detalhes.
@export var cor: Color = Color.WHITE
## Cena de fala da patrona: "<cena>_primeira" na 1ª oferta, "<cena>_repeticao" depois (NAR-01).
@export var cena_falas: String = ""
@export var upgrades: Array[DadosUpgrade] = []
