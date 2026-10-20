component extends="org.lucee.cfml.test.LuceeTestCase" labels="perlregex" {

	function beforeAll() {
		variables.origRegex = getApplicationSettings().regex;
	}

	function afterAll() {
		application action="update" regex=variables.origRegex;
	}

	function run( testResults, testBox ) {

		describe( "Perl Regex extension (engine perl, Apache ORO)", function() {

			// the matchers of the test framework use regex themselves, so evaluate with the engine and compare afterwards
			function withEngine( type, fn ) {
				application action="update" regex={ type: arguments.type };
				try {
					return arguments.fn();
				}
				finally {
					application action="update" regex=variables.origRegex;
				}
			}

			it( title="perl is registered and reported as the active engine", body=function( currentSpec ) {
				var type = withEngine( "perl", function() {
					return getApplicationSettings().regex.type;
				} );
				expect( type ).toBe( "perl" );
			} );

			it( title="the engine understands Perl5 specific syntax (POSIX classes), java does not", body=function( currentSpec ) {
				var perl = withEngine( "perl", function() {
					return reFind( "[[:alpha:]]+", "123bcd" );
				} );
				var java = withEngine( "java", function() {
					return reFind( "[[:alpha:]]+", "123bcd" );
				} );
				expect( perl ).toBe( 4 );
				expect( java ).toBe( 0 );
			} );

			it( title="the names perl5, classic and oro select the same engine", body=function( currentSpec ) {
				for ( var name in [ "perl", "perl5", "classic", "oro" ] ) {
					var found = withEngine( name, function() {
						return reFind( "[[:alpha:]]+", "123bcd" );
					} );
					expect( found ).toBe( 4 );
				}
			} );

			it( title="reReplace with backreferences, one and all", body=function( currentSpec ) {
				var res = withEngine( "perl", function() {
					return {
						one: reReplace( "abcabc", "(b)", "[\1]" ),
						all: reReplace( "abcabc", "(b)", "[\1]", "all" ),
						nocase: reReplaceNoCase( "ABC", "b", "x" )
					};
				} );
				expect( res.one ).toBe( "a[b]cabc" );
				expect( res.all ).toBe( "a[b]ca[b]c" );
				expect( res.nocase ).toBe( "AxC" );
			} );

			it( title="reFind with returnSubExpressions returns pos, len and match per group", body=function( currentSpec ) {
				var res = withEngine( "perl", function() {
					return reFind( "(\d+)-(\d+)", "tel 12-345 x", 1, true );
				} );
				expect( res.pos ).toBe( [ 5, 5, 8 ] );
				expect( res.len ).toBe( [ 6, 2, 3 ] );
				expect( res.match ).toBe( [ "12-345", "12", "345" ] );
			} );

			it( title="reMatch, reFind all positions and reEscape", body=function( currentSpec ) {
				var res = withEngine( "perl", function() {
					return {
						matches: reMatch( "\d+", "a1b22c333" ),
						escaped: reEscape( "a.b?c" )
					};
				} );
				expect( res.matches ).toBe( [ "1", "22", "333" ] );
				expect( res.escaped ).toBe( "a\.b\?c" );
			} );

			it( title="reEscape escapes the characters of the Perl5 syntax", body=function( currentSpec ) {
				var samples = {
					"lucee": "lucee",
					"lucee?[]^": "lucee\?\[\]\^",
					"/s/acf/lucee": "\/s\/acf\/lucee",
					"1": "1",
					"": "",
					" ": "\ "
				};
				var escaped = withEngine( "perl", function() {
					var res = {};
					for ( var input in samples ) {
						res[ input ] = reEscape( input );
					}
					res.member = "lucee?[]^".reEscape();
					return res;
				} );
				for ( var input in samples ) {
					expect( escaped[ input ] ).toBe( samples[ input ] );
				}
				expect( escaped.member ).toBe( "lucee\?\[\]\^" );
			} );

			it( title="start offset, no match and all positions", body=function( currentSpec ) {
				var res = withEngine( "perl", function() {
					return {
						offset5: reFind( "b+", "abbbcbb", 5 ),
						offset3: reFind( "b+", "abbbcbb", 3 ),
						beyond: reFind( ".", "abc", 10 ),
						none: reFind( "x", "abc", 1, true ),
						all: reFind( "b", "abcb", 1, false, "all" )
					};
				} );
				expect( res.offset5 ).toBe( 6 );
				expect( res.offset3 ).toBe( 3 );
				expect( res.beyond ).toBe( 0 );
				expect( res.none.pos ).toBe( [ 0 ] );
				expect( res.none.len ).toBe( [ 0 ] );
				expect( res.none.match ).toBe( [ "" ] );
				expect( res.all ).toBe( [ 2, 4 ] );
			} );

			it( title="multiLine changes the meaning of ^", body=function( currentSpec ) {
				var text = "a" & chr( 10 ) & "b";
				var res = withEngine( "perl", function() {
					return {
						single: reFind( "^b", text, 1, false, "one", false ),
						multi: reFind( "^b", text, 1, false, "one", true )
					};
				} );
				expect( res.single ).toBe( 0 );
				expect( res.multi ).toBe( 3 );
			} );

			it( title="case insensitive find and match", body=function( currentSpec ) {
				var res = withEngine( "perl", function() {
					return {
						find: reFindNoCase( "B+", "aBBc" ),
						sensitive: reFind( "B+", "abbc" ),
						matches: reMatchNoCase( "b+", "aBbc xBB" ),
						sub: reFindNoCase( "(B)(C)", "abc", 1, true )
					};
				} );
				expect( res.find ).toBe( 2 );
				expect( res.sensitive ).toBe( 0 );
				expect( res.matches ).toBe( [ "Bb", "BB" ] );
				expect( res.sub.match ).toBe( [ "bc", "b", "c" ] );
			} );

			// the replacement text is escaped by the engine, only \1 style backreferences and \u \l \U \L \E are special
			it( title="replacement text: + ? $ ^ and backslashes are literal", body=function( currentSpec ) {
				var res = withEngine( "perl", function() {
					return {
						plus: reReplace( "aBc", "(B)", "+" ),
						question: reReplace( "aBc", "(B)", "?" ),
						dollar: reReplace( "aBc", "(B)", "$" ),
						dollar1: reReplace( "aBc", "(B)", "$1" ),
						caret: reReplace( "aBc", "(B)", "^" ),
						backref: reReplace( "aBc", "(B)", "\1" ),
						escapedBackref: reReplace( "aBc", "(B)", "\\1" ),
						singleBackslash: reReplace( "aBc", "(B)", "\" ),
						mixed: reReplace( "aBc", "(B)", "<\1+?>" )
					};
				} );
				expect( res.plus ).toBe( "a+c" );
				expect( res.question ).toBe( "a?c" );
				expect( res.dollar ).toBe( "a$c" );
				expect( res.dollar1 ).toBe( "a$1c" );
				expect( res.caret ).toBe( "a^c" );
				expect( res.backref ).toBe( "aBc" );
				expect( res.escapedBackref ).toBe( "a\Bc" );
				expect( res.singleBackslash ).toBe( "a\c" );
				expect( res.mixed ).toBe( "a<B+?>c" );
			} );

			it( title="replacement text: case modifiers", body=function( currentSpec ) {
				var res = withEngine( "perl", function() {
					return {
						upperFirst: reReplace( "hello", "(.+)", "\u\1" ),
						lowerFirst: reReplace( "HELLO", "(.+)", "\l\1" ),
						upperGroup: reReplace( "helloworld", "(hello)(world)", "\U\1\E\2" ),
						lowerGroup: reReplace( "HELLOWORLD", "(hello)(world)", "\L\1\E\2" ),
						unterminated: reReplace( "hello world", "(.+)", "\U\1" ),
						escapedUpper: reReplace( "aBc", "(B)", "\\U\1" )
					};
				} );
				expect( res.upperFirst ).toBe( "Hello" );
				expect( res.lowerFirst ).toBe( "hELLO" );
				expect( res.upperGroup ).toBe( "HELLOworld" );
				expect( res.lowerGroup ).toBe( "helloWORLD" );
				expect( res.unterminated ).toBe( "HELLO WORLD" );
				expect( res.escapedUpper ).toBe( "a\Bc" );
			} );

			it( title="an invalid pattern throws an error that names the pattern", body=function( currentSpec ) {
				var msg = withEngine( "perl", function() {
					try {
						reFind( "(unclosed", "text" );
						return "";
					}
					catch ( any e ) {
						return e.message;
					}
				} );
				expect( msg ).toInclude( "(unclosed" );
			} );

		} );

	}

}
