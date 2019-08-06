# frozen_string_literal: true

describe QueueFilterParameter do
  describe ".from_string" do
    let(:filter_string) { nil }

    subject { QueueFilterParameter.from_string(filter_string) }

    context "when input argument is nil" do
      let(:filter_string) { nil }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input string is not formed how we expect" do
      let(:filter_string) { "string is poorly formed" }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input string does not include the value field" do
      let(:filter_string) { "col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}" }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input string contains valid column and value fields" do
      let(:filter_string) { "col=#{Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN}&val=#{RootTask.name}" }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(QueueFilterParameter)
      end
    end
  end
end
