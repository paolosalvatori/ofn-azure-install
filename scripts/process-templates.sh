#!/bin/bash

# A simple script to replace <KEY> with VALUES
# Takes a minimum of 3 parameters input_file, output_file and a set of key=value pairs
# Generates a sed script to search input_file for <key> and replaces all occurences with value

if [ $# -lt 3 ]; then
        echo "Syntax: $0 <input_file> <outputfile> key1=value1 key2=value2"
        exit 1
fi


SED_REPLACE_ARGS=""
# Arguments should be in the format TEMPLATE_VAR=value
for PARAM in ${@:3}; do
        TPL_KEY=${PARAM%%=*}
        TPL_VAL=${PARAM#*=}
        # Make sure / is escaped in the value string
        TPL_VAL_ESCAPED=$(printf '%s\n' "$TPL_VAL" | sed -e 's/[\/&]/\\&/g')
        SED_REPLACE_ARGS="${SED_REPLACE_ARGS} -e s/<${TPL_KEY}>/${TPL_VAL_ESCAPED}/g"
done

sed $SED_REPLACE_ARGS <$1 >$2
