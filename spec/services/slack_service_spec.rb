describe SlackService do
  it "posts to http" do
    slack_service = SlackService.new(url: "http://www.example.com")
    allow_any_instance_of(HTTPClient).to receive(:post).and_return('response')
    response = slack_service.send_notification("hello")
    expect(response).to eq("response")
  end
end