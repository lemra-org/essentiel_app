import 'package:essentiel/resources/category.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';

class EssentielCardData {
  final Category category;
  final String question;
  final Widget header;

  const EssentielCardData(
      {@required this.category, @required this.question, this.header});

  factory EssentielCardData.fromGSheet(Map<String, dynamic> json) {
    final image = json['Image'];
    return EssentielCardData(
        category: Category.values
            .firstWhere((element) => element.title() == json['Catégorie']),
        question: json['Question'],
        header: (image != null && image.toString().trim().isNotEmpty)
            ? Image.network(image)
            : null);
  }
}

class EssentialCard extends StatefulWidget {
  final EssentielCardData cardData;
  final VoidCallback onFlip;

  const EssentialCard({Key key, this.cardData, this.onFlip}) : super(key: key);

  @override
  _EssentialCardState createState() => _EssentialCardState();
}

class _EssentialCardState extends State<EssentialCard> {
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
                    widget.cardData.question,
                    style: TextStyle(
                        fontSize: 28.0,
                        color: widget.cardData.category.color()),
                  ),
                ),
                Positioned.fill(
                    child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: widget.cardData.category.color(),
                    ),
                    child: Text(
                      widget.cardData.category.title(),
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
