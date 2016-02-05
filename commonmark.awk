BEGIN {
    out_text = "" # converted text not yet output
    text = "" # collected text for current block
    blank_lines = 0 # number of blank lines before current line
    blank_line = 0 #
}

# Blank lines
/^[ \t]*$/ {
    blank_lines++
    blank_line = 1
    next
}

{   # not a blank line
    if (! blank_line) then blank_lines = 0
    blank_line = 0
}

# Setext headings
# TODO: if line is interpretable as empty list item, it should be inter-
#       preted as such
# TODO: Setext headings take precedence over thematic breaks
text && !blank_lines && /^( |  |   )?(==*|--*) *$/ {
    heading_level = $0 ~ /=/ ? 1 : 2
    oprint("<h" heading_level ">" text "</h" heading_level ">")
    clear_text()
    next
}

# Thematic break
/^( |  |   )?(\* *\* *\* *(\* *)*|- *- *- *(- *)*|_ *_ *_ *(_ *)*) *$/ \
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
    sub(/^ *#* */, "", line)   # remove initial spaces and hashes
                                 # Must be the last substitution so that
                                 # patterns like `### ###` work.
    oprint("<h" heading_level ">" line "</h" heading_level ">\n")
    next
}

{
    sub(/^ */, "")
    append_text($0)
}


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

function clear_text() {
    text = ""
}

function append_text(str) {
    if (text) text = text "\n"
    text = text str
}
