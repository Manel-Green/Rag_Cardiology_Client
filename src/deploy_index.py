"""
Step 5: Deploy the Vector Search index to an endpoint so it can
actually be queried.

This is the step that starts hourly billing (~$0.094/hour for a single
e2-standard-2 node) - the index itself (already created) is free to
store, but only a deployed index can answer queries. Undeploy after
testing to stop billing; redeploy later takes the same ~20-30 min.

Run: python src/deploy_index.py
"""
import os
from dotenv import load_dotenv
from google.cloud import aiplatform
load_dotenv()

PROJECT_ID = os.environ["PROJECT_ID"]
LOCATION = os.environ["INDEX_LOCATION"]
INDEX_RESOURCE_NAME = os.environ["INDEX_RESOURCE_NAME"]
INDEX_ENDPOINT_RESOURCE_NAME = os.environ["INDEX_ENDPOINT_RESOURCE_NAME"]
DEPLOYED_INDEX_ID = os.environ["DEPLOYED_INDEX_ID"]

aiplatform.init(project=PROJECT_ID, location=LOCATION)


def deploy_index():
    index = aiplatform.MatchingEngineIndex(INDEX_RESOURCE_NAME)

    print("Using existing index endpoint...")
    index_endpoint = aiplatform.MatchingEngineIndexEndpoint(INDEX_ENDPOINT_RESOURCE_NAME)
    print(f"Index endpoint resource name: {index_endpoint.resource_name}")

    print("Deploying index to endpoint - this can take 20-30 minutes...")
    index_endpoint.deploy_index(
        index=index,
        deployed_index_id=DEPLOYED_INDEX_ID,
        machine_type="e2-standard-2",
        min_replica_count=1,
        max_replica_count=1,
    )

    print("Deployed.")
    print(f"Index endpoint resource name: {index_endpoint.resource_name}")
    print(f"Deployed index id: {DEPLOYED_INDEX_ID}")


if __name__ == "__main__":
    deploy_index()
