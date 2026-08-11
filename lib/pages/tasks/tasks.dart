import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../components/page_components/screens_background/background_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';



class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});
  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<dynamic> allTasks = [];

  String scope = 'assigned'; // 'assigned' (para mí) | 'created' (asignadas por mí)
  String filter = 'pending'; // 'pending' | 'all' | 'done'


  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Widget _buildEmptyTasksState(BuildContext context) {
    // Mensajes según scope + filtro
    final bool isAssigned = scope == 'assigned';
    final bool isPending = filter == 'pending';
    final bool isDone = filter == 'done';

    String title;
    String subtitle;
    IconData icon;

    if (isAssigned) {
      if (isPending) {
        title = 'No tienes tareas pendientes';
        subtitle = 'Cuando alguien te asigne una tarea, aparecerá aquí.';
        icon = Icons.inbox_outlined;
      } else if (isDone) {
        title = 'Aún no terminas tareas';
        subtitle = 'Cuando completes alguna tarea, la verás en esta lista.';
        icon = Icons.task_alt_outlined;
      } else {
        title = 'No tienes tareas';
        subtitle = 'Todavía no hay tareas asignadas para ti.';
        icon = Icons.checklist_rtl_outlined;
      }
    } else {
      // created
      if (isPending) {
        title = 'No has asignado tareas pendientes';
        subtitle = 'Las tareas que asignes a otros y estén pendientes se verán aquí.';
        icon = Icons.assignment_ind_outlined;
      } else if (isDone) {
        title = 'No hay tareas terminadas';
        subtitle = 'Cuando las tareas asignadas por ti se completen, aparecerán aquí.';
        icon = Icons.verified_outlined;
      } else {
        title = 'No has asignado tareas';
        subtitle = 'Crea o asigna tareas para que se reflejen en esta pantalla.';
        icon = Icons.playlist_add_outlined;
      }
    }

    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.secondaryBackground.withOpacity(0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12.withOpacity(0.0)),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.08),
            //     blurRadius: 18,
            //     offset: const Offset(0, 10),
            //   ),
            // ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.primary, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.bodySmall.copyWith(
                  color: Colors.black54,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: fetchTasks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Recargar'),
                    ),
                  ),
                ],
              ),

              if (filter != 'all') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => filter = 'all'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Ver todas'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim());

    if (v is Map) {
      // cubre: {id}, {value}, {pk}, {user_id}
      final id = v['id'] ?? v['value'] ?? v['pk'] ?? v['user_id'];
      if (id is int) return id;
      if (id is double) return id.toInt();
      if (id is String) return int.tryParse(id.trim());
    }

    return null;
  }



  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'approved':
        return Colors.blue;
      case 'denied':
        return Colors.red;
      case 'returned':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.amber;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Terminada';
      case 'approved':
        return 'Aprobada';
      case 'denied':
        return 'Denegada';
      case 'returned':
        return 'Devuelta';
      case 'pending':
      default:
        return 'Pendiente';
    }
  }

  Future<void> _setStatusAndRefresh(String id, String status) async {
    final resp = await PostTaskSetStatus.call(
      tenant: FFAppState().organizacion,
      token: FFAppState().token,
      id: id,
      status: status,
    );

    if (resp.succeeded) {
      await fetchTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado', style: TextStyle(color: FlutterFlowTheme.of(context).white)),
          backgroundColor: FlutterFlowTheme.of(context).primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar', style: TextStyle(color: FlutterFlowTheme.of(context).white)),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  Widget _buildTaskTile(BuildContext context, dynamic task) {
    final status = (task['status'] ?? 'pending').toString();
    final isDone = status == 'done';

    final title = (task['title'] ?? 'Sin título').toString();
    final desc = (task['description'] ?? '').toString();

    final originModule = task['origin_module_name']?.toString();
    final originLabel = task['origin_record_label']?.toString();

    final due = _parseTaskDate(task['due_at']);
    final dueText = due != null ? DateFormat('dd MMM, hh:mm a', 'es_CO').format(due) : null;

    return InkWell(
      onTap: () async {
        // abre link como en notifications (usa link u origin_link)
        final url = (task['link'] ?? task['origin_link'] ?? '').toString();
        if (url.isEmpty) return;

        try {
          RegExp regExp = RegExp(r'#(\w+)');
          String? hashValue = regExp.firstMatch(url)?.group(1);

          Uri uri = Uri.parse("https://${FFAppState().organizacion}.itsquery.com$url");
          String? filterModule = uri.queryParameters["filter_module"];

          if (hashValue == null) throw Exception("No se encontró un ID válido en la URL");

          if (hashValue != "new") {
            // url ejemplo: /apps/master-table/master/?filter_module=xxx#105
            final rawUrl = (task['link'] ?? task['origin_link'] ?? '').toString(); // o notification['link']
            if (rawUrl.isEmpty) return;

// 1) hashValue (#105)
            final hashValue = RegExp(r'#(\w+)').firstMatch(rawUrl)?.group(1);
            if (hashValue == null) throw Exception("No se encontró un ID válido en la URL");

// 2) armamos uri absoluta para leer path/query sin problemas
            final uri = Uri.parse("https://${FFAppState().organizacion}.itsquery.com$rawUrl");
            final path = uri.path; // ej: /apps/master-table/master/
            final filterModule = uri.queryParameters["filter_module"];

// 3) NEW -> formulario
            if (hashValue == "new") {
              context.pushNamed(
                'newRegistersModule',
                queryParameters: {'moduleName': filterModule}.withoutNulls,
              );
              return;
            }

// 4) ✅ decidir si es master-table
            final isMaster = path.contains('/apps/master-table/');

// 5) ✅ call correcto
            final projectData = isMaster
                ? await GetDataMastersCall.call(
              tenant: FFAppState().organizacion,
              token: FFAppState().token,
              id: hashValue,
            )
                : await GetDataRegistersCall.call(
              tenant: FFAppState().organizacion,
              token: FFAppState().token,
              id: hashValue,
            );

            if (projectData.jsonBody == null) {
              throw Exception("No se pudo obtener información del registro");
            }

            context.pushNamed(
              'detailGrouped',
              queryParameters: {
                'title': serializeParam('a', ParamType.String),
                'body': serializeParam('aa', ParamType.String),
                'general': serializeParam(projectData.jsonBody, ParamType.JSON),
              }.withoutNulls,
            );

          } else {
            context.pushNamed(
              'newRegistersModule',
              queryParameters: {'moduleName': filterModule}.withoutNulls,
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}', style: TextStyle(color: FlutterFlowTheme.of(context).white)),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // status dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6, right: 10),
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
              ),
            ),

            // content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // status chip + due
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (dueText != null)
                        Text(
                          'Vence: $dueText',
                          style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.copyWith(color: Colors.black54),
                    ),
                  ],

                  if ((originModule != null && originModule.isNotEmpty) ||
                      (originLabel != null && originLabel.isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${originModule ?? ''}${originModule != null && originLabel != null ? ' • ' : ''}${originLabel ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.copyWith(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Terminar button (distinto si ya está done)
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: isDone ? null : () => _setStatusAndRefresh(task['id'].toString(), 'done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? Colors.grey.shade300 : Colors.green,
                  foregroundColor: isDone ? Colors.grey.shade700 : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(isDone ? 'Terminada' : 'Terminar'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  DateTime? _parseTaskDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;

    if (raw is String) {
      // 1) ISO (DRF): "2026-02-03T12:11:49Z" o "2026-02-03T07:11:49-05:00"
      try {
        return DateTime.parse(raw).toLocal();
      } catch (_) {}

      // 2) fallback (si alguna vez llega como el formato viejo)
      final r = RegExp(r'^(\d{1,2})\s([A-Za-z]{3})\s(\d{4}),\s(\d{1,2}):(\d{2})\s(AM|PM)$');
      final m = r.firstMatch(raw.trim());
      if (m == null) return null;

      final day = int.parse(m.group(1)!);
      final monStr = m.group(2)!;
      final year = int.parse(m.group(3)!);
      var hour = int.parse(m.group(4)!);
      final minute = int.parse(m.group(5)!);
      final ampm = m.group(6)!;

      final monthMap = {
        'Jan': 1,'Feb': 2,'Mar': 3,'Apr': 4,'May': 5,'Jun': 6,
        'Jul': 7,'Aug': 8,'Sep': 9,'Oct': 10,'Nov': 11,'Dec': 12,
      };
      final month = monthMap[monStr];
      if (month == null) return null;

      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    }

    return null;
  }


  DateTime? _parseNotificationDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;

    if (raw is String) {
      // Ej: "27 Jan 2026, 08:03 AM"
      final r = RegExp(
        r'^(\d{1,2})\s([A-Za-z]{3})\s(\d{4}),\s(\d{1,2}):(\d{2})\s(AM|PM)$',
      );
      final m = r.firstMatch(raw.trim());
      if (m == null) return null;

      final day = int.parse(m.group(1)!);
      final monStr = m.group(2)!;
      final year = int.parse(m.group(3)!);
      var hour = int.parse(m.group(4)!);
      final minute = int.parse(m.group(5)!);
      final ampm = m.group(6)!;

      final monthMap = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final month = monthMap[monStr];
      if (month == null) return null;

      // AM/PM -> 24h
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      // created_at parece “hora local”, entonces lo armamos en local
      return DateTime(year, month, day, hour, minute);
    }

    return null;
  }


  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime d) {
    // Semana empieza lunes
    final dayStart = _startOfDay(d);
    return dayStart.subtract(Duration(days: dayStart.weekday - 1));
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text,
        style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.black54,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, dynamic notification) {
    final bool isRead = notification['is_read'] ?? false;
    final sender = notification['sender_info'];

    return InkWell(
      onTap: () async {
        try {
          String url = notification['link'];

          RegExp regExp = RegExp(r'#(\w+)');
          String? hashValue = regExp.firstMatch(url)?.group(1);

          Uri uri = Uri.parse("https://${FFAppState().organizacion}.itsquery.com$url");
          String? filterModule = uri.queryParameters["filter_module"];

          if (hashValue == null) {
            throw Exception("No se encontró un ID válido en la URL");
          }

          if (hashValue != "new") {
            final path = uri.path; // ej: /apps/master-table/master/
            final isMaster = path.contains('/apps/master-table/');

            final projectData = isMaster
                ? await GetDataMastersCall.call(
              tenant: FFAppState().organizacion,
              token: FFAppState().token,
              id: hashValue,
            )
                : await GetDataRegistersCall.call(
              tenant: FFAppState().organizacion,
              token: FFAppState().token,
              id: hashValue,
            );

            if (projectData.jsonBody == null) {
              throw Exception("No se pudo obtener información del proyecto");
            }

            context.pushNamed(
              'detailGrouped',
              queryParameters: {
                'title': serializeParam('a', ParamType.String),
                'body': serializeParam('aa', ParamType.String),
                'general': serializeParam(projectData.jsonBody, ParamType.JSON),
              }.withoutNulls,
            );
          } else {
            context.pushNamed(
              'newRegistersModule',
              queryParameters: {'moduleName': filterModule}.withoutNulls,
            );
          }

          if (notification['is_read'] == false) {
            await PatchNotifications.call(
              tenant: FFAppState().organizacion,
              token: FFAppState().token,
              id: notification['id'].toString(),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Notificación marcada como leída',
                  style: TextStyle(color: FlutterFlowTheme.of(context).white),
                ),
                duration: const Duration(milliseconds: 4000),
                backgroundColor: FlutterFlowTheme.of(context).primary,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString()}',
                style: TextStyle(color: FlutterFlowTheme.of(context).white),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(context).error,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 20),

            CircleAvatar(
              radius: 22,
              backgroundImage: sender?['avatar'] != null
                  ? NetworkImage(
                'https://${FFAppState().organizacion}.itsquery.com${sender['avatar']}',
              )
                  : const AssetImage('assets/images/app_launcher_icon.png')
              as ImageProvider,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'De ${sender?['full_name'] ?? ''} • ${notification['created_at'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ IMPORTANTE: aquí NO ponemos nada (sin imagen derecha)
          ],
        ),
      ),
    );
  }


  Future<void> fetchTasks() async {
    try {
      final resp = await GetTasks.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
        itemsPerPage: 100,
        page: 1,
      );

      if (resp.succeeded) {
        // DRF suele devolver data/results. Normalizamos:
        final body = resp.jsonBody ?? {};
        final data = body['data'] ?? body['results'] ?? body;

        final list = (data is List) ? data : <dynamic>[];

        setState(() {
          allTasks = List<dynamic>.from(list);
        });

        // ✅ Badge (pendientes PARA MÍ, como en web)
        final myId = _toInt(FFAppState().id);

        final pendingForMe = list.where((t) {
          final assigneeId = _toInt(t['assignee']);
          final status = (t['status'] ?? '').toString();
          return status == 'pending' && myId != null && assigneeId == myId;
        }).length;

        setState(() {
          FFAppState().pendingTasks = pendingForMe;
        });

      }
    } catch (e) {
      print('Error fetchTasks: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    Color bottomLeftColor = FlutterFlowTheme.of(context).accent3.withOpacity(1);
    Color topRightColor = FlutterFlowTheme.of(context).primary.withOpacity(0.7);
    return Scaffold(
      body: Container(
          width: double.infinity,
          height: double.infinity,

          child: Stack(
            children: [

              DynamicBackground(
                bottomLeftColor: bottomLeftColor,
                topRightColor: topRightColor,
              ),

              Column(
                children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      onPressed: () {
                        appNavigatorKey.currentContext?.goNamed('home');
                      },
                    ),
                    centerTitle: true,

                    title: Text(
                      'Tareas',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0, // Elimina sombra del AppBar
                    iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => scope = 'assigned'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scope == 'assigned'
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).secondaryBackground,
                              foregroundColor: scope == 'assigned'
                                  ? Colors.white
                                  : FlutterFlowTheme.of(context).primaryText,
                              elevation: 0,
                            ),
                            child: const Text('Para mí'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => scope = 'created'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scope == 'created'
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).secondaryBackground,
                              foregroundColor: scope == 'created'
                                  ? Colors.white
                                  : FlutterFlowTheme.of(context).primaryText,
                              elevation: 0,
                            ),
                            child: const Text('Asignadas por mí'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => filter = 'pending'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: filter == 'pending'
                                  ? FlutterFlowTheme.of(context).primary.withOpacity(0.12)
                                  : Colors.transparent,
                            ),
                            child: const Text('Pendientes'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => filter = 'all'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: filter == 'all'
                                  ? FlutterFlowTheme.of(context).primary.withOpacity(0.12)
                                  : Colors.transparent,
                            ),
                            child: const Text('Todas'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => filter = 'done'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: filter == 'done'
                                  ? FlutterFlowTheme.of(context).primary.withOpacity(0.12)
                                  : Colors.transparent,
                            ),
                            child: const Text('Terminadas'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchTasks,
                      child: Builder(
                        builder: (context) {
                          final myId = _toInt(FFAppState().id);

                          // 1) scope (para mí / creadas por mí)
                          List<dynamic> scoped = allTasks.where((t) {
                            final assigneeId = _toInt(t['assignee']);
                            final creatorId = _toInt(t['creator']);

                            if (scope == 'assigned') return myId != null && assigneeId == myId;
                            return myId != null && creatorId == myId;
                          }).toList();
                          // 2) filtro estado
                          List<dynamic> filtered = scoped.where((t) {
                            if (filter == 'all') return true;
                            if (filter == 'done') return t['status'] == 'done';
                            // pending
                            return t['status'] == 'pending';
                          }).toList();

                          // 3) orden desc por created_at
                          filtered.sort((a, b) {
                            final da = _parseTaskDate(a['created_at']);
                            final db = _parseTaskDate(b['created_at']);
                            if (da == null && db == null) return 0;
                            if (da == null) return 1;
                            if (db == null) return -1;
                            return db.compareTo(da);
                          });

                          if (filtered.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 0),
                                _buildEmptyTasksState(context),
                              ],
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                            itemBuilder: (context, i) => _buildTaskTile(context, filtered[i]),
                          );
                        },
                      ),
                    ),
                  ),

                ],
              ),

            ],
          )
      ),
    );
  }
}
