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

  static const _purple = Color(0xFF6548E8);
  static const _borderColor = Color(0xFFE6E1F2);

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

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _purple),
      filled: true,
      fillColor: const Color(0xFFFAF9FE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _purple, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF25213A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF77738A)),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE9F6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34236B).withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dateTimeButton({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback? onPressed,
    bool selected = false,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(15),
        foregroundColor: _purple,
        side: const BorderSide(color: _borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _purple, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF77738A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFF25213A)
                        : const Color(0xFF77738A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF9993AD)),
        ],
      ),
    );
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

    if (selected == null || !mounted) return;

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
    if (_isSubmitting) return;

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 650;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6548E8), Color(0xFF8B72F4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plan something amazing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add the details to make this stop part '
                                'of your journey.',
                                style: TextStyle(
                                  color: Color(0xFFEDE8FF),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.explore_rounded,
                          size: 48,
                          color: Color(0xFFEDE8FF),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Activity details',
                          'Give your activity a name and location.',
                        ),
                        TextFormField(
                          controller: _titleController,
                          decoration: _decoration(
                            label: 'Activity title',
                            icon: Icons.edit_location_alt_outlined,
                            hint: 'e.g. Visit a famous landmark',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: ActivityValidators.validateTitle,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _placeNameController,
                          decoration: _decoration(
                            label: 'Place name',
                            icon: Icons.location_on_outlined,
                            hint: 'e.g. Statue of Unity',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: ActivityValidators.validatePlaceName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _decoration(
                            label: 'Description (optional)',
                            icon: Icons.notes_rounded,
                            hint: 'Add notes about this activity',
                          ),
                          minLines: 2,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Date and time',
                          'Choose when you plan to visit.',
                        ),
                        _dateTimeButton(
                          icon: Icons.calendar_month_rounded,
                          title: 'Activity date',
                          value: _date == null
                              ? 'Choose a date'
                              : ActivityValidators.formatDate(_date!),
                          selected: _date != null,
                          onPressed: _isSubmitting ? null : _pickDate,
                        ),
                        if (_dateError != null) ...[
                          const SizedBox(height: 7),
                          Text(
                            _dateError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: _dateTimeButton(
                                  icon: Icons.schedule_rounded,
                                  title: 'Start time',
                                  value:
                                      _startTime?.format(context) ??
                                      'Choose start time',
                                  selected: _startTime != null,
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _pickTime(isStartTime: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dateTimeButton(
                                  icon: Icons.alarm_rounded,
                                  title: 'End time',
                                  value:
                                      _endTime?.format(context) ??
                                      'Choose end time',
                                  selected: _endTime != null,
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _pickTime(isStartTime: false),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _dateTimeButton(
                            icon: Icons.schedule_rounded,
                            title: 'Start time',
                            value:
                                _startTime?.format(context) ??
                                'Choose start time',
                            selected: _startTime != null,
                            onPressed: _isSubmitting
                                ? null
                                : () => _pickTime(isStartTime: true),
                          ),
                          const SizedBox(height: 12),
                          _dateTimeButton(
                            icon: Icons.alarm_rounded,
                            title: 'End time',
                            value:
                                _endTime?.format(context) ?? 'Choose end time',
                            selected: _endTime != null,
                            onPressed: _isSubmitting
                                ? null
                                : () => _pickTime(isStartTime: false),
                          ),
                        ],
                        if (_timeError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _timeError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'Map coordinates',
                          'Optional: specify the exact location.',
                        ),
                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latitudeController,
                                  decoration: _decoration(
                                    label: 'Latitude',
                                    icon: Icons.my_location_rounded,
                                    hint: '-90 to 90',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  validator: (value) =>
                                      ActivityValidators.validateCoordinate(
                                        value,
                                        minimum: -90,
                                        maximum: 90,
                                        label: 'latitude between -90 and 90',
                                      ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _longitudeController,
                                  decoration: _decoration(
                                    label: 'Longitude',
                                    icon: Icons.public_rounded,
                                    hint: '-180 to 180',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  validator: (value) =>
                                      ActivityValidators.validateCoordinate(
                                        value,
                                        minimum: -180,
                                        maximum: 180,
                                        label: 'longitude between -180 and 180',
                                      ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          TextFormField(
                            controller: _latitudeController,
                            decoration: _decoration(
                              label: 'Latitude (optional)',
                              icon: Icons.my_location_rounded,
                              hint: '-90 to 90',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (value) =>
                                ActivityValidators.validateCoordinate(
                                  value,
                                  minimum: -90,
                                  maximum: 90,
                                  label: 'latitude between -90 and 90',
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _longitudeController,
                            decoration: _decoration(
                              label: 'Longitude (optional)',
                              icon: Icons.public_rounded,
                              hint: '-180 to 180',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (value) =>
                                ActivityValidators.validateCoordinate(
                                  value,
                                  minimum: -180,
                                  maximum: 180,
                                  label: 'longitude between -180 and 180',
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _isSubmitting ? 'Saving...' : widget.submitLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
