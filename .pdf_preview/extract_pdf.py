import fitz
from pathlib import Path

pdf = Path(r"c:\Users\luisj\Downloads\PROPOSTA DE APP (1).pdf")
out = Path(__file__).parent
doc = fitz.open(pdf)
print("pages", doc.page_count)
for i in range(doc.page_count):
    page = doc[i]
    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
    p = out / f"page_{i + 1}.png"
    pix.save(p)
    print("saved", p)
    print("--- TEXT PAGE", i + 1)
    for block in page.get_text("dict")["blocks"]:
        if block.get("type") != 0:
            continue
        for line in block.get("lines", []):
            text = "".join(s["text"] for s in line.get("spans", [])).strip()
            if not text:
                continue
            s0 = line["spans"][0]
            bbox = line["bbox"]
            font = s0.get("font", "")[:40]
            size = s0.get("size", 0)
            print(f"  y={bbox[1]:.0f} size={size:.1f} font={font} | {text}")
