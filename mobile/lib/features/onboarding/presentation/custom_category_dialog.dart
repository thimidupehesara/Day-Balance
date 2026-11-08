import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/primary_button.dart';
import 'onboarding_controller.dart';

class CustomCategoryDialog extends ConsumerStatefulWidget {
  const CustomCategoryDialog({super.key});
  @override
  ConsumerState<CustomCategoryDialog> createState() =>
      _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends ConsumerState<CustomCategoryDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _color = '#A9CEC6';
  String? _error;
  static const _colors = {
    'Mist': '#B9D0DA',
    'Sand': '#DEC2A5',
    'Lilac': '#C7BADA',
    'Sage': '#C2D1AE',
    'Sea': '#A9CEC6',
    'Rose': '#DBB9B2',
  };
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    final ok = await ref
        .read(onboardingControllerProvider.notifier)
        .addCustomCategory(_name.text, _description.text, _color);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(
        () => _error = ref.read(onboardingControllerProvider).errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return PopScope(
      canPop: !state.isLoading,
      child: Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Make it yours.', style: AppTextStyles.heading),
                  const SizedBox(height: 10),
                  const Text(
                    'Give a personal priority its own space in your day.',
                    style: AppTextStyles.body14,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    enabled: !state.isLoading,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      hintText: 'e.g. Learning guitar',
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return 'Enter a category name';
                      if (state.availableCategories.any(
                        (c) => c.name.toLowerCase() == name.toLowerCase(),
                      )) {
                        return 'That category already exists';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    enabled: !state.isLoading,
                    maxLength: 100,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Choose a color', style: AppTextStyles.caption12),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _colors.entries
                        .map(
                          (entry) => ChoiceChip(
                            label: Text(entry.key),
                            selected: _color == entry.value,
                            selectedColor: Color(
                              int.parse(
                                'FF${entry.value.substring(1)}',
                                radix: 16,
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: _color == entry.value
                                  ? AppColors.textOnPrimary
                                  : AppColors.text,
                            ),
                            onSelected: state.isLoading
                                ? null
                                : (_) => setState(() => _color = entry.value),
                          ),
                        )
                        .toList(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(_error!, style: AppTextStyles.error),
                      ),
                    ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'Add category',
                    isLoading: state.isLoading,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
