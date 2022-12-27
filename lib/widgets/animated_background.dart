import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tween = MultiTween<DefaultAnimationProperties>()
      ..add(
          DefaultAnimationProperties.color1,
          ColorTween(begin: Color(0xffD38312), end: Colors.lightBlue.shade900),
          Duration(seconds: 3))
      ..add(
          DefaultAnimationProperties.color2,
          ColorTween(begin: Color(0xffA83279), end: Colors.blue.shade600),
          Duration(seconds: 3));

    return MirrorAnimation(
      tween: tween,
      duration: tween.duration,
      builder: (BuildContext context, Widget? child,
          MultiTweenValues<DefaultAnimationProperties> values) {
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                values.get(DefaultAnimationProperties.color1),
                values.get(DefaultAnimationProperties.color2)
              ])),
        );
      },
    );
  }
}
