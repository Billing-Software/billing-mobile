import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropdownField<T> extends StatefulWidget {
  final String? label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;
  final bool isCompact;
  final String placeholder;

  const CustomDropdownField({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.prefixIcon,
    this.isCompact = false,
    this.placeholder = 'Select...',
  });

  @override
  State<CustomDropdownField<T>> createState() => _CustomDropdownFieldState<T>();
}

class _CustomDropdownFieldState<T> extends State<CustomDropdownField<T>>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (widget.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No options available for ${widget.label?.replaceAll('*', '').trim() ?? 'selection'}.'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _isOpen = true;
    });
    _animationController.forward();

    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final List<PopupMenuEntry<T>> menuItems = widget.items.map((item) {
      final isSelected = widget.value == item;
      Widget child = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.itemLabel(item),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF006A61) : const Color(0xFF374151),
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_rounded,
              color: Color(0xFF006A61),
              size: 18,
            ),
          ],
        ],
      );

      if (!widget.isCompact) {
        child = SizedBox(
          width: size.width - 32, // Accommodates the default popup menu horizontal padding (16 on each side)
          child: child,
        );
      }

      return PopupMenuItem<T>(
        value: item,
        height: 42,
        child: child,
      );
    }).toList();

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy + size.height + 4,
      ),
      items: menuItems,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.08),
    ).then((selectedItem) {
      _closeDropdown();
      if (selectedItem != null && mounted) {
        widget.onChanged(selectedItem);
      }
    });
  }

  void _closeDropdown() {
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactDropdown();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.inter(
              color: const Color(0xFF374151),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _isOpen ? const Color(0xFF006A61) : const Color(0xFFE5E7EB),
              width: _isOpen ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: const Color(0xFF006A61).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: _toggleDropdown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Icon(widget.prefixIcon, color: const Color(0xFF6B7280), size: 20),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        widget.value != null ? widget.itemLabel(widget.value as T) : widget.placeholder,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: widget.value != null ? const Color(0xFF1A1C1E) : const Color(0xFFADB5BD),
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _isOpen ? const Color(0xFF006A61).withValues(alpha: 0.12) : const Color(0xFF006A61).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isOpen ? const Color(0xFF006A61) : const Color(0xFF006A61).withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _toggleDropdown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.prefixIcon != null) ...[
                  Icon(widget.prefixIcon, color: const Color(0xFF006A61), size: 16),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.value != null ? widget.itemLabel(widget.value as T) : widget.placeholder,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF006A61),
                  ),
                ),
                const SizedBox(width: 4),
                RotationTransition(
                  turns: _rotateAnimation,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF006A61),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
