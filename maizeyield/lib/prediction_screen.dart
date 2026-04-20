import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'prediction_result_screen.dart'; // import the result screen

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController farmSizeController = TextEditingController();
  final TextEditingController rainfallController = TextEditingController();
  final TextEditingController tempController = TextEditingController();

  String soilType = 'Loamy';

  bool _loading = false;

  // Your API URL (use local or Render URL)
  final String apiUrl = "http://192.168.0.100:8000/predict/";

  Future<void> _predictYield() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Soil_Type": soilType,
          "pH": 6.5,
          "Seed_Variety": "H614",
          "Rainfall_mm": double.tryParse(rainfallController.text) ?? 0,
          "Temperature_C": double.tryParse(tempController.text) ?? 0,
          "Humidity_percent": 60,
          "Planting_Date": "2026-03-10",
          "Fertilizer_Type": "DAP",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionResultScreen(
              predictedYield: data['predicted_yield'],
              confidenceRange: data['confidence_range'],
              category: data['category'],
              recommendation: data['recommendation'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching prediction')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maize Yield Prediction'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      backgroundColor: const Color(0xFFE8F5E9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: soilType,
                items: ['Loamy', 'Sandy', 'Clay', 'Silty']
                    .map((soil) => DropdownMenuItem(
                          value: soil,
                          child: Text(soil),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => soilType = value!),
                decoration: const InputDecoration(
                  labelText: 'Soil Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: farmSizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Farm Size (acres)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter farm size' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: rainfallController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rainfall (mm)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter rainfall' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tempController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter temperature' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _predictYield,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PREDICT YIELD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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