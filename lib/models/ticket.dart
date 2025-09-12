class Ticket {
  final String id;
  final String fullName;
  final double? minimumPrice;
  final bool open;
  final DateTime? opensAt;
  final bool openToContributors;
  
  Ticket({
    required this.id,
    required this.fullName,
    this.minimumPrice,
    required this.open,
    this.opensAt,
    required this.openToContributors,
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
  );
}