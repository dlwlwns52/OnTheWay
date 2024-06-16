
import 'package:flutter/material.dart';
class SchoolEmailDialog extends StatefulWidget {
  final Function(String) onSelected;

  SchoolEmailDialog({required this.onSelected});

  @override
  _SchoolEmailDialogState createState() => _SchoolEmailDialogState();
}

class _SchoolEmailDialogState extends State<SchoolEmailDialog> {
  TextEditingController _searchController = TextEditingController();
  List<String> _domains = [
    '학교 메일 선택',
    'naver.com',
    'edu.hanbat.ac.kr',
    'yahoo.com',
    'aaa.com',
    // Add more domains here
  ];
  List<String> _filteredDomains = [];

  @override
  void initState() {
    super.initState();
    _filteredDomains = _domains;
  }

  void _filterDomains(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDomains = _domains;
      } else {
        _filteredDomains = _domains.where((domain) {
          return domain.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        '본인 학교 웹메일을 선택해주세요.',
        style: TextStyle(
          color: Colors.indigo,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.indigo),
              hintText: '학교를 검색하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.indigo),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.indigo),
              ),
            ),
            onChanged: _filterDomains,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: _filteredDomains.map((String domain) {
                return ListTile(
                  title: Text(domain),
                  onTap: () {
                    widget.onSelected(domain);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('취소', style: TextStyle(color: Colors.indigo)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}