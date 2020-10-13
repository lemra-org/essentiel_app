import 'package:essentiel/resources/category.dart';
import 'package:flutter/material.dart';

class EssentielCard {
  final Category category;
  final String question;
  final Widget header;

  const EssentielCard(
      {@required this.category, @required this.question, this.header});
}
