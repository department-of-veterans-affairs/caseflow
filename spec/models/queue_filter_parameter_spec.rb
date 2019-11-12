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
      let(:filter_string) { "col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}" }

      it "raises an MissingRequiredProperty error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
      end
    end

    context "when input string contains valid column and value fields" do
      let(:filter_string) { "col=#{Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name}&val=#{RootTask.name}" }

      it "instantiates without error" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(QueueFilterParameter)
      end
    end

    context "when input string contains blank value field" do
      let(:non_null_value) { "good_value" }
      let(:encoded_blank_value) { URI.escape(URI.escape(COPY::NULL_FILTER_LABEL)) }
      let(:column_name) { "fake_column" }
      let(:filter_string) { "col=#{column_name}&val=#{non_null_value},#{encoded_blank_value}" }

      it "converts the blank value to a null value" do
        expect(subject.values).to match_array([non_null_value, nil])
      end
    end
  end
end
