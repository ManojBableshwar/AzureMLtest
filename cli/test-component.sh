set -x
sample=$1
mode=$2

echo "Private preview features enabled? AZURE_ML_CLI_PRIVATE_FEATURES_ENABLED=$AZURE_ML_CLI_PRIVATE_FEATURES_ENABLED"

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

unixepoch=$(date +"%s")
c_version=$(( $unixepoch + $RANDOM ))

gitroot=$(git rev-parse --show-toplevel)
cur_dir=$(pwd)
gitrepourl=$(git config --get remote.origin.url | sed 's|\.git||')
relativepath=$(echo $cur_dir | sed "s|$gitroot||")
gitbranch=$(git name-rev --name-only HEAD)
gitdirurl=$gitrepourl"/tree/"$gitbranch$relativepath
echo "Git url for this sample: $gitdirurl"

for job in $( yq eval '.jobs | keys' $pyml | awk  '{print $2}' )
do
  echo "Registering component used in job: $job"
  c_file=$( yq eval ".jobs.$job.component" $pyml | sed 's/file://' )
  echo "component file: $c_file"
  c_name=$(yq eval '.name' $c_file)
  c_file_no_cur_dir=$(echo $c_file | sed 's/\.//')
  echo "Git url for this component: $gitdirurl$c_file_no_cur_dir"

  if [[  $sample == "nyc_taxi_data_regression" ]]
  then
    az ml component create --file $c_file --version $c_version $reg_var --set environment=azureml://registries/azureml-staging/environments/sklearn-10-ubuntu2004-py38-cpu/versions/19.dev6 $DEBUG  || {
        echo "Component create failed for c_file=$c_file"
        exit 1
    }
  else
    az ml component create --file $c_file --version $c_version $reg_var $DEBUG  || {
        echo "Component create failed for c_file=$c_file"
        exit 1
    }
  fi


#  echo "az ml component show --name $c_name --version $c_version $reg_var $DEBUG"
  az ml component show --name $c_name --version $c_version $reg_var $DEBUG || {
      echo "Component show failed for --name $c_name --version $c_version"
      exit 1
  }
  if [[ $mode == "registry" ]]
  then
    set_var="$set_var,jobs.$job.component=azureml://registries/$REGISTRY/components/$c_name/versions/$c_version"
  else
    set_var="$set_var,jobs.$job.component=azureml:$c_name:$c_version"
  fi
done

set_var="$set_var,display_name=$sample-$mode-$c_version"

echo "Git url for this job: $gitdirurl/$pyml"
echo "$cli_dir/create-job.sh $pyml $set_var"
bash $cli_dir/create-job.sh $pyml $set_var
  
