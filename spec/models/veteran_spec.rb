require "rails_helper"

describe Veteran do
  let(:veteran) { Veteran.new({ file_number: "445566" }.merge(veteran_attrs)) }
  let(:veteran_attrs) { {} }

  context "#load_bgs_record!" do
    subject { veteran.load_bgs_record! }

    let(:veteran_record) do
      {
        file_number: "445566",
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        city: "San Francisco",
        state: "CA",
        country: "USA",
        zip_code: "94117",
        military_post_office_type_code: "DPO",
        military_postal_type_code: "AE",

        # test extra values from BGS go unused
        chaff: "chaff"
      }
    end

    before do
      Fakes::BGSService.veteran_records = { "445566" => veteran_record }
    end

    it "returns the veteran with data loaded from BGS" do
      is_expected.to have_attributes(
        file_number: "445566",
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        city: "San Francisco",
        state: "CA",
        country: "USA",
        zip_code: "94117",
        military_post_office_type_code: "DPO",
        military_postal_type_code: "AE"
      )
    end
  end

  context "#to_vbms_hash" do
    subject { veteran.to_vbms_hash }

    let(:veteran_attrs) do
      {
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        city: "San Francisco",
        state: "CA",
        country: country,
        zip_code: "94117",
        military_post_office_type_code: military_post_office_type_code,
        military_postal_type_code: military_postal_type_code
      }
    end

    let(:military_post_office_type_code) { nil }
    let(:military_postal_type_code) { nil }
    let(:country) { "USA" }

    it "returns the correct values" do
      is_expected.to eq(
        file_number: "445566",
        sex: "M",
        first_name: "June",
        last_name: "Juniper",
        ssn: "123456789",
        address_line1: "122 Mullberry St.",
        address_line2: "PO BOX 123",
        address_line3: "Daisies",
        city: "San Francisco",
        state: "CA",
        country: "USA",
        zip_code: "94117",
        address_type: ""
      )
    end

    context "when state represents a military address" do
      let(:military_postal_type_code) { "AA" }
      let(:military_post_office_type_code) { "APO" }

      it { is_expected.to include(state: "AA", city: "APO", address_type: "OVR") }
    end

    context "when country is not USA" do
      let(:country) { "Australia" }

      it { is_expected.to include(address_type: "INT") }

      context "when state represents a military address" do
        let(:military_postal_type_code) { "AA" }
        let(:military_post_office_type_code) { "DPO" }

        it { is_expected.to include(state: "AA", city: "DPO", address_type: "OVR") }
      end
    end
  end
end
