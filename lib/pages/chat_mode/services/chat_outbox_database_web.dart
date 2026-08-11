import 'package:sembast_web/sembast_web.dart';

Future<Database> openChatOutboxDatabase() =>
    databaseFactoryWeb.openDatabase('query-chat-outbox');
