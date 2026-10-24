import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_store/controllers/manager_controller.dart';
import 'package:app_store/widgets/manager/manager_components.dart';

class CreateManagerUserDialog extends StatefulWidget {
  final ManagerController controller;
  final String initialRole;
  const CreateManagerUserDialog({
    super.key,
    required this.controller,
    this.initialRole = 'employee',
  });

  static Future<bool?> show(
    BuildContext context,
    ManagerController controller, {
    String role = 'employee',
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        CreateManagerUserDialog(controller: controller, initialRole: role),
  );

  @override
  State<CreateManagerUserDialog> createState() =>
      _CreateManagerUserDialogState();
}

class _CreateManagerUserDialogState extends State<CreateManagerUserDialog> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final name in ['id_user', 'nom', 'prenom', 'cin', 'teleph', 'pw_user'])
      name: TextEditingController(),
  };
  late String _role = widget.initialRole;
  DateTime? _birthday;
  bool _saving = false, _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.createUser({
        for (final field in _fields.entries)
          field.key: field.key == 'pw_user'
              ? field.value.text
              : field.value.text.trim(),
        'role': _role,
        'date_naiss': _birthday == null
            ? null
            : '${_birthday!.year.toString().padLeft(4, '0')}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}',
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }
  Widget _field(
  String key,
  String label, {
  bool required = true,
  int max = 50,
  Color color =  ManagerColors.muted,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    controller: _fields[key],
    enabled: !_saving,
    maxLength: max,
    obscureText: key == 'pw_user' && _hidePassword,
    style: TextStyle(
      color: color,
    ),
    keyboardType: key == 'cin'
        ? TextInputType.number
        : key == 'teleph'
            ? TextInputType.phone
            : TextInputType.text,
    inputFormatters: key == 'cin'
        ? [FilteringTextInputFormatter.digitsOnly]
        : null,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: color,
      ),
      floatingLabelStyle: TextStyle(
        color: color,
      ),
      counterText: '',
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.white54,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.white,
        ),
      ),
      disabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.white38,
        ),
      ),
      suffixIcon: key == 'pw_user'
          ? IconButton(
              onPressed: _saving
                  ? null
                  : () => setState(
                        () => _hidePassword = !_hidePassword,
                      ),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: color,
              ),
            )
          : null,
    ),
    validator: (value) {
      if (required && (value == null || value.trim().isEmpty)) {
        return '$label is required';
      }
      if (key == 'cin' && !RegExp(r'^\d{8}$').hasMatch(value ?? '')) {
        return 'Enter exactly 8 digits';
      }
      return null;
    },
  ),
);

@override
Widget build(BuildContext context) => PopScope(
  canPop: !_saving,
  child: AlertDialog(
    backgroundColor: ManagerColors.card,
    title: const Text(
      'Create team account',
      style: TextStyle(
        color: Colors.white,
      ),
    ),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _role,
                style: const TextStyle(
                  color: Colors.white,
                ),
                dropdownColor: ManagerColors.card,
                iconEnabledColor: Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white54,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'employee',
                    child: Text(
                      'Employee',
                      style: TextStyle(
                        color: ManagerColors.muted,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'supplier',
                    child: Text(
                      'Supplier',
                      style: TextStyle(
                        color: ManagerColors.muted,
                      ),
                    ),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _role = value!),
              ),
              const SizedBox(height: 16),
              _field('id_user', 'Username'),
              _field('prenom', 'First name'),
              _field('nom', 'Last name'),
              _field('cin', 'CIN', max: 8),
              _field(
                'teleph',
                'Phone (optional)',
                required: false,
                max: 20,
              ),
              _field('pw_user', 'Password'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white54,
                        ),
                      ),
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        _birthday == null
                            ? 'Birth date (optional)'
                            : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
                        style: const TextStyle(
                          color: ManagerColors.muted,
                        ),
                      ),
                      onPressed: _saving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _birthday ?? DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && mounted) {
                                setState(() => _birthday = picked);
                              }
                            },
                    ),
                  ),
                  if (_birthday != null)
                    IconButton(
                      tooltip: 'Clear birth date',
                      onPressed: _saving
                          ? null
                          : () => setState(() => _birthday = null),
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor:  ManagerColors.gold,
        ),
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Text(
              'Create account',
              style: TextStyle(
                color: ManagerColors.border,
              ),
            ),
      ),
    ],
  ),
);
}
