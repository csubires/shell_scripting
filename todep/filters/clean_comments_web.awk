# ============================================
# clean_comments.awk
# Robust comment and whitespace cleaner
# Supports: //, /* */, #, <!-- -->
# Keeps URLs like http:// or https://
# Preserves C/C++ preprocessor lines (#define, #include, etc.)
# Removes inline comments after code, trailing spaces, and empty lines.
# ============================================

BEGIN {
    inside_multiline = 0
}

{
    line = $0

    # Remove trailing spaces
    sub(/[[:space:]]+$/, "", line)

    # Skip empty lines early
    if (length(line) == 0) next

    # --- Handle multiline comment blocks ---
    if (inside_multiline) {
        if (match(line, /\*\//) || match(line, /-->/)) {
            inside_multiline = 0
            # Remove everything after closing token
            line = substr(line, RSTART + RLENGTH)
        } else {
            next
        }
    }

    # --- Remove inline block comments like /* ... */ and <!-- ... --> ---
    while (match(line, /\/\*[^*]*\*\//)) {
        line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    }
    while (match(line, /<!--[^-]*-->/)) {
        line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    }

    # --- Detect start of multiline comment ---
    if (match(line, /\/\*/)) {
        inside_multiline = 1
        line = substr(line, 1, RSTART - 1)
    } else if (match(line, /<!--/)) {
        inside_multiline = 1
        line = substr(line, 1, RSTART - 1)
    }

    # --- Remove // comments ---
    # Only remove if NOT part of '://'
    if (match(line, /\/\/[[:space:]]/)) {
        # Ensure it's not inside a URL
        pos = RSTART
        if (pos <= 1 || substr(line, pos-1, 1) != ":") {
            line = substr(line, 1, pos - 1)
        }
    } else {
        # Handle cases where // has no space but is clearly not URL (e.g., ;//)
        # Look for ;//, ){//, or start-of-line //
        if (match(line, /(^|[^:])\/\/(?!\/)/)) {
            pos = RSTART + (RLENGTH - 2) # find start of //
            # Remove if not URL (e.g., https://)
            if (substr(line, pos-1, 1) != ":") {
                line = substr(line, 1, pos - 1)
            }
        }
    }

    # --- Remove hash (#) comments (not preprocessor) ---
# Preserve preprocessor lines starting with #
if (match(line, /#/)) {
    # Only remove if # is NOT at the start
    if (substr(line, 1, 1) != "#") {
        pos = index(line, "#")
        line = substr(line, 1, pos - 1)
    }
}

    # --- Final cleanup ---
    sub(/[[:space:]]+$/, "", line)
    if (length(line) > 0) print line
}
