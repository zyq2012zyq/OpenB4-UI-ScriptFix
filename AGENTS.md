# Repository workflow

- Work on the source in `OpenB4/`; preserve the authorized binary script fixes in `vendor/RavenB4-scriptfix-input.jar` unless updated input is supplied.
- For each completed change, add a concise entry at the top of `CHANGELOG.md`, run the relevant build or release check, and commit with a descriptive message.
- Local commits automatically push through `.githooks/post-commit`; verify the push and GitHub Actions release succeeded. If it fails, fix it and push the existing commit without duplicating it.
- Do not commit credentials, Minecraft instance data, logs, caches, or generated `dist/` files. GitHub Releases carry the generated JAR.
