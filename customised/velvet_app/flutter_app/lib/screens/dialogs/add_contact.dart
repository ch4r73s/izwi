import 'package:flutter/material.dart';
import 'package:outgoing_notifications/models/Contact.dart';

Future<void> showAddContactDialog(
  BuildContext context,
  Function(Contact) onAddContact, {
  List<String> districtSuggestions = const [],
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  TextEditingController? districtController;
  String? ageRange;
  String? sex;

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add Contact'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Invalid email'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: ageRange,
                        decoration: const InputDecoration(labelText: 'Age Range'),
                        items: const [
                          DropdownMenuItem(value: 'Infant', child: Text('Infant')),
                          DropdownMenuItem(value: 'Child', child: Text('Child')),
                          DropdownMenuItem(value: 'Teen', child: Text('Teen')),
                          DropdownMenuItem(value: 'Adult', child: Text('Adult')),
                          DropdownMenuItem(
                            value: 'Senior Adult',
                            child: Text('Senior Adult'),
                          ),
                        ],
                        onChanged: (v) => setState(() => ageRange = v),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: sex,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(
                            value: 'Non-Binary',
                            child: Text('Non-Binary'),
                          ),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => sex = v),
                      ),
                      const SizedBox(height: 10),
                      Autocomplete<String>(
                        initialValue: const TextEditingValue(text: 'Harare'),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text.toLowerCase();
                          if (query.isEmpty) return districtSuggestions;
                          return districtSuggestions.where(
                            (d) => d.toLowerCase().contains(query),
                          );
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          districtController = controller;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'District',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;

                  onAddContact(
                    Contact(
                      name: nameController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      emailAddress: emailController.text.trim(),
                      address: addressController.text.trim(),
                      ageRange: ageRange,
                      sex: sex,
                      district: districtController?.text.trim(),
                      isPaused: false,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}
