import 'package:essentiel/resources/category.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';

class EssentielCardData {
  final QuestionCategory? category;
  final String? question;
  final bool isForCouples;
  final bool isForFamilies;
  final bool isForInternalMood;

  const EssentielCardData(
      {@required this.category,
      @required this.question,
      this.isForInternalMood = false,
      this.isForCouples = false,
      this.isForFamilies = false});

  factory EssentielCardData.fromGSheet(Map<String, dynamic> json) {
    final image = json['Image'];
    final question = json['Question'];
    return EssentielCardData(
        category: CategoryStore.findByName(json['Catégorie']),
        question: question,
        isForInternalMood: question != null &&
            question.toString().toLowerCase().contains("météo"),
        isForCouples: json["Pour Couples"]?.toString().toLowerCase() ==
            "Oui".toLowerCase(),
        isForFamilies: json["Pour Familles"]?.toString().toLowerCase() ==
            "Oui".toLowerCase());
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return FlipCard(
      onFlip: this.widget.onFlip,
      front: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.black, width: 2.0),
            color: Colors.white),
        padding: EdgeInsets.all(18),
        height: screenHeight * 0.3,
        child: Image.asset("assets/images/essentiel_logo.svg.png",
            fit: BoxFit.fill),
      ),
      back: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 2.0),
              color: Colors.white),
          height: screenHeight * 0.3,
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
    );
  }
}
