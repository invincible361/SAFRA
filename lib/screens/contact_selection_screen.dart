import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import '../services/contact_service.dart';
import '../l10n/app_localizations.dart';

class ContactSelectionScreen extends StatefulWidget {
  final Function(Contact) onContactSelected;
  final bool showCustomListOnly;

  const ContactSelectionScreen({
    super.key,
    required this.onContactSelected,
    this.showCustomListOnly = false,
  });

  @override
  State<ContactSelectionScreen> createState() => _ContactSelectionScreenState();
}

class _ContactSelectionScreenState extends State<ContactSelectionScreen> {
  List<Contact> _allContacts = [];
  List<Contact> _customContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.showCustomListOnly) {
        _customContacts = await ContactService.loadCustomContactList();
        _filteredContacts = List.from(_customContacts);
      } else {
        _allContacts = await ContactService.getContactsWithPhone();
        _customContacts = await ContactService.loadCustomContactList();
        _filteredContacts = List.from(_allContacts);
      }
    } catch (e) {
      print('Error loading contacts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading contacts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredContacts = widget.showCustomListOnly
            ? List.from(_customContacts)
            : List.from(_allContacts);
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    final filtered = (widget.showCustomListOnly ? _customContacts : _allContacts)
        .where((contact) {
      if (contact.displayName?.toLowerCase().contains(lowercaseQuery) == true) {
        return true;
      }
      for (final phone in contact.phones!) {
        if (phone.value?.toLowerCase().contains(lowercaseQuery) == true) {
          return true;
        }
      }
      return false;
    }).toList();

    setState(() {
      _filteredContacts = filtered;
    });
  }

  Future<void> _addToCustomList(Contact contact) async {
    final success = await ContactService.addContactToCustomList(contact);
    if (success) {
      _customContacts = await ContactService.loadCustomContactList();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${contact.displayName} added to favorites'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeFromCustomList(Contact contact) async {
    final success = await ContactService.removeContactFromCustomList(contact.displayName!);
    if (success) {
      _customContacts = await ContactService.loadCustomContactList();
      if (widget.showCustomListOnly) {
        _filteredContacts = List.from(_customContacts);
      }
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${contact.displayName} removed from favorites'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  bool _isInCustomList(Contact contact) {
    return _customContacts.any((c) => c.displayName == contact.displayName);
  }

  Widget _buildContactTile(Contact contact) {
    final isInCustomList = _isInCustomList(contact);
    final primaryPhone = ContactService.getPrimaryPhoneNumber(contact);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            ContactService.formatContactName(contact).substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          ContactService.formatContactName(contact),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: primaryPhone != null
            ? Text(
          ContactService.formatPhoneNumber(primaryPhone),
          style: const TextStyle(color: Colors.white70),
        )
            : const Text('No phone number', style: TextStyle(color: Colors.redAccent)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.showCustomListOnly)
              IconButton(
                onPressed: () {
                  if (isInCustomList) {
                    _removeFromCustomList(contact);
                  } else {
                    _addToCustomList(contact);
                  }
                },
                icon: Icon(
                  isInCustomList ? Icons.favorite : Icons.favorite_border,
                  color: isInCustomList ? Colors.red : Colors.white70,
                ),
              ),
            IconButton(
              onPressed: () => widget.onContactSelected(contact),
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              tooltip: 'Send location',
            ),
          ],
        ),
        onTap: () => widget.onContactSelected(contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(
          widget.showCustomListOnly
              ? (localizations?.favoriteContacts ?? 'Favorite Contacts')
              : (localizations?.selectContact ?? 'Select Contact'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          if (!widget.showCustomListOnly)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactSelectionScreen(
                      onContactSelected: widget.onContactSelected,
                      showCustomListOnly: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.favorite, color: Colors.redAccent),
              tooltip: 'Show favorites',
            ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Modern search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filterContacts,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: localizations?.searchContacts ?? 'Search contacts...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _isSearching
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterContacts('');
                  },
                  icon: const Icon(Icons.clear, color: Colors.white70),
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📞 Contact list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredContacts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.people_outline,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? (localizations?.noContactsFound ?? 'No contacts found')
                        : (localizations?.noContactsAvailable ?? 'No contacts available'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                return _buildContactTile(_filteredContacts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
