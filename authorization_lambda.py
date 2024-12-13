import json
import boto3
import os
import base64
from botocore.exceptions import ClientError

secretName = os.environ['SECRETNAME']
region_name = os.environ['AWSREGION']

# Create a Secrets Manager client
session = boto3.session.Session()
client = session.client(
    service_name='secretsmanager',
    region_name=region_name
)

def lambda_handler(event, context):
    secretValue=''
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secretName)
        get_pending_secret_value_response = ""
        try: 
            get_pending_secret_value_response = client.get_secret_value(SecretId=secretName,VersionStage='AWSPENDING')
        except ClientError as e:
            print (e.response["Error"]["Code"])
        
        secret_HeaderValue = json.loads(get_secret_value_response['SecretString'])['HEADERVALUE']
        if get_pending_secret_value_response:
            pending_secret_HeaderValue = json.loads(get_pending_secret_value_response['SecretString'])['HEADERVALUE']
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        else:
            #default
            raise e

    if (event['headers']['x-origin-verify'] == secret_HeaderValue or event['headers']['x-origin-verify'] == pending_secret_HeaderValue):
        response = generateAllow('me', event['routeArn'])
        print (response)
        return response
    else:
        print('unauthorized')
        raise Exception('Unauthorized') # Return a 401 Unauthorized response

# Create IAM policy with 'Allow" effect/statement. For 'resource' we expect the API route ARN.
def generatePolicy(principalId, effect, resource):
    authResponse = {}
    authResponse['principalId'] = principalId
    if (effect and resource):
        policyDocument = {}
        policyDocument['Version'] = '2012-10-17'
        policyDocument['Statement'] = []
        statementOne = {}
        statementOne['Action'] = 'execute-api:Invoke'
        statementOne['Effect'] = effect
        statementOne['Resource'] = resource
        policyDocument['Statement'] = [statementOne]
        authResponse['policyDocument'] = policyDocument

    authResponse['context'] = {
        "stringKey": "stringval",
        "numberKey": 123,
        "booleanKey": True
    }

    return authResponse

def generateAllow(principalId, resource):
    return generatePolicy(principalId, 'Allow', resource)
