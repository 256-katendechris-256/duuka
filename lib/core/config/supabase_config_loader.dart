import 'supabase_config_loader_stub.dart' if (dart.library.io) 'supabase_config_loader_io.dart' as impl;

Future<Map<String, String>?> loadSupabaseConfigFromFile() => impl.loadSupabaseConfigFromFile();
