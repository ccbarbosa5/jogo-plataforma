"""Gera a prancha de estilo v0.1 do departamento de Arte.
Saídas: paleta.png, sprites (1x), mockup_varrek_480x270.png, prancha_estilo_v01.png
"""
from PIL import Image, ImageDraw, ImageFont
import math, random, os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'sprites', 'conceito')
random.seed(7)

# ---------------- PALETA ----------------
PAL = {
    # contorno
    'k': ('#16111c', 'Contorno'), 'K': ('#2b2236', 'Sombra profunda'),
    # humanos / Ryker
    'o': ('#c4652e', 'Macacão'), 'O': ('#82391f', 'Macacão sombra'), 'h': ('#eba35c', 'Macacão luz'),
    's': ('#dca07a', 'Pele'), 'S': ('#a0644a', 'Pele sombra'), 'c': ('#33241f', 'Cabelo'),
    'b': ('#3d4c60', 'Lona azul'), 'B': ('#263142', 'Lona sombra'),
    'm': ('#5e6370', 'Metal'), 'M': ('#a4abb6', 'Metal luz'),
    'x': ('#4b4753', 'Arma'), 'X': ('#7d7886', 'Arma luz'),
    # Kharn
    'g': ('#56604a', 'Kharn pele'), 'G': ('#363d30', 'Kharn sombra'), 'l': ('#7c8a6c', 'Kharn luz'),
    'w': ('#dccfae', 'Osso'), 'W': ('#9d9175', 'Osso sombra'),
    'e': ('#9c3527', 'Pintura de guerra'), 'f': ('#ff5a2e', 'Energia Kharn'),
    # Vesh
    'v': ('#4c2c5e', 'Quitina'), 'V': ('#2b1838', 'Quitina sombra'), 'p': ('#7d4c90', 'Quitina luz'),
    'z': ('#a3e23c', 'Ácido'), 'Z': ('#57901f', 'Ácido escuro'), 'u': ('#b8d4e0', 'Asa'),
    # especiais
    'a': ('#ffc95c', 'Âmbar (ECO)'),
    'n': ('#4fb0a6', 'Antigos'), 'N': ('#2a6a66', 'Antigos sombra'),
    'y': ('#fff3a0', 'AVISO (reservada)'), 't': ('#dff8ff', 'Tiro do jogador'),
}
def rgb(ch):
    hx = PAL[ch][0].lstrip('#')
    return tuple(int(hx[i:i+2], 16) for i in (0, 2, 4)) + (255,)

ENV = {  # cores só de cenário (baixa saturação, ficam atrás)
    'ceu0': '#1e1424', 'ceu1': '#3a1f30', 'ceu2': '#6a3030', 'ceu3': '#a2523a', 'ceu4': '#c9773f',
    'longe': '#4a2a33', 'meio': '#2f1d28', 'perto': '#20141d',
    'chao': '#3a3340', 'chao_luz': '#5b5262', 'chao_sombra': '#251f2b',
}
def hx(c):
    c = c.lstrip('#'); return tuple(int(c[i:i+2], 16) for i in (0, 2, 4)) + (255,)

# ---------------- SPRITES EM ASCII ----------------
def from_ascii(txt, h=None):
    rows = [r for r in txt.strip('\n').split('\n')]
    w = max(len(r) for r in rows)
    H = h or len(rows)
    img = Image.new('RGBA', (w, H), (0, 0, 0, 0))
    off = H - len(rows)  # alinha pelos pés
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.' and ch != ' ':
                img.putpixel((x, y + off), rgb(ch))
    return img

RYKER = """
......kkkk..............
.....kcccck.............
....kcccccck............
...akccccssk............
...kkccsssksk...........
....kcssssssk...........
.....kSssssk............
.....kkSSSkk............
....kOooooohk...........
...kOoooooohhk..........
...kOookooohok..........
..kSkOoooooohkkkkkkkkk..
..ksSkOooooohsSXXXXXXXk.
..kMmkOooooksSkxxxkxkk..
..kmkkOOoooOkkkkkk.k....
...km.kOOOOOk...........
...km.kkbbbkk...........
....m.kbbbbbk...........
.....kbbBbbbk...........
.....kbBkkbbk...........
....kbBk.kbbk...........
....kbBk.kbbk...........
....kbBk..kbbk..........
....kbBk..kbbk..........
...kOOOk..kOOk..........
...kOOOOk.kOOOk.........
...kkkkkk.kkkkkk........
"""

ZANGAO = """
..u.....u...
.uuu...uuu..
..uukkkuu...
...kvvvk....
..kvpppvk...
.kvpaapvzk..
.kvvppvvzk..
..kvvvvzk...
...kZzzk....
....kzk.....
.....k......
"""

CUSPIDOR = """
......kkkkk.........
....kkvvvvvkk.......
...kvppppvvvvk......
..kvpzzzzpvvvvk.....
..kvzzZzzzvvvvvkk...
.kvvzZZzzvvvvvvvak..
.kvvvzzzvvvvvvvvvk..
..kVvvvvvvvvvvvVk...
...kVkVkVkVkVkVk....
...k.k.k.k.k.k.k....
"""

# ---------------- UTIL ----------------
def outline(img, col='k'):
    """Contorno de 1 px por fora da silhueta."""
    w, h = img.size
    out = img.copy(); px = img.load(); c = rgb(col)
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx, ny = x+dx, y+dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny][:3] != c[:3]:
                        out.putpixel((x, y), c); break
    return out

def shade_lower(img, base, shadow, frac):
    """Pinta com 'shadow' os pixels 'base' na parte inferior-esquerda de cada coluna (luz vem de cima-direita)."""
    w, h = img.size; px = img.load(); b = rgb(base); s = rgb(shadow)
    for x in range(w):
        ys = [y for y in range(h) if px[x, y] == b]
        if not ys: continue
        cut = int(len(ys) * (1 - frac))
        for y in ys[cut:]:
            px[x, y] = s
    return img

# ---------------- GUERREIRO DE CLÃ (KHARN), 32x64 de corpo ----------------
def guerreiro_kharn():
    W, H = 44, 64
    im = Image.new('RGBA', (W, H), (0,0,0,0)); d = ImageDraw.Draw(im)
    g, G, l, w, Wc, e, f, x, X = (rgb(c) for c in 'gGlwWefxX')
    # cauda
    d.polygon([(8,44),(0,58),(2,60),(12,50)], fill=G)
    # pernas (digitígradas)
    d.polygon([(10,44),(20,44),(18,54),(22,62),(10,62),(13,54)], fill=G)
    d.polygon([(20,44),(30,44),(28,54),(32,62),(20,62),(23,54)], fill=g)
    # torso curvado para frente
    d.ellipse((4,14,32,50), fill=g)
    # cabeça pequena projetada para frente + mandíbula
    d.ellipse((24,8,36,20), fill=g)
    d.polygon([(30,16),(38,15),(37,19),(29,20)], fill=G)
    d.point((33,12), fill=f)  # olho brasa
    # placa de ombro de osso (Ossoferro) e espinhos
    d.ellipse((5,12,22,27), fill=w)
    d.polygon([(6,12),(4,4),(10,11)], fill=w); d.polygon([(13,10),(13,2),(17,10)], fill=w)
    d.polygon([(19,12),(22,5),(23,13)], fill=Wc)
    # armadura frontal (placa de osso e ferro no peito)
    d.rectangle((25,22,32,42), fill=x); d.rectangle((26,23,31,30), fill=w); d.rectangle((26,32,31,41), fill=Wc)
    # pintura de guerra
    d.line((8,30,14,36), fill=e); d.line((8,34,12,38), fill=e)
    # braço-canhão
    d.rectangle((22,28,38,35), fill=x); d.rectangle((23,28,38,29), fill=X)
    d.rectangle((38,27,42,36), fill=x); d.rectangle((40,30,42,33), fill=f)
    # mão/garra de apoio
    d.polygon([(14,40),(20,40),(22,46),(14,46)], fill=G)
    shade_lower(im, 'g', 'G', 0.35)
    shade_lower(im, 'w', 'W', 0.3)
    # luz de topo no torso
    for xx in range(24, 31):
        if im.getpixel((xx, 15))[3]: im.putpixel((xx, 15), l)
    return outline(im)

# ---------------- CENÁRIO 480x270 ----------------
def bayer(x, y):
    m = [[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]]
    return m[y % 4][x % 4] / 16

def ceu(img):
    stops = [(0, 'ceu0'), (60, 'ceu1'), (120, 'ceu2'), (165, 'ceu3'), (200, 'ceu4')]
    px = img.load()
    for y in range(270):
        for i in range(len(stops)-1):
            y0, c0 = stops[i]; y1, c1 = stops[i+1]
            if y0 <= y < y1: break
        else:
            y0, c0, y1, c1 = 200, 'ceu4', 270, 'ceu4'
        t = (y - y0) / max(1, (y1 - y0))
        for x in range(480):
            px[x, y] = hx(ENV[c1] if t > bayer(x, y) else ENV[c0])

def anel_portal(img):
    """Anel quebrado da rede dos Antigos no céu (D-021): pista visual do mundo."""
    d = ImageDraw.Draw(img); cx, cy, r = 340, 70, 105
    sil = hx('#3b2236'); lit = rgb('n'); dim = rgb('N')
    for ang in range(0, 3600):
        a = ang / 10
        if 300 < a < 345: continue  # quebra
        for rr in range(r - 6, r + 1):
            x = cx + rr * math.cos(math.radians(a)); y = cy + rr * math.sin(math.radians(a))
            if 0 <= x < 480 and 0 <= y < 270: img.putpixel((int(x), int(y)), sil)
    for a in range(0, 360, 15):
        if 300 < a < 345: continue
        x = cx + (r - 3) * math.cos(math.radians(a)); y = cy + (r - 3) * math.sin(math.radians(a))
        if 0 <= x < 480 and 0 <= y < 270:
            img.putpixel((int(x), int(y)), lit if a % 45 == 0 else dim)
    # fragmentos soltos
    for (fx, fy, s) in [(424, 22, 5), (436, 40, 3), (446, 14, 2), (412, 4, 3)]:
        d.rectangle((fx, fy, fx + s, fy + s // 2 + 1), fill=sil)

def silhuetas(img, base_y, amp, cor, seed, step=(10, 30)):
    rnd = random.Random(seed); d = ImageDraw.Draw(img)
    x = -10; pts = [(-10, 270)]
    while x < 500:
        w = rnd.randint(*step); y = base_y - rnd.randint(0, amp)
        tipo = rnd.random()
        if tipo < 0.3:   # proa inclinada
            pts += [(x, y + 10), (x + w, y)]
        elif tipo < 0.6: # casco reto com antena
            pts += [(x, y), (x + w // 2, y), (x + w // 2, y - 12), (x + w // 2 + 2, y - 12), (x + w // 2 + 2, y), (x + w, y)]
        else:            # costela de casco
            pts += [(x, y), (x + 3, y - 8), (x + 6, y), (x + w, y + 4)]
        x += w
    pts += [(500, 270)]
    d.polygon(pts, fill=hx(cor))

def chao(img, y0=222):
    d = ImageDraw.Draw(img)
    for tx in range(0, 480, 16):
        for ty in range(y0, 270, 16):
            d.rectangle((tx, ty, tx + 15, ty + 15), fill=hx(ENV['chao']))
            if ty == y0:
                d.line((tx, ty, tx + 15, ty), fill=hx(ENV['chao_luz']))
                d.point((tx + 2, ty + 3), fill=hx(ENV['chao_luz'])); d.point((tx + 13, ty + 3), fill=hx(ENV['chao_luz']))
            d.line((tx, ty + 15, tx + 15, ty + 15), fill=hx(ENV['chao_sombra']))
            d.line((tx + 15, ty, tx + 15, ty + 15), fill=hx(ENV['chao_sombra']))
    d.line((0, y0 - 1, 480, y0 - 1), fill=rgb('k'))

def plataforma(img, x0, y0, n):
    d = ImageDraw.Draw(img)
    for i in range(n):
        x = x0 + i * 16
        d.rectangle((x, y0, x + 15, y0 + 7), fill=hx(ENV['chao']))
        d.line((x, y0, x + 15, y0), fill=hx(ENV['chao_luz']))
        d.line((x, y0 + 7, x + 15, y0 + 7), fill=rgb('k'))
    d.line((x0 - 1, y0, x0 - 1, y0 + 7), fill=rgb('k')); d.line((x0 + n * 16, y0, x0 + n * 16, y0 + 7), fill=rgb('k'))

def hud(img):
    d = ImageDraw.Draw(img)
    # 4 blocos de vida = 4 elos de corrente (3 cheios, 1 perdido)
    for i in range(4):
        x = 8 + i * 13; cheio = i < 3
        d.rectangle((x, 8, x + 10, 15), outline=rgb('k'), fill=rgb('M') if cheio else rgb('K'))
        d.rectangle((x + 3, 10, x + 7, 13), fill=rgb('k'))
        if cheio: d.line((x + 1, 9, x + 9, 9), fill=(255, 255, 255, 255))
    # barra de Chamado
    d.rectangle((8, 19, 60, 22), outline=rgb('k'), fill=rgb('K')); d.rectangle((9, 20, 40, 21), fill=rgb('a'))
    # granadas
    for i in range(3):
        d.ellipse((66 + i * 7, 9, 71 + i * 7, 15), fill=rgb('x'), outline=rgb('k'))

def mockup(sprites):
    img = Image.new('RGBA', (480, 270))
    ceu(img); anel_portal(img)
    silhuetas(img, 175, 25, ENV['longe'], 1, (14, 34))
    silhuetas(img, 200, 30, ENV['meio'], 2, (20, 46))
    chao(img); plataforma(img, 176, 174, 5)
    ry, kh, zg, cp = sprites
    img.alpha_composite(ry, (110, 222 - ry.size[1]))
    kx = 330
    # Kharn virado para a esquerda, mirando Ryker
    khf = kh.transpose(Image.FLIP_LEFT_RIGHT); img.alpha_composite(khf, (kx, 222 - kh.size[1]))
    # aviso do canhão: brilho + flash reservado
    d = ImageDraw.Draw(img)
    mx, my = kx + 1, 222 - kh.size[1] + 31
    d.ellipse((mx - 4, my - 4, mx + 4, my + 4), fill=rgb('y')); d.ellipse((mx - 2, my - 2, mx + 2, my + 2), fill=(255,255,255,255))
    # tiros inimigos (lentos, grandes, com contorno) e do jogador (finos)
    for bx in (250, 275):
        d.ellipse((bx - 3, my - 3, bx + 3, my + 3), fill=rgb('f'), outline=rgb('k'))
    for bx in (140, 160, 180):
        d.rectangle((bx, 222 - 20, bx + 5, 222 - 19), fill=rgb('t'))
    # Vesh
    for (zx, zy) in [(268, 96), (286, 84), (304, 102), (276, 118)]:
        img.alpha_composite(zg, (zx, zy))
    img.alpha_composite(cp.transpose(Image.FLIP_LEFT_RIGHT), (214, 174 - cp.size[1]))
    # poça de ácido
    d.rectangle((60, 220, 84, 221), fill=rgb('z')); d.point((66, 219), fill=rgb('z')); d.point((78, 219), fill=rgb('Z'))
    hud(img)
    return img

# ---------------- MONTAGEM ----------------
def up(im, s): return im.resize((im.size[0] * s, im.size[1] * s), Image.NEAREST)

def font(sz):
    for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf']:
        if os.path.exists(p): return ImageFont.truetype(p, sz)
    return ImageFont.load_default(size=sz)

def main():
    ry = from_ascii(RYKER, 32); zg = from_ascii(ZANGAO, 12); cp = from_ascii(CUSPIDOR, 14)
    kh = guerreiro_kharn()
    for nome, im in [('ryker_idle', ry), ('kharn_guerreiro', kh), ('vesh_zangao', zg), ('vesh_cuspidor', cp)]:
        im.save(f'{OUT}/{nome}.png')
    mk = mockup((ry, kh, zg, cp)); mk.save(f'{OUT}/mockup_varrek_480x270.png')

    W = 1500; Hh = 1640
    pr = Image.new('RGBA', (W, Hh), hx('#120d16')); d = ImageDraw.Draw(pr)
    d.text((40, 28), 'ARTE · Prancha de estilo v0.1 — Ato 1 (Varrek)', font=font(34), fill=(240, 230, 220, 255))
    d.text((40, 74), 'Pixel art · tile 16 px · tela 480×270 · contorno escuro só nos personagens · cor AVISO reservada', font=font(18), fill=(170, 160, 170, 255))
    # paleta
    y = 120; d.text((40, y), 'Paleta do jogo (personagens e efeitos)', font=font(22), fill=(240,230,220,255)); y += 36
    keys = list(PAL.keys())
    for i, k in enumerate(keys):
        cx = 40 + (i % 8) * 180; cy = y + (i // 8) * 58
        d.rectangle((cx, cy, cx + 40, cy + 40), fill=rgb(k), outline=(80, 70, 90, 255))
        d.text((cx + 48, cy + 2), PAL[k][1], font=font(14), fill=(220, 210, 210, 255))
        d.text((cx + 48, cy + 21), PAL[k][0], font=font(13), fill=(140, 130, 140, 255))
    y += ((len(keys) + 7) // 8) * 58 + 20
    # escala lado a lado (x6) com régua de tiles
    d.text((40, y), 'Escala real lado a lado (ampliado 6×) — "pequeno no meio de gigantes"', font=font(22), fill=(240,230,220,255)); y += 40
    S = 6; base = y + 64 * S + 10; x = 60
    for i in range(0, 5):  # régua de 16 px
        d.line((40, base - i * 16 * S, 40 + 10, base - i * 16 * S), fill=(120,110,130,255))
        d.text((14, base - i * 16 * S - 8), f'{i}', font=font(14), fill=(120,110,130,255))
    d.line((40, base, W - 40, base), fill=(90, 80, 100, 255))
    for im, nome, info in [(ry, 'Ryker Vale', 'corpo ~14×27 · quadro 32×32'), (kh, 'Guerreiro de Clã (Kharn)', 'corpo ~32×60 · placa de osso = armadura frontal'),
                           (cp, 'Cuspidor (Vesh)', '20×14 · glândulas de ácido'), (zg, 'Zangão (Vesh)', '12×12 · olhos âmbar')]:
        u = up(im, S); pr.alpha_composite(u, (x, base - u.size[1]))
        d.text((x, base + 10), nome, font=font(16), fill=(230, 220, 210, 255))
        d.text((x, base + 32), info, font=font(13), fill=(150, 140, 150, 255))
        x += u.size[0] + 110
    y = base + 70
    d.text((40, y), 'Mockup de tela 480×270 (ampliado 2×): legibilidade em combate', font=font(22), fill=(240,230,220,255)); y += 36
    pr.alpha_composite(up(mk, 2), (40, y))
    nx = 40 + 960 + 30; ny = y
    notas = ['Leitura em 3 camadas:', ' fundo escuro e dessaturado,', ' cenário jogável em cinza-roxo,', ' personagens saturados com contorno.', '',
             'Ryker: laranja de macacão de mineiro', ' (humano = cor quente, pequena).', 'Âncora na nuca em âmbar.', '',
             'Kharn: ardósia + osso + brasa.', 'Vesh: quitina roxa + ácido verde.', '',
             'AVISO: amarelo-claro piscando,', ' cor usada SÓ para ataques', ' anunciados (pilar 1).', '',
             'Tiros inimigos: grandes, lentos,', ' com contorno. Tiros do jogador:', ' finos, branco-ciano.', '',
             'HUD: 4 elos de corrente = vida.', '',
             'No céu: o anel quebrado da rede', ' dos Antigos (D-021).']
    for i, t in enumerate(notas):
        d.text((nx, ny + i * 22), t, font=font(15), fill=(200, 190, 195, 255))
    pr = pr.crop((0, 0, W, y + 540 + 40))
    pr.save(f'{OUT}/prancha_estilo_v01.png')
    print('ok', pr.size)

if __name__ == '__main__':
    main()
