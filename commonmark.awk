BEGIN {
    OFS = ""
}

# Blank lines

/^[ \t]*$/ {
    if (current_block ~ /indented_code_block/) {
        sub(/^( |  |   |    |\t| \t|  \t|   \t)/, "")
        blank_lines = blank_lines $0 "\n"
    }
    else if (current_block ~ /paragraph|html_block_[67]/) {
        close_block()
    }
    else if (current_block ~ /fenced_code_block/) {
	add_fenced_code_block_line()
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

current_block !~ /paragraph/ && current_block !~ /fenced_code_block/ && sub(/^(    |\t| \t|  \t|   \t)/, "") {
    current_block = "indented_code_block"
    text = $0 "\n"
    next
}

# Fenced Code Blocks

current_block !~ /fenced_code_block/ && /^( |  |   )?(````*[^`]*|~~~~*[^~]*)$/ {
    match($0, /(``*|~~*)/)
    close_block()
    current_block = "fenced_code_block"
    fence_character = substr($0, RSTART, 1)
    fence_length = RLENGTH
    match($0, /^ */)
    fence_indent = RLENGTH
    info_string = $0
    sub(/^ *(``*|~~*) */, "", info_string)
    sub(/ *$/, "", info_string)
    text = ""
    split(info_string, info_string_words)
    fence_lang = info_string_words[1] 
    next
}

current_block ~ /fenced_code_block/ && /^( |  |   )?(````* *|~~~~* *)$/ {
    match($0, /(``*|~~*)/)
    if (substr($0, RSTART, 1) == fence_character && RLENGTH >= fence_length) {
	close_block()
	next
    }
}

current_block ~ /fenced_code_block/ {
    add_fenced_code_block_line()
    next
}

function add_fenced_code_block_line() {
    for (i = fence_indent; i > 0 && sub(/^ /, ""); i--) { }
    text = text $0 "\n"
}

# HTML blocks

function html_add_line_and_close() {
    text = text ? $0 : text "\n" $0
    close_block()
    next
}

## HTML block 1

current_block !~ /html_block/ && /^( |  |   )?(<[sS][cC][rR][iI][pP][tT]|<[pP][rR][eE]|<[sS][tT][yY][lL][eE])([ \t].*|>.*)?$/ {
    close_block()
    current_block = "html_block_1"
}

current_block ~ /html_block_1/ && /<\/([sS][cC][rR][iI][pP][tT]|[pP][rR][eE]|[sS][tT][yY][lL][eE])>/ {
    html_add_line_and_close()
}

## HTML block 2

current_block !~ /html_block/ && /^( |  |   )?<!--/ {
    close_block()
    current_block = "html_block_2"
}

current_block ~ /html_block_2/ && /-->/ {
    html_add_line_and_close()
}

## HTML block 3

current_block !~ /html_block/ && /^( |  |   )?<\?/ {
    close_block()
    current_block = "html_block_3"
}

current_block ~ /html_block_3/ && /\?>/ {
    html_add_line_and_close()
}

## HTML block 4

current_block !~ /html_block/ && /^( |  |   )<!/ {
    close_block()
    current_block = "html_block_4"
}

current_block ~ /html_block_4/ && />/ {
    html_add_line_and_close()
}

## HTML block 5

current_block !~ /html_block/ && /^( |  |   )<!\[CDATA\[/ {
    close_block()
    current_block = "html_block_5"
}

current_block ~ /html_block_5/ && /\]\]>/ {
    html_add_line_and_close()
}

## HTML block 6

current_block !~ /html_block/ && /( |  |   )<\/+([aA][dD][dD][rR][eE][sS][sS]|[aA][rR][tT][iI][cC][lL][eE]|[aA][sS][iI][dD][eE]|[bB][aA][sS][eE]|[bB][aA][sS][eE][fF][oO][nN][tT]|[bB][lL][oO][cC][kK][qQ][uU][oO][tT][eE]|[bB][oO][dD][yY]|[cC][aA][pP][tT][iI][oO][nN]|[cC][eE][nN][tT][eE][rR]|[cC][oO][lL]|[cC][oO][lL][gG][rR][oO][uU][pP]|[dD][dD]|[dD][iI][aA][lL][oO][gG]|[dD][iI][rR]|[dD][iI][vV]|[dD][lL]|[dD][tT]|[fF][iI][eE][lL][dD][sS][eE][tT]|[fF][iI][gG][cC][aA][pP][tT][iI][oO][nN]|[fF][iI][gG][uU][rR][eE]|[fF][oO][oO][tT][eE][rR]|[fF][oO][rR][mM]|[fF][rR][aA][mM][eE]|[fF][rR][aA][mM][eE][sS][eE][tT]|[hH]1|[hH][eE][aA][dD]|[hH][eE][aA][dD][eE][rR]|[hH][rR]|[hH][tT][mM][lL]|[iI][fF][rR][aA][mM][eE]|[lL][eE][gG][eE][nN][dD]|[lL][iI]|[lL][iI][nN][kK]|[mM][aA][iI][nN]|[mM][eE][nN][uU]|[mM][eE][nN][uU][iI][tT][eE][mM]|[mM][eE][tT][aA]|[nN][aA][vV]|[nN][oO][fF][rR][aA][mM][eE][sS]|[oO][lL]|[oO][pP][tT][gG][rR][oO][uU][pP]|[oO][pP][tT][iI][oO][nN]|[pP]|[pP][aA][rR][aA][mM]|[sS][eE][cC][tT][iI][oO][nN]|[sS][oO][uU][rR][cC][eE]|[sS][uU][mM][mM][aA][rR][yY]|[tT][aA][bB][lL][eE]|[tT][bB][oO][dD][yY]|[tT][dD]|[tT][fF][oO][oO][tT]|[tT][hH]|[tT][hH][eE][aA][dD]|[tT][iI][tT][lL][eE]|[tT][rR]|[tT][rR][aA][cC][kK]|[uU][lL])([ \t]+|>|\/>)?$/ {
    close_block()
    current_block = "html_block_6"
}

## HTML block 7
current_block !~ /html_block|paragraph/ && /^( |  |   )?(<[a-zA-Z][a-zA-Z0-9-]*([ \t]+[a-zA-Z_:][a-zA-Z0-9_.:-]*([ \t]*=[ \t]*([^"'=<>`]+|'[^']'|"[^"]"))?)*|<\/[a-zA-Z][a-zA-Z0-9-]*[ \t]*>)[ \t]*\/?>[ \t]*$/ {
    close_block()
    current_block = "current_block_7"
}

## HTML continuation

current_block ~ /html_block/ {
    text = text ? $0 : text "\n" $0
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
    if (current_block ~ /code_block/) {
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
    print "<h" heading_level, ">", text, "</h", heading_level, ">"
}

function thematic_break_out() {
    print "<hr />"
}

function atx_heading_out() {
    print "<h", heading_level, ">", text, "</h", heading_level, ">"
}

function indented_code_block_out() {
    if (fence_lang)
	print "<pre><code class=\"language-", fence_lang, "\">", text, "</code></pre>"
    else
	print "<pre><code>", text, "</code></pre>"
}

function paragraph_out() {
    print "<p>", text, "</p>"
}
