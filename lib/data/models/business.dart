import 'package:isar/isar.dart';
import 'product.dart';

part 'business.g.dart';

@collection
class Business {
  Id id = Isar.autoIncrement;

  late String name;
  late String ownerName;
  String? phone;
  String? email;
  String? address;
  String? district;
  String? area;
  String? tinNumber;
  String? logoPath;

  @enumerated
  late BusinessType businessType;

  @enumerated
  late BusinessSize businessSize;

  @enumerated
  SubscriptionPlan plan = SubscriptionPlan.free;

  DateTime? planExpiryDate;
  bool onTrial = true;

  late DateTime createdAt;
  late DateTime updatedAt;

  String? remoteId;
  String? ownerId;
}

enum BusinessType {
  retail,
  pharmacy,
  hardware,
  agroInput,
  restaurant,
  clothing,
  cosmetics,
  other
}

enum BusinessSize {
  starter,
  small,
  growing,
  established
}

enum SubscriptionPlan { free, starter, business, premium }
