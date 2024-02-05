import 'package:flutter/material.dart';

// KeyPad widget
// This widget is reusable and its buttons are customizable (color, size)
class NumPad extends StatelessWidget {
  final double buttonSize;
  final Color buttonColor;
  final Color iconColor;
  final TextEditingController controller = TextEditingController();
  final Function delete;
  final Function(String char) onPress;

  NumPad({
    Key? key,
    this.buttonSize = 70,
    this.buttonColor = Colors.indigo,
    this.iconColor = Colors.amber,
    required this.delete,
    //required this.onSubmit,
    //required this.controller,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      //margin: const EdgeInsets.only(left: 30, right: 30),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            // implement the number keys (from 0 to 9) with the NumberButton widget
            // the NumberButton widget is defined in the bottom of this file
            children: [
              DigitButton(
                digit: '1',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
              DigitButton(
                digit: '2',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
              DigitButton(
                digit: '3',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DigitButton(
                digit: '4',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
              DigitButton(
                digit: '5',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
              DigitButton(
                digit: '6',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DigitButton(
                digit: '7',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
              DigitButton(
                digit: '8',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
              DigitButton(
                digit: '9',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // this button is used to delete the last number
              IconButton(
                onPressed: () => delete(),
                icon: Icon(
                  Icons.backspace,
                  color: iconColor,
                ),
                iconSize: buttonSize,
              ),
              DigitButton(
                digit: '0',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
              DigitButton(
                digit: ',',
                size: buttonSize,
                color: buttonColor,
                onPress: onPress,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// define NumberButton widget
// its shape is round
class DigitButton extends StatelessWidget {
  final String digit;
  final double size;
  final Color color;
  final Function(String char) onPress;

  const DigitButton({
    Key? key,
    required this.digit,
    required this.size,
    required this.color,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size / 2),
          ),
        ),
        onPressed: () {
          onPress(digit);
        },
        child: Center(
          child: Text(
            digit.toString(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 40),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final double height;
  final String tooltip;
  final bool primary;
  final bool disabled;

  const ActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.height,
    required this.tooltip,
    required this.disabled,
    this.primary = false,
  });

  factory ActionButton.icon(
      {Key? key,
      required IconData icon,
      required VoidCallback onPressed,
      required double height,
      required String tooltip,
      required bool disabled,
      bool primary = false}) {
    return ActionButton(
        key: key,
        icon: Icon(
          icon,
          size: 60,
        ),
        tooltip: tooltip,
        primary: primary,
        disabled: disabled,
        onPressed: onPressed,
        height: height);
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: primary ? colorScheme.secondary : null,
            foregroundColor: primary ? Colors.white : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
              //side: BorderSide(color: Colors.black)
            ),
            minimumSize: Size(5, height)),
        onPressed: disabled ? null : onPressed,
        child: icon,
      ),
    );
  }
}
