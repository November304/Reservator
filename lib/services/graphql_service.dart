import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:reservator/services/graphql_auth.dart';

class GraphQLService {
  static GraphQLService? _instance;
  static GraphQLService get instance => _instance ??= GraphQLService._();

  GraphQLService._();

  late ValueNotifier<GraphQLClient> client;
  
  Future<void> init() async {
    await AuthService.instance.init();

    final authLink = AuthLink(getToken: () async {
      final token = await AuthService.instance.getToken();
      return token != null ? 'Bearer $token' : null;
    });
    
    client = ValueNotifier(GraphQLClient(
      link: authLink.concat(HttpLink(dotenv.env['API_URL']!)),
      cache: GraphQLCache(store: InMemoryStore()),
    ));
  }
}