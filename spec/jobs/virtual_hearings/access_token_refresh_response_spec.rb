# frozen_string_literal: true

require "spec_helper"

RSpec.describe ExternalApi::WebexService::AccessTokenRefreshResponse do
  let(:access_token) { SecureRandom.hex }
  let(:refresh_token) { SecureRandom.hex }
  let(:raw_body) do
    {
      "access_token" => access_token,
      "refresh_token" => refresh_token
    }.to_json
  end
  let(:http_response) { instance_double(HTTPI::Response, raw_body: raw_body, code: 200) }
  let(:response) { described_class.new(http_response) }

  describe "#data" do
    it "returns the parsed JSON response body" do
      expect(response.data).to eq(JSON.parse(raw_body))
    end
  end

  describe "#access_token" do
    it "returns the access token from the response data" do
      expect(response.access_token).to eq(access_token)
    end
  end

  describe "#refresh_token" do
    it "returns the refresh token from the response data" do
      expect(response.refresh_token).to eq(refresh_token)
    end
  end
end
