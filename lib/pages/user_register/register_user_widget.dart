import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:transport_app/backend/api_requests/api_calls.dart';
import 'package:transport_app/flutter_flow/flutter_flow_theme.dart';
import 'package:transport_app/login_equipo/widgets/widgets.dart';

import '../../app_state.dart';

class RegistrationUserScreen extends StatefulWidget {
  RegistrationUserScreen({
    super.key,
    this.publicRoles = const [],
  });

  List<dynamic> publicRoles;

  static String routeName = 'RegisterUserAntonio';
  static String routePath = '/RegisterUserAntonio';

  @override
  State<RegistrationUserScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationUserScreen> {
  String? selectedRoleId;

  List<AllowedRole> get roles =>
      widget.publicRoles.map((e) => AllowedRole.fromJson(e)).toList();

  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Correo obligatorio';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Correo no válido';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Contraseña obligatoria';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordCtrl.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final response = await RegisterUserCall.call(
      tenant: FFAppState().organizacion,
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      email: _emailCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
      groups: [selectedRoleId],
      jsonData: {},
    );

    setState(() => isSubmitting = false);

    if (response.statusCode == 201) {
      final returnPayload = {
        ...response.jsonBody,
        'password': _passwordCtrl.text,
      };
      debugPrint('[REGISTER] Devolviendo payload: $returnPayload');
      Navigator.pop(context, returnPayload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background image + blur
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    (FFAppState().fondoLink == '')
                        ? 'https://itsquery.com/mediafiles/auth/bg9-dark.jpg'
                        : FFAppState().fondoLink,
                  ),
                  fit: BoxFit.cover,
                  alignment: const AlignmentDirectional(-0.4, 0.5),
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
            // Subtle gradient overlay
            const Positioned.fill(
              child: AnimatedBackground(),
            ),
            // Scrollable content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            Form(
                              key: _formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: GlassAuthCard(
                                children: [
                                GlassLogoHeader(
                                  size: 100,
                                  blurHash: 'L9I5f1wf00~q-Vk;aKoL00we0000',
                                  imageProvider: const AssetImage(
                                      'assets/images/13.png'),
                                ),
                                const SizedBox(height: 24),
                                // Nombre completo
                                GlassTextField(
                                  controller: _fullNameCtrl,
                                  focusNode: _fullNameFocus,
                                  labelText: 'Nombre completo',
                                  prefixIcon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                  validator: _requiredValidator,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                          context)
                                      .requestFocus(_emailFocus),
                                ),
                                const SizedBox(height: 16),
                                // Correo
                                GlassTextField(
                                  controller: _emailCtrl,
                                  focusNode: _emailFocus,
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icons.email_outlined,
                                  textInputAction: TextInputAction.next,
                                  validator: _emailValidator,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                          context)
                                      .requestFocus(_usernameFocus),
                                ),
                                const SizedBox(height: 16),
                                // Username
                                GlassTextField(
                                  controller: _usernameCtrl,
                                  focusNode: _usernameFocus,
                                  labelText: 'Nombre de usuario',
                                  prefixIcon:
                                      Icons.account_circle_outlined,
                                  textInputAction: TextInputAction.next,
                                  validator: _requiredValidator,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                          context)
                                      .requestFocus(_passwordFocus),
                                ),
                                const SizedBox(height: 16),
                                // Contraseña
                                GlassTextField(
                                  controller: _passwordCtrl,
                                  focusNode: _passwordFocus,
                                  labelText: 'Contraseña',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: true,
                                  textInputAction: TextInputAction.next,
                                  validator: _passwordValidator,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                          context)
                                      .requestFocus(
                                          _confirmPasswordFocus),
                                ),
                                const SizedBox(height: 16),
                                // Confirmar contraseña
                                GlassTextField(
                                  controller: _confirmPasswordCtrl,
                                  focusNode: _confirmPasswordFocus,
                                  labelText: 'Confirme su contraseña',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  validator: _confirmPasswordValidator,
                                  onFieldSubmitted: (_) =>
                                      isSubmitting ? null : _submitForm(),
                                ),
                                const SizedBox(height: 16),
                                // Rol
                                _buildRoleDropdown(),
                                const SizedBox(height: 24),
                                // Botón registrar
                                GlassButton(
                                  onPressed:
                                      isSubmitting ? null : _submitForm,
                                  text: 'REGISTRARSE',
                                  isLoading: isSubmitting,
                                  icon: Icons.person_add,
                                ),
                                const SizedBox(height: 16),
                                // Botón atrás
                                GlassButton(
                                  onPressed: () =>
                                      Navigator.pop(context, null),
                                  text: 'ATRÁS',
                                  isPrimary: false,
                                  icon: Icons.chevron_left,
                                ),
                              ],
                            ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRolePicker(List<AllowedRole> roles, FormFieldState<String> state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = FlutterFlowTheme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1A2E).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Selecciona un rol',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : theme.primaryText,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...roles.map((role) {
                    final isSelected = selectedRoleId == role.id.toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRoleId = role.id.toString();
                            state.didChange(role.id.toString());
                          });
                          Navigator.pop(ctx);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primary.withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.white.withValues(alpha: 0.55)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.primary.withValues(alpha: 0.5)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.white.withValues(alpha: 0.45)),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? theme.primary
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.5)
                                            : theme.secondaryText),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      role.name,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : theme.primaryText,
                                        fontSize: 15,
                                        fontFamily: 'Outfit',
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleDropdown() {
    final roles =
        widget.publicRoles.map((e) => AllowedRole.fromJson(e)).toList();

    return FormField<String>(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Debes seleccionar un rol';
        }
        return null;
      },
      builder: (state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final theme = FlutterFlowTheme.of(context);
        final isEmpty = selectedRoleId == null;
        final selectedRole = isEmpty
            ? null
            : roles.firstWhere(
                (r) => r.id.toString() == selectedRoleId,
                orElse: () => roles.first,
              );

        return Animate(
          effects: const [
            FadeEffect(duration: Duration(milliseconds: 600)),
            SlideEffect(
              begin: Offset(0, 0.08),
              end: Offset.zero,
              duration: Duration(milliseconds: 600),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showRolePicker(roles, state),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: state.hasError
                              ? Colors.red.withValues(alpha: 0.7)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white.withValues(alpha: 0.45)),
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : theme.secondaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEmpty ? 'Escoge un rol' : selectedRole!.name,
                              style: TextStyle(
                                color: isEmpty
                                    ? (isDark
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : theme.secondaryText)
                                    : (isDark
                                        ? Colors.white
                                        : theme.primaryText),
                                fontSize: isEmpty ? 14 : 15,
                                fontFamily: isEmpty ? 'Lexend Deca' : 'Outfit',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : theme.secondaryText,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class PublicRegistrationSettings {
  final bool enabled;
  final List<AllowedRole> allowedRoles;

  PublicRegistrationSettings({
    required this.enabled,
    required this.allowedRoles,
  });

  factory PublicRegistrationSettings.fromJson(Map<String, dynamic> json) {
    return PublicRegistrationSettings(
      enabled: json['enabled'] as bool,
      allowedRoles: (json['allowed_roles'] as List<dynamic>)
          .map((e) => AllowedRole.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AllowedRole {
  final int id;
  final String name;
  final List<dynamic> permissions;
  final String? description;

  AllowedRole({
    required this.id,
    required this.name,
    required this.permissions,
    this.description,
  });

  factory AllowedRole.fromJson(Map<String, dynamic> json) {
    return AllowedRole(
      id: json['id'] as int,
      name: json['name'] as String,
      permissions: json['permissions'] as List<dynamic>? ?? [],
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'permissions': permissions,
        'description': description,
      };
}
