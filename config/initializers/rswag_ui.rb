Rswag::Ui.configure do |c|

  # List the Swagger endpoints that you want to be documented through the
  # swagger-ui. The first parameter is the path (absolute or relative to the UI
  # host) to the corresponding endpoint and the second is a title that will be
  # displayed in the document selector.
  # NOTE: If you're using rspec-api to expose Swagger files
  # (under openapi_root) as JSON or YAML endpoints, then the list below should
  # correspond to the relative paths for those endpoints.

  # The API V1, API V2, and API V3 swagger files are the rswag generated files

  unless Rails.in_upper_env?
    # c.openapi_endpoint '/api-docs/v1/swagger.yaml', 'API V1'
    c.openapi_endpoint '/api-docs/cmp/swagger.yaml', 'API V1: Correspondence CMP Integration'
    # c.openapi_endpoint '/api-docs/v2/swagger.yaml', 'API V2'
    # c.openapi_endpoint '/api-docs/v3/swagger.yaml', 'API V3'
    c.openapi_endpoint '/api-docs/v3/ama_issues.yaml', 'API V3: AMA Request Issues'
    c.openapi_endpoint '/api-docs/v3/decision_reviews.yaml', 'API V3: Decision Reviews'
    c.openapi_endpoint '/api-docs/v3/vacols_issues.yaml', 'API V3: VACOLS Issues'
    c.openapi_endpoint '/api-docs/idt/swagger.yaml', 'IDT-Caseflow-Package Manager Bridge API'
  end

  # Add Basic Auth in case your API is private
  # c.basic_auth_enabled = true
  # c.basic_auth_credentials 'username', 'password'
end
