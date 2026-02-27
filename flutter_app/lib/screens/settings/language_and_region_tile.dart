import 'package:flutter/material.dart';

class LanguageAndRegionTile extends StatefulWidget {
  final String selectedLanguage;
  final String selectedRegion;

  const LanguageAndRegionTile({
    super.key,
    required this.selectedLanguage,
    required this.selectedRegion,
  });

  @override
  State<LanguageAndRegionTile> createState() => _LanguageAndRegionTileState();
}

class _LanguageAndRegionTileState extends State<LanguageAndRegionTile> {
  late String _selectedLanguage;
  late String _selectedRegion;
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  final List<String> _regions = [
    'United States',
    'Canada',
    'Mexico',
    'Germany'
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _selectedRegion = widget.selectedRegion;
  }

  void _showLanguageDialog() async {
    final String? selectedLanguage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Language'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value: _selectedLanguage,
                items: _languages.map((String language) {
                  return DropdownMenuItem<String>(
                    value: language,
                    child: Text(language),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                  });
                  Navigator.of(context)
                      .pop(newValue); // Return the selected language
                },
              );
            },
          ),
        );
      },
    );

    if (selectedLanguage != null) {
      setState(() {
        _selectedLanguage =
            selectedLanguage; // Update the selected language in the state
      });
    }
  }

  void _showRegionDialog() async {
    final String? selectedRegion = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Region'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value:
                    _regions.contains(_selectedRegion) ? _selectedRegion : null,
                items: _regions.map((String region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Text(region),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRegion = newValue!;
                  });
                  Navigator.of(context)
                      .pop(newValue); // Return the selected region
                },
              );
            },
          ),
        );
      },
    );

    if (selectedRegion != null) {
      setState(() {
        _selectedRegion =
            selectedRegion; // Update the selected region in the state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Language and Region',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: const Icon(Icons.language),
      initiallyExpanded: false,
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(_selectedLanguage),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showLanguageDialog, // Show the language dialog
          ),
        ),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text(_selectedRegion),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showRegionDialog, // Show the region dialog
          ),
        ),
      ],
    );
  }
}
