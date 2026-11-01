"""
Undeploys the Vector Search index, stopping the ~$0.094/hour billing
from deploy_index.py. The index itself (and all its data) is untouched
and free to keep - only the serving machine goes away. Redeploying
later takes the same ~20-30 min as the original deploy.

Run: python src/undeploy_index.py
"""

import os

from dotenv import load_dotenv
from google.cloud import aiplatform

load_dotenv()

PROJECT_ID = os.environ["PROJECT_ID"]
LOCATION = os.environ["INDEX_LOCATION"]
INDEX_ENDPOINT_RESOURCE_NAME = os.environ["INDEX_ENDPOINT_RESOURCE_NAME"]
DEPLOYED_INDEX_ID = os.environ["DEPLOYED_INDEX_ID"]

aiplatform.init(project=PROJECT_ID, location=LOCATION)


def undeploy_index():
    index_endpoint = aiplatform.MatchingEngineIndexEndpoint(INDEX_ENDPOINT_RESOURCE_NAME)
    print("Undeploying - this can take a few minutes...")
    index_endpoint.undeploy_index(deployed_index_id=DEPLOYED_INDEX_ID)
    print("Undeployed. Billing for the deployed index has stopped.")


if __name__ == "__main__":
    undeploy_index()