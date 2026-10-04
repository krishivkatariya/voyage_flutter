import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/itinerary/services/activity_validators.dart';
import 'package:voyage_flutter/models/activity.dart';

class ActivityForm extends StatefulWidget {
  const ActivityForm({
    required this.submitLabel,
    required this.onSubmit,
    this.initialActivity,
    super.key,
  });

  final String submitLabel;
  final Activity? initialActivity;
  final Future<void> Function({
    required String title,
    required String placeName,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? description,
    double? latitude,
    double? longitude,
  })
  onSubmit;

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _placeNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late DateTime? _date;
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;
  bool _isSubmitting = false;
  String? _timeError;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final activity = widget.initialActivity;
    _titleController = TextEditingController(text: activity?.title ?? '');
    _placeNameController = TextEditingController(
      text: activity?.placeName ?? '',
    );
    _descriptionController = TextEditingController(
      text: activity?.description ?? '',
    );
    _latitudeController = TextEditingController(
      text: activity?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: activity?.longitude?.toString() ?? '',
    );
    _date = activity?.date;
    _startTime = activity == null
        ? null
        : ActivityValidators.parseTime(activity.startTime);
    _endTime = activity == null
        ? null
        : ActivityValidators.parseTime(activity.endTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeNameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected != null && mounted) {
      setState(() {
        _date = selected;
        _dateError = null;
      });
    }
  }

  Future<void> _pickTime({required bool isStartTime}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isStartTime) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
      _timeError = ActivityValidators.validateTimes(_startTime, _endTime);
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    final formIsValid = _formKey.currentState!.validate();
    final dateError = ActivityValidators.validateDate(_date);
    final timeError = ActivityValidators.validateTimes(_startTime, _endTime);
    setState(() {
      _dateError = dateError;
      _timeError = timeError;
    });
    if (!formIsValid || dateError != null || timeError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        title: _titleController.text,
        placeName: _placeNameController.text,
        date: _date!,
        startTime: _startTime!,
        endTime: _endTime!,
        description: _descriptionController.text,
        latitude: _coordinateValue(_latitudeController.text),
        longitude: _coordinateValue(_longitudeController.text),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  double? _coordinateValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : double.parse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Activity title',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: ActivityValidators.validateTitle,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _placeNameController,
            decoration: const InputDecoration(
              labelText: 'Place name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: ActivityValidators.validatePlaceName,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              _date == null
                  ? 'Choose date'
                  : ActivityValidators.formatDate(_date!),
            ),
          ),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _dateError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => _pickTime(isStartTime: true),
            icon: const Icon(Icons.schedule),
            label: Text(
              _startTime == null
                  ? 'Choose start time'
                  : 'Start: ${_startTime!.format(context)}',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () => _pickTime(isStartTime: false),
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              _endTime == null
                  ? 'Choose end time'
                  : 'End: ${_endTime!.format(context)}',
            ),
          ),
          if (_timeError != null) ...[
            const SizedBox(height: 8),
            Text(
              _timeError!,
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
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _latitudeController,
            decoration: const InputDecoration(
              labelText: 'Latitude (optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validator: (value) => ActivityValidators.validateCoordinate(
              value,
              minimum: -90,
              maximum: 90,
              label: 'latitude between -90 and 90',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _longitudeController,
            decoration: const InputDecoration(
              labelText: 'Longitude (optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validator: (value) => ActivityValidators.validateCoordinate(
              value,
              minimum: -180,
              maximum: 180,
              label: 'longitude between -180 and 180',
            ),
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
