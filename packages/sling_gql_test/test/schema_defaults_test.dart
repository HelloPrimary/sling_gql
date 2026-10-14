import 'package:flutter_test/flutter_test.dart';
import 'package:sling_gql/sling_gql.dart';
import 'package:sling_gql_test/sling_gql_test.dart';

import 'support/test_schema.dart' show Query, Mutation;

// enum Status { ACTIVE BANNED }  scalar Date  interface Pet  type Dog implements Pet
const _schema = SlingSchema<Query, Mutation>(
  query: Query.root,
  fields: {
    'ROOT_QUERY': {'me': 'User!', 'user': '(id: ID!) User'},
    'User': {
      'id': 'ID!',
      'name': 'String!',
      'age': 'Int',
      'score': 'Float!',
      'admin': 'Boolean!',
      'status': 'Status!',
      'joined': 'Date!',
      'pet': 'Pet!',
      'best': 'User!',
      'friends': '(limit: Int) [User!]!',
    },
    'Pet': {},
    'Dog': {'name': 'String!'},
  },
  enums: {
    'Status': ['ACTIVE', 'BANNED'],
  },
  possibleTypes: {
    'Pet': ['Dog'],
  },
);

void main() {
  group('MockGraphQLServer(schema:)', () {
    test('fills the selected non-null fields the data leaves out', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        query: {
          'me': {'__typename': 'User', 'name': 'Ada'},
        },
      );

      final result = await server.execute(
        '{ me { __typename id name age score admin '
        'friends(limit: 2) { id } best { __typename id name } } }',
      );

      expect(result, {
        'data': {
          'me': {
            '__typename': 'User',
            'id': 'me',
            'name': 'Ada',
            'age': null,
            'score': 0.0,
            'admin': false,
            'friends': <Object?>[],
            'best': {
              '__typename': 'User',
              'id': 'me.best',
              'name': 'User.name',
            },
          },
        },
      });
    });

    test('takes an enum\'s first value and an abstract type\'s first '
        'concrete type from the schema', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        query: {
          'me': {'__typename': 'User'},
        },
      );

      final result = await server.execute(
        '{ me { status pet { __typename ... on Dog { name } } } }',
      );

      expect(result['data'], {
        'me': {
          'status': 'ACTIVE',
          'pet': {'__typename': 'Dog', 'name': 'Dog.name'},
        },
      });
    });

    test(
      'takes enums, custom scalars and abstract types from defaults',
      () async {
        final server = MockGraphQLServer(
          schema: _schema,
          defaults: {
            'Status': 'BANNED',
            'Date': '2021-01-01',
            'Pet': {'__typename': 'Dog'},
            'Dog': {'name': 'Rex'},
          },
          query: {
            'me': {'__typename': 'User'},
          },
        );

        final result = await server.execute(
          '{ me { status joined pet { __typename ... on Dog { name } } } }',
        );

        expect(result['data'], {
          'me': {
            'status': 'BANNED',
            'joined': '2021-01-01',
            'pet': {'__typename': 'Dog', 'name': 'Rex'},
          },
        });
      },
    );

    test('fails naming the type when no default can be made', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        query: {
          'me': {'__typename': 'User'},
        },
      );

      expect(
        () => server.execute('{ me { joined } }'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('Date'), contains('defaults')),
          ),
        ),
      );
    });

    test('still fails on a missing root field', () async {
      final server = MockGraphQLServer(schema: _schema);

      expect(() => server.execute('{ me { id } }'), throwsStateError);
    });
  });
}
