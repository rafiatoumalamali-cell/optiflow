import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../utils/app_colors.dart';
import '../../utils/error_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../providers/transport_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/location_model.dart';
import '../../utils/app_localizations.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _latController = TextEditingController(text: '13.5127');
  final TextEditingController _lngController = TextEditingController(text: '2.1128');

  LatLng _selectedLocation = const LatLng(13.5127, 2.1128);

  String _selectedType = 'Factory/Warehouse';
  String _selectedUnit = 'kg';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _qtyController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final transportProvider = Provider.of<TransportProvider>(context, listen: false);
      final businessId = authProvider.currentUser?.businessId ?? 'default_biz';

      final qty = double.tryParse(_qtyController.text) ?? 0.0;
      final type = _selectedType.contains('Factory') ? 'Factory' : (_selectedType.contains('Retail') ? 'Retail' : 'Hub');

      final newLocation = LocationModel(
        locationId: const Uuid().v4(),
        businessId: businessId,
        name: _nameController.text,
        address: _addressController.text,
        latitude: double.tryParse(_latController.text) ?? 13.5116,
        longitude: double.tryParse(_lngController.text) ?? 2.1254,
        type: type,
        supplyQuantity: type == 'Retail' ? 0.0 : qty,
        demandQuantity: type == 'Retail' ? qty : 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await transportProvider.addLocation(newLocation);

      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc?.translate('location_saved_successfully') ?? 'Location saved successfully'), backgroundColor: AppColors.successGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorUtils.localizeError(e, context)), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(loc?.translate('add_location') ?? 'Add Location', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: loc?.translate('location_name') ?? 'Location Name',
                hintText: loc?.translate('location_name_hint') ?? 'e.g., Central Warehouse, Shop A',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? loc?.translate('enter_name') ?? 'Enter name' : null,
              ),
              const SizedBox(height: 24),
              Text(loc?.translate('location_type') ?? 'Location Type', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip(loc?.translate('factories') ?? 'Factory', Icons.factory_outlined),
                  _buildTypeChip(loc?.translate('retailers') ?? 'Retail Shop', Icons.storefront),
                  _buildTypeChip(loc?.translate('transport') ?? 'Hub', Icons.hub_outlined),
                ],
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: loc?.translate('full_address') ?? 'Full Address',
                hintText: loc?.translate('address_hint') ?? 'Street name, District, City',
                controller: _addressController,
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primaryGreen),
                validator: (v) => v == null || v.isEmpty ? loc?.translate('enter_address') ?? 'Enter address' : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc?.translate('map_location') ?? 'Map Location', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  TextButton(onPressed: () {}, child: Text(loc?.translate('tap_drop_pin') ?? 'Tap to drop pin', style: const TextStyle(fontSize: 12, color: AppColors.primaryGreen))),
                ],
              ),
              // Interactive Google Map
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 13),
                    onTap: _onMapTap,
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected-location'),
                        position: _selectedLocation,
                      ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 16, color: AppColors.textLight),
                  const SizedBox(width: 8),
                  Text(loc?.translate('gps_coordinates') ?? 'GPS COORDINATES', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: 'LATITUDE', hintText: '13.5116', controller: _latController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(label: 'LONGITUDE', hintText: '2.1254', controller: _lngController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              Text(loc?.translate('available_supply_qty') ?? 'Quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: '', hintText: '0.00', controller: _qtyController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.backgroundGray, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        items: ['kg', 'liters', 'units'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: loc?.translate('save_location') ?? 'Save Location',
                icon: Icons.save,
                isLoading: _isSaving,
                onPressed: _saveLocation,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon) {
    bool isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textLight),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}
