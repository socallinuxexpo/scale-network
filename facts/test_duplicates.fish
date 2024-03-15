#!/usr/bin/env fish

function check_column --description 'check a column for duplicates and return error if any found'
    set filename $argv[1]
    set column_num $argv[2]
    set column_name $argv[3]

    set output (cat $filename | cut -d "," -f $column_num | sort | uniq -d | wc -l)
    if test (echo $output) -ne 0
        echo "duplicates found in $filename in column $column_num : $column_name"
        cat $filename | cut -d "," -f $column_num | sort | uniq -d
        exit 1
    else
        echo "no duplicates found in $filename in column $column_num : $column_name"
    end
end

# aps.csv
check_column aps/aps.csv 1 serial
check_column aps/aps.csv 2 mac-address

# apuse.csv
check_column aps/apuse.csv 1 name
check_column aps/apuse.csv 2 serial
check_column aps/apuse.csv 3 ipv4

# pilist.csv
check_column pi/pilist.csv 1 name
check_column pi/pilist.csv 2 ipv6

# routerlist
check_column routers/routerlist.csv 1 name
check_column routers/routerlist.csv 2 ipv6

# serverlist.csv
check_column servers/serverlist.csv 1 name
check_column servers/serverlist.csv 2 mac-address
check_column servers/serverlist.csv 3 ipv6
check_column servers/serverlist.csv 4 ipv4


