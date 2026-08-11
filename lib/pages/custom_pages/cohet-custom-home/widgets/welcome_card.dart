import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart';
import '/widgets/cached_avatar_image.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              theme.primary.withValues(alpha: 0.36),
              theme.secondary.withValues(alpha: 0.40),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: theme.primary.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BIENVENIDOS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.labelLarge.override(
                      fontFamily: 'Outfit',
                      color: theme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FFAppState().fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleMedium.override(
                      fontFamily: 'Outfit',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRoleBadge(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(FlutterFlowTheme theme) {
    return Container(
      width: 78,
      height: 78,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.primaryBackground,
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.28),
          width: 1.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedAvatarImage(
          imageUrl: buildMediaUrl(FFAppState().avatar),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/app_launcher_icon.png',
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleBadge(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        FFAppState().role,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.bodySmall.override(
          fontFamily: 'Outfit',
          color: theme.secondaryText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.0,
        ),
      ),
    );
  }
}
