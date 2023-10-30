# frozen_string_literal: true

describe ExternalApi::WebexService do
  before do
    subject { ExternalApi::WebexService.new }
    stub_const("ENV", "WEBEX_HOST" => "fake.api")
    stub_const("ENV", "WEBEX_DOMAIN" => ".webex.com")
    stub_const("ENV", "WEBEX_CLIENT_ID" => "fake_id")
    stub_const("ENV", "WEBEX_CLIENT_SECRET" => "fake_secret")
    stub_const("ENV", "WEBEX_REFRESH_TOKEN" => "fake_token")
  end

  describe "OAuth" do
    let(:example_auth_response_body) do
      { "access_token": "fake_token",
        "refresh_token": "fake_token",
        "expires_in": "99999999",
        "refresh_token_expires_in": "99999999" }
    end
    header = { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" }
    let(:example_auth_response) { HTTPI::Response.new(200, header, example_auth_response_body.to_json) }
    let(:caseflow_auth_response) { ExternalApi::WebexService::Response.new(example_auth_response) }
    it "refreshes access token" do
      allow(Faraday).to receive(:post).and_return(example_auth_response)
      expect(subject.refresh_access_token).to eq(caseflow_auth_response.resp)
    end
  end

  context "error" do
    let(:example_expired_refresh_token_response) do
      { "error": "invalid_token",
        "error_description": "The access token expired" }
    end
    header = { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" }
    let(:example_401_response) { HTTPI::Response.new(401, header, example_expired_refresh_token_response.to_json) }
    let(:caseflow_401_response) { ExternalApi::WebexService::Response.new(example_401_response) }
    it "returns an invalid token error" do
      allow(Faraday).to receive(:post).and_return(example_401_response)
      expect { subject.refresh_access_token }.to raise_error(Caseflow::Error::WebexInvalidTokenError)
    end
  end
end
