job=$1
set_var=$2

echo "Private preview features enabled? AZURE_ML_CLI_PRIVATE_FEATURES_ENABLEDk=$AZURE_ML_CLI_PRIVATE_FEATURES_ENABLED"

if [[ -z "$set_var" ]]
then
  echo "az ml job create --file $job --query name -o tsv $DEBUG"
  export run_id=$(az ml job create --file $job --query name -o tsv $DEBUG)
else
  set_var=$(echo $set_var | sed 's/,/ /g')
  echo "az ml job create --file $job --set $set_var --query name -o tsv $DEBUG"
  export run_id=$(az ml job create --file $job --set $set_var --query name -o tsv $DEBUG)
fi

#export run_uri=$(az ml job show --name $run_id --query services.Studio.endpoint)
export run_uri="https://ml.azure.com/runs/$run_id?flight=ModelRegisterV2,ModelRegisterExistingEnvironment,dpv2data"

if [[ -z "$run_id" ]]
then
    echo "Job creation failed"
    exit 3
fi

az ml job show --name $run_id

status=$(az ml job show --name $run_id --query status -o tsv $DEBUG)

if [[ -z "$status" ]]
then
    echo "Status query failed"
    exit 4
fi

job_uri=$(az ml job show --name $run_id --query services.Studio.endpoint $DEBUG)

echo $job_uri

running=("Queued" "NotStarted" "Starting" "Preparing" "Running" "Finalizing")
while [[ ${running[*]} =~ $status ]]
do
    echo $job_uri
    sleep 8 
    status=$(az ml job show --name $run_id --query status -o tsv)
    echo $status
done

if [[ $status == "Completed" ]]
then
    echo "Job completed"
    echo "::set-output name=RUNID::$run_id"
    echo "::set-output name=RUNURI::https://ml.azure.com/runs/$run_id?flight=ModelRegisterV2,ModelRegisterExistingEnvironment,dpv2data"
    exit 0
elif [[ $status == "Failed" ]]
then
    echo "Job failed"
    exit 1
else
    echo "Job not completed or failed. Status is $status"
    exit 2
fi   