import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class AuthService{
  static final instance = AuthService._();
  AuthService._();
  
  String? _token;
  DateTime? _expiresAt;
  late GraphQLClient _client;

  Future<void> init() async {
    await dotenv.load();
    _client = GraphQLClient(
      link: HttpLink(dotenv.env['API_URL']!),
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  Future<String?> getToken() async {
    if (_token != null && _expiresAt != null && DateTime.now().isBefore(_expiresAt!)) {
      return _token;
    }
    
    return await _login();
  }

  Future<String?> _login() async {
    const mutation = '''
      mutation Login(\$email: String!, \$password: String!) {
        login(email: \$email, password: \$password) {
          ... on MutationLoginSuccess {
            data { token expiresAt }
          }
          ... on Error {
            message
          }
        }
      }
    ''';

    await dotenv.load(fileName: '.env');
    
    final result = await _client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {
        'email': dotenv.env['EMAIL']!,
        'password': dotenv.env['PASSWORD']!,
      },
    ));

    final login = result.data?['login'];
    if (login?['data'] != null) {
      _token = login['data']['token'];
      _expiresAt = DateTime.parse(login['data']['expiresAt']);
      return _token;
    }
    
    print('Login failed: ${login?['message'] ?? result.exception}');
    return null;
  }
}