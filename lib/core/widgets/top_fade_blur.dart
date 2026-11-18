import 'dart:ui';

import 'package:flutter/material.dart';

// 스크롤 영역 상단에 블러와 그라데이션을 겹쳐
// 위로 올라간 내용이 상단 경계에서 자연스럽게 사라지도록 하는 위젯
// 배경색도 함께 칠하므로 화면 최상단의 ColoredBox 대신 사용 가능
// SafeArea 바깥에서 쓰면 상태 표시줄 바로 아래부터 블러 적용
class TopFadeBlur extends StatelessWidget {
  const TopFadeBlur({
    super.key,
    required this.color,
    required this.child,
    this.height = 20,
  });

  // 화면 배경색 (블러 상단도 이 색으로 덮음)
  final Color color;
  final Widget child;
  final double height;

  // 위로 갈수록 강한 블러를 겹쳐 블러 경계가 드러나지 않도록 함
  static const List<double> _blurSigmas = [1.5, 3.0, 5.0];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: color, child: child),
        Positioned(
          // SafeArea 안에서는 0, 바깥에서는 상태 표시줄 높이
          top: MediaQuery.paddingOf(context).top,
          left: 0,
          right: 0,
          height: height,
          // 블러 영역이 스크롤과 터치를 막지 않도록 설정
          child: IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < _blurSigmas.length; i++)
                  Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: 1 - i / _blurSigmas.length,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: _blurSigmas[i],
                            sigmaY: _blurSigmas[i],
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),

                // 맨 위는 배경색으로 덮고 아래로 갈수록 투명하게
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
