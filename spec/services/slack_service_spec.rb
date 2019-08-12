# frozen_string_literal: true

require "rails_helper"

describe SlackService do
  context "channel and title not specified, DEPLOY_ENV not set" do
    it "makes a POST HTTP request with default Slack params" do
      http_library = FakeHttpLibrary.new
      url = "http://www.example.com"
      stub_const("ENV", "SLACK_DISPATCH_ALERT_URL" => url)
      slack_service = SlackService.new(msg: "hello", http_service: http_library)
      slack_msg = {
        username: "Caseflow (development)",
        channel: "#appeals-app-alerts",
        attachments: [
          {
            title: "",
            color: "#ccc",
            text: "hello"
          }
        ]
      }

      params = {
        body: slack_msg.to_json,
        headers: { "Content-Type" => "application/json" }
      }

      expect(http_library).to receive(:post).with(url, params)

      slack_service.send_notification
    end
  end

  context "DEPLOY_ENV is set" do
    it "lists value of DEPLOY_ENV in username attribute" do
      http_library = FakeHttpLibrary.new
      url = "http://www.example.com"
      stub_const("ENV", "SLACK_DISPATCH_ALERT_URL" => url, "DEPLOY_ENV" => "test")
      slack_service = SlackService.new(msg: "hello", http_service: http_library)
      slack_msg = {
        username: "Caseflow (test)",
        channel: "#appeals-app-alerts",
        attachments: [
          {
            title: "",
            color: "#ccc",
            text: "hello"
          }
        ]
      }

      params = {
        body: slack_msg.to_json,
        headers: { "Content-Type" => "application/json" }
      }

      expect(http_library).to receive(:post).with(url, params)

      slack_service.send_notification
    end
  end

  context "channel specified and already starts with the # character" do
    it "does not add another # character to the channel param" do
      http_library = FakeHttpLibrary.new
      url = "http://www.example.com"
      stub_const("ENV", "SLACK_DISPATCH_ALERT_URL" => url)
      slack_service = SlackService.new(
        msg: "hello", title: "title", channel: "#channel", http_service: http_library
      )
      slack_msg = {
        username: "Caseflow (development)",
        channel: "#channel",
        attachments: [
          {
            title: "title",
            color: "#ccc",
            text: "hello"
          }
        ]
      }

      params = {
        body: slack_msg.to_json,
        headers: { "Content-Type" => "application/json" }
      }

      expect(http_library).to receive(:post).with(url, params)

      slack_service.send_notification
    end
  end

  context "channel specified but doesn't include # character" do
    it "does prepends channel name with # character" do
      http_library = FakeHttpLibrary.new
      url = "http://www.example.com"
      stub_const("ENV", "SLACK_DISPATCH_ALERT_URL" => url)
      slack_service = SlackService.new(
        msg: "hello", title: "title", channel: "channel", http_service: http_library
      )
      slack_msg = {
        username: "Caseflow (development)",
        channel: "#channel",
        attachments: [
          {
            title: "title",
            color: "#ccc",
            text: "hello"
          }
        ]
      }

      params = {
        body: slack_msg.to_json,
        headers: { "Content-Type" => "application/json" }
      }

      expect(http_library).to receive(:post).with(url, params)

      slack_service.send_notification
    end
  end

  it "returns the http response" do
    http_library = FakeHttpLibrary.new
    slack_service = SlackService.new(msg: "hello", http_service: http_library)
    stub_const("ENV", "SLACK_DISPATCH_ALERT_URL" => "http://www.example.com")
    allow(http_library).to receive(:post).and_return("response")
    response = slack_service.send_notification

    expect(response).to eq("response")
  end

  context "when it is run in the uat environment" do
    it "does not make post request" do
      http_library = FakeHttpLibrary.new
      slack_service = SlackService.new(msg: "hello", http_service: http_library)
      stub_const("ENV", "DEPLOY_ENV" => "uat")

      expect(http_library).to_not receive(:post)

      slack_service.send_notification
    end
  end

  context "when SLACK_DISPATCH_ALERT_URL env var is not set" do
    it "does not make post request" do
      http_library = FakeHttpLibrary.new
      slack_service = SlackService.new(msg: "hello", http_service: http_library)

      expect(http_library).to_not receive(:post)

      slack_service.send_notification
    end
  end
end
