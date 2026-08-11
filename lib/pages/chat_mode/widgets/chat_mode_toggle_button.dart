import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transport_app/app_state.dart';
import 'package:transport_app/flutter_flow/flutter_flow_theme.dart';

/// Boton compacto que activa el modo chat y navega a /chatMode.
///
/// Pensado para ir en el AppBar, junto al menu burger (arriba a la izquierda).
/// Al activarlo persiste el modo (SharedPreferences), asi al reabrir la app se
/// entra directamente al chat.
class ChatModeToggleButton extends StatelessWidget {
  const ChatModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return IconButton(
      tooltip: 'Modo chat',
      iconSize: 22.0,
      icon: Icon(Icons.forum_outlined, color: theme.primary),
      onPressed: () {
        FFAppState().chatMode = 'true';
        context.goNamed('chatMode');
      },
    );
  }
}

/// Leading para AppBar que combina el boton de menu (abre el Drawer) con el
/// boton de modo chat, manteniendo el burger en su lugar habitual.
class ChatModeLeading extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ChatModeLeading({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Menu',
          icon: Icon(Icons.menu, color: theme.primary),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        const ChatModeToggleButton(),
      ],
    );
  }
}
