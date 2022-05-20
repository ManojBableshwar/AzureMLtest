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


echo "az ml environment create --file ../config/env.yml --version $version $reg_var"
az ml environment create --file ../config/env.yml --version $version $reg_var  || {
    echo "Env create failed for ../config/env.yml"
    exit 1
}

c_file="../config/component.yml"
c_version=$version
for c_name in $(cat ../config/component.csv)
do
  echo "az ml component create --file $c_file --name $c_name --version $c_version --set environment=azureml://registries/$REGISTRY/environments/public_image_example/labels/latest $reg_var "
  az ml component create --file $c_file --name $c_name --version $c_version $reg_var  || {
      echo "Component create failed for c_name=$c_name"
      exit 1
  }
  echo "az ml component show --name $c_name --version $c_version $reg_var"
  az ml component show --name $c_name --version $c_version $reg_var || {
      echo "Component show failed for --name $c_name --version $c_version"
      exit 1
  }
done