# frozen_string_literal: true

describe VBMSError do
  describe ".from_vbms_http_error" do
    subject { described_class.from_vbms_http_error(error) }

    context "Incident Flash" do
      let(:error) { VBMS::HTTPError.new(500, "Error! This case requires additional review due to an Incident Flash") }

      it "re-casts the exception to a VBMS::IncidentFlashError" do
        expect(subject).to be_a(VBMS::IncidentFlashError)
      end
    end
  end
end
