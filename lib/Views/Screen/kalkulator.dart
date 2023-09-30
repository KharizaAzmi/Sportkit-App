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
import 'package:sportkit_statistik/Controller/subtitution_provider.dart';
import 'package:sportkit_statistik/Views/Screen/log.dart';
import 'package:sportkit_statistik/Views/Screen/statistik.dart';
import 'package:sportkit_statistik/Views/Screen/subtitution.dart';
import 'package:sportkit_statistik/Utils/Colors.dart';
import 'package:get/get.dart';
import 'package:sportkit_statistik/Views/Component/reusable_button_calc.dart';
import 'package:dialogflow_grpc/generated/google/cloud/dialogflow/v2beta1/session.pb.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sportkit_statistik/Views/Screen/konfigurasi.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

import '../../Controller/ViewCalc.dart';
import '../../Controller/buuttonStatus_provider.dart';
import '../../Controller/matchData_provider.dart';
import '../../Controller/timer_provider.dart';
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

  //final InputController _inputController = InputController();
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

  void updateButtonState() {
    setState(() {
      // Lakukan perubahan pada state tombol di sini
    });
  }

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
      // _runningMinutes = _minutes;
      // _runningSeconds = _seconds;
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


  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // String _formatTime(int minutes, int seconds) {
  //   return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
    sendDataToAPI();
    fetchData(widget.selectedDate);
    token = widget.token;
    matchData = widget.matchData;
    id = widget.id;
    fetchDataSubtitution(id);
    buildButtons();
    final configuration = Provider.of<ConfigurationModel>(context, listen: false);
    _start = configuration.time * 60;
  }

  List<String> selectedValues2 = [];
  String _handleButtonPress(String newValue) {
    // setState(() {
    //   value1 = newValue;
    // });
    setState(() {
      if (selectedValues2.contains(newValue) && selectedValues2.isNotEmpty) {
        selectedValues2.clear();
        selectedValues2.remove(newValue);
        //selectedValues2.removeAt(0);
      } else {
        //selectedValues2.clear();
        selectedValues2.add(newValue);
        value1 = newValue;
      }
    });
    return newValue;
  }

  List<String> selectedValues = [];

  String combinedValue = '';
  String? gelapTerang1;
  String? namaTim;
  void _handleButtonPressNumber(String value, String gelapTerang) {

    gelapTerang1 = gelapTerang;
    namaTim = (gelapTerang == 'terang') ? '${matchData.terang}' : '${matchData.gelap}';
    combinedValue = '$namaTim #$value';

    setState(() {
      if (selectedValues.contains(combinedValue)) {
        selectedValues.clear();
        selectedValues.remove(combinedValue);
      } else {
        //selectedValues.clear();
        selectedValues.add(combinedValue);
        value2 = value;
      }
    });
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
      combinedValue = '';
      value1 = '';
      value2 = '';
    });
  }

  bool isOk = false;

  DateTime? timestamp;
  int startMinutes = 0;
  int startSeconds = 0;
  int elapsedMinutes = 0;
  int elapsedSeconds = 0;
  int _lastElapsedTime = 0;
  String option = '';

  void _handleOkButtonPress() {

    option = selectedOption;

    setState(() {
      if (!isOk) {
        // Tombol OK ditekan pertama kali
        startMinutes = _minutes;
        startSeconds = _seconds;
        //isOk = true;
        //isOk = false;
      }
      // else {
      //   // Tombol OK ditekan lagi
      //   //_pauseTimer(); // Hentikan timer
      //   int elapsedSeconds = (startMinutes - _minutes) * 60 + (startSeconds - _seconds);
      //   isOk = false;
      //   String formattedTime = _formatTime(elapsedSeconds);
      //   print('Selisih waktu: $formattedTime');
      // }

      isOk = true;
      // _handleButtonPressNumber;
      // _handleButtonPress;
      // _handleSelection;
      _lastElapsedTime = _start;
      sendDataToAPI();

      // if(selectedValues.isNotEmpty || selectedValues2.isNotEmpty) {
      //   //isOk = false;
      //   nomor = '';
      //   action = '';
      //   quarter = '';
      //   klub = '';
      // }
      if(!isOk){
        if(selectedValues.isNotEmpty || selectedValues2.isNotEmpty) {
          // selectedValues2.clear();
          // selectedValues.clear();
          Timer(Duration(seconds: 3), () {
            setState(() {
              isOk = false;
              value1 = '';
              value2 = '';
              combinedValue = '';
              selectedValues.clear();
              selectedValues2.clear();
              _lastElapsedTime = 0;
              option = '';
            });
          });
        }
      }
      if(!isOk) {
        print('Selisih waktu: ${_formatTime(elapsedMinutes)}');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data terkirim'),
        duration: Duration(seconds: 2), // Durasi tampilan Snackbar
      ),
    );
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

  void fetchData(String selectedDate) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_by_tanggal.php?tanggal=$selectedDate');
    final response = await http.get(url, headers: getHeaders());


    if (response.statusCode == 200) {
      final responseData = response.body;
      final _responseData = json.decode(response.body);

      ApiResponse apiResponse = ApiResponse.fromJson(_responseData);

      try {
        //print("matchDataList: $responseData");
        matchData = apiResponse.data.firstWhere((data) => data.id == id);

      } catch (e) {
        print("No element found with the specified ID: $id");
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
  Future<dynamic> fetchDataSubtitution(String id) async {
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/list_pemain.php?event_id=$id&action=subtitution');
    final response = await http.get(url, headers: getHeaders());

    final responseJson = json.decode(response.body);

    if (responseJson['status'] == true) {
      final data = responseJson['data'];

      final terangMainString = data['terang_main'];
      final gelapMainString = data['gelap_main'];


      terangMain = terangMainString.split(',').toList();
      gelapMain = gelapMainString.split(',').toList();

      print('Pemain Terang Main: $terangMain');
      print('Pemain Gelap Main: $gelapMain');
    } else {
      final message = responseJson['message'];
      print('Error: $message');
    }
    return;
  }

  int minutes = 0;
  int remainingSeconds = 0;

  String nomor = '';
  String action = '';
  String klub = '';
  String quarter = '';

  void sendDataToAPI() async {
    final String apiUrl = 'https://sportkit.id/friendship/api/v1/post_score.php';

    final uuid = Uuid();
    final uniqueId = uuid.v4();

    minutes = _lastElapsedTime ~/ 60;
    remainingSeconds = _lastElapsedTime % 60;

    nomor = value2;
    action = value1;
    klub = namaTim!;
    quarter = selectedOption;

    // Data yang akan dikirim dalam format JSON
    if (widget.id != null &&
        widget.id.isNotEmpty &&
        gelapTerang1 != null &&
        gelapTerang1!.isNotEmpty &&
        namaTim != null &&
        namaTim!.isNotEmpty &&
        value2 != null &&
        value2.isNotEmpty &&
        value1 != null &&
        value1.isNotEmpty &&
        selectedOption != null &&
        selectedOption!.isNotEmpty &&
        uniqueId != null &&
        uniqueId.isNotEmpty) {
      final Map<String, dynamic> postData = {
        "event_id": widget.id,
        "tim": gelapTerang1,
        "klub": klub,
        "nomor": nomor,
        "action": action,
        "minute": '$minutes:${remainingSeconds.toString().padLeft(2, '0')}',
        "quarter": quarter,
        "uniqid": uniqueId,
        "insert_time": DateTime.now().toString(),
        "owner_id": "owner_id_value",
      };

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: getHeaders(),
          body: jsonEncode(postData),
        );

        if (response.statusCode == 200) {
          // Permintaan berhasil
          print("Data berhasil dikirim ke API");
          print(postData);
        } else {
          // Permintaan gagal
          print("Gagal mengirim data ke API: ${response.statusCode}");
        }
      } catch (error) {
        print("Terjadi kesalahan saat mengirim data ke API: $error");
      }
    } else {
      print("Terdapat nilai yang null atau kosong (''). Data tidak dikirim.");
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
      localeId: localeId, // bahasa yang digunakan
      cancelOnError: true, // Optional, cancel listening on error
    ) as StreamSubscription<stt.SpeechResultListener>?;

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
      _messages.clear();
    });

    DetectIntentResponse dataIndo = await dialogflow.detectIntent(text, 'id-ID');
    String fulfillmentTextIndo = dataIndo.queryResult.fulfillmentText;

    List<String> parts = fulfillmentTextIndo.split(' ');
    value2 = parts[1];
    gelapTerang1 = parts[0];

    int minutes = _start ~/ 60;
    int remainingSeconds = _start % 60;

    String messageTerang = '';
    String messageGelap = '';
    print('teks: $fulfillmentTextIndo');

    Map<String, String> responseMappingTerang = {
      'terang $value2 cetak poin 1': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMade +1',
      'Tim terang $value2, 1 cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMade +1',
      'terang $value2 cetak poin 2': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMade +2',
      'Tim terang $value2, 2 cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMade +2',
      'terang $value2 cetak poin 3': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMade +3',
      'Tim terang $value2, 3 cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMade +3',
      'terang $value2 gagal cetak poin 1': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMissed +1',
      'Tim terang $value2, 1 gagal cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMissed +1',
      'terang $value2 gagal cetak poin 2': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMissed +2',
      'Tim terang $value2, 1 gagal cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMissed +2',
      'terang $value2 gagal cetak poin 3': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMissed +3',
      'Tim terang $value2, 3 gagal cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nMissed +3',
      'Tim terang $value2 rebound Bertahan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nOffensive Rebound',
      'terang $value2 rebound Bertahan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nOffensive Rebound',
      'Tim terang $value2 tidak supportive': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nUnsportmanship Foul',
      'terang $value2 tidak supportive': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nUnsportmanship Foul',
      'Tim terang $value2 tidak suportif': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nUnsportmanship Foul',
      'terang $value2 tidak suportif': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nUnsportmanship Foul',
      'Tim terang $value2 teknikal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nTechnical Foul',
      'terang $value2 teknikal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nTechnical Foul',
      'Tim terang $value2 technical': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nTechnical Foul',
      'terang $value2 technical': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nTechnical Foul',
      'Tim terang $value2 personal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nPersonal Foul',
      'terang $value2 personal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nPersonal Foul',
      'Tim terang $value2 mencuri': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nSteal',
      'terang $value2 mencuri': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nSteal',
      'Tim terang $value2 memblok': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nBlock',
      'terang $value2 memblok': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nBlock',
      'Tim terang $value2 menyerahkan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nTurn Over',
      'terang $value2 menyerahkan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nTurn Over',
      'Tim terang $value2 rebound serangan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nOffensive Rebound',
      'terang $value2 rebound serangan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nOffensive Rebound',
      'Tim terang $value2 asis': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nAssist',
      'terang $value2 asis': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nAssist',
      'Tim terang $value2 bantu': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nAssist',
      'terang $value2 bantu': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.terang} #$value2 \nAssist',
    };

    Map<String, String> responseMappingGelap = {
      'gelap $value2 cetak poin 1': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMade +1',
      'Tim gelap $value2, 1 cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMade +1',
      'gelap $value2 cetak poin 2': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMade +2',
      'Tim gelap $value2, 2 cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMade +2',
      'gelap $value2 cetak poin 3': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMade +3',
      'Tim gelap $value2, 3 cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMade +3',
      'gelap $value2 gagal cetak poin 1': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMissed +1',
      'Tim gelap $value2, 1 gagal cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMissed +1',
      'gelap $value2 gagal cetak poin 2': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMissed +2',
      'Tim gelap $value2, 2 gagal cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMissed +2',
      'gelap $value2 gagal cetak poin 3': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMissed +3',
      'Tim gelap $value2, 3 gagal cetak poin': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nMissed +3',
      'Tim gelap $value2 rebound bertahan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nOffensive Rebound',
      'gelap $value2 rebound bertahan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nOffensive Rebound',
      'Tim gelap $value2 tidak supportive': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nUnsportmanship Foul',
      'gelap $value2 tidak supportive': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nUnsportmanship Foul',
      'Tim gelap $value2 tidak suportif': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nUnsportmanship Foul',
      'gelap $value2 tidak suportif': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nUnsportmanship Foul',
      'Tim gelap $value2 teknikal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nTechnical Foul',
      'gelap $value2 teknikal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nTechnical Foul',
      'Tim gelap $value2 technical': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nTechnical Foul',
      'gelap $value2 technical': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nTechnical Foul',
      'Tim gelap $value2 personal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nPersonal Foul',
      'gelap $value2 personal': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nPersonal Foul',
      'Tim gelap $value2 mencuri': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nSteal',
      'gelap $value2 mencuri': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nSteal',
      'Tim gelap $value2 memblok': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nBlock',
      'gelap $value2 memblok': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nBlock',
      'Tim gelap $value2 menyerahkan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nTurn Over',
      'gelap $value2 menyerahkan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nTurn Over',
      'Tim gelap $value2 rebound serangan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nOffensive Rebound',
      'gelap $value2 rebound serangan': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nOffensive Rebound',
      'Tim gelap $value2 asis': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nAssist',
      'gelap $value2 asis': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nAssist',
      'Tim gelap $value2 bantu': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nAssist',
      'gelap $value2 bantu': '$selectedOption $minutes:${remainingSeconds.toString().padLeft(2, '0')}\n${matchData.gelap} #$value2 \nAssist',
    };


    namaTim = (gelapTerang1 == 'terang') ? '${matchData.terang}' : '${matchData.gelap}';

    for (String key in responseMappingTerang.keys) {
      if (fulfillmentTextIndo.startsWith(key)) {
        value1 = responseMappingTerang[key]!.split('\n')[2].trim();
        print('value1: $value1');
        messageTerang = responseMappingTerang[key]!;
        print('Pesanan yang cocok: $key');
        break;
      }
    }

    for (String key in responseMappingGelap.keys) {
      if (fulfillmentTextIndo.startsWith(key)) {
        value1 = responseMappingGelap[key]!.split('\n')[2].trim(); // Mengambil "Made +1" dll. sebagai action
        print('value1: $value1');
        messageGelap = responseMappingGelap[key]!;
        print('Pesanan yang cocok: $key');
        break;
      }
    }

    sendDataToAPI();


    messageTerang = responseMappingTerang[fulfillmentTextIndo] ?? '';
    print('response yang sudah di mapping: $messageTerang');

    messageGelap = responseMappingGelap[fulfillmentTextIndo] ?? '';
    print('response yang sudah di mapping: $messageGelap');

    if(fulfillmentTextIndo.isNotEmpty){
      if(gelapTerang1 == "terang"){
        Message botMessage = Message(
          //text: fulfillmentTextIndo,
          text: messageTerang,
          type: false,
        );

        setState(() {
          //_fulfillmentText = fulfillmentTextIndo;
          _fulfillmentText = messageTerang;
          _messages.insert(0, botMessage);
        });

      } else {
        Message botMessage = Message(
          //text: fulfillmentTextIndo,
          text: messageGelap,
          type: false,
        );

        setState(() {
          //_fulfillmentText = fulfillmentTextIndo;
          _fulfillmentText = messageGelap;
          _messages.insert(0, botMessage);
        });
      }

      Timer(Duration(seconds: 3), () {
        setState(() {
          _fulfillmentText = ""; // Menghapus teks fulfillmentText setelah 3 detik
          //selectedValues2.clear();
        });
      });

      // if (messageTerang.isNotEmpty) {
      //   Message terangMessage = Message(
      //     text: messageTerang,
      //     type: false,
      //   );
      //   _messages.insert(0, terangMessage);
      // }

      // Simpan respons ke database
      //await DatabaseManager().saveResponseToDatabase(fulfillmentTextIndo);

    }
  }

  // Future<Object> getResponsesFromDatabase() async {
  //   final Database? db = await DatabaseManager().database;
  //   return db?.query('dialogflow_responses') ?? [];
  // }

  List<Widget> terangButtons = [];
  List<Widget> gelapButtons = [];

  void buildButtons() {
    // terangButtons.clear();
    // gelapButtons.clear();
    terangButtons = terangMain.map((angka) {
      return Padding(
        padding: EdgeInsets.all(3),
        child: ReusableButton1(
          text: angka,
          onPressed: () {
            _handleButtonPressNumber(angka, 'terang');
            Vibration.vibrate(duration: 100, amplitude: 128);
          },
          value: angka,
          backgroundColor: widget.selectedColor2,
          textColor: widget.selectedColor1,
        ),
      );
    }).toList();

    gelapButtons = gelapMain.map((angka) {
      return Padding(
        padding: EdgeInsets.all(3),
        child: ReusableButton1(
          text: angka,
          onPressed: () {
            _handleButtonPressNumber(angka, 'gelap');
            Vibration.vibrate(duration: 100, amplitude: 128);
          },
          value: angka,
          backgroundColor: widget.selectedColor4,
          textColor: widget.selectedColor3,
        ),
      );
    }).toList();

    setState(() {
      // Memperbarui terangButtons berdasarkan widget.activeTerang yang baru
      terangButtons = terangMain.map((angka) {
        return Padding(
          padding: EdgeInsets.all(3),
          child: ReusableButton1(
            text: angka,
            onPressed: () => _handleButtonPressNumber(angka, 'terang'),
            value: angka,
            backgroundColor: widget.selectedColor2,
            textColor: widget.selectedColor1,
          ),
        );
      }).toList();

      // Memperbarui gelapButtons berdasarkan widget.activeGelap yang baru
      gelapButtons = gelapMain.map((angka) {
        return Padding(
          padding: EdgeInsets.all(3),
          child: ReusableButton1(
            text: angka,
            onPressed: () => _handleButtonPressNumber(angka, 'gelap'),
            value: angka,
            backgroundColor: widget.selectedColor4,
            textColor: widget.selectedColor3,
          ),
        );
      }).toList();
    });

  }


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

    final terangGelapProvider = Provider.of<TerangGelapProvider>(context);
    final activeTerang = terangGelapProvider.activeTerang;
    final activeGelap = terangGelapProvider.activeGelap;


    //final GlobalKey<_KalkulatorState> yourWidgetKey = GlobalKey<_KalkulatorState>();

    // Menggunakan Provider.of untuk mengakses MatchDataProvider
    final matchDataProvider = Provider.of<MatchDataProvider>(context);

    final buttonStatusProvider = Provider.of<ButtonStatusModel>(context);

    final timerProvider = Provider.of<CountdownTimerProvider>(context);

    // return FutureBuilder(
    //   future: fetchDataSubtitution(widget.id),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return CircularProgressIndicator(); // Tampilkan loading indicator ketika data diambil
    //     } else if (snapshot.hasError) {
    //       return Text('Error: ${snapshot.error}');
    //     } else {
    //       //final terangMain = snapshot.data;
    //       //final gelapMain = snapshot.data['gelapMain'];
    //     }
    //   },
    // );
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
              // Navigasi ke layar WebView saat tombol ditekan
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LogWebView(id: widget.id,),
                ),
              );
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
              // Navigasi ke layar WebView saat tombol ditekan
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StatistikWebView(id: widget.id,),
                ),
              );
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
              Navigator.pop(context, {
                'activeTerang': widget.activeTerang,
                'activeGelap': widget.activeGelap,
              });
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
                      //yourWidgetKey.currentState?.updateButtonState();
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
                          style: TextStyle(color: SportkitColors.black, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
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
                        child: GestureDetector(
                          onTap: () {
                            _showPickerDialog(context);
                          },
                          child: Text(
                            _formatTime(_start),
                            style: TextStyle(fontSize: 24, color: SportkitColors.lightGreen, fontWeight: FontWeight.bold, fontFamily: 'DotMatrix'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isActive ? _pauseTimer : _startTimer,
                    child: Icon(
                      _isActive ? Icons.pause : Icons.play_arrow,
                      size: 25,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: SportkitColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4), // Radius border
                      ),
                    ),
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
                      primary: SportkitColors.yellow,
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
                    //alignment: Alignment.center,
                    height: 110,
                    width: 657,
                    decoration: BoxDecoration(
                      color: SportkitColors.lightBackground, borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 15,
                    child: Column(
                      children: [
                        Text(
                          _fulfillmentText,
                          style: GoogleFonts.poppins(fontSize: 20, color: SportkitColors.white),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 15,
                    child: isOk
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children:[
                            Icon(Icons.check_circle, color: SportkitColors.green, size: 30,),
                            Padding(padding: EdgeInsets.all(8)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$selectedOption ${_formatTime(_lastElapsedTime)}', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
                                Text('${selectedValues.join()}', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
                                Text('${selectedValues2.join()}', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                        : SizedBox(), // Jika false, tidak menampilkan apapun
                  ),
                ],
              ),
              Padding(padding: EdgeInsets.all(4)),
              Container(
                alignment: Alignment.center,
                height: 50,
                width: 657,
                decoration: BoxDecoration(
                  color: SportkitColors.black, borderRadius: BorderRadius.circular(1),
                ),
                child: Text(
                  combinedValue,
                  style: TextStyle(color: SportkitColors.green,  fontFamily: 'DotMatrix', fontWeight: FontWeight.bold),
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
                          //children: terangButtons,
                          children: terangMain.map((angka) {
                            //final angkaStr = angka.toString();
                            return Padding(
                              padding: EdgeInsets.all(3),
                              child: ReusableButton1(
                                text: angka,
                                onPressed: () {
                                  _handleButtonPressNumber(angka, 'terang');
                                  Vibration.vibrate(duration: 100, amplitude: 128);
                                  //buttonStatusProvider.saveButtonStatusToStorage();
                                },
                                value: angka,
                                backgroundColor: widget.selectedColor2,
                                textColor: widget.selectedColor1,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(2)),
                  SingleChildScrollView(
                    child:  Wrap(
                      //children: gelapButtons,
                      children: gelapMain.map((angka) {
                        //final angkaStr = angka.toString();
                        return Padding(
                          padding: EdgeInsets.all(3),
                          child: ReusableButton1(
                            text: angka,
                            onPressed: () {
                              _handleButtonPressNumber(angka, 'gelap');
                              Vibration.vibrate(duration: 100, amplitude: 128);
                            },
                            value: angka,
                            backgroundColor: widget.selectedColor4,
                            textColor: widget.selectedColor3,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(3)),
                ],
              ),
              Padding(padding: EdgeInsets.all(3)),
              Container(
                alignment: Alignment.center,
                height: 50,
                width: 657,
                decoration: BoxDecoration(
                  color: SportkitColors.black, borderRadius: BorderRadius.circular(1),
                ),
                child: Text(
                  _handleButtonPress(value1),
                  style: TextStyle(color: SportkitColors.green,  fontFamily: 'DotMatrix', fontWeight: FontWeight.bold),
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
                          // onPressed: () => _handleButtonPress('Made +1'),
                          onPressed: () {
                            _handleButtonPress('Made +1');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Made 1',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.1,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: '1',
                          text2: 'Missed',
                          // onPressed: () => _handleButtonPress('Missed 1'),
                          onPressed: () {
                            _handleButtonPress('Missed +1');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Missed 1',
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'A',
                          text2: 'Assist',
                          onPressed: () {
                            _handleButtonPress('Assist');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Assist',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'TO',
                          text2: 'Turn Over',
                          onPressed: () {
                            _handleButtonPress('Turn Over');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Turn Over',
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                          width: MediaQuery.of(context).size.width * 0.2,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'P',
                          text2: 'Personal',
                          onPressed: () {
                            _handleButtonPress('Personal Foul');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Personal Foul',
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
                          onPressed: () {
                            _handleButtonPress('Made +2');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Made 2',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: '2',
                          text2: 'Missed',
                          onPressed: () {
                            _handleButtonPress('Missed +2');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Missed 2',
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'OR',
                          text2: 'Ofs Rebound',
                          onPressed: () {
                            _handleButtonPress('Offensive Rebound');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Offensive Rebound',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'B',
                          text2: 'Block',
                          onPressed: () {
                            _handleButtonPress('Block');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Block',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'T',
                          text2: 'Technical',
                          onPressed: () {
                            _handleButtonPress('Technical Foul');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Technical Foul',
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
                          onPressed: () {
                            _handleButtonPress('Made +3');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Made 3',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: '3',
                          text2: 'Missed',
                          onPressed: () {
                            _handleButtonPress('Missed +3');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Missed 3',
                          backgroundColor: SportkitColors.red,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'DR',
                          text2: 'Dfs Rebound',
                          onPressed: () {
                            _handleButtonPress('Defensive Rebound');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Defensive Rebound',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'S',
                          text2: 'Steal',
                          onPressed: () {
                            _handleButtonPress('Steal');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Steal',
                          backgroundColor: SportkitColors.green,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton(
                          text1: 'U',
                          text2: 'Unsports',
                          onPressed: () {
                            _handleButtonPress('Unsportmanship Foul');
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'Unsportsmanship Foul',
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
                          onPressed: () {
                            _handleClearButtonPress();
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
                          value: 'clear',
                          width: 93,
                          height: 50,
                          backgroundColor: SportkitColors.lightBackground,
                          textColor: SportkitColors.white,
                        ),
                        Padding(padding: EdgeInsets.all(3)),
                        ReusableButton1(
                          text: 'OK',
                          onPressed: () {
                            _handleOkButtonPress();
                            Vibration.vibrate(duration: 100, amplitude: 128);
                          },
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
                                Vibration.vibrate(duration: 100, amplitude: 128);
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