import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/attachment_model.dart';

const _uuid = Uuid();

/// Provider that DropTarget in ChatArea writes to; InputArea consumes it.
final droppedFilesProvider = StateProvider<List<XFile>>((ref) => const []);

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

class InputArea extends ConsumerStatefulWidget {
  final void Function(String content, List<AttachmentModel> attachments) onSend;
  final bool enabled;

  const InputArea({super.key, required this.onSend, this.enabled = true});

  @override
  ConsumerState<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends ConsumerState<InputArea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<_PendingFile> _pendingFiles = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _processDroppedFiles(List<XFile> files) async {
    final newFiles = await Future.wait(files.map((f) async {
      final bytes = await f.readAsBytes();
      final mime = lookupMimeType(f.name) ?? 'application/octet-stream';
      return _PendingFile(
        name: f.name,
        mimeType: mime,
        sizeBytes: bytes.length,
        bytes: bytes,
      );
    }));
    if (mounted) setState(() => _pendingFiles.addAll(newFiles));
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
    // Consume dropped files from DropTarget in ChatArea
    ref.listen<List<XFile>>(droppedFilesProvider, (_, files) {
      if (files.isNotEmpty) {
        _processDroppedFiles(files);
        ref.read(droppedFilesProvider.notifier).state = const [];
      }
    });

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
                            .map((e) {
                              final f = e.value;
                              final isImage = f.mimeType.startsWith('image/');
                              return InputChip(
                                avatar: isImage
                                    ? ClipOval(
                                        child: Image.memory(
                                          f.bytes,
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.insert_drive_file, size: 16),
                                label: Text(
                                  f.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onDeleted: () => setState(
                                    () => _pendingFiles.removeAt(e.key)),
                              );
                            })
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
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              _send();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
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
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: AppConstants.space8,
                            bottom: AppConstants.space8),
                        child: IconButton.filled(
                          onPressed: canSend ? _send : null,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: canSend ? AppColors.accent : AppColors.bgHover,
                            foregroundColor: canSend ? Colors.white : AppColors.textMuted,
                            minimumSize: const Size(36, 36),
                            fixedSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          tooltip: 'Send',
                        ),
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






