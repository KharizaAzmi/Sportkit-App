class MatchData {
  final String? id;
  final String? waktu;
  final String? venue;
  final String? terang;
  final String? gelap;
  final String? KU;
  final String? pool;
  final String? terangPemain;
  final String? gelapPemain;
  final String? terangId;
  final String? gelapId;
  final String? tanggalPlain;
  final String? tanggal;
  final String? jam;

  MatchData({
    required this.id,
    required this.waktu,
    required this.venue,
    required this.terang,
    required this.gelap,
    required this.KU,
    required this.pool,
    required this.terangPemain,
    required this.gelapPemain,
    required this.terangId,
    required this.gelapId,
    required this.tanggalPlain,
    required this.tanggal,
    required this.jam,
  });

  factory MatchData.fromJson(Map<String, dynamic> json) {
    return MatchData(
      id: json['id'],
      waktu: json['waktu'],
      venue: json['venue'],
      terang: json['terang'],
      gelap: json['gelap'],
      KU: json['KU'],
      pool: json['pool'],
      terangPemain: json['terang_pemain'],
      gelapPemain: json['gelap_pemain'],
      terangId: json['terang_id'],
      gelapId: json['gelap_id'],
      tanggalPlain: json['tanggal_plain'],
      tanggal: json['tanggal'],
      jam: json['jam'],
    );
  }
}

class ApiResponse {
  final bool status;
  final String message;
  final List<MatchData> data;

  ApiResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> dataList = json['data'];
    List<MatchData> matchDataList = dataList
        .map((data) => MatchData.fromJson(data))
        .toList();

    return ApiResponse(
      status: json['status'],
      message: json['message'],
      data: matchDataList,
    );
  }
}
