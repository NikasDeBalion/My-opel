import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TelematicsPage extends StatefulWidget {
  @override
  _TelematicsPageState createState() => _TelematicsPageState();
}

class _TelematicsPageState extends State<TelematicsPage> {
  Map<String, dynamic>? latestTelematicsData;
  TextEditingController deviceIdController = TextEditingController();
  TextEditingController tokenController = TextEditingController();
  Timer? _timer;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (deviceIdController.text.isNotEmpty) {
        fetchTelematicsData();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    deviceIdController.dispose();
    tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('flespi_token');
    if (token != null) {
      tokenController.text = token; // Загружаем токен при запуске
    }
  }

  Future<void> _saveToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('flespi_token', tokenController.text); // Сохраняем токен
  }

  Future<void> fetchTelematicsData() async {
    final deviceId = deviceIdController.text.trim();
    final token = tokenController.text.trim(); // Получаем токен из поля ввода

    if (deviceId.isEmpty || token.isEmpty) {
      setState(() {
        errorMessage = 'Please enter both device ID and token';
      });
      return;
    }

    final url = 'https://flespi.io/gw/devices/$deviceId/messages?limit=1';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'FlespiToken $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = data['result'];

        if (result.isNotEmpty) {
          setState(() {
            latestTelematicsData = result[0]; // Получаем последние данные
            errorMessage = null;
          });
        } else {
          setState(() {
            errorMessage = 'No data available';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Telematics Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: tokenController,
              decoration: InputDecoration(
                labelText: 'Enter Flespi Token',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _saveToken(); // Сохраняем токен при изменении
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: deviceIdController,
              decoration: InputDecoration(
                labelText: 'Enter Device ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                fetchTelematicsData();
              },
              child: Text('Update Data'),
            ),
            SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            latestTelematicsData == null
                ? Text('No data to display')
                : Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Количество столбцов
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.5, // Соотношение сторон карточек
                      ),
                      itemCount: latestTelematicsData!.length,
                      itemBuilder: (context, index) {
                        String key = latestTelematicsData!.keys.elementAt(index);
                        var value = latestTelematicsData![key];

                        return Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  key.replaceAll('.', ' ').capitalizeFirst,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  value.toString(),
                                  style: TextStyle(fontSize: 24),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String get capitalizeFirst {
    return this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : this;
  }
}

void main() {
  runApp(MaterialApp(
    home: TelematicsPage(),
  ));
}
