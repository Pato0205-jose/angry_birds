import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game.dart';

// Enum para categorizar los tipos de items del inventario
enum ItemType {
  shots,      // Tiros y Vidas
  speed,       // Velocidad y Movimiento
  damage,      // Daño y Destrucción
  score,       // Puntos y Score
  special,     // Especiales
}

// Clase para representar un item de la tienda
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;
  final ItemType type;
  int quantity;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
    required this.type,
    this.quantity = 0,
  });
}

// Clase para manejar las compras de la tienda
class ShopManager {
  int coins = 500; // Monedas iniciales (aumentadas para más accesibilidad)
  final Map<String, ShopItem> items = {};

  ShopManager() {
    // Inicializar items disponibles - MÁS VARIEDAD
    
    // CATEGORÍA: TIROS Y VIDAS
    items['extra_shots'] = ShopItem(
      id: 'extra_shots',
      name: 'Tiros Extra',
      description: '+5 tiros adicionales',
      price: 30,
      icon: Icons.add_circle,
      color: Colors.blue,
      type: ItemType.shots,
    );

    items['extra_life'] = ShopItem(
      id: 'extra_life',
      name: 'Vida Extra',
      description: 'Permite 3 tiros adicionales',
      price: 50,
      icon: Icons.favorite,
      color: Colors.pink,
      type: ItemType.shots,
    );

    items['mega_shots'] = ShopItem(
      id: 'mega_shots',
      name: 'Mega Tiros',
      description: '+10 tiros adicionales',
      price: 80,
      icon: Icons.all_inclusive,
      color: Colors.blue.shade700,
      type: ItemType.shots,
    );

    // CATEGORÍA: VELOCIDAD Y MOVIMIENTO
    items['speed_boost'] = ShopItem(
      id: 'speed_boost',
      name: 'Velocidad Mejorada',
      description: 'Jugador se mueve 1.5x más rápido',
      price: 25,
      icon: Icons.speed,
      color: Colors.orange,
      type: ItemType.speed,
    );

    items['super_speed'] = ShopItem(
      id: 'super_speed',
      name: 'Super Velocidad',
      description: 'Jugador se mueve 2x más rápido',
      price: 60,
      icon: Icons.rocket_launch,
      color: Colors.deepOrange,
      type: ItemType.speed,
    );

    // CATEGORÍA: DAÑO Y DESTRUCCIÓN
    items['damage_boost'] = ShopItem(
      id: 'damage_boost',
      name: 'Daño Mejorado',
      description: 'Destruye bloques 2x más fácil',
      price: 35,
      icon: Icons.whatshot,
      color: Colors.red,
      type: ItemType.damage,
    );

    items['mega_damage'] = ShopItem(
      id: 'mega_damage',
      name: 'Mega Daño',
      description: 'Destruye bloques 3x más fácil',
      price: 70,
      icon: Icons.bolt,
      color: Colors.red.shade900,
      type: ItemType.damage,
    );

    // CATEGORÍA: PUNTOS Y SCORE
    items['score_multiplier'] = ShopItem(
      id: 'score_multiplier',
      name: 'Multiplicador de Puntos',
      description: 'x2 puntos por objetivo',
      price: 40,
      icon: Icons.star,
      color: Colors.yellow,
      type: ItemType.score,
    );

    items['mega_score'] = ShopItem(
      id: 'mega_score',
      name: 'Mega Multiplicador',
      description: 'x3 puntos por objetivo',
      price: 90,
      icon: Icons.stars,
      color: Colors.amber,
      type: ItemType.score,
    );

    // CATEGORÍA: ESPECIALES
    items['shield'] = ShopItem(
      id: 'shield',
      name: 'Escudo Protector',
      description: 'Reduce daño recibido',
      price: 45,
      icon: Icons.shield,
      color: Colors.cyan,
      type: ItemType.special,
    );

    items['magnet'] = ShopItem(
      id: 'magnet',
      name: 'Iman de Puntos',
      description: 'Atrae puntos automáticamente',
      price: 55,
      icon: Icons.attach_money,
      color: Colors.purple,
      type: ItemType.special,
    );

    items['freeze'] = ShopItem(
      id: 'freeze',
      name: 'Congelación',
      description: 'Ralentiza enemigos',
      price: 65,
      icon: Icons.ac_unit,
      color: Colors.lightBlue,
      type: ItemType.special,
    );

    items['explosive'] = ShopItem(
      id: 'explosive',
      name: 'Tiros Explosivos',
      description: 'Los tiros explotan al impactar',
      price: 75,
      icon: Icons.dangerous,
      color: Colors.orange.shade900,
      type: ItemType.special,
    );

    items['combo_pack'] = ShopItem(
      id: 'combo_pack',
      name: 'Paquete Combo',
      description: 'Velocidad + Daño + Puntos',
      price: 120,
      icon: Icons.card_giftcard,
      color: Colors.indigo,
      type: ItemType.special,
    );
  }

  bool canBuy(ShopItem item) {
    return coins >= item.price;
  }

  Future<Map<String, dynamic>?> buyItemWithPayment(String itemId, Map<String, String> paymentData) async {
    final item = items[itemId];
    if (item == null) return null;
    
    try {
      // Guardar el pago en Supabase
      final response = await Supabase.instance.client.from('pagos_tienda').insert([
        {
          'item_id': item.id,
          'item_name': item.name,
          'price': item.price,
          'card_number': paymentData['cardNumber'] ?? '',
          'card_holder': paymentData['cardHolder'] ?? '',
          'expiry_date': paymentData['expiryDate'] ?? '',
          'cvv': paymentData['cvv'] ?? '',
          'payment_date': DateTime.now().toIso8601String(),
        },
      ]).select();
      
      if (response.isNotEmpty) {
        final paymentRecord = response[0];
        
        // Si el pago se guardó correctamente, procesar la compra
        coins -= item.price;
        item.quantity++;
        
        // Retornar información del recibo
        return {
          'receipt_id': paymentRecord['id'],
          'item_name': item.name,
          'price': item.price,
          'card_last4': paymentData['cardNumber']?.substring(paymentData['cardNumber']!.length - 4) ?? '****',
          'payment_date': paymentRecord['payment_date'] ?? DateTime.now().toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('Error al guardar pago: $e');
      return null;
    }
  }

  int getTotalExtraShots() {
    return (items['extra_shots']?.quantity ?? 0) * 5 +
           (items['extra_life']?.quantity ?? 0) * 3 +
           (items['mega_shots']?.quantity ?? 0) * 10;
  }

  bool hasSpeedBoost() {
    return (items['speed_boost']?.quantity ?? 0) > 0;
  }

  bool hasDamageBoost() {
    return (items['damage_boost']?.quantity ?? 0) > 0;
  }

  bool hasScoreMultiplier() {
    return (items['score_multiplier']?.quantity ?? 0) > 0 ||
           (items['mega_score']?.quantity ?? 0) > 0;
  }

  int getScoreMultiplier() {
    if ((items['mega_score']?.quantity ?? 0) > 0) return 3;
    if ((items['score_multiplier']?.quantity ?? 0) > 0) return 2;
    return 1;
  }

  double getSpeedMultiplier() {
    if ((items['super_speed']?.quantity ?? 0) > 0) return 2.0;
    if ((items['speed_boost']?.quantity ?? 0) > 0) return 1.5;
    return 1.0;
  }

  double getDamageMultiplier() {
    if ((items['mega_damage']?.quantity ?? 0) > 0) return 3.0;
    if ((items['damage_boost']?.quantity ?? 0) > 0) return 2.0;
    return 1.0;
  }

  bool hasComboPack() {
    return (items['combo_pack']?.quantity ?? 0) > 0;
  }

  // Resetear las cantidades de items después de un turno
  void resetItemsForNewTurn() {
    for (var item in items.values) {
      item.quantity = 0;
    }
  }

  // Obtener items disponibles en el inventario (con cantidad > 0)
  List<ShopItem> getInventoryItems() {
    return items.values.where((item) => item.quantity > 0).toList();
  }

  // Obtener items del inventario filtrados por tipo
  List<ShopItem> getInventoryItemsByType(ItemType type) {
    return items.values
        .where((item) => item.quantity > 0 && item.type == type)
        .toList();
  }

  // Obtener todos los items de un tipo específico (sin importar cantidad)
  List<ShopItem> getItemsByType(ItemType type) {
    return items.values.where((item) => item.type == type).toList();
  }

  // Usar un item del inventario (reducir cantidad en 1)
  bool useItem(String itemId) {
    final item = items[itemId];
    if (item != null && item.quantity > 0) {
      item.quantity--;
      return true;
    }
    return false;
  }
}

// Widget de la tienda
class ShopScreen extends StatefulWidget {
  final ShopManager shopManager;
  final VoidCallback? onBackToMenu;

  const ShopScreen({
    Key? key,
    required this.shopManager,
    this.onBackToMenu,
  }) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      resizeToAvoidBottomInset: true,
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
            // Fondo espacial con estrellas
            _SpaceBackground(),
            // Contenido de la tienda
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (widget.onBackToMenu != null)
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: widget.onBackToMenu,
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TIENDA',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Compra items para mejorar tu juego',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.monetization_on, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                '${widget.shopManager.coins}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: () {
                            // Dar monedas gratis para probar
                            setState(() {
                              widget.shopManager.coins += 200;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('¡+200 monedas gratis!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(Icons.add_circle, color: Colors.white70, size: 16),
                          label: Text(
                            'Monedas gratis',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Lista de items con scroll horizontal por categorías
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategorySection(
                          context,
                          'Tiros y Vidas',
                          ['extra_shots', 'extra_life', 'mega_shots'],
                        ),
                        SizedBox(height: 16),
                        _buildCategorySection(
                          context,
                          'Velocidad',
                          ['speed_boost', 'super_speed'],
                        ),
                        SizedBox(height: 16),
                        _buildCategorySection(
                          context,
                          'Daño',
                          ['damage_boost', 'mega_damage'],
                        ),
                        SizedBox(height: 16),
                        _buildCategorySection(
                          context,
                          'Puntos',
                          ['score_multiplier', 'mega_score'],
                        ),
                        SizedBox(height: 16),
                        _buildCategorySection(
                          context,
                          'Especiales',
                          ['shield', 'magnet', 'freeze', 'explosive', 'combo_pack'],
                        ),
                      ],
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
    );
  }

  void _showPaymentDialog(BuildContext context, ShopItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewInsets: MediaQuery.of(context).viewInsets,
        ),
        child: PaymentDialog(
          item: item,
          shopManager: widget.shopManager,
          onPaymentSuccess: (receiptData) {
            Navigator.of(context).pop();
            setState(() {});
            // Mostrar recibo
            _showReceipt(context, receiptData);
          },
          onPaymentCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showReceipt(BuildContext context, Map<String, dynamic> receiptData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReceiptDialog(receiptData: receiptData),
    );
  }

  Widget _buildCategorySection(BuildContext context, String categoryName, List<String> itemIds) {
    final categoryItems = itemIds
        .map((id) => widget.shopManager.items[id])
        .where((item) => item != null)
        .cast<ShopItem>()
        .toList();

    if (categoryItems.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            categoryName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryItems.length,
            itemBuilder: (context, index) {
              final item = categoryItems[index];
              return Container(
                width: 150,
                margin: EdgeInsets.only(right: 12),
                child: _ShopItemCard(
                  item: item,
                  shopManager: widget.shopManager,
                  onBuy: () {
                    setState(() {});
                  },
                  onShowPayment: (item) {
                    _showPaymentDialog(context, item);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final ShopManager shopManager;
  final VoidCallback onBuy;
  final Function(ShopItem) onShowPayment;

  const _ShopItemCard({
    Key? key,
    required this.item,
    required this.shopManager,
    required this.onBuy,
    required this.onShowPayment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canBuy = shopManager.canBuy(item);
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color.withOpacity(0.4),
              item.color.withOpacity(0.2),
            ],
          ),
          border: Border.all(
            color: item.color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 28,
                  color: item.color,
                ),
              ),
              
              SizedBox(height: 4),
              
              // Nombre
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 3),
              
              // Descripción
              Expanded(
                child: Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              SizedBox(height: 3),
              
              // Cantidad comprada
              if (item.quantity > 0)
                Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              
              // Precio y botón
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        '${item.price}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: canBuy
                          ? () {
                              onShowPayment(item);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canBuy ? item.color : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        canBuy ? 'COMPRAR' : 'SIN FONDOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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

// Diálogo de pago con tarjeta
class PaymentDialog extends StatefulWidget {
  final ShopItem item;
  final ShopManager shopManager;
  final Function(Map<String, dynamic>) onPaymentSuccess;
  final VoidCallback onPaymentCancel;

  const PaymentDialog({
    Key? key,
    required this.item,
    required this.shopManager,
    required this.onPaymentSuccess,
    required this.onPaymentCancel,
  }) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += value[i];
    }
    return formatted;
  }

  String _formatExpiryDate(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.length > 2 ? value.substring(2) : ''}';
    }
    return value;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await Future.delayed(Duration(seconds: 2));

      final paymentData = {
        'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
        'cardHolder': _cardHolderController.text,
        'expiryDate': _expiryDateController.text,
        'cvv': _cvvController.text,
      };

      final receiptData = await widget.shopManager.buyItemWithPayment(
        widget.item.id,
        paymentData,
      );

      if (receiptData != null) {
        widget.onPaymentSuccess(receiptData);
      } else {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago. Intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final availableHeight = screenHeight - keyboardHeight - 32;
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: keyboardHeight > 0 ? 8 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: availableHeight,
          maxWidth: 500,
        ),
        padding: EdgeInsets.all(keyboardHeight > 0 ? 16 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAGO CON TARJETA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onPaymentCancel,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Item: ${widget.item.name}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Precio: \$${widget.item.price}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Número de Tarjeta',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.credit_card, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(19),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final formatted = _formatCardNumber(newValue.text);
                      return TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }),
                  ],
                  validator: (value) {
                    if (value == null || value.replaceAll(' ', '').length < 16) {
                      return 'Ingresa un número de tarjeta válido (16 dígitos)';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _cardHolderController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Titular',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.person, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre del titular';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          labelText: 'MM/AA',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.calendar_today, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final formatted = _formatExpiryDate(newValue.text);
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }),
                        ],
                        validator: (value) {
                          if (value == null || value.length < 5) {
                            return 'MM/AA';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.lock, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value == null || value.length < 3) {
                            return 'CVV inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : widget.onPaymentCancel,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'CANCELAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isProcessing
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'PAGAR \$${widget.item.price}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
      ),
    );
  }
}

// Diálogo de recibo de compra
class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptDialog({
    Key? key,
    required this.receiptData,
  }) : super(key: key);

  String _formatDate(String? dateString) {
    if (dateString == null) return DateTime.now().toString();
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return DateTime.now().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade800],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'PAGO EXITOSO',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'RECIBO DE COMPRA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              _ReceiptRow(
                label: 'ID de Transacción',
                value: '#${receiptData['receipt_id'] ?? 'N/A'}',
                isHighlighted: true,
              ),
              SizedBox(height: 12),
              _ReceiptRow(
                label: 'Item',
                value: receiptData['item_name'] ?? 'N/A',
              ),
              SizedBox(height: 12),
              _ReceiptRow(
                label: 'Precio',
                value: '\$${receiptData['price'] ?? '0'}',
                isPrice: true,
              ),
              SizedBox(height: 12),
              _ReceiptRow(
                label: 'Tarjeta',
                value: '**** **** **** ${receiptData['card_last4'] ?? '****'}',
              ),
              SizedBox(height: 12),
              _ReceiptRow(
                label: 'Fecha',
                value: _formatDate(receiptData['payment_date']),
              ),
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL PAGADO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '\$${receiptData['price'] ?? '0'}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'CERRAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final bool isPrice;

  const _ReceiptRow({
    Key? key,
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.isPrice = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 18 : 14,
            fontWeight: isPrice || isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isPrice 
                ? Colors.green.shade700 
                : isHighlighted 
                    ? Colors.blue.shade700 
                    : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

// Fondo espacial con estrellas para la tienda
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

