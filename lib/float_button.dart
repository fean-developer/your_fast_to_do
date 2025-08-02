import 'package:flutter/material.dart';
import 'package:your_fast_to_do/admin_screen.dart';
import 'package:your_fast_to_do/timeline_screen.dart';

class FloatMenuButton extends StatefulWidget {
  const FloatMenuButton({Key? key}) : super(key: key);

  @override
  State<FloatMenuButton> createState() => _FloatMenuButtonState();
}

class _FloatMenuButtonState extends State<FloatMenuButton> with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 56,
        height: 180,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
              // Botão 1
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                right: 8,
                bottom: _open ? 70 : 0,
                child: Opacity(
                  opacity: _open ? 1 : 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _toggle();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const TimelineScreen()),
                          );
                        },
                        child: const Icon(
                          Icons.task,
                          color: Colors.white,
                          size: 20,
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Botão 2
              // AnimatedPositioned(
              //   duration: const Duration(milliseconds: 200),
              //   right: 8,
              //   bottom: _open ? 80 : 0,
              //   child: Opacity(
              //     opacity: _open ? 1 : 0,
              //     child: Container(
              //       width: 40,
              //       height: 40,
              //       decoration: const BoxDecoration(
              //         color: Colors.green,
              //         shape: BoxShape.circle,
              //       ),
              //       child: Material(
              //         color: Colors.transparent,
              //         child: InkWell(
              //           borderRadius: BorderRadius.circular(20),
              //           onTap: () {
              //             _toggle();
              //             Navigator.of(context).pushReplacement(
              //               MaterialPageRoute(builder: (_) => AdminScreen(onSave: () {})),
              //             );
              //           },
              //           child: const Icon(
              //             Icons.work,
              //             color: Colors.white,
              //             size: 20,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              // // Botão principal
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _toggle,
                    child: AnimatedRotation(
                      turns: _open ? 0.125 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}

// Removido _FloatMenuAction: agora só FloatingActionButton circular, sem texto
