# uaepass_flutter example

This folder contains the Dart example and the exact Android/iOS configuration snippets used by the package documentation.

Example application identity:

```text
Android applicationId: com.abqamar.uaepass_flutter
iOS bundle ID:         com.abqamar.uaepass_flutter
Callback scheme:       abqamaruaepass
```

Because the package archive is intentionally a normal Flutter package rather than a platform plugin, the generated Android/iOS runner shells are not duplicated here. To make the example runnable locally, generate the platform shell with your installed Flutter SDK and then merge the files under `platform_config/`:

```bash
cd example
flutter create --org com.abqamar --project-name uaepass_flutter_example .
```

After generation, keep `lib/main.dart` and merge the platform configuration documented in the root README.
