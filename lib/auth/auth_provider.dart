import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/auth/auth_mode.dart';
import 'package:shop/common/db.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _userId;
  String? _token;
  String? _refreshToken;
  DateTime? _expiryDate;
  Timer? _logoutTimer;

  Future<void> _authenticate(
    String email,
    String password,
    AuthMode mode,
  ) async {
    Uri? url;
    if (mode == AuthMode.Signup) {
      url = Uri.parse(firebaseSignupNewUser);
    } else if (mode == AuthMode.Login) {
      url = Uri.parse(firebaseSignin);
    }

    final payload = json.encode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    });
    try {
      final rawResponse = await http.post(url!, body: payload);
      final response = json.decode(rawResponse.body);

      if (response['error'] != null) {
        throw HttpException(response['error']['message']);
      }

      _userId = response['localId'];
      _token = response['idToken'];
      _refreshToken = response['refreshToken'];
      _expiryDate = DateTime.now().add(
        Duration(seconds: int.parse(response['expiresIn'])),
      );
      _setAutoLogout();
      notifyListeners();

      final String authData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate!.toIso8601String(),
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('authData', authData);
      print('AP30| set authData: $authData');
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, AuthMode.Signup);
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, AuthMode.Login);
  }

  Future<void> logout() async {
    _userId = null;
    _token = null;
    _expiryDate = null;

    if (_logoutTimer != null) {
      _logoutTimer!.cancel();
      _logoutTimer = null;
    }

    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString('authData'));
    prefs.remove('authData');
    // prefs.clear(); // clear all data
  }

  void _setAutoLogout() {
    if (_logoutTimer != null) {
      _logoutTimer!.cancel();
    }
    final timeToExpiry = _expiryDate != null
        ? _expiryDate!.difference(DateTime.now()).inSeconds
        : 0;
    _logoutTimer = Timer(Duration(seconds: timeToExpiry), logout);
    print('AP10| _autoLogout sets for $timeToExpiry sec');
  }

  Future<bool> tryAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authData')) {
      print('AP20| tryToAutoLogin() > prefs.containsKey(authData): false');
      return false;
    }
    final extractedAuthData = prefs.getString('authData');
    print('AP21| tryToAutoLogin() > extractedAuthData: $extractedAuthData');
    final decode = json.decode(extractedAuthData!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(decode['expiryDate']);
    if (expiryDate.isBefore(DateTime.now())) {
      print(
          'AP22| tryToAutoLogin() > expiryDate.isBefore(DateTime.now()): true');
      return false;
    }
    _token = decode['token'];
    _userId = decode['userId'];
    _expiryDate = expiryDate;

    notifyListeners();
    _setAutoLogout();
    return true;
  }

  String? get token {
    if (_expiryDate != null && _expiryDate!.isAfter(DateTime.now())) {
      return _token;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  bool get isAuth {
    return token != null;
  }

  String? get refreshToken {
    return _refreshToken;
  }
}
