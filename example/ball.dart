import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Bounce Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const BallGame(),
    );
  }
}

// 공 클래스
class Ball {
  Offset position;
  Offset velocity;
  final double radius;
  final Color color;
  bool isDragging = false;
  Offset? dragStartPosition;
  Offset? dragCurrentPosition;

  Ball({
    required this.position,
    required this.radius,
    required this.color,
    Offset? velocity,
  }) : velocity = velocity ?? Offset.zero;
}

class BallGame extends StatefulWidget {
  const BallGame({super.key});

  @override
  State<BallGame> createState() => _BallGameState();
}

class _BallGameState extends State<BallGame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Ball> balls = [];
  Size? screenSize;
  int? draggingBallIndex;
  
  // 공 색상 목록
  final List<Color> ballColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateBalls);
    _controller.repeat();
  }

  void _initBalls() {
    if (screenSize == null || balls.isNotEmpty) return;
    
    final random = Random();
    for (int i = 0; i < 5; i++) {
      balls.add(Ball(
        position: Offset(
          100 + random.nextDouble() * (screenSize!.width - 200),
          100 + random.nextDouble() * (screenSize!.height - 200),
        ),
        radius: 30,
        color: ballColors[i],
      ));
    }
  }

  void _updateBalls() {
    if (screenSize == null) return;
    
    setState(() {
      // 각 공 업데이트
      for (int i = 0; i < balls.length; i++) {
        if (balls[i].isDragging) continue;
        
        // 속도 적용
        balls[i].position += balls[i].velocity;
        
        // 마찰 적용
        balls[i].velocity *= 0.995;
        
        // 벽 충돌 검사
        _checkWallCollision(balls[i]);
      }
      
      // 공끼리 충돌 검사
      _checkBallCollisions();
    });
  }

  void _checkWallCollision(Ball ball) {
    // 왼쪽 벽
    if (ball.position.dx - ball.radius < 0) {
      ball.position = Offset(ball.radius, ball.position.dy);
      ball.velocity = Offset(-ball.velocity.dx * 0.9, ball.velocity.dy);
    }
    // 오른쪽 벽
    if (ball.position.dx + ball.radius > screenSize!.width) {
      ball.position = Offset(screenSize!.width - ball.radius, ball.position.dy);
      ball.velocity = Offset(-ball.velocity.dx * 0.9, ball.velocity.dy);
    }
    // 위쪽 벽
    if (ball.position.dy - ball.radius < 0) {
      ball.position = Offset(ball.position.dx, ball.radius);
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy * 0.9);
    }
    // 아래쪽 벽
    if (ball.position.dy + ball.radius > screenSize!.height) {
      ball.position = Offset(ball.position.dx, screenSize!.height - ball.radius);
      ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy * 0.9);
    }
  }

  void _checkBallCollisions() {
    for (int i = 0; i < balls.length; i++) {
      for (int j = i + 1; j < balls.length; j++) {
        Ball ball1 = balls[i];
        Ball ball2 = balls[j];
        
        // 두 공 사이 거리 계산
        double dx = ball2.position.dx - ball1.position.dx;
        double dy = ball2.position.dy - ball1.position.dy;
        double distance = sqrt(dx * dx + dy * dy);
        double minDistance = ball1.radius + ball2.radius;
        
        if (distance < minDistance && distance > 0) {
          // 충돌 발생
          // 정규화된 충돌 벡터
          double nx = dx / distance;
          double ny = dy / distance;
          
          // 상대 속도
          double dvx = ball1.velocity.dx - ball2.velocity.dx;
          double dvy = ball1.velocity.dy - ball2.velocity.dy;
          
          // 상대 속도의 법선 성분
          double dvn = dvx * nx + dvy * ny;
          
          // 이미 멀어지고 있으면 무시
          if (dvn > 0) continue;
          
          // 충돌 응답 (탄성 충돌)
          double restitution = 0.9;
          double impulse = -(1 + restitution) * dvn / 2;
          
          if (!ball1.isDragging) {
            ball1.velocity = Offset(
              ball1.velocity.dx + impulse * nx,
              ball1.velocity.dy + impulse * ny,
            );
          }
          if (!ball2.isDragging) {
            ball2.velocity = Offset(
              ball2.velocity.dx - impulse * nx,
              ball2.velocity.dy - impulse * ny,
            );
          }
          
          // 겹침 해결
          double overlap = minDistance - distance;
          if (!ball1.isDragging && !ball2.isDragging) {
            ball1.position = Offset(
              ball1.position.dx - overlap / 2 * nx,
              ball1.position.dy - overlap / 2 * ny,
            );
            ball2.position = Offset(
              ball2.position.dx + overlap / 2 * nx,
              ball2.position.dy + overlap / 2 * ny,
            );
          } else if (ball1.isDragging) {
            ball2.position = Offset(
              ball2.position.dx + overlap * nx,
              ball2.position.dy + overlap * ny,
            );
          } else {
            ball1.position = Offset(
              ball1.position.dx - overlap * nx,
              ball1.position.dy - overlap * ny,
            );
          }
        }
      }
    }
  }

  int? _getBallAtPosition(Offset position) {
    for (int i = balls.length - 1; i >= 0; i--) {
      double dx = position.dx - balls[i].position.dx;
      double dy = position.dy - balls[i].position.dy;
      if (sqrt(dx * dx + dy * dy) <= balls[i].radius) {
        return i;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('공 던지기 게임'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                balls.clear();
                _initBalls();
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          _initBalls();
          
          return GestureDetector(
            onPanStart: (details) {
              int? index = _getBallAtPosition(details.localPosition);
              if (index != null) {
                setState(() {
                  draggingBallIndex = index;
                  balls[index].isDragging = true;
                  balls[index].dragStartPosition = details.localPosition;
                  balls[index].dragCurrentPosition = details.localPosition;
                  balls[index].velocity = Offset.zero;
                });
              }
            },
            onPanUpdate: (details) {
              if (draggingBallIndex != null) {
                setState(() {
                  balls[draggingBallIndex!].position = details.localPosition;
                  balls[draggingBallIndex!].dragCurrentPosition = details.localPosition;
                });
              }
            },
            onPanEnd: (details) {
              if (draggingBallIndex != null) {
                setState(() {
                  Ball ball = balls[draggingBallIndex!];
                  ball.isDragging = false;
                  
                  // 드래그 속도를 공의 속도로 변환
                  ball.velocity = details.velocity.pixelsPerSecond / 60;
                  
                  ball.dragStartPosition = null;
                  ball.dragCurrentPosition = null;
                  draggingBallIndex = null;
                });
              }
            },
            child: CustomPaint(
              painter: BallPainter(balls: balls),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

class BallPainter extends CustomPainter {
  final List<Ball> balls;

  BallPainter({required this.balls});

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그리드 그리기
    final gridPaint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 1;
    
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 공 그리기
    for (Ball ball in balls) {
      // 그림자
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        ball.position + const Offset(4, 4),
        ball.radius,
        shadowPaint,
      );

      // 공 본체
      final ballPaint = Paint()
        ..color = ball.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ball.position, ball.radius, ballPaint);

      // 공 하이라이트 (광택 효과)
      final highlightPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.6),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(
          center: ball.position - Offset(ball.radius * 0.3, ball.radius * 0.3),
          radius: ball.radius * 0.5,
        ));
      canvas.drawCircle(
        ball.position - Offset(ball.radius * 0.3, ball.radius * 0.3),
        ball.radius * 0.4,
        highlightPaint,
      );

      // 공 테두리
      final borderPaint = Paint()
        ..color = ball.color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(ball.position, ball.radius, borderPaint);

      // 속도 표시 (공이 움직일 때)
      if (ball.velocity.distance > 1) {
        final velocityPaint = Paint()
          ..color = Colors.yellow.withOpacity(0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        
        Offset velocityEnd = ball.position + ball.velocity * 5;
        canvas.drawLine(ball.position, velocityEnd, velocityPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
