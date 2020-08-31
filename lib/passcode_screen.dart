library passcode_screen;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/shake_curve.dart';

typedef PasswordEnteredCallback = void Function(String text);
typedef IsValidCallback = void Function();
typedef CancelCallback = void Function();

class PasscodeScreen extends StatefulWidget {
  final Widget title, showTheTextError;
  final int passwordDigits;
  final Color backgroundColor;
  final PasswordEnteredCallback passwordEnteredCallback;

  //isValidCallback will be invoked after passcode screen will pop.
  final IsValidCallback isValidCallback;
  final CancelCallback cancelCallback;

  // Cancel button and delete button will be switched based on the screen state
  final Widget cancelButton;
  final Widget deleteButton;
  final Stream<bool> shouldTriggerVerification;
  final Widget bottomWidget;
  final CircleUIConfig circleUIConfig;
  final KeyboardUIConfig keyboardUIConfig;
  final List<String> digits;

  PasscodeScreen({
    Key key,
    @required this.title,
    this.passwordDigits = 4,
    @required this.passwordEnteredCallback,
    @required this.cancelButton,
    @required this.deleteButton,
    @required this.shouldTriggerVerification,
    this.isValidCallback,
    CircleUIConfig circleUIConfig,
    KeyboardUIConfig keyboardUIConfig,
    this.bottomWidget,
    this.backgroundColor,
    this.cancelCallback,
    this.showTheTextError,
    this.digits,
  })  : circleUIConfig =
            circleUIConfig == null ? const CircleUIConfig() : circleUIConfig,
        keyboardUIConfig = keyboardUIConfig == null
            ? const KeyboardUIConfig()
            : keyboardUIConfig,
        super(key: key);

  @override
  State<StatefulWidget> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<bool> streamSubscription;
  String enteredPasscode = '';
  AnimationController controller;
  Animation<double> animation;

  @override
  initState() {
    super.initState();
    streamSubscription = widget.shouldTriggerVerification
        .listen((isValid) => _showValidation(isValid));
    controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final Animation curve =
        CurvedAnimation(parent: controller, curve: ShakeCurve());
    animation = Tween(begin: 0.0, end: 10.0).animate(curve)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            enteredPasscode = '';
            controller.value = 0;
          });
        }
      })
      ..addListener(() {
        setState(() {
          // the animation object’s value is the changed state
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return _buildPortraitPasscodeScreen();
          },
        ),
      ),
    );
  }

  _buildPortraitPasscodeScreen() => Container(
        alignment: Alignment.center,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.vpn_lock,
                  color: Colors.yellow,
                  size: 40.0,
                ),
                SizedBox(
                  width: 10.0,
                ),
                Text('Chef Tech',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 35.0,
                        fontWeight: FontWeight.bold))
              ],
            ),
            SizedBox(height: 15.0),
            widget.title,
            SizedBox(height: widget.showTheTextError != null ? 10.0 : 0.0),
            widget.showTheTextError ?? Container(),
            Container(
              margin: const EdgeInsets.only(top: 20),
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildCircles(),
              ),
            ),
            _buildKeyboard(),
            widget.bottomWidget != null ? widget.bottomWidget : Container()
          ],
        ),
      );

  _buildLandscapePasscodeScreen() => Center(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.title,
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _buildCircles(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  widget.bottomWidget != null
                      ? Positioned(
                          child: Align(
                              alignment: Alignment.topCenter,
                              child: widget.bottomWidget),
                        )
                      : Container()
                ],
              ),
            ),
            _buildKeyboard(),
          ],
        ),
      );

  _buildKeyboard() => Container(
        child: Keyboard(
          onKeyboardTap: _onKeyboardButtonPressed,
          keyboardUIConfig: widget.keyboardUIConfig,
          digits: widget.digits,
          actionDelete: () {
            _onDeleteCancelButtonPressed();
          },
          actionBack: () {
            _onBack();
          },
        ),
      );

  List<Widget> _buildCircles() {
    var list = <Widget>[];
    var config = widget.circleUIConfig;
    var extraSize = animation.value;
    for (int i = 0; i < widget.passwordDigits; i++) {
      list.add(
        Container(
          margin: EdgeInsets.all(10),
          child: Circle(
            filled: i < enteredPasscode.length,
            circleUIConfig: config,
            extraSize: extraSize,
          ),
        ),
      );
    }
    return list;
  }

  _onDeleteCancelButtonPressed() {
    if (enteredPasscode.length > 0) {
      setState(() {
        enteredPasscode =
            enteredPasscode.substring(0, enteredPasscode.length - 1);
      });
    } else {
      controller.forward();
    }
  }

  _onBack() {
    if (widget.cancelCallback != null) {
      widget.cancelCallback();
    }
  }

  _onKeyboardButtonPressed(String text) {
    setState(() {
      if (enteredPasscode.length < widget.passwordDigits) {
        enteredPasscode += text;
        if (enteredPasscode.length == widget.passwordDigits) {
          widget.passwordEnteredCallback(enteredPasscode);
        }
      }
    });
  }

  @override
  didUpdateWidget(PasscodeScreen old) {
    super.didUpdateWidget(old);
    // in case the stream instance changed, subscribe to the new one
    if (widget.shouldTriggerVerification != old.shouldTriggerVerification) {
      streamSubscription.cancel();
      streamSubscription = widget.shouldTriggerVerification
          .listen((isValid) => _showValidation(isValid));
    }
  }

  @override
  dispose() {
    controller.dispose();
    streamSubscription.cancel();
    super.dispose();
  }

  _showValidation(bool isValid) {
    if (isValid) {
      Navigator.maybePop(context).then((pop) => _validationCallback());
    } else {
      controller.forward();
    }
  }

  _validationCallback() {
    if (widget.isValidCallback != null) {
      widget.isValidCallback();
    } else {
      print(
          "You didn't implement validation callback. Please handle a state by yourself then.");
    }
  }

//  Widget _buildDeleteButton() {
//    return Container(
//      child: CupertinoButton(
//        onPressed: _onDeleteCancelButtonPressed,
//        child: Container(
//          margin: widget.keyboardUIConfig.digitInnerMargin,
//          child: enteredPasscode.length == 0
//              ? widget.cancelButton
//              : widget.deleteButton,
//        ),
//      ),
//    );
//  }
}
