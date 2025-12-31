#!/usr/bin/awk -f
# clean_comments_robust.awk
# Robust comment and whitespace cleaner that ignores comment tokens inside strings.

BEGIN {
    # persistent state across lines
    inside_multiline = 0         # 0 = no multiline comment open, 1 = inside
    multiline_end = ""          # token that ends multiline comment: "*/" or "-->"
    inside_single = 0           # inside single-quoted string '
    inside_double = 0           # inside double-quoted string "
    prev_was_backslash = 0      # for handling escapes inside strings
}

{
    raw = $0
    # remove trailing newline/keep raw as-is for parsing
    line = raw

    # remove trailing spaces for nicer output, but do parsing on original characters
    # we'll build out_line char-by-char
    out_line = ""

    # If currently inside a multiline comment, try to find its end in this line
    if (inside_multiline) {
        # look for end token
        pos = index(line, multiline_end)
        if (pos > 0) {
            # skip everything up to and including end token, continue parsing rest of line
            line = substr(line, pos + length(multiline_end))
            inside_multiline = 0
            multiline_end = ""
            # reset quote/escape state (strings don't continue over a comment)
            inside_single = 0
            inside_double = 0
            prev_was_backslash = 0
            # continue normally to parse remainder of line below
        } else {
            # whole line is inside comment -> skip
            next
        }
    }

    i = 1
    n = length(line)
    while (i <= n) {
        c = substr(line, i, 1)

        # handle escape state inside strings
        if (prev_was_backslash) {
            out_line = out_line c
            prev_was_backslash = 0
            i++
            continue
        }

        # toggle quote states (only if not inside the other type)
        if (c == "'" && !inside_double) {
            inside_single = !inside_single
            out_line = out_line c
            i++
            continue
        }
        if (c == "\"" && !inside_single) {
            inside_double = !inside_double
            out_line = out_line c
            i++
            continue
        }

        # if inside a quote and we see a backslash, set escape for next char
        if ((inside_single || inside_double) && c == "\\") {
            prev_was_backslash = 1
            out_line = out_line c
            i++
            continue
        }

        # If not inside any string, check for comment starts
        if (!inside_single && !inside_double) {

            # check for inline block comment start "/*"
            if (i < n && substr(line, i, 2) == "/*") {
                # start multiline comment; find if it ends later on same line
                endpos = index(substr(line, i+2), "*/")
                if (endpos > 0) {
                    # remove the whole /* ... */ from the line (i .. i+1+endpos+1)
                    # append text before i (already in out_line), skip comment
                    i = i + 2 + endpos + 1  # move i to char after */
                    # continue without adding comment text
                    continue
                } else {
                    # multiline comment continues to future lines
                    inside_multiline = 1
                    multiline_end = "*/"
                    # stop parsing rest of this line (anything after /* is removed)
                    break
                }
            }

            # check for HTML comment start "<!--"
            if (i <= n-3 && substr(line, i, 4) == "<!--") {
                # find closing "-->" on same line?
                endpos = index(substr(line, i+4), "-->")
                if (endpos > 0) {
                    i = i + 4 + endpos + 2
                    continue
                } else {
                    inside_multiline = 1
                    multiline_end = "-->"
                    break
                }
            }

            # check for '//' comment: only treat as comment if following char is space or tab
            if (i < n && substr(line, i, 2) == "//") {
                nextchar = substr(line, i+2, 1)
                if (nextchar == " " || nextchar == "\t") {
                    # drop rest of line
                    break
                } else {
                    # keep the '//' (likely URL like http://)
                    out_line = out_line substr(line, i, 2)
                    i += 2
                    continue
                }
            }

            # check for '#' comment: only if '#' followed by space (and not preprocessor)
            if (c == "#") {
                rest = substr(line, i)
                if (match(rest, /^#(define|include|ifdef|ifndef|endif|pragma|else|elif)/)) {
                    # it's a preprocessor-like directive at this position: keep it as-is
                    out_line = out_line rest
                    i = n + 1
                    break
                } else if (match(rest, /^#[[:space:]]/)) {
                    # it's a hash comment (and not inside quote) -> drop rest of line
                    break
                } else {
                    # keep the '#'
                    out_line = out_line c
                    i++
                    continue
                }
            }
        }

        # default: copy character
        out_line = out_line c
        i++
    }

    # final trim of trailing whitespace
    sub(/[[:space:]]+$/, "", out_line)

    if (length(out_line) > 0) print out_line
}
