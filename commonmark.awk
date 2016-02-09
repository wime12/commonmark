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
        close_block()
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
    close_block()
    setext_heading_out()
    next
}

# Thematic break

/^( |  |   )?(\* *\* *\* *(\* *)*|- *- *- *(- *)*|_ *_ *_ *(_ *)*) *$/ \
{
    close_block()
    thematic_break_out()
    next
}

# ATX headings

/^( |  |   )?(#|##|###|####|#####|######)( .*)?$/ {
    close_block()
    text = $0
    match(text, /##*/)
    heading_level = RLENGTH
    sub(/  *#* *$/, "", text)    # remove trailing spaces and closing sequence
    sub(/^ *#* */, "", text)   # remove initial spaces and hashes
    atx_heading_out()
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
    close_block()
    current_block = "paragraph"
    sub(/^ */, "")
    sub(/ *$/, "")
    text = $0
}

END {
    close_blocks()
}

function close_block() {
    if (current_block ~ /indented_code_block/) {
        indented_code_block_out()
    }
    else if (current_block ~ /paragraph/) {
        paragraph_out()
    }
    current_block = ""
}

function close_blocks() {
    # TODO: Implementation!
    close_block()
}

# HTML Backend

function setext_heading_out() {
    print "<h" heading_level ">" text "</h" heading_level ">"
}

function thematic_break_out() {
    print "<hr />"
}

function atx_heading_out() {
    print "<h" heading_level ">" text "</h" heading_level ">"
}

function indented_code_block_out() {
    print "<pre><code>" text "</code></pre>"
}

function paragraph_out() {
    print "<p>" text "</p>"
}
