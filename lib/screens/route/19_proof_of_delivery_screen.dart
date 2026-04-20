import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../services/firebase/firebase_storage_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../models/delivery_stop_model.dart';
import '../../providers/route_provider.dart';

class ProofOfDeliveryScreen extends StatefulWidget {
  const ProofOfDeliveryScreen({super.key});

  @override
  State<ProofOfDeliveryScreen> createState() => _ProofOfDeliveryScreenState();
}

class _ProofOfDeliveryScreenState extends State<ProofOfDeliveryScreen> {
  SignatureController? _signatureController;
  File? _deliveryImage;
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  bool _isSubmitting = false;
  DeliveryStopModel? _currentStop;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.textDark,
      exportBackgroundColor: Colors.white,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stop = ModalRoute.of(context)!.settings.arguments as DeliveryStopModel?;
      if (stop != null) {
        setState(() => _currentStop = stop);
      }
    });
  }

  @override
  void dispose() {
    _signatureController?.dispose();
    super.dispose();
  }

  Future<void> _takeDeliveryPhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _deliveryImage = File(pickedFile.path));
      }
    } catch (e, stack) {
      Logger.error('Error capturing delivery photo', name: 'ProofOfDeliveryScreen', error: e, stackTrace: stack);
    }
  }

  Future<void> _submitDelivery() async {
    if (_signatureController == null || _signatureController!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a signature'), backgroundColor: AppColors.primaryOrange),
      );
      return;
    }

    if (_currentStop == null) return;

    setState(() => _isSubmitting = true);

    try {
      final String routeId = _currentStop!.routeId;
      final Uint8List? signatureBytes = await _signatureController!.toPngBytes();
      
      if (signatureBytes != null) {
        String? signatureUrl;
        String? photoUrl;

        final uploads = await Future.wait([
          if (_deliveryImage != null)
            _storageService.uploadDeliveryProof(routeId: routeId, imageFile: _deliveryImage!),
          _storageService.uploadSignature(routeId: routeId, signatureBytes: signatureBytes),
        ]);

        if (_deliveryImage != null) photoUrl = uploads[0];
        signatureUrl = _deliveryImage != null ? uploads[1] : uploads[0];

        final prov = Provider.of<RouteProvider>(context, listen: false);
        await prov.updateStopStatus(
          _currentStop!.stopId, 
          'Completed', 
          podUrl: photoUrl, 
          signatureUrl: signatureUrl
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proof of delivery submitted!'), backgroundColor: AppColors.successGreen),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Securing Delivery Proof to Cloud...'),
      );
    }

    if (_currentStop == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('OptiFlow', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm Delivery', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text('ACTIVE STOP', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('ID: ${_currentStop!.stopId.split('-').last}', style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSmallBadge('PROOF REQUIRED', Colors.grey[200]!, AppColors.textLight),
                      _buildSmallBadge('SAFE WORK', Colors.orange[100]!, AppColors.primaryOrange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: _takeDeliveryPhoto,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGray,
                              borderRadius: BorderRadius.circular(12),
                              image: _deliveryImage != null
                                ? DecorationImage(image: FileImage(_deliveryImage!), fit: BoxFit.cover)
                                : null,
                            ),
                            child: _deliveryImage == null ? const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey) : null,
                          ),
                          Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Goods Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text(
                    'Ensure all security seals are visible and the package is placed in the designated safe zone.',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Delivery Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LOCATION NAME', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  Text(_currentStop!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('GPS COORDINATES', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  Text(
                    '${_currentStop!.lat.toStringAsFixed(4)}, ${_currentStop!.lng.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Digital Signature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _signatureController?.clear(), 
                  child: const Text('CLEAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Signature(
                  controller: _signatureController!,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _submitDelivery,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Confirm & Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}
