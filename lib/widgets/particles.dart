import 'dart:math';

import 'package:essentiel/widgets/particle_model.dart';
import 'package:essentiel/widgets/particle_painter.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

class Particles extends StatefulWidget {
  final int numberOfParticles;

  Particles(this.numberOfParticles);

  @override
  _ParticlesState createState() => _ParticlesState();
}

class _ParticlesState extends State<Particles> {
  final Random random = Random();

  final List<ParticleModel> particles = [];

  @override
  void initState() {
    List.generate(widget.numberOfParticles, (index) {
      particles.add(ParticleModel(random));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LoopAnimation<int>(
      duration: Duration(seconds: 20),
      tween: ConstantTween(1),
      //onTick: _simulateParticles,
      builder: (context, child, value) {
        return CustomPaint(
          painter: ParticlePainter(particles, DateTime.now().duration()),
        );
      },
    );
  }

  _simulateParticles(Duration time) {
    particles.forEach((particle) => particle.maintainRestart(time));
  }
}
