# Reel Bridge

Reel Bridge is a Flutter app that combines a paginated user directory, movie discovery, and offline-first local persistence. The app is designed to stay usable under unstable connectivity by storing app-created users and bookmarks locally, then syncing pending work once the device is back online.

## Highlights

- paginated user browsing
- local-first user creation
- movie search and detail views
- per-user bookmarks
- offline persistence with deferred sync
- resilient networking with retry and failure simulation

## Product Behavior

### User directory

- loads users in pages
- supports infinite scrolling
- displays avatar, name, and supporting metadata
- keeps locally created users visible in the app alongside fetched users

### Local-first creation

- users can be created whether the device is online or offline
- when online, the app submits immediately and stores the result locally
- when offline, the app creates a local record, marks it pending, and makes it available right away

### Movie browsing

- supports paginated movie search
- opens a dedicated detail view for each movie
- shows poster, release information, plot, and supporting metadata

### Bookmarks

- movies can be bookmarked from both list and detail views
- bookmarks are stored per user
- bookmark relationships remain stable even if the user was originally created offline

### Sync

- pending users are stored in the local database
- the app attempts sync when connectivity returns in the foreground
- `workmanager` provides a background fallback for pending sync tasks
- once sync succeeds, local records are updated with their remote identifiers

### Network resilience

- GET requests pass through a custom Dio interceptor
- a configurable percentage of requests can be intentionally failed to simulate real-world instability
- retry uses exponential backoff
- previously loaded UI remains visible while retry is in progress

## Architecture

- state management and dependency injection: `flutter_riverpod`
- networking: `dio`
- local persistence: `drift` + SQLite
- background work: `workmanager`
- connectivity monitoring: `connectivity_plus`
- image loading: `cached_network_image`

The codebase uses a feature-first structure:

```text
lib/
  app/
  core/
    config/
    db/
    network/
    sync/
    widgets/
  features/
    users/
      data/
      domain/
      presentation/
      providers/
    movies/
      data/
      domain/
      presentation/
      providers/
    bookmarks/
      data/
      domain/
      providers/
```

## Configuration

Runtime configuration is provided through `--dart-define`.

Required:

- `REQRES_API_KEY`
- `OMDB_API_KEY`

Optional:

- `REQRES_ENV` default: `dev`
- `DEFAULT_MOVIE_QUERY` default: `movie`
- `SIMULATED_GET_FAILURE_RATE` default: `0.3`

## Run

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run \
  --dart-define=REQRES_API_KEY=YOUR_REQRES_KEY \
  --dart-define=REQRES_ENV=dev \
  --dart-define=OMDB_API_KEY=YOUR_OMDB_KEY
```

## Data Model

The local database contains:

- `local_users`
- `bookmarks`
- `sync_queue_entries`

Key design choices:

- every app-created user gets a stable `localId`
- `remoteId` stays nullable until sync succeeds
- bookmarks are linked to `localId`
- when sync completes, related records are updated with the returned remote ID

This preserves user-bookmark relationships for records created while offline.

## Integrations

- ReqRes powers the user directory and remote user creation flow
- OMDB powers the movie search and movie detail flow

Bookmarks remain local in the current implementation because there is no remote bookmark contract configured for sync.

## Verification

- `dart format lib test`
- `flutter pub run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
