#!/bin/zsh

# Change these to match your project
PROJECT_ID="budget-21dbe"
REGION="us-central1"
FUNCTION_NAME="logClient"

curl -X POST \
  "https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${FUNCTION_NAME}" \
  -H "Content-Type: application/json" \
  -d '{
    "level": "info",
    "message": "Hello World from zsh",
    "metadata": {
      "source": "zsh_test"
    }
  }'

echo ""
echo "Log request sent."
