import 'package:flutter/material.dart';
import 'package:transport_app/components/empty_component/empty_component_widget.dart';
import '../../components/page_components/screens_background/background_widget.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = []; // Lista de notificaciones

  @override
  void initState() {
    super.initState();
    fetchNotifications(); // Llamar API al iniciar la pantallaError al obtener las notificaciones:
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
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
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

  Future<void> _markNotificationRead(dynamic notification) async {
    if (notification['is_read'] != false) return;
    await PatchNotifications.call(
      tenant: FFAppState().organizacion,
      token: FFAppState().token,
      id: notification['id'].toString(),
    );
    if (!mounted) return;
    setState(() => notification['is_read'] = true);
    FFAppState().update(() {
      if (FFAppState().unreadNotifications > 0) {
        FFAppState().unreadNotifications--;
      }
    });
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
          String url = (notification['link'] ?? '').toString();
          final instanceData = notification['instance_data'];
          final isChatNotification =
              instanceData is Map && instanceData['type'] == 'openclaw_message';
          final notificationUri = Uri.tryParse(url);
          if (isChatNotification || notificationUri?.path == '/chatMode') {
            await _markNotificationRead(notification);
            if (!context.mounted) return;
            final route = url.startsWith('/')
                ? url
                : '/chatMode?threadId=${instanceData?['thread_id']}';
            context.go(route);
            return;
          }

          RegExp regExp = RegExp(r'#(\w+)');
          String? hashValue = regExp.firstMatch(url)?.group(1);

          Uri uri = Uri.parse(
              "https://${FFAppState().organizacion}.itsquery.com$url");
          String? filterModule = uri.queryParameters["filter_module"];

          if (hashValue == null) {
            throw Exception("No se encontró un ID válido en la URL");
          }

          if (hashValue != "new") {
            final seg = uri.pathSegments;
            final isMaster =
                seg.length >= 2 && seg[0] == 'apps' && seg[1] == 'master-table';

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

          await _markNotificationRead(notification);
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

  Future<void> fetchNotifications() async {
    try {
      final response = await GetNotifications.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (response.succeeded) {
        final data =
            response.jsonBody['data'] ?? []; // Obtener las notificaciones
        setState(() {
          notifications = data;
        });
      }
    } catch (e) {
      // Error al cargar notificaciones
    }

    try {
      final response = await GetNotificationsCount.call(
        tenant: FFAppState().organizacion,
        token: FFAppState().token,
      );

      if (response.succeeded) {
        final data = response.jsonBody;
        setState(() {
          FFAppState().unreadNotifications = data['count'] ?? 0;
        });
      }
    } catch (e) {
      // Error al obtener conteo de notificaciones
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
                      'Notificaciones',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0, // Elimina sombra del AppBar
                    iconTheme: IconThemeData(
                        color: FlutterFlowTheme.of(context).primary),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchNotifications,
                      child: Builder(
                        builder: (context) {
                          final now = DateTime.now();
                          final todayStart = _startOfDay(now);
                          final weekStart = _startOfWeek(now);

                          final today = <dynamic>[];
                          final thisWeek = <dynamic>[];
                          final before = <dynamic>[];

                          for (final n in notifications) {
                            final dt = _parseNotificationDate(n['created_at']);

                            if (dt == null) {
                              before.add(n);
                              continue;
                            }

                            final localDt = dt; // ya es local
                            if (!localDt.isBefore(todayStart)) {
                              today.add(n);
                            } else if (!localDt.isBefore(weekStart)) {
                              thisWeek.add(n);
                            } else {
                              before.add(n);
                            }
                          }

                          int compareDesc(dynamic a, dynamic b) {
                            final da = _parseNotificationDate(a['created_at']);
                            final db = _parseNotificationDate(b['created_at']);
                            if (da == null && db == null) return 0;
                            if (da == null) return 1;
                            if (db == null) return -1;
                            return db.compareTo(da);
                          }

                          today.sort(compareDesc);
                          thisWeek.sort(compareDesc);
                          before.sort(compareDesc);

                          final children = <Widget>[];

                          void addSection(String title, List<dynamic> items) {
                            children.add(_sectionHeader(context, title));

                            if (items.isEmpty) {
                              children.add(
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 6, 16, 10),
                                  child: Text(
                                    'No hay notificaciones',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .copyWith(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              );
                              return;
                            }

                            for (int i = 0; i < items.length; i++) {
                              final notification = items[i];
                              children.add(_buildNotificationTile(
                                  context, notification));
                              children.add(const Divider(
                                  height: 1, color: Colors.black12));
                            }
                          }

                          addSection("HOY", today);
                          addSection("ESTA SEMANA", thisWeek);
                          addSection("ANTES DE ESTA SEMANA", before);

                          return ListView(
                            padding: EdgeInsetsGeometry.fromLTRB(20, 0, 20, 0),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: children,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
