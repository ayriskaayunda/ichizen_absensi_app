import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/constants/app_text_styles.dart';
import 'package:latlong2/latlong.dart' as latlong_pkg;

class CheckInScreen extends StatefulWidget {
  final Function(latlong_pkg.LatLng, String) onCheckIn;
  final Position? currentPosition;
  final bool isChecking;

  const CheckInScreen({
    super.key,
    required this.onCheckIn,
    this.currentPosition,
    required this.isChecking,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  static final gmaps.LatLng _ppkdjpLocation = const gmaps.LatLng(
    -6.175388,
    106.827153,
  );
  gmaps.GoogleMapController? _mapController;
  String _currentAddress = 'Mencari alamat...';
  final Set<gmaps.Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMarkers();
      _getAddressFromLatLng(widget.currentPosition);
    });
  }

  void _addMarkers() {
    _markers.add(
      gmaps.Marker(
        markerId: const gmaps.MarkerId('ppkdjp'),
        position: _ppkdjpLocation,
        infoWindow: const gmaps.InfoWindow(
          title: 'PPKDJP',
          snippet: 'Titik Absensi',
        ),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueBlue,
        ),
      ),
    );

    if (widget.currentPosition != null) {
      _markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('current_location'),
          position: gmaps.LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          infoWindow: const gmaps.InfoWindow(
            title: 'Lokasi Anda',
            snippet: 'Posisi saat ini',
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _getAddressFromLatLng(Position? position) async {
    if (position == null) {
      setState(() => _currentAddress = 'Lokasi tidak tersedia.');
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      } else {
        setState(() => _currentAddress = 'Alamat tidak ditemukan.');
      }
    } catch (e) {
      setState(() => _currentAddress = 'Gagal mendapatkan alamat: $e');
    }
  }

  void _zoomToCurrentLocation() async {
    if (widget.currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          16.0,
        ),
      );
      _getAddressFromLatLng(widget.currentPosition);
    } else if (_mapController != null) {
      await _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(_ppkdjpLocation, 14),
      );
    }
  }

  String _getDistanceText(Position? currentPosition) {
    if (currentPosition == null) return 'Mendapatkan lokasi...';

    final distance = Geolocator.distanceBetween(
      _ppkdjpLocation.latitude,
      _ppkdjpLocation.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    return distance < 1000
        ? 'Jarak ke PPKDJP: ${distance.toStringAsFixed(1)} meter'
        : 'Jarak ke PPKDJP: ${(distance / 1000).toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Lokasi Absensi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF624F82),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            mapType: gmaps.MapType.normal,
            initialCameraPosition: gmaps.CameraPosition(
              target: widget.currentPosition != null
                  ? gmaps.LatLng(
                      widget.currentPosition!.latitude,
                      widget.currentPosition!.longitude,
                    )
                  : _ppkdjpLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _zoomToCurrentLocation();
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getDistanceText(widget.currentPosition),
                    style: AppTextStyles.normal.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress,
                    style: AppTextStyles.normal.copyWith(
                      fontSize: 14,
                      color: AppColors.placeholder,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.isChecking
                        ? null
                        : () {
                            if (widget.currentPosition != null) {
                              widget.onCheckIn(
                                latlong_pkg.LatLng(
                                  widget.currentPosition!.latitude,
                                  widget.currentPosition!.longitude,
                                ),
                                _currentAddress,
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Lokasi tidak ditemukan. Coba lagi.',
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF624F82),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Check In di Lokasi Ini',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _zoomToCurrentLocation,
              backgroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.gps_fixed, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
