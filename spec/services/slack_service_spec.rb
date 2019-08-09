# frozen_string_literal: true

describe SlackService do
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  it "posts to http" do
    allow_any_instance_of(HTTPClient).to receive(:post).and_return("response")
    response = slack_service.send_notification("hello")
    expect(response).to eq("response")
  end

  context "when it is run in the uat environment" do
    it "does not make post request" do
      stub_const("ENV", "DEPLOY_ENV" => "uat")
      expect_any_instance_of(HTTPClient).to_not receive(:post)
      slack_service.send_notification("filler message contents")
    end
  end
end
