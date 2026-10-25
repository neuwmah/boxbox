# BoxBox!

Recreational casual money farming game.

## Stack

The client is built with Flutter (Dart), utilizing `cannon_physics` for physics simulation, `flutter_soloud` for audio processing, and `google_mobile_ads` for ad integration. Authentication is managed through Firebase Auth with native Google and Apple Sign-In support. On the backend, the API is powered by Node.js, Express, and PostgreSQL, integrated with Firebase Admin, while deployment and hosting for both `server/` and `.web/` are handled on Fly.io.

## Structure

The project root centers around the `lib/` directory, which houses the core Flutter application code, including game logic, UI components, assets, and shaders. The `server/` folder contains the backend API, and `.appstore/` holds the store listing assets and metadata. Lastly, dedicated platform folders (android, ios, web, windows, macos, and linux) manage native configuration and build targets.
