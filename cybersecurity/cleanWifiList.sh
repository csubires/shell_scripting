

cat w | awk '{print $1, $11}' | sort | uniq > wifi_list_clean.txt
