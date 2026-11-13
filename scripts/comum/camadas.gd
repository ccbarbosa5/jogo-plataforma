class_name Camadas
## Bits das camadas de física 2D (nomes em Project Settings > Layer Names > 2D Physics).

const MUNDO: int = 1 << 0             ## camada 1: chão, paredes, blocos sólidos
const JOGADOR: int = 1 << 1           ## camada 2
const INIMIGOS: int = 1 << 2          ## camada 3
const PROJETEIS_JOGADOR: int = 1 << 3 ## camada 4
const PROJETEIS_INIMIGO: int = 1 << 4 ## camada 5
const PLATAFORMAS: int = 1 << 5       ## camada 6: plataformas de mão única (dá para atravessar por baixo)
const GANCHOS: int = 1 << 6           ## camada 7: pontos onde o Grilhão engata
const PONTOS_FRACOS: int = 1 << 7     ## camada 8: hitbox de ponto fraco dos inimigos
