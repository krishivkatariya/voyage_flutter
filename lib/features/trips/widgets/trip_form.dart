import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/trips/services/trip_validators.dart';
import 'package:voyage_flutter/models/trip.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_card.dart';

const Color _formPurple = Color(0xFF6D4AFF);
const Color _formDarkPurple = Color(0xFF38216D);
const Color _formMuted = Color(0xFF77738A);

class TripForm extends StatefulWidget {
  const TripForm({
    required this.submitLabel,
    required this.onSubmit,
    this.initialTrip,
    super.key,
  });

  final String submitLabel;
  final Trip? initialTrip;

  final Future<void> Function({
    required String tripName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required TripType tripType,
    String? description,
  })
  onSubmit;

  @override
  State<TripForm> createState() => TripFormState();
}

class TripFormState extends State<TripForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tripNameController;
  late final TextEditingController _destinationController;
  late final TextEditingController _descriptionController;

  late DateTime? _startDate;
  late DateTime? _endDate;
  late TripType? _tripType;

  bool _isSubmitting = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();

    final trip = widget.initialTrip;

    _tripNameController = TextEditingController(text: trip?.tripName ?? '');
    _destinationController = TextEditingController(
      text: trip?.destination ?? '',
    );
    _descriptionController = TextEditingController(
      text: trip?.description ?? '',
    );

    _startDate = trip?.startDate;
    _endDate = trip?.endDate;
    _tripType = trip?.tripType;
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();

    final initialDate = isStartDate
        ? (_startDate ?? _endDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _formPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _formDarkPurple,
            ),
          ),
          child: child,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isStartDate) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }

      _dateError = TripValidators.validateDates(_startDate, _endDate);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final form = _formKey.currentState;
    if (form == null) return;

    final formIsValid = form.validate();
    final dateError = TripValidators.validateDates(_startDate, _endDate);

    setState(() => _dateError = dateError);

    if (!formIsValid ||
        dateError != null ||
        _startDate == null ||
        _endDate == null ||
        _tripType == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        tripName: _tripNameController.text.trim(),
        destination: _destinationController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        tripType: _tripType!,
        description: _descriptionController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _formPurple),
      filled: true,
      fillColor: const Color(0xFFFBFAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE8E1FA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE8E1FA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _formPurple, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _tripNameController,
            enabled: !_isSubmitting,
            decoration: _inputDecoration(
              label: 'Trip name',
              icon: Icons.luggage_outlined,
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: TripValidators.validateTripName,
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _destinationController,
            enabled: !_isSubmitting,
            decoration: _inputDecoration(
              label: 'Destination',
              icon: Icons.location_on_outlined,
            ),
            textCapitalization: TextCapitalization.words,
            validator: TripValidators.validateDestination,
          ),
          const SizedBox(height: 18),

          DropdownButtonFormField<TripType>(
            initialValue: _tripType,
            isExpanded: true,
            decoration: _inputDecoration(
              label: 'Trip type',
              icon: Icons.group_outlined,
            ),
            items: TripType.values.map((type) {
              return DropdownMenuItem<TripType>(
                value: type,
                child: Text(type.label),
              );
            }).toList(),
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _tripType = value),
            validator: (value) => value == null ? 'Choose a trip type.' : null,
          ),
          const SizedBox(height: 22),

          const Text(
            'Travel dates',
            style: TextStyle(
              color: _formDarkPurple,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          _DateField(
            label: 'Start date',
            date: _startDate,
            onPressed: _isSubmitting
                ? null
                : () => _pickDate(isStartDate: true),
          ),
          const SizedBox(height: 10),

          _DateField(
            label: 'End date',
            date: _endDate,
            onPressed: _isSubmitting
                ? null
                : () => _pickDate(isStartDate: false),
          ),

          if (_dateError != null) ...[
            const SizedBox(height: 8),
            Text(
              _dateError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 22),

          TextFormField(
            controller: _descriptionController,
            enabled: !_isSubmitting,
            decoration: _inputDecoration(
              label: 'Description (optional)',
              icon: Icons.notes_rounded,
            ).copyWith(alignLabelWithHint: true),
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 26),

          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _formPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _formPurple.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded),
                        const SizedBox(width: 9),
                        Text(
                          widget.submitLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime? date;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _formDarkPurple,
        backgroundColor: const Color(0xFFFBFAFF),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
        side: const BorderSide(color: Color(0xFFE8E1FA)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: _formPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _formMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null ? 'Select a date' : formatTripDate(date!),
                  style: const TextStyle(
                    color: _formDarkPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: _formMuted),
        ],
      ),
    );
  }
}
