BEGIN {
    text = "" # collected text for current block
    blank_lines = 0 # number of blank lines before current one
    blank_line = 0 #
    current_block = ""
}

## State

# Blank lines


# TODO: Remove blank_lines variable?

/^[ \t]*$/ {    # blank line
    if (blank_line) blank_lines++
    else blank_line = blank_lines = 1
    if (current_block ~ /indented_code_block/) {
        sub(/^( |  |   |    |\t| \t|  \t|   \t|)/, "")
        code_blank_lines = code_blank_lines $0 "\n"
    }
    else if (current_block ~ /paragraph/) {
        close_blocks()
    }
    next
}

current_block !~ /indented_code_block/ {   # not a blank line
    if (blank_line) blank_line = 0
    else blank_lines = 0
}

## Leaf blocks

# Setext headings

current_block ~ /paragraph/ && !blank_lines && /^( |  |   )?(==*|--*) *$/ {
    current_block = ""
    close_blocks()
    heading_level = $0 ~ /=/ ? 1 : 2
    print "<h" heading_level ">" text "</h" heading_level ">"
    text = ""
    next
}

# Thematic break

/^( |  |   )?(\* *\* *\* *(\* *)*|- *- *- *(- *)*|_ *_ *_ *(_ *)*) *$/ \
{
    close_blocks()
    print "<hr />"
    next
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
    print "<h" heading_level ">" line "</h" heading_level ">"
    next
}

# Paragraph

current_block ~ /paragraph/ && ! blank_lines {
    sub(/^ */, "")
    sub(/ *$/, "")
    text = text "\n" $0
    next
}

# Indented code blocks

current_block ~ /indented_code_block/ && sub(/^(    |\t| \t|  \t|   \t)/, "") {
    text = text code_blank_lines $0 "\n"
    code_blank_lines = ""
    next
}

sub(/^(    |\t| \t|  \t|   \t)/, "") {
    current_block = "indented_code_block"
    text = text "<pre><code>" $0 "\n"
    next
}

# Paragraph

{
    close_blocks()
    current_block = "paragraph"
    sub(/^ */, "")
    sub(/ *$/, "")
    text = $0
}


END {
    close_blocks()
}

function close_blocks(str) {
    if (current_block ~ /indented_code_block/) {
        print text "</code></pre>"
	text = ""
    }
    else if (current_block ~ /paragraph/) {
        print "<p>" text "</p>"
	text = ""
    }
    current_block = ""
}
