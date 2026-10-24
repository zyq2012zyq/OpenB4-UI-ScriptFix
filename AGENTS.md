# Repository workflow

- Work on the source in `OpenB4/`; preserve the authorized binary script fixes in `vendor/RavenB4-scriptfix-input.jar` unless updated input is supplied.
- For each completed change, add a concise entry at the top of `CHANGELOG.md`, run the relevant build or release check, and commit with a descriptive message.
- When the user requests a change, finish and verify it, then manually push the commit and publish the release with a specific update description. Do not add automatic push hooks, scheduled monitors, or push-triggered release workflows.
- Do not commit credentials, Minecraft instance data, logs, caches, or generated `dist/` files. GitHub Releases carry the generated JAR.
