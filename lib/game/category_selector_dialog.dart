import 'package:essentiel/resources/category.dart';
import 'package:flutter/material.dart';

typedef CategorySelectorDialogCallback = void Function(
    List<String> selectedCategories);

class CategorySelectorDialog extends StatefulWidget {
  final Widget title;
  final List<String> all;
  final List<String> selected;
  final CategorySelectorDialogCallback callback;

  CategorySelectorDialog(
      {Key key,
      @required this.title,
      @required this.all,
      this.selected,
      @required this.callback})
      : super(key: key);

  @override
  _CategorySelectorDialogState createState() => _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<CategorySelectorDialog> {
  List<String> selectedItems;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: Wrap(
        children: widget.all.map((category) {
          final elementsWhere =
              Category.values.where((element) => element.title() == category);
          Color chipColor;
          if (elementsWhere.isNotEmpty) {
            chipColor = elementsWhere.elementAt(0).color();
          } else {
            if (category == "Couples") {
              chipColor = Colors.pink;
            } else {
              chipColor = Colors.brown;
            }
          }
          final isSelected = selectedItems.contains(category);
          return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedItems.contains(category)) {
                      selectedItems.remove(category);
                    } else {
                      selectedItems.add(category);
                    }
                  });
                },
                child: Chip(
                  backgroundColor: isSelected ? chipColor : Colors.grey[200],
                  label: Text(
                    category,
                    style: TextStyle(
                      fontSize: 20.0,
                      color: isSelected ? Colors.white : chipColor,
                    ),
                  ),
                ),
              ));
        }).toList(),
      ),
      actions: [
        //TODO
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    this.selectedItems = [];
  }
}
