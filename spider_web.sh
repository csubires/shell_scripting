
// BUscar todas las

url="https://elhacker.info/ebooks%20Joas/"
log="url222.txt"
agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36"
wget --no-directories --mirror --spider --wait=10 --random-wait --no-parent --no-verbose -c \
--header="Referer: $url/" --header="Accept-Encoding: compress, gzip" --user-agent="$agent" \
"$url" 2>&1 | tee "$log"

cat url.txt | grep "$url" | awk '{print $3}' > urls.txt

agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36"
wget --no-directories --wait=10 --random-wait --no-parent --no-verbose -c \
--header="Referer: https://elhacker.info/" --header="Accept-Encoding: compress, gzip" --user-agent="$agent" \
-i names.txt 2>&1
