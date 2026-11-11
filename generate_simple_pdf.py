import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, total_pages):
        self.saveState()
        # Top Header line
        self.setStrokeColor(colors.HexColor('#087F73'))
        self.setLineWidth(1)
        self.line(54, letter[1] - 40, letter[0] - 54, letter[1] - 40)

        # Header Text
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor('#087F73'))
        self.drawString(54, letter[1] - 34, "AI-ASSISTED SMART DAIRY APPLICATION")
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor('#64748B'))
        self.drawRightString(letter[0] - 54, letter[1] - 34, "Core Algorithms & Machine Learning Guide")

        # Bottom Footer line
        self.setStrokeColor(colors.HexColor('#CBD5E1'))
        self.setLineWidth(0.5)
        self.line(54, 45, letter[0] - 54, 45)

        # Footer Text
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor('#64748B'))
        self.drawString(54, 32, "Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur")
        page_str = f"Page {self._pageNumber} of {total_pages}"
        self.drawRightString(letter[0] - 54, 32, page_str)
        self.restoreState()

def build_simple_pdf(filename="Smart_Dairy_Algorithms_Simple_Guide.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    primary = colors.HexColor('#087F73')
    primary_dark = colors.HexColor('#065F56')
    dark_text = colors.HexColor('#1E293B')
    muted_text = colors.HexColor('#64748B')

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=primary,
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=muted_text,
        spaceAfter=12
    )

    algo_title = ParagraphStyle(
        'AlgoTitle',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12.5,
        leading=16.5,
        textColor=primary_dark,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    section_header = ParagraphStyle(
        'SectionHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=9.5,
        leading=13,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=4,
        spaceAfter=2,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Simple',
        parent=styles['BodyText'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=dark_text,
        spaceAfter=4
    )

    example_box = ParagraphStyle(
        'Example_Box',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor('#064E3B'),
        backColor=colors.HexColor('#ECFDF5'),
        borderColor=colors.HexColor('#A7F3D0'),
        borderWidth=0.5,
        borderPadding=6,
        spaceBefore=4,
        spaceAfter=6
    )

    th_style = ParagraphStyle(
        'TableHeader',
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.white
    )

    td_style = ParagraphStyle(
        'TableCell',
        fontName='Helvetica',
        fontSize=8,
        leading=10.5,
        textColor=dark_text
    )

    story = []

    # Title Banner
    story.append(Paragraph("Smart Dairy Application: Algorithms Guide", title_style))
    story.append(Paragraph(
        "<b>Simple, Clear Explanation of Machine Learning, Math & Security Algorithms for Viva & Report</b><br/>"
        "Dairy Society: Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur (Code: LDK-402)<br/>"
        "Technology Stack: Flutter Mobile &bull; Java Spring Boot Backend &bull; MongoDB &bull; Random Forest ML &bull; Ollama Llama 3.1",
        subtitle_style
    ))
    story.append(HRFlowable(width="100%", thickness=1.5, color=primary, spaceBefore=0, spaceAfter=10))

    # Summary Table
    story.append(Paragraph("Quick Overview: What Does Each Algorithm Do?", section_header))
    summary_data = [
        [Paragraph("Algorithm", th_style),
         Paragraph("What It Does In Plain Words", th_style),
         Paragraph("Why We Use It", th_style)],

        [Paragraph("<b>1. Dual-Axis Pricing</b>", td_style),
         Paragraph("Calculates milk price (₹/Litre) using both FAT (cream) and SNF (protein/minerals).", td_style),
         Paragraph("Fair payment: farmers with richer milk earn more money automatically.", td_style)],

        [Paragraph("<b>2. Anomaly Detection</b>", td_style),
         Paragraph("Immediately flags watered milk or accidental double-tapping on the weighing scale.", td_style),
         Paragraph("Stops bad milk acceptance and prevents double-payment errors.", td_style)],

        [Paragraph("<b>3. Random Forest Classifier</b>", td_style),
         Paragraph("Machine Learning algorithm using an ensemble of 100 decision trees to predict milk quality grade.", td_style),
         Paragraph("Accurately grades milk (Good / Normal / Attention) by combining FAT, SNF, CLR & Temp.", td_style)],

        [Paragraph("<b>4. Yield Forecaster</b>", td_style),
         Paragraph("Predicts how many litres of milk will arrive tomorrow morning and evening.", td_style),
         Paragraph("Helps the owner arrange the right size milk tanker truck and chiller space.", td_style)],

        [Paragraph("<b>5. Ollama AI Chatbot</b>", td_style),
         Paragraph("A local conversational assistant (like ChatGPT) answering questions in English & Marathi.", td_style),
         Paragraph("Runs 100% locally on laptop/PC: zero cloud bills, fast answers, protects farmer data.", td_style)],

        [Paragraph("<b>6. 10-Day Billing</b>", td_style),
         Paragraph("Consolidates milk earnings every 10 days and automatically cuts cattle feed advances.", td_style),
         Paragraph("Standard Indian dairy cooperative rule: pays farmers cleanly 3 times a month.", td_style)],

        [Paragraph("<b>7. Password & Token Security</b>", td_style),
         Paragraph("Scrambles passwords with BCrypt and creates digital passes (JWT) for login.", td_style),
         Paragraph("Members can only see their own milk and cannot see other farmers' data.", td_style)],

        [Paragraph("<b>8. Offline Mode Sync</b>", td_style),
         Paragraph("Works without internet connection in rural booths and auto-syncs when online.", td_style),
         Paragraph("No work stoppage when mobile internet drops at 6:00 AM collection.", td_style)]
    ]

    t_summary = Table(summary_data, colWidths=[1.6*inch, 3.2*inch, 2.2*inch])
    t_summary.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), primary),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F8FAFC')]),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    story.append(t_summary)
    story.append(Spacer(1, 10))

    # --- Algorithm 1 ---
    story.append(Paragraph("Algorithm 1: Dual-Axis Milk Pricing (Fair Rate Calculation)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> Instead of paying everyone the same flat price, the app checks two things in the milk: <b>FAT</b> (the butterfat cream) and <b>SNF</b> (Solids-Not-Fat: proteins, calcium, and minerals). Richer milk gets a higher rate.", body_style))
    story.append(Paragraph("<b>How it calculates:</b><br/>"
                           "&bull; <b>Cow Milk:</b> Base rate is <b>₹38.00 / Litre</b> (for 3.5% Fat & 8.0% SNF). For every 0.1% higher Fat, add 25 paise; for every 0.1% higher SNF, add 20 paise.<br/>"
                           "&bull; <b>Buffalo Milk:</b> Base rate is <b>₹54.00 / Litre</b> (for 6.0% Fat & 8.5% SNF). For every 0.1% higher Fat, add 30 paise; for every 0.1% higher SNF, add 25 paise.", body_style))
    story.append(Paragraph("<b>Real-Life Example:</b> Farmer Ramesh brings 10 Litres of Cow milk with 4.5% FAT and 8.5% SNF. Because his milk has extra fat and solids, his calculated rate is <b>₹41.50 per Litre</b>. The receipt prints: <code>10 L &times; ₹41.50 = ₹415.00</code>.", example_box))

    # --- Algorithm 2 ---
    story.append(Paragraph("Algorithm 2: Rule-Based Anomaly Detection (Catching Watered Milk & Duplicate Entries)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> Acts like a digital quality inspector sitting at the weighing counter.", body_style))
    story.append(Paragraph("<b>How it works:</b><br/>"
                           "1. <b>Catches Added Water:</b> Pure natural cow milk always has at least 3.0% Fat and 7.5% SNF. If someone mixes water with milk, these numbers drop abnormally low. The algorithm flags it immediately: <i>'Warning: Possible dilution detected!'</i><br/>"
                           "2. <b>Catches Accidental Double Clicks:</b> If the operator accidentally presses the Save button twice for the same farmer on the same morning, the app rejects the duplicate so the farmer doesn't get double-billed.", body_style))
    story.append(Paragraph("<b>Real-Life Example:</b> If milk comes with 2.1% Fat and 6.0% SNF, the app immediately flags it red so the dairy doesn't accept watered milk.", example_box))

    story.append(PageBreak())

    # --- Algorithm 3: RANDOM FOREST ---
    story.append(Paragraph("Algorithm 3: Random Forest Classifier (Milk Quality Prediction & Grading)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> This is our core <b>Machine Learning algorithm</b> that predicts the quality grade of milk. Instead of relying on just 1 rule, think of Random Forest as a <b>committee of 100 decision trees voting together</b>.", body_style))
    story.append(Paragraph("<b>How Random Forest Works in our Dairy:</b><br/>"
                           "When milk is tested on the ultrasonic analyzer, the Random Forest model inspects <b>5 sensor features simultaneously</b>:<br/>"
                           "1. <b>FAT %</b> (Butterfat content)<br/>"
                           "2. <b>SNF %</b> (Protein, calcium, minerals)<br/>"
                           "3. <b>CLR</b> (Corrected Lactometer Reading &mdash; specific density)<br/>"
                           "4. <b>Temperature</b> (Ensures cold-chain freshness)<br/>"
                           "5. <b>Acidity / pH</b> (Detects souring or bacterial growth)<br/>"
                           "Each decision tree in the forest analyzes these features independently and casts a vote. The model takes the <b>majority vote</b> to classify the milk into:<br/>"
                           "&bull; <b>Grade A (Good / Premium):</b> Top-grade pure milk (Quality Score ~86.5% - 98%).<br/>"
                           "&bull; <b>Grade B (Normal / Standard):</b> Standard acceptable commercial milk.<br/>"
                           "&bull; <b>Grade C (Attention Required):</b> Souring, abnormal density, or feed deficiency.", body_style))
    story.append(Paragraph("<b>Why Random Forest is so good:</b> A single if-else condition can easily make mistakes if a sensor is noisy or temperature changes. But because Random Forest combines 100 trees (ensemble learning), it rarely makes mistakes and achieves <b>over 95% classification accuracy</b>.", example_box))

    # --- Algorithm 4 ---
    story.append(Paragraph("Algorithm 4: Yield Prediction (Forecasting Tomorrow's Milk Collection)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> Predicts how many litres of milk will arrive tomorrow so the dairy manager can book the right size transport truck in advance.", body_style))
    story.append(Paragraph("<b>How it works:</b> The algorithm checks the past 7 days of collection logs. It knows that cows naturally produce about <b>56% of their milk in the morning</b> and <b>44% in the evening</b>. It calculates the moving average and tells the owner: <i>'Expected tomorrow: 720 Litres morning, 530 Litres evening.'</i>", body_style))
    story.append(Paragraph("<b>Why it helps:</b> If the dairy expects 1,200 Litres, the owner orders a 1,500 L tanker truck. Without this prediction, milk might sit outside in the heat and spoil if the truck is too small.", example_box))

    # --- Algorithm 5 ---
    story.append(Paragraph("Algorithm 5: Conversational AI Assistant (Local Ollama Llama 3.1)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> A smart, ChatGPT-style helper built right into the app that answers questions in plain English or Marathi (मराठी).", body_style))
    story.append(Paragraph("<b>How it works:</b><br/>"
                           "&bull; It runs <b>100% locally on your computer</b> using Ollama with the <b>Llama 3.1</b> model (no internet needed, zero cloud bill).<br/>"
                           "&bull; It remembers your previous questions in the conversation so you can ask follow-ups like <i>'Explain that more simply'</i> or <i>'Tell me in Marathi'</i>.<br/>"
                           "&bull; <b>Safety Rules:</b> It is strictly programmed never to invent fake milk records and never to reveal passwords.", body_style))
    story.append(Paragraph("<b>Real-Life Example:</b> A farmer asks: <i>'What is SNF?'</i> The AI answers: <i>'SNF means Solids-Not-Fat. It includes all the good nutrients in milk like protein, calcium, and milk sugar, excluding butter fat.'</i>", example_box))

    story.append(PageBreak())

    # --- Algorithm 6 ---
    story.append(Paragraph("Algorithm 6: 10-Day Cooperative Billing Cycle (Automatic Net Pay)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> Village cooperative dairies pay farmers every 10 days (Cycle 1: 1st to 10th, Cycle 2: 11th to 20th, Cycle 3: 21st to end of month). This algorithm computes the final take-home pay automatically.", body_style))
    story.append(Paragraph("<b>How it calculates Net Payable:</b><br/>"
                           "<code>Net Pay = (Total Milk Value) - (Cattle Feed Advance Cut) - (Society Dues) + (Bonus)</code><br/>"
                           "If a farmer took 2 bags of cattle feed on credit (an advance), the app automatically deducts the advance cost from their 10-day earnings and prints a clean WhatsApp-shareable PDF billing slip.", body_style))
    story.append(Paragraph("<b>Real-Life Example:</b> Milk value = ₹15,000. Cattle feed advance = ₹3,000. Net payment credited to bank = ₹12,000.", example_box))

    # --- Algorithm 7 ---
    story.append(Paragraph("Algorithm 7: Security & Account Protection (BCrypt & JWT)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> Keeps farmer accounts, passwords, and private money information completely safe.", body_style))
    story.append(Paragraph("<b>How it works:</b><br/>"
                           "1. <b>BCrypt Password Scrambler:</b> Passwords are never saved as plain text. Even if someone opens the database, they only see an unreadable scrambled hash (e.g. <code>$2a$10$e8w9F...</code>).<br/>"
                           "2. <b>JWT Digital Pass:</b> When a farmer logs in, the server gives their phone a temporary digital badge (JSON Web Token). The phone uses this badge to view records. A Member's badge only unlocks their own milk passbook—they can never see another farmer's money or change dairy records.", body_style))
    story.append(Paragraph("<b>Why it helps:</b> Dairy Owner and Farmers can use separate phones without any risk of data tampering or leaking.", example_box))

    # --- Algorithm 8 ---
    story.append(Paragraph("Algorithm 8: Offline-First Synchronization (Works Without Internet)", algo_title))
    story.append(Paragraph("<b>In Simple Words:</b> Ensures the dairy collection booth never stops working even when the village mobile tower has zero signal.", body_style))
    story.append(Paragraph("<b>How it works:</b><br/>"
                           "&bull; At 6:00 AM, if there is no internet, the app saves collections on the phone's internal storage in <b>0 milliseconds</b> and prints receipts.<br/>"
                           "&bull; It places unsynced records into a waiting queue.<br/>"
                           "&bull; As soon as mobile data or Wi-Fi reconnects, the background synchronizer quietly sends all pending records to the central MongoDB database.", body_style))
    story.append(Paragraph("<b>Real-Life Example:</b> Morning collection of 80 farmers finishes smoothly on an Android tablet with zero internet. When the operator reaches home on Wi-Fi, all 80 records sync to the cloud in 2 seconds.", example_box))
    story.append(Spacer(1, 10))

    # Summary Conclusion Callout
    story.append(Paragraph("How to Explain Your Project in 30 Seconds during Viva:", section_header))
    story.append(Paragraph("<i>'Our project uses <b>Random Forest Machine Learning</b> to grade milk quality from sensor readings, a <b>Dual-Axis Mathematical Formula</b> to pay farmers fair rates based on Fat and SNF, an <b>Anomaly Detection algorithm</b> to catch watered milk, and a <b>Local Ollama Llama 3.1 AI Chatbot</b> to answer farmer questions in English and Marathi, with <b>BCrypt security</b> and <b>100% offline support</b>.'</i>", example_box))

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Simple PDF generated successfully: {filename}")

if __name__ == '__main__':
    out_file = sys.argv[1] if len(sys.argv) > 1 else "Smart_Dairy_Algorithms_Simple_Guide.pdf"
    build_simple_pdf(out_file)
