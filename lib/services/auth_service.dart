import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  UserModel? _currentUserModel;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _init();
  }

  void _init() {
    print('AuthService _init() 開始');
    _auth.authStateChanges().listen((User? user) async {
      print('authStateChanges: user = ${user?.uid ?? "null"}');
      _currentUser = user;
      if (user != null) {
        print('ユーザーが存在、UserModelを読み込み開始');
        await _loadUserModel();
      } else {
        print('ユーザーが存在しない');
        _currentUserModel = null;
      }
      _isLoading = false;
      print('isLoading = false に設定');
      notifyListeners();
    });
  }

  Future<void> _loadUserModel() async {
    print('_loadUserModel() 開始');
    if (_currentUser == null) {
      print('currentUser が null');
      return;
    }

    try {
      print('Firestoreからユーザーデータを取得: ${_currentUser!.uid}');
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        print('ユーザーデータが見つかりました');
        _currentUserModel = UserModel.fromFirestore(doc);
      } else {
        print('ユーザーデータが見つかりません');
      }
    } catch (e) {
      print('_loadUserModel エラー: $e');
      _errorMessage = e.toString();
    }
  }

  // ユーザーモデルを再読み込み（public メソッド）
  Future<void> refreshUserModel() async {
    await _loadUserModel();
    notifyListeners();
  }

  // ユーザー登録
  Future<bool> register({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      print('register() 開始: email = $email');
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      // Firebase Authでユーザー作成
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Firebase Auth ユーザー作成完了: ${credential.user?.uid}');

      if (credential.user != null) {
        // Firestoreにユーザー情報を保存
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          nickname: nickname,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        print('Firestoreにユーザーデータを保存開始');
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toFirestore());
        print('Firestoreにユーザーデータを保存完了');

        _currentUserModel = userModel;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('register エラー: $e');
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ログイン
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      print('login() 開始: email = $email');
      _errorMessage = null;
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('ログイン成功');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('login エラー: $e');
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ログアウト
  Future<void> logout() async {
    print('logout() 開始');
    await _auth.signOut();
    _currentUserModel = null;
    _errorMessage = null;
    print('ログアウト完了');
    notifyListeners();
  }

  // ユーザー情報更新
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      print('updateUserProfile() 開始');
      _errorMessage = null;

      final updatedUserWithTimestamp = updatedUser.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUserWithTimestamp.toFirestore());
      print('ユーザープロフィール更新完了');

      _currentUserModel = updatedUserWithTimestamp;
      notifyListeners();
      return true;
    } catch (e) {
      print('updateUserProfile エラー: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // エラーメッセージを日本語に変換
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'ユーザーが見つかりません';
        case 'wrong-password':
          return 'パスワードが正しくありません';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'weak-password':
          return 'パスワードが弱すぎます';
        case 'invalid-email':
          return 'メールアドレスが正しくありません';
        case 'invalid-credential':
          return 'メールアドレスまたはパスワードが正しくありません';
        default:
          return '認証エラーが発生しました: ${error.message}';
      }
    }
    return error.toString();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}