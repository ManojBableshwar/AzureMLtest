c_name=$1
env_version=$2
mode=$3

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

c_file="../config/component.yml"
c_version=$version

c_display_name=$(cat ../config/component.csv | grep "$c_name" | awk -F, '{print $2}')
echo "az ml component create --file $c_file --name $c_name --version $c_version --set display_name=\"$c_display_name\" environment=azureml://registries/$REGISTRY/environments/publicimageexample/versions/$env_version $reg_var $DEBUG "
start_time=`date +%s`
az ml component create --file $c_file --name $c_name --version $c_version --set display_name="$c_display_name" environment=azureml://registries/$REGISTRY/environments/publicimageexample/versions/$env_version $reg_var $DEBUG || {
    echo "Component create failed for c_name=$c_name"
    exit 1
}
end_time=`date +%s`
timetaken=$(expr $end_time - $start_time)
echo "Time taken: $timetaken seconds"
echo "az ml component show --name $c_name --version $c_version $reg_var"
az ml component show --name $c_name --version $c_version $reg_var || {
  echo "Component show failed for --name $c_name --version $c_version"
  exit 1
}
