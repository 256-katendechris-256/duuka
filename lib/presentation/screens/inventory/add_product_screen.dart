import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../widgets/common/duuka_app_bar.dart';
import '../../widgets/common/duuka_button.dart';
import '../../widgets/common/duuka_text_field.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../providers/product_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? product; // If provided, we're editing

  const AddProductScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _unitController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditMode => widget.product != null;
  
  // Image handling
  String? _selectedImagePath;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Color handling
  Color? _selectedColor;
  
  // Measurable product handling
  bool _isMeasurable = false;
  MeasurementUnit _measurementUnit = MeasurementUnit.kg;
  final _customUnitController = TextEditingController();

  // Custom specifications handling
  List<ProductSpecification> _specifications = [];
  final _specNameController = TextEditingController();
  final _specValueController = TextEditingController();
  
  // Predefined colors for quick selection
  static const List<Color> _presetColors = [
    Color(0xFFE53935), // Red
    Color(0xFFD81B60), // Pink
    Color(0xFF8E24AA), // Purple
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF3949AB), // Indigo
    Color(0xFF1E88E5), // Blue
    Color(0xFF039BE5), // Light Blue
    Color(0xFF00ACC1), // Cyan
    Color(0xFF00897B), // Teal
    Color(0xFF43A047), // Green
    Color(0xFF7CB342), // Light Green
    Color(0xFFC0CA33), // Lime
    Color(0xFFFDD835), // Yellow
    Color(0xFFFFB300), // Amber
    Color(0xFFFB8C00), // Orange
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF6D4C41), // Brown
    Color(0xFF757575), // Grey
    Color(0xFF546E7A), // Blue Grey
    Color(0xFF000000), // Black
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _populateFields();
    } else {
      _reorderLevelController.text = '5';
      _unitController.text = 'pcs';
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _barcodeController.text = product.barcode ?? '';
    _sizeController.text = product.size ?? '';
    _colorController.text = product.color ?? '';
    _categoryController.text = product.category ?? '';
    _costPriceController.text = product.costPrice.toString();
    _sellPriceController.text = product.sellPrice.toString();
    _quantityController.text = product.stockQuantity.toString();
    _reorderLevelController.text = product.reorderLevel.toString();
    _unitController.text = product.unit;
    _selectedImagePath = product.photoPath;
    
    // Measurable product settings
    _isMeasurable = product.isMeasurable;
    _measurementUnit = product.measurementUnit;
    _customUnitController.text = product.customUnit ?? '';

    // Custom specifications
    _specifications = List.from(product.specifications);

    // Parse color if exists
    if (product.color != null && product.color!.isNotEmpty) {
      _selectedColor = _parseColor(product.color!);
    }
  }
  
  Color? _parseColor(String colorString) {
    // Try to parse hex color
    if (colorString.startsWith('#')) {
      try {
        final hex = colorString.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _categoryController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _quantityController.dispose();
    _reorderLevelController.dispose();
    _unitController.dispose();
    _customUnitController.dispose();
    _specNameController.dispose();
    _specValueController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        // Save to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final productsDir = Directory('${appDir.path}/product_images');
        if (!await productsDir.exists()) {
          await productsDir.create(recursive: true);
        }
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
        final savedPath = '${productsDir.path}/$fileName';
        
        await File(pickedFile.path).copy(savedPath);
        
        setState(() {
          _selectedImagePath = savedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    }
  }
  
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: DuukaColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImagePath != null)
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    label: 'Remove',
                    color: DuukaColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImagePath = null;
                      });
                    },
                  ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: (color ?? DuukaColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: color ?? DuukaColors.primary,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color ?? DuukaColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Color',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                if (_selectedColor != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedColor = null;
                        _colorController.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: DuukaColors.error,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: _presetColors.map((color) {
                final isSelected = _selectedColor?.value == color.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                      _colorController.text = _colorToHex(color);
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? DuukaColors.textPrimary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            size: 24.sp,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),
            // Custom color input
            DuukaTextField(
              label: 'Or enter hex color',
              hint: '#FF5733',
              controller: _colorController,
              onChanged: (value) {
                if (value.startsWith('#') && value.length == 7) {
                  final parsed = _parseColor(value);
                  if (parsed != null) {
                    setState(() {
                      _selectedColor = parsed;
                    });
                  }
                }
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('📝 Creating product object...');
      final product = Product()
        ..name = _nameController.text.trim()
        ..barcode = _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim()
        ..size = _sizeController.text.trim().isEmpty
            ? null
            : _sizeController.text.trim()
        ..color = _selectedColor != null ? _colorToHex(_selectedColor!) : null
        ..photoPath = _selectedImagePath
        ..category = _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim()
        ..costPrice = double.parse(_costPriceController.text)
        ..sellPrice = double.parse(_sellPriceController.text)
        ..stockQuantity = double.parse(_quantityController.text)
        ..reorderLevel = int.parse(_reorderLevelController.text)
        ..unit = _isMeasurable 
            ? (_measurementUnit == MeasurementUnit.custom 
                ? _customUnitController.text.trim() 
                : _measurementUnit.symbol)
            : _unitController.text.trim()
        ..isMeasurable = _isMeasurable
        ..measurementUnit = _measurementUnit
        ..customUnit = _measurementUnit == MeasurementUnit.custom
            ? _customUnitController.text.trim()
            : null
        ..specifications = _specifications
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      if (_isEditMode) {
        product.id = widget.product!.id;
        product.createdAt = widget.product!.createdAt;
      }

      print('📦 Product details: ${product.name}, Category: ${product.category}, Size: ${product.size}');
      print('💰 Prices: Cost=${product.costPrice}, Sell=${product.sellPrice}, Qty=${product.quantity}');
      print('🔄 Calling save method (edit mode: $_isEditMode)...');

      final success = _isEditMode
          ? await ref.read(productsProvider.notifier).updateProduct(product)
          : await ref.read(productsProvider.notifier).addProduct(product);

      print('✅ Save result: $success');

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Product updated successfully'
                  : 'Product added successfully',
            ),
            backgroundColor: DuukaColors.success,
          ),
        );
        context.pop();
      } else if (mounted) {
        print('❌ Save returned false');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Failed to update product' : 'Failed to add product',
            ),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } catch (e) {
      print('💥 Exception during save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoryPicker() async {
    try {
      // Get existing categories from the database
      final categories = await ref.read(productCategoriesProvider.future);

      if (!mounted) return;

      // Filter out 'All' category
      final availableCategories = categories.where((c) => c != 'All').toList();

      if (availableCategories.isEmpty) {
        // Show message if no categories exist yet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No categories yet. Type a new category name.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) => Container(
          padding: EdgeInsets.all(16.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Category',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Or type a new one in the field',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: DuukaColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                ...(availableCategories.map((category) {
                  return ListTile(
                    title: Text(category),
                    onTap: () {
                      _categoryController.text = category;
                      Navigator.pop(context);
                    },
                  );
                })),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: ${e.toString()}'),
            backgroundColor: DuukaColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: DuukaColors.background,
        appBar: DuukaAppBar(
          title: _isEditMode ? 'Edit Product' : 'Add Product',
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              // Product Image Section
              _buildImageSection(),
              SizedBox(height: 20.h),

              // Product Name
              DuukaTextField(
                label: 'Product Name *',
                hint: 'Enter product name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Barcode
              DuukaTextField(
                label: 'Barcode (Optional)',
                hint: 'Scan or enter barcode',
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                suffixIcon: IconButton(
                  icon: Icon(Icons.qr_code_scanner, size: 20.sp),
                  onPressed: () {
                    // TODO: Open barcode scanner
                  },
                ),
              ),
              SizedBox(height: 16.h),

              // Category
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DuukaTextField(
                    label: 'Category (Optional)',
                    hint: 'e.g., Beverages, Snacks, etc.',
                    controller: _categoryController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: 24.sp,
                        color: DuukaColors.textSecondary,
                      ),
                      onPressed: _showCategoryPicker,
                      tooltip: 'Select from existing categories',
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Create your own categories or select from existing ones',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Variants Section Header
              Text(
                'Variants (Optional)',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),

              // Size & Color Row
              Row(
                children: [
                  Expanded(
                    child: DuukaTextField(
                      label: 'Size',
                      hint: 'e.g., S, M, L, XL',
                      controller: _sizeController,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildColorField(),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Pricing Section Header
              Text(
                'Pricing',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),

              // Cost & Sell Price Row
              Row(
                children: [
                  Expanded(
                    child: DuukaTextField(
                      label: 'Cost Price *',
                      hint: '0.00',
                      controller: _costPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: DuukaTextField(
                      label: 'Sell Price *',
                      hint: '0.00',
                      controller: _sellPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Stock Section Header
              Text(
                'Stock Information',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              
              // Measurable Product Toggle
              _buildMeasurableToggle(),
              SizedBox(height: 16.h),

              // Quantity & Unit Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DuukaTextField(
                      label: _isEditMode ? 'Current Stock *' : 'Initial Stock *',
                      hint: _isMeasurable ? '0.0' : '0',
                      controller: _quantityController,
                      keyboardType: _isMeasurable 
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.number,
                      inputFormatters: _isMeasurable
                          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                          : [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _isMeasurable
                        ? _buildMeasurementUnitPicker()
                        : DuukaTextField(
                            label: 'Unit *',
                            hint: 'pcs',
                            controller: _unitController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Reorder Level
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DuukaTextField(
                    label: 'Reorder Level *',
                    hint: '5',
                    controller: _reorderLevelController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Reorder level is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Alert when stock falls below this level',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: DuukaColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Custom Specifications Section
              _buildSpecificationsSection(),
              SizedBox(height: 32.h),

              // Save Button
              DuukaButton.primary(
                label: _isEditMode ? 'Update Product' : 'Add Product',
                onPressed: _saveProduct,
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Image (Optional)',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: DuukaColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: DuukaColors.border,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(_selectedImagePath!),
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 48.sp,
                        color: DuukaColors.textSecondary,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Tap to add product image',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Camera or Gallery',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: DuukaColors.textHint,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMeasurableToggle() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _isMeasurable ? DuukaColors.primaryBg : DuukaColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isMeasurable ? DuukaColors.primary : DuukaColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: _isMeasurable 
                  ? DuukaColors.primary.withOpacity(0.1) 
                  : DuukaColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.scale,
              size: 24.sp,
              color: _isMeasurable ? DuukaColors.primary : DuukaColors.textSecondary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by Measurement',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _isMeasurable 
                      ? 'Price is per ${_measurementUnit.symbol}' 
                      : 'Enable for products sold by weight, volume, or length',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isMeasurable,
            onChanged: (value) {
              setState(() {
                _isMeasurable = value;
                if (value) {
                  // Reset to kg as default
                  _measurementUnit = MeasurementUnit.kg;
                }
              });
            },
            activeColor: DuukaColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementUnitPicker() {
    final displayText = _measurementUnit == MeasurementUnit.custom
        ? (_customUnitController.text.isEmpty ? 'Custom...' : _customUnitController.text)
        : _measurementUnit.symbol.toUpperCase();
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit *',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: DuukaColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _showMeasurementUnitPicker,
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: DuukaColors.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 24.sp,
                  color: DuukaColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMeasurementUnitPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: DuukaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: DuukaColors.border,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Select Measurement Unit',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: DuukaColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Choose how this product is measured and sold',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    children: [
                      _buildUnitSection('Weight', [
                        MeasurementUnit.kg,
                        MeasurementUnit.g,
                        MeasurementUnit.lb,
                      ]),
                      SizedBox(height: 16.h),
                      _buildUnitSection('Volume', [
                        MeasurementUnit.liter,
                        MeasurementUnit.ml,
                      ]),
                      SizedBox(height: 16.h),
                      _buildUnitSection('Length', [
                        MeasurementUnit.meter,
                        MeasurementUnit.cm,
                        MeasurementUnit.yard,
                      ]),
                      SizedBox(height: 16.h),
                      
                      // Informal/Custom Units Section
                      _buildInformalUnitsSection(setModalState),
                      
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInformalUnitsSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informal / Custom Units',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: DuukaColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Common local measurement units',
          style: TextStyle(
            fontSize: 11.sp,
            color: DuukaColors.textHint,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Common informal units as chips
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: InformalUnits.common.map((unit) {
            final isSelected = _measurementUnit == MeasurementUnit.custom && 
                              _customUnitController.text == unit;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _measurementUnit = MeasurementUnit.custom;
                  _customUnitController.text = unit;
                });
                setModalState(() {});
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? DuukaColors.primary : DuukaColors.background,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? DuukaColors.primary : DuukaColors.border,
                  ),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : DuukaColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16.h),
        
        // Custom unit input
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: DuukaColors.background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _measurementUnit == MeasurementUnit.custom 
                  ? DuukaColors.primary 
                  : DuukaColors.border,
              width: _measurementUnit == MeasurementUnit.custom ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: 18.sp,
                    color: DuukaColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Or enter your own unit',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: DuukaColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customUnitController,
                      decoration: InputDecoration(
                        hintText: 'e.g., debe, kasuku, gorogoro...',
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          color: DuukaColors.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setModalState(() {});
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: _customUnitController.text.trim().isNotEmpty
                        ? () {
                            setState(() {
                              _measurementUnit = MeasurementUnit.custom;
                            });
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DuukaColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Use',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSection(String title, List<MeasurementUnit> units) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: DuukaColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        ...units.map((unit) {
          final isSelected = _measurementUnit == unit;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: GestureDetector(
              onTap: () {
                setState(() => _measurementUnit = unit);
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isSelected ? DuukaColors.primaryBg : DuukaColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? DuukaColors.primary : DuukaColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? DuukaColors.primary.withOpacity(0.1) 
                            : DuukaColors.surface,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          unit.symbol,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? DuukaColors.primary : DuukaColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.label,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: DuukaColors.textPrimary,
                            ),
                          ),
                          Text(
                            'e.g., 0.5 ${unit.symbol}, 1.25 ${unit.symbol}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: DuukaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: DuukaColors.primary,
                        size: 24.sp,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildColorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: DuukaColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: DuukaColors.border, width: 1),
            ),
            child: Row(
              children: [
                if (_selectedColor != null) ...[
                  Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DuukaColors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _colorToHex(_selectedColor!),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.palette_outlined,
                    size: 20.sp,
                    color: DuukaColors.textSecondary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Select color',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: DuukaColors.textHint,
                      ),
                    ),
                  ),
                ],
                Icon(
                  Icons.arrow_drop_down,
                  size: 24.sp,
                  color: DuukaColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Specifications',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: DuukaColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Add custom fields like RAM, expiry date, etc.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: DuukaColors.textSecondary,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _showAddSpecificationDialog,
              icon: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: DuukaColors.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // List of specifications
        if (_specifications.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: DuukaColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: 40.sp,
                  color: DuukaColors.textHint,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No specifications added',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: DuukaColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Tap + to add custom fields',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: DuukaColors.textHint,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: DuukaColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: DuukaColors.border),
            ),
            child: Column(
              children: _specifications.asMap().entries.map((entry) {
                final index = entry.key;
                final spec = entry.value;
                final isLast = index == _specifications.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(color: DuukaColors.border),
                          ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    title: Text(
                      spec.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: DuukaColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      spec.value,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: DuukaColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20.sp,
                            color: DuukaColors.primary,
                          ),
                          onPressed: () => _showEditSpecificationDialog(index),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20.sp,
                            color: DuukaColors.error,
                          ),
                          onPressed: () => _removeSpecification(index),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showAddSpecificationDialog() {
    _specNameController.clear();
    _specValueController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Specification',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add custom attributes for this product',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: DuukaColors.textSecondary,
                ),
              ),
              SizedBox(height: 20.h),

              DuukaTextField(
                label: 'Field Name *',
                hint: 'e.g., RAM, Expiry Date, Batch Number',
                controller: _specNameController,
              ),
              SizedBox(height: 12.h),
              DuukaTextField(
                label: 'Field Value *',
                hint: 'e.g., 16GB, 2025-06-30, ABC123',
                controller: _specValueController,
              ),
              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: DuukaColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = _specNameController.text.trim();
                        final value = _specValueController.text.trim();

                        if (name.isEmpty || value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please fill in both fields'),
                              backgroundColor: DuukaColors.error,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _specifications.add(
                            ProductSpecification.create(name: name, value: value),
                          );
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DuukaColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSpecificationDialog(int index) {
    final spec = _specifications[index];
    _specNameController.text = spec.name;
    _specValueController.text = spec.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Specification',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: DuukaColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),

              DuukaTextField(
                label: 'Field Name *',
                hint: 'e.g., RAM, Expiry Date',
                controller: _specNameController,
              ),
              SizedBox(height: 12.h),
              DuukaTextField(
                label: 'Field Value *',
                hint: 'e.g., 16GB, 2025-06-30',
                controller: _specValueController,
              ),
              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: DuukaColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: DuukaColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = _specNameController.text.trim();
                        final value = _specValueController.text.trim();

                        if (name.isEmpty || value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please fill in both fields'),
                              backgroundColor: DuukaColors.error,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _specifications[index] = ProductSpecification.create(
                            name: name,
                            value: value,
                          );
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DuukaColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  void _removeSpecification(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Specification'),
        content: Text(
          'Are you sure you want to remove "${_specifications[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _specifications.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: TextStyle(color: DuukaColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
