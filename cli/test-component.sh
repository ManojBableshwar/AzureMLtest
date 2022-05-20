

pyml=$1

for job in $( yq eval '.jobs | keys' $pyml | awk  '{print $2}' )
do
  echo "job name: $job"
  c_file=$( yq eval ".jobs.$job.component" $pyml | sed 's/file://' )
  echo "component file: $c_file"
  c_name=$(yq eval '.name' $c_file)
  c_version=$(date +"%s")
  echo "az ml component create --file $c_file --version $c_versio"
  az ml component create --file $c_file --version $c_version || {
      echo "Component create failed for c_file=$c_file"
      exit 1
  }
  echo "az ml component show --name $c_name --version $c_version"
  az ml component show --name $c_name --version $c_version
  
  
done
  