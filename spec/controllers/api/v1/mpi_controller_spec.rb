# frozen_string_literal: true

describe Api::V1::MpiController, type: :controller do
  let(:api_key) { ApiKey.create!(consumer_name: "API Consumer").key_string }
  let(:request_params) do
    {
      veterans_id: "123456789",
      deceased_ind: true,
      deceased_time: 1.day.ago
    }
  end

  context "authorization" do
    it "fails if user provides no API key" do
      post :veteran_updates, params: request_params
      expect(response.status).to eq(401)
    end

    it "fails if user provides a bad API key" do
      request.headers["Authorization"] = "bad_api_key"
      post :veteran_updates, params: request_params
      expect(response.status).to eq(401)
    end
  end

  context "with good request" do
    it "returns 200 and calls update_veteran_nod" do
      expect(VACOLS::Correspondent).to receive(:update_veteran_nod).and_return("SUCCESSFUL")
      request.headers["Authorization"] = "Bearer #{api_key}"
      post :veteran_updates, params: request_params
      expect(response.status).to eq(200)
    end
  end
end
