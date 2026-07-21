import 'package:flutter/material.dart';
import '../../../core/utils/date_format_utils.dart';

class ExpectedDeliveryDateField extends StatelessWidget {
  const ExpectedDeliveryDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.labelText,
    this.helpText,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;
  final String? labelText;
  final String? helpText;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: helpText ?? 'Data de conclusão prevista',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );

    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = value != null
        ? DateFormatUtils.formatDayMonthYear(value!)
        : 'Selecionar data';

    return InputDecorator(
      decoration: InputDecoration(
        labelText: required
            ? '${labelText ?? 'Data de conclusão prevista'} *'
            : (labelText ?? 'Data de conclusão prevista'),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.event_outlined),
        suffixIcon: value != null
            ? IconButton(
                tooltip: 'Remover data',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close),
              )
            : null,
      ),
      child: InkWell(
        onTap: () => _pickDate(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: value != null
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
