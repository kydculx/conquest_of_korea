#!/usr/bin/env python3
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE
import os
try:
    import matplotlib.pyplot as _plt
    import matplotlib.patches as _mp
    for _n in ["Circle", "Ellipse", "Rectangle", "Polygon"]:
        setattr(_plt, _n, getattr(_mp, _n))
except Exception:
    pass

OUT = os.path.join(os.path.dirname(__file__), "찜모험_지자체제안서_10장.pptx")
IMGDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "img_light")
DARKDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "img_dark")
COVER_IMG = os.path.join(IMGDIR, "concept_cover.png")
SVC_IMG = os.path.join(IMGDIR, "concept_service.png")
SPOTS_IMG = os.path.join(IMGDIR, "concept_spots.png")
TOWN_IMG = os.path.join(IMGDIR, "concept_town.png")
IMG_WALK = os.path.join(DARKDIR, "walk_goal.png")
IMG_KPI = os.path.join(DARKDIR, "kpi_goal.png")
IMG_FLOW = os.path.join(DARKDIR, "flow.png")

BLACK = RGBColor(0x00, 0x00, 0x00)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
GRAY = RGBColor(0x9A, 0xA5, 0xA1)
DIMGRAY = RGBColor(0x55, 0x55, 0x55)
MINT = RGBColor(0x3D, 0xDC, 0x84)
CORAL = RGBColor(0xFF, 0x6B, 0x4A)
TOTAL = 10

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
prs.core_properties.title = "찜! 모험 지자체 제안서 (키노트)"
prs.core_properties.subject = "시민 건강 운동 + 지역 알리기 - 지자체 제안용"
prs.core_properties.author = "Conquest Mobile"

BLANK = prs.slide_layouts[6]

def set_bg(slide):
    fill = slide.background.fill
    fill.solid()
    fill.fore_color.rgb = BLACK

def add_text(slide, left, top, width, height, runs, alignment=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP):
    txBox = slide.shapes.add_textbox(left, top, width, height)
    tf = txBox.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    first = True
    for text, size, bold, color in runs:
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.alignment = alignment
        p.space_after = Pt(4)
        p.space_before = Pt(2)
        p.line_spacing = 1.05
        run = p.add_run()
        run.text = text
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.color.rgb = color
        run.font.name = "AppleGothic"
    return txBox

def foot(slide, num):
    add_text(slide, Inches(0.6), Inches(7.0), Inches(3.0), Inches(0.3),
             [("찜! 모험", 10, False, DIMGRAY)])
    add_text(slide, Inches(12.0), Inches(7.0), Inches(0.7), Inches(0.3),
             [(f"{int(num)}", 10, False, DIMGRAY)], alignment=PP_ALIGN.RIGHT)

def fit_image(slide, path, left, top, width, max_h):
    pic = slide.shapes.add_picture(path, left, top, width=width)
    if pic.height > max_h:
        r = max_h / pic.height
        pic.height = int(pic.height * r)
        pic.width = int(pic.width * r)
    pic.left = left + int((width - pic.width) / 2)
    return pic

def statement(num, kicker, giants, sub=None, note=""):
    s = prs.slides.add_slide(BLANK)
    set_bg(s)
    add_text(s, Inches(0.8), Inches(0.7), Inches(11.7), Inches(0.5),
             [(kicker, 17, True, GRAY)])
    runs = []
    for i, g in enumerate(giants):
        runs.append((g, 54, True, WHITE if i < len(giants) - 1 or len(giants) == 1 else MINT))
    add_text(s, Inches(0.8), Inches(1.6), Inches(11.7), Inches(3.6), runs)
    if sub:
        add_text(s, Inches(0.8), Inches(5.3), Inches(11.7), Inches(0.8),
                 [(sub, 20, False, GRAY)])
    foot(s, num)
    if note:
        s.notes_slide.placeholders[1].text = note
    return s

def split_slide(num, kicker, giants, sub, image, note=""):
    s = prs.slides.add_slide(BLANK)
    set_bg(s)
    add_text(s, Inches(0.8), Inches(0.7), Inches(6.4), Inches(0.5),
             [(kicker, 17, True, GRAY)])
    runs = [(g, 46, True, WHITE) for g in giants]
    add_text(s, Inches(0.8), Inches(1.5), Inches(6.4), Inches(3.2), runs)
    add_text(s, Inches(0.8), Inches(4.9), Inches(6.4), Inches(1.2),
             [(sub, 19, False, MINT)])
    if image and os.path.exists(image):
        fit_image(s, image, Inches(7.6), Inches(0.9), Inches(5.0), Inches(5.7))
    foot(s, num)
    if note:
        s.notes_slide.placeholders[1].text = note
    return s

def _pin(ax, x, y, s, color):
    import matplotlib.pyplot as plt
    ax.add_patch(plt.Circle((x, y), s, color=color, zorder=5))
    ax.add_patch(plt.Polygon([[x - s * 0.72, y - s * 0.5], [x + s * 0.72, y - s * 0.5], [x, y - s * 1.65]], closed=True, color=color, zorder=5))
    ax.add_patch(plt.Circle((x, y), s * 0.36, color="white", zorder=6))

def _tree(ax, x, y, s):
    import matplotlib.pyplot as plt
    ax.add_patch(plt.Rectangle((x - s * 0.11, y), s * 0.22, s * 0.7, color="#0C4A2A", zorder=4))
    ax.add_patch(plt.Circle((x, y + s * 0.95), s * 0.55, color="#159A52", zorder=4))
    ax.add_patch(plt.Circle((x - s * 0.32, y + s * 0.68), s * 0.34, color="#2FBF6B", zorder=5))

def _cloud(ax, x, y, s):
    import matplotlib.pyplot as plt
    for dx, dy, w, h in [(-0.5, 0, 1.1, 0.55), (0.1, 0.12, 1.3, 0.65), (0.7, 0, 1.0, 0.5)]:
        ax.add_patch(plt.Ellipse((x + dx * s, y + dy * s), w * s, h * s, color="white", zorder=3, alpha=0.95))

def _house(ax, x, y, w, h, body, roof):
    import matplotlib.pyplot as plt
    ax.add_patch(plt.Rectangle((x, y), w, h, color=body, ec="#0C4A2A", lw=1.5, zorder=4))
    ax.add_patch(plt.Polygon([[x - w * 0.12, y + h], [x + w * 1.12, y + h], [x + w * 0.5, y + h * 1.7]], closed=True, color=roof, ec="#0C4A2A", lw=1.2, zorder=4))
    ax.add_patch(plt.Rectangle((x + w * 0.38, y), w * 0.24, h * 0.55, color="#0C4A2A", zorder=5))

def ensure_concepts():
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception:
        return
    os.makedirs(IMGDIR, exist_ok=True)
    if not os.path.exists(COVER_IMG):
        fig, ax = plt.subplots(figsize=(9.6, 6.4))
        fig.patch.set_facecolor("#F4F7F2")
        ax.set_facecolor("#F4F7F2")
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 6.5)
        ax.axis("off")
        ax.add_patch(plt.Circle((8.1, 5.0), 1.45, color="#FDE3D3", zorder=1))
        ax.add_patch(plt.Circle((8.1, 5.0), 0.95, color="#F26B3A", zorder=2))
        _cloud(ax, 2.2, 5.6, 1.1)
        _cloud(ax, 5.6, 5.9, 0.8)
        ax.add_patch(plt.Ellipse((5, -1.4), 15, 6.4, color="#BFE3CC", zorder=2))
        ax.add_patch(plt.Ellipse((5, -3.0), 17, 6.2, color="#8FD0A6", zorder=3))
        path_x = [0.4, 2.2, 3.8, 5.4, 7.0, 8.6, 9.8]
        path_y = [0.5, 1.3, 0.9, 1.9, 1.4, 2.3, 2.0]
        ax.plot(path_x, path_y, color="#EBD9A8", linewidth=30, solid_capstyle="round", solid_joinstyle="round", zorder=3)
        for i in range(0, len(path_x) - 1):
            for k in range(4):
                t = (k + 1) / 5.0
                fx = path_x[i] + (path_x[i + 1] - path_x[i]) * t
                fy = path_y[i] + (path_y[i + 1] - path_y[i]) * t + (0.11 if k % 2 == 0 else -0.11)
                ax.add_patch(plt.Ellipse((fx, fy), 0.23, 0.33, color="#0C4A2A", ec="white", lw=1.4, zorder=4))
        _house(ax, 1.1, 2.2, 1.2, 0.9, "white", "#F26B3A")
        _house(ax, 6.9, 2.9, 1.1, 0.85, "white", "#159A52")
        _tree(ax, 3.1, 1.6, 0.7)
        _tree(ax, 5.6, 2.5, 0.85)
        _tree(ax, 9.0, 3.1, 0.6)
        _pin(ax, 2.2, 3.9, 0.34, "#F26B3A")
        _pin(ax, 5.6, 4.3, 0.4, "#159A52")
        _pin(ax, 8.2, 3.8, 0.34, "#F26B3A")
        plt.tight_layout(pad=0.4)
        fig.savefig(COVER_IMG, facecolor=fig.get_facecolor(), dpi=130)
        plt.close(fig)
    if not os.path.exists(SVC_IMG):
        from matplotlib.patches import FancyBboxPatch
        fig, ax = plt.subplots(figsize=(7.0, 7.0))
        fig.patch.set_facecolor("#FFFFFF")
        ax.set_facecolor("#FFFFFF")
        ax.set_xlim(0, 7)
        ax.set_ylim(0, 7)
        ax.axis("off")
        ax.add_patch(FancyBboxPatch((2.15, 0.5), 2.7, 6.0, boxstyle="round,pad=0.08,rounding_size=0.35", color="#0C4A2A", zorder=3))
        ax.add_patch(FancyBboxPatch((2.38, 1.0), 2.24, 5.05, boxstyle="round,pad=0.02,rounding_size=0.18", color="white", zorder=4))
        ax.add_patch(plt.Circle((3.5, 6.28), 0.09, color="white", zorder=5))
        rx = [2.7, 3.1, 3.0, 3.5, 4.0, 4.3]
        ry = [1.6, 2.4, 3.3, 3.9, 4.6, 5.4]
        ax.plot(rx, ry, color="#159A52", linewidth=7, solid_capstyle="round", solid_joinstyle="round", zorder=5)
        ax.add_patch(plt.Circle((2.7, 1.6), 0.17, color="#0C4A2A", zorder=6))
        _pin(ax, 4.3, 5.75, 0.24, "#F26B3A")
        ax.add_patch(plt.Circle((5.75, 4.9), 0.52, color="#F26B3A", zorder=5))
        ax.add_patch(plt.Circle((5.75, 4.9), 0.30, color="white", zorder=6))
        ax.add_patch(plt.Circle((5.75, 4.9), 0.16, color="#F26B3A", zorder=7))
        _pin(ax, 1.15, 5.4, 0.28, "#159A52")
        _tree(ax, 1.0, 0.9, 0.8)
        _tree(ax, 6.0, 0.9, 0.65)
        for sx, sy in [(5.9, 2.2), (1.6, 3.4), (5.5, 1.1)]:
            ax.add_patch(plt.Circle((sx, sy), 0.13, color="#E4F3E9", ec="#159A52", lw=1.5, zorder=4))
        plt.tight_layout(pad=0.3)
        fig.savefig(SVC_IMG, facecolor=fig.get_facecolor(), dpi=130)
        plt.close(fig)
    if not os.path.exists(SPOTS_IMG):
        fig, ax = plt.subplots(figsize=(9.0, 6.3))
        fig.patch.set_facecolor("#FFFFFF")
        ax.set_facecolor("#E4F3E9")
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 7)
        ax.axis("off")
        for gx in [1.5, 3.5, 5.5, 7.5]:
            ax.plot([gx, gx + 1.2], [0, 7], color="white", linewidth=14, solid_capstyle="round", zorder=2)
        for gy in [1.6, 3.6, 5.4]:
            ax.plot([0, 10], [gy, gy], color="white", linewidth=14, solid_capstyle="round", zorder=2)
        ax.add_patch(plt.Rectangle((6.2, 3.9), 2.6, 2.2, color="#8FD0A6", zorder=3))
        _tree(ax, 6.9, 4.4, 0.55)
        _tree(ax, 7.9, 4.6, 0.7)
        _tree(ax, 7.4, 5.2, 0.5)
        route_x = [1.4, 3.1, 4.6, 6.9, 8.2]
        route_y = [1.6, 3.6, 2.2, 4.9, 2.6]
        ax.plot(route_x, route_y, color="#0C4A2A", linewidth=3.5, linestyle=(0, (6, 4)), zorder=4)
        _pin(ax, 1.4, 2.15, 0.32, "#F26B3A")
        _pin(ax, 3.1, 4.15, 0.32, "#159A52")
        _pin(ax, 4.6, 2.75, 0.32, "#F26B3A")
        _pin(ax, 6.9, 5.45, 0.36, "#159A52")
        _pin(ax, 8.2, 3.15, 0.36, "#F26B3A")
        ax.add_patch(plt.Rectangle((0.5, 0.4), 1.15, 0.85, color="#0C4A2A", zorder=5))
        ax.add_patch(plt.Circle((1.07, 0.82), 0.26, color="white", zorder=6))
        ax.add_patch(plt.Circle((1.07, 0.82), 0.14, color="#0C4A2A", zorder=7))
        plt.tight_layout(pad=0.3)
        fig.savefig(SPOTS_IMG, facecolor=fig.get_facecolor(), dpi=130)
        plt.close(fig)
    if not os.path.exists(TOWN_IMG):
        fig, ax = plt.subplots(figsize=(9.0, 6.3))
        fig.patch.set_facecolor("#FFFFFF")
        ax.set_facecolor("#F4F7F2")
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 7)
        ax.axis("off")
        ax.add_patch(plt.Circle((8.4, 5.6), 0.8, color="#F6C445", zorder=2))
        _cloud(ax, 2.0, 5.9, 1.0)
        _cloud(ax, 6.2, 6.2, 0.7)
        ax.add_patch(plt.Rectangle((0, 0), 10, 1.5, color="#BFE3CC", zorder=2))
        ax.plot([0, 10], [1.5, 1.5], color="#8FD0A6", linewidth=4, zorder=3)
        _house(ax, 0.8, 1.5, 1.7, 1.5, "white", "#F26B3A")
        _house(ax, 3.2, 1.5, 2.0, 1.9, "white", "#0C4A2A")
        _house(ax, 5.9, 1.5, 1.6, 1.4, "white", "#159A52")
        _house(ax, 8.0, 1.5, 1.3, 1.1, "white", "#F26B3A")
        _tree(ax, 2.9, 1.5, 0.6)
        _tree(ax, 5.6, 1.5, 0.7)
        _tree(ax, 7.7, 1.5, 0.55)
        _pin(ax, 1.65, 4.4, 0.32, "#F26B3A")
        _pin(ax, 4.2, 4.9, 0.36, "#159A52")
        _pin(ax, 6.7, 4.2, 0.32, "#F26B3A")
        _pin(ax, 8.65, 3.9, 0.3, "#159A52")
        plt.tight_layout(pad=0.3)
        fig.savefig(TOWN_IMG, facecolor=fig.get_facecolor(), dpi=130)
        plt.close(fig)

def ensure_dark_charts():
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        from matplotlib.font_manager import FontProperties
    except Exception:
        return
    try:
        fp = FontProperties(fname="/System/Library/Fonts/Supplemental/AppleGothic.ttf")
        kw = {"fontproperties": fp}
    except Exception:
        fp = None
        kw = {}
    os.makedirs(DARKDIR, exist_ok=True)
    paper = "#000000"
    ink = "#FFFFFF"
    muted = "#9AA5A1"
    grid = "#2A2A2A"
    if not os.path.exists(IMG_WALK):
        fig, ax = plt.subplots(figsize=(7.0, 4.4))
        fig.patch.set_facecolor(paper)
        ax.set_facecolor(paper)
        weeks = ["1주차", "2주차", "3주차", "4주차"]
        vals = [5000, 6000, 7000, 8000]
        bars = ax.bar(weeks, vals, color="#3DDC84", edgecolor="none", width=0.55)
        ax.set_title("주간 평균 걸음 목표 (예시)", color=ink, fontsize=16, pad=14, **kw)
        ax.tick_params(colors=muted)
        if fp:
            for l in list(ax.get_xticklabels()) + list(ax.get_yticklabels()):
                l.set_fontproperties(fp)
        for b, v in zip(bars, vals):
            ax.text(b.get_x() + b.get_width() / 2, v + 140, f"{v:,}보", ha="center", color=ink, fontsize=12, **kw)
        for spine in ax.spines.values():
            spine.set_visible(False)
        ax.set_ylim(0, 9800)
        ax.yaxis.grid(True, color=grid, linewidth=0.8)
        ax.set_axisbelow(True)
        plt.tight_layout()
        fig.savefig(IMG_WALK, facecolor=fig.get_facecolor(), dpi=130)
        plt.close(fig)
    if not os.path.exists(IMG_KPI):
        fig, ax = plt.subplots(figsize=(7.0, 4.4))
        fig.patch.set_facecolor(paper)
        ax.set_facecolor(paper)
        labels = ["연속 참여율", "명소 방문 달성", "재방문율", "쿠폰 사용률"]
        vals = [60, 70, 45, 30]
        y = list(range(len(labels)))
        bars = ax.barh(y, vals, color=["#3DDC84", "#FF6B4A", "#3DDC84", "#FF6B4A"], height=0.5)
        ax.set_yticks(y)
        ax.set_yticklabels(labels, **kw)
        ax.set_title("파일럿 성공 기준 (예시, %)", color=ink, fontsize=16, pad=14, **kw)
        ax.tick_params(colors=muted)
        if fp:
            for l in list(ax.get_xticklabels()) + list(ax.get_yticklabels()):
                l.set_fontproperties(fp)
        for b, v in zip(bars, vals):
            ax.text(v + 1.5, b.get_y() + b.get_height() / 2, f"{v}%", va="center", color=ink, fontsize=12, **kw)
        for spine in ax.spines.values():
            spine.set_visible(False)
        ax.set_xlim(0, 100)
        ax.invert_yaxis()
        ax.xaxis.grid(True, color=grid, linewidth=0.8)
        ax.set_axisbelow(True)
        plt.tight_layout()
        fig.savefig(IMG_KPI, facecolor=fig.get_facecolor(), dpi=130)
        plt.close(fig)
    if not os.path.exists(IMG_FLOW):
        fig, ax = plt.subplots(figsize=(7.2, 3.2))
        fig.patch.set_facecolor(paper)
        ax.set_facecolor(paper)
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 3)
        ax.axis("off")
        steps = [("시작 2분", "간편 가입"), ("첫 산책", "공원 방문 인증"), ("습관 형성", "매일 기록·보상"), ("추억 축적", "사진·스탬프 공유")]
        for i, (t, d) in enumerate(steps):
            x = 0.55 + i * 2.5
            ax.text(x + 0.8, 1.5, t + "\n" + d, ha="center", va="center", color=ink, fontsize=11,
                    bbox=dict(boxstyle="round,pad=0.45", facecolor="#111111", edgecolor="#3DDC84", linewidth=1.5), **kw)
            if i < 3:
                ax.annotate("", xy=(x + 1.85, 1.5), xytext=(x + 1.65, 1.5),
                            arrowprops=dict(arrowstyle="->", color="#3DDC84", lw=2))
        plt.tight_layout()
        fig.savefig(IMG_FLOW, facecolor=fig.get_facecolor(), dpi=130)
        plt.close(fig)

ensure_concepts()
ensure_dark_charts()

split_slide(1, "기 · 시작", ["매일 걷는 그 길"], "우리 시민의 가장 흔한 운동, 걷기.", COVER_IMG,
            note="대본: 매일 아침, 우리 시민들은 같은 길을 걷습니다. 공원 한 바퀴, 산책로 20분. 가장 흔하고, 가장 건강한 운동. (잠시) 오늘 이야기는 그 길에서 시작합니다.")

statement(2, "기 · 공감", ["혼자 걸으면,", "3일 만에 그만둔다."], "의지가 약해서가 아닙니다. 재미가 없고, 남는 게 없기 때문입니다.",
          note="대본: 그런데. 혼자 걸으면, 3일 만에 그만둡니다. 의지가 약해서가 아닙니다. 재미가 없고, 남는 게 없기 때문입니다. 당연한 결과입니다.")

statement(3, "승 · 발견", ["좋은 곳은 많은데,", "아는 사람은 적다."], "공원도, 산책로도, 이야기도 있습니다. 계기가 없을 뿐입니다.",
          note="대본: 동네를 보세요. 좋은 곳은 많습니다. 공원도, 산책로도, 이야깃거리도. 그런데 아는 사람은 적습니다. (잠시) 좋은 곳이 없는 게 아니라, 알게 될 계기가 없는 겁니다.")

statement(4, "승 · 심화", ["행사는 끝나고.", "남는 게 없다."], "팸플릿도, 스탬프도, 기록도 사라집니다.",
          note="대본: 그래서 행사를 엽니다. 팸플릿을 찍고, 스탬프를 나눠줍니다. 그런데 행사가 끝나면, 남는 게 없습니다. 기록도, 추억도, 다음을 위한 숫자도. 사라집니다.")

split_slide(5, "전 · 반전", ["그 산책길이,", "게임이 된다면?"], "찜! 모험 — 걷는 건 그대로, 의미가 바뀝니다.", SVC_IMG,
            note="대본: 만약. (한 박자) 그 산책길이 게임이 된다면 어떨까요. 같은 길인데, 매일이 달라진다면. 이름하여, 찜! 모험. (잠시) 걷는 건 그대로, 의미가 바뀝니다.")

split_slide(6, "전 · 걷기", ["걷기만 하세요."], "기록은 폰이 합니다. 1주차 5천보부터, 무리 없이.", IMG_WALK,
            note="대본: 걷기만 하세요. 기록은 폰이 합니다. 주머니에 넣고 걷기만 하면 오늘 걸음이 저장됩니다. 1주차 5천보부터, 무리 없이. (차트를 가리키며) 4주면, 걷기가 습관이 됩니다.")

split_slide(7, "전 · 명소", ["가면,", "이야기가 됩니다."], "명소 열 곳 스탬프 + 유래와 사진이 남습니다.", SPOTS_IMG,
            note="대본: 가면, 이야기가 됩니다. 공원에 도착하면 도장이 찍히고, 명소마다 유래와 사진이 쌓입니다. 열 곳을 모으면 기념과 쿠폰. (잠시) 그냥 지나치던 곳이, 목적지가 됩니다.")

split_slide(8, "전 · 함께", ["함께라서,", "계속됩니다."], "주말엔 손주와 명소 세 곳, 평일엔 이웃과 산책 모임.", TOWN_IMG,
            note="대본: 함께라서, 계속됩니다. 주말엔 손주와 명소 세 곳, 평일엔 이웃과 산책 모임. 1년이 지나면 사진첩이 남습니다. (잠시) 운동 기록이 아니라, 우리 가족의 1년입니다.")

split_slide(9, "결 · 증명", ["숫자로 보여드립니다."], "12주 후 — 참여율 · 걸음 · 명소 방문. 기준부터 정합니다.", IMG_KPI,
            note="대본: 그리고 12주 후. 숫자로 보여드립니다. 연속 참여율, 평균 걸음, 명소 방문. (차트를 가리키며) 이 기준은 시작 전에 함께 정합니다. 감이 아니라 숫자로 판단합니다.")

statement(10, "결 · 제안", ["한 개 공원,", "명소 열 곳."], "다음 주부터 시작할 수 있습니다. 감사합니다.",
          note="대본: 필요한 건 작습니다. 한 개 공원, 명소 열 곳. 크게 시작하지 맙시다. 한 곳에서 증명하고, 넓히면 됩니다. 다음 주부터 시작할 수 있습니다. 감사합니다.")

prs.save(OUT)
print(f"saved: {OUT} ({len(prs.slides)} slides)")
