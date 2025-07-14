import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ichizen/screens/attendance/checkin_screen.dart';
import 'package:ichizen/screens/attendance/chekout_screen.dart';
import 'package:ichizen/screens/attendance/request_screen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/screens/main_bottom_navigation_bar.dart';
import 'package:ichizen/services/api_services.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;
  const HomeScreen({super.key, required this.refreshNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  String _userName = 'User';
  String _trainingName = 'Belum terdaftar training';
  String _currentDate = '', _currentTime = '';
  Timer? _timer;

  AbsenceToday? _todayAbsence;
  AbsenceStats? _absenceStats;
  Position? _currentPosition;
  bool _permissionGranted = false, _isChecking = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null).then((_) => _updateDateTime());
    _determinePosition();
    _loadUserData();
    _fetchAttendanceData();
    widget.refreshNotifier.addListener(_handleRefreshSignal);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateDateTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.refreshNotifier.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (widget.refreshNotifier.value) {
      _fetchAttendanceData();
      widget.refreshNotifier.value = false;
    }
  }

  Future<void> _loadUserData() async {
    final response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      setState(() {
        _userName = response.data!.name;
        _trainingName = response.data!.training?.title?.isNotEmpty == true
            ? response.data!.training!.title!
            : 'Belum terdaftar training';
      });
    }
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDate = DateFormat('EEEE, dd MMMM yyyy', 'id').format(now);
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  Future<void> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Aktifkan layanan lokasi.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      _showErrorDialog('Izin lokasi ditolak secara permanen.');
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition();
      _currentPosition = pos;
      _permissionGranted = true;
    } catch (e) {
      _showErrorDialog('Gagal mendapatkan lokasi.');
    }
  }

  Future<void> _fetchAttendanceData() async {
    final todayRes = await _apiService.getAbsenceToday();
    final statRes = await _apiService.getAbsenceStats();
    if (todayRes.statusCode == 200) _todayAbsence = todayRes.data;
    if (statRes.statusCode == 200) _absenceStats = statRes.data;
    setState(() {});
  }

  Future<void> _handleCheckIn() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog('Pastikan lokasi aktif dan sudah didapatkan.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CheckInScreen(
          currentPosition: _currentPosition,
          isChecking: _isChecking,
          onCheckIn: (location, address) async {
            if (_isChecking) return;
            setState(() => _isChecking = true);

            final now = DateTime.now();
            final response = await _apiService.checkIn(
              checkInLat: location.latitude,
              checkInLng: location.longitude,
              checkInAddress: address,
              attendanceDate: DateFormat('yyyy-MM-dd').format(now),
              checkInTime: DateFormat('HH:mm').format(now),
              status: 'masuk',
            );

            if (response.statusCode == 200) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(response.message)));
              _todayAbsence = AbsenceToday(jamMasuk: now);
              MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
              setState(() {});
            } else {
              _showErrorDialog(response.message);
            }

            setState(() => _isChecking = false);
          },
        ),
      ),
    );
  }

  Future<void> _handleCheckOut() async {
    if (!_permissionGranted || _currentPosition == null) {
      _showErrorDialog('Pastikan lokasi aktif.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CheckOutScreen(
          currentPosition: _currentPosition,
          isChecking: _isChecking,
          onCheckOut: (location, address) async {
            if (_isChecking) return;
            setState(() => _isChecking = true);

            final now = DateTime.now();
            final response = await _apiService.checkOut(
              checkOutLat: location.latitude,
              checkOutLng: location.longitude,
              checkOutAddress: address,
              attendanceDate: DateFormat('yyyy-MM-dd').format(now),
              checkOutTime: DateFormat('HH:mm').format(now),
            );

            if (response.statusCode == 200) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(response.message)));
              _todayAbsence = AbsenceToday(
                jamMasuk: _todayAbsence?.jamMasuk,
                jamKeluar: now,
              );
              MainBottomNavigationBar.refreshAttendanceNotifier.value = true;
              setState(() {});
            } else {
              _showErrorDialog(response.message);
            }

            setState(() => _isChecking = false);
          },
        ),
      ),
    );
  }

  // New method to handle Izin request navigation
  Future<void> _handleIzinRequest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const RequestScreen()),
    );

    // If the RequestScreen returns true, it means a request was successfully submitted,
    // so refresh the attendance data.
    if (result == true) {
      _fetchAttendanceData();
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Perhatian',
          style: TextStyle(color: AppColors.textDark),
        ),
        content: Text(msg, style: const TextStyle(color: AppColors.textDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk me-refresh data
  Future<void> _onRefresh() async {
    await Future.wait([
      _loadUserData(),
      _fetchAttendanceData(),
      _determinePosition(), // Opsional: me-refresh posisi juga
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final hasCheckedIn = _todayAbsence?.jamMasuk != null;
    final hasCheckedOut = _todayAbsence?.jamKeluar != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Menggunakan warna-warna yang konsisten dengan tema jika diinginkan,
            // atau mempertahankan gradien ini jika ini adalah desain yang disengaja.
            // Contoh penggunaan AppColors untuk gradien (jika ingin mengubah):
            // colors: [AppColors.primary.withOpacity(0.8), AppColors.primary.withOpacity(0.6), AppColors.primary],
            colors: [Color(0xFFE0BBE4), Color(0xFFADD8E6), Color(0xFF957DAD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  // <--- Tambahkan RefreshIndicator di sini
                  onRefresh: _onRefresh,
                  color: AppColors.primary, // Warna indikator refresh
                  backgroundColor:
                      AppColors.background, // Latar belakang indikator refresh
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildCheckButton(hasCheckedIn, hasCheckedOut),
                      const SizedBox(height: 12), // Added spacing
                      _buildIzinButton(), // Added Izin button
                      const SizedBox(height: 16),
                      _buildSummarySection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.card,
          ), // Menggunakan AppColors.card
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hai, $_userName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.card, // Menggunakan AppColors.card
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _trainingName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ), // Menggunakan AppColors.textLight
                ),
              ],
            ),
          ),
          const Icon(
            Icons.notifications_none,
            color: AppColors.card,
          ), // Menggunakan AppColors.card
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card, // Menggunakan AppColors.card
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 8,
            offset: Offset(0, 3),
          ), // Menggunakan AppColors.border
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            _currentDate,
            style: const TextStyle(
              color: AppColors.placeholder,
              fontSize: 14,
            ), // Menggunakan AppColors.placeholder
          ),
          const SizedBox(height: 4),
          Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ), // Menggunakan AppColors.textDark
          ),
          const Divider(
            height: 28,
            color: AppColors.border,
          ), // Menggunakan AppColors.border
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleTimeBox('Masuk', _todayAbsence?.jamMasuk),
              _buildSimpleTimeBox('Keluar', _todayAbsence?.jamKeluar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTimeBox(String label, DateTime? time) {
    final text = time != null ? DateFormat('HH:mm').format(time) : '--:--';
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.placeholder,
          ), // Menggunakan AppColors.placeholder
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ), // Menggunakan AppColors.textDark
        ),
      ],
    );
  }

  Widget _buildCheckButton(bool hasCheckIn, bool hasCheckOut) {
    Color buttonColor;
    if (hasCheckIn) {
      buttonColor = hasCheckOut
          ? AppColors.inputFill
          : AppColors.error; // Selesai: inputFill, Check Out: error
    } else {
      buttonColor = AppColors.success; // Check In: success
    }

    return ElevatedButton(
      onPressed: hasCheckIn
          ? (hasCheckOut ? null : _handleCheckOut)
          : _handleCheckIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isChecking
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.card, // Menggunakan AppColors.card
              ),
            )
          : Text(
              hasCheckIn ? (hasCheckOut ? 'Selesai' : 'Check Out') : 'Check In',
              style: const TextStyle(
                color: AppColors.card,
                fontSize: 16,
              ), // Menggunakan AppColors.card
            ),
    );
  }

  // New Izin button widget
  Widget _buildIzinButton() {
    return ElevatedButton(
      onPressed: _handleIzinRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.primary, // You can choose an appropriate color
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        'Izin',
        style: TextStyle(color: AppColors.card, fontSize: 16),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Bulan Ini',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ), // Menggunakan AppColors.textDark
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          'Hadir',
          _absenceStats?.totalMasuk ?? 0,
          AppColors.accentGreen, // Menggunakan AppColors.accentGreen
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Izin',
          _absenceStats?.totalIzin ?? 0,
          AppColors.accentOrange,
        ), // Menggunakan AppColors.accentOrange
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Absen',
          _absenceStats?.totalAbsen ?? 0,
          AppColors.accentRed,
        ), // Menggunakan AppColors.accentRed
      ],
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, // Menggunakan AppColors.card
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 5,
            offset: Offset(0, 3),
          ), // Menggunakan AppColors.border
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
