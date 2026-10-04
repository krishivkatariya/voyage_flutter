import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/trips/services/trip_validators.dart';
import 'package:voyage_flutter/models/trip.dart';
import 'package:voyage_flutter/features/trips/widgets/trip_card.dart';

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
    );
    if (picked == null || !mounted) {
      return;
    }

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
    if (_isSubmitting) {
      return;
    }
    final formIsValid = _formKey.currentState!.validate();
    final dateError = TripValidators.validateDates(_startDate, _endDate);
    setState(() => _dateError = dateError);
    if (!formIsValid || dateError != null || _tripType == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        tripName: _tripNameController.text,
        destination: _destinationController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        tripType: _tripType!,
        description: _descriptionController.text,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _tripNameController,
            decoration: const InputDecoration(
              labelText: 'Trip name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: TripValidators.validateTripName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'Destination',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: TripValidators.validateDestination,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TripType>(
            initialValue: _tripType,
            decoration: const InputDecoration(
              labelText: 'Trip type',
              border: OutlineInputBorder(),
            ),
            items: TripType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _tripType = value),
            validator: (value) => value == null ? 'Choose a trip type.' : null,
          ),
          const SizedBox(height: 16),
          _DateField(
            label: 'Start date',
            date: _startDate,
            onPressed: _isSubmitting
                ? null
                : () => _pickDate(isStartDate: true),
          ),
          const SizedBox(height: 8),
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
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
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(date == null ? label : '$label: ${formatTripDate(date!)}'),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
