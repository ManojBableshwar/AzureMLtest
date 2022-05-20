az extension remove -n azure-cli-ml
az extension remove -n ml


# if CLI env var not set, then install default CLI
if [[ -z "$CLI" ]]
then
    az extension add -n ml -y
# else install private CLI
else
    az extension add --source $CLI --yes
fi

# enable PRP features 
export AZURE_ML_CLI_PRIVATE_FEATURES_ENABLED=true 

echo "CLI version:"
az version

if [[ -z "$GROUP" ]]
then
    echo "GROUP env var not set"
    exit 1
fi

if [[ -z "$WORKSPACE" ]]
then
    echo "WORKSPACE env var not set"
    exit 1
fi

if [[ -z "$LOCATION" ]]
then
    echo "LOCATION env var not set"
    exit 1
fi

# Use defaults if not passed by workflow inputs

echo "Setting defaults: group=$GROUP workspace=$WORKSPACE location=$LOCATION"

az configure --defaults group=$GROUP workspace=$WORKSPACE location=$LOCATION

# install yq tool to parse yaml files

VERSION=v4.4.0
BINARY=yq_linux_amd64

wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - |  tar xz && mv ${BINARY} /usr/bin/yq

yq --help


