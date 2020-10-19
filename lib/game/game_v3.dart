import 'dart:math';

import 'package:essentiel/game/cards.dart';
import 'package:essentiel/resources/category.dart';
import 'package:essentiel/utils.dart';
import 'package:essentiel/widgets/animated_background.dart';
import 'package:essentiel/widgets/animated_wave.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gsheets/gsheets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  List<EssentielCardData> _allCardsData;
  Object _errorWhileLoadingData;
  int _currentIndex;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

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
          _allCardsData = cardData;
        });
      }).catchError((e) {
        setState(() {
          _errorWhileLoadingData = e;
          _allCardsData = null;
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
    } else if (_allCardsData == null) {
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
    } else if (_allCardsData.isEmpty) {
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
                "Aucune donnée trouvée pour initialiser le jeu. Merci de réessayer dans quelques instants.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 20, height: 1.7, color: Colors.white))),
      ]));
    } else {
      //Yeah - we have some data !
      Widget widgetToDisplay;
      if (_currentIndex == null) {
        widgetToDisplay = Container(
            // height: screenHeight * 0.4,
            padding: const EdgeInsets.all(10.0),
            child: Center(
                child: Text(
                    "Merci de sélectionner une carte en dessous ou d'en choisir une au hasard.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20, height: 1.7, color: Colors.white))));
      } else {
        final cardData = _allCardsData.elementAt(_currentIndex);
        widgetToDisplay = Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.black, width: 2.0),
                color: Colors.white),
            // height: screenHeight * 0.1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      cardData.question,
                      style: TextStyle(
                          fontSize: 28.0, color: cardData.category.color()),
                    ),
                  ),
                  Positioned.fill(
                      child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: cardData.category.color(),
                      ),
                      child: Text(
                        cardData.category.title(),
                        style: TextStyle(
                          fontSize: 22.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ));
      }
      body = Column(
        children: [
          Expanded(
            flex: 4,
            child: widgetToDisplay,
          ),
          SizedBox(
            height: screenHeight * 0.05,
          ),
          Expanded(
              flex: 1,
              child: AnimationLimiter(
                child: ScrollablePositionedList.builder(
                  physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  // clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                  // shrinkWrap: true,
                  itemCount: _allCardsData.length,
                  itemBuilder: (BuildContext context, int index) =>
                      AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: Align(
                      widthFactor: (_currentIndex == index) ? 1.25 : 0.4,
                      alignment: Alignment.topCenter,
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: GestureDetector(
                              child: EssentielCardWidget(
                                  index: index,
                                  selected: _currentIndex == index,
                                  noCardSelected: _currentIndex == null,
                                  cardData: _allCardsData.elementAt(index)),
                              onTap: () {
                                //TODO Animate card selection
                                if (_currentIndex == index) {
                                  setState(() {
                                    _currentIndex = null;
                                  });
                                } else {
                                  _jumpTo(index);
                                }
                              }),
                        ),
                      ),
                    ),
                  ),
                ),
              ))
        ],
      );
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
                        top: screenHeight * 0.2,
                        bottom: screenHeight * 0.13,
                        left: 10.0,
                        right: 10.0),
                    // height: screenHeight * 0.5,
                    child: body,
                  )),
            ),
          ],
        ),
      ),
      floatingActionButton: (_allCardsData != null && _allCardsData.isNotEmpty)
          ? SpeedDial(
              animatedIcon: AnimatedIcons.menu_close,
              animatedIconTheme: IconThemeData(size: 22.0),
              overlayColor: Colors.black,
              overlayOpacity: 0.5,
              tooltip: 'Menu',
              heroTag: 'essentiel-speed-dial-hero-tag',
              elevation: 8.0,
              shape: CircleBorder(),
              foregroundColor: Colors.white,
              backgroundColor: Colors.lightGreen,
              curve: Curves.bounceIn,
              children: [
                SpeedDialChild(
                    child: Icon(Icons.shuffle),
                    backgroundColor: Category.EVANGELISATION.color(),
                    label: 'Choisir une carte au hasard',
                    labelBackgroundColor: Category.EVANGELISATION.color(),
                    labelStyle: TextStyle(fontSize: 18.0, color: Colors.white),
                    onTap: _randomDraw),
                SpeedDialChild(
                  child: Icon(Icons.autorenew_rounded),
                  backgroundColor: Category.PRIERE.color(),
                  label: 'Mélanger les cartes',
                  labelBackgroundColor: Category.PRIERE.color(),
                  labelStyle: TextStyle(fontSize: 18.0, color: Colors.white),
                  onTap: _shuffleCards,
                ),
              ],
            )
          : null,
    );
  }

  void _shuffleCards() {
    setState(() {
      _currentIndex = null;
      _allCardsData.shuffle();
    });
  }

  void _randomDraw() {
    final _numberOfCards = _allCardsData.length;
    final randomPick = RandomUtils.getRandomValueInRangeButExcludingValue(
        0, _numberOfCards, _currentIndex);
    debugPrint(
        "_numberOfCards=$_numberOfCards / _currentPageIndex=$_currentIndex / randomPick=$randomPick");
    _jumpTo(randomPick);
  }

  _onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );

  _jumpTo(int index) => itemScrollController
          .scrollTo(
              index: max(0, index - 3),
              duration: Duration(seconds: 1),
              curve: Curves.easeInOutCubic)
          .whenComplete(() {
        setState(() {
          _currentIndex = index;
        });
      });
}

class EssentielCardWidget extends StatelessWidget {
  final EssentielCardData cardData;
  final bool selected;
  final bool noCardSelected;
  final int index;

  const EssentielCardWidget(
      {Key key,
      @required this.index,
      @required this.cardData,
      this.selected = false,
      this.noCardSelected = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Transform.scale(
        scale: selected ? 1.0 : 0.6,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Colors.grey,
                    (noCardSelected || selected)
                        ? BlendMode.dstOver
                        : BlendMode.darken),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.black, width: 2.0),
                      color: Colors.white),
                  padding: EdgeInsets.all(15),
                  height: screenHeight * 0.3,
                  width: screenWidth * 0.3,
                  child: Image.asset("assets/images/essentiel_logo.svg.png",
                      fit: BoxFit.fill),
                ))));
  }
}
