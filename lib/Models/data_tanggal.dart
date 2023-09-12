class TanggalData {
  final bool status;
  final String message;
  final List<TanggalItem> data;

  TanggalData({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TanggalData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'];
    final List<TanggalItem> tanggalItems =
    dataList.map((item) => TanggalItem.fromJson(item)).toList();

    return TanggalData(
      status: json['status'],
      message: json['message'],
      data: tanggalItems,
    );
  }
}

class TanggalItem {
  String waktu;

  TanggalItem({
    required this.waktu,
  });

  factory TanggalItem.fromJson(Map<String, dynamic> json) {
    return TanggalItem(
      waktu: json['waktu'],
    );
  }
}