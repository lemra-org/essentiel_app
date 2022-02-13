import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

typedef CategorySelectorDialogCallback = void Function(
    List<String> selectedCategories);

typedef TextBackgroundColorProvider = Color Function(
    String text, bool isSelected);
typedef TextColorProvider = Color Function(String text, bool isSelected);

class CategorySelectorDialog extends StatefulWidget {
  final Widget? title;
  final List<String>? all;
  final List<String>? selected;
  final TextBackgroundColorProvider? textBackgroundColorProvider;
  final TextColorProvider? textColorProvider;
  final CategorySelectorDialogCallback? callback;

  CategorySelectorDialog(
      {Key? key,
      @required this.title,
      @required this.all,
      this.selected,
      @required this.callback,
      this.textBackgroundColorProvider,
      this.textColorProvider})
      : super(key: key);

  @override
  _CategorySelectorDialogState createState() => _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<CategorySelectorDialog> {
  Set<String>? selectedItems;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: Wrap(
        children: widget.all!.map((element) {
          final isSelected = selectedItems?.contains(element) ?? false;
          return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedItems != null &&
                        selectedItems!.contains(element)) {
                      selectedItems!.remove(element);
                    } else {
                      if (selectedItems == null) {
                        selectedItems = LinkedHashSet();
                      }
                      selectedItems!.add(element);
                    }
                  });
                },
                child: Chip(
                  backgroundColor: widget.textBackgroundColorProvider != null
                      ? widget.textBackgroundColorProvider!(element, isSelected)
                      : null,
                  label: Text(
                    element,
                    style: TextStyle(
                      fontSize: 20.0,
                      color: widget.textColorProvider != null
                          ? widget.textColorProvider!(element, isSelected)
                          : null,
                    ),
                  ),
                ),
              ));
        }).toList(),
      ),
      actions: [
        FlatButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler'.toUpperCase(),
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          textColor: Colors.blue,
        ),
        // FlatButton(
        //   onPressed: () {
        //     setState(() {
        //       if (selectedItems == null) {
        //         selectedItems = LinkedHashSet();
        //       }
        //       if (selectedItems.isEmpty) {
        //         //Select all
        //         selectedItems.addAll(widget.all);
        //       } else {
        //         //Deselect all
        //         selectedItems.clear();
        //       }
        //     });
        //   },
        //   child: Text(
        //       'Tout ${selectedItems?.isEmpty ?? true ? '' : 'dé'}sélectionner',
        //       style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
        // ),
        FlatButton(
          onPressed: () {
            if (selectedItems != null && selectedItems!.isEmpty) {
              Fluttertoast.cancel();
              Fluttertoast.showToast(
                  msg: 'Merci de choisir au moins une catégorie !',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.SNACKBAR,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            } else {
              if (selectedItems != null && widget.callback != null) {
                widget.callback!(selectedItems!.toList(growable: false));
              }
              Navigator.of(context).pop();
            }
          },
          child: Text(
            'Appliquer'.toUpperCase(),
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          textColor: Colors.blue,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    this.selectedItems =
        widget.selected != null ? LinkedHashSet.of(widget.selected!) : null;
  }
}
