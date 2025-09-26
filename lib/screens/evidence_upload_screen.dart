import 'dart:io';
 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../l10n/app_localizations.dart';

// ANDROID PERMISSIONS (AndroidManifest.xml):
// <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
// <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
// <uses-permission android:name="android.permission.CAMERA"/>
// <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
// <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
// <!-- For Android 12- -->
// <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
//
// iOS (Info.plist):
// <key>NSLocationWhenInUseUsageDescription</key><string>Need your location to attach evidence.</string>
// <key>NSCameraUsageDescription</key><string>Need camera to capture evidence.</string>
// <key>NSPhotoLibraryUsageDescription</key><string>Need photo library to select evidence.</string>

class EvidenceUploadScreen extends StatefulWidget {
  const EvidenceUploadScreen({super.key});

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Media
  final List<XFile> _photos = [];
  final List<XFile> _videos = [];

  // Pickers
  final ImagePicker _picker = ImagePicker();

  // Date & time
  DateTime? _date;
  TimeOfDay? _time;

  // Location
  final TextEditingController _locationCtrl = TextEditingController();

  // Meta
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();
  final List<String> _tags = [];

  final List<String> _categories = const [
    'Harassment',
    'Assault',
    'Stalking',
    'Theft',
    'Accident',
    'Other',
  ];
  String _category = 'Harassment';
  double _severity = 3; // 1–5
  bool _anonymous = true;
  bool _shareToCommunity = false;

  // ===== Helpers =====
  String _dateLabel() {
    if (_date == null) return 'Pick date';
    return DateFormat.yMMMEd().format(_date!);
  }

  String _timeLabel() {
    if (_time == null) return 'Pick time';
    final dt = DateTime(0, 1, 1, _time!.hour, _time!.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(data: Theme.of(context), child: child!),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _fillCurrentLocation() async {
    try {
      await _ensureLocationPermission();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      String address;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = [
          p.name,
          p.street,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ]
            .map((e) => (e ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .join(', ');
      } else {
        address = '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      }
      if (!mounted) return;
      setState(() {
        _locationCtrl.text = address;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _pickPhotos() async {
    try {
      // Request photos permission first
      final photosStatus = await Permission.photos.request();
      if (!photosStatus.isGranted) {
        _toast('Photos permission denied');
        return;
      }
      
      // Also request media library permission for iOS
      final mediaStatus = await Permission.mediaLibrary.request();
      if (!mediaStatus.isGranted) {
        _toast('Media library permission denied');
        return;
      }

      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() => _photos.addAll(images));
        _toast('${images.length} photos selected');
      }
    } catch (e) {
      _toast('Error picking photos: $e');
      debugPrint('Error picking photos: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      // Request camera permission first
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _toast('Camera permission denied');
        return;
      }
      
      // Also request microphone permission for camera (some devices need this)
      final microphoneStatus = await Permission.microphone.request();
      if (!microphoneStatus.isGranted) {
        _toast('Microphone permission denied');
        return;
      }

      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        setState(() => _photos.add(photo));
        _toast('Photo captured successfully');
      }
    } catch (e) {
      _toast('Camera error: $e');
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      // Request photos permission for video access
      final photosStatus = await Permission.photos.request();
      if (!photosStatus.isGranted) {
        _toast('Photos permission denied');
        return;
      }
      
      // Also request media library permission for iOS
      final mediaStatus = await Permission.mediaLibrary.request();
      if (!mediaStatus.isGranted) {
        _toast('Media library permission denied');
        return;
      }

      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        setState(() => _videos.add(video));
        _toast('Video selected successfully');
      }
    } catch (e) {
      _toast('Error picking video: $e');
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      // Request camera permission first
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _toast('Camera permission denied');
        return;
      }
      
      // Also request microphone permission for video recording
      final microphoneStatus = await Permission.microphone.request();
      if (!microphoneStatus.isGranted) {
        _toast('Microphone permission denied');
        return;
      }

      final video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        setState(() => _videos.add(video));
        _toast('Video recorded successfully');
      }
    } catch (e) {
      _toast('Video recording error: $e');
      debugPrint('Video recording error: $e');
    }
  }

  void _addTag() {
    final text = _tagCtrl.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagCtrl.clear();
      });
    }
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _saveEvidence() async {
    if (_photos.isEmpty && _videos.isEmpty) {
      _toast('Please attach at least one photo or video.');
      return;
    }
    if (_date == null || _time == null) {
      _toast('Please select date and time.');
      return;
    }
    if (_locationCtrl.text.isEmpty) {
      _toast('Please provide a location.');
      return;
    }

    try {
      // Get current user
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _toast('Please login to save evidence.');
        return;
      }

      // Upload photos to Supabase storage
      List<String> photoUrls = [];
      if (_photos.isNotEmpty) {
        photoUrls = await _uploadPhotos(currentUser.id);
      }

      // Upload videos to Supabase storage
      List<String> videoUrls = [];
      if (_videos.isNotEmpty) {
        videoUrls = await _uploadVideos(currentUser.id);
      }

      // Verify database connection and table exists
      try {
        await Supabase.instance.client
            .from('evidence')
            .select('id')
            .limit(1);
        debugPrint('Evidence table exists, test query successful');
      } catch (e) {
        debugPrint('Evidence table check failed: $e');
        _toast('Database connection issue. Please try again.');
        return;
      }

      // Create evidence record in database
      final evidenceData = {
        'user_id': currentUser.id,
        'category': _category,
        'severity': _severity,
        'incident_date': DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time!.hour,
          _time!.minute,
        ).toIso8601String(),
        'location': _locationCtrl.text,
        'notes': _notesCtrl.text,
        'tags': _tags,
        'photo_urls': photoUrls,
        'video_urls': videoUrls,
        'is_anonymous': _anonymous,
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('evidence')
          .insert(evidenceData)
          .select()
          .single();

      // If user wants to share to community, post a message with photo URLs
      if (_shareToCommunity) {
        await _postToCommunity(currentUser, photoUrls, videoUrls);
      }

      _toast('Evidence saved successfully!');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = 'Error saving evidence';
      if (e.toString().contains('404')) {
        errorMessage = 'Evidence table not found. Please run database setup or contact support.';
        debugPrint('Database table "evidence" not found. Run setup_evidence_table.dart or execute evidence_table_setup.sql');
      } else if (e.toString().contains('403')) {
        errorMessage = 'Permission denied. Please check your login status.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication required. Please login again.';
      } else {
        errorMessage = 'Error saving evidence: ${e.toString().split('\n')[0]}';
      }
      _toast(errorMessage);
      debugPrint('Error saving evidence: $e');
    }
  }

  Future<List<String>> _uploadPhotos(String userId) async {
    List<String> photoUrls = [];
    
    for (int i = 0; i < _photos.length; i++) {
      final photo = _photos[i];
      final fileName = 'evidence_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final filePath = 'evidence/$userId/$fileName';
      
      try {
        final file = File(photo.path);
        final bytes = await file.readAsBytes();
        
        await Supabase.instance.client.storage
            .from('evidence')
            .uploadBinary(filePath, bytes);
            
        final publicUrl = Supabase.instance.client.storage
            .from('evidence')
            .getPublicUrl(filePath);
            
        photoUrls.add(publicUrl);
      } catch (e) {
        debugPrint('Error uploading photo $i: $e');
        throw Exception('Failed to upload photo: $e');
      }
    }
    
    return photoUrls;
  }

  Future<List<String>> _uploadVideos(String userId) async {
    List<String> videoUrls = [];
    
    for (int i = 0; i < _videos.length; i++) {
      final video = _videos[i];
      final fileName = 'evidence_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.mp4';
      final filePath = 'evidence/$userId/$fileName';
      
      try {
        final file = File(video.path);
        final bytes = await file.readAsBytes();
        
        await Supabase.instance.client.storage
            .from('evidence')
            .uploadBinary(filePath, bytes);
            
        final publicUrl = Supabase.instance.client.storage
            .from('evidence')
            .getPublicUrl(filePath);
            
        videoUrls.add(publicUrl);
      } catch (e) {
        debugPrint('Error uploading video $i: $e');
        throw Exception('Failed to upload video: $e');
      }
    }
    
    return videoUrls;
  }

  Future<void> _postToCommunity(User currentUser, List<String> photoUrls, List<String> videoUrls) async {
    try {
      // Create a community message with evidence summary and photo URLs
      final evidenceSummary = _createEvidenceSummary();
      
      final message = {
        'user_id': currentUser.id,
        'user_email': currentUser.email ?? 'Unknown',
        'user_name': currentUser.userMetadata?['full_name'] ?? 'Anonymous',
        'message': evidenceSummary,
        'created_at': DateTime.now().toIso8601String(),
        'is_evidence': true,
        'evidence_category': _category,
        'evidence_severity': _severity,
        'evidence_location': _locationCtrl.text,
        'evidence_date': DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time!.hour,
          _time!.minute,
        ).toIso8601String(),
        'evidence_media_count': _photos.length + _videos.length,
        'evidence_tags': _tags,
        'evidence_notes': _notesCtrl.text,
        'evidence_photo_urls': photoUrls,
        'evidence_video_urls': videoUrls,
      };

      await Supabase.instance.client
          .from('community_messages')
          .insert(message);

      debugPrint('Evidence shared to community successfully');
    } catch (e) {
      debugPrint('Error posting to community: $e');
      // Don't fail the entire evidence upload if community posting fails
      // Just log the error
    }
  }

  String _createEvidenceSummary() {
    final dateStr = _date != null ? DateFormat.yMMMEd().format(_date!) : 'Unknown date';
    final timeStr = _time != null ? _time!.format(context) : 'Unknown time';
    final mediaCount = _photos.length + _videos.length;
    
    String summary = '📋 Evidence Report\n';
    summary += 'Category: $_category\n';
    summary += 'Severity: ${_severity.toStringAsFixed(1)}/5\n';
    summary += 'Date: $dateStr at $timeStr\n';
    summary += 'Location: ${_locationCtrl.text}\n';
    summary += 'Media: $mediaCount files attached\n';
    
    if (_notesCtrl.text.isNotEmpty) {
      summary += 'Notes: ${_notesCtrl.text}\n';
    }
    
    if (_tags.isNotEmpty) {
      summary += 'Tags: ${_tags.join(', ')}\n';
    }
    
    summary += '\nShared from Evidence Upload';
    
    return summary;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.evidenceUpload ?? 'Evidence Upload'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Attachments'),
                _mediaButtonsRow(),
                const SizedBox(height: 12),
                _mediaPreviewGrid(),

                const SizedBox(height: 16),
                _sectionTitle('Incident Details'),
                _categorySeverityCard(),
                const SizedBox(height: 12),
                _dateTimeCard(),

                const SizedBox(height: 16),
                _sectionTitle('Location'),
                _locationCard(),

                const SizedBox(height: 16),
                _sectionTitle('Notes & Tags'),
                _notesField(),
                const SizedBox(height: 8),
                _tagsField(),

                const SizedBox(height: 16),
                _privacyCard(),

                const SizedBox(height: 20),
                _saveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );

  Widget _cardDecoration({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: child,
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryAccent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryAccent),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: AppColors.primaryAccent, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _categorySeverityCard() {
    return _cardDecoration(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _categoryDropdown(),
          const SizedBox(height: 12),
          _severitySlider(),
        ],
      ),
    );
  }

  Widget _dateTimeCard() {
    return _cardDecoration(
      child: Row(
        children: [
          Expanded(child: _dateButton()),
          const SizedBox(width: 12),
          Expanded(child: _timeButton()),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return _cardDecoration(
      child: _locationField(),
    );
  }

  Widget _notesField() {
    return TextField(
      controller: _notesCtrl,
      maxLines: 4,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Notes',
        labelStyle: TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _tagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: -8,
          children: _tags
              .map((t) => Chip(
                    label: Text(t),
                    onDeleted: () => setState(() => _tags.remove(t)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Add tag',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            _pillButton(icon: Icons.add, label: 'Add', onTap: _addTag),
          ],
        ),
      ],
    );
  }

  Widget _privacyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Submit anonymously', style: TextStyle(color: AppColors.textPrimary)),
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
          ),
          SwitchListTile(
            title: const Text('Share to community', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Post this evidence to community chat', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _shareToCommunity,
            onChanged: (v) => setState(() => _shareToCommunity = v),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveEvidence,
        icon: const Icon(Icons.cloud_upload),
        label: Text(AppLocalizations.of(context)?.saveEvidence ?? 'Save Evidence'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _mediaButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconButton(Icons.camera_alt, 'Camera', _capturePhoto),
        _iconButton(Icons.videocam, 'Video', _recordVideo),
        _iconButton(Icons.photo_library, 'Photos', _pickPhotos),
        _iconButton(Icons.video_library, 'Gallery', _pickVideo),
      ],
    );
  }

  Widget _iconButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _mediaPreviewGrid() {
    final items = [..._photos, ..._videos];
    if (items.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final file = items[index];
        final isVideo = _videos.contains(file);
        return _MediaThumb(
          file: file,
          isVideo: isVideo,
          onRemove: () {
            setState(() {
              if (isVideo) {
                _videos.remove(file);
              } else {
                _photos.remove(file);
              }
            });
          },
        );
      },
    );
  }

  Widget _dateButton() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_dateLabel(), style: const TextStyle(color: AppColors.textPrimary))),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _timeButton() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_timeLabel(), style: const TextStyle(color: AppColors.textPrimary))),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _locationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter location or use current location',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.glassBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _fillCurrentLocation,
              icon: const Icon(Icons.my_location, color: AppColors.primaryAccent),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.glassBackground,
                side: const BorderSide(color: AppColors.glassBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      dropdownColor: Colors.white, // Changed to opaque white background
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white, // Changed to opaque white background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _categories
          .map((e) => DropdownMenuItem(
                value: e, 
                child: Text(
                  e,
                  style: const TextStyle(color: Colors.black), // Make text black
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _severitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity: ${_severity.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.textPrimary)),
        Slider(
          value: _severity,
          min: 1,
          max: 5,
          divisions: 40,
          activeColor: AppColors.primaryAccent,
          inactiveColor: AppColors.glassBorder,
          onChanged: (v) => setState(() => _severity = v),
        ),
      ],
    );
  }

  // Removed duplicate methods that are not used in the new UI structure
}

// ---------------- PRIVATE WIDGET ----------------

class _MediaThumb extends StatelessWidget {
  final XFile file;
  final bool isVideo;
  final VoidCallback onRemove;

  const _MediaThumb({
    required this.file,
    required this.isVideo,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(file.path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isVideo)
          const Center(
            child: Icon(Icons.videocam, color: Colors.white, size: 32),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}