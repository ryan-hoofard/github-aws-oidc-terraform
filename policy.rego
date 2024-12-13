package terraform

import rego.v1

allow if {
	cloudfront_exists
	http_api_exists
	cloudfront_origin_is_api_gateway
}

# Whether there is any change to IAM
http_api_exists if {
	some api_gateway in data.terraform.resources
	api_gateway.type == "aws_apigatewayv2_api" # Corrected to API Gateway v2 HTTP API
    print(api_gateway)
}

cloudfront_exists if {
	some cloudfront in data.terraform.resources
	cloudfront.type == "aws_cloudfront_distribution"
    print(cloudfront)
}

cloudfront_origin_is_api_gateway if {
	some cloudfront in data.terraform.resources
	cloudfront.type == "aws_cloudfront_distribution"
	some api_gateway in data.terraform.resources
	api_gateway.type == "aws_apigatewayv2_api" # Corrected to API Gateway v2 HTTP API
	name := api_gateway.address
	some origin in cloudfront.values.origins
	some reference in origin.domain_name.references
	print("reference", reference)
	print("name", name)
	reference == name
}
