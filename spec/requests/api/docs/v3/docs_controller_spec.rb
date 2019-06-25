require "rails_helper"

RSpec.describe Api::Docs::V3::DocsController, type: :request do
  describe '#decision_reviews' do
    it 'should successfully return openapi spec' do
      get '/api/docs/v3/decision_reviews'
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json["openapi"]).to eq('3.0.0')
    end
    describe '/higher_level_review documentation' do
      before(:each) do
        get '/api/docs/v3/decision_reviews'
      end
      let(:hlr_doc){
        json = JSON.parse(response.body)
        json['paths']['/higher_level_reviews']
      }
      it 'should have POST' do
        expect(hlr_doc).to include('post')
      end
      # TODO when doc is real, verify some other stuff about it
    end
  end
end
