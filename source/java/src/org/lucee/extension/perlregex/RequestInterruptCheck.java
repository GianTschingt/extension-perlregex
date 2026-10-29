package org.lucee.extension.perlregex;

import org.lucee.extension.perlregex.oro.InterruptCheck;

import lucee.loader.engine.CFMLEngine;
import lucee.loader.engine.CFMLEngineFactory;
import lucee.runtime.PageContext;
import lucee.runtime.exp.PageException;

/**
 * Stops a running match when the thread of the request is interrupted, which is what Lucee does
 * when the request timeout is reached. The match throws a PageRuntimeException, so the template
 * gets a regular exception (that can be caught) instead of a thread that never returns.
 */
final class RequestInterruptCheck implements InterruptCheck {

	private final PageContext pc;

	RequestInterruptCheck() {
		this.pc = CFMLEngineFactory.getInstance().getThreadPageContext();
	}

	@Override
	public void check() {
		if (!Thread.currentThread().isInterrupted()) return;

		// the interrupt flag stays set, so the code that runs after the exception knows about it as well
		CFMLEngine engine = CFMLEngineFactory.getInstance();
		String msg = "The thread was interrupted while processing a regular expression, the processing was stopped";
		if (pc != null) {
			long timeout = pc.getRequestTimeout();
			if (timeout > 0 && System.currentTimeMillis() - pc.getStartTime() >= timeout) {
				msg = "The request timeout of " + (timeout / 1000) + " seconds was reached while processing a regular expression, the processing was stopped";
			}
		}
		PageException pe = engine.getExceptionUtil().createApplicationException(msg);
		throw engine.getExceptionUtil().createPageRuntimeException(pe);
	}
}
