import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Assuming you have a provider for saving feeding records, but for now
// we will just define the UI. The GenUi interaction handles the 'submit' flow
// usually by capturing the output.
class GenUiFeedingForm extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>)? onSubmit;

  const GenUiFeedingForm({
    super.key,
    this.initialData = const {},
    this.onSubmit,
  });

  @override
  ConsumerState<GenUiFeedingForm> createState() => _GenUiFeedingFormState();
}

class _GenUiFeedingFormState extends ConsumerState<GenUiFeedingForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _animalIdController;
  late TextEditingController _feedTypeController;
  late TextEditingController _quantityController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _animalIdController = TextEditingController(
      text: widget.initialData['animalId'] ?? '',
    );
    _feedTypeController = TextEditingController(
      text: widget.initialData['feedType'] ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.initialData['quantity']?.toString() ?? '',
    );

    final dateStr = widget.initialData['date'];
    if (dateStr != null) {
      _selectedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _animalIdController.dispose();
    _feedTypeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Log Feeding",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _animalIdController,
                decoration: const InputDecoration(
                  labelText: 'Animal Tag / ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter animal ID'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedTypeController,
                decoration: const InputDecoration(
                  labelText: 'Feed Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grass),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter feed type'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter quantity';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  "Date: ${DateFormat.yMMMd().format(_selectedDate)}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      'animalId': _animalIdController.text,
                      'feedType': _feedTypeController.text,
                      'quantity': double.parse(_quantityController.text),
                      'date': _selectedDate.toIso8601String(),
                    };

                    if (widget.onSubmit != null) {
                      widget.onSubmit!(data);
                    } else {
                      // If no callback, we might trigger a provider directly or
                      // just show a success message for this demo.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Action recorded! (Simulation)"),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
