describe "Health Check API" do
  context "mock tests" do
    before do
      Rails.application.config.build_version = { deployed_at: "the best day ever" }
      FakeWeb.allow_net_connect = false
    end

    after { FakeWeb.allow_net_connect = true }

    context "pushgateway offline" do
      it "fails health check when pushgateway is offline" do
        get "/health-check"

        expect(response).to be_success

        json = JSON.parse(response.body)
        expect(json["healthy"]).to eq(false)
        expect(json["deployed_at"]).to eq("the best day ever")
      end
    end

    context "service online and unhealthy" do
      before do
        FakeWeb.register_uri(
          :get, "http://127.0.0.1:9091/-/healthy",
          body: "Error",
          status: ["503", "Service Unavailable"]
        )
      end

      after { FakeWeb.clean_registry }

      it "fails health check when pushgateway is unhealthy" do
        Rails.application.config.build_version = { deployed_at: "the best day ever" }

        get "/health-check"

        expect(response).to be_success

        json = JSON.parse(response.body)
        expect(json["healthy"]).to eq(false)
        expect(json["deployed_at"]).to eq("the best day ever")
      end
    end

    context "service online and healthy" do
      before do
        FakeWeb.register_uri(
          :get, "http://127.0.0.1:9091/-/healthy",
          body: "OK"
        )
      end

      after { FakeWeb.clean_registry }

      it "passes health check when everything is working" do
        Rails.application.config.build_version = { deployed_at: "the best day ever" }

        get "/health-check"

        expect(response).to be_success

        json = JSON.parse(response.body)
        expect(json["healthy"]).to be_truthy
        expect(json["deployed_at"]).to eq("the best day ever")
      end
    end
  end
end
