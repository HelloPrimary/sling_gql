## 1.4.2

 - **FIX**(sling_gql): repair pubspec metadata after repository move. ([9965e67a](https://github.com/helloprimary/sling_gql/commit/9965e67a9476989e2f5b9dc958a77ef12644adf3))
 - **FIX**(sling_gql): move repository to helloprimary/sling_gql. ([2175b5b9](https://github.com/helloprimary/sling_gql/commit/2175b5b9005ca35073c18f8701ee82508bb05272))

## 1.4.1

 - Update a dependency to the latest release.

## 1.4.0

 - **FEAT**(sling_gql_gen): slingSchema.fields lists the mutation and subscription roots. ([0a0f4445](https://github.com/tpucci/sling_gql/commit/0a0f444521a6229a7cec7963eca9e9dc5a3c920f))

## 1.3.0

 - **FEAT**(sling_gql_gen): slingSchema carries enums and possibleTypes (needs sling_gql 1.2.0). ([f668116a](https://github.com/tpucci/sling_gql/commit/f668116aa4f0c04974cac04ba7fa89578e274642))

## 1.2.0

 - **FEAT**(sling_gql): cancelQueries drops the responses in flight on sign-out. ([49b6e9b0](https://github.com/tpucci/sling_gql/commit/49b6e9b05fd88fbc8a92eca45d6b736bc4d1e81b))

## 1.1.0

 - **FIX**(sling_gql_sqflite): migration types an entity by its __typename. ([793e114f](https://github.com/tpucci/sling_gql/commit/793e114fbc190ff10d4cf3e5c58292ccfe8d49cb))
 - **FEAT**(sling_gql_sqflite): open accepts the cache's normalization. ([3854a58a](https://github.com/tpucci/sling_gql/commit/3854a58a4592b08b4c5ed60e534ed0bf4684a746))

## 1.0.1

 - Update a dependency to the latest release.

## 1.0.0

> Note: This release has breaking changes.

 - First stable release. Upgrading from 0.x: see [Upgrading to 1.0](https://tpucci.github.io/sling_gql/guides/upgrading-to-1-0/).

 - **PERF**(sling_gql_sqflite): compact after each save; delete rows in chunks. ([ea4a06f4](https://github.com/tpucci/sling_gql/commit/ea4a06f4c8a024a341cef3166574276399dcd25d))
 - **PERF**(sling_gql_sqflite): save only the changed root fields; hydrate without a copy. ([6d1c3a4f](https://github.com/tpucci/sling_gql/commit/6d1c3a4ff503d6fe8af240d13f56eed1b410d89b))
 - **FEAT**(sling_gql_gen): debugLabel on the generated mutate and subscribe ([#73](https://github.com/tpucci/sling_gql/issues/73)). ([c928a936](https://github.com/tpucci/sling_gql/commit/c928a93615585e282da671075c751ca77b70d7ca))
 - **FEAT**(sling_gql_sqflite): clear() also empties the stored mutation queue. ([9b20e98d](https://github.com/tpucci/sling_gql/commit/9b20e98da4b87dc57d0c5c860ed8a0a70be8c506))
 - **FEAT**(sling_gql_sqflite): persistence.mutationQueue ([#72](https://github.com/tpucci/sling_gql/issues/72)). ([a70f8b91](https://github.com/tpucci/sling_gql/commit/a70f8b9141e4db31d21e8492b571b2ad1e682280))
 - **DOCS**(repo): Versioning sections in the adapter, test and generator READMEs ([#73](https://github.com/tpucci/sling_gql/issues/73)). ([a3574704](https://github.com/tpucci/sling_gql/commit/a35747046d8fa901476b73825661861c9acf78ce))
 - **BREAKING** **REFACTOR**(sling_gql): settle the 1.0 public surface ([#73](https://github.com/tpucci/sling_gql/issues/73)). ([0f1e6992](https://github.com/tpucci/sling_gql/commit/0f1e6992e8cb3caee34071000742b2e10ddae482))
 - **BREAKING** **FEAT**(sling_gql_sqflite): migrate across schema changes, recover, one writer, codec ([#72](https://github.com/tpucci/sling_gql/issues/72)). ([40d0d46a](https://github.com/tpucci/sling_gql/commit/40d0d46a6986040d02288d71033d9c5524e56680))

## 0.1.0

Initial release.

- `SqflitePersistence.open(path, schema:)`: loads the stored rows into a `Cache` before the client starts (optionally in a background isolate), dropping root fields past `maxAge`, the oldest ones over `maxEntities`, and unreachable entities.
- Write-behind saves of `Cache.changesSince` deltas: debounced, bounded by `maxWait`, flushed on app pause/hide/detach and `flush()`; serialized, retried after a failure. One row per entity, one per `ROOT_QUERY` field.
- The store is wiped when the format version, key field or `slingSchema.hash` changed, or when its rows cannot be decoded (reported to `onError`).
- `clear()` (logout), `close()`, a pluggable `DatabaseFactory` (ffi, web, SQLCipher).
