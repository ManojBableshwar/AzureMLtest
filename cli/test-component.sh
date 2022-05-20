sample=$1
mode=$2

if [[ -z "$COMPONENT_SAMPLE_ROOT" ]]
then
    echo "env var COMPONENT_SAMPLE_ROOT not set"
    exit 1
fi

if [[ -z "$PIPELINE_YAML" ]]
then
    echo "env var PIPELINE_YAML not set"
    exit 1
fi

pyml=$PIPELINE_YAML

if [[ -z "$sample" ]]
then
    echo "parameter sample not set"
    exit 1
fi

cli_dir=$(pwd)
cd $COMPONENT_SAMPLE_ROOT
cd $sample

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





c_version=$(date +"%s")

for job in $( yq eval '.jobs | keys' $pyml | awk  '{print $2}' )
do
  echo "job name: $job"
  c_file=$( yq eval ".jobs.$job.component" $pyml | sed 's/file://' )
  echo "component file: $c_file"
  c_name=$(yq eval '.name' $c_file)
  echo "az ml component create --file $c_file --version $c_version $reg_var"
  az ml component create --file $c_file --version $c_version $reg_var || {
      echo "Component create failed for c_file=$c_file"
      exit 1
  }
  echo "az ml component show --name $c_name --version $c_version"
  az ml component show --name $c_name --version $c_version
  if [[ $mode == "registry" ]]
  then
    set_var="$set_var,jobs.$job.component=azureml://registries/$REGISTRY/components/$c_name/versions/$c_version"
  else
    set_var="$set_var,jobs.$job.component=azureml:$c_name:$c_version"
  fi
done

echo "$cli_dir/create-job.sh $pyml $set_var"
bash $cli_dir/create-job.sh $pyml $set_var
  
