import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';
import '../../models/product_return.dart';
import '../../models/device.dart';
import '../../models/team_member.dart';
import '../../models/invitation.dart';

class DatabaseService {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    print('🗄️ Initializing Isar database at: ${dir.path}');

    _isar = await Isar.open(
      [
        ProductSchema,
        SaleSchema,
        InvoiceSchema,
        CustomerSchema,
        CreditTransactionSchema,
        CreditPaymentSchema,
        ExpenseSchema,
        BusinessSchema,
        AppUserSchema,
        SyncQueueSchema,
        ProductReturnSchema,
        DeviceSchema,
        TeamMemberSchema,
        InvitationSchema,
      ],
      directory: dir.path,
      name: 'duuka_v9', // Updated for team management
      inspector: true, // Enable Isar Inspector for debugging
    );

    print('✅ Database initialized successfully');
  }

  static Future<void> clear() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }
}
