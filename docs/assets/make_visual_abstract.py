#!/usr/bin/env python3
"""Build the README visual abstract as two SVGs (light + dark theme).

    python3 docs/assets/make_visual_abstract.py

Writes visual-abstract-light.svg and visual-abstract-dark.svg next to this
script. Edit the text or the PALETTES below and re-run; the README picks the
right file for the reader's GitHub theme via <picture>.

Only system fonts and CSS animations are used, because GitHub renders README
SVGs as plain images (no web fonts, no scripts, no hover).
"""
import math
from pathlib import Path

W, H = 1000, 730

PALETTES = {
    "light": dict(
        bg="#f6f8fa", panel="#ffffff", line="#d7dee6", ink="#15202b", muted="#566573",
        faint="#e9eef3", astro="#1f8f6a", hom="#d6457a", cortex="#4a3aa7",
        cereb="#e09a00", up="#e34948", down="#2a78d6", serum="#fbeccb",
        vessel="#f6dce3", qbg="#eef1fb",
    ),
    "dark": dict(
        bg="#151b23", panel="#0d1117", line="#2d3640", ink="#e6edf3", muted="#9aa7b4",
        faint="#1f2731", astro="#34b98b", hom="#d55181", cortex="#9085e9",
        cereb="#c98500", up="#e66767", down="#3987e5", serum="#3b3220",
        vessel="#3a2129", qbg="#1c2033",
    ),
}

FONT = "'Helvetica Neue', Helvetica, Arial, 'Liberation Sans', sans-serif"


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def text(x, y, s, cls, anchor="start"):
    a = "" if anchor == "start" else f' text-anchor="{anchor}"'
    return f'<text x="{x}" y="{y}" class="{cls}"{a}>{s}</text>'


def lines(x, y, rows, cls, step):
    return "\n".join(text(x, y + i * step, esc(r), cls) for i, r in enumerate(rows))


def ko(size=8):
    """Superscript −/− for Myorg knockout, built with dy shifts (works everywhere)."""
    return f'<tspan dy="-5" font-size="{size}">−/−</tspan><tspan dy="5"> </tspan>'


def panel(x, y, w, h, eyebrow, title):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" class="panel"/>'
        + text(x + 16, y + 26, eyebrow, "eyebrow")
        + text(x + 16, y + 48, title, "h2")
    )


def astrocyte(cx, cy, r, scale=1.0, cls="astro", endfoot=None):
    """Star-shaped astrocyte: soma + tapering processes."""
    out = [f'<g class="{cls}">']
    for ang, ln in [(200, 34), (150, 30), (250, 32), (110, 28), (300, 30), (65, 26), (345, 0)]:
        if ln == 0:
            continue
        a = math.radians(ang)
        x2 = cx + math.cos(a) * ln * scale
        y2 = cy - math.sin(a) * ln * scale
        mx = cx + math.cos(a + 0.25) * ln * 0.55 * scale
        my = cy - math.sin(a + 0.25) * ln * 0.55 * scale
        out.append(f'<path d="M{cx:.1f},{cy:.1f} Q{mx:.1f},{my:.1f} {x2:.1f},{y2:.1f}" class="proc" '
                   f'stroke-width="{4.5 * scale:.1f}"/>')
    if endfoot:
        ex, ey = endfoot
        out.append(f'<path d="M{cx:.1f},{cy:.1f} L{ex - 5:.1f},{ey:.1f}" class="proc" stroke-width="{4.5 * scale:.1f}"/>')
        out.append(f'<ellipse cx="{ex - 3}" cy="{ey}" rx="4" ry="9" class="foot"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" class="soma"/>')
    out.append("</g>")
    return "\n".join(out)


def mini_astro(cx, cy, cls):
    out = [f'<g class="{cls}">']
    for k in range(6):
        a = math.radians(k * 60 + 15)
        out.append(f'<line x1="{cx}" y1="{cy}" x2="{cx + math.cos(a) * 11:.1f}" y2="{cy - math.sin(a) * 11:.1f}" '
                   f'class="mproc"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="4.5" class="msoma"/></g>')
    return "\n".join(out)


def tri(cx, cy, up, size=7):
    if up:
        pts = f"{cx},{cy - size} {cx + size},{cy + size * 0.7} {cx - size},{cy + size * 0.7}"
    else:
        pts = f"{cx},{cy + size} {cx + size},{cy - size * 0.7} {cx - size},{cy - size * 0.7}"
    return f'<polygon points="{pts}" class="{"tri-up" if up else "tri-down"}"/>'


def build(p):
    css = f"""
  text {{ font-family: {FONT}; fill: {p['ink']}; }}
  .bgcard {{ fill: {p['bg']}; stroke: {p['line']}; }}
  .panel {{ fill: {p['panel']}; stroke: {p['line']}; stroke-width: 1; }}
  .eyebrow {{ font-size: 11px; font-weight: 700; letter-spacing: 1.6px; fill: {p['muted']}; }}
  .title {{ font-size: 26px; font-weight: 700; letter-spacing: -0.3px; }}
  .sub {{ font-size: 14px; fill: {p['muted']}; }}
  .h2 {{ font-size: 16px; font-weight: 700; }}
  .body {{ font-size: 12.5px; }}
  .small {{ font-size: 11px; fill: {p['muted']}; }}
  .lab {{ font-size: 12px; font-weight: 700; }}
  .num {{ font-size: 24px; font-weight: 700; font-variant-numeric: tabular-nums; }}
  .q {{ font-size: 12.5px; font-weight: 700; }}
  .take {{ font-size: 15px; }}
  .take b, .em {{ font-weight: 700; }}
  .step-role {{ font-size: 13px; font-weight: 700; }}
  .step-tool {{ font-size: 11px; }}
  .step-n {{ font-size: 10px; font-weight: 700; fill: {p['muted']}; }}
  .sulcus {{ fill: none; stroke: {p['line']}; stroke-width: 1.4; stroke-linecap: round; }}
  .brain {{ fill: {p['faint']}; stroke: {p['muted']}; stroke-width: 1.4; }}
  .calc {{ fill: {p['hom']}; transform-box: fill-box; transform-origin: center;
           animation: pulse 3.2s ease-in-out infinite; }}
  .astro .proc {{ fill: none; stroke: {p['astro']}; stroke-linecap: round; }}
  .astro .soma {{ fill: {p['astro']}; }}
  .astro .foot {{ fill: {p['astro']}; }}
  .vessel {{ fill: {p['vessel']}; stroke: {p['hom']}; stroke-width: 1.2; stroke-opacity: .55; }}
  .er {{ fill: none; stroke: {p['panel']}; stroke-width: 1.6; stroke-linecap: round; }}
  .koX {{ stroke: {p['hom']}; stroke-width: 3; stroke-linecap: round; }}
  .koRing {{ fill: {p['panel']}; stroke: {p['hom']}; stroke-width: 2; }}
  .leader {{ stroke: {p['muted']}; stroke-width: 1; fill: none; }}
  .well {{ stroke-width: 2.2; }}
  .well.scm {{ fill: {p['serum']}; }}
  .well.sfm {{ fill: {p['panel']}; stroke-dasharray: 4 3; }}
  .cx {{ stroke: {p['cortex']}; }}
  .cb {{ stroke: {p['cereb']}; }}
  .bar-cx {{ fill: {p['cortex']}; }}
  .bar-cb {{ fill: {p['cereb']}; }}
  .wt .mproc {{ stroke: {p['muted']}; stroke-width: 2.2; stroke-linecap: round; }}
  .wt .msoma {{ fill: {p['muted']}; }}
  .hom .mproc {{ stroke: {p['hom']}; stroke-width: 2.2; stroke-linecap: round; }}
  .hom .msoma {{ fill: {p['hom']}; }}
  .tile {{ stroke-width: 1.5; }}
  .tile.up {{ fill: {p['up']}; fill-opacity: .14; stroke: {p['up']}; }}
  .tile.down {{ fill: {p['down']}; fill-opacity: .14; stroke: {p['down']}; }}
  .tri-up {{ fill: {p['up']}; transform-box: fill-box; transform-origin: center; animation: bobUp 2.6s ease-in-out infinite; }}
  .tri-down {{ fill: {p['down']}; transform-box: fill-box; transform-origin: center; animation: bobDown 2.6s ease-in-out infinite; }}
  .qbox {{ fill: {p['qbg']}; }}
  .qmark {{ fill: {p['cortex']}; }}
  .qmark-t {{ font-size: 13px; font-weight: 700; fill: {p['panel']}; }}
  .chev {{ fill: none; stroke: {p['muted']}; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; }}
  .chip {{ fill: {p['panel']}; stroke: {p['line']}; stroke-width: 1.2; animation: glow 8.4s linear infinite; }}
  .track {{ stroke: {p['line']}; stroke-width: 2; stroke-linecap: round; }}
  .packet {{ fill: {p['astro']}; animation: travel 8.4s linear infinite; }}
  .dot-cx {{ fill: {p['cortex']}; }}
  .dot-cb {{ fill: {p['cereb']}; }}
  .rule {{ stroke: {p['line']}; stroke-width: 1; }}
  @keyframes pulse {{ 0%, 100% {{ opacity: .45; transform: scale(.8); }} 50% {{ opacity: 1; transform: scale(1.2); }} }}
  @keyframes bobUp {{ 0%, 100% {{ transform: translateY(1.5px); }} 50% {{ transform: translateY(-1.5px); }} }}
  @keyframes bobDown {{ 0%, 100% {{ transform: translateY(-1.5px); }} 50% {{ transform: translateY(1.5px); }} }}
  @keyframes travel {{ 0% {{ transform: translateX(0); opacity: 0; }} 3% {{ opacity: 1; }} 97% {{ opacity: 1; }} 100% {{ transform: translateX(836px); opacity: 0; }} }}
  @keyframes glow {{ 0%, 14.3%, 100% {{ stroke: {p['line']}; stroke-width: 1.2; }} 3%, 9% {{ stroke: {p['astro']}; stroke-width: 2.2; }} }}
  @media (prefers-reduced-motion: reduce) {{ * {{ animation: none !important; }} }}
"""
    o = []
    o.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
             f'role="img" aria-labelledby="t d">')
    o.append('<title id="t">Visual abstract: how loss of MYORG reshapes the astrocyte transcriptome</title>')
    o.append('<desc id="d">Primary cortical and cerebellar astrocytes from wild-type and Myorg knockout mice were '
             'grown with or without serum (27 RNA-seq libraries, 8 groups, 12 contrasts) and analysed with '
             'STAR, edgeR, limma-voom, fgsea and clusterProfiler. Without serum, Myorg knockout astrocytes show '
             'lower apoptosis and oxidative phosphorylation signatures in cortex but higher ones in cerebellum, '
             'and NF-kB inflammatory signaling is raised in serum-free conditions.</desc>')
    o.append(f"<style>{css}</style>")
    o.append(f'<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="18" class="bgcard"/>')

    # ---- header ----------------------------------------------------------
    o.append(text(36, 44, "VISUAL ABSTRACT  ·  BULK RNA-SEQ  ·  PRIMARY FAMILIAL BRAIN CALCIFICATION (PFBC)", "eyebrow"))
    o.append(text(36, 79, "How loss of MYORG reshapes the astrocyte transcriptome", "title"))
    o.append(f'<text x="36" y="106" class="sub">Primary mouse astrocytes  ·  wild-type vs Myorg{ko(9)}'
             f' ·  cortex vs cerebellum  ·  with vs without serum</text>')

    # ---- panel geometry --------------------------------------------------
    py, ph, pw = 128, 368, 296
    xs = [36, 352, 668]

    # ---- panel 1: question ----------------------------------------------
    x0 = xs[0]
    o.append(panel(x0, py, pw, ph, "QUESTION", "MYORG and brain calcification"))
    bx, by = x0 + 14, py + 66  # brain origin
    o.append(f'<g transform="translate({bx},{by})">')
    o.append('<path class="brain" d="M92,86 C96,100 98,112 96,128 L107,128 C107,113 106,100 109,86 Z"/>')
    o.append('<path class="brain" d="M102,94 C102,82 140,78 148,91 C153,104 134,113 119,111 C108,109 102,103 102,94 Z"/>')
    o.append('<path class="sulcus" d="M110,96 C122,90 136,90 145,95 M108,102 C120,98 134,99 143,102"/>')
    o.append('<path class="brain" d="M16,78 C4,58 12,24 44,12 C72,1 114,2 136,19 C155,33 160,56 151,72 '
             'C145,83 132,86 120,84 C108,82 100,86 93,90 C80,93 70,88 59,92 C42,98 24,94 16,78 Z"/>')
    o.append('<path class="sulcus" d="M74,9 C76,28 68,42 74,58 M38,64 C58,58 80,60 100,68 M114,12 C107,27 115,40 110,52 '
             'M30,34 C40,30 48,36 56,30"/>')
    for i, (cx, cy, r) in enumerate([(64, 54, 3.4), (71, 49, 2.6), (86, 63, 3), (122, 99, 3.2), (130, 97, 2.4)]):
        o.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" class="calc" style="animation-delay:{i * 0.45:.2f}s"/>')
    o.append("</g>")
    o.append(text(bx + 80, py + 214, "calcified deep brain regions", "small", "middle"))

    # astrocyte touching a capillary
    vx = x0 + 268
    o.append(f'<rect x="{vx}" y="{py + 62}" width="14" height="138" rx="7" class="vessel"/>')
    for i, (dx, dy, r) in enumerate([(-2, 82, 3), (15, 108, 2.6), (-1, 166, 3.2), (16, 186, 2.4)]):
        o.append(f'<circle cx="{vx + dx}" cy="{py + dy}" r="{r}" class="calc" style="animation-delay:{0.3 + i * 0.5:.2f}s"/>')
    acx, acy = x0 + 224, py + 132
    o.append(astrocyte(acx, acy, 15, 1.05, endfoot=(vx, acy - 2)))
    o.append(f'<path class="er" d="M{acx - 8},{acy - 4} q4,-4 8,0 t8,0 M{acx - 8},{acy + 3} q4,-4 8,0 t8,0"/>')
    kx, ky = acx - 6, acy + 46
    o.append(f'<path class="leader" d="M{acx - 2},{acy + 12} L{kx + 4},{ky - 10}"/>')
    o.append(f'<circle cx="{kx}" cy="{ky}" r="9" class="koRing"/>')
    o.append(f'<path class="koX" d="M{kx - 4},{ky - 4} L{kx + 4},{ky + 4} M{kx + 4},{ky - 4} L{kx - 4},{ky + 4}"/>')
    o.append(text(kx + 14, ky + 4, "MYORG", "lab"))
    o.append(text(acx + 6, py + 214, "astrocyte", "small", "middle"))

    o.append(lines(x0 + 16, py + 240, [
        "In PFBC, calcium phosphate builds up",
        "in the basal ganglia, thalamus and",
        "cerebellum. MYORG is an ER enzyme",
        "made by astrocytes; losing both",
        "copies causes the recessive form.",
    ], "body", 16.5))
    o.append(f'<rect x="{x0 + 12}" y="{py + 318}" width="{pw - 24}" height="38" rx="8" class="qbox"/>')
    o.append(f'<circle cx="{x0 + 32}" cy="{py + 337}" r="10" class="qmark"/>')
    o.append(text(x0 + 32, py + 342, "?", "qmark-t", "middle"))
    o.append(text(x0 + 50, py + 333, "What changes inside astrocytes", "q"))
    o.append(text(x0 + 50, py + 349, "that lack Myorg?", "q"))

    # ---- panel 2: experiment --------------------------------------------
    x0 = xs[1]
    o.append(panel(x0, py, pw, ph, "EXPERIMENT", "2 × 2 × 2 culture design"))
    gx = x0 + 80   # first well column centre
    dx = 56
    cols = [("cx", "scm", "SCM"), ("cx", "sfm", "SFM"), ("cb", "scm", "SCM"), ("cb", "sfm", "SFM")]
    o.append(text(gx + dx * 0.5, py + 74, "Cortex", "lab", "middle"))
    o.append(text(gx + dx * 2.5, py + 74, "Cerebellum", "lab", "middle"))
    o.append(f'<rect x="{gx - 22}" y="{py + 80}" width="{dx + 44}" height="4" rx="2" class="bar-cx"/>')
    o.append(f'<rect x="{gx + dx * 2 - 22}" y="{py + 80}" width="{dx + 44}" height="4" rx="2" class="bar-cb"/>')
    for i, (_, _, lab) in enumerate(cols):
        o.append(text(gx + dx * i, py + 101, lab, "small", "middle"))
    o.append(f'<rect x="{x0 + 14}" y="{py + 108}" width="{pw - 28}" height="98" rx="10" fill="none" class="rule"/>')
    rows = [("WT", "wt", py + 132), ("HOM", "hom", py + 180)]
    for rlab, rcls, ry in rows:
        o.append(text(x0 + 24, ry + 4, rlab, "lab"))
        for i, (reg, med, _) in enumerate(cols):
            cx = gx + dx * i
            o.append(f'<circle cx="{cx}" cy="{ry}" r="19" class="well {med} {reg}"/>')
            o.append(mini_astro(cx, ry, rcls))
    o.append(text(x0 + 16, py + 228, "SCM = with serum  ·  SFM = serum-free", "small"))
    o.append(f'<text x="{x0 + 16}" y="{py + 244}" class="small">HOM = Myorg{ko(8)}knockout  ·  WT = wild-type</text>')

    stats = [("27", "libraries"), ("8", "groups"), ("2", "seq. runs"), ("12", "contrasts")]
    tw = (pw - 32) / 4
    for i, (n, lab) in enumerate(stats):
        cx = x0 + 16 + tw * i + tw / 2
        o.append(text(f"{cx:.1f}", py + 286, n, "num", "middle"))
        o.append(text(f"{cx:.1f}", py + 303, lab, "small", "middle"))
        if i:
            lx = x0 + 16 + tw * i
            o.append(f'<line x1="{lx:.1f}" y1="{py + 262}" x2="{lx:.1f}" y2="{py + 306}" class="rule"/>')
    o.append(lines(x0 + 16, py + 332, [
        "Standard + low-input mRNA-seq runs;",
        "sequencing run kept in the model.",
    ], "body", 16.5))

    # ---- panel 3: findings ----------------------------------------------
    x0 = xs[2]
    o.append(panel(x0, py, pw, ph, "FINDINGS", "HOM astrocytes without serum"))
    t1, t2, tw2 = x0 + 128, x0 + 206, 72
    o.append(text(t1 + tw2 / 2, py + 72, "Cortex", "lab", "middle"))
    o.append(text(t2 + tw2 / 2, py + 72, "Cerebellum", "lab", "middle"))
    o.append(f'<rect x="{t1}" y="{py + 78}" width="{tw2}" height="4" rx="2" class="bar-cx"/>')
    o.append(f'<rect x="{t2}" y="{py + 78}" width="{tw2}" height="4" rx="2" class="bar-cb"/>')
    grid = [
        (["Apoptosis"], False, True),
        (["Oxidative", "phosphorylation"], False, True),
        (["TNFα signaling", "via NF-κB"], True, True),
    ]
    for r, (lab, cx_up, cb_up) in enumerate(grid):
        ty = py + 90 + r * 50
        if len(lab) == 1:
            o.append(text(x0 + 16, ty + 26, esc(lab[0]), "lab"))
        else:
            o.append(text(x0 + 16, ty + 18, esc(lab[0]), "lab"))
            o.append(text(x0 + 16, ty + 33, esc(lab[1]), "lab"))
        for tx, up in [(t1, cx_up), (t2, cb_up)]:
            o.append(f'<rect x="{tx}" y="{ty}" width="{tw2}" height="42" rx="7" class="tile {"up" if up else "down"}"/>')
            o.append(tri(tx + 17, ty + 21, up))
            o.append(text(tx + 31, ty + 25, "up" if up else "down", "lab"))
    o.append(lines(x0 + 16, py + 268, [
        "Apoptosis and OxPhos fall in cortex",
        "but rise in cerebellum. NF-κB",
        "inflammatory signaling rises",
        "consistently in serum-free medium.",
    ], "body", 16.5))
    o.append(f'<line x1="{x0 + 16}" y1="{py + 334}" x2="{x0 + pw - 16}" y2="{py + 334}" class="rule"/>')
    o.append(tri(x0 + 24, py + 351, True, 5))
    o.append(text(x0 + 33, py + 355, "enriched", "small"))
    o.append(tri(x0 + 92, py + 351, False, 5))
    o.append(text(x0 + 101, py + 355, esc("depleted  ·  GSEA padj < 0.05"), "small"))

    # chevrons between panels
    for cx in (342, 658):
        o.append(f'<path class="chev" d="M{cx - 3},{py + 170} l6,6 l-6,6"/>')

    # ---- workflow strip --------------------------------------------------
    sy, sh = 512, 110
    o.append(f'<rect x="36" y="{sy}" width="928" height="{sh}" rx="12" class="panel"/>')
    o.append(text(52, sy + 26, "WORKFLOW", "eyebrow"))
    o.append(text(140, sy + 26, "Bash on an HPC cluster (SLURM), then R / Bioconductor", "small"))
    steps = [
        ("Reads", "27 × paired-end", "FASTQ"),
        ("Trim + QC", "Trim Galore", "FastQC · ≥ 26 nt"),
        ("Align", "STAR", "sorted BAM"),
        ("Count", "summarizeOverlaps", "GENCODE vM36"),
        ("Normalize", "edgeR · TMM", "filterByExpr"),
        ("Model", "limma-voom", "+ run, eBayes"),
        ("Enrich", "fgsea · enrichGO", "Hallmark + GO"),
    ]
    n = len(steps)
    gap = 10
    cw = (896 - gap * (n - 1)) / n
    o.append(f'<line x1="{52 + cw / 2:.1f}" y1="{sy + 96}" x2="{52 + 896 - cw / 2:.1f}" y2="{sy + 96}" class="track"/>')
    o.append(f'<circle cx="{52 + cw / 2:.1f}" cy="{sy + 96}" r="4.5" class="packet"/>')
    for i, (role, tool, detail) in enumerate(steps):
        cx0 = 52 + i * (cw + gap)
        delay = i * 1.2
        o.append(f'<rect x="{cx0:.1f}" y="{sy + 36}" width="{cw:.1f}" height="50" rx="8" class="chip" '
                 f'style="animation-delay:{delay:.1f}s"/>')
        o.append(text(f"{cx0 + 9:.1f}", sy + 53, f"{i + 1}", "step-n"))
        o.append(text(f"{cx0 + 20:.1f}", sy + 54, esc(role), "step-role"))
        o.append(text(f"{cx0 + 9:.1f}", sy + 69, esc(tool), "step-tool"))
        o.append(text(f"{cx0 + 9:.1f}", sy + 82, esc(detail), "small"))

    # ---- take-home -------------------------------------------------------
    ty = 652
    o.append(text(36, ty, "TAKE-HOME", "eyebrow"))
    o.append(f'<text x="36" y="{ty + 24}" class="take">Without Myorg, serum-starved astrocytes turn on '
             f'<tspan class="em">NF-κB inflammation</tspan>, while <tspan class="em">cell-death and energy</tspan></text>')
    o.append(f'<text x="36" y="{ty + 45}" class="take"><tspan class="em">programs</tspan> move in opposite '
             f'directions in cortex and cerebellum: one mutation, region-specific astrocyte responses.</text>')

    o.append("</svg>")
    return "\n".join(o)


if __name__ == "__main__":
    here = Path(__file__).resolve().parent
    for name, pal in PALETTES.items():
        out = here / f"visual-abstract-{name}.svg"
        out.write_text(build(pal) + "\n", encoding="utf-8")
        print("wrote", out.relative_to(here.parent.parent))
