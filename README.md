# Lucee Perl Regex Extension

With Lucee 9, the Perl5 regular expression engine (Apache ORO) has moved from the core into this extension.

Lucee has two built-in regex engines, `java` (the default, also `modern`) and `compat` (Java with Perl-style replacement syntax). This extension adds the engine `perl` (aliases `perl5`, `classic`, `oro`) that was part of the Lucee core until Lucee 8, and was the default there.

Select it per application:

```cfml
this.regex.type = "perl";
```

or for the whole server with the `regexType` setting (`lucee.regex.type` system property, `LUCEE_REGEX_TYPE` environment variable).

Without the extension, `perl` is still accepted as a setting, but using a regex function fails with the message that the engine is not available.

## Moving to the built-in engines

The Apache ORO library is old and no longer developed, so this extension is deprecated from the start and exists to give existing applications time to move.

* Use `java` (the default) for new code. Patterns use Java regular expression syntax.
* Use `compat` if you want Java patterns but the replacement syntax of Perl5: `\1` for a backreference and the case modifiers `\u \l \U \L \E`.
* Perl5 specific syntax has to be rewritten for Java, for example the POSIX classes `[[:alpha:]]` become `\p{Alpha}`.

The engine matrix tests in the Lucee repository (`test/general/regex`) show how the engines behave for the same patterns.

## Request timeout

A regex that runs for a long time (catastrophic backtracking) is stopped when the request timeout interrupts the request, the same as the `java` engine in Lucee. This needs a patched copy of Apache ORO, which is part of the extension source (package `org.lucee.extension.perlregex.oro`).

## Third party

This product includes software developed by the Apache Software Foundation (http://www.apache.org/): Jakarta-ORO 2.0.8, Copyright (c) 2000 The Apache Software Foundation, under the Apache Software License, Version 1.1. The license text is kept in the header of every ORO source file.

Issues: https://luceeserver.atlassian.net/browse/LDEV-6632
