BEGIN {
    out_text = "" # converted text not yet output
    text = "" # collected text for current block
    blank_lines = 0 # number of blank lines before current one
    blank_line = 0 #
    current_block = ""
}

## State

# Blank lines
/^[ \t]*$/ {    # blank line
    if (blank_line) blank_lines++
    else blank_line = blank_lines = 1
    next
}

{   # not a blank line
    if (blank_line) blank_line = 0
    else blank_lines = 0
}

## Continuations

# Indented Code Block
current_block ~ /indented_code_block/ && sub(/^(    |\t| \t|  \t|   \t)/, "") {
    for(i = blank_lines; i > 0; i--) append_text("")
    append_text($0)
    next
}
    

## Leaf blocks

# Setext headings
# TODO: if line is interpretable as empty list item, it should be inter-
#       preted as such
# TODO: Setext headings take precedence over thematic breaks
text && !blank_lines && /^( |  |   )?(==*|--*) *$/ {
    close_blocks()
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

# Indented code blocks
sub(/^(    |\t| \t|  \t|   \t)/, "") {
    current_block = "indented_code_block"
    append_text("<pre><code>" $0)
    next
}

{
    sub(/^ */, "")
    append_text($0)
}


END {
    close_blocks()
    # print out_text
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

function clear_text() {
    text = ""
}

function append_text(str) {
    if (text) text = text "\n"
    text = text str
}

function close_blocks(str) {
    if (current_block ~ /indented_code_block/) {
        oprint(text "\n</code></pre>")
        current_block = ""
    }
}
