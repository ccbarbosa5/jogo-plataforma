class_name ModificadorArma
extends Resource
## Muda o comportamento da arma (GD-07). Vem de dois lugares:
##  - nós dos ramos de arma da árvore de Combate (permanentes, escolhidos na nave);
##  - Gambiarras (só na run, 1 entre 3 ao limpar cada sala; somem na morte).
## Números somam e multiplicam; cada marcador é um comportamento com código em ControleArma.
## Uma Gambiarra acumulável pega duas vezes entra duas vezes (ArmaEquipada.acumulos()).

enum Raridade { COMUM, RARA, EPICA }

@export var id: StringName = &""
@export var nome: String = ""
@export_multiline var descricao: String = ""
## Gambiarras: raridade e quantas vezes pode acumular (1 = única).
@export var raridade: Raridade = Raridade.COMUM
@export var maximo: int = 1
## Arma a que pertence (&"mordida", &"bramido"; vazio = qualquer).
@export var arma: StringName = &""
## Multiplicadores (1 = sem mudança).
@export var mult_dano: float = 1.0
@export var mult_cadencia: float = 1.0
@export var mult_velocidade_projetil: float = 1.0
@export var mult_duracao_projetil: float = 1.0
@export var mult_tamanho_projetil: float = 1.0
## Somas.
@export var soma_dano: int = 0
@export var soma_projeteis_por_tiro: int = 0
@export var soma_espalhamento_graus: float = 0.0
@export var soma_perfuracoes: int = 0
@export var soma_ricochetes: int = 0
## px a mais antes da queda de dano (Bramido).
@export var soma_queda_px: float = 0.0
## Marcadores de comportamento novo (lista em ControleArma).
@export var marcadores: Array[StringName] = []
