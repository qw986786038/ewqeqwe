import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:yidivination/bokong/widget/argon_buttons_flutter.dart';

typedef FutureTap = Future Function();

class AppLoadingButton extends StatefulWidget {
  const AppLoadingButton({
    super.key,
    this.text,
    this.child,
    this.width,
    this.height,
    this.background,
    this.elevation,
    this.textColor,
    this.loadingColor,
    this.padding,
    this.margin,
    this.radius,
    this.hoverElevation,
    this.highlightElevation,
    this.enable = true,
    this.onTap,
  });
  final String? text;
  final Widget? child;
  final double? width;
  final double? height;
  final Color? background;
  final double? elevation;
  final double? hoverElevation;
  final double? highlightElevation;
  final Color? textColor;
  final Color? loadingColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final FutureTap? onTap;
  final bool? enable;

  @override
  _AppLoadingButtonState createState() => _AppLoadingButtonState();
}

class _AppLoadingButtonState extends State<AppLoadingButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      width: widget.width ?? 90,
      child: ArgonButton(
        width: widget.width ?? 90,
        height: widget.height ?? 50,
        elevation: widget.elevation,
        hoverElevation: widget.hoverElevation,
        roundLoadingShape: false,
        highlightElevation: widget.highlightElevation,
        focusElevation: 2,
        disabledElevation: 0,
        borderRadius: widget.radius ?? 5,
        disabledColor: const Color(0xFFBBBBBB),
        loader: Container(
          padding: const EdgeInsets.all(8),
          child: SpinKitRotatingCircle(
            color: widget.loadingColor ?? Colors.white,
          ),
        ),
        highlightColor: const Color(0x334A90D9),
        splashColor: Colors.transparent,
        enable: widget.enable ?? true,
        onTap: widget.onTap == null
            ? null
            : (startLoading, stopLoading, btnState) {
                if (btnState == ButtonState.Idle) {
                  startLoading();
                  widget.onTap
                          ?.call()
                          .catchError((error) => stopLoading())
                          .whenComplete(() => stopLoading()) ??
                      stopLoading();
                }
              },
        child: widget.child == null
            ? Text(
                widget.text ?? "",
                style: TextStyle(color: widget.textColor ?? Colors.white),
              )
            : widget.child!,
        color: widget.background ?? Colors.blue,
      ),
    );
  }
}
