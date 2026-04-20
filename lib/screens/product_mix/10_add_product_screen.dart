import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';
import '../../models/product_resource_model.dart';
import '../../utils/app_localizations.dart';
import '../../services/firebase/firebase_storage_service.dart';
import '../../utils/logger.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _selectedUnit = 'Kilograms (kg)';
  String _selectedCurrency = 'CFA (XOF)';
  bool _isSaving = false;

  final List<Map<String, dynamic>> _productResources = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e, stack) {
      Logger.error('Error picking image', name: 'AddProductScreen', error: e, stackTrace: stack);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryGreen),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final businessId = authProvider.currentUser?.businessId ?? 'default_biz';

      String? imageUrl;
      if (_imageFile != null) {
        try {
          Logger.info('Starting image upload for product', name: 'AddProductScreen');
          imageUrl = await _storageService.uploadProductImage(
            businessId: businessId,
            imageFile: _imageFile!,
          );
          Logger.info('Image upload successful', name: 'AddProductScreen');
        } catch (e, stack) {
          Logger.error('Image upload failed', name: 'AddProductScreen', error: e, stackTrace: stack);
          
          String errorMessage = 'Could not upload image';
          if (e.toString().contains('too large')) {
            errorMessage = 'Image is too large. Maximum size is 5MB.';
          } else if (e.toString().contains('does not exist')) {
            errorMessage = 'Image file not found. Please select an image again.';
          } else if (e.toString().contains('network')) {
            errorMessage = 'Network error. Please check your connection and try again.';
          } else if (e.toString().contains('permission')) {
            errorMessage = 'Permission denied. Please check app permissions.';
          } else {
            errorMessage = 'Image upload failed: ${e.toString()}';
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: AppColors.errorRed),
            );
          }
          
          // Don't continue saving the product if image upload fails
          setState(() => _isSaving = false);
          return;
        }
      }

      final price = double.tryParse(_priceController.text) ?? 0.0;
      final cost = double.tryParse(_costController.text) ?? 0.0;

      final newProduct = ProductModel(
        productId: const Uuid().v4(),
        businessId: businessId,
        name: _nameController.text,
        sellingPrice: price,
        productionCost: cost,
        unit: _selectedUnit,
        profitMargin: price - cost,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await productProvider.addProduct(newProduct);
      
      // Save all real required constraints defined by the user
      for (var reqData in _productResources) {
        try {
          await productProvider.saveProductRequirement(
            ProductResourceRequirement(
              productId: newProduct.productId,
              resourceId: reqData['resourceId'],
              quantityRequired: double.tryParse(reqData['quantity'].toString()) ?? 0.0,
            )
          );
        } catch (e) {
          Logger.error('Failed to save req for product', error: e);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product and constraints saved successfully'), backgroundColor: AppColors.successGreen),
        );
        Navigator.pop(context);
      }
    } catch (e, stack) {
      Logger.error('Error saving product', name: 'AddProductScreen', error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddResourceDialog(AppLocalizations? loc) async {
    final prov = Provider.of<ProductProvider>(context, listen: false);
    if (prov.resources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please define your Resource Constraints first!')));
      return;
    }

    String? selectedResId = prov.resources.first.resourceId;
    final valueController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Add Required Resource'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedResId,
                    isExpanded: true,
                    items: prov.resources.map((r) => DropdownMenuItem(value: r.resourceId, child: Text('${r.name} (${r.unit})'))).toList(),
                    onChanged: (v) => setStateSB(() => selectedResId = v),
                  ),
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: 'Quantity Required per Unit'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final val = valueController.text.trim();
                    if (val.isNotEmpty && selectedResId != null) {
                      final selectedRes = prov.resources.firstWhere((r) => r.resourceId == selectedResId);
                      setState(() {
                         _productResources.add({
                           'resourceId': selectedRes.resourceId,
                           'name': selectedRes.name,
                           'quantity': val,
                           'unit': selectedRes.unit,
                         });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Limit')
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(loc?.translate('home_title') ?? 'OptiFlow', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/user_avatar.png')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc?.translate('add_new_product') ?? 'Add New Product', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(loc?.translate('product_params_desc') ?? 'Define production parameters and optimize resource allocation for West African distribution hubs.', 
                style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 24),
              // Image Upload / Preview Area
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                    image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) 
                      : null,
                  ),
                  child: _imageFile == null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.primaryGreen),
                        const SizedBox(height: 8),
                        Text(loc?.translate('upload_photo') ?? 'Upload Product Photo', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        Text(loc?.translate('high_quality_img') ?? 'High-quality JPG or PNG', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 20, color: AppColors.errorRed),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.black.withOpacity(0.5),
                            child: const Text('Tap to Change Photo', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: loc?.translate('business_name') ?? 'Product Name', 
                hintText: 'e.g., Premium Shea Butter 500g',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Enter product name' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildDropdown(loc?.translate('unit_type') ?? 'Unit Type', _selectedUnit, ['Kilograms (kg)', 'Litres (L)', 'Units'], (v) => setState(() => _selectedUnit = v!))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown(loc?.translate('currency_hub') ?? 'Currency Hub', _selectedCurrency, ['CFA (XOF)', 'Naira (NGN)', 'Cedi (GHS)'], (v) => setState(() => _selectedCurrency = v!))),
                ],
              ),
              const SizedBox(height: 32),
              Text(loc?.translate('unit_financials') ?? 'Unit Financials', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(
                label: loc?.translate('selling_price') ?? 'SELLING PRICE', 
                hintText: '0.00', 
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.payments_outlined, size: 20, color: AppColors.successGreen),
                validator: (v) => v == null || v.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: loc?.translate('production_cost') ?? 'PRODUCTION COST', 
                hintText: '0.00', 
                controller: _costController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.primaryOrange),
                validator: (v) => v == null || v.isEmpty ? 'Enter cost' : null,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc?.translate('resource_requirements') ?? 'Resource Requirements', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: () => _showAddResourceDialog(loc), icon: const Icon(Icons.add, size: 16), label: Text(loc?.translate('add_resource') ?? 'Add Resource', style: const TextStyle(fontSize: 12))),
                ],
              ),
              ..._productResources.asMap().entries.map((entry) {
                final idx = entry.key;
                final res = entry.value;
                return _buildResourceItem(idx, 'Constraint', res['name'].toString(), res['quantity'].toString(), res['unit'].toString());
              }),
              const SizedBox(height: 40),
              CustomButton(
                text: loc?.translate('save_product') ?? 'Save Product', 
                icon: Icons.save, 
                isLoading: _isSaving,
                onPressed: _saveProduct,
              ),
              const SizedBox(height: 12),
              Center(child: Text(loc?.translate('save_desc') ?? 'Once saved, this product will be available for route planning and scenario modeling.', 
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textLight))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value, isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceItem(int index, String category, String name, String value, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(category == 'Raw Materials' ? Icons.inventory_2_outlined : category == 'Energy' ? Icons.bolt : Icons.people_outline, size: 20, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _productResources.removeAt(index)),
            child: const Icon(Icons.close, size: 16, color: AppColors.errorRed),
          ),
        ],
      ),
    );
  }
}
