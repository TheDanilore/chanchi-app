// Widget animado para mostrar el balance total con efecto de contador
import 'package:flutter/material.dart';

class AnimatedBalanceWidget extends StatefulWidget {
  final double balance;
  final TextStyle style;
  final String currencySymbol;
  
  const AnimatedBalanceWidget({
    Key? key, 
    required this.balance, 
    required this.style,
    this.currencySymbol = 'S/',
  }) : super(key: key);

  @override
  _AnimatedBalanceWidgetState createState() => _AnimatedBalanceWidgetState();
}

class _AnimatedBalanceWidgetState extends State<AnimatedBalanceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _oldBalance;
  late double _newBalance;
  
  @override
  void initState() {
    super.initState();
    _oldBalance = 0;
    _newBalance = widget.balance;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: _oldBalance, end: _newBalance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
    );
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(AnimatedBalanceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance != widget.balance) {
      _oldBalance = oldWidget.balance;
      _newBalance = widget.balance;
      _animation = Tween<double>(begin: _oldBalance, end: _newBalance).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
      );
      _controller.reset();
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.currencySymbol} ${_formatCurrency(_animation.value)}',
          style: widget.style,
        );
      },
    );
  }
  
  String _formatCurrency(double value) {
    // Formatear a 2 decimales y agregar separador de miles
    String priceString = value.toStringAsFixed(2);
    final parts = priceString.split('.');
    final whole = parts[0];
    final decimal = parts.length > 1 ? parts[1] : '00';
    
    // Agregar separador de miles
    final buffer = StringBuffer();
    for (int i = whole.length - 1; i >= 0; i--) {
      buffer.write(whole[i]);
      if (i > 0 && (whole.length - i) % 3 == 0) {
        buffer.write(',');
      }
    }
    
    return '${buffer.toString().split('').reversed.join('')}.$decimal';
  }
}