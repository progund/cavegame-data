#!/bin/bash

TABLES=""
DB=../../database/cavedatabas.db

sql()
{
    echo "$*" | sqlite3 $DB
}

find_tables()
{
    TABLES=$(sql ".schema" | grep TABLE | awk '{ print $3}')
}

json_begin()
{
    echo "{"
}
json_end()
{
    echo "}"
}

print_json()
{
    echo " \"$1\" : \"$2\" "
}

extract_row()
{
    col_cnt=0
    export IFS="|"
    json_begin
    STOP=$(( $CNT - 1 ))
    for value in $LINE 
    do
                #echo " == COL_HEADER[$col_cnt]: ${COL_HEADER[$col_cnt]}   ($CNT)"
        echo -n "  \"${COL_HEADER[$col_cnt]}\" : \"$value\" "
        col_cnt=$(( $col_cnt + 1 ))
        if [ $col_cnt -le $STOP ]; then echo "," ;  fi
    done
    echo
    json_end
#    echo "--- CNT: $CNT | $LINE"
}

extract_table()
{
    TABLE=$1
    CNT=0
    COL_STR=""
    declare -a COL_HEADER
    export COL_HEADER
    for col in $(sql ".schema $TABLE" | grep -v CREATE | grep -v ");" | grep -v "^[ \t]*primary key" | grep -v "^[ \t]*foreign key" | awk '{ print $1 }'  )
    do
        if [ $CNT -ne 0 ] ; then COL_STR="${COL_STR}," ; fi
        COL_STR="${COL_STR} $col"
        COL_HEADER[$CNT]=$col
        CNT=$(( $CNT + 1 ))
    done

    SQL="SELECT $COL_STR FROM $TABLE"
    export CNT
    echo " \"$TABLE\" : [ "
    sql ${SQL} | while read LINE
    do
        extract_row $LINE
        if [ "$LINE" = "" ] ; then break  ; else echo -n "," ; fi
    done 
    echo "] "
}

extract_tables()
{
    json_begin
    for i in $TABLES
    do
        extract_table $i | sed 's/,\]/\]/g'
        echo -n ","
    done
    json_end
}

build_json()
{
    find_tables
    extract_tables | sed 's/,}/}/g'
}

build_json > temp.json
json_reformat < temp.json > cave.json
echo "Created cave.json"
jsonlint-php cave.json

