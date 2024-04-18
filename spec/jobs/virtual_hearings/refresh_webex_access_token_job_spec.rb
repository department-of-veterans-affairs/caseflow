require "rails_helper"

RSpec.describe VirtualHearings::RefreshWebexAccessTokenJob, type: :job do
  let(:webex_service) { instance_double(Fakes::WebexService) }
  let(:new_access_token) { "1234567890abcdef" }
  let(:new_refresh_token) { "1234567890abcdef" }
  let(:response) { instance_double("WebexService::Response", success?: true, access_token: new_access_token, refresh_token: new_refresh_token) }

  before do
    allow(WebexService).to receive(:new).and_return(webex_service)
    allow(webex_service).to receive(:refresh_access_token).and_return(response)
    allow(CredStash).to receive(:put)
  end

  describe "#perform" do
    it "calls WebexService#refresh_access_token" do
      described_class.perform_now
      expect(webex_service).to have_received(:refresh_access_token)
    end

    context "when the response is successful" do
      it "updates the access token and refresh token in CredStash" do
        described_class.perform_now
        expect(CredStash).to have_received(:put).with("webex_#{Rails.deploy_env}_access_token", new_access_token)
        expect(CredStash).to have_received(:put).with("webex_#{Rails.deploy_env}_refresh_token", new_refresh_token)
      end
    end

    context "when an error occurs" do
      let(:error) { StandardError.new("error") }

      before do
        allow(Rails.logger).to receive(:error)
        allow(webex_service).to receive(:refresh_access_token).and_raise(error)
      end

      it "logs the error" do
        described_class.perform_now
        expect(Rails.logger).to have_received(:error).with(error)
      end
    end
  end
end
