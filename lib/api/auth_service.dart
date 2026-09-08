import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  static bool get required {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  final ValueNotifier<User?> user = ValueNotifier(null);
  final ValueNotifier<bool> needsLogin = ValueNotifier(false);

  StreamSubscription<User?>? _sub;

  bool get isSignedIn => user.value != null;
  String? get uid => user.value?.uid;

  Future<void> init() async {
    if (!required) return;
    _sub ??= FirebaseAuth.instance.authStateChanges().listen((next) {
      user.value = next;
      needsLogin.value = next == null;
    });
    user.value = FirebaseAuth.instance.currentUser;
    needsLogin.value = user.value == null;
  }

  Future<String?> idToken({bool forceRefresh = false}) async {
    final current = user.value ?? FirebaseAuth.instance.currentUser;
    if (current == null) return null;
    return current.getIdToken(forceRefresh);
  }

  Future<void> signInGoogle() async {
    final google = GoogleSignIn(scopes: const ['email']);
    final account = await google.signIn();
    if (account == null) return;
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    needsLogin.value = false;
  }

  Future<void> signInApple() async {
    final rawNonce = _nonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    final credential = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
      accessToken: apple.authorizationCode,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    needsLogin.value = false;
  }

  void markUnauthorized() {
    needsLogin.value = true;
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    user.value = null;
    needsLogin.value = required;
  }

  String _nonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
