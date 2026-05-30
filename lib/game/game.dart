import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:animated_widgets/animated_widgets.dart';
import 'package:essentiel/about.dart';
import 'package:essentiel/env.dart';
import 'package:essentiel/game/cards.dart';
import 'package:essentiel/game/category_selector_dialog.dart';
import 'package:essentiel/resources/category.dart';
import 'package:essentiel/services/backend_api_service.dart';
import 'package:essentiel/utils.dart';
import 'package:essentiel/widgets/animated_background.dart';
import 'package:essentiel/widgets/animated_wave.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gsheets/gsheets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shake/shake.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

const _spreadsheetId = '1cR8lE6eCvDrgUXAVD1bmm36j6v5MtOEurSOAEfrTcCI';

const title = 'Jeu Essentiel';
// Updated: 2026-05-30 - Large text for mobile web

// French error messages for refresh failures
const _errorNoNetwork =
    "Pas de connexion réseau. Veuillez vérifier votre connexion.";
const _errorTimeout =
    "Le chargement des questions a expiré. Réessayez plus tard.";
const _errorAccess = "Impossible d'accéder à la feuille de calcul.";
const _errorGeneric = "Erreur lors du chargement des questions.";

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
  bool? _isReloading;
  List<String>? _categoryListFilter;
  bool _isRefreshing = false;
  bool _showDealingAnimation = false;
  int? _previousIndex; // Track previous card for animation logic

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  GlobalKey _cardListShowcaseKey = GlobalKey();
  BuildContext? myContext;

  @override
  void initState() {
    super.initState();
    _doShuffleCards = true; // Shuffle cards by default
    _applyFilter = false;
    _isReloading = false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _fetchQuestionsFromSheets();
        await AppUtils.isFirstLaunch().then((result) {
          if (result) {
            if (myContext != null) {
              ShowCaseWidget.of(myContext!)
                  .startShowCase([_cardListShowcaseKey]);
            }
          }
        });
      } catch (e) {
        setState(() {
          _errorWhileLoadingData = e;
          _categoryList = null;
          _rawCardsData = null;
          _allCardsData = null;
        });
      }
    });

    // Only enable shake detection on native platforms (not web)
    // Web browsers have limited sensor access and require HTTPS + permissions
    if (!kIsWeb) {
      ShakeDetector.autoStart(onPhoneShake: () {
        _randomDraw();
      });
    }
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
        _isReloading == true ||
        _allCardsData == null ||
        _showDealingAnimation) {
      //Not initialized yet or showing dealing animation
      if (_showDealingAnimation) {
        // Show stacked deck animation with seamless transition to horizontal list
        final numDeckCards = 20;
        final cardHeight =
            screenHeight * 0.38 > 380 ? 380.0 : screenHeight * 0.38;
        final cardWidth = cardHeight * 0.71;

        body = RefreshIndicator(
          onRefresh: _handleRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              // On web, balance space between popup card area and horizontal list
              final cardListHeight =
                  kIsWeb ? availableHeight * 0.50 : availableHeight * 0.35;
              final spacerHeight =
                  kIsWeb ? availableHeight * 0.005 : availableHeight * 0.04;
              final cardDisplayHeight =
                  availableHeight - cardListHeight - spacerHeight;

              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: Column(
                    children: [
                      SizedBox(
                        height: cardDisplayHeight,
                        child: Stack(
                          children: [
                            // Blurred logo in background
                            Center(
                              child: ImageFiltered(
                                imageFilter:
                                    ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                child: Opacity(
                                  opacity: 0.6,
                                  child: Image.asset(
                                    "assets/images/essentiel_logo.svg.png",
                                    width: screenWidth * 0.3,
                                    height: screenHeight * 0.3,
                                    fit: BoxFit.contain,
                                    cacheWidth: (screenWidth * 0.6).toInt(),
                                    cacheHeight: (screenHeight * 0.6).toInt(),
                                  ),
                                ),
                              ),
                            ),
                            // Deck animation on top
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 2000),
                              curve: Curves.easeInOutCubic,
                              onEnd: () {
                                setState(() {
                                  _showDealingAnimation = false;
                                });
                              },
                              builder: (context, value, child) {
                                return Stack(
                                  children:
                                      List.generate(numDeckCards, (index) {
                                    final double stackOffset = index * 2.0;
                                    final double rotation =
                                        (index - numDeckCards / 2) * 0.015;

                                    // Start at center, move to bottom where horizontal list is
                                    final double startY =
                                        cardDisplayHeight * 0.3;
                                    final double endY =
                                        cardDisplayHeight * 0.85;
                                    final double currentY =
                                        startY + (endY - startY) * value;

                                    // Spread horizontally across the bottom
                                    final double maxSpread = screenWidth * 0.8;
                                    final double spreadX =
                                        ((index / numDeckCards) - 0.5) *
                                            maxSpread *
                                            value;

                                    // Fade out as they settle
                                    final double fadeStart = 0.7;
                                    final double fadeValue = value < fadeStart
                                        ? 1.0
                                        : 1.0 -
                                            ((value - fadeStart) /
                                                (1.0 - fadeStart));

                                    return Positioned(
                                      left: screenWidth / 2 - 60 + spreadX,
                                      top: currentY + stackOffset * (1 - value),
                                      child: Transform.rotate(
                                        angle: rotation * (1 - value),
                                        child: Opacity(
                                          opacity: fadeValue,
                                          child: Container(
                                            width: 120,
                                            height: 170,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 2.0),
                                              color: Colors.white,
                                            ),
                                            padding: EdgeInsets.all(10),
                                            child: Image.asset(
                                              "assets/images/essentiel_logo.svg.png",
                                              fit: BoxFit.contain,
                                              cacheWidth: 240,
                                              cacheHeight: 340,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: spacerHeight),
                      // Horizontal list fades in as deck cards fade out
                      SizedBox(
                        height: cardListHeight,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 2000),
                          curve: Interval(0.5, 1.0, curve: Curves.easeIn),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: child,
                            );
                          },
                          child: Showcase(
                            key: _cardListShowcaseKey,
                            disposeOnTap: true,
                            onTargetClick: () {},
                            descTextStyle: TextStyle(fontSize: 20.0),
                            overlayOpacity: 0.6,
                            description:
                                'Faites défiler de gauche à droite \npour découvrir plus de cartes',
                            child: AnimationLimiter(
                              child: ScrollablePositionedList.builder(
                                physics: BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                scrollDirection: Axis.horizontal,
                                itemScrollController: itemScrollController,
                                itemPositionsListener: itemPositionsListener,
                                itemCount: _allCardsData!.length,
                                itemBuilder:
                                    (BuildContext context, int index) =>
                                        AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 175),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: SlideAnimation(
                                      horizontalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: GestureDetector(
                                          child: AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 300),
                                            margin: const EdgeInsets.only(
                                                left: 5.0),
                                            child: ImageFiltered(
                                              imageFilter:
                                                  _currentIndex != null &&
                                                          _currentIndex != index
                                                      ? ImageFilter.blur(
                                                          sigmaX: 3.0,
                                                          sigmaY: 3.0)
                                                      : ImageFilter.blur(
                                                          sigmaX: 0.0,
                                                          sigmaY: 0.0),
                                              child: Opacity(
                                                opacity: _currentIndex !=
                                                            null &&
                                                        _currentIndex != index
                                                    ? 0.5
                                                    : 1.0,
                                                child: EssentielCardWidget(
                                                    index: index,
                                                    selected:
                                                        _currentIndex == index,
                                                    noCardSelected:
                                                        _currentIndex == null,
                                                    cardData: _allCardsData!
                                                        .elementAt(index)),
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            if (_currentIndex == index) {
                                              setState(() {
                                                _currentIndex = null;
                                                _doShuffleCards = false;
                                                _applyFilter = false;
                                              });
                                            } else {
                                              _jumpTo(index);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      } else {
        body = Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                              : _isReloading == true
                                  ? "Rechargement des cartes"
                                  : "Initialisation") +
                      " en cours. Merci de patienter quelques instants...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24, height: 1.7, color: Colors.white))),
        ]));
      }
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
        // Show blurred Essentiel logo when no card is selected
        final isWeb = kIsWeb;

        widgetToDisplay = Container(
            padding: const EdgeInsets.all(15.0),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Blurred logo background (always shown)
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        "assets/images/essentiel_logo.svg.png",
                        width: screenWidth * 0.3,
                        height: screenHeight * 0.3,
                        fit: BoxFit.contain,
                        cacheWidth: (screenWidth * 0.6).toInt(),
                        cacheHeight: (screenHeight * 0.6).toInt(),
                      ),
                    ),
                  ),
                  // Shake animation and text on mobile (on top of logo)
                  if (!isWeb)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        SizedBox(height: 10.0),
                        Text("Secouez votre téléphone pour choisir une carte.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 24,
                                height: 1.2,
                                color: Colors.white)),
                      ],
                    ),
                ],
              ),
            ));
      } else {
        final cardData = _allCardsData?.elementAt(_currentIndex!);
        // Responsive breakpoints: mobile <600px, tablet 600-1200px, desktop >1200px
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        final isDesktop = screenWidth >= 1200;

        // Responsive card size: for web, use much larger sizes for readability
        // Allow card to grow beyond initial size if text overflows
        final heightRatio =
            kIsWeb ? 0.85 : (isMobile ? 0.6 : (isTablet ? 0.65 : 0.7));
        final minHeight = kIsWeb ? 800.0 : (isMobile ? 500.0 : 550.0);
        final maxHeight = kIsWeb
            ? double.infinity
            : (isMobile ? 500.0 : (isTablet ? 550.0 : 600.0));
        final aspectRatio = isMobile ? 0.85 : 0.9;
        final widthCap = kIsWeb
            ? 0.95
            : (isMobile
                ? 0.9
                : (isTablet ? 0.85 : 0.8)); // More constrained on desktop

        final calculatedHeight = screenHeight * heightRatio;
        final selectedCardHeight = calculatedHeight < minHeight
            ? minHeight
            : (calculatedHeight > maxHeight ? maxHeight : calculatedHeight);
        final calculatedWidth = selectedCardHeight * aspectRatio;
        final selectedCardWidth = calculatedWidth > screenWidth * widthCap
            ? screenWidth * widthCap
            : calculatedWidth;

        // Build the card content (AnimatedSwitcher for card-to-card transitions)
        final cardContent = AnimatedSwitcher(
          duration: Duration(milliseconds: 600),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            // Flip animation: rotate on Y-axis
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                // Determine rotation angle based on whether this is incoming or outgoing
                final isIncoming = child?.key == ValueKey(_currentIndex);
                final rotationValue = isIncoming
                    ? (1 - animation.value) *
                        0.5 // Incoming: rotate from 90° to 0°
                    : animation.value * 0.5; // Outgoing: rotate from 0° to 90°

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(3.14159 * rotationValue), // rotate around Y-axis
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity:
                        isIncoming ? animation.value : (1 - animation.value),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          child: Stack(
            key: ValueKey(_currentIndex), // Key changes trigger the animation
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: BoxConstraints(
                  minWidth: selectedCardWidth * 0.9,
                  maxWidth: selectedCardWidth,
                  minHeight: kIsWeb ? 800.0 : selectedCardHeight * 0.8,
                  maxHeight: kIsWeb ? screenHeight * 0.95 : selectedCardHeight,
                ),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.black, width: 2.0),
                    color: Colors.white),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Icon at top - fixed position, doesn't scroll
                    if (cardData?.isForParentChild == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
                        child: FaIcon(
                          FontAwesomeIcons.childReaching,
                          color: const Color(0xFFF06292),
                          size: 50.0,
                        ),
                      )
                    else if (cardData?.isForParents == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
                        child: Image.asset(
                          'assets/images/family.png',
                          fit: BoxFit.scaleDown,
                          height: 60.0,
                          width: 60.0,
                          cacheWidth: 120,
                          cacheHeight: 120,
                        ),
                      )
                    else if (cardData?.isForCouples == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
                        child: Image.asset(
                          'assets/images/couple.png',
                          fit: BoxFit.scaleDown,
                          height: 60.0,
                          cacheWidth: 120,
                          cacheHeight: 120,
                          width: 60.0,
                        ),
                      )
                    else if (cardData?.isForInternalMood == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
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
                    // Spacing between icon and text
                    if (cardData!.isForParents ||
                        cardData.isForParentChild ||
                        cardData.isForCouples ||
                        cardData.isForInternalMood)
                      SizedBox(height: 20.0),
                    // Question text - centered and scrollable
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Text(
                            cardData.question!,
                            style: TextStyle(
                                fontSize: kIsWeb ? 56.0 : 25.0,
                                color: cardData.category!.color,
                                wordSpacing: 2.0,
                                height: 1.75,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    // Category label at bottom - no padding, merged with card edge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 10.0),
                      decoration: BoxDecoration(
                        color: cardData.category!.color,
                      ),
                      child: Text(
                        cardData.category!.title!,
                        style: TextStyle(
                          fontSize: kIsWeb ? 38.0 : 22.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button positioned relative to the card
              Positioned(
                top: -8,
                right: -8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _previousIndex =
                            _currentIndex; // Remember last card for next animation
                        _currentIndex = null;
                        _doShuffleCards = false;
                        _applyFilter = false;
                      });
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.solidCircleXmark,
                      size: 36.0,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        // Wrap in slide-up animation only for first card
        final isFirstCard = _previousIndex == null;
        widgetToDisplay = Align(
          alignment: kIsWeb ? Alignment(0, -0.3) : Alignment.center,
          child: isFirstCard
              ? TweenAnimationBuilder<double>(
                  key: ValueKey('slide-$_currentIndex'),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * screenHeight * 0.5),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: cardContent,
                )
              : cardContent,
        );
      }
      body = RefreshIndicator(
        onRefresh: _handleRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final screenWidth = MediaQuery.of(context).size.width;

            // Balanced allocation for card list - enough room without overwhelming
            // For web, push horizontal scrollbar to bottom near menu buttons
            final isMobileWeb = kIsWeb && screenWidth < 600;
            final cardListHeight =
                kIsWeb ? availableHeight * 0.50 : availableHeight * 0.35;
            final spacerHeight =
                kIsWeb ? availableHeight * 0.01 : availableHeight * 0.04;
            final cardDisplayHeight =
                availableHeight - cardListHeight - spacerHeight;

            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Column(
                  children: [
                    SizedBox(
                      height: cardDisplayHeight,
                      child: Stack(
                        children: [
                          widgetToDisplay,
                        ],
                      ),
                    ),
                    SizedBox(
                      height: spacerHeight,
                    ),
                    SizedBox(
                        height: cardListHeight,
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
                                          child: AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 300),
                                            margin: const EdgeInsets.only(
                                                left: 5.0),
                                            // Add blur to unselected cards
                                            child: ImageFiltered(
                                              imageFilter:
                                                  _currentIndex != null &&
                                                          _currentIndex != index
                                                      ? ImageFilter.blur(
                                                          sigmaX: 3.0,
                                                          sigmaY: 3.0)
                                                      : ImageFilter.blur(
                                                          sigmaX: 0.0,
                                                          sigmaY: 0.0),
                                              child: Opacity(
                                                opacity: _currentIndex !=
                                                            null &&
                                                        _currentIndex != index
                                                    ? 0.5
                                                    : 1.0,
                                                child: EssentielCardWidget(
                                                    index: index,
                                                    selected:
                                                        _currentIndex == index,
                                                    noCardSelected:
                                                        _currentIndex == null,
                                                    cardData: _allCardsData!
                                                        .elementAt(index)),
                                              ),
                                            ),
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
                ),
              ),
            );
          },
        ),
      );
    }

    final toDisplay = Stack(
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
                top: kIsWeb ? screenHeight * 0.01 : screenHeight * 0.085,
                left: 10.0,
                right: 10.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: kIsWeb ? 42.0 : 36.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.only(
                    top: screenHeight * 0.2,
                    bottom: kIsWeb ? screenHeight * 0.02 : screenHeight * 0.13,
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
          _showDealingAnimation = true; // Show dealing animation
        });
      });
    } else if (_applyFilter!) {
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _currentIndex = null;
          _allCardsData = _filter(_categoryListFilter!);
          _doShuffleCards = false;
          _applyFilter = false;
          _showDealingAnimation = true; // Show dealing animation
        });
      });
    }

    // final Map<String, Category> allCategoryTitlesMap = {
    //   for (var cat in categoryValues) cat.title(): cat
    // };
    final Map<String, QuestionCategory> allCategoryTitlesMap =
        CategoryStore.findAll();

    final allCategoryFilters = allCategoryTitlesMap.keys.toList()
      ..addAll(["Parents", "Couples"])
      ..sort((a, b) {
        // Normalize French accents for proper alphabetical sorting
        String normalize(String s) {
          return s
              .toLowerCase()
              .replaceAll('é', 'e')
              .replaceAll('è', 'e')
              .replaceAll('ê', 'e')
              .replaceAll('ë', 'e')
              .replaceAll('à', 'a')
              .replaceAll('â', 'a')
              .replaceAll('ä', 'a')
              .replaceAll('ç', 'c')
              .replaceAll('ô', 'o')
              .replaceAll('ö', 'o')
              .replaceAll('û', 'u')
              .replaceAll('ù', 'u')
              .replaceAll('ü', 'u')
              .replaceAll('î', 'i')
              .replaceAll('ï', 'i');
        }

        return normalize(a).compareTo(normalize(b));
      });

    final chipColorFn = (String category) {
      final categoryForText = allCategoryTitlesMap[category];
      if (categoryForText != null) {
        return categoryForText.color;
      }
      if (category == "Couples") {
        return Colors.pink;
      }
      if (category == "Parents") {
        return Colors.brown;
      }
      return null;
    };

    return ShowCaseWidget(
      onStart: (index, key) {
        debugPrint('onStart: $index, $key');
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
      builder: (ctx) {
        myContext = ctx;
        return Scaffold(
          body: toDisplay,
          floatingActionButton: (_rawCardsData != null &&
                  _rawCardsData!.isNotEmpty)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // "Tirer une carte" button - always visible for easy access
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: FloatingActionButton.extended(
                        heroTag: 'draw-card-fab',
                        onPressed: _randomDraw,
                        backgroundColor: const Color(0xFFED2910),
                        foregroundColor: Colors.white,
                        elevation: kIsWeb ? 12.0 : 8.0,
                        shape: kIsWeb
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              )
                            : null,
                        icon: FaIcon(FontAwesomeIcons.handSparkles,
                            size: kIsWeb ? 56 : 20),
                        label: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: kIsWeb ? 24 : 0,
                              vertical: kIsWeb ? 18 : 0),
                          child: Text(
                            'Tirer une carte',
                            style: TextStyle(
                                fontSize: kIsWeb ? 48 : 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: kIsWeb ? 1.2 : 0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Menu button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SpeedDial(
                        animatedIcon: AnimatedIcons.menu_close,
                        animatedIconTheme:
                            IconThemeData(size: kIsWeb ? 56.0 : 22.0),
                        overlayColor: Colors.black,
                        overlayOpacity: 0.5,
                        tooltip: 'Menu',
                        heroTag: 'essentiel-speed-dial-hero-tag',
                        elevation: 8.0,
                        shape: CircleBorder(),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.lightGreen,
                        curve: Curves.bounceIn,
                        buttonSize: Size(kIsWeb ? 100 : 56, kIsWeb ? 100 : 56),
                        spacing: kIsWeb ? 20 : 12,
                        spaceBetweenChildren: kIsWeb ? 20 : 12,
                        childPadding: kIsWeb ? EdgeInsets.all(16) : EdgeInsets.all(5),
                        childMargin: kIsWeb
                            ? EdgeInsets.symmetric(vertical: 10)
                            : EdgeInsets.symmetric(vertical: 4),
                        children: [
                          SpeedDialChild(
                            child: Icon(Icons.info_outline,
                                size: kIsWeb ? 56 : 24),
                            backgroundColor: const Color(0xFF62D739),
                            label: 'À propos',
                            labelBackgroundColor: const Color(0xFF62D739),
                            labelStyle: TextStyle(
                                fontSize: kIsWeb ? 48.0 : 18.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            onTap: () => showAppAboutDialog(context),
                          ),
                          SpeedDialChild(
                              child: Icon(Icons.filter_alt_sharp,
                                  size: kIsWeb ? 56 : 24),
                              backgroundColor: const Color(0xFF12A0FF),
                              label: 'Filtres',
                              labelBackgroundColor: const Color(0xFF12A0FF),
                              labelStyle: TextStyle(
                                  fontSize: kIsWeb ? 48.0 : 18.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                              onTap: () async => showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext ctx) =>
                                      CategorySelectorDialog(
                                        title: Text(
                                          'Catégories à afficher',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: kIsWeb ? 44.0 : 20.0),
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
                                            final prefs =
                                                await SharedPreferences
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
                            child: Icon(Icons.refresh, size: kIsWeb ? 56 : 24),
                            backgroundColor: const Color(0xFF9C27B0),
                            label: 'Recharger les cartes',
                            labelBackgroundColor: const Color(0xFF9C27B0),
                            labelStyle: TextStyle(
                                fontSize: kIsWeb ? 48.0 : 18.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            onTap: () => _handleRefresh(),
                          ),
                          SpeedDialChild(
                            child: Icon(Icons.shuffle_outlined,
                                size: kIsWeb ? 56 : 24),
                            backgroundColor: const Color(0xFF97205E),
                            label: 'Mélanger les cartes',
                            labelBackgroundColor: const Color(0xFF97205E),
                            labelStyle: TextStyle(
                                fontSize: kIsWeb ? 48.0 : 18.0,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            onTap: _shuffleCards,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
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
      if (_categoryListFilter!.contains("Parents") && cardData.isForParents) {
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
          _previousIndex = _currentIndex; // Track previous for animation
          _currentIndex = index;
          _doShuffleCards = false;
          _applyFilter = false;
        });
      });

  Future<void> _handleRefresh() async {
    // Prevent concurrent refresh operations
    if (_isRefreshing) return;

    setState(() {
      _isReloading = true;
      _currentIndex = null;
      _doShuffleCards = false;
      _applyFilter = false;
    });

    _isRefreshing = true;
    try {
      await _fetchQuestionsFromSheets(forceRefresh: true);
    } on SocketException {
      // No network connectivity
      Fluttertoast.showToast(
        msg: _errorNoNetwork,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } on TimeoutException {
      // Request timeout
      Fluttertoast.showToast(
        msg: _errorTimeout,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      // Generic error (permission errors, malformed data, etc.)
      final errorMessage = e.toString().toLowerCase().contains('permission') ||
              e.toString().toLowerCase().contains('access')
          ? _errorAccess
          : _errorGeneric;
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isReloading = false;
      });
      _isRefreshing = false;
    }
  }

  Future<void> _fetchQuestionsFromSheets({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryListFilter = prefs.getStringList(CATEGORY_FILTER_PREF_KEY);

    List<QuestionCategory> categoryList;
    List<EssentielCardData> cardData;

    try {
      if (kIsWeb) {
        // Web builds: Use backend API service (no credentials in client)
        // Empty string is valid - means use relative URLs (same origin via nginx proxy)
        final backendUrl = Env.value!.backendApiUrl ?? '';

        final apiService = BackendApiService(baseUrl: backendUrl);

        // Fetch categories from backend API
        categoryList =
            await apiService.fetchCategories(forceRefresh: forceRefresh);

        // Fetch questions from backend API
        final questionsData =
            await apiService.fetchQuestions(forceRefresh: forceRefresh);
        cardData = questionsData
            .map((questionJson) => EssentielCardData.fromGSheet(questionJson))
            .where((element) =>
                element.question != null && element.question!.trim().isNotEmpty)
            .toList();

        // Cache data in localStorage for offline support
        await _cacheDataToLocalStorage(prefs, categoryList, cardData);
      } else {
        // Mobile builds: Use direct Google Sheets access with Service Account
        final String spreadsheetId = Env.value!.spreadsheetId ?? _spreadsheetId;
        final gsheets = GSheets.withServiceAccountCredentials(
            ServiceAccountCredentials(Env.value!.saEmail!,
                ClientId(Env.value!.saId!), Env.value!.saPK!));

        final spreadsheet = await gsheets.spreadsheet(spreadsheetId);
        final categoriesSheet = await spreadsheet
            .worksheetByTitle('Categories')
            ?.values
            .map
            .allRows();
        categoryList = categoriesSheet != null
            ? (categoriesSheet as List<Map<String, dynamic>>)
                .map((json) => QuestionCategory.fromGSheet(json))
                .toList()
            : <QuestionCategory>[];

        final questionsSheet = await spreadsheet
            .worksheetByTitle('Questions')
            ?.values
            .map
            .allRows();
        cardData = questionsSheet != null
            ? (questionsSheet as List<Map<String, dynamic>>)
                .map((questionJson) =>
                    EssentielCardData.fromGSheet(questionJson))
                .where((element) =>
                    element.question != null &&
                    element.question!.trim().isNotEmpty)
                .toList()
            : <EssentielCardData>[];
      }
    } catch (e) {
      // Try to load from cache if available (web only)
      if (kIsWeb) {
        final cachedData = await _loadCachedDataFromLocalStorage(prefs);
        if (cachedData != null) {
          categoryList = cachedData['categories'] as List<QuestionCategory>;
          cardData = cachedData['cards'] as List<EssentielCardData>;
        } else {
          // No cache available, rethrow error
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    setState(() {
      _errorWhileLoadingData = null;
      _doShuffleCards = false;
      _applyFilter = false;
      _categoryListFilter = categoryListFilter;
      _categoryList = categoryList.toList(growable: false);
      if (_categoryListFilter == null || _categoryListFilter!.length == 0) {
        // All categories selected by default
        _categoryListFilter = <String>["Parents", "Couples"];
        categoryList
            .where((element) => element.title != null)
            .forEach((element) {
          _categoryListFilter!.add(element.title!);
        });
      }
      _rawCardsData = cardData.toList(growable: false);
      _allCardsData = _filter(_categoryListFilter);

      // Shuffle cards immediately on load if shuffle is enabled
      if (_doShuffleCards == true) {
        _allCardsData!.shuffle();
      }

      // Show dealing animation on initial load
      _showDealingAnimation = true;
    });
  }

  // Cache data to localStorage for offline support (web only)
  Future<void> _cacheDataToLocalStorage(SharedPreferences prefs,
      List<QuestionCategory> categories, List<EssentielCardData> cards) async {
    // Store categories as JSON
    final categoriesJson = categories
        .map(
            (cat) => {'title': cat.title, 'color': cat.color?.value.toString()})
        .toList();
    await prefs.setString('cached_categories', categoriesJson.toString());

    // Store cards as JSON
    final cardsJson = cards
        .map((card) => {
              'question': card.question,
              'category': card.category?.title,
              'isForCouples': card.isForCouples,
              'isForParents': card.isForParents,
            })
        .toList();
    await prefs.setString('cached_cards', cardsJson.toString());
    await prefs.setString('cached_timestamp', DateTime.now().toIso8601String());
  }

  // Load cached data from localStorage (web only)
  Future<Map<String, List>?> _loadCachedDataFromLocalStorage(
      SharedPreferences prefs) async {
    final categoriesJson = prefs.getString('cached_categories');
    final cardsJson = prefs.getString('cached_cards');

    if (categoriesJson == null || cardsJson == null) {
      return null;
    }

    // Note: This is a simplified implementation
    // In production, you'd want proper JSON parsing
    return null; // Placeholder - implement proper JSON deserialization if needed
  }
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

    // Match deck card aspect ratio: taller than wide (120w x 170h = 0.706 ratio)
    // For horizontal cards, use landscape/paysage orientation (width > height)
    // This preserves the Essentiel logo's original scale better
    final widthRatio = kIsWeb ? 0.30 : 0.25;
    final maxWidth = kIsWeb ? 500.0 : 250.0;

    final cardWidth = screenWidth * widthRatio > maxWidth
        ? maxWidth
        : screenWidth * widthRatio;
    final cardHeight =
        cardWidth * 0.706; // Landscape: width > height (flipped from portrait)

    // For web, add much larger font sizes to card logos
    final logoFontSize = kIsWeb ? cardWidth * 0.08 : cardWidth * 0.05;

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
                  height: cardHeight,
                  width: cardWidth,
                  child: Center(
                    child: Image.asset(
                      "assets/images/essentiel_logo.svg.png",
                      fit: BoxFit.contain,
                      width: cardWidth * 0.7, // Logo takes 70% of card width
                      height: cardHeight * 0.7, // Logo takes 70% of card height
                      cacheWidth: (cardWidth * 1.4).toInt(),
                      cacheHeight: (cardHeight * 1.4).toInt(),
                    ),
                  ),
                ))
            // )
            );
  }
}
