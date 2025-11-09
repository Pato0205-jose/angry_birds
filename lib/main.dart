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
  bool _showShop = true;

  void _startGame(LevelType levelType) {
    setState(() {
      _showShop = false;
      _game = MyPhysicsGame(
        shopManager: _shopManager,
        levelType: levelType,
      );
    });
  }

  void _returnToShop() {
    // Resetear items comprados para el siguiente turno
    _shopManager.resetItemsForNewTurn();
    setState(() {
      _showShop = true;
      _game = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showShop) {
      return ShopScreen(
        shopManager: _shopManager,
        onStartGame: _startGame,
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
                    onReturnToShop: _returnToShop,
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
                  
                  // Volver a Tienda
                  if (widget.onReturnToShop != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                  widget.game.overlays.remove('dialog');
                          widget.onReturnToShop!();
                        },
                        icon: Icon(Icons.shopping_cart),
                        label: Text('Volver a Tienda'),
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