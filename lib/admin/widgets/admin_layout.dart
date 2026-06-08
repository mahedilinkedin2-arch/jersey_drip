import 'package:flutter/material.dart';

class AdminLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final int index;
  final Function(int) onTap;

  const AdminLayout({
    super.key,
    required this.body,
    required this.title,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin - $title"),
        backgroundColor: Colors.indigo,
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: onTap,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text("Dashboard"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory),
                  label: Text("Products"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list),
                  label: Text("Orders"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.view_list),
                  label: Text("Inventory"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text("Users"),
                ),
              ],
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: !wide
          ? BottomNavigationBar(
              currentIndex: index,
              onTap: onTap,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: "Products",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: "Orders",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.view_list),
                  label: "Inventory",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: "Users",
                ),
              ],
            )
          : null,
    );
  }
}
