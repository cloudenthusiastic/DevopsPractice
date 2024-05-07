from colorama import Fore, init
from google.cloud import storage
import subprocess
import requests
import base64
import json
import getpass
import random
import string


def bucketCreation(SITE_ID, USER_NAME, PASS, bucketCount):
    global response, column_index
    # url = f'https://teradatacs.service-now.com/api/now/table/u_cmdb_ci_siteid?name={SITE_ID}'  # Replace with the URL you want to request
    # username = f'{USER_NAME}@teradatacloud.com'
    #
    # # Encode the username and password as a Base64 string
    # credentials = base64.b64encode(f"{username}:{PASS}".encode('utf-8')).decode('utf-8')
    #
    # # Include the Authorization header with Basic Authentication
    # headers = {
    #     'Authorization': f'Basic {credentials}'
    # }
    #
    # try:
    #     response = requests.get(url, headers=headers)
    #     if response.status_code == 200:
    #         pass
    #     else:
    #         print(f"Request failed with status code {response.status_code}")
    # except requests.exceptions.RequestException as e:
    #     print(f"Request encountered an error: {e}")
    #
    # # Parse the JSON response
    # data = json.loads(response.text)
    #
    # # Extract u_cloud_account_id and u_region
    # PROJECT_ID = data["result"][0]["u_cloud_account_id"]
    # REGION_NAME = data["result"][0]["u_region"] + "-" + data["result"][0]["u_availability_zone"]
    PROJECT_ID = 'fluid-amulet-422612-u0'
    REGION_NAME = 'us-west2'
    ##############################

    # Initialize colorama
    init(autoreset=True)

    # Print the message in cyan
    print(Fore.CYAN + "AUTHORIZED THE REQUEST USING TERADATACLOUD AND WAIT UNTIL NEXT SUCCESSFUL MESSAGE COMES UP")
    print("-----------------------------------------")

    cmd = "gcloud auth application-default login >$null 2>&1"

    returned_value = subprocess.call(cmd, shell=True)

    if returned_value != 0:
        print(f"Error. Command returned {returned_value}")
    else:
        print(Fore.GREEN + "Authenticate Successfully")

    # gcloud config set project admin-service-prod'

    # command = f'gcloud config set project {PROJECT_ID}'

    ##########################
    print(Fore.GREEN + f"Please Be Patience I AM Creating {bucketCount} GCS Bucket for {SITE_ID}.....")
    # compute = discovery.build('compute', 'v1')
    # result = compute.instances().list(project=PROJECT_ID, zone=REGION_NAME).execute()

    storage_client = storage.Client(project=PROJECT_ID)

    for count in range(1, bucketCount + 1):
        bucket_name = f"{SITE_ID.lower()}-dsc-bucket-{count}"
        bucket = storage_client.create_bucket(bucket_name, location=REGION_NAME)
        # Create folders inside the bucket
        i = 0
        for folder in range(4):
            i += 1

            def generate_random_name(count):
                prefix = ''.join(random.choices(string.digits, k=1))
                mid_section = ''.join(random.choices(string.ascii_lowercase + string.digits, k=5))
                return f"{prefix}{mid_section}-fb{count}_{i}"
                # return f"{prefix}{mid_section}-fb{count}_{random.randint(1, 4)}"

            random_name = generate_random_name(count)
            blob = bucket.blob(f"{random_name}")  # Add a trailing slash to create a "folder"
            blob.upload_from_string('')  # Upload an empty string to create the folder

    # buckets = list(storage_client.list_buckets())
    buckets = storage_client.list_buckets()
    print("List of buckets:")
    for bucket in buckets:
        print(f"Bucket Name: {bucket.name}")
        blobs = storage_client.list_blobs(f"{bucket.name}")
        for blob in blobs:
            print(f"-Folder Name: {blob.name}")


if __name__ == '__main__':
    SITE_ID = input("Please Enter Site_ID :")
    USER_NAME = input("Enter Your TeradataCloud UserName (e.g.kunal.sapkal):")
    PASS = getpass.getpass("Enter Your TeradataCloud Password:")
    bucketCount = int(input("How many buckets you want to create (Should be more than 4)?:"))

    bucketCreation(SITE_ID, USER_NAME, PASS, bucketCount)
