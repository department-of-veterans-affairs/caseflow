# frozen_string_literal: true

describe DispatchEmailJob do
  let(:appeal) { create(:appeal) }
  let(:type) { "dispatch" }
  let(:email_address) { "test@test.test" }

  let(:send_email_job) do
    DispatchEmailJob.new(appeal: appeal, type: type, email_address: email_address)
  end

  let(:error) do
    StandardError.new("Error")
  end

  before do
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end

  describe "#call" do
    subject do
      send_email_job.call
    end

    it "returns true" do
      expect(subject).to eq(true)
    end
  end

  describe "#email_for_recipient" do
    context "the type is dispatch" do
      subject do
        send_email_job.send(:email_for_recipient)
      end

      it "creates the email correctly" do
        expect(subject.to).to eq([email_address])
      end
    end

    context "there is no type" do
      let(:send_email_job) do
        DispatchEmailJob.new(appeal: appeal, type: nil, email_address: email_address)
      end

      subject do
        send_email_job.send(:email_for_recipient)
      end

      it "raises exception" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(ArgumentError)
        end
      end
    end
  end

  describe "#send_email" do
    context "there is a valid email" do
      let(:email) { send_email_job.send(:email_for_recipient) }
      subject do
        send_email_job.send(:send_email, email)
      end

      it "sends the email" do
        expect(subject).to eq(true)
      end
    end

    context "the email is nil" do
      let(:email) { nil }
      subject do
        send_email_job.send(:send_email, email)
      end

      it "returns false, doesn't send the email" do
        expect(subject).to eq(false)
      end
    end

    context "an error is thrown" do
      it "rescues error and logs to sentry" do
        allow_any_instance_of(DispatchMailer).to receive(:dispatch).and_raise(error)
        send_email_job.call
        expect(@raven_called).to eq(true)
      end
    end
  end
end
