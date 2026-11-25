"""ART-9: chão da arena de Varrek (pacote 11A) -> 640x384 só com as cores escuras de cenário da paleta.
Uso: python3 -I ferramentas/arte/arena_chao.py ferramentas/arte/originais_ia/11A_arena_varrek_chao_v1.png assets/sprites/arena/varrek_chao.png /tmp/previa.png
(o tratar_ia.py puxava a areia para laranja vivo, a cor do Ryker; aqui só entram tons de cenário)."""
import sys
from PIL import Image
import numpy as np
orig, saida, previa = sys.argv[1:4]
cores = ["16111c","1e1424","20141d","2f1d28","3a1f30","4a2a33","6a3030","251f2b","2b2236","3a3340","5b5262","82391f"]
pal = np.array([[int(c[i:i+2],16) for i in (0,2,4)] for c in cores], float)
im = Image.open(orig).convert("RGB").resize((640,384), Image.BOX)
a = np.asarray(im, float)
d = ((a[:,:,None,:]-pal[None,None,:,:])**2).sum(-1)
out = pal[d.argmin(-1)].astype(np.uint8)
Image.fromarray(out).save(saida)
Image.fromarray(out).resize((1280,768), Image.NEAREST).save(previa)
print(len(np.unique(d.argmin(-1))), "cores")
