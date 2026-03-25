import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';

class InputArea extends StatefulWidget {
  final void Function(String content) onSend;
  final bool enabled;

  const InputArea({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space16,
        vertical: AppConstants.space12,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: AppConstants.inputAreaHeight - 24),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppConstants.radiusInput),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: AppConstants.space12, bottom: AppConstants.space12),
                    child: IconButton(
                      icon: const Icon(Icons.attach_file, size: 20, color: AppColors.textMuted),
                      onPressed: widget.enabled ? () {} : null,
                      tooltip: 'Attach file',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          _send();
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        maxLines: AppConstants.inputMaxLines,
                        minLines: 1,
                        style: AppTypography.inputText,
                        decoration: const InputDecoration(
                          hintText: 'Message Aralobster...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppConstants.space12,
                            vertical: AppConstants.space12,
                          ),
                          filled: false,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppConstants.space8, bottom: AppConstants.space8),
                    child: _SendButton(onPressed: widget.enabled ? _send : null),
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

class _SendButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _SendButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(AppConstants.radiusButton),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.radiusButton),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
