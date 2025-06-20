while getopts a:r:y:l flag
do
    case "${flag}" in
        a) apikey=${OPTARG};;
        r) rdfile=${OPTARG};;
        y) ytsfile=${OPTARG};;
        l) language=${OPTARG};;
    esac
done

if [ -z ${language} ]; then
        language="en"
fi

headers="Authorization: Bearer $apikey"
baseurl="https://api.real-debrid.com/rest/1.0/torrents"
ytsurl="https://yts.mx/api/v2/list_movies.json"

# Progress bar
bar_size=40
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2
function show_progress {
    current="$1"
    total="$2"

    # calculate the progress in percentage
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\rProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"

    if [ $total -eq $current ]; then
        echo -e "\nWaiting for responses..."
    fi
}

function yts() {
        local response=$(curl -s -X GET "$ytsurl&page=$1&limit=50" | jq -r --arg lang $language '.data.movies[] | select(.language==$lang) | .torrents[] | select(.quality=="1080p" or .quality=="2160p") | .hash')
        if [ $(printf '%s\n' "${response[@]}" | wc -l) -gt 0 ]; then
                printf '%s\n' "${response[@]}" | sort | uniq -u >> yts.txt
                show_progress $1 $2
        else
                if [ -z ${3} ]; then
                        sleep 5
                        echo "Retrying page $1 in 5s"
                        yts $1 $2 1
                elif [ $3 < 5 ]; then
                        sleep 5
                        echo "Retrying page $1 in 5s"
                        yts $1 $2 $3
                else
                        echo "Page $1 failed."
                fi
        fi
}


# Init RD
if [ -f "$rdfile" ]; then
  mapfile -t rdhashes < $rdfile
else
  rdfile="rd.txt"
  # Init RD
  page=1
  echo "RD Page: $page"
  rdhashes=()
  response=$(curl -s -X GET -H "$headers" "$baseurl?limit=5000&page=$page" | jq -r .[].hash)
  # RD Loop
  while [ $(printf '%s\n' "${response[@]}" | wc -l) -gt 1 ]
  do
          rdhashes+=$response
          ((page++));
          response=$(curl -s -X GET -H "$headers" "$baseurl?limit=5000&page=$page" | jq -r .[].hash)
          echo "RD Page: $page"
  done
  printf '%s\n' "${rdhashes[@]}" > rd.txt
fi
echo "Found $(printf '%s\n' "${rdhashes[@]}" | wc -l) hashes"


if [ -f "$ytsfile" ]; then
  mapfile -t ytshashes < $ytsfile
else
        ytsfile="yts.txt"
        # Init ytshashes
        moviescount=$(curl -s -X GET "$ytsurl" | jq .data.movie_count)
        pages=$(( (moviescount + 50 - 1) / 50 ))
        page=0
        curl -s -X GET "$ytsurl?page=$page&limit=50" | jq -r --arg lang $language '.data.movies[] | select(.language==$lang) | .torrents[] | select(.quality=="1080p" or .quality=="2160p") | .hash' | sort | uniq -u > yts.txt
        # YTS Loop
        while [ $page -lt $pages ]
        do
                yts $page $pages &
                sleep 0.1
                ((page++))
        done
        wait
fi

echo "Found $(cat $ytsfile | wc -l) yts hashes"
echo "Found $(grep -i -v -F -x -f $rdfile $ytsfile | wc -l) unadded torrents"
grep -i -v -F -x -f $rdfile $ytsfile > unique.txt

count=0
totalcount=$(cat unique.txt | wc -l)

while IFS= read -r line; do
    response=$(curl -s -X POST -H "$headers" -H "application/x-www-form-urlencoded" --data-raw "magnet=magnet:?xt=urn:btih:$line" $baseurl/addMagnet)
    torrentId=$(echo $response | jq .id)
        if [ $torrentId == "null" ]
                then
                echo $response
                if [ $(echo $response | jq .error_code) == 34 ]
                then
                                        echo "API limited, sleeping 60s"
                    sleep 60
                else
                    echo "$line failed, response: $response" > failed.txt
                fi
        else
                (($count++))
                show_progress $count $totalcount
        fi
        sleep 1

done < unique.txt
