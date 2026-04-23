import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'debug_actions.dart';
import 'debug_widgets.dart';

class DebugFlightEditor extends StatefulWidget {
  final Map<String, dynamic> flight;
  final DebugActions actions;
  final VoidCallback onSaved;

  const DebugFlightEditor({
    super.key,
    required this.flight,
    required this.actions,
    required this.onSaved,
  });

  @override
  State<DebugFlightEditor> createState() => _DebugFlightEditorState();
}

class _DebugFlightEditorState extends State<DebugFlightEditor> {
  late DateTime _departureAt;
  late DateTime _arrivalAt;
  late TextEditingController _aircraftCtrl;
  late TextEditingController _totalSeatsCtrl;
  late TextEditingController _availSeatsCtrl;
  late TextEditingController _priceCtrl;
  late String _status;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.flight;
    _departureAt = DateTime.parse(f['departure_at'] as String).toLocal();
    _arrivalAt   = DateTime.parse(f['arrival_at'] as String).toLocal();
    _aircraftCtrl    = TextEditingController(text: f['aircraft'] as String);
    _totalSeatsCtrl  = TextEditingController(text: '${f['total_seats']}');
    _availSeatsCtrl  = TextEditingController(text: '${f['avail_seats']}');
    _priceCtrl       = TextEditingController(
        text: (f['price'] as num).toDouble().toStringAsFixed(0));
    _status = f['status'] as String;
  }

  @override
  void dispose() {
    _aircraftCtrl.dispose();
    _totalSeatsCtrl.dispose();
    _availSeatsCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isDeparture) async {
    final initial = isDeparture ? _departureAt : _arrivalAt;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.background,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.gold,
            onPrimary: AppColors.background,
            surface: AppColors.surfaceElevated,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isDeparture) {
        _departureAt = result;
      } else {
        _arrivalAt = result;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.actions.updateFlight(widget.flight['id'] as String, {
        'departure_at': _departureAt.toUtc().toIso8601String(),
        'arrival_at':   _arrivalAt.toUtc().toIso8601String(),
        'aircraft':     _aircraftCtrl.text.trim(),
        'total_seats':  int.tryParse(_totalSeatsCtrl.text) ?? widget.flight['total_seats'],
        'avail_seats':  int.tryParse(_availSeatsCtrl.text) ?? widget.flight['avail_seats'],
        'price':        double.tryParse(_priceCtrl.text) ?? widget.flight['price'],
        'status':       _status,
      });
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(), style: const TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeId = (widget.flight['route_id'] as String?) ?? widget.flight['id'] as String;
    final origin  = widget.flight['origin_code'] as String;
    final dest    = widget.flight['dest_code'] as String;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          const DebugHandle(),
          const SizedBox(height: 16),
          DebugSectionHeader(
            icon: Icons.edit_rounded,
            label: routeId,
            trailing: Text(
              '$origin → $dest',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),

          // ── Departure / Arrival ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _DateTimeField(
                label: 'Departure',
                value: _departureAt,
                onTap: () => _pickDateTime(true),
              )),
              const SizedBox(width: 12),
              Expanded(child: _DateTimeField(
                label: 'Arrival',
                value: _arrivalAt,
                onTap: () => _pickDateTime(false),
              )),
            ],
          ),
          const SizedBox(height: 16),

          // ── Aircraft ────────────────────────────────────────────────────────
          _FieldLabel('Aircraft'),
          _DebugTextField(controller: _aircraftCtrl),
          const SizedBox(height: 16),

          // ── Seats ───────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Total seats'),
                  _DebugTextField(
                    controller: _totalSeatsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Avail seats'),
                  _DebugTextField(
                    controller: _availSeatsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              )),
            ],
          ),
          const SizedBox(height: 16),

          // ── Price ───────────────────────────────────────────────────────────
          _FieldLabel('Price (\$)'),
          _DebugTextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          ),
          const SizedBox(height: 16),

          // ── Status ──────────────────────────────────────────────────────────
          _FieldLabel('Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: flightStatuses.map((s) => GestureDetector(
              onTap: () => setState(() => _status = s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: s == _status
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: s == _status
                        ? AppColors.gold.withValues(alpha: 0.6)
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    color: s == _status ? AppColors.gold : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 32),

          // ── Save ────────────────────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.background))
                  : const Text('Save',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  const _DateTimeField({required this.label, required this.value, required this.onTap});

  String _fmt(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    return '$mm/$dd  $hh:$mn';
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_fmt(value),
                        style: const TextStyle(color: AppColors.white, fontSize: 13)),
                  ),
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _DebugTextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _DebugTextField({
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: AppColors.white, fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
        ),
      );
}
