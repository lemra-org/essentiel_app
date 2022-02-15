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
