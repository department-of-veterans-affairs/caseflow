# frozen_string_literal: true

RSpec.describe Hearings::RefreshWebexAccessTokenJob, type: :job do
  let(:new_access_token) { "token1" }
  let(:new_refresh_token) { "token2" }

  before do
    allow(CredStash).to receive(:put)
  end

  describe "#perform" do
    it "calls WebexService#refresh_access_token" do
      expect_any_instance_of(WebexService).to receive(:refresh_access_token)

      described_class.perform_now
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
        allow_any_instance_of(WebexService).to receive(:refresh_access_token).and_raise(error)
      end

      it "logs the error" do
        described_class.perform_now

        expect(Rails.logger).to have_received(:error).with(error)
      end
    end
  end
end
