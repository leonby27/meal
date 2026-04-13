import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String mealType;
  final String? dateStr;

  const BarcodeScannerScreen({
    super.key,
    required this.mealType,
    this.dateStr,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
  );

  bool _isProcessing = false;
  String? _lastScannedCode;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final code = barcode.rawValue!;
    if (code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
      _errorMessage = null;
    });

    try {
      final api = ApiClient();
      await api.ensureAuthenticated();
      final response = await api.get('/api/products/barcode/$code');

      if (!mounted) return;

      final db = await AppDatabase.getInstance();
      final product = await db.cacheServerProduct(response);
      await _showGramsDialogAndAdd(product);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404) {
        setState(() {
          _errorMessage = context.l10n.nothingFound;
          _isProcessing = false;
        });
        _resetAfterDelay();
      } else {
        setState(() {
          _errorMessage = e.message;
          _isProcessing = false;
        });
        _resetAfterDelay();
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isProcessing = false;
      });
      _resetAfterDelay();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.nothingFound;
        _isProcessing = false;
      });
      _resetAfterDelay();
    }
  }

  void _resetAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _lastScannedCode = null;
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _showGramsDialogAndAdd(Product product) async {
    final controller = TextEditingController(
      text: product.weightGrams?.toInt().toString() ?? '100',
    );

    final grams = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.caloriesPer100g != null)
              Text(
                context.l10n.per100gInfo(
                  product.caloriesPer100g!.toInt(),
                  product.proteinPer100g?.toStringAsFixed(1) ?? '-',
                  product.fatPer100g?.toStringAsFixed(1) ?? '-',
                  product.carbsPer100g?.toStringAsFixed(1) ?? '-',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.gramsDialogLabel,
                suffixText: context.l10n.gramsUnit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final g = double.tryParse(controller.text);
              Navigator.pop(ctx, g);
            },
            child: Text(context.l10n.add),
          ),
        ],
      ),
    );

    if (grams == null || grams <= 0 || !mounted) {
      setState(() => _isProcessing = false);
      _lastScannedCode = null;
      return;
    }

    final factor = grams / 100.0;
    final date = widget.dateStr != null
        ? DateFormat('yyyy-MM-dd').parse(widget.dateStr!)
        : DateTime.now();

    final db = await AppDatabase.getInstance();
    await db.addFoodLog(FoodLogsCompanion.insert(
      id: const Uuid().v4(),
      productId: drift.Value(product.productId),
      productName: product.name,
      mealType: widget.mealType,
      mealDate: DateTime(date.year, date.month, date.day, 12),
      grams: grams,
      protein: drift.Value((product.proteinPer100g ?? 0) * factor),
      fat: drift.Value((product.fatPer100g ?? 0) * factor),
      carbs: drift.Value((product.carbsPer100g ?? 0) * factor),
      calories: drift.Value((product.caloriesPer100g ?? 0) * factor),
      imageUrl: drift.Value(product.imageUrl),
    ));

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.l10n.barcodeScannerTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          _buildOverlay(),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (_errorMessage != null)
            Positioned(
              bottom: 120,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: Text(
              context.l10n.barcodeScanHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final top = (constraints.maxHeight - scanAreaSize) / 2 - 40;
        final left = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: top,
                    left: left,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: top,
              left: left,
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
