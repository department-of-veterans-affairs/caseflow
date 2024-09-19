# frozen_string_literal: true

describe MetricsService do
  let!(:current_user) { User.authenticate! }
  let!(:appeal) { create(:appeal) }
  let(:description) { "Test description" }
  let(:service) { "Reader" }
  let(:name) { "Test" }

  describe ".record" do
    subject do
      MetricsService.record(description, service: service, name: name) do
        appeal.appeal_views.find_or_create_by(user: current_user).update!(last_viewed_at: Time.zone.now)
      end
    end

    context "metrics_monitoring is disabled" do
      before { FeatureToggle.disable!(:metrics_monitoring) }
      it "Store record metric returns nil" do
        expect(MetricsService).to receive(:store_record_metric).and_return(nil)

        subject
      end
    end

    context "metrics_monitoring is enabled" do
      before do
        FeatureToggle.enable!(:metrics_monitoring)
      end

      it "records metrics" do
        allow(Rails.logger).to receive(:info)

        expect(MetricsService).to receive(:emit_gauge).with(
          metric_group: "service",
          metric_name: "request_latency",
          metric_value: anything,
          app_name: "other",
          attrs: {
            service: service,
            endpoint: name
          }
        )
        expect(MetricsService).to receive(:increment_counter).with(
          metric_group: "service",
          app_name: "other",
          metric_name: "request_attempt",
          attrs: {
            service: service,
            endpoint: name
          }
        )
        expect(Rails.logger).to receive(:info)
        expect(Metric).to receive(:create_metric).with(
          MetricsService,
          {
            uuid: anything,
            name: "caseflow.server.metric.request_latency",
            message: "Test description",
            type: "performance",
            product: "Reader",
            metric_attributes: {
              service: service,
              endpoint: name
            },
            sent_to: [["rails_console"], "dynatrace"],
            sent_to_info: {
              metric_group: "service",
              metric_name: "request_latency",
              metric_value: anything,
              app_name: "other",
              attrs: {
                service: service,
                endpoint: name
              }
            },
            start: anything,
            end: anything,
            duration: anything,
            additional_info: anything
          },
          current_user
        )

        subject
      end
    end
    context "Recording metric errors" do
      before do
        FeatureToggle.enable!(:metrics_monitoring)
      end
      it "Error raised, record metric error" do
        allow(Benchmark).to receive(:measure).and_raise(StandardError)

        expect(Rails.logger).to receive(:error)
        expect(MetricsService).to receive(:increment_counter).with(
          metric_group: "service",
          app_name: "other",
          metric_name: "request_error",
          attrs: {
            service: service,
            endpoint: name
          }
        )
        expect(MetricsService).to receive(:increment_counter).with(
          metric_group: "service",
          app_name: "other",
          metric_name: "request_attempt",
          attrs: {
            service: service,
            endpoint: name
          }
        )
        expect(Rails.logger).to receive(:info)
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
