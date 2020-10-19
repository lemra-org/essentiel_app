import 'package:essentiel/resources/category.dart';
import 'package:essentiel/widgets/particle_model.dart';
import 'package:flutter/material.dart';

class ParticlePainter extends CustomPainter {
  List<ParticleModel> particles;
  Duration time;

  ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final categories = Category.values;
    particles.asMap().forEach((index, particle) {
      final paint = Paint()
        ..color = categories[
                index < categories.length ? index : index % categories.length]
            .color()
            .withAlpha(100);
      var progress = particle.animationProgress.progress(time);
      final animation = particle.tween.transform(progress);
      final position =
          Offset(animation["x"] * size.width, animation["y"] * size.height);
      canvas.drawCircle(position, size.width * 0.2 * particle.size, paint);
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
