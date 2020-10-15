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
  int _currentPageIndex = 0;
  int _numberOfCards = 0;

  @override
  void initState() {
    super.initState();

    _cardsController = PageController(initialPage: 300);

    ShakeDetector.autoStart(onPhoneShake: () {
      _randomDraw();
    });
  }

  Future<List<EssentielCardData>> _getCardsDataFuture() {
    //TODO Leverage GSheets API
    final allCardsData = Category.values
        .toList()
        .expand((category) => category.essentielCards())
        .toList();
    allCardsData.shuffle();
    return Future.delayed(Duration(seconds: 5), () => allCardsData);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getCardsDataFuture(),
        builder: (BuildContext context,
            AsyncSnapshot<List<EssentielCardData>> snapshot) {
          Widget body;
          if (snapshot.hasData) {
            final allCardsData = snapshot.data;
            if (allCardsData == null || allCardsData.isEmpty) {
              _numberOfCards = 0;
              body = Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Flexible(
                        child: Text(
                            "Pas de données trouvées pour initialiser le jeu. Merci de réessayer dans quelques instants.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20,
                                height: 1.7,
                                color: Colors.white))),
                  ]));
            } else {
              _numberOfCards = allCardsData.length;
              body = StackedCardCarousel(
                pageController: _cardsController,
                onPageChanged: (int pageIndex) {
                  _currentPageIndex = pageIndex;
                },
                type: StackedCardCarouselType.cardsStack,
                items: allCardsData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cardData = entry.value;
                  return EssentialCard(
                      cardData: cardData, onFlip: () => _jumpTo(index));
                }).toList(),
              );
            }
          } else {
            _numberOfCards = 0;
            //Loading
            body = Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 20.0,
                  ),
                  Flexible(
                      child: Text(
                          "Initialisation en cours. Merci de patienter quelques instants...",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20, height: 1.7, color: Colors.white))),
                ]));
          }

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
                            left: screenWidth * 0.05,
                            right: screenWidth * 0.05),
                        height: screenHeight * 0.5,
                        child: body,
                      )),
                ),
              ],
            ),
            floatingActionButton: (snapshot.hasData != null &&
                    snapshot.data != null &&
                    snapshot.data.isNotEmpty)
                ? FloatingActionButton.extended(
                    onPressed: () {
                      _randomDraw();
                    },
                    label: Text("Je choisis une carte au hasard"),
                    icon: FaIcon(FontAwesomeIcons.random),
                    backgroundColor: Category.EVANGELISATION.color(),
                  )
                : null,
          );
        });
  }

  void _randomDraw() {
    final randomPick = RandomUtils.getRandomValueInRangeButExcludingValue(
        0, _numberOfCards, _currentPageIndex);
    debugPrint(
        "_currentPageIndex=$_currentPageIndex / randomPick=$randomPick / _numberOfCards=$_numberOfCards");
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
