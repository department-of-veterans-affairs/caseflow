describe "Health Check API" do
  it "returns meta info about the app" do
    Rails.application.config.build_version = { deployed_at: "the best day ever" }

    get "/health-check"

    expect(response).to be_success

    json = JSON.parse(response.body)
    expect(json["healthy"]).to be_truthy
    expect(json["deployed_at"]).to eq("the best day ever")
  end
end
