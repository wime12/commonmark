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

# Setext headings

current_block ~ /paragraph/ && !blank_lines && /^( |  |   )?(==*|--*) *$/ {
    heading_level = $0 ~ /=/ ? 1 : 2
    current_block = ""
    close_blocks()
    setext_heading_out(heading_level, text)
    next
}

# Thematic break

/^( |  |   )?(\* *\* *\* *(\* *)*|- *- *- *(- *)*|_ *_ *_ *(_ *)*) *$/ \
{
    close_blocks()
    thematic_break_out()
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
    atx_heading_out(heading_level, line)
    next
}

# Paragraph (continuation)

current_block ~ /paragraph/ && !blank_lines {
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
    text = $0 "\n"
    next
}

# Paragraph (start)

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
        indented_code_block_out(text)
    }
    else if (current_block ~ /paragraph/) {
        paragraph_out(text)
    }
    current_block = ""
}

# HTML Backend

function setext_heading_out(level, text) {
    print "<h" level ">" text "</h" level ">"
}

function thematic_break_out() {
    print "<hr />"
}

function atx_heading_out(level, text) {
    print "<h" level ">" line "</h" level ">"
}

function indented_code_block_out(text) {
    print "<pre><code>" text "</code></pre>"
}

function paragraph_out(text) {
    print "<p>" text "</p>"
}
