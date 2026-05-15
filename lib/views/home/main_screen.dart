import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../farm_finance/farm_finance_screen.dart';
import '../ai/ai_screen.dart';
import '../crop_advisory/crop_advisory_screen.dart';
import '../mandi_price/mandi_price_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FarmFinanceScreen(),
    const AiScreen(),
    const CropAdvisoryScreen(),
    const MandiPriceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F3D89), // Dark purple/blue
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6uR4K8yR2V7N1_vS3Lh_V3R3vB8V_vR8V_A&s', // Placeholder logo
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.agriculture, color: Colors.white),
          ),
        ),
        title: const Text(
          'GramIQ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Home'),
              _buildNavItem(1, Icons.account_balance_wallet, 'Farm Finance'),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(3, Icons.grass, 'Crop Advisory'),
              _buildNavItem(4, Icons.storefront, 'Mandi Price'),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        backgroundColor: const Color(0xFF3F3D89),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF3F3D89) : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFF3F3D89) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
