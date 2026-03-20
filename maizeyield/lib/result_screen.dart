import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  void shareResult(BuildContext context) {
    final summary = StringBuffer();
    summary.writeln("🌽 MaizeMate Prediction Results:");
    summary.writeln("Predicted Yield: ${result["predicted_yield"]} bags per acre");
    summary.writeln("Confidence Range: ${result["confidence_range"]}");
    summary.writeln("Category: ${result["category"]}");
    summary.writeln("Recommendation: ${result["recommendation"]}");

    // result["input_summary"].forEach((key, value) {
    //   summary.writeln("$key: $value");
    // });

    Share.share(summary.toString(), subject: 'MaizeMate Prediction');
  }

  void printResult() {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("🌽 MaizeMate Prediction", style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 10),
              pw.Text("Predicted Yield: ${result["predicted_yield"]} bags per acre"),
              pw.Text("Confidence Range: ${result["confidence_range"]}"),
              pw.Text("Category: ${result["category"]}"),
              pw.Text("Recommendation: ${result["recommendation"]}"),
              pw.SizedBox(height: 10),
              pw.Text("🔍 Input Summary:"),
              ...result["input_summary"].entries.map((entry) => pw.Text("${entry.key}: ${entry.value}"))
            ],
          );
        },
      ),
    );

    Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Result'),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: printResult,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => shareResult(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCard(Icons.agriculture, "Predicted Yield", "${result["predicted_yield"]} bags per acre"),
            buildCard(Icons.trending_up, "Confidence Range", result["confidence_range"]),
            buildCard(
              result["category"] == "High Yield"
                  ? Icons.emoji_events
                  : result["category"] == "Moderate Yield"
                  ? Icons.insights
                  : Icons.warning,
              "Category",
              result["category"],
            ),
            buildCard(Icons.lightbulb, "Recommendation", result["recommendation"]),
            const SizedBox(height: 20),
            const Text("🔍 Input Data Summary:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            //buildInputSummary(result["input_summary"]),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('🔙 Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard(IconData icon, String title, String value) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  Widget buildInputSummary(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: summary.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text("${entry.key}: ${entry.value}", style: const TextStyle(fontSize: 16)),
            );
          }).toList(),
        ),
      ),
    );
  }
}