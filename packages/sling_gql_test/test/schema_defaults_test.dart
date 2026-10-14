import 'package:flutter_test/flutter_test.dart';
import 'package:sling_gql/sling_gql.dart';
import 'package:sling_gql_test/sling_gql_test.dart';

import 'support/test_schema.dart' show Query, Mutation;

// enum Status { ACTIVE BANNED }  scalar Date  interface Pet  type Dog implements Pet
const _schema = SlingSchema<Query, Mutation>(
  query: Query.root,
  fields: {
    'ROOT_QUERY': {'me': 'User!', 'user': '(id: ID!) User'},
    'ROOT_MUTATION': {'rename': '(id: ID!, name: String!) User!'},
    'ROOT_SUBSCRIPTION': {'userChanged': 'User'},
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
      'tag': 'Tag!',
      'friends': '(limit: Int) [User!]!',
    },
    'Pet': {},
    'Dog': {'name': 'String!'},
    'Tag': {'id': 'ID', 'label': 'String'},
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

    test('gives a nullable key field the object\'s path', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        query: {
          'me': {'__typename': 'User'},
        },
      );

      final result = await server.execute('{ me { tag { id label } } }');

      expect(result['data'], {
        'me': {
          'tag': {'id': 'me.tag', 'label': null},
        },
      });
    });

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

    test('infers the __typename of an object type', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        query: {
          'me': {
            'name': 'Ada',
            'best': {'name': 'Bob'},
            'friends': [
              {'id': 'f1'},
            ],
          },
        },
      );

      final result = await server.execute(
        '{ me { __typename name best { __typename name } '
        'friends(limit: 1) { __typename id } } }',
      );

      expect(result['data'], {
        'me': {
          '__typename': 'User',
          'name': 'Ada',
          'best': {'__typename': 'User', 'name': 'Bob'},
          'friends': [
            {'__typename': 'User', 'id': 'f1'},
          ],
        },
      });
    });

    test('infers the __typename at the root of a mutation', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        mutation: {
          'rename': (Map<String, Object?> args) => {'name': args['name']},
        },
      );

      final result = await server.execute(
        'mutation { rename(id: "1", name: "Bo") { __typename id name } }',
      );

      expect(result['data'], {
        'rename': {'__typename': 'User', 'id': 'rename', 'name': 'Bo'},
      });
    });

    test('infers the __typename at the root of a subscription', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        subscription: {
          'userChanged': Stream.value({'id': '1', 'name': 'Ada'}),
        },
      );

      final result = await server
          .subscribe('subscription { userChanged { __typename name } }')
          .single;

      expect(result['data'], {
        'userChanged': {'__typename': 'User', 'name': 'Ada'},
      });
    });

    test('still needs the __typename of an interface\'s object', () async {
      final server = MockGraphQLServer(
        schema: _schema,
        query: {
          'me': {
            'pet': {'name': 'Rex'},
          },
        },
      );

      expect(
        () => server.execute('{ me { pet { __typename } } }'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains("no '__typename'"),
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
