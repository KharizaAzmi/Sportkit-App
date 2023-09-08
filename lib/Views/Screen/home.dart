import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportkit_statistik/Views/Screen/kalkulator.dart';
import 'package:sportkit_statistik/Views/Screen/konfigurasi.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../../Controller/user_provider.dart';
import '../../Utils/Colors.dart';
import '../../Models/data_pertandingan.dart';

class HomeStat extends StatefulWidget {
  final String token;
  final MatchData matchData;
  final String id;

  HomeStat({required this.token, required this.matchData, required this.id});

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


  late String token;
  late String _id;
  MatchData matchData = MatchData(id: '', waktu: '', venue: '', terang: '', gelap: '', KU: '', pool: '', terangPemain: '', gelapPemain: '', terangId: '', gelapId: '', tanggalPlain: '', tanggal: '', jam: '');

  @override
  void initState() {
    super.initState();
    initializeToken();
    fetchData();
    //_id = widget.matchData.id!;
    //matchData = widget.matchData;
    //final id = Provider.of<UserDataProvider>(context, listen: false).id;
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
  void fetchData() async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_by_tanggal.php?tanggal=2023-07-05');
    final response = await http.get(url, headers: getHeaders());

    if (response.statusCode == 200) {
      final responseData = response.body;
      final _responseData = json.decode(response.body);
      //final List<dynamic> responseData = json.decode(response.body);
      //List<Map<String, dynamic>> data = json.decode(responseData);
      ApiResponse apiResponse = ApiResponse.fromJson(_responseData);

      for (var matchData in apiResponse.data) {
        String? id = matchData.id;
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

  Kalkulator kalkulatorInstance = Kalkulator(
    selectedColor1: Colors.blue,
    selectedColor2: Colors.white,
    selectedColor3: Colors.red,
    selectedColor4: Colors.black,
    token: '',
    matchData: MatchData(id: '', waktu: '', venue: '', terang: '', gelap: '', KU: '', pool: '', terangPemain: '', gelapPemain: '', terangId: '', gelapId: '', tanggalPlain: '', tanggal: '', jam: ''), data: {}, id: '',
    // ...and so on for selectedColor3 and selectedColor4
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
            'assets/image/logo-stat.svg', // Ganti dengan path gambar SVG Anda
            width: 424, // Lebar gambar
            height: 34, // Tinggi gambar
          ),
          SizedBox(width: 220,),
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
                            // decoration: BoxDecoration(
                            //   color: SportkitColors.darkBackground,
                            // ),
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
                                            // Logika ketika tombol play ditekan
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
                                            //routing ke webview
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
                                                  },token: widget.token, matchData: widget.matchData, id: id!,
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
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => Kalkulator(
                                                  token: widget.token,
                                                  matchData: widget.matchData,
                                                  selectedColor1: Colors.white,
                                                  selectedColor2: Colors.blue,
                                                  selectedColor3: Colors.red,
                                                  selectedColor4: Colors.black, data: {}, id: id!,
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
                        }, id: widget.id,
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