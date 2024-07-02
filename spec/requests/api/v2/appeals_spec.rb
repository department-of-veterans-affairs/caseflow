# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v2/appeals", type: :request, openapi_spec: "v2/swagger.yaml", skip: true do
  path "/api/v2/appeals" do
    get("list appeals") do
      response(200, "successful") do
        after do |example|
          example.metadata[:response][:content] = {
            "application/json" => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
