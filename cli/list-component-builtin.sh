mode=$1
unixepoch=$(date +"%s")
version=$(( $unixepoch + $RANDOM ))
if [[ $mode == "registry" ]]
then
  if [[ -z "$REGISTRY" ]]
  then 
    echo "mode=$mode but REGISTRY is not set"
    exit 1
  else
    echo "Using REGISTRY=$REGISTRY to create assets..."
    reg_var="--registry-name $REGISTRY"
  fi
else
  echo "Using WORKSPACE=$WORKSPACE to create assets..."
fi


echo "az ml environment create --file ../config/env.yml --version $version $reg_var $DEBUG"
start_time=`date +%s`
az ml environment create --file ../config/env.yml --version $version $reg_var $DEBUG || {
    echo "Env create failed for ../config/env.yml"
    exit 1
}
end_time=`date +%s`
timetaken=$(expr $end_time - $start_time)
echo "Time taken: $timetaken seconds"

echo "az ml environment show --name publicimageexample --version $version $reg_var $DEBUG"
az ml environment show --name publicimageexample --version $version $reg_var $DEBUG || {
    echo "Env show failed for --name publicimageexample --version $version"
    exit 1
}

while read line
do
  c_name=$(echo $line | awk -F, '{print $1}')
  matrix="$matrix,\"$c_name\""
done < ../config/component.csv

matrix=$(echo $matrix | sed 's/,//')

echo "matrix=$matrix"

echo "::set-output name=env_version::$version"
echo "::set-output name=sample_matrix::[$matrix]"