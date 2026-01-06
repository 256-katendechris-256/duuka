import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';

class DatabaseService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        ProductSchema,
        SaleSchema,
        CustomerSchema,
        BusinessSchema,
        AppUserSchema,
        SyncQueueSchema,
      ],
      directory: dir.path,
      name: 'duuka',
    );
  }

  static Future<void> clear() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }
}
