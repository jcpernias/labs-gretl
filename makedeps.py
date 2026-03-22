import argparse
import io
import re
import os

class GretlScanner:
    """Scans Gretl script files to identify file dependencies.

    It detects:
    - The working directory (`set workdir`)
    - Input data files (`open`)
    - Output files (`outfile`)
    - Figure files generated with gnuplot (`gnuplot --output=`)
    - Coorelogram figure files  (`corrgm --plot=`)

    It also handles Gretl-style line and block comments and manages line
    continuations.

    Attributes:
        source (iterable): Source of lines from the script file.
        datafiles (set): Set of normalized paths to data input files.
        outfiles (set): Set of normalized paths to output files.
        figfiles (set): Set of normalized paths to figure files.
        comment_block (bool): Flag for tracking multi-line comment blocks.

    """

    # Regex to match specific Gretl commands and extract file paths
    GRETL_PATTERN = re.compile(r'''
    ^\s*                        # Allow spaces
    (?:set\s+(workdir)|(open)|(outfile)|(gnuplot)|(corrgm)) # Command
    \s+                         # Some spaces
    (?:(?(4).*--output=))       # gnuplot file
    (?:(?(5).*--plot=))         # gnuplot file
    (?:"([^"]+)"|([^"\s]+)      # name without quotes
    (?:\s|$))                   # a space or end of line
    ''', re.X)

    # Regex to identify and optionally remove comments or strings
    COMMENT_PATTERN = re.compile(r'''
    ("[^"]*")|                  # String
    (/\*(?:[^*]|\*(?!/))*\*/)|  # Delimited comment
    (\#.*$)|                    # Line comment
    (/\*(?:[^*]|\*(?!/))*$)     # Incomplete delimited comment
    ''', re.X)

    def __init__(self, source):
        self.source = source
        self.datafiles = set()
        self.outfiles = set()
        self.figfiles = set()
        self.comment_block = False

    def delete_comments(self, line):
        """Removes comments from a line of code.

        Handles multi-line and single-line comments. Quoted strings
        are preserved.

        Returns a tuple: (cleaned_line, is_continuation)
        """

        # Handle multiple line comment blocks
        if self.comment_block:
            parts = line.split('*/', maxsplit = 1)
            if len(parts) == 1:
                return('', False)
            else:
                self.comment_block = False
                line = parts[1]

        # Scan line
        start = 0
        end = 0
        parts = []
        while True:
            mobj = GretlScanner.COMMENT_PATTERN.search(line, start)
            if not mobj:        # No match in the rest of the line
                parts.append(line[start:])
                break
            if mobj[1]:         # Found a string
                end = mobj.end()
                parts.append(line[start:end])
                start = end
            elif mobj[2]:       # Found a delimited comment
                end = mobj.start()
                parts.append(line[start:end])
                start = mobj.end()
            elif mobj[3]:       # Found a line comment
                end = mobj.start()
                parts.append(line[start:end])
                return (' '.join(parts), False)
            elif mobj[4]:       # Found the start of a block comment
                end = mobj.start()
                parts.append(line[start:end])
                self.comment_block = True
                return (' '.join(parts), False)

        line = ' '.join(parts).rstrip()

        # Check line continuation char
        line_cont = len(line) and line[-1] == '\\'
        if line_cont:
            line = line[:-1] + ' '
        return (line, line_cont)

    def lines(self):
        """Generator function that yields logical lines.

        Yields a str: A complete line of code after removing comments
           and joining continued lines.
        """

        result = ''
        while True:
            try:
                line = next(self.source)
            except StopIteration:
                return

            # Remove line comments
            line, line_cont = self.delete_comments(line)
            result += line

            # Check continuation line char
            if not line_cont:
                yield result
                result = ''

    def parse_line(self, line):
        """Parses a single logical line.

        It uses the GRETL_PATTERN to identify known commands and
        associated file paths.

        Args: line (str): A logical line without comments.

        Returns a tuple: (command, path) if matched, otherwise (None, None)
        """

        mobj = GretlScanner.GRETL_PATTERN.match(line)
        if mobj is None:
            return (None, None)
        return tuple(x for x in mobj.groups() if x is not None)

    def norm_path(self, workdir, path):
        """Normalizes file paths relative to current workdir.

        Args:
            workdir (str): The current workdir.
            path (str): A path from the script.

        Returns a str: Normalized path.
        """
        return os.path.normpath(os.path.join(workdir, path))

    def parse(self):
        """Parses a Gretl script.

        It scans the source and populate datafiles, outfiles, and figfiles.

        Returns:
            self: Allows for method chaining.
        """

        workdir = ''
        for line in self.lines():
            match self.parse_line(line):
                case ('workdir', path):
                    workdir = path
                case ('open', path):
                    self.datafiles.add(self.norm_path(workdir, path))
                case ('outfile', path):
                    self.outfiles.add(self.norm_path(workdir, path))
                case ('gnuplot', path):
                    self.figfiles.add(self.norm_path(workdir, path))
                case ('corrgm', path):
                    self.figfiles.add(self.norm_path(workdir, path))
        return self


def dependency_rules(base_name, input_file, outfiles, datafiles, figfiles):
    gretl_out_str = f"{base_name}-gretl-output"
    intermediate_str = f"{gretl_out_str}.intermediate"

    out_str = io.StringIO()
    print(f"$(deps-dir)/{base_name}.d: {input_file}\n", file = out_str)
    print(f"{gretl_out_str} := \\", file = out_str)
    print(" \\\n".join({f"\t{x}" for x in outfiles.union(figfiles)}),
          file = out_str)

    print(f"\n$({gretl_out_str}): {intermediate_str}\n\t@:\n", file = out_str)
    print(f".INTERMEDIATE: {intermediate_str}\n{intermediate_str}:\\",
          file = out_str)
    print(" \\\n".join([f"\t{x}" for x in [input_file] + [x for x in datafiles]]),
          file = out_str)
    print("\tgretlcli -b -e $(realpath $<)\n", file = out_str)
    print(f"$(pdf-dir)/{base_name}-ans.pdf: \\", file = out_str)
    print(f"\t$(patsubst %.plt,%.pdf,$({gretl_out_str}))", file = out_str)

    rules = out_str.getvalue()
    out_str.close()
    return rules

def get_base_name(path):
    fname = os.path.basename(args.file)
    return os.path.splitext(fname)[0]

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('file', help='input file')
    parser.add_argument("-o", "--out", help="output file")

    args = parser.parse_args()
    input_path = args.file
    output_path = args.out

    with open(input_path, 'r') as fin:
        scanner = GretlScanner(fin).parse()

    rules = dependency_rules(get_base_name(args.file), input_path,
                             scanner.outfiles, scanner.datafiles,
                             scanner.figfiles)

    out = open(output_path, "w") if output_path else None
    print(rules, file = out)
    if out:
        out.close()
