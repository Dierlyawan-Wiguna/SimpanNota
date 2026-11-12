import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';

class LocationSearchResult {
  final String title;
  final String fullAddress;

  const LocationSearchResult({
    required this.title,
    required this.fullAddress,
  });
}

class LocationSearchSheet extends StatefulWidget {
  final String? initialQuery;

  const LocationSearchSheet({super.key, this.initialQuery});

  static Future<String?> show(BuildContext context, {String? initialQuery}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSearchSheet(initialQuery: initialQuery),
    );
  }

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  bool _isLocatingGps = false;
  String? _errorMessage;
  String? _fallbackNotice;
  List<LocationSearchResult> _results = [];
  List<String> _suggestedChips = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      final cleanInit = _cleanInitialQuery(widget.initialQuery!.trim());
      _searchController.text = cleanInit;
      _updateSuggestedChips(cleanInit);
      _performSmartSearch(cleanInit);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Membersihkan query awal jika berasal dari format gabungan "NamaToko (Alamat)"
  String _cleanInitialQuery(String raw) {
    final match = RegExp(r'\((.*?)\)').firstMatch(raw);
    if (match != null) {
      final inside = match.group(1)?.trim();
      if (inside != null && inside.isNotEmpty) {
        return inside;
      }
    }
    return raw;
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _fallbackNotice = null;
        _results = [];
        _suggestedChips = [];
      });
      return;
    }

    _updateSuggestedChips(trimmed);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSmartSearch(trimmed);
    });
  }

  /// Ekstraksi kata kunci yang berguna untuk dijadikan chip pencarian cepat
  void _updateSuggestedChips(String query) {
    final chips = <String>[];

    // Bersihkan tanda kurung
    final cleaned = query.replaceAll(RegExp(r'[\(\)]'), ' ');

    // Ambil bagian-bagian yang dipisahkan koma atau titik
    final parts = cleaned.split(RegExp(r'[,;]')).map((p) => p.trim()).where((p) => p.length >= 3).toList();
    for (final p in parts) {
      // Hapus noise seperti lantai, blok, no
      final cleanPart = p
          .replaceAll(RegExp(r'\b(lantai|lt|blok|kav|unit|no|nomor|rt|rw)\b\.?\s*[\w\d\-\/\.]*', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\b\d{5}\b'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleanPart.length >= 3 &&
          !chips.any((c) => c.toLowerCase() == cleanPart.toLowerCase()) &&
          cleanPart.toLowerCase() != query.toLowerCase()) {
        chips.add(cleanPart);
      }
    }

    setState(() {
      _suggestedChips = chips.take(4).toList();
    });
  }

  /// Membersihkan query untuk OpenStreetMap Nominatim
  String _cleanForOsm(String input) {
    return input
        .replaceAll(RegExp(r'[\(\)]'), ' ')
        .replaceAll(RegExp(r'\b(lantai|lt|blok|kav|unit|no|nomor)\b\.?\s*[\w\d\-\/\.]*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(rt|rw)\b\.?\s*\d+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b\d{5}\b'), ' ') // Hilangkan kode pos jika ada kata lain
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Memanggil API OpenStreetMap Nominatim
  Future<List<LocationSearchResult>> _queryNominatim(String q) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&addressdetails=1&limit=8&countrycodes=id',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'SimpanNotaApp/1.0 (contact: support@simpannota.local)',
        'Accept-Language': 'id',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final list = <LocationSearchResult>[];

      for (final item in data) {
        final displayName = item['display_name'] as String? ?? '';
        final name = (item['name'] as String?)?.trim();

        final parts = displayName.split(',').map((e) => e.trim()).toList();
        final title = (name != null && name.isNotEmpty)
            ? name
            : (parts.isNotEmpty ? parts.first : q);

        list.add(LocationSearchResult(
          title: title,
          fullAddress: displayName,
        ));
      }
      return list;
    }
    return [];
  }

  /// Pencarian pintar bertahap (Multi-tier Smart Search):
  /// 1. Coba cari query yang diketik user
  /// 2. Jika 0 hasil, coba bersihkan noise (lantai/blok/kodepos/kurung)
  /// 3. Jika masih 0 hasil, coba cari nama gedung/mall atau nama jalan utama
  Future<void> _performSmartSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fallbackNotice = null;
    });

    try {
      // Tahap 1: Pencarian langsung
      List<LocationSearchResult> items = await _queryNominatim(query);

      // Tahap 2: Jika kosong, coba query yang sudah dibersihkan dari noise detail
      if (items.isEmpty) {
        final cleanedQuery = _cleanForOsm(query);
        if (cleanedQuery.isNotEmpty && cleanedQuery.toLowerCase() != query.toLowerCase()) {
          items = await _queryNominatim(cleanedQuery);
          if (items.isNotEmpty && mounted) {
            setState(() {
              _fallbackNotice = 'Menampilkan hasil untuk area: "$cleanedQuery"';
            });
          }
        }
      }

      // Tahap 3: Jika masih kosong, coba cari per segmen (misal: "ITC BSD")
      if (items.isEmpty) {
        final parts = query.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.length >= 3).toList();
        for (final p in parts) {
          final cleanedPart = _cleanForOsm(p);
          if (cleanedPart.length >= 3 && cleanedPart.toLowerCase() != query.toLowerCase()) {
            final partResults = await _queryNominatim(cleanedPart);
            if (partResults.isNotEmpty) {
              items = partResults;
              if (mounted) {
                setState(() {
                  _fallbackNotice = 'Menampilkan hasil pencarian: "$cleanedPart"';
                });
              }
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Periksa koneksi internet Anda untuk mencari lokasi.';
        });
      }
    }
  }

  Future<void> _useCurrentGpsLocation() async {
    setState(() {
      _isLocatingGps = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocatingGps = false;
            _errorMessage = 'Layanan lokasi/GPS di HP belum aktif. Mohon aktifkan GPS.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLocatingGps = false;
              _errorMessage = 'Izin akses lokasi ditolak oleh pengguna.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLocatingGps = false;
            _errorMessage = 'Izin lokasi ditolak permanen. Silakan aktifkan via Pengaturan HP.';
          });
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final reverseUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1',
      );

      final response = await http.get(
        reverseUrl,
        headers: {
          'User-Agent': 'SimpanNotaApp/1.0 (contact: support@simpannota.local)',
          'Accept-Language': 'id',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          if (mounted) {
            Navigator.pop(context, displayName);
            return;
          }
        }
      }

      if (mounted) {
        final fallbackAddr = 'Lokasi GPS (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        Navigator.pop(context, fallbackAddr);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocatingGps = false;
          _errorMessage = 'Gagal mendeteksi lokasi: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cari Lokasi Toko',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Cari nama toko, mall, atau alamat jalan',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textGrey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Input Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _performSmartSearch(val.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'Ketik nama toko, mall, atau jalan...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),

          // Chip Saran Pencarian Cepat (jika ada beberapa kata kunci)
          if (_suggestedChips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Saran: ', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ..._suggestedChips.map((chipText) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.lightBlue.withValues(alpha: 0.5),
                          label: Text(
                            chipText,
                            style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            _searchController.text = chipText;
                            _performSmartSearch(chipText);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Tombol GPS "Gunakan Posisi Saya Saat Ini"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: AppColors.lightBlue.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLocatingGps ? null : _useCurrentGpsLocation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      _isLocatingGps
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primaryBlue,
                              size: 18,
                            ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLocatingGps
                                  ? 'Mendeteksi alamat dari GPS...'
                                  : 'Gunakan Posisi Saya Saat Ini (GPS)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const Text(
                              'Otomatis mengisi alamat toko tempat Anda berada',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Banner Notifikasi Fallback / Alternatif Pencarian
          if (_fallbackNotice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fallbackNotice!,
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Pesan Error jika ada
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Area Hasil Pencarian (Scrollable & Keyboard-Safe)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2.5),
                        SizedBox(height: 12),
                        Text(
                          'Mencari lokasi toko...',
                          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _results.isNotEmpty
                    ? ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: _results.length + 1, // +1 untuk opsi manual di paling bawah
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index < _results.length) {
                            final item = _results[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              subtitle: Text(
                                item.fullAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context, item.fullAddress);
                              },
                            );
                          } else {
                            // Opsi manual selalu tersedia di akhir daftar
                            final currentText = _searchController.text.trim();
                            if (currentText.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context, currentText);
                                },
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(
                                  'Gunakan teks "$currentText"',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  side: const BorderSide(color: AppColors.primaryBlue),
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : _searchController.text.trim().isNotEmpty && !_isLoading
                        // State saat tidak ditemukan hasil pencarian di OpenStreetMap (Keyboard-Safe Scrollable)
                        ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 32,
                                        color: Colors.amber.shade900,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Alamat Tidak Ditemukan di Peta',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Lokasi "${_searchController.text.trim()}" belum terdaftar di OpenStreetMap. Anda dapat mengetik alamat lengkapnya secara manual pada form nota.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.amber.shade900,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Tutup modal dan kirim sinyal isi manual
                                      Navigator.pop(context, 'MANUAL_INPUT:${_searchController.text.trim()}');
                                    },
                                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                                    label: const Text(
                                      'Isi Manual di Form Nota',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primaryBlue),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Tips: Coba cari nama mall/gedung (misal: "ITC BSD") atau nama jalan utama.',
                                          style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 44,
                                  color: AppColors.cardBorder,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Ketik nama toko, mall, atau jalan untuk mencari alamat',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
