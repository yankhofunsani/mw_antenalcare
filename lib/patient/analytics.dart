import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  _AnalyticsState createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  bool _isLoading = true;
  String? regNumber;
  List<Map<String, dynamic>> recentRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentRecords();
  }

  Future<void> _fetchRecentRecords() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final emailAddress = currentUser.email;
    if (emailAddress != null) {
      // Get registration number
      final patientSnap = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: emailAddress)
          .limit(1)
          .get();

      if (patientSnap.docs.isNotEmpty) {
        regNumber = patientSnap.docs.first.data()['registration_number'];

        if (regNumber != null) {
          // 2-3 latest session_data records
          final recordsSnap = await FirebaseFirestore.instance
              .collection('session_data')
              .where('registration_number', isEqualTo: regNumber)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .get();

          final data = recordsSnap.docs.map((doc) {
            final visit = doc.data()['visit'] ?? {};

            // date parsing
            dynamic rawDate = visit['visit_date'];
            DateTime? visitDate;
            if (rawDate is Timestamp) {
              visitDate = rawDate.toDate();
            } else if (rawDate is String) {
              visitDate = DateTime.tryParse(rawDate);
            }

            //  numeric parsing
            final fundalHeight =
                double.tryParse(visit['fundal_height']?.toString() ?? '0') ?? 0;
            final gestAge =
                double.tryParse(visit['gest_age']?.toString() ?? '0') ?? 0;
            final weight =
                double.tryParse(visit['weight']?.toString() ?? '0') ?? 0;

            return {
              'visit_date': visitDate,
              'fundal_height': fundalHeight,
              'gest_age': gestAge,
              'remarks': visit['remarks'] ?? 'N/A',
              'position_presentation': visit['position_presentation'] ?? 'N/A',
              'bp': visit['bp'] ?? 'N/A',
              'weight': weight,
            };
          }).toList();

          setState(() {
            recentRecords = data;
          });
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("My pregnancy trends "), backgroundColor: Colors.grey.shade100,
          leading: const Icon(Icons.analytics, color: Colors.black),
             ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentRecords.isEmpty
              ? const Center(child: Text("No recent records found."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTable(),
                      const SizedBox(height: 30),
                      _buildChart(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTable() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Records",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Colors.blueGrey),
                    children: const [
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Visit Date",
                              style: TextStyle(color: Colors.white))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Fundal Height",
                              style: TextStyle(color: Colors.white))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Gest Age",
                              style: TextStyle(color: Colors.white))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Weight",
                              style: TextStyle(color: Colors.white))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("BP",
                              style: TextStyle(color: Colors.white))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Position",
                              style: TextStyle(color: Colors.white))),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Remarks",
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                  ...recentRecords.map((rec) {
                    return TableRow(children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(rec['visit_date'] != null
                            ? "${rec['visit_date']!.year}-${rec['visit_date']!.month.toString().padLeft(2,'0')}-${rec['visit_date']!.day.toString().padLeft(2,'0')}"
                            : "N/A"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(rec['fundal_height'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(rec['gest_age'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(rec['weight'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(rec['bp'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(rec['position_presentation'].toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(rec['remarks'].toString()),
                      ),
                    ]);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Fundal Height & Gest Age Trends",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _TrendsChart(records: recentRecords),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.circle, color: Colors.blue, size: 12),
                  SizedBox(width: 4),
                  Text("Fundal Height"),
                  SizedBox(width: 16),
                  Icon(Icons.circle, color: Colors.red, size: 12),
                  SizedBox(width: 4),
                  Text("Gest Age"),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendsChart extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _TrendsChart({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const Center(child: Text("No data for graph"));

    final data = records.reversed.toList(); 

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx < 0 || idx >= data.length) return Container();
                final date = data[idx]['visit_date'] as DateTime?;
                return Text(date != null ? "${date.month}/${date.day}" : "N/A");
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              final index = e.key.toDouble();
              final height = e.value["fundal_height"]?.toDouble() ?? 0;
              return FlSpot(index, height);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              final index = e.key.toDouble();
              final age = e.value["gest_age"]?.toDouble() ?? 0;
              return FlSpot(index, age);
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
