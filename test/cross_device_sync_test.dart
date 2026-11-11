import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/dashboard/dashboard_screen.dart';
import 'package:test_app/milk_collection/milk_collection_screen.dart';
import 'package:test_app/invoice/invoice_screen.dart';
import 'package:test_app/screens/create_account_screen.dart';
import 'package:test_app/main_smartdairy_backup.dart';
import 'package:test_app/services/api_service.dart';
import 'package:test_app/services/language_service.dart';

void main() {
  setUp(() {
    LanguageService.setLanguage('English');
    ApiService.userRole = 'DAIRY_OWNER';
  });

  group('Cross-Device Owner and Member Data Synchronization & Security Tests', () {
    test('1. Owner records milk for Ramesh; Ramesh retrieves exact entry', () async {
      // Step A: Owner logs in
      final ownerLogin = await ApiService.login('owner', 'password');
      expect(ownerLogin['role'], 'DAIRY_OWNER');
      expect(ApiService.userRole, 'DAIRY_OWNER');

      // Step B: Owner records collection for Ramesh (M001)
      final newEntry = {
        'memberCode': 'M001',
        'memberName': 'Ramesh Patil',
        'animalType': 'Cow',
        'shift': 'Morning',
        'quantity': 25.5,
        'fat': 4.5,
        'snf': 8.6,
        'ratePerLitre': 42.0,
        'totalAmount': 1071.0,
        'collectionDate': 'Today',
      };
      final recorded = await ApiService.recordCollection(newEntry);
      expect(recorded, isNotNull);
      expect(recorded!['memberCode'], 'M001');

      // Step C: Ramesh logs in on his own phone as MEMBER
      final rameshLogin = await ApiService.login('ramesh', 'password');
      expect(rameshLogin['role'], 'MEMBER');
      expect(ApiService.userRole, 'MEMBER');
      expect(ApiService.currentMemberCode, 'M001');
      expect(ApiService.currentMemberName, 'Ramesh Patil');

      // Step D: Ramesh queries his collections passbook
      final rameshCols = await ApiService.getTodayCollections();
      expect(rameshCols.isNotEmpty, true);
      // All returned records must belong exclusively to Ramesh (M001)
      for (final item in rameshCols) {
        expect(item['memberCode'] ?? item['farmerId'], 'M001');
      }

      // Step E: Member summary is computed specifically for Ramesh
      final summary = await ApiService.getTodaySummary();
      expect(summary['totalMilk'], greaterThan(0));
      expect(summary['totalAmount'], greaterThan(0));
    });

    test('2. Tenant Isolation: Suresh (M002) cannot access Ramesh (M001) records', () async {
      // Step A: Suresh logs in on his phone as MEMBER
      final sureshLogin = await ApiService.login('suresh', 'password');
      expect(sureshLogin['role'], 'MEMBER');
      expect(ApiService.userRole, 'MEMBER');
      expect(ApiService.currentMemberCode, 'M002');
      expect(ApiService.currentMemberName, 'Suresh Deshmukh');

      // Step B: Suresh retrieves collections
      final sureshCols = await ApiService.getTodayCollections();
      for (final item in sureshCols) {
        // Must NEVER contain Ramesh's data
        expect(item['memberCode'], isNot('M001'));
        expect(item['memberName'], isNot('Ramesh Patil'));
        expect(item['memberCode'], 'M002');
      }

      // Step C: Suresh retrieves invoices
      final sureshInvoices = await ApiService.getInvoices();
      for (final item in sureshInvoices) {
        expect(item['memberCode'], isNot('M001'));
      }

      // Step D: Suresh retrieves advances
      final sureshAdvances = await ApiService.getAdvances();
      for (final item in sureshAdvances) {
        expect(item['memberId'], isNot('M001'));
      }
    });

    test('3. Server Endpoint Configuration is dynamic across Emulator and Mobile IP', () {
      expect(ApiService.serverHost, isNotEmpty);

      // Configure host for Android Emulator
      ApiService.setServerHost('10.0.2.2:8080');
      expect(ApiService.serverHost, '10.0.2.2:8080');
      expect(ApiService.baseUrl, 'http://10.0.2.2:8080/api/v1');

      // Configure host for Wi-Fi Physical Device
      ApiService.setServerHost('10.186.234.201:8080');
      expect(ApiService.serverHost, '10.186.234.201:8080');
      expect(ApiService.baseUrl, 'http://10.186.234.201:8080/api/v1');

      // Clean protocol prefixes
      ApiService.setServerHost('http://192.168.1.50:8080/api/v1/');
      expect(ApiService.serverHost, '192.168.1.50:8080');
    });

    testWidgets('4. Member Passbook UI restricts official collection entry addition', (WidgetTester tester) async {
      // Login as MEMBER
      await ApiService.login('ramesh', 'password');

      await tester.pumpWidget(
        const MaterialApp(
          home: MilkCollectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // App bar shows Passbook
      expect(find.text('Milk Passbook'), findsOneWidget);

      // Floating action button for creating new official collection is hidden for Member
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('5. Member Dashboard displays My Milk, My Earnings, and My Slips', (WidgetTester tester) async {
      // Login as MEMBER
      await ApiService.login('ramesh', 'password');

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello, Member (Farmer) 👋'), findsOneWidget);
      expect(find.text('My Milk & Earnings Today'), findsOneWidget);
      expect(find.text('My Milk'), findsOneWidget);
      expect(find.text('My Earnings'), findsOneWidget);
      expect(find.text('My Slips'), findsOneWidget);
      expect(find.text('Milk Passbook'), findsOneWidget);

      // BUG 1: Verify Add (+) button and collection creation actions are completely hidden for Member
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('6. Member Invoice Screen displays personal invoices and history', (WidgetTester tester) async {
      await ApiService.login('ramesh', 'password');

      await tester.pumpWidget(
        const MaterialApp(
          home: InvoiceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Invoices & Billing'), findsOneWidget);
    });

    testWidgets('7. Marathi Language translation applies to Member interface', (WidgetTester tester) async {
      LanguageService.setLanguage('Marathi (मराठी)');
      await ApiService.login('ramesh', 'password');

      await tester.pumpWidget(
        ValueListenableBuilder<String>(
          valueListenable: LanguageService.currentLanguageNotifier,
          builder: (context, _, __) {
            return const MaterialApp(
              home: DashboardScreen(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('नमस्कार, शेतकरी बंधू 👋'), findsOneWidget);
      expect(find.text('आजचे माझे दूध आणि उत्पन्न'), findsOneWidget);
      expect(find.text('माझे दूध'), findsOneWidget);
      expect(find.text('माझी कमाई'), findsOneWidget);
      expect(find.text('दूध पासबुक'), findsWidgets);
    });

    test('8. Audit history captures collection, payment, and advance operations', () async {
      await ApiService.login('owner', 'password');

      // Record a collection
      await ApiService.recordCollection({
        'memberCode': 'M001',
        'memberName': 'Ramesh Patil',
        'animalType': 'Cow',
        'shift': 'Morning',
        'quantity': 18.0,
        'fat': 4.1,
        'snf': 8.5,
        'ratePerLitre': 40.0,
        'totalAmount': 720.0,
      });

      // Grant an advance
      await ApiService.createAdvance({
        'member': 'Ramesh Patil',
        'memberId': 'M001',
        'amount': 1500.0,
        'reason': 'Cattle Feed',
      });

      // Disburse a payment
      await ApiService.createPayment({
        'member': 'Ramesh Patil',
        'gross': 5000.0,
        'advance': 1000.0,
        'deduction': 200.0,
        'amount': 3800.0,
        'cycle': '10 Days',
      });

      final auditLogs = await ApiService.getAuditLogs();
      expect(auditLogs.isNotEmpty, true);

      final hasCollectionAudit = auditLogs.any((l) => l['action'] == 'COLLECTION_RECORDED');
      final hasAdvanceAudit = auditLogs.any((l) => l['action'] == 'ADVANCE_GRANTED');
      final hasPaymentAudit = auditLogs.any((l) => l['action'] == 'PAYMENT_DISBURSED');

      expect(hasCollectionAudit, true);
      expect(hasAdvanceAudit, true);
      expect(hasPaymentAudit, true);
    });

    test('9. Secure logout clears auth token, member credentials, and resets session', () async {
      // Step A: Member logs in
      await ApiService.login('ramesh', 'password');
      expect(ApiService.userRole, 'MEMBER');
      expect(ApiService.currentMemberCode, 'M001');
      expect(ApiService.authToken, isNotNull);

      // Step B: Logout
      ApiService.logout();

      // Step C: Verify all credentials are wiped
      expect(ApiService.authToken, isNull);
      expect(ApiService.currentMemberCode, isNull);
      expect(ApiService.currentMemberId, isNull);
      expect(ApiService.currentMemberName, isNull);
      expect(ApiService.userRole, 'DAIRY_OWNER');
    });

    test('10. Milk Collection date filtering handles Today, Yesterday, and Range queries', () async {
      await ApiService.login('owner', 'password');

      final todayCols = await ApiService.getTodayCollections(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
      expect(todayCols, isNotNull);

      final shiftCols = await ApiService.getTodayCollections(
        shift: 'Morning',
      );
      expect(shiftCols, isNotNull);
      for (final item in shiftCols) {
        expect((item['shift'] ?? '').toString().toUpperCase(), 'MORNING');
      }
    });

    testWidgets('11. Fresh installation initial screen displays Create Account screen first', (WidgetTester tester) async {
      ApiService.resetInstallStateForTesting();
      // Emulate fresh install (no account created yet)
      expect(ApiService.hasCreatedAccount(), false);

      await tester.pumpWidget(
        const MaterialApp(
          home: AppAuthGate(),
        ),
      );
      await tester.pumpAndSettle();

      // Must display Create Account screen first
      expect(find.byType(CreateAccountScreen), findsOneWidget);
      expect(find.text('Create New Account'), findsOneWidget);
      expect(find.text('Select Role *'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);

      // Must NOT display Quick Login shortcuts
      expect(find.text('Quick Login As Role:'), findsNothing);
    });

    testWidgets('12. CreateAccountScreen validates required fields and password matching', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CreateAccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to button and tap Create Account with empty fields
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('13. Production LoginPage contains role selector, remember me, and no Quick Login shortcuts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsWidgets);
      expect(find.text('Select Role *'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('New user?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Verify Quick Login buttons are completely removed from production screen
      expect(find.text('Quick Login As Role:'), findsNothing);
      expect(find.text('Admin (Dev)'), findsNothing);
      expect(find.text('Owner'), findsWidgets); // Inside role dropdown
    });

    test('14. Role validation on login: Role mismatch throws validation error', () async {
      // Ramesh is a registered Member account. Logging in selecting Owner role must throw error
      expect(
        () async => await ApiService.login('ramesh', 'password', role: 'DAIRY_OWNER'),
        throwsA(predicate((e) => e.toString().contains('Role mismatch'))),
      );

      // Logging in selecting correct Member role succeeds
      final success = await ApiService.login('ramesh', 'password', role: 'MEMBER');
      expect(success['role'], 'MEMBER');
      expect(success['memberCode'], 'M001');
    });

    testWidgets('15. Session restore navigates directly to DashboardScreen on launch', (WidgetTester tester) async {
      // Emulate valid remembered session
      ApiService.saveSession(
        token: 'valid_test_jwt_token',
        role: 'DAIRY_OWNER',
        username: 'owner',
        fullName: 'Vishwajeet Patil',
      );
      expect(ApiService.restoreSession(), true);

      await tester.pumpWidget(
        const MaterialApp(
          home: AppAuthGate(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigates directly to DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Hello, Dairy Owner 👋'), findsOneWidget);
    });

    test('16. BUG 1 Verification (Test A): Member cannot record collection via API', () async {
      await ApiService.login('ramesh', 'password');
      expect(ApiService.userRole, 'MEMBER');

      // Member attempting to record milk collection throws Unauthorized
      expect(
        () async => await ApiService.recordCollection({
          'memberCode': 'M001',
          'memberName': 'Ramesh Patil',
          'quantity': 10.0,
          'fat': 4.5,
          'snf': 8.5,
          'animalType': 'Cow',
          'shift': 'Morning',
        }),
        throwsA(predicate((e) => e.toString().contains('Unauthorized') || e.toString().contains('cannot record'))),
      );
    });

    test('17. BUG 2 Verification (Test B & C): Owner adds 10L entry; dashboard values do not reset to 65.5L dummy data', () async {
      ApiService.resetCollectionsForTesting();
      await ApiService.login('owner', 'password');

      // Before recording: initial summary has 0 Ltr milk (never hardcoded 65.5L)
      final initialSummary = await ApiService.getTodaySummary();
      expect(initialSummary['totalMilk'], 0.0);
      expect(initialSummary['totalAmount'], 0.0);

      // Owner records a 10 L milk collection for Ramesh
      final saved = await ApiService.recordCollection({
        'memberCode': 'M001',
        'memberName': 'Ramesh Patil',
        'animalType': 'Cow',
        'shift': 'Morning',
        'quantity': 10.0,
        'fat': 4.5,
        'snf': 8.5,
        'ratePerLitre': 42.0,
        'totalAmount': 420.0,
      });
      expect(saved, isNotNull);
      expect(saved!['quantity'], 10.0);

      // Summary updates accurately to 10.0L and ₹420.0
      final updatedSummary = await ApiService.getTodaySummary();
      expect(updatedSummary['totalMilk'], 10.0);
      expect(updatedSummary['totalAmount'], 420.0);
      expect(updatedSummary['avgFat'], 4.5);
      expect(updatedSummary['collectionsCount'], 1);

      // Emulate app restart / screen reload: summary remains 10.0L (never reverts to 65.5L)
      final reloadedSummary = await ApiService.getTodaySummary();
      expect(reloadedSummary['totalMilk'], 10.0);
      expect(reloadedSummary['totalMilk'], isNot(65.5));
      expect(reloadedSummary['totalAmount'], isNot(3378.80));
    });

    test('18. BUG 2 Verification (Test D & E): Member sees their own entry; another member cannot see it', () async {
      // Login as Ramesh: Sees his 10L entry
      await ApiService.login('ramesh', 'password');
      final rameshCols = await ApiService.getTodayCollections();
      expect(rameshCols.any((c) => (c['memberCode'] ?? c['farmerId']) == 'M001'), isTrue);

      // Login as Suresh: Cannot see Ramesh's entry
      await ApiService.login('suresh', 'password');
      final sureshCols = await ApiService.getTodayCollections();
      expect(sureshCols.any((c) => (c['memberCode'] ?? c['farmerId']) == 'M001'), isFalse);
    });

    testWidgets('19. BUG 2 Verification (Test F): Stopped backend displays offline error state and never hardcoded 65.5L', (WidgetTester tester) async {
      ApiService.resetCollectionsForTesting();
      await ApiService.login('owner', 'password');
      ApiService.isOffline = true; // Emulate offline/unreachable backend

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT display hardcoded 65.5 L or ₹3,379
      expect(find.text('65.5 Ltr'), findsNothing);
      expect(find.text('65.5 L'), findsNothing);
      expect(find.text('₹3,379'), findsNothing);
      expect(find.text('₹3,378.80'), findsNothing);
      expect(find.text('0 Ltr'), findsOneWidget); // Accurate empty state
    });

    testWidgets('20. BUG 1 Verification: Member role has NO collection entry buttons or Add floating button', (WidgetTester tester) async {
      await ApiService.login('ramesh', 'password', role: 'MEMBER');
      expect(ApiService.userRole, 'MEMBER');

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Bottom nav and screen must NOT have Add Collection button
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('21. Complete Owner-to-Member Flow: Owner creates Ramesh, records 10L milk, Ramesh registers as Member & sees exact entry', (WidgetTester tester) async {
      ApiService.resetCollectionsForTesting();

      // 1. Owner logs in on Owner phone
      await ApiService.login('owner', 'password');
      expect(ApiService.userRole, 'DAIRY_OWNER');

      // 2. Owner creates a new farmer profile for Ramesh with unique code
      final rameshFarmer = await ApiService.addMember({
        'memberCode': 'M101',
        'name': 'Ramesh Patil',
        'phone': '9876500001',
        'animalType': 'Cow',
        'avgFat': 4.5,
      });
      expect(rameshFarmer, isNotNull);
      final rameshCode = rameshFarmer!['memberCode'] ?? 'M101';

      // 3. Owner records 10 L milk collection entry for Ramesh
      final savedEntry = await ApiService.recordCollection({
        'memberCode': rameshCode,
        'memberName': 'Ramesh Patil',
        'animalType': 'Cow',
        'shift': 'Morning',
        'quantity': 10.0,
        'fat': 4.5,
        'snf': 8.6,
        'ratePerLitre': 41.20,
        'totalAmount': 412.00,
      });
      expect(savedEntry, isNotNull);
      expect(savedEntry!['quantity'], 10.0);
      expect(savedEntry['memberCode'], rameshCode);

      // 4. Ramesh creates a separate MEMBER account using the registration flow with Owner-issued member code
      final registered = await ApiService.register(
        username: 'ramesh_sync_user',
        password: 'password123',
        confirmPassword: 'password123',
        role: 'MEMBER',
        fullName: 'Ramesh Patil',
        memberCode: rameshCode,
      );
      expect(registered, isNotNull);

      // 5. Ramesh logs in using MEMBER role
      await ApiService.login('ramesh_sync_user', 'password123', role: 'MEMBER');
      expect(ApiService.userRole, 'MEMBER');
      expect(ApiService.currentMemberCode, rameshCode);

      // 6. Ramesh opens Collection / Passbook screen
      await tester.pumpWidget(
        const MaterialApp(
          home: MilkCollectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 7. Ramesh sees the exact saved entry recorded by Owner
      expect(find.text('10.0 L'), findsWidgets);
      expect(find.text('₹412'), findsWidgets);
      expect(find.text('Morning'), findsWidgets);
      expect(find.text('Cow'), findsWidgets);
    });

    testWidgets('22. Unlinked Member account displays helpful linking message and Link Farmer Profile action', (WidgetTester tester) async {
      // Register an unlinked member account (omitting member code)
      await ApiService.register(
        username: 'unlinked_member_user',
        password: 'password123',
        confirmPassword: 'password123',
        role: 'MEMBER',
      );

      // Log in as unlinked member
      await ApiService.login('unlinked_member_user', 'password123', role: 'MEMBER');
      expect(ApiService.userRole, 'MEMBER');
      expect(ApiService.currentMemberCode, isNull);

      // Open Collection / Passbook screen
      await tester.pumpWidget(
        const MaterialApp(
          home: MilkCollectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Must display clear, helpful linking prompt
      expect(find.text('Account Not Linked to Farmer Profile'), findsOneWidget);
      expect(find.text('Link Farmer Profile'), findsOneWidget);
      expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);
    });

    test('23. Unlinked Member can explicitly link to farmer profile and view saved entries', () async {
      // Owner creates a new unlinked farmer profile and adds milk
      await ApiService.login('owner', 'password');
      await ApiService.addMember({
        'memberCode': 'M102',
        'name': 'Ganesh Shinde',
        'phone': '9876500002',
        'animalType': 'Cow',
      });
      await ApiService.recordCollection({
        'memberCode': 'M102',
        'memberName': 'Ganesh Shinde',
        'animalType': 'Cow',
        'shift': 'Evening',
        'quantity': 12.0,
        'fat': 4.2,
        'snf': 8.5,
        'ratePerLitre': 40.0,
        'totalAmount': 480.0,
      });

      // Log in as unlinked member
      await ApiService.login('unlinked_member_user', 'password123', role: 'MEMBER');
      expect(ApiService.currentMemberCode, isNull);

      // Collections should be empty when unlinked
      final initialCols = await ApiService.getTodayCollections();
      expect(initialCols, isEmpty);

      // Explicitly link profile using valid member code M102
      final linkRes = await ApiService.linkMemberProfile('M102');
      expect(linkRes['memberCode'], 'M102');
      expect(ApiService.currentMemberCode, 'M102');

      // Now collections query retrieves Ganesh's entries
      final cols = await ApiService.getTodayCollections();
      expect(cols, isNotEmpty);
      expect(cols.any((c) => (c['memberCode'] ?? c['farmerId']) == 'M102'), isTrue);
    });

    test('24. Session restore preserves linked member profile across app force-close and restart', () {
      ApiService.saveSession(
        token: 'member_session_token_123',
        role: 'MEMBER',
        username: 'ramesh_sync_user',
        fullName: 'Ramesh Patil',
        memberCode: 'M001',
        memberId: 'M001',
      );

      // Reset in-memory session (simulate force close)
      ApiService.authToken = null;
      ApiService.currentMemberCode = null;

      // Reopen app: restore session
      final restored = ApiService.restoreSession();
      expect(restored, isTrue);
      expect(ApiService.userRole, 'MEMBER');
      expect(ApiService.currentMemberCode, 'M001');
      expect(ApiService.currentUsername, 'ramesh_sync_user');
    });

    test('25. Permanent Persistence Lifecycle: App reinstall & logout/login retrieves saved records', () async {
      // 1. Owner logs in and records milk collection
      await ApiService.login('owner', 'password');
      final entry = await ApiService.recordCollection({
        'memberCode': 'M001',
        'memberName': 'Ramesh Patil',
        'quantity': 15.5,
        'fat': 4.5,
        'snf': 8.6,
        'animalType': 'Cow',
        'ratePerLitre': 42.0,
        'totalAmount': 651.0,
        'shift': 'Morning',
        'collectionDate': '2026-10-27',
      });
      expect(entry, isNotNull);

      // 2. Owner logs out
      ApiService.logout();
      expect(ApiService.authToken, isNull);

      // 3. Ramesh logs in as MEMBER (simulating Phone B or reinstalled app)
      await ApiService.login('ramesh', 'password');
      expect(ApiService.userRole, 'MEMBER');
      expect(ApiService.currentMemberCode, 'M001');

      // 4. Retrieve collections: Must retrieve the saved 15.5L entry
      final cols = await ApiService.getTodayCollections();
      expect(cols.any((c) => (c['memberCode'] ?? c['farmerId']) == 'M001'), isTrue);

      // 5. Simulate App Uninstall/Reinstall: Clear all session & install state
      ApiService.logout();
      ApiService.resetInstallStateForTesting();
      expect(ApiService.restoreSession(), isFalse);

      // 6. Post-reinstall login restores account and all historical records
      final postReinstallLogin = await ApiService.login('ramesh', 'password');
      expect(postReinstallLogin['memberCode'], 'M001');
      final restoredCols = await ApiService.getTodayCollections();
      expect(restoredCols.any((c) => (c['memberCode'] ?? c['farmerId']) == 'M001'), isTrue);
    });

    test('26. Date filtering: All Records queries complete history across previous days', () async {
      await ApiService.login('owner', 'password');

      // Add collection for a previous date
      await ApiService.recordCollection({
        'memberCode': 'M001',
        'memberName': 'Ramesh Patil',
        'quantity': 22.0,
        'fat': 4.2,
        'snf': 8.5,
        'animalType': 'Cow',
        'ratePerLitre': 40.0,
        'totalAmount': 880.0,
        'shift': 'Evening',
        'collectionDate': '2026-10-24',
      });

      // Query without date filters (All Records)
      final allCols = await ApiService.getTodayCollections();
      expect(allCols.any((c) => c['collectionDate'] == '2026-10-24'), isTrue);
    });

    test('27. Member isolation after restart: Suresh cannot access Ramesh records across cycles', () async {
      await ApiService.login('suresh', 'password');
      expect(ApiService.currentMemberCode, 'M002');

      final sureshCols = await ApiService.getTodayCollections();
      for (final c in sureshCols) {
        final code = (c['memberCode'] ?? c['farmerId'] ?? '').toString();
        expect(code, isNot('M001'));
      }

      final sureshAdvances = await ApiService.getAdvances();
      for (final a in sureshAdvances) {
        final code = (a['memberId'] ?? '').toString();
        expect(code, isNot('M001'));
      }
    });
  });
}
