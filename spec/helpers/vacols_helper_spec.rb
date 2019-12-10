# frozen_string_literal: true

describe VacolsHelper do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    Time.zone = "Eastern Time (US & Canada)"
  end

  context ".local_time_with_utc_timezone" do
    subject { VacolsHelper.local_time_with_utc_timezone }

    it "should be time in EST with UTC timezone" do
      now = Time.zone.now
      expect(subject.hour).to eq now.hour
      expect(subject.zone).to eq "UTC"
    end
  end

  context ".validate_presence" do
    subject { VacolsHelper.validate_presence(hash, required_keys) }

    context "when there is a missing field" do
      let(:hash) do
        { foo: "bar", grip: "foo" }
      end
      let(:required_keys) { [:foo, :grip, :dre] }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredFieldError)
      end
    end

    context "when there is no missing field" do
      let(:hash) do
        { foo: "bar", grip: "foo" }
      end
      let(:required_keys) { [:foo, :grip] }

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
