import 'dart:math';

import 'package:essentiel/game/cards.dart';
import 'package:essentiel/resources/category.dart';
import 'package:essentiel/widgets/animated_background.dart';
import 'package:essentiel/widgets/animated_wave.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gsheets/gsheets.dart';
import 'package:shake/shake.dart';

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

const title = 'Jeu Essentiel';

//Inpiration from https://dribbble.com/shots/7696045-Tarot-App-Design
class GameV3 extends StatefulWidget {
  @override
  _GameV3State createState() => _GameV3State();
}

class _GameV3State extends State<GameV3> {
  List<EssentielCard> _allCards;
  Object _errorWhileLoadingData;
  int _currentIndex;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gsheets = GSheets(_credentials);
      gsheets
          .spreadsheet(_spreadsheetId)
          .then((spreadsheet) =>
              spreadsheet.worksheetByTitle('Questions').values.map.allRows())
          .then((questionsListJson) => Future.value((questionsListJson == null)
              ? <EssentielCardData>[]
              : questionsListJson
                  .map((questionJson) =>
                      EssentielCardData.fromGSheet(questionJson))
                  .where((element) =>
                      element.category != null &&
                      element.question != null &&
                      element.question.trim().isNotEmpty)
                  .toList()))
          .then((cardData) {
        setState(() {
          _errorWhileLoadingData = null;
          _allCards = cardData.asMap().entries.map((entry) {
            final index = entry.key;
            final cardData = entry.value;
            return EssentielCard(
                index: index, cardData: cardData, onFlip: () => _jumpTo(index));
          }).toList();
        });
      }).catchError((e) {
        setState(() {
          _errorWhileLoadingData = e;
          _allCards = null;
        });
      });
    });

    ShakeDetector.autoStart(onPhoneShake: () {
      _randomDraw();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Widget body;
    if (_errorWhileLoadingData != null) {
      //Oh no!
      body = Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                "Une erreur s'est produite. Merci de réessayer dans quelques instants.\n\n$_errorWhileLoadingData",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 20, height: 1.7, color: Colors.white))),
      ]));
    } else if (_allCards == null) {
      //Not initialized yet
      body = Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(),
        SizedBox(
          height: 20.0,
        ),
        Flexible(
            child: Text(
                "Initialisation en cours. Merci de patienter quelques instants...",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 20, height: 1.7, color: Colors.white))),
      ]));
    } else if (_allCards.isEmpty) {
      //No data
      body = Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                style:
                    TextStyle(fontSize: 20, height: 1.7, color: Colors.white))),
      ]));
    } else {
      //Yeah - we have some data !
      body = Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
                // height: screenHeight * 0.4,
                padding: const EdgeInsets.all(10.0),
                color: Colors.orangeAccent,
                child: (_currentIndex == null)
                    ? Center(
                        child: Flexible(
                            child: Text(
                                "Merci de sélectionner une carte en dessous ou d'en choisir une au hasard.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20,
                                    height: 1.7,
                                    color: Colors.white))),
                      )
                    :
                    //TODO
                    Container(child: Text('TODO'))),
          ),
          SizedBox(
            height: 20.0,
          ),
          Expanded(
              flex: 2,
              child: Container(
                // height: screenHeight * 0.1,
                color: Colors.greenAccent,
              ))
        ],
      );
      //FIXME
      // body = StackedCardCarousel(
      //   pageController: _cardsController,
      //   onPageChanged: (int pageIndex) {
      //     _currentPageIndex = pageIndex;
      //     // if (currentPageIndex)
      //   },
      //   type: StackedCardCarouselType.cardsStack,
      //   items: _allCards.toList(),
      // );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
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
                padding: EdgeInsets.only(top: screenHeight * 0.03, left: 10.0),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 30.0, color: Colors.white),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: EdgeInsets.only(
                        top: screenHeight * 0.1,
                        bottom: screenHeight * 0.1,
                        left: 10.0,
                        right: 10.0),
                    // height: screenHeight * 0.5,
                    child: body,
                  )),
            ),
          ],
        ),
      ),
      floatingActionButton: (_allCards != null && _allCards.isNotEmpty)
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
  }

  void _randomDraw() {
    //TODO
    final _numberOfCards = _allCards.length;
    // final randomPick = RandomUtils.getRandomValueInRangeButExcludingValue(
    //     0, _numberOfCards, _currentPageIndex);
    // debugPrint(
    //     "_currentPageIndex=$_currentPageIndex / randomPick=$randomPick / _numberOfCards=$_numberOfCards");
    // _jumpTo(randomPick);
  }

  _onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );

  _jumpTo(int index) {
    //TODO
    // _cardsController.animateToPage(index,
    //     curve: Curves.ease, duration: Duration(milliseconds: 500));
  }
}
