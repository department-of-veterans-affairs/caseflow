# frozen_string_literal: true

require "rails_helper"

OPENAPI = "3.0.2"
SECURITY = {
  bearerAuth: []
}.freeze
SECURITY_SCHEMES = {
  bearerAuth: {
    type: "http",
    scheme: "bearer",
    description: "API Key provided by Caseflow"
  }
}.freeze

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("app/controllers/swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: OPENAPI,
      info: {
        title: "API V1",
        version: "v1"
      },
      security: SECURITY,
      servers: [
        url: "/api/v1"
      ],
      paths: {},
      components: {
        securitySchemes: SECURITY_SCHEMES
      }
    },
    "v2/swagger.yaml" => {
      openapi: OPENAPI,
      info: {
        title: "API V2",
        version: "V2"
      },
      security: SECURITY,
      servers: [
        url: "/api/v2"
      ],
      paths: {},
      components: {
        securitySchemes: SECURITY_SCHEMES
      }
    },
    "v3/swagger.yaml" => {
      openapi: OPENAPI,
      info: {
        title: "API V3",
        version: "V3"
      },
      security: SECURITY,
      servers: [
        url: "/api/v3"
      ],
      paths: {},
      components: {
        securitySchemes: SECURITY_SCHEMES
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
