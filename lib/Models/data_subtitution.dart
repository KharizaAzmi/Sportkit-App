class SubtitutionData {
  final List<int> terangMain;
  final List<int> gelapMain;
  final String eventId;
  final String minute;
  final String quarter;
  final String ownerId;

  SubtitutionData({
    required this.terangMain,
    required this.gelapMain,
    required this.eventId,
    required this.minute,
    required this.quarter,
    required this.ownerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'minute': minute,
      'quarter': quarter,
      'terang_main': terangMain,
      'gelap_main': gelapMain,
      'owner_id': ownerId,
    };
  }
}
