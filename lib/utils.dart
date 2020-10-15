import 'dart:math';

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
