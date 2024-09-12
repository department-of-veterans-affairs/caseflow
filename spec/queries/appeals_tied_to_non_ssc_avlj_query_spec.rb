# frozen_string_literal: true

require "appeals_tied_to_non_ssc_avlj_query"

RSpec.describe AppealsTiedToNonSscAvljQuery do
  describe ".tied_appeals" do
    let(:docket_coordinator) { instance_double(DocketCoordinator) }
    let(:legacy_docket) { instance_double("LegacyDocket") }

    before do
      allow(DocketCoordinator).to receive(:new).and_return(docket_coordinator)
      allow(docket_coordinator).to receive(:dockets)
        .and_return(
          {
            legacy: legacy_docket
          }
        )
    end

    context "when there are legacy appeals tied to non-SSC AVLJs" do
      let(:legacy_appeal1) { { "tinum" => "123456", "bfkey" => "1", "priority" => 1, "bfd19" => "2023-01-01" } }
      let(:legacy_appeal2) { { "tinum" => "789012", "bfkey" => "2", "priority" => 0, "bfd19" => "2023-02-01" } }

      before do
        allow(legacy_docket).to receive(:appeals_tied_to_non_ssc_avljs).and_return([legacy_appeal1, legacy_appeal2])
        allow(described_class).to receive(:calculate_field_values)
          .and_return(
            {
              veteran_file_number: "123456789",
              veteran_name: "John Doe",
              non_ssc_avlj: "Judge Smith",
              hearing_judge: "Judge Smith",
              most_recent_signing_judge: "Judge Johnson",
              bfcurloc: "57"
            }
          )
      end

      it "returns formatted legacy appeals" do
        result = described_class.tied_appeals

        expect(result.length).to eq(2)
        expect(result.first[:docket_number]).to eq("123456")
        expect(result.first[:docket]).to eq("legacy")
        expect(result.first[:priority]).to eq("True")
        expect(result.first[:receipt_date]).to eq("2023-01-01")
        expect(result.first[:veteran_file_number]).to eq("123456789")
        expect(result.first[:veteran_name]).to eq("John Doe")
        expect(result.first[:non_ssc_avlj]).to eq("Judge Smith")
        expect(result.first[:hearing_judge]).to eq("Judge Smith")
        expect(result.first[:most_recent_signing_judge]).to eq("Judge Johnson")
        expect(result.first[:bfcurloc]).to eq("57")
      end
    end

    context "when there are no legacy appeals tied to non-SSC AVLJs" do
      before do
        allow(legacy_docket).to receive(:appeals_tied_to_non_ssc_avljs).and_return([])
      end

      it "returns an empty array" do
        expect(described_class.tied_appeals).to be_empty
      end
    end

    context "when there are duplicate legacy appeals" do
      let(:duplicate_appeal) { { "tinum" => "123456", "bfkey" => "1", "priority" => 1, "bfd19" => "2023-01-01" } }

      before do
        allow(legacy_docket).to receive(:appeals_tied_to_non_ssc_avljs).and_return([duplicate_appeal, duplicate_appeal])
        allow(described_class).to receive(:calculate_field_values)
          .and_return(
            {
              veteran_file_number: "123456789",
              veteran_name: "John Doe",
              non_ssc_avlj: "Judge Smith",
              hearing_judge: "Judge Smith",
              most_recent_signing_judge: "Judge Johnson",
              bfcurloc: "57"
            }
          )
      end

      it "returns unique appeals based on docket number" do
        result = described_class.tied_appeals

        expect(result.length).to eq(1)
        expect(result.first[:docket_number]).to eq("123456")
      end
    end
  end
end
