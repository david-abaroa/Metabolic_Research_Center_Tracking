import 'package:flutter/material.dart';
import '../utils/units.dart';

/// A pair of linked text fields — oz is the primary input, grams is shown
/// alongside and stays in sync; typing in either updates the other.
class DualUnitField extends StatefulWidget {
  final String label;
  final double? initialGrams;
  final ValueChanged<double?> onGramsChanged;

  const DualUnitField({
    super.key,
    required this.label,
    required this.onGramsChanged,
    this.initialGrams,
  });

  @override
  State<DualUnitField> createState() => _DualUnitFieldState();
}

class _DualUnitFieldState extends State<DualUnitField> {
  late final TextEditingController _ozCtrl;
  late final TextEditingController _gramsCtrl;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final grams = widget.initialGrams;
    _ozCtrl = TextEditingController(
        text: grams == null ? '' : _fmt(gramsToOz(grams)));
    _gramsCtrl = TextEditingController(text: grams == null ? '' : _fmt(grams));
    _ozCtrl.addListener(_onOzChanged);
    _gramsCtrl.addListener(_onGramsChanged);
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  void _onOzChanged() {
    if (_syncing) return;
    final oz = double.tryParse(_ozCtrl.text);
    _syncing = true;
    if (oz == null) {
      _gramsCtrl.text = '';
      widget.onGramsChanged(null);
    } else {
      final grams = ozToGrams(oz);
      _gramsCtrl.text = _fmt(grams);
      widget.onGramsChanged(grams);
    }
    _syncing = false;
  }

  void _onGramsChanged() {
    if (_syncing) return;
    final grams = double.tryParse(_gramsCtrl.text);
    _syncing = true;
    if (grams == null) {
      _ozCtrl.text = '';
      widget.onGramsChanged(null);
    } else {
      _ozCtrl.text = _fmt(gramsToOz(grams));
      widget.onGramsChanged(grams);
    }
    _syncing = false;
  }

  @override
  void dispose() {
    _ozCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ozCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: '${widget.label} (oz)'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _gramsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '= grams'),
          ),
        ),
      ],
    );
  }
}
