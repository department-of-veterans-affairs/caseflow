# frozen_string_literal: true

describe "DeprecationWarningSubscriber" do
  let(:rails_logger) { Rails.logger }
  let(:slack_service) { SlackService.new(url: "dummy-url") }

  before do
    allow(Rails).to receive(:logger).and_return(rails_logger)
    allow(rails_logger).to receive(:warn)

    allow(Raven).to receive(:capture_message)
    allow(Raven).to receive(:capture_exception)

    allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
    allow(slack_service).to receive(:send_notification)
  end

  context "when a 'deprecation.rails' event is instrumented" do
    let(:app_name) { "caseflow" }
    let(:deploy_env) { "test" }
    let(:payload) do
      {
        message: "test message",
        gem_name: "Rails",
        deprecation_horizon: "6.0",
        callstack: [location_1, location_2]
      }
    end
    let(:location_1) { instance_double("Thread::Backtrace::Location", to_s: "location 1") }
    let(:location_2) { instance_double("Thread::Backtrace::Location", to_s: "location 2") }

    def instrument_deprecation_warning
      ActiveSupport::Notifications.instrument("deprecation.rails", payload)
    end

    it "emits a warning to the application logs" do
      instrument_deprecation_warning

      expect(rails_logger).to have_received(:warn).with(payload[:message])
    end

    it "emits a warning to Sentry" do
      instrument_deprecation_warning

      expect(Raven).to have_received(:capture_message).with(
        payload[:message],
        level: "warning",
        extra: {
          message: payload[:message],
          gem_name: "Rails",
          deprecation_horizon: "6.0",
          callstack: ["location 1", "location 2"],
          environment: Rails.env
        }
      )
    end

    it "emits a warning to Slack channel" do
      slack_alert_title = "Deprecation Warning - #{app_name} (#{deploy_env})"

      instrument_deprecation_warning

      expect(slack_service).to have_received(:send_notification).with(
        payload[:message],
        slack_alert_title,
        "#appeals-deprecation-alerts"
      )
    end

    context "when an exception occurs" do
      before { allow(slack_service).to receive(:send_notification).and_raise(StandardError) }

      it "logs error to Sentry" do
        instrument_deprecation_warning

        expect(Raven).to have_received(:capture_exception).with(StandardError)
      end

      it "does not raise error" do
        expect { instrument_deprecation_warning }.not_to raise_error
      end
    end
  end
end
