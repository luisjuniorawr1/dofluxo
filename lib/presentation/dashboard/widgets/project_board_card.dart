import 'package:flutter/material.dart';

import '../config/dashboard_stages.dart';
import '../models/project_board_item.dart';

class ProjectBoardCard extends StatefulWidget {
  const ProjectBoardCard({
    super.key,
    required this.item,
    required this.stage,
    this.compact = false,
    this.isDragging = false,
    this.isPlaceholder = false,
    this.onTap,
  });

  final ProjectBoardItem item;
  final DashboardStage stage;
  final bool compact;
  final bool isDragging;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  @override
  State<ProjectBoardCard> createState() => _ProjectBoardCardState();
}

class _ProjectBoardCardState extends State<ProjectBoardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final background =
        widget.item.isCompleted ? widget.stage.completedCardBackground : widget.stage.cardBackground;
    final textColor = _textColorFor(background);
    final radius = widget.compact ? 12.0 : 12.0;
    final canHover = !widget.isDragging && !widget.isPlaceholder;
    final showHover = canHover && _isHovered;

    final elevation = widget.isDragging ? 8.0 : (showHover ? 5.0 : 1.0);
    final scale = showHover ? 1.02 : 1.0;

    Widget card = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        elevation: elevation,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.all(widget.compact ? 8 : 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            border: showHover
                ? Border.all(
                    color: textColor.withValues(alpha: 0.35),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckBadge(isCompleted: widget.item.isCompleted, textColor: textColor),
              SizedBox(width: widget.compact ? 8 : 10),
              Expanded(
                child: _CardContent(
                  item: widget.item,
                  textColor: textColor,
                  compact: widget.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isPlaceholder) {
      return Opacity(opacity: 0.3, child: card);
    }

    if (canHover && widget.onTap != null) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: widget.onTap, child: card),
      );
    } else if (canHover) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: card,
      );
    }

    return card;
  }

  Color _textColorFor(Color background) {
    return background.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.isCompleted, required this.textColor});

  final bool isCompleted;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: textColor.withValues(alpha: 0.35), width: 1.5),
        color: isCompleted ? textColor.withValues(alpha: 0.12) : Colors.transparent,
      ),
      child: Icon(
        isCompleted ? Icons.check_rounded : Icons.circle_outlined,
        size: 16,
        color: textColor.withValues(alpha: isCompleted ? 1 : 0.45),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.item,
    required this.textColor,
    required this.compact,
  });

  final ProjectBoardItem item;
  final Color textColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      fontWeight: FontWeight.w800,
      color: textColor,
      height: 1.25,
    );
    final bodyStyle = TextStyle(
      fontSize: compact ? 9.5 : 10.5,
      color: textColor.withValues(alpha: 0.92),
      height: 1.35,
    );
    final statusStyle = bodyStyle.copyWith(fontWeight: FontWeight.w700);

    final lines = <Widget>[];

    if (item.title.isNotEmpty) {
      lines.add(Text(item.title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis));
    }

    if (item.clientName != null && item.clientName!.isNotEmpty) {
      lines.add(Text(item.clientName!, style: bodyStyle.copyWith(fontWeight: FontWeight.w700)));
    }

    if (item.expectedDeliveryDate != null && item.expectedDeliveryDate!.isNotEmpty) {
      lines.add(Text('ENTREGA PREVISTA: ${item.expectedDeliveryDate}', style: bodyStyle));
    }

    if (item.description != null && item.description!.isNotEmpty) {
      lines.add(Text(item.description!, style: bodyStyle, maxLines: compact ? 2 : 3, overflow: TextOverflow.ellipsis));
    }

    if (item.statusLabel != null && item.statusLabel!.isNotEmpty) {
      lines.add(Text(item.statusLabel!, style: statusStyle));
    }

    if (lines.isEmpty) {
      lines.add(Text('Sem informações', style: bodyStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) SizedBox(height: compact ? 2 : 4),
          lines[i],
        ],
      ],
    );
  }
}
