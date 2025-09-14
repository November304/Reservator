class Reservation {
  final String ticketId;
  final String bookingUrl;
  final DateTime bookingTime;
  final String state;
  final String eventTitle;
  final String ticketName;

  Reservation({
    required this.ticketId,
    required this.bookingUrl,
    required this.bookingTime,
    required this.state,
    required this.eventTitle,
    required this.ticketName,
  });
  
  Map<String, dynamic> toJson() {
    return {
      "ticketId": ticketId,
      "bookingUrl":bookingUrl,
      "bookingTime":bookingTime.toIso8601String(),
      "state":state,
      "eventTitle":eventTitle,
      "ticketName":ticketName
    };
  }

  factory Reservation.fromJson(Map<String,dynamic> json) {
    return Reservation(
      ticketId: json["ticketId"], 
      bookingUrl: json["bookingUrl"], 
      bookingTime: json["bookingTime"], 
      state: json["state"], 
      eventTitle: json["eventTitle"], 
      ticketName: json["ticketName"]
    );
  }

}
