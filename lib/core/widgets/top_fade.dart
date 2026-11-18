import 'package:flutter/material.dart';

// 스크롤 영역 상단에 그라데이션을 겹쳐
// 위로 올라간 내용이 상단 경계에서 자연스럽게 사라지도록 하는 위젯
// 블러는 절전 모드 등에서 성능 저하가 커서 그라데이션만 사용
// 배경색도 함께 칠하므로 화면 최상단의 ColoredBox 대신 사용 가능
// SafeArea 바깥에서 쓰면 상태 표시줄 바로 아래부터 적용
class TopFade extends StatelessWidget {
  const TopFade({
    super.key,
    required this.color,
    required this.child,
    this.height = 20,
  });

  // 화면 배경색 (상단 그라데이션도 이 색으로 칠함)
  final Color color;
  final Widget child;
  final double height;

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
          // 그라데이션 영역이 스크롤과 터치를 막지 않도록 설정
          child: IgnorePointer(
            // 맨 위는 배경색으로 덮고 아래로 갈수록 투명하게
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color,
                    color.withValues(alpha: 0.6),
                    color.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
