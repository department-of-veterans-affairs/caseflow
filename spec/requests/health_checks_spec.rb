describe "Health Check API" do
  Rails.application.config.build_version = { deployed_at: "the best day ever" }

  it "fails health check when unhealthy" do
    allow()

    get "/health-check"

    expect(response).to be_success

    json = JSON.parse(response.body)
    expect(json["healthy"]).to eq(false)
    expect(json["deployed_at"]).to eq("the best day ever")
  end

  it "passes health check when healthy" do
    get "/health-check"

    expect(response).to be_success

    json = JSON.parse(response.body)
    expect(json["healthy"]).to eq(true)
    expect(json["deployed_at"]).to eq("the best day ever")
  end
end
