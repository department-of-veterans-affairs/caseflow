# frozen_string_literal: true

module DeprecationWarnings
  describe DevelopmentHandler do
    context ".call" do
      subject(:call) do
        described_class.call(message, _callstack = [], _deprecation_horizon = "6.0", _gem_name = "Rails")
      end

      let(:message) { "dummy deprecation message" }
      let(:rails_logger) { Rails.logger }

      before do
        allow(Rails).to receive(:logger).and_return(rails_logger)
        allow(rails_logger).to receive(:warn)
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
          stub_const("DisallowedDeprecations::DISALLOWED_DEPRECATION_WARNING_REGEXES",
                     [Regexp.new(Regexp.escape(message))])
        end

        it "raises DisallowedDeprecationError" do
          expect { call }.to raise_error(::DisallowedDeprecationError)
        end
      end
    end
  end
end
