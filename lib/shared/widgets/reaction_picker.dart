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
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((emoji) {
          final isSelected = emoji == selectedReaction;
          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: const Color(0xFF6C63FF)) : null,
              ),
              child: Text(
                emoji,
                style: TextStyle(fontSize: isSelected ? 24 : 20),
              ),
            ),
          );
        }).toList(),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: reactions.entries.map((entry) {
        return GestureDetector(
          onTap: () => onTap?.call(entry.key),
          child: Container(
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
                  style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
