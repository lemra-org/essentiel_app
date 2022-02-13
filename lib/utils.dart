import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RandomUtils {
  static final _random = Random();
  static final Map<dynamic, int> _cache = Map();

  RandomUtils._();

  static int getRandomValueInRange(int min, int max) {
    int randomValue;
    do {
      randomValue = _random.nextInt(max);
    } while (randomValue < min);

    return randomValue;
  }

  static int getRandomValueInRangeButExcludingValue(
      int min, int max, int excluded) {
    int randomValue;
    do {
      randomValue = _random.nextInt(max);
    } while (randomValue == excluded || randomValue < min);

    return randomValue;
  }

  static int getNamedRandomValueInRange<T>(T key, int min, int max) =>
      _cache.putIfAbsent(key, () => getRandomValueInRange(min, max));
}

class AppUtils {
  static const PREFERENCES_IS_FIRST_LAUNCH_STRING = "isFirstLaunch";

  static Future<bool> isFirstLaunch() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final bool isFirstLaunch = sharedPreferences
            .getBool(AppUtils.PREFERENCES_IS_FIRST_LAUNCH_STRING) ??
        true;

    debugPrint("isFirstLaunch: $isFirstLaunch");

    if (isFirstLaunch) {
      sharedPreferences.setBool(
          AppUtils.PREFERENCES_IS_FIRST_LAUNCH_STRING, false);
    }

    return isFirstLaunch;
  }
}

class ColorUtils {
  static Color? getColorFromHexString(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0X$hexColor"));
    }
    return null;
  }
}
