from azure.storage.blob import BlobServiceClient
from azure.core.exceptions import ResourceNotFoundError
import os

# Azure Storage connection string
CONNECTION_STRING = "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=instacartstorage123;AccountKey=RuSOWLQeMdQCJbWpL2Pl/p0gGDLsOX3BGApLf3kK/IQnYsSVA3TechIbOvOs/qBar+IpBxlsmS7e+AStKcq1hg==;BlobEndpoint=https://instacartstorage123.blob.core.windows.net/;FileEndpoint=https://instacartstorage123.file.core.windows.net/;QueueEndpoint=https://instacartstorage123.queue.core.windows.net/;TableEndpoint=https://instacartstorage123.table.core.windows.net/"
CONTAINER_NAME = "instacartdata"

# Local path
PROCESSED_DATA_PATH = '../../1_data/processed/'

def validate_azure_connection(blob_service_client, container_name):
    """Validate Azure connection by checking if a known container is accessible"""
    try:
        container_client = blob_service_client.get_container_client(container_name)
        container_client.get_container_properties()
        print(f"Successfully connected to container: {container_name}")
        return True
    except ResourceNotFoundError:
        print(f"Container '{container_name}' not found")
        return False
    except Exception as e:
        print(f"Connection failed: {str(e)}")
        return False

def upload_to_azure():
    """Upload processed data to Azure Blob Storage"""
    print("Initializing connection to Azure Storage Account...")
    
    try:
        # Create a blob service client using connection string
        blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
        
        # Validate connection
        if not validate_azure_connection(blob_service_client, CONTAINER_NAME):
            print("Failed to validate Azure connection. Please check your credentials or container name.")
            return
        
        # Get container client
        container_client = blob_service_client.get_container_client(CONTAINER_NAME)
        
        # Verify that the data directory exists
        if not os.path.exists(PROCESSED_DATA_PATH):
            print(f"Error: Directory not found: {PROCESSED_DATA_PATH}")
            return
        
        # Upload each file
        files_uploaded = 0
        for filename in os.listdir(PROCESSED_DATA_PATH):
            if filename.endswith('.csv'):
                local_file_path = os.path.join(PROCESSED_DATA_PATH, filename)
                blob_client = container_client.get_blob_client(filename)
                
                print(f"Uploading {filename}...")
                try:
                    with open(local_file_path, "rb") as data:
                        blob_client.upload_blob(data, overwrite=True)
                    files_uploaded += 1
                    print(f"Successfully uploaded: {filename}")
                except Exception as e:
                    print(f"Failed to upload {filename}: {str(e)}")
        
        print(f"Upload completed. {files_uploaded} files uploaded.")
    
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        raise

if __name__ == "__main__":
    upload_to_azure()