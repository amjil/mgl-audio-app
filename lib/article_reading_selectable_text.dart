import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mgl_editor_core/mgl_selectable_text.dart';

/// Bridge widget used by CLJD page:
/// - Renders body with MglSelectableText.
/// - Uses caret geometry to auto-correct horizontal scroll position.
class ArticleReadingSelectableText extends StatefulWidget {
  final TextSpan textSpan;
  final int selectionStart;
  final int selectionEnd;
  final bool autoScroll;
  final ScrollController? scrollController;

  const ArticleReadingSelectableText({
    super.key,
    required this.textSpan,
    required this.selectionStart,
    required this.selectionEnd,
    this.autoScroll = false,
    this.scrollController,
  });

  @override
  State<ArticleReadingSelectableText> createState() =>
      _ArticleReadingSelectableTextState();
}

class _ArticleReadingSelectableTextState
    extends State<ArticleReadingSelectableText> {
  final GlobalKey _textKey = GlobalKey();
  double? _lastTarget;

  int _clampOffset(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  void _autoScrollToSelection() {
    if (!mounted || !widget.autoScroll) return;
    final ctrl = widget.scrollController;
    if (ctrl == null || !ctrl.hasClients) return;

    final text = widget.textSpan.toPlainText();
    final textLen = text.length;
    if (textLen <= 0) return;

    final start = _clampOffset(widget.selectionStart, 0, textLen);
    final end = _clampOffset(widget.selectionEnd, 0, textLen);
    final caretOffset = math.max(start, end);

    final caretGlobal =
        MglSelectableText.getGlobalOffsetForCaret(_textKey, caretOffset);
    if (caretGlobal == null) return;

    final ctx = _textKey.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;

    // Convert caret global point to paragraph-local coordinates.
    final localCaret = ro.globalToLocal(caretGlobal);

    final maxExtent = ctrl.position.maxScrollExtent;
    final viewport = ctrl.position.viewportDimension;
    final current = ctrl.offset;

    // Keep current sentence close to viewport center.
    final target =
        (current + localCaret.dx - viewport * 0.5).clamp(0.0, maxExtent);
    final targetDouble = target.toDouble();
    final delta = (targetDouble - current).abs();

    // Ignore tiny corrections to reduce jitter.
    if (_lastTarget != null && (targetDouble - _lastTarget!).abs() < 8.0) {
      return;
    }
    if (delta < 12.0) return;

    _lastTarget = targetDouble;
    ctrl
        .animateTo(
          targetDouble,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        )
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollToSelection();
    });

    final text = widget.textSpan.toPlainText();
    final textLen = text.length;
    final start = _clampOffset(widget.selectionStart, 0, textLen);
    final end = _clampOffset(widget.selectionEnd, 0, textLen);

    return MglSelectableText(
      textKey: _textKey,
      textSpan: widget.textSpan,
      selection: TextSelection(baseOffset: start, extentOffset: end),
      isFocused: widget.autoScroll,
      showCursor: false,
      showLineDivider: false,
    );
  }
}
