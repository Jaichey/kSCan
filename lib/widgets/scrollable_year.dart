import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoYearSelector extends StatelessWidget {
  final TextEditingController controller;

  const CupertinoYearSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final List<int> years = List.generate(100, (index) => currentYear - index);

    int selectedIndex = years.indexOf(
      int.tryParse(controller.text) ?? currentYear,
    );

    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder:
              (_) => Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  child: Container(
                    height: 150,
                    width: 300,
                    color: Colors.white,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedIndex,
                      ),
                      itemExtent: 40,
                      diameterRatio: 1.2,
                      magnification: 1.2,
                      useMagnifier: true,
                      backgroundColor: Colors.white,
                      onSelectedItemChanged: (_) {},
                      children:
                          years.map((year) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                controller.text = year.toString();
                                Navigator.of(context).pop();
                              },
                              child: Center(
                                child: Text(
                                  '$year',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
        );
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: "Year Of Passing",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2.0),
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          validator: (value) => value!.isEmpty ? "Required" : null,
        ),
      ),
    );
  }
}
