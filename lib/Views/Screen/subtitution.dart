import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:date_field/date_field.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sportkit_statistik/Controller/ColorProvider.dart';
import 'package:sportkit_statistik/Models/data_pertandingan.dart';
import 'package:sportkit_statistik/Utils/Colors.dart';
import 'package:sportkit_statistik/Views/Component/reusable_button1.dart';
import 'package:sportkit_statistik/Views/Screen/kalkulator.dart';
import 'package:http/http.dart' as http;

import '../../Controller/buuttonStatus_provider.dart';
import '../../Models/data_subtitution.dart';

class Subtitution extends StatefulWidget {
  // final List<Color> initialColors;
  // final Function(List<Color>) onColorsChanged;
  final String token;
  final MatchData matchData;
  //final Map<String, dynamic> data;
  final String id;
  final String selectedDate;

  Subtitution({required this.token, required this.matchData, required this.id, required this.selectedDate});


  @override
  _SubtitutionState createState() => _SubtitutionState();
}

class _SubtitutionState extends State<Subtitution> {

  late String token;
  late String id;
  late MatchData matchData;
  List<bool> isButtonActiveList = [];
  List<bool> isButtonActiveList2 = [];
  List<String> angkaList = [''];
  List<String> angkaList2 = [''];
  String selectedDate = '2023-06-25';

  @override
  void initState() {
    super.initState();
    initializeToken();
    fetchData(widget.selectedDate);
    token = widget.token;
    matchData = widget.matchData;
    id = widget.id;
    //angkaList = []; // Inisialisasi angkaList dengan daftar kosong
    //isButtonActiveList = []; // Inisialisasi isButtonActiveList dengan daftar kosong
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
  late String? angka;

  void fetchData(String selectedDate) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_by_tanggal.php?tanggal=$selectedDate');
    final response = await http.get(url, headers: getHeaders());

    print(response);

    if (response.statusCode == 200) {
      final responseData = response.body;
      final _responseData = json.decode(response.body);
      //final List<dynamic> responseData = json.decode(response.body);
      //List<Map<String, dynamic>> data = json.decode(responseData);
      ApiResponse apiResponse = ApiResponse.fromJson(_responseData);

      try {
        //print("matchDataList: $responseData");
        matchData = apiResponse.data.firstWhere((data) => data.id == id);

        String deretAngka = '${matchData.terangPemain}';
        angkaList = deretAngka.split(',');
        isButtonActiveList = List.generate(angkaList!.length, (index) => true);

        String deretAngka2 = '${matchData.gelapPemain}';
        angkaList2 = deretAngka2.split(',');
        isButtonActiveList2 = List.generate(angkaList2!.length, (index) => true);

        // Isi formulir dengan data yang sesuai
        // setState(() {
        //   _nameController.text = matchData.terang ?? '';
        //   // Isi formulir dengan data lainnya sesuai kebutuhan
        // });
      } catch (e) {
        // Handle the case where no match was found
        print("No element found with the specified ID: $id");
        // You can assign a default value or take appropriate action here.
      }

      for (var matchData in apiResponse.data) {
        String? id = matchData.id;
        print('id: $id');
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

  Future<void> sendSubtitutionData(SubtitutionData subtitutionData) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/post_subtitution.php');

    // final headers = {
    //   'Content-Type': 'application/json',
    //   //Tambahkan header lain jika diperlukan, seperti token
    // };

    final jsonData = subtitutionData.toJson();
    final requestBody = json.encode(jsonData);

    print('data yang dikirim: $jsonData');

    try {
      final response = await http.post(url, headers: getHeaders(), body: requestBody);

      if (response.statusCode == 200) {
        // Data berhasil dikirim, Anda dapat menangani respons di sini
        final responseData = json.decode(response.body);
        print('Data berhasil dikirim');
        print('Response Data: $responseData');
      } else {
        // Gagal mengirim data ke API
        print('HTTP Request Failed: ${response.statusCode}');
      }
    } catch (error) {
      // Terjadi kesalahan saat mengirim permintaan
      print('Error: $error');
    }
  }


  @override
  Widget build(BuildContext context) {
    final buttonStatusProvider = Provider.of<ButtonStatusModel>(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Subtitution', style: TextStyle(color: Colors.white),),
        backgroundColor: SportkitColors.midBackground,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // Fungsi untuk kembali
          },
          child: const Icon(
            Icons.arrow_back_ios,
            size: 24, // Ukuran ikon
            color: Colors.white, // Warna ikon
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          color: SportkitColors.darkBackground,
          padding: EdgeInsets.only(left: 5, right: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Wrap(
                children: [
                  Padding(padding: EdgeInsets.all(12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${matchData.terang ?? ''} ', style: TextStyle(fontSize: 16, color: SportkitColors.white),),
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4.0,
                    children: angkaList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final angka = entry.value;
                      final isActive = buttonStatusProvider.buttonStatusMap[id] != null ? buttonStatusProvider.buttonStatusMap[id]![index] : false;

                      return Padding(
                        padding: EdgeInsets.all(4),
                        child: ReusableButton1(
                          text: angka,
                          onPressed: () {
                            setState(() {
                              buttonStatusProvider.toggleButton(id, index);
                            });
                          },
                          value: angka,
                          width: 47,
                          height: 47,
                          backgroundColor: !isActive ? Colors.white12 : Colors.white,
                          textColor: !isActive ? Colors.black87 : Colors.blue,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.all(12)),
              Wrap(
                children: [
                  Padding(padding: EdgeInsets.all(12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${matchData.gelap ?? ''} ', style: TextStyle(fontSize: 16, color: SportkitColors.white),),
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4.0,
                    children: angkaList2.asMap().entries.map((entry) {
                      final index = entry.key;
                      final angka = entry.value;
                      final isActive = buttonStatusProvider.buttonStatusMap2[id] != null ? buttonStatusProvider.buttonStatusMap2[id]![index] : false;

                      return Padding(
                        padding: EdgeInsets.all(4),
                        child: ReusableButton1(
                          text: angka,
                          onPressed: () {
                            setState(() {
                              buttonStatusProvider.toggleButton2(id, index);
                            });
                          },
                          value: angka,
                          width: 47,
                          height: 47,
                          backgroundColor: !isActive ? Colors.white12 : Colors.black,
                          textColor: !isActive ? Colors.black87 : Colors.red,
                        ),
                      );
                    }).toList(),
                  )

                ],
              ),
              Padding(padding: EdgeInsets.all(20)),
              ReusableButton1(
                text: 'OK',
                onPressed: (){
                  String? id = matchData.id;
                  //final activeTerang = angkaList.where((button) => isButtonActiveList[angkaList.indexOf(button)]).toList();
                  //final activeTerang = angkaList.asMap().entries.where((entry) => buttonStatusProvider.isButtonActiveList[entry.key]).map((entry) => entry.value).toList();
                  //final activeGelap = angkaList2.asMap().entries.where((entry) => buttonStatusProvider.isButtonActiveList2[entry.key]).map((entry) => entry.value).toList();
                  //final activeGelap = angkaList2.where((button) => isButtonActiveList2[angkaList2.indexOf(button)]).toList();
                  final activeTerang = angkaList.asMap().entries.where((entry) => buttonStatusProvider.buttonStatusMap[id]![entry.key]).map((entry) => entry.value).toList();
                  final activeGelap = angkaList2.asMap().entries.where((entry) => buttonStatusProvider.buttonStatusMap2[id]![entry.key]).map((entry) => entry.value).toList();

                  final subtitutionData = SubtitutionData(
                    eventId: widget.id,
                    minute: '10',
                    quarter: '4',
                    terangMain: activeTerang.map((e) => int.parse(e)).toList(),
                    gelapMain: activeGelap.map((e) => int.parse(e)).toList(),
                    ownerId: 'owner_id',
                  );

                  sendSubtitutionData(subtitutionData);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Kalkulator(
                        token: widget.token,
                        matchData: widget.matchData,
                        selectedColor1: Colors.white,
                        selectedColor2: Colors.blue,
                        selectedColor3: Colors.red,
                        selectedColor4: Colors.black, data: {}, id: widget.id, selectedDate: selectedDate, activeTerang: activeTerang, activeGelap: activeGelap,
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
                value: 'ok',
                width: 100,
                height: 50,
                backgroundColor: SportkitColors.lightGreen,
                textColor: SportkitColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
