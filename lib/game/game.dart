import 'dart:math';

import 'package:essentiel/game/cards.dart';
import 'package:essentiel/resources/category.dart';
import 'package:essentiel/utils.dart';
import 'package:essentiel/widgets/animated_background.dart';
import 'package:essentiel/widgets/animated_wave.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shake/shake.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';

class Game extends StatefulWidget {
  final String title;

  const Game({Key key, this.title}) : super(key: key);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> {
  PageController _cardsController;
  List<EssentielCardData> _allCardsData;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();

    final allCategories = Category.values.toList();

    _allCardsData =
        allCategories.expand((category) => category.essentielCards()).toList();
    _allCardsData.shuffle();

    _cardsController = PageController(initialPage: _allCardsData.length);

    ShakeDetector.autoStart(onPhoneShake: () {
      _randomDraw();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: AnimatedBackground()),
          _onBottom(AnimatedWave(
            height: 180,
            speed: 1.0,
          )),
          _onBottom(AnimatedWave(
            height: 120,
            speed: 0.9,
            offset: pi,
          )),
          _onBottom(AnimatedWave(
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
          Positioned.fill(
            child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.only(
                      left: screenWidth * 0.05, right: screenWidth * 0.05),
                  height: screenHeight * 0.5,
                  child: StackedCardCarousel(
                    pageController: _cardsController,
                    onPageChanged: (int pageIndex) {
                      _currentPageIndex = pageIndex;
                    },
                    type: StackedCardCarouselType.cardsStack,
                    items: _allCardsData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final cardData = entry.value;
                      return EssentialCard(
                          cardData: cardData, onFlip: () => _jumpTo(index));
                    }).toList(),
                  ),
                )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _randomDraw();
        },
        label: Text("Choisir une carte au hasard"),
        icon: FaIcon(FontAwesomeIcons.random),
        backgroundColor: Category.EVANGELISATION.color(),
      ),
    );
  }

  void _randomDraw() {
    final randomPick = RandomUtils.getRandomValueInRangeButExcludingValue(
        0, _allCardsData.length, _currentPageIndex);
    debugPrint("_currentPageIndex=$_currentPageIndex / randomPick=$randomPick");
    _jumpTo(randomPick);
  }

  _onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );

  _jumpTo(int index) {
    _cardsController.animateToPage(index,
        curve: Curves.ease, duration: Duration(milliseconds: 500));
  }
}
