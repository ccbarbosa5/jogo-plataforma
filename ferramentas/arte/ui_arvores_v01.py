"""ART-3 — telas das duas árvores (Passiva e Combate) e das 3 cartas de Gambiarra (GD-07, D-058).

Uso: python3 ferramentas/arte/ui_arvores_v01.py   (Python 3 + Pillow).
Saída: assets/sprites/ui/arvore/ (v2), assets/sprites/ui/gambiarras/ e as telas de conferência
conceito/mockup_v09_arvore_combate.png, mockup_v10_arvore_passiva.png, mockup_v11_gambiarras.png.

Mesma regra da D-056: arte em 480×270 ampliada ×4, texto nativo em 1080p. O texto das conferências usa a
Open Sans (D-060), guardada só para isso em ferramentas/arte/fontes_conferencia/ (OFL).
"""
from PIL import Image, ImageDraw, ImageFont
import math, os, sys

AQUI = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, AQUI)
from prancha_estilo import rgb, hx, outline
from sprites_v02 import salvar, folha, camada
from ui_v03 import nine_patch as nine_patch_48, moldura_humana
from titulo_menus_v01 import np16, up, botao, painel, ESCALA

RAIZ = os.path.join(AQUI, '..', '..')
T = (0, 0, 0, 0)
CLARO, FOCO, APAGADO, DICA = hx('#fff6ea'), hx('#ffe0b8'), hx('#7d7886'), hx('#a7a1ae')
RARIDADES = {  # chave: (nome, cor da borda, cor clara, cor do texto)
    'C': ('COMUM', 'm', 'M', '#c9c3cf'),
    'R': ('RARA', 'b', 'u', '#9fd0ff'),
    'E': ('ÉPICA', 'O', 'h', '#f2a65a'),
}


def fonte(tam, peso='SemiBold'):
    f = ImageFont.truetype(os.path.join(AQUI, 'fontes_conferencia', 'OpenSans-Variavel.ttf'), tam)
    f.set_variation_by_name(peso)
    return f


def escrever(tela, xy, s, tam, cor=CLARO, peso='SemiBold', ancora='la', sombra=True):
    d = ImageDraw.Draw(tela); f = fonte(tam, peso)
    if sombra:
        d.text((xy[0] + 2, xy[1] + 2), s, font=f, fill=hx('#16111c'), anchor=ancora)
    d.text(xy, s, font=f, fill=cor, anchor=ancora)


def quebrar(s, tam, largura, peso='SemiBold'):
    f = fonte(tam, peso); linhas, atual = [], ''
    for p in s.split():
        t = (atual + ' ' + p).strip()
        if f.getlength(t) <= largura:
            atual = t
        else:
            linhas.append(atual); atual = p
    return linhas + [atual]


# =====================================================================
# PEÇAS DAS ÁRVORES — nine-patch 16×16, margem 4
# =====================================================================
ESTADOS_NO = ('bloqueado', 'disponivel', 'comprado', 'apice_disponivel', 'apice_comprado')


def no(estado):
    fundo, borda, luz = {
        'bloqueado': ('k', 'K', 'K'),
        'disponivel': ('K', 'X', 'M'),
        'comprado': ('O', 'h', 'w'),
        'apice_disponivel': ('K', 'f', 'h'),
        'apice_comprado': ('f', 'w', 'w'),
    }[estado]
    im = camada(16, 16); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), fill=rgb('k'))
    d.rectangle((1, 1, 14, 14), fill=rgb(borda))
    d.rectangle((2, 2, 13, 13), fill=rgb(fundo))
    d.line((2, 1, 13, 1), fill=rgb(luz))
    if estado.startswith('apice'):  # Ápice: cantos com rebite e borda dupla
        d.rectangle((3, 3, 12, 12), outline=rgb('k' if estado == 'apice_comprado' else 'O'))
        for p in ((2, 2), (13, 2), (2, 13), (13, 13)):
            im.putpixel(p, rgb('w'))
    for p in ((0, 0), (15, 0), (0, 15), (15, 15)):
        im.putpixel(p, T)
    return im


def no_foco():
    """Contorno de foco (vai por cima de qualquer estado): 16×16, margem 4, centro vazio."""
    im = camada(16, 16); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), outline=rgb('w'))
    d.rectangle((1, 1, 14, 14), outline=rgb('h'))
    for p in ((0, 0), (15, 0), (0, 15), (15, 15)):
        im.putpixel(p, T)
    return im


def conector(ativo):
    """Ligação vertical entre nós do mesmo ramo: 4×4, repete na vertical (TILE)."""
    im = camada(4, 4)
    for y in range(4):
        im.putpixel((1, y), rgb('h' if ativo else 'K'))
        im.putpixel((2, y), rgb('o' if ativo else 'k'))
    return im


ICONES = {
    'mordida': """
............
.........kk.
..kkkkkkkMk.
.kXXXXXXXXk.
.kxxxxxxxxk.
.kxxkkkkkk..
.kxxk.......
..kxk.......
..kk........
""",
    'bramido': """
............
...kkkkkkkk.
..kXXXXXXXk.
.kxxxxxxxxk.
.kxxkkkkkk..
.kxxk.kk....
.kOOk.......
..kOOk......
...kk.......
""",
    'granada': """
.....kkk....
....kMMk....
...kkkkkk...
..kggglggk..
.kgGglggggk.
.kgGgggggGk.
.kgGgggggGk.
..kGGgggGk..
...kkkkkk...
""",
    'grilhao': """
.kkk........
kMmMk.......
kmkmkkkk....
kMmMkMmMk...
.kkkmkkmk...
....kMmMkkk.
.....kkkMmMk
........kmkk
........kMMk
.........kk.
""",
    'dash': """
............
....kkkkk...
...kohhhok..
.kkkooooook.
kwwkoooOok..
.kkkOOOOk...
...kkkkk....
""",
    'corpo': """
...kkkkk....
..kMMMMMk...
.kMmmmmmMk..
.kmmMMMmmk..
.kmmMwMmmk..
.kmmmMmmmk..
..kmmmmmk...
...kmmmk....
....kkk.....
""",
    'movimento': """
.....kkk....
....kwwwk...
...kkwwk....
..kOookk....
.kOookkk....
.kOookkkkk..
.kOOoooook..
..kkkkkkkk..
""",
    'fortuna': """
....kkkk....
...khhhhk...
..khokkohk..
..khkhhkhk..
..khokkohk..
...khhhhk...
....kkkk....
""",
}


def icone(nome):
    im = camada(12, 12)
    for y, r in enumerate(ICONES[nome].strip('\n').split('\n')):
        for x, ch in enumerate(r):
            if ch != '.':
                im.putpixel((x, y), rgb(ch))
    return im


def icone_ponto():
    """Ponto da árvore de Combate (vem do nível): losango laranja 7×7."""
    im = camada(7, 7)
    for y in range(7):
        w = 3 - abs(y - 3)
        for x in range(3 - w, 4 + w):
            c = 'k' if abs(x - 3) + abs(y - 3) == 3 else ('w' if (x, y) == (3, 1) else ('h' if y < 3 else 'o'))
            im.putpixel((x, y), rgb(c))
    return im


def icone_nucleo():
    """Núcleo (moeda da árvore Passiva): cristal teal 7×9."""
    m = """
..kkk..
.knNnk.
knnNnnk
kNnnnNk
knnNnnk
kNnnnNk
.knnnk.
..kNk..
...k...
"""
    im = camada(7, 9)
    for y, r in enumerate(m.strip('\n').split('\n')):
        for x, ch in enumerate(r):
            if ch != '.':
                im.putpixel((x, y), rgb(ch))
    return im


def pip_nivel():
    """Nível de um nó da Passiva: 2 quadros 5×5 (vazio, cheio)."""
    q = []
    for cheio in (False, True):
        im = camada(5, 5); d = ImageDraw.Draw(im)
        d.rectangle((0, 0, 4, 4), fill=rgb('k'))
        d.rectangle((1, 1, 3, 3), fill=rgb('h' if cheio else 'K'))
        if cheio:
            im.putpixel((1, 1), rgb('w'))
        q.append(im)
    return folha(q)


# =====================================================================
# GAMBIARRAS — carta 32×32 (margem 10) por raridade + gema de raridade 12×12
# =====================================================================
def carta(r):
    _, borda, luz, _ = RARIDADES[r]
    im = camada(32, 32); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 31, 31), fill=rgb('k'))
    d.rectangle((1, 1, 30, 30), fill=rgb(borda))
    d.line((2, 1, 29, 1), fill=rgb(luz))
    d.rectangle((3, 3, 28, 28), fill=rgb('k'))
    d.rectangle((4, 4, 27, 27), fill=hx('#1d1626'))
    d.rectangle((4, 4, 27, 9), fill=rgb('K'))          # faixa do topo (raridade)
    for p in ((2, 2), (29, 2), (2, 29), (29, 29)):
        im.putpixel(p, rgb(luz))                            # rebites
    if r == 'E':  # Épica: brasa nos cantos
        for p in ((3, 3), (28, 3), (3, 28), (28, 28)):
            im.putpixel(p, rgb('f'))
    for p in ((0, 0), (31, 0), (0, 31), (31, 31)):
        im.putpixel(p, T)
    return im


def gema(r):
    """C = 1 losango, R = 2, É = 3 (lê sem depender da cor)."""
    _, borda, luz, _ = RARIDADES[r]
    im = camada(12, 12)
    n = {'C': 1, 'R': 2, 'E': 3}[r]
    xs = {1: [6], 2: [3, 9], 3: [2, 6, 10]}[n]
    for cx in xs:
        for y in range(3, 10):
            w = 2 - abs(y - 6) if abs(y - 6) <= 2 else -1
            w = 3 - abs(y - 6)
            for x in range(cx - w, cx + w + 1):
                if 0 <= x < 12:
                    borda_px = abs(x - cx) + abs(y - 6) == 3
                    im.putpixel((x, y), rgb('k' if borda_px else (luz if y < 6 else borda)))
    return im


def carta_foco():
    im = camada(32, 32); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 31, 31), outline=rgb('w'))
    d.rectangle((1, 1, 30, 30), outline=rgb('h'))
    for p in ((0, 0), (31, 0), (0, 31), (31, 31)):
        im.putpixel(p, T)
    return im


def np(src, w, h, m):
    return np16(src, w, h, m)


# =====================================================================
# TELAS DE CONFERÊNCIA (1080p)
# =====================================================================
def fundo_nave():
    f = Image.open(os.path.join(RAIZ, 'assets', 'sprites', 'conceito', 'mockup_v02_varrek.png')).convert('RGBA')
    t = up(f); t.alpha_composite(Image.new('RGBA', t.size, (10, 6, 14, 200)))
    return t


COMBATE = [
    ('Mordida', 'mordida', [('Rebite Afiado', 1, 'c'), ('Gatilho de Mina', 1, 'c'), ('Perfurante', 2, 'c'), ('Três Golpes', 2, 'c'), ('Grande Arena', 3, 'ad')]),
    ('Bramido', 'bramido', [('Balins Pesados', 1, 'i'), ('Boca Larga', 1, 'i'), ('Abre-Couraça', 2, 'i'), ('Cano Duplo', 2, 'i'), ('Recuo de Gladiador', 3, 'ai')]),
    ('Granada', 'granada', [('Cinto', 1, 'c'), ('Pavio Curto', 1, 'd'), ('Estilhaços', 2, 'b'), ('Recarga de Campo', 2, 'b'), ('Fragmentação', 3, 'ab')]),
    ('Grilhão', 'grilhao', [('Corrente Longa', 1, 'c'), ('Marca Funda', 1, 'f'), ('Duas Cargas', 2, 'b'), ('Arrastão', 2, 'b'), ('Corrente Explosiva', 3, 'ab')]),
    ('Dash', 'dash', [('Passo Leve', 1, 'd'), ('Dash Duplo', 2, 'b'), ('Esquiva de Arena', 2, 'b')]),
]
# estado: c comprado, d disponível, b bloqueado, i ramo inativo, f foco (disponível com foco), a = Ápice


def mockup_combate():
    tela = fundo_nave()
    tela.alpha_composite(up(nine_patch_48(moldura_humana(), 472, 262)), (4 * ESCALA, 4 * ESCALA))
    escrever(tela, (240 * ESCALA, 20 * ESCALA), 'ÁRVORE DE COMBATE — RYKER', 40, FOCO, 'Bold', 'mm')
    # cabeçalho: nível, pontos, ápices
    escrever(tela, (22 * ESCALA, 34 * ESCALA), 'Nível 11', 28, CLARO, 'Bold', 'lm')
    tela.alpha_composite(up(icone_ponto()), (80 * ESCALA, 31 * ESCALA))
    escrever(tela, (90 * ESCALA, 34 * ESCALA), '2 livres de 10', 28, CLARO, ancora='lm')
    escrever(tela, (458 * ESCALA, 34 * ESCALA), 'Ápices: 0 de 2', 28, DICA, ancora='rm')
    x0 = (480 - (5 * 84 + 4 * 6)) // 2
    for i, (ramo, ic, nos) in enumerate(COMBATE):
        x = x0 + i * 90
        inativo = all(e[2] == 'i' or e[2] == 'ai' for e in nos)
        tela.alpha_composite(up(icone(ic)), ((x + 4) * ESCALA, 42 * ESCALA))
        escrever(tela, ((x + 19) * ESCALA, 48 * ESCALA), ramo, 28, APAGADO if inativo else CLARO, 'Bold', 'lm')
        if inativo:
            escrever(tela, ((x + 42) * ESCALA, 60 * ESCALA), 'arma não levada', 20, APAGADO, ancora='mm')
        for j, (nome, custo, est) in enumerate(nos):
            y = 64 + j * 26
            apice = est.startswith('a'); e = est[-1]
            if j:
                ativo = nos[j - 1][2][-1] == 'c' and e in 'cdf'
                c = conector(ativo)
                for yy in range(y - 4, y, 4):
                    tela.alpha_composite(up(c), ((x + 40) * ESCALA, yy * ESCALA))
            nome_estado = {'c': 'comprado', 'd': 'disponivel', 'f': 'disponivel', 'b': 'bloqueado', 'i': 'bloqueado'}[e]
            if apice:
                nome_estado = 'apice_comprado' if e == 'c' else ('apice_disponivel' if e in 'df' else 'bloqueado')
            tela.alpha_composite(up(np(no(nome_estado), 84, 22, 4)), (x * ESCALA, y * ESCALA))
            if e == 'f':
                tela.alpha_composite(up(np(no_foco(), 84, 22, 4)), (x * ESCALA, y * ESCALA))
            cor = APAGADO if e in 'bi' else (hx('#16111c') if e == 'c' and apice else CLARO)
            sombra = not (e == 'c' and apice)
            escrever(tela, ((x + 5) * ESCALA, (y + 8) * ESCALA), nome, 22 if len(nome) < 17 else 19, cor, 'Bold', 'lm', sombra)
            for k in range(custo):  # custo em losangos
                tela.alpha_composite(up(icone_ponto()), ((x + 5 + k * 8) * ESCALA, (y + 13) * ESCALA))
    # descrição do nó em foco
    tela.alpha_composite(up(np(painel(), 444, 36, 8)), (x0 * ESCALA, 226 * ESCALA))
    escrever(tela, ((x0 + 10) * ESCALA, 235 * ESCALA), 'Marca Funda', 30, FOCO, 'Bold', 'lm')
    escrever(tela, ((x0 + 10) * ESCALA, 248 * ESCALA), 'A Marca do Grilhão passa a dar +40% de dano dos tiros, por 6 s.', 26, CLARO, ancora='lm')
    escrever(tela, ((x0 + 434) * ESCALA, 235 * ESCALA), 'Clique: comprar · Direito: devolver · R: redistribuir', 20, DICA, ancora='rm')
    return tela


PASSIVA = [
    ('Corpo', 'corpo', [('Blindagem', '+1 bloco de vida', 2, 1, (40, 90)), ('Sinal de Emergência', 'Volta 1 vez com 2 blocos', 1, 0, (120,))]),
    ('Movimento', 'movimento', [('Passada', '+5% de corrida', 2, 2, (30, 60)), ('Pernas de Mineiro', '+6% de pulo', 2, 1, (30, 60)), ('Propulsores', '−0,1 s no dash', 2, 0, (40, 80))]),
    ('Fortuna', 'fortuna', [('Contato no Mercado', '+30 Créditos ao começar', 3, 1, (20, 40, 60)), ('Recalibrar', '+1 troca por run', 2, 0, (50, 100)), ('Memória da Âncora', '+10% de XP', 3, 0, (40, 70, 100)), ('Coleta Fina', '+10% de Núcleos', 2, 0, (60, 120))]),
]


def mockup_passiva():
    tela = fundo_nave()
    tela.alpha_composite(up(nine_patch_48(moldura_humana(), 472, 262)), (4 * ESCALA, 4 * ESCALA))
    escrever(tela, (240 * ESCALA, 20 * ESCALA), 'MELHORIAS DO VOSSA MARGEM', 40, FOCO, 'Bold', 'mm')
    tela.alpha_composite(up(icone_nucleo()), (22 * ESCALA, 30 * ESCALA))
    escrever(tela, (32 * ESCALA, 34 * ESCALA), '215 Núcleos', 28, CLARO, 'Bold', 'lm')
    escrever(tela, (458 * ESCALA, 34 * ESCALA), 'Permanente · vale para todos', 24, DICA, ancora='rm')
    pip = pip_nivel()
    for i, (ramo, ic, nos) in enumerate(PASSIVA):
        x = 20 + i * 150
        tela.alpha_composite(up(icone(ic)), ((x + 2) * ESCALA, 42 * ESCALA))
        escrever(tela, ((x + 17) * ESCALA, 48 * ESCALA), ramo, 28, CLARO, 'Bold', 'lm')
        for j, (nome, efeito, niv, tem, custos) in enumerate(nos):
            y = 58 + j * 40
            completo = tem == niv
            pode = not completo and (j == 0 or nos[j - 1][3] > 0 or i != 0)
            est = 'comprado' if completo else ('disponivel' if pode else 'bloqueado')
            foco = (i, j) == (1, 1)
            tela.alpha_composite(up(np(no(est), 140, 34, 4)), (x * ESCALA, y * ESCALA))
            if foco:
                tela.alpha_composite(up(np(no_foco(), 140, 34, 4)), (x * ESCALA, y * ESCALA))
            cor = CLARO if est != 'bloqueado' else APAGADO
            escrever(tela, ((x + 6) * ESCALA, (y + 8) * ESCALA), nome, 24, cor, 'Bold', 'lm')
            escrever(tela, ((x + 6) * ESCALA, (y + 17) * ESCALA), efeito, 20, DICA if est != 'bloqueado' else APAGADO, ancora='lm')
            for k in range(niv):
                tela.alpha_composite(up(pip.crop((5 if k < tem else 0, 0, 10 if k < tem else 5, 5))), ((x + 6 + k * 7) * ESCALA, (y + 24) * ESCALA))
            if not completo:
                tela.alpha_composite(up(icone_nucleo()), ((x + 112) * ESCALA, (y + 22) * ESCALA))
                escrever(tela, ((x + 110) * ESCALA, (y + 26.5) * ESCALA), str(custos[tem]), 24, FOCO if est == 'disponivel' else APAGADO, 'Bold', 'rm')
            else:
                escrever(tela, ((x + 134) * ESCALA, (y + 26.5) * ESCALA), 'completo', 20, FOCO, ancora='rm')
    escrever(tela, (240 * ESCALA, 246 * ESCALA), 'Clique: comprar o próximo nível · Esc: voltar', 22, DICA, ancora='mm')
    return tela


GAMBIARRAS = [
    ('C', 'Gatilho Leve', '+12% de cadência.', '1 de 3'),
    ('R', 'Perfura-Casco', 'O tiro atravessa +1 inimigo.', 'novo'),
    ('E', 'Rebite Guiado', 'O projétil curva até 15° na direção do inimigo mais próximo.', 'única'),
]


def mockup_gambiarras():
    f = Image.open(os.path.join(RAIZ, 'assets', 'sprites', 'conceito', 'mockup_v02_varrek.png')).convert('RGBA')
    tela = up(f); tela.alpha_composite(Image.new('RGBA', tela.size, (8, 5, 12, 180)))
    escrever(tela, (240 * ESCALA, 34 * ESCALA), 'GAMBIARRA', 46, FOCO, 'Bold', 'mm')
    escrever(tela, (240 * ESCALA, 50 * ESCALA), 'Escolha 1 melhoria para a Mordida (só nesta run)', 26, CLARO, ancora='mm')
    arma = Image.open(os.path.join(RAIZ, 'assets', 'sprites', 'armas', 'icones', 'icone_mordida.png')).convert('RGBA').crop((0, 0, 16, 16))
    W, H, E = 132, 124, 12
    x0 = (480 - (3 * W + 2 * E)) // 2
    for i, (r, nome, efeito, acum) in enumerate(GAMBIARRAS):
        x, y = x0 + i * (W + E), 70 - (4 if i == 1 else 0)
        nome_r, _, _, cor_r = RARIDADES[r]
        tela.alpha_composite(up(np(carta(r), W, H, 10)), (x * ESCALA, y * ESCALA))
        if i == 1:
            tela.alpha_composite(up(np(carta_foco(), W, H, 10)), (x * ESCALA, y * ESCALA))
        tela.alpha_composite(up(gema(r)), ((x + 5) * ESCALA, (y + 2) * ESCALA))
        escrever(tela, ((x + W - 8) * ESCALA, (y + 9.5) * ESCALA), nome_r, 22, hx(cor_r), 'Bold', 'rm')
        tela.alpha_composite(up(up(arma, 2), 1).resize((32 * ESCALA, 32 * ESCALA), Image.NEAREST), ((x + W // 2 - 16) * ESCALA, (y + 20) * ESCALA))
        escrever(tela, ((x + W / 2) * ESCALA, (y + 62) * ESCALA), nome, 32, CLARO, 'Bold', 'mm')
        for k, l in enumerate(quebrar(efeito, 26, (W - 20) * ESCALA, 'Regular')):
            escrever(tela, ((x + W / 2) * ESCALA, (y + 76 + k * 9) * ESCALA), l, 26, CLARO, 'Regular', 'mm', False)
        escrever(tela, ((x + W / 2) * ESCALA, (y + H - 10) * ESCALA), acum, 22, DICA, ancora='mm', sombra=False)
    b = up(np16(botao('normal'), 110, 18)); tela.alpha_composite(b, (185 * ESCALA, 214 * ESCALA))
    escrever(tela, (240 * ESCALA, 223 * ESCALA), 'Recalibrar (1)', 28, CLARO, 'Bold', 'mm')
    return tela


def main():
    A = ('ui', 'arvore')
    salvar(folha([no(e) for e in ESTADOS_NO]), *A, 'no_v2.png')
    salvar(no_foco(), *A, 'no_foco.png')
    salvar(folha([conector(False), conector(True)]), *A, 'conector_v2.png')
    salvar(folha([icone(n) for n in ICONES]), *A, 'ramos.png')
    salvar(icone_ponto(), *A, 'icone_ponto.png')
    salvar(icone_nucleo(), *A, 'icone_nucleo.png')
    salvar(pip_nivel(), *A, 'pip_nivel.png')
    G = ('ui', 'gambiarras')
    salvar(folha([carta(r) for r in 'CRE']), *G, 'carta.png')
    salvar(carta_foco(), *G, 'carta_foco.png')
    salvar(folha([gema(r) for r in 'CRE']), *G, 'raridade.png')
    salvar(mockup_combate(), 'conceito', 'mockup_v09_arvore_combate.png')
    salvar(mockup_passiva(), 'conceito', 'mockup_v10_arvore_passiva.png')
    salvar(mockup_gambiarras(), 'conceito', 'mockup_v11_gambiarras.png')
    print('ok')


if __name__ == '__main__':
    main()
