import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:contacts_service/contacts_service.dart';
import '../services/sms_service.dart';
import '../services/contact_service.dart';
import '../l10n/app_localizations.dart';
import '../screens/contact_selection_screen.dart';
import 'package:flutter/foundation.dart';

class SmsShareWidget extends StatefulWidget {
  final LatLng? currentLocation;
  final String? title;

  const SmsShareWidget({
    super.key,
    this.currentLocation,
    this.title,
  });

  @override
  State<SmsShareWidget> createState() => _SmsShareWidgetState();
}

class _SmsShareWidgetState extends State<SmsShareWidget> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _includeAddress = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _shareLocation() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      bool success;
      if (_includeAddress) {
        success = await SmsService.shareLocationWithAddress(
          phoneNumber: _phoneController.text.trim(),
          customMessage: _messageController.text.trim(),
          customLocation: widget.currentLocation,
        );
      } else {
        success = await SmsService.shareLocationViaSms(
          phoneNumber: _phoneController.text.trim(),
          customMessage: _messageController.text.trim(),
          customLocation: widget.currentLocation,
        );
      }

      if (success) {
        setState(() {
          if (kIsWeb) {
            _successMessage = 'SMS app opened! If no SMS app is available, the message may have been copied to clipboard.';
          } else {
            _successMessage = 'Location shared successfully via SMS!';
          }
          _phoneController.clear();
          _messageController.clear();
        });
      } else {
        setState(() {
          if (kIsWeb) {
            _errorMessage = 'Could not open SMS app. Please try manually sending the location.';
          } else {
            _errorMessage = 'Failed to send SMS. Please check permissions and try again.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSmsAvailability() async {
    bool isAvailable = await SmsService.isSmsAvailable();
    if (!isAvailable) {
      setState(() {
        if (kIsWeb) {
          _errorMessage = 'SMS functionality is limited on web browsers. The app will try to open your SMS app.';
        } else {
          _errorMessage = 'SMS is not available on this device';
        }
      });
    }
  }

  void _openContactSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactSelectionScreen(
          onContactSelected: (Contact contact) {
            final phoneNumber = ContactService.getPrimaryPhoneNumber(contact);
            if (phoneNumber != null) {
              setState(() {
                _phoneController.text = phoneNumber;
              });
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkSmsAvailability();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(widget.title ?? localizations?.shareLocation ?? 'Share Location'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact selection row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: localizations?.phoneNumber ?? 'Phone Number',
                      hintText: '+1234567890',
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _openContactSelection(),
                  icon: const Icon(Icons.contacts, color: Colors.blue),
                  tooltip: 'Select from contacts',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Message input
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: localizations?.customMessage ?? 'Custom Message (Optional)',
                hintText: 'Add a personal message...',
                prefixIcon: const Icon(Icons.message),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Include address checkbox
            CheckboxListTile(
              title: Text(localizations?.includeAddress ?? 'Include Address'),
              subtitle: Text(
                localizations?.addressRequiresInternet ?? 'Address requires internet connection',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: _includeAddress,
              onChanged: (value) {
                setState(() {
                  _includeAddress = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            // Current location info
            if (widget.currentLocation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations?.currentLocation ?? 'Current Location:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      SmsService.getFormattedCoordinates(widget.currentLocation!),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Success message
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations?.cancel ?? 'Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _shareLocation,
          icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
          label: Text(_isLoading 
            ? (localizations?.sending ?? 'Sending...')
            : (localizations?.share ?? 'Share')),
        ),
      ],
    );
  }
} 