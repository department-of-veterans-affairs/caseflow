describe ExternalApi::ApiService do
  context ".request", focus: true do

    subject do
      ExternalApi::ApiService.request("Test ApiService",
                                      service: :api,
                                      name: "endpoint") do
        "Do Nothing"
      end
    end

    context "when feature flag is turned on" do
      before do
        FeatureToggle.enable!(:release_db_connections)
      end

      it "calls MetricsService" do
        expect(MetricsService).to receive(:record).once
        subject
      end

      context "when not in a transaction" do

      end

      context "when in a transaction" do
        
      end
    end

    context "when feature flag is turned off" do
      before do
        FeatureToggle.disable!(:release_db_connections)
      end

      it "just calls MetricsService" do
        expect(MetricsService).to receive(:record).once
        subject
      end
    end
  end
end
