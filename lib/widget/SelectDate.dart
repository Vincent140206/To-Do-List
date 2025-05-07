import 'package:flutter/material.dart';

class DatePickerField extends StatefulWidget {
  final String label;
  final String? iconAssetPath;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime>? onDateChanged;
  final TextEditingController? controller;

  const DatePickerField({
    Key? key,
    required this.label,
    this.iconAssetPath,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.onDateChanged,
    this.controller,
  }) : super(key: key);

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late DateTime _selectedDate;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    } else {
      DateTime now = DateTime.now();
      if (now.isAfter(widget.lastDate)) {
        _selectedDate = widget.lastDate;
      } else if (now.isBefore(widget.firstDate)) {
        _selectedDate = widget.firstDate;
      } else {
        _selectedDate = now;
      }
    }

    _controller = widget.controller ?? TextEditingController();
    _updateDisplayDate();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateDisplayDate() {
    _controller.text = "${_selectedDate.day.toString().padLeft(2, '0')}/"
        "${_selectedDate.month.toString().padLeft(2, '0')}/"
        "${_selectedDate.year}";
  }

  void _showDatePicker() {
    try {
      print("Attempting to show date picker");
      print("Current date range: ${widget.firstDate} to ${widget.lastDate}");
      print("Current selected date: $_selectedDate");

      if (!mounted) {
        print("Widget is not mounted, cannot show date picker");
        return;
      }

      DateTime initialPickerDate = _selectedDate;
      if (initialPickerDate.isAfter(widget.lastDate)) {
        initialPickerDate = widget.lastDate;
      }
      if (initialPickerDate.isBefore(widget.firstDate)) {
        initialPickerDate = widget.firstDate;
      }

      print("Using initialDate for picker: $initialPickerDate");

      showDatePicker(
        context: context,
        initialDate: initialPickerDate,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
      ).then((pickedDate) {
        print("Date picker result: $pickedDate");

        if (pickedDate != null && pickedDate != _selectedDate) {
          setState(() {
            _selectedDate = pickedDate;
            _updateDisplayDate();
          });
          if (widget.onDateChanged != null) {
            widget.onDateChanged!(pickedDate);
          }
        }
      }).catchError((error) {
        print("Error showing date picker: $error");
      });
    } catch (e) {
      print("Exception while showing date picker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showDatePicker,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.iconAssetPath != null
              ? Padding(
            padding: const EdgeInsets.all(12.0),
            child: ImageIcon(
              AssetImage(widget.iconAssetPath!),
              color: Colors.black,
            ),
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          _controller.text,
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
    );
  }
}