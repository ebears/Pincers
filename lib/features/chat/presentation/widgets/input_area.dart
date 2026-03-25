import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/attachment_model.dart';

const _uuid = Uuid();

class _PendingFile {
  final String name;
  final String mimeType;
  final int sizeBytes;
  final Uint8List bytes;

  const _PendingFile({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
  });
}

class InputArea extends StatefulWidget {
  final void Function(String content, List<AttachmentModel> attachments) onSend;
  final bool enabled;

  const InputArea({super.key, required this.onSend, this.enabled = true});

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<_PendingFile> _pendingFiles = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;

    final newFiles = result.files
        .where((f) => f.bytes != null)
        .map((f) => _PendingFile(
              name: f.name,
              mimeType: lookupMimeType(f.name) ?? 'application/octet-stream',
              sizeBytes: f.size,
              bytes: f.bytes!,
            ))
        .toList();

    setState(() => _pendingFiles.addAll(newFiles));
  }

  void _send() {
    final text = _controller.text.trim();
    if ((text.isEmpty && _pendingFiles.isEmpty) || !widget.enabled) return;

    final attachments = _pendingFiles
        .map((f) => AttachmentModel(
              id: _uuid.v4(),
              filename: f.name,
              mimeType: f.mimeType,
              sizeBytes: f.sizeBytes,
              base64Data: base64.encode(f.bytes),
            ))
        .toList();

    widget.onSend(text, attachments);
    _controller.clear();
    setState(() => _pendingFiles.clear());
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.enabled &&
        (_controller.text.trim().isNotEmpty || _pendingFiles.isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.space16, vertical: AppConstants.space12),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                  minHeight: AppConstants.inputAreaHeight - 24),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusInput),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Attachment preview strip
                  if (_pendingFiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppConstants.space12,
                          AppConstants.space8,
                          AppConstants.space12,
                          0),
                      child: Wrap(
                        spacing: AppConstants.space8,
                        runSpacing: AppConstants.space8,
                        children: _pendingFiles
                            .asMap()
                            .entries
                            .map((e) => _AttachmentPreviewChip(
                                  file: e.value,
                                  onRemove: () => setState(
                                      () => _pendingFiles.removeAt(e.key)),
                                ))
                            .toList(),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: AppConstants.space12,
                            bottom: AppConstants.space12),
                        child: IconButton(
                          icon: const Icon(Icons.attach_file,
                              size: 20, color: AppColors.textMuted),
                          onPressed: widget.enabled ? _pickFiles : null,
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
                                event.logicalKey ==
                                    LogicalKeyboardKey.enter &&
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
                                  vertical: AppConstants.space12),
                              filled: false,
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: AppConstants.space8,
                            bottom: AppConstants.space8),
                        child: _SendButton(
                            onPressed: canSend ? _send : null),
                      ),
                    ],
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

class _AttachmentPreviewChip extends StatelessWidget {
  final _PendingFile file;
  final VoidCallback onRemove;

  const _AttachmentPreviewChip(
      {required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isImage = file.mimeType.startsWith('image/');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.bgHover,
            borderRadius: BorderRadius.circular(AppConstants.radiusButton),
            border: Border.all(color: AppColors.border),
          ),
          child: isImage
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusButton),
                  child: Image.memory(file.bytes, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.insert_drive_file,
                        size: 20, color: AppColors.textSecondary),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        file.name,
                        style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 11, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _SendButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed != null ? AppColors.accent : AppColors.bgHover,
      borderRadius: BorderRadius.circular(AppConstants.radiusButton),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.radiusButton),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(Icons.send_rounded,
              size: 18,
              color: onPressed != null
                  ? Colors.white
                  : AppColors.textMuted),
        ),
      ),
    );
  }
}
