import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

class ParticleModel {
  MultiTween<DefaultAnimationProperties>? tween;
  double? size;
  Random? random;

  Duration? startTime;
  Duration? duration;

  ParticleModel(this.random) {
    restart();
  }

  restart({Duration time = Duration.zero}) {
    final startPosition =
        Offset(-0.2 + 1.4 * random!.nextDouble(), 1.2 * random!.nextDouble());
    final endPosition =
        Offset(-0.2 + 1.4 * random!.nextDouble(), -0.2 * random!.nextDouble());
    final duration = Duration(milliseconds: 5000 + random!.nextInt(1000));

    tween = MultiTween<DefaultAnimationProperties>()
      ..add(
          DefaultAnimationProperties.x,
          startPosition.dx.tweenTo(endPosition.dx),
          duration,
          Curves.easeInOutSine)
      ..add(DefaultAnimationProperties.y,
          startPosition.dy.tweenTo(endPosition.dy), duration, Curves.easeIn);

    this.startTime = time;
    this.duration = duration;
    size = 0.2 + random!.nextDouble() * 0.4;
  }

  maintainRestart(Duration time) {
    if (startTime == null) {
      startTime = time;
      restart(time: time);
      return;
    }
    if (progress(time) == 1.0) {
      restart(time: time);
    }
  }

  double progress(Duration time) {
    if (startTime == null) {
      return 0.0;
    }
    if (duration != null && duration!.inMicroseconds != 0) {
      return ((time - startTime!).inMicroseconds /
          duration!.inMicroseconds).clamp(0.0, 1.0).toDouble();
    }
    return 0.0;
  }
}
