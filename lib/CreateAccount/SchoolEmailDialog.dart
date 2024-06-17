import 'package:flutter/material.dart';

class SchoolEmailDialog extends StatefulWidget {
  final Function(String) onSelected;

  SchoolEmailDialog({required this.onSelected});

  @override
  _SchoolEmailDialogState createState() => _SchoolEmailDialogState();
}

class _SchoolEmailDialogState extends State<SchoolEmailDialog> {
  TextEditingController _searchController = TextEditingController();


  List<Map<String, String>> _domains = [
    {'name': '전북대학교', 'domain': 'jbnu.ac.kr'},
    {'name': '충남대학교', 'domain': 'cnu.ac.kr'},
    {'name': '한밭대학교', 'domain': 'edu.hanbat.ac.kr'},

    // 도메인 추가
  ];

  List<Map<String, String>> _filteredDomains = [];

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
          return domain['name']!.toLowerCase().contains(query.toLowerCase()) ||
              domain['domain']!.toLowerCase().contains(query.toLowerCase());
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
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
                hintText: '학교 메일을 검색하세요',
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
            Container(
              height: 200,
              child: ListView(
                shrinkWrap: true,
                children: _filteredDomains.map((domain) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        domain['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        domain['domain']!,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      trailing: Icon(
                        Icons.check,
                        color: Colors.indigo,
                        size: 16.0,
                      ),
                      onTap: () {
                        widget.onSelected(domain['domain']!);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('취소', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16),),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
