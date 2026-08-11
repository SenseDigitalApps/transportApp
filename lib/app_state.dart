import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:transport_app/components/default_text_field/default_text_field_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ModuleCacheEntry {
  final dynamic jsonBody;
  final DateTime timestamp;
  final String moduleId;

  _ModuleCacheEntry({
    required this.jsonBody,
    required this.timestamp,
    required this.moduleId,
  });

  bool isValid({int maxAgeHours = 12}) {
    return DateTime.now().difference(timestamp).inHours < maxAgeHours;
  }
}

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  static final Map<String, _ModuleCacheEntry> _moduleConfigCache = {};

  dynamic getCachedModuleConfigJson(String moduleName) {
    final entry = _moduleConfigCache[moduleName];
    if (entry == null) return null;
    if (!entry.isValid(maxAgeHours: 12)) {
      _moduleConfigCache.remove(moduleName);
      return null;
    }
    return entry.jsonBody;
  }

  void setCachedModuleConfig(
      String moduleName, String moduleId, dynamic jsonBody) {
    _moduleConfigCache[moduleName] = _ModuleCacheEntry(
      jsonBody: jsonBody,
      timestamp: DateTime.now(),
      moduleId: moduleId,
    );
  }

  void invalidateAllModuleConfig() {
    _moduleConfigCache.clear();
  }

  String? getCachedModuleId(String moduleName) {
    return _moduleConfigCache[moduleName]?.moduleId;
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _clienteEquipo = prefs.getString('ff_clienteEquipo') ?? _clienteEquipo;
    });
    _safeInit(() {
      _clientId = prefs.getString('ff_clientId') ?? _clientId;
    });
    _safeInit(() {
      _organizacion = prefs.getString('ff_organizacion') ?? _organizacion;
    });
    _safeInit(() {
      _token = prefs.getString('ff_token') ?? _token;
    });
    _safeInit(() {
      _chatMode = prefs.getString('ff_chatmode') ?? _chatMode;
    });
    _safeInit(() {
      _refreshToken = prefs.getString('ff_refreshToken') ?? _refreshToken;
    });
    _safeInit(() {
      _loginUser = prefs.getString('ff_loginUser') ?? _loginUser;
    });
    _safeInit(() {
      _loginPassword = prefs.getString('ff_loginPassword') ?? _loginPassword;
    });
    _safeInit(() {
      _unreadNotifications =
          prefs.getInt('ff_unreadNotifications') ?? _unreadNotifications;
    });
    _safeInit(() {
      _pendingTasks = prefs.getInt('ff_pendingTasks') ?? _pendingTasks;
    });
    _safeInit(() {
      _id = prefs.getString('ff_id') ?? _id;
    });
    _safeInit(() {
      _username = prefs.getString('ff_username') ?? _username;
    });
    _safeInit(() {
      _email = prefs.getString('ff_email') ?? _email;
    });
    _safeInit(() {
      _fullName = prefs.getString('ff_fullName') ?? _fullName;
    });
    _safeInit(() {
      _avatar = prefs.getString('ff_avatar') ?? _avatar;
    });
    _safeInit(() {
      _role = prefs.getString('ff_role') ?? _role;
    });

    _safeInit(() {
      _modulesPermissions = prefs.getStringList('ff_modulesPermissions') ?? [];
    });

    _safeInit(() {
      _shortname = prefs.getString('ff_shortname') ?? _shortname;
    });

    _safeInit(() {
      _recientes = prefs.getStringList('ff_recientes')?.map((x) {
            try {
              return jsonDecode(x);
            } catch (e) {
              return {};
            }
          }).toList() ??
          _recientes;
    });

    _safeInit(() {
      _moduleList = prefs.getStringList('ff_moduleList')?.map((x) {
            try {
              return jsonDecode(x);
            } catch (e) {
              return {};
            }
          }).toList() ??
          _moduleList;
    });

    _safeInit(() {
      _permissions = prefs.getStringList('ff_permissions') ?? [];
    });

    _safeInit(() {
      _roleGroups = prefs.getStringList('ff_roleGroups')?.map((x) {
            try {
              return jsonDecode(x);
            } catch (e) {
              return {};
            }
          }).toList() ??
          _roleGroups;
    });

    _safeInit(() {
      _textoControlador = prefs.getStringList('ff_textoControlador')?.map((x) {
            try {
              return jsonDecode(x);
            } catch (e) {
              return [];
            }
          }).toList() ??
          _textoControlador;
    });

    _safeInit(() {
      _logoLink = prefs.getString('ff_logolink') ?? _logoLink;
    });

    _safeInit(() {
      _fondoLink = prefs.getString('ff_fondolink') ?? _fondoLink;
    });

    _safeInit(() {
      _simpleApp = prefs.getString('ff_simpleapp') ?? _simpleApp;
    });

    _safeInit(() {
      _simpleAppRole = prefs.getString('ff_simpleapprole') ?? _simpleAppRole;
    });

    _safeInit(() {
      _simpleAppSlugModule =
          prefs.getString('ff_simpleappslugmodule') ?? _simpleAppSlugModule;
    });

    _safeInit(() {
      _simpleAppSlugFecha =
          prefs.getString('ff_simpleappslugfecha') ?? _simpleAppSlugFecha;
    });

    _safeInit(() {
      _simpleAppSlugFormato =
          prefs.getString('ff_simpleappslugformato') ?? _simpleAppSlugFormato;
    });

    _safeInit(() {
      _simpleAppSlugUserAsignado =
          prefs.getString('ff_simpleappsluguserasignado') ??
              _simpleAppSlugUserAsignado;
    });

    //Nuevos campos de configuración

    _safeInit(() {
      _simpleSlugFilter =
          prefs.getString('ff_simpleslugfilter') ?? _simpleSlugFilter;
    });

    _safeInit(() {
      _simpleValueFilter =
          prefs.getString('ff_simplevaluefilter') ?? _simpleValueFilter;
    });

    _safeInit(() {
      _simpleSlugAsignado =
          prefs.getString('ff_simpleslugasignado') ?? _simpleSlugAsignado;
    });

    _safeInit(() {
      _simpleSlugRepeater =
          prefs.getString('ff_simpleslugrepeater') ?? _simpleSlugRepeater;
    });

    _safeInit(() {
      _simpleSlugRepeaterLabel =
          prefs.getString('ff_simpleslugrepeaterlabel') ??
              _simpleSlugRepeaterLabel;
    });

    _safeInit(() {
      _simpleSlugRepeaterBoolean =
          prefs.getString('ff_simpleslugrepeaterboolean') ??
              _simpleSlugRepeaterBoolean;
    });

    _safeInit(() {
      _simpleSlugRepeaterRelated =
          prefs.getString('ff_simpleslugrepeaterrelated') ??
              _simpleSlugRepeaterRelated;
    });

    _safeInit(() {
      _firma = prefs.getString('ff_firma') ?? _firma;
    });

    _safeInit(() {
      _lookerStudio = prefs.getString('ff_lookerStudio') ?? _lookerStudio;
    });

    _safeInit(() {
      _loaderLogo = prefs.getString('ff_loaderLogo') ?? _loaderLogo;
    });

    _safeInit(() {
      _customHomePage = prefs.getString('ff_customHomePage') ?? _customHomePage;
    });

    _safeInit(() {
      _empresaRaw = prefs.getString('ff_empresaRaw') ?? _empresaRaw;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _firma = '';
  String get firma => _firma;
  set firma(String value) {
    _firma = value;
    prefs.setString('ff_firma', value);
  }

  String _lookerStudio = '';
  String get lookerStudio => _lookerStudio;
  set lookerStudio(String value) {
    _lookerStudio = value;
    prefs.setString('ff_lookerStudio', value);
  }

  String _loaderLogo = '';
  String get loaderLogo => _loaderLogo;
  set loaderLogo(String value) {
    _loaderLogo = value;
    prefs.setString('ff_loaderLogo', value);
    notifyListeners();
  }

  String _clienteEquipo = '';
  String get clienteEquipo => _clienteEquipo;
  set clienteEquipo(String value) {
    _clienteEquipo = value;
    prefs.setString('ff_clienteEquipo', value);
  }

  String _clientId = '';
  String get clientId => _clientId;
  set clientId(String value) {
    _clientId = value;
    prefs.setString('ff_clientId', value);
  }

  String _organizacion = '';
  String get organizacion => _organizacion;
  set organizacion(String value) {
    _organizacion = value;
    prefs.setString('ff_organizacion', value);
    notifyListeners();
  }

  String _empresaRaw = '';
  String get empresaRaw => _empresaRaw;
  set empresaRaw(String value) {
    _empresaRaw = value;
    prefs.setString('ff_empresaRaw', value);
  }

  String _token = '';
  String get token => _token;
  set token(String value) {
    _token = value;
    prefs.setString('ff_token', value);
    notifyListeners();
  }

  String _refreshToken = '';
  String get refreshToken => _refreshToken;
  set refreshToken(String value) {
    _refreshToken = value;
    prefs.setString('ff_refreshToken', value);
  }

  String _loginUser = '';
  String get loginUser => _loginUser;
  set loginUser(String value) {
    _loginUser = value;
    prefs.setString('ff_loginUser', value);
  }

  String _loginPassword = '';
  String get loginPassword => _loginPassword;
  set loginPassword(String value) {
    _loginPassword = value;
    prefs.setString('ff_loginPassword', value);
  }

  int _unreadNotifications = 0;
  int get unreadNotifications => _unreadNotifications;
  set unreadNotifications(int value) {
    _unreadNotifications = value;
    prefs.setInt('ff_unreadNotifications', value);
  }

  int _pendingTasks = 0;
  int get pendingTasks => _pendingTasks;
  set pendingTasks(int value) {
    _pendingTasks = value;
    prefs.setInt('ff_pendingTasks', value);
  }

  String _id = '';
  String get id => _id;
  set id(String value) {
    _id = value;
    prefs.setString('ff_id', value);
  }

  String _username = '';
  String get username => _username;
  set username(String value) {
    _username = value;
    prefs.setString('ff_username', value);
  }

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
    prefs.setString('ff_email', value);
  }

  String _fullName = '';
  String get fullName => _fullName;
  set fullName(String value) {
    _fullName = value;
    prefs.setString('ff_fullName', value);
  }

  String _avatar = '';
  String get avatar => _avatar;
  set avatar(String value) {
    _avatar = value;
    prefs.setString('ff_avatar', value);
  }

  String _shortname = '';
  String get shortname => _shortname;
  set shortname(String value) {
    _shortname = value;
    prefs.setString('ff_shortname', value);
  }

  String _role = '';
  String get role => _role;
  set role(String value) {
    _role = value;
    prefs.setString('ff_role', value);
  }

  List<dynamic> _roleGroups = [];
  List<dynamic> get roleGroups => _roleGroups;
  set roleGroups(List<dynamic> value) {
    _roleGroups = value;
    prefs.setStringList(
        'ff_roleGroups', value.map((x) => jsonEncode(x)).toList());
  }

  void addToRoleGroups(dynamic value) {
    roleGroups.add(value);
    prefs.setStringList(
        'ff_roleGroups', _roleGroups.map((x) => jsonEncode(x)).toList());
  }

  void removeFromRoleGroups(dynamic value) {
    roleGroups.remove(value);
    prefs.setStringList(
        'ff_roleGroups', _roleGroups.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromRoleGroups(int index) {
    roleGroups.removeAt(index);
    prefs.setStringList(
        'ff_roleGroups', _roleGroups.map((x) => jsonEncode(x)).toList());
  }

  void updateRoleGroupsAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    roleGroups[index] = updateFn(_roleGroups[index]);
    prefs.setStringList(
        'ff_roleGroups', _roleGroups.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInRoleGroups(int index, dynamic value) {
    roleGroups.insert(index, value);
    prefs.setStringList(
        'ff_roleGroups', _roleGroups.map((x) => jsonEncode(x)).toList());
  }

  List<String> _permissions = [];
  List<String> get permissions => _permissions;
  set permissions(List<String> value) {
    _permissions = value;
    prefs.setStringList('ff_permissions', value);
    notifyListeners();
  }

  void addToPermissions(String value) {
    update(() {
      _permissions.add(value);
      prefs.setStringList('ff_permissions', _permissions);
    });
  }

  void removeFromPermissions(String value) {
    update(() {
      _permissions.remove(value);
      prefs.setStringList('ff_permissions', _permissions);
    });
  }

  void removeAtIndexFromPermissions(int index) {
    update(() {
      _permissions.removeAt(index);
      prefs.setStringList('ff_permissions', _permissions);
    });
  }

  void updatePermissionsAtIndex(int index, String Function(String) updateFn) {
    update(() {
      _permissions[index] = updateFn(_permissions[index]);
      prefs.setStringList('ff_permissions', _permissions);
    });
  }

  void insertAtIndexInPermissions(int index, String value) {
    update(() {
      _permissions.insert(index, value);
      prefs.setStringList('ff_permissions', _permissions);
    });
  }

  List<String> _modulesPermissions = [];
  List<String> get modulesPermissions => _modulesPermissions;

  set modulesPermissions(List<String> value) {
    _modulesPermissions = value;
    prefs.setStringList('ff_modulesPermissions', value);
    notifyListeners();
  }

  void addToModulesPermissions(String value) {
    update(() {
      _modulesPermissions.add(value);
      prefs.setStringList('ff_modulesPermissions', _modulesPermissions);
    });
  }

  void removeFromModulesPermissions(String value) {
    update(() {
      _modulesPermissions.remove(value);
      prefs.setStringList('ff_modulesPermissions', _modulesPermissions);
    });
  }

  void removeAtIndexFromModulesPermissions(int index) {
    update(() {
      _modulesPermissions.removeAt(index);
      prefs.setStringList('ff_modulesPermissions', _modulesPermissions);
    });
  }

  void updateModulesPermissionsAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    update(() {
      _modulesPermissions[index] = updateFn(_modulesPermissions[index]);
      prefs.setStringList('ff_modulesPermissions', _modulesPermissions);
    });
  }

  void insertAtIndexInModulesPermissions(int index, String value) {
    update(() {
      _modulesPermissions.insert(index, value);
      prefs.setStringList('ff_modulesPermissions', _modulesPermissions);
    });
  }

  List<dynamic> _recientes = [];
  List<dynamic> get recientes => _recientes;
  set recientes(List<dynamic> value) {
    _recientes = value;
    prefs.setStringList(
        'ff_recientes', value.map((x) => jsonEncode(x)).toList());
  }

  void addToRecientes(dynamic value) {
    recientes.add(value);
    prefs.setStringList(
        'ff_recientes', _recientes.map((x) => jsonEncode(x)).toList());
  }

  void removeFromRecientes(dynamic value) {
    recientes.remove(value);
    prefs.setStringList(
        'ff_recientes', _recientes.map((x) => jsonEncode(x)).toList());
  }

  void removeAtIndexFromRecientes(int index) {
    recientes.removeAt(index);
    prefs.setStringList(
        'ff_recientes', _recientes.map((x) => jsonEncode(x)).toList());
  }

  void updateRecientesAtIndex(
    int index,
    dynamic Function(dynamic) updateFn,
  ) {
    recientes[index] = updateFn(_recientes[index]);
    prefs.setStringList(
        'ff_recientes', _recientes.map((x) => jsonEncode(x)).toList());
  }

  void insertAtIndexInRecientes(int index, dynamic value) {
    recientes.insert(index, value);
    prefs.setStringList(
        'ff_recientes', _recientes.map((x) => jsonEncode(x)).toList());
  }

  List<dynamic> _moduleList = [];
  List<dynamic> get moduleList => _moduleList;
  set moduleList(List<dynamic> value) {
    _moduleList = value;
    prefs.setStringList(
        'ff_moduleList', value.map((x) => jsonEncode(x)).toList());
    notifyListeners();
  }

  void addToModuleList(dynamic value) {
    update(() {
      _moduleList.add(value);
      prefs.setStringList(
        'ff_moduleList',
        _moduleList.map((x) => jsonEncode(x)).toList(),
      );
    });
  }

  void removeFromModuleList(dynamic value) {
    update(() {
      _moduleList.remove(value);
      prefs.setStringList(
        'ff_moduleList',
        _moduleList.map((x) => jsonEncode(x)).toList(),
      );
    });
  }

  void removeAtIndexFromModuleList(int index) {
    update(() {
      _moduleList.removeAt(index);
      prefs.setStringList(
        'ff_moduleList',
        _moduleList.map((x) => jsonEncode(x)).toList(),
      );
    });
  }

  void updateModuleListAtIndex(int index, dynamic Function(dynamic) updateFn) {
    update(() {
      _moduleList[index] = updateFn(_moduleList[index]);
      prefs.setStringList(
        'ff_moduleList',
        _moduleList.map((x) => jsonEncode(x)).toList(),
      );
    });
  }

  void insertAtIndexInModuleList(int index, dynamic value) {
    update(() {
      _moduleList.insert(index, value);
      prefs.setStringList(
        'ff_moduleList',
        _moduleList.map((x) => jsonEncode(x)).toList(),
      );
    });
  }

  List<dynamic> _textoControlador = [];
  List<dynamic> get textoControlador => _textoControlador;
  set textoControlador(List<dynamic> value) {
    _textoControlador = value;
    notifyListeners();
    prefs.setStringList(
        'ff_textoControlador', value.map((x) => jsonEncode(x)).toList());
  }

  void addToTextoControlador(String texto, TextControllerNotifier controlador) {
    textoControlador.add([texto, controlador.value]);
    notifyListeners();
    prefs.setStringList('ff_textoControlador',
        _textoControlador.map((x) => jsonEncode(x)).toList());
  }

  void removeFromTextoControlador(int index) {
    textoControlador.removeAt(index);
    notifyListeners();
    prefs.setStringList('ff_textoControlador',
        _textoControlador.map((x) => jsonEncode(x)).toList());
  }

  void updateTextoControladorAtIndex(
      int index, String texto, TextEditingController controlador) {
    textoControlador[index] = [texto, controlador.text];
    notifyListeners();
    prefs.setStringList('ff_textoControlador',
        _textoControlador.map((x) => jsonEncode(x)).toList());
  }

  void clearTextoControladores() {
    _textoControlador.clear();
    notifyListeners();
    prefs.setStringList('ff_textoControlador', []);
  }

  String _logoLink = '';
  String get logoLink => _logoLink;
  set logoLink(String value) {
    _logoLink = value;
    prefs.setString('ff_logolink', value);
    notifyListeners();
  }

  String _fondoLink = '';
  String get fondoLink => _fondoLink;
  set fondoLink(String value) {
    _fondoLink = value;
    prefs.setString('ff_fondolink', value);
    notifyListeners();
  }

  // Modo chat estilo Telegram. 'true' => la app abre directamente en /chatMode.
  // Se persiste en SharedPreferences (localStorage en web) para preservar el
  // modo entre cierres y aperturas de la app.
  String _chatMode = '';
  String get chatMode => _chatMode;
  set chatMode(String value) {
    _chatMode = value;
    prefs.setString('ff_chatmode', value);
  }

  bool get isChatModeActive => _chatMode == 'true';

  String _simpleApp = '';
  String get simpleApp => _simpleApp;
  set simpleApp(String value) {
    _simpleApp = value;
    prefs.setString('ff_simpleapp', value);
  }

  String _simpleAppRole = '';
  String get simpleAppRole => _simpleAppRole;
  set simpleAppRole(String value) {
    _simpleAppRole = value;
    prefs.setString('ff_simpleapprole', value);
  }

  String _simpleAppSlugModule = '';
  String get simpleAppSlugModule => _simpleAppSlugModule;
  set simpleAppSlugModule(String value) {
    _simpleAppSlugModule = value;
    prefs.setString('ff_simpleappslugmodule', value);
  }

  String _simpleAppSlugFecha = '';
  String get simpleAppSlugFecha => _simpleAppSlugFecha;
  set simpleAppSlugFecha(String value) {
    _simpleAppSlugFecha = value;
    prefs.setString('ff_simpleappslugfecha', value);
  }

  String _simpleAppSlugFormato = '';
  String get simpleAppSlugFormato => _simpleAppSlugFormato;
  set simpleAppSlugFormato(String value) {
    _simpleAppSlugFormato = value;
    prefs.setString('ff_simpleappslugformato', value);
  }

  String _simpleAppSlugUserAsignado = '';
  String get simpleAppSlugUserAsignado => _simpleAppSlugUserAsignado;
  set simpleAppSlugUserAsignado(String value) {
    _simpleAppSlugUserAsignado = value;
    prefs.setString('ff_simpleappsluguserasignado', value);
  }

  //Nuevos campos de configuración

  String _simpleSlugFilter = '';
  String get simpleSlugFilter => _simpleSlugFilter;
  set simpleSlugFilter(String value) {
    _simpleSlugFilter = value;
    prefs.setString('ff_simpleslugfilter', value);
  }

  String _simpleValueFilter = '';
  String get simpleValueFilter => _simpleValueFilter;
  set simpleValueFilter(String value) {
    _simpleValueFilter = value;
    prefs.setString('ff_simplevaluefilter', value);
  }

  String _simpleSlugAsignado = '';
  String get simpleSlugAsignado => _simpleSlugAsignado;
  set simpleSlugAsignado(String value) {
    _simpleSlugAsignado = value;
    prefs.setString('ff_simpleslugasignado', value);
  }

  String _simpleSlugRepeater = '';
  String get simpleSlugRepeater => _simpleSlugRepeater;
  set simpleSlugRepeater(String value) {
    _simpleSlugRepeater = value;
    prefs.setString('ff_simpleslugrepeater', value);
  }

  String _simpleSlugRepeaterLabel = '';
  String get simpleSlugRepeaterLabel => _simpleSlugRepeaterLabel;
  set simpleSlugRepeaterLabel(String value) {
    _simpleSlugRepeaterLabel = value;
    prefs.setString('ff_simpleslugrepeaterlabel', value);
  }

  String _simpleSlugRepeaterBoolean = '';
  String get simpleSlugRepeaterBoolean => _simpleSlugRepeaterBoolean;
  set simpleSlugRepeaterBoolean(String value) {
    _simpleSlugRepeaterBoolean = value;
    prefs.setString('ff_simpleslugrepeaterboolean', value);
  }

  String _simpleSlugRepeaterRelated = '';
  String get simpleSlugRepeaterRelated => _simpleSlugRepeaterRelated;
  set simpleSlugRepeaterRelated(String value) {
    _simpleSlugRepeaterRelated = value;
    prefs.setString('ff_simpleslugrepeaterrelated', value);
  }

  String _customHomePage = '';
  String get customHomePage => _customHomePage;
  set customHomePage(String value) {
    _customHomePage = value;
    prefs.setString('ff_customHomePage', value);
  }

  // Deep link: módulo destino tras pago de Mercado Pago (no persistido)
  String _mpDeepLinkModuleName = '';
  String get mpDeepLinkModuleName => _mpDeepLinkModuleName;
  set mpDeepLinkModuleName(String value) => _mpDeepLinkModuleName = value;

  int _mpDeepLinkRecordId = 0;
  int get mpDeepLinkRecordId => _mpDeepLinkRecordId;
  set mpDeepLinkRecordId(int value) => _mpDeepLinkRecordId = value;

  // URI completa del deep link (se pierde en GoRouter redirect)
  Uri? _mpDeepLinkUri;
  Uri? get mpDeepLinkUri => _mpDeepLinkUri;
  set mpDeepLinkUri(Uri? value) => _mpDeepLinkUri = value;

  void clearMpDeepLink() {
    _mpDeepLinkModuleName = '';
    _mpDeepLinkRecordId = 0;
    _mpDeepLinkUri = null;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
