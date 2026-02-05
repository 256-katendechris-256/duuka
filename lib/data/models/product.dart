import 'package:isar/isar.dart';

part 'product.g.dart';

/// Units for measurable products (sold by weight/volume/length)
enum MeasurementUnit {
  // Weight
  kg,      // Kilogram
  g,       // Gram
  lb,      // Pound
  
  // Volume
  liter,   // Liter
  ml,      // Milliliter
  
  // Length
  meter,   // Meter
  cm,      // Centimeter
  yard,    // Yard
  
  // Count (default for non-measurable)
  piece,   // Single piece/unit
  dozen,   // 12 pieces
  pack,    // Pack/bundle
  
  // Informal/Custom units (common in African markets)
  custom;  // Custom unit defined by owner

  String get label {
    switch (this) {
      case MeasurementUnit.kg:
        return 'Kilograms (kg)';
      case MeasurementUnit.g:
        return 'Grams (g)';
      case MeasurementUnit.lb:
        return 'Pounds (lb)';
      case MeasurementUnit.liter:
        return 'Liters (L)';
      case MeasurementUnit.ml:
        return 'Milliliters (ml)';
      case MeasurementUnit.meter:
        return 'Meters (m)';
      case MeasurementUnit.cm:
        return 'Centimeters (cm)';
      case MeasurementUnit.yard:
        return 'Yards (yd)';
      case MeasurementUnit.piece:
        return 'Pieces (pcs)';
      case MeasurementUnit.dozen:
        return 'Dozen (12 pcs)';
      case MeasurementUnit.pack:
        return 'Packs';
      case MeasurementUnit.custom:
        return 'Custom Unit';
    }
  }

  String get symbol {
    switch (this) {
      case MeasurementUnit.kg:
        return 'kg';
      case MeasurementUnit.g:
        return 'g';
      case MeasurementUnit.lb:
        return 'lb';
      case MeasurementUnit.liter:
        return 'L';
      case MeasurementUnit.ml:
        return 'ml';
      case MeasurementUnit.meter:
        return 'm';
      case MeasurementUnit.cm:
        return 'cm';
      case MeasurementUnit.yard:
        return 'yd';
      case MeasurementUnit.piece:
        return 'pcs';
      case MeasurementUnit.dozen:
        return 'dz';
      case MeasurementUnit.pack:
        return 'pk';
      case MeasurementUnit.custom:
        return ''; // Will use customUnit field
    }
  }

  /// Whether this unit typically allows fractional quantities
  bool get allowsFractions {
    switch (this) {
      case MeasurementUnit.kg:
      case MeasurementUnit.g:
      case MeasurementUnit.lb:
      case MeasurementUnit.liter:
      case MeasurementUnit.ml:
      case MeasurementUnit.meter:
      case MeasurementUnit.cm:
      case MeasurementUnit.yard:
      case MeasurementUnit.custom:  // Custom units allow fractions
        return true;
      case MeasurementUnit.piece:
      case MeasurementUnit.dozen:
      case MeasurementUnit.pack:
        return false;
    }
  }
}

/// Common informal units used in African markets
class InformalUnits {
  static const List<String> common = [
    'debe',       // Tin container (~18L)
    'kasuku',     // Small tin (~2L)
    'gorogoro',   // Milk tin (~2kg)
    'gunia',      // Sack/bag (~90-100kg)
    'ndoo',       // Bucket (~20L)
    'karai',      // Basin
    'cup',        // Cup/mug measure
    'heap',       // Small pile/heap
    'bunch',      // Bunch (bananas, spinach)
    'bundle',     // Bundle (firewood, sugarcane)
    'piece',      // Single piece
    'half',       // Half unit
    'quarter',    // Quarter unit
    'plate',      // Plate measure
    'spoon',      // Spoon measure
    'glass',      // Glass measure
    'jerrycan',   // Jerrycan (~20L)
    'roll',       // Roll (fabric, rope)
    'pair',       // Pair (shoes, socks)
    'set',        // Set of items
  ];
}

/// Product specification (key-value pair)
@embedded
class ProductSpecification {
  late String name;
  late String value;

  ProductSpecification();

  ProductSpecification.create({required this.name, required this.value});

  Map<String, String> toMap() => {'name': name, 'value': value};

  static ProductSpecification fromMap(Map<String, dynamic> map) {
    return ProductSpecification()
      ..name = map['name'] as String? ?? ''
      ..value = map['value'] as String? ?? '';
  }
}

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  String? barcode;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  /// Product description (general info, features, etc.)
  String? description;

  String? size;  // e.g., 500ml, 1L, Small, Medium, Large, Pack of 6
  String? color; // Hex color string e.g., "#FF5733" or color name
  String? photoPath; // Local file path to product image
  String? category;

  /// Custom specifications (user-defined key-value pairs)
  /// e.g., RAM: 16GB, Processor: Intel i7, Expiry Date: 2025-06-30
  List<ProductSpecification> specifications = [];

  late double costPrice;
  late double sellPrice;
  
  // Stock quantity - double to support measurable products (with default for migration)
  double stockQuantity = 0;
  
  // Legacy field for migration - safely handles NaN/Infinity
  @ignore
  int get quantity {
    if (stockQuantity.isNaN || stockQuantity.isInfinite) return 0;
    return stockQuantity.toInt();
  }
  @ignore
  set quantity(int value) => stockQuantity = value.toDouble();
  
  int reorderLevel = 5;
  String unit = 'pcs';
  
  // Measurable product fields
  bool isMeasurable = false;  // True for products sold by weight/volume/length
  
  @enumerated
  MeasurementUnit measurementUnit = MeasurementUnit.piece;
  
  // Custom unit name (e.g., "debe", "kasuku", "gorogoro") for informal measurements
  String? customUnit;

  bool isActive = true;

  @enumerated
  SyncStatus syncStatus = SyncStatus.pending;

  @Index()
  late DateTime createdAt;
  late DateTime updatedAt;

  String? remoteId;

  // Computed properties - safely handle NaN/Infinity (all @ignore to prevent Isar serialization)
  @ignore
  double get safeStockQuantity {
    if (stockQuantity.isNaN || stockQuantity.isInfinite) return 0;
    return stockQuantity;
  }
  
  @ignore
  double get stockValue => costPrice * safeStockQuantity;
  @ignore
  double get profit => sellPrice - costPrice;
  @ignore
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;
  @ignore
  bool get isLowStock => safeStockQuantity <= reorderLevel;
  
  /// Get the display unit (uses customUnit for custom, measurementUnit symbol for standard, or unit field)
  @ignore
  String get displayUnit {
    if (isMeasurable) {
      if (measurementUnit == MeasurementUnit.custom && customUnit != null && customUnit!.isNotEmpty) {
        return customUnit!;
      }
      return measurementUnit.symbol.isNotEmpty ? measurementUnit.symbol : unit;
    }
    return unit;
  }
  
  /// Format quantity with appropriate unit
  @ignore
  String formatQuantity(double qty) {
    final safeQty = qty.isNaN || qty.isInfinite ? 0.0 : qty;
    if (isMeasurable && measurementUnit.allowsFractions) {
      // Show decimals for measurable products
      return '${safeQty.toStringAsFixed(safeQty.truncateToDouble() == safeQty ? 0 : 2)} $displayUnit';
    } else {
      // Whole numbers for piece-based products
      return '${safeQty.toInt()} $displayUnit';
    }
  }
  
  // Check if product has a custom image
  @ignore
  bool get hasCustomImage => photoPath != null && photoPath!.isNotEmpty;
}

enum SyncStatus { synced, pending, failed }
