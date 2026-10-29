<cfscript>
	str = "The quick brown Fox jumps over the lazy dog, fox@example.com and DOG@example.org";
	res = {};
	res.reFind = reFind( "[a-z]+@[a-z]+\.com", str );
	res.reFindOffset = reFind( "o", str, 20 );
	res.reFindNoMatch = reFind( "zzz", str );
	res.reFindNoCase = reFindNoCase( "fox", str );
	res.reFindSub = reFind( "([a-z]+)@([a-z]+)\.com", str, 1, true );
	res.reFindAll = reFind( "o", str, 1, false, "all" );
	res.reMatch = reMatch( "[a-z]+@[a-z]+\.[a-z]+", str );
	res.reMatchNoCase = reMatchNoCase( "[a-z]+@[a-z]+\.[a-z]+", str );
	res.reReplace = reReplace( str, "o", "0" );
	res.reReplaceAll = reReplace( str, "o", "0", "all" );
	res.reReplaceNoCaseAll = reReplaceNoCase( str, "dog", "cat", "all" );
	res.reReplaceBackRef = reReplace( str, "([a-z]+)@([a-z]+)\.com", "\2 at \1" );
	res.isValid = isValid( "regex", "abc123", "^[a-z]+[0-9]+$" );
	res.posix = reFind( "[[:alpha:]]+", "123bcd" );
	// the ticket pattern on a normal input still matches
	res.ticketPattern = reReplace( "mail all@tricksman.com now", "([[:alnum:]_\.\-]+@([[:alnum:]_\.\-]+\.)+[[:alpha:]]{2,4})", "<\1>", "all" );
	writeOutput( serializeJSON( res ) );
</cfscript>
