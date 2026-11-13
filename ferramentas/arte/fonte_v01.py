"""Fonte própria do No Rest (D-046): pixel 5×7 com acentos do português, gerada por código.

Saída (BMFont texto, que o Godot 4 importa como FontFile):
  assets/fontes/no_rest_5.fnt + .png      texto normal (célula 11 px de altura, linha 12)
  assets/fontes/no_rest_5_x2.fnt + .png   a mesma, com pixels dobrados, para placas e títulos
Uso: python3 ferramentas/arte/fonte_v01.py           (gera)
     python3 ferramentas/arte/fonte_v01.py --verificar (confere se cobre todo o texto de data/dialogos/*.json)
Glifos brancos: a cor vem do jogo (font_color / modulate). Sem licença de terceiros: a fonte é do estúdio.
"""
import glob, json, os, sys
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(AQUI, '..', '..'))
SAIDA = os.path.join(RAIZ, 'assets', 'fontes')

# Célula: linhas 0-1 = acento das maiúsculas; 2-8 = altura das maiúsculas (7); 9-10 = descendente.
ALTURA, LINHA, BASE = 11, 12, 9

# Maiúsculas, dígitos e sinais: 7 linhas (área das maiúsculas). '#' = pixel.
G7 = {
 'A': ".###./#...#/#...#/#####/#...#/#...#/#...#", 'B': "####./#...#/#...#/####./#...#/#...#/####.",
 'C': ".###./#...#/#..../#..../#..../#...#/.###.", 'D': "####./#...#/#...#/#...#/#...#/#...#/####.",
 'E': "#####/#..../#..../####./#..../#..../#####", 'F': "#####/#..../#..../####./#..../#..../#....",
 'G': ".###./#...#/#..../#.###/#...#/#...#/.####", 'H': "#...#/#...#/#...#/#####/#...#/#...#/#...#",
 'I': "###/.#./.#./.#./.#./.#./###", 'J': "..###/...#./...#./...#./#..#./#..#./.##..",
 'K': "#...#/#..#./#.#../##.../#.#../#..#./#...#", 'L': "#..../#..../#..../#..../#..../#..../#####",
 'M': "#...#/##.##/#.#.#/#.#.#/#...#/#...#/#...#", 'N': "#...#/##..#/#.#.#/#..##/#...#/#...#/#...#",
 'O': ".###./#...#/#...#/#...#/#...#/#...#/.###.", 'P': "####./#...#/#...#/####./#..../#..../#....",
 'Q': ".###./#...#/#...#/#...#/#.#.#/#..#./.##.#", 'R': "####./#...#/#...#/####./#.#../#..#./#...#",
 'S': ".####/#..../#..../.###./....#/....#/####.", 'T': "#####/..#../..#../..#../..#../..#../..#..",
 'U': "#...#/#...#/#...#/#...#/#...#/#...#/.###.", 'V': "#...#/#...#/#...#/#...#/#...#/.#.#./..#..",
 'W': "#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#", 'X': "#...#/#...#/.#.#./..#../.#.#./#...#/#...#",
 'Y': "#...#/#...#/.#.#./..#../..#../..#../..#..", 'Z': "#####/....#/...#./..#../.#.../#..../#####",
 '0': ".###./#...#/#..##/#.#.#/##..#/#...#/.###.", '1': ".#./##./.#./.#./.#./.#./###",
 '2': ".###./#...#/....#/...#./..#../.#.../#####", '3': "####./....#/....#/.###./....#/....#/####.",
 '4': "#...#/#...#/#...#/#####/....#/....#/....#", '5': "#####/#..../####./....#/....#/#...#/.###.",
 '6': ".###./#..../#..../####./#...#/#...#/.###.", '7': "#####/....#/...#./..#../..#../..#../..#..",
 '8': ".###./#...#/#...#/.###./#...#/#...#/.###.", '9': ".###./#...#/#...#/.####/....#/....#/.###.",
 '.': "./././././.#".replace('.#', '#'), '!': "#/#/#/#/#/./#", '?': ".###./#...#/....#/...#./..#../...../..#..",
 ':': "./././#/././#".replace('/./', '/./'), "'": "#/#/./././././", '"': "#.#/#.#/.../.../.../.../...",
 '-': "..../..../..../####/..../..../....", '—': "....../....../....../######/....../....../......",
 '–': "...../...../...../#####/...../...../.....", '…': "...../...../...../...../...../...../#.#.#",
 '(': ".#/#./#./#./#./#./.#", ')': "#./.#/.#/.#/.#/.#/#.", '[': "##/#./#./#./#./#./##", ']': "##/.#/.#/.#/.#/.#/##",
 '/': "....#/...#./...#./..#../.#.../.#.../#....", '\\': "#..../.#.../.#.../..#../...#./...#./....#",
 '+': "...../..#../..#../#####/..#../..#../.....", '=': "...../...../#####/...../#####/...../.....",
 '*': "...../#.#.#/.###./#####/.###./#.#.#/.....", '%': "##..#/##.#./...#./..#../.#.../.#.##/#..##",
 '#': ".#.#./#####/.#.#./.#.#./.#.#./#####/.#.#.", '&': ".##../#..#./#.#../.#.../#.#.#/#..#./.##.#",
 '<': "...#/..#./.#../#.../.#../..#./...#", '>': "#.../.#../..#./...#/..#./.#../#...",
 '_': "...../...../...../...../...../...../#####", '@': ".###./#...#/#.###/#.#.#/#.##./#..../.###.",
 '$': "..#../.####/#.#../.###./..#.#/####./..#..", '|': "#/#/#/#/#/#/#", '^': ".#./#.#/.../.../.../.../...",
 '~': "...../...../.#..#/#.##./...../...../.....", '`': "#./.#/../../../../..",
 '“': "#.#/#.#/.../.../.../.../...", '”': "#.#/#.#/.../.../.../.../...", '‘': "#/#/./././././", '’': "#/#/./././././",
 '«': "...../...../.#..#/#..#./.#..#/...../.....", '»': "...../...../#..#./.#..#/#..#./...../.....",
 'º': "###/#.#/###/.../###/.../...", 'ª': ".##/#.#/.##/.../###/.../...", '°': "###/#.#/###/.../.../.../...",
 '·': "./././#/./././", '¡': "#/./#/#/#/#/#", '¿': "..#../...../..#../.#.../#..../#...#/.###.",
}
G7['.'] = "./././././././#".replace('./././././././#', './././././.' + '/#')
G7['.'] = "././././././#"
G7[':'] = "././#/./././#"
# Sinais com parte abaixo da linha de base (7 linhas + 2 de descendente).
G9 = {
 ',': "../../../../../.#/.#/#./..", ';': "../../.#/../../.#/.#/#./..",
}
# Minúsculas: 7 linhas (as 2 de cima ficam vazias nas letras sem haste) + 2 de descendente.
G9.update({
 'a': "...../...../.###./....#/.####/#...#/.####/...../.....", 'b': "#..../#..../####./#...#/#...#/#...#/####./...../.....",
 'c': "...../...../.###./#..../#..../#..../.###./...../.....", 'd': "....#/....#/.####/#...#/#...#/#...#/.####/...../.....",
 'e': "...../...../.###./#...#/#####/#..../.###./...../.....", 'f': "..##/.#../###./.#../.#../.#../.#../..../....",
 'g': "...../...../.####/#...#/#...#/#...#/.####/....#/.###.", 'h': "#..../#..../####./#...#/#...#/#...#/#...#/...../.....",
 'i': ".#./.../##./.#./.#./.#./###/.../...", 'j': "..#/.../.##/..#/..#/..#/..#/#.#/.#.",
 'k': "#.../#.../#..#/#.#./##../#.#./#..#/..../....", 'l': "##./.#./.#./.#./.#./.#./###/.../...",
 'm': "...../...../##.#./#.#.#/#.#.#/#.#.#/#.#.#/...../.....", 'n': "...../...../####./#...#/#...#/#...#/#...#/...../.....",
 'o': "...../...../.###./#...#/#...#/#...#/.###./...../.....", 'p': "...../...../####./#...#/#...#/#...#/####./#..../#....",
 'q': "...../...../.####/#...#/#...#/#...#/.####/....#/....#", 'r': "...../...../#.##./##..#/#..../#..../#..../...../.....",
 's': "...../...../.####/#..../.###./....#/####./...../.....", 't': ".#../.#../###./.#../.#../.#../..##/..../....",
 'u': "...../...../#...#/#...#/#...#/#...#/.####/...../.....", 'v': "...../...../#...#/#...#/#...#/.#.#./..#../...../.....",
 'w': "...../...../#...#/#...#/#.#.#/#.#.#/.#.#./...../.....", 'x': "...../...../#...#/.#.#./..#../.#.#./#...#/...../.....",
 'y': "...../...../#...#/#...#/#...#/#...#/.####/....#/.###.", 'z': "...../...../#####/...#./..#../.#.../#####/...../.....",
 'ı': ".../.../##./.#./.#./.#./###/.../...",  # i sem pingo, base dos acentos
})

ACENTOS = {  # 2 linhas
    'agudo': ['..#', '.#.'], 'grave': ['#..', '.#.'], 'circ': ['.#.', '#.#'], 'til': ['.#.#', '#.#.'], 'trema': ['#.#', '...'],
}
COMPOSTOS = {
    'á': ('a', 'agudo'), 'à': ('a', 'grave'), 'â': ('a', 'circ'), 'ã': ('a', 'til'), 'ä': ('a', 'trema'),
    'é': ('e', 'agudo'), 'è': ('e', 'grave'), 'ê': ('e', 'circ'), 'ë': ('e', 'trema'),
    'í': ('ı', 'agudo'), 'ì': ('ı', 'grave'), 'î': ('ı', 'circ'), 'ï': ('ı', 'trema'),
    'ó': ('o', 'agudo'), 'ò': ('o', 'grave'), 'ô': ('o', 'circ'), 'õ': ('o', 'til'), 'ö': ('o', 'trema'),
    'ú': ('u', 'agudo'), 'ù': ('u', 'grave'), 'û': ('u', 'circ'), 'ü': ('u', 'trema'), 'ñ': ('n', 'til'),
    'Á': ('A', 'agudo'), 'À': ('A', 'grave'), 'Â': ('A', 'circ'), 'Ã': ('A', 'til'), 'Ä': ('A', 'trema'),
    'É': ('E', 'agudo'), 'È': ('E', 'grave'), 'Ê': ('E', 'circ'), 'Ë': ('E', 'trema'),
    'Í': ('I', 'agudo'), 'Ì': ('I', 'grave'), 'Î': ('I', 'circ'), 'Ï': ('I', 'trema'),
    'Ó': ('O', 'agudo'), 'Ò': ('O', 'grave'), 'Ô': ('O', 'circ'), 'Õ': ('O', 'til'), 'Ö': ('O', 'trema'),
    'Ú': ('U', 'agudo'), 'Ù': ('U', 'grave'), 'Û': ('U', 'circ'), 'Ü': ('U', 'trema'), 'Ñ': ('N', 'til'),
}
CEDILHA = {'ç': 'c', 'Ç': 'C'}


def _linhas(spec):
    return spec.split('/')


def glifo(ch):
    """Retorna a matriz ALTURA × largura (listas de 0/1) do caractere, ou None se não existe."""
    if ch == ' ':
        return [[0] * 3 for _ in range(ALTURA)]
    if ch in G7:
        rows = _linhas(G7[ch]); w = max(len(r) for r in rows)
        m = [[0] * w for _ in range(ALTURA)]
        for y, r in enumerate(rows):
            for x, c in enumerate(r):
                if c == '#': m[2 + y][x] = 1
        return m
    if ch in G9:
        rows = _linhas(G9[ch]); w = max(len(r) for r in rows)
        m = [[0] * w for _ in range(ALTURA)]
        for y, r in enumerate(rows):
            for x, c in enumerate(r):
                if c == '#': m[2 + y][x] = 1
        return m
    if ch in COMPOSTOS:
        base, ac = COMPOSTOS[ch]; m = [row[:] for row in glifo(base)]; w = len(m[0])
        a = ACENTOS[ac]; aw = len(a[0]); x0 = max(0, (w - aw + 1) // 2)
        topo = 0 if base.isupper() else 2  # maiúsculas: acima da letra; minúsculas: acima da altura-x
        if base.isupper():
            pass
        for y, r in enumerate(a):
            for x, c in enumerate(r):
                if c == '#' and 0 <= x0 + x < w: m[topo + y][x0 + x] = 1
        return m
    if ch in CEDILHA:
        m = [row[:] for row in glifo(CEDILHA[ch])]; w = len(m[0]); cx = w // 2
        m[9][cx] = 1; m[10][cx - 1] = 1
        return m
    return None


def caracteres():
    cs = [chr(c) for c in range(32, 127)]
    cs += list(COMPOSTOS) + list(CEDILHA) + [c for c in G7 if ord(c) > 126] + [c for c in G9 if ord(c) > 126 and c != 'ı']
    vistos, saida = set(), []
    for c in cs:
        if c not in vistos and glifo(c) is not None:
            vistos.add(c); saida.append(c)
    return saida


def gerar(escala=1, nome='no_rest_5'):
    cs = caracteres(); por_linha = 16; cel_w = 8 * escala; cel_h = (ALTURA + 1) * escala
    linhas = (len(cs) + por_linha - 1) // por_linha
    W = 1
    while W < por_linha * cel_w: W *= 2
    H = 1
    while H < linhas * cel_h: H *= 2
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0)); px = img.load()
    chars = []
    for i, ch in enumerate(cs):
        m = glifo(ch); gw = len(m[0])
        ox, oy = (i % por_linha) * cel_w, (i // por_linha) * cel_h
        for y in range(ALTURA):
            for x in range(gw):
                if m[y][x]:
                    for dy in range(escala):
                        for dx in range(escala):
                            px[ox + x * escala + dx, oy + y * escala + dy] = (255, 255, 255, 255)
        avanço = (gw + 1) * escala if ch != ' ' else 4 * escala
        chars.append(f'char id={ord(ch)} x={ox} y={oy} width={gw * escala} height={ALTURA * escala} '
                     f'xoffset=0 yoffset=0 xadvance={avanço} page=0 chnl=15')
    os.makedirs(SAIDA, exist_ok=True)
    img.save(os.path.join(SAIDA, f'{nome}.png'))
    cab = [f'info face="No Rest {5 * escala}" size={ALTURA * escala} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0',
           f'common lineHeight={LINHA * escala} base={BASE * escala} scaleW={W} scaleH={H} pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4',
           f'page id=0 file="{nome}.png"', f'chars count={len(chars)}']
    with open(os.path.join(SAIDA, f'{nome}.fnt'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(cab + chars) + '\n')
    return cs


def texto(img, xy, s, cor, escala=1):
    """Escreve com a fonte do No Rest numa imagem Pillow (usado nas telas de conferência)."""
    x, y = xy; px = img.load()
    for ch in s:
        m = glifo(ch) or glifo('?')
        for gy in range(ALTURA):
            for gx in range(len(m[0])):
                if m[gy][gx]:
                    for dy in range(escala):
                        for dx in range(escala):
                            X, Y = x + gx * escala + dx, y + gy * escala + dy
                            if 0 <= X < img.width and 0 <= Y < img.height: px[X, Y] = cor
        x += (len(m[0]) + 1) * escala if ch != ' ' else 4 * escala
    return x


def largura(s, escala=1):
    return sum(((len((glifo(c) or glifo('?'))[0]) + 1) if c != ' ' else 4) * escala for c in s)


def verificar():
    """Confere se a fonte cobre todo o texto dos diálogos do jogo. Sai com erro se faltar algum caractere."""
    cobertos = set(caracteres()); faltam = {}
    for arq in glob.glob(os.path.join(RAIZ, 'data', 'dialogos', '*.json')):
        conteudo = json.load(open(arq, encoding='utf-8'))
        def walk(o):
            if isinstance(o, dict):
                for v in o.values(): yield from walk(v)
            elif isinstance(o, list):
                for v in o: yield from walk(v)
            elif isinstance(o, str):
                yield o
        for s in walk(conteudo):
            for c in s:
                if c not in cobertos and c not in '\n\t': faltam.setdefault(c, os.path.basename(arq))
    obrigatorios = 'áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ'
    sem = [c for c in obrigatorios if c not in cobertos]
    print(f'{len(cobertos)} caracteres na fonte.')
    if sem: print('FALTAM obrigatórios do português:', ''.join(sem))
    if faltam: print('FALTAM caracteres usados nas falas:', faltam)
    if sem or faltam: sys.exit(1)
    print('OK: a fonte cobre todos os acentos do português e todo o texto dos diálogos.')


if __name__ == '__main__':
    if '--verificar' in sys.argv:
        verificar()
    else:
        cs = gerar(1, 'no_rest_5'); gerar(2, 'no_rest_5_x2')
        print(f'ok: {len(cs)} caracteres')
