import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class ParticleModel {
  Animatable? tween;
  double? size;
  AnimationProgress? animationProgress;
  Random? random;

  ParticleModel(this.random) {
    restart();
  }

  restart({Duration time = Duration.zero}) {
    final startPosition =
        Offset(-0.2 + 1.4 * random!.nextDouble(), 1.2 * random!.nextDouble());
    final endPosition =
        Offset(-0.2 + 1.4 * random!.nextDouble(), -0.2 * random!.nextDouble());
    final duration = Duration(milliseconds: 5000 + random!.nextInt(1000));

    tween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: Curves.easeInOutSine),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: Curves.easeIn),
    ]);
    animationProgress = AnimationProgress(duration: duration, startTime: time);
    size = 0.2 + random!.nextDouble() * 0.4;
  }

  maintainRestart(Duration time) {
    if (animationProgress!.progress(time) == 1.0) {
      restart(time: time);
    }
  }
}
