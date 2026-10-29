<cfscript>
	// runs a regex that backtracks (nearly) without limit in a separate thread and interrupts that thread after
	// half a second, which is what Lucee does to a request that reached its request timeout
	param name="url.fn" default="reFind";
	param name="url.pattern" default="nested";
	param name="url.len" default="60";

	server.ldev1631 = { javaThread: nullValue() };
	structDelete( server.ldev1631, "javaThread" );

	thread name="regexThread" fn=url.fn pattern=url.pattern len=url.len {
		server.ldev1631.javaThread = getPageContext().getThread();
		start = getTickCount();
		try {
			if ( attributes.pattern == "ticket" ) {
				// the example of LDEV-1631, an email address pattern that backtracks without limit on a string with many dots
				str = ".......................................All@tricksMan...............................................";
				pattern = "([[:alnum:]_\.\-]+@([[:alnum:]_\.\-]+\.)+[[:alpha:]]{2,4})";
				replacement = "<a class='autolink' href='mailto:\1'>\1</a>";
			}
			else {
				// nested quantifiers with a back reference, the number of steps doubles with every additional "a"
				str = repeatString( "a", val( attributes.len ) ) & "b";
				pattern = "(a+)+\1c";
				replacement = "x";
			}
			fn = attributes.fn;
			if ( fn == "reFind" ) reFind( pattern, str );
			else if ( fn == "reFindNoCase" ) reFindNoCase( pattern, str );
			else if ( fn == "reFindSub" ) reFind( pattern, str, 1, true );
			else if ( fn == "reFindAll" ) reFind( pattern, str, 1, false, "all" );
			else if ( fn == "reMatch" ) reMatch( pattern, str );
			else if ( fn == "reMatchNoCase" ) reMatchNoCase( pattern, str );
			else if ( fn == "reReplace" ) reReplace( str, pattern, replacement, "all" );
			else if ( fn == "reReplaceNoCase" ) reReplaceNoCase( str, pattern, replacement, "all" );
			else if ( fn == "isValid" ) isValid( "regex", str, "^" & pattern & "$" );
			else throw( message="unknown function [#fn#]" );
			thread.stopped = false;
			thread.message = "finished";
		}
		catch ( any e ) {
			thread.stopped = true;
			thread.message = e.message;
		}
		thread.ms = getTickCount() - start;
	}

	// wait until the thread is running, give the regex a moment to get into the backtracking, then interrupt
	waited = 0;
	while ( !structKeyExists( server.ldev1631, "javaThread" ) && waited < 5000 ) {
		sleep( 10 );
		waited += 10;
	}
	sleep( 500 );
	if ( structKeyExists( server.ldev1631, "javaThread" ) ) server.ldev1631.javaThread.interrupt();

	thread action="join" name="regexThread" timeout="15000";
	res = cfthread.regexThread;
	if ( res.status != "COMPLETED" ) {
		// the regex did not stop, do not leave a spinning thread behind
		thread action="terminate" name="regexThread";
		writeOutput( serializeJSON( { "stopped": false, "message": "the regex was not stopped by the interrupt", "ms": 15000 } ) );
	}
	else {
		writeOutput( serializeJSON( { "stopped": res.stopped, "message": res.message, "ms": res.ms } ) );
	}
</cfscript>
