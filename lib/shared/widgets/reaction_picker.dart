import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../../core/theme/app_colors.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;
  final String? selectedReaction;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.selectedReaction,
  });

  static const List<String> reactions = ['🔥', '😂', '😭', '😱', '❤️', '👏', '🤯', '💀'];

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: reactions.map((emoji) {
            final isSelected = emoji == selectedReaction;
            return GestureDetector(
              onTap: () => onReactionSelected(emoji),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 8, vertical: isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.electricPurple.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: AppColors.electricPurple.withValues(alpha: 0.5)) : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.electricPurple.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: isSelected ? 22 : 18),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ReactionDisplay extends StatelessWidget {
  final Map<String, int> reactions;
  final Function(String)? onTap;

  const ReactionDisplay({
    super.key,
    required this.reactions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox();

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.entries.map((entry) {
          return GestureDetector(
            onTap: () => onTap?.call(entry.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value}',
                    style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
