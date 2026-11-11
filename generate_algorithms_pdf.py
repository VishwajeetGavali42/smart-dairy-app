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
        self.drawRightString(letter[0] - 54, letter[1] - 34, "Core Algorithms & Implementation Specification")

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

def build_pdf(filename="Smart_Dairy_Algorithms_Documentation.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    # Custom styles
    primary = colors.HexColor('#087F73')
    dark_text = colors.HexColor('#0F172A')
    muted_text = colors.HexColor('#475569')

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=primary,
        spaceAfter=6
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=muted_text,
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=19,
        textColor=primary,
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor('#1E293B'),
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['BodyText'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13.5,
        textColor=dark_text,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=3
    )

    code_style = ParagraphStyle(
        'Formula_Box',
        parent=styles['Normal'],
        fontName='Courier-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#044E46'),
        backColor=colors.HexColor('#F0FDF4'),
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
    story.append(Paragraph("AI-Assisted Smart Dairy Application", title_style))
    story.append(Paragraph("<b>Complete Algorithms & Mathematical Formulations Specification</b><br/>"
                           "Dairy Center: Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur | Center Code: LDK-402<br/>"
                           "Architecture: Flutter (Frontend) &bull; Spring Boot 3.4 (Backend) &bull; MongoDB &bull; Local Ollama Llama 3.1 (AI)", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=primary, spaceBefore=0, spaceAfter=12))

    # Executive Summary Table
    story.append(Paragraph("1. Algorithm Taxonomy & Quick Reference", h1_style))
    story.append(Paragraph("The application leverages 8 foundational algorithms across pricing, automated quality assurance, predictive logistics, natural language understanding, and cryptographic security:", body_style))

    overview_data = [
        [Paragraph("Algorithm Name", th_style),
         Paragraph("Category", th_style),
         Paragraph("Core Code Location", th_style),
         Paragraph("Key Purpose & Value", th_style)],

        [Paragraph("<b>1. Dual-Axis Pricing Matrix</b>", td_style),
         Paragraph("Economics / Pricing", td_style),
         Paragraph("MilkCollectionService.java<br/>ApiService.dart", td_style),
         Paragraph("Fair farmer valuation based on both butterfat (FAT) & non-fat solids (SNF)", td_style)],

        [Paragraph("<b>2. Statistical Anomaly Filter</b>", td_style),
         Paragraph("Quality Assurance", td_style),
         Paragraph("AiGatewayController.java<br/>ApiService.dart", td_style),
         Paragraph("Instant detection of milk watering, chemical dilution, or duplicate entry", td_style)],

        [Paragraph("<b>3. Composite Quality Index</b>", td_style),
         Paragraph("Decision Scoring", td_style),
         Paragraph("AiGatewayController.java", td_style),
         Paragraph("Instant 0–100 quality scoring and grading (Premium/Good/Standard)", td_style)],

        [Paragraph("<b>4. Yield Trend Forecaster</b>", td_style),
         Paragraph("Time-Series Analytics", td_style),
         Paragraph("AiGatewayController.java", td_style),
         Paragraph("Moving-average prediction for morning/evening shifts & tanker logistics", td_style)],

        [Paragraph("<b>5. Autoregressive LLM (Llama 3.1)</b>", td_style),
         Paragraph("Conversational AI", td_style),
         Paragraph("OllamaService.java<br/>AiAssistantService.java", td_style),
         Paragraph("Local natural language understanding, bilingual QA, zero cloud costs", td_style)],

        [Paragraph("<b>6. 10-Day Cycle Net Settlement</b>", td_style),
         Paragraph("Financial Accounting", td_style),
         Paragraph("PdfExportService.java<br/>detailed_bill_statement.dart", td_style),
         Paragraph("Automated recovery of cattle feed advances & cyclic net payable computation", td_style)],

        [Paragraph("<b>7. BCrypt & HMAC-SHA256</b>", td_style),
         Paragraph("Cryptographic Security", td_style),
         Paragraph("SecurityConfig.java<br/>JwtTokenProvider.java", td_style),
         Paragraph("Salting/hashing passwords and stateless tokenized role-based access", td_style)],

        [Paragraph("<b>8. Optimistic Offline Sync</b>", td_style),
         Paragraph("Distributed Systems", td_style),
         Paragraph("ApiService.dart<br/>dataChangeNotifier", td_style),
         Paragraph("Zero-downtime booth operation during network drops with automatic queue sync", td_style)],
    ]

    t_overview = Table(overview_data, colWidths=[1.5*inch, 1.2*inch, 1.6*inch, 2.7*inch])
    t_overview.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), primary),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F8FAFC')]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(t_overview)
    story.append(Spacer(1, 14))

    # Algorithm 1: Dual-Axis Pricing
    story.append(Paragraph("2. Dual-Axis Milk Pricing Algorithm (FAT & SNF Matrix)", h1_style))
    story.append(Paragraph("<b>Concept:</b> Standard Indian dairy cooperative pricing relies on both <i>Fat</i> (butterfat) and <i>Solids-Not-Fat (SNF)</i> (protein, lactose, minerals). Unlike flat rate models, this ensures scientific accuracy and incentivizes high-quality dairy farming.", body_style))
    story.append(Paragraph(
        "<b>Mathematical Formula:</b><br/>"
        "Rate (₹/Ltr) = BaseRate + [(FAT - MinFAT) &times; 10 &times; FatStep] + [(SNF - MinSNF) &times; 10 &times; SnfStep]<br/>"
        "Total Collection Amount (₹) = Quantity (Litres) &times; Calculated Rate (₹/Ltr)", code_style))
    story.append(Paragraph("<b>Benchmark Operational Parameters:</b>", h2_style))
    story.append(Paragraph("&bull; <b>Cow Milk:</b> Base Rate = ₹38.00/L (at Min FAT 3.5%, Min SNF 8.0%). FatStep = ₹0.25 per 0.1%, SnfStep = ₹0.20 per 0.1%.", bullet_style))
    story.append(Paragraph("&bull; <b>Buffalo Milk:</b> Base Rate = ₹54.00/L (at Min FAT 6.0%, Min SNF 8.5%). FatStep = ₹0.30 per 0.1%, SnfStep = ₹0.25 per 0.1%.", bullet_style))
    story.append(Paragraph("&bull; <b>Strict Validation Boundaries:</b> Quantity &isin; [0.1 L, 1000.0 L] (Preserving exact decimals without integer rounding), FAT &isin; [1.0%, 15.0%], SNF &isin; [4.0%, 15.0%].", bullet_style))
    story.append(Spacer(1, 12))

    # Algorithm 2: Anomaly Detection
    story.append(Paragraph("3. Rule-Based Statistical Anomaly Detection Algorithm", h1_style))
    story.append(Paragraph("<b>Concept:</b> Detects physical milk tampering (watering down or chemical adulteration) and operator duplicate submission before records are permanently written to MongoDB.", body_style))
    story.append(Paragraph("<b>Heuristic Rules & Thresholds:</b>", h2_style))
    story.append(Paragraph("&bull; <b>Water Dilution Screening:</b> If <code>FAT &lt; 3.0%</code> or <code>SNF &lt; 7.5%</code>, the system flags the batch as <i>'Severe Dilution Outlier'</i> with a confidence score of 0.85.", bullet_style))
    story.append(Paragraph("&bull; <b>Chemical Spiking Screening:</b> If <code>FAT &gt; 12.0%</code> or <code>SNF &gt; 12.0%</code>, the batch is flagged as <i>'Biological Improbability / Additive Alert'</i> requiring mandatory laboratory re-inspection.", bullet_style))
    story.append(Paragraph("&bull; <b>Duplicate Submission Collision:</b> Composite constraint hash <code>H(memberCode, date, shift, quantity &plusmn; 0.001)</code> prevents accidental double-tapping on Bluetooth hardware weighing scales.", bullet_style))
    story.append(Spacer(1, 12))

    # Page Break for clean multi-page layout
    story.append(PageBreak())

    # Algorithm 3: Quality Scoring
    story.append(Paragraph("4. Multi-Criteria Composite Quality Scoring Algorithm", h1_style))
    story.append(Paragraph("<b>Concept:</b> Converts multi-sensor analyzer readings into a unified 0–100 Quality Purity Score and assigns commercial grades instantly at collection booths.", body_style))
    story.append(Paragraph(
        "<b>Scoring Formulation:</b><br/>"
        "Quality Score = 100 - [&omega;<sub>1</sub> &times; |FAT - BenchmarkFAT| &times; 10] - [&omega;<sub>2</sub> &times; |SNF - BenchmarkSNF| &times; 10] - Penalties<br/>"
        "Weights: &omega;<sub>1</sub> = 0.55 (Fat Weight), &omega;<sub>2</sub> = 0.45 (SNF Weight)", code_style))
    story.append(Paragraph("<b>Grade Categorization:</b>", h2_style))
    story.append(Paragraph("&bull; <b>Score &ge; 90:</b> <i>Premium Grade</i> (Top-tier milk, eligible for annual society quality dividend bonus).", bullet_style))
    story.append(Paragraph("&bull; <b>Score 75–89:</b> <i>Standard Grade</i> (Good commercial milk meeting cooperative standard benchmarks).", bullet_style))
    story.append(Paragraph("&bull; <b>Score &lt; 75:</b> <i>Substandard / Attention Required</i> (Notifies farmer on milk slip with nutritional advice for cattle feed).", bullet_style))
    story.append(Spacer(1, 12))

    # Algorithm 4: Yield Forecasting
    story.append(Paragraph("5. Time-Series Yield Forecasting & Trend Estimation", h1_style))
    story.append(Paragraph("<b>Concept:</b> Predictive analytics algorithm that forecasts morning and evening shift volumes for logistics management (tanker dispatching, chiller power scheduling).", body_style))
    story.append(Paragraph("<b>Methodology:</b>", h2_style))
    story.append(Paragraph("&bull; <b>Exponential Rolling Moving Average:</b> Analyzes the past 7-day rolling window of shift collections weighted towards recent days.", bullet_style))
    story.append(Paragraph("&bull; <b>Shift Disparity Ratio:</b> Accounts for diurnal biological patterns where cows yield ~56% of daily volume in the Morning shift and ~44% in the Evening shift.", bullet_style))
    story.append(Paragraph("&bull; <b>Trend Directionality:</b> Computes rate of change (&Delta;Q = (Q<sub>current</sub> - Q<sub>previous</sub>)/Q<sub>previous</sub> &times; 100) indicating rising (&uarr;) or declining (&darr;) dairy yield.", bullet_style))
    story.append(Spacer(1, 12))

    # Algorithm 5: Conversational AI
    story.append(Paragraph("6. Local Conversational AI Architecture (Meta Llama 3.1 via Ollama)", h1_style))
    story.append(Paragraph("<b>Concept:</b> Enables genuine conversational artificial intelligence in natural language (English & Marathi) without depending on external cloud APIs or risking farmer privacy.", body_style))
    story.append(Paragraph("<b>Core Components:</b>", h2_style))
    story.append(Paragraph("&bull; <b>Model Specification:</b> <code>llama3.1:latest</code> (8.0 Billion parameters, Q4_K_M quantized GGUF format, 128k context window).", bullet_style))
    story.append(Paragraph("&bull; <b>Local Daemon Endpoint:</b> Direct HTTP/1.1 communication to <code>http://127.0.0.1:11434/api/chat</code> via Spring Boot's <code>OllamaService.java</code>.", bullet_style))
    story.append(Paragraph("&bull; <b>Domain Knowledge Grounding:</b> System prompt enforces strict constraints against inventing fictitious records or revealing user credentials.", bullet_style))
    story.append(Paragraph("&bull; <b>Sliding-Window Dialogue Management:</b> Retains the last 10–15 messages across multi-turn conversation sessions.", bullet_style))
    story.append(Paragraph("&bull; <b>Greedy Sampling Parameters:</b> Configured with <code>temperature = 0.3</code>, <code>num_predict = 350</code>, ensuring concise, factual answers in under 12 seconds on consumer CPUs.", bullet_style))
    story.append(Spacer(1, 12))

    # Algorithm 6: 10-Day Billing Cycle
    story.append(Paragraph("7. 10-Day Cooperative Billing Cycle Net Settlement Algorithm", h1_style))
    story.append(Paragraph("<b>Concept:</b> Implements the statutory Indian cooperative dairy billing system where payments are consolidated every 10 days rather than monthly.", body_style))
    story.append(Paragraph(
        "<b>Cycle Settlement Formulation:</b><br/>"
        "Net Payable = Gross Milk Amount - Recovered Cattle Feed Advances - Society Deductions + Quality Bonus<br/>"
        "Gross Milk Amount = &sum;<sub>i=1..N</sub> (Quantity<sub>i</sub> &times; Rate<sub>i</sub>)", code_style))
    story.append(Paragraph("<b>Cycle Partitions:</b> Cycle 1 (Days 1–10), Cycle 2 (Days 11–20), Cycle 3 (Day 21 to End of Month).", bullet_style))
    story.append(Paragraph("<b>Automated Advance Prorating:</b> Outstanding cattle feed loans are automatically amortized against cycle gross earnings. The balance carries over to the subsequent cycle until zeroed out.", bullet_style))
    story.append(Spacer(1, 12))

    # Algorithm 7: Security & Cryptography
    story.append(Paragraph("8. Cryptographic Security & Offline Synchronization Algorithms", h1_style))
    story.append(Paragraph("<b>BCrypt Password Hashing:</b>", h2_style))
    story.append(Paragraph("&bull; Employs the Blowfish-based adaptive hashing algorithm with 10 salt rounds (cost factor 2<sup>10</sup> = 1024 iterations), rendering brute-force dictionary attacks computationally infeasible.", bullet_style))
    story.append(Paragraph("<b>HMAC-SHA256 Stateless Tokenization (JWT):</b>", h2_style))
    story.append(Paragraph("&bull; Compact, digitally signed tokens containing user claims, role permissions, and a 24-hour expiration window. Allows Owner and Member accounts to operate securely across separate mobile devices.", bullet_style))
    story.append(Paragraph("<b>Optimistic Offline Sync Queue:</b>", h2_style))
    story.append(Paragraph("&bull; Implements an event-driven background sync queue in Flutter. In rural collection booths with network disconnects, records are written locally in 0ms and automatically pushed to MongoDB with server timestamp precedence upon reconnection.", bullet_style))

    # Build PDF
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF generated successfully: {filename}")

if __name__ == '__main__':
    out_file = sys.argv[1] if len(sys.argv) > 1 else "Smart_Dairy_Algorithms_Documentation.pdf"
    build_pdf(out_file)
