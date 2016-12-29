{
    if ($1 == "source" && system("test -f '"$2"'") == 0) {
        print "#include '" $2 "' begin"
        p = "dist/"$2
        while ((getline line < p) > 0) {
            print line
        }
        close(p)
        print "#include '" $2 "' end"
    }
    else {
        print
    }
}
