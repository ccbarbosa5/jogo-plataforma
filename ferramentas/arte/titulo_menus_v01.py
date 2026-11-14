"""ART v0.1 — tela de título, menus e placa de nome legível (D-053, D-054, D-056, D-057).

Uso: python3 ferramentas/arte/titulo_menus_v01.py   (Python 3 + Pillow).
Saída: assets/sprites/ui/titulo/, assets/sprites/ui/menus/ e as telas de conferência em assets/sprites/conceito/.

Regra da D-056: a arte (molduras, botões, fundo, logo) é pixel art em 480×270 e é ampliada ×4 (Nearest);
o TEXTO é desenhado na resolução nativa (1920×1080) com a Atkinson Hyperlegible (OFL, assets/fonts/).
O logo daqui é PROVISÓRIO: o definitivo sai do pacote de prompt 09 (ChatGPT) e é tratado com tratar_ia.py.
"""
from PIL import Image, ImageDraw, ImageFont
import math, os, random, sys

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
from prancha_estilo import rgb, hx, outline, ceu, anel_portal, silhuetas, bayer, ENV
from sprites_v02 import salvar, folha, camada
from ui_v03 import nine_patch as nine_patch_48, moldura_eco, seta_continuar

RAIZ = os.path.join(AQUI, '..', '..')
FONTES = os.path.join(RAIZ, 'assets', 'fonts', 'atkinson_hyperlegible')
T = (0, 0, 0, 0)
ESCALA = 4  # 480×270 → 1920×1080
TEXTO_CLARO = hx('#fff6ea')


def fonte(tam, negrito=False):
    nome = 'AtkinsonHyperlegible-Bold.ttf' if negrito else 'AtkinsonHyperlegible-Regular.ttf'
    return ImageFont.truetype(os.path.join(FONTES, nome), tam)


def up(im, s=ESCALA):
    return im.resize((im.width * s, im.height * s), Image.NEAREST)


def opaco(px, x, y, w, h):
    return 0 <= x < w and 0 <= y < h and px[x, y][3] > 0


# =====================================================================
# LOGO PROVISÓRIO (D-053) — letras de chapa laranja batida, bloco 3D e a corrente partida embaixo
# =====================================================================
def logo():
    txt = 'NO REST'
    f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf', 50)
    l, t, r, b = f.getbbox(txt)
    m = Image.new('L', (r - l + 40, b - t + 10), 0)
    ImageDraw.Draw(m).text((10 - l, 4 - t), txt, font=f, fill=255)
    m = m.point(lambda v: 255 if v > 120 else 0)
    # inclinação para a frente (velocidade)
    k = 0.16
    m = m.transform((m.width + int(m.height * k), m.height), Image.AFFINE, (1, k, -m.height * k, 0, 1, 0), Image.NEAREST)
    m = m.crop(m.getbbox())
    W, H = m.width + 8, m.height + 26
    img = camada(W, H)
    mp = m.load(); px = img.load()
    hh = m.height
    random.seed(7)
    for y in range(m.height):
        for x in range(m.width):
            if not mp[x, y]:
                continue
            fy = y / hh
            cima = y == 0 or not mp[x, y - 1]
            baixo = y == hh - 1 or not mp[x, y + 1]
            if cima:
                c = 'w'                       # fio de luz no topo de cada traço
            elif baixo:
                c = 'O'
            elif fy < 0.38:
                c = 'h' if fy < 0.22 or bayer(x, y) > (fy - 0.22) / 0.16 else 'o'
            elif fy < 0.72:
                c = 'o'
            else:
                c = 'o' if bayer(x, y) > (fy - 0.72) / 0.28 else 'O'
            if c in 'oO' and random.random() < 0.035:
                c = 'K'                       # marcas de golpe (metal de arena)
            px[x + 3, y + 2] = rgb(c)
    # risco de lâmina atravessando o "R"
    for i in range(14):
        x, y = W // 2 + 4 + i, 6 + i * 2 // 2
        if opaco(px, x, y, W, H):
            px[x, y] = rgb('K')
    # bloco 3D: extrusão para baixo e para a direita
    base = img.copy(); bp = base.load()
    ext = camada(W, H); ep = ext.load()
    for d in range(1, 4):
        for y in range(H):
            for x in range(W):
                if bp[x, y][3] and x + d // 2 < W and y + d < H and not bp[x + d // 2, y + d][3]:
                    ep[x + d // 2, y + d] = rgb('K')
    ext.alpha_composite(base)
    img = outline(ext, 'k')
    # corrente partida embaixo: o gladiador que fugiu
    cy = m.height + 12
    d = ImageDraw.Draw(img)
    meio = W // 2 - 6
    for x0 in list(range(6, meio - 10, 10)) + list(range(meio + 14, W - 10, 10)):
        d.rectangle((x0, cy - 3, x0 + 8, cy + 3), outline=rgb('k'))
        d.rectangle((x0 + 1, cy - 2, x0 + 7, cy + 2), outline=rgb('m'))
        d.line((x0 + 2, cy - 2, x0 + 6, cy - 2), fill=rgb('M'))
        d.line((x0 + 8, cy, x0 + 10, cy), fill=rgb('m'))
    # elos abertos na quebra + faíscas
    for (x0, dx) in ((meio - 8, -1), (meio + 8, 1)):
        d.line((x0, cy - 3, x0 + 4 * dx, cy + 2), fill=rgb('k'), width=3)
        d.line((x0, cy - 3, x0 + 4 * dx, cy + 2), fill=rgb('M'))
    for (x, y, c) in ((meio + 1, cy - 4, 'h'), (meio + 3, cy - 1, 'f'), (meio - 1, cy + 2, 'f'), (meio + 5, cy - 6, 'h'), (meio - 3, cy - 5, 'f')):
        img.putpixel((x, y), rgb(c))
    return img.crop(img.getbbox())


# =====================================================================
# FUNDO DA TELA DE TÍTULO (D-053) — 3 camadas para parallax + brasas
# =====================================================================
def fundo_ceu():
    img = Image.new('RGBA', (480, 270))
    ceu(img)
    random.seed(3)
    for _ in range(70):
        x, y = random.randrange(480), random.randrange(110)
        img.putpixel((x, y), hx(random.choice(['#6a5a78', '#9a8aa8', '#dff8ff'])))
    anel_portal(img)
    return img


def fundo_longe():
    """Mesas e torres distantes de Varrek, 960 px de largura (repete sem emenda para rolar devagar)."""
    img = camada(960, 270)
    for i, semente in enumerate((11, 12)):
        parte = camada(480, 270)
        silhuetas(parte, 196, 26, ENV['longe'], semente, (14, 40))
        img.alpha_composite(parte, (i * 480, 0))
    img = _repetir(img)
    return img


def _repetir(img):
    """Faz as bordas esquerda e direita casarem (para TILE horizontal)."""
    w = img.width; px = img.load(); fx = 40
    for x in range(fx):
        a = x / fx
        for y in range(img.height):
            e = px[x, y]; d = px[w - fx + x, y]
            px[w - fx + x, y] = d if bayer(x, y) < a else e
    return img


def fundo_arena():
    """A arena em ruínas (onde o Ryker lutou), em primeiro plano, 960 px de largura."""
    img = camada(960, 270)
    d = ImageDraw.Draw(img)
    meio, perto = hx(ENV['meio']), hx(ENV['perto'])
    random.seed(5)
    # muralha curva da arena com dois andares de arcos, topo quebrado
    for x in range(960):
        topo = 150 + int(18 * math.sin(x / 160)) + (random.randint(0, 6) if (x // 12) % 5 == 0 else 0)
        if 380 < x < 520:  # desabou aqui
            topo = 205 + int(8 * math.sin(x / 9))
        d.line((x, topo, x, 270), fill=meio)
    for andar, (y0, alt) in enumerate(((170, 22), (204, 26))):
        for x0 in range(10 + andar * 12, 960, 44):
            if 370 < x0 < 520:
                continue
            d.rectangle((x0, y0 + 8, x0 + 20, y0 + alt), fill=T)
            d.ellipse((x0, y0, x0 + 20, y0 + 16), fill=T)
    # entulho e chão
    for x in range(960):
        h = 244 + int(5 * math.sin(x / 13) + 3 * math.sin(x / 5.3))
        d.line((x, h, x, 270), fill=perto)
    # pilar de corrente pendurado (marca do jogo)
    for (x0, y0, n) in ((210, 120, 9), (760, 110, 11)):
        d.rectangle((x0 - 4, y0 - 60, x0 + 4, y0), fill=perto)
        for i in range(n):
            y = y0 + i * 5
            d.rectangle((x0 - 2 + (i % 2), y, x0 + 1 + (i % 2), y + 4), outline=perto)
    return _repetir(img)


def brasa():
    """Partícula de brasa, 3 quadros 3×3 (para CPUParticles2D subindo devagar)."""
    q = []
    for c, n in (('h', 1), ('f', 1), ('o', 0)):
        im = camada(3, 3)
        im.putpixel((1, 1), rgb(c))
        if n:
            for p in ((0, 1), (2, 1), (1, 0), (1, 2)):
                im.putpixel(p, rgb('O')[:3] + (150,))
        q.append(im)
    return folha(q)


# =====================================================================
# MENUS (D-053, D-054) — nine-patch 16×16, margem 4 (×4 na tela = 16 px de canto)
# =====================================================================
def botao(estado):
    """Estados: normal, foco, pressionado, desativado. Fundo escuro e liso (contraste alto, D-057)."""
    fundo, borda, luz = {
        'normal': ('K', 'x', 'X'),
        'foco': ('K', 'o', 'h'),
        'pressionado': ('O', 'o', 'h'),
        'desativado': ('k', 'x', 'x'),
    }[estado]
    im = camada(16, 16); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=rgb('k'))
    d.rectangle((1, 1, 14, 14), fill=rgb(borda))
    d.rectangle((2, 2, 13, 13), fill=rgb(fundo))
    d.line((2, 1, 13, 1), fill=rgb(luz))  # luz de cima
    for p in ((0, 0), (15, 0), (0, 15), (15, 15)):
        im.putpixel(p, T)  # cantos chanfrados
    if estado == 'foco':
        d.line((2, 13, 13, 13), fill=rgb('O'))
    return im


def painel():
    """Painel do menu de pausa e das listas (Controles, Opções): 32×32, margem 8."""
    im = camada(32, 32); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 31, 31), fill=rgb('k'))
    d.rectangle((1, 1, 30, 30), fill=rgb('m'))
    d.line((1, 1, 30, 1), fill=rgb('M'))
    d.rectangle((3, 3, 28, 28), fill=rgb('k'))
    d.rectangle((4, 4, 27, 27), fill=hx('#1d1626'))
    d.line((4, 4, 27, 4), fill=rgb('o'))  # filete laranja do Ryker no topo
    for (x, y) in ((2, 2), (29, 2), (2, 29), (29, 29)):
        im.putpixel((x, y), rgb('M'))  # rebites
    for p in ((0, 0), (31, 0), (0, 31), (31, 31)):
        im.putpixel(p, T)
    return im


def seletor():
    """Seta que aponta a opção em foco, 6×9, 2 quadros (4 qps: anda 1 px)."""
    q = []
    for dx in (0, 1):
        im = camada(6, 9)
        for y in range(9):
            w = 4 - abs(y - 4)
            for x in range(w + 1):
                if x + dx < 6:
                    im.putpixel((x + dx, y), rgb('h' if y < 4 else 'o'))
        q.append(outline(im, 'k'))
    return folha(q)


# =====================================================================
# PLACA DE NOME LEGÍVEL (D-057) — 16×16, margem 4; fundo escuro liso, filete na cor do grupo
# =====================================================================
PLACAS = {  # grupo: (filete, cor do nome)
    'humano': ('o', '#fff6ea'),
    'kharn': ('f', '#fff6ea'),
    'vesh': ('p', '#fff6ea'),
    'ilo': ('u', '#fff6ea'),
    'eco': ('a', '#ffe7b0'),
}


def placa(grupo):
    filete = PLACAS[grupo][0]
    im = camada(16, 16); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=rgb('k'))
    d.rectangle((1, 1, 14, 14), fill=rgb(filete))
    d.rectangle((2, 2, 13, 13), fill=rgb('k'))
    for p in ((0, 0), (15, 0), (0, 15), (15, 15), (1, 1), (14, 1), (1, 14), (14, 14)):
        im.putpixel(p, T if p[0] in (0, 15) and p[1] in (0, 15) else rgb('k'))
    return im


def np16(src, w, h, m=4):
    """Monta w×h (em pixels da arte) a partir de um nine-patch pequeno, com bordas repetidas (TILE)."""
    S = src.width
    out = camada(w, h)
    def tile(box, dest):
        reg = src.crop(box); bw, bh = reg.size
        x0, y0, x1, y1 = dest
        for yy in range(y0, y1, bh):
            for xx in range(x0, x1, bw):
                out.alpha_composite(reg.crop((0, 0, min(bw, x1 - xx), min(bh, y1 - yy))), (xx, yy))
    tile((m, m, S - m, S - m), (m, m, w - m, h - m))
    tile((m, 0, S - m, m), (m, 0, w - m, m)); tile((m, S - m, S - m, S), (m, h - m, w - m, h))
    tile((0, m, m, S - m), (0, m, m, h - m)); tile((S - m, m, S, S - m), (w - m, m, w, h - m))
    for (sx, sy, dx, dy) in ((0, 0, 0, 0), (S - m, 0, w - m, 0), (0, S - m, 0, h - m), (S - m, S - m, w - m, h - m)):
        out.alpha_composite(src.crop((sx, sy, sx + m, sy + m)), (dx, dy))
    return out


# =====================================================================
# TELAS DE CONFERÊNCIA 1920×1080 (arte ×4 + texto nativo)
# =====================================================================
def escrever(tela, xy, s, tam, cor=TEXTO_CLARO, negrito=False, ancora='la', sombra=True):
    d = ImageDraw.Draw(tela); f = fonte(tam, negrito)
    if sombra:
        d.text((xy[0] + 3, xy[1] + 3), s, font=f, fill=hx('#16111c'), anchor=ancora)
    d.text(xy, s, font=f, fill=cor, anchor=ancora)
    return d.textbbox(xy, s, font=f, anchor=ancora)


def lista_botoes(tela, x, y, w, itens, foco=0, desativados=(), tam=34, passo=22):
    """Botões empilhados. x, y, w em pixels da arte (480×270); texto nativo centralizado."""
    sel = seletor().crop((0, 0, 6, 9))
    for i, nome in enumerate(itens):
        est = 'desativado' if i in desativados else ('foco' if i == foco else 'normal')
        b = up(np16(botao(est), w, 18))
        tela.alpha_composite(b, (x * ESCALA, (y + i * passo) * ESCALA))
        cor = hx('#7d7886') if est == 'desativado' else (hx('#ffe0b8') if est == 'foco' else TEXTO_CLARO)
        escrever(tela, ((x + w / 2) * ESCALA, (y + i * passo + 9) * ESCALA), nome, tam, cor, True, 'mm')
        if est == 'foco':
            tela.alpha_composite(up(sel), ((x - 9) * ESCALA, (y + i * passo + 5) * ESCALA))


def mockup_titulo(lg):
    pasta = os.path.join(RAIZ, 'assets', 'sprites', 'ui', 'titulo')
    ia_fundo, ia_logo = os.path.join(pasta, 'fundo_titulo_ia.png'), os.path.join(pasta, 'logo_no_rest.png')
    if os.path.exists(ia_fundo) and os.path.exists(ia_logo):  # versão definitiva (pacote 09)
        tela = up(Image.open(ia_fundo).convert('RGBA'))
        lg = Image.open(ia_logo).convert('RGBA')
        L = up(lg); tela.alpha_composite(L, ((1920 - L.width) // 2, 90))
        lista_botoes(tela, 190, 128, 100, ['Continuar', 'Novo jogo', 'Opções', 'Créditos', 'Sair'], foco=0)
        escrever(tela, (40, 1040), 'v0.2 · protótipo', 22, hx('#a4abb6'), ancora='ls')
        return tela
    tela = up(fundo_ceu()).convert('RGBA')
    tela.alpha_composite(up(fundo_longe().crop((120, 0, 600, 270))))
    tela.alpha_composite(up(fundo_arena().crop((300, 0, 780, 270))))
    random.seed(9)
    b = brasa()
    for _ in range(26):
        q = random.randrange(3)
        tela.alpha_composite(up(b.crop((q * 3, 0, q * 3 + 3, 3))), (random.randrange(1900), random.randrange(500, 1060)))
    lg2 = up(lg, 2)  # o logo aparece ×2 na arte (×8 na tela)
    if lg2.width > 380:
        lg2 = up(lg, 1)
    L = up(lg2)
    tela.alpha_composite(L, ((1920 - L.width) // 2, 110))
    lista_botoes(tela, 190, 136, 100, ['Continuar', 'Novo jogo', 'Opções', 'Créditos', 'Sair'], foco=0)
    escrever(tela, (40, 1040), 'v0.2 · protótipo', 22, hx('#a4abb6'), ancora='ls')
    return tela


def tela_jogo():
    f = Image.open(os.path.join(RAIZ, 'assets', 'sprites', 'conceito', 'mockup_v02_varrek.png')).convert('RGBA')
    return up(f)


def mockup_pausa():
    tela = tela_jogo(); tela.alpha_composite(Image.new('RGBA', tela.size, (10, 6, 14, 175)))
    p = up(np16(painel(), 160, 150, 8)); tela.alpha_composite(p, (160 * ESCALA, 50 * ESCALA))
    escrever(tela, (240 * ESCALA, 66 * ESCALA), 'PAUSA', 44, hx('#ffe0b8'), True, 'mm')
    lista_botoes(tela, 180, 80, 120, ['Continuar', 'Controles', 'Opções', 'Voltar à nave', 'Sair do jogo'], foco=1)
    return tela


def mockup_controles():
    tela = tela_jogo(); tela.alpha_composite(Image.new('RGBA', tela.size, (10, 6, 14, 175)))
    p = up(np16(painel(), 300, 230, 8)); tela.alpha_composite(p, (90 * ESCALA, 20 * ESCALA))
    escrever(tela, (240 * ESCALA, 36 * ESCALA), 'CONTROLES', 44, hx('#ffe0b8'), True, 'mm')
    linhas = [('Mover', 'A  D'), ('Agachar', 'S'), ('Pular', 'Espaço'), ('Mirar', 'Mouse'), ('Atirar', 'Botão esquerdo'),
              ('Grilhão', 'Botão direito'), ('Dash', 'Shift'), ('Granada', 'Q'), ('Interagir', 'E'), ('Pausa', 'Esc')]
    for i, (acao, tecla) in enumerate(linhas):
        y = 52 + i * 17
        foco = i == 4
        if foco:
            tela.alpha_composite(up(np16(botao('foco'), 162, 15)), (106 * ESCALA, (y - 2) * ESCALA))
        escrever(tela, (116 * ESCALA, (y + 5.5) * ESCALA), acao, 30, TEXTO_CLARO, False, 'lm')
        k = up(np16(botao('pressionado' if foco else 'normal'), 96, 13))
        tela.alpha_composite(k, (272 * ESCALA, (y - 1) * ESCALA))
        escrever(tela, (320 * ESCALA, (y + 5.5) * ESCALA), 'Aperte uma tecla…' if foco else tecla, 26,
                 hx('#ffe0b8') if foco else TEXTO_CLARO, True, 'mm')
    escrever(tela, (240 * ESCALA, 236 * ESCALA), 'Enter: trocar   ·   Esc: voltar   ·   Restaurar padrão', 24, hx('#a4abb6'), ancora='mm')
    return tela


def mockup_placa():
    """Diálogo em 1080p: retratos ×4, caixa ×4, placa nova (D-057) e texto nativo (D-056)."""
    raiz = os.path.join(RAIZ, 'assets', 'sprites', 'retratos')
    tela = tela_jogo(); tela.alpha_composite(Image.new('RGBA', tela.size, (10, 6, 14, 150)))
    R = Image.open(os.path.join(raiz, 'ryker', 'ryker_retratos.png')); E = Image.open(os.path.join(raiz, 'eco', 'eco_retratos.png'))
    ry = R.crop((144, 0, 288, 208)); ec = E.crop((0, 0, 144, 208)).transpose(Image.FLIP_LEFT_RIGHT)
    ry.putalpha(ry.getchannel('A').point(lambda v: int(v * 0.55)))
    tela.alpha_composite(up(ry), (-6 * ESCALA, 62 * ESCALA))
    tela.alpha_composite(up(nine_patch_48(moldura_eco(), 268, 80)), (84 * ESCALA, 186 * ESCALA))
    tela.alpha_composite(up(ec), (342 * ESCALA, 62 * ESCALA))
    # placa: largura acompanha o nome, encostada no canto de cima da caixa, do lado de quem fala
    nome = 'ECO'; f = fonte(46, True)
    tw = ImageDraw.Draw(tela).textbbox((0, 0), nome, font=f)[2]
    w_arte = math.ceil((tw + 2 * 30) / ESCALA)
    px0 = 352 - w_arte
    tela.alpha_composite(up(np16(placa('eco'), w_arte, 19)), (px0 * ESCALA, 169 * ESCALA))
    escrever(tela, ((px0 + w_arte / 2) * ESCALA, 178.5 * ESCALA), nome, 46, hx(PLACAS['eco'][1]), True, 'mm')
    for i, l in enumerate(['Tem uma peça minha lá embaixo. E… faz muito tempo',
                           'que ninguém fica aqui comigo. Eu ganho companhia.']):
        escrever(tela, (100 * ESCALA, (200 + i * 10) * ESCALA), l, 30, TEXTO_CLARO, sombra=False)
    tela.alpha_composite(up(seta_continuar().crop((0, 0, 9, 7))), (334 * ESCALA, 252 * ESCALA))
    return tela


def amostra_placas():
    """Uma placa de cada grupo, ×4, para o DEV conferir as cores."""
    nomes = [('humano', 'RYKER'), ('kharn', 'GARRAK'), ('vesh', 'SETE'), ('ilo', 'VOSSA MARGEM'), ('eco', 'ECO')]
    tela = Image.new('RGBA', (1920, 140), hx('#3a1f30')[:3] + (255,)); x = 40
    for g, n in nomes:
        f = fonte(46, True); tw = ImageDraw.Draw(tela).textbbox((0, 0), n, font=f)[2]
        w = math.ceil((tw + 60) / ESCALA)
        tela.alpha_composite(up(np16(placa(g), w, 19)), (x, 32))
        escrever(tela, (x + w * ESCALA / 2, 32 + 38), n, 46, hx(PLACAS[g][1]), True, 'mm')
        x += w * ESCALA + 40
    return tela


def main():
    lg = logo()
    salvar(lg, 'ui', 'titulo', 'logo_no_rest_provisorio.png')
    salvar(fundo_ceu(), 'ui', 'titulo', 'fundo_titulo_ceu.png')
    salvar(fundo_longe(), 'ui', 'titulo', 'fundo_titulo_longe.png')
    salvar(fundo_arena(), 'ui', 'titulo', 'fundo_titulo_arena.png')
    salvar(brasa(), 'ui', 'titulo', 'brasa.png')
    M = ('ui', 'menus')
    salvar(folha([botao(e) for e in ('normal', 'foco', 'pressionado', 'desativado')]), *M, 'botao.png')
    salvar(painel(), *M, 'painel.png')
    salvar(seletor(), *M, 'seletor.png')
    for g in PLACAS:
        salvar(placa(g), *M, f'placa_{g}.png')
    salvar(mockup_titulo(lg), 'conceito', 'mockup_v05_titulo.png')
    salvar(mockup_pausa(), 'conceito', 'mockup_v06_pausa.png')
    salvar(mockup_controles(), 'conceito', 'mockup_v07_controles.png')
    salvar(mockup_placa(), 'conceito', 'mockup_v08_dialogo_1080p.png')
    salvar(amostra_placas(), 'conceito', 'amostra_placas_1080p.png')
    print('ok', lg.size)


if __name__ == '__main__':
    main()
