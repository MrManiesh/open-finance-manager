import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../preferences_service.dart';

class GoogleAuthService {
  static final GoogleAuthService instance = GoogleAuthService._internal();

  GoogleAuthService._internal();

  static const String appPackageName = 'com.openfinancemanager.open_finance_manager';
  static const String appDebugSha1 = '6E:01:6D:D4:78:F3:E2:0D:08:A6:EB:17:55:3F:8E:BB:35:3C:6D:8B';
  static const String appDebugSha256 = '9D:F3:E5:89:8B:58:0C:31:5A:02:23:39:17:5A:A8:2C:59:42:CD:27:5A:2C:D8:91:6E:3C:30:7F:A5:5F:06:A9';

  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _manualConnectedEmail;
  String? _manualConnectedName;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null || (_manualConnectedEmail != null && _manualConnectedEmail!.isNotEmpty);

  String? get currentEmail => _currentUser?.email ?? _manualConnectedEmail ?? PreferencesService.getUserEmail();
  String? get currentName => _currentUser?.displayName ?? _manualConnectedName ?? PreferencesService.getUserName();

  Future<void> init() async {
    _manualConnectedEmail = PreferencesService.getUserEmail();
    _manualConnectedName = PreferencesService.getUserName();

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      if (account != null) {
        _manualConnectedEmail = account.email;
        _manualConnectedName = account.displayName ?? account.email.split('@').first;
        PreferencesService.setUserEmail(account.email);
        PreferencesService.setUserName(_manualConnectedName);
      }
    });

    try {
      _currentUser = await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Silent Google Sign-In error: $e');
    }
  }

  Future<GoogleSignInAccount?> signIn({String? serverClientId}) async {
    try {
      if (serverClientId != null && serverClientId.trim().isNotEmpty) {
        _googleSignIn = GoogleSignIn(
          serverClientId: serverClientId.trim(),
          scopes: <String>[
            'email',
            drive.DriveApi.driveFileScope,
          ],
        );
      }

      final account = await _googleSignIn.signIn();
      _currentUser = account;
      if (account != null) {
        _manualConnectedEmail = account.email;
        _manualConnectedName = account.displayName ?? account.email.split('@').first;
        await PreferencesService.setUserEmail(account.email);
        await PreferencesService.setUserName(_manualConnectedName);
      }
      return account;
    } on PlatformException catch (pe) {
      debugPrint('PlatformException during Google Sign-In: ${pe.code} - ${pe.message}');
      if (pe.message?.contains('10') == true || pe.code.contains('10') || pe.message?.contains('ApiException: 10') == true) {
        throw Exception(
          'Google Cloud Setup Required:\n'
          'Google requires registering this app\'s SHA-1 fingerprint in your Google Cloud Console project.\n\n'
          'Package: $appPackageName\n'
          'SHA-1: $appDebugSha1',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// Direct connect with email for immediate testing / local drive simulation
  Future<void> connectWithEmail(String email, {String? name}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;

    _manualConnectedEmail = cleanEmail;
    _manualConnectedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : cleanEmail.split('@').first;

    await PreferencesService.setUserEmail(_manualConnectedEmail);
    await PreferencesService.setUserName(_manualConnectedName);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
    _currentUser = null;
    _manualConnectedEmail = null;
    _manualConnectedName = null;
    await PreferencesService.setUserEmail(null);
    await PreferencesService.setUserName(null);
  }

  Future<http.Client?> getAuthenticatedClient() async {
    if (_currentUser != null) {
      try {
        final headers = await _currentUser!.authHeaders;
        return _GoogleAuthClient(headers);
      } catch (e) {
        debugPrint('Failed to get auth headers: $e');
      }
    }
    return null;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
