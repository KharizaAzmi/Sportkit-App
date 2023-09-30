import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportkit_statistik/Models/data_tanggal.dart';
import 'package:sportkit_statistik/Views/Screen/kalkulator.dart';
import 'package:sportkit_statistik/Views/Screen/konfigurasi.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:sportkit_statistik/Views/Screen/log.dart';
import 'package:sportkit_statistik/Views/Screen/statistik.dart';

import '../../Controller/user_provider.dart';
import '../../Utils/Colors.dart';
import '../../Models/data_pertandingan.dart';

class HomeStat extends StatefulWidget {
  final String token;
  final MatchData matchData;
  final String id;
  final List<String> activeTerang;
  final List<String> activeGelap;

  HomeStat({required this.token, required this.matchData, required this.id, required this.activeTerang, required this.activeGelap});

  @override
  _HomeStatState createState() => _HomeStatState();
}

class _HomeStatState extends State<HomeStat> {

  List<Color> _selectedColors = [
    Colors.blue,
    Colors.white,
    Colors.red,
    Colors.black,
  ];

  late Kalkulator myKalkulator;
  String selectedValue = '2023-06-25';
  late String token;
  String _id = '';
  late TanggalItem tanggalItem;
  MatchData matchData = MatchData(id: '', waktu: '', venue: '', terang: '', gelap: '', KU: '', pool: '', terangPemain: '', gelapPemain: '', terangId: '', gelapId: '', tanggalPlain: '', tanggal: '', jam: '');

  @override
  void initState() {
    super.initState();
    initializeToken();
    fetchDataTanggal(() {
      fetchData(selectedValue);
    });
    fetchData(selectedValue);
    _id = widget.id;
  }

  void initializeToken() {
    token = widget.token;
  }

  Map<String, String> getHeaders() {
    return {
      'Authorization' : 'Bearer $token',
    };
  }

  List<MatchData> matchDataList = [];
  //late Map<String, dynamic> matchDataList;
  void fetchData(String selectedDate) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_by_tanggal.php?tanggal=$selectedDate');
    final response = await http.get(url, headers: getHeaders());

    //print(response);

    if (response.statusCode == 200) {
      final responseData = response.body;
      final _responseData = json.decode(response.body);

      ApiResponse apiResponse = ApiResponse.fromJson(_responseData);

      for (var matchData in apiResponse.data) {
        _id = matchData.id!;
        print('id: $_id');
        try {
          matchData = apiResponse.data.firstWhere((data) => data.id == _id);

        } catch (e) {
          print("No element found with the specified ID: $_id");
        }
      }

      setState(() {
        matchDataList = (_responseData['data'] as List)
            .map((data) => MatchData.fromJson(data))
            .toList();
      });
      print('Response Data: $responseData');
    } else {
      print('HTTP Request Failed: ${response.statusCode}');
    }
  }

  List<TanggalItem> tanggalList = [];
  List<String> stringTanggalList = [];
  List<dynamic> tanggalData = [];
  Future<void> fetchDataTanggal(Function() callback) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_tanggal.php');
    final response = await http.get(url, headers: getHeaders());

    try {

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);

        tanggalData = data['data'];

        setState(() {
          tanggalList = tanggalData.map((item) => TanggalItem.fromJson(item)).toList();
          print('${tanggalList}');
          for (var tanggalItem in tanggalList) {
            stringTanggalList.add(tanggalItem.waktu);
          }
          print(stringTanggalList);
        });
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  // Metode ini akan dipanggil ketika nilai dropdown berubah.
  void onDropdownChanged(String? newValue) {
    setState(() {
      selectedValue = newValue!;
    });

    fetchData(selectedValue);
  }

  Kalkulator kalkulatorInstance = Kalkulator(
    selectedColor1: Colors.blue,
    selectedColor2: Colors.white,
    selectedColor3: Colors.red,
    selectedColor4: Colors.black,
    token: '',
    matchData: MatchData(id: '', waktu: '', venue: '', terang: '', gelap: '', KU: '', pool: '', terangPemain: '', gelapPemain: '', terangId: '', gelapId: '', tanggalPlain: '', tanggal: '', jam: ''), data: {}, id: '', selectedDate: '', activeTerang: [], activeGelap: [],
  );



  @override
  Widget build(BuildContext context) {
    final id = Provider.of<UserDataProvider>(context, listen: false).id;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SportkitColors.midBackground,
        leading: Padding(padding: EdgeInsets.only(left: 0),),
        actions: [
          SvgPicture.asset(
            'assets/image/logo-stat.svg',
            width: 424,
            height: 34,
          ),
          SizedBox(width: 120,),
          DropdownButton<String>(
            value: selectedValue,
            style: TextStyle(color: Colors.white),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
            elevation: 16,
            dropdownColor: SportkitColors.darkBackground,
            items: stringTanggalList.map((String tanggal) {
              return DropdownMenuItem<String>(
                value: tanggal,
                child: Text(
                  tanggal,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: onDropdownChanged,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: matchDataList.length,
                  itemBuilder: (context, index) {
                    final matchData = matchDataList[index];
                    Color backgroundColor = index.isEven
                        ? SportkitColors.darkBackground
                        : SportkitColors.lightBackground;
                    return Container(
                      width: screenWidth,  // Atur panjang
                      height: 140, // Atur lebar
                      decoration: BoxDecoration(
                        color: backgroundColor,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: screenWidth,
                            height: 140,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 200,
                                      //height: 20,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Text('${matchData.terang ?? ''} vs ${matchData.gelap ?? ''}', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Text('$id'.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            // Navigasi ke layar WebView saat tombol ditekan
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => LogWebView(id: _id,),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            primary: SportkitColors.grey,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          ),
                                          child: const Icon(
                                            Icons.sort,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Navigasi ke layar WebView saat tombol ditekan
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => StatistikWebView(id: _id,),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            primary: SportkitColors.grey,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.bar_chart,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 200,
                                      height: 50,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Text('${matchData.venue ?? ''}', style: TextStyle(fontSize: 12, color: Colors.white)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Text('${matchData.tanggal ?? ''} ' '${matchData.jam ?? ''}', style: TextStyle(fontSize: 12, color: Colors.white)),
                                          ),
                                          // Add more Text widgets to display other data as needed
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            String? id = matchData.id;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => InputConfiguration(
                                                  initialColors: _selectedColors,
                                                  onColorsChanged: (colors) {
                                                    setState(() {
                                                      _selectedColors = colors;
                                                    });
                                                    Navigator.of(context).pop();
                                                  },token: widget.token, matchData: widget.matchData, id: id!, selectedDate: selectedValue,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            primary: SportkitColors.grey,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.settings,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            String? id = matchData.id;
                                            // SchedulerBinding.instance.addPostFrameCallback((_) {
                                            //
                                            // });
                                            final result = Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Kalkulator(
                                                  token: widget.token,
                                                  matchData: widget.matchData,
                                                  selectedColor1: Colors.white,
                                                  selectedColor2: Colors.blue,
                                                  selectedColor3: Colors.red,
                                                  selectedColor4: Colors.black, data: {}, id: id!, selectedDate: selectedValue, activeTerang: widget.activeTerang, activeGelap: widget.activeGelap,
                                                  // onColorsChanged: (colors) {
                                                  //   setState(() {
                                                  //     _selectedColors = colors;
                                                  //   });
                                                  //   Navigator.of(context).pop();
                                                  // },
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            primary: SportkitColors.grey,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: FloatingActionButton(
                backgroundColor: SportkitColors.green,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InputConfiguration(
                        token: widget.token,
                        matchData: widget.matchData,
                        initialColors: _selectedColors,
                        onColorsChanged: (colors) {
                          setState(() {
                            _selectedColors = colors;
                          });
                          Navigator.of(context).pop();
                        }, id: widget.id, selectedDate: '',
                      ),
                    ),
                  );
                },
                child: Icon(Icons.add, size: 35, color: SportkitColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}