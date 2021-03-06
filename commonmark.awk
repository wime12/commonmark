#!/usr/local/bin/mawk -f

BEGIN {
    OFS = ""
}

# Container blocks

{
    n_matched_containers = 0
    while (n_matched_containers <= n_open_containers \
           && ((open_containers[n_matched_containers] ~ /^blockquote/ \
                && sub(/^( |  |   )?> ?/, "")))) {
        if (DEBUG) print "***** CONTAINER MATCHED"
        n_matched_containers++
    }
    if (DEBUG) print "***** n_open_containers = " n_open_containers
    if (DEBUG) print "***** n_matched_containers = " n_matched_containers
    if (n_matched_containers != n_open_containers \
	&& current_block ~ /^(fenced|indented)_code_block/) {
	if (DEBUG) print "***** CONTAINERS CLOSE CURRENT BLOCK: |" current_block "|"
	close_unmatched_blocks()
    }
    if (DEBUG) print "***** LINE: " $0
    if (/^( |  |   )?(> ?|[-*+] )/) {
	if (DEBUG) print "***** NEW CONTAINERS"
        close_unmatched_blocks()
        # open new containers
        while (1) {
            if (sub(/^( |  |   )?> ?/, "")) {
                open_container("blockquote")
                continue
            }
                # check for list
            else {
                break
            }
        }
    }
}

function open_container(block) {
    if (block ~ /^blockquote/) blockquote_start()
    # else if (block ~ /^list/) ...
    open_containers[n_open_containers++] = block
    n_matched_containers = n_open_containers
}

function close_container(n    , container) {
    container = open_containers[n]
    if (container ~ /^blockquote/) {
        blockquote_end()
    }        
    open_containers[n] = ""
}

function close_unmatched_containers() {
    if (DEBUG) print "***** CLOSE UNMATCHED CONTAINERS |" n_matched_containers ", " n_open_containers "|"
    while (n_open_containers > n_matched_containers) {
	n_open_containers--
	close_container(n_open_containers)
    }
}

function close_unmatched_blocks() {
    if (DEBUG) print "***** CLOSE UNMATCHED BLOCKS |" n_matched_containers ", " n_open_containers "|"
    close_block(current_block)
    close_unmatched_containers()
}

# Blank lines

/^[ \t]*$/ {
    if (current_block ~ /^indented_code_block/) {
        sub(/^( |  |   |    |\t| \t|  \t|   \t)/, "")
        blank_lines = blank_lines $0 "\n"
    }
    else if (current_block ~ /^html_block_[1-5]/) {
        text = text "\n" $0
    }
    else if (current_block ~ /^fenced_code_block/) {
	add_fenced_code_block_line()
    }
    else if (link_definition_parse ~ /^label/ \
        || link_definition_parse ~ /^destination/ \
	|| (link_definition_parse ~ /^title/ && link_title_start_tag)) {
        if (DEBUG) print "***** BLANK LINE LINK DEFINITION ABORT"
        link_definition_abort()
        close_block(current_block)
    }
    else if (link_definition_parse ~ /^title/ && !link_title_start_tag) {
        if (DEBUG) print "***** BLANK LINE LINK DEFINITION TITLE FINISH"
        link_definition_finish()
    }
    else if (current_block ~ /^(paragraph|html_block_[67])/) {
        close_unmatched_blocks()
    }
    next
}

# Setext headings

current_block ~ /^paragraph/ && n_matched_containers == n_open_containers \
&& /^( |  |   )?(==*|--*) *$/ {
    if (DEBUG) print "***** SETEXT HEADINGS | matched: " n_matched_containers ", open: " n_open_containers "|"
    close_unmatched_containers()
    heading_level = /\=/ ? 1 : 2
    current_block = ""
    setext_heading_out()
    next
}

# Thematic break

/^( |  |   )?(\* *\* *(\* *)+|- *- *(- *)+|_ *_ *(_ *)+) *$/ {
    close_unmatched_blocks()
    thematic_break_out()
    next
}

# ATX headings

/^( |  |   )?(#|##|###|####|#####|######)( .*)?$/ {
    close_unmatched_blocks()
    text = $0
    match(text, /##*/)
    heading_level = RLENGTH
    sub(/  *#* *$/, "", text)    # remove trailing spaces and closing sequence
    sub(/^ *#* */, "", text)   # remove initial spaces and hashes
    atx_heading_out()
    next
}

# Indented Code Blocks

current_block ~ /^indented_code_block/ && sub(/^(    |\t| \t|  \t|   \t)/, "") {
    if (DEBUG) print "***** INDENTED CODE BLOCK CONT"
    text = text blank_lines $0 "\n"
    blank_lines = ""
    next
}

current_block !~ /^paragraph|fenced_code_block|html_block/ && \
  sub(/^(    |\t| \t|  \t|   \t)/, "") {
    if (DEBUG) print "***** INDENTED CODE BLOCK START"
    # close_unmatched_blocks()
    current_block = "indented_code_block"
    text = $0 "\n"
    next
}

# Fenced Code Blocks

## Start
current_block !~ /^fenced_code_block|html_block/\
&& /^( |  |   )?(```+[^`]*|~~~*[^~]*)$/ {
    close_unmatched_blocks()
    match($0, /(``*|~~*)/)
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

# End
current_block ~ /^fenced_code_block/ && /^( |  |   )?(````* *|~~~~* *)$/ {
    match($0, /(``*|~~*)/)
    if (substr($0, RSTART, 1) == fence_character && RLENGTH >= fence_length) {
	close_block(current_block)
	next
    }
}

# Continue
current_block ~ /^fenced_code_block/ {
    add_fenced_code_block_line()
    next
}

function add_fenced_code_block_line() {
    for (i = fence_indent; i > 0 && sub(/^ /, ""); i--) { }
    text = text $0 "\n"
}

# HTML blocks

function html_add_line_and_close() {
    text = text ? text "\n" $0 : $0
    close_block(current_block) # TODO: too early?
}

## HTML block 1

### Start
current_block !~ /^html_block/ && \
/^( |  |   )?<([sS][cC][rR][iI][pP][tT]|[pP][rR][eE]|[sS][tT][yY][lL][eE])\
([ \t].*|>.*)?$/ {
    close_unmatched_blocks()
    current_block = "html_block_1"
    text = ""
}

### End
current_block ~ /^html_block_1/ && /<\/([sS][cC][rR][iI][pP][tT]|[pP][rR][eE]\
|[sS][tT][yY][lL][eE])>/ {
    html_add_line_and_close()
    next
}

## HTML block 2

### Start
current_block !~ /^html_block/ && /^( |  |   )?<!--/ {
    close_unmatched_blocks()
    current_block = "html_block_2"
    text = ""
}

### End
current_block ~ /^html_block_2/ && /-->/ {
    html_add_line_and_close()
    next
}

## HTML block 3

### Start
current_block !~ /^html_block/ && /^( |  |   )?<\?/ {
    close_unmatched_blocks()
    current_block = "html_block_3"
    text = ""
}

### End
current_block ~ /^html_block_3/ && /\?>/ {
    html_add_line_and_close()
    next
}

## HTML block 4

### Start
current_block !~ /^html_block/ && /^( |  |   )?<!/ {
    close_unmatched_blocks()
    current_block = "html_block_4"
    text = ""
}

### End
current_block ~ /^html_block_4/ && />/ {
    html_add_line_and_close()
    next
}

## HTML block 5

### Start
current_block !~ /^html_block/ && /^( |  |   )<!\[CDATA\[/ {
    close_unmatched_blocks()
    current_block = "html_block_5"
    text = $0
    next
}

### End
current_block ~ /^html_block_5/ && /\]\]>/ {
    html_add_line_and_close()
    next
}

## HTML block 6

### Start
current_block !~ /^html_block/ && /^( |  |   )?<\/?\
([aA][dD][dD][rR][eE][sS][sS]|[aA][rR][tT][iI][cC][lL][eE]|[aA][sS][iI][dD][eE]\
|[bB][aA][sS][eE]|[bB][aA][sS][eE][fF][oO][nN][tT]\
|[bB][lL][oO][cC][kK][qQ][uU][oO][tT][eE]|[bB][oO][dD][yY]\
|[cC][aA][pP][tT][iI][oO][nN]|[cC][eE][nN][tT][eE][rR]|[cC][oO][lL]\
|[cC][oO][lL][gG][rR][oO][uU][pP]\
|[dD][dD]|[dD][iI][aA][lL][oO][gG]|[dD][iI][rR]|[dD][iI][vV]|[dD][lL]|[dD][tT]\
|[fF][iI][eE][lL][dD][sS][eE][tT]|[fF][iI][gG][cC][aA][pP][tT][iI][oO][nN]\
|[fF][iI][gG][uU][rR][eE]|[fF][oO][oO][tT][eE][rR]|[fF][oO][rR][mM]\
|[fF][rR][aA][mM][eE]|[fF][rR][aA][mM][eE][sS][eE][tT]\
|[hH]1|[hH][eE][aA][dD]|[hH][eE][aA][dD][eE][rR]|[hH][rR]|[hH][tT][mM][lL]\
|[iI][fF][rR][aA][mM][eE]\
|[lL][eE][gG][eE][nN][dD]|[lL][iI]|[lL][iI][nN][kK]\
|[mM][aA][iI][nN]|[mM][eE][nN][uU]|[mM][eE][nN][uU][iI][tT][eE][mM]\
|[mM][eE][tT][aA]\
|[nN][aA][vV]|[nN][oO][fF][rR][aA][mM][eE][sS]\
|[oO][lL]|[oO][pP][tT][gG][rR][oO][uU][pP]|[oO][pP][tT][iI][oO][nN]\
|[pP]|[pP][aA][rR][aA][mM]\
|[sS][eE][cC][tT][iI][oO][nN]|[sS][oO][uU][rR][cC][eE]\
|[sS][uU][mM][mM][aA][rR][yY]\
|[tT][aA][bB][lL][eE]|[tT][bB][oO][dD][yY]|[tT][dD]|[tT][fF][oO][oO][tT]\
|[tT][hH]|[tT][hH][eE][aA][dD]|[tT][iI][tT][lL][eE]|[tT][rR]\
|[tT][rR][aA][cC][kK]|[uU][lL])\
([ \t]+.*|\/?>.*)?$/ {
    close_unmatched_blocks()
    current_block = "html_block_6"
    text = $0
    next
}

## HTML block 7

### Start
current_block !~ /^html_block|paragraph/\
&& /^( |  |   )?(<[a-zA-Z][a-zA-Z0-9-]*\
([ \t]+[a-zA-Z_:][a-zA-Z0-9_.:-]*([ \t]*=[ \t]*([^"'=<>`]+|'[^']*'|"[^"]*"))?)*\
[ \t]*\/?>|<\/[a-zA-Z][a-zA-Z0-9-]*[ \t]*>)[ \t]*$/ {
    close_block(current_block)
    current_block = "html_block_7"
    text = $0
    next
}

## HTML continuation

### Continue
current_block ~ /^html_block/ {
    text = text ? text "\n" $0 : $0
    next
}

# Link reference definitions

link_definition_skip { link_definition_skip = 0 }

## Start and Label

!link_definition_parse && current_block !~ /^paragraph/ \
&& match($0, /^( |  |   )?\[/) {
    if (DEBUG) print "***** START LINK DEFINITION |", $0, "|" #DEBUG
    close_unmatched_blocks()
    link_label = ""
    link_definition_parse = "label"
    if (link_definition_continue_label(substr($0, RLENGTH + 1))) {
        if (DEBUG) print "***** LINKDEF CONT LABEL RETURN"
	next
    }
    link_definition_skip = 1
}

!link_definition_skip && link_definition_parse ~ /^title/ \
  && ! link_title_start_tag && match($0, /^( |  |   )?\[/) {
    link_definition_finish()
    link_label = ""
    link_definition_parse = "label"
    if (link_definition_continue_label(substr($0, RLENGTH + 1)))
        next
    link_definition_skip = 1
}

!link_definition_skip && link_definition_parse ~ /^label/ {
    if (DEBUG) print "***** CONTINUE LABEL |", $0, "|" #DEBUG
    if (link_definition_continue_label($0))
	next
    link_definition_skip = 1
}

function link_definition_continue_label(line) {
    if (DEBUG) print "***** CONTINUE LABEL FUNC |", line, "|" #DEBUG
    if (line ~ /^([^\]\[]|\\]|\\\[)*$/) {
	if (DEBUG) print "***** CONTINUE LABEL FUNC CASE 1"
	link_label = link_label line "\n"
    }
    else if (match(line, /^([^\]\[]|\\]|\\\[)*]:/)) {
	# TODO: check length
	# TODO: check that non-whitespace was read
	if (DEBUG) print "***** CONTINUE LABEL FUNC CASE 2"
	link_label = link_label substr(line, 1, RLENGTH - 2)
	if (DEBUG) print "***** CONTINUE LABEL FUNC END |", link_label, "|" #DEBUG
	link_definition_parse = "destination"
	return link_definition_continue_destination(substr(line, RLENGTH + 1))
    }
    else {
	if (DEBUG) print "***** CONTINUE LABEL FUNC ELSE: ABORT"
	link_definition_abort()
    }
    return 0
}

## Destination

!link_definition_skip && link_definition_parse ~ /^destination/ {
    if (DEBUG) print "***** CONTINUE DESTINATION |", $0, "|" #DEBUG
    if (link_definition_continue_destination($0))
	next
    link_definition_skip = 1
}

function link_definition_continue_destination(line) {
    if (DEBUG) print "***** CONTINUE DESTINATION FUNC |", line, "|" #DEBUG
    link_destination = ""
    if (match(line, /^[[:space:]]*<([^<> \t]|\\<|\\>)*>/)) {
        # <...> style
	if (DEBUG) print "***** CONTINUE DESTINATION FUNC CASE 1"
	link_destination = substr(line, 1, RLENGTH - 1)
	sub(/[ \t]*</, "", link_destination)
    }
    else if (match(line, /^[[:space:]]*(([^ ()[:cntrl:]]|\\\(|\\\))+\
|([^ ()[:cntrl:]]|\\\(|\\\))*\(([^ ()[:cntrl:]]|\\\(|\\\))*\))*\
([^ ()[:cntrl:]]|\\\(|\\\))*/)) {
        # "freestyle"
	if (DEBUG) print "***** CONTINUE DESTINATION FUNC CASE 2"
	link_destination = substr(line, 1, RLENGTH)
	sub(/[ \t]*/, "", link_destination)
    }
    if (link_destination) {
        line = substr(line, RLENGTH + 1)
        if (line ~ /^([[:space:]]+.*)?$/) {
            link_definition_parse = "title"
            link_title = link_title_start_tag = ""
            return link_definition_continue_title(line)
        }
        else
            link_definition_abort()
    }
    return 0
}

## Title

!link_definition_skip && link_definition_parse ~ /^title/ {
    if (DEBUG) print "***** CONTINUE TITLE |", $0, "|" #DEBUG
    if (link_definition_continue_title($0))
	next
}

function link_definition_continue_title(line) {
    if (DEBUG) print "***** CONTINUE TITLE FUNC |", line, "|" #DEBUG
    if (!link_title_start_tag && match(line, /^[[:space:]]*$/)) {
        # title starts on next line
    }
    else if (!link_title_start_tag && match(line, /^[[:space:]]*[('"]/)) {
	if (DEBUG) print "***** CONTINUE TILE FUNCT START |", line, "|" #DEBUG
	link_title_start_tag = substr(line, RLENGTH, 1)
	return link_definition_continue_title(substr(line, RLENGTH + 1))
    }
    else if ((link_title_start_tag ~ /^'/ && match(line, /^([^']|\\')*$/)) \
	 || (link_title_start_tag ~ /^"/ && match(line, /^([^"]|\\")*$/)) \
	 || (link_title_start_tag ~ /^\(/ && match(line, /^([^)]|\\\))*$/))) {
       if (DEBUG) print "***** CONTINUE TILE FUNCT CONT |", line, "|" #DEBUG
       link_title = link_title line "\n"
    }
    else if (((link_title_start_tag ~ /^'/ \
               && match(line, /^([^']|\\')*'[[:space:]]*$/))  \
	    || (link_title_start_tag ~ /^"/ \
                && match(line, /^([^"]|\\")*"[[:space:]]*$/))  \
	    || (link_title_start_tag ~ /^\(/ \
                && match(line, /^([^)]|\\\))*\)[[:space:]]*$/))) \
	    && (substr(line, RLENGTH + 1) ~ /^[ \t]*$/)) {
	if (DEBUG) print "***** CONTINUE TILE FUNC END |", line, "|" #DEBUG
	link_title = link_title substr(line, 1, RLENGTH - 1)
	link_definition_finish()
	return 1
    }
    else {
	if (DEBUG) print "***** CONTINUE TILE FUNCT FAIL |", line, "|" #DEBUG
	link_definition_finish()
    }
    if (DEBUG) print "***** CONTINUE TITLE FUNC EXIT"
    return 0
}

### Helpers

function link_definition_abort() {
    if (DEBUG) print "***** LINK DEF FUNC ABORT"
    link_definition_parse = ""
}

function link_definition_finish() {
    if (DEBUG) print "***** LINK DEF FUNC FINISH"
    link_label = normalize_link_label(link_label)
    link_destinations[link_label] = link_destination
    link_titles[link_label] = link_title
    print_link() #DEBUG
    link_definition_abort()
    current_block = ""
}

function print_link(    title) {
    title = link_titles[link_label]
    # print "<a href=\"", link_destinations[link_label],
    #       title ? "\" title=\"" title : "",
    #       "\">", link_label, "</a>"
}

# TODO: Label normalization

function normalize_link_label(str) {
    sub(/[[:space:]]+/, " ", str)
    return toupper(str)
}

# Paragraph

current_block ~ /^paragraph/ {
    if (DEBUG) print "***** PARAGRAPH CONTINUATION"
    sub(/^ */, "")
    sub(/ *$/, "")
    text = text "\n" $0
    next
}

{
    if (DEBUG) print "***** PARAGRAPH START"
    close_unmatched_blocks()
    current_block = "paragraph"
    sub(/^ */, "")
    sub(/ *$/, "")
    text = $0
}

# Cleanup

END {
    if (link_definition_parse ~ /^title/)
        link_definition_finish()
    else {
	n_matched_containers = 0
        close_unmatched_blocks()
    }
}

# Helper Functions

function close_block(block) {
    if (block ~ /^(fenced|indented)_code_block/) {
        code_block_out()
    }
    else if (block ~ /^paragraph/) {
        paragraph_out()
    }
    else if (block ~ /^html_block/) {
        html_block_out()
    }
    current_block = ""
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

function code_block_out() {
    if (fence_lang)
	print "<pre><code class=\"language-", fence_lang, "\">", text,
              "</code></pre>"
    else
	print "<pre><code>", text, "</code></pre>"
}

function html_block_out() {
    print text
}

function paragraph_out() {
    print "<p>", text, "</p>"
}

function blockquote_start() {
    print "<blockquote>"
}

function blockquote_end() {
    print "</blockquote>"
}
