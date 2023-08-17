# frozen_string_literal: true

module DeprecationWarnings
  describe DevelopmentHandler do
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

      context "when deprecation is allowed" do
        let(:message) { "allowed deprecation message" }

        it "does not raise error" do
          expect { call }.not_to raise_error
        end
      end

      context "when deprecation is disallowed" do
        let(:message) { "disallowed deprecation message" }

        before do
          stub_const("DisallowedDeprecations::DISALLOWED_DEPRECATION_WARNING_REGEXES", [Regexp.new(Regexp.escape(message))])
        end

        it "raises DisallowedDeprecationError" do
          expect { call }.to raise_error(::DisallowedDeprecationError)
        end
      end
    end
  end
end
