#!/bin/bash

set -e

# download model from Hugging Face
echo "Downloading bge-reranker-v2-m3 model from Hugging Face.."
MODEL_DIR="model_asset/model"
mkdir -p $MODEL_DIR
FILES=(
 "config.json"
 "model.safetensors"
 "sentencepiece.bpe.model"
 "special_tokens_map.json"
 "tokenizer.json"
 "tokenizer_config.json"
)
BASE_URL="https://huggingface.co/BAAI/bge-reranker-v2-m3/resolve/main"

for FILE in "${FILES[@]}"; do
 curl -L -o "$MODEL_DIR/$FILE" "$BASE_URL/$FILE?download=true"
done

source <(azd env get-values)

# <create_deployment>
echo "Deploying bge-reranker-v2-m3 model to Azure Machine Learning Workspace.."
az login
az account set --subscription $AZURE_SUBSCRIPTION_ID
az ml online-deployment create --name $AZURE_AML_DEPLOYMENT_NAME --endpoint $AZURE_AML_ENDPOINT_NAME -f model_asset/deployment.yml --all-traffic --resource-group $AZURE_RESOURCE_GROUP_NAME --workspace-name $AZURE_AML_WORKSPACE_NAME
# </create_deployment>
