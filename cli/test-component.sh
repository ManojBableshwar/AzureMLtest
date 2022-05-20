

pyml_full=$1


if [[ -z "$pyml_full" ]]
then
    echo "pipeline file name missing"
    exit 1
fi

dir=$(dirname $pyml_full)
pyml=$(basename $pyml_full)

cd $dir

for job in $( yq eval '.jobs | keys' $pyml | awk  '{print $2}' )
do
  echo "job name: $job"
  c_file=$( yq eval ".jobs.$job.component" $pyml | sed 's/file://' )
  echo "component file: $c_file"
  c_name=$(yq eval '.name' $c_file)
  c_version=$(date +"%s")
  echo "az ml component create --file $c_file --version $c_version"
  az ml component create --file $c_file --version $c_version || {
      echo "Component create failed for c_file=$c_file"
      exit 1
  }
  echo "az ml component show --name $c_name --version $c_version"
  az ml component show --name $c_name --version $c_version
  set_var="$set_var=jobs.$job.component=azureml:$c_name:$c_version"
done

bash ./create-job.sh $pyml $set_var
  
