import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '../types/cohet_home_config.dart';
import '../types/cohet_module.dart';
import 'module_tile.dart';

class ModulesSection extends StatelessWidget {
  final Map<String, CohetModule> resolvedModules;
  final bool isLoading;
  final void Function(CohetModule module) onModuleTap;

  const ModulesSection({
    super.key,
    required this.resolvedModules,
    required this.isLoading,
    required this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(),
          const SizedBox(height: 16),
          if (isLoading)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 16) / 2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: CohetHomeConfig.modules.map(
                    (configModule) {
                      final resolved = resolvedModules[configModule.slug];
                      final displayModule = resolved ?? configModule;

                      return ModuleTile(
                        module: displayModule,
                        size: tileWidth,
                        onTap: resolved != null
                            ? () => onModuleTap(resolved)
                            : null,
                      );
                    },
                  ).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                theme.primary.withValues(alpha: 0.20),
                theme.secondary.withValues(alpha: 0.24),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.dashboard_outlined,
            color: theme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CohetHomeConfig.modulesSectionTitle,
                style: theme.titleLarge.override(
                  fontFamily: 'Roboto',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.0,
                ),
              ),
              Text(
                CohetHomeConfig.modulesSectionSubtitle,
                style: theme.bodySmall,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 4),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            '${CohetHomeConfig.modules.length}',
            style: theme.labelSmall.override(
              fontFamily: 'Roboto',
              color: theme.primary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.0,
            ),
          ),
        ),
      ],
    );
  }
}
