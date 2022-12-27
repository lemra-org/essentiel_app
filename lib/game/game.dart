import 'dart:math';
import 'dart:ui';

import 'package:animated_widgets/animated_widgets.dart';
import 'package:essentiel/about.dart';
import 'package:essentiel/game/cards.dart';
import 'package:essentiel/game/category_selector_dialog.dart';
import 'package:essentiel/resources/category.dart';
import 'package:essentiel/utils.dart';
import 'package:essentiel/widgets/animated_background.dart';
import 'package:essentiel/widgets/animated_wave.dart';
import 'package:essentiel/widgets/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gsheets/gsheets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

const _spreadsheetId = '1cR8lE6eCvDrgUXAVD1bmm36j6v5MtOEurSOAEfrTcCI';

// These are credentials for a Serice Account that has no other access except a read-only access to the Spreadsheet.
// Also, the spreadhseet is open to the public in a read-only mode. So any service account can actually be used.
// => It is therefore safe to hardcode it below.
const _saEmail = "essentiel-mobile-app-readonly@essentiel-app.iam.gserviceaccount.com";
const _saId = "xxx";
const _saPK = "xxx";

const title = 'Jeu Essentiel';

//Inpiration from https://dribbble.com/shots/7696045-Tarot-App-Design
class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> {
  List<EssentielCardData>? _rawCardsData;
  List<EssentielCardData>? _allCardsData;
  List<QuestionCategory>? _categoryList;
  Object? _errorWhileLoadingData;
  int? _currentIndex;
  bool? _doShuffleCards;
  bool? _applyFilter;
  List<String>? _categoryListFilter;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  GlobalKey _cardListShowcaseKey = GlobalKey();
  BuildContext? myContext;

  @override
  void initState() {
    super.initState();
    _doShuffleCards = false;
    _applyFilter = false;

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final categoryListFilter = prefs.getStringList(CATEGORY_FILTER_PREF_KEY);
      debugPrint("Initial state for categoryListFilter: $categoryListFilter");

      final gsheets = GSheets.withServiceAccountCredentials(
          ServiceAccountCredentials(_saEmail, ClientId(_saId), _saPK));

      gsheets
          .spreadsheet(_spreadsheetId)
          .then((spreadsheet) =>
              spreadsheet.worksheetByTitle('Categories')?.values.map.allRows())
          .then((jsonList) => Future.value(jsonList != null
              ? (jsonList as List<Map<String, dynamic>>)
                  .map((json) => QuestionCategory.fromGSheet(json))
                  .toList()
              : <QuestionCategory>[]))
          .then((categoryList) async {
        gsheets
            .spreadsheet(_spreadsheetId)
            .then((spreadsheet) =>
                spreadsheet.worksheetByTitle('Questions')?.values.map.allRows())
            .then((questionsListJson) => Future.value(questionsListJson != null
                ? (questionsListJson as List<Map<String, dynamic>>)
                    .map((questionJson) =>
                        EssentielCardData.fromGSheet(questionJson))
                    .where((element) =>
                        element.question != null &&
                        element.question!.trim().isNotEmpty)
                    .toList()
                : <EssentielCardData>[]))
            .then((cardData) async {
          setState(() {
            _errorWhileLoadingData = null;
            _doShuffleCards = false;
            _applyFilter = false;
            _categoryListFilter = categoryListFilter;
            _categoryList = categoryList.toList(growable: false);
            _rawCardsData = cardData.toList(growable: false);
            _allCardsData = _filter(categoryListFilter);
          });
          await AppUtils.isFirstLaunch().then((result) {
            if (result) {
              if (myContext != null) {
                ShowCaseWidget.of(myContext!)
                    ?.startShowCase([_cardListShowcaseKey]);
              }
            }
          });
        }).catchError((e) {
          setState(() {
            _errorWhileLoadingData = e;
            _categoryList = null;
            _rawCardsData = null;
            _allCardsData = null;
            _doShuffleCards = false;
            _applyFilter = false;
            _categoryListFilter = categoryListFilter;
          });
        });
      }).catchError((e) {
        setState(() {
          _errorWhileLoadingData = e;
          _categoryList = null;
          _rawCardsData = null;
          _allCardsData = null;
          _doShuffleCards = false;
          _applyFilter = false;
          _categoryListFilter = categoryListFilter;
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

    final categoryValues =
        _categoryList != null ? _categoryList! : <QuestionCategory>[];

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
                    TextStyle(fontSize: 24, height: 1.7, color: Colors.white))),
      ]));
    } else if (_doShuffleCards == true ||
        _applyFilter == true ||
        _allCardsData == null) {
      //Not initialized yet
      body = Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SpinKitCubeGrid(
          size: 100.0,
          itemBuilder: (BuildContext context, int idx) => DecoratedBox(
              decoration: BoxDecoration(
                  color: categoryValues.isEmpty
                      ? null
                      : categoryValues[idx < categoryValues.length
                              ? idx
                              : (idx % categoryValues.length)]
                          .color)),
        ),
        SizedBox(
          height: 20.0,
        ),
        Flexible(
            child: Text(
                (_doShuffleCards == true
                        ? "Mélange de cartes"
                        : _applyFilter == true
                            ? "Filtrage des catégories de cartes"
                            : "Initialisation") +
                    " en cours. Merci de patienter quelques instants...",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 24, height: 1.7, color: Colors.white))),
      ]));
    } else if (_allCardsData != null && _allCardsData!.isEmpty) {
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
                    TextStyle(fontSize: 24, height: 1.7, color: Colors.white))),
      ]));
    } else {
      //Yeah - we have some data !
      Widget widgetToDisplay;
      if (_currentIndex == null) {
        widgetToDisplay = Container(
            // height: screenHeight * 0.4,
            padding: const EdgeInsets.all(15.0),
            child: Center(
              child: Column(
                children: [
                  ShakeAnimatedWidget(
                    enabled: true,
                    duration: Duration(milliseconds: 2000),
                    shakeAngle: Rotation.deg(x: 50, y: 5, z: 5),
                    curve: Curves.fastOutSlowIn,
                    child: SvgPicture.asset(
                      'assets/images/phone_in_hand.svg',
                      color: Colors.white,
                      width: screenWidth * 0.25,
                      height: screenHeight * 0.25,
                      semanticsLabel:
                          'Secouer smartphone en main pour choisir une carte',
                    ),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Flexible(
                      child: Text(
                          "Secouez votre téléphone pour choisir une carte.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24, height: 1.2, color: Colors.white)))
                ],
              ),
            ));
      } else {
        final cardData = _allCardsData?.elementAt(_currentIndex!);
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
                  if (cardData?.isForFamilies == true)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Image.asset(
                          'assets/images/family.png',
                          fit: BoxFit.scaleDown,
                          height: 60.0,
                          width: 60.0,
                          // colorBlendMode: ,
                        ),
                      ),
                    ),
                  if (cardData?.isForCouples == true)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Image.asset(
                          'assets/images/couple.png',
                          fit: BoxFit.scaleDown,
                          height: 60.0,
                          width: 60.0,
                          // colorBlendMode: ,
                        ),
                      ),
                    ),
                  if (cardData?.isForInternalMood == true)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              color: const Color(0xFFF7B900),
                              size: 40.0,
                            ),
                            FaIcon(
                              FontAwesomeIcons.cloudSun,
                              color: const Color(0xFFb5a347),
                              size: 35.0,
                            ),
                            FaIcon(
                              FontAwesomeIcons.cloudSunRain,
                              color: Colors.blueGrey,
                              size: 35.0,
                            ),
                            FaIcon(
                              FontAwesomeIcons.cloudRain,
                              color: Colors.blue,
                              size: 35.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: (cardData!.isForFamilies ||
                                    cardData.isForInternalMood ||
                                    cardData.isForInternalMood)
                                ? 40.0
                                : 0.0,
                            bottom: 35.0),
                        child: Text(
                          cardData.question!,
                          style: TextStyle(
                              fontSize: 25.0,
                              color: cardData.category!.color,
                              wordSpacing: 2.0,
                              height: 1.75,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                      child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: cardData.category!.color,
                      ),
                      child: Text(
                        cardData.category!.title!,
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
            child: Stack(
              children: [
                widgetToDisplay,
                if (_currentIndex != null)
                  Positioned.fill(
                      child: Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex = null;
                            _doShuffleCards = false;
                            _applyFilter = false;
                          });
                        },
                        icon: FaIcon(
                          FontAwesomeIcons.solidWindowClose,
                          size: 45.0,
                          color: Colors.black87,
                        )),
                  )),
              ],
            ),
          ),
          SizedBox(
            height: screenHeight * 0.05,
          ),
          Expanded(
              flex: 1,
              child: Showcase(
                key: _cardListShowcaseKey,
                disposeOnTap: true,
                onTargetClick: () {},
                // onToolTipClick: () {},
                descTextStyle: TextStyle(
                  fontSize: 20.0,
                ),
                overlayOpacity: 0.6,
                description:
                    'Faites défiler de gauche à droite \npour découvrir plus de cartes',
                child: AnimationLimiter(
                  child: ScrollablePositionedList.builder(
                    physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    // clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    // shrinkWrap: true,
                    itemCount: _allCardsData!.length,
                    itemBuilder: (BuildContext context, int index) =>
                        AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 175),
                      child: Align(
                        // widthFactor: (_currentIndex == index) ? 1.25 : 0.4,
                        alignment: Alignment.topCenter,
                        child: SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(
                            child: GestureDetector(
                                child: Container(
                                  margin: const EdgeInsets.only(left: 5.0),
                                  child: EssentielCardWidget(
                                      index: index,
                                      selected: _currentIndex == index,
                                      noCardSelected: _currentIndex == null,
                                      cardData:
                                          _allCardsData!.elementAt(index)),
                                ),
                                onTap: () {
                                  //TODO Animate card selection
                                  if (_currentIndex == index) {
                                    setState(() {
                                      _currentIndex = null;
                                      _doShuffleCards = false;
                                      _applyFilter = false;
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
                ),
              ))
        ],
      );
    }

    final toDisplay = Stack(
      children: [
        Positioned.fill(child: AnimatedBackground()),
        (_allCardsData != null)
            ? Positioned.fill(child: Particles(10))
            : Container(),
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
                top: screenHeight * 0.085, left: 10.0, right: 10.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 28.0, color: Colors.white),
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
    );

    if (_doShuffleCards == true) {
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _currentIndex = null;
          _allCardsData!.shuffle();
          _doShuffleCards = false;
          _applyFilter = false;
        });
      });
    } else if (_applyFilter!) {
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _currentIndex = null;
          _allCardsData = _filter(_categoryListFilter!);
          _doShuffleCards = false;
          _applyFilter = false;
        });
      });
    }

    // final Map<String, Category> allCategoryTitlesMap = {
    //   for (var cat in categoryValues) cat.title(): cat
    // };
    final Map<String, QuestionCategory> allCategoryTitlesMap =
        CategoryStore.findAll();

    final allCategoryFilters = allCategoryTitlesMap.keys.toList()
      ..addAll(["Familles", "Couples"]);

    final chipColorFn = (String category) {
      final categoryForText = allCategoryTitlesMap[category];
      if (categoryForText != null) {
        return categoryForText.color;
      }
      if (category == "Couples") {
        return Colors.pink;
      }
      if (category == "Familles") {
        return Colors.brown;
      }
      return null;
    };

    return ShowCaseWidget(
      onStart: (index, key) {
        debugPrint('onStart: $index, $key');
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          itemScrollController
              .scrollTo(
                  index: min(5, _allCardsData!.length - 1),
                  duration: Duration(seconds: 1),
                  curve: Curves.easeInOutCubic)
              .whenComplete(() async {
            Future.delayed(
                Duration(seconds: 1),
                () => itemScrollController.scrollTo(
                    index: 0,
                    duration: Duration(seconds: 1),
                    curve: Curves.easeInOutCubic));
          });
        });
      },
      builder: Builder(
        builder: (ctx) {
          myContext = ctx;
          return Scaffold(
            body: toDisplay,
            floatingActionButton: (_rawCardsData != null &&
                    _rawCardsData!.isNotEmpty)
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
                        child: Icon(Icons.info_outline),
                        backgroundColor: const Color(0xFF62D739),
                        label: 'À propos',
                        labelBackgroundColor: const Color(0xFF62D739),
                        labelStyle:
                            TextStyle(fontSize: 18.0, color: Colors.white),
                        onTap: () => showAppAboutDialog(context),
                      ),
                      SpeedDialChild(
                          child: Icon(Icons.filter_alt_sharp),
                          backgroundColor: const Color(0xFF12A0FF),
                          label: 'Filtrer les catégories de carte',
                          labelBackgroundColor: const Color(0xFF12A0FF),
                          labelStyle:
                              TextStyle(fontSize: 18.0, color: Colors.white),
                          onTap: () async => showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext ctx) =>
                                  CategorySelectorDialog(
                                    title: Text(
                                      'Catégories à afficher',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.0),
                                    ),
                                    all: allCategoryFilters,
                                    selected: _categoryListFilter != null
                                        ? _categoryListFilter
                                        : <String>[],
                                    textBackgroundColorProvider:
                                        (String category, bool isSelected) {
                                      var color = isSelected
                                          ? chipColorFn(category)
                                          : Colors.grey[200];
                                      if (color == null) {
                                        return Colors.grey;
                                      }
                                      return color;
                                    },
                                    textColorProvider:
                                        (String category, bool isSelected) {
                                      var color = isSelected
                                          ? Colors.white
                                          : chipColorFn(category);
                                      if (color == null) {
                                        return Colors.white;
                                      }
                                      return color;
                                    },
                                    callback: (List<String>
                                        selectedCategories) async {
                                      debugPrint(
                                          "selectedCategories: $selectedCategories");
                                      if (selectedCategories.isNotEmpty) {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        prefs.setStringList(
                                            CATEGORY_FILTER_PREF_KEY,
                                            selectedCategories);
                                        setState(() {
                                          _categoryListFilter =
                                              selectedCategories;
                                          _applyFilter = true;
                                          _doShuffleCards = false;
                                        });
                                      }
                                    },
                                  ))
                          // onTap: () async {
                          //   await FilterListDialog.display(context,
                          //       allTextList: allCategoryFilters,
                          //       height: 480,
                          //       borderRadius: 20,
                          //       headlineText: "Catégories de carte à afficher",
                          //       hideSearchField: true,
                          //       selectedTextList: _categoryListFilter,
                          //       onApplyButtonClick: (list) async {
                          //     if (list != null) {
                          //       final selectedCategories =
                          //           list.map((e) => e.toString()).toList();
                          //       final prefs = await SharedPreferences.getInstance();
                          //       prefs.setStringList(
                          //           CATEGORY_FILTER_PREF_KEY, selectedCategories);
                          //       setState(() {
                          //         _categoryListFilter = selectedCategories;
                          //         _applyFilter = true;
                          //         _doShuffleCards = false;
                          //       });
                          //     }
                          //     Navigator.pop(context);
                          //   });
                          // },
                          ),
                      SpeedDialChild(
                        child: Icon(Icons.shuffle_outlined),
                        backgroundColor: const Color(0xFF97205E),
                        label: 'Mélanger les cartes',
                        labelBackgroundColor: const Color(0xFF97205E),
                        labelStyle:
                            TextStyle(fontSize: 18.0, color: Colors.white),
                        onTap: _shuffleCards,
                      ),
                      SpeedDialChild(
                          child: Icon(Icons.find_replace_outlined),
                          backgroundColor: const Color(0xFFED2910),
                          label: 'Choisir une carte au hasard',
                          labelBackgroundColor: const Color(0xFFED2910),
                          labelStyle:
                              TextStyle(fontSize: 18.0, color: Colors.white),
                          onTap: _randomDraw),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  List<EssentielCardData> _filter(List<String>? filter) {
    if (filter == null) {
      return _rawCardsData!;
    }
    if (filter.isEmpty) {
      return List.empty(growable: true);
    }
    return _rawCardsData!.where((cardData) {
      if (_categoryListFilter!.contains(cardData.category!.title)) {
        return true;
      }
      if (_categoryListFilter!.contains("Familles") && cardData.isForFamilies) {
        return true;
      }
      if (_categoryListFilter!.contains("Couples") && cardData.isForCouples) {
        return true;
      }
      return false;
    }).toList();
  }

  void _shuffleCards() {
    setState(() {
      _doShuffleCards = true;
      _applyFilter = false;
    });
  }

  void _randomDraw() {
    if (_allCardsData == null || _allCardsData!.isEmpty) {
      debugPrint("_randomDraw: _allCardsData=$_allCardsData");
      return;
    }
    final _numberOfCards = _allCardsData!.length;
    final randomPick = _currentIndex != null
        ? RandomUtils.getRandomValueInRangeButExcludingValue(
            0, _numberOfCards, _currentIndex!)
        : RandomUtils.getRandomValueInRange(0, _numberOfCards);
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
              index: max(0, index - 1),
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic)
          .whenComplete(() {
        setState(() {
          _currentIndex = index;
          _doShuffleCards = false;
          _applyFilter = false;
        });
      });
}

class EssentielCardWidget extends StatelessWidget {
  final EssentielCardData? cardData;
  final bool? selected;
  final bool? noCardSelected;
  final int? index;

  const EssentielCardWidget(
      {Key? key,
      @required this.index,
      @required this.cardData,
      this.selected = false,
      this.noCardSelected = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return
        // Transform.scale(
        //   scale: selected ? 1.0 : 0.9,
        //   child:
        ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Colors.grey,
                    (noCardSelected! || selected!)
                        ? BlendMode.dstOver
                        : BlendMode.darken),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.black, width: 2.0),
                      color: Colors.white),
                  padding: EdgeInsets.all(15),
                  height: screenHeight * 0.3,
                  width: screenWidth * 0.25,
                  child: Image.asset("assets/images/essentiel_logo.svg.png",
                      fit: BoxFit.fill),
                ))
            // )
            );
  }
}
