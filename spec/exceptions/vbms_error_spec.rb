# frozen_string_literal: true

describe VBMSError do
  describe "#new" do
    it "preserves backtrace" do
      trace = %w[foo bar]
      orig_error = StandardError.new("oop!")
      orig_error.set_backtrace(trace)

      vbms_error = described_class.new(orig_error)

      expect(vbms_error.message).to eq("oop!")
      expect(vbms_error.backtrace).to eq(trace)
    end

    it "copies over code and body" do
      orig_error = VBMS::HTTPError.new(500, "oops")
      vbms_error = described_class.new(orig_error)

      expect(vbms_error.body).to eq("oops")
      expect(vbms_error.code).to eq(500)
    end
  end

  describe ".from_vbms_http_error" do
    subject { described_class.from_vbms_http_error(error) }

    described_class::KNOWN_ERRORS.each do |err_str, err_class|
      context err_str do
        let(:error) { VBMS::HTTPError.new(500, err_str.sub("\\w+", "FOOBAR")) }

        it "re-casts the exception to a #{err_class}" do
          expect(subject).to be_a("VBMSError::#{err_class}".constantize)
        end
      end
    end
  end
end
