import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sportkit_statistik/Controller/user_provider.dart';
import 'package:sportkit_statistik/Views/Screen/home.dart';
import 'package:http/http.dart' as http;

import '../../Controller/token_provider.dart';
import '../../Models/data_pertandingan.dart';
import '../../Utils/Colors.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async{
    final url = Uri.parse('https://sportkit.id/friendship/api/v1/login.php');

    final Map<String, dynamic> requestData = {
      'id': _idController.text,
      'username': _usernameController.text,
      'password' : _passwordController.text,
    };

    final response = await http.post(
      url,
      body: jsonEncode(requestData),
      headers: {'Content-Type': 'application/json'},
    );

    print('Request: ${response.request}');
    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Login berhasil');
      final responseData = json.decode(response.body);
      final matchData = MatchData.fromJson(responseData);

      if (responseData != null && responseData['jwt'] != null) {
        String token = responseData['jwt'];
        print(token);

        Provider.of<TokenProvider>(context, listen: false).setToken(token);
        Provider.of<UserDataProvider>(context, listen: false).setId(_idController.text);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeStat(token: token, matchData: matchData, id: '', activeTerang: [], activeGelap: []),
          ),
        );
      } else {
        print('Token is null');
      }
    } else {
      print('Login gagal');
      print('HTTP Request Failed: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SportkitColors.darkBackground,
      appBar: null,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: 14,),
                      ListTile(
                        title: SvgPicture.asset(
                          'assets/image/logo-stat.svg',
                          width: 534,
                          height: 44,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 10, right: 18, left: 18),
                            child: Column(
                              children: [
                                const Align(
                                  alignment: Alignment.topLeft,
                                  child: Text('ID', style: TextStyle(fontSize: 18)),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  width: 340,
                                  height: 45,
                                  child: TextField(
                                    controller: _idController,
                                    textAlign: TextAlign.left,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4), // Border radius
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10, right: 18, left: 18),
                            child: Column(
                              children: [
                                const Align(
                                  alignment: Alignment.topLeft,
                                  child: Text('User', style: TextStyle(fontSize: 18)),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  width: 340,
                                  height: 45,
                                  child: TextField(
                                    controller: _usernameController,
                                    textAlign: TextAlign.left,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4), // Border radius
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10, right: 18, left: 18),
                            child: Column(
                              children: [
                                const Align(
                                  alignment: Alignment.topLeft,
                                  child: Text('Password', style: TextStyle(fontSize: 18)),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  width: 340,
                                  height: 45,
                                  child: TextField(
                                    controller: _passwordController,
                                    textAlign: TextAlign.left,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4), // Border radius
                                      ),
                                    ),
                                    obscureText: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20, top: 50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _login,
                              child: Text('Login',
                                style: TextStyle(fontSize: 22, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: SportkitColors.green, // Set warna latar belakang menjadi transparan
                                //elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4), // Radius border (sesuaikan dengan kebutuhan)
                                ), // Menghilangkan bayangan saat ditekan
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 97),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
