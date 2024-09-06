package tools;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class WhitespaceCleaner extends SimpleFileVisitor<Path> {

	private static final class Config {

		static final Config DEFAULT = new Config(Collections.emptyList(), 4);

		private final List<Matcher> nameMatchers;

		final int tabstop;

		private Config(List<Matcher> nameMatchers, int tabstop) {
			super();
			this.nameMatchers = nameMatchers;
			this.tabstop = tabstop;
		}

		boolean nameMatches(Path file) {
			if (nameMatchers.isEmpty()) {
				return true;
			}

			String name = file.toString();

			for (Matcher matcher : nameMatchers) {
				if (matcher.reset(name).matches()) {
					return true;
				}
			}

			return false;
		}

		Config withName(String namePattern) {
			List<Matcher> newMatchers = new ArrayList<>(nameMatchers);

			newMatchers.add(Pattern.compile(namePattern).matcher(""));

			return new Config(newMatchers, tabstop);
		}

		Config withTabstop(int width) {
			return new Config(nameMatchers, width);
		}

	}

	private static final Pattern LINE_PATTERN = Pattern.compile("^(\\s*)(.*?)\\s*$");

	public static void main(String[] args) {
		Config config = Config.DEFAULT;

		for (String arg : args) {
			if (arg.startsWith("--name=")) {
				config = config.withName(arg.substring(7));
			} else if (arg.startsWith("--tab=")) {
				try {
					int tabstop = Integer.parseInt(arg.substring(6));

					if (tabstop < 1) {
						System.err.format("Tabstop (%s) must be positive%n", arg);
						System.exit(1);
					}

					config = config.withTabstop(tabstop);
				} catch (NumberFormatException e) {
					System.err.format("Tabstop (%s) must be an integer%n", arg);
					System.exit(1);
				}
			} else {
				WhitespaceCleaner cleaner = new WhitespaceCleaner(config);

				System.out.format("Cleaning %s ...%n", arg);

				try {
					Files.walkFileTree(Path.of(arg), cleaner);
				} catch (IOException e) {
					System.err.format("Could not clean %s:%n", arg);
					e.printStackTrace();
					System.exit(1);
				}
			}
		}
	}

	private static String makeIndentFor(int width, int tabstop) {
		char[] result;

		if (tabstop == 1) {
			result = new char[width];

			Arrays.fill(result, 0, width, ' ');
		} else {
			int tabs = width / tabstop;
			int spaces = width % tabstop;

			result = new char[tabs + spaces];

			Arrays.fill(result, 0, tabs, '\t');
			Arrays.fill(result, tabs, result.length, ' ');
		}

		return new String(result);
	}

	private static int widthOf(String input, int tabstop) {
		int width = 0;

		for (int index = 0, length = input.length(); index < length; ++index) {
			switch (input.charAt(index)) {
			case ' ':
				width += 1;
				break;
			case '\t':
				width += tabstop - (width % tabstop);
				break;
			default:
				throw new IllegalArgumentException(input);
			}
		}

		return width;
	}

	private final Config config;

	private final Map<Integer, String> indents;

	private WhitespaceCleaner(Config config) {
		super();
		this.config = config;
		this.indents = new HashMap<>();
	}

	private void cleanFile(Path file) throws IOException {
		List<String> lines = new ArrayList<>();

		try (BufferedReader in = Files.newBufferedReader(file)) {
			Matcher matcher = LINE_PATTERN.matcher("");
			boolean needBlank = false;
			boolean nonEmpty = false;

			for (String line; (line = in.readLine()) != null;) {
				matcher.reset(line);

				// no need to check (LINE_PATTERN matches any string)
				matcher.matches();

				String content = matcher.group(2);

				if (content.isEmpty()) {
					needBlank = nonEmpty;
				} else {
					if (needBlank) {
						lines.add("");
						needBlank = false;
					}
					nonEmpty = true;

					int width = widthOf(matcher.group(1), config.tabstop);

					if (width == 0) {
						lines.add(content);
					} else {
						lines.add(indentFor(width).concat(content));
					}
				}
			}
		}

		Files.write(file, lines);
	}

	private String indentFor(int width) {
		return indents.computeIfAbsent(Integer.valueOf(width), i -> makeIndentFor(width, config.tabstop));
	}

	@Override
	public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
		if (attrs.isRegularFile() && config.nameMatches(file)) {
			cleanFile(file);
		}

		return FileVisitResult.CONTINUE;
	}

}
