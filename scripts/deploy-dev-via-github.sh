#!/bin/bash

# Variables
gitHubOwner="paolosalvatori"
gitHubRepo="ofn-azure-install"
url="https://api.github.com/repos/$gitHubOwner/$gitHubRepo/dispatches"
keyVaultName="BaboKeyVault"
keyVaultSecretName="GitHubPersonalAccessToken"
eventType="deploy_ofn_dev_env"

# Formatting
redPrefix="\033[38;5;1m"
redPostfix="\033[m"

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
echo -e "Retrieving the personal access token for the [${redPrefix}${gitHubOwner}${redPostfix}] GitHub account from the [${redPrefix}${keyVaultSecretName}${redPostfix}] secret in [${redPrefix}${keyVaultName}${redPostfix}] key vault..."
gitHubPAT=$(az keyvault secret show \
    --name $keyVaultSecretName \
    --vault-name $keyVaultName \
    --query value \
    --output tsv)

if [[ $? == 0 ]]; then
    echo -e "Personal access token for the [${redPrefix}${gitHubOwner}${redPostfix}] GitHub account successfully retrieved from the [${redPrefix}${keyVaultSecretName}${redPostfix}] secret in [${redPrefix}${keyVaultName}${redPostfix}] key vault"
else
    echo -e "Failed to retrieve the Personal access token for the [$gitHubOwner] GitHub account from the [${redPrefix}${keyVaultSecretName}${redPostfix}] secret in [${redPrefix}${keyVaultName}${redPostfix}] key vault"
fi

# Manually call the deploy_arm_template type via a repository_dispatch event
echo -e "Calling [${redPrefix}${eventType}${redPostfix}] workflow in the [${redPrefix}${gitHubRepo}${redPostfix}] GitHub repo..."
httpCode=$(curl \
    --header "Authorization: token $gitHubPAT" \
    --header "Accept: application/vnd.github.everest-preview+json" \
    --request POST \
    --data "$payload" \
    --write-out "%{http_code}" \
    $url)

if (( $httpCode >= 200 && $httpCode < 300 )); then
    echo -e "[${redPrefix}${eventType}${redPostfix}] workflow successfully called in the [${redPrefix}${gitHubRepo}${redPostfix}] GitHub repo"
else
    echo -e "Failed to call the [${redPrefix}${eventType}${redPostfix}] worklow in the [${redPrefix}${gitHubRepo}${redPostfix}] GitHub repo"
fi