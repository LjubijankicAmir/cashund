import 'package:cashund/domain/value_objects/category_color.dart';
import 'package:flutter/material.dart';

/// One category color in the current theme.
@immutable
class CategorySwatch {
  const CategorySwatch({required this.mark, required this.label});

  /// Solid marks: the bar beside a category, dots, fills, chart segments.
  final Color mark;

  /// The category's name as text; readable on surfaces (4.5:1).
  final Color label;
}

/// The category palette for the current theme.
///
/// Read with `context.categoryColor(category.color)`.
@immutable
class CategoryColors extends ThemeExtension<CategoryColors> {
  const CategoryColors(this.brightness);

  final Brightness brightness;

  // dart format off
  static const Map<CategoryColor, CategorySwatch> _light = {
    CategoryColor.coral: CategorySwatch(mark: Color(0xFFCF756D), label: Color(0xFFAD5750)),
    CategoryColor.sky: CategorySwatch(mark: Color(0xFF6EB7DF), label: Color(0xFF2D789D)),
    CategoryColor.mustard: CategorySwatch(mark: Color(0xFFB8AE4B), label: Color(0xFF7B7100)),
    CategoryColor.plum: CategorySwatch(mark: Color(0xFFBF8AD5), label: Color(0xFF905DA4)),
    CategoryColor.olive: CategorySwatch(mark: Color(0xFF6E944E), label: Color(0xFF567A34)),
    CategoryColor.periwinkle: CategorySwatch(mark: Color(0xFF4D69B3), label: Color(0xFF4D69B3)),
    CategoryColor.apricot: CategorySwatch(mark: Color(0xFFD68C4D), label: Color(0xFFA55E1A)),
    CategoryColor.teal: CategorySwatch(mark: Color(0xFF039396), label: Color(0xFF007C7F)),
    CategoryColor.rose: CategorySwatch(mark: Color(0xFFEC96B9), label: Color(0xFFA65779)),
    CategoryColor.slate: CategorySwatch(mark: Color(0xFF505E6D), label: Color(0xFF505E6D)),
    CategoryColor.lavender: CategorySwatch(mark: Color(0xFF9173AF), label: Color(0xFF82649F)),
    CategoryColor.cocoa: CategorySwatch(mark: Color(0xFFCAAE9D), label: Color(0xFF846A5B)),
  };

  static const Map<CategoryColor, CategorySwatch> _dark = {
    CategoryColor.coral: CategorySwatch(mark: Color(0xFFA46560), label: Color(0xFFB67570)),
    CategoryColor.sky: CategorySwatch(mark: Color(0xFF86C7EF), label: Color(0xFF86C7EF)),
    CategoryColor.mustard: CategorySwatch(mark: Color(0xFFA9A745), label: Color(0xFFA9A745)),
    CategoryColor.plum: CategorySwatch(mark: Color(0xFFD89BE4), label: Color(0xFFD89BE4)),
    CategoryColor.olive: CategorySwatch(mark: Color(0xFF678D62), label: Color(0xFF699065)),
    CategoryColor.periwinkle: CategorySwatch(mark: Color(0xFF557EC6), label: Color(0xFF5C86CE)),
    CategoryColor.apricot: CategorySwatch(mark: Color(0xFFD08647), label: Color(0xFFD08647)),
    CategoryColor.teal: CategorySwatch(mark: Color(0xFF00ADB9), label: Color(0xFF01ADB9)),
    CategoryColor.rose: CategorySwatch(mark: Color(0xFFEDB9D6), label: Color(0xFFEDB9D6)),
    CategoryColor.slate: CategorySwatch(mark: Color(0xFF66747E), label: Color(0xFF7A8993)),
    CategoryColor.lavender: CategorySwatch(mark: Color(0xFFAE78C1), label: Color(0xFFAE78C1)),
    CategoryColor.cocoa: CategorySwatch(mark: Color(0xFFBFACA1), label: Color(0xFFBFACA1)),
  };
  // dart format on

  CategorySwatch of(CategoryColor color) =>
      (brightness == Brightness.dark ? _dark : _light)[color]!;

  @override
  CategoryColors copyWith({Brightness? brightness}) =>
      CategoryColors(brightness ?? this.brightness);

  // Swatches can't blend between palettes, so switch halfway.
  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) {
    return other is CategoryColors && t >= 0.5 ? other : this;
  }
}

extension CategoryColorContext on BuildContext {
  CategorySwatch categoryColor(CategoryColor color) =>
      Theme.of(this).extension<CategoryColors>()!.of(color);
}
