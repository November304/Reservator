class Ticket {
  final String id;
  final String fullName;
  final double? minimumPrice;
  final bool open;
  final DateTime? opensAt;
  final bool openToContributors;
  final bool isUnlimited;
  final int? capacity;
  final int? placesLeft;
  
  Ticket({
    required this.id,
    required this.fullName,
    this.minimumPrice,
    required this.open,
    this.opensAt,
    required this.openToContributors,
    required this.isUnlimited,
    required this.capacity,
    required this.placesLeft
  });
  
  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    minimumPrice: json['minimumPrice']?.toDouble(),
    open: json['open'] ?? false,
    opensAt: json['opensAt'] != null 
        ? DateTime.parse(json['opensAt']) 
        : null,
    openToContributors: json['openToContributors'] ?? false,
    isUnlimited: json['capacity'] == "Unlimited",
    capacity: json['capacity'] == "Unlimited" ? null : json['capacity'],
    placesLeft: json['capacity'] == "Unlimited" ? null : json['placesLeft'],
  );
}