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
    original_line = line

    # Remove trailing spaces
    sub(/[[:space:]]+$/, "", line)

    # Skip empty lines early
    if (length(line) == 0) next

    # --- Handle multiline comment blocks ---
    if (inside_multiline) {
        if (match(line, /\*\//)) {
            inside_multiline = 0
            line = substr(line, RSTART + RLENGTH)
        } else if (match(line, /-->/)) {
            inside_multiline = 0
            line = substr(line, RSTART + RLENGTH)
        } else {
            next
        }
    }

    # --- Remove inline block comments like /* ... */ and <!-- ... --> ---
    while (match(line, /\/\*[^*]*\*\//)) {
        line = substr(line, 1, RSTART - 1) substr(line, RSTART + RLENGTH)
    }
    while (match(line, /<!--.*-->/)) {
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

    # If we're still inside multiline after processing, skip the line
    if (inside_multiline) {
        next
    }

    # --- Special handling for different file types ---
    
    # For Makefiles: remove # comments but preserve the line if it has content before #
    if (FILENAME ~ /Makefile|makefile|\.mk$/) {
        if (match(line, /#/)) {
            # Check if there's non-comment content before the #
            before_comment = substr(line, 1, RSTART - 1)
            gsub(/[[:space:]]/, "", before_comment)
            if (length(before_comment) > 0) {
                # There's content before #, keep only that part
                line = substr(line, 1, RSTART - 1)
            } else {
                # It's a pure comment line, skip it
                next
            }
        }
    }
    # For C/C++ preprocessor directives: preserve but remove inline comments
    else if (line ~ /^[[:space:]]*#/) {
        # Remove // comments from preprocessor lines
        if (match(line, /\/\//)) {
            pos = RSTART
            # Check if it's part of a URL
            if (pos > 1 && substr(line, pos-1, 1) == ":") {
                # It's a URL, don't remove
            } else {
                # Remove everything after //
                line = substr(line, 1, pos - 1)
            }
        }
        
        # Remove # comments from preprocessor lines (but not the directive itself)
        if (match(line, /[^#]#[^#]/)) {
            # Find the comment # that's not part of the directive
            pos = RSTART + 1  # +1 because we matched [^#]#
            # Remove everything after this #
            line = substr(line, 1, pos - 1)
        }
        
        # Final cleanup for preprocessor lines
        sub(/[[:space:]]+$/, "", line)
        if (length(line) > 0) print line
        next
    }
    # For regular code files: remove both // and # comments
    else {
        # --- Remove // comments ---
        # Only remove if NOT part of '://'
        if (match(line, /\/\//)) {
            pos = RSTART
            # Check if it's part of a URL
            if (pos > 1 && substr(line, pos-1, 1) == ":") {
                # It's a URL, don't remove
            } else {
                # Remove everything after //
                line = substr(line, 1, pos - 1)
            }
        }

        # --- Remove # comments (for non-preprocessor lines) ---
        if (match(line, /#/)) {
            pos = RSTART
            # Only remove if it's not the first character and not in a URL
            if (pos > 1 && substr(line, pos-1, 1) != ":") {
                line = substr(line, 1, pos - 1)
            }
        }
    }

    # --- Final cleanup ---
    sub(/[[:space:]]+$/, "", line)
    if (length(line) > 0) print line
}