import 'package:flutter/material.dart';

class LanguageService {
  static final ValueNotifier<String> currentLanguageNotifier =
      ValueNotifier<String>('English');

  static String get currentLanguage => currentLanguageNotifier.value;

  static String get currentLanguageCode {
    if (currentLanguage.startsWith('Marathi')) return 'mr';
    if (currentLanguage.startsWith('Hindi')) return 'hi';
    return 'en';
  }

  static void setLanguage(String lang) {
    if (lang == 'mr' || lang.contains('Marathi')) {
      currentLanguageNotifier.value = 'Marathi (मराठी)';
    } else if (lang == 'hi' || lang.contains('Hindi')) {
      currentLanguageNotifier.value = 'Hindi (हिंदी)';
    } else {
      currentLanguageNotifier.value = 'English';
    }
  }

  static final Map<String, Map<String, String>> _translations = {
    // General & Branding
    'Smart Dairy': {'mr': 'स्मार्ट डेअरी', 'hi': 'स्मार्ट डेयरी'},
    'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur': {
      'mr': 'स्व. एल. डी. कदम दूध उत्पादक सहकारी संस्था मर्या., कदमवाडी, कोल्हापूर',
      'hi': 'स्व. एल. डी. कदम दूध उत्पादक सहकारी संस्था लि., कदमवाडी, कोल्हापुर',
    },
    'LATE L D KADAM MILK PRODUCERS COOPERATIVE SOCIETY LTD., KADAMWADI, KOLHAPUR': {
      'mr': 'स्व. एल. डी. कदम दूध उत्पादक सहकारी संस्था मर्या., कदमवाडी, कोल्हापूर',
      'hi': 'स्व. एल. डी. कदम दूध उत्पादक सहकारी संस्था लि., कदमवाडी, कोल्हापुर',
    },
    'LATE L D KADAM COOP DAIRY': {
      'mr': 'स्व. एल. डी. कदम सहकारी डेअरी',
      'hi': 'स्व. एल. डी. कदम सहकारी डेयरी',
    },
    'LATE L D KADAM DAIRY': {
      'mr': 'स्व. एल. डी. कदम डेअरी',
      'hi': 'स्व. एल. डी. कदम डेयरी',
    },
    'LATE L D KADAM': {
      'mr': 'स्व. एल. डी. कदम',
      'hi': 'स्व. एल. डी. कदम',
    },
    'Late L D Kadam Dairy': {
      'mr': 'स्व. एल. डी. कदम डेअरी',
      'hi': 'स्व. एल. डी. कदम डेयरी',
    },
    'SAI KRUPA DAIRY': {
      'mr': 'स्व. एल. डी. कदम दूध उत्पादक सहकारी संस्था मर्या., कदमवाडी, कोल्हापूर',
      'hi': 'स्व. एल. डी. कदम दूध उत्पादक सहकारी संस्था लि., कदमवाडी, कोल्हापुर',
    },
    'SAI KRUPA': {
      'mr': 'स्व. एल. डी. कदम',
      'hi': 'स्व. एल. डी. कदम',
    },
    'Welcome Back!': {'mr': 'पुन्हा स्वागत आहे!', 'hi': 'वापसी पर स्वागत है!'},
    'Sign in to manage your dairy center': {
      'mr': 'तुमचे डेअरी केंद्र व्यवस्थापित करण्यासाठी साइन इन करा',
      'hi': 'अपने डेयरी केंद्र को प्रबंधित करने के लिए साइन इन करें',
    },
    'Login': {'mr': 'लॉगिन करा', 'hi': 'लॉग इन करें'},
    'Username': {
      'mr': 'वापरकर्ता नाव (युझरनेम)',
      'hi': 'उपयोगकर्ता नाम (यूज़रनेम)',
    },
    'Enter username': {
      'mr': 'युझरनेम प्रविष्ट करा',
      'hi': 'यूज़रनेम दर्ज करें',
    },
    'Password': {'mr': 'पासवर्ड', 'hi': 'पासवर्ड'},
    'Enter password': {'mr': 'पासवर्ड प्रविष्ट करा', 'hi': 'पासवर्ड दर्ज करें'},
    'Remember me': {'mr': 'माझी आठवण ठेवा', 'hi': 'मुझे याद रखें'},
    'Forgot Password?': {'mr': 'पासवर्ड विसरलात?', 'hi': 'पासवर्ड भूल गए?'},
    'Secure login with JWT authentication': {
      'mr': 'सुरक्षित JWT ऑथेंटिकेशन लॉगिन',
      'hi': 'सुरक्षित JWT प्रमाणीकरण लॉगिन',
    },
    'Milk Collection & Dairy Management': {
      'mr': 'दूध संकलन आणि डेअरी व्यवस्थापन',
      'hi': 'दूध संकलन एवं डेयरी प्रबंधन',
    },
    'Dark Mode Theme': {'mr': 'डार्क मोड थीम', 'hi': 'डार्क मोड थीम'},
    'Toggle dark slate theme mode': {
      'mr': 'डार्क स्लेट थीम चालू किंवा बंद करा',
      'hi': 'डार्क स्लेट थीम टॉगल करें',
    },
    'Collection Slip': {
      'mr': 'संकलन पावती / स्लिप',
      'hi': 'संकलन पर्ची / स्लिप',
    },
    'Print / Done': {'mr': 'प्रिंट / पूर्ण', 'hi': 'प्रिंट / संपन्न'},
    'Slip copied to clipboard!': {
      'mr': 'पावती क्लिपबोर्डवर कॉपी केली!',
      'hi': 'पर्ची क्लिपबोर्ड पर कॉपी की गई!',
    },
    'Copy': {'mr': 'कॉपी करा', 'hi': 'कॉपी करें'},
    'Sync Status': {'mr': 'सिंक स्थिती', 'hi': 'सिंक स्थिति'},
    'Pending Sync': {'mr': 'प्रलंबित सिंक', 'hi': 'लंबित सिंक'},
    'All records synced': {
      'mr': 'सर्व नोंदी सिंक केल्या आहेत',
      'hi': 'सभी रिकॉर्ड सिंक किए गए हैं',
    },
    'Center Code: SK-402': {
      'mr': 'केंद्र कोड: SK-402',
      'hi': 'केंद्र कोड: SK-402',
    },
    'Center Code': {'mr': 'केंद्र कोड', 'hi': 'केंद्र कोड'},

    // Dashboard
    'Hello, Dairy Owner 👋': {
      'mr': 'नमस्कार, डेअरी मालक 👋',
      'hi': 'नमस्ते, डेयरी मालिक 👋',
    },
    'Hello, Admin (Developer) 👋': {
      'mr': 'नमस्कार, ॲडमिन (डेव्हलपर) 👋',
      'hi': 'नमस्ते, एडमिन (डेवलपर) 👋',
    },
    'Admin (Developer)': {'mr': 'ॲडमिन (डेव्हलपर)', 'hi': 'एडमिन (डेवलपर)'},
    'Admin (Dev)': {'mr': 'ॲडमिन (डेव्ह)', 'hi': 'एडमिन (देव)'},
    'Admin': {'mr': 'ॲडमिन', 'hi': 'एडमिन'},
    'Admin Console': {'mr': 'ॲडमिन कन्सोल', 'hi': 'एडमिन कंसोल'},
    'Member (Farmer)': {'mr': 'सभासद (शेतकरी)', 'hi': 'सदस्य (किसान)'},
    'Hello, Member (Farmer) 👋': {'mr': 'नमस्कार, शेतकरी बंधू 👋', 'hi': 'नमस्ते, किसान भाई 👋'},
    'My Milk & Earnings Today': {'mr': 'आजचे माझे दूध आणि उत्पन्न', 'hi': 'आज का मेरा दूध व आय'},
    'My Milk': {'mr': 'माझे दूध', 'hi': 'मेरा दूध'},
    'My Earnings': {'mr': 'माझी कमाई', 'hi': 'मेरी कमाई'},
    'My Slips': {'mr': 'माझ्या पावत्या', 'hi': 'मेरी पर्चियां'},
    'My Avg FAT': {'mr': 'माझे सरासरी फॅट', 'hi': 'मेरा औसत फैट'},
    'Milk Passbook': {'mr': 'दूध पासबुक', 'hi': 'दूध पासबुक'},
    'My Invoices & Billing': {'mr': 'माझी बिले व हिशोब', 'hi': 'मेरे बिल व चालान'},
    'View your payment bills, deductions & cycle slips': {
      'mr': 'तुमची दूध बिले, कपात आणि १०-दिवसीय स्लिप पहा',
      'hi': 'अपने दूध के बिल, कटौती और १०-दिवसीय पर्चियां देखें',
    },
    'Contact Admin': {'mr': 'ॲडमिन संपर्क', 'hi': 'एडमिन संपर्क'},
    'Contact Admin / Developer': {
      'mr': 'ॲडमिन / डेव्हलपरशी संपर्क साधा',
      'hi': 'एडमिन / डेवलपर से संपर्क करें',
    },
    'Developer Vishwajeet': {
      'mr': 'डेव्हलपर विश्वजीत',
      'hi': 'डेवलपर विश्वजीत',
    },
    'Developer Vishwajeet (Full System Access)': {
      'mr': 'डेव्हलपर विश्वजीत (सर्व अधिकार)',
      'hi': 'डेवलपर विश्वजीत (पूर्ण पहुँच)',
    },
    'Morning Shift': {'mr': 'सकाळ सत्र', 'hi': 'सुबह की पाली'},
    'Evening Shift': {'mr': 'संध्याकाळ सत्र', 'hi': 'शाम की पाली'},
    'Morning': {'mr': 'सकाळ', 'hi': 'सुबह'},
    'Evening': {'mr': 'संध्याकाळ', 'hi': 'शाम'},
    "Today's Overview": {'mr': 'आजचा गोषवारा', 'hi': 'आज का विवरण'},
    'Total Milk': {'mr': 'एकूण दूध', 'hi': 'कुल दूध'},
    'Total Amount': {'mr': 'एकूण रक्कम', 'hi': 'कुल राशि'},
    'Members': {'mr': 'सभासद', 'hi': 'सदस्य'},
    'Avg FAT': {'mr': 'सरासरी फॅट', 'hi': 'औसत फैट'},
    'Quick Access': {'mr': 'जलद पर्याय', 'hi': 'त्वरित पहुँच'},
    'Collection': {'mr': 'दूध संकलन', 'hi': 'दूध संकलन'},
    'Customer': {'mr': 'सभासद', 'hi': 'ग्राहक / सदस्य'},
    'Dashboard': {'mr': 'डॅशबोर्ड', 'hi': 'डैशबोर्ड'},
    'View All': {'mr': 'सर्व पहा', 'hi': 'सभी देखें'},
    'Rate Chart': {'mr': 'दर पत्रक', 'hi': 'दर तालिका'},
    'Advance': {'mr': 'अ‍ॅडव्हान्स (उचल)', 'hi': 'अग्रिम राशि'},
    'Invoice': {'mr': 'बिल / पावती', 'hi': 'चालान / बिल'},
    'Payments': {'mr': 'पेमेंट्स', 'hi': 'भुगतान'},
    'Deduction': {'mr': 'कपात', 'hi': 'कटौती'},
    'Milk Sale': {'mr': 'दूध विक्री', 'hi': 'दूध बिक्री'},
    'Reports': {'mr': 'अहवाल', 'hi': 'रिपोर्ट्स'},
    'Expense': {'mr': 'खर्च', 'hi': 'खर्च'},
    'Dispatch': {'mr': 'डिसपॅच (पाठवणे)', 'hi': 'डिस्पैच'},
    'Received': {'mr': 'स्वीकारलेले दूध', 'hi': 'प्राप्त दूध'},
    'Products': {'mr': 'पशूखाद्य व वस्तू', 'hi': 'पशु आहार व उत्पाद'},
    'Detailed Bill': {'mr': 'तपशीलवार बिल', 'hi': 'विस्तृत बिल'},
    'Annual Bonus': {'mr': 'वार्षिक बोनस', 'hi': 'वार्षिक बोनस'},
    'AI Insights': {
      'mr': 'एआय विश्लेषण व सूचना',
      'hi': 'एआई अंतर्दृष्टि व अलर्ट',
    },
    'Milk collection is 12% higher than yesterday.': {
      'mr': 'कालच्या तुलनेत दूध संकलनात १२% वाढ झाली आहे.',
      'hi': 'कल की तुलना में दूध संकलन १२% अधिक है।',
    },
    '2 unusual FAT values detected today.': {
      'mr': 'आज २ संशयास्पद फॅट नोंदी आढळल्या आहेत.',
      'hi': 'आज २ असामान्य फैट मान पाए गए हैं।',
    },
    '2 unusual FAT values detected today on Khed route.': {
      'mr': 'खेड मार्गावर आज २ संशयास्पद फॅट नोंदी आढळल्या आहेत.',
      'hi': 'खेड रूट पर आज २ असामान्य फैट मान पाए गए हैं।',
    },
    'Optimal evening dispatch vehicle timing: 06:30 PM.': {
      'mr': 'संध्याकाळच्या वाहनाची योग्य वेळ: संध्याकाळी ०६:३०.',
      'hi': 'शाम के वाहन का सही समय: शाम ०६:३०.',
    },

    // Navigation & Tabs
    'Home': {'mr': 'होम', 'hi': 'होम'},
    'Profile': {'mr': 'प्रोफाइल', 'hi': 'प्रोफ़ाइल'},
    'Profile & Settings': {
      'mr': 'प्रोफाइल आणि सेटिंग्ज',
      'hi': 'प्रोफ़ाइल और सेटिंग्स',
    },

    // Drawer items
    'Navigation': {'mr': 'नेव्हिगेशन', 'hi': 'नेविगेशन'},
    'Dashboard / Home': {'mr': 'डॅशबोर्ड / होम', 'hi': 'डैशबोर्ड / होम'},
    'Dashboard Overview': {'mr': 'डॅशबोर्ड गोषवारा', 'hi': 'डैशबोर्ड विवरण'},
    'Milk Collection': {'mr': 'दूध संकलन', 'hi': 'दूध संकलन'},
    'Members Management': {'mr': 'सभासद व्यवस्थापन', 'hi': 'सदस्य प्रबंधन'},
    'Advance Payments': {'mr': 'अ‍ॅडव्हान्स देयके', 'hi': 'अग्रिम भुगतान'},
    'Farmer Advance': {'mr': 'शेतकरी अ‍ॅडव्हान्स', 'hi': 'किसान अग्रिम'},
    'Invoices & Billing': {'mr': 'बिल आणि पावत्या', 'hi': 'चालान और बिलिंग'},
    'Payments & Payouts': {'mr': 'पेमेंट्स आणि देयके', 'hi': 'भुगतान विवरण'},
    'Deductions (Feed/Loan)': {
      'mr': 'कपात (पशुखाद्य/कर्ज)',
      'hi': 'कटौती (चारा/ऋण)',
    },
    'Milk Sales': {'mr': 'दूध विक्री', 'hi': 'दूध बिक्री'},
    'Expenses Tracker': {'mr': 'खर्च ट्रॅकर', 'hi': 'खर्च ट्रैकर'},
    'Dispatch to Plant': {
      'mr': 'प्लँटकडे दूध पाठवणे',
      'hi': 'प्लांट को डिस्पैच',
    },
    'Received Tankers': {'mr': 'स्वीकारलेले टँकर्स', 'hi': 'प्राप्त टैंकर'},
    'Notifications & Alerts': {'mr': 'सूचना व इशारे', 'hi': 'सूचनाएं और अलर्ट'},
    'Settings & System': {
      'mr': 'सेटिंग्ज व सिस्टीम',
      'hi': 'सेटिंग्स और सिस्टम',
    },
    'Help & Support Hotline': {
      'mr': 'मदत व हेल्पलाइन',
      'hi': 'मदद और हेल्पलाइन',
    },
    'Reports & Analytics': {
      'mr': 'अहवाल आणि विश्लेषण',
      'hi': 'रिपोर्ट्स और विश्लेषण',
    },
    'Notifications': {'mr': 'सूचना', 'hi': 'सूचनाएं'},
    'Settings': {'mr': 'सेटिंग्ज', 'hi': 'सेटिंग्स'},
    'Help & Support': {'mr': 'मदत आणि सहाय्य', 'hi': 'मदद और सहायता'},
    'Logout': {'mr': 'लॉग आऊट', 'hi': 'लॉग आउट'},

    // Milk Collection Screen
    "Today's Collection": {'mr': 'आजचे संकलन', 'hi': 'आज का संकलन'},
    'Milk Entries': {'mr': 'दूध नोंदी', 'hi': 'दूध प्रविष्टियाँ'},
    'Milk': {'mr': 'दूध', 'hi': 'दूध'},
    'Amount': {'mr': 'रक्कम', 'hi': 'राशि'},
    'Entries': {'mr': 'नोंदी', 'hi': 'प्रविष्टियाँ'},
    'Add Milk Collection': {'mr': 'नवीन दूध नोंद', 'hi': 'दूध संकलन जोड़ें'},
    'Search member or animal...': {
      'mr': 'सभासद किंवा जनावर शोधा...',
      'hi': 'सदस्य या पशु खोजें...',
    },
    'Member': {'mr': 'सभासद', 'hi': 'सदस्य'},
    'Select Member': {'mr': 'सभासद निवडा', 'hi': 'सदस्य चुनें'},
    'Animal Type': {'mr': 'जनावराचा प्रकार', 'hi': 'पशु का प्रकार'},
    'Cow': {'mr': 'गाय', 'hi': 'गाय'},
    'Buffalo': {'mr': 'म्हैस', 'hi': 'भैंस'},
    'Shift': {'mr': 'सत्र', 'hi': 'पाली'},
    'Quantity': {'mr': 'प्रमाण', 'hi': 'मात्रा'},
    'FAT': {'mr': 'फॅट', 'hi': 'फैट'},
    'SNF': {'mr': 'एस.एन.एफ', 'hi': 'एस.एन.एफ'},
    'No Collection Found': {
      'mr': 'कोणतीही नोंद सापडली नाही',
      'hi': 'कोई प्रविष्टि नहीं मिली',
    },
    'Try searching for another member.': {
      'mr': 'दुसऱ्या सभासदाचा शोध घेऊन पहा.',
      'hi': 'किसी अन्य सदस्य को खोजें।',
    },
    'Milk collection saved successfully': {
      'mr': 'दूध संकलन यशस्वीरित्या जतन झाले!',
      'hi': 'दूध संकलन सफलतापूर्वक सहेजा गया!',
    },
    'Matched rate from Rate Chart': {
      'mr': 'दर पत्रकानुसार लागू झालेला दर',
      'hi': 'दर तालिका से लागू दर',
    },
    'Based on the nearest FAT and SNF chart row': {
      'mr': 'जवळच्या फॅट आणि एस.एन.एफ पत्रकानुसार',
      'hi': 'निकटतम फैट और एस.एन.एफ तालिका अनुसार',
    },
    'Farmer Name': {'mr': 'शेतकऱ्याचे नाव', 'hi': 'किसान का नाम'},
    'Cattle Type': {'mr': 'जनावराचा प्रकार', 'hi': 'पशु का प्रकार'},
    'Date & Time': {'mr': 'दिनांक व वेळ', 'hi': 'दिनांक और समय'},
    'TOTAL AMOUNT': {'mr': 'एकूण रक्कम', 'hi': 'कुल राशि'},
    'Save Collection': {'mr': 'संकलन जतन करा', 'hi': 'संकलन सहेजें'},

    // Members Screen
    'Total Members': {'mr': 'एकूण सभासद', 'hi': 'कुल सदस्य'},
    'Active': {'mr': 'सक्रिय', 'hi': 'सक्रिय'},
    'Milk Today': {'mr': 'आजचे दूध', 'hi': 'आज का दूध'},
    'Search member by name or phone': {
      'mr': 'सभासदाचे नाव किंवा फोन शोधा',
      'hi': 'नाम या फोन से सदस्य खोजें',
    },
    'Add Member': {'mr': 'नवीन सभासद जोडा', 'hi': 'सदस्य जोड़ें'},
    'Member Name': {'mr': 'सभासदाचे नाव', 'hi': 'सदस्य का नाम'},
    'Phone Number': {'mr': 'फोन नंबर', 'hi': 'फ़ोन नंबर'},
    'Edit Member': {'mr': 'सभासद संपादित करा', 'hi': 'सदस्य संपादित करें'},
    'Delete Member?': {
      'mr': 'सभासद हटवायचा आहे का?',
      'hi': 'क्या सदस्य को हटाना है?',
    },
    'Bank & Payout Information': {
      'mr': 'बँक आणि पेमेंट माहिती',
      'hi': 'बैंक और भुगतान विवरण',
    },
    'Bank Name': {'mr': 'बँकेचे नाव', 'hi': 'बैंक का नाम'},
    'Account Number': {'mr': 'खाते क्रमांक', 'hi': 'खाता संख्या'},
    'IFSC Code': {'mr': 'आय.एफ.एस.सी कोड', 'hi': 'आई.एफ.एस.सी कोड'},
    'Call Member': {'mr': 'कॉल करा', 'hi': 'कॉल करें'},
    'CANCEL': {'mr': 'रद्द करा', 'hi': 'रद्द करें'},
    'ADD': {'mr': 'जोडा', 'hi': 'जोड़ें'},
    'SAVE': {'mr': 'जतन करा', 'hi': 'सहेजें'},
    'DELETE': {'mr': 'हटवा', 'hi': 'हटाएं'},

    // Profile & Settings Screen
    'App Language': {'mr': 'अ‍ॅप भाषा', 'hi': 'ऐप भाषा'},
    'Select Language': {'mr': 'भाषा निवडा', 'hi': 'भाषा चुनें'},
    'System & Support': {'mr': 'सिस्टम आणि सहाय्य', 'hi': 'सिस्टम और सहायता'},
    'Data Backup & Sync': {
      'mr': 'डेटा बॅकअप आणि सिंक',
      'hi': 'डेटा बैकअप और सिंक',
    },
    'Help & Customer Support': {
      'mr': 'मदत आणि ग्राहक सहाय्य',
      'hi': 'मदद और ग्राहक सहायता',
    },
    'Active Collection Shift': {
      'mr': 'चालू संकलन सत्र',
      'hi': 'सक्रिय संकलन पाली',
    },
    'Dairy Information': {'mr': 'डेअरी माहिती', 'hi': 'डेयरी विवरण'},
    'Hardware & Devices': {
      'mr': 'हार्डवेअर आणि उपकरणे',
      'hi': 'हार्डवेयर और उपकरण',
    },
    'Connected Printer': {'mr': 'जोडलेला प्रिंटर', 'hi': 'कनेक्टेड प्रिंटर'},
    'Thermal POS 58mm': {
      'mr': 'थर्मल प्रिंटर ५८ मिमी',
      'hi': 'थर्मल प्रिंटर ५८ मिमी',
    },
    'Hardware Testing': {'mr': 'हार्डवेअर चाचणी', 'hi': 'हार्डवेयर परीक्षण'},
    'Milk Analyzer (FAT/SNF)': {
      'mr': 'मिल्क अ‍ॅनालायझर (फॅट/एस.एन.एफ)',
      'hi': 'मिल्क एनालाइज़र (फैट/एस.एन.एफ)',
    },
    'Weighing Scale': {'mr': 'वजन काटा', 'hi': 'वज़न काँटा'},
    'Security & Preferences': {
      'mr': 'सुरक्षा आणि प्राधान्ये',
      'hi': 'सुरक्षा और प्राथमिकताएं',
    },
    'Push Notifications': {'mr': 'पुश सूचना', 'hi': 'पुश सूचनाएं'},
    'Auto Slip Printing': {
      'mr': 'स्वयंचलित पावती छपाई',
      'hi': 'स्वचालित पर्ची छपाई',
    },
    'Offline Data Sync': {'mr': 'ऑफलाइन डेटा सिंक', 'hi': 'ऑफ़लाइन डेटा सिंक'},
    'Change Password': {'mr': 'पासवर्ड बदला', 'hi': 'पासवर्ड बदलें'},
    'Logout of Sai Krupa': {'mr': 'लॉग आऊट करा', 'hi': 'लॉग आउट करें'},
    'Logout of Late L D Kadam Dairy': {'mr': 'लॉग आऊट करा', 'hi': 'लॉग आउट करें'},
    'AI Smart Dairy Assistant': {
      'mr': 'AI स्मार्ट डेअरी सहाय्यक',
      'hi': 'AI स्मार्ट डेयरी सहायक',
    },
    'Ask AI Assistant': {
      'mr': 'AI सहाय्यकाला विचारा',
      'hi': 'AI सहायक से पूछें',
    },
    'AI Assistant': {'mr': 'AI सहाय्यक', 'hi': 'AI सहायक'},
    'Ask AI': {'mr': 'AI मदत', 'hi': 'AI मदद'},
    'Online Assistant': {'mr': 'ऑनलाईन सहाय्यक', 'hi': 'ऑनलाइन सहायक'},
    'Offline Knowledge': {
      'mr': 'स्थानिक ज्ञान केंद्र',
      'hi': 'स्थानीय ज्ञान केंद्र',
    },
    'Clear Chat': {'mr': 'संभाषण साफ करा', 'hi': 'बातचीत साफ़ करें'},
  };

  static String tr(String key) {
    final code = currentLanguageCode;
    if (code == 'en') return key;

    final entry = _translations[key];
    if (entry != null && entry.containsKey(code)) {
      return entry[code]!;
    }
    return key;
  }
}

extension StringTranslateExtension on String {
  String get tr => LanguageService.tr(this);
}
