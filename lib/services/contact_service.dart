import 'package:contacts_service/contacts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ContactService {
  static const String _customContactsKey = 'custom_contacts_list';

  /// Get all contacts from the device
  static Future<List<Contact>> getAllContacts() async {
    try {
      // Get all contacts (permission is handled by the package)
      final contacts = await ContactsService.getContacts();
      return contacts.toList();
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }

  /// Get contacts with phone numbers only
  static Future<List<Contact>> getContactsWithPhone() async {
    try {
      final allContacts = await getAllContacts();
      return allContacts.where((contact) => 
        contact.phones != null && contact.phones!.isNotEmpty
      ).toList();
    } catch (e) {
      print('Error getting contacts with phone: $e');
      return [];
    }
  }

  /// Search contacts by name or phone number
  static Future<List<Contact>> searchContacts(String query) async {
    try {
      final allContacts = await getContactsWithPhone();
      final lowercaseQuery = query.toLowerCase();
      
      return allContacts.where((contact) {
        // Search by name
        if (contact.displayName?.toLowerCase().contains(lowercaseQuery) == true) {
          return true;
        }
        
        // Search by phone number
        for (final phone in contact.phones!) {
          if (phone.value?.toLowerCase().contains(lowercaseQuery) == true) {
            return true;
          }
        }
        
        return false;
      }).toList();
    } catch (e) {
      print('Error searching contacts: $e');
      return [];
    }
  }

  /// Save custom contact list to SharedPreferences
  static Future<bool> saveCustomContactList(List<Contact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactList = contacts.map((contact) => {
        'id': contact.identifier,
        'displayName': contact.displayName,
        'phones': contact.phones?.map((phone) => phone.value).toList() ?? [],
        'emails': contact.emails?.map((email) => email.value).toList() ?? [],
      }).toList();
      
      await prefs.setString(_customContactsKey, jsonEncode(contactList));
      return true;
    } catch (e) {
      print('Error saving custom contact list: $e');
      return false;
    }
  }

  /// Load custom contact list from SharedPreferences
  static Future<List<Contact>> loadCustomContactList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactListString = prefs.getString(_customContactsKey);
      
      if (contactListString == null) {
        return [];
      }
      
      final contactList = jsonDecode(contactListString) as List;
      return contactList.map((contactData) {
        final data = contactData as Map<String, dynamic>;
        return Contact(
          phones: (data['phones'] as List).map((phone) => 
            Item(label: 'mobile', value: phone)
          ).toList(),
          emails: (data['emails'] as List).map((email) => 
            Item(label: 'email', value: email)
          ).toList(),
          displayName: data['displayName'],
        );
      }).toList();
    } catch (e) {
      print('Error loading custom contact list: $e');
      return [];
    }
  }

  /// Add contact to custom list
  static Future<bool> addContactToCustomList(Contact contact) async {
    try {
      final currentList = await loadCustomContactList();
      
      // Check if contact already exists
      final exists = currentList.any((c) => c.identifier == contact.identifier);
      if (exists) {
        return true; // Already exists
      }
      
      currentList.add(contact);
      return await saveCustomContactList(currentList);
    } catch (e) {
      print('Error adding contact to custom list: $e');
      return false;
    }
  }

  /// Remove contact from custom list
  static Future<bool> removeContactFromCustomList(String contactId) async {
    try {
      final currentList = await loadCustomContactList();
      currentList.removeWhere((contact) => contact.displayName == contactId);
      return await saveCustomContactList(currentList);
    } catch (e) {
      print('Error removing contact from custom list: $e');
      return false;
    }
  }

  /// Clear custom contact list
  static Future<bool> clearCustomContactList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customContactsKey);
      return true;
    } catch (e) {
      print('Error clearing custom contact list: $e');
      return false;
    }
  }

  /// Get primary phone number from contact
  static String? getPrimaryPhoneNumber(Contact contact) {
    if (contact.phones == null || contact.phones!.isEmpty) {
      return null;
    }
    
    // Try to find mobile number first
    final mobile = contact.phones!.firstWhere(
      (phone) => phone.label?.toLowerCase().contains('mobile') == true,
      orElse: () => contact.phones!.first,
    );
    
    return mobile.value;
  }

  /// Format contact name for display
  static String formatContactName(Contact contact) {
    return contact.displayName ?? 'Unknown Contact';
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Format based on length
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '${digits.substring(0, 1)}-${digits.substring(1, 4)}-${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phoneNumber;
  }
} 