import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dialogflow_grpc/dialogflow_grpc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:sportkit_statistik/Controller/configuration_provider.dart';
import 'package:sportkit_statistik/Views/Screen/subtitution.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:sportkit_statistik/Router/routes_name.dart';
import 'package:sportkit_statistik/Utils/Colors.dart';
import 'package:get/get.dart';
import 'package:sportkit_statistik/Views/Component/reusable_button_calc.dart';
import 'package:dialogflow_grpc/generated/google/cloud/dialogflow/v2beta1/session.pb.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sportkit_statistik/Views/Screen/konfigurasi.dart';
import 'package:sportkit_statistik/Database/db_dialogflow.dart';
import 'package:http/http.dart' as http;
import 'package:pausable_timer/pausable_timer.dart';


import '../../Controller/InputCalc.dart';
import '../../Controller/ViewCalc.dart';
import '../../Controller/buuttonStatus_provider.dart';
import '../../Controller/matchData_provider.dart';
import '../../Controller/timer_provider.dart';
import '../../Controller/userData_provider.dart';
import '../../Models/data_inputConfiguration.dart';
import '../../Models/data_pertandingan.dart';
import '../Component/reusable_button1.dart';



class Kalkulator extends StatefulWidget {
  final Color selectedColor1;
  final Color selectedColor2;
  final Color selectedColor3;
  final Color selectedColor4;
  final String token;
  final MatchData matchData;
  final Map<String, dynamic> data;
  final String id;
  final String selectedDate;
  final List<String> activeTerang;
  final List<String> activeGelap;


  Kalkulator({
    required this.selectedColor1,
    required this.selectedColor2,
    required this.selectedColor3,
    required this.selectedColor4,
    required this.token,
    required this.matchData,
    required this.data,
    required this.id,
    required this.selectedDate,
    required this.activeTerang,
    required this.activeGelap,
  });


  @override
  _KalkulatorState createState() => _KalkulatorState();
}

class _KalkulatorState extends State<Kalkulator> {

  final InputController _inputController = InputController();
  final ViewController v = Get.put(ViewController());
  String selectedOption = 'Q1'; // Nilai awal pilihan waktu timer

  String value1 = '';
  String value2 = '';

  bool _isRecording = false;
  final List<Message> _messages = <Message>[];
  //late List<Widget> widgetsOtherMessage;
  late DialogflowGrpcV2Beta1 dialogflow;
  RecorderStream _recorder = RecorderStream();
  late StreamSubscription _recorderStatus;
  late StreamSubscription<Uint8List> _audioStreamSubscription;
  late BehaviorSubject<Uint8List> _audioStream;
  stt.SpeechToText _speech = stt.SpeechToText();
  StreamSubscription<stt.SpeechResultListener>? _streamSubscription;
  final TextEditingController _textController = TextEditingController();
  String _fulfillmentText = '';

  List<Color> _selectedColors = [
    Colors.blue,
    Colors.white,
    Colors.red,
    Colors.black,
  ];

  void _openInputConfiguration() async {
    List<Color>? newColors = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InputConfiguration(
          initialColors: _selectedColors,
          onColorsChanged: (colors) {
            setState(() {
              _selectedColors = colors;
            });
            Navigator.of(context).pop();
          }, token: widget.token, matchData: widget.matchData, id: '', selectedDate: widget.selectedDate,
        ),
      ),
    );

    if (newColors != null) {
      setState(() {
        _selectedColors = newColors;
      });
    }
  }

  late Timer _timer = Timer(Duration(seconds: 0), () {});
  bool _isActive = false;
  late int _start;

  void _startTimer() {
    if (!_isActive) {
      _isActive = true;
      _timer = Timer.periodic(Duration(seconds: 1), _tick);
    }
  }

  void _tick(Timer timer) {
    if (_start == 0) {
      _resetTimer();
    } else {
      setState(() {
        _start--;
      });
    }
  }

  void _pauseTimer() {
    if (_isActive) {
      _isActive = false;
      setState(() {
        _timer.cancel();
      });
    }
  }

  void _resetTimer() {
    _isActive = false;
    _timer.cancel();
    setState(() {
      //_start = 10 * 60; // Reset waktu ke nilai awal
      _start;
    });
  }

  // StreamController<int> _timerStreamController = StreamController<int>();
  //
  // void _startTimer() {
  //   if (_minutes > 0 || _seconds > 0) {
  //     setState(() {
  //       _isRunning = true;
  //     });
  //
  //     int totalSeconds = _minutes * 60 + _seconds;
  //     _timerStreamController = StreamController<int>();
  //     int remainingSeconds = totalSeconds; // Initialize remainingSeconds
  //
  //     Stream<int> countdownStream = Stream.periodic(
  //       Duration(seconds: 1),
  //           (x) {
  //         remainingSeconds -= 1; // Decrement remainingSeconds
  //         return remainingSeconds;
  //       },
  //     ).takeWhile((count) => count >= 0);
  //
  //     countdownStream.listen((remainingSeconds) {
  //       _timerStreamController.sink.add(remainingSeconds);
  //       if (remainingSeconds <= 0) {
  //         _pauseTimer(); // Call this to stop the timer when it reaches 0.
  //       }
  //     });
  //   }
  // }
  //
  //
  // void _pauseTimer() {
  //   setState(() {
  //     _isRunning = false;
  //   });
  //   _timerSubscription.cancel();
  // }
  //
  // void _resetTimer() {
  //   setState(() {
  //     _isRunning = false;
  //     _minutes = 0;
  //     _seconds = 0;
  //   });
  //   _timerSubscription.cancel();
  // }


  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // String _formatTime() {
  //   return '$_minutes:${_seconds.toString().padLeft(2, '0')}';
  // }

  TextEditingController _minutesController = TextEditingController();
  TextEditingController _secondsController = TextEditingController();

  int _minutes = 0;
  int _seconds = 0;

  bool _isRunning = false;
  late Stream<int> _timerStream;
  late StreamSubscription<int> _timerSubscription;

  Future<void> _showPickerDialog(BuildContext context) async {
    final selectedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Minutes'),
                      onChanged: (value) {
                        _minutes = int.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                  Text(':', style: TextStyle(fontSize: 24)),
                  Expanded(
                    child: TextFormField(
                      controller: _secondsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Seconds'),
                      onChanged: (value) {
                        _seconds = int.tryParse(value) ?? 0;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Set'),
              onPressed: () {
                Navigator.of(context).pop(TimeOfDay(
                  hour: _minutes,
                  minute: _seconds,
                ));
              },
            ),
          ],
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _minutes = selectedTime.hour;
        _seconds = selectedTime.minute;
        _start = (_minutes * 60) + _seconds;
      });
    }
  }



  late String token;
  late String id;
  late MatchData matchData;
  //MatchData matchData = MatchData(id: '', waktu: '', venue: '', terang: '', gelap: '', KU: '', pool: '', terangPemain: '', gelapPemain: '', terangId: '', gelapId: '', tanggalPlain: '', tanggal: '', jam: '');

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlugin();
    initializeToken();
    fetchData(widget.selectedDate);
    token = widget.token;
    matchData = widget.matchData;
    id = widget.id;
    fetchDataSubtitution(id);
    final configuration = Provider.of<ConfigurationModel>(context, listen: false);
    _start = configuration.time * 60;
    // int _start = configuration.time;
    // _timerStream = Stream<int>.periodic(
    //   Duration(seconds: 1),
    //       (x) => _minutes * 60 + _seconds - x - 1,
    // ).takeWhile((count) => count > 0);
    // _timerSubscription = _timerStream.listen((remainingSeconds) {
    //   setState(() {
    //     if (remainingSeconds <= 0) {
    //       _isRunning = false;
    //     }
    //   });
    // });
  }

  List<String> selectedValues2 = [];
  String _handleButtonPress(String newValue) {
    // setState(() {
    //   value1 = newValue;
    // });
    setState(() {
      if (selectedValues2.contains(newValue)) {
        selectedValues2.remove(newValue);
      } else {
        selectedValues2.add(newValue);
        value1 = newValue;
      }
    });
    return newValue;
  }

  List<String> selectedValues = [];
  String _handleButtonPressNumber(String value) {
    // setState(() {
    //   value2 = newValue;
    // });
    // return newValue;
    setState(() {
      if (selectedValues.contains(value)) {
        selectedValues.remove(value);
      } else {
        selectedValues.add(value);
        value2 = value;
      }
    });
    return value;
  }

  void _handleSelection(String value) {
    setState(() {
      selectedOption = value;
      _resetTimer();
    });
  }

  void _handleClearButtonPress() {
    setState(() {
      selectedValues.clear();
      selectedValues2.clear();
      _fulfillmentText = '';
      value1 = '';
      value2 = '';
    });
  }

  bool isOk = false;
  void _handleOkButtonPress() {
    setState(() {
      isOk = true;
      _handleButtonPressNumber(value2);
      _handleButtonPress(value1);
      // if(selectedValues2.contains(selectedValues2) || selectedValues.contains(selectedValues)){
      //   isOk = false;
      //   selectedValues2.remove(selectedValues2);
      //   selectedValues.remove(selectedValues);
      // }
      // selectedValues = selectedValues as List<String>;
      // selectedValues2 = selectedValues2 as List<String>;
    });
    //isOk = false;
    // setState(() {
    //   isOk = true;
    //  // _handleButtonPress(value1);
    // });
    // _handleClearButtonPress();
  }

  // bool isConfigurationDataInputted = false;
  // void _handleConfigurationDataInput() {
  //   setState(() {
  //     isConfigurationDataInputted = true;
  //   });
  // }

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
      //final List<dynamic> responseData = json.decode(response.body);
      //List<Map<String, dynamic>> data = json.decode(responseData);
      ApiResponse apiResponse = ApiResponse.fromJson(_responseData);

      try {
        //print("matchDataList: $responseData");
        matchData = apiResponse.data.firstWhere((data) => data.id == id);

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

  List<dynamic> terangMain = [];
  List<dynamic> gelapMain = [];
  void fetchDataSubtitution(String id) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_pemain.php?event_id=$id&action=subtitution');
    final response = await http.get(url, headers: getHeaders());

    final responseJson = json.decode(response.body);

    // Pastikan respons memiliki status true sebelum melanjutkan
    if (responseJson['status'] == true) {
      final data = responseJson['data'];

      // Parse data pemain terang_main
      //final terangMain= json.decode(data['terang_main']);
      //terangMain = List<int>.from(json.decode(data['terang_main']));

      // Parse data pemain gelap_main
      //final gelapMain = json.decode(data['gelap_main']);

      final terangMainString = data['terang_main'];
      final gelapMainString = data['gelap_main'];

      terangMain = terangMainString.split(',').map((e) => int.parse(e)).toList();
      gelapMain = gelapMainString.split(',').map((e) => int.parse(e)).toList();


      // Sekarang, Anda memiliki data pemain terang_main dan gelap_main dalam bentuk List<int>
      print('Pemain Terang Main: $terangMain');
      print('Pemain Gelap Main: $gelapMain');
    } else {
      // Status false, tangani kesalahan jika diperlukan
      final message = responseJson['message'];
      print('Error: $message');
    }
  }


  Future<void> initPlugin() async {
    _recorderStatus = _recorder.status.listen((status) {
      if (mounted) {
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
      }
    });

    await Future.wait([
      _recorder.initialize()
    ]);

    // TODO Get a Service account
    final serviceAccount = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/credentials.json'))}'
    );

    dialogflow = DialogflowGrpcV2Beta1.viaServiceAccount(serviceAccount);

  }

  @override

  void handleStream() async {

    // final myInstance = recording();
    // myInstance.handleSubmitted();

    bool _isRecording = false;

    bool _isAvailable = await _speech.initialize();
    if (!_isAvailable) {
      print('recording tidak tersedia');
      return;
    }
    else{
      print('recording tersedia');
    }

    final localeId = 'id_ID';
    _streamSubscription = _speech.listen(
      onResult: (result) {
        String transcript = result.recognizedWords;
        _textController.text = transcript;

        if (result.finalResult) {
          handleSubmitted(transcript);
        }
      },
      // onError: (error) {
      //   // Handle error
      // },
      localeId: localeId, // bahasa yang digunakan
      cancelOnError: true, // Optional, cancel listening on error
    ) as StreamSubscription<stt.SpeechResultListener>?;


    // setState(() {
    //   _isListening = true;
    // });
  }

  void stopStream() async {
    await _recorder.stop();
    await _audioStreamSubscription?.cancel();
    await _audioStream?.close();
  }

  void stopListening() {
    _speech.stop();
    _streamSubscription!.cancel();
  }

  void handleSubmitted(text) async {
    print(text);
    _textController.clear();

    //TODO Dialogflow Code


    setState(() {
      _messages.clear(); // Hapus semua pesan sebelumnya
      //_messages.insert(0, message);
    });

    // DetectIntentResponse dataEnglish = await dialogflow.detectIntent(text, 'en-US');
    // String fulfillmentText = dataEnglish.queryResult.fulfillmentText;

    DetectIntentResponse dataIndo = await dialogflow.detectIntent(text, 'id-ID');
    String fulfillmentTextIndo = dataIndo.queryResult.fulfillmentText;

    String? NPStringTerang = matchData.terangPemain; // String dengan angka-angka yang dipisahkan koma
    List<int> dataIntTerang = NPStringTerang!.split(',').map((e) => int.parse(e)).toList();
    print(dataIntTerang);

    String? NPStringGelap = matchData.gelapPemain; // String dengan angka-angka yang dipisahkan koma
    List<int> dataIntGelap = NPStringGelap!.split(',').map((e) => int.parse(e)).toList();

    String messageTerang = '';

    if(fulfillmentTextIndo.isNotEmpty){
      // Message botMessage = Message(
      //   text: fulfillmentTextIndo,
      //   type: false,
      // );
      //
      // setState(() {
      //   _fulfillmentText = fulfillmentTextIndo;
      //   _messages.insert(0, botMessage);
      // });

      for(int i = 0; i<dataIntTerang.length; i ++){
        if(fulfillmentTextIndo == 'Terang ${dataIntTerang[i]} cetak poin 1'){
          messageTerang = '${matchData.terang} #${dataIntTerang[i]} Made +1';
          print(messageTerang);
          Message botMessage = Message(
            text: messageTerang,
            type: false,
          );

          setState(() {
            _fulfillmentText = fulfillmentTextIndo;
            _messages.insert(0, botMessage);
          });
        }
        else if(fulfillmentTextIndo == 'Terang ${dataIntTerang[i]} cetak poin 2'){
          messageTerang = '${matchData.terang} #${dataIntTerang[i]} Made +2';
        }
        else if(fulfillmentTextIndo == 'Terang ${dataIntTerang[i]} cetak poin 3'){
          messageTerang = '${matchData.terang} #${dataIntTerang[i]} Made +3';
        }
        else if(fulfillmentTextIndo == 'Terang ${dataIntTerang[i]} gagal cetak poin 1'){
          messageTerang = '${matchData.terang} #${dataIntTerang[i]} Missed +1';
        }
        else if(fulfillmentTextIndo == 'Terang ${dataIntTerang[i]} gagal cetak poin 2'){
          messageTerang = '${matchData.terang} #${dataIntTerang[i]} Missed +2';
        }
        else if(fulfillmentTextIndo == 'Terang ${dataIntTerang[i]} gagal cetak poin 3'){
          messageTerang = '${matchData.terang} #${dataIntTerang[i]} Missed +3';
        }
        else if(fulfillmentTextIndo == 'Terang ${dataIntTerang[i]} asis'){
          messageTerang = '${matchData.terang} #${dataIntTerang[i]} Assist';
        }
      }


      // Simpan respons ke database
      await DatabaseManager().saveResponseToDatabase(fulfillmentTextIndo);

    }
  }

  // Future<Object> getResponsesFromDatabase() async {
  //   final Database? db = await DatabaseManager().database;
  //   return db?.query('dialogflow_responses') ?? [];
  // }

  @override
  Widget build(BuildContext context) {
    final quarters = Provider.of<ConfigurationDataProvider>(context, listen: false).quarters;
    final period = Provider.of<ConfigurationDataProvider>(context, listen: false).period;
    final overtime = Provider.of<ConfigurationDataProvider>(context, listen: false).overtime;
    final matchTitle = Provider.of<ConfigurationDataProvider>(context, listen: false).MatchTitle;
    final tanggal = Provider.of<ConfigurationDataProvider>(context, listen: false).tanggal;
    final jam = Provider.of<ConfigurationDataProvider>(context, listen: false).jam;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Menggunakan Provider.of untuk mengakses MatchDataProvider
    final matchDataProvider = Provider.of<MatchDataProvider>(context);

    final buttonStatusProvider = Provider.of<ButtonStatusModel>(context);

    final timerProvider = Provider.of<CountdownTimerProvider>(context);
    return Scaffold(
      backgroundColor: SportkitColors.darkBackground,
      appBar:  AppBar(
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
        actions: <Widget>[
          SvgPicture.asset(
            'assets/image/logo-stat.svg',
            width: 434,
            height: 34,
          ),
          Padding(padding: EdgeInsets.all(7)),
          ElevatedButton(
            onPressed: () {
              // Logika ketika tombol play ditekan
            },
            style: ElevatedButton.styleFrom(
              //padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
              primary: SportkitColors.grey, // Warna latar belakang tombol
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Radius border (sesuaikan dengan kebutuhan)
              ),
              padding: EdgeInsets.symmetric(vertical: 1, horizontal: 1),
            ),
            child: const Icon(
              Icons.sort,
              size: 24, // Ukuran ikon
              color: Colors.white, // Warna ikon
            ),
          ),
          Padding(padding: EdgeInsets.all(4)),
          ElevatedButton(
            onPressed: () {
              // Logika ketika tombol play ditekan
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
              primary: SportkitColors.grey, // Warna latar belakang tombol
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Radius border (sesuaikan dengan kebutuhan)
              ),
            ),
            child: const Icon(
              Icons.bar_chart,
              size: 24, // Ukuran ikon
              color: Colors.white, // Warna ikon
            ),
          ),
          Padding(padding: EdgeInsets.all(4)),
          ElevatedButton(
            onPressed: () {
              //var matchData = matchDataList;
              String? id = matchData.id ?? '';
              Navigator.push(
                context,
                new MaterialPageRoute(
                  builder: (context) => new InputConfiguration(
                    token: widget.token,
                    matchData: widget.matchData,
                    initialColors: _selectedColors,
                    onColorsChanged: (colors) {
                      setState(() {
                        _selectedColors = colors;
                      });
                      Navigator.of(context).pop();
                    }, id: id!, selectedDate: widget.selectedDate,),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
              primary: SportkitColors.grey, // Warna latar belakang tombol
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Radius border (sesuaikan dengan kebutuhan)
              ),
            ),
            child: const Icon(
              Icons.settings,
              size: 24, // Ukuran ikon
              color: Colors.white, // Warna ikon
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(5.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  PopupMenuButton<String>(
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Q1',
                          child: Text('Q1'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Q2',
                          child: Text('Q2'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Q3',
                          child: Text('Q3'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Q4',
                          child: Text('Q4'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'OT',
                          child: Text('OT'),
                        ),
                      ];
                    },
                    onSelected: _handleSelection,
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: SportkitColors.yellow,
                        borderRadius: BorderRadius.circular(4), // Memberikan border radius
                      ),
                      child: Center(
                        child: Text(
                          selectedOption,
                          style: TextStyle(color: SportkitColors.black),
                        ),
                      ),// Ganti warna latar belakang bagian depan
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: SportkitColors.black,
                            borderRadius: BorderRadius.circular(4)
                        ),
                        // child: Text(
                        //   _formatTime(_start!),
                        //   //'${_formatTime(10)}',
                        //   style: TextStyle(
                        //     color: SportkitColors.lightGreen,
                        //     fontSize: 20,
                        //   ),
                        // ),
                        child: GestureDetector(
                          onTap: () {
                            _showPickerDialog(context);
                          },
                          child: Text(
                            _formatTime(_start),
                            style: TextStyle(fontSize: 24, color: SportkitColors.lightGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isActive ? _pauseTimer : _startTimer,
                    // onPressed: () {
                    //   if (timerProvider.isActive) {
                    //     timerProvider.pauseTimer();
                    //   } else {
                    //     timerProvider.startTimer(10);
                    //   }
                    //},
                    child: Icon(
                      _isActive ? Icons.pause : Icons.play_arrow,
                      //timerProvider.isActive ? Icons.pause : Icons.play_arrow,
                      size: 25, // Ukuran ikon
                      color: Colors.white, // Warna ikon
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: SportkitColors.green, // Warna latar belakang tombol
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4), // Radius border (sesuaikan dengan kebutuhan)
                      ),
                    ),
                    // child: Padding(
                    //   padding: EdgeInsets.all(1),
                    //
                    // ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Subtitution(token: widget.token, matchData: widget.matchData, id: widget.id, selectedDate: widget.selectedDate,),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: SportkitColors.yellow, // Warna latar belakang tombol
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4), // Radius border (sesuaikan dengan kebutuhan)
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(1),
                      child: Icon(
                        Icons.sync_alt,
                        size: 30, // Ukuran ikon
                        color: Colors.white, // Warna ikon
                      ),
                    ),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.all(3)),
              //Screen
              Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: 110,
                    width: 657,
                    decoration: BoxDecoration(
                      color: SportkitColors.lightBackground, borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Positioned(
                    // Letakkan Text widget untuk menampilkan hasil dari fungsi handleSubmitted
                    top: 0,
                    left: 0,
                    child: Text(
                      _fulfillmentText, // Tampilkan hasil di sini
                      style: TextStyle(fontSize: 20, color: SportkitColors.white),
                    ),
                  ),
                  // ListView.builder(
                  //   itemCount: responses.length,
                  //   itemBuilder: (BuildContext context, int index) {
                  //     return ListTile(
                  //       title: Text(responses[index]),
                  //     );
                  //   },
                  // ),
                  if(isOk) Positioned(
                    child: Column(
                      children: [
                        //Text(selectedOption),
                        Text(selectedValues.join()),
                        Text(selectedValues2.join()),
                      ],
                    ),
                  ) else Container(),
    //if(!isOk) Container(),
                ],
              ),
              // TextField(
              //   controller: v.textEditingController,
              //   decoration: InputDecoration(
              //     fillColor: SportkitColors.black,
              //   ),
              //   enabled: false,
              // ),
              Padding(padding: EdgeInsets.all(4)),
              Container(
                alignment: Alignment.center,
                height: 50,
                width: 657,
                decoration: BoxDecoration(
                  color: SportkitColors.black, borderRadius: BorderRadius.circular(1),
                ),
                child: Text(
                  _handleButtonPressNumber(value2),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Padding(padding: EdgeInsets.all(3)),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SingleChildScrollView(
                    child:  Column(
                      children: [
                          Wrap(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: widget.activeTerang.take(5).map((angka) {
                                  //final angkaStr = angka.toString(); // Ubah angka menjadi String jika diperlukan
                                  return Padding(
                                    padding: EdgeInsets.all(3),
                                    child: ReusableButton1(
                                      text: angka,
                                      onPressed: () => _handleButtonPressNumber(angka),
                                      value: angka,
                                      backgroundColor: widget.selectedColor2,
                                      textColor: widget.selectedColor1,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(2)),
                  SingleChildScrollView(
                    child:  Wrap(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.activeGelap.take(5).map((angka) {
                            //final angkaStr = angka.toString(); // Ubah angka menjadi String jika diperlukan
                            return Padding(
                              padding: EdgeInsets.all(3),
                              child: ReusableButton1(
                                text: angka,
                                onPressed: () => _handleButtonPressNumber(angka),
                                value: angka,
                                backgroundColor: widget.selectedColor4,
                                textColor: widget.selectedColor3,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(3)),
                ],
              ),
              // Padding(padding: EdgeInsets.all(3)),
              Container(
                alignment: Alignment.center,
                height: 50,
                width: 657,
                decoration: BoxDecoration(
                  color: SportkitColors.black, borderRadius: BorderRadius.circular(1),
                ),
                child: Text(
                    _handleButtonPress(value1),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Padding(padding: EdgeInsets.all(3)),
              //Input
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SingleChildScrollView(
                    // scrollDirection: Axis.horizontal,
                    child:  Wrap(
                      children: [
                        ReusableButton(
                          text1: '1',
                          text2: 'Made',
                          // onPressed: () => _handleButtonPress('Made 1'),
                          onPressed: () => _handleButtonPress('Made 1'),
                          value: 'Made 1',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.1,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: '1',
                          text2: 'Missed',
                          // onPressed: () => _handleButtonPress('Missed 1'),
                          onPressed: () => _handleButtonPress('Missed 1'),
                          value: 'Missed 1',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'A',
                          text2: 'Assist',
                          onPressed: () => _handleButtonPress('Assist'),
                          value: 'Assist',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'TO',
                          text2: 'Turn Over',
                          onPressed: () => _handleButtonPress('Turn Over'),
                          value: 'Turn Over',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'P',
                          text2: 'Personal',
                          onPressed: () => _handleButtonPress('Personal'),
                          value: 'Personal Foul',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(3)),
                  SingleChildScrollView(
                    child:  Wrap(
                      children: [
                        ReusableButton(
                          text1: '2',
                          text2: 'Made',
                          onPressed: () => _handleButtonPress('Made 2'),
                          value: 'Made 2',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: '2',
                          text2: 'Missed',
                          onPressed: () => _handleButtonPress('Missed 2'),
                          value: 'Missed 2',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'OR',
                          text2: 'Ofs Rebound',
                          onPressed: () => _handleButtonPress('Ofs Rebound'),
                          value: 'Offensive Rebound',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'B',
                          text2: 'Block',
                          onPressed: () => _handleButtonPress('Block'),
                          value: 'Block',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'T',
                          text2: 'Technical',
                          onPressed: () => _handleButtonPress('Technical Foul'),
                          value: 'Technical Foul',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(3)),
                  SizedBox(
                    child: Wrap(
                      children: [
                        ReusableButton(
                          text1: '3',
                          text2: 'Made',
                          onPressed: () => _handleButtonPress('Made 3'),
                          value: 'Made 3',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: '3',
                          text2: 'Missed',
                          onPressed: () => _handleButtonPress('Missed 3'),
                          value: 'Missed 3',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'DR',
                          text2: 'Dfs Rebound',
                          onPressed: () => _handleButtonPress('DFS Rebound'),
                          value: 'Defensive Rebound',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'S',
                          text2: 'Steal',
                          onPressed: () => _handleButtonPress('Steal'),
                          value: 'Steal',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'U',
                          text2: 'Unsports',
                          onPressed: () => _handleButtonPress('Unsportsmanship Foul'),
                          value: 'Unsportsmanship Foul',
                          // width: 67,
                          // height: 60,
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.all(3)),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child:  Wrap(
                      children: [
                        ReusableButton1(
                          text: 'Clear',
                          onPressed: () => _handleClearButtonPress(),
                          value: 'clear',
                          width: 93,
                          height: 50,
                          backgroundColor: SportkitColors.lightBackground,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton1(
                          text: 'OK',
                          onPressed: _handleOkButtonPress,
                          value: 'ok',
                          width: 80,
                          height: 50,
                          backgroundColor: SportkitColors.lightGreen,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                      ],
                    ),
                  ),
                  // Padding(padding: EdgeInsets.all(1)),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(5),
                          child: FloatingActionButton(
                            onPressed: (){
                              if (!_speech.isListening) {
                                handleStream();
                              } else {
                                stopListening();
                              }
                            },
                            child: Icon(
                              _speech.isListening ? Icons.mic_off : Icons.mic,
                            ),
                          ),
                        ),
                        //Padding(padding: EdgeInsets.all(4)),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.all(3.0), // Set the left margin here
                            child: TextField(
                              style: TextStyle(color: Colors.white),
                              enabled: false,
                              controller: _textController,
                              onSubmitted: handleSubmitted, // Memanggil handleSubmitted pada instance recording
                              decoration: InputDecoration(
                                hintText: "Output Speech To Text",
                                hintStyle: TextStyle(
                                  color: SportkitColors.white, // Ganti warna sesuai yang Anda inginkan
                                ),
                                filled: true, // Mengaktifkan latar belakang terisi
                                fillColor: SportkitColors.lightBackground, // Warna latar belakang
                                border: OutlineInputBorder( // Gaya border
                                  borderSide: BorderSide.none, // Tidak ada border
                                  borderRadius: BorderRadius.circular(18),
                                ),
                            ),

                          ),
                        ),
                        ),
                      ],
                    ),
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

class Message extends StatelessWidget {
  Message({required this.text, required this.type});

  final String text;
  final bool type;

  List<Widget> otherMessage(context) {
    return <Widget>[
      Center(
        child: Container(
          child: Text(
            text,
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: otherMessage(context),
      ),
    );
  }
}