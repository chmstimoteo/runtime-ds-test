from googleapiclient import discovery
from oauth2client.service_account import ServiceAccountCredentials
import google.auth
import argparse


GCP_PROJECT = ''  # Change to GCP project where the Cloud ML Engine model is deployed
CMLE_MODEL_NAME = ''  # Change to the deployed Cloud ML Engine model
CMLE_MODEL_VERSION = None  # If None, the default version will be used
scopes = ['https://www.googleapis.com/auth/cloud-platform']


def predict_cmle(instances):
    """ Use a deployed model to Cloud ML Engine to perform prediction

    Args:
        instances: list of json, csv, or tf.example objects, based on the serving function called
    Returns:
        response - dictionary. If no error, response will include an item with 'predictions' key
    """

    #credentials = GoogleCredentials.get_application_default()
    credentials = ServiceAccountCredentials.from_json_keyfile_name('cloud-mle-service-account.json', scopes=scopes)

    service = discovery.build('ml', 'v1', credentials=credentials)
    #service = discovery.build('ml', 'v1')
    model_url = 'projects/{}/models/{}'.format(GCP_PROJECT, CMLE_MODEL_NAME)

    if CMLE_MODEL_VERSION is not None:
        model_url += '/versions/{}'.format(CMLE_MODEL_VERSION)

    request_data = {
        'instances': instances
    }

    response = service.projects().predict(
        body=request_data,
        name=model_url
    ).execute()

    output = response
    return output

def main():
    parser = argparse.ArgumentParser()

    # Input Arguments
    parser.add_argument(
        '--predict-file',
        help='GCS or local paths to JSON prediction input file',
        nargs='+',
        required=True
    )

    params = parser.parse_args()
    with open(params.predict_file[0]) as f:
        content = f.readlines()
    print(content[0])

    response = predict_cmle(content[0])
    print(response)

if __name__ == '__main__':
    main()