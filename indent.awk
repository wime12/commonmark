function indentation(str,    indent) {
    indent = 0
    while(1) {
        print "***** STR |" str "|"
        if (sub(/^ /, "", str))
            indent++
        else if (sub(/^\t/, "", str))
            indent +=4
        else
            break
    }
    return indent
}

{
    print "Indent: " indentation($0) ", original String |" $0 "|"
}
