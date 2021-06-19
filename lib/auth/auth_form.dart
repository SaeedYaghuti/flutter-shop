import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/auth/auth_provider.dart';

import 'auth_mode.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    Key? key,
  }) : super(key: key);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };
  var _isLoading = false;
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: Container(
        height: _authMode == AuthMode.Signup ? 320 : 260,
        constraints:
            BoxConstraints(minHeight: _authMode == AuthMode.Signup ? 320 : 260),
        width: deviceSize.width * 0.75,
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _buildEmailFeild(),
                _buildPasswordField(),
                if (_authMode == AuthMode.Signup) _buildConformPasswordField(),
                SizedBox(height: 20),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  _buildSigninLoginButton(context),
                _buildSwitchButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailFeild() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'E-Mail'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty || !value.contains('@')) {
          return 'Invalid email!';
        }
        return null;
      },
      onSaved: (value) {
        _authData['email'] = value!;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Password'),
      obscureText: true,
      controller: _passwordController,
      validator: (value) {
        if (value == null || value.isEmpty || value.length < 5) {
          return 'Password is too short!';
        }
      },
      onSaved: (value) {
        _authData['password'] = value!;
      },
    );
  }

  TextFormField _buildConformPasswordField() {
    return TextFormField(
      enabled: _authMode == AuthMode.Signup,
      decoration: InputDecoration(labelText: 'Confirm Password'),
      obscureText: true,
      validator: _authMode == AuthMode.Signup
          ? (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match!';
              }
            }
          : null,
    );
  }

  RaisedButton _buildSigninLoginButton(BuildContext context) {
    return RaisedButton(
      child: Text(_authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP'),
      onPressed: _submit,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      color: Theme.of(context).primaryColor,
      textColor: Theme.of(context).primaryTextTheme.button!.color,
    );
  }

  FlatButton _buildSwitchButton(BuildContext context) {
    return FlatButton(
      child:
          Text('${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
      onPressed: _switchAuthMode,
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    _startLoading();

    try {
      if (_authMode == AuthMode.Login) {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _authData['email']!,
          _authData['password']!,
        );
        // after successfull login; we run notifyListiner() at authProvider; listiner will action themself to new state
      } else {
        await Provider.of<AuthProvider>(context, listen: false).signup(
          _authData['email']!,
          _authData['password']!,
        );
        // after successfull signup; we run notifyListiner() at authProvider; listiner will action themself to new state

      }
    } on HttpException catch (error) {
      _endLoading();
      var errorMessage = 'Authentication failed';
      if (error.toString().contains('EMAIL_EXISTS')) {
        errorMessage = 'This email address is already in use.';
      } else if (error.toString().contains('INVALID_EMAIL')) {
        errorMessage = 'This is not a valid email address';
      } else if (error.toString().contains('WEAK_PASSWORD')) {
        errorMessage = 'This password is too weak.';
      } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
        errorMessage = 'Could not find a user with that email.';
      } else if (error.toString().contains('INVALID_PASSWORD')) {
        errorMessage = 'Invalid password.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _endLoading();
      const errorMessage =
          'Could not authenticate you. Please try again later.';
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred!'),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void _endLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }
}
