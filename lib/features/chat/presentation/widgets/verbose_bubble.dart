import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/message_model.dart';

/// Renders a single tool-call activity entry in verbose mode.
///
/// Content format: "$toolName\n$argsJson" — tool name on the first line,
/// JSON-encoded arguments on the remainder.
class VerboseBubble extends StatefulWidget {
  final MessageModel message;

  const VerboseBubble({super.key, required this.message});

  @override
  State<VerboseBubble> createState() => _VerboseBubbleState();
}

class _VerboseBubbleState extends State<VerboseBubble> {
  bool _expanded = false;

  ({String toolName, String argsJson}) get _parts {
    final nl = widget.message.content.indexOf('\n');
    if (nl == -1) return (toolName: widget.message.content, argsJson: '{}');
    return (
      toolName: widget.message.content.substring(0, nl),
      argsJson: widget.message.content.substring(nl + 1),
    );
  }

  String _prettyArgs(String raw) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (:toolName, :argsJson) = _parts;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space16,
        vertical: 2,
      ),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      toolName,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.expand_more,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 6),
                SelectableText(
                  _prettyArgs(argsJson),
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
