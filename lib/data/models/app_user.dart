import 'package:isar/isar.dart';
import 'product.dart';

part 'app_user.g.dart';

@collection
class AppUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  late String phone;
  String? name;
  String? email;
  String? photoUrl;

  @enumerated
  UserRole role = UserRole.owner;

  int? businessId;

  bool isActive = true;

  late DateTime createdAt;
  DateTime? lastLoginAt;

  String? remoteId;
}

enum UserRole { owner, manager, cashier, viewer }
