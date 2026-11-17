"""Generate the current report from its reviewed Markdown source."""
from pathlib import Path
import re
from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/reports/BAO_CAO_KY_THUAT.md'
OUTPUT = ROOT / 'docs/reports/Bao_Cao_Giai_Thich_Code_Va_Nguyen_Ly_Module.docx'

def build():
    doc = Document()
    sec = doc.sections[0]
    sec.page_width, sec.page_height = Cm(21), Cm(29.7)
    sec.top_margin = sec.bottom_margin = Cm(1.8)
    sec.left_margin = sec.right_margin = Cm(2)
    for name in ['Normal', 'Title', 'Heading 1', 'Heading 2']:
        style = doc.styles[name]
        style.font.name = 'Arial'
        style.font.color.rgb = RGBColor(0, 0, 0)
    normal = doc.styles['Normal']
    normal.font.size = Pt(10.5)
    normal.paragraph_format.space_after = Pt(7)
    normal.paragraph_format.line_spacing = 1.08
    doc.styles['Title'].font.size = Pt(22)
    doc.styles['Heading 1'].font.size = Pt(15)
    code = doc.styles.add_style('RTL Code', 1)
    code.font.name, code.font.size = 'Consolas', Pt(8.5)
    code.paragraph_format.space_after = Pt(0)
    code.paragraph_format.keep_with_next = True
    lines = SOURCE.read_text(encoding='utf-8-sig').splitlines()
    page = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1; continue
        if line.startswith('# '):
            doc.add_paragraph(line[2:], 'Title')
        elif line.startswith('## '):
            if page: doc.add_page_break()
            page += 1
            doc.add_heading(line[3:], 1)
        elif line.startswith('```'):
            i += 1
            paragraphs = []
            while i < len(lines) and not lines[i].startswith('```'):
                paragraphs.append(doc.add_paragraph(lines[i], 'RTL Code'))
                i += 1
            if paragraphs: paragraphs[-1].paragraph_format.keep_with_next = False
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].startswith('|'):
                if not re.match(r'^\|[\s:|\-]+\|$', lines[i]):
                    rows.append([c.strip() for c in lines[i].strip('|').split('|')])
                i += 1
            table = doc.add_table(rows=0, cols=len(rows[0]))
            table.style = 'Table Grid'
            for ri, row in enumerate(rows):
                cells = table.add_row().cells
                for cell, text in zip(cells, row):
                    cell.text = text
                    for p in cell.paragraphs:
                        p.paragraph_format.space_after = Pt(4)
                        p.paragraph_format.space_before = Pt(4)
                        for run in p.runs:
                            run.font.size = Pt(9)
                            run.bold = ri == 0
                    if ri == 0:
                        shading = OxmlElement('w:shd')
                        shading.set(qn('w:fill'), 'E8EDF2')
                        cell._tc.get_or_add_tcPr().append(shading)
                props = table.rows[-1]._tr.get_or_add_trPr()
                props.append(OxmlElement('w:cantSplit'))
                if ri == 0: props.append(OxmlElement('w:tblHeader'))
            doc.add_paragraph().paragraph_format.space_after = Pt(0)
            continue
        else:
            doc.add_paragraph(line)
        i += 1
    doc.core_properties.title = 'Báo cáo thiết kế hệ thống đèn giao thông FPGA'
    doc.core_properties.author = 'Nguyễn Huy Hân'
    # Remove inherited template paragraph borders, including Title's blue rule.
    for root in [doc.styles.element, doc.element]:
        for border in list(root.iter(qn('w:pBdr'))):
            border.getparent().remove(border)
    doc.save(OUTPUT)
    print(OUTPUT)

if __name__ == '__main__': build()
