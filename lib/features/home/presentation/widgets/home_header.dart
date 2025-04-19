import 'package:flutter/material.dart';
import 'package:chanchi_app/core/config/theme.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;

  const HomeHeader({
    Key? key,
    required this.userName,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hola, $userName',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.primaryColor),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
