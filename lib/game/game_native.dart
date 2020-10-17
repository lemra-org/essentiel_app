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

const _credentials = r'''
{
  "type": "service_account",
  "project_id": "essentiel-app",
  "private_key_id": "96abfc77058910deaa08486e5c3e26180b600710",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDRBDm/B3Urne/E\nbpb6nLdpK/tzJqA6cpvOM1oEm+6fncofyHcyyRs/SkIDJrKDyO5VVV1Icc1sbBOZ\n58hWvVHkHhVVlrHT8+okQ7dS62J/wckuSAoUf03c0f2VmM6bzCz2kt3cSkNZgrrx\nsDwfn7t88YPBeNsNg4zUsdU9yhEdnVh4W256GTDXJDOKdE7EioEvJQJoWO3xC6W5\nu+Wmr2ZfHGWps6f1EVO7J0yQsNaThL8SJswYgA10NcMUWB52KkTHa9BANMFBusdK\nhsN3JowTYmg6BX4nBvOXk9Y9POLhNeVyK+GFGpEwh1wYJMAnz9MmERx7MIMPdoU3\nulWyYdm9AgMBAAECggEAD06XagmCR7Tzy7droCPc/LtHWWoBPvaIuYOiOocu5QqZ\ntFUqgZIfyDVIe1GYrjUHW0F6qOUIrcGGd/V1AwEvX5ziZBe6ozKQOaKp6M0rM/79\nnEGTV2fxTFQmlY+QxfEgc9hSniDkKMh9p1iINqqsgNxxETioFifFpwf0/WbwdPIg\nmF/GHcZFuDf8FaY4fCYRHeSoDczKs7VmJYk8SrRPszCvWaB0ujlbfxoRD6GO2WQk\nCKsilN1ufiOhChzj/2d9Ur6FpBFp0qXZnLmclZ00bYVn7luhzQv8XeB29d21sHq7\nsv5VP+rVdMp/EWfgfcA37Ha4qjwJtAMF7dLKrGABowKBgQDocl3LwmdAOdWc/kQI\n1ZZBnnP3MdyMSbcPi2n10aqmbaOTldR1BNe8voy25Ho7YOOT8sU74MiLRtoIFl8Y\nQcJFXwI4G0HsP/qDBZDpn87WvfoOl8j9VZRocsVRRdQd5vZD6HCaZ3qEUgAyl0g1\nPv6pO2awi2b7gmyml9Nzu3WnkwKBgQDmMhUUHQt/B6CNxCbFjb2/m3pmo1UEas/j\nIDEJMq0XqLJ6UYq+n5JwzFr++tQXIiX8fObe3adGP0YQuLBzZn3843Jmv2pDfr3T\nbUyd5yRk4vODi0VE2w9Pps12GAsoH9tKgOb53h7sbrtxFuFLluCYlcu5kuMAjCxN\nk+OMljWrbwKBgQCHxJ0icXcrXVx2qVEFs/NienGTlc0TJ89DxhNq4D8DnJBpmJ8S\nhnSYKtg3zzXRzuK+PJOVSNL5/rVE+gQrP+V/7WF3cfxMSIZC1xJwUsZWSXpv4Zok\n1kKryzWTJe0iVg/LVE3I8d3uwZKZ+iDT8Op/4FE3lwTcrK5Xk+CO/ZRX/wKBgQDR\nI3NPIMxPDwjpg+qN1actK/7avU4Cg2B4Q8kJSEdGlXgB9Y+OfL+5R5Ds08pZcib8\n7CV9GfhdtCLeEk4NqnKQjbxkaUgMJlwkeMsBMv03w5HmU2QNmNCiVzOYNWP9gmPj\nnpU7Mnj56ejWaCksWdmYB5Bd+3vOBYxCtzgnhFkidQKBgEwLBHiIqNIeFRcuXhRw\n4PQ6fzHMK2l60CTpfjQZugXONLIpYOmIqU73DmFVNOjGyMEPSLvGkrbQq/NnKPU+\ny0bzWHQp2Tu9A5MFtIl0asELgZl45pGKisENdZOZm9w/a90eMzJ7x72vtOqqaggF\nl+rd+vKwhImb1oOdFlRIpM0b\n-----END PRIVATE KEY-----\n",
  "client_email": "essentiel-mobile-app@essentiel-app.iam.gserviceaccount.com",
  "client_id": "108214015117832858585",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/essentiel-mobile-app%40essentiel-app.iam.gserviceaccount.com"
}
''';

const _spreadsheetId = '1cR8lE6eCvDrgUXAVD1bmm36j6v5MtOEurSOAEfrTcCI';

class GameNative extends StatefulWidget {
  final String title;

  const GameNative({Key key, this.title}) : super(key: key);

  @override
  _GameNativeState createState() => _GameNativeState();
}

class _GameNativeState extends State<GameNative>
    with SingleTickerProviderStateMixin {
  List<EssentielCard> _allCards;
  Object _errorWhileLoadingData;

  int _currentIndex;
  AnimationController _controller;
  CurvedAnimation _curvedAnimation;
  Animation<Offset> _translationAnim;
  Animation<Offset> _moveAnim;
  Animation<double> _scaleAnim;

  @override
  void initState() {
    _currentIndex = 0;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );

    _curvedAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _translationAnim = Tween(begin: Offset(0.0, 0.0), end: Offset(-1000.0, 0.0))
        .animate(_controller)
          ..addListener(() {
            setState(() {});
          });

    _scaleAnim = Tween(begin: 0.965, end: 1.0).animate(_curvedAnimation);
    _moveAnim = Tween(begin: Offset(0.0, 0.05), end: Offset(0.0, 0.0))
        .animate(_curvedAnimation);

    ShakeDetector.autoStart(onPhoneShake: () {
      _randomDraw();
    });

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

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body = Stack(
          overflow: Overflow.visible,
          children: _allCards.reversed.map((card) {
            Widget widget;
            if (_allCards.indexOf(card) <= 2) {
              widget = GestureDetector(
                // onHorizontalDragEnd: _horizontalDragEnd,
                onHorizontalDragEnd: (DragEndDetails details) {
                  final delta = details.primaryVelocity;
                  if (delta > 0) {
                    //LTR drag
                    debugPrint("RTL drag detected");
                    _controller.forward().whenComplete(() {
                      setState(() {
                        _errorWhileLoadingData = null;
                        _controller.reset();
                        final removedCard = _allCards.removeLast();
                        _allCards.insert(0, removedCard);
                        // _allCards.removeAt(_allCards.length - 1);
                        // _allCards.insert(0, removedCard);
                        _currentIndex = _allCards.elementAt(0).index;
                        // if (widget.onCardChanged != null)
                        //   widget.onCardChanged(allCards[0].imageUrl);
                      });
                    });
                  } else if (delta < 0) {
                    //RTL drag
                    debugPrint("LRT drag detected");
                    _controller.forward().whenComplete(() {
                      setState(() {
                        _errorWhileLoadingData = null;
                        _controller.reset();
                        final removedCard = _allCards.removeAt(0);
                        // final removedCard = _allCards.removeAt(0);
                        _allCards.add(removedCard);
                        _currentIndex = _allCards.elementAt(0).index;
                        // if (widget.onCardChanged != null)
                        //   widget.onCardChanged(allCards[0].imageUrl);
                      });
                    });
                  }
                },
                child: Transform.translate(
                  offset: _getFlickTransformOffset(card),
                  child: FractionalTranslation(
                    translation: _getStackedCardOffset(card),
                    child: Transform.scale(
                      scale: _getStackedCardScale(card),
                      child: Center(child: card),
                    ),
                  ),
                ),
              );
            } else {
              widget = Container();
            }
            return widget;
          }).toList());
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
                      left: screenWidth * 0.05, right: screenWidth * 0.05),
                  height: screenHeight * 0.5,
                  child: body,
                )),
          ),
        ],
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

  Offset _getStackedCardOffset(EssentielCard card) {
    int diff = card.index - _currentIndex;
    if (card.index == _currentIndex + 1) {
      return _moveAnim.value;
    } else if (diff > 0 && diff <= 2) {
      return Offset(0.0, 0.05 * diff);
    } else {
      return Offset(0.0, 0.0);
    }
  }

  double _getStackedCardScale(EssentielCard card) {
    int diff = card.index - _currentIndex;
    debugPrint(
        "card.index=${card.index} / _currentIndex=$_currentIndex / diff=$diff / category=${card.cardData.category} / question=${card.cardData.question}");
    if (card.index == _currentIndex) {
      return 1.0;
    } else if (card.index == _currentIndex + 1) {
      return _scaleAnim.value;
    } else {
      return (1 - (0.035 * diff.abs()));
    }
  }

  Offset _getFlickTransformOffset(EssentielCard card) {
    if (card.index == _currentIndex) {
      return _translationAnim.value;
    }
    return Offset(0.0, 0.0);
  }

  void _randomDraw() {
    final numberOfCards = _allCards?.length ?? 0;
    final randomPick = RandomUtils.getRandomValueInRangeButExcludingValue(
        0, numberOfCards, _currentIndex);
    debugPrint(
        "_currentIndex=$_currentIndex / randomPick=$randomPick / numberOfCards=$numberOfCards");
    _jumpTo(randomPick);
  }

  _onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );

  _jumpTo(int index) {
    // _cardsController.animateToPage(index,
    //     curve: Curves.ease, duration: Duration(milliseconds: 500));
  }
}
