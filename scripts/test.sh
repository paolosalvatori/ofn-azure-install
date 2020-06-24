#!/bin/bash
echo $1 > json.txt
 sudo apt-get install -y jq
json=$(echo $1)
foo=$(echo $1 | jq -r '.foo')
bar=$(echo $1 | jq -r '.bar')
cat > ./parameters.txt <<EOL
json=${json}
foo=${foo}
bar=${bar}
EOL