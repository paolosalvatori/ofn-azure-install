#!/bin/bash

# Variables
gitHubOwner="paolosalvatori"
gitHubRepo="ofn-azure-install"
url="https://api.github.com/repos/$gitHubOwner/$gitHubRepo/dispatches"
keyVaultName="BaboKeyVault"
keyVaultSecretName="GitHubPersonalAccessToken"
eventType="deploy_ofn_dev_env"

# Formatting
greenPrefix="\033[1;32m"
greenPostfix="\033[m"

# Set the payload
read -r -d '' payload << EndOfMessage
{
    "event_type": "deploy_ofn_dev_env",
    "client_payload": {
        "location": "West Europe",
        "resourceGroupName": "OfnDevRG",
        "templateLocation": "./templates/azuredeploy.dev.json",
        "parameters": "./templates/azuredeploy.dev.parameters.json",
        "preScriptLocation": "",
        "preScriptArgument": "",
        "postScriptLocation": "",
        "postScriptArgument": ""
    }
}
EndOfMessage

# Retrieve the GitHub personal access token from Key Vault
echo -e "Retrieving the personal access token for the [${greenPrefix}${gitHubOwner}${greenPostfix}] GitHub account from the [${greenPrefix}${keyVaultSecretName}${greenPostfix}] secret in [${greenPrefix}${keyVaultName}${greenPostfix}] key vault..."
gitHubPAT=$(az keyvault secret show \
    --name $keyVaultSecretName \
    --vault-name $keyVaultName \
    --query value \
    --output tsv)

if [[ $? == 0 ]]; then
    echo -e "Personal access token for the [${greenPrefix}${gitHubOwner}${greenPostfix}] GitHub account successfully retrieved from the [${greenPrefix}${keyVaultSecretName}${greenPostfix}] secret in [${greenPrefix}${keyVaultName}${greenPostfix}] key vault"
else
    echo -e "Failed to retrieve the Personal access token for the [$gitHubOwner] GitHub account from the [${greenPrefix}${keyVaultSecretName}${greenPostfix}] secret in [${greenPrefix}${keyVaultName}${greenPostfix}] key vault"
fi

# Manually call the deploy_arm_template type via a repository_dispatch event
echo -e "Calling [${greenPrefix}${eventType}${greenPostfix}] workflow in the [${greenPrefix}${gitHubRepo}${greenPostfix}] GitHub repo..."
httpCode=$(curl \
    --header "Authorization: token $gitHubPAT" \
    --header "Accept: application/vnd.github.everest-preview+json" \
    --request POST \
    --data "$payload" \
    --write-out "%{http_code}" \
    $url)

if (( $httpCode >= 200 && $httpCode < 300 )); then
    echo -e "[${greenPrefix}${eventType}${greenPostfix}] workflow successfully called in the [${greenPrefix}${gitHubRepo}${greenPostfix}] GitHub repo"
else
    echo -e "Failed to call the [${greenPrefix}${eventType}${greenPostfix}] worklow in the [${greenPrefix}${gitHubRepo}${greenPostfix}] GitHub repo"
fi