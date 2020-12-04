# frozen_string_literal: true

describe SlackService do
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }
  let(:http_agent) { double("http") }
  let(:ssl_config) { double("ssl") }

  before do
    @http_params = nil
    allow(HTTPClient).to receive(:new) { http_agent }
    allow(http_agent).to receive(:ssl_config) { ssl_config }
    allow(ssl_config).to receive(:clear_cert_store) { true }
    allow(ssl_config).to receive(:add_trust_ca) { true }
    allow(http_agent).to receive(:post) do |_url, params|
      @http_params = params
      "response"
    end
  end

  it "posts to http" do
    response = slack_service.send_notification("hello")
    expect(response).to eq("response")
  end

  context "when it is run in the uat environment" do
    it "does not make post request" do
      stub_const("ENV", "DEPLOY_ENV" => "uat")
      slack_service.send_notification("filler message contents")
      expect(@http_params).to be_nil
    end
  end

  context "color selection" do
    context "title contains ERROR" do
      it "picks red color" do
        slack_service.send_notification("filler message contents", "[ERROR] ouch!")
        expect(@http_params[:body]).to match(/"#ff0000"/)
      end
    end

    context "message contains error but title contains warning" do
      it "picks yellow color" do
        slack_service.send_notification("there was an error", "Really just a warning")
        expect(@http_params[:body]).to match(/"#ffff00"/)
      end
    end

    context "message contains error" do
      it "picks red color" do
        slack_service.send_notification("there was an error")
        expect(@http_params[:body]).to match(/"#ff0000"/)
      end
    end

    context "message contains warning" do
      it "picks yellow color" do
        slack_service.send_notification("a warning of something")
        expect(@http_params[:body]).to match(/"#ffff00"/)
      end
    end

    context "no magic string" do
      it "defaults to gray" do
        slack_service.send_notification("hello world")
        expect(@http_params[:body]).to match(/"#cccccc"/)
      end
    end
  end
end
