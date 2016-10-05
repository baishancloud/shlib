{
    if ($1 == "source" && system("test -f '"$2"'") == 0) {
        print $2
    }
}
