import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _usernameKey = 'biometric_username';
  static const String _passwordKey = 'biometric_password';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Verifica si el dispositivo soporta biometría y está configurada
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// Obtiene los tipos biométricos disponibles (Face ID, Touch ID, Fingerprint, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting biometrics: $e');
      return [];
    }
  }

  /// Autentica al usuario con biometría
  Future<bool> authenticate({String reason = 'Autentícate para acceder a tu cuenta'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }

  /// Guarda las credenciales cifradas
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _secureStorage.write(key: _usernameKey, value: username);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
  }

  /// Recupera las credenciales guardadas
  Future<Map<String, String>?> getSavedCredentials() async {
    final username = await _secureStorage.read(key: _usernameKey);
    final password = await _secureStorage.read(key: _passwordKey);
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    if (username != null && password != null && enabled == 'true') {
      return {'username': username, 'password': password};
    }
    return null;
  }

  /// Verifica si hay credenciales guardadas
  Future<bool> hasSavedCredentials() async {
    final creds = await getSavedCredentials();
    return creds != null;
  }

  /// Elimina las credenciales guardadas
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  /// Verifica si la biometría está habilitada por el usuario
  Future<bool> isEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }
}
