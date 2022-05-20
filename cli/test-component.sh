

pyml_full=$1


if [[ -z "$pyml_full" ]]
then
    echo "pipeline file name missing"
    exit 1
fi

dir=$(dirname $pyml_full)
pyml=$(basename $pyml_full)
cli_dir=$(pwd)

cd $dir

c_version=$(date +"%s")

for job in $( yq eval '.jobs | keys' $pyml | awk  '{print $2}' )
do
  echo "job name: $job"
  c_file=$( yq eval ".jobs.$job.component" $pyml | sed 's/file://' )
  echo "component file: $c_file"
  c_name=$(yq eval '.name' $c_file)
  echo "az ml component create --file $c_file --version $c_version"
  az ml component create --file $c_file --version $c_version || {
      echo "Component create failed for c_file=$c_file"
      exit 1
  }
  echo "az ml component show --name $c_name --version $c_version"
  az ml component show --name $c_name --version $c_version
  set_var="$set_var,jobs.$job.component=azureml:$c_name:$c_version"
done

echo "$cli_dir/create-job.sh $pyml $set_var"
bash $cli_dir/create-job.sh $pyml $set_var
  
