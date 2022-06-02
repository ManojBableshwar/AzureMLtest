set -x
run_id=$1

if [[ -z "$run_id" ]]
then
    echo "Run_id not passed as input parameter"
    exit 3
fi

BASE_DIR=/tmp/op-$run_id

mkdir $BASE_DIR/all
midir $BASE_DIR/each

az ml job download --name $run_id --all --download-path $BASE_DIR/all $DEBUG || {
    echo "az ml job download --all failed"
    exit 1
}

for output in $(az ml job show --name $run_id --query "outputs | keys(@)"  | head -n -1 | tail -n +2 | sed 's/[", ]//g')
do
    az ml job download --name $run_id --output-name $output --download-path $BASE_DIR/each  $DEBUG || {
        echo "az ml job download --output-name failed"
        exit 1
    }
done

tree  $BASE_DIR
