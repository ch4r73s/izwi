import 'package:flutter/material.dart';
import 'wavy_painter.dart';

class WavyScaffold extends StatelessWidget {
  final ThemeData theme;
  final Widget body;
  final List<Widget>? floatingActionButtons;

  WavyScaffold({
    required this.theme,
    required this.body,
    this.floatingActionButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Stack(
        children: [
          CustomPaint(
            painter: WavePainter(color: theme.scaffoldBackgroundColor),
            child: Container(
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          Positioned.fill(child: body),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          if (floatingActionButtons != null)
            for (var i = 0; i < floatingActionButtons!.length; i++)
              Positioned(
                bottom: 8.0 + (i * 50.0), // Adjust spacing as needed
                right: 8.0,
                child: floatingActionButtons![i],
              ),
        ],
      ),
    );
  }
}

class WavyScaffoldOne extends StatelessWidget {
  final Widget body;
  final List<Widget>? floatingActionButtons;

  WavyScaffoldOne({required this.body, this.floatingActionButtons});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: WavePainterOne(),
            child: Container(
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          Positioned.fill(child: body),
        ],
      ),
      floatingActionButton: Stack(
        // children: floatingActionButtons ?? [],
        children: [
          if (floatingActionButtons != null)
            for (var i = 0; i < floatingActionButtons!.length; i++)
              Positioned(
                bottom: 8.0 + (i * 50.0), // Adjust spacing as needed
                right: 8.0,
                child: floatingActionButtons![i],
              ),
        ],
      ),
    );
  }
}
