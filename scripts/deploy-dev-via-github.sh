#!/bin/bash

# Variables
gitHubOwner="paolosalvatori"
gitHubRepo="ofn-azure-install"
url="https://api.github.com/repos/$gitHubOwner/$gitHubRepo/dispatches"
keyVaultName="BaboKeyVault"
keyVaultSecretName="GitHubPersonalAccessToken"
eventType="deploy_dev_env"

# Set the payload
read -r -d '' payload << EndOfMessage
{
    "event_type": "deploy_dev_env",
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
echo "Retrieving the personal access token for the [$gitHubOwner] GitHub account from the [$keyVaultSecretName] secret in [$keyVaultName] key vault..."
gitHubPAT=$(az keyvault secret show \
    --name $keyVaultSecretName \
    --vault-name $keyVaultName \
    --query value \
    --output tsv)

if [[ $? == 0 ]]; then
    echo "Personal access token for the [$gitHubOwner] GitHub account successfully retrieved from the [$keyVaultSecretName] secret in [$keyVaultName] key vault"
else
    echo "Failed to retrieve the Personal access token for the [$gitHubOwner] GitHub account from the [$keyVaultSecretName] secret in [$keyVaultName] key vault"
fi

# Manually call the deploy_arm_template type via a repository_dispatch event
echo "Calling [$eventType] workflow..."
httpCode=$(curl \
    --header "Authorization: token $gitHubPAT" \
    --header "Accept: application/vnd.github.everest-preview+json" \
    --request POST \
    --data "$payload" \
    --write-out "%{http_code}" \
    $url)

if (( $httpCode >= 200 && $httpCode < 300 )); then
    echo "[$eventType] workflow successfully called"
else
    echo "Failed to call the [$eventType] worklow"
fi