describe Api::V3::DecisionReview::HigherLevelReviewsController, type: :request do
  fdescribe '#create' do #TODO remove 'f'
    it 'should return a 202 on success' do
      post '/api/v3/decision_review/higher_level_reviews'
      expect(response).to have_http_status(202)
    end
    it 'should be a jsonapi response' do
      post '/api/v3/decision_review/higher_level_reviews'
      json = JSON.parse(response.body)
      expect(json["openapi"]).to eq('3.0.0') #FIXME be a key that should actually come back
    end
  end
end