import 'package:flutter/foundation.dart';
import '../services/drive/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isSignedIn => GoogleAuthService.instance.isSignedIn;
  String? get userEmail => GoogleAuthService.instance.currentEmail;
  String? get userName => GoogleAuthService.instance.currentName;
  String? get userPhotoUrl => GoogleAuthService.instance.currentUser?.photoUrl;

  Future<void> init() async {
    await GoogleAuthService.instance.init();
    notifyListeners();
  }

  Future<bool> signIn({String? serverClientId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final account = await GoogleAuthService.instance.signIn(serverClientId: serverClientId);
      _isLoading = false;
      notifyListeners();
      return account != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> connectWithEmailDirectly(String email, {String? name}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await GoogleAuthService.instance.connectWithEmail(email, name: name);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await GoogleAuthService.instance.signOut();
    _isLoading = false;
    notifyListeners();
  }
}
