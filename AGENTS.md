# Perl Regex Extension — Agent Guide

Maven-based Lucee extension with the Perl5 regular expression engine (Apache ORO). It implements the `lucee.runtime.regex.Regex` interface of the Lucee loader and registers it under the names `perl`, `perl5`, `classic` and `oro` with the manifest attribute `regex-engine`.

## Folder Structure

- `source/java/src/` — Java source (`org.lucee.extension.perlregex.Perl5Regex`)
- `source/java/pom.xml` — module POM (dependency Apache ORO, bundled into the extension)
- `pom.xml` — root Maven build, extension manifest values, `.lex` packaging
- `build.xml` — Ant part of the build, writes the extension `MANIFEST.MF` (called from Maven)
- `tests/` — CFML integration tests (label: `perlregex`)
- `CHANGELOG.md` — release notes, update for user-visible changes

## Build

Requires JDK 21 (the Lucee 9 jar has Java 21 class files, javac cannot read them with an older JDK) and Maven. The Lucee dependency (`org.lucee:lucee`, scope provided) must be available for the version in `source/java/pom.xml`.

```bash
mvn clean install -Dgoal=install
```

Output: `target/*.lex`

Versions and releases are handled by the GitHub workflow, which passes `-Drevision` (see "Versioning and releases" in `README.md`). A manual deploy by maintainers uses a local `maven-deploy.sh` (not committed), which needs `MAVEN_USERNAME`, `MAVEN_PASSWORD` and `GPG_PASSPHRASE` in the environment. Never commit credentials.

## Test

CI (`.github/workflows/main.yml`) builds once and runs the tests with [script-runner](https://github.com/lucee/script-runner) against the Lucee versions defined in the repository variable `LUCEE_TEST_VERSIONS_9`.

## Notes

- The extension only uses the loader API (`CFMLEngineFactory` creation and cast utilities), never core classes.
- Minimum Lucee version is in `luceeCoreVersion` in `pom.xml`, it must be a Lucee version that knows the `regex-engine` manifest attribute.
- Behaviour must stay identical to the engine that was in the Lucee core until Lucee 8.
