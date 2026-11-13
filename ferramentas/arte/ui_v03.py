"""ART v0.3 — interface por código (D-039): árvore da arma, HUD (elos + Embalo), ícones e molduras.

Uso: python3 ferramentas/arte/ui_v03.py   (Python 3 + Pillow). Tudo sai em assets/sprites/ui/.
"""
from PIL import Image, ImageDraw, ImageFont
import math, os, random, sys, unicodedata

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
from prancha_estilo import rgb, hx, outline
from sprites_v02 import salvar, folha, camada, icone_arma, disco

T = (0, 0, 0, 0)


# =====================================================================
# MOLDURAS (D-032) — nine-patch 48×48, borda de 12 px, bordas periódicas (período 8)
# para o Godot usar NinePatchRect com axis_stretch = TILE (não distorce o pixel).
# =====================================================================
B = 12  # largura da borda


def _moldura(base, borda, luz, sombra, enfeite=None, fundo='#16111c', seed=1):
    im = Image.new('RGBA', (48, 48), T); d = ImageDraw.Draw(im)
    d.rectangle((9, 9, 38, 38), fill=hx(fundo))  # miolo (fora do anel fica transparente)
    # anel da borda
    for y in range(48):
        for x in range(48):
            na_borda = x < B or x >= 48 - B or y < B or y >= 48 - B
            dentro_anel = 3 <= x < 45 and 3 <= y < 45 and not (9 <= x < 39 and 9 <= y < 39)
            if na_borda and dentro_anel:
                im.putpixel((x, y), rgb(base))
    d.rectangle((3, 3, 44, 44), outline=rgb('k'))
    d.rectangle((9, 9, 38, 38), outline=rgb('k'))
    d.line((4, 4, 43, 4), fill=rgb(luz)); d.line((4, 4, 4, 43), fill=rgb(luz))      # luz de cima-esquerda do anel
    d.line((10, 37, 37, 37), fill=rgb(luz)); d.line((37, 10, 37, 37), fill=rgb(luz))  # luz na borda interna de baixo/direita
    d.line((5, 43, 43, 43), fill=rgb(sombra)); d.line((43, 5, 43, 43), fill=rgb(sombra))
    if enfeite: enfeite(im, d)
    return im


def _periodico(im, fn):
    """Aplica fn(x, y) só nas bordas, com padrão de período 8 (casa com o TILE do nine-patch)."""
    for y in range(48):
        for x in range(48):
            no_anel = 4 <= x < 44 and 4 <= y < 44 and not (9 <= x < 39 and 9 <= y < 39)
            if no_anel and im.getpixel((x, y))[3]:
                c = fn(x, y, im.getpixel((x, y)))
                if c: im.putpixel((x, y), c)


def moldura_humana():
    """Sucata remendada: chapas de tons diferentes, rebites, um remendo laranja apagado nos cantos."""
    def enf(im, d):
        def f(x, y, c):
            if c[:3] != rgb('m')[:3]: return None
            if (x % 8 == 6 and (y < B or y >= 48 - B)) or (y % 8 == 6 and (x < B or x >= 48 - B)): return rgb('M')  # rebites
            if ((x // 8) + (y // 8)) % 2: return rgb('x')                                                         # chapas alternadas
            return None
        _periodico(im, f)
        for (cx, cy) in ((3, 3), (37, 3), (3, 37), (37, 37)):  # remendos de canto
            d.rectangle((cx + 1, cy + 1, cx + 6, cy + 6), fill=rgb('O')); d.rectangle((cx + 1, cy + 1, cx + 6, cy + 6), outline=rgb('k'))
            d.point((cx + 2, cy + 2), fill=rgb('M')); d.point((cx + 5, cy + 5), fill=rgb('M'))
    return _moldura('m', 'k', 'M', 'K', enf)


def moldura_kharn():
    """Metal e osso, vermelho-brasa: ferro escuro com espinhos de osso nos cantos e um filete brasa."""
    def enf(im, d):
        d.rectangle((6, 6, 41, 41), outline=rgb('e'))
        def f(x, y, c):
            if (x < B or x >= 48 - B) and y % 8 in (2, 3) and 4 <= x < 44: return rgb('W')
            if (y < B or y >= 48 - B) and x % 8 in (2, 3) and 4 <= y < 44: return rgb('W')
            return None
        _periodico(im, f)
        for (x0, y0, sx, sy) in ((0, 0, 1, 1), (47, 0, -1, 1), (0, 47, 1, -1), (47, 47, -1, -1)):  # espinhos de osso
            for k in range(5):
                im.putpixel((x0 + sx * k, y0 + sy * k), rgb('w'))
                if k: im.putpixel((x0 + sx * k, y0 + sy * (k - 1)), rgb('W'))
    return _moldura('x', 'k', 'X', 'K', enf)


def moldura_vesh():
    """Resina e quitina âmbar: quitina roxa com gotas e veios de resina âmbar."""
    def enf(im, d):
        def f(x, y, c):
            if (x + 2 * y) % 16 == 0: return rgb('a')   # veios de resina, espaçados
            if (x + 2 * y) % 16 == 1: return rgb('h')
            return None
        _periodico(im, f)
        for (cx, cy) in ((6, 6), (41, 6), (6, 41), (41, 41)):  # bolhas de resina nos cantos
            disco(im, cx + 0.5, cy + 0.5, 3.2, rgb('a')); disco(im, cx - 0.5, cy - 0.5, 1.2, rgb('t'))
    return _moldura('v', 'k', 'p', 'V', enf)


def moldura_ilo():
    """Latão e vidro: tons de osso fazem o latão; janelinhas de vidro (azul-asa) na borda."""
    def enf(im, d):
        def f(x, y, c):
            horiz = y < B or y >= 48 - B
            pos = x if horiz else y
            outro = y if horiz else x
            if pos % 8 in (3, 4) and outro in (5, 6, 41, 42): return rgb('u')       # vidro
            if pos % 8 == 0: return rgb('w')
            return None
        _periodico(im, f)
    return _moldura('W', 'k', 'w', 'x', enf)


def moldura_eco():
    """Luz âmbar sobre o teal da nave (D-032): anel teal com um fio de luz âmbar contínuo."""
    def enf(im, d):
        d.rectangle((6, 6, 41, 41), outline=rgb('a'))
        d.rectangle((7, 7, 40, 40), outline=rgb('h'))
        def f(x, y, c):
            if c[:3] == rgb('N')[:3] and (x + y) % 8 == 0: return rgb('n')
            return None
        _periodico(im, f)
    return _moldura('N', 'k', 'n', 'K', enf, fundo='#0f1416')


MOLDURAS = {'humana': moldura_humana, 'kharn': moldura_kharn, 'vesh': moldura_vesh, 'ilo': moldura_ilo, 'eco': moldura_eco}


def seta_continuar():
    """2 quadros (sobe e desce 1 px). Laranja: 'aperte para o Ryker continuar'."""
    qs = []
    for dy in (0, 1):
        im = camada(9, 7); d = ImageDraw.Draw(im)
        d.polygon([(1, 1 + dy), (7, 1 + dy), (4, 4 + dy)], fill=rgb('h'))
        qs.append(outline(im))
    return folha(qs)


# =====================================================================
# ÁRVORE DA ARMA (D-040, GD-05)
# =====================================================================
def no(estado, apice=False):
    """Nó 20×20 (Ápice 24×24). Estados: trancado, disponivel, comprado, bloqueado (Ápice trancado por outro Ápice)."""
    L = 24 if apice else 20; im = camada(L, L); d = ImageDraw.Draw(im)
    c = L // 2
    if apice:  # Ápice: losango de sucata com pontas
        forma = [(c, 1), (L - 2, c), (c, L - 2), (1, c)]
    else:
        forma = [(2, 2), (L - 3, 2), (L - 3, L - 3), (2, L - 3)]
    aro = {'trancado': 'K', 'disponivel': 'M', 'comprado': 'h', 'bloqueado': 'K'}[estado]
    miolo = {'trancado': 'k', 'disponivel': 'K', 'comprado': 'o', 'bloqueado': 'k'}[estado]
    d.polygon(forma, fill=rgb(aro))
    inset = 3
    if apice:
        d.polygon([(c, 1 + inset), (L - 2 - inset, c), (c, L - 2 - inset), (1 + inset, c)], fill=rgb(miolo))
    else:
        d.rectangle((2 + inset, 2 + inset, L - 3 - inset, L - 3 - inset), fill=rgb(miolo))
    if estado == 'comprado':  # brilho
        d.point((c - 3, c - 3), fill=rgb('t')); d.point((c - 2, c - 3), fill=rgb('h'))
    if estado == 'trancado':  # cadeado
        d.rectangle((c - 2, c - 1, c + 1, c + 2), fill=rgb('m')); d.arc((c - 2, c - 4, c + 1, c), 180, 360, fill=rgb('m'))
    if estado == 'bloqueado':  # rachadura: o outro Ápice foi escolhido
        for k in range(-4, 5): im.putpixel((c + k, c + (1 if k % 2 else 0) - k // 3), rgb('e'))
    return outline(im)


def destaque(apice=False):
    """Contorno que pisca no 1º uso (GD-03 1.2): 2 quadros, branco-ciano / transparente."""
    L = (24 if apice else 20) + 4; c = L // 2
    a = camada(L, L); d = ImageDraw.Draw(a)
    if apice: d.polygon([(c, 0), (L - 1, c), (c, L - 1), (0, c)], outline=rgb('t'))
    else: d.rectangle((0, 0, L - 1, L - 1), outline=rgb('t'))
    return folha([a, camada(L, L)])


def conector():
    """Liga um nó ao próximo. 4×10, 2 quadros: apagado / aceso."""
    qs = []
    for cor, luz in (('K', 'k'), ('o', 'h')):
        im = camada(4, 10); d = ImageDraw.Draw(im)
        d.rectangle((1, 0, 2, 9), fill=rgb(cor)); d.line((1, 0, 1, 9), fill=rgb(luz))
        qs.append(im)
    return folha(qs)


def pips_custo():
    """Custo do nó em rebites: 1, 2 ou 3. Cada quadro 12×4."""
    qs = []
    for n in (1, 2, 3):
        im = camada(12, 4)
        x0 = 6 - (n * 4 - 1) // 2
        for i in range(n):
            ImageDraw.Draw(im).rectangle((x0 + i * 4, 0, x0 + i * 4 + 2, 2), fill=rgb('M'))
            im.putpixel((x0 + i * 4, 0), (255, 255, 255, 255))
        qs.append(outline(im))
    return folha(qs)


def ponto_aprimoramento():
    """Ponto de Aprimoramento = sucata para gambiarra (NAR-03): uma porca com brilho laranja. 12×12."""
    im = camada(12, 12); d = ImageDraw.Draw(im)
    hexa = [(6 + 4.6 * math.cos(math.radians(a)), 6 + 4.6 * math.sin(math.radians(a))) for a in range(0, 360, 60)]
    d.polygon(hexa, fill=rgb('m')); d.ellipse((4, 4, 7, 7), fill=rgb('k'))
    d.line((3, 3, 6, 2), fill=rgb('M')); im.putpixel((9, 4), rgb('h')); im.putpixel((9, 5), rgb('o'))
    return outline(im)


def icone_porta_aprimoramento():
    """Recompensa de porta 'Aprimoramento de Arma' (GD-03). 24×24: chave inglesa cruzando um cano, com a porca."""
    im = camada(24, 24); d = ImageDraw.Draw(im)
    d.line((4, 18, 18, 4), fill=rgb('x'), width=3); d.line((5, 17, 17, 5), fill=rgb('X'))       # cano
    d.ellipse((15, 1, 21, 7), fill=rgb('x')); d.ellipse((17, 3, 19, 5), fill=rgb('k'))           # boca do cano
    d.line((5, 5, 17, 17), fill=rgb('M'), width=3)                                                # chave
    d.ellipse((1, 1, 8, 8), fill=rgb('M')); d.rectangle((4, 1, 6, 4), fill=T)                    # boca da chave
    p = ponto_aprimoramento(); im.alpha_composite(p, (12, 12))
    return outline(im)


# =====================================================================
# HUD (ART-01 §11, D-043)
# =====================================================================
def hud_elo(cheio):
    im = camada(11, 8); d = ImageDraw.Draw(im)
    if cheio:
        d.rounded_rectangle((0, 0, 10, 7), 2, fill=rgb('M')); d.rectangle((3, 2, 7, 5), fill=T)
        d.line((2, 1, 8, 1), fill=(255, 255, 255, 255)); d.line((1, 6, 9, 6), fill=rgb('m'))
    else:  # elo quebrado
        d.rounded_rectangle((0, 0, 10, 7), 2, fill=rgb('K')); d.rectangle((3, 2, 7, 5), fill=T); d.rectangle((5, 0, 6, 1), fill=T)
    return outline(im)


def barra(cor_fill, cor_luz, largura=50):
    """Barra fina: (fundo, preenchimento, preenchimento cheio). Para TextureProgressBar (under/progress)."""
    fundo = camada(largura + 2, 5); d = ImageDraw.Draw(fundo)
    d.rectangle((0, 0, largura + 1, 4), fill=rgb('k')); d.rectangle((1, 1, largura, 3), fill=rgb('K'))
    fill = camada(largura + 2, 5); d = ImageDraw.Draw(fill)
    d.rectangle((1, 1, largura, 3), fill=rgb(cor_fill)); d.line((1, 1, largura, 1), fill=rgb(cor_luz))
    cheio = camada(largura + 2, 5); d = ImageDraw.Draw(cheio)
    d.rectangle((1, 1, largura, 3), fill=rgb('t')); d.line((1, 3, largura, 3), fill=rgb(cor_fill))
    return fundo, fill, cheio


# =====================================================================
# TELA DE CONFERÊNCIA DA ÁRVORE (não é a tela do jogo; layout para o DEV)
# =====================================================================
def _sem_acento(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')


def nine_patch(src, w, h):
    """Monta um retângulo w×h a partir do nine-patch 48×48 (bordas repetidas, como o TILE do Godot)."""
    out = camada(w, h)
    def tile(box, dest):
        reg = src.crop(box); bw, bh = reg.size
        x0, y0, x1, y1 = dest
        for yy in range(y0, y1, bh):
            for xx in range(x0, x1, bw):
                pedaço = reg.crop((0, 0, min(bw, x1 - xx), min(bh, y1 - yy))); out.alpha_composite(pedaço, (xx, yy))
    tile((B, B, 48 - B, 48 - B), (B, B, w - B, h - B))
    tile((B, 0, 48 - B, B), (B, 0, w - B, B)); tile((B, 48 - B, 48 - B, 48), (B, h - B, w - B, h))
    tile((0, B, B, 48 - B), (0, B, B, h - B)); tile((48 - B, B, 48, 48 - B), (w - B, B, w, h - B))
    for (sx, sy, dx, dy) in ((0, 0, 0, 0), (48 - B, 0, w - B, 0), (0, 48 - B, 0, h - B), (48 - B, 48 - B, w - B, h - B)):
        out.alpha_composite(src.crop((sx, sy, sx + B, sy + B)), (dx, dy))
    return out


def mockup_arvore(fundo_tela):
    tela = fundo_tela.copy().convert('RGBA')
    escuro = Image.new('RGBA', tela.size, (10, 6, 14, 170)); tela.alpha_composite(escuro)  # jogo pausado, escurecido
    painel = nine_patch(moldura_humana(), 400, 236); tela.alpha_composite(painel, (40, 17))
    d = ImageDraw.Draw(tela); fnt = ImageFont.load_default_imagefont()
    txt = lambda xy, s, cor='t': d.text(xy, _sem_acento(s).upper(), font=fnt, fill=rgb(cor))
    tela.alpha_composite(icone_arma('mordida', 32, 16, 1.9), (60, 34))
    txt((100, 34), 'Mordida', 'h'); txt((100, 46), 'Embalo: acertar sem levar dano acelera', 'M')
    pts = ponto_aprimoramento()
    for i in range(2): tela.alpha_composite(pts, (372 + i * 14, 36))
    txt((338, 38), 'x2', 'M')
    ramos = [('Ovacao', ['Plateia Fiel', 'Ritmo de Arena', 'Grande Arena']),
             ('Rajada', ['Disciplina', 'Tres Golpes', 'Execucao']),
             ('Corrente', ['Marca do Escravo', 'Cacada', 'Algema Viva'])]
    estados = [['comprado', 'comprado', 'disponivel'], ['comprado', 'disponivel', 'trancado'], ['disponivel', 'trancado', 'trancado']]
    pips = pips_custo(); con = conector()
    for r, (nome, nos) in enumerate(ramos):
        cx = 120 + r * 120
        txt((cx - len(nome) * 3, 66), nome, 'M')
        for k in range(3):
            ap = k == 2; est = estados[r][k]
            n = no(est, ap); y = 80 + k * 50
            tela.alpha_composite(n, (cx - n.width // 2, y))
            if r == 0 and k == 2:  # destaque piscando no 1º uso
                tela.alpha_composite(destaque(True).crop((0, 0, 28, 28)), (cx - 14, y - 2))
            tela.alpha_composite(pips.crop((k * 12, 0, k * 12 + 12, 4)), (cx + n.width // 2 + 3, y + n.height // 2 - 2))
            if k < 2:
                aceso = estados[r][k] == 'comprado'
                tela.alpha_composite(con.crop((4 if aceso else 0, 0, 8 if aceso else 4, 10)), (cx - 2, y + n.height + 1))
            rot = _sem_acento(nos[k]).upper()
            txt((cx - len(rot) * 3, y + n.height + 12 if k < 2 else y + n.height + 3),
                nos[k], 'h' if est == 'comprado' else ('t' if est == 'disponivel' else 'K'))
    txt((60, 232), 'Apice: so 1 por run. Escolher um tranca os outros.', 'M')
    return tela


# =====================================================================
def main():
    U = ('ui',)
    for nome, fn in MOLDURAS.items():
        salvar(fn(), *U, 'molduras', f'moldura_{nome}.png')
    salvar(seta_continuar(), *U, 'molduras', 'seta_continuar.png')
    A = ('ui', 'arvore')
    for apice, suf in ((False, ''), (True, '_apice')):
        salvar(folha([no(e, apice) for e in ('trancado', 'disponivel', 'comprado', 'bloqueado')]), *A, f'no{suf}.png')
        salvar(destaque(apice), *A, f'destaque{suf}.png')
    salvar(conector(), *A, 'conector.png'); salvar(pips_custo(), *A, 'custo.png')
    salvar(ponto_aprimoramento(), *A, 'ponto_aprimoramento.png')
    salvar(icone_porta_aprimoramento(), 'ui', 'portas', 'porta_aprimoramento_de_arma.png')
    H = ('ui', 'hud')
    salvar(folha([hud_elo(True), hud_elo(False)]), *H, 'elo_vida.png')
    for nome, (cor, luz) in (('embalo', ('o', 'h')), ('chamado', ('a', 't'))):
        f_, p_, c_ = barra(cor, luz)
        salvar(f_, *H, f'barra_{nome}_fundo.png'); salvar(p_, *H, f'barra_{nome}_cheia.png'); salvar(c_, *H, f'barra_{nome}_completa.png')
    fundo = Image.open(os.path.join(AQUI, '..', '..', 'assets', 'sprites', 'conceito', 'mockup_v02_varrek.png'))
    salvar(mockup_arvore(fundo), 'conceito', 'mockup_v03_arvore.png')
    print('ok')


if __name__ == '__main__':
    main()
