import 'package:sembast/sembast.dart';

import 'chat_outbox_database_stub.dart'
    if (dart.library.io) 'chat_outbox_database_io.dart'
    if (dart.library.html) 'chat_outbox_database_web.dart' as platform;

Future<Database> openChatOutboxDatabase() => platform.openChatOutboxDatabase();
