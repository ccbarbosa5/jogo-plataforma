class_name Unidades
## Conversão das unidades de design para pixels.
## GD especifica distâncias e velocidades em *tiles*. O tamanho do tile ainda
## depende de ART; quando ART fechar, basta mudar TILE_PX aqui.

const TILE_PX: float = 16.0


static func px(tiles: float) -> float:
	return tiles * TILE_PX


static func em_tiles(pixels: float) -> float:
	return pixels / TILE_PX
