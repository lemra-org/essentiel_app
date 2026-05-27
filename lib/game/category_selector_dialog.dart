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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select All / Deselect All action buttons
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (selectedItems == null) {
                        selectedItems = LinkedHashSet();
                      }
                      selectedItems!.clear();
                      selectedItems!.addAll(widget.all!);
                    });
                  },
                  icon: Icon(Icons.check_box, size: 20.0),
                  label: Text(
                    'Toutes',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                  ),
                ),
                Container(
                  width: 1.0,
                  height: 24.0,
                  color: Colors.grey[300],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (selectedItems == null) {
                        selectedItems = LinkedHashSet();
                      }
                      selectedItems!.clear();
                    });
                  },
                  icon: Icon(Icons.clear, size: 20.0),
                  label: Text(
                    'Aucune',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
          // Category chips
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: widget.all!.map((element) {
              final isSelected = selectedItems?.contains(element) ?? false;
              return GestureDetector(
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
                  );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler'.toUpperCase(),
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
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
        TextButton(
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
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // If no selection is provided, select all by default
    if (widget.selected != null) {
      this.selectedItems = LinkedHashSet.of(widget.selected!);
    } else {
      this.selectedItems = LinkedHashSet.of(widget.all!);
    }
  }
}
