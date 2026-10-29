package org.lucee.extension.perlregex.oro;

/**
 * Called now and then by the {@link Perl5Matcher} while it is matching. An implementation throws a
 * RuntimeException to stop a match that takes too long, otherwise it returns. Not part of the
 * original Apache ORO library.
 */
public interface InterruptCheck {

	void check();
}
