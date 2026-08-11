import 'package:flutter_test/flutter_test.dart';
import 'package:transport_app/pages/chat_mode/widgets/chat_widgets.dart';

/// El servidor manda tres formas distintas bajo la misma clave
/// `proposed_changes`, y la tarjeta las pintaba todas como si fueran una lista
/// plana de cambios. Un lote acababa mostrando una fila "null" por registro y
/// ningun valor: parecia funcionar y no decia nada.
void main() {
  group('formas de proposed_changes', () {
    final singleAction = <String, dynamic>{
      'action_id': 'a-1',
      'action_type': 'update_record',
      'module_label': 'Obras',
      'proposed_changes': [
        {'slug': 'estado', 'label': 'Estado', 'from': 'Abierto', 'to': 'Cerrado'},
      ],
    };

    final batchAction = <String, dynamic>{
      'action_id': 'a-2',
      'action_type': 'bulk_update',
      'module_label': 'Obras',
      'is_batch': true,
      'record_count': 2,
      'proposed_changes': [
        {
          'record_id': 12,
          'record_title': 'Obra Norte',
          'changes': [
            {'slug': 'estado', 'label': 'Estado', 'from': 'Abierto', 'to': 'Cerrado'},
          ],
        },
        {
          'record_id': null,
          'fallback_title': 'Obra nueva',
          'changes': [
            {'slug': 'estado', 'label': 'Estado', 'from': null, 'to': 'Abierto'},
          ],
        },
      ],
    };

    final planAction = <String, dynamic>{
      'action_id': 'a-3',
      'action_type': 'api_plan',
      'module_label': 'Configuración',
      'is_plan': true,
      'step_count': 2,
      'proposed_changes': [
        {
          'method': 'POST',
          'path': '/api/v2/modulos/',
          'label': 'Crear el módulo Obras',
        },
        {'method': 'DELETE', 'path': '/api/v2/custom-fields/42/'},
      ],
    };

    test('un lote se lee como bloques por registro, no como cambios sueltos', () {
      final items = batchItemsOfAction(batchAction);

      expect(items, hasLength(2));
      expect(items.first['record_title'], 'Obra Norte');
      expect((items.first['changes'] as List).first['slug'], 'estado');
      // El alta del lote no trae registro previo: se identifica por su titulo.
      expect(items.last['record_id'], isNull);
      expect(items.last['fallback_title'], 'Obra nueva');
    });

    test('un plan se lee como pasos con metodo y ruta', () {
      final steps = planStepsOfAction(planAction);

      expect(steps, hasLength(2));
      expect(steps.first['method'], 'POST');
      expect(steps.first['label'], 'Crear el módulo Obras');
      expect(steps.last['method'], 'DELETE');
    });

    test('cada forma solo responde a su propio lector', () {
      // Esto es lo que fallaba: el lector plano se tragaba los lotes.
      expect(flatChangesOfAction(batchAction), isEmpty);
      expect(flatChangesOfAction(planAction), isEmpty);
      expect(batchItemsOfAction(singleAction), isEmpty);
      expect(planStepsOfAction(singleAction), isEmpty);
      expect(flatChangesOfAction(singleAction), hasLength(1));
    });

    test('el titular dice de que se trata sin mentir', () {
      expect(actionHeadline(singleAction), 'Actualizar registro');
      expect(actionHeadline(batchAction), '2 cambios');
      expect(actionHeadline(planAction), '2 cambios de configuración');
    });

    test('una propuesta vieja sin las claves nuevas se sigue leyendo', () {
      // Los mensajes ya guardados no traen `is_batch` ni `is_plan`.
      final legacy = <String, dynamic>{
        'action_id': 'a-4',
        'action_type': 'update_record',
        'proposed_changes': [
          {'slug': 'estado', 'from': 'Abierto', 'to': 'Cerrado'},
        ],
      };

      expect(flatChangesOfAction(legacy), hasLength(1));
      expect(batchItemsOfAction(legacy), isEmpty);
      expect(planStepsOfAction(legacy), isEmpty);
    });
  });

  group('resumen de la confirmación escrita', () {
    test('sin resolucion no dice nada', () {
      expect(writtenDecisionSummary(null), isNull);
      expect(writtenDecisionSummary(<String, dynamic>{}), isNull);
    });

    test('cuenta cuantas cerro el mensaje', () {
      final summary = writtenDecisionSummary(<String, dynamic>{
        'resolved_action': {
          'status': 'batch_applied',
          'decision': 'confirm',
          'applied': 3,
        },
      });

      expect(summary, 'Query aplicó 3 propuestas con este mensaje.');
    });

    test('un lote a medias lo dice en vez de darlo por cerrado', () {
      final summary = writtenDecisionSummary(<String, dynamic>{
        'resolved_action': {
          'status': 'batch_partial',
          'decision': 'confirm',
          'applied': 2,
          'requested': 3,
        },
      });

      expect(summary, contains('2 de 3'));
      expect(summary, contains('pendiente'));
    });

    test('sin permiso avisa que sigue pendiente', () {
      final summary = writtenDecisionSummary(<String, dynamic>{
        'resolved_action': {'status': 'not_allowed', 'decision': 'confirm'},
      });

      expect(summary, contains('sigue pendiente'));
    });
  });
}
