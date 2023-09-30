import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:date_field/date_field.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sportkit_statistik/Utils/Colors.dart';
import 'package:sportkit_statistik/Views/Screen/kalkulator.dart';
import 'package:http/http.dart' as http;

import '../../Controller/timer_provider.dart';
import '../../Models/data_inputConfiguration.dart';
import '../../Models/data_pertandingan.dart';

class InputConfiguration extends StatefulWidget {
  final List<Color> initialColors;
  final Function(List<Color>) onColorsChanged;

  final String token;
  final MatchData matchData;
  final String id;
  final String selectedDate;

  InputConfiguration({
    required this.initialColors,
    required this.onColorsChanged,
    required this.token,
    required this.matchData,
    required this.id,
    required this.selectedDate,
  });


  @override
  _InputConfigurationState createState() => _InputConfigurationState();
}

class _InputConfigurationState extends State<InputConfiguration> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _jerseyController = TextEditingController();
  TextEditingController _colorsController = TextEditingController();
  TextEditingController _nameController2 = TextEditingController();
  TextEditingController _jerseyController2 = TextEditingController();
  TextEditingController _colorsController2 = TextEditingController();
  TextEditingController _quarterController = TextEditingController();
  TextEditingController _periodtimesController = TextEditingController();
  TextEditingController _timesController = TextEditingController();
  TextEditingController _matchController = TextEditingController();
  TextEditingController _venueController = TextEditingController();
  TextEditingController _dateTextController = TextEditingController();
  DateTime? _selectedDate;

  TimeOfDay _selectedtime = TimeOfDay(hour: 7, minute: 15);

  Color _selectedColor1 = Colors.blue;
  Color _selectedColor2 = Colors.white;
  Color _selectedColor3 = Colors.red;
  Color _selectedColor4 = Colors.black;

  void _selectTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _selectedtime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (newTime != null) {
      setState(() {
        _selectedtime = newTime;
      });
    }
  }

  void _openColorPickerDialogs(List<Color> initialColors, Function(List<Color>) onColorsChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Color> _tempColors = List.from(initialColors);
        //List<Color> _tempColors = initialColors;
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ColorPicker(
                  pickerColor: _tempColors[0],
                  onColorChanged: (color) {
                    _tempColors[0] = color;
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
                SizedBox(height: 20),
                ColorPicker(
                  pickerColor: _tempColors[1],
                  onColorChanged: (color) {
                    _tempColors[1] = color;
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
                // ... Repeat for other color pickers
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onColorsChanged(_tempColors);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openColorPickerDialog(Color initialColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color _tempColor = initialColor;
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _tempColor,
              onColorChanged: (color) {
                _tempColor = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onColorChanged(_tempColor);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  late String token;
  late String id;
  late MatchData matchData;
  String selectedDate = '2023-06-25';

  @override
  void initState() {
    super.initState();
    token = widget.token;
    matchData = widget.matchData;
    id = widget.id;
    initializeToken();
    fetchData(widget.selectedDate);
    _quarterController.text = "4";
    _periodtimesController.text = "10";
    _timesController.text = "5";
  }

  void initializeToken() {
    setState(() {
      token = widget.token;
    });
  }

  Map<String, String> getHeaders() {
    return {
      'Authorization' : 'Bearer $token',
    };
  }

  int? intValue;

  late final responseData;
  List<MatchData> matchDataList = [];
  void fetchData(String selectedDate) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_by_tanggal.php?tanggal=$selectedDate');
    final response = await http.get(url, headers: getHeaders());

    print('$token');
    print('tanggal yang di select: $selectedDate');


    if (response.statusCode == 200) {
      responseData = response.body;
      final _responseData = json.decode(response.body);
      print('Response Data: $responseData');

      ApiResponse apiResponse = ApiResponse.fromJson(_responseData);
      MatchData match = apiResponse.data.isNotEmpty ? apiResponse.data[0] : matchData;

      try {
        //print("matchDataList: $responseData");
        matchData = apiResponse.data.firstWhere((data) => data.id == id);


        setState(() {
          _nameController.text = matchData.terang ?? '';
          _jerseyController.text = matchData.terangPemain ?? '';
          _nameController2.text = matchData.gelap ?? '';
          _jerseyController2.text = matchData.gelapPemain ?? '';
          _venueController.text = matchData.venue ?? '';

          String dateStr = matchData.tanggal ?? '';
          print('$dateStr');
          _selectedDate = DateFormat('dd/MM/yyyy').parse(dateStr);

          String timeStr = matchData.jam ?? '';

          List<String> timeParts = timeStr.split(':');
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          _selectedtime = TimeOfDay(hour: hour, minute: minute);

          String inputPeriods = _periodtimesController.text;
          if (int.tryParse(inputPeriods) != null) {
            intValue = int.parse(inputPeriods);
          } else {
            print('Input tidak valid');
          }

        });
      } catch (e) {
        print("No element found with the specified ID: $id");
      }

      setState(() {
        matchDataList = apiResponse.data;
      });

      setState(() {
        matchDataList = (_responseData['data'] as List)
            .map((data) => MatchData.fromJson(data))
            .toList();
      });

    } else {
      print('HTTP Request Failed: ${response.statusCode}');
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    _nameController2.dispose();
    _jerseyController2.dispose();
    _quarterController.dispose();
    _timesController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configuration = Provider.of<ConfigurationModel>(context);
    final timerProvider = Provider.of<CountdownTimerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration', style: TextStyle(color: Colors.white),),
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
          color: SportkitColors.darkBackground,
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TEAM #1', style: TextStyle(fontSize: 16, color: Colors.white)),
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Name', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jersey #', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _jerseyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BG/FG Colors', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _openColorPickerDialog(_selectedColor1, (color) {
                              setState(() {
                                _selectedColor1 = color;
                              });
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            color: _selectedColor1,
                          ),
                        ),
                        SizedBox(width: 20,),
                        GestureDetector(
                          onTap: () {
                            _openColorPickerDialog(_selectedColor2, (color) {
                              setState(() {
                                _selectedColor2 = color;
                              });
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            color: _selectedColor2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Divider( // Garis pembatas
                color: Colors.white,
                thickness: 0.3, // Ketebalan garis
                indent: 0.3, // Jarak dari kiri
                endIndent: 1, // Jarak dari kanan
              ),
              Text('TEAM #2', style: TextStyle(fontSize: 16, color: Colors.white)),
              SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Name', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _nameController2,
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jersey #', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _jerseyController2,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BG/FG Colors', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _openColorPickerDialog(_selectedColor3, (color) {
                              setState(() {
                                _selectedColor3 = color;
                              });
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            color: _selectedColor3,
                          ),
                        ),
                        SizedBox(width: 20,),
                        GestureDetector(
                          onTap: () {
                            _openColorPickerDialog(_selectedColor4, (color) {
                              setState(() {
                                _selectedColor4 = color;
                              });
                            });
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            color: _selectedColor4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Divider( // Garis pembatas
                color: Colors.white,
                thickness: 0.3, // Ketebalan garis
                indent: 0.3, // Jarak dari kiri
                endIndent: 1, // Jarak dari kanan
              ),
              SizedBox(height: 10,),
              Row(
                children: [
                  Text('Number of periods/quarters', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _quarterController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Hanya menerima angka
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                children: [
                  Text('Period/quarter length (mins)', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _periodtimesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Hanya menerima angka
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                children: [
                  Text('Overtime length (mins)', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _timesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Hanya menerima angka
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Match Title', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _matchController,
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Venue', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _venueController,
                        decoration: InputDecoration(
                          hintText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                children: [
                  Text('Date/Time', style: TextStyle(fontSize: 16, color: Colors.white)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DateTimeFormField(
                            decoration: InputDecoration(
                              //labelText: '',
                              border: InputBorder.none,
                            ),
                            mode: DateTimeFieldPickerMode.date,
                            autovalidateMode: AutovalidateMode.always,
                            onDateSelected: (DateTime value) {
                              setState(() {
                                _selectedDate = value;
                              });
                            },
                            dateFormat: DateFormat('dd/MM/yyyy'), // Format tanggal yang diinginkan
                            initialDate: _selectedDate,
                            initialValue: _selectedDate,
                            onSaved: (DateTime? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDate = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0,),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Padding(padding: EdgeInsets.only(left: 18)),
                        Text(
                          '${_selectedtime.hour.toString().padLeft(2, '0')}:${_selectedtime.minute.toString().padLeft(2, '0')}',
                        ),
                        IconButton(
                          onPressed: _selectTime,
                          icon: Icon(Icons.arrow_drop_down_sharp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
// Mengisi data dalam configurationModel menggunakan TextEditingController
                      bool isButtonClicked = false;
                      setState(() {
                        isButtonClicked = !isButtonClicked;
                      });

                      String name = _nameController.text;
                      String jersey = _jerseyController.text;
                      String colors = _colorsController.text;
                      String name2 = _nameController2.text;
                      String jersey2 = _jerseyController2.text;
                      String colors2 = _colorsController2.text;
                      String periods = _periodtimesController.text;
                      //int time = int.tryParse(configuration.periodtimesController.text) ?? 0;
                      int? time = int.tryParse(periods);
                      // print('Name $name');
                      // print('Jersey # $jersey');
                      // print('BG/FG Colors $colors');
                      configuration.updateData(name, jersey, colors, name2, jersey2, colors2, time!);

                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Kalkulator(
                            selectedColor1: _selectedColor1,
                            selectedColor2: _selectedColor2,
                            selectedColor3: _selectedColor3,
                            selectedColor4: _selectedColor4,
                            token: token,
                            matchData: matchData,
                            data: configuration.configurationData,
                            id: widget.id!,
                            selectedDate: selectedDate,
                            activeTerang: [],
                            activeGelap: [],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 60),
                      primary: SportkitColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text('Save', style: TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
