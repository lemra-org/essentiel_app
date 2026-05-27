import 'package:essentiel/resources/category.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';

class EssentielCardData {
  final QuestionCategory? category;
  final String? question;
  final bool isForCouples;
  final bool isForFamilies;
  final bool isForParentChild;
  final bool isForInternalMood;

  const EssentielCardData(
      {@required this.category,
      @required this.question,
      this.isForInternalMood = false,
      this.isForCouples = false,
      this.isForFamilies = false,
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
        isForFamilies: json["Pour Familles"]?.toString().toLowerCase() ==
            "Oui".toLowerCase(),
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
    final cardHeight = screenHeight * 0.38 > 380 ? 380.0 : screenHeight * 0.38;
    final cardWidth = cardHeight * 0.71;

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
              fit: BoxFit.fill),
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
                    style: TextStyle(
                        fontSize: 28.0,
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
                      style: TextStyle(
                        fontSize: 22.0,
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
