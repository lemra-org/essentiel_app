import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final Widget? child;
  final Function? onTap;
  final Color? boxBorderColor;
  final Color? boxColor;
  final double? boxWidth;
  final double? boxHeight;
  final double? borderRadius;
  final double? borderWidth;

  const AnimatedButton(
      {Key? key,
      @required this.child,
      @required this.onTap,
      @required this.boxBorderColor,
      @required this.boxColor,
      this.boxWidth,
      this.boxHeight,
      this.borderRadius,
      this.borderWidth})
      : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  double? _scale;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 0.1,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller?.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller?.reverse();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller!.value;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTap: () => {
        if (widget.onTap != null) {widget.onTap!()}
      },
      child: Transform.scale(
        scale: _scale,
        child: _animatedButtonUI,
      ),
    );
  }

  Widget get _animatedButtonUI => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.boxBorderColor!,
            style: BorderStyle.solid,
            width: widget.borderWidth ?? 2.0,
          ),
          color: widget.boxColor,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 30.0),
        ),
        width: widget.boxWidth,
        height: widget.boxHeight,
        child: Center(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: widget.child,
            ),
          ],
        )),
      );
}
