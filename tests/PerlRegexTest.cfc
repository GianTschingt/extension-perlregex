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
				expect( len( msg ) ).toBeGT( 0 );
			} );

		} );

	}

}
