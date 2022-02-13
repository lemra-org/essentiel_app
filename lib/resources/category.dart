import 'dart:collection';

import 'package:essentiel/utils.dart';
import 'package:flutter/material.dart';

const CATEGORY_FILTER_PREF_KEY = "categories_selected";

class CategoryStore {
  static final Map<String, QuestionCategory> _cache = LinkedHashMap();

  static QuestionCategory put(String name, QuestionCategory category) {
    _cache[name] = category;
    return category;
  }

  static List<QuestionCategory> listAllCategories() => _cache.values.toList();

  static QuestionCategory? findByName(String name) => _cache[name];

  static Map<String, QuestionCategory> findAll() {
    final Map<String, QuestionCategory> all = {
      for (var cat in _cache.entries) cat.key: cat.value
    };
    return all;
  }
}

class QuestionCategory {
  String? title;
  Color? color;

  QuestionCategory(String title, String? hexColor) {
    this.title = title;
    this.color = (hexColor == null || hexColor.trim().isEmpty)
        ? Colors.teal
        : ColorUtils.getColorFromHexString(hexColor);
  }

  factory QuestionCategory.fromGSheet(Map<String, dynamic> json) {
    final categoryName = json['Catégorie'];
    final hexColor = json['Couleur'];
    final category = QuestionCategory(
        categoryName, hexColor != null ? hexColor.toString() : null);
    CategoryStore.put(categoryName, category);
    return category;
  }
}

// enum Category {
//   VIE_FRATERNELLE,
//   PRIERE,
//   FORMATION,
//   SERVICE,
//   EVANGELISATION,
//   ESSENTIELLES_PLUS
// }
//
// extension CategoryColor on Category {
//   Color? color() => {
//         Category.VIE_FRATERNELLE: const Color(0xFFF7B900),
//         Category.PRIERE: const Color(0xFF97205E),
//         Category.FORMATION: const Color(0xFF12A0FF),
//         Category.SERVICE: const Color(0xFF62D739),
//         Category.EVANGELISATION: const Color(0xFFED2910),
//         Category.ESSENTIELLES_PLUS: Colors.teal
//       }[this];
// }

// extension Title on Category {
//   String? title() => const {
//         Category.VIE_FRATERNELLE: "Vie fraternelle",
//         Category.PRIERE: "Prière",
//         Category.EVANGELISATION: "Évangélisation",
//         Category.FORMATION: "Formation chrétienne",
//         Category.SERVICE: "Service",
//         Category.ESSENTIELLES_PLUS: "Essentielles+"
//       }[this];
// }
//
// extension CategoryIcon on Category {
//   IconData? icon() => const {
//         Category.VIE_FRATERNELLE: Icons.ac_unit,
//         Category.PRIERE: Icons.ac_unit,
//         Category.EVANGELISATION: Icons.ac_unit,
//         Category.FORMATION: Icons.ac_unit,
//         Category.SERVICE: Icons.ac_unit,
//         Category.ESSENTIELLES_PLUS: Icons.ac_unit
//       }[this];
// }
