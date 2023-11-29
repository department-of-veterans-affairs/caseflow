# frozen_string_literal: true

describe QueueFilterParameter do
  describe ".from_string" do
    let(:filter_string) { nil }

    subject { QueueFilterParameter.from_string(filter_string) }

    def encode_values(values)
      URI::DEFAULT_PARSER.escape(
        values.map(&URI::DEFAULT_PARSER.method(:escape)).join("|")
      )
    end

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
      let(:encoded_values) { encode_values([non_null_value, COPY::NULL_FILTER_LABEL]) }
      let(:column_name) { "fake_column" }
      let(:filter_string) { "col=#{column_name}&val=#{encoded_values}" }

      it "converts the blank value to a null value" do
        expect(subject.values).to match_array([non_null_value, nil])
      end
    end

    context "input string contains valid column and value fields with comma" do
      let(:location_values) { ["New York, NY(RO)", "San Francisco, CA(VA)"] }
      let(:all_location_values) { location_values }
      let(:encoded_location_values) { encode_values(all_location_values) }
      let(:filter_string) do
        "col=#{Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME}&val=#{encoded_location_values}"
      end

      it "instantiates without error and returns the expected values" do
        expect { subject }.to_not raise_error
        expect(subject).to be_a(QueueFilterParameter)
        expect(subject.values).to match_array all_location_values
      end

      context "input string also includes a blank value field" do
        let(:all_location_values) { location_values + [COPY::NULL_FILTER_LABEL] }

        it "returns the expected values" do
          expect(subject.values).to match_array location_values + [nil]
        end
      end
    end
  end
end
