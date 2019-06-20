require "rails_helper"

RSpec.describe LighthouseApi::Docs::V0::DocsController, type: :request do
  describe '#intakes' do
    fit 'should show openapi spec json' do
      get '/lighthouse_api/docs/v0/intakes'
      expect(response).to have_http_status(200)

      json = JSON.parse(response.body)
      expect(json["openapi"]).to eq('3.0.0')
    end
  end
end
