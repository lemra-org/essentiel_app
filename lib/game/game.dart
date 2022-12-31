import 'dart:math';

import 'package:essentiel/game/cards.dart';
import 'package:essentiel/resources/category.dart';
import 'package:essentiel/utils.dart';
import 'package:essentiel/widgets/animated_background.dart';
import 'package:essentiel/widgets/animated_wave.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gsheets/gsheets.dart';
import 'package:shake/shake.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';

const _credentials = r'''
{
  "type": "service_account",
  "project_id": "essentiel-app",
  "private_key_id": "xxx",
  "private_key": "xxx",
  "client_email": "xxx",
  "client_id": "xxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "xxx"
}
''';

const _spreadsheetId = '1cR8lE6eCvDrgUXAVD1bmm36j6v5MtOEurSOAEfrTcCI';

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

  Future<List<EssentielCardData>> _getCardsDataFuture(GSheets gsheets) async {
    final spreadsheet = await gsheets.spreadsheet(_spreadsheetId);
    final questionsListJson =
        await spreadsheet.worksheetByTitle('Questions').values.map.allRows();
    if (questionsListJson == null) {
      return <EssentielCardData>[];
    }
    return questionsListJson
        .map((questionJson) => EssentielCardData.fromGSheet(questionJson))
        .where((element) =>
            element.category != null &&
            element.question != null &&
            element.question.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final gsheets = GSheets(_credentials);
    return FutureBuilder(
        future: _getCardsDataFuture(gsheets),
        builder: (BuildContext context,
            AsyncSnapshot<List<EssentielCardData>> snapshot) {
          Widget body;
          if (snapshot.hasError) {
            final error = snapshot.error;
            _numberOfCards = 0;
            body = Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Icon(
                    Icons.error,
                    color: Colors.redAccent,
                    size: 50,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Flexible(
                      child: Text(
                          "Une erreur s'est produite. Merci de réessayer dans quelques instants.\n\n$error",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20, height: 1.7, color: Colors.white))),
                ]));
          } else {
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
                        color: Colors.orangeAccent,
                        size: 50,
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      Flexible(
                          child: Text(
                              "Aucune donnée trouvée pour initialiser le jeu Essentiel. Merci de réessayer dans quelques instants.",
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
                                fontSize: 20,
                                height: 1.7,
                                color: Colors.white))),
                  ]));
            }
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
