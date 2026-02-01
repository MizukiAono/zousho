#######################################################
# User Pool Outputs
#######################################################

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_name" {
  description = "Cognito User Pool Name"
  value       = aws_cognito_user_pool.main.name
}

output "user_pool_endpoint" {
  description = "Cognito User Pool Endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

#######################################################
# App Client Outputs
#######################################################

output "app_client_id" {
  description = "Cognito User Pool App Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "app_client_secret" {
  description = "Cognito User Pool App Client Secret (sensitive)"
  value       = aws_cognito_user_pool_client.main.client_secret
  sensitive   = true
}

#######################################################
# Domain Outputs
#######################################################

output "domain" {
  description = "Cognito User Pool Domain"
  value       = var.domain != "" ? aws_cognito_user_pool_domain.main[0].domain : null
}

output "domain_cloudfront_distribution" {
  description = "Cognito User Pool Domain CloudFront Distribution"
  value       = var.domain != "" ? aws_cognito_user_pool_domain.main[0].cloudfront_distribution : null
}

output "domain_cloudfront_distribution_arn" {
  description = "Cognito User Pool Domain CloudFront Distribution ARN"
  value       = var.domain != "" ? aws_cognito_user_pool_domain.main[0].cloudfront_distribution_arn : null
}

#######################################################
# User Groups Outputs
#######################################################

output "user_groups" {
  description = "Cognito User Groups"
  value = {
    for name, group in aws_cognito_user_group.groups : name => {
      id         = group.id
      name       = group.name
      precedence = group.precedence
      role_arn   = group.role_arn
    }
  }
}
