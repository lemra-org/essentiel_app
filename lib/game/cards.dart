import 'package:essentiel/resources/category.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class EssentielCardData {
  final QuestionCategory? category;
  final String? question;
  final bool isForCouples;
  final bool isForParents;
  final bool isForParentChild;
  final bool isForInternalMood;

  const EssentielCardData(
      {@required this.category,
      @required this.question,
      this.isForInternalMood = false,
      this.isForCouples = false,
      this.isForParents = false,
      this.isForParentChild = false});

  factory EssentielCardData.fromGSheet(Map<String, dynamic> json) {
    final question = json['Question'];
    final categoryName = json['Catégorie'];
    return EssentielCardData(
        category: CategoryStore.findByName(categoryName),
        question: question,
        isForInternalMood: question != null &&
            question.toString().toLowerCase().contains("météo"),
        isForCouples: json["Pour Couples"]?.toString().toLowerCase() ==
            "Oui".toLowerCase(),
        isForParents: (json["Pour Parents"]?.toString().toLowerCase() ==
                "Oui".toLowerCase()) ||
            (json["Pour Familles"]?.toString().toLowerCase() ==
                "Oui".toLowerCase()),
        isForParentChild: categoryName?.toString() == "Parent - Enfant");
  }
}

class EssentielCard extends StatefulWidget {
  final EssentielCardData? cardData;
  final VoidCallback? onFlip;
  final int? index;

  const EssentielCard({Key? key, this.cardData, this.onFlip, this.index})
      : super(key: key);

  @override
  _EssentielCardState createState() => _EssentielCardState();
}

class _EssentielCardState extends State<EssentielCard> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Cards for horizontal list: balanced size with good spacing around logo
    // Maintain playing card aspect ratio (roughly 2.5:3.5 or 0.71)
    // For web: smaller cards in horizontal scrollbar (200px height)
    final baseHeightRatio = kIsWeb ? 0.20 : 0.38;
    final maxCardHeight = kIsWeb ? 200.0 : 380.0;

    final cardHeight = screenHeight * baseHeightRatio > maxCardHeight
        ? maxCardHeight
        : screenHeight * baseHeightRatio;
    final cardWidth = cardHeight * 0.71;

    // Font sizes adjusted for smaller web cards in horizontal list
    final questionFontSize = kIsWeb ? 14.0 : cardHeight * 0.065;
    final categoryFontSize = kIsWeb ? 12.0 : cardHeight * 0.05;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: cardWidth,
        maxHeight: cardHeight,
      ),
      child: FlipCard(
        onFlip: this.widget.onFlip,
        front: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 2.0),
              color: Colors.white),
          padding: EdgeInsets.all(18),
          height: cardHeight,
          width: cardWidth,
          child: Image.asset("assets/images/essentiel_logo.svg.png",
              fit: BoxFit.fill, cacheWidth: (cardWidth * 2).toInt()),
        ),
        back: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.black, width: 2.0),
                color: Colors.white),
            height: cardHeight,
            width: cardWidth,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      widget.cardData!.question!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: questionFontSize,
                          color: widget.cardData!.category!.color),
                    ),
                  ),
                  Positioned.fill(
                      child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: widget.cardData!.category!.color,
                      ),
                      child: Text(
                        widget.cardData!.category!.title!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: categoryFontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            )),
      ),
    );
  }
}
