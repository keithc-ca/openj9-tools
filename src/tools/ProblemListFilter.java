package tools;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/*
 *
 */
public class ProblemListFilter {

	private static final class Problem implements Comparable<Problem> {

		// com/sun/crypto/provider/Cipher/Blowfish/TestCipherBlowfish.java https://github.com/eclipse-openj9/openj9/issues/20343 generic-all
		private static final Pattern PATTERN = Pattern.compile("(\\S+)\\s+(\\S+)\\s+(\\S+)");

		private static int dotOrEnd(String string) {
			int index = string.indexOf('.');

			return (index >= 0) ? index : string.length();
		}

		static Problem parse(String line) {
			if (!(line.isEmpty() || line.startsWith("#"))) {
				Matcher matcher = PATTERN.matcher(line);

				if (matcher.matches()) {
					return new Problem(matcher.group(1), matcher.group(2), matcher.group(3));
				}
			}

			return null;
		}

		private final String platforms;

		private final String reason;

		private final String test;

		private Problem(String test, String reason, String platforms) {
			this.platforms = Stream.of(platforms.split(",")).sorted().collect(Collectors.joining(","));
			this.reason = reason;
			this.test = test;
		}

		@Override
		public int compareTo(Problem that) {
			String lhs = this.test;
			int lhsDot = dotOrEnd(lhs);
			String rhs = that.test;
			int rhsDot = dotOrEnd(rhs);

			// Compare the parts before the final '.', if any.
			int result = lhs.substring(0, lhsDot).compareToIgnoreCase(rhs.substring(0, rhsDot));

			if (result == 0) {
				// If the prefixes match, compare the suffixes.
				result = lhs.substring(lhsDot).compareToIgnoreCase(rhs.substring(rhsDot));
			}

			return result;
		}

		@Override
		public String toString() {
			return test + " " + reason + " " + platforms;
		}

	}

	private static boolean keepDuplicates = false;

	private static void filter(InputStream in, PrintStream out) throws IOException {
		List<Problem> pending = new ArrayList<>();
		Map<String, Boolean> duplicates = new TreeMap<>();

		try (InputStreamReader reader = new InputStreamReader(in, StandardCharsets.UTF_8);
				BufferedReader buffered = new BufferedReader(reader)) {
			for (;;) {
				String line = buffered.readLine();

				if (line == null) {
					break;
				}

				Problem problem = Problem.parse(line);

				if (problem != null) {
					boolean isDuplicate = duplicates.compute(problem.test,
							(key, value) -> Boolean.valueOf(value != null));

					if (keepDuplicates || !isDuplicate) {
						pending.add(problem);
					}
				} else {
					print(pending, out);
					pending.clear();
					System.out.println(line);
				}
			}
		} finally {
			print(pending, out);
			showDuplicates(duplicates, out);
		}
	}

	public static void main(String[] args) {
		String source = "<stdin>";
		try {
			if (args.length == 0) {
				filter(System.in, System.out);
			} else {
				for (String arg : args) {
					source = arg;
					try (InputStream file = new FileInputStream(source)) {
						filter(file, System.out);
					}
				}
			}
		} catch (IOException e) {
			System.err.format("%s: %s%n", source, e.getLocalizedMessage());
			System.exit(1);
		}
	}

	private static void print(List<Problem> pending, PrintStream out) {
		pending.stream().sorted().forEachOrdered(out::println);
	}

	private static void showDuplicates(Map<String, Boolean> duplicates, PrintStream out) {
		boolean first = true;
		for (Map.Entry<String, Boolean> entry : duplicates.entrySet()) {
			if (entry.getValue().booleanValue()) {
				if (first) {
					out.format("Duplicate tests:%n", keepDuplicates ? "" : " removed");
					first = false;
				}
				out.format("  %s%n", entry.getKey());
			}
		}
	}

}
