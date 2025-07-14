import 'dart:async';
import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonReportScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const PersonReportScreen({super.key, required this.refreshNotifier});

  @override
  State<PersonReportScreen> createState() => _PersonReportScreenState();
}

class _PersonReportScreenState extends State<PersonReportScreen> {
  final ApiService _apiService = ApiService();
  late Future<void> _reportDataFuture;
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  int _presentCount = 0;
  int _absentCount = 0;
  int _lateInCount = 0;
  int _totalWorkingDaysInMonth = 0;
  String _totalWorkingHours = '0hr';

  List<PieChartSectionData> _pieChartSections = [];

  @override
  void initState() {
    super.initState();
    _reportDataFuture = _fetchAndCalculateMonthlyReports();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      setState(() {
        _reportDataFuture = _fetchAndCalculateMonthlyReports();
      });
      widget.refreshNotifier.value = false;
    }
  }

  Future<void> _fetchAndCalculateMonthlyReports() async {
    try {
      final statsResponse = await _apiService.getAbsenceStats();
      if (statsResponse.statusCode == 200 && statsResponse.data != null) {
        final stats = statsResponse.data!;
        setState(() {
          _presentCount = stats.totalMasuk;
          _absentCount = stats.totalIzin;
          _lateInCount = stats.totalAbsen;
          _totalWorkingDaysInMonth = stats.totalMasuk;
        });
      } else {
        _updateSummaryCounts(0, 0, 0, 0, '0hr');
        _updatePieChartData(0, 0, 0);
        _showSnackBar('Gagal memuat ringkasan: ${statsResponse.message}');
        return;
      }

      final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
      final String endDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

      final historyResponse = await _apiService.getAbsenceHistory(
        startDate: startDate,
        endDate: endDate,
      );

      Duration totalWorkingDuration = Duration.zero;
      if (historyResponse.statusCode == 200 && historyResponse.data != null) {
        for (var absence in historyResponse.data!) {
          if (absence.status?.toLowerCase() == 'masuk' &&
              absence.checkIn != null &&
              absence.checkOut != null) {
            totalWorkingDuration += absence.checkOut!.difference(
              absence.checkIn!,
            );
          }
        }
      } else {
        _showSnackBar('Gagal memuat jam kerja: ${historyResponse.message}');
      }

      final int totalHours = totalWorkingDuration.inHours;
      final int remainingMinutes = totalWorkingDuration.inMinutes.remainder(60);
      String formattedTotalWorkingHours = '${totalHours}j ${remainingMinutes}m';

      setState(() {
        _totalWorkingHours = formattedTotalWorkingHours;
      });

      _updatePieChartData(_presentCount, _absentCount, _lateInCount);
    } catch (e) {
      _updateSummaryCounts(0, 0, 0, 0, '0hr');
      _updatePieChartData(0, 0, 0);
      _showSnackBar('Terjadi kesalahan saat memuat laporan: $e');
    }
  }

  void _updateSummaryCounts(
    int present,
    int absent,
    int late,
    int totalWorkingDays,
    String totalHrs,
  ) {
    setState(() {
      _presentCount = present;
      _absentCount = absent;
      _lateInCount = late;
      _totalWorkingDaysInMonth = totalWorkingDays;
      _totalWorkingHours = totalHrs;
    });
  }

  void _updatePieChartData(int presentCount, int absentCount, int lateInCount) {
    final total = presentCount + absentCount + lateInCount;
    if (total == 0) {
      setState(() {
        _pieChartSections = [];
      });
      return;
    }

    setState(() {
      _pieChartSections = [
        PieChartSectionData(
          color: Colors.green,
          value: presentCount.toDouble(),
          title: 'Hadir\n${(presentCount / total * 100).toStringAsFixed(1)}%',
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          color: Colors.red,
          value: absentCount.toDouble(),
          title: 'Absen\n${(absentCount / total * 100).toStringAsFixed(1)}%',
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          color: Colors.orange,
          value: lateInCount.toDouble(),
          title:
              'Terlambat\n${(lateInCount / total * 100).toStringAsFixed(1)}%',
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    });
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
      );
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null &&
        (picked.year != _selectedMonth.year ||
            picked.month != _selectedMonth.month)) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _reportDataFuture = _fetchAndCalculateMonthlyReports();
      });
    }
  }

  Widget _buildSummaryCard(String title, dynamic value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Laporan Kehadiran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0BBE4), Color(0xFFADD8E6), Color(0xFF957DAD)],
          ),
        ),
        child: FutureBuilder<void>(
          future: _reportDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return SafeArea(
              child: RefreshIndicator(
                onRefresh: _fetchAndCalculateMonthlyReports,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ringkasan Bulanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectMonth(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('MMM yyyy').format(_selectedMonth),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth < 600 ? 2 : 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      children: [
                        _buildSummaryCard(
                          'Hari Kerja',
                          _totalWorkingDaysInMonth,
                          Colors.blueGrey,
                        ),
                        _buildSummaryCard('Hadir', _presentCount, Colors.green),
                        _buildSummaryCard(
                          'Izin/Absen',
                          _absentCount + _lateInCount,
                          Colors.deepOrange,
                        ),
                        _buildSummaryCard(
                          'Jam Kerja',
                          _totalWorkingHours,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Grafik Kehadiran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: screenWidth < 400 ? 1 : 1.3,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        color: Colors.white.withOpacity(0.95),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: PieChart(
                            PieChartData(
                              sections: _pieChartSections,
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 4,
                              centerSpaceRadius: screenWidth < 400 ? 30 : 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
