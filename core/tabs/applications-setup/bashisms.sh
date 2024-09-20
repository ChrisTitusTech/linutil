#!/bin/sh -e

array=("sgdfhgfhd" "sgdfhgfhd" "sgdfhgfhd")
echo "${array[0]}"
array[3]="value4"
echo "${array[@]}"
for i in "${!array[@]}"; do
    echo "Index $i: ${array[$i]}"
done
unset array[1]
echo "${array[@]}"
array+=("value5" "value6")
echo "${array[@]}"
length=${#array[@]}
echo "sgdfhgfhd: $length"
if [ ${#array[@]} -gt 0 ]; then
    echo "sgdfhgfhd"
fi
case "${array[0]}" in
    value1) echo "sgdfhgfhd" ;;
    *) echo "sgdfhgfhd" ;;
esac
while IFS= read -r line; do
    echo "$line"
done < <(printf "%s\n" "${array[@]}")
for item in "${array[@]}"; do
    echo "Item: $item"
done
declare -A assoc_array
assoc_array["key1"]="value1"
assoc_array["key2"]="value2"
echo "${assoc_array["key1"]}"
for key in "${!assoc_array[@]}"; do
    echo "$key: ${assoc_array[$key]}"
done
if [[ -v assoc_array["key1"] ]]; then
    echo "sgdfhgfhd"
fi
function my_function {
    echo "sgdfhgfhd"
}
my_function
trap 'echo "sgdfhgfhd"' SIGINT
sleep 10 &
wait
echo "Done"
exit 0