import json

def lambda_handler(event, context):
  return {
        'statusCode': 200,
        'body': json.dumps('Sample Website. Content comes through the HTTP API Gateway.')
    }
