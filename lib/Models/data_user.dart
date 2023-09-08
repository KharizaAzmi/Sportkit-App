class UserData {
  final String name1;
  final String jersey1;
  final String name2;
  final String jersey2;
  final String colors;
  final String colors2;
  final int periods;

  UserData({
    required this.name1,
    required this.jersey1,
    required this.name2,
    required this.jersey2,
    required this.colors,
    required this.colors2,
    required this.periods,
  });
}

class UserModel {
  final UserData userData;
  final int periodtimes;

  UserModel({
    required this.userData,
    required this.periodtimes,
  });
}