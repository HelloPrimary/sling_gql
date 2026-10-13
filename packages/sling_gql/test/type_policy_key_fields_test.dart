import 'package:flutter_test/flutter_test.dart';
import 'package:sling_gql/sling_gql.dart';

import 'support/test_schema.dart';

/// A user's id is only unique per name: the key reads both.
const _parNom = Normalization(identify: _membre);

String? _membre(Map<String, Object?> o) {
  final id = o['id'];
  final name = o['name'];
  return id == null || name == null ? null : 'User:$id:$name';
}

/// `name`, not the one in `__typename`.
final _name = RegExp(r'\bname\b');

void main() {
  test('TypePolicy.keyFields are selected with the key field, a request for '
      'the missing fields only included', () async {
    final queries = <String>[];
    final client = SlingClient<Query>(
      endpoint: testEndpoint,
      schema: slingSchema,
      cache: Cache(normalization: _parNom),
      typePolicies: const {
        User: TypePolicy(keyFields: ['name']),
      },
      httpClient: mockGraphQL((query, _) {
        queries.add(query);
        // Answers what was asked: a key field left out stays out.
        return {
          'me': {
            '__typename': 'User',
            'id': '1',
            if (query.contains(_name)) 'name': 'Ada',
            if (query.contains('age')) 'age': 36,
          },
        };
      }),
    );

    expect(await client.resolve((q) => q.me.name), 'Ada');
    expect(await client.resolve((q) => (q.me.name, q.me.age)), ('Ada', 36));

    expect(queries, hasLength(2));
    expect(queries.last, contains('age'));
    expect(queries.last, contains(_name));
    expect(client.cache.entityKeys, contains('User:1:Ada'));
  });
}
