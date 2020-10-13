import 'dart:math';

import 'package:essentiel/game/cards.dart';
import 'package:essentiel/resources/category.dart';
import 'package:essentiel/utils.dart';
import 'package:essentiel/widgets/animated_background.dart';
import 'package:essentiel/widgets/animated_wave.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_cards/infinite_cards.dart';
import 'package:shake/shake.dart';

class Game extends StatefulWidget {
  final String title;

  const Game({Key key, this.title}) : super(key: key);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> {
  InfiniteCardsController _controller;
  bool _isTypeSwitch = true;

  int _startIndex;
  int _currentIndex;

  Widget _renderItem(
      BuildContext context, List<EssentielCard> allCards, int index) {
    final essentielCard = allCards.elementAt(index);
    return FlipCard(
      front: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.black, width: 2.0),
            color: Colors.white),
        padding: EdgeInsets.all(18),
        child: Image.asset("assets/images/essentiel_logo.svg.png",
            fit: BoxFit.fill),
      ),
      back: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 2.0),
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    essentielCard.question,
                    style: TextStyle(
                        fontSize: 28.0, color: essentielCard.category.color()),
                  ),
                ),
                Positioned.fill(
                    child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: essentielCard.category.color(),
                    ),
                    child: Text(
                      essentielCard.category.title(),
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          )
          // child: ClipRect(
          //   child: Banner(
          //     location: BannerLocation.bottomEnd,
          //     message: essentielCard.category.title(),
          //     color:
          //         essentielCard.category.color() ?? Color(0xA0B71C1C),
          //     textStyle: TextStyle(fontSize: 10.0),
          //     child: Center(
          //       child: Padding(
          //         padding: const EdgeInsets.all(8.0),
          //         child: Text(
          //           essentielCard.question,
          //           style: TextStyle(fontSize: 22.0),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startIndex = 0;

    final allCards = Category.values
        .expand((category) => category.essentielCards())
        .toList();
    allCards.shuffle();

    _controller = InfiniteCardsController(
      itemBuilder: (BuildContext context, int index) =>
          _renderItem(context, allCards, index),
      itemCount: 5,
      animType: AnimType.SWITCH,
    );

    ShakeDetector.autoStart(onPhoneShake: () {
      _randomDraw(allCards.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    debugPrint("Start index: $_startIndex");

    _currentIndex = _startIndex;

    final int maxCards = 20;

    final allCards = Category.values
        .expand((category) => category.essentielCards())
        .toList();
    allCards.shuffle();

    final allColors =
        Category.values.map((category) => category.color()).toList();

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      //   elevation: 0.0,
      //   // backgroundColor: Colors.teal,
      // ),
      // appBar: GradientAppBar(
      //     elevation: 0.0,
      //     title: Text(widget.title),
      //     gradient: LinearGradient(
      //         colors: [Category.FORMATION.color(), Category.PRIERE.color()])),
      body: Stack(
        children: [
          Positioned.fill(child: AnimatedBackground()),
          onBottom(AnimatedWave(
            height: 180,
            speed: 1.0,
          )),
          onBottom(AnimatedWave(
            height: 120,
            speed: 0.9,
            offset: pi,
          )),
          onBottom(AnimatedWave(
            height: 220,
            speed: 1.2,
            offset: pi / 2,
          )),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                  top: screenHeight * 0.08, left: screenWidth * 0.03),
              child: Text(
                widget.title,
                style: TextStyle(fontSize: 30.0, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: InfiniteCards(
              background: Colors.transparent,
              height: screenHeight * 0.3,
              width: screenWidth,
              controller: _controller,
            ),
            // child: Swiper(
            //   index: _startIndex,
            //   controller: _swiperController,
            //   itemBuilder: (BuildContext context, int index) {
            //     final essentielCard = allCards.elementAt(index);
            //     return FlipCard(
            //       front: Container(
            //         decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(8.0),
            //             border: Border.all(color: Colors.black, width: 2.0),
            //             color: Colors.white),
            //         padding: EdgeInsets.all(screenWidth * 0.12),
            //         child: Image.asset("assets/images/essentiel_logo.svg.png",
            //             fit: BoxFit.fill),
            //       ),
            //       back: Container(
            //           decoration: BoxDecoration(
            //               borderRadius: BorderRadius.circular(8.0),
            //               border: Border.all(color: Colors.black, width: 2.0),
            //               color: Colors.white),
            //           child: Padding(
            //             padding: const EdgeInsets.all(8.0),
            //             child: Stack(
            //               children: [
            //                 Center(
            //                   child: Text(
            //                     essentielCard.question,
            //                     style: TextStyle(
            //                         fontSize: 28.0,
            //                         color: essentielCard.category.color()),
            //                   ),
            //                 ),
            //                 Positioned.fill(
            //                     child: Align(
            //                   alignment: Alignment.bottomCenter,
            //                   child: Container(
            //                     padding: const EdgeInsets.all(5.0),
            //                     decoration: BoxDecoration(
            //                       color: essentielCard.category.color(),
            //                     ),
            //                     child: Text(
            //                       essentielCard.category.title(),
            //                       style: TextStyle(
            //                         fontSize: 22.0,
            //                         color: Colors.white,
            //                       ),
            //                     ),
            //                   ),
            //                 )),
            //               ],
            //             ),
            //           )
            //           // child: ClipRect(
            //           //   child: Banner(
            //           //     location: BannerLocation.bottomEnd,
            //           //     message: essentielCard.category.title(),
            //           //     color:
            //           //         essentielCard.category.color() ?? Color(0xA0B71C1C),
            //           //     textStyle: TextStyle(fontSize: 10.0),
            //           //     child: Center(
            //           //       child: Padding(
            //           //         padding: const EdgeInsets.all(8.0),
            //           //         child: Text(
            //           //           essentielCard.question,
            //           //           style: TextStyle(fontSize: 22.0),
            //           //         ),
            //           //       ),
            //           //     ),
            //           //   ),
            //           // ),
            //           ),
            //     );
            //   },
            //   itemCount: allCards.length,
            //   itemWidth: screenWidth * 0.8,
            //   itemHeight: screenHeight * 0.3,
            //   layout: SwiperLayout.STACK,
            //   onIndexChanged: (int index) {
            //     debugPrint("index changed: $index");
            //     _currentIndex = index;
            //   },
            //   loop: true,
            //   autoplay: false,
            //   autoplayDisableOnInteraction: true,
            // ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _randomDraw(maxCards);
          // _swiperController.move(3, animation: true);
        },
        label: Text("Choisir une carte au hasard"),
        icon: Icon(Icons.autorenew_sharp),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _randomDraw(int maxCards) {
    final randomPick = RandomUtils.getRandomValueInRange(0, maxCards - 1);
    debugPrint("randomPick: $randomPick");
    // for (int i = 0; i < randomPick; i++) {
    //   _controller.reset(animType: AnimType.TO_END);
    //   _controller.next();
    // }

    _controller.reset(animType: AnimType.TO_END);
    _controller.next();

    //TODO Flip Card at index i
  }

  onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );

  void _changeType(BuildContext context) {
    if (_isTypeSwitch) {
      _controller.reset(
        itemCount: 4,
        animType: AnimType.TO_FRONT,
        transformToBack: _customToBackTransform,
      );
    } else {
      _controller.reset(
        itemCount: 5,
        animType: AnimType.SWITCH,
        transformToBack: DefaultToBackTransform,
      );
    }
    _isTypeSwitch = !_isTypeSwitch;
  }

  Transform _customToBackTransform(
      Widget item,
      double fraction,
      double curveFraction,
      double cardHeight,
      double cardWidth,
      int fromPosition,
      int toPosition) {
    int positionCount = fromPosition - toPosition;
    double scale =
        (0.8 - 0.1 * fromPosition) + (0.1 * fraction * positionCount);
    double rotateY;
    double translationX;
    if (fraction < 0.5) {
      translationX = cardWidth * fraction * 1.5;
      rotateY = pi / 2 * fraction;
    } else {
      translationX = cardWidth * 1.5 * (1 - fraction);
      rotateY = pi / 2 * (1 - fraction);
    }
    double interpolatorScale =
        0.8 - 0.1 * fromPosition + (0.1 * curveFraction * positionCount);
    double translationY = -cardHeight * (0.8 - interpolatorScale) * 0.5 -
        cardHeight *
            (0.02 * fromPosition - 0.02 * curveFraction * positionCount);
    return Transform.translate(
      offset: Offset(translationX, translationY),
      child: Transform.scale(
        scale: scale,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(rotateY),
          alignment: Alignment.center,
          child: item,
        ),
      ),
    );
  }
}
