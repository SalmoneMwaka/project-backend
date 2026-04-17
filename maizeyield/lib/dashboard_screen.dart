import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'result_screen.dart';
import 'landing_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Dropdown options
  final List<String> soilTypes = ['Clay', 'Loam', 'Peat', 'Sandy', 'Silt'];
  final List<String> pHLevels = ['4.5', '5.0', '5.5', '6.0', '6.5', '7.0'];
  final List<String> seedVarieties = [
    'Drought-Resistant',
    'Early-Maturing',
    'Hybrid A',
    'Hybrid B',
    'Open-Pollinated'
  ];
  final List<String> plantingDates = ['March', 'April', 'May'];
  final List<String> fertilizerTypes = ['Compost', 'DAP', 'NPK', 'Organic', 'Urea'];

  // Controllers
  final TextEditingController rainfallController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController humidityController = TextEditingController();

  // Selected values
  String? selectedSoilType;
  String? selectedPH;
  String? selectedSeedVariety;
  String? selectedPlantingDate;
  String? selectedFertilizerType;
  bool isLoading = false;

  Future<void> predictYield() async {
    if (selectedSoilType == null ||
        selectedPH == null ||
        selectedSeedVariety == null ||
        selectedPlantingDate == null ||
        selectedFertilizerType == null ||
        rainfallController.text.isEmpty ||
        temperatureController.text.isEmpty ||
        humidityController.text.isEmpty) {
      showErrorDialog("Please fill in all fields before predicting.");
      return;
    }

    double? pH, rainfall, temperature, humidity;
    try {
      pH = double.parse(selectedPH!);
      rainfall = double.parse(rainfallController.text);
      temperature = double.parse(temperatureController.text);
      humidity = double.parse(humidityController.text);
    } catch (e) {
      showErrorDialog("Invalid number format in fields.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.103.121:8000/predict/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Soil_Type": selectedSoilType,
          "pH": pH,
          "Seed_Variety": selectedSeedVariety,
          "Rainfall_mm": rainfall,
          "Temperature_C": temperature,
          "Humidity_percent": humidity, // <-- change here
          "Planting_Date": selectedPlantingDate,
          "Fertilizer_Type": selectedFertilizerType
        }),
        
      );
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(result: jsonDecode(response.body)),
          ),
        );
      } else {
        showErrorDialog("Server error: ${response.statusCode}");
      }
    } catch (e) {
      showErrorDialog("Connection error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MaizeMate Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Prediction Data:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              buildDropdown('Soil Type', soilTypes, selectedSoilType, (val) {
                setState(() => selectedSoilType = val);
              }),
              buildDropdown('pH Level', pHLevels, selectedPH, (val) {
                setState(() => selectedPH = val);
              }),
              buildDropdown('Seed Variety', seedVarieties, selectedSeedVariety, (val) {
                setState(() => selectedSeedVariety = val);
              }),
              buildDropdown('Planting Date', plantingDates, selectedPlantingDate, (val) {
                setState(() => selectedPlantingDate = val);
              }),
              buildDropdown('Fertilizer Type', fertilizerTypes, selectedFertilizerType, (val) {
                setState(() => selectedFertilizerType = val);
              }),
              buildTextField('Rainfall (mm)', rainfallController),
              buildTextField('Temperature (°C)', temperatureController),
              buildTextField('Humidity (%)', humidityController),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : predictYield,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('PREDICT YIELD', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    rainfallController.dispose();
    temperatureController.dispose();
    humidityController.dispose();
    super.dispose();
  }
}