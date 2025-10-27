import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PriceTextField extends StatefulWidget {
  const PriceTextField({
    super.key,
    required this.controller,
    this.displayText = "Price",
  });

  final TextEditingController controller;
  final String displayText;

  @override
  State<PriceTextField> createState() => _PriceTextFieldState();
}

class _PriceTextFieldState extends State<PriceTextField> {
  final _formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  late final TextEditingController _controller;
  late final String _display;
  bool _isFormatting = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _display = widget.displayText;
    _controller.addListener(_formatValue);
  }

  void _formatValue() {
    if (_isFormatting) return;

    final text = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) {
      _controller.value = TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
      return;
    }

    _isFormatting = true;

    // Interpret as cents
    final value = double.parse(text) / 100;
    final newText = _formatter.format(value);

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );

    _isFormatting = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_formatValue);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: _display,
        prefixIcon: const Icon(Icons.attach_money),
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}
