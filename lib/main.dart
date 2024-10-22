import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'db_helper.dart'; // Import your SQLite helper

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AquariumScreen(),
    );
  }
}

class Fish {
  Color color;
  double speed;
  Offset position;
  Offset direction;

  Fish({
    required this.color,
    required this.speed,
    required this.position,
    required this.direction,
  });
}

class AquariumScreen extends StatefulWidget {
  const AquariumScreen({super.key});

  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  List<Fish> fishes = [];
  Timer? _timer;
  Color _selectedColor = Colors.blue;
  double _selectedSpeed = 2.0;
  Color _selectedAddColor = Colors.red;
  Color _selectedRemoveColor = Colors.red;

  final List<Color> availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.brown,
    Colors.cyan,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Load settings from SQLite
  Future<void> _loadSavedSettings() async {
    List<Map<String, dynamic>> savedFishes =
        await DatabaseHelper.instance.loadFishes();
    setState(() {
      fishes = savedFishes.map((fish) {
        Color color = Color(int.parse(fish['color']));
        return Fish(
          color: color,
          speed: fish['speed'],
          position:
              Offset(Random().nextDouble() * 300, Random().nextDouble() * 300),
          direction:
              Offset(Random().nextDouble() - 0.5, Random().nextDouble() - 0.5),
        );
      }).toList();
    });
  }

  // Save settings to SQLite
  Future<void> _saveSettings() async {
    if (fishes.isEmpty) {
      _showErrorDialog('No Fish to Save', 'You must add fish before saving.');
      return;
    }

    List<Map<String, dynamic>> fishData = fishes.map((fish) {
      return {
        'color': fish.color.value.toString(),
        'speed': fish.speed,
      };
    }).toList();
    await DatabaseHelper.instance.saveFish(fishData);
  }

  // Create a new Fish
  Fish _createFish(Color color) {
    final random = Random();
    return Fish(
      color: color,
      speed: _selectedSpeed,
      position: Offset(random.nextDouble() * 300, random.nextDouble() * 300),
      direction: Offset(random.nextDouble() - 0.5, random.nextDouble() - 0.5),
    );
  }

  // Add new fish with error handling
  void _addFish() {
    if (fishes.length >= 10) {
      _showErrorDialog('Fish Limit Reached', 'Cannot add more than 10 fish.');
    } else {
      setState(() {
        fishes.add(_createFish(_selectedAddColor));
      });
    }
  }

  // Remove fish by color with error handling
  void _removeFish() {
    int removedFishCount =
        fishes.where((fish) => fish.color == _selectedRemoveColor).length;

    if (removedFishCount == 0) {
      _showErrorDialog(
          'No Fish to Remove', 'There are no fish of this color to remove.');
    } else {
      setState(() {
        fishes.removeWhere((fish) => fish.color == _selectedRemoveColor);
      });
      // Remove from database
      DatabaseHelper.instance
          .removeFishByColor(_selectedRemoveColor.value.toString());
    }
  }

  // Start fish animation
  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        for (var fish in fishes) {
          fish.position += fish.direction * fish.speed;
          if (fish.position.dx <= 0 || fish.position.dx >= 300) {
            fish.direction = Offset(-fish.direction.dx, fish.direction.dy);
          }
          if (fish.position.dy <= 0 || fish.position.dy >= 300) {
            fish.direction = Offset(fish.direction.dx, -fish.direction.dy);
          }
        }
      });
    });
  }

  // Show error dialogs
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // UI Elements for fish control
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Aquarium'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Aquarium with background gradient
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent, Colors.blue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: fishes.map((fish) {
                return Positioned(
                  left: fish.position.dx,
                  top: fish.position.dy,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: fish.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Speed Control Section
          _buildSpeedControlSection(),

          // Add Fish Section with a polished button
          _buildAddFishSection(),

          // Remove Fish Section with polished button
          _buildRemoveFishSection(),

          // Save Settings Button
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              foregroundColor: Color.fromARGB(255, 246, 244, 244),
              backgroundColor: Colors.teal, // Polished button color
              textStyle: TextStyle(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startAnimation,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  // Speed control UI
  Widget _buildSpeedControlSection() {
    return Column(
      children: [
        DropdownButton<Color>(
          value: _selectedColor,
          items: availableColors.map((color) {
            return DropdownMenuItem(
              value: color,
              child: Container(
                width: 24,
                height: 24,
                color: color,
              ),
            );
          }).toList(),
          onChanged: (newColor) {
            setState(() {
              _selectedColor = newColor!;
            });
          },
        ),
        Slider(
          value: _selectedSpeed,
          min: 1.0,
          max: 5.0,
          divisions: 4,
          label: _selectedSpeed.toString(),
          activeColor: _selectedColor,
          onChanged: (value) {
            setState(() {
              _selectedSpeed = value;
              for (var fish
                  in fishes.where((fish) => fish.color == _selectedColor)) {
                fish.speed = _selectedSpeed;
              }
            });
          },
        ),
        const Text('Adjust Speed'),
      ],
    );
  }

  // Add Fish UI
  Widget _buildAddFishSection() {
    return Column(
      children: [
        DropdownButton<Color>(
          value: _selectedAddColor,
          items: availableColors.map((color) {
            return DropdownMenuItem(
              value: color,
              child: Container(
                width: 24,
                height: 24,
                color: color,
              ),
            );
          }).toList(),
          onChanged: (newColor) {
            setState(() {
              _selectedAddColor = newColor!;
            });
          },
        ),
        ElevatedButton(
          onPressed: _addFish,
          style: ElevatedButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 246, 244, 244),
            backgroundColor: Colors.teal,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('Add Fish'),
        ),
      ],
    );
  }

  // Remove Fish UI
  Widget _buildRemoveFishSection() {
    return Column(
      children: [
        DropdownButton<Color>(
          value: _selectedRemoveColor,
          items: availableColors.map((color) {
            return DropdownMenuItem(
              value: color,
              child: Container(
                width: 24,
                height: 24,
                color: color,
              ),
            );
          }).toList(),
          onChanged: (newColor) {
            setState(() {
              _selectedRemoveColor = newColor!;
            });
          },
        ),
        ElevatedButton(
          onPressed: _removeFish,
          style: ElevatedButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 246, 244, 244),
            backgroundColor: Colors.redAccent,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text(
              selectionColor: Color.fromARGB(255, 246, 244, 244),
              'Remove Fish'),
        ),
      ],
    );
  }
}
