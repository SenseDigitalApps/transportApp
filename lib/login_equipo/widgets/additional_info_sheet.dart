import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';

class AdditionalInfoSheetWidget extends StatelessWidget {
  final List<AdditionalInfoAlert> alerts;

  const AdditionalInfoSheetWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: FlutterFlowTheme.of(context).warning, size: 28),
              const SizedBox(width: 12),
              Text(
                'Completar información',
                style: FlutterFlowTheme.of(context).titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Los siguientes módulos tienen información incompleta:',
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
          const SizedBox(height: 20),
          ...alerts.map((alert) => _buildAlertTile(context, alert)),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Omitir'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, AdditionalInfoAlert alert) {
    final percent = (alert.completenessPercent * 100).round();
    final missing = alert.missingFields.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FlutterFlowTheme.of(context).alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.moduleLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$percent% completado · $missing faltante${missing != 1 ? 's' : ''}',
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(alert.moduleName);
                },
                child: const Text('Completar ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
