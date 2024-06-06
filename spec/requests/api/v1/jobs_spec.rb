require 'swagger_helper'

RSpec.describe 'api/v1/jobs', type: :request, skip: true do

  path '/api/v1/jobs' do

    post('create job') do
      response(200, 'successful') do

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
