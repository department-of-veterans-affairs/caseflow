# frozen_string_literal: true

describe Api::MetadataController, type: :request do
  describe "#index" do
    it "should successfully return metadata json object" do
      get "/api/metadata"
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to have_key("meta")
    end
  end
end
