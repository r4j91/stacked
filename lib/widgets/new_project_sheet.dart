import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/haptic_service.dart';
import '../services/project_repository.dart';
import '../services/supabase_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/palette_colors.dart';
import 'app_button.dart';
import 'app_sheet.dart';
import 'pressable.dart';

/// Opens the standard "Novo projeto" sheet (AppSheet + color picker + AppButton).
Future<void> showNewProjectSheet(
  BuildContext context, {
  VoidCallback? onCreated,
  bool useRootNavigator = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: AppSheet(
        title: 'Novo projeto',
        scrollable: true,
        child: NewProjectSheetForm(onCreated: onCreated),
      ),
    ),
  );
}

class NewProjectSheetForm extends StatefulWidget {
  final VoidCallback? onCreated;

  const NewProjectSheetForm({super.key, this.onCreated});

  @override
  State<NewProjectSheetForm> createState() => _NewProjectSheetFormState();
}

class _NewProjectSheetFormState extends State<NewProjectSheetForm> {
  static final _colorPalette = PaletteColors.projectColors;

  late final TextEditingController _nameCtrl;
  late Color _selectedColor;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _selectedColor = _colorPalette.first;
    _nameCtrl.addListener(() {
      if (_nameError != null && _nameCtrl.text.trim().isNotEmpty) {
        setState(() => _nameError = null);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedInput => _nameCtrl.text.trim().isNotEmpty;

  InputDecoration _nameDecoration() => InputDecoration(
        labelText: 'Nome do projeto',
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintText: 'Ex.: Reforma da cozinha',
        hintStyle: TextStyle(color: AppColors.textTertiary),
        errorText: _nameError,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.priorityHigh, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.priorityHigh, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Future<void> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Descartar projeto?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'O nome digitado será perdido.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Continuar editando',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Descartar',
              style: TextStyle(
                color: AppColors.priorityHigh,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Digite um nome para o projeto');
      return;
    }
    HapticService().saved();
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    if (!mounted) return;
    Navigator.pop(context);
    final hexColor =
        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    try {
      await const ProjectRepository().createProject(
        name: name,
        colorHex: hexColor,
        userId: userId,
      );
      widget.onCreated?.call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasUnsavedInput) _confirmDiscard();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              cursorColor: AppColors.accent,
              decoration: _nameDecoration(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Cor',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorPalette.map((c) {
                final selected = c == _selectedColor;
                final hex =
                    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Cor do projeto $hex',
                  child: Pressable(
                    onTap: () {
                      HapticService().selectionClick();
                      setState(() => _selectedColor = c);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: selected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                      ),
                      child: selected
                          ? const HugeIcon(
                              icon: HugeIcons.strokeRoundedTick01,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Criar projeto',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
