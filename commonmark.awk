# Blank lines

/^[ \t]*$/ {
    if (current_block ~ /indented_code_block/) {
        sub(/^( |  |   |    |\t| \t|  \t|   \t|)/, "")
        blank_lines = blank_lines $0 "\n"
    }
    else if (current_block ~ /paragraph/) {
        close_block()
    }
    next
}

# Setext headings

current_block ~ /paragraph/ && /^( |  |   )?(==*|--*) *$/ {
    heading_level = $0 ~ /=/ ? 1 : 2
    current_block = ""
    close_block()
    setext_heading_out()
    next
}

# Thematic break

/^( |  |   )?(\* *\* *\* *(\* *)*|- *- *- *(- *)*|_ *_ *_ *(_ *)*) *$/ {
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

# Indented code blocks

current_block ~ /indented_code_block/ && sub(/^(    |\t| \t|  \t|   \t)/, "") {
    text = text blank_lines $0 "\n"
    blank_lines = ""
    next
}

current_block !~ /paragraph/ && sub(/^(    |\t| \t|  \t|   \t)/, "") {
    current_block = "indented_code_block"
    text = $0 "\n"
    next
}

# Fenced Code Blocks

current_block ~ /fenced_code_block/ {
    
}

/^( |  |   )?(````*|~~~~*)/ {
    close_block()
    current_block = "fenced_code_block"
    info_string = $0
    match(info_string, /^ */)
    fence_indent = RLENGTH
    match(info_string, /(``*|~~*)/)
    fence_length = RLENGTH
    sub(/^ *(``*|~~*) */, info_string)
    sub(/ *$/, info_string)
    next
}

# Paragraph (start)

current_block ~ /paragraph/ {
    sub(/^ */, "")
    sub(/ *$/, "")
    text = text "\n" $0
    next
}

{
    close_block()
    current_block = "paragraph"
    sub(/^ */, "")
    sub(/ *$/, "")
    text = $0
}

# Cleanup

END {
    close_blocks()
}

# Helper Functions

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
