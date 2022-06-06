set -x
sample=$1
mode=$2

echo "Private preview features enabled? AZURE_ML_CLI_PRIVATE_FEATURES_ENABLED=$AZURE_ML_CLI_PRIVATE_FEATURES_ENABLED"

if [[ -z "$ENVIRONMENT_SAMPLE_ROOT" ]]
then
    echo "env var ENVIRONMENT_SAMPLE_ROOT not set"
    exit 1
fi

if [[ -z "$sample" ]]
then
    echo "parameter sample not set"
    exit 1
fi

cli_dir=$(pwd)
cd $ENVIRONMENT_SAMPLE_ROOT

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
env_version=$(( $unixepoch + $RANDOM ))

gitroot=$(git rev-parse --show-toplevel)
cur_dir=$(pwd)
gitrepourl=$(git config --get remote.origin.url | sed 's|\.git||')
relativepath=$(echo $cur_dir | sed "s|$gitroot||")
gitbranch=$(git name-rev --name-only HEAD)
gitdirurl=$gitrepourl"/tree/"$gitbranch$relativepath/$sample
echo "Git url for this sample: $gitdirurl"

env_name=$(az ml environment create --file $sample --version $env_version --query name -o tsv $reg_var $DEBUG)

if [[ -z "$env_name" ]]
then
    echo "ENVIRONMENT create failed for e_file=$e_file"
    exit 1
fi

az ml environment show --name $env_name --version $env_version $reg_var $DEBUG || {
    echo "ENVIRONMENT show failed for --name $env_name --version $env_version"
    exit 1
}

job_yml="../../jobs/basics/hello-pipeline.yml"

if [[ $mode == "registry" ]]
then
  set_var="jobs.hello_job.environment=azureml://registries/$REGISTRY/environments/$env_name/versions/$env_version,jobs.world_job.environment=azureml://registries/$REGISTRY/environments/$env_name/versions/$env_version"
else
  set_var="jobs.hello_job.environment=azureml:$env_name:$env_version,jobs.world_job.environment=azureml:$env_name:$env_version"
fi

set_var="$set_var,display_name=$sample-hello-pipeline-$mode-$env_version"

bash $cli_dir/create-job.sh $job_yml $set_var
  


job_yml="../../jobs/basics/hello-world.yml"

if [[ $mode == "registry" ]]
then
  set_var="environment=azureml://registries/$REGISTRY/environments/$env_name/versions/$env_version"
else
  set_var="environment=azureml:$env_name:$env_version"
fi

set_var="$set_var,display_name=$sample-hello-world-$mode-$env_version"

bash $cli_dir/create-job.sh $job_yml $set_var
  



