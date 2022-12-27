import 'package:essentiel/resources/category.dart';
import 'package:essentiel/widgets/particle_model.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class ParticlePainter extends CustomPainter {
  List<ParticleModel> particles;
  Duration time;

  ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final categories = CategoryStore.listAllCategories();
    particles.asMap().forEach((index, particle) {
      final paint = Paint()
        ..color = categories[
                index < categories.length ? index : index % categories.length]
            .color!
            .withAlpha(100);
      var progress = particle.progress(time);
      final animation = particle.tween!.transform(progress);
      final position = Offset(
          animation.get(DefaultAnimationProperties.x) * size.width,
          animation.get(DefaultAnimationProperties.y) * size.height);
      canvas.drawCircle(position, size.width * 0.2 * particle.size!, paint);
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
