describe Api::V3::HigherLevelReviewsController, type: :request do
  describe '#create' do
    it 'should return a 202 on success' do
      get '/api/docs/v3/decision_reviews'
      expect(response).to have_http_status(202)
      # json = JSON.parse(response.body)
      # expect(json["openapi"]).to eq('3.0.0')
    end
  end
end