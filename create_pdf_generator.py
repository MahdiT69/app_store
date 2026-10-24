import os

target_dir = r'd:\oussema\Projet pfa\backend\utils'
os.makedirs(target_dir, exist_ok=True)

target_file = os.path.join(target_dir, 'pdf_generator.py')

pdf_gen_code = '''import os
import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT

def generate_delivery_receipt_pdf(output_path, invoice_data):
    """
    Generates a professional Delivery Receipt PDF matching the ShopYme template.
    """
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()

    # Colors
    c_dark = colors.HexColor('#16161A')
    c_gold = colors.HexColor('#D4A94D')
    c_border = colors.HexColor('#E5E7EB')
    c_header_bg = colors.HexColor('#111827')
    c_text_muted = colors.HexColor('#6B7280')
    c_red = colors.HexColor('#DC2626')

    story = []

    # Title & Header
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=colors.white,
        alignment=TA_RIGHT
    )
    sub_title_style = ParagraphStyle(
        'DocSubTitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=12,
        textColor=colors.HexColor('#9CA3AF'),
        alignment=TA_RIGHT
    )
    logo_style = ParagraphStyle(
        'LogoText',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=colors.white
    )

    header_table_data = [
        [
            Paragraph('<font color="#D4A94D"><b>SHOPYME.</b></font>', logo_style),
            [
                Paragraph('<b>DELIVERY RECEIPT</b>', title_style),
                Paragraph('Bon de livraison', sub_title_style)
            ]
        ]
    ]

    header_table = Table(header_table_data, colWidths=[200, 340])
    header_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), c_header_bg),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 16),
        ('BOTTOMPADDING', (0,0), (-1,-1), 16),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 16))

    # Meta Grid Box
    meta_label = ParagraphStyle('MetaLabel', fontName='Helvetica-Bold', fontSize=8, leading=10, textColor=c_text_muted)
    meta_val = ParagraphStyle('MetaVal', fontName='Helvetica-Bold', fontSize=11, leading=13, textColor=c_dark)

    receipt_no = invoice_data.get('receipt_no', f"BL-2026-{invoice_data.get('id', 1):04d}")
    inv_ref = invoice_data.get('invoice_ref', f"INV-{invoice_data.get('id', 1):04d}")
    ship_date = invoice_data.get('ship_date', datetime.date.today().strftime('%d / %m / %Y'))
    order_date = invoice_data.get('order_date', datetime.date.today().strftime('%d / %m / %Y'))

    meta_data = [
        [
            Paragraph('RECEIPT NO.', meta_label),
            Paragraph('INVOICE REF.', meta_label),
            Paragraph('SHIP DATE', meta_label),
            Paragraph('STATUS', meta_label)
        ],
        [
            Paragraph(receipt_no, meta_val),
            Paragraph(inv_ref, meta_val),
            Paragraph(ship_date, meta_val),
            Paragraph(invoice_data.get('status', 'SHIPPED').upper(), meta_val)
        ],
        [
            Paragraph('ORDER DATE', meta_label),
            Paragraph('CARRIER', meta_label),
            Paragraph('PACKAGES', meta_label),
            Paragraph('TRACKING', meta_label)
        ],
        [
            Paragraph(order_date, meta_val),
            Paragraph(invoice_data.get('carrier', 'Express Tunis'), meta_val),
            Paragraph(str(invoice_data.get('packages', '3')), meta_val),
            Paragraph(invoice_data.get('tracking', 'TN-88420913'), meta_val)
        ]
    ]

    meta_table = Table(meta_data, colWidths=[135, 135, 135, 135])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F9FAFB')),
        ('BOX', (0,0), (-1,-1), 1, c_border),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 16))

    # Supplier & Deliver To Box
    sec_title = ParagraphStyle('SecTitle', fontName='Helvetica-Bold', fontSize=9, leading=11, textColor=c_gold)
    sec_body_bold = ParagraphStyle('SecBodyB', fontName='Helvetica-Bold', fontSize=11, leading=14, textColor=c_dark)
    sec_body = ParagraphStyle('SecBody', fontName='Helvetica', fontSize=10, leading=13, textColor=c_text_muted)

    sup_name = invoice_data.get('supplier_name', 'TechParts Distribution')
    sup_email = invoice_data.get('supplier_email', 'contact@supplier.tn')
    emp_name = invoice_data.get('employee_name', 'ShopYme Warehouse')

    addr_data = [
        [
            [
                Paragraph('SUPPLIER', sec_title),
                Spacer(1, 4),
                Paragraph(sup_name, sec_body_bold),
                Paragraph(sup_email, sec_body),
            ],
            [
                Paragraph('DELIVER TO', sec_title),
                Spacer(1, 4),
                Paragraph('ShopYme Central Warehouse', sec_body_bold),
                Paragraph(f'Attn: {emp_name}', sec_body),
                Paragraph('Zone Industrielle, Tunis', sec_body),
            ]
        ]
    ]
    addr_table = Table(addr_data, colWidths=[270, 270])
    addr_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('PADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(addr_table)
    story.append(Spacer(1, 18))

    # Items Table
    th_style = ParagraphStyle('TH', fontName='Helvetica-Bold', fontSize=9, leading=11, textColor=colors.white)
    td_style = ParagraphStyle('TD', fontName='Helvetica', fontSize=10, leading=13, textColor=c_dark)
    td_bold = ParagraphStyle('TDB', fontName='Helvetica-Bold', fontSize=10, leading=13, textColor=c_dark)
    td_red = ParagraphStyle('TDR', fontName='Helvetica-Bold', fontSize=10, leading=13, textColor=c_red)
    td_note_red = ParagraphStyle('TDNR', fontName='Helvetica', fontSize=9, leading=11, textColor=c_red)

    table_data = [
        [
            Paragraph('#', th_style),
            Paragraph('PRODUCT', th_style),
            Paragraph('SKU', th_style),
            Paragraph('QTY ORDERED', th_style),
            Paragraph('QTY DELIVERED', th_style),
            Paragraph('NOTE', th_style)
        ]
    ]

    items = invoice_data.get('items', [])
    tot_ordered = 0
    tot_delivered = 0

    for idx, item in enumerate(items, 1):
        q_ord = item.get('qty_requested', item.get('qty_ordered', 0))
        q_del = item.get('qty_confirmed', item.get('qty_delivered', q_ord))
        if q_del is None:
            q_del = q_ord

        tot_ordered += q_ord
        tot_delivered += q_del

        has_disc = q_del < q_ord
        note_str = item.get('note', '')
        if has_disc and not note_str:
            note_str = f"Backorder {q_ord - q_del}"

        sku_val = item.get('category', item.get('sku', ''))
        if not sku_val:
            sku_val = f"PER-{item.get('product_id', idx):03d}"

        table_data.append([
            Paragraph(str(idx), td_style),
            Paragraph(item.get('product_name', item.get('name', 'Product')), td_bold),
            Paragraph(sku_val, td_style),
            Paragraph(str(q_ord), td_bold),
            Paragraph(str(q_del), td_red if has_disc else td_bold),
            Paragraph(note_str, td_note_red if has_disc else td_style)
        ])

    table_data.append([
        Paragraph('TOTAL UNITS', td_bold),
        '', '',
        Paragraph(str(tot_ordered), td_bold),
        Paragraph(str(tot_delivered), td_bold),
        ''
    ])

    items_table = Table(table_data, colWidths=[30, 180, 90, 80, 90, 70])
    ts = [
        ('BACKGROUND', (0,0), (-1,0), c_header_bg),
        ('ALIGN', (0,0), (-1,-1), 'LEFT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-2), 0.5, c_border),
        ('PADDING', (0,0), (-1,-1), 8),
        ('BACKGROUND', (0,-1), (-1,-1), colors.HexColor('#FEF3C7')),
        ('SPAN', (0,-1), (2,-1)),
    ]
    items_table.setStyle(TableStyle(ts))
    story.append(items_table)
    story.append(Spacer(1, 16))

    # Notes Box
    notes_txt = invoice_data.get('notes', '')
    if not notes_txt:
        discrepancies = [i for i in items if (i.get('qty_confirmed') or i.get('qty_delivered', i.get('qty_requested', 0))) < i.get('qty_requested', i.get('qty_ordered', 0))]
        if discrepancies:
            notes_lines = []
            for d in discrepancies:
                q_o = d.get('qty_requested', d.get('qty_ordered', 0))
                q_c = d.get('qty_confirmed', d.get('qty_delivered', q_o))
                notes_lines.append(f"{d.get('product_name', 'Item')}: only {q_c} of {q_o} available. Remaining {q_o - q_c} units backordered.")
            notes_txt = " ".join(notes_lines)

    if notes_txt:
        n_title = ParagraphStyle('NTitle', fontName='Helvetica-Bold', fontSize=9, leading=11, textColor=c_dark)
        n_body = ParagraphStyle('NBody', fontName='Helvetica', fontSize=9, leading=12, textColor=c_text_muted)
        notes_table_data = [
            [
                [
                    Paragraph('NOTES', n_title),
                    Spacer(1, 4),
                    Paragraph(notes_txt, n_body)
                ]
            ]
        ]
        notes_table = Table(notes_table_data, colWidths=[540])
        notes_table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F9FAFB')),
            ('BOX', (0,0), (-1,-1), 1, c_border),
            ('PADDING', (0,0), (-1,-1), 10),
        ]))
        story.append(notes_table)
        story.append(Spacer(1, 20))

    # Footer Signatures
    sig_label = ParagraphStyle('SigLabel', fontName='Helvetica', fontSize=8, leading=10, textColor=c_text_muted)
    sig_data = [
        [
            [
                HRFlowable(width="100%", thickness=1, color=c_border, spaceAfter=4),
                Paragraph('Supplier signature and stamp', sig_label)
            ],
            [
                HRFlowable(width="100%", thickness=1, color=c_border, spaceAfter=4),
                Paragraph('Received by (name, date, signature)', sig_label)
            ]
        ]
    ]
    sig_table = Table(sig_data, colWidths=[240, 240])
    story.append(sig_table)

    doc.build(story)
    print(f"Generated PDF Delivery Receipt at {output_path}")
    return output_path
'''

with open(target_file, 'w', encoding='utf-8') as f:
    f.write(pdf_gen_code)

print("Created backend/utils/pdf_generator.py successfully!")
