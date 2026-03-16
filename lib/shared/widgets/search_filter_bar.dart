// lib/shared/widgets/search_filter_bar.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A combined search field + optional filter chips row.
class SearchFilterBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSearch;
  final List<String>? filterOptions;
  final String? selectedFilter;
  final ValueChanged<String>? onFilterChanged;
  final Widget? trailing;

  const SearchFilterBar({
    super.key,
    required this.hint,
    required this.onSearch,
    this.filterOptions,
    this.selectedFilter,
    this.onFilterChanged,
    this.trailing,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onSearch,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            widget.onSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 12),
              widget.trailing!,
            ],
          ],
        ),
        if (widget.filterOptions != null && widget.filterOptions!.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.filterOptions!.map((opt) {
                final isSelected = widget.selectedFilter == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(opt),
                    onSelected: (_) => widget.onFilterChanged?.call(opt),
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
