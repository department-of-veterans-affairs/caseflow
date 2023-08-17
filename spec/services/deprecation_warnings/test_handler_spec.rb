# frozen_string_literal: true

module DeprecationWarnings
  describe TestHandler do
    context ".call" do
      subject(:call) { described_class.call(message, callstack = [], deprecation_horizon = "6.0", gem_name = "Rails") }

      let(:message) { "dummy deprecation message" }

      it "logs message to stderr" do
        expect { call }.to output("#{message}\n").to_stderr
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
