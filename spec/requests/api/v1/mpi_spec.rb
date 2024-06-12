# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "api/v1/mpi", type: :request, skip: true do
  path "/api/v1/mpi" do
    post("veteran_updates mpi") do
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
