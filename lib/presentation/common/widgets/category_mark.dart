import 'package:cashund/core/theme/category_colors.dart';
import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:flutter/material.dart';

/// The thin colored bar that marks a category next to its name.
class CategoryMark extends StatelessWidget {
  const CategoryMark({required this.color, this.height = 24, super.key});

  final CategoryColor color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: context.categoryColor(color).mark,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
