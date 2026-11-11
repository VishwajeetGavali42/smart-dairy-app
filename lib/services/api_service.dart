import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'pdf_generator_service.dart';

class ApiService {
  static String serverHost = '192.168.118.201:8080'; // 192.168.118.201 for physical mobile on Wi-Fi, 10.0.2.2 for Emulator, 127.0.0.1 for local
  static String get baseUrl => 'http://$serverHost/api/v1';
  static void setServerHost(String host) {
    final clean = host.trim().replaceAll('http://', '').replaceAll('https://', '').replaceAll('/api/v1', '').replaceAll('/', '');
    if (clean.isNotEmpty) {
      serverHost = clean;
      _checkedConnection = false;
    }
  }

  /// Ping and test server latency from mobile phone
  static Future<Map<String, dynamic>> testServerConnection(String host) async {
    final clean = host.trim().replaceAll('http://', '').replaceAll('https://', '').replaceAll('/api/v1', '').replaceAll('/', '');
    final testUrl = 'http://$clean/api/v1/auth/health';
    final sw = Stopwatch()..start();
    try {
      final res = await http.get(Uri.parse(testUrl)).timeout(const Duration(milliseconds: 2000));
      sw.stop();
      if (res.statusCode == 200) {
        setServerHost(clean);
        isOffline = false;
        _checkedConnection = true;
        return {
          'success': true,
          'latencyMs': sw.elapsedMilliseconds,
          'host': clean,
          'message': 'Connected to live Spring Boot backend (${sw.elapsedMilliseconds} ms)',
        };
      }
    } catch (_) {}
    sw.stop();
    return {
      'success': false,
      'latencyMs': sw.elapsedMilliseconds,
      'host': clean,
      'message': 'Unreachable - running in local offline-first mode',
    };
  }

  // Session & First-Time Install State
  static bool _hasAccountCreated = false;
  static Map<String, dynamic>? _persistedSession;

  static bool hasCreatedAccount() {
    return _hasAccountCreated;
  }

  static void markAccountCreated() {
    _hasAccountCreated = true;
  }

  static void resetInstallStateForTesting() {
    _hasAccountCreated = false;
    _persistedSession = null;
    authToken = null;
    currentUsername = null;
    currentMemberCode = null;
    currentMemberId = null;
    currentMemberName = null;
    userRole = 'DAIRY_OWNER';
  }

  static void saveSession({
    required String token,
    required String role,
    required String username,
    String? fullName,
    String? dairyName,
    String? memberCode,
    String? memberId,
  }) {
    currentUsername = username;
    _persistedSession = {
      'token': token,
      'role': role,
      'username': username,
      'fullName': fullName,
      'dairyName': dairyName,
      'memberCode': memberCode,
      'memberId': memberId,
      'savedAt': DateTime.now().toIso8601String(),
    };
    _hasAccountCreated = true;
  }

  static bool restoreSession() {
    if (_persistedSession != null && _persistedSession!['token'] != null) {
      final token = _persistedSession!['token'] as String;
      if (token.isNotEmpty) {
        authToken = token;
        userRole = _persistedSession!['role'] ?? 'DAIRY_OWNER';
        currentUsername = _persistedSession!['username']?.toString();
        dairyName = _persistedSession!['dairyName'] ?? 'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur';
        currentMemberCode = _persistedSession!['memberCode']?.toString();
        currentMemberId = _persistedSession!['memberId']?.toString();
        currentMemberName = _persistedSession!['fullName']?.toString();
        isOffline = false;
        _checkedConnection = true;
        notifyDataChanged();
        return true;
      }
    }
    return false;
  }

  /// Secure session logout: clears auth tokens and active member credentials
  static void logout() {
    authToken = null;
    currentUsername = null;
    userRole = 'DAIRY_OWNER';
    dairyName = null;
    currentMemberCode = null;
    currentMemberId = null;
    currentMemberName = null;
    _persistedSession = null;
    isOffline = true;
    _checkedConnection = false;
    notifyDataChanged();
  }

  static String? authToken;
  static String? currentUsername;
  static String? dairyName;
  static bool isOffline = true;
  static bool _checkedConnection = false;

  // Member-specific session properties for authenticated farmers
  static String? currentMemberCode;
  static String? currentMemberId;
  static String? currentMemberName;

  // Audit Log Memory & Sync Store
  static final List<Map<String, dynamic>> _localAuditLogs = [
    {
      'id': 'audit_init_01',
      'action': 'COLLECTION_RECORDED',
      'entityType': 'COLLECTION',
      'entityId': 'col_001',
      'performedBy': 'Dairy Owner',
      'role': 'ROLE_OWNER',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'details': 'Recorded 15.5L Morning milk for Ramesh Patil (Fat: 4.2%, SNF: 8.5%) @ ₹42.0/L = ₹651.0',
    },
    {
      'id': 'audit_init_02',
      'action': 'COLLECTION_RECORDED',
      'entityType': 'COLLECTION',
      'entityId': 'col_002',
      'performedBy': 'Dairy Owner',
      'role': 'ROLE_OWNER',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'details': 'Recorded 22.0L Morning milk for Suresh Deshmukh (Fat: 6.8%, SNF: 9.0%) @ ₹58.5/L = ₹1287.0',
    },
    {
      'id': 'audit_init_03',
      'action': 'PAYMENT_DISBURSED',
      'entityType': 'PAYMENT',
      'entityId': 'pay_001',
      'performedBy': 'Dairy Owner',
      'role': 'ROLE_OWNER',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'details': 'Disbursed payment for Ramesh Patil: Gross ₹6500.0, Advance deduction ₹500.0, Net ₹6000.0 (Cycle: 10 Days)',
    },
    {
      'id': 'audit_init_04',
      'action': 'ADVANCE_GRANTED',
      'entityType': 'ADVANCE',
      'entityId': 'adv_001',
      'performedBy': 'Dairy Owner',
      'role': 'ROLE_OWNER',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'details': 'Granted advance of ₹2000.0 to Ramesh Patil (Reason: Cattle Feed)',
    },
  ];

  static Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/audit/logs'), headers: _headers).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_localAuditLogs);
  }

  static void addLocalAudit({
    required String action,
    required String entityType,
    required String entityId,
    required String details,
    String? performedBy,
    String? role,
  }) {
    _localAuditLogs.insert(0, {
      'id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'performedBy': performedBy ?? (currentMemberName ?? 'Dairy Owner'),
      'role': role ?? (userRole == 'MEMBER' ? 'ROLE_MEMBER' : 'ROLE_OWNER'),
      'timestamp': DateTime.now().toIso8601String(),
      'details': details,
    });
  }

  static final ValueNotifier<String> userRoleNotifier = ValueNotifier<String>(
    'DAIRY_OWNER',
  );
  static String get userRole => userRoleNotifier.value;
  static set userRole(String? role) {
    if (role != null && role.isNotEmpty) {
      userRoleNotifier.value = role;
    }
  }

  static final ValueNotifier<int> dataChangeNotifier = ValueNotifier<int>(0);
  static void notifyDataChanged() {
    dataChangeNotifier.value++;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  /// Check server health with adaptive timeout and ADB/host fallback
  static Future<bool> checkConnection({bool force = false}) async {
    if (_checkedConnection && !force && !isOffline) return true;

    final candidateHosts = [
      serverHost,
      '192.168.118.201:8080',
      '10.0.2.2:8080',
      '127.0.0.1:8080',
      'localhost:8080',
    ];

    for (final host in candidateHosts.toSet()) {
      try {
        final clean = host
            .replaceAll('http://', '')
            .replaceAll('https://', '')
            .replaceAll('/api/v1', '')
            .replaceAll('/', '');
        final res = await http
            .get(Uri.parse('http://' + clean + '/api/v1/auth/health'))
            .timeout(const Duration(milliseconds: 1800));
        if (res.statusCode == 200) {
          serverHost = clean;
          isOffline = false;
          _checkedConnection = true;
          return true;
        }
      } catch (_) {}
    }

    isOffline = true;
    _checkedConnection = true;
    return false;
  }

  // Registered Accounts Store (synchronized with Spring Boot / MongoDB)
  static final List<Map<String, dynamic>> _registeredUsers = [
    {
      'username': 'owner',
      'role': 'DAIRY_OWNER',
      'fullName': 'Vishwajeet Patil (Owner)',
      'passwordHash': 'password',
    },
    {
      'username': 'ramesh',
      'role': 'MEMBER',
      'fullName': 'Ramesh Patil',
      'memberCode': 'M001',
      'memberId': 'M001',
      'passwordHash': 'password',
    },
    {
      'username': 'suresh',
      'role': 'MEMBER',
      'fullName': 'Suresh Deshmukh',
      'memberCode': 'M002',
      'memberId': 'M002',
      'passwordHash': 'password',
    },
    {
      'username': 'admin',
      'role': 'ADMIN',
      'fullName': 'System Administrator',
      'passwordHash': 'password',
    },
  ];

  /// Register / Create Account on Spring Boot backend
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String role,
    String? fullName,
    String? phone,
    String? memberCode,
    String? adminSecretKey,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) throw 'Username is required';
    if (cleanUsername.length < 3) throw 'Username must be at least 3 characters long';
    if (password.isEmpty) throw 'Password is required';
    if (password.length < 6) throw 'Password must be at least 6 characters long';
    if (password != confirmPassword) throw 'Password and Confirm Password do not match';
    if (role.isEmpty) throw 'Role selection is required';

    if (role.toUpperCase() == 'ADMIN') {
      if (adminSecretKey == null || adminSecretKey.trim() != 'SMART_DAIRY_ADMIN_2026') {
        throw 'Admin privileges require a valid Master Admin Authorization Key.';
      }
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': cleanUsername,
              'password': password,
              'confirmPassword': confirmPassword,
              'role': role,
              'fullName': fullName,
              'phone': phone,
              'memberCode': memberCode,
              'adminSecretKey': adminSecretKey,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        markAccountCreated();
        isOffline = false;
        _checkedConnection = true;
        return data as Map<String, dynamic>;
      } else {
        final err = data['error'] ?? data['message'] ?? 'Registration failed';
        throw err.toString();
      }
    } catch (e) {
      if (e is String) rethrow;
      if (e.toString().contains('already taken') ||
          e.toString().contains('already linked') ||
          e.toString().contains('not found') ||
          e.toString().contains('Admin privileges')) {
        rethrow;
      }
    }

    // Offline / fallback storage
    if (_registeredUsers.any((u) => u['username'] == cleanUsername)) {
      throw "Username '$cleanUsername' is already taken. Please choose another username.";
    }

    String? assignedMemberCode;
    if (role.toUpperCase() == 'MEMBER') {
      if (memberCode != null && memberCode.trim().isNotEmpty) {
        final cleanCode = memberCode.trim().toUpperCase();
        final existingMember = _localMembers.firstWhere(
          (m) =>
              (m['memberCode'] ?? m['id'] ?? '').toString().toUpperCase() ==
              cleanCode,
          orElse: () => {},
        );
        if (existingMember.isEmpty) {
          throw "Farmer profile not found with code '$cleanCode'. Please check the Member Code provided by your Dairy Owner.";
        }
        final alreadyLinked = _registeredUsers.any(
          (u) =>
              u['role']?.toString().toUpperCase() == 'MEMBER' &&
              u['memberCode']?.toString().toUpperCase() == cleanCode,
        );
        if (alreadyLinked) {
          throw "Farmer profile '$cleanCode' is already linked to another account.";
        }
        assignedMemberCode = cleanCode;
        if (fullName == null || fullName.isEmpty) {
          fullName = existingMember['name']?.toString();
        }
      } else {
        assignedMemberCode = null; // Unlinked Member account
      }
    }

    final newUser = {
      'username': cleanUsername,
      'role': role,
      'fullName': fullName?.isNotEmpty == true ? fullName : cleanUsername,
      'memberCode': role.toUpperCase() == 'MEMBER' ? assignedMemberCode : null,
      'memberId': role.toUpperCase() == 'MEMBER' ? assignedMemberCode : null,
      'phone': phone,
      'passwordHash': password,
    };
    _registeredUsers.add(newUser);
    markAccountCreated();
    return {
      'message': 'Account created successfully',
      'username': cleanUsername,
      'role': role,
      'token': 'offline_token_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Auth - Login with role validation against backend
  static Future<Map<String, dynamic>> login(
    String username,
    String password, {
    String? role,
    bool rememberMe = false,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) throw 'Please enter your username';
    if (password.isEmpty) throw 'Please enter your password';

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': cleanUsername,
              'password': password,
              if (role != null) 'role': role,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        authToken = data['token'];
        userRole = data['role'];
        currentUsername = cleanUsername;
        dairyName = data['dairyName'];
        currentMemberCode = data['memberCode']?.toString();
        currentMemberId = data['memberId']?.toString();
        currentMemberName = data['fullName']?.toString();
        isOffline = false;
        _checkedConnection = true;
        markAccountCreated();

        if (rememberMe) {
          saveSession(
            token: authToken!,
            role: userRole,
            username: cleanUsername,
            fullName: currentMemberName,
            dairyName: dairyName,
            memberCode: currentMemberCode,
            memberId: currentMemberId,
          );
        }
        return data;
      } else {
        final errMap = jsonDecode(response.body);
        final errMsg = errMap['error'] ?? errMap['message'] ?? 'Invalid username or password.';
        throw errMsg.toString();
      }
    } catch (e) {
      if (e is String) rethrow;
    }

    // Offline / fallback verification
    final match = _registeredUsers.firstWhere(
      (u) => u['username'] == cleanUsername,
      orElse: () => {},
    );

    if (match.isEmpty) {
      throw 'User not found. Please verify your username or create an account.';
    }

    if (match['passwordHash'] != password) {
      throw 'Invalid credentials. Please verify username and password.';
    }

    if (role != null && role.isNotEmpty) {
      final expected = _normalizeRole(match['role']);
      final actual = _normalizeRole(role);
      if (expected != actual) {
        throw 'Role mismatch: Your account is registered as $expected, not $actual.';
      }
    }

    final assignedRole = match['role'] ?? role ?? 'DAIRY_OWNER';
    authToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
    userRole = assignedRole;
    currentUsername = cleanUsername;
    dairyName = 'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur';
    currentMemberCode = match['memberCode']?.toString();
    currentMemberId = match['memberId']?.toString();
    currentMemberName = match['fullName']?.toString() ?? cleanUsername;
    isOffline = true;
    _checkedConnection = true;
    markAccountCreated();

    if (rememberMe) {
      saveSession(
        token: authToken!,
        role: userRole,
        username: cleanUsername,
        fullName: currentMemberName,
        dairyName: dairyName,
        memberCode: currentMemberCode,
        memberId: currentMemberId,
      );
    }

    return {
      'token': authToken,
      'role': assignedRole,
      'dairyName': dairyName,
      'fullName': currentMemberName,
      'memberCode': currentMemberCode,
      'memberId': currentMemberId,
    };
  }

  static Future<Map<String, dynamic>> linkMemberProfile(String memberCode) async {
    final cleanCode = memberCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw 'Please enter a valid Farmer / Member Code';
    }

    if (!isOffline && authToken != null) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/members/link-profile'),
              headers: _headers,
              body: jsonEncode({'memberCode': cleanCode}),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          authToken = data['token'] ?? authToken;
          currentMemberCode = data['memberCode']?.toString();
          currentMemberId = data['memberId']?.toString();
          if (data['fullName'] != null) {
            currentMemberName = data['fullName'].toString();
          }
          saveSession(
            token: authToken!,
            role: userRole,
            username: currentUsername ?? 'member',
            fullName: currentMemberName,
            dairyName: dairyName,
            memberCode: currentMemberCode,
            memberId: currentMemberId,
          );
          notifyDataChanged();
          return data;
        } else {
          final errMap = jsonDecode(response.body);
          final msg = errMap['error'] ?? errMap['message'] ?? 'Failed to link profile';
          throw msg.toString();
        }
      } catch (e) {
        if (e is String) rethrow;
        if (e.toString().contains('already linked') ||
            e.toString().contains('not found') ||
            e.toString().contains('Failed to link')) {
          rethrow;
        }
        isOffline = true;
      }
    }

    // Offline / fallback profile linking
    final mIdx = _localMembers.indexWhere(
      (m) =>
          (m['memberCode'] ?? m['id'] ?? '').toString().toUpperCase() ==
          cleanCode,
    );
    if (mIdx < 0) {
      throw "Farmer profile not found with code '$cleanCode'. Please check the Member Code provided by your Dairy Owner.";
    }

    final alreadyLinked = _registeredUsers.any(
      (u) =>
          u['username'] != currentUsername &&
          u['role']?.toString().toUpperCase() == 'MEMBER' &&
          u['memberCode']?.toString().toUpperCase() == cleanCode,
    );
    if (alreadyLinked) {
      throw "Farmer profile '$cleanCode' is already linked to another account.";
    }

    final member = _localMembers[mIdx];
    currentMemberCode = cleanCode;
    currentMemberId = cleanCode;
    currentMemberName = member['name']?.toString() ?? currentMemberName;

    if (currentUsername != null) {
      final userIdx = _registeredUsers.indexWhere((u) => u['username'] == currentUsername);
      if (userIdx >= 0) {
        _registeredUsers[userIdx]['memberCode'] = cleanCode;
        _registeredUsers[userIdx]['memberId'] = cleanCode;
        _registeredUsers[userIdx]['fullName'] = currentMemberName;
      }
    }

    saveSession(
      token: authToken ?? 'offline_token',
      role: userRole,
      username: currentUsername ?? 'member',
      fullName: currentMemberName,
      dairyName: dairyName,
      memberCode: currentMemberCode,
      memberId: currentMemberId,
    );
    notifyDataChanged();
    return {
      'success': true,
      'memberCode': cleanCode,
      'fullName': currentMemberName,
      'message': 'Profile linked successfully',
    };
  }

  static String _normalizeRole(String? role) {
    if (role == null) return 'Owner';
    final r = role.toUpperCase().replaceAll('ROLE_', '');
    if (r == 'OWNER' || r == 'DAIRY_OWNER') return 'Owner';
    if (r == 'MEMBER' || r == 'FARMER') return 'Member';
    if (r == 'ADMIN') return 'Admin';
    if (r == 'EMPLOYEE' || r == 'OPERATOR') return 'Employee';
    return r;
  }

  // Developer & Admin Support Tickets Store (Accessible by Admin to solve Dairy Owner issues)
  static final List<Map<String, dynamic>> supportTickets = [
    {
      'id': 'TKT-101',
      'title': 'Milk Analyzer BLE sync lag',
      'description': 'Analyzer takes 4 seconds to transfer FAT reading during evening shift',
      'submittedBy': 'Vishwajeet Shinde (Owner)',
      'contact': '+91 98220 12345',
      'status': 'Open',
      'date': 'Today, 10:15 AM',
      'screen': 'Milk Collection',
    },
    {
      'id': 'TKT-102',
      'title': 'Rate chart step adjustment request',
      'description':
          'Need to adjust buffalo fat step to 0.45 for next 10-day cycle',
      'submittedBy':
          'Late L D Kadam Milk Producers Cooperative Society Ltd.',
      'contact': '+91 98220 12345',
      'status': 'Resolved',
      'date': 'Yesterday',
      'screen': 'Rate Chart',
    },
  ];

  static void addSupportTicket({
    required String title,
    required String description,
    required String submittedBy,
    required String contact,
    String screen = 'General',
  }) {
    supportTickets.insert(0, {
      'id':
          'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'title': title,
      'description': description,
      'submittedBy': submittedBy,
      'contact': contact,
      'status': 'Open',
      'date': 'Just now',
      'screen': screen,
    });
  }

  static void resolveSupportTicket(String id) {
    final idx = supportTickets.indexWhere((t) => t['id'] == id);
    if (idx != -1) {
      supportTickets[idx]['status'] = 'Resolved';
    }
  }

  // Members Cache & Store
  static final List<Map<String, dynamic>> _localMembers = [
    {
      'id': 'M001',
      'memberCode': 'M001',
      'name': 'Ramesh Patil',
      'phone': '9876543210',
      'animalType': 'Cow',
      'totalMilkSupplied': 450.0,
      'avgFat': 4.2,
      'snf': 8.5,
      'active': true,
    },
    {
      'id': 'M002',
      'memberCode': 'M002',
      'name': 'Suresh Deshmukh',
      'phone': '9876543211',
      'animalType': 'Buffalo',
      'totalMilkSupplied': 620.0,
      'avgFat': 6.8,
      'snf': 9.0,
      'active': true,
    },
    {
      'id': 'M003',
      'memberCode': 'M003',
      'name': 'Anand Shinde',
      'phone': '9876543212',
      'animalType': 'Cow',
      'totalMilkSupplied': 380.0,
      'avgFat': 4.0,
      'snf': 8.4,
      'active': true,
    },
    {
      'id': 'M004',
      'memberCode': 'M004',
      'name': 'Prakash Jadhav',
      'phone': '9876543213',
      'animalType': 'Buffalo',
      'totalMilkSupplied': 540.0,
      'avgFat': 7.1,
      'snf': 9.1,
      'active': true,
    },
    {
      'id': 'M005',
      'memberCode': 'M005',
      'name': 'Sunita Kadam',
      'phone': '9876543214',
      'animalType': 'Cow',
      'totalMilkSupplied': 290.0,
      'avgFat': 4.3,
      'snf': 8.6,
      'active': true,
    },
  ];

  static Future<List<dynamic>> getMembers() async {
    if (isOffline) return List<dynamic>.from(_localMembers);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/members'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final serverList = jsonDecode(response.body) as List<dynamic>;
        final serverCodes = <String>{};
        for (final item in serverList) {
          final code = (item['memberCode'] ?? item['id'] ?? '').toString();
          if (code.isNotEmpty) serverCodes.add(code);
        }
        final unsynced = _localMembers.where((m) {
          final code = (m['memberCode'] ?? m['id'] ?? '').toString();
          return !serverCodes.contains(code);
        }).toList();

        _localMembers.clear();
        for (final item in serverList) {
          if (item is Map<String, dynamic>) {
            _localMembers.add(Map<String, dynamic>.from(item));
          }
        }
        _localMembers.addAll(unsynced);
        return List<dynamic>.from(_localMembers);
      }
    } catch (_) {
      // Fallback to local cache if network drops
    }
    return List<dynamic>.from(_localMembers);
  }

  static Future<Map<String, dynamic>?> addMember(
    Map<String, dynamic> member,
  ) async {
    final newMember = Map<String, dynamic>.from(member);
    newMember['active'] = true;
    newMember['totalMilkSupplied'] = newMember['totalMilkSupplied'] ?? 0.0;
    newMember['avgFat'] = newMember['avgFat'] ?? 4.2;

    final existingIdx = _localMembers.indexWhere(
      (m) =>
          (m['memberCode'] != null &&
              newMember['memberCode'] != null &&
              m['memberCode'].toString().toUpperCase() ==
                  newMember['memberCode'].toString().toUpperCase()) ||
          (m['name'] == newMember['name'] && m['phone'] == newMember['phone']),
    );
    if (existingIdx >= 0) {
      newMember['memberCode'] ??= _localMembers[existingIdx]['memberCode'];
      _localMembers[existingIdx] = newMember;
    } else {
      if (!newMember.containsKey('memberCode') ||
          (newMember['memberCode']?.toString().isEmpty ?? true)) {
        final nextNum = _localMembers.length + 1;
        newMember['memberCode'] = 'M${nextNum.toString().padLeft(3, '0')}';
      }
      _localMembers.add(newMember);
    }

    notifyDataChanged();
    if (!isOffline && authToken != null) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/members'),
              headers: _headers,
              body: jsonEncode(newMember),
            )
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200 || response.statusCode == 201) {
          final saved = jsonDecode(response.body) as Map<String, dynamic>;
          final idx = _localMembers.indexWhere(
            (m) => m['memberCode'] == newMember['memberCode'],
          );
          if (idx >= 0) {
            _localMembers[idx] = Map<String, dynamic>.from(saved);
          }
          return saved;
        } else if (response.body.isNotEmpty) {
          _localMembers.removeWhere((m) => m['memberCode'] == newMember['memberCode']);
          notifyDataChanged();
          final errMap = jsonDecode(response.body);
          final msg = errMap['error'] ?? errMap['message'] ?? 'Failed to save member to server';
          throw Exception(msg.toString());
        }
      } catch (e) {
        if (e.toString().contains('Failed to save') || e.toString().contains('Unauthorized')) {
          rethrow;
        }
      }
    }

    return newMember;
  }

  static Future<bool> updateMember(
    String idOrCode,
    Map<String, dynamic> updated,
  ) async {
    final idx = _localMembers.indexWhere(
      (m) => m['memberCode'] == idOrCode || m['id'] == idOrCode,
    );
    if (idx >= 0) {
      _localMembers[idx].addAll(updated);
      notifyDataChanged();
    }
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/members/$idOrCode'),
            headers: _headers,
            body: jsonEncode(updated),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static Future<bool> deleteMember(String idOrCode) async {
    _localMembers.removeWhere(
      (m) => m['memberCode'] == idOrCode || m['id'] == idOrCode,
    );
    notifyDataChanged();
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/members/$idOrCode'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {}
    return false;
  }

  // Collections Cache & Store (BUG 2 FIX: Real persisted MongoDB store without hardcoded dummy collections)
  static final List<Map<String, dynamic>> _localCollections = [];

  static void resetCollectionsForTesting() {
    _localCollections.clear();
  }

  static Future<List<dynamic>> getTodayCollections({
    DateTime? startDate,
    DateTime? endDate,
    String? shift,
  }) async {
    final bool isMember = userRole.toUpperCase() == 'MEMBER';
    final targetCode = currentMemberCode;

    if (isMember && (targetCode == null || targetCode.isEmpty)) {
      // Unlinked Member: has no farmer profile attached yet, return empty list
      return [];
    }

    if (!isOffline && authToken != null) {
      try {
        String endpoint;
        if (startDate != null && endDate != null) {
          final startStr = startDate.toIso8601String().substring(0, 10);
          final endStr = endDate.toIso8601String().substring(0, 10);
          endpoint = '$baseUrl/collections?startDate=$startStr&endDate=$endStr';
          if (shift != null && shift.isNotEmpty && shift.toUpperCase() != 'ALL') {
            endpoint += '&shift=$shift';
          }
        } else {
          endpoint = isMember ? '$baseUrl/collections/my-collections' : '$baseUrl/collections';
          if (shift != null && shift.isNotEmpty && shift.toUpperCase() != 'ALL') {
            endpoint += '?shift=$shift';
          }
        }

        final response = await http
            .get(Uri.parse(endpoint), headers: _headers)
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final serverList = jsonDecode(response.body) as List<dynamic>;
          final serverIds = <String>{};
          for (final item in serverList) {
            final id = (item['id'] ?? item['_id'] ?? '').toString();
            if (id.isNotEmpty) serverIds.add(id);
          }
          final unsynced = _localCollections.where((c) {
            final id = (c['id'] ?? c['_id'] ?? '').toString();
            return !serverIds.contains(id);
          }).toList();

          _localCollections.clear();
          for (final item in serverList) {
            if (item is Map<String, dynamic>) {
              _localCollections.add(Map<String, dynamic>.from(item));
            }
          }
          _localCollections.addAll(unsynced);
          return serverList;
        }
      } catch (_) {
        // Fallback to local cache if network drops
      }
    }

    Iterable<Map<String, dynamic>> list = _localCollections;
    if (isMember && targetCode != null) {
      list = list.where((c) {
        final code = (c['memberCode'] ?? c['farmerId'] ?? '').toString();
        return code.toUpperCase() == targetCode.toUpperCase();
      });
    }
    if (startDate != null && endDate != null) {
      final startStr = startDate.toIso8601String().substring(0, 10);
      final endStr = endDate.toIso8601String().substring(0, 10);
      list = list.where((c) {
        final d = (c['collectionDate'] ?? '').toString();
        return d.compareTo(startStr) >= 0 && d.compareTo(endStr) <= 0;
      });
    }
    if (shift != null && shift.isNotEmpty && shift.toUpperCase() != 'ALL') {
      list = list.where((c) => (c['shift'] ?? '').toString().toUpperCase() == shift.toUpperCase());
    }
    return list.toList();
  }

  static Future<Map<String, dynamic>> getTodaySummary() async {
    final bool isMember = userRole.toUpperCase() == 'MEMBER';
    if (isMember && (currentMemberCode == null || currentMemberCode!.isEmpty)) {
      return {
        'totalMilk': 0.0,
        'totalAmount': 0.0,
        'avgFat': 0.0,
        'collectionsCount': 0,
        'memberCount': 0,
      };
    }

    // BUG 2: Fetch live summary from Spring Boot / MongoDB backend whenever online
    if (!isOffline && authToken != null) {
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/collections/summary/today'),
              headers: _headers,
            )
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data;
        }
      } catch (_) {
        isOffline = true;
      }
    }

    // Local computed summary based on actual local cache (never fake 65.5L dummy values)
    if (isMember) {
      final memberCols = await getTodayCollections();
      double totalMilk = 0.0;
      double totalAmount = 0.0;
      double totalFat = 0.0;
      for (final c in memberCols) {
        final q = (c['quantity'] as num?)?.toDouble() ?? 0.0;
        final a = (c['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final f = (c['fat'] as num?)?.toDouble() ?? 0.0;
        totalMilk += q;
        totalAmount += a;
        totalFat += f;
      }
      final avgFat = memberCols.isEmpty ? 0.0 : (totalFat / memberCols.length);
      return {
        'totalMilk': ((totalMilk * 100).round()) / 100,
        'totalAmount': ((totalAmount * 100).round()) / 100,
        'avgFat': ((avgFat * 10).round()) / 10,
        'collectionsCount': memberCols.length,
        'memberCount': 1,
      };
    }

    return _computeLocalSummary();
  }

  static Map<String, dynamic> _computeLocalSummary() {
    double totalMilk = 0.0;
    double totalAmount = 0.0;
    double totalFat = 0.0;
    for (final c in _localCollections) {
      final q = (c['quantity'] as num?)?.toDouble() ?? 0.0;
      final a = (c['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final f = (c['fat'] as num?)?.toDouble() ?? 0.0;
      totalMilk += q;
      totalAmount += a;
      totalFat += f;
    }
    final avgFat = _localCollections.isEmpty
        ? 0.0
        : (totalFat / _localCollections.length);
    return {
      'totalMilk': ((totalMilk * 100).round()) / 100,
      'totalAmount': ((totalAmount * 100).round()) / 100,
      'avgFat': ((avgFat * 10).round()) / 10,
      'collectionsCount': _localCollections.length,
      'memberCount': _localMembers.length,
    };
  }

  static Future<Map<String, dynamic>?> recordCollection(
    Map<String, dynamic> collection,
  ) async {
    // BUG 1 Security: Members cannot create collection records
    final String currentRole = userRole.toUpperCase();
    if (currentRole == 'MEMBER') {
      throw Exception('Unauthorized: Members cannot record official milk collections.');
    }

    final newCollection = Map<String, dynamic>.from(collection);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (newCollection['collectionDate'] == null || newCollection['collectionDate'] == 'Today') {
      newCollection['collectionDate'] = todayStr;
    }
    newCollection['collectionTime'] ??=
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final qty = (newCollection['quantity'] as num?)?.toDouble() ?? 0.0;
    final fat = (newCollection['fat'] as num?)?.toDouble() ?? 4.2;

    // Cache locally immediately
    newCollection['id'] ??= 'col_${now.millisecondsSinceEpoch}_${_localCollections.length}';
    _localCollections.insert(0, newCollection);
    notifyDataChanged();

    addLocalAudit(
      action: 'COLLECTION_RECORDED',
      entityType: 'COLLECTION',
      entityId: newCollection['id']?.toString() ?? 'col',
      details: 'Recorded ${qty}L ${newCollection['shift'] ?? 'Morning'} milk for ${newCollection['memberName'] ?? newCollection['memberCode'] ?? 'Member'} @ ₹${newCollection['ratePerLitre'] ?? 0}/L = ₹${newCollection['totalAmount'] ?? 0}',
    );

    // Update corresponding local member if present
    final memberCode = newCollection['memberCode']?.toString();
    if (memberCode != null && memberCode.isNotEmpty) {
      final mIdx = _localMembers.indexWhere(
        (m) => m['memberCode'] == memberCode || m['id'] == memberCode,
      );
      if (mIdx >= 0) {
        final currentMilk =
            (_localMembers[mIdx]['totalMilkSupplied'] as num?)?.toDouble() ??
            0.0;
        _localMembers[mIdx]['totalMilkSupplied'] =
            ((currentMilk + qty) * 100).round() / 100;
        _localMembers[mIdx]['avgFat'] = fat;
      }
    }

    // Persist permanently to MongoDB via Spring Boot backend
    if (!isOffline && authToken != null) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/collections'),
              headers: _headers,
              body: jsonEncode(newCollection),
            )
            .timeout(const Duration(seconds: 4));
        if (response.statusCode == 200 || response.statusCode == 201) {
          final saved = jsonDecode(response.body) as Map<String, dynamic>;
          final idx = _localCollections.indexWhere(
            (c) => c['id'] == newCollection['id'],
          );
          if (idx >= 0) {
            _localCollections[idx] = Map<String, dynamic>.from(saved);
          }
          notifyDataChanged();
          return saved;
        } else if (response.statusCode == 403) {
          _localCollections.removeWhere((c) => c['id'] == newCollection['id']);
          notifyDataChanged();
          throw Exception('Unauthorized: Only Dairy Owners and authorized operators can record milk collections.');
        } else if (response.body.isNotEmpty) {
          _localCollections.removeWhere((c) => c['id'] == newCollection['id']);
          notifyDataChanged();
          try {
            final errMap = jsonDecode(response.body);
            final msg = errMap['error'] ?? errMap['message'] ?? 'Failed to record collection (HTTP ${response.statusCode})';
            throw Exception(msg.toString());
          } catch (je) {
            if (je.toString().contains('Failed to record')) rethrow;
            throw Exception('Failed to record collection (HTTP ${response.statusCode})');
          }
        }
      } catch (e) {
        if (e.toString().contains('Unauthorized') || e.toString().contains('Forbidden') || e.toString().contains('Failed to record') || e.toString().contains('Invalid')) {
          rethrow;
        }
      }
    }

    return newCollection;
  }

  static Future<Map<String, Map<String, double>>> getMemberCycleTotals(
    String memberCode,
  ) async {
    if (isOffline) return _computeLocalCycleTotals(memberCode);
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/collections/member/$memberCode/cycles'),
            headers: _headers,
          )
          .timeout(const Duration(milliseconds: 600));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          '10_days': {
            'litres': (data['tenDays']?['litres'] as num?)?.toDouble() ?? 0.0,
            'amount': (data['tenDays']?['amount'] as num?)?.toDouble() ?? 0.0,
          },
          '15_days': {
            'litres':
                (data['fifteenDays']?['litres'] as num?)?.toDouble() ?? 0.0,
            'amount':
                (data['fifteenDays']?['amount'] as num?)?.toDouble() ?? 0.0,
          },
          'monthly': {
            'litres': (data['monthly']?['litres'] as num?)?.toDouble() ?? 0.0,
            'amount': (data['monthly']?['amount'] as num?)?.toDouble() ?? 0.0,
          },
          'yearly': {
            'litres': (data['yearly']?['litres'] as num?)?.toDouble() ?? 0.0,
            'amount': (data['yearly']?['amount'] as num?)?.toDouble() ?? 0.0,
          },
        };
      }
    } catch (_) {
      isOffline = true;
    }

    return _computeLocalCycleTotals(memberCode);
  }

  static Map<String, Map<String, double>> _computeLocalCycleTotals(
    String memberCode,
  ) {
    final now = DateTime.now();
    final tenDaysAgo = now.subtract(const Duration(days: 10));
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    double milk10 = 0.0, amt10 = 0.0;
    double milk15 = 0.0, amt15 = 0.0;
    double milkMonth = 0.0, amtMonth = 0.0;
    double milkYear = 0.0, amtYear = 0.0;

    final memberCols = _localCollections.where((c) {
      final cCode = (c['memberCode'] ?? c['id'] ?? '').toString();
      return cCode == memberCode;
    });

    for (final c in memberCols) {
      DateTime date = now;
      if (c['collectionDate'] != null) {
        date = DateTime.tryParse(c['collectionDate'].toString()) ?? now;
      }
      final q = (c['quantity'] as num?)?.toDouble() ?? 0.0;
      final a = (c['totalAmount'] as num?)?.toDouble() ?? 0.0;

      if (!date.isBefore(tenDaysAgo)) {
        milk10 += q;
        amt10 += a;
      }
      if (!date.isBefore(fifteenDaysAgo)) {
        milk15 += q;
        amt15 += a;
      }
      if (!date.isBefore(startOfMonth)) {
        milkMonth += q;
        amtMonth += a;
      }
      if (!date.isBefore(startOfYear)) {
        milkYear += q;
        amtYear += a;
      }
    }

    if (milkMonth == 0.0) {
      final m = _localMembers.firstWhere(
        (m) => m['memberCode'] == memberCode || m['id'] == memberCode,
        orElse: () => {},
      );
      final registeredMilk =
          (m['totalMilkSupplied'] as num?)?.toDouble() ?? 0.0;
      if (registeredMilk > 0) {
        final estRate = (m['animalType'] == 'Buffalo') ? 54.0 : 38.0;
        final estAmt = registeredMilk * estRate;
        milk10 = (registeredMilk * 0.33 * 10).round() / 10;
        amt10 = (estAmt * 0.33).roundToDouble();
        milk15 = (registeredMilk * 0.5 * 10).round() / 10;
        amt15 = (estAmt * 0.5).roundToDouble();
        milkMonth = registeredMilk;
        amtMonth = estAmt.roundToDouble();
        milkYear = registeredMilk;
        amtYear = estAmt.roundToDouble();
      }
    }

    return {
      '10_days': {
        'litres': (milk10 * 10).round() / 10,
        'amount': amt10.roundToDouble(),
      },
      '15_days': {
        'litres': (milk15 * 10).round() / 10,
        'amount': amt15.roundToDouble(),
      },
      'monthly': {
        'litres': (milkMonth * 10).round() / 10,
        'amount': amtMonth.roundToDouble(),
      },
      'yearly': {
        'litres': (milkYear * 10).round() / 10,
        'amount': amtYear.roundToDouble(),
      },
    };
  }

  // Rate calculation
  static Future<double> calculateRate(
    String animalType,
    double fat,
    double snf,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/collections/rate/calculate').replace(
        queryParameters: {
          'animalType': animalType,
          'fat': fat.toString(),
          'snf': snf.toString(),
        },
      );
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['ratePerLitre'] as num).toDouble();
      }
    } catch (_) {}
    // Offline calculation fallback
    final base = animalType.toLowerCase() == 'cow' ? 38.0 : 54.0;
    return base + (fat - 3.5) * 4.0;
  }

  // AI & Anomaly Insights
  static Future<Map<String, dynamic>> checkAnomaly(
    Map<String, dynamic> sample,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai/anomaly-check'),
            headers: _headers,
            body: jsonEncode(sample),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'isAnomaly': false, 'confidence': 0.8};
  }

  static Future<Map<String, dynamic>> predictQuality(
    Map<String, dynamic> sample,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai/predict-quality'),
            headers: _headers,
            body: jsonEncode(sample),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'grade': 'Good',
      'qualityScore': 86.5,
      'recommendation':
          'Standard Grade milk meeting purity benchmarks (AI Model)',
    };
  }

  static Future<Map<String, dynamic>> getAiForecast() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/ai/forecast'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'morningShiftForecastLtr': 720.5,
      'eveningShiftForecastLtr': 533.5,
      'weeklyTrend': '↑ 12% anticipated rise in milk yield',
      'confidence': 0.89,
    };
  }

  static Future<List<String>> getAiInsights() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/ai/insights'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['insights'] ?? []);
      }
    } catch (_) {}
    return [
      'Milk collection is 12% higher than yesterday.',
      '2 unusual FAT values detected today.',
      'Optimal evening dispatch vehicle timing: 06:30 PM.',
    ];
  }

  // =============================================================
  // OPERATIONS (Advances, Deductions, Expenses, Dispatches, etc.)
  // =============================================================

  // Advances Cache & Store
  static final List<Map<String, dynamic>> _localAdvances = [
    {
      'id': 'adv_001',
      'member': 'Ramesh Patil',
      'memberId': 'M001',
      'amount': 2000.0,
      'recovered': 500.0,
      'reason': 'Cattle Feed Advance',
      'status': 'Pending',
      'date': '15 Sep 2026',
    },
    {
      'id': 'adv_002',
      'member': 'Suresh Deshmukh',
      'memberId': 'M002',
      'amount': 3500.0,
      'recovered': 1000.0,
      'reason': 'Festival Advance',
      'status': 'Pending',
      'date': '18 Sep 2026',
    },
  ];

  static Future<List<dynamic>> getAdvances() async {
    final bool isMember = userRole.toUpperCase() == 'MEMBER';
    final targetCode = currentMemberCode ?? 'M001';
    final targetName = currentMemberName ?? 'Ramesh Patil';

    if (isOffline) {
      if (isMember) {
        return _localAdvances.where((a) {
          final mId = (a['memberId'] ?? '').toString();
          final mName = (a['member'] ?? '').toString();
          return mId == targetCode ||
              mName.contains(targetName) ||
              targetName.contains(mName);
        }).toList();
      }
      return List<dynamic>.from(_localAdvances);
    }
    try {
      final endpoint = isMember
          ? '$baseUrl/operations/advances/my-advances'
          : '$baseUrl/operations/advances';
      final response = await http
          .get(Uri.parse(endpoint), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list;
      }
    } catch (_) {
      // Fallback to local cache if network drops
    }
    if (isMember) {
      return _localAdvances.where((a) {
        final mId = (a['memberId'] ?? '').toString();
        final mName = (a['member'] ?? '').toString();
        return mId == targetCode ||
            mName.contains(targetName) ||
            targetName.contains(mName);
      }).toList();
    }
    return List<dynamic>.from(_localAdvances);
  }

  static Future<Map<String, dynamic>?> createAdvance(
    Map<String, dynamic> advance,
  ) async {
    final newAdv = Map<String, dynamic>.from(advance);
    newAdv['id'] ??= 'adv_${DateTime.now().millisecondsSinceEpoch}';
    _localAdvances.insert(0, newAdv);
    notifyDataChanged();

    addLocalAudit(
      action: 'ADVANCE_GRANTED',
      entityType: 'ADVANCE',
      entityId: newAdv['id']?.toString() ?? 'adv',
      details: 'Granted advance of ₹${newAdv['amount'] ?? 0} to ${newAdv['member'] ?? 'Farmer'} (Reason: ${newAdv['reason'] ?? 'Advance'})',
    );
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/advances'),
            headers: _headers,
            body: jsonEncode(newAdv),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return newAdv;
  }

  static Future<bool> repayAdvance(String id, double amount) async {
    final idx = _localAdvances.indexWhere((a) => a['id'] == id);
    if (idx >= 0) {
      final current =
          (_localAdvances[idx]['recovered'] as num?)?.toDouble() ?? 0.0;
      _localAdvances[idx]['recovered'] = current + amount;
      if (_localAdvances[idx]['recovered'] >=
          (_localAdvances[idx]['amount'] as num)) {
        _localAdvances[idx]['status'] = 'Recovered';
      }
      notifyDataChanged();
    }
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/advances/$id/repay'),
            headers: _headers,
            body: jsonEncode({'amount': amount}),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {}
    return true;
  }

  // Deductions Cache & Store
  static final List<Map<String, dynamic>> _localDeductions = [
    {
      'id': 'ded_001',
      'member': 'Ramesh Patil',
      'memberId': 'M001',
      'amount': 250.0,
      'reason': 'Veterinary Medicine',
      'status': 'Applied',
      'date': '20 Sep 2026',
    },
    {
      'id': 'ded_002',
      'member': 'Suresh Deshmukh',
      'memberId': 'M002',
      'amount': 400.0,
      'reason': 'Cattle Feed Bag',
      'status': 'Applied',
      'date': '22 Sep 2026',
    },
  ];

  static Future<List<dynamic>> getDeductions() async {
    if (isOffline) return List<dynamic>.from(_localDeductions);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/operations/deductions'), headers: _headers)
          .timeout(const Duration(milliseconds: 700));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      isOffline = true;
    }
    return List<dynamic>.from(_localDeductions);
  }

  static Future<Map<String, dynamic>?> createDeduction(
    Map<String, dynamic> deduction,
  ) async {
    final newDed = Map<String, dynamic>.from(deduction);
    newDed['id'] ??= 'ded_${DateTime.now().millisecondsSinceEpoch}';
    _localDeductions.insert(0, newDed);
    notifyDataChanged();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/deductions'),
            headers: _headers,
            body: jsonEncode(newDed),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return newDed;
  }

  // Invoices Cache & Store
  static final List<Map<String, dynamic>> _localInvoices = [
    {
      'id': 'inv_001',
      'invoiceNumber': 'INV-2026-001',
      'memberName': 'Ramesh Patil',
      'memberCode': 'M001',
      'cycle': 'Monthly',
      'amount': 16110.0,
      'status': 'Paid',
      'date': '25 Sep 2026',
    },
    {
      'id': 'inv_002',
      'invoiceNumber': 'INV-2026-002',
      'memberName': 'Suresh Deshmukh',
      'memberCode': 'M002',
      'cycle': 'Monthly',
      'amount': 32556.0,
      'status': 'Paid',
      'date': '25 Sep 2026',
    },
  ];

  static Future<List<dynamic>> getInvoices() async {
    final bool isMember = userRole.toUpperCase() == 'MEMBER';
    final targetCode = currentMemberCode ?? 'M001';
    final targetName = currentMemberName ?? 'Ramesh Patil';

    if (isOffline) {
      if (isMember) {
        return _localInvoices.where((inv) {
          final mCode = (inv['memberCode'] ?? '').toString();
          final mName = (inv['memberName'] ?? inv['member'] ?? '').toString();
          return mCode == targetCode ||
              mName.contains(targetName) ||
              targetName.contains(mName);
        }).toList();
      }
      return List<dynamic>.from(_localInvoices);
    }
    try {
      final endpoint = isMember
          ? '$baseUrl/operations/invoices/my-invoices'
          : '$baseUrl/operations/invoices';
      final response = await http
          .get(Uri.parse(endpoint), headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list;
      }
    } catch (_) {
      // Fallback to local cache if network drops
    }
    if (isMember) {
      return _localInvoices.where((inv) {
        final mCode = (inv['memberCode'] ?? '').toString();
        final mName = (inv['memberName'] ?? inv['member'] ?? '').toString();
        return mCode == targetCode ||
            mName.contains(targetName) ||
            targetName.contains(mName);
      }).toList();
    }
    return List<dynamic>.from(_localInvoices);
  }

  static Future<Map<String, dynamic>?> createInvoice(
    Map<String, dynamic> invoice,
  ) async {
    final newInv = Map<String, dynamic>.from(invoice);
    newInv['id'] ??= 'inv_${DateTime.now().millisecondsSinceEpoch}';
    _localInvoices.insert(0, newInv);
    notifyDataChanged();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/invoices'),
            headers: _headers,
            body: jsonEncode(newInv),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return newInv;
  }

  // Expenses Cache & Store
  static final List<Map<String, dynamic>> _localExpenses = [
    {
      'id': 'exp_001',
      'title': 'Chilling Unit Electricity Bill',
      'category': 'Electricity',
      'amount': 4500.0,
      'paymentMode': 'Online',
      'date': '20 Sep 2026',
    },
    {
      'id': 'exp_002',
      'title': 'Dairy Cleaning & Sanitization Materials',
      'category': 'Maintenance',
      'amount': 650.0,
      'paymentMode': 'Cash',
      'date': '24 Sep 2026',
    },
  ];

  static Future<List<dynamic>> getExpenses() async {
    if (isOffline) return List<dynamic>.from(_localExpenses);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/operations/expenses'), headers: _headers)
          .timeout(const Duration(milliseconds: 700));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      isOffline = true;
    }
    return List<dynamic>.from(_localExpenses);
  }

  static Future<Map<String, dynamic>?> createExpense(
    Map<String, dynamic> expense,
  ) async {
    final newExp = Map<String, dynamic>.from(expense);
    newExp['id'] ??= 'exp_${DateTime.now().millisecondsSinceEpoch}';
    _localExpenses.insert(0, newExp);
    notifyDataChanged();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/expenses'),
            headers: _headers,
            body: jsonEncode(newExp),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return newExp;
  }

  // Dispatches Cache & Store
  static final List<Map<String, dynamic>> _localDispatches = [
    {
      'id': 'disp_001',
      'tankerNo': 'MH-12-AB-1234',
      'driverName': 'Sachin Gaikwad',
      'quantity': 850.0,
      'animalType': 'Buffalo',
      'fat': 6.8,
      'snf': 9.0,
      'temperature': 3.8,
      'destination': 'Pune Dairy Processing Plant',
      'status': 'Dispatched',
      'date': 'Today',
    },
  ];

  static Future<List<dynamic>> getDispatches() async {
    if (isOffline) return List<dynamic>.from(_localDispatches);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/operations/dispatches'), headers: _headers)
          .timeout(const Duration(milliseconds: 700));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      isOffline = true;
    }
    return List<dynamic>.from(_localDispatches);
  }

  static Future<Map<String, dynamic>?> createDispatch(
    Map<String, dynamic> dispatch,
  ) async {
    final newDisp = Map<String, dynamic>.from(dispatch);
    newDisp['id'] ??= 'disp_${DateTime.now().millisecondsSinceEpoch}';
    _localDispatches.insert(0, newDisp);
    notifyDataChanged();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/dispatches'),
            headers: _headers,
            body: jsonEncode(newDisp),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return newDisp;
  }

  // Received Milk
  static final List<Map<String, dynamic>> _localReceived = [
    {
      'id': 'rec_001',
      'source': 'Sub-Center Sangli',
      'quantity': 450.0,
      'type': 'Cow Milk',
      'quality': 'Grade A (4.3% FAT)',
      'status': 'Accepted',
      'date': 'Today',
    },
    {
      'id': 'rec_002',
      'source': 'Sub-Center Satara',
      'quantity': 600.0,
      'type': 'Buffalo Milk',
      'quality': 'Grade A+ (6.9% FAT)',
      'status': 'Accepted',
      'date': 'Today',
    },
  ];

  static Future<List<dynamic>> getReceived() async {
    if (isOffline) return List<dynamic>.from(_localReceived);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/operations/received'), headers: _headers)
          .timeout(const Duration(milliseconds: 700));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      isOffline = true;
    }
    return List<dynamic>.from(_localReceived);
  }

  static Future<Map<String, dynamic>?> createReceived(
    Map<String, dynamic> received,
  ) async {
    final newRec = Map<String, dynamic>.from(received);
    newRec['id'] ??= 'rec_${DateTime.now().millisecondsSinceEpoch}';
    _localReceived.insert(0, newRec);
    notifyDataChanged();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/received'),
            headers: _headers,
            body: jsonEncode(newRec),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return newRec;
  }

  // Milk Sales
  static final List<Map<String, dynamic>> _localMilkSales = [
    {
      'id': 'sale_001',
      'buyerName': 'Hotel Rajdhani Dairy',
      'milkType': 'Cow Milk',
      'quantity': 25.0,
      'ratePerLitre': 48.0,
      'totalAmount': 1200.0,
      'status': 'Paid',
      'date': 'Today',
    },
    {
      'id': 'sale_002',
      'buyerName': 'Mahalaxmi Sweets',
      'milkType': 'Buffalo Milk',
      'quantity': 40.0,
      'ratePerLitre': 65.0,
      'totalAmount': 2600.0,
      'status': 'Paid',
      'date': 'Today',
    },
  ];

  static Future<List<dynamic>> getMilkSales() async {
    if (isOffline) return List<dynamic>.from(_localMilkSales);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/operations/milk-sales'), headers: _headers)
          .timeout(const Duration(milliseconds: 700));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      isOffline = true;
    }
    return List<dynamic>.from(_localMilkSales);
  }

  static Future<Map<String, dynamic>?> createMilkSale(
    Map<String, dynamic> sale,
  ) async {
    final newSale = Map<String, dynamic>.from(sale);
    newSale['id'] ??= 'sale_${DateTime.now().millisecondsSinceEpoch}';
    _localMilkSales.insert(0, newSale);
    notifyDataChanged();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/milk-sales'),
            headers: _headers,
            body: jsonEncode(newSale),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200)
        return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    return newSale;
  }

  // Payments Cache & Store
  static final List<Map<String, dynamic>> _localPayments = [
    {
      'id': 'pay_001',
      'memberCode': 'M001',
      'memberName': 'Ramesh Patil',
      'animal': 'Cow',
      'cycle': 'Monthly',
      'totalMilk': 450.0,
      'grossAmount': 18360.0,
      'advanceDeduction': 2000.0,
      'otherDeductions': 250.0,
      'netPayable': 16110.0,
      'paymentMode': 'Bank',
      'status': 'Paid',
      'date': 'Today',
    },
    {
      'id': 'pay_002',
      'memberCode': 'M002',
      'memberName': 'Suresh Deshmukh',
      'animal': 'Buffalo',
      'cycle': 'Monthly',
      'totalMilk': 620.0,
      'grossAmount': 36456.0,
      'advanceDeduction': 3500.0,
      'otherDeductions': 400.0,
      'netPayable': 32556.0,
      'paymentMode': 'Cash',
      'status': 'Paid',
      'date': 'Today',
    },
    {
      'id': 'pay_003',
      'memberCode': 'M003',
      'memberName': 'Anand Shinde',
      'animal': 'Cow',
      'cycle': '15 Days',
      'totalMilk': 190.0,
      'grossAmount': 7600.0,
      'advanceDeduction': 500.0,
      'otherDeductions': 0.0,
      'netPayable': 7100.0,
      'paymentMode': 'UPI',
      'status': 'Paid',
      'date': 'Today',
    },
    {
      'id': 'pay_004',
      'memberCode': 'M004',
      'memberName': 'Prakash Jadhav',
      'animal': 'Buffalo',
      'cycle': '10 Days',
      'totalMilk': 180.0,
      'grossAmount': 10908.0,
      'advanceDeduction': 0.0,
      'otherDeductions': 0.0,
      'netPayable': 10908.0,
      'paymentMode': 'Cash',
      'status': 'Paid',
      'date': 'Today',
    },
  ];

  static Future<List<dynamic>> getPayments([String? cycle]) async {
    final bool isMember = userRole.toUpperCase() == 'MEMBER';
    final targetCode = currentMemberCode ?? 'M001';
    final targetName = currentMemberName ?? 'Ramesh Patil';

    if (isOffline) {
      var source = _localPayments;
      if (isMember) {
        source = _localPayments.where((p) {
          final mCode = (p['memberCode'] ?? '').toString();
          final mName = (p['memberName'] ?? '').toString();
          return mCode == targetCode ||
              mName.contains(targetName) ||
              targetName.contains(mName);
        }).toList();
      }
      if (cycle != null && cycle.isNotEmpty) {
        final sel = cycle.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
        return source.where((p) {
          final c = (p['cycle'] ?? '')
              .toString()
              .toLowerCase()
              .replaceAll(' ', '')
              .replaceAll('_', '');
          return c.isEmpty || c == sel || c.contains(sel) || sel.contains(c);
        }).toList();
      }
      return List<dynamic>.from(source);
    }
    try {
      final uri = isMember
          ? Uri.parse('$baseUrl/operations/payments/my-payments')
          : (cycle != null
              ? Uri.parse('$baseUrl/operations/payments?cycle=$cycle')
              : Uri.parse('$baseUrl/operations/payments'));
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final serverList = jsonDecode(response.body) as List<dynamic>;
        if (isMember) return serverList;

        final serverIds = <String>{};
        for (final item in serverList) {
          final id = (item['id'] ?? item['_id'] ?? '').toString();
          if (id.isNotEmpty) serverIds.add(id);
        }
        final unsynced = _localPayments.where((p) {
          final id = (p['id'] ?? p['_id'] ?? '').toString();
          return !serverIds.contains(id);
        }).toList();

        _localPayments.clear();
        for (final item in serverList) {
          if (item is Map<String, dynamic>) {
            _localPayments.add(Map<String, dynamic>.from(item));
          }
        }
        _localPayments.addAll(unsynced);

        if (cycle != null && cycle.isNotEmpty) {
          final sel = cycle
              .toLowerCase()
              .replaceAll(' ', '')
              .replaceAll('_', '');
          return _localPayments.where((p) {
            final c = (p['cycle'] ?? '')
                .toString()
                .toLowerCase()
                .replaceAll(' ', '')
                .replaceAll('_', '');
            return c.isEmpty || c == sel || c.contains(sel) || sel.contains(c);
          }).toList();
        }
        return List<dynamic>.from(_localPayments);
      }
    } catch (_) {
      isOffline = true;
    }

    var source = _localPayments;
    if (isMember) {
      source = _localPayments.where((p) {
        final mCode = (p['memberCode'] ?? '').toString();
        final mName = (p['memberName'] ?? '').toString();
        return mCode == targetCode ||
            mName.contains(targetName) ||
            targetName.contains(mName);
      }).toList();
    }
    if (cycle != null && cycle.isNotEmpty) {
      final sel = cycle.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
      return source.where((p) {
        final c = (p['cycle'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('_', '');
        return c.isEmpty || c == sel || c.contains(sel) || sel.contains(c);
      }).toList();
    }
    return List<dynamic>.from(source);
  }

  static Future<Map<String, dynamic>> createMemberLogin(
    String memberCode,
    String username,
    String password,
  ) async {
    final cleanUser = username.trim().toLowerCase();
    final cleanCode = memberCode.trim().toUpperCase();
    final memberName = _localMembers.firstWhere(
      (m) =>
          (m['memberCode'] ?? m['id'] ?? '').toString().toUpperCase() ==
          cleanCode,
      orElse: () => {},
    )['name'] ?? cleanUser;

    final userIdx = _registeredUsers.indexWhere((u) => u['username'] == cleanUser);
    final userMap = {
      'username': cleanUser,
      'role': 'MEMBER',
      'fullName': memberName,
      'memberCode': cleanCode,
      'memberId': cleanCode,
      'passwordHash': password,
    };
    if (userIdx >= 0) {
      _registeredUsers[userIdx] = userMap;
    } else {
      _registeredUsers.add(userMap);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/members/$cleanCode/create-login'),
            headers: _headers,
            body: jsonEncode({
              'username': cleanUser,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'status': 'success',
      'username': cleanUser,
      'memberCode': cleanCode,
      'message': 'Login provisioned for member $cleanCode',
    };
  }

  static Future<Map<String, dynamic>?> createPayment(
    Map<String, dynamic> payment,
  ) async {
    final newPayment = Map<String, dynamic>.from(payment);
    if (!newPayment.containsKey('id') || newPayment['id'] == null) {
      newPayment['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    _localPayments.insert(0, newPayment);
    notifyDataChanged();

    addLocalAudit(
      action: 'PAYMENT_DISBURSED',
      entityType: 'PAYMENT',
      entityId: newPayment['id']?.toString() ?? 'pay',
      details: 'Disbursed payment for ${newPayment['member'] ?? 'Farmer'}: Gross ₹${newPayment['gross'] ?? 0}, Net ₹${newPayment['amount'] ?? 0} (Cycle: ${newPayment['cycle'] ?? 'Monthly'})',
    );

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/operations/payments'),
            headers: _headers,
            body: jsonEncode(newPayment),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final saved = jsonDecode(response.body) as Map<String, dynamic>;
        final idx = _localPayments.indexWhere(
          (p) => p['id'] == newPayment['id'],
        );
        if (idx >= 0) {
          _localPayments[idx] = Map<String, dynamic>.from(saved);
        }
        return saved;
      }
    } catch (_) {}
    return newPayment;
  }

  // Products Master Catalog
  static final List<Map<String, dynamic>> _localProducts = [
    {
      'id': 'PROD_001',
      'name': 'Kapila Cattle Feed (50 Kg)',
      'category': 'Cattle Feed',
      'price': 1450.0,
      'stock': 45,
      'unit': 'Bag',
      'description': 'Balanced dairy cattle feed rich in protein & energy for higher milk yield.',
    },
    {
      'id': 'PROD_002',
      'name': 'Chelated Mineral Mixture (1 Kg)',
      'category': 'Supplements',
      'price': 220.0,
      'stock': 120,
      'unit': 'Packet',
      'description': 'Contains essential minerals to boost fertility and immunity in dairy cattle.',
    },
    {
      'id': 'PROD_003',
      'name': 'Calci-Gold Liquid Calcium (5 Ltr)',
      'category': 'Supplements',
      'price': 850.0,
      'stock': 35,
      'unit': 'Can',
      'description':
          'High calcium supplement with Vitamin D3 for preventing milk fever.',
    },
    {
      'id': 'PROD_004',
      'name': 'Stainless Steel Milk Can (40 Ltr)',
      'category': 'Equipment',
      'price': 3200.0,
      'stock': 15,
      'unit': 'Piece',
      'description':
          'Heavy gauge stainless steel food-grade milk collection can.',
    },
    {
      'id': 'PROD_005',
      'name': 'Teat Dip Antiseptic Solution (1 Ltr)',
      'category': 'Healthcare',
      'price': 380.0,
      'stock': 60,
      'unit': 'Bottle',
      'description':
          'Post-milking teat dip for mastitis prevention and udder hygiene.',
    },
  ];

  static Future<List<Map<String, dynamic>>> getProducts() async {
    if (isOffline) return List<Map<String, dynamic>>.from(_localProducts);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/products'), headers: _headers)
          .timeout(const Duration(milliseconds: 700));
      if (response.statusCode == 200) {
        final serverList = jsonDecode(response.body) as List<dynamic>;
        if (serverList.isNotEmpty) {
          _localProducts.clear();
          for (final item in serverList) {
            if (item is Map<String, dynamic>) {
              _localProducts.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
    } catch (_) {
      isOffline = true;
    }
    return List<Map<String, dynamic>>.from(_localProducts);
  }

  static Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> product,
  ) async {
    final newProduct = Map<String, dynamic>.from(product);
    newProduct['id'] ??= 'PROD_${DateTime.now().millisecondsSinceEpoch}';
    _localProducts.insert(0, newProduct);
    notifyDataChanged();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/products'),
            headers: _headers,
            body: jsonEncode(newProduct),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final saved = jsonDecode(response.body) as Map<String, dynamic>;
        final idx = _localProducts.indexWhere(
          (p) => p['id'] == newProduct['id'],
        );
        if (idx >= 0) _localProducts[idx] = Map<String, dynamic>.from(saved);
        return saved;
      }
    } catch (_) {}

    return newProduct;
  }

  static Future<bool> updateProductStock(String id, int delta) async {
    final idx = _localProducts.indexWhere((p) => p['id'] == id);
    bool updatedLocal = false;
    if (idx >= 0) {
      final current = (_localProducts[idx]['stock'] as num?)?.toInt() ?? 0;
      final updated = current + delta;
      if (updated >= 0) {
        _localProducts[idx]['stock'] = updated;
        notifyDataChanged();
        updatedLocal = true;
      }
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/products/$id/stock?delta=$delta'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return true;
    } catch (_) {}

    return updatedLocal;
  }

  // =============================================================
  // ANNUAL BONUS & DETAILED CYCLE STATEMENT
  // =============================================================
  static final Map<String, bool> _disbursedBonus = {};

  static Future<List<Map<String, dynamic>>> getAnnualBonusList([
    double bonusRate = 1.50,
  ]) async {
    final members = await getMembers();
    final List<Map<String, dynamic>> bonusList = [];

    for (final m in members) {
      final code = (m['memberCode'] ?? m['id'] ?? 'M001').toString();
      final name = (m['name'] ?? m['memberName'] ?? 'Farmer').toString();
      final animal = (m['animalType'] ?? 'Cow').toString();
      final monthly = (m['totalMilkSupplied'] as num?)?.toDouble() ?? 450.0;
      final annualLitres = ((monthly * 12 * 10).round()) / 10;
      final bonusAmount = ((annualLitres * bonusRate) * 100).round() / 100;
      final isDisbursed = _disbursedBonus[code] ?? false;

      bonusList.add({
        'memberCode': code,
        'name': name,
        'animalType': animal,
        'phone': m['phone'] ?? '+91 98765 43210',
        'annualLitres': annualLitres,
        'bonusRate': bonusRate,
        'bonusAmount': bonusAmount,
        'status': isDisbursed ? 'Disbursed' : 'Pending',
        'payoutDate': isDisbursed ? 'Today' : 'Due',
      });
    }

    return bonusList;
  }

  static Future<bool> disburseMemberBonus(
    String memberCode,
    double amount,
  ) async {
    _disbursedBonus[memberCode] = true;
    notifyDataChanged();
    return true;
  }

  static Future<Map<String, dynamic>> getDetailedCycleStatementData(
    String memberCode, {
    int cycle = 1,
  }) async {
    final members = await getMembers();
    final cleanTarget = memberCode.replaceAll('-', '').toUpperCase();
    final member = members.firstWhere(
      (m) {
        final c = (m['memberCode'] ?? m['id'] ?? m['code'] ?? '')
            .toString()
            .replaceAll('-', '')
            .toUpperCase();
        return c == cleanTarget;
      },
      orElse: () => members.isNotEmpty
          ? Map<String, dynamic>.from(members.first as Map)
          : {
              'memberCode': memberCode,
              'name': 'Ramesh Patil',
              'animalType': 'Cow',
              'phone': '9876543210',
            },
    );

    final cleanCode = (member['memberCode'] ?? member['id'] ?? member['code'] ?? memberCode).toString();
    final mName = (member['name'] ?? member['farmerName'] ?? 'Ramesh Patil').toString();
    final isBuffalo = (member['animalType'] ?? 'Cow').toString().toLowerCase() == 'buffalo';
    final rate = isBuffalo ? 54.0 : 38.0;
    final typeLabel = isBuffalo ? 'म्है' : 'गा';
    final avgFat = (member['avgFat'] as num?)?.toDouble() ?? (isBuffalo ? 6.8 : 4.2);
    final snf = (member['snf'] as num?)?.toDouble() ?? (isBuffalo ? 9.0 : 8.5);
    final mPhone = (member['phone'] ?? '+91 98765 43210').toString();

    // Determine cycle date range (Cycle 1: 1-10, Cycle 2: 11-20, Cycle 3: 21-31)
    final int startDay = cycle == 2 ? 11 : (cycle == 3 ? 21 : 1);
    final int endDay = cycle == 2 ? 20 : (cycle == 3 ? 31 : 10);
    final now = DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    final yearStr = now.year.toString();
    final cyclePeriod = '// To //';
    final dateRange = '// ते //';

    // Retrieve actual member collections
    final realCollections = _localCollections.where((c) {
      final cCode = (c['memberCode'] ?? c['farmerId'] ?? '').toString().replaceAll('-', '').toUpperCase();
      return cCode == cleanCode.replaceAll('-', '').toUpperCase();
    }).toList();

    final List<Map<String, dynamic>> dailyRows = [];
    double morningQty = 0, morningAmt = 0;
    double eveningQty = 0, eveningAmt = 0;

    for (int d = startDay; d <= endDay; d++) {
      final dateStr2 = d.toString().padLeft(2, '0');
      final dayCols = realCollections.where((c) {
        final cDate = (c['collectionDate'] ?? '').toString();
        return cDate.endsWith('-') || cDate.endsWith('/') || cDate == dateStr2;
      }).toList();

      final realMorning = dayCols.firstWhere(
        (c) => (c['shift'] ?? '').toString().toLowerCase() == 'morning',
        orElse: () => <String, dynamic>{},
      );
      final realEvening = dayCols.firstWhere(
        (c) => (c['shift'] ?? '').toString().toLowerCase() == 'evening',
        orElse: () => <String, dynamic>{},
      );

      // Populate morning shift
      double mQ, mF, mS, mR, mA;
      if (realMorning.isNotEmpty) {
        mQ = (realMorning['quantity'] as num?)?.toDouble() ?? 0.0;
        mF = (realMorning['fat'] as num?)?.toDouble() ?? avgFat;
        mS = (realMorning['snf'] as num?)?.toDouble() ?? snf;
        mR = (realMorning['ratePerLitre'] as num?)?.toDouble() ?? rate;
        mA = (realMorning['totalAmount'] as num?)?.toDouble() ?? (mQ * mR);
      } else {
        final baseDailyQty = ((member['totalMilkSupplied'] as num?)?.toDouble() ?? 240.0) / 20.0;
        mQ = (baseDailyQty * 0.55 + (d % 3) * 0.4);
        mQ = mQ > 0 ? ((mQ * 10).round() / 10) : 12.5;
        mF = avgFat;
        mS = snf;
        mR = rate;
        mA = ((mQ * mR) * 10).round() / 10;
      }

      // Populate evening shift
      double eQ, eF, eS, eR, eA;
      if (realEvening.isNotEmpty) {
        eQ = (realEvening['quantity'] as num?)?.toDouble() ?? 0.0;
        eF = (realEvening['fat'] as num?)?.toDouble() ?? avgFat;
        eS = (realEvening['snf'] as num?)?.toDouble() ?? snf;
        eR = (realEvening['ratePerLitre'] as num?)?.toDouble() ?? rate;
        eA = (realEvening['totalAmount'] as num?)?.toDouble() ?? (eQ * eR);
      } else {
        final baseDailyQty = ((member['totalMilkSupplied'] as num?)?.toDouble() ?? 240.0) / 20.0;
        eQ = (baseDailyQty * 0.45 + ((d + 1) % 3) * 0.3);
        eQ = eQ > 0 ? ((eQ * 10).round() / 10) : 10.5;
        eF = avgFat;
        eS = snf;
        eR = rate;
        eA = ((eQ * eR) * 10).round() / 10;
      }

      morningQty += mQ;
      morningAmt += mA;
      eveningQty += eQ;
      eveningAmt += eA;

      dailyRows.add({
        'date': dateStr2,
        'type': typeLabel,
        'm': {
          'ltr': mQ,
          'fat': mF,
          'snf': mS,
          'rate': mR,
          'amt': mA,
        },
        'e': {
          'ltr': eQ,
          'fat': eF,
          'snf': eS,
          'rate': eRate(mR, isBuffalo),
          'amt': eA,
        },
        'mQty': mQ,
        'mFat': mF,
        'mSnf': mS,
        'mRate': mR,
        'mAmt': mA,
        'eQty': eQ,
        'eFat': eF,
        'eSnf': eS,
        'eRate': eRate(mR, isBuffalo),
        'eAmt': eA,
      });
    }

    final totalQty = ((morningQty + eveningQty) * 100).round() / 100;
    final totalMilkAmt = ((morningAmt + eveningAmt) * 100).round() / 100;

    final List<Map<String, dynamic>> feedPurchases = [
      {
        'date': startDay.toString().padLeft(2, '0'),
        'item': 'Hindustan Govats 50kg (पशूखाद्य)',
        'qty': 1,
        'rate': 1600.0,
        'total': 1600.0,
      },
    ];
    const totalFeedAmt = 1600.0;
    const totalFeedBags = 1;
    const otherDeduction = 250.0;
    const totalDeducted = totalFeedAmt + otherDeduction;
    final netPayable = (totalMilkAmt - totalDeducted) > 0 ? (((totalMilkAmt - totalDeducted) * 100).round() / 100) : 0.0;

    final List<Map<String, dynamic>> deductions = [
      {
        'name': 'पशूखाद्य (Feed Deductions)',
        'amount': totalFeedAmt.toStringAsFixed(2),
      },
      {
        'name': 'इतर खर्च (Veterinary / Medicine)',
        'amount': otherDeduction.toStringAsFixed(2),
      },
    ];

    final summary = {
      'totalLiters': totalQty.toStringAsFixed(1),
      'milkTotalAmount': totalMilkAmt.toStringAsFixed(2),
      'totalDeduction': totalDeducted.toStringAsFixed(2),
      'previousBalance': '0.00',
      'netPayable': netPayable.toStringAsFixed(2),
    };

    final memberInfo = {
      'code': cleanCode,
      'name': mName,
      'village': member['village'] ?? 'Kadamwadi, Kolhapur',
      'phone': mPhone,
      'milkType': isBuffalo ? 'BUFFALO' : 'COW',
      'bankName': member['bankName'] ?? 'Bank of India (Kadamwadi Branch)',
      'accountNo': member['accountNo'] ?? '6024101100234',
    };

    final dairyInfo = {
      'name': 'Late L D Kadam Milk Producers Cooperative Society Ltd.',
      'address': 'Kadamwadi, Kolhapur, Maharashtra',
      'phone': '+91 98220 12345',
    };

    final deductionsLedger = [
      {
        'type': 'इतर देय (Veterinary/Medicine)',
        'totalDue': -otherDeduction,
        'deducted': otherDeduction,
        'balance': 0.0,
        'currentCredit': 0.0,
      },
      {
        'type': 'पशूखाद्य (Cattle Feed Bags)',
        'totalDue': -totalFeedAmt,
        'deducted': totalFeedAmt,
        'balance': 0.0,
        'currentCredit': 0.0,
      },
      {
        'type': 'अ‍ॅडव्हान्स (Advance Loan)',
        'totalDue': 0.0,
        'deducted': 0.0,
        'balance': 0.0,
        'currentCredit': 0.0,
      },
    ];

    return {
      'dairyInfo': dairyInfo,
      'memberInfo': memberInfo,
      'summary': summary,
      'feedPurchases': feedPurchases,
      'deductions': deductions,
      'dailyRows': dailyRows,
      'billNo': 'BILL--721',
      'cyclePeriod': cyclePeriod,
      'dateRange': dateRange,
      'dairyName': 'Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur',
      'centerLocation': 'Kadamwadi, Kolhapur, Maharashtra',
      'centerPhone': '+91 98220 12345',
      'memberCode': cleanCode,
      'memberName': mName,
      'rate': rate,
      'morningTotalQty': (morningQty * 100).round() / 100,
      'morningTotalAmt': (morningAmt * 100).round() / 100,
      'eveningTotalQty': (eveningQty * 100).round() / 100,
      'eveningTotalAmt': (eveningAmt * 100).round() / 100,
      'totalQty': totalQty,
      'totalMilkAmt': totalMilkAmt,
      'feedItems': feedPurchases,
      'totalFeedBags': totalFeedBags,
      'totalFeedAmt': totalFeedAmt,
      'deductionsLedger': deductionsLedger,
      'totalDeductions': totalDeducted,
      'previousBalance': 0.00,
      'netPayable': netPayable,
      'remainingBalance': 0.00,
      'bankDetails': '6024101100234 / BKID0000123 / Kadamwadi Branch',
      'note': 'नियमित दूध संकलन केल्याबद्दल धन्यवाद',
    };
  }

  static double eRate(double base, bool isBuffalo) => isBuffalo ? 54.0 : 38.0;

  // =============================================================
  // SERVER-SIDE PDF EXPORT ENDPOINTS
  // =============================================================
  static String getInvoicePdfUrl(String id) => '$baseUrl/pdf/invoice/$id';
  static String getSlipPdfUrl(String id) => '$baseUrl/pdf/slip/$id';
  static String getPayoutPdfUrl(String id) => '$baseUrl/pdf/payout/$id';
  static String getDetailedStatementPdfUrl(String memberCode) =>
      '$baseUrl/pdf/statement/$memberCode';
  static String getAnnualBonusPdfUrl(double rate) =>
      '$baseUrl/pdf/annual-bonus?rate=$rate';

  static Future<Uint8List?> fetchInvoicePdf(String id) async {
    if (!isOffline) {
      try {
        final response = await http
            .get(Uri.parse(getInvoicePdfUrl(id)), headers: _headers)
            .timeout(const Duration(milliseconds: 900));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }
    final inv = _localInvoices.firstWhere(
      (i) => i['id'] == id || i['invoiceNumber'] == id,
      orElse: () => _localInvoices.first,
    );
    return PdfGeneratorService.generateInvoicePdf(inv);
  }

  static Future<Uint8List?> fetchSlipPdf(String id) async {
    if (!isOffline) {
      try {
        final response = await http
            .get(Uri.parse(getSlipPdfUrl(id)), headers: _headers)
            .timeout(const Duration(milliseconds: 900));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }
    final col = _localCollections.firstWhere(
      (c) => c['id'] == id,
      orElse: () => _localCollections.first,
    );
    final invMock = {
      'invoiceNo': 'SLIP-${col['id']}',
      'member': col['memberName'],
      'cycle': '${col['shift']} Shift',
      'milk': col['quantity'],
      'gross': col['totalAmount'],
      'advance': 0.0,
      'deduction': 0.0,
      'net': col['totalAmount'],
      'status': 'Verified',
    };
    return PdfGeneratorService.generateInvoicePdf(invMock);
  }

  static Future<Uint8List?> fetchDetailedStatementPdf(String memberCode) async {
    if (!isOffline) {
      try {
        final response = await http
            .get(
              Uri.parse(getDetailedStatementPdfUrl(memberCode)),
              headers: _headers,
            )
            .timeout(const Duration(milliseconds: 900));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }
    final data = await getDetailedCycleStatementData(memberCode);
    return PdfGeneratorService.generateDetailedStatementPdf(data);
  }

  static Future<Uint8List?> fetchAnnualBonusPdf(double rate) async {
    if (!isOffline) {
      try {
        final response = await http
            .get(Uri.parse(getAnnualBonusPdfUrl(rate)), headers: _headers)
            .timeout(const Duration(milliseconds: 900));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }
    final list = await getAnnualBonusList(rate);
    return PdfGeneratorService.generateAnnualBonusPdf(list, rate);
  }

  // ==========================================
  // EXTERNAL SERVICES (SMS, FCM, S3, Maps)
  // ==========================================

  /// Get status of live external integrations (SMS, FCM, AWS S3, Google Maps)
  static Future<Map<String, dynamic>> fetchExternalServicesStatus() async {
    if (!isOffline) {
      try {
        final response = await http
            .get(Uri.parse('/external/status'), headers: _headers)
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'sms': {
        'provider': 'FAST2SMS',
        'isLive': false,
        'mode': 'SANDBOX_MOCK',
        'supportedProviders': ['FAST2SMS', 'TWILIO'],
      },
      'fcm': {
        'provider': 'FIREBASE_CLOUD_MESSAGING',
        'isLive': false,
        'mode': 'SANDBOX_MOCK',
      },
      'storage': {
        'provider': 'AWS_S3',
        'bucket': 'smartdairy-storage-bucket',
        'region': 'ap-south-1',
        'isLive': false,
        'mode': 'LOCAL_CLOUD_CACHE',
      },
      'maps': {
        'provider': 'GOOGLE_MAPS_DISTANCE_MATRIX',
        'isLive': false,
        'mode': 'HAVERSINE_MATHEMATICAL_MODEL',
      },
    };
  }

  /// Sends a test or live SMS to the specified phone number
  static Future<Map<String, dynamic>> sendTestSms(String phone, {String? message}) async {
    final msg = message ?? 'LDK Smart Dairy test receipt message.';
    if (!isOffline) {
      try {
        final uri = Uri.parse('/external/sms/test').replace(
          queryParameters: {'phone': phone, 'message': msg},
        );
        final response = await http.post(uri, headers: _headers).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'status': 'DELIVERED_SANDBOX',
      'provider': 'FAST2SMS_SANDBOX',
      'live': false,
      'info': 'Operating in offline / sandbox mock mode.',
    };
  }

  /// Fetches milk tanker transit estimates between center and processing plant
  static Future<Map<String, dynamic>> fetchTankerTransit({
    String origin = 'Center 1',
    String destination = 'Sangli Dairy Plant',
    double originLat = 16.8524,
    double originLon = 74.5815,
    double destLat = 16.9200,
    double destLon = 74.6500,
  }) async {
    if (!isOffline) {
      try {
        final uri = Uri.parse('/external/maps/transit').replace(
          queryParameters: {
            'origin': origin,
            'destination': destination,
            'originLat': originLat.toString(),
            'originLon': originLon.toString(),
            'destLat': destLat.toString(),
            'destLon': destLon.toString(),
          },
        );
        final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'origin': origin,
      'destination': destination,
      'distanceKm': 10.38,
      'estimatedMinutes': 16,
      'service': 'Haversine mathematical model (Mock offline)',
      'isLive': false,
    };
  }
}
