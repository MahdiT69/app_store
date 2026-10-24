import os

target_dir = r'd:\oussema\Projet pfa\backend\utils'
os.makedirs(target_dir, exist_ok=True)
target_file = os.path.join(target_dir, 'ocr_service.py')

ocr_code = r'''import re
import tempfile
import traceback
from urllib.parse import unquote
import fitz  # PyMuPDF
import requests


def combine_references_in_dict(page_dict):
    """
    Combine references split across two spans based on proximity
    (using PyMuPDF page.get_text("dict") format).
    """
    combined_references = []
    temp_reference = None
    prev_top = None
    prev_left = None
    threshold = 15
    prev_bbox = None

    for block in page_dict.get("blocks", []):
        for line in block.get("lines", []):
            for span in line.get("spans", []):
                text = span.get("text", "")
                bbox = span.get("bbox", None)

                if not text:
                    continue

                if re.match(r'^[A-Za-z]+$', text):
                    temp_reference = text
                    prev_top = span.get('origin', (None, None))[1]
                    prev_left = span.get('origin', (None, None))[0]
                    prev_bbox = bbox

                elif re.match(r'^-\d+$', text.strip()) and temp_reference:
                    prev_right = prev_bbox[2]
                    current_left = bbox[0]

                    if (abs(prev_top - span.get('origin', (None, None))[1]) < threshold
                            and abs(prev_left - span.get('origin', (None, None))[0]) < threshold
                            and (current_left - prev_right) < threshold):
                        combined_reference = temp_reference + text.strip()
                        combined_references.append(combined_reference)
                        temp_reference = None
                    else:
                        combined_references.append(temp_reference)
                        combined_references.append(text.strip())
                        temp_reference = None

                else:
                    if temp_reference:
                        combined_references.append(temp_reference)
                        temp_reference = None
                    combined_references.append(text)

    return combined_references


def extract_delivery_receipt_data(pdf_source):
    """
    Parses a Delivery Receipt PDF using PyMuPDF (fitz).
    Returns structured dict containing:
    - receipt_no
    - invoice_ref
    - items: [{num, product_name, sku, qty_ordered, qty_delivered, discrepancy, has_discrepancy, note}]
    - reference_coords
    - raw_text
    """
    doc = None
    temp_path = None
    try:
        if isinstance(pdf_source, str) and (pdf_source.startswith("http://") or pdf_source.startswith("https://")):
            pdf_url = unquote(pdf_source)
            response = requests.get(pdf_url, timeout=10)
            with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
                tmp.write(response.content)
                temp_path = tmp.name
            doc = fitz.open(temp_path)
        elif isinstance(pdf_source, bytes):
            doc = fitz.open(stream=pdf_source, filetype="pdf")
        else:
            doc = fitz.open(pdf_source)

        raw_text = ""
        reference_coords = []
        items = []
        ref_pattern = r'^(?=.*[A-Za-z0-9])\s*[A-Za-z0-9]+(?:[ *-]+[A-Za-z0-9]+)*\*?\s*$'

        for page_num in range(doc.page_count):
            page = doc.load_page(page_num)
            raw_text += page.get_text("text") + "\n"
            page_dict = page.get_text("dict")

            # 1. Table Extraction using find_tables()
            tabs = page.find_tables()
            for t in tabs:
                rows = t.extract()
                header = [str(c or '').strip().upper() for c in rows[0]] if rows else []
                
                if any("PRODUCT" in c or "QTY" in c or "DELIVERED" in c for c in header):
                    for row in rows[1:]:
                        if not row or not row[0]:
                            continue
                        row_str = " ".join([str(c) for c in row if c])
                        if "TOTAL" in row_str.upper():
                            continue

                        try:
                            num = int(row[0].strip()) if row[0].strip().isdigit() else len(items) + 1
                            p_name = str(row[1] or '').strip() if len(row) > 1 else 'Product'
                            sku = str(row[2] or '').strip() if len(row) > 2 else ''
                            
                            q_ord_str = re.sub(r'[^\d]', '', str(row[3] or '0')) if len(row) > 3 else '0'
                            q_del_str = re.sub(r'[^\d]', '', str(row[4] or '0')) if len(row) > 4 else '0'

                            qty_ord = int(q_ord_str) if q_ord_str else 0
                            qty_del = int(q_del_str) if q_del_str else qty_ord
                            note = str(row[5] or '').strip() if len(row) > 5 else ''

                            discrepancy = qty_del - qty_ord

                            items.append({
                                "num": num,
                                "product_name": p_name,
                                "sku": sku,
                                "qty_ordered": qty_ord,
                                "qty_delivered": qty_del,
                                "discrepancy": discrepancy,
                                "has_discrepancy": discrepancy < 0,
                                "note": note
                            })
                        except Exception as ex:
                            print("Row parse notice:", ex)

            # 2. Extract Spans and Coordinates
            if "blocks" in page_dict:
                pending_prefix = None
                pending_bbox = None
                pending_origin = None

                for block in page_dict.get("blocks", []):
                    if block.get("type") != 0:
                        continue

                    for line in block.get("lines", []):
                        for span in line.get("spans", []):
                            text = span.get("text", "").strip()
                            bbox = span.get("bbox", None)
                            origin = span.get("origin", (None, None))

                            if not text or not bbox:
                                continue

                            if re.match(ref_pattern, text):
                                if text.lower().startswith("alg"):
                                    continue
                                reference_coords.append({
                                    "reference": text,
                                    "coordinates": {
                                        "xPct": (bbox[0] + bbox[2]) / 2 / page.rect.width,
                                        "yPct": (bbox[1] + bbox[3]) / 2 / page.rect.height
                                    }
                                })
                                pending_prefix = None
                                continue

                            if re.match(r'^[A-Z]{2,6}-?$', text):
                                pending_prefix = text
                                pending_bbox = bbox
                                pending_origin = origin
                                continue

                            if pending_prefix and text:
                                vertical_distance = abs(origin[1] - pending_origin[1])
                                horizontal_distance = abs(bbox[0] - pending_bbox[2])

                                if vertical_distance < 15 and horizontal_distance < 30:
                                    combined_ref = pending_prefix + text
                                    if not combined_ref.lower().startswith("alg"):
                                        combined_bbox = [pending_bbox[0], pending_bbox[1], bbox[2], bbox[3]]
                                        reference_coords.append({
                                            "reference": combined_ref,
                                            "coordinates": {
                                                "xPct": (combined_bbox[0] + combined_bbox[2]) / 2 / page.rect.width,
                                                "yPct": (combined_bbox[1] + combined_bbox[3]) / 2 / page.rect.height
                                            }
                                        })
                                pending_prefix = None
                                continue

                            if not re.match(r'^\d{1,2}$', text):
                                pending_prefix = None

        # Extract Meta Fields from raw_text
        receipt_no_match = re.search(r'BL-\d{4}-\d{4}', raw_text)
        receipt_no = receipt_no_match.group(0) if receipt_no_match else ""

        inv_ref_match = re.search(r'INV-\d{4}', raw_text, re.IGNORECASE)
        invoice_ref = inv_ref_match.group(0).upper() if inv_ref_match else ""

        return {
            "success": True,
            "receipt_no": receipt_no,
            "invoice_ref": invoice_ref,
            "items": items,
            "reference_coords": reference_coords,
            "raw_text": raw_text
        }

    except Exception as e:
        print(f"❌ OCR Extraction Error: {e}")
        traceback.print_exc()
        return {
            "success": False,
            "message": str(e),
            "items": [],
            "reference_coords": []
        }
    finally:
        if doc:
            doc.close()
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except Exception:
                pass
'''

with open(target_file, 'w', encoding='utf-8') as f:
    f.write(ocr_code)

print("Updated backend/utils/ocr_service.py successfully!")
