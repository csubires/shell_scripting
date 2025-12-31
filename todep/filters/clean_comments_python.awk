# ============================================
# clean_comments.awk
# Robust comment and whitespace cleaner
# Supports: //, /* */, #, <!-- -->
# Keeps URLs like http:// or https:// (because // is not followed by a space)
# Preserves C/C++ preprocessor lines (#define, #include, etc.)
# ============================================

BEGIN {
    inside_multiline = 0
}

{
    line = $0

    # Remove trailing spaces
    sub(/[[:space:]]+$/, "", line)

    # Skip completely empty lines early
    if (length(line) == 0) next

    # --- Handle multiline comment blocks (we are inside one) ---
    if (inside_multiline) {
        if (match(line, /\*\//) || match(line, /-->/)) {
            inside_multiline = 0
            # Remove everything up to and including the closing token
            line = substr(line, RSTART + RLENGTH)
        } else {
            next
        }
    }

    # --- Remove inline block comments like /* ... */ and <!-- ... --> on same line ---
    # These while loops remove any fully-contained block comments on the same line.
    while (match(line, /\/\*[^*]*\*\//)) {
        line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    }
    while (match(line, /<!--[^-]*-->/)) {
        line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    }

    # --- Detect start of multiline comment that extends beyond this line ---
    if (match(line, /\/\*/)) {
        inside_multiline = 1
        line = substr(line, 1, RSTART - 1)
    } else if (match(line, /<!--/)) {
        inside_multiline = 1
        line = substr(line, 1, RSTART - 1)
    }

    # --- Remove // comments ONLY if the char immediately after // is a space or tab ---
    # This keeps URLs like "https://..." intact.
    if (index(line, "//") != 0) {
        pos = index(line, "//")
        # get the character after the '//' (may be empty if // is at end)
        nextchar = substr(line, pos+2, 1)
        if (nextchar == " " || nextchar == "\t") {
            # remove from '//' to end
            if (pos > 1) {
                line = substr(line, 1, pos - 1)
            } else {
                line = ""    # starts with // and it's a comment
            }
        }
    }

    # --- Remove hash (#) comments (not preprocessor or URLs) ---
    if (match(line, /#[[:space:]]/) && \
        line !~ /^#(define|include|ifdef|ifndef|endif|pragma|else|elif)/) {
        pos = index(line, "#")
        line = substr(line, 1, pos - 1)
    }

    # --- Final cleanup of trailing spaces ---
    sub(/[[:space:]]+$/, "", line)

    # Print only non-empty lines
    if (length(line) > 0) {
        print line
    }
}
