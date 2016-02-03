BEGIN {
    out_text = ""
}

# Thematic break (Setext heading for '---' takes precedence!)
/^( |  |   )?(\* *\* *\* *(\* *)*|- *- *- *(- *)*|_ *_ *_ *(_ *)*)[ \t]*$/ \
{
    close_blocks()
    oprint("<hr \\>\n")
    next
    # TODO: thematic breaks in list items
}

# ATX headings
/^( |  |   )?(#|##|###|####|#####|######)( .*)?$/ {
    close_blocks()
    line = $0
    match(line, /##*/)
    heading_level = RLENGTH
    sub(/  *#* *$/, "", line)    # remove trailing spaces and closing sequence
    sub(/^ *#*[ ]*/, "", line)   # remove initial spaces and hashes
                                 # Must be the last substitution so that
                                 # patterns like `### ###` work.
    oprint("<h" heading_level ">" line "</h" heading_level ">\n")
    next
}

# Setext headings

END {
    print out_text
}

function strip_whitespace(str) {
    sub(/[ \t]*$/, "", str)
    sub(/^[ \t]+/, "", str)
    return str
}

function oprint(str) {
    print str
    # TODO: maybe change to `out_text = out_text str`
}

function close_blocks() {
    # TODO
}
