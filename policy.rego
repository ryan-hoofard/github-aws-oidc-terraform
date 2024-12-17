package terraform

import rego.v1

default allow := false

allow if {
	some api_gateway in input.configuration.root_module.resources
	api_gateway.type == "aws_apigatewayv2_api"
	api_address := api_gateway.address
	some cloudfront in input.configuration.root_module.resources
	cloudfront.type == "aws_cloudfront_distribution"
	some origin in cloudfront.expressions.origin
	some ref in origin.domain_name.references
	ref == api_address
	print(ref)
	print(api_address)
}
