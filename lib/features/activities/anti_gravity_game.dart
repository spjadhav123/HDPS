// lib/features/activities/anti_gravity_game.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class FloatingObject {
  final int id;
  final IconData icon;
  final Color color;
  final double size;
  
  double x;
  double y;
  double vx;
  double vy;
  bool isDragging;
  bool isCollectible; // If it's a star that gives points

  FloatingObject({
    required this.id,
    required this.icon,
    required this.color,
    required this.size,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.isDragging = false,
    this.isCollectible = false,
  });
}

class AntiGravityGame extends StatefulWidget {
  const AntiGravityGame({super.key});

  @override
  State<AntiGravityGame> createState() => _AntiGravityGameState();
}

class _AntiGravityGameState extends State<AntiGravityGame> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<FloatingObject> _objects = [];
  final Random _random = Random();
  
  bool _isAntiGravity = true;
  int _score = 0;
  
  // Physics constants
  final double _gravityForce = 0.5;
  final double _antiGravityForce = -0.3; // Upward pull
  final double _friction = 0.98; // Air resistance drifting
  final double _bounceFactor = -0.7; // How bouncy the walls are
  
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 365))
      ..addListener(_updatePhysics)
      ..forward();
      
    _spawnInitialObjects();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawnInitialObjects() {
    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.accent, AppTheme.warning, Colors.purpleAccent, Colors.pinkAccent];
    final icons = [Icons.rocket_launch_rounded, Icons.sports_soccer_rounded, Icons.smart_toy_rounded, Icons.public_rounded, Icons.bedtime_rounded];
    
    // Spawn regular toys
    for (int i = 0; i < 8; i++) {
      _objects.add(
        FloatingObject(
          id: i,
          icon: icons[_random.nextInt(icons.length)],
          color: colors[_random.nextInt(colors.length)],
          size: 60.0 + _random.nextDouble() * 40.0,
          x: 100.0 + _random.nextDouble() * 200,
          y: 200.0 + _random.nextDouble() * 300,
          vx: (_random.nextDouble() - 0.5) * 5,
          vy: (_random.nextDouble() - 0.5) * 5,
        )
      );
    }
    _spawnStar();
    _spawnStar();
  }

  void _spawnStar() {
    _objects.add(
      FloatingObject(
        id: _random.nextInt(10000) + 100, // Safe ID
        icon: Icons.star_rounded,
        color: Colors.amber,
        size: 70.0,
        x: 50.0 + _random.nextDouble() * 200,
        y: 100.0 + _random.nextDouble() * 400,
        vx: (_random.nextDouble() - 0.5) * 4,
        vy: (_random.nextDouble() - 0.5) * 4,
        isCollectible: true,
      )
    );
  }

  void _updatePhysics() {
    if (_screenSize == Size.zero) return;
    
    setState(() {
      for (var obj in _objects) {
        if (obj.isDragging) continue;

        // Apply Forces
        obj.vy += _isAntiGravity ? _antiGravityForce : _gravityForce;
        
        // Add some random drift / wind for realism
        obj.vx += (_random.nextDouble() - 0.5) * 0.2;

        // Apply Friction
        obj.vx *= _friction;
        obj.vy *= _friction;

        // Apply Velocity
        obj.x += obj.vx;
        obj.y += obj.vy;

        // Wall Collisions (Bounce)
        if (obj.x <= 0) {
          obj.x = 0;
          obj.vx *= _bounceFactor;
        } else if (obj.x + obj.size >= _screenSize.width) {
          obj.x = _screenSize.width - obj.size;
          obj.vx *= _bounceFactor;
        }

        if (obj.y <= 0) {
          obj.y = 0;
          obj.vy *= _bounceFactor;
          // In anti-gravity, let objects hang around the top easily
          if (_isAntiGravity) obj.vy *= 0.8; 
        } else if (obj.y + obj.size >= _screenSize.height) {
          obj.y = _screenSize.height - obj.size;
          obj.vy *= _bounceFactor;
        }
      }
    });
  }

  void _onPanStart(FloatingObject obj) {
    setState(() {
      obj.isDragging = true;
      obj.vx = 0;
      obj.vy = 0;
    });
  }

  void _onPanUpdate(FloatingObject obj, DragUpdateDetails details) {
    setState(() {
      obj.x += details.delta.dx;
      obj.y += details.delta.dy;
      // Track velocity based on user drag speed
      obj.vx = details.delta.dx * 0.5;
      obj.vy = details.delta.dy * 0.5;
    });
  }

  void _onPanEnd(FloatingObject obj, DragEndDetails details) {
    setState(() {
      obj.isDragging = false;
      // Add natural throw momentum
      obj.vx += details.velocity.pixelsPerSecond.dx * 0.015;
      obj.vy += details.velocity.pixelsPerSecond.dy * 0.015;
    });
  }

  void _onTapObject(FloatingObject obj) {
    setState(() {
      if (obj.isCollectible) {
        _score += 10;
        _objects.remove(obj);
        _spawnStar(); // Spawn a new one!
      } else {
        // Boost upwards!
        obj.vy -= 12.0; 
        obj.vx += (_random.nextDouble() - 0.5) * 10;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Space Blue
      body: LayoutBuilder(
        builder: (context, constraints) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          
          return Stack(
            children: [
              // Background Stars
              Positioned.fill(child: _buildBackgroundStars()),
              
              // Floating Objects
              ..._objects.map((obj) => Positioned(
                left: obj.x,
                top: obj.y,
                child: GestureDetector(
                  onPanStart: (_) => _onPanStart(obj),
                  onPanUpdate: (d) => _onPanUpdate(obj, d),
                  onPanEnd: (d) => _onPanEnd(obj, d),
                  onTap: () => _onTapObject(obj),
                  child: Container(
                    width: obj.size,
                    height: obj.size,
                    decoration: BoxDecoration(
                      color: obj.color.withOpacity(obj.isCollectible ? 1.0 : 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: obj.color.withOpacity(0.5),
                          blurRadius: obj.isCollectible ? 25 : 15,
                          spreadRadius: obj.isCollectible ? 5 : 0,
                        )
                      ],
                    ),
                    child: Icon(obj.icon, color: Colors.white, size: obj.size * 0.5),
                  )
                ).animate(onPlay: (c) => obj.isCollectible ? c.repeat(reverse: true) : null)
                 .scaleXY(end: 1.1, duration: 800.ms),
              )),
              
              // UI Overlay
              _buildUIOverlay(),
            ],
          );
        }
      ),
    );
  }

  Widget _buildBackgroundStars() {
    return Opacity(
      opacity: 0.3,
      child: Stack(
        children: List.generate(40, (index) {
          return Positioned(
            left: _random.nextDouble() * (_screenSize.width > 0 ? _screenSize.width : 1000),
            top: _random.nextDouble() * (_screenSize.height > 0 ? _screenSize.height : 1000),
            child: Icon(Icons.star, color: Colors.white, size: _random.nextDouble() * 10 + 2),
          );
        }),
      ),
    );
  }

  Widget _buildUIOverlay() {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score Ticket
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.warning,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: AppTheme.warning.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text('$_score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ).animate(key: ValueKey(_score)).shakeX(amount: 3),
          
          // Environment Toggle
          GestureDetector(
            onTap: () => setState(() => _isAntiGravity = !_isAntiGravity),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _isAntiGravity ? AppTheme.primary : Colors.blueGrey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(_isAntiGravity ? Icons.air_rounded : Icons.keyboard_double_arrow_down_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isAntiGravity ? 'ANTI-GRAVITY' : 'NORMAL GRAVITY',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
