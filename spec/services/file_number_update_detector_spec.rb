# frozen_string_literal: true

describe FileNumberUpdateDetector, :postgres do
  let(:detector) { FileNumberUpdateDetector.new(veteran: veteran) }
  let(:file_number) { ssn }
  let(:ssn) { "123456789" }
  let(:veteran) { create(:veteran, ssn: ssn, file_number: ssn) }
  before do
    allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn).and_return(file_number)
  end

  describe "#new_file_number" do
    subject { detector.new_file_number }
    context "when no update is detected" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when a new file number is found" do
      let(:file_number) { "new file number" }

      it "returns the new file number" do
        expect(subject).to eq(file_number)
      end
    end

    context "when file number is nil" do
      let(:file_number) { nil }
      before do
        allow_any_instance_of(BGSService).to receive(:fetch_veteran_info).and_return(vet_info)
      end

      context "when the veteran's file can be fetched using their SSN" do
        let(:vet_info) do
          { ssn: ssn }
        end
        it "returns nil" do
          expect(subject).to be_nil
        end
      end

      context "when the veteran's file is not found" do
        let(:vet_info) do
          { return_code: "BPNQ0100", return_message: "No BIRLS record found" }
        end

        it "raises an exception" do
          expect { subject }.to raise_error(Caseflow::Error::BgsFileNumberMismatch)
        end
      end
    end
  end
end
