import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/game.dart';
import 'components/shop.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  await Supabase.initialize(
    url: 'https://qwvhwnsapbbnqwdrdzop.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3dmh3bnNhcGJibnF3ZHJkem9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MDI5MzIsImV4cCI6MjA3NzI3ODkzMn0.BGbq6BU45nOD_1I0HAnB_VilSs-cnZYvlBY0V2ZVGto',
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _GameWrapper(),
    ),
  );
}

class _GameWrapper extends StatefulWidget {
  @override
  State<_GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<_GameWrapper> {
  final ShopManager _shopManager = ShopManager();
  MyPhysicsGame? _game;
  String _currentScreen = 'menu'; // 'menu', 'shop', 'game', 'records'

  void _startGame(LevelType levelType) {
    setState(() {
      _currentScreen = 'game';
      _game = MyPhysicsGame(
        shopManager: _shopManager,
        levelType: levelType,
      );
    });
  }

  void _returnToMenu() {
    // Resetear items comprados para el siguiente turno
    _shopManager.resetItemsForNewTurn();
    setState(() {
      _currentScreen = 'menu';
      _game = null;
    });
  }

  void _goToShop() {
    setState(() {
      _currentScreen = 'shop';
    });
  }

  void _showRecords() {
    setState(() {
      _currentScreen = 'records';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentScreen == 'menu') {
      return MainMenuScreen(
        onStartNormal: () => _startGame(LevelType.normal),
        onStartBigBoss: () => _startGame(LevelType.bigBoss),
        onGoToShop: _goToShop,
        onShowRecords: _showRecords,
      );
    }
    
    if (_currentScreen == 'shop') {
      return ShopScreen(
        shopManager: _shopManager,
        onBackToMenu: _returnToMenu,
      );
    }
    
    if (_currentScreen == 'records') {
      return RecordsScreen(
        onBackToMenu: _returnToMenu,
      );
    }

    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GameWidget.controlled(
              gameFactory: () => _game!,
              overlayBuilderMap: {
                'dialog': (context, game) {
                  return _SaveScoreDialog(
                    game: game as MyPhysicsGame,
                    onReturnToShop: _returnToMenu,
                  );
                },
                'inventory': (context, game) {
                  return _InventoryOverlay(
                    game: game as MyPhysicsGame,
                  );
                },
              },
            ),
            // Botón de inventario flotante
            Positioned(
              top: 10,
              left: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _game?.overlays.add('inventory');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'INVENTARIO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

class _SaveScoreDialog extends StatefulWidget {
  const _SaveScoreDialog({
    required this.game,
    this.onReturnToShop,
  });

  final MyPhysicsGame game;
  final VoidCallback? onReturnToShop;

  @override
  State<_SaveScoreDialog> createState() => _SaveScoreDialogState();
}

class _SaveScoreDialogState extends State<_SaveScoreDialog> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final won = widget.game.playerWon;
    final score = widget.game.score;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 400,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de resultado
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: won ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 64,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              SizedBox(height: 16),
              
              // Mensaje principal
              Text(
                won ? '¡Victoria!' : '¡Juego Terminado!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              SizedBox(height: 8),
              
              // Score
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Tu Score: $score',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Instrucción
              Text(
                'Ingresa tu nombre para guardar tu score',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              
              // Campo de texto
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Nombre del jugador',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 24),
              
              // Botones de acción
              Column(
                children: [
                  // Guardar Score
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                onPressed: () async {
                        if (_textController.text.isNotEmpty) {
                          try {
                  await widget.game.saveScore(_textController.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Score guardado exitosamente'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al guardar score: $e'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Por favor ingresa tu nombre'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.save),
                      label: Text('Guardar Score'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Nueva Ronda
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        widget.game.overlays.remove('dialog');
                        await widget.game.reset();
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Nueva Ronda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Volver a Menú
                  if (widget.onReturnToShop != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                  widget.game.overlays.remove('dialog');
                          widget.onReturnToShop!();
                        },
                        icon: Icon(Icons.home),
                        label: Text('Volver a Menú'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget del inventario durante el juego
class _InventoryOverlay extends StatefulWidget {
  final MyPhysicsGame game;

  const _InventoryOverlay({
    required this.game,
  });

  @override
  State<_InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<_InventoryOverlay> {
  @override
  Widget build(BuildContext context) {
    final shopManager = widget.game.shopManager;
    if (shopManager == null) {
      return SizedBox.shrink();
    }

    final inventoryItems = shopManager.getInventoryItems();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade400, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'INVENTARIO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        widget.game.overlays.remove('inventory');
                      },
                    ),
                  ],
                ),
              ),
              
              // Lista de items
              Flexible(
                child: inventoryItems.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tienes items en el inventario',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Compra items en la tienda antes de jugar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        shrinkWrap: true,
                        itemCount: inventoryItems.length,
                        itemBuilder: (context, index) {
                          final item = inventoryItems[index];
                          return _InventoryItemCard(
                            item: item,
                            onUse: () {
                              if (widget.game.useItem(item.id)) {
                                setState(() {});
                                widget.game.overlays.remove('inventory');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} usado'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onUse;

  const _InventoryItemCard({
    required this.item,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade800,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            
            // Información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cantidad: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón usar
            SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: item.quantity > 0 ? onUse : null,
              icon: Icon(Icons.play_arrow),
              label: Text('USAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: item.color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menú Principal con estilo espacial
class MainMenuScreen extends StatelessWidget {
  final VoidCallback onStartNormal;
  final VoidCallback onStartBigBoss;
  final VoidCallback onGoToShop;
  final VoidCallback onShowRecords;

  const MainMenuScreen({
    Key? key,
    required this.onStartNormal,
    required this.onStartBigBoss,
    required this.onGoToShop,
    required this.onShowRecords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27), // Azul muy oscuro
              Color(0xFF1A1F3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Fondo con estrellas y planetas decorativos
            _SpaceBackground(),
            
            // Contenido principal
            SafeArea(
              child: Row(
                children: [
                  // Lado izquierdo - Elementos decorativos espaciales
                  Expanded(
                    flex: 2,
                    child: _SpaceDecorations(),
                  ),
                  
                  // Lado derecho - Panel de menú
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: _MenuPanel(
                          onStartNormal: onStartNormal,
                          onStartBigBoss: onStartBigBoss,
                          onGoToShop: onGoToShop,
                          onShowRecords: onShowRecords,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fondo espacial con estrellas
class _SpaceBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpacePainter(),
      child: Container(),
    );
  }
}

class _SpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Dibujar estrellas
    final random = Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Líneas horizontales sutiles
    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1;
    
    for (int i = 0; i < 10; i++) {
      final y = (size.height / 10) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Decoraciones espaciales (planetas y órbitas)
class _SpaceDecorations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Planeta grande
        Positioned(
          left: 100,
          top: 150,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFF4A5568),
                  Color(0xFF2D3748),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _PlanetPainter(),
            ),
          ),
        ),
        
        // Órbitas
        Positioned(
          left: 50,
          top: 100,
          child: CustomPaint(
            size: Size(200, 200),
            painter: _OrbitPainter(),
          ),
        ),
        
        // Planetas pequeños
        Positioned(
          left: 200,
          top: 80,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange.withOpacity(0.7),
            ),
          ),
        ),
        Positioned(
          left: 150,
          top: 300,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.6),
            ),
          ),
        ),
        Positioned(
          left: 80,
          top: 400,
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    // Dibujar franjas en el planeta
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.1, size.width * 0.3, size.height * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Dibujar órbitas concéntricas
    for (int i = 1; i <= 3; i++) {
      final radius = (size.width / 2) * (i / 3);
      canvas.drawCircle(center, radius, paint);
    }

    // Dibujar puntos en las órbitas
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * pi) / 8;
      final radius = size.width / 2 * 0.7;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Panel de menú
class _MenuPanel extends StatefulWidget {
  final VoidCallback onStartNormal;
  final VoidCallback onStartBigBoss;
  final VoidCallback onGoToShop;
  final VoidCallback onShowRecords;

  const _MenuPanel({
    required this.onStartNormal,
    required this.onStartBigBoss,
    required this.onGoToShop,
    required this.onShowRecords,
  });

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  int _selectedIndex = 0;

  final List<_MenuButtonData> _buttons = [];

  @override
  void initState() {
    super.initState();
    _buttons.addAll([
      _MenuButtonData(
        label: 'NIVEL NORMAL',
        icon: Icons.play_arrow,
        onTap: widget.onStartNormal,
        isHighlighted: true,
      ),
      _MenuButtonData(
        label: 'BIG BOSS',
        icon: Icons.warning,
        onTap: widget.onStartBigBoss,
        isHighlighted: false,
      ),
      _MenuButtonData(
        label: 'TIENDA',
        icon: Icons.shopping_cart,
        onTap: widget.onGoToShop,
        isHighlighted: false,
      ),
      _MenuButtonData(
        label: 'VER RECORDS',
        icon: Icons.emoji_events,
        onTap: widget.onShowRecords,
        isHighlighted: false,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 300,
      ),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1A1F3A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _buttons.length; i++)
            _MenuButton(
              data: _buttons[i],
              isSelected: _selectedIndex == i,
              onTap: () {
                setState(() {
                  _selectedIndex = i;
                });
                _buttons[i].onTap();
              },
            ),
        ],
      ),
    );
  }
}

class _MenuButtonData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isHighlighted;

  _MenuButtonData({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isHighlighted,
  });
}

class _MenuButton extends StatelessWidget {
  final _MenuButtonData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuButton({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
                    )
                  : null,
              color: isSelected ? null : Color(0xFF2D3748),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.orange
                    : Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Barra vertical de acento
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange
                        : Colors.blue.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                // Icono
                Icon(
                  data.icon,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                // Texto
                Expanded(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                // Puntos decorativos
                Row(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Container(
                        width: 4,
                        height: 4,
                        margin: EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Pantalla de Records
class RecordsScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const RecordsScreen({
    Key? key,
    required this.onBackToMenu,
  }) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('scores_puntuaje')
          .select('*')
          .order('score', ascending: false)
          .limit(5);

      print('Records cargados: ${response.length}');
      print('Datos: $response');

      setState(() {
        _records = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar records: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Hace 0 min';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        if (difference.inDays == 1) return 'Ayer';
        return 'Hace ${difference.inDays} días';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours} h';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes} min';
      } else {
        return 'Hace 0 min';
      }
    } catch (e) {
      print('Error al formatear fecha: $e - $dateString');
      return 'Hace 0 min';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Color(0xFFFFD700); // Oro
      case 2:
        return Color(0xFFC0C0C0); // Plata
      case 3:
        return Color(0xFFCD7F32); // Bronce
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Fondo con estrellas
              _SpaceBackground(),
              
              // Contenido
              Center(
                child: Container(
                  width: 500,
                  constraints: BoxConstraints(maxHeight: 600),
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1F3A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOP 5 RECORDS',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: widget.onBackToMenu,
                            ),
                          ],
                        ),
                      ),
                      
                      // Lista de records
                      Flexible(
                        child: _isLoading
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _records.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Text(
                                        'No hay records aún',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.all(16),
                                    shrinkWrap: true,
                                    itemCount: _records.length,
                                    itemBuilder: (context, index) {
                                      final record = _records[index];
                                      final rank = index + 1;
                                      final playerName = record['player_name']?.toString() ?? 'Anónimo';
                                      final score = record['score'] ?? 0;
                                      // Intentar obtener la fecha de diferentes campos posibles
                                      final createdAt = record['created_at']?.toString() ?? 
                                                       record['payment_date']?.toString() ?? 
                                                       record['fecha']?.toString() ??
                                                       DateTime.now().toIso8601String();
                                      
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 12),
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: rank <= 3
                                              ? _getRankColor(rank).withOpacity(0.2)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: rank <= 3
                                                ? _getRankColor(rank)
                                                : Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Número de ranking
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: rank <= 3
                                                    ? _getRankColor(rank)
                                                    : Color(0xFF1A1F3A),
                                              ),
                                              child: Center(
                                                child: rank <= 3
                                                    ? Text(
                                                        '$rank',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.circle,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                              ),
                                            ),
                                            SizedBox(width: 16),
                                            
                                            // Información del jugador
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    playerName.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1A1F3A),
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    _formatDate(createdAt),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Score
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF1A1F3A),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$score',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      
                      // Botón actualizar
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: TextButton.icon(
                          onPressed: _loadRecords,
                          icon: Icon(Icons.refresh, color: Color(0xFF1A1F3A)),
                          label: Text(
                            'Actualizar',
                            style: TextStyle(
                              color: Color(0xFF1A1F3A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}