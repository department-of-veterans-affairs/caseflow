# frozen_string_literal: true

module DeprecationWarnings
  describe ProductionHandler do
    context ".call" do
      subject(:call) { described_class.call(message, callstack, deprecation_horizon, gem_name) }

      let(:message) { "dummy deprecation message" }
      let(:callstack) { [] }
      let(:deprecation_horizon) { "6.0" }
      let(:gem_name) { "Rails" }

      let(:rails_logger) { Rails.logger }
      let(:slack_service) { SlackService.new(url: "dummy-url") }
      let(:deploy_env) { ENV["DEPLOY_ENV"] }

      before do
        allow(Rails).to receive(:logger).and_return(rails_logger)
        allow(rails_logger).to receive(:warn)

        allow(Raven).to receive(:capture_message)
        allow(Raven).to receive(:capture_exception)

        allow(SlackService).to receive(:new).with(url: anything).and_return(slack_service)
        allow(slack_service).to receive(:send_notification)
      end

      it "emits a warning to the application logs" do
        call

        expect(rails_logger).to have_received(:warn).with(message)
      end

      it "emits a warning to Sentry" do
        call

        expect(Raven).to have_received(:capture_message).with(
          message,
          level: "warning",
          extra: {
            message: message,
            gem_name: gem_name,
            deprecation_horizon: deprecation_horizon,
            callstack: callstack,
            environment: Rails.env
          }
        )
      end

      it "emits a warning to Slack channel" do
        slack_alert_title = "Deprecation Warning - caseflow (#{deploy_env})"

        call

        expect(slack_service).to have_received(:send_notification).with(
          message,
          slack_alert_title,
          "#appeals-deprecation-alerts"
        )
      end

      context "when an exception occurs" do
        before { allow(slack_service).to receive(:send_notification).and_raise(StandardError) }

        it "logs error to Sentry" do
          call

          expect(Raven).to have_received(:capture_exception).with(StandardError)
        end

        it "does not raise error" do
          expect { call }.not_to raise_error
        end
      end
    end
  end
end
