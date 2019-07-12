describe Api::V3::DecisionReview::HigherLevelReviewsController, type: :request do
  fdescribe '#create' do #TODO remove 'f'
    it 'should return a 202 on success' do
      post '/api/v3/decision_review/higher_level_reviews'
      expect(response).to have_http_status(202)
    end
    it 'should be a jsonapi IntakeStatus response' do
      post '/api/v3/decision_review/higher_level_reviews'
      json = JSON.parse(response.body)
      expect(json["data"].keys).to include('id', 'type', 'attributes')
      expect(json['data']['type']).to eq 'IntakeStatus'
      expect(json['data']['attributes']['status']).to be_a String
    end
  end
end