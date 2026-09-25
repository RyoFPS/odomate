import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/app_localizations.dart';

Future<String?> showPlateNumberSheet(
  BuildContext context, {
  String initialValue = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlateNumberSheet(initialValue: initialValue),
  );
}

class _PlateNumberSheet extends StatefulWidget {
  final String initialValue;

  const _PlateNumberSheet({required this.initialValue});

  @override
  State<_PlateNumberSheet> createState() => _PlateNumberSheetState();
}

class _PlateNumberSheetState extends State<_PlateNumberSheet> {
  late final TextEditingController region;
  late final TextEditingController number;
  late final TextEditingController suffix;

  @override
  void initState() {
    super.initState();
    final current = widget.initialValue.trim().toUpperCase().split(
      RegExp(r'\s+'),
    );
    region = TextEditingController(text: current.elementAtOrNull(0) ?? '');
    number = TextEditingController(text: current.elementAtOrNull(1) ?? '');
    suffix = TextEditingController(text: current.elementAtOrNull(2) ?? '');
  }

  @override
  void dispose() {
    region.dispose();
    number.dispose();
    suffix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.t('plate_update_title'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.t('plate_update_subtitle'),
                  style: TextStyle(color: colors.secondary, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _input(
                        region,
                        l10n.t('plate_region'),
                        2,
                        TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: _input(
                        number,
                        l10n.t('plate_number'),
                        4,
                        TextInputType.number,
                        digitsOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _input(
                        suffix,
                        l10n.t('plate_series'),
                        3,
                        TextInputType.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.t('save_plate')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    int maxLength,
    TextInputType keyboardType, {
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: [
        if (digitsOnly)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  void _save() {
    if (region.text.trim().isEmpty || number.text.trim().isEmpty) return;
    final values = [
      region.text.trim().toUpperCase(),
      number.text.trim(),
      suffix.text.trim().toUpperCase(),
    ].where((value) => value.isNotEmpty).join(' ');
    Navigator.of(context).pop(values);
  }
}
