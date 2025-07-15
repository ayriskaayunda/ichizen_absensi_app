import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class AttendanceListScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  const AttendanceListScreen({super.key, required this.refreshNotifier});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Absence>> _attendanceFuture;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null);
    _attendanceFuture = _fetchAndFilterAttendances();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _refreshList();
      widget.refreshNotifier.value = false;
    }
  }

  Future<List<Absence>> _fetchAndFilterAttendances() async {
    final String startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
    final String endDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

    try {
      final ApiResponse<List<Absence>> response = await _apiService
          .getAbsenceHistory(startDate: startDate, endDate: endDate);

      if (response.statusCode == 200 && response.data != null) {
        final List<Absence> fetchedAbsences = response.data!;
        fetchedAbsences.sort((a, b) {
          if (a.attendanceDate == null && b.attendanceDate == null) return 0;
          if (a.attendanceDate == null) return 1;
          if (b.attendanceDate == null) return -1;
          return b.attendanceDate!.compareTo(a.attendanceDate!);
        });
        return fetchedAbsences;
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage +=
                '\n$key: ${value is List ? value.join(', ') : value}';
          });
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      _attendanceFuture = _fetchAndFilterAttendances();
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final DateTime newSelectedMonth = DateTime(picked.year, picked.month, 1);
      if (newSelectedMonth.year != _selectedMonth.year ||
          newSelectedMonth.month != _selectedMonth.month) {
        setState(() {
          _selectedMonth = newSelectedMonth;
        });
        _refreshList();
      }
    }
  }

  String _calculateWorkingHours(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) return '00:00:00';
    DateTime endDateTime = checkOut ?? DateTime.now();
    final Duration duration = endDateTime.difference(checkIn);
    return '${duration.inHours.toString().padLeft(2, '0')}:'
        '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required DateTime? time,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            '$label: ${time != null ? DateFormat('HH:mm').format(time) : 'Belum Check-out'}',
            style: TextStyle(
              fontSize: 17,
              color: time != null ? Colors.black87 : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTile(Absence absence) {
    bool isRequestType = absence.status?.toLowerCase() == 'izin';
    String statusText;
    Color statusColor;

    if (isRequestType) {
      statusText = 'IZIN';
      statusColor = AppColors.accentOrange;
    } else if (absence.status?.toLowerCase() == 'late') {
      statusText = 'TERLAMBAT';
      statusColor = AppColors.accentRed;
    } else if (absence.status?.toLowerCase() == 'masuk' &&
        absence.checkOut != null) {
      statusText = 'SELESAI';
      statusColor = AppColors.accentGreen;
    } else if (absence.status?.toLowerCase() == 'masuk' &&
        absence.checkIn != null) {
      statusText = 'CHECK IN HARI INI';
      statusColor = Colors.blue;
    } else {
      statusText = 'N/A';
      statusColor = Colors.grey;
    }

    final String formattedDate = absence.attendanceDate != null
        ? DateFormat('EEEE, dd MMMM yyyy', 'id').format(absence.attendanceDate!)
        : 'N/A';

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.85),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF624F82),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1.5, color: Colors.grey),
            if (!isRequestType)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeRow(
                    icon: Icons.login,
                    label: 'Check-in',
                    time: absence.checkIn,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeRow(
                    icon: Icons.logout,
                    label: 'Check-out',
                    time: absence.checkOut,
                    color: Colors.red,
                  ),
                  if (absence.checkIn != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.blueGrey,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Jam Kerja: ${_calculateWorkingHours(absence.checkIn, absence.checkOut)}',
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Alasan: ${absence.alasanIzin?.isNotEmpty == true ? absence.alasanIzin : 'Tidak ada alasan'}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<Color> gradientColors = [
      Color(0xFFE0BBE4),
      Color(0xFFADD8E6),
      Color(0xFF957DAD),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            color: Color(0xFF624F82),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF624F82),
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top:
                    AppBar().preferredSize.height +
                    MediaQuery.of(context).padding.top +
                    16.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Riwayat Kehadiran Bulanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _selectMonth(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat(
                              'MMM yyyy',
                              'id',
                            ).format(_selectedMonth).toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF624F82),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF624F82),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshList,
                color: AppColors.primary,
                child: FutureBuilder<List<Absence>>(
                  future: _attendanceFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final attendances = snapshot.data ?? [];

                    if (attendances.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada riwayat kehadiran untuk ${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 16.0,
                        left: 16,
                        right: 16,
                      ),
                      itemCount: attendances.length,
                      itemBuilder: (context, index) {
                        return _buildAttendanceTile(attendances[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
