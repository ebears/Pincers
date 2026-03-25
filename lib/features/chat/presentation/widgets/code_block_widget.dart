import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class CodeBlockWidget extends StatefulWidget {
  final String code;
  final String? language;

  const CodeBlockWidget({super.key, required this.code, this.language});

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _hovered = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppConstants.space4),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar: language label + copy button
            if (widget.language != null || _hovered)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.space12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusButton),
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.language != null)
                      Text(
                        widget.language!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: GestureDetector(
                        onTap: _copy,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _copied ? Icons.check : Icons.copy,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _copied ? 'Copied!' : 'Copy',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Code content: max 400px tall, scrollable both axes
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: HighlightView(
                    widget.code,
                    language: widget.language ?? 'plaintext',
                    theme: atomOneDarkTheme,
                    padding: const EdgeInsets.all(AppConstants.space12),
                    textStyle: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final String? langClass = element.attributes['class'];
    // Inline code has no class; block code has class like 'language-dart'
    final bool isBlock = langClass != null || element.textContent.contains('\n');
    if (!isBlock) return null;

    final String language =
        (langClass != null && langClass.startsWith('language-'))
            ? langClass.substring(9)
            : '';

    return CodeBlockWidget(
      code: element.textContent,
      language: language.isEmpty ? null : language,
    );
  }
}
