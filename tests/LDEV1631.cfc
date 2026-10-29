component extends="org.lucee.cfml.test.LuceeTestCase" labels="perlregex" {

	function beforeAll() {
		variables.uri = "/testAdditional/LDEV1631";
	}

	function run( testResults, testBox ) {

		describe( "LDEV-1631: the perl engine is stopped when the thread is interrupted (request timeout)", function() {

			var fns = [ "reFind", "reFindNoCase", "reFindSub", "reFindAll", "reMatch", "reMatchNoCase", "reReplace", "reReplaceNoCase", "isValid" ];
			loop array=fns item="local.fn" {
				( function( fn ) {
					it( title="#fn# with catastrophic backtracking is stopped by an interrupt", body=function( currentSpec ) {
						var res = runInterrupted( fn, "nested" );
						expect( res.stopped ).toBeTrue( res.message );
						expect( res.message ).toInclude( "interrupted" );
						// interrupted after 500ms
						expect( res.ms ).toBeLT( 10000 );
					});
				} )( fn );
			}

			it( title="the regex of the ticket (email pattern on a string with many dots) never runs on after an interrupt", body=function( currentSpec ) {
				var res = runInterrupted( "reReplace", "ticket" );
				// the pattern is either stopped by the interrupt or finishes by itself, it must never run on
				expect( res.ms ).toBeLT( 10000 );
				if ( res.stopped ) expect( res.message ).toInclude( "interrupted" );
			});

			it( title="a regular request after an interrupted regex works as before", body=function( currentSpec ) {
				var result = _InternalRequest(
					template: "#variables.uri#/results.cfm"
				);
				expect( isJson( result.filecontent ) ).toBeTrue();
			});

		});

		describe( "LDEV-1631: results of the perl engine are unchanged", function() {

			it( title="reFind, reMatch, reReplace and isValid return the same results as before", body=function( currentSpec ) {
				var result = _InternalRequest(
					template: "#variables.uri#/results.cfm"
				);
				var actual = deserializeJSON( result.filecontent );
				var expected = {
					"reFind": 46,
					"reFindOffset": 27,
					"reFindNoMatch": 0,
					"reFindNoCase": 17,
					"reFindSub": { "pos": [ 46, 46, 50 ], "len": [ 15, 3, 7 ], "match": [ "fox@example.com", "fox", "example" ] },
					"reFindAll": [ 13, 18, 27, 42, 47, 59, 78 ],
					"reMatch": [ "fox@example.com" ],
					"reMatchNoCase": [ "fox@example.com", "DOG@example.org" ],
					"reReplace": "The quick br0wn Fox jumps over the lazy dog, fox@example.com and DOG@example.org",
					"reReplaceAll": "The quick br0wn F0x jumps 0ver the lazy d0g, f0x@example.c0m and DOG@example.0rg",
					"reReplaceNoCaseAll": "The quick brown Fox jumps over the lazy cat, fox@example.com and cat@example.org",
					"reReplaceBackRef": "The quick brown Fox jumps over the lazy dog, example at fox and DOG@example.org",
					"isValid": true,
					"posix": 4,
					"ticketPattern": "mail <all@tricksman.com> now"
				};
				expect( structCount( actual ) ).toBe( structCount( expected ) );
				loop struct=expected index="local.key" item="local.value" {
					expect( actual[ key ] ).toBe( value, key );
				}
			});

		});
	}


	private struct function runInterrupted( required string fn, required string pattern ) {
		var result = _InternalRequest(
			template: "#variables.uri#/interrupt.cfm",
			urls: { pattern: arguments.pattern, fn: arguments.fn, len: 60 }
		);
		expect( isJson( result.filecontent ) ).toBeTrue( result.filecontent );
		return deserializeJSON( result.filecontent );
	}

}
