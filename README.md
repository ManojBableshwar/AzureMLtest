# AzureMLtest

# AzureMLOpsDemo

Install gh cmd line installed and log in.

Login with: `az login` 

Set your Azure Subscription: `az account set -s <sub_id>`

Set $GROUP $WORKSPACE $LOCATION

```
export GROUP=<resource_group>

export WORKSPACE=<workspace_name>

export LOCATION=<workspace_location>

```

Create CLI auth secret. (Needs gh cmd line installed and logged in)
```
SUBSCRIPTION=$(az account show --query id -o tsv)

SECRET_NAME="AZ_CREDS"

az ad sp create-for-rbac --name <idname> --role owner --scopes /subscriptions/$SUBSCRIPTION/resourceGroups/$GROUP --sdk-auth | gh secret set $SECRET_NAME

```





