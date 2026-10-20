package org.lucee.extension.perlregex;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.oro.text.regex.MalformedPatternException;
import org.apache.oro.text.regex.MatchResult;
import org.apache.oro.text.regex.Pattern;
import org.apache.oro.text.regex.PatternMatcherInput;
import org.apache.oro.text.regex.Perl5Compiler;
import org.apache.oro.text.regex.Perl5Matcher;
import org.apache.oro.text.regex.Perl5Substitution;
import org.apache.oro.text.regex.Util;

import lucee.loader.engine.CFMLEngine;
import lucee.loader.engine.CFMLEngineFactory;
import lucee.runtime.exp.PageException;
import lucee.runtime.regex.Regex;
import lucee.runtime.type.Array;
import lucee.runtime.type.Struct;

/**
 * The Perl5 regular expression engine of Lucee, based on Apache ORO. It was part of the Lucee core
 * until Lucee 8.
 */
public class Perl5Regex implements Regex {

	private static final Map<String, Pattern> patterns = new ConcurrentHashMap<>();

	private static CFMLEngine engine() {
		return CFMLEngineFactory.getInstance();
	}

	@Override
	public boolean matches(String strPattern, String strInput) throws PageException {
		try {
			return _matches(strPattern, strInput);
		}
		catch (MalformedPatternException e) {
			throw engine().getExceptionUtil().createExpressionException("The provided pattern [" + strPattern + "] is invalid", e.getMessage());
		}
	}

	@Override
	public boolean matches(String strPattern, String strInput, boolean defaultValue) {
		try {
			return _matches(strPattern, strInput);
		}
		catch (MalformedPatternException e) {
			return defaultValue;
		}
	}

	private static boolean _matches(String strPattern, String strInput) throws MalformedPatternException {
		Pattern pattern = new Perl5Compiler().compile(strPattern, Perl5Compiler.DEFAULT_MASK);
		PatternMatcherInput input = new PatternMatcherInput(strInput);
		return new Perl5Matcher().matches(input, pattern);
	}

	@Override
	public String match(String strPattern, String strInput, int offset, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return (String) match(strPattern, strInput, offset, caseSensitive, false, multiLine);
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public Array matchAll(String strPattern, String strInput, int offset, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return (Array) match(strPattern, strInput, offset, caseSensitive, true, multiLine);
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public int indexOf(String strPattern, String strInput, int offset, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return ((Number) indexOf(strPattern, strInput, offset, caseSensitive, false, multiLine)).intValue();
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public Object indexOfAll(String strPattern, String strInput, int offset, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return indexOf(strPattern, strInput, offset, caseSensitive, true, multiLine);
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public Struct find(String strPattern, String strInput, int offset, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return (Struct) find(strPattern, strInput, offset, caseSensitive, false, multiLine);
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public Array findAll(String strPattern, String strInput, int offset, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return (Array) find(strPattern, strInput, offset, caseSensitive, true, multiLine);
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public String replace(String strInput, String strPattern, String replacement, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return replace(strInput, strPattern, replacement, caseSensitive, false, multiLine);
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public String replaceAll(String strInput, String strPattern, String replacement, boolean caseSensitive, boolean multiLine) throws PageException {
		try {
			return replace(strInput, strPattern, replacement, caseSensitive, true, multiLine);
		}
		catch (MalformedPatternException e) {
			throw engine().getCastUtil().toPageException(e);
		}
	}

	@Override
	public String escape(String strInput) throws PageException {
		return Perl5Compiler.quotemeta(strInput);
	}

	@Override
	public String getTypeName() {
		return "perl";
	}

	private static int toCompileOptions(boolean caseSensitive, boolean multiLine) {
		int compileOptions = caseSensitive ? 0 : Perl5Compiler.CASE_INSENSITIVE_MASK;
		compileOptions += multiLine ? Perl5Compiler.MULTILINE_MASK : Perl5Compiler.SINGLELINE_MASK;
		return compileOptions;
	}

	/**
	 * index of the first occurrence of the pattern, or of all occurrences as an array
	 */
	private static Object indexOf(String strPattern, String strInput, int offset, boolean caseSensitive, boolean matchAll, boolean multiLine) throws MalformedPatternException {
		PatternMatcherInput input = new PatternMatcherInput(strInput);
		Perl5Matcher matcher = new Perl5Matcher();

		if (offset < 1) offset = 1;

		Pattern pattern = getPattern(strPattern, toCompileOptions(caseSensitive, multiLine));

		if (offset <= strInput.length()) {
			input.setCurrentOffset(offset - 1);

			Array matches = null;
			while (matcher.contains(input, pattern)) {
				int match = matcher.getMatch().beginOffset(0) + 1;
				if (!matchAll) {
					return Double.valueOf(match);
				}

				if (matches == null) matches = engine().getCreationUtil().createArray();
				matches.appendEL(match);
			}

			if (matches != null) {
				return matches;
			}
		}
		return 0;
	}

	private static Object match(String strPattern, String strInput, int offset, boolean caseSensitive, boolean matchAll, boolean multiLine) throws MalformedPatternException {
		Perl5Matcher matcher = new Perl5Matcher();
		PatternMatcherInput input = new PatternMatcherInput(strInput);

		if (offset < 1) offset = 1;

		Pattern pattern = getPattern(strPattern, toCompileOptions(caseSensitive, multiLine));
		if (offset <= strInput.length()) input.setCurrentOffset(offset - 1);

		Array rtn = matchAll ? engine().getCreationUtil().createArray() : null;
		MatchResult result;
		while (matcher.contains(input, pattern)) {
			result = matcher.getMatch();
			if (!matchAll) return result.toString();
			rtn.appendEL(result.toString());
		}
		if (!matchAll) return "";
		return rtn;
	}

	/**
	 * find occurrence of a pattern in a string (same like indexOf), but return a struct with all
	 * information
	 */
	private static Object find(String strPattern, String strInput, int offset, boolean caseSensitive, boolean matchAll, boolean multiLine) throws MalformedPatternException {
		CFMLEngine eng = engine();
		Perl5Matcher matcher = new Perl5Matcher();
		PatternMatcherInput input = new PatternMatcherInput(strInput);
		Array matches = null;

		if (offset < 1) offset = 1;

		Pattern pattern = getPattern(strPattern, toCompileOptions(caseSensitive, multiLine));

		if (offset <= strInput.length()) {
			input.setCurrentOffset(offset - 1);

			while (matcher.contains(input, pattern)) {
				Struct matchStruct = getMatchStruct(matcher.getMatch(), strInput);
				if (!matchAll) {
					return matchStruct;
				}

				if (matches == null) matches = eng.getCreationUtil().createArray();
				matches.appendEL(matchStruct);
			}

			if (matches != null) {
				return matches;
			}
		}

		Array posArray = eng.getCreationUtil().createArray();
		Array lenArray = eng.getCreationUtil().createArray();
		Array matchArray = eng.getCreationUtil().createArray();
		posArray.appendEL(Integer.valueOf(0));
		lenArray.appendEL(Integer.valueOf(0));
		matchArray.appendEL("");

		Struct struct = eng.getCreationUtil().createStruct(Struct.TYPE_LINKED);
		struct.setEL("pos", posArray);
		struct.setEL("len", lenArray);
		struct.setEL("match", matchArray);

		if (matchAll) {
			matches = eng.getCreationUtil().createArray();
			matches.appendEL(struct);
			return matches;
		}

		return struct;
	}

	private static Struct getMatchStruct(MatchResult result, String input) {
		CFMLEngine eng = engine();
		int groupCount = result.groups();

		Array posArray = eng.getCreationUtil().createArray();
		Array lenArray = eng.getCreationUtil().createArray();
		Array matchArray = eng.getCreationUtil().createArray();
		int beginOff;
		int endOff;
		for (int i = 0; i < groupCount; i++) {
			beginOff = result.beginOffset(i);
			endOff = result.endOffset(i);
			if (beginOff == -1 && endOff == -1) {
				posArray.appendEL(Integer.valueOf(0));
				lenArray.appendEL(Integer.valueOf(0));
				matchArray.appendEL(null);
				continue;
			}
			posArray.appendEL(Integer.valueOf(beginOff + 1));
			lenArray.appendEL(Integer.valueOf(endOff - beginOff));
			matchArray.appendEL(input.substring(beginOff, endOff));
		}

		Struct struct = eng.getCreationUtil().createStruct(Struct.TYPE_LINKED);
		struct.setEL("pos", posArray);
		struct.setEL("len", lenArray);
		struct.setEL("match", matchArray);

		return struct;
	}

	private static Pattern getPattern(String strPattern, int type) throws MalformedPatternException {
		String key = strPattern + type;
		Pattern pattern = patterns.get(key);
		if (pattern == null) {
			pattern = new Perl5Compiler().compile(strPattern, type);
			patterns.put(key, pattern);
		}
		return pattern;
	}

	/**
	 * replace the first/all occurrence of given pattern
	 */
	private static String replace(String strInput, String strPattern, String replacement, boolean caseSensitive, boolean replaceAll, boolean multiLine) throws MalformedPatternException {
		return _replace(strInput, strPattern, escapeReplacement(replacement), caseSensitive, replaceAll, multiLine);
	}

	private static String _replace(String strInput, String strPattern, String replacement, boolean caseSensitive, boolean replaceAll, boolean multiLine)
			throws MalformedPatternException {
		Pattern pattern = getPattern(strPattern, toCompileOptions(caseSensitive, multiLine));
		return Util.substitute(new Perl5Matcher(), pattern, new Perl5Substitution(replacement), strInput, replaceAll ? -1 : 1);
	}

	private static String escapeReplacement(String replacement) throws MalformedPatternException {
		// no char the steps below act on: all three would return the input unchanged
		if (!hasEscapable(replacement)) return replacement;
		replacement = _replace(replacement, "\\\\", "\\\\\\\\", false, true, false);
		replacement = _escape(replacement);
		replacement = _replace(replacement, "\\\\\\\\(\\d)", "\\$$1", false, true, false);
		return replacement;
	}

	private static boolean hasEscapable(String str) {
		char c;
		for (int i = 0, len = str.length(); i < len; i++) {
			c = str.charAt(i);
			if ('\\' == c || '+' == c || '?' == c || '$' == c || '^' == c) return true;
		}
		return false;
	}

	private static String _escape(String str) {
		StringBuilder sb = new StringBuilder();
		int len = str.length();
		char c;

		for (int i = 0; i < len; i++) {
			c = str.charAt(i);

			if ('+' == c) sb.append("\\+");
			else if ('?' == c) sb.append("\\?");
			else if ('$' == c) sb.append("\\$");
			else if ('^' == c) sb.append("\\^");
			else if ('\\' == c) {
				if (i + 1 < len) {
					char n = str.charAt(i + 1);
					if ('\\' == n) {
						if (i + 2 < len) {
							char nn = str.charAt(i + 2);
							char x = 0;
							if ('U' == nn) x = 'U';
							else if ('L' == nn) x = 'L';
							else if ('u' == nn) x = 'u';
							else if ('l' == nn) x = 'l';
							else if ('E' == nn) x = 'E';
							if (x != 0) {
								sb.append("\\" + x);
								i += 2;
								continue;
							}
						}
					}
				}
				sb.append(c);
			}
			else sb.append(c);
		}
		return sb.toString();
	}
}
