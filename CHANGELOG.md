# Changelog

## 1.0.0.1-BETA

- [LDEV-1631](https://luceeserver.atlassian.net/browse/LDEV-1631) — the Perl5 engine now stops when the request is interrupted by the request timeout, a regex with catastrophic backtracking no longer runs on past the timeout. Needs a patched copy of Apache ORO, now included in the extension

## 1.0.0.0-BETA

- [LDEV-6632](https://luceeserver.atlassian.net/browse/LDEV-6632) — first BETA, published to Maven Central and as a GitHub pre-release with the .lex files, tested with the Lucee 9 versions from `LUCEE_TEST_VERSIONS_9`

## 1.0.0.0-ALPHA

- [LDEV-6632](https://luceeserver.atlassian.net/browse/LDEV-6632) — initial version, the Perl5 regex engine (Apache ORO 2.0.8) moved out of the Lucee core, registered with the manifest attribute `regex-engine`
