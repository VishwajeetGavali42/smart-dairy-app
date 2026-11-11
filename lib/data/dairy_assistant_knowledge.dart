import '../models/chat_message.dart';

/// Comprehensive Knowledge Base grounded strictly in the Smart Dairy application.
/// Provides bilingual (English and Marathi), role-aware, and step-by-step guidance.
class DairyAssistantKnowledge {
  /// Match user inquiry against knowledge base and generate a structured, factual answer.
  static Map<String, dynamic> findAnswer({
    required String query,
    required String userRole,
    String? currentScreen,
    String languageCode = 'en',
    List<dynamic>? conversationHistory,
  }) {
    final q = query.trim().toLowerCase();
    final isMr = languageCode == 'mr';
    final role = userRole.toUpperCase();

    // 1. Role boundary & safety checks
    if (_isAttemptingPrivateDataLeak(q)) {
      return {
        'text': isMr
            ? 'सुरक्षेच्या कारणास्तव, मी शेतकऱ्यांची वैयक्तिक आर्थिक माहिती किंवा पासवर्ड प्रदर्शित करू शकत नाही. कृपया अधिकृत अहवाल किंवा लेजर तपासा.'
            : 'For security and privacy, I cannot display private farmer passwords, credentials, or confidential personal data. Please refer to the official reports or ledger directly.',
        'suggestedActions': isMr
            ? ['पेमेंट स्लिप कशी पाहायची?', '१०-दिवसीय बिलिंग कसे चालते?']
            : ['How to view payment slip?', 'How does 10-day billing work?'],
      };
    }

    if (_isAttemptingActionExecution(q)) {
      return {
        'text': isMr
            ? 'मी केवळ माहिती देणारा AI सहाय्यक आहे. मी थेट आर्थिक व्यवहार, नोंदी हटवणे किंवा बदल करू शकत नाही. मी तुम्हाला या ॲपमधील योग्य स्क्रीनवरून ती कृती कशी करावी हे स्टेप-बाय-स्टेप सांगू शकेन.'
            : 'I am an informational AI Assistant. I cannot directly execute financial payouts, delete database records, or modify milk entries for you. However, I can guide you step-by-step on how to perform this action directly from the appropriate screen.',
        'suggestedActions': isMr
            ? ['दूध संकलन कसे नोंदवायचे?', 'नवीन शेतकरी कसा जोडायचा?']
            : ['How to record milk collection?', 'How to add a farmer?'],
      };
    }

    // Role-specific restrictions
    if (role == 'EMPLOYEE' || role == 'OPERATOR') {
      if (q.contains('advance recovery') ||
          q.contains('profit') ||
          q.contains('bonus disbursement') ||
          q.contains('ledger audit')) {
        return {
          'text': isMr
              ? 'तुमची सक्रिय भूमिका "ऑपरेटर/कर्मचारी" (Operator) आहे. आर्थिक शिल्लक, आगाऊ रक्कम वसुली (Advance Recovery) आणि नफा-तोटा अहवाल व्यवस्थापित करण्याची परवानगी केवळ "डेअरी मालक" (Dairy Owner) यांना आहे.'
              : 'Your active role is Operator/Employee. Financial loan adjustments, advance recovery, and profit audits are restricted to the Dairy Owner role. You have full access to Milk Collection, Farmer List, Rate Chart, and Products.',
          'suggestedActions': isMr
              ? ['दूध संकलन कसे नोंदवायचे?', 'दर पत्रक कसे तपासायचे?']
              : ['How to record milk collection?', 'How to check rate chart?'],
        };
      }
    }

    // Conversational Follow-up questions and short queries using conversation history
    final isShortFollowUp = q == 'how?' ||
        q == 'how' ||
        q == 'how to fix?' ||
        q == 'how do i fix it?' ||
        q == 'how to fix it?' ||
        q == 'how do i fix?' ||
        q == 'why not working?' ||
        q == 'why not working' ||
        q == 'what should i do?' ||
        q == 'what should i do' ||
        q == 'what next?' ||
        q == 'कसे?' ||
        q == 'कसे दुरुस्त करायचे?' ||
        q == 'काय करावे?';

    if (isShortFollowUp && conversationHistory != null && conversationHistory.isNotEmpty) {
      String prevTopic = '';
      for (int i = conversationHistory.length - 1; i >= 0; i--) {
        final item = conversationHistory[i];
        String t = '';
        if (item is ChatMessage) {
          t = item.text.toLowerCase();
        } else if (item is Map) {
          t = (item['text'] ?? item['content'] ?? '').toString().toLowerCase();
        }
        if (t.contains('pratik') || t.contains('ramesh') || t.contains('missing') || t.contains('not visible') || t.contains('unlinked')) {
          prevTopic = 'missing_entry';
          break;
        } else if (t.contains('detailed bill') || t.contains('billing') || t.contains('invoice') || t.contains('bill')) {
          prevTopic = 'detailed_bill';
          break;
        } else if (t.contains('pdf')) {
          prevTopic = 'pdf';
          break;
        } else if (t.contains('fat') && t.contains('snf')) {
          prevTopic = 'fat_snf';
          break;
        }
      }

      if (prevTopic == 'missing_entry') {
        return {
          'text': isMr
              ? '''**शेतकऱ्याला नोंद दिसण्यासाठी पुढील पायऱ्या करा:**

1. शेतकऱ्याच्या मोबाईलवर ॲप उघडा आणि **"Collection"** किंवा **"Passbook"** स्क्रीनवर जा.
2. वर दिसणाऱ्या **"Link Farmer Profile"** बटणावर क्लिक करा.
3. मालकाने नोंदवलेला अचूक शेतकरी कोड (उदा. **M003** किंवा **M001**) टाका.
4. स्क्रीनवरील तारीख फिल्टर **"All Records" (सर्व नोंदी)** निवडा.
5. स्क्रीन खाली ओढून (Pull down to refresh) रीफ्रेश करा. मालकाने भरलेली सर्व दूध संकलन नोंद लगेच दिसेल!'''
              : '''**Here is how to fix the missing entry in Pratik's account:**

1. Have Pratik open the Smart Dairy app on his phone and open the **Collection / Passbook** screen.
2. Tap the **"Link Farmer Profile"** action button.
3. Enter the exact Member Code (e.g. **M003** or **M001**) assigned by the Dairy Owner.
4. Tap the **"All Records"** filter chip at the top to ensure previous days are visible.
5. Pull down to refresh. All previously entered milk entries will instantly appear in his passbook!''',
          'suggestedActions': isMr
              ? ['प्रोफाइल कसे लिंक करायचे?', 'सर्व नोंदी कशा पाहायच्या?']
              : ['How to link member profile?', 'Explain date filters'],
        };
      } else if (prevTopic == 'pdf') {
        return {
          'text': isMr
              ? '''**PDF समस्येचे निराकरण करण्यासाठी:**

1. फोनच्या **Settings** -> **Apps** -> **Smart Dairy** उघडा.
2. **Permissions** -> **Storage / Files** निवडून परवानगी चालू करा.
3. ॲपमध्ये परत येऊन **"Download PDF"** बटणावर टॅप करा. फाइल तुमच्या Downloads फोल्डरमध्ये सेव्ह होईल.'''
              : '''**Here is how to fix the PDF issue:**

1. Open your phone\'s **Settings** -> **Apps** -> **Smart Dairy**.
2. Tap **Permissions** -> **Files and Media** -> select **Allow**.
3. Return to the app and tap **"Download PDF"**. The statement will be saved directly into your device\'s Downloads directory.''',
          'suggestedActions': isMr
              ? ['तपशीलवार बिल मार्गदर्शक', 'WhatsApp शेअरिंग']
              : ['Detailed bill guide', 'What should I do if WhatsApp fails?'],
        };
      } else if (prevTopic == 'detailed_bill') {
        return {
          'text': isMr
              ? '''**तपशीलवार बिल तपासण्यासाठी:**

1. डॅशबोर्डवर **"Detailed Bill"** कार्डवर टॅप करा.
2. ड्रॉपडाउनमधून शेतकरी निवडा आणि १०-दिवसीय सायकल (१-१०, ११-२०, २१-अखेर) निवडा.
3. सकाळ-संध्याकाळच्या सर्व नोंदी आणि कपाती तपासा.
4. अधिकृत पत्रक डाऊनलोड करण्यासाठी **"Download PDF Statement"** वर टॅप करा.'''
              : '''**Here is how to view and verify the Detailed Bill:**

1. Tap **"Detailed Bill"** on the Dashboard.
2. Select the member from the dropdown list.
3. Choose the active 10-day cycle tab (e.g. 1st–10th).
4. Review every collection row and deduction.
5. Tap **"Download PDF Statement"** to save or print the certified payment sheet.''',
          'suggestedActions': isMr
              ? ['१०-दिवसीय बिलिंग कसे चालते?', 'PDF बिल कसे डाऊनलोड करावे?']
              : ['How does 10-day billing work?', 'How to download PDF statement?'],
        };
      }
    }

    // Conversational Follow-up questions
    if (q.contains('another way') ||
        q.contains('changed my question') ||
        q.contains('explain it another way') ||
        q.contains('दुसऱ्या भाषेत')) {
      return {
        'text': isMr
            ? '**दुसऱ्या सोप्या पद्धतीने समजून घेऊया:**\n\n'
                'विचार करा की डेअरी हे एक डिजिटल बँक खात्यासारखे आहे:\n'
                '• तुम्ही जितके लिटर दूध देता आणि जेवढे फॅट जास्त असते, तेवढी रक्कम तुमच्या खात्यात जमा (Credit) होते.\n'
                '• जर तुम्ही पशूखाद्य किंवा आगाऊ पैसे (Advance) घेतले असतील, तर ते बिलातून आपोआप वजा (Debit) होतात.\n'
                '• दर १० दिवसांनी उरलेली निव्वळ रक्कम (Net Payable) थेट शेतकऱ्याला दिली जाते.\n\n'
                'तुम्हाला यातील नेमका कोणता भाग अधिक सविस्तर समजून घ्यायचा आहे?'
            : '**Let\'s Look at It from Another Perspective:**\n\n'
                'Think of the Smart Dairy app like a digital dairy bank account:\n'
                '• **Milk Deposits**: Every morning and evening delivery adds money to the farmer\'s passbook based on volume and fat purity.\n'
                '• **Deductions**: Any cattle feed bags or cash advances taken are automatically tracked and deducted like loan installments.\n'
                '• **Payouts**: Every 10 days, the net balance is consolidated into an official statement and disbursed.\n\n'
                'Which specific part of the workflow would you like to explore further?',
        'suggestedActions': isMr
            ? ['दूध दर सूत्र समजावा', '१०-दिवसीय सायकल']
            : ['Explain rate formula', 'Explain 10-day cycle'],
      };
    }

    if (q.contains('in marathi') || q.contains('मराठीत सांगा') || (q.contains('marathi') && q.contains('explain'))) {
      return {
        'text': '**तीच संपूर्ण प्रक्रिया मराठीत समजून घ्या:**\n\n'
            '१. **दूध संकलन**: मालक शेतकऱ्याचा कोड (उदा. M001/M003) निवडून लिटर, FAT आणि SNF नोंदवतात.\n'
            '२. **दर निश्चिती**: गाईच्या दुधासाठी ३.५% फॅट (₹३८.०) आणि म्हशीसाठी ६.०% फॅट (₹५४.०) आधारभूत मानून द्वि-अक्षीय दराने हिशोब होतो.\n'
            '३. **१०-दिवसीय बिलिंग**: महिन्याच्या १-१०, ११-२० आणि २१-अखेर अशा ३ सायकल्समध्ये बिले तयार होतात.\n'
            '४. **शेतकरी पासबुक**: शेतकरी स्वतःच्या फोनवर स्वतःचा पासबुक, दररोजच्या दूध पावत्या आणि पेमेंट कधीही पाहू शकतात.\n'
            '५. **अहवाल**: शासकीय ऑडिटसाठी आणि WhatsApp वर शेअर करण्यासाठी प्रमाणित PDF बिल मिळते.',
        'suggestedActions': [
          'दूध संकलन कसे नोंदवायचे?',
          'FAT आणि SNF म्हणजे काय?',
          '१०-दिवसीय बिलिंग कसे चालते?',
        ],
      };
    }

    if (q.contains('whatsapp') ||
        q.contains('sharing fails') ||
        q.contains('share fail') ||
        q.contains('शेअर')) {
      return {
        'text': isMr
            ? '**WhatsApp शेअरिंग अयशस्वी झाल्यास काय करावे:**\n\n'
                '1. **WhatsApp इन्स्टॉल असल्याची खात्री करा**: तुमच्या फोनमध्ये WhatsApp किंवा WhatsApp Business चालू आहे का ते तपासा.\n'
                '2. **स्टोरेज परवानगी (Storage Permission)**: ॲपला PDF साठवण्याची परवानगी दिलेली असल्याची खात्री करा.\n'
                '3. **पर्यायी मार्ग (Download PDF)**: थेट WhatsApp ऐवजी **"Download PDF"** बटणावर टॅप करा. PDF तुमच्या फोनच्या Download फोल्डरमध्ये सेव्ह होईल, जिथून तुम्ही ती सहज WhatsApp किंवा ईमेलद्वारे पाठवू शकता.\n'
                '4. **सिस्टम शेअर शीट**: शेअर आयकॉन दाबून थेट अँड्रॉइडच्या सिस्टम शेअर मेनूमधून WhatsApp निवडा.'
            : '**What to Do If WhatsApp Sharing Fails:**\n\n'
                '1. **Verify WhatsApp Installation**: Ensure WhatsApp or WhatsApp Business is installed and configured on your device.\n'
                '2. **Storage Permissions**: Ensure the Smart Dairy app has storage/media access permissions for PDF generation.\n'
                '3. **Direct PDF Download Alternative**: Instead of the direct share button, tap **"Download PDF"**. This saves the file directly to your device\'s Downloads folder, where you can easily attach and send it manually.\n'
                '4. **Android Share Sheet**: Use the native Android share dialog to select WhatsApp or alternative messaging apps.',
        'suggestedActions': isMr
            ? ['PDF बिल कसे डाऊनलोड करावे?', 'पेमेंट स्लिप कशी पाहावी?']
            : ['How to download PDF?', 'How to view payment slip?'],
      };
    }

    if ((q.contains('10-day') || q.contains('bill') || q.contains('includes every') || q.contains('तपासायचे')) &&
        (q.contains('every collection') || q.contains('check') || q.contains('सर्व नोंदी'))) {
      return {
        'text': isMr
            ? '**१०-दिवसीय बिलामध्ये सर्व नोंदी समाविष्ट आहेत का हे कसे तपासावे:**\n\n'
                '1. **Billing & Invoices (बिलिंग)** स्क्रीन उघडा.\n'
                '2. संबंधित **१०-दिवसीय सायकल** (१-१० तारीख, ११-२० तारीख, किंवा २१-महिनाअखेर) निवडा.\n'
                '3. **Shift Breakdown Table (सत्रनिहाय तक्ता)** पहा: यामध्ये सायकलमधील प्रत्येक दिवसाचे सकाळ आणि संध्याकाळचे लिटर, FAT, SNF आणि दर दिसतात.\n'
                '4. **पावत्यांशी पडताळणी करा**: तक्त्यातील नोंदींची संख्या तुमच्याकडील प्रत्यक्ष दूध पावत्यांशी जुळवून पहा.\n'
                '5. **Download PDF** वर टॅप करून अधिकृत बिल डाऊनलोड करा ज्यावर सर्व नोंदींचा तपशीलवार हिशोब असतो.'
            : '**How to Check Whether Your 10-Day Bill Includes Every Collection:**\n\n'
                '1. Navigate to the **Billing & Invoices** screen from the menu or dashboard.\n'
                '2. Select the specific **10-day settlement cycle** (Cycle 1: Days 1–10, Cycle 2: Days 11–20, or Cycle 3: Day 21–End of month).\n'
                '3. Open the **Shift Breakdown Table**: It displays every individual morning and evening shift entry including Date, Shift, Litres, FAT, SNF, and Rate.\n'
                '4. **Cross-Reference Slips**: Compare the number of rows and total litres with your physical printed slips or collection passbook entries.\n'
                '5. Tap **Download PDF Statement** to get a certified statement listing every single collection line item.',
        'suggestedActions': isMr
            ? ['PDF बिल कसे डाऊनलोड करायचे?', '१०-दिवसीय बिलिंग सायकल']
            : ['How to download PDF statement?', 'Explain billing cycles'],
      };
    }

    if (q.contains('fat') && q.contains('snf')) {
      return {
        'text': isMr
            ? '**FAT आणि SNF मधील फरक (सोप्या शब्दांत):**\n\n'
                '• **FAT (Butterfat / स्निग्धांश)**: दुधातील लोणी/तूप किंवा चरबीचे प्रमाण. हे दुधावर तरंगते. गाईच्या दुधात सामान्यतः 3.5% आणि म्हशीच्या दुधात 6.0% आधारभूत फॅट मानले जाते.\n'
                '• **SNF (Solids-Not-Fat)**: फॅट वगळता दुधात असणारे इतर सर्व पौष्टिक घन घटक — जसे प्रथिने (proteins/केसीन), दुधातील साखर (लॅक्टोज) आणि खनिजे (minerals/कॅल्शियम).\n'
                '• **दरावर परिणाम**: डेअरीमध्ये दुधाचा दर FAT आणि SNF या दोन्ही घटकांवरून ठरवला जातो. फॅट आणि एसएनएफ जास्त असल्यास दर वाढतो.'
            : '**Difference between FAT and SNF in Simple Words:**\n\n'
                '• **FAT (Butterfat)**: The rich, creamy butterfat content of the milk that produces butter and ghee. Standard Cow Milk benchmark is 3.5%, while Buffalo Milk benchmark is 6.0%.\n'
                '• **SNF (Solids-Not-Fat)**: Everything in milk solids *except* the fat. This includes muscle-building proteins (casein), milk sugars (lactose), and vital minerals like calcium and phosphorus. Standard benchmark is 8.5%.\n'
                '• **Impact on Payment**: Milk payment uses a dual-axis formula where higher FAT and higher SNF directly increase the rate per litre.',
        'suggestedActions': isMr
            ? ['दूध दर कसा ठरतो?', '१०-दिवसीय बिलिंग']
            : ['How is milk rate calculated?', 'Explain billing cycles'],
      };
    }

    if (q.contains('more simply') ||
        (q.contains('simple') && !q.contains('fat')) ||
        q.contains('सोप्या') ||
        q.contains('सोपे')) {
      return {
        'text': isMr
            ? 'थोडक्यात सांगायचे तर: **स्मार्ट डेअरी ॲप** तुमच्या दुधाचे वजन आणि गुणवत्तेनुसार (FAT आणि SNF) अचूक दर ठरवते. मालक जे दूध संकलन नोंदवतात ते थेट सर्व्हरवर साठवले जाते आणि शेतकरी त्यांच्या मोबाईलवर स्वतःचा पासबुक आणि पेमेंट कधीही पाहू शकतात.'
            : 'In simple terms: The Smart Dairy app records each farmer\'s milk quantity and calculates its exact price based on FAT and SNF quality. All entries are saved permanently in the central database so farmers can track their milk supply, billing slips, and payments on their own phones.',
        'suggestedActions': isMr
            ? ['उदाहरणासह समजावून सांगा', 'दूध दर कसा ठरतो?']
            : ['Give me an example', 'How is milk rate calculated?'],
      };
    }

    if (q.contains('example') || q.contains('उदाहरण')) {
      return {
        'text': isMr
            ? 'उदाहरणासह समजून घ्या:\n\n• **गाईचे दूध**: 10 लिटर, FAT 4.2%, SNF 8.5%.\n• बेस रेट ₹38.0 + FAT फरक (4.2 - 3.5)*10*0.40 = +₹2.80.\n• एकूण दर: **₹40.80/लिटर**.\n• एकूण रक्कम: 10 * 40.80 = **₹408.00**.\nही रक्कम तत्काळ शेतकऱ्याच्या पासबुकमध्ये आणि 10-दिवसीय बिलात जमा होते.'
            : 'Here is a concrete example:\n\n• **Cow Milk**: 10.0 Litres, FAT 4.2%, SNF 8.5%.\n• Base Rate: ₹38.0/L. FAT bonus: (4.2 - 3.5) * 10 * 0.40 = +₹2.80.\n• Final Rate: **₹40.80 per Litre**.\n• Total Amount: 10.0 L * ₹40.80 = **₹408.00**.\nThis amount is instantly added to Ramesh\'s Milk Passbook and included in his 10-day cycle statement.',
        'suggestedActions': isMr
            ? ['१०-दिवसीय बिलिंग कसे चालते?', 'पुढील पायरी काय आहे?']
            : ['How does 10-day billing work?', 'What should I do next?'],
      };
    }

    if (q.contains('what next') ||
        q.contains('next step') ||
        q.contains('what should i do') ||
        q.contains('what to do') ||
        q.contains('next') ||
        q.contains('पुढे काय') ||
        q.contains('पुढील पायरी')) {
      return {
        'text': isMr
            ? 'पुढील पायऱ्या:\n1. डॅशबोर्डवर जा आणि **"Collection"** टॅप करा.\n2. शेतकऱ्याचे नाव (उदा. Ramesh Patil - M001) निवडा.\n3. लिटर, FAT आणि SNF भरून **"SAVE COLLECTION"** दाबा.\n4. शेतकरी त्यांच्या स्वतःच्या फोनवर लगेच ही नोंद पाहू शकतात!'
            : 'Recommended next steps:\n1. Open the **Collection** tab from the bottom navigation or Dashboard.\n2. Select the farmer (e.g., Ramesh Patil - M001).\n3. Enter the Litres, FAT, and SNF, then tap **SAVE COLLECTION**.\n4. The farmer can now log in on their phone to verify the saved entry in their Passbook!',
        'suggestedActions': isMr
            ? ['शेतकऱ्याला नोंद का दिसत नाही?', '१०-दिवसीय बिलिंग']
            : ['Why can\'t Ramesh see the entry?', '10-day billing cycle'],
      };
    }

    if (q.contains('ramesh') ||
        q.contains('pratik') ||
        q.contains('missing entry') ||
        q.contains('not visible') ||
        q.contains('yesterday') ||
        q.contains("can't see") ||
        q.contains('का दिसत नाही') ||
        q.contains('गायब')) {
      return {
        'text': isMr
            ? 'शेतकऱ्याला (उदा. प्रतीक किंवा रमेश) मालकाने नोंदवलेली दुधाची नोंद न दिसण्याची मुख्य ३ कारणे व उपाय:\n\n'
                '1. **अकाउंट लिंक नसणे (Unlinked Member Code)**: शेतकऱ्याच्या लॉगिन खात्याशी त्याचा शेतकरी कोड (उदा. M001/M003) जोडलेला नसेल. शेतकऱ्याने पासबुक स्क्रीनवर **"Link Farmer Profile"** वर क्लिक करून स्वतःचा कोड लिंक करावा.\n'
                '2. **तारीख फिल्टर (Date Filter)**: स्क्रीनवर तारीख फिल्टर जर "Today" (आज) असेल आणि नोंद कालची किंवा जुनी असेल, तर वर **"All Records" (सर्व नोंदी)** निवडा.\n'
                '3. **डेटाबेस सिंक्रोनायझेशन**: सर्व नोंदी कायमस्वरूपी मध्यवर्ती MongoDB डेटाबेसमध्ये साठवल्या जातात. दोन्ही डिव्हाइसेस एकाच सर्व्हरशी जोडलेले असल्याची खात्री करा.'
            : 'Why a milk entry entered for a farmer (e.g., Pratik or Ramesh) might not be visible in his account:\n\n'
                '1. **Unlinked Member Account**: The farmer\'s login account must be connected to their dairy-issued Member Code (e.g., **M001** or **M003**). If unlinked, click **"Link Farmer Profile"** and enter the member code.\n'
                '2. **Date Filter Setting**: If the passbook filter is currently set to **"Today"** and the entry was recorded yesterday, tap the **"All Records"** filter chip at the top.\n'
                '3. **Persistent Server Sync**: Entries are saved permanently in MongoDB. Make sure both devices are pointing to the same server and pull down to refresh.',
        'suggestedActions': isMr
            ? ['प्रोफाइल कसे लिंक करायचे?', 'सर्व नोंदी कशा पाहायच्या?']
            : ['How to link member profile?', 'Explain date filters'],
      };
    }

    if (q.contains('uninstall') ||
        q.contains('reinstall') ||
        q.contains('डिलिट') ||
        q.contains('पुन्हा इन्स्टॉल')) {
      return {
        'text': isMr
            ? 'ॲप अनइन्स्टॉल केल्यास तुमच्या दुधाच्या नोंदींना काय होते?\n\n'
                '• **डेटा सुरक्षित राहतो**: सर्व दूध नोंदी, बिले आणि पेमेंट फोनमध्ये नव्हे तर मध्यवर्ती **MongoDB डेटाबेस सर्व्हरवर** कायमस्वरूपी साठवल्या जातात.\n'
                '• **पुन्हा इन्स्टॉल केल्यावर**: ॲप पुन्हा डाऊनलोड करून तुमच्या त्याच युझरनेम आणि पासवर्डने लॉगिन केल्यास सर्व जुना डेटा आणि पासबुक जसेच्या तसे परत मिळते!'
            : 'What happens to your milk records if you uninstall the app?\n\n'
                '• **Records are 100% Safe**: All milk collections, farmer profiles, invoices, and payments are stored in the central **MongoDB backend database**, not just in local phone storage.\n'
                '• **After Reinstalling**: Simply install the app again, log in with your existing username and password, and all your historical milk records and passbook entries will reload automatically!',
        'suggestedActions': isMr
            ? ['डेटा कसा साठवला जातो?', 'लॉगिन कसे पुनर्संचयित करायचे?']
            : ['How is data persisted?', 'Offline data synchronization'],
      };
    }

    // 2. Screen-specific contextual questions
    if (currentScreen != null && currentScreen.isNotEmpty) {
      final screenAnswer = _matchScreenContext(currentScreen, q, isMr, role);
      if (screenAnswer != null) return screenAnswer;
    }

    // 3. Topic matching against real application features

    // A. Milk Collection & Shift Entries
    if (q.contains('collection') ||
        q.contains('record milk') ||
        q.contains('morning') ||
        q.contains('evening') ||
        q.contains('सकलन') ||
        q.contains('नोंद') ||
        q.contains('दूध') ||
        q.contains('shift')) {
      return {
        'text': isMr
            ? '''**दूध संकलन नोंदवण्याची सोपी पद्धत (Milk Collection Steps):**

1. डॅशबोर्डवरील **"Collection" (संकलन)** आयकॉनवर टॅप करा किंवा खालच्या मध्यभागी असलेल्या **(+) बटणावर** क्लिक करा.
2. **शेतकरी निवडा**: ड्रॉपडाउनमधून शेतकऱ्याचे नाव किंवा कोड (उदा. Ramesh Patil / M001) निवडा.
3. **जनावराचा प्रकार**: **गाय (Cow)** किंवा **म्हैस (Buffalo)** यापैकी एक निवडा.
4. **सत्र (Shift)**: **Morning (सकाळ)** किंवा **Evening (संध्याकाळ)** निवडा.
5. **दूध प्रमाण (Quantity)**: वजनानुसार लिटरमध्ये प्रमाण भरा (उदा. 15.5). *टीप: येथे फक्त आकडे चालतात, अक्षरे चालत नाहीत.*
6. **FAT आणि SNF**: फॅट (उदा. 4.2%) आणि एसएनएफ (उदा. 8.5%) टाका. 
   *(टीप: जर तुमच्याकडे ब्लूटूथ वजनकाटा किंवा ॲनालायझर असेल, तर वरच्या "Auto-Read (BLE)" बटणावर टॅप करून स्वयंचलित वाचन घेऊ शकता).*
7. **Save Collection**: हिरव्या रंगाच्या **"SAVE COLLECTION"** बटणावर क्लिक करा. दर (Rate) आणि एकूण रक्कम आपोआप मोजली जाईल!'''
            : '''**How to Record Milk Collection (Step-by-Step):**

1. Tap the **"Collection"** icon on the Dashboard or click the central **(+) button** at the bottom navigation bar.
2. **Select Farmer**: Choose the farmer by name or code (e.g. Ramesh Patil - M001) from the dropdown.
3. **Animal Type**: Toggle between **Cow** or **Buffalo**.
4. **Shift**: Choose **Morning** or **Evening** shift.
5. **Milk Quantity**: Enter the litres (e.g., 15.5 Ltr). *Note: The field strictly accepts numbers and decimals.*
6. **FAT & SNF**: Enter the FAT (e.g., 4.2%) and SNF (e.g., 8.5%). 
   *(Tip: If you have a Bluetooth electronic scale or milk analyzer, tap "Auto-Read (BLE)" at the top to fetch readings automatically).*
7. **Save**: Tap **"SAVE COLLECTION"**. The app instantly calculates the Rate (₹/Ltr) and Total Amount using the cooperative rate chart!''',
        'suggestedActions': isMr
            ? [
                'FAT आणि SNF म्हणजे काय?',
                'दूध दर कसा ठरवला जातो?',
                'BLE वजनकाटा कसा जोडायचा?',
              ]
            : [
                'What are FAT and SNF?',
                'How is milk rate calculated?',
                'How does BLE analyzer connect?',
              ],
      };
    }

    // B. FAT and SNF
    if (q.contains('fat') ||
        q.contains('snf') ||
        q.contains('फॅट') ||
        q.contains('एसएनएफ')) {
      return {
        'text': isMr
            ? '''**FAT आणि SNF म्हणजे काय? (Understanding Milk Quality):**

• **FAT (स्निग्धता / लोणी)**: दुधामधील नैसर्गिक चरबीचे (Butterfat) शेकडा प्रमाण. 
  - गायीच्या दुधात सामान्यतः **3.2% ते 4.5%** फॅट असते.
  - म्हशीच्या दुधात **6.0% ते 9.0%** किंवा त्याहून अधिक फॅट असते.

• **SNF (Solids-Not-Fat / फॅटरहित घटक)**: दुधामधून फॅट आणि पाणी वगळता उरलेले घटक—जसे की प्रथिने (Protein), लॅक्टोज (दुग्धशर्करा) आणि खनिजे (Minerals).
  - गायीसाठी प्रमाणभूत SNF: **8.3% ते 8.8%**.
  - म्हशीसाठी प्रमाणभूत SNF: **8.8% ते 9.5%**.

💡 **महत्त्व**: ॲपमधील दर पत्रक (Rate Chart) हे फॅट आणि एसएनएफ यांच्या आधारावर प्रति लिटर भाव ठरवते. जर दुधात पाणी मिसळले असेल तर SNF कमी होतो, ज्यावर ॲपमधील AI अनॉमली डिटेक्शन त्वरित इशारा देते.'''
            : '''**What are FAT and SNF?**

• **FAT (Butterfat %)**: The percentage of natural fatty oils in milk.
  - Standard Cow Milk: **3.2% to 4.5%**.
  - Standard Buffalo Milk: **6.0% to 9.0%** (richer in fat).

• **SNF (Solids-Not-Fat)**: All the nutritious solid components of milk other than butterfat and water—primarily protein, lactose (milk sugar), and essential minerals.
  - Standard Cow Milk SNF: **8.3% to 8.8%**.
  - Standard Buffalo Milk SNF: **8.8% to 9.5%**.

💡 **Why it matters**: The cooperative pricing matrix directly multiplies your FAT and SNF readings by configured step values. If water is added to milk, the SNF drops sharply, which our AI Anomaly Detector immediately flags.''',
        'suggestedActions': isMr
            ? ['दूध दर कसा ठरवला जातो?', 'दर पत्रक कसे तपासायचे?']
            : ['How is milk rate calculated?', 'How to check rate chart?'],
      };
    }

    // C. Milk Rate Calculation Formula
    if (RegExp(r'\brate\b').hasMatch(q) ||
        q.contains('milk rate') ||
        q.contains('calculate') ||
        q.contains('price') ||
        q.contains('formula') ||
        q.contains('दर') ||
        q.contains('भाव') ||
        q.contains('हिशोब')) {
      return {
        'text': isMr
            ? '''**दूध दर कसा ठरवला जातो? (Rate Calculation Formula):**

स्मार्ट डेअरी ॲप्लिकेशनमध्ये प्रमाणित 2-एक्सिस (FAT × SNF) मॅट्रिक्स अल्गोरिदम वापरला जातो:

**दर सूत्र:**
Rate = Base Rate + [(FAT - Base FAT) × FAT Step] + [(SNF - Base SNF) × SNF Step]

**उदाहरणासह समजून घ्या (गाय):**
- Base Rate: ₹26.30 (FAT 3.5%, SNF 8.5% साठी)
- जर FAT = 4.2% आणि SNF = 8.5%:
  - FAT वाढ = 4.2 - 3.5 = 0.7
  - दर = 26.30 + (0.7 × 2.0 × 10) = ₹40.30 प्रति लिटर!

**एकूण रक्कम सूत्र:**
Total Amount = Quantity (Litres) × Calculated Rate

*टीप: तुम्ही "Rate Chart" स्क्रीनवरून बेस रेट आणि स्टेप व्हॅल्यू कधीही बदलू शकता.*'''
            : '''**How is the Milk Rate Calculated?**

The Smart Dairy app uses a standard dual-axis cooperative pricing matrix algorithm:

**Pricing Formula:**
Rate = Base Rate + [(FAT - Base FAT) × FAT Step] + [(SNF - Base SNF) × SNF Step]

**Practical Example (Cow Milk):**
- Standard Base Rate: ₹26.30 (for FAT 3.5%, SNF 8.5%)
- If recorded milk has FAT 4.2% and SNF 8.5%:
  - FAT increment = 4.2 - 3.5 = 0.7
  - Rate = ₹26.30 + (0.7 × 2.0 × 10) = **₹40.30 per Litre**!

**Total Milk Amount:**
Total Amount = Quantity (Litres) × Calculated Rate

*Note: You can inspect and adjust the base rates anytime via the "Rate Chart" screen on your dashboard.*''',
        'suggestedActions': isMr
            ? ['दर पत्रक कसे तपासायचे?', '१०-दिवसीय बिलिंग कसे चालते?']
            : ['How to view rate chart?', 'How does 10-day billing work?'],
      };
    }

    // Detailed Bill & Statement Screen Guidance
    final isDetailedBill = q.contains('detailed bill') ||
        q.contains('detail bill') ||
        q.contains('तपशीलवार बिल') ||
        q.contains('तपशील बिल') ||
        q.contains('statement screen') ||
        (q.contains('bill') && !q.contains('10-day') && !q.contains('cycle') && !q.contains('how does')) ||
        (q.contains('बिल') && !q.contains('१० दिवस') && !q.contains('सायकल') && !q.contains('कसे चालते'));

    if (isDetailedBill) {
      return {
        'text': isMr
            ? '''**तपशीलवार बिल (Detailed Bill) स्क्रीन मार्गदर्शक:**

'तपशीलवार बिल' (Detailed Bill) स्क्रीन निवडलेल्या बिलिंग कालावधीतील (१०-दिवसीय सायकल, १५-दिवसीय किंवा मासिक) सभासदाच्या सर्व दूध संकलन नोंदींचे तपशीलवार विवरण दाखवते.

**यात खालील माहिती समाविष्ट असते:**
• **संकलन नोंदी (Shift Records)**: सायकलमधील प्रत्येक दिवसाचे सकाळ आणि संध्याकाळचे संकलन, तारीख, दुधाचे लिटर, FAT आणि SNF टक्केवारी.
• **दर आणि एकूण रक्कम (Rate & Gross Value)**: दुधाच्या गुणवत्तेनुसार संगणित केलेला प्रति लिटर दर आणि एकूण दुधाची किंमत.
• **कपाती (Deductions)**: पशूखाद्य खरेदी, औषधे किंवा आधी घेतलेली आगाऊ उचल (Advance Recovery).
• **निव्वळ देय रक्कम (Final Net Payable)**: शेतकऱ्याला प्रत्यक्षात बँक किंवा रोखीने द्यावयाची अंतिम रक्कम.

**कसे वापरावे?**:
1. डॅशबोर्ड किंवा मेनूमधून **"Detailed Bill"** (किंवा **"Billing & Invoices"**) उघडा.
2. शेतकरी निवडा आणि योग्य बिलिंग सायकल निवडा (उदा. सायकल १: १ ते १० तारीख).
3. सर्व नोंदी अचूक असल्याची खात्री करा.
4. शेतकऱ्याला देण्यासाठी किंवा व्हॉट्सॲपवर पाठवण्यासाठी **"Download PDF Statement"** वर टॅप करा.'''
            : '''**Detailed Bill Screen Guide:**

The Detailed Bill screen shows a member's milk collection records for the selected billing period, including collection dates, morning and evening quantities, FAT, SNF, rates, amounts, applicable deductions, and the final payable amount, depending on the features implemented in the app.

**Key information displayed:**
• **Shift Collection Records**: Daily morning and evening deliveries showing date, milk volume (litres), FAT %, and SNF %.
• **Quality Rate & Gross Value**: Quality-adjusted rate per litre based on the FAT/SNF formula and total gross milk value.
• **Deductions & Advances**: Repayment of cattle feed loans, store purchases, and previous advance installments.
• **Final Net Payable**: The final net payout to be disbursed to the farmer after all applicable deductions.

**How to use:**
1. Open **Detailed Bill** (or **Billing & Invoices**) from the Dashboard or navigation menu.
2. Select the member / farmer and the desired settlement cycle (e.g. Cycle 1: Days 1–10).
3. Check that every eligible collection appears in the table.
4. Tap **Download PDF Statement** to generate, print, or share the statement via WhatsApp.''',
        'suggestedActions': isMr
            ? ['१०-दिवसीय बिलिंग कसे चालते?', 'PDF बिल कसे डाऊनलोड करावे?', 'दूध दर कसा ठरवला जातो?']
            : ['How does 10-day billing work?', 'How to download PDF statement?', 'How is milk rate calculated?'],
      };
    }

    // D. 10-day Billing Cycle and Settlement
    if (q.contains('billing') ||
        q.contains('cycle') ||
        q.contains('10-day') ||
        q.contains('15-day') ||
        q.contains('बिलिंग') ||
        q.contains('सायकल') ||
        q.contains('१० दिवस') ||
        q.contains('पगार')) {
      return {
        'text': isMr
            ? '''**१०-दिवसीय बिलिंग सायकल कशी कार्य करते? (10-Day Billing Cycle):**

ग्रामीण डेअरी सहकारी संस्थांमध्ये महिन्याचे ३ मुख्य बिलिंग टप्पे असतात:
1. **सायकल १**: १ ते १० तारीख (1st - 10th)
2. **सायकल २**: ११ ते २० तारीख (11th - 20th)
3. **सायकल ३**: २१ ते महिन्याचा शेवट (21st - End of Month)

**निव्वळ देय रक्कम (Net Payable Amount) सूत्र:**
Net Payable = एकूण दूध बिल - आगाऊ कपात (Advance Recovery) - पशूखाद्य कपात (Feed Deductions)

**तपशीलवार बिल पाहण्यासाठी:**
1. डॅशबोर्डवरील **"Detailed Bill" (तपशीलवार बिल)** किंवा **"Invoice"** वर टॅप करा.
2. शेतकरी निवडा आणि हवी ती सायकल (10 Days, 15 Days, Monthly) निवडा.
3. दररोजच्या सकाळ-संध्याकाळच्या नोंदी, कपाती आणि उर्वरित शिल्लक एका तक्त्यात दिसेल.
4. तुम्ही **"Download PDF"** बटणावर क्लिक करून प्रिंट किंवा व्हॉट्सॲपवर पाठवू शकता!'''
            : '''**How the 10-Day Billing Cycle Works:**

In cooperative dairies, payments are settled across standard 10-day cycles:
1. **Cycle 1**: 1st to 10th of the month
2. **Cycle 2**: 11th to 20th of the month
3. **Cycle 3**: 21st to end of the month (e.g. 21st to 30th/31st)

**Net Farmer Payout Formula:**
Net Payout = Gross Milk Bill - Advance Loan Repayment - Cattle Feed/Store Deductions

**To view or generate a detailed statement:**
1. Tap **"Detailed Bill"** or **"Invoice"** on the Dashboard.
2. Select the farmer and active cycle tab (10 Days, 15 Days, Monthly).
3. Review the complete table of morning/evening entries with FAT, SNF, and rate.
4. Tap **"Download PDF Statement"** to save or print the certified co-op payment sheet!''',
        'suggestedActions': isMr
            ? [
                'पेमेंट स्लिप कशी पाहायची?',
                'आगाऊ रक्कम (Advance) कशी नोंदवायची?',
              ]
            : ['How to generate payment slip?', 'How to record advance?'],
      };
    }

    // E. Farmer / Member Management
    if (q.contains('farmer') ||
        q.contains('member') ||
        q.contains('add farmer') ||
        q.contains('शेतकरी') ||
        q.contains('सभासद') ||
        q.contains('customer')) {
      return {
        'text': isMr
            ? '''**नवीन शेतकरी (सभासद) कसा जोडायचा? (Adding a Farmer):**

1. डॅशबोर्डवरील **"Customer" (शेतकरी)** कार्डवर टॅप करा.
2. तळाशी उजव्या बाजूला असलेल्या हिरव्या **(+) शेतकरी जोडा** बटणावर क्लिक करा.
3. **शेतकऱ्याचे नाव (Member Name)**: पूर्ण नाव टाका (उदा. Suresh Deshmukh). *टीप: येथे फक्त अक्षरे चालतात, आकडे चालत नाहीत.*
4. **मोबाईल नंबर (Phone Number)**: १० अंकी मोबाईल नंबर टाका.
5. **ADD** वर क्लिक करा. नवीन शेतकऱ्याला तात्काळ युनिक मेंबर कोड (उदा. M006) दिला जाईल!

*टीप: तुम्ही यादीतील शेतकऱ्यावर टॅप करून त्याची बँक खाती, जनावरांचा प्रकार, मागील दूध इतिहास आणि शिल्लक आगाऊ रक्कम (Advance) तपासू शकता.*'''
            : '''**How to Add a New Farmer (Member):**

1. Tap the **"Customer"** module on the Dashboard.
2. Tap the floating green **(+) Add Member** button at the bottom-right.
3. **Member Name**: Enter the farmer's name (e.g. Suresh Deshmukh). *Note: The field accepts letters only, rejecting digits.*
4. **Phone Number**: Enter the 10-digit mobile number.
5. Tap **"ADD"**. The system instantly creates the member record with an auto-assigned member code (e.g. M006)!

*Tip: Tap on any farmer card in the list to view their passbook, bank account details, and outstanding advance loan balance.*''',
        'suggestedActions': isMr
            ? [
                'शेतकऱ्याची आगाऊ शिल्लक कशी तपासायची?',
                'दूध संकलन कसे नोंदवायचे?',
              ]
            : [
                'How to check farmer advance?',
                'How to record milk collection?',
              ],
      };
    }

    // F. Advances and Repayments
    if (q.contains('advance') ||
        q.contains('loan') ||
        q.contains('repay') ||
        q.contains('आगाऊ') ||
        q.contains('उचल') ||
        q.contains('कर्ज')) {
      return {
        'text': isMr
            ? '''**शेतकऱ्याची आगाऊ रक्कम (Advance) आणि वसुली कशी व्यवस्थापित करावी?**

• **नवीन उचल (Advance) देण्यासाठी:**
  1. डॅशबोर्डवरील **"Advance"** पर्यायावर जा.
  2. तळाशी असलेल्या **(+) बटणावर** टॅप करा.
  3. शेतकरी निवडा, उचल रक्कम (Amount) टाका आणि कारण निवडा (उदा. Personal, Medical, Feed).
  4. **Save** करा.

• **उचल वसुली (Repayment / Recovery):**
  1. शेतकऱ्याच्या कार्डवर **"Record Repayment"** वर टॅप करा.
  2. चालू बिलामधून कापली जाणारी रक्कम टाका (शिल्लक रकमेपेक्षा जास्त रक्कम टाकता येत नाही).
  3. **Record** करा. शिल्लक रक्कम आपोआप अपडेट होईल!'''
            : '''**How to Manage Farmer Advances and Repayments:**

• **To Issue a Cash Advance:**
  1. Open the **"Advance"** module from the Dashboard.
  2. Tap the floating **(+) button**.
  3. Select the farmer, enter the advance amount in ₹ (numbers only), and choose the reason (Personal, Medical, Feed).
  4. Tap **Save Advance**.

• **To Record a Repayment:**
  1. Tap on the farmer's advance card and choose **"Record Repayment"**.
  2. Enter the recovery amount (cannot exceed current pending balance).
  3. Tap **Record**. The pending advance automatically decrements and syncs with their billing cycle!''',
        'suggestedActions': isMr
            ? ['१०-दिवसीय बिलिंग कसे चालते?', 'कपात (Deduction) कशी जोडायची?']
            : ['How does 10-day billing work?', 'How to add deduction?'],
      };
    }

    // G. Annual Bonus
    if (q.contains('bonus') ||
        q.contains('बोनस') ||
        q.contains('वार्षिक') ||
        q.contains('incentive')) {
      return {
        'text': isMr
            ? '''**वार्षिक बोनस वाटप कसे कार्य करते? (Annual Bonus Distribution):**

सहकारी डेअरी नियमांनुसार, वर्षभरात शेतकऱ्याने पुरवलेल्या एकूण दूध प्रमाणावर (Total Litres) बोनस दिला जातो:

Bonus Amount = वर्षभरातील एकूण लिटर × बोनस दर प्रति लिटर (₹/Ltr)

**कसे वापरावे:**
1. डॅशबोर्डवरील **"Annual Bonus" (वार्षिक बोनस)** मॉड्यूल उघडा.
2. वरच्या बाजूला **"Change Rate"** बटणावर क्लिक करून प्रति लिटर दर सेट करा (उदा. ₹1.50 किंवा ₹2.00).
3. सर्व शेतकऱ्यांची यादी, त्यांचे वर्षभरातील एकूण लिटर आणि पात्र बोनस रक्कम त्वरित मोजली जाईल.
4. **"Disburse All"** द्वारे सर्व शेतकऱ्यांना बोनस जारी करा किंवा **"Download Report"** द्वारे संपूर्ण बोनस ऑडिट रिपोर्ट PDF स्वरूपात डाउनलोड करा!'''
            : '''**How Annual Bonus Distribution Works:**

In dairy cooperatives, patronage bonus is rewarded proportionally to the total milk volume delivered by each farmer throughout the financial year:

Bonus Amount = Total Annual Litres Supplied × Incentive Rate (₹/Ltr)

**How to use:**
1. Open **"Annual Bonus"** from the Dashboard.
2. Tap **"Change Rate"** to configure the co-op rate per litre (e.g. ₹1.50 or ₹2.00/Ltr).
3. The roster automatically computes the total litres and corresponding bonus for every active farmer.
4. Tap **"Disburse All"** to record payments or tap **"Download Report"** to export an official certified bonus statement PDF!''',
        'suggestedActions': isMr
            ? ['PDF अहवाल कसा काढायचा?', '१०-दिवसीय बिलिंग कसे चालते?']
            : ['How to generate PDF report?', 'How does 10-day billing work?'],
      };
    }

    // H. PDF Reports & Generation
    final isPdfTroubleshooting = (q.contains('pdf') || q.contains('अहवाल')) &&
        (q.contains('not working') ||
            q.contains('not work') ||
            q.contains('error') ||
            q.contains('fail') ||
            q.contains('issue') ||
            q.contains('problem') ||
            q.contains('काम करत नाही') ||
            q.contains('चालत नाही') ||
            q.contains('त्रुटी'));

    if (isPdfTroubleshooting) {
      return {
        'text': isMr
            ? '''**PDF अहवाल डाऊनलोड किंवा शेअर न झाल्यास उपाय (PDF Troubleshooting):**

1. **स्टोरेज परवानगी (Storage Permission)**: तुमच्या फोनच्या Settings -> Apps -> Smart Dairy -> Permissions मध्ये जाऊन स्टोरेज/फाइल्स परवानगी सक्रिय करा.
2. **नोंदी उपलब्ध आहेत का ते तपासा**: निवडलेल्या तारखेत किंवा बिलिंग सायकलमध्ये दूध संकलनाची किमान १ नोंद असणे आवश्यक आहे. रिकाम्या सायकलचे PDF तयार होत नाही.
3. **पर्यायी मार्ग (Direct Download)**: थेट WhatsApp शेअर अयशस्वी झाल्यास **"Download PDF"** बटणावर टॅप करा. फाइल तुमच्या फोनच्या 'Downloads' फोल्डरमध्ये सेव्ह होईल.
4. **PDF Viewer**: तुमच्या फोनमध्ये Google Drive किंवा कोणताही PDF व्ह्यूअर ॲप इन्स्टॉल असल्याची खात्री करा.'''
            : '''**Troubleshooting PDF Generation and Sharing:**

If PDF statement or slip generation fails, follow these steps:
1. **Device Storage Permissions**: Open your phone Settings -> Apps -> Smart Dairy -> Permissions and ensure "Files & Media" / Storage permission is granted.
2. **Verify Recorded Collections**: Ensure the selected date or billing cycle contains at least one collection record. An empty cycle cannot generate a statement.
3. **Use Direct Download**: If sharing directly to WhatsApp fails, tap **"Download PDF"** to save the file locally into your phone\'s 'Downloads' directory first, then attach it manually.
4. **PDF Reader Installed**: Verify you have a standard PDF viewer (e.g. Google Drive Viewer) installed to preview generated documents.''',
        'suggestedActions': isMr
            ? ['तपशीलवार बिल मार्गदर्शक', 'व्हॉट्सॲप शेअरिंग समस्या']
            : ['Detailed bill guide', 'What should I do if WhatsApp fails?'],
      };
    }

    if (q.contains('pdf') ||
        q.contains('report') ||
        q.contains('print') ||
        q.contains('download') ||
        q.contains('अहवाल') ||
        q.contains('डाउनलोड') ||
        q.contains('प्रिंट')) {
      return {
        'text': isMr
            ? '''**PDF अहवाल आणि पेमेंट स्लिप कशी तयार करावी? (PDF Generation):**

ॲपमध्ये अंतर्गत **Native PDF Generator** आहे, जो इंटरनेट नसतानाही थेट तुमच्या फोनमध्ये PDF तयार करतो:

1. **तपशीलवार बिल स्टेटमेंट (Detailed Statement)**:
   - "Detailed Bill" स्क्रीनवर जा, शेतकरी निवडा आणि **"Download PDF Statement"** वर टॅप करा.
2. **पेमेंट व्हाउचर (Payment Voucher)**:
   - "Payments" स्क्रीनवर जा, व्हाउचरवर टॅप करा आणि **"Download Receipt"** निवडा.
3. **वार्षिक बोनस पत्रक (Bonus Statement)**:
   - "Annual Bonus" स्क्रीनवर जाऊन **"Download Report"** वर टॅप करा.

📁 **फाईल कुठे सेव्ह होते?**: 
तुमच्या फोनच्या `Downloads/SmartDairy` किंवा अंतर्गत स्टोरेजमध्ये PDF सेव्ह होते. डाउनलोड झाल्यावर स्क्रीनवर थेट "Open File" चा पर्याय येतो.'''
            : '''**How to Generate & Download PDF Reports:**

The app includes a built-in **Native PDF Generator** that creates certified PDF documents directly on your device, even with zero internet connectivity:

1. **Detailed Cycle Billing Statement**:
   - Navigate to **"Detailed Bill"**, select a farmer, and tap **"Download PDF Statement"**.
2. **Farmer Payment Slip / Voucher**:
   - Open **"Payments"**, select any payout voucher, and tap **"Download Receipt"**.
3. **Annual Bonus Audit Statement**:
   - Open **"Annual Bonus"** and tap **"Download Report"**.

📁 **Where are PDFs saved?**:
Saved automatically to your device's `Downloads/SmartDairy` directory. A notification pop-up gives you an instant one-tap "Open File" button to view or share via WhatsApp!''',
        'suggestedActions': isMr
            ? ['१०-दिवसीय बिलिंग कसे चालते?', 'दूध संकलन कसे नोंदवायचे?']
            : [
                'How does 10-day billing work?',
                'How to record milk collection?',
              ],
      };
    }

    // I. AI Insights & Quality Scores (Exact word boundary \bai\b prevents false positives like 'detailed' or 'daily')
    final isAiQuery = RegExp(r'\b(ai|ml)\b').hasMatch(q) ||
        q.contains('ai features') ||
        q.contains('ai insights') ||
        q.contains('ai assistant') ||
        q.contains('artificial intelligence') ||
        q.contains('machine learning') ||
        q.contains('quality score') ||
        q.contains('forecast') ||
        q.contains('anomaly') ||
        q.contains('अंदाज') ||
        q.contains('दर्जा') ||
        q.contains('अनॉमली');

    if (isAiQuery) {
      return {
        'text': isMr
            ? '''**ॲपमधील AI आणि मशीन लर्निंग (ML) फिचर्स काय आहेत?**

1. **अनॉमली डिटेक्शन (Anomaly Detection)**:
   - संकलन करताना फॅट (FAT) किंवा एसएनएफ (SNF) असामान्य आढळल्यास (उदा. दुधात पाणी मिसळल्यास SNF अचानक कमी होणे) ॲप त्वरित इशारा देते.
2. **दुधाचा गुणवत्ता स्कोअर (Milk Quality Prediction)**:
   - संकलित दुधाचे शुद्धतेनुसार परीक्षण करून **Grade A / Good / Attention** असा दर्जा व स्कोअर (उदा. 86.5/100) देते.
3. **संकलन अंदाज (Collection Forecast)**:
   - सकाळ आणि संध्याकाळच्या शिफ्टमध्ये एकूण किती लिटर दूध जमा होईल याचा अचूक अंदाज वर्तवते (उदा. Morning Shift: 720.5 Ltr), ज्यामुळे टँकर वाहतुकीचे नियोजन सोपे होते.

💡 **कसे पाहायचे?**: डॅशबोर्डवरील **"AI Insights"** कार्ड खाली **"View All"** वर टॅप करा!'''
            : '''**What do the AI & ML Features in this App do?**

1. **Real-time Anomaly Detection**:
   - Compares incoming FAT/SNF readings against biological norms. If excessive water dilution or bad sensor calibration occurs, an instant alert is triggered.
2. **Milk Quality Prediction**:
   - Analyzes quality parameters and awards a purity score (e.g. **86.5/100 - Grade A Purity**), determining eligibility for clean milk bonuses.
3. **Shift Yield Forecasting**:
   - Predicts upcoming collection volume (e.g. **Morning Shift: 720.5 Ltr • Evening: 533.5 Ltr**) using linear trend modeling to help schedule dispatch tankers efficiently.

💡 **How to view**: Tap **"View All"** next to **AI Insights** on your Dashboard home screen!''',
        'suggestedActions': isMr
            ? ['FAT आणि SNF म्हणजे काय?', 'दूध दर कसा ठरवला जातो?']
            : ['What are FAT and SNF?', 'How is milk rate calculated?'],
      };
    }

    // J. Language Switching (English / Marathi)
    if (q.contains('language') ||
        q.contains('marathi') ||
        q.contains('english') ||
        q.contains('भाषा') ||
        q.contains('मराठी') ||
        q.contains('इंग्रजी')) {
      return {
        'text': isMr
            ? '''**ॲपची भाषा मराठी कशी करावी? (Language Switching):**

तुम्ही १ सेकंदात संपूर्ण ॲप मराठीत बदलू शकता:
1. डॅशबोर्डवर सर्वात वरच्या पट्टीतील **भाषा आयकॉन (文A)** वर टॅप करा.
2. **"Marathi (मराठी)"** निवडा.
3. सर्व बटणे, आकडेवारी, डॅशबोर्ड आणि अहवाल तात्काळ मराठीमध्ये भाषांतरित होतील!

*(तुम्ही डाव्या बाजूच्या मेनू (Drawer) मधून किंवा "Profile" स्क्रीनवरूनही भाषा बदलू शकता).*'''
            : '''**How to Change App Language to Marathi (or English):**

You can switch the entire application interface in one tap:
1. On the Dashboard top app bar, tap the **Language icon (文A)**.
2. Select **"Marathi (मराठी)"** or **"English"**.
3. All navigation, buttons, calculations, and tables instantly update to your chosen language!

*(You can also change language anytime from the left Navigation Drawer or Profile screen).*''',
        'suggestedActions': isMr
            ? ['दूध संकलन कसे नोंदवायचे?', 'नवीन शेतकरी कसा जोडायचा?']
            : ['How to record milk collection?', 'How to add a farmer?'],
      };
    }

    // K. Offline Architecture & Sync
    if (q.contains('sync') ||
        q.contains('offline') ||
        q.contains('internet') ||
        q.contains('सिंक') ||
        q.contains('इंटरनेट') ||
        q.contains('ऑफलाईन')) {
      return {
        'text': isMr
            ? '''**ऑफलाईन डेटा आणि सिंक (Data Syncing Guide):**

स्मार्ट डेअरी हे **Offline-First** तत्त्वावर तयार केले आहे:
• **इंटरनेट नसतानाही चालू राहते**: गावात नेटवर्क नसले तरी दूध संकलन, शेतकरी नोंदणी आणि बिलिंग सुरळीत चालते. सर्व डेटा फोनच्या सुरक्षित स्थानिक मेमरीमध्ये साठवला जातो.
• **सिंक (Sync) कसे करावे?**:
  1. जेव्हा इंटरनेट उपलब्ध होईल, डॅशबोर्डवरील वरच्या **मेघ आयकॉनवर (Cloud Icon ☁️)** टॅप करा.
  2. सर्व प्रलंबित (Pending) नोंदी काही सेकंदात केंद्रीय सर्व्हरवर सुरक्षितपणे पाठवल्या जातील.
  3. सर्व डेटा सिंक झाल्यावर ढगावर हिरवी बरोबरची खूण दिसेल!'''
            : '''**Offline Data & Syncing Troubleshooting:**

The Smart Dairy app is built with an **Offline-First Architecture**:
• **Works Without Internet**: In remote rural villages with no cellular connectivity, you can continue recording collections, issuing advances, and generating bills without interruption.
• **How to Sync when Network Returns**:
  1. Tap the **Cloud icon (☁️)** at the top right of the Dashboard.
  2. The counter displays how many offline records are queued.
  3. Tapping it triggers background batch synchronization with zero duplicate entries.
  4. Once complete, the icon turns into a green checkmark indicating "Server in Sync"!''',
        'suggestedActions': isMr
            ? ['दूध संकलन कसे नोंदवायचे?', '१०-दिवसीय बिलिंग कसे चालते?']
            : [
                'How to record milk collection?',
                'How does 10-day billing work?',
              ],
      };
    }

    // M. Admin Role, App Developer (Vishwajeet) & Dairy Owner Problem Resolution
    if (q.contains('admin') ||
        q.contains('developer') ||
        q.contains('vishwajeet') ||
        q.contains('facing problem') ||
        q.contains('facing issue') ||
        q.contains('contact admin') ||
        q.contains('contact dev') ||
        q.contains('support') ||
        q.contains('issue') ||
        q.contains('problem') ||
        q.contains('troubleshoot') ||
        q.contains('solve') ||
        q.contains('समस्या') ||
        q.contains('तक्रार') ||
        q.contains('मदत') ||
        q.contains('ॲडमिन') ||
        q.contains('डेव्हलपर')) {
      return {
        'text': isMr
            ? '''**ॲडमिन भूमिका आणि ॲप डेव्हलपर (विश्वजीत) सपोर्ट:**

१. **ॲडमिन (Admin) कोण आहे?**:
   ॲडमिन म्हणजे या ॲप्लिकेशनचे मुख्य **डेव्हलपर (Vishwajeet)** आहेत, ज्यांना ॲपमधील सर्व १६ मॉड्यूल्स, डेटाबेस, रेट चार्ट्स, आणि बिलिंग इंजिनवर **पूर्ण प्रवेश अधिकार (Full Access)** आहेत.

२. **जर डेअरी मालकाला किंवा ऑपरेटरला कोणतीही समस्या आली तर**:
   - जर दूध संकलन, वजनकाटा BLE सिंक, फॅट-एसएनएफ दर आकारणी, १०-दिवसीय बिलिंग, शेतकरी कपात किंवा डेटा सिंकमध्ये कोणतीही त्रुटी किंवा अडचण आली, तर मालक थेट ॲडमिन (डेव्हलपर विश्वजीत) यांच्याशी संपर्क साधू शकतात.
   - **थेट फोन सपोर्ट**: +91 98220 12345
   - **WhatsApp सपोर्ट**: स्क्रीनशॉट आणि एरर लॉग शेअरिंग
   - **तक्रार नोंदवा (Submit Ticket)**: डॅशबोर्ड किंवा प्रोफाईलवरील "Contact Admin / Developer" वरून थेट तक्रार नोंदवा.

३. **ॲडमिन समस्या कशी सोडवतात?**:
   - ॲडमिनकडे Full Access असल्यामुळे ते रेट चार्ट त्रुटी दुरुस्त करू शकतात, स्थानिक डेटाबेस कॅशे रिपेअर करू शकतात, आणि बिलिंग स्टेटमेंट पुन्हा कॅल्क्युलेट करू शकतात!'''
            : '''**Admin Role & App Developer (Vishwajeet) Support:**

1. **Who is the Admin?**:
   The **Admin** role is the **Application Developer (Vishwajeet)** who has **Full Unrestricted Access** across all 16 modules, offline database caches, rate charts, and cycle billing engines.

2. **When Dairy Owners Face Any Problem**:
   - If the Dairy Owner (or staff) encounters any problem—such as Bluetooth scale connection lag, milk rate calculation disputes, 10-day cycle statement adjustments, farmer advance balance mismatches, or offline sync conflicts—they can directly contact Admin (Developer Vishwajeet).
   - **Developer Hotline**: +91 98220 12345 (Direct Call)
   - **WhatsApp Support**: Instant error screenshot & log sharing
   - **In-App Problem Ticket**: Submit directly via Drawer or Profile -> "Contact Admin / Developer"

3. **How Admin Solves the Problem**:
   - Because the Admin has full developer access, Vishwajeet can inspect local database records, resolve calculation rules, adjust rate matrices, and clear offline sync locks to restore 100% operational flow!''',
        'suggestedActions': isMr
            ? [
                'ॲडमिनशी संपर्क साधा',
                'ॲडमिनचे पूर्ण अधिकार समजावा',
                '१०-दिवसीय बिलिंग कसे चालते?',
                'दूध संकलन कसे नोंदवायचे?',
              ]
            : [
                'Contact Admin (Developer)',
                'Explain Admin Full Access',
                'How does 10-day billing work?',
                'How to record milk collection?',
              ],
      };
    }

    // L. Cattle Feed & Products Inventory
    if (q.contains('product') ||
        q.contains('feed') ||
        q.contains('inventory') ||
        q.contains('stock') ||
        q.contains('पशूखाद्य') ||
        q.contains('गोळी पेंड') ||
        q.contains('औषध')) {
      return {
        'text': isMr
            ? '''**पशूखाद्य आणि वस्तू स्टोअर (Products & Cattle Feed Store):**

डेअरी केंद्रावरून शेतकऱ्यांना पुरवले जाणारे पशूखाद्य, खनिज मिश्रणे आणि साहित्य व्यवस्थापित करण्यासाठी:
1. डॅशबोर्डवरील **"Products"** वर टॅप करा.
2. येथे पशूखाद्य (Cattle Feed 50kg), मिनरल मिक्स्चर, कॅल्शियम टॉनिक आणि स्टेनलेस स्टीलच्या कॅन यांची यादी दिसेल.
3. **नवीन वस्तू जोडण्यासाठी**: वरच्या **(+) बटणावर** टॅप करून वस्तूचे नाव, प्रकार, किंमत (₹) आणि प्रारंभिक स्टॉक टाका.
4. जेव्हा शेतकरी पशूखाद्य खरेदी करतो, तेव्हा त्याची किंमत त्याच्या १०-दिवसीय बिलातून आपोआप कपात (Deduction) म्हणून जोडली जाऊ शकते!'''
            : '''**Cattle Feed & Product Store Management:**

To manage cooperative supplies, mineral feed, and equipment issued to farmers:
1. Tap the **"Products"** card on the Dashboard.
2. View catalog items like Cattle Feed 50kg, Mineral Mixture, Calcium Tonic, and 40L Milk Cans with live stock counts.
3. **Add New Product**: Tap the **(+) button** at the top, enter the product name, category, price in ₹, and stock quantity.
4. When farmers purchase feed on credit, it links directly to their billing cycle as a store deduction!''',
        'suggestedActions': isMr
            ? ['कपात (Deduction) कशी जोडायची?', '१०-दिवसीय बिलिंग कसे चालते?']
            : ['How to add deduction?', 'How does 10-day billing work?'],
      };
    }

    // Default Fallback for Unrelated Custom Questions when LLM is unavailable
    return {
      'text': isMr
          ? '''⚠️ **थेट AI सहाय्यक सध्या अनुपलब्ध आहे (Live AI Unavailable)**

मी या सानुकूल प्रश्नाचे गतिमान उत्तर देऊ शकत नाही कारण बॅकएंड Large Language Model (LLM) जोडलेले नाही. ऑफलाईन / स्थानिक मोडमध्ये मी केवळ या ॲपमधील प्रमाणित फिचर्सचे अचूक मार्गदर्शन करू शकतो.

**तुम्ही मला खालील विषयांवर विचारू शकता:**
• **'Detailed Bill'** (तपशीलवार बिल, कपाती आणि पेमेंट कसे पाहावे)
• **'दूध संकलन'** (सकाळ/संध्याकाळ नोंदी आणि BLE वजनकाटा)
• **'FAT आणि SNF'** (दर सूत्र आणि फरक)
• **'PDF अहवाल'** (बिल डाऊनलोड आणि शेअरिंग)
• **'शेतकरी नोंदणी'** (कोड लिंकिंग आणि गायब नोंदी)

सानुकूल किंवा नवीन प्रश्न विचारण्यासाठी कृपया स्प्रिंग बूट सर्व्हरवर OPENAI_API_KEY किंवा स्थानिक Ollama मॉडेल सेट करा.'''
          : '''⚠️ **Live Conversational AI is Currently Unavailable**

I cannot dynamically answer this custom question because a live Large Language Model (LLM) is not currently connected to the backend. In offline / local knowledge mode, I can only provide guidance on verified Smart Dairy application features.

**You can ask about any implemented app feature, including:**
• **'Detailed Bill'**: Viewing member shift records, deductions, and payout statements
• **'Milk Collection'**: Recording morning/evening shifts and BLE auto-read
• **'FAT and SNF'**: Dual-axis rate formula and quality benchmarks
• **'PDF Statements'**: Downloading and sharing certified reports
• **'Farmer Account Linking'**: Resolving missing entries and member codes (e.g. M001/M003)

To ask arbitrary questions freely like ChatGPT, configure an LLM API key (e.g. OpenAI or Ollama) on the Spring Boot backend server.''',
      'suggestedActions': isMr
          ? [
              'तपशीलवार बिल कसे पाहावे?',
              'दूध संकलन कसे नोंदवायचे?',
              'FAT आणि SNF म्हणजे काय?',
              '१०-दिवसीय बिलिंग कसे चालते?',
            ]
          : [
              'Explain Detailed Bill',
              'How do I record milk collection?',
              'Explain FAT and SNF',
              'How does 10-day billing work?',
            ],
    };
  }

  /// Context-specific answers when user asks while viewing a particular screen
  static Map<String, dynamic>? _matchScreenContext(
    String screen,
    String query,
    bool isMr,
    String role,
  ) {
    final s = screen.toLowerCase();
    final q = query.toLowerCase();

    if (s.contains('collection')) {
      if (q.contains('this screen') ||
          q.contains('explain') ||
          q.contains('buttons') ||
          q.contains('काय आहे')) {
        return {
          'text': isMr
              ? '''**दूध संकलन स्क्रीन मार्गदर्शक (Milk Collection Screen Controls):**

• **Auto-Read (BLE) बटण**: इलेक्ट्रॉनिक वजनकाटा आणि फॅट ॲनालायझरशी ब्लूटूथद्वारे कनेक्ट करून वजन आणि फॅट आपोआप भरते.
• **Member Dropdown**: शेतकरी निवडण्यासाठी.
• **Cow / Buffalo Buttons**: जनावराचा प्रकार निवडणे (म्हैशीच्या दुधाचा दर जास्त असतो).
• **Morning / Evening**: संकलनाचे सत्र निवडणे.
• **Milk Quantity**: वजन (केवळ संख्या व दशांश स्वीकारले जातात).
• **FAT & SNF**: प्रयोगशाळा तपासणीनुसार टक्केवारी.
• **SAVE COLLECTION**: नोंद सेव्ह करून पावती तयार करते.'''
              : '''**Milk Collection Screen Controls Guide:**

• **Auto-Read (BLE) Button**: Connects wirelessly to your electronic weighing scale and ultrasonic milk analyzer to auto-fill litres and FAT.
• **Member Dropdown**: Select the registered farmer.
• **Cow / Buffalo Buttons**: Toggles animal breed (Buffalo milk commands higher fat-based rates).
• **Morning / Evening**: Sets collection session.
• **Milk Quantity**: Input volume in litres (strictly accepts decimal numbers).
• **FAT & SNF**: Quality readings determining rate.
• **SAVE COLLECTION**: Commits entry and prints/saves receipt.''',
          'suggestedActions': isMr
              ? ['दूध दर कसा ठरवला जातो?', 'FAT आणि SNF म्हणजे काय?']
              : ['How is milk rate calculated?', 'What are FAT and SNF?'],
        };
      }
    }

    if (s.contains('billing') ||
        s.contains('invoice') ||
        s.contains('statement')) {
      if (q.contains('this screen') ||
          q.contains('explain') ||
          q.contains('काय आहे')) {
        return {
          'text': isMr
              ? '''**बिलिंग आणि तपशीलवार स्टेटमेंट स्क्रीन मार्गदर्शक:**

• **10 Days / 15 Days / Monthly टॅब**: हव्या त्या कालावधीचा हिशोब निवडण्यासाठी.
• **दूध तक्ता**: सायकलमधील प्रत्येक दिवसाचे सकाळ-संध्याकाळचे लिटर, फॅट आणि एकूण रक्कम.
• **Deductions & Advances**: पशूखाद्य आणि आगाऊ कर्जाची कापलेली रक्कम.
• **Net Payable**: शेतकऱ्याला प्रत्यक्ष द्यावयाची निव्वळ रक्कम.
• **Download PDF**: शासकीय ऑडिट व शेतकऱ्याला देण्यासाठी अधिकृत PDF तयार करते.'''
              : '''**Billing & Detailed Statement Screen Guide:**

• **10 Days / 15 Days / Monthly Tabs**: Switches between cooperative settlement cycles.
• **Daily Shift Breakdown Table**: Shows daily litres, FAT, SNF, and rate for each shift.
• **Deductions & Advances Row**: Lists recovered loan payments and feed store deductions.
• **Net Payable Header**: The final amount to be paid to the farmer.
• **Download PDF Statement**: Generates an audit-ready certified statement for printing or WhatsApp.''',
          'suggestedActions': isMr
              ? ['१०-दिवसीय बिलिंग कसे चालते?', 'पेमेंट स्लिप कशी पाहायची?']
              : [
                  'How does 10-day billing work?',
                  'How to generate payment slip?',
                ],
        };
      }
    }

    return null;
  }

  static bool _isAttemptingPrivateDataLeak(String query) {
    final q = query.toLowerCase();
    return q.contains('password') ||
        q.contains('secret key') ||
        q.contains('show all pin') ||
        q.contains('show password') ||
        q.contains('पासवर्ड दाखवा');
  }

  static bool _isAttemptingActionExecution(String query) {
    final q = query.toLowerCase();
    return q.startsWith('pay ') ||
        q.startsWith('delete all') ||
        q.startsWith('drop table') ||
        q.contains('transfer money') ||
        q.contains('सर्व डेटा डिलीट करा') ||
        q.contains('पैसे पाठवा');
  }
}
