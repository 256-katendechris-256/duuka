import 'dart:convert';
import 'dart:io';

/// Reads supabase_config.json from the current working directory (project root when run from IDE/flutter run).
Future<Map<String, String>?> loadSupabaseConfigFromFile() async {
  try {
    final file = File('supabase_config.json');
    if (await file.exists()) {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final url = (map['SUPABASE_URL'] as String?)?.trim() ?? '';
      final key = (map['SUPABASE_ANON_KEY'] as String?)?.trim() ?? '';
      final clientId = (map['GOOGLE_WEB_CLIENT_ID'] as String?)?.trim() ?? '';
      if (url.isNotEmpty && key.isNotEmpty) {
        return {
          'SUPABASE_URL': url,
          'SUPABASE_ANON_KEY': key,
          'GOOGLE_WEB_CLIENT_ID': clientId,
        };
      }
    }
  } catch (_) {}
  return null;
}
