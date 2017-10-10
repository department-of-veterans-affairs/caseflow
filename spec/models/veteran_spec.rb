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

    context "when veteran does not exist in BGS" do
      before do
        veteran.file_number = "DOESNOTEXIST"
      end

      it { is_expected.to_not be_found }
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
        military_postal_type_code: military_postal_type_code,
        service: [{ branch_of_service: "army" }]
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
        service: [{ branch_of_service: "army" }],
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

  context "#accessible?" do
    subject { veteran.accessible? }

    context "when veteran is too sensitive for user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = ["445566"]
      end

      it { is_expected.to eq(false) }
    end

    context "when veteran is not too sensitive for user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = ["445567"]
      end

      it { is_expected.to eq(true) }
    end
  end

  context "#periods_of_service" do
    subject { veteran.periods_of_service }
    let(:veteran) do
      Veteran.new(service: service)
    end

    context "when a veteran served in multiple places" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: "06282003",
           char_of_svc_code: "HON" },
         { branch_of_service: "Navy",
           entered_on_duty_date: "06282006",
           released_active_duty_date: "06282008",
           char_of_svc_code: "DVA" }]
      end

      it do
        is_expected.to eq ["Army 06/28/2002 - 06/28/2003, Honorable Discharge",
                           "Navy 06/28/2006 - 06/28/2008, Dishonorable for VA Purposes Discharge"]
      end
    end

    context "when a veteran is still serving" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end

      it { is_expected.to eq ["Army 06/28/2002 - "] }
    end

    context "when a veteran does not have any service information" do
      let(:service) do
        [{ branch_of_service: nil,
           entered_on_duty_date: nil,
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end

      it { is_expected.to eq [] }
    end

    context "when a veteran served in one place" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: "06282003",
           char_of_svc_code: "HVA" },
         { branch_of_service: nil,
           entered_on_duty_date: nil,
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end
      it { is_expected.to eq ["Army 06/28/2002 - 06/28/2003, Honorable for VA Purposes Discharge"] }
    end

    context "when a character of service code is not recognized" do
      let(:service) do
        [{ branch_of_service: "Army",
           entered_on_duty_date: "06282002",
           released_active_duty_date: "06282003",
           char_of_svc_code: "TBD" },
         { branch_of_service: nil,
           entered_on_duty_date: nil,
           released_active_duty_date: nil,
           char_of_svc_code: nil }]
      end
      it { is_expected.to eq ["Army 06/28/2002 - 06/28/2003"] }
    end
  end

  context "#age" do
    before do
      Timecop.freeze(Time.utc(2022, 1, 15, 12, 0, 0))
    end
    subject { veteran.age }
    let(:veteran) { Veteran.new(date_of_birth: date_of_birth) }

    context "when they're born in the 1900s" do
      let(:date_of_birth) { Time.utc(1956, 2, 2) }
      it { is_expected.to eq(65) }
    end

    context "when they're born in the 2000s" do
      let(:date_of_birth) { Time.utc(2001, 2, 2) }
      it { is_expected.to eq(20) }
    end

    context "when the date has already passed this year" do
      let(:date_of_birth) { Time.utc(1987, 1, 10) }
      it { is_expected.to eq(35) }
    end
  end
end
