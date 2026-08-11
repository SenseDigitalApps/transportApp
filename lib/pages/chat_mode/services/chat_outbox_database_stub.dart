import 'package:sembast/sembast_memory.dart';

Future<Database> openChatOutboxDatabase() =>
    databaseFactoryMemory.openDatabase('query-chat-outbox');
